extends Node
## BotSystem: bots que completan los equipos (4 contra 4). Juegan el objetivo de
## la ronda con roles de ataque/defensa, compran y construyen en el interludio y
## usan el mismo CombatSystem que los jugadores. Corre solo en el servidor.
##
## Unidades: las constantes de comportamiento están en studs y
## se convierten a píxeles con GC.STUD. Y va hacia abajo en Godot.

const THINK_INTERVAL := 0.12
const REACTION_TIME := 0.3
const ENGAGE_DISTANCE := 55.0          # studs
const GRENADE_MIN := 12.0              # studs
const GRENADE_MAX := 40.0              # studs
const ENEMY_BASE_X := 236.0            # studs desde el centro
const PATH_REFRESH := 0.6              # s entre recálculos de BFS por bot
const ENSURE_INTERVAL := 3.0

const BOT_NAMES := {
	"USA": ["Pvt. Jelly", "Cpl. Gumdrop", "Sgt. Sourpatch", "Pvt. Licorice", "Pvt. Marshmallow", "Cpl. Taffy"],
	"Vietnam": ["Dong Keo", "Be Deo", "Anh Mut", "Chu Gom", "Bo Doi Ngot", "Co Mia"],
}

## NavGrid usa como "celda de pie" la celda de aire donde están los pies; acá
## el nodo es el bloque sólido de abajo: fila + NAV_OFFSET.
const NAV_OFFSET := 1

const COMBAT_UTIL_PATH := "res://scripts/game/combat_util.gd"

## Cada slot: {key, name, team, class, role, range_offset, move_dir, next_think,
## seen_for, stuck_for, strafe_until, strafe, aim_error, want_fire, fire_angle,
## next_grenade, jump_until, dead_since, path, path_goal, path_at}
var _slots: Array = []
var _next_bot_id := 1
var _ensure_accum := 0.0
var _started := false
var _combat_util: Script = null


func init_system() -> void:
	_slots.clear()
	_next_bot_id = 1
	if ResourceLoader.exists(COMBAT_UTIL_PATH):
		var s = load(COMBAT_UTIL_PATH)
		if s is Script:
			_combat_util = s


func start_system() -> void:
	_started = true
	ServerEvents.phase_changed.connect(_on_phase)
	ServerEvents.deployed.connect(func(_peer_id: int): call_deferred("_ensure_slots"))
	Net.peer_left.connect(func(_peer_id: int): call_deferred("_ensure_slots"))


func _exit_tree() -> void:
	# al cerrar la sesión no dejar bots huérfanos en el registro
	_slots.clear()


# --- utilidades ------------------------------------------------------------

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _phase() -> String:
	return MatchState.phase()


func _sys(n: String) -> Node:
	return G.system(n)


func _sign(x: float) -> int:
	return 1 if x > 0.0 else (-1 if x < 0.0 else 0)


func _side(team: String) -> int:
	return int(GC.TEAM_INFO[team]["side"]) if GC.TEAM_INFO.has(team) else -1


func _attr(ch: Node, k: String, def = null):
	if ch != null and ch.has_method("get_attr"):
		return ch.get_attr(k, def)
	return def


func _alive(ch: Node) -> bool:
	return ch != null and is_instance_valid(ch) and ch.has_method("is_alive") and ch.is_alive()


func _feet(ch: Node) -> Vector2:
	if ch.has_method("feet_position"):
		return ch.feet_position()
	return (ch as Node2D).global_position


func _center(ch: Node) -> Vector2:
	return _feet(ch) + Vector2(0, -GC.CHARACTER["feet_offset"] * GC.STUD)


func _shoulder(ch: Node) -> Vector2:
	if ch.has_method("shoulder_position"):
		return ch.shoulder_position()
	return _feet(ch) + Vector2(0, -GC.CHARACTER["shoulder_height"] * GC.STUD)


func _vel(ch: Node) -> Vector2:
	var v = ch.get("velocity")
	return v if v is Vector2 else Vector2.ZERO


