extends Node
## CombatSystem (servidor): combate autoritativo. Cadencia (15% de tolerancia),
## munición, recarga, proyectiles simulados en _physics_process con "spherecast"
## en el plano, headshots (matan en el acto), quemaduras, granadas "Dona Explosiva",
## daño a bloques/estructuras, bajas y recompensas.
## Daño solo en la fase Round; en Prep/Waiting se puede disparar sin daño.

const SAMPLE_STEP := 4.0          # px entre muestras del barrido de un proyectil
const GRENADE_RADIUS_PX := 0.6 * 8.0
const AIM_THROTTLE := 0.03

var _projectiles: Array = []       # {pos, dir, speed, remaining, radius, team, weapon_id, attacker}
var _grenades: Array = []          # {id, pos, vel, age, team, attacker}
var _next_grenade_id := 0
var _last_fire := {}               # key -> seg
var _last_grenade := {}            # key -> seg
var _reloads := {}                 # key -> {at: seg, token}
var _burning := {}                 # key -> {expires, next_tick, data, attacker}
var _last_attacker := {}           # key -> attacker info
var _last_aim := {}                # peer -> seg


func init_system() -> void:
	_projectiles.clear()
	_grenades.clear()
	_last_fire.clear()
	_last_grenade.clear()
	_reloads.clear()
	_burning.clear()
	_last_attacker.clear()


func start_system() -> void:
	Net.register_handler("Fire", _on_fire)
	Net.register_handler("Aim", _on_aim)
	Net.register_handler("Reload", _on_reload)
	Net.register_handler("Grenade", _on_grenade)
	ServerEvents.phase_changed.connect(_on_phase_changed)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# --- fases ------------------------------------------------------------------

func damage_enabled() -> bool:
	return MatchState.phase() == "Round"


func _phase_allows_fire() -> bool:
	var p := MatchState.phase()
	return p == "Round" or p == "Prep" or p == "Waiting"


func _on_phase_changed(_phase: String, _round: int) -> void:
	# al cambiar de fase se limpian quemaduras (los personajes reaparecen)
	for key in _burning.keys():
		var ch = G.get_character(key)
		if ch:
			ch.set_attr("Burning", false)
	_burning.clear()


# --- helpers ----------------------------------------------------------------

func _weapon_id(ch) -> String:
	var w = ch.get_attr("Weapon", "Rifle")
	return w if w is String else "Rifle"


func attacker_info(ch, weapon_display: String = "") -> Dictionary:
	var wid := _weapon_id(ch)
	return {
		"key": CombatUtil.key_of(ch),
		"name": CombatUtil.display_name(ch),
		"team": CombatUtil.team_of(ch),
		"weapon": weapon_display if weapon_display != "" else str(Data.get_weapon(wid).get("display", wid)),
	}


func _valid_angle(a) -> bool:
	return (a is float or a is int) and not is_nan(float(a)) and not is_inf(float(a))


func _char_for_peer(peer_id: int):
	return G.get_character(Net.key_for_peer(peer_id))


## Empuje: en los personajes simulados acá se aplica directo; si no, se avisa al dueño.
func apply_knockback(ch, velocity_px: Vector2) -> void:
	if ch == null or not is_instance_valid(ch):
		return
	var local_ctrl = ch.get("controlled_locally")
	var peer := Net.peer_for_key(CombatUtil.key_of(ch))
	if (local_ctrl is bool and local_ctrl) or peer == 0:
		if ch.has_method("apply_knockback"):
			ch.apply_knockback(velocity_px)
	else:
		Net.send_to(peer, "Knockback", {"velocity": velocity_px})


# --- handlers de red --------------------------------------------------------

func _on_fire(peer_id: int, args: Array) -> void:
	if args.size() < 1 or not (args[0] is Array):
		return
	var ch = _char_for_peer(peer_id)
	if ch:
		fire(ch, args[0])


func _on_aim(peer_id: int, args: Array) -> void:
	if args.size() < 1 or not _valid_angle(args[0]):
		return
	var now := _now()
	if now - float(_last_aim.get(peer_id, 0.0)) < AIM_THROTTLE:
		return
	_last_aim[peer_id] = now
	var ch = _char_for_peer(peer_id)
	if ch:
		set_aim(ch, float(args[0]))


