extends Node
## ObjectiveSystem: objetivos de cada ronda.
## Cada misión crea sus marcadores (diccionarios que se replican con el evento
## "ObjMarkers" y dibuja ObjectiveRenderer) y lleva el progreso de cada equipo
## (0..1) en MatchState.Progress<Equipo>.
##
## Las coordenadas de diseño están en studs (Y hacia arriba) y se
## convierten a píxeles con GC.studs_to_px. Las posiciones de los marcadores
## que viajan por la red están en píxeles.

const TEAMS := ["USA", "Vietnam"]

const HILL := {"min_x": -34.0, "max_x": 34.0, "min_y": 0.0, "max_y": 30.0, "hold_time": 80.0}
const RADIO_POINTS := [
	Vector2(-100, 16), Vector2(100, 16), Vector2(-40, 16), Vector2(40, 16),
	Vector2(0, 12), Vector2(-150, 0), Vector2(150, 0), Vector2(-52, 24), Vector2(52, 24),
]
const RADIO_HACK_TIME := 7.0
const RADIO_SIGNALS := 3
const RADIO_COOLDOWN := 4.0
const CTF_CAPTURES := 2
const FLAG_HOME_X := 241.0
const FLAG_RETURN_TIME := 20.0
const FLAG_SPEED_MULT := 0.9
const VIP_HEALTH := 260.0
const VIP_HOLD_X := 222.0
const DEPOT_HEALTH := 1600.0
const DEPOT_X := 249.5
const DEPOT_Y := 2.1
const DEPOT_SIZE := Vector2(4.4, 4.2)  # studs
const DEPOT_EXPLOSION_RADIUS := 26.0   # studs
const MARKER_INTERVAL := 0.1           # ObjMarkers a 10 Hz

var _active := ""          # id de la misión en curso ("" = ninguna)
var _data := {}
var _winner := ""
var _progress := {"USA": 0.0, "Vietnam": 0.0}
var _marker_accum := 0.0
var _clock := 0.0
var _last_sig := ""
var _last_full: Array = []


# --- ciclo de vida -------------------------------------------------------

func init_system() -> void:
	_active = ""
	_data = {}
	_winner = ""
	_clear_objective_nodes()


func start_system() -> void:
	ServerEvents.damaged.connect(_on_damaged)
	ServerEvents.killed.connect(_on_killed)
	ServerEvents.character_ready.connect(_on_character_ready)
	Net.peer_joined.connect(_on_peer_joined)


func _exit_tree() -> void:
	_clear_objective_nodes()


func _physics_process(delta: float) -> void:
	if not Net.is_server():
		return
	_clock += delta
	if _active != "" and _winner == "" and MatchState.phase() == "Round":
		match _active:
			"Assassination":
				_assassination_step(delta)
			"KingOfHill":
				_hill_step(delta)
			"Radio":
				_radio_step(delta)
			"CTF":
				_ctf_step(delta)
	_marker_accum += delta
	if _marker_accum >= MARKER_INTERVAL:
		_marker_accum = 0.0
		_send_markers(false)


# --- API pública ---------------------------------------------------------

func start_mission(mission_id: String) -> void:
	stop_mission()
	_active = mission_id if mission_id in GC.MISSIONS else ""
	_data = {}
	_winner = ""
	for t in TEAMS:
		_set_progress(t, 0.0)
	match _active:
		"Assassination":
			_assassination_start()
		"KingOfHill":
			_hill_start()
		"Radio":
			_radio_start()
		"CTF":
			_ctf_start()
		"Demolition":
			_demolition_start()
	_send_markers(true)


func stop_mission() -> void:
	match _active:
		"Assassination":
			_assassination_stop()
		"CTF":
			_ctf_stop()
	_active = ""
	_data = {}
	_clear_objective_nodes()
	for v in ["SignalsUSA", "SignalsVietnam", "CapturesUSA", "CapturesVietnam"]:
		MatchState.set_var(v, 0)
	_send_markers(true)


func get_winner() -> String:
	return _winner


func get_progress(team: String) -> float:
	return float(_progress.get(team, 0.0))


func get_mission() -> String:
	return _active


## Estado actual de los marcadores (lo mismo que viaja en "ObjMarkers").
func get_markers() -> Array:
	return _build_markers()


## A dónde tiene que ir un bot (px). role: "attack" | "defend".
func get_bot_target(ch: Node, role: String) -> Vector2:
	var goal := get_bot_goal(ch, role)
	return goal.get("position", _fallback_target(ch))