func _char(key: String) -> Node:
	var ch: Node = G.get_character(key)
	if ch != null and is_instance_valid(ch) and not ch.is_queued_for_deletion():
		return ch
	return null


# --- altas y bajas -----------------------------------------------------------

func _match_running() -> bool:
	var p := _phase()
	return p != "" and p != "Waiting"


func _humans_on(team: String) -> int:
	var n := 0
	for p in MatchState.players.values():
		if p.get("Deployed", false) and p.get("Team", "") == team:
			n += 1
	return n


func _ensure_slots() -> void:
	if not _started or not is_inside_tree():
		return
	for team in GC.TEAMS:
		var wanted := 0
		if GC.MATCH["fill_with_bots"] and _match_running():
			wanted = maxi(0, int(GC.MATCH["team_size"]) - _humans_on(team))
		var mine: Array = []
		for i in _slots.size():
			if _slots[i]["team"] == team:
				mine.append(i)
		if mine.size() < wanted:
			for n in range(1, wanted - mine.size() + 1):
				var names: Array = BOT_NAMES[team]
				var id := _next_bot_id
				_next_bot_id += 1
				var slot := {
					"key": "B%d" % id,
					"name": names[(id - 1) % names.size()],
					"team": team,
					"class": "Pyro" if id % 3 == 0 else "Soldier",
					"role": "defend" if (mine.size() + n) % 2 == 0 else "attack",
					"range_offset": float(randi_range(-8, 12)),
				}
				_reset_slot(slot)
				_slots.append(slot)
				var ph := _phase()
				if ph == "Prep" or ph == "Round":
					_spawn(slot)
				else:
					# registrarlo igual para que figure en el marcador
					var lo := _sys("Loadout")
					if lo and lo.has_method("register"):
						lo.register(slot["key"], {"name": slot["name"], "team": team,
							"class": slot["class"], "is_bot": true, "peer_id": 0})
		elif mine.size() > wanted:
			for k in range(mine.size() - 1, wanted - 1, -1):
				_remove_slot(mine[k])


func _reset_slot(slot: Dictionary) -> void:
	slot["move_dir"] = 0
	slot["next_think"] = 0.0
	slot["seen_for"] = 0.0
	slot["stuck_for"] = 0.0
	slot["strafe_until"] = 0.0
	slot["strafe"] = 0
	slot["aim_error"] = 0.0
	slot["want_fire"] = false
	slot["fire_angle"] = 0.0
	slot["next_grenade"] = _now() + 4.0 + randf() * 6.0
	slot["jump_until"] = 0.0
	slot["dead_since"] = -1.0
	slot["path"] = []
	slot["path_goal"] = Vector2i(999999, 999999)
	slot["path_at"] = -100.0


## Aparece (o reaparece) al bot en su base.
func _spawn(slot: Dictionary) -> void:
	var cs := _sys("Character")
	if cs == null:
		return
	var key: String = slot["key"]
	var ch := _char(key)
	if ch != null and cs.has_method("respawn"):
		cs.respawn(key)
	elif cs.has_method("spawn_bot"):
		cs.spawn_bot(key, slot["name"], slot["team"], slot["class"])
	_reset_slot(slot)


func _remove_slot(index: int) -> void:
	var slot: Dictionary = _slots[index]
	var key: String = slot["key"]
	var cs := _sys("Character")
	if cs and cs.has_method("despawn"):
		cs.despawn(key)
	else:
		var ch := _char(key)
		if ch:
			ch.queue_free()
	var lo := _sys("Loadout")
	if lo and lo.has_method("unregister"):
		lo.unregister(key)
	_slots.remove_at(index)


func _on_phase(new_phase: String, _round_number: int) -> void:
	call_deferred("_ensure_slots")
	if new_phase == "Prep" or new_phase == "Round":
		call_deferred("_spawn_all")
	if new_phase == "Prep":
		_prep_routine()
	elif new_phase == "Waiting":
		for i in range(_slots.size() - 1, -1, -1):
			_remove_slot(i)