func _on_reload(peer_id: int, _args: Array) -> void:
	var ch = _char_for_peer(peer_id)
	if ch:
		reload(ch)


func _on_grenade(peer_id: int, args: Array) -> void:
	if args.size() < 1 or not _valid_angle(args[0]):
		return
	var ch = _char_for_peer(peer_id)
	if ch:
		throw_grenade(ch, float(args[0]))


# --- API (humanos y bots) ---------------------------------------------------

func set_aim(ch, angle: float) -> void:
	if ch and _valid_angle(angle):
		ch.set_attr("Aim", wrapf(angle, -PI, PI))


func can_fire(ch) -> bool:
	if not _phase_allows_fire() or not CombatUtil.is_alive(ch):
		return false
	if ch.get_attr("Reloading", false):
		return false
	var w := Data.get_weapon(_weapon_id(ch))
	var key := CombatUtil.key_of(ch)
	if _last_fire.has(key) and _now() - float(_last_fire[key]) < float(w["fire_rate"]):
		return false
	return int(ch.get_attr("Ammo", 0)) > 0


func reload(ch) -> void:
	if not CombatUtil.is_alive(ch) or ch.get_attr("Reloading", false):
		return
	var w := Data.get_weapon(_weapon_id(ch))
	var max_ammo := int(ch.get_attr("MaxAmmo", w["mag_size"]))
	if int(ch.get_attr("Ammo", 0)) >= max_ammo:
		return
	ch.set_attr("Reloading", true)
	_reloads[CombatUtil.key_of(ch)] = {"at": _now() + float(w["reload_time"]), "node": ch}


## angles: un ángulo por perdigón, ya con dispersión. Devuelve true si disparó.
func fire(ch, angles: Array) -> bool:
	if not _phase_allows_fire() or not CombatUtil.is_alive(ch):
		return false
	if ch.get_attr("Reloading", false):
		return false
	var wid := _weapon_id(ch)
	var w := Data.get_weapon(wid)
	var key := CombatUtil.key_of(ch)
	var now := _now()
	if _last_fire.has(key) and now - float(_last_fire[key]) < float(w["fire_rate"]) * 0.85:
		return false
	var ammo := int(ch.get_attr("Ammo", 0))
	if ammo <= 0:
		reload(ch)
		return false
	_last_fire[key] = now
	ammo -= 1
	ch.set_attr("Ammo", ammo)
	# disparar quita la protección de aparición
	if float(ch.get_attr("ProtectedUntil", 0.0)) > Net.server_time():
		ch.set_attr("ProtectedUntil", 0.0)

	var team := CombatUtil.team_of(ch)
	var shoulder := CombatUtil.shoulder(ch)
	var attacker := attacker_info(ch)
	var sent: Array = []
	var n := mini(angles.size(), int(w["pellets"]))
	for i in n:
		var a = angles[i]
		if not _valid_angle(a):
			continue
		var angle := float(a)
		sent.append(angle)
		_projectiles.append({
			"pos": shoulder,
			"dir": GC.angle_to_dir(angle),
			"speed": float(w["projectile_speed"]) * GC.STUD,
			"remaining": (float(w["range"]) + GC.CHARACTER["muzzle_distance"]) * GC.STUD,
			"radius": float(w["hit_radius"]) * GC.STUD,
			"team": team,
			"weapon_id": wid,
			"attacker": attacker,
		})
	if sent.is_empty():
		return false
	var aim = ch.get_attr("Aim", sent[0])
	var origin := CombatUtil.muzzle(ch, float(aim) if _valid_angle(aim) else float(sent[0]))
	Net.broadcast_unreliable("Projectile", {
		"shooter": key, "weapon": wid, "origin": origin, "angles": sent, "team": team,
	})
	if ammo <= 0:
		reload(ch)
	return true