## Versión completa para bots: {valid, position: Vector2 px, hold: bool, zone: bool,
## priority: String (clave del personaje a perseguir), structure: Node (depósito a atacar)}.
## Si no hay objetivo (valid = false) position es un punto razonable hacia el frente.
func get_bot_goal(ch: Node, role: String) -> Dictionary:
	var out := {"valid": false, "position": _fallback_target(ch), "hold": false, "zone": false,
		"priority": "", "structure": null}
	if _active == "" or ch == null or not is_instance_valid(ch):
		return out
	var defend := role.to_lower() == "defend"
	var g := {}
	match _active:
		"Assassination":
			g = _assassination_goal(ch)
		"KingOfHill":
			g = _hill_goal(ch)
		"Radio":
			g = _radio_goal(ch)
		"CTF":
			g = _ctf_goal(ch, defend)
		"Demolition":
			g = _demolition_goal(ch, defend)
	if g.is_empty():
		return out
	out.merge(g, true)
	out["valid"] = true
	return out


# --- utilidades ----------------------------------------------------------

## Reloj interno del sistema (avanza en _physics_process).
func _now() -> float:
	return _clock


func _side(team: String) -> int:
	return int(GC.TEAM_INFO[team]["side"])


func _display(team: String) -> String:
	return String(GC.TEAM_INFO[team]["display"]) if GC.TEAM_INFO.has(team) else team


func _reward() -> int:
	return int(GC.MATCH["objective_reward"])


func _set_progress(team: String, value: float) -> void:
	_progress[team] = clampf(value, 0.0, 1.0)
	MatchState.set_var("Progress" + team, _progress[team])


func _obj_event(kind: String, team: String, text: String, extra: Dictionary = {}) -> void:
	var ev := {"kind": kind, "team": team, "text": text}
	ev.merge(extra, true)
	Net.broadcast("ObjectiveEvent", ev)


func _intercom() -> Node:
	return G.system("Intercom")


func _say_team(team: String, key: String, throttle: float = 0.0) -> void:
	var ic := _intercom()
	if ic:
		ic.team(team, key, throttle)


func _say_both(key: String, throttle: float = 0.0) -> void:
	var ic := _intercom()
	if ic:
		ic.both(key, throttle)


func _add_money(key: String, amount: int, reason: String) -> void:
	var lo := G.system("Loadout")
	if lo and key != "":
		lo.add_money(key, amount, reason)


func _reward_chars(chars: Array, amount: int, reason: String) -> void:
	for ch in chars:
		_add_money(_key_of(ch), amount, reason)


func _all_chars() -> Array:
	var out := []
	for c in G.all_characters():
		if c != null and is_instance_valid(c) and not c.is_queued_for_deletion() and c.has_method("is_alive"):
			out.append(c)
	return out


func _alive(ch) -> bool:
	return ch != null and is_instance_valid(ch) and not ch.is_queued_for_deletion() \
		and ch.has_method("is_alive") and ch.is_alive()


func _alive_of(team: String) -> Array:
	var out := []
	for c in _all_chars():
		if c.team() == team and c.is_alive():
			out.append(c)
	return out


func _key_of(ch) -> String:
	if ch == null or not is_instance_valid(ch):
		return ""
	return ch.key() if ch.has_method("key") else String(ch.name)


func _char(key: String) -> Node:
	if key == "":
		return null
	var c := G.get_character(key)
	if c == null or c.is_queued_for_deletion():
		return null
	return c


func _feet_studs(ch) -> Vector2:
	return GC.px_to_studs(ch.feet_position())


## Centro del cuerpo en studs.
func _root_studs(ch) -> Vector2:
	return _feet_studs(ch) + Vector2(0, GC.CHARACTER["feet_offset"])


func _name_of(ch) -> String:
	var n = ch.get_attr("DisplayName", "")
	return String(n) if n != null and String(n) != "" else _key_of(ch)


## Suelo debajo de una posición (studs). Busca la primera celda sólida hacia abajo
## (60 studs como el raycast original); si no hay, Y = 0.
func _ground_below(pos_studs: Vector2) -> Vector2:
	var map := G.map
	if map == null or not map.has_method("is_solid"):
		return Vector2(pos_studs.x, 0.0)
	var cell := GC.world_to_cell(GC.studs_to_px(pos_studs + Vector2(0, 1)))
	for i in int(60.0 / GC.BLOCK_STUDS) + 1:
		var row := cell.y - i
		if row < -1:
			# debajo de la fila -1 está la losa continua
			return Vector2(pos_studs.x, -2 * GC.BLOCK_STUDS)
		if map.is_solid(cell.x, row):
			return Vector2(pos_studs.x, row * GC.BLOCK_STUDS)
	return Vector2(pos_studs.x, 0.0)