func _spawn_all() -> void:
	for slot in _slots:
		_spawn(slot)


## A los 3 s del interludio cada bot compra y construye, uno cada 0,4 s.
func _prep_routine() -> void:
	await get_tree().create_timer(3.0).timeout
	for slot in _slots.duplicate():
		if not is_inside_tree() or _phase() != "Prep":
			return
		if not (slot in _slots):
			continue
		_bot_shop(slot)
		_bot_build(slot)
		await get_tree().create_timer(0.4).timeout


# --- interludio: compras y construcción -------------------------------------

func _bot_shop(slot: Dictionary) -> void:
	var lo := _sys("Loadout")
	if lo == null or not lo.has_method("get_combatant") or not lo.has_method("buy"):
		return
	var c: Dictionary = lo.get_combatant(slot["key"])
	if c.is_empty():
		return
	var money: int = int(c["loadout"]["money"])
	var options: Array = []
	for item in Data.SHOP_ITEMS:
		if int(item["price"]) <= money:
			options.append(item["id"])
	if options.size() > 0 and randf() < 0.8:
		lo.buy(slot["key"], options[randi() % options.size()])


## Coberturas espaciadas (nunca murallas que tapen el paso): columnas de 1-2
## bloques con huecos entre medio.
func _bot_build(slot: Dictionary) -> void:
	var bs := _sys("Build")
	var lo := _sys("Loadout")
	if bs != null and bs.has_method("bot_build"):
		bs.bot_build(slot["key"])
		return
	if bs == null or not bs.has_method("place_block") or lo == null:
		return
	var c: Dictionary = lo.get_combatant(slot["key"])
	if c.is_empty():
		return
	var team: String = slot["team"]
	var zone: Dictionary = GC.BUILD[team]
	var side := _side(team)
	var key: String = slot["key"]
	var budget := mini(int(c["loadout"]["blocks_left"]), randi_range(3, 5))
	var tries := 0
	while budget > 0 and tries < 30:
		tries += 1
		var t := pow(randf(), 0.7)
		var span := float(zone["max_col"] - zone["min_col"])
		var col: int
		if side == -1:
			col = int(floor(zone["min_col"] + span * t + 0.5))
		else:
			col = int(floor(zone["max_col"] - span * t + 0.5))
		# dejar pasillo: no construir pegado a otra columna construida
		var crowded := false
		for dc in [-2, -1, 1, 2]:
			if _is_built(col + dc, 1):
				crowded = true
		if not crowded and _can_place(bs, key, Vector2i(col, 1)):
			if bs.place_block(key, Vector2i(col, 1)) == "":
				budget -= 1
				if budget > 0 and randf() < 0.5 and _can_place(bs, key, Vector2i(col, 2)):
					if bs.place_block(key, Vector2i(col, 2)) == "":
						budget -= 1


func _can_place(bs: Node, key: String, cell: Vector2i) -> bool:
	if bs.has_method("can_place"):
		return bs.can_place(key, cell) == ""
	return true


func _is_built(col: int, row: int) -> bool:
	if G.map == null:
		return false
	if G.map.has_method("is_built"):
		return G.map.is_built(col, row)
	if G.map.has_method("get_cell"):
		var c: Dictionary = G.map.get_cell(col, row)
		return not c.is_empty() and not c.get("static", true)
	return false


# --- navegación ----------------------------------------------------------------

## Fila del bloque sobre el que están los pies.
func _support_cell(feet: Vector2) -> Vector2i:
	return Vector2i(int(round(feet.x / GC.BLOCK)), int(round(-feet.y / GC.BLOCK)))


func _standable(nav: Node, c: int, r: int) -> bool:
	if nav != null and nav.has_method("standable"):
		return nav.standable(Vector2i(c, r + NAV_OFFSET))
	if G.map == null or not G.map.has_method("is_solid"):
		return false
	return G.map.is_solid(c, r) and not G.map.is_solid(c, r + 1) and not G.map.is_solid(c, r + 2)