func throw_grenade(ch, angle: float) -> bool:
	if not _phase_allows_fire() or not CombatUtil.is_alive(ch) or not _valid_angle(angle):
		return false
	var g: Dictionary = Data.GRENADE
	var count := int(ch.get_attr("Grenades", 0))
	var key := CombatUtil.key_of(ch)
	var now := _now()
	if count <= 0 or (_last_grenade.has(key) and now - float(_last_grenade[key]) < float(g["cooldown"])):
		return false
	_last_grenade[key] = now
	ch.set_attr("Grenades", count - 1)
	var pos := CombatUtil.shoulder(ch)
	var body_vel := Vector2.ZERO
	var v = ch.get("velocity")
	if v is Vector2:
		body_vel = v
	var vel := GC.angle_to_dir(angle) * float(g["throw_speed"]) * GC.STUD \
		+ Vector2(0.0, -float(g["up_boost"]) * GC.STUD) + Vector2(body_vel.x * 0.4, 0.0)
	_next_grenade_id += 1
	var team := CombatUtil.team_of(ch)
	_grenades.append({
		"id": _next_grenade_id, "pos": pos, "vel": vel, "age": 0.0, "team": team,
		"attacker": attacker_info(ch, str(g["display"])),
	})
	Net.broadcast("GrenadeThrown", {"id": _next_grenade_id, "origin": pos, "velocity": vel, "team": team, "thrower": key})
	return true


## Daño a un personaje. info: {attacker_key, attacker_team, attacker_name, weapon,
## headshot, position, burn, knockback (Vector2 px/s)}
func damage(victim, amount: float, info: Dictionary = {}) -> void:
	if not damage_enabled() or not CombatUtil.is_alive(victim):
		return
	if float(victim.get_attr("ProtectedUntil", 0.0)) > Net.server_time():
		return
	var vkey := CombatUtil.key_of(victim)
	var headshot: bool = info.get("headshot", false)
	var burn: bool = info.get("burn", false)
	var akey: String = str(info.get("attacker_key", ""))
	var ateam: String = str(info.get("attacker_team", ""))
	var weapon: String = str(info.get("weapon", ""))
	var pos = info.get("position", CombatUtil.shoulder(victim))
	if akey != "":
		_last_attacker[vkey] = {
			"key": akey, "team": ateam, "weapon": weapon,
			"name": str(info.get("attacker_name", _name_for_key(akey))),
			"headshot": headshot,
		}
	var hp := float(victim.get_attr("Health", 100.0)) - amount
	victim.set_attr("Health", maxf(0.0, hp))
	if akey != "" and amount > 0.0 and not burn:
		victim.set_attr("LastHitBy", akey)
	ServerEvents.damaged.emit(victim, amount, {
		"victim_key": vkey, "victim_team": CombatUtil.team_of(victim),
		"attacker_key": akey, "attacker_team": ateam, "amount": amount,
		"weapon": weapon, "headshot": headshot, "position": pos, "burn": burn,
	})
	var killed := hp <= 0.0
	Net.broadcast("Hit", {
		"victim": vkey, "attacker": akey, "amount": amount, "headshot": headshot,
		"position": pos, "killed": killed, "burn": burn,
	})
	var kb = info.get("knockback", null)
	if kb is Vector2 and not killed:
		apply_knockback(victim, kb)
	if killed:
		_kill(victim, headshot, pos)


func _name_for_key(key: String) -> String:
	var ch = G.get_character(key)
	if ch:
		return CombatUtil.display_name(ch)
	return str(MatchState.get_combatant(key).get("Name", key))