func _clear_objective_nodes() -> void:
	if G.objectives == null:
		return
	for c in G.objectives.get_children():
		if c.is_in_group("objective_depot"):
			c.remove_from_group("structures")
			c.queue_free()


# ------------------------------------------------------------ Asesinato

func _pick_vip(team: String) -> void:
	var candidates := _alive_of(team)
	if candidates.is_empty():
		return
	var vip: Node = candidates[randi() % candidates.size()]
	var key := _key_of(vip)
	_data["VIP"][team] = key
	_apply_vip(vip)
	_say_team(team, "VIPTeam")
	var peer := Net.peer_for_key(key)
	if peer > 0:
		get_tree().create_timer(4.0).timeout.connect(func():
			var ic := _intercom()
			if ic and _active == "Assassination":
				ic.player(peer, "VIPYou"))
	_obj_event("VIP", team, "%s es el objetivo de %s" % [_name_of(vip), _display(team)],
		{"action": "Marked", "key": key})


func _apply_vip(vip: Node) -> void:
	vip.set_attr("VIP", true)
	vip.set_attr("MaxHealth", VIP_HEALTH)
	vip.set_attr("Health", VIP_HEALTH)


func _assassination_start() -> void:
	_data["VIP"] = {"USA": "", "Vietnam": ""}
	_data["Damage"] = {"USA": 0.0, "Vietnam": 0.0}
	for t in TEAMS:
		_pick_vip(t)


func _assassination_step(_dt: float) -> void:
	for t in TEAMS:
		var key: String = _data["VIP"][t]
		if _char(key) == null:
			_pick_vip(t)


func _assassination_stop() -> void:
	for t in TEAMS:
		var c := _char(String(_data.get("VIP", {}).get(t, "")))
		if c:
			c.set_attr("VIP", false)


func _assassination_goal(ch: Node) -> Dictionary:
	var team: String = ch.team()
	if ch.get_attr("VIP", false):
		return {"position": GC.studs_to_px(Vector2(_side(team) * VIP_HOLD_X, 0)), "hold": true}
	var enemy_vip := _char(String(_data["VIP"].get(GC.enemy(team), "")))
	if _alive(enemy_vip):
		return {"position": enemy_vip.feet_position(), "priority": _key_of(enemy_vip)}
	return {}


# ------------------------------------------------------ Rey de la colina

func _hill_start() -> void:
	_data["Owner"] = ""
	_data["MarkerOwner"] = ""
	_data["Contested"] = false
	_data["RewardStep"] = {"USA": 0, "Vietnam": 0}


func _inside_hill(ch) -> bool:
	if not _alive(ch):
		return false
	var p := _root_studs(ch)
	return p.x >= HILL["min_x"] and p.x <= HILL["max_x"] and p.y >= HILL["min_y"] and p.y <= HILL["max_y"] + 4.0


func _hill_step(dt: float) -> void:
	var present := {"USA": [], "Vietnam": []}
	for t in TEAMS:
		for ch in _alive_of(t):
			if _inside_hill(ch):
				present[t].append(ch)
	var a: bool = not present["USA"].is_empty()
	var b: bool = not present["Vietnam"].is_empty()
	var owner := ""
	if a and not b:
		owner = "USA"
	elif b and not a:
		owner = "Vietnam"
	var was_contested: bool = _data["Contested"]
	_data["Contested"] = a and b
	_data["MarkerOwner"] = owner if owner != "" else ("Contested" if a and b else "")
	if a and b and not was_contested:
		_obj_event("Hill", "", "¡La colina está en disputa!", {"action": "Contested"})
	if owner != "":
		if _data["Owner"] != owner:
			_say_team(owner, "HillOurs", 10.0)
			_say_team(GC.enemy(owner), "HillTheirs", 10.0)
			_obj_event("Hill", owner, _display(owner) + " controla la colina", {"action": "Taken"})
		var speed := 1.0 + mini(present[owner].size() - 1, 2) * 0.25
		_set_progress(owner, _progress[owner] + dt * speed / HILL["hold_time"])
		var step := int(floor(_progress[owner] * 10.0))
		if step > int(_data["RewardStep"][owner]):
			_data["RewardStep"][owner] = step
			_reward_chars(present[owner], 40, "CONTROL DE COLINA")
		if _progress[owner] >= 1.0:
			_winner = owner
	_data["Owner"] = owner