## Nodo transitable más cercano (el bloque sólido).
func _nearest_node(nav: Node, col: int, row: int) -> Variant:
	var best = null
	var best_score := INF
	for c in range(maxi(-64, col - 6), mini(64, col + 6) + 1):
		for r in range(maxi(-1, row - 8), mini(22, row + 8) + 1):
			if _standable(nav, c, r):
				var score := absi(c - col) * 2.0 + absi(r - row) * 3.0
				if score < best_score:
					best = Vector2i(c, r)
					best_score = score
	return best


## Devuelve [siguiente_nodo, nodo_inicial] o [] si ya llegamos / no hay camino.
func _next_step(slot: Dictionary, feet: Vector2, goal_pos: Vector2, now: float) -> Array:
	var nav := _sys("Nav")
	if nav == null or not nav.has_method("find_path"):
		return []
	var sc := _support_cell(feet)
	var start = _nearest_node(nav, sc.x, sc.y)
	var goal = _nearest_node(nav, int(round(goal_pos.x / GC.BLOCK)), int(round(-goal_pos.y / GC.BLOCK)))
	if start == null or goal == null or start == goal:
		return []
	var off := NAV_OFFSET
	var path: Array = slot["path"]
	var idx := _path_index(path, start)
	if goal != slot["path_goal"] or idx < 0 or now - float(slot["path_at"]) > PATH_REFRESH:
		var raw = nav.find_path(Vector2i(start.x, start.y + off), Vector2i(goal.x, goal.y + off))
		path = []
		if raw is Array:
			for cell in raw:
				if cell is Vector2i:
					path.append(Vector2i(cell.x, cell.y - off))
		slot["path"] = path
		slot["path_goal"] = goal
		slot["path_at"] = now
		idx = _path_index(path, start)
	if path.is_empty():
		return []
	if idx < 0:
		# el camino no empieza en nuestro nodo: ir al primero
		return [path[0], start]
	if idx + 1 >= path.size():
		return []
	return [path[idx + 1], start]


func _path_index(path: Array, cell: Vector2i) -> int:
	for i in path.size():
		if path[i] == cell:
			return i
	return -1


# --- percepción ----------------------------------------------------------------

func _find_target(ch: Node, pos: Vector2, max_dist_px: float) -> Array:
	var team: String = slot_team(ch)
	var best: Node = null
	var best_dist := max_dist_px
	for other in G.all_characters():
		if other == ch or not _alive(other) or other.team() == team:
			continue
		var d := _center(other).distance_to(pos)
		if d < best_dist:
			best = other
			best_dist = d
	return [best, best_dist]


func slot_team(ch: Node) -> String:
	return ch.team() if ch.has_method("team") else String(_attr(ch, "Team", ""))


## Blanco prioritario de la misión: el VIP enemigo (Asesinato) o quien lleva
## nuestra bandera (CTF).
func _priority_target(ch: Node, team: String) -> Node:
	var mission := String(MatchState.get_var("Mission", ""))
	for other in G.all_characters():
		if other == ch or not _alive(other) or other.team() == team:
			continue
		if mission == "Assassination" and _attr(other, "VIP", false):
			return other
		var flag = _attr(other, "CarryingFlag", "")
		if mission == "CTF" and ((flag is String and flag != "") or (flag is bool and flag)):
			return other
	return null


func _line_of_sight(from: Vector2, to: Vector2, team: String) -> bool:
	if G.map == null or not G.map.has_method("segment_hit"):
		return true
	var r = G.map.segment_hit(from, to, team)
	return not (r is Dictionary and r.get("hit", false))


func _aim_at(slot: Dictionary, ch: Node, shoulder: Vector2, point: Vector2) -> float:
	var angle := GC.dir_to_angle(point - shoulder) + float(slot["aim_error"])
	_set_aim(ch, angle)
	return angle