func _kill(victim, headshot: bool, pos) -> void:
	var vkey := CombatUtil.key_of(victim)
	var vteam := CombatUtil.team_of(victim)
	victim.set_attr("Health", 0.0)
	victim.set_attr("Dead", true)
	victim.set_attr("Burning", false)
	victim.set_attr("Reloading", false)
	var killer: Dictionary = _last_attacker.get(vkey, {})
	_last_attacker.erase(vkey)
	_burning.erase(vkey)
	_reloads.erase(vkey)
	_last_fire.erase(vkey)
	var loadout = G.system("Loadout")
	if loadout:
		loadout.add_stat(vkey, "Deaths")
	MatchState.set_var("TotalDeaths", int(MatchState.get_var("TotalDeaths", 0)) + 1)
	var kkey: String = str(killer.get("key", ""))
	var kteam: String = str(killer.get("team", ""))
	if kkey != "" and kteam != vteam and loadout:
		loadout.add_stat(kkey, "Kills")
		if headshot:
			loadout.add_stat(kkey, "Headshots")
			loadout.add_money(kkey, int(GC.MATCH["kill_reward"]) + int(GC.MATCH["headshot_bonus"]), "TIRO A LA CABEZA")
		else:
			loadout.add_money(kkey, int(GC.MATCH["kill_reward"]), "BAJA ENEMIGA")
	ServerEvents.killed.emit({
		"victim_key": vkey, "victim_team": vteam,
		"killer_key": kkey, "killer_team": kteam,
		"weapon": str(killer.get("weapon", "")), "headshot": headshot,
		"position": pos, "victim": victim,
	})
	Net.broadcast("KillFeed", {
		"killer": str(killer.get("name", "")), "killer_team": kteam,
		"victim": CombatUtil.display_name(victim), "victim_team": vteam,
		"weapon": str(killer.get("weapon", "")), "headshot": headshot,
		"killer_key": kkey, "victim_key": vkey,
	})


func _ignite(victim, burn: Dictionary, attacker: Dictionary) -> void:
	if not damage_enabled() or not CombatUtil.is_alive(victim):
		return
	if float(victim.get_attr("ProtectedUntil", 0.0)) > Net.server_time():
		return
	var key := CombatUtil.key_of(victim)
	var now := _now()
	var s: Dictionary = _burning.get(key, {})
	if s.is_empty():
		_burning[key] = {
			"expires": now + float(burn["duration"]), "next_tick": now + float(burn["interval"]),
			"data": burn, "attacker": attacker,
		}
		victim.set_attr("Burning", true)
	else:
		s["expires"] = now + float(burn["duration"])
		s["attacker"] = attacker
		s["data"] = burn


# --- estructuras ------------------------------------------------------------

func _damage_block(cell: Vector2i, amount: float, team: String, key: String) -> void:
	if not damage_enabled() or G.map == null or not G.map.has_method("damage_cell"):
		return
	if G.map.has_method("is_built") and not G.map.is_built(cell.x, cell.y):
		return
	if G.map.has_method("get_cell"):
		var c = G.map.get_cell(cell.x, cell.y)
		if c is Dictionary and (c.is_empty() or c.get("static", false) or str(c.get("team", "")) == team):
			return
	# map_grid.damage_cell ya emite structure_damaged/destroyed y los eventos Structure/BlockRemoved
	G.map.damage_cell(cell, amount, team, key)


func _damage_structure(node, amount: float, team: String, key: String) -> void:
	if not damage_enabled() or not is_instance_valid(node):
		return
	if str(node.get("team")) == team:
		return
	if node.has_method("apply_damage"):
		node.apply_damage(amount, team, key)


func _structure_at(point: Vector2, radius: float, team: String):
	for s in get_tree().get_nodes_in_group("structures"):
		if not is_instance_valid(s) or str(s.get("team")) == team:
			continue
		if s.has_method("hit_test") and s.hit_test(point, radius):
			return s
	return null


# --- simulación --------------------------------------------------------------

func _physics_process(dt: float) -> void:
	if not Net.is_server():
		return
	_step_projectiles(dt)
	_step_grenades(dt)
	_step_burning()
	_step_reloads()


func _enemy_candidates(team: String, a: Vector2, b: Vector2, pad: float) -> Array:
	var out: Array = []
	var box := Rect2(a, Vector2.ZERO).expand(b).grow(pad)
	for ch in CombatUtil.get_characters():
		if CombatUtil.team_of(ch) == team or not CombatUtil.is_alive(ch):
			continue
		if box.has_point(CombatUtil.shoulder(ch)):
			out.append(ch)
	return out