func _hill_goal(ch: Node) -> Dictionary:
	# El original sortea un X en ±8 studs en cada consulta; acá es fijo por bot
	# (y cambia cada 6 s) para que no tiemble el destino.
	var k := _key_of(ch)
	var seed_val := hash(k + str(int(_now() / 6.0)))
	var off := (float(absi(seed_val) % 1000) / 1000.0 - 0.5) * 16.0
	return {"position": GC.studs_to_px(Vector2(off, 12)), "hold": _inside_hill(ch), "zone": true}


# --------------------------------------------------------------- Radio

func _move_radio() -> void:
	var index := 0
	var prev := int(_data.get("Index", -1))
	while true:
		index = randi() % RADIO_POINTS.size()
		if index != prev or RADIO_POINTS.size() == 1:
			break
	_data["Index"] = index
	_data["Pos"] = RADIO_POINTS[index]
	_data["Active"] = true
	_data["Hack"] = {"USA": 0.0, "Vietnam": 0.0}
	_say_both("RadioNew", 5.0)
	_obj_event("Radio", "", "Nueva señal de radio detectada",
		{"action": "New", "position": GC.studs_to_px(RADIO_POINTS[index])})


func _radio_start() -> void:
	_data["Signals"] = {"USA": 0, "Vietnam": 0}
	_data["Hack"] = {"USA": 0.0, "Vietnam": 0.0}
	_data["Pos"] = RADIO_POINTS[0]
	_data["Contested"] = false
	_data["CooldownUntil"] = 0.0
	_move_radio()
	MatchState.set_var("SignalsUSA", 0)
	MatchState.set_var("SignalsVietnam", 0)


func _near_radio(ch) -> bool:
	if not _alive(ch):
		return false
	var d := _root_studs(ch) - Vector2(_data["Pos"])
	return absf(d.x) < 6.0 and d.y > -2.0 and d.y < 9.0


func _radio_step(dt: float) -> void:
	if not _data["Active"]:
		if _now() >= float(_data["CooldownUntil"]):
			_move_radio()
		return
	var present := {"USA": [], "Vietnam": []}
	for t in TEAMS:
		for ch in _alive_of(t):
			if _near_radio(ch):
				present[t].append(ch)
	var a: bool = not present["USA"].is_empty()
	var b: bool = not present["Vietnam"].is_empty()
	var hack: Dictionary = _data["Hack"]
	if a and not b:
		hack["USA"] += dt / RADIO_HACK_TIME
		hack["Vietnam"] = maxf(0.0, hack["Vietnam"] - dt / 14.0)
	elif b and not a:
		hack["Vietnam"] += dt / RADIO_HACK_TIME
		hack["USA"] = maxf(0.0, hack["USA"] - dt / 14.0)
	elif not a and not b:
		hack["USA"] = maxf(0.0, hack["USA"] - dt / 20.0)
		hack["Vietnam"] = maxf(0.0, hack["Vietnam"] - dt / 20.0)
	_data["Contested"] = a and b
	var signals: Dictionary = _data["Signals"]
	for t in TEAMS:
		hack = _data["Hack"]
		if hack[t] >= 1.0:
			signals[t] += 1
			_reward_chars(present[t], _reward(), "SEÑAL INTERCEPTADA")
			_say_team(t, "RadioOurs")
			_say_team(GC.enemy(t), "RadioTheirs")
			_obj_event("Radio", t, _display(t) + " interceptó una señal",
				{"action": "Hacked", "signals": signals[t]})
			_data["Hack"] = {"USA": 0.0, "Vietnam": 0.0}
			_data["Active"] = false
			_data["CooldownUntil"] = _now() + RADIO_COOLDOWN
			if signals[t] >= RADIO_SIGNALS:
				_winner = t
		_set_progress(t, (signals[t] + minf(float(_data["Hack"][t]), 0.99)) / RADIO_SIGNALS)
	MatchState.set_var("SignalsUSA", signals["USA"])
	MatchState.set_var("SignalsVietnam", signals["Vietnam"])


func _radio_goal(ch: Node) -> Dictionary:
	if not _data.get("Active", false):
		return {}
	var k := _key_of(ch)
	var off := (float(absi(hash(k)) % 1000) / 1000.0 - 0.5) * 6.0
	return {"position": GC.studs_to_px(Vector2(_data["Pos"]) + Vector2(off, 2)) , "hold": _near_radio(ch), "zone": true}