func _set_aim(ch: Node, angle: float) -> void:
	var cb := _sys("Combat")
	if cb and cb.has_method("set_aim"):
		cb.set_aim(ch, angle)
	elif ch.has_method("set_attr"):
		ch.set_attr("Aim", angle)


## Estructura enemiga (depósito de Demolición) a tiro. Equivale a goal.AttackPart.
func _attack_structure(team: String, shoulder: Vector2, range_px: float) -> Node2D:
	for s in get_tree().get_nodes_in_group("structures"):
		if not (s is Node2D) or not is_instance_valid(s):
			continue
		var st = s.get("team")
		if st is String and st != team and st != "":
			if (s as Node2D).global_position.distance_to(shoulder) < range_px:
				return s
	return null


# --- cerebro -------------------------------------------------------------------

func _think(slot: Dictionary, ch: Node, now: float) -> void:
	var weapon := Data.get_weapon(String(_attr(ch, "Weapon", "Rifle")))
	var feet := _feet(ch)
	var pos := _center(ch)
	var shoulder := _shoulder(ch)
	var vel := _vel(ch)
	var team: String = slot["team"]
	var side := _side(team)
	var S := GC.STUD
	var move_dir := 0
	var jump := false
	slot["want_fire"] = false
	slot["aim_error"] = clampf(float(slot["aim_error"]) + (randf() - 0.5) * 0.05, -0.06, 0.06)
	var ph := _phase()

	# Interludio: quedarse en la base moviéndose un poco
	if ph == "Prep":
		var home_x := side * (150.0 + float(slot["range_offset"]) * 3.0) * S
		var hdx := home_x - pos.x
		move_dir = _sign(hdx) if absf(hdx) > 4.0 * S else 0
		slot["move_dir"] = move_dir
		_set_aim(ch, 0.0 if -side > 0 else PI)
		return
	if ph != "Round":
		slot["move_dir"] = 0
		return

	var role: String = slot["role"]
	var goal_pos := Vector2(-side * ENEMY_BASE_X * S, 0.0)
	var hold := false
	var priority: Node = null
	var structure: Node2D = null
	var obj := _sys("Objective")
	if obj and obj.has_method("get_bot_goal"):
		# versión completa: {valid, position, hold, priority (clave), structure}
		var g = obj.get_bot_goal(ch, role)
		if g is Dictionary and g.get("valid", false):
			var gp = g.get("position")
			if gp is Vector2 and gp.is_finite():
				goal_pos = gp
			hold = bool(g.get("hold", false))
			var pk = g.get("priority", "")
			if pk is String and pk != "":
				var pc := _char(pk)
				if _alive(pc):
					priority = pc
			var st = g.get("structure")
			if st is Node2D and is_instance_valid(st):
				structure = st
	elif obj and obj.has_method("get_bot_target"):
		var gp = obj.get_bot_target(ch, role)
		if gp is Vector2 and gp.is_finite():
			goal_pos = gp
			# sin la versión completa: aproximar "Hold" y el blanco prioritario
			var mission := String(MatchState.get_var("Mission", ""))
			var zone_mission := mission == "KingOfHill" or mission == "Radio"
			var near_goal := absf(goal_pos.x - feet.x) < 8.0 * S and absf(goal_pos.y - feet.y) < 8.0 * S
			hold = near_goal and (zone_mission or role == "defend")
			priority = _priority_target(ch, team)
			if role == "attack":
				structure = _attack_structure(team, shoulder, INF)

	var range_studs := float(weapon["range"])
	var target: Node = priority
	var target_dist := 0.0
	if target != null:
		target_dist = _center(target).distance_to(pos)
	else:
		var found := _find_target(ch, pos, (ENGAGE_DISTANCE + (40.0 if range_studs > 100.0 else 0.0)) * S)
		target = found[0]
		target_dist = found[1]

	var fighting := false
	if target != null:
		var tpos := _center(target)
		var aim_point := tpos + Vector2(0, -0.6 * S)
		if weapon["projectile"] != "Flame":
			# adelantar el tiro según la velocidad del blanco
			var travel := (aim_point - shoulder).length() / (float(weapon["projectile_speed"]) * S)
			aim_point.x += _vel(target).x * travel
			# a veces apuntan a la cabeza
			if randf() < 0.25:
				aim_point.y -= 1.2 * S
		var angle := _aim_at(slot, ch, shoulder, aim_point)
		var los := (aim_point - shoulder).length() <= (range_studs + 3.0) * S \
			and _line_of_sight(shoulder, aim_point, team)
		slot["seen_for"] = float(slot["seen_for"]) + THINK_INTERVAL if los else 0.0
		if float(slot["seen_for"]) >= REACTION_TIME:
			slot["want_fire"] = true
			slot["fire_angle"] = angle
		fighting = los or target_dist < 25.0 * S

		if fighting:
			var dx := tpos.x - pos.x
			var melee := range_studs < 60.0
			var ro: float = slot["range_offset"]
			var preferred := (5.0 + absf(ro) * 0.3) if melee else (26.0 + ro)
			preferred *= S
			if hold:
				if now >= float(slot["strafe_until"]):
					slot["strafe"] = randi_range(-1, 1)
					slot["strafe_until"] = now + 0.3 + randf() * 0.4
				move_dir = slot["strafe"]
			elif absf(dx) > preferred + 6.0 * S:
				move_dir = _sign(dx)
			elif not melee and absf(dx) < preferred - 10.0 * S:
				move_dir = -_sign(dx)
			else:
				if now >= float(slot["strafe_until"]):
					slot["strafe"] = randi_range(-1, 1)
					slot["strafe_until"] = now + 0.4 + randf() * 0.6
				move_dir = slot["strafe"]
			# blanco más alto (Y hacia abajo)
			if tpos.y < pos.y - 4.0 * S and randf() < 0.3:
				jump = true
			# granada
			if int(_attr(ch, "Grenades", 0)) > 0 and now >= float(slot["next_grenade"]) \
					and target_dist > GRENADE_MIN * S and target_dist < GRENADE_MAX * S:
				slot["next_grenade"] = now + 6.0 + randf() * 6.0
				var cb := _sys("Combat")
				if cb and cb.has_method("throw_grenade"):
					cb.throw_grenade(ch, angle + _sign(cos(angle)) * 0.35)
	else:
		slot["seen_for"] = 0.0

	if not fighting:
		var dx := goal_pos.x - pos.x
		var step := _next_step(slot, feet, goal_pos, now)
		if hold and absf(dx) < 6.0 * S and absf(goal_pos.y - feet.y) < 6.0 * S:
			if now >= float(slot["strafe_until"]):
				slot["strafe"] = randi_range(-1, 1)
				slot["strafe_until"] = now + 0.5 + randf()
			move_dir = slot["strafe"]
		elif step.size() == 2:
			# seguir el camino de plataformas
			var node: Vector2i = step[0]
			var start_node: Vector2i = step[1]
			var sdx := node.x * GC.BLOCK - pos.x
			move_dir = _sign(sdx) if absf(sdx) > 0.8 * S else _sign(dx)
			# en el aire se mantiene la dirección (evita ir y venir a mitad de un salto)
			if absf(vel.y) > 3.0 * S and int(slot["move_dir"]) != 0:
				move_dir = slot["move_dir"]
			var climbing := node.y > start_node.y
			var gap := absi(node.x - start_node.x) >= 2
			if (climbing or gap) and absf(sdx) < (7.0 if gap else 5.5) * S:
				jump = true
		else:
			move_dir = _sign(dx) if absf(dx) > 1.5 * S else 0
			if goal_pos.y < feet.y - 3.0 * S and absf(dx) < 16.0 * S and randf() < 0.5:
				jump = true
		# atacar la estructura objetivo (depósito)
		var part: Node2D = structure
		if part != null and part.global_position.distance_to(shoulder) < (range_studs + 2.0) * S:
			var ang := _aim_at(slot, ch, shoulder, part.global_position)
			slot["want_fire"] = true
			slot["fire_angle"] = ang
			if part.global_position.distance_to(shoulder) < 8.0 * S:
				move_dir = 0
		elif target == null:
			_set_aim(ch, 0.0 if move_dir >= 0 else PI)

	# Obstáculos: saltar, o romper bloques enemigos que bloquean el paso
	if move_dir != 0:
		var chest := Vector2(pos.x, feet.y - 2.5 * S)
		if G.map and G.map.has_method("segment_hit"):
			var hit = G.map.segment_hit(chest, chest + Vector2(move_dir * 3.2 * S, 0), team)
			if hit is Dictionary and hit.get("hit", false):
				var cell = hit.get("cell")
				if cell is Vector2i and G.map.has_method("get_cell") and not slot["want_fire"]:
					var info: Dictionary = G.map.get_cell(cell.x, cell.y)
					if not info.is_empty() and not info.get("static", true) and info.get("team", team) != team:
						var ang := _aim_at(slot, ch, shoulder, GC.cell_center(cell.x, cell.y))
						slot["want_fire"] = true
						slot["fire_angle"] = ang
				jump = true
		if absf(vel.x) < 1.5 * S:
			slot["stuck_for"] = float(slot["stuck_for"]) + THINK_INTERVAL
			if float(slot["stuck_for"]) > 0.3:
				jump = true
				slot["stuck_for"] = 0.0
		else:
			slot["stuck_for"] = 0.0
	if randf() < 0.02:
		jump = true

	slot["move_dir"] = move_dir
	if jump:
		slot["jump_until"] = now + THINK_INTERVAL