func _step_projectiles(dt: float) -> void:
	var i := _projectiles.size() - 1
	while i >= 0:
		var p: Dictionary = _projectiles[i]
		var dist: float = minf(p["speed"] * dt, p["remaining"])
		var from: Vector2 = p["pos"]
		var to: Vector2 = from + p["dir"] * dist
		var remove := false
		# 1) mapa
		var mh := CombatUtil.map_hit(from, to, p["team"])
		var wall_dist := dist
		if mh.get("hit", false):
			var hp: Vector2 = mh.get("position", to)
			wall_dist = from.distance_to(hp)
		# 2) personajes y estructuras a lo largo del tramo libre
		var cands := _enemy_candidates(p["team"], from, from + p["dir"] * wall_dist, 6.0 * GC.STUD)
		var has_structs := not get_tree().get_nodes_in_group("structures").is_empty()
		var hit_done := false
		if not cands.is_empty() or has_structs:
			var steps := int(ceil(wall_dist / SAMPLE_STEP))
			for s in range(steps + 1):
				var point: Vector2 = from + p["dir"] * minf(s * SAMPLE_STEP, wall_dist)
				for ch in cands:
					var part: String = ch.hit_test(point, p["radius"]) if ch.has_method("hit_test") else ""
					if part != "":
						_projectile_hits_char(p, ch, part, point)
						hit_done = true
						break
				if hit_done:
					break
				if has_structs:
					var st = _structure_at(point, p["radius"], p["team"])
					if st:
						var w := Data.get_weapon(p["weapon_id"])
						_damage_structure(st, float(w["damage"]) * float(w["block_damage"]), p["team"], p["attacker"]["key"])
						hit_done = true
						break
		if hit_done:
			remove = true
		elif mh.get("hit", false):
			var cell = mh.get("cell", null)
			if cell is Vector2i:
				var w2 := Data.get_weapon(p["weapon_id"])
				_damage_block(cell, float(w2["damage"]) * float(w2["block_damage"]), p["team"], p["attacker"]["key"])
			remove = true
		else:
			p["pos"] = to
			p["remaining"] = p["remaining"] - dist
			remove = p["remaining"] <= 0.0
		if remove:
			_projectiles[i] = _projectiles[_projectiles.size() - 1]
			_projectiles.pop_back()
		i -= 1


func _projectile_hits_char(p: Dictionary, ch, part: String, point: Vector2) -> void:
	var w := Data.get_weapon(p["weapon_id"])
	var headshot: bool = bool(w.get("headshot", false)) and part == "head"
	var kbs: float = float(w.get("knockback", 0.0))
	var dir: Vector2 = p["dir"]
	var kb := (dir * kbs + Vector2(0.0, -kbs * 0.35)) * GC.STUD
	var att: Dictionary = p["attacker"]
	damage(ch, 1000.0 if headshot else float(w["damage"]), {
		"attacker_key": att["key"], "attacker_team": att["team"], "attacker_name": att["name"],
		"weapon": att["weapon"], "headshot": headshot, "position": point, "knockback": kb,
	})
	if w.has("burn"):
		_ignite(ch, w["burn"], att)


func _step_grenades(dt: float) -> void:
	var g: Dictionary = Data.GRENADE
	var grav: float = float(g["gravity"]) * GC.STUD
	var i := _grenades.size() - 1
	while i >= 0:
		var n: Dictionary = _grenades[i]
		n["age"] = n["age"] + dt
		var vel: Vector2 = n["vel"] + Vector2(0.0, grav * dt)
		var pos: Vector2 = n["pos"]
		var step := vel * dt
		var explode: bool = n["age"] >= float(g["fuse"])
		# contacto con enemigo vivo
		for ch in _enemy_candidates(n["team"], pos, pos + step, 6.0 * GC.STUD):
			if ch.has_method("hit_test") and ch.hit_test(pos + step, GRENADE_RADIUS_PX) != "":
				explode = true
				break
		var mh := CombatUtil.map_hit(pos, pos + step, n["team"])
		if mh.get("hit", false):
			var hp: Vector2 = mh.get("position", pos + step)
			var normal := CombatUtil.hit_normal(hp, mh.get("cell", null), step)
			vel = (vel - 2.0 * vel.dot(normal) * normal) * float(g["bounce"])
			pos = hp + normal * 2.0
		else:
			pos += step
		n["vel"] = vel
		n["pos"] = pos
		if explode or pos.y > 40.0 * GC.STUD:
			_grenades[i] = _grenades[_grenades.size() - 1]
			_grenades.pop_back()
			Net.broadcast("GrenadeThrown", {"id": n["id"], "remove": true})
			explode_at(pos, n["attacker"], float(g["radius"]), float(g["damage"]), float(g["block_damage"]), float(g["knockback"]))
		i -= 1