# ------------------------------------------------------- Robo de bandera

func _ctf_start() -> void:
	_data["Flags"] = {}
	_data["Captures"] = {"USA": 0, "Vietnam": 0}
	for t in TEAMS:
		var home := Vector2(_side(t) * FLAG_HOME_X, 0)
		_data["Flags"][t] = {"Home": home, "Pos": home, "State": "Home", "Carrier": "", "DroppedAt": -1.0}
	MatchState.set_var("CapturesUSA", 0)
	MatchState.set_var("CapturesVietnam", 0)


func _set_flag(team: String, st: String, carrier: Node = null, pos = null) -> void:
	var f: Dictionary = _data["Flags"][team]
	var old := _char(String(f["Carrier"]))
	if old:
		old.set_attr("CarryingFlag", "")
		old.set_attr("SpeedMult", 1.0)
	f["State"] = st
	f["Carrier"] = _key_of(carrier) if carrier else ""
	if carrier:
		carrier.set_attr("CarryingFlag", team)
		carrier.set_attr("SpeedMult", FLAG_SPEED_MULT)
	f["Pos"] = pos if pos != null else f["Home"]
	f["DroppedAt"] = _now() if st == "Dropped" else -1.0


## Suelta la bandera que lleva un personaje (al morir o desaparecer).
func _drop_flag(team: String, at_studs: Vector2) -> void:
	_set_flag(team, "Dropped", null, _ground_below(at_studs))
	_obj_event("Flag", team, "¡Bandera de %s en el suelo!" % _display(team),
		{"action": "Dropped", "position": GC.studs_to_px(_data["Flags"][team]["Pos"])})


func _near(ch, pos: Vector2, radius: float) -> bool:
	if not _alive(ch):
		return false
	var feet := _feet_studs(ch)
	return absf(feet.x - pos.x) < radius and absf(feet.y - pos.y) < 5.0


func _ctf_step(_dt: float) -> void:
	var flags: Dictionary = _data["Flags"]
	var captures: Dictionary = _data["Captures"]
	for t in TEAMS:
		var f: Dictionary = flags[t]
		var enemy := GC.enemy(t)
		if f["State"] == "Carried":
			var carrier := _char(String(f["Carrier"]))
			if not _alive(carrier):
				var at: Vector2 = f["Pos"]
				if carrier:
					at = _root_studs(carrier)
				_drop_flag(t, at)
			else:
				f["Pos"] = _root_studs(carrier)
				if _near(carrier, flags[enemy]["Home"], 5.0):
					captures[enemy] += 1
					_set_flag(t, "Home")
					_reward_chars([carrier], _reward() * 2, "BANDERA CAPTURADA")
					_say_team(enemy, "FlagScored")
					_say_team(t, "FlagConceded")
					_obj_event("FlagCapture", enemy, _display(enemy) + " capturó la bandera",
						{"action": "Captured", "captures": captures[enemy]})
					if captures[enemy] >= CTF_CAPTURES:
						_winner = enemy
		else:
			# tomar la bandera (enemigos) o devolverla (dueños)
			for ch in _all_chars():
				if _alive(ch) and _near(ch, f["Pos"], 3.5):
					var ct: String = ch.team()
					var carrying = ch.get_attr("CarryingFlag", "")
					if ct == enemy and (carrying == null or String(carrying) == ""):
						_set_flag(t, "Carried", ch)
						_say_team(enemy, "FlagTaken", 6.0)
						_say_team(t, "FlagStolen", 6.0)
						_obj_event("Flag", enemy, "%s robó la bandera de %s" % [_name_of(ch), _display(t)],
							{"action": "Stolen", "flag": t, "key": _key_of(ch)})
						break
					elif ct == t and f["State"] == "Dropped":
						_set_flag(t, "Home")
						_reward_chars([ch], 50, "BANDERA RECUPERADA")
						_obj_event("Flag", t, "Bandera de %s recuperada" % _display(t), {"action": "Recovered"})
						break
			if f["State"] == "Dropped" and float(f["DroppedAt"]) >= 0.0 \
					and _now() - float(f["DroppedAt"]) > FLAG_RETURN_TIME:
				_set_flag(t, "Home")
				_obj_event("Flag", t, "La bandera de %s volvió a su base" % _display(t), {"action": "Returned"})
	for t in TEAMS:
		var carrying := 0.15 if flags[GC.enemy(t)]["State"] == "Carried" else 0.0
		_set_progress(t, minf(0.99, float(captures[t]) / CTF_CAPTURES + carrying))
		if _winner == t:
			_set_progress(t, 1.0)
	MatchState.set_var("CapturesUSA", captures["USA"])
	MatchState.set_var("CapturesVietnam", captures["Vietnam"])