func _fire(slot: Dictionary, ch: Node) -> void:
	var cb := _sys("Combat")
	if cb == null or not cb.has_method("fire"):
		return
	# recargar si se quedó sin balas
	if int(_attr(ch, "Ammo", 1)) <= 0:
		if not _attr(ch, "Reloading", false) and cb.has_method("reload"):
			cb.reload(ch)
		return
	if cb.has_method("can_fire") and not cb.can_fire(ch):
		return
	var weapon_id := String(_attr(ch, "Weapon", "Rifle"))
	var aim: float = slot["fire_angle"]
	var moving := int(slot["move_dir"]) != 0
	var angles: Array = []
	if _combat_util != null:
		var r = _combat_util.call("spread_angles", weapon_id, aim, moving)
		if r is Array:
			angles = r
	if angles.is_empty():
		var w := Data.get_weapon(weapon_id)
		var spread := deg_to_rad(float(w["spread"]))
		for i in int(w["pellets"]):
			angles.append(aim + (randf() * 2.0 - 1.0) * spread)
	cb.fire(ch, angles)


func _physics_process(_delta: float) -> void:
	if not _started:
		return
	var now := _now()
	_ensure_accum += _delta
	if _ensure_accum >= ENSURE_INTERVAL:
		_ensure_accum = 0.0
		_ensure_slots()
	var ph := _phase()
	for slot in _slots:
		var ch := _char(slot["key"])
		if ch != null and _alive(ch):
			slot["dead_since"] = -1.0
			if now >= float(slot["next_think"]):
				slot["next_think"] = now + THINK_INTERVAL
				_think(slot, ch, now)
			ch.set("move_input", float(slot["move_dir"]))
			ch.set("jump_input", now < float(slot["jump_until"]))
			if slot["want_fire"] and ph == "Round":
				_fire(slot, ch)
		elif ph == "Prep" or ph == "Round":
			if ch != null:
				ch.set("move_input", 0.0)
				ch.set("jump_input", false)
			if float(slot["dead_since"]) < 0.0:
				slot["dead_since"] = now
			elif now - float(slot["dead_since"]) >= _respawn_delay(ph):
				_spawn(slot)


## Los bots los reaparece este sistema (CharacterSystem solo reaparece humanos).
func _respawn_delay(ph: String) -> float:
	return float(GC.MATCH["prep_respawn_time"] if ph == "Prep" else GC.MATCH["respawn_time"])