## Explosión (radio, daño y empuje en studs como en Data.GRENADE). Empuja al lanzador sin herirlo.
func explode_at(pos: Vector2, attacker: Dictionary, radius: float, dmg: float, block_dmg: float, knockback: float) -> void:
	var r_px := radius * GC.STUD
	Net.broadcast("Explosion", {"position": pos, "radius_px": r_px})
	var team: String = str(attacker.get("team", ""))
	var akey: String = str(attacker.get("key", ""))
	for ch in CombatUtil.get_characters():
		if not CombatUtil.is_alive(ch):
			continue
		var c := CombatUtil.shoulder(ch)
		var offset := c - pos
		var d := offset.length()
		if d >= r_px:
			continue
		var falloff := 1.0 - (d / r_px) * 0.7
		var dir := offset / d if d > 0.08 else Vector2(0, -1)
		var push := (dir + Vector2(0.0, -0.6)).normalized() * knockback * falloff * GC.STUD
		if CombatUtil.team_of(ch) != team:
			damage(ch, dmg * falloff, {
				"attacker_key": akey, "attacker_team": team, "attacker_name": attacker.get("name", ""),
				"weapon": attacker.get("weapon", ""), "headshot": false, "position": c, "knockback": push,
			})
		elif CombatUtil.key_of(ch) == akey:
			apply_knockback(ch, push)  # salto con granada, sin daño propio
	# bloques construidos
	var br := r_px * 0.75
	var c0 := GC.world_to_cell(pos - Vector2(br, -br))
	var c1 := GC.world_to_cell(pos + Vector2(br, -br))
	for col in range(mini(c0.x, c1.x), maxi(c0.x, c1.x) + 1):
		for row in range(mini(c0.y, c1.y), maxi(c0.y, c1.y) + 1):
			var cc := GC.cell_center(col, row)
			var dd := cc.distance_to(pos)
			if dd > br + GC.BLOCK * 0.5:
				continue
			var f := clampf(1.0 - dd / (r_px * 0.9), 0.25, 1.0)
			_damage_block(Vector2i(col, row), block_dmg * f, team, akey)
	# estructuras (depósitos)
	for s in get_tree().get_nodes_in_group("structures"):
		if not is_instance_valid(s) or str(s.get("team")) == team:
			continue
		if s.has_method("hit_test") and s.hit_test(pos, br):
			var sp: Vector2 = s.global_position if s is Node2D else pos
			var f2 := clampf(1.0 - sp.distance_to(pos) / (r_px * 0.9), 0.25, 1.0)
			_damage_structure(s, block_dmg * f2, team, akey)


func _step_burning() -> void:
	var now := _now()
	for key in _burning.keys():
		var s: Dictionary = _burning[key]
		var ch = G.get_character(key)
		if not CombatUtil.is_alive(ch) or now >= float(s["expires"]):
			_burning.erase(key)
			if ch and is_instance_valid(ch):
				ch.set_attr("Burning", false)
		elif now >= float(s["next_tick"]):
			var data: Dictionary = s["data"]
			s["next_tick"] = float(s["next_tick"]) + float(data["interval"])
			var att: Dictionary = s["attacker"]
			damage(ch, float(data["damage"]), {
				"attacker_key": att["key"], "attacker_team": att["team"], "attacker_name": att["name"],
				"weapon": att["weapon"], "headshot": false, "position": CombatUtil.shoulder(ch), "burn": true,
			})


func _step_reloads() -> void:
	var now := _now()
	for key in _reloads.keys():
		var r: Dictionary = _reloads[key]
		var ch = G.get_character(key)
		if ch == null or ch != r["node"] or not CombatUtil.is_alive(ch):
			_reloads.erase(key)
			if ch and is_instance_valid(ch):
				ch.set_attr("Reloading", false)
			continue
		if now >= float(r["at"]):
			_reloads.erase(key)
			var w := Data.get_weapon(_weapon_id(ch))
			ch.set_attr("Ammo", int(ch.get_attr("MaxAmmo", w["mag_size"])))
			ch.set_attr("Reloading", false)