func _ctf_stop() -> void:
	for t in TEAMS:
		var f: Dictionary = _data.get("Flags", {}).get(t, {})
		var c := _char(String(f.get("Carrier", "")))
		if c:
			c.set_attr("CarryingFlag", "")
			c.set_attr("SpeedMult", 1.0)


func _ctf_goal(ch: Node, defend: bool) -> Dictionary:
	var team: String = ch.team()
	var own: Dictionary = _data["Flags"][team]
	var theirs: Dictionary = _data["Flags"][GC.enemy(team)]
	var carrying = ch.get_attr("CarryingFlag", "")
	if carrying != null and String(carrying) != "":
		return {"position": GC.studs_to_px(own["Home"])}
	if defend:
		if own["State"] == "Carried":
			var c := _char(String(own["Carrier"]))
			if _alive(c):
				return {"position": c.feet_position(), "priority": _key_of(c)}
		return {"position": GC.studs_to_px(own["Pos"]), "hold": own["State"] == "Home" and _near(ch, own["Home"], 14.0)}
	if theirs["State"] == "Carried":
		var c2 := _char(String(theirs["Carrier"]))
		return {"position": c2.feet_position()} if _alive(c2) else {}
	return {"position": GC.studs_to_px(theirs["Pos"])}


# ------------------------------------------------------------ Demolición

class Depot extends Node2D:
	## Depósito de azúcar: estructura dañable (grupo "structures").
	## CombatSystem llama hit_test / apply_damage en el servidor.
	var team := ""
	var health := 1600.0
	var max_health := 1600.0
	var destroyed := false
	var size_px := Vector2.ZERO
	var system = null
	var _body: StaticBody2D

	func setup(t: String, center_px: Vector2, size_studs: Vector2, hp: float, sys) -> void:
		team = t
		name = "Depot" + t
		position = center_px
		size_px = size_studs * GC.STUD
		health = hp
		max_health = hp
		system = sys
		add_to_group("structures")
		add_to_group("objective_depot")
		_body = StaticBody2D.new()
		_body.collision_layer = GC.LAYER_STRUCTURE
		_body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size_px
		shape.shape = rect
		_body.add_child(shape)
		add_child(_body)

	func hit_test(point: Vector2, radius_px: float) -> bool:
		if destroyed:
			return false
		var half := size_px * 0.5 + Vector2(radius_px, radius_px)
		var d := point - global_position
		return absf(d.x) <= half.x and absf(d.y) <= half.y

	func apply_damage(amount: float, attacker_team: String, attacker_key: String) -> void:
		if destroyed or amount <= 0.0 or attacker_team == team:
			return
		if MatchState.phase() != "Round":
			return
		var dealt := minf(amount, health)
		health = maxf(0.0, health - amount)
		ServerEvents.structure_damaged.emit(self, dealt, attacker_team, attacker_key)
		if system and is_instance_valid(system):
			system._on_depot_damaged(self, dealt, attacker_team, attacker_key)
		if health <= 0.0:
			destroyed = true
			_body.set_deferred("collision_layer", 0)
			Net.broadcast("Structure", {"kind": "depot", "team": team, "position": global_position, "destroyed": true})
			ServerEvents.structure_destroyed.emit(self, attacker_team, attacker_key)
			if system and is_instance_valid(system):
				system._on_depot_destroyed(self, attacker_team, attacker_key)


func _demolition_start() -> void:
	_data["Depots"] = {}
	_data["Credit"] = {}
	_data["HitNotice"] = {"USA": -100.0, "Vietnam": -100.0}
	for t in TEAMS:
		var d := Depot.new()
		d.setup(t, GC.studs_to_px(Vector2(_side(t) * DEPOT_X, DEPOT_Y)), DEPOT_SIZE, DEPOT_HEALTH, self)
		if G.objectives:
			G.objectives.add_child(d)
		_data["Depots"][t] = d


func _on_depot_damaged(depot: Node, amount: float, _attacker_team: String, attacker_key: String) -> void:
	if _active != "Demolition":
		return
	var team: String = depot.team
	var hp: float = depot.health
	_set_progress(GC.enemy(team), minf(0.99, 1.0 - hp / DEPOT_HEALTH))
	_say_team(team, "DepotHit", 20.0)
	if hp / DEPOT_HEALTH < 0.25:
		_say_team(GC.enemy(team), "DepotEnemyLow", 30.0)
	if _now() - float(_data["HitNotice"][team]) > 6.0 and hp > 0.0:
		_data["HitNotice"][team] = _now()
		_obj_event("Depot", team, "¡Están atacando el depósito de %s!" % _display(team),
			{"action": "Damaged", "health": hp, "max_health": DEPOT_HEALTH})
	if attacker_key != "":
		var credit: Dictionary = _data["Credit"]
		credit[attacker_key] = float(credit.get(attacker_key, 0.0)) + amount
		while credit[attacker_key] >= 200.0:
			credit[attacker_key] -= 200.0
			_add_money(attacker_key, 50, "DAÑO AL DEPÓSITO")


func _on_depot_destroyed(depot: Node, _attacker_team: String, attacker_key: String) -> void:
	if _active != "Demolition" or _winner != "":
		return
	var team: String = depot.team
	_winner = GC.enemy(team)
	_set_progress(_winner, 1.0)
	Net.broadcast("Explosion", {"position": depot.global_position, "radius_px": DEPOT_EXPLOSION_RADIUS * GC.STUD})
	_obj_event("Depot", _winner, "¡El depósito de %s voló por los aires!" % _display(team),
		{"action": "Destroyed", "depot": team})
	if attacker_key != "":
		_add_money(attacker_key, _reward() * 2, "DEPÓSITO DESTRUIDO")


func _demolition_goal(ch: Node, defend: bool) -> Dictionary:
	var team: String = ch.team()
	if defend:
		var own = _data["Depots"].get(team)
		if own and is_instance_valid(own):
			return {"position": own.global_position + Vector2(-_side(team) * 14.0 * GC.STUD, DEPOT_Y * GC.STUD), "hold": true}
		return {}
	var target = _data["Depots"].get(GC.enemy(team))
	if target and is_instance_valid(target) and not target.destroyed:
		return {"position": target.global_position, "structure": target}
	return {}


func _fallback_target(ch: Node) -> Vector2:
	if ch == null or not is_instance_valid(ch) or not ch.has_method("team"):
		return Vector2.ZERO
	# hacia el frente enemigo
	return GC.studs_to_px(Vector2(_side(GC.enemy(ch.team())) * 120.0, 0))


# --- eventos del servidor ------------------------------------------------

func _on_damaged(victim: Node, amount: float, info: Dictionary) -> void:
	if _active != "Assassination" or _winner != "":
		return
	var vk := String(info.get("victim_key", _key_of(victim)))
	for t in TEAMS:
		if vk != "" and vk == _data["VIP"][t]:
			var enemy := GC.enemy(t)
			_data["Damage"][enemy] += amount
			_set_progress(enemy, minf(0.99, _data["Damage"][enemy] / VIP_HEALTH))


func _on_killed(info: Dictionary) -> void:
	var vk := String(info.get("victim_key", ""))
	if vk == "":
		return
	if _active == "Assassination" and _winner == "":
		for t in TEAMS:
			if vk == _data["VIP"][t]:
				_winner = GC.enemy(t)
				_set_progress(_winner, 1.0)
				var killer := String(info.get("killer_key", ""))
				if killer != "":
					_add_money(killer, _reward() * 2, "OBJETIVO ELIMINADO")
				_obj_event("VIP", t, "¡Cayó el objetivo de %s!" % _display(t), {"action": "Killed", "key": vk})
				break
	elif _active == "CTF":
		for t in TEAMS:
			var f: Dictionary = _data["Flags"][t]
			if f["State"] == "Carried" and String(f["Carrier"]) == vk:
				var at: Vector2 = f["Pos"]
				var p = info.get("position")
				if p is Vector2:
					at = GC.px_to_studs(p) + Vector2(0, GC.CHARACTER["feet_offset"])
				_drop_flag(t, at)


func _on_character_ready(character: Node, key: String) -> void:
	if _active == "Assassination" and character != null:
		var team: String = character.team() if character.has_method("team") else ""
		if team != "" and _data["VIP"].get(team, "") == key:
			_apply_vip(character)
	elif _active == "CTF" and character != null:
		# un personaje recién aparecido nunca lleva bandera
		var carrying = character.get_attr("CarryingFlag", "")
		if carrying != null and String(carrying) != "":
			var f: Dictionary = _data["Flags"].get(String(carrying), {})
			if f.get("Carrier", "") != key:
				character.set_attr("CarryingFlag", "")
				character.set_attr("SpeedMult", 1.0)


func _on_peer_joined(peer_id: int) -> void:
	Net.send_to(peer_id, "ObjMarkers", _build_markers())


# --- marcadores ----------------------------------------------------------

func _marker(id: String, kind: String, pos_px: Vector2) -> Dictionary:
	return {"Id": id, "Kind": kind, "Team": "", "State": "", "Owner": "", "position": pos_px,
		"Contested": false, "Active": true, "HackUSA": 0.0, "HackVietnam": 0.0,
		"Health": 0.0, "MaxHealth": 0.0}


func _build_markers() -> Array:
	var out: Array = []
	match _active:
		"KingOfHill":
			var m := _marker("Hill", "Hill", GC.studs_to_px(Vector2(0, 8)))
			m["Owner"] = _data.get("MarkerOwner", "")
			m["Contested"] = _data.get("Contested", false)
			m["State"] = m["Owner"]
			m["Min"] = GC.studs_to_px(Vector2(HILL["min_x"], HILL["max_y"]))   # esquina sup. izq. (px)
			m["Max"] = GC.studs_to_px(Vector2(HILL["max_x"], HILL["min_y"]))   # esquina inf. der. (px)
			m["ProgressUSA"] = _progress["USA"]
			m["ProgressVietnam"] = _progress["Vietnam"]
			out.append(m)
		"Radio":
			var m := _marker("Radio", "Radio", GC.studs_to_px(Vector2(_data.get("Pos", Vector2.ZERO))))
			m["Active"] = bool(_data.get("Active", false))
			m["Contested"] = bool(_data.get("Contested", false))
			m["State"] = "Active" if m["Active"] else "Cooldown"
			var hack: Dictionary = _data.get("Hack", {})
			m["HackUSA"] = snappedf(float(hack.get("USA", 0.0)), 0.01)
			m["HackVietnam"] = snappedf(float(hack.get("Vietnam", 0.0)), 0.01)
			out.append(m)
		"CTF":
			for t in TEAMS:
				var f: Dictionary = _data["Flags"][t]
				var stand := _marker("FlagStand" + t, "FlagStand", GC.studs_to_px(f["Home"]))
				stand["Team"] = t
				out.append(stand)
				var m := _marker("Flag" + t, "Flag", GC.studs_to_px(f["Pos"]).round())
				m["Team"] = t
				m["State"] = f["State"]
				m["Owner"] = f["Carrier"]
				out.append(m)
		"Demolition":
			for t in TEAMS:
				var d = _data["Depots"].get(t)
				if d == null or not is_instance_valid(d):
					continue
				var m := _marker("Depot" + t, "Depot", d.global_position)
				m["Team"] = t
				m["Health"] = d.health
				m["MaxHealth"] = d.max_health
				m["Active"] = not d.destroyed
				m["State"] = "Destroyed" if d.destroyed else "Alive"
				out.append(m)
		"Assassination":
			for t in TEAMS:
				var m := _marker("VIP" + t, "VIP", Vector2.ZERO)
				m["Team"] = t
				var key: String = _data["VIP"][t]
				m["Owner"] = key
				var c := _char(key)
				m["Active"] = _alive(c)
				if c:
					m["position"] = c.feet_position().round()
					m["Health"] = float(c.get_attr("Health", 0.0))
					m["MaxHealth"] = float(c.get_attr("MaxHealth", VIP_HEALTH))
				out.append(m)
	return out


func _send_markers(force_reliable: bool) -> void:
	var markers := _build_markers()
	# firma sin posiciones: si cambió algo de estado va confiable
	var sig_parts := []
	for m in markers:
		var copy: Dictionary = m.duplicate()
		copy.erase("position")
		copy.erase("Health")
		copy.erase("HackUSA")
		copy.erase("HackVietnam")
		copy.erase("ProgressUSA")
		copy.erase("ProgressVietnam")
		sig_parts.append(str(copy))
	var sig := "|".join(sig_parts)
	if force_reliable or sig != _last_sig:
		_last_sig = sig
		_last_full = markers
		Net.broadcast("ObjMarkers", markers)
	elif markers != _last_full:
		_last_full = markers
		Net.broadcast_unreliable("ObjMarkers", markers)
