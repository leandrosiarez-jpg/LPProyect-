extends Node
## CharacterSystem (servidor): despliegue desde el menú, aparición/reaparición,
## armado de los personajes (humanos y bots), barreras del interludio,
## protección de aparición y replicación de personajes.
##
## Física: cada humano simula SU personaje y manda "Move" [pos, vel, flags, aim?]
## (unreliable ~30 Hz); el servidor lo valida y lo aplica al títere. Los bots los
## simula el servidor.
##
## Eventos de red que emite:
##   CharSpawn  {key, attrs: Dictionary, pos: Vector2, seq: int}     (confiable; aparición o reaparición)
##   CharRemove {key}                                                (confiable)
##   CharAttrs  {chars: {key: {attr: valor}}, teleport: {key: [pos, seq]}}   (confiable; diferencias)
##   CharSnap   {t: server_time, c: {key: [pos, vel, aim, flags]}}   (unreliable ~20 Hz)
##     flags (también en Move): bit 0 = en el piso; bits 8..15 = seq de aparición & 0xFF.

const SNAP_INTERVAL := 1.0 / 20.0
const CLASS_CHANGE_COOLDOWN := 0.5
const MAP_DATA_PATH := "res://data/map_frente_caramelo.gd"
const DEFAULT_SPAWNS := {
	"USA": [Vector2(-236, 1), Vector2(-232, 1), Vector2(-228, 1)],
	"Vietnam": [Vector2(228, 1), Vector2(232, 1), Vector2(236, 1)],
}

var _spawns := {}
var _respawn_tokens := {}     # peer_id -> int
var _last_class_change := {}  # peer_id -> float
var _last_move := {}          # key -> {t, pos}
var _snap_accum := 0.0
var _seq := 0
var _barriers_on := false


func init_system() -> void:
	_spawns = DEFAULT_SPAWNS.duplicate(true)
	if ResourceLoader.exists(MAP_DATA_PATH):
		var md: Script = load(MAP_DATA_PATH)
		if md:
			var consts := md.get_script_constant_map()
			if consts.has("SPAWNS"):
				_spawns = consts["SPAWNS"]


func start_system() -> void:
	Net.register_handler("Deploy", _on_deploy)
	Net.register_handler("ReturnToMenu", _on_return_to_menu)
	Net.register_handler("SelectClass", _on_select_class)
	Net.register_handler("SetReady", _on_set_ready)
	Net.register_handler("Move", _on_move)
	# "Aim" es de Combat; este es un respaldo por si nadie lo registra (Combat lo pisa al arrancar después)
	if not Net._handlers.has("Aim"):
		Net.register_handler("Aim", _on_aim)
	ServerEvents.killed.connect(_on_killed)
	Net.peer_joined.connect(_on_peer_joined)
	Net.peer_left.connect(_on_peer_left)
	var loadout := _loadout()
	if loadout and loadout.has_signal("changed"):
		loadout.changed.connect(_on_loadout_changed)


func _exit_tree() -> void:
	for sig in [[ServerEvents.killed, _on_killed], [Net.peer_joined, _on_peer_joined], [Net.peer_left, _on_peer_left]]:
		var s: Signal = sig[0]
		if s.is_connected(sig[1]):
			s.disconnect(sig[1])


func _loadout() -> Node:
	return G.system("Loadout")


func _phase() -> String:
	return MatchState.phase()


# --- consultas ------------------------------------------------------------------

func has_deployed_players() -> bool:
	for p in MatchState.players.values():
		if p.get("Deployed", false):
			return true
	return false


## Punto de aparición (pies, px) al azar entre los de la base del equipo.
func get_spawn_point(team: String) -> Vector2:
	var list: Array = _spawns.get(team, [])
	if list.is_empty():
		return GC.studs_to_px(Vector2(0, 6))
	var s: Vector2 = list[randi() % list.size()]
	return GC.studs_to_px(Vector2(s.x + (randf() - 0.5) * 2.0, s.y + 0.5))


func get_character(key: String) -> Gummy:
	return G.get_character(key) as Gummy


# --- aparición ---------------------------------------------------------------------

func _base_attrs(c: Dictionary) -> Dictionary:
	var stats: Dictionary = _loadout().get_spawn_stats(c)
	var team: String = c["team"]
	var side: int = GC.TEAM_INFO[team]["side"] if GC.TEAM_INFO.has(team) else -1
	return {
		"Key": c["key"], "Team": team, "Class": c["class"], "DisplayName": c["name"],
		"IsBot": c.get("is_bot", false),
		"Aim": 0.0 if side == -1 else PI,
		"Weapon": stats["weapon"], "Ammo": stats["mag_size"], "MaxAmmo": stats["mag_size"],
		"Grenades": stats["grenades"], "Reloading": false, "Burning": false,
		"BaseSpeed": stats["walk_speed"], "SpeedMult": 1.0, "JumpPower": stats["jump_power"],
		"VIP": false, "CarryingFlag": "", "LastHitBy": "",
		"Health": stats["max_health"], "MaxHealth": stats["max_health"], "Dead": false,
		"ProtectedUntil": Net.server_time() + GC.MATCH["spawn_protection"],
	}


## Crea (o reutiliza) el nodo del combatiente y lo pone en su base.
func _spawn_combatant(c: Dictionary) -> Gummy:
	if c.is_empty() or G.characters == null:
		return null
	var key: String = c["key"]
	var ch := get_character(key)
	if ch == null or ch.is_queued_for_deletion():
		ch = Gummy.new()
		ch.name = key
		G.characters.add_child(ch)
	var peer: int = c.get("peer_id", 0)
	ch.controlled_locally = c.get("is_bot", false) or peer == Net.my_id()
	ch.move_input = 0.0
	ch.jump_input = false
	ch.attrs = {}
	ch.apply_attrs(_base_attrs(c))
	ch.take_dirty()
	_seq += 1
	ch.spawn_seq = _seq
	ch.teleport(get_spawn_point(c["team"]))
	_last_move.erase(key)
	Net.broadcast("CharSpawn", _spawn_data(ch))
	ServerEvents.character_ready.emit(ch, key)
	return ch


func _spawn_data(ch: Gummy) -> Dictionary:
	return {"key": String(ch.name), "attrs": ch.attrs.duplicate(), "pos": ch.global_position, "seq": ch.spawn_seq}


func _spawn_player(peer_id: int) -> void:
	var p: Dictionary = MatchState.players.get(peer_id, {})
	if not p.get("Deployed", false):
		return
	_respawn_tokens[peer_id] = int(_respawn_tokens.get(peer_id, 0)) + 1
	MatchState.set_player_attr(peer_id, "RespawnAt", 0.0)
	var c: Dictionary = _loadout().get_combatant(Net.key_for_peer(peer_id))
	if c.is_empty():
		return
	c["class"] = p.get("Class", c["class"])
	_loadout().sync(c)
	_spawn_combatant(c)


func _schedule_respawn(peer_id: int, delay: float) -> void:
	var token := int(_respawn_tokens.get(peer_id, 0)) + 1
	_respawn_tokens[peer_id] = token
	MatchState.set_player_attr(peer_id, "RespawnAt", Net.server_time() + delay)
	get_tree().create_timer(delay).timeout.connect(func():
		if not is_inside_tree() or int(_respawn_tokens.get(peer_id, 0)) != token:
			return
		if not MatchState.get_player(peer_id, "Deployed", false):
			return
		var ph := _phase()
		if ph == "MatchEnd" or ph == "RoundEnd":
			return  # reaparecen todos al empezar la fase siguiente
		_spawn_player(peer_id))


## Reaparece a todos los jugadores desplegados en su base.
func respawn_all_players() -> void:
	for peer_id in MatchState.players.keys():
		if MatchState.players[peer_id].get("Deployed", false):
			_spawn_player(peer_id)


## Para el BotSystem. Registra al bot en Loadout si hace falta.
func spawn_bot(key: String, display_name: String, team: String, class_id: String) -> Gummy:
	var loadout := _loadout()
	var c: Dictionary = loadout.get_combatant(key)
	if c.is_empty() or c["team"] != team or c["class"] != class_id or c["name"] != display_name:
		c = loadout.register(key, {"name": display_name, "team": team,
			"class": class_id if Data.is_valid_class(class_id) else Data.DEFAULT_CLASS,
			"is_bot": true, "peer_id": 0})
	return _spawn_combatant(c)


## Reaparece un combatiente (humano o bot) ya registrado.
func respawn(key: String) -> Gummy:
	var peer := Net.peer_for_key(key)
	if peer != 0:
		_spawn_player(peer)
		return get_character(key)
	return _spawn_combatant(_loadout().get_combatant(key))


## Saca al personaje del mundo (no lo desregistra de Loadout).
func despawn(key: String) -> void:
	var ch := G.get_character(key)
	if ch:
		G.characters.remove_child(ch)
		ch.queue_free()
		Net.broadcast("CharRemove", {"key": key})
	_last_move.erase(key)


## Aplica compras/equipo sin reaparecer (interludio).
func refresh_loadout(key: String) -> void:
	var ch := get_character(key)
	var c: Dictionary = _loadout().get_combatant(key)
	if ch == null or c.is_empty() or not ch.is_alive():
		return
	var stats: Dictionary = _loadout().get_spawn_stats(c)
	ch.set_attr("Weapon", stats["weapon"])
	ch.set_attr("Ammo", stats["mag_size"])
	ch.set_attr("MaxAmmo", stats["mag_size"])
	ch.set_attr("Grenades", stats["grenades"])
	ch.set_attr("Reloading", false)
	ch.set_attr("BaseSpeed", stats["walk_speed"])
	ch.set_attr("JumpPower", stats["jump_power"])
	ch.set_attr("MaxHealth", stats["max_health"])
	ch.set_attr("Health", stats["max_health"])


## Barreras del interludio (cada equipo queda en su mitad).
func set_barriers(on: bool) -> void:
	_barriers_on = on
	Gummy.ensure_barriers(on)


# --- handlers ---------------------------------------------------------------------

func _team_humans(team: String) -> int:
	var n := 0
	for p in MatchState.players.values():
		if p.get("Deployed", false) and p.get("Team", "") == team:
			n += 1
	return n


func _player_name(peer_id: int, args: Array) -> String:
	if peer_id == Net.my_id():
		return Net.local_name
	if args.size() >= 3 and args[2] is String:
		var s: String = args[2].strip_edges().left(20)
		if s != "":
			return s
	var existing = MatchState.get_player(peer_id, "Name", "")
	if existing is String and existing != "":
		return existing
	return "Gomita %d" % peer_id


func _on_deploy(peer_id: int, args: Array) -> void:
	if MatchState.get_player(peer_id, "Deployed", false):
		return
	var team := ""
	if args.size() >= 1 and args[0] is String and args[0] in GC.TEAMS:
		team = args[0]
	else:
		team = "USA" if _team_humans("USA") <= _team_humans("Vietnam") else "Vietnam"
	var cls: String = Data.DEFAULT_CLASS
	if args.size() >= 2 and Data.is_valid_class(args[1]):
		cls = args[1]
	var pname := _player_name(peer_id, args)
	MatchState.set_player(peer_id, {"Name": pname, "Deployed": true, "Ready": false, "Class": cls,
		"Team": team, "RespawnAt": 0.0})
	_loadout().register(Net.key_for_peer(peer_id), {"name": pname, "team": team, "class": cls,
		"is_bot": false, "peer_id": peer_id})
	ServerEvents.deployed.emit(peer_id)
	_spawn_player(peer_id)


func _return_to_menu(peer_id: int) -> void:
	MatchState.set_player(peer_id, {"Deployed": false, "Ready": false, "RespawnAt": 0.0, "Team": ""})
	_respawn_tokens[peer_id] = int(_respawn_tokens.get(peer_id, 0)) + 1
	var key := Net.key_for_peer(peer_id)
	despawn(key)
	_loadout().unregister(key)
	ServerEvents.deployed.emit(peer_id)


func _on_return_to_menu(peer_id: int, _args: Array) -> void:
	if MatchState.get_player(peer_id, "Deployed", false):
		_return_to_menu(peer_id)


func _on_select_class(peer_id: int, args: Array) -> void:
	if args.size() < 1 or not Data.is_valid_class(args[0]):
		return
	if not MatchState.get_player(peer_id, "Deployed", false):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_class_change.get(peer_id, -10.0)) < CLASS_CHANGE_COOLDOWN:
		return
	_last_class_change[peer_id] = now
	var cls: String = args[0]
	if MatchState.get_player(peer_id, "Class", "") == cls:
		return
	MatchState.set_player_attr(peer_id, "Class", cls)
	var c: Dictionary = _loadout().get_combatant(Net.key_for_peer(peer_id))
	if not c.is_empty():
		c["class"] = cls
		_loadout().sync(c)
	var ph := _phase()
	if ph == "Prep" or ph == "Waiting":
		_spawn_player(peer_id)
	elif not c.is_empty():
		_loadout().notice(c, "Vas a ser %s al reaparecer" % Data.get_class_data(cls)["display"], "Info")


func _on_set_ready(peer_id: int, args: Array) -> void:
	if _phase() != "Prep" or not MatchState.get_player(peer_id, "Deployed", false):
		return
	MatchState.set_player_attr(peer_id, "Ready", args.size() >= 1 and args[0] == true)


func _on_aim(peer_id: int, args: Array) -> void:
	if args.size() < 1 or not (args[0] is float or args[0] is int):
		return
	var ch := get_character(Net.key_for_peer(peer_id))
	if ch and not ch.controlled_locally and is_finite(float(args[0])):
		ch.set_attr("Aim", float(args[0]))


func _on_move(peer_id: int, args: Array) -> void:
	if args.size() < 3 or not (args[0] is Vector2) or not (args[1] is Vector2) or not (args[2] is int):
		return
	var key := Net.key_for_peer(peer_id)
	var ch := get_character(key)
	if ch == null or ch.controlled_locally:
		return
	var flags: int = args[2]
	if ((flags >> 8) & 0xFF) != (ch.spawn_seq & 0xFF):
		return  # paquete de una vida anterior
	var pos: Vector2 = args[0]
	var vel: Vector2 = args[1]
	if not (is_finite(pos.x) and is_finite(pos.y) and is_finite(vel.x) and is_finite(vel.y)):
		return
	if args.size() >= 4 and (args[3] is float or args[3] is int) and is_finite(float(args[3])):
		ch.set_attr("Aim", float(args[3]))
	# validación razonable: límites del mapa, velocidad máxima y distancia recorrida
	var limit_x := 258.0 * GC.STUD
	pos.x = clampf(pos.x, -limit_x, limit_x)
	pos.y = clampf(pos.y, -200.0 * GC.STUD, 60.0 * GC.STUD)
	vel = vel.limit_length(300.0 * GC.STUD)
	var now := Net.server_time()
	var last: Dictionary = _last_move.get(key, {})
	var from: Vector2 = last.get("pos", ch.global_position)
	var dt := clampf(now - float(last.get("t", now - 0.1)), 0.02, 0.6)
	var speed_px := (ch.walk_speed() * 2.0 + 90.0) * GC.STUD
	var allowed := speed_px * dt + 3.0 * GC.STUD
	var moved := pos.distance_to(from)
	if moved > allowed:
		pos = from + (pos - from).normalized() * allowed
		if moved > allowed + 12.0 * GC.STUD:
			# corrección al dueño
			Net.send_to(peer_id, "CharAttrs", {"chars": {}, "teleport": {key: [pos, ch.spawn_seq]}})
	_last_move[key] = {"t": now, "pos": pos}
	ch.apply_remote_state(pos, vel, (flags & 1) == 1, now, 30.0)


func _on_killed(info: Dictionary) -> void:
	var key: String = str(info.get("victim_key", ""))
	var ch := get_character(key)
	if ch and not ch.get_attr("Dead", false):
		ch.set_attr("Dead", true)
	var peer := Net.peer_for_key(key)
	if peer == 0 or not MatchState.get_player(peer, "Deployed", false):
		return  # los bots los reaparece el BotSystem
	var delay: float = GC.MATCH["prep_respawn_time"] if _phase() == "Prep" else GC.MATCH["respawn_time"]
	_schedule_respawn(peer, delay)


func _on_loadout_changed(key: String) -> void:
	var ph := _phase()
	if ph == "Prep" or ph == "Waiting":
		refresh_loadout(key)


func _on_peer_joined(peer_id: int) -> void:
	# estado completo de los personajes al que entra
	if G.characters == null:
		return
	for ch in G.characters.get_children():
		if ch is Gummy and not ch.is_queued_for_deletion():
			Net.send_to(peer_id, "CharSpawn", _spawn_data(ch))


func _on_peer_left(peer_id: int) -> void:
	_last_class_change.erase(peer_id)
	if MatchState.get_player(peer_id, "Deployed", false):
		_return_to_menu(peer_id)
	else:
		var key := Net.key_for_peer(peer_id)
		despawn(key)
		_loadout().unregister(key)
	_respawn_tokens.erase(peer_id)
	MatchState.remove_player(peer_id)
	ServerEvents.deployed.emit(peer_id)


# --- replicación ---------------------------------------------------------------

func _process(delta: float) -> void:
	if G.characters == null:
		return
	var online := Net.mode == Net.Mode.HOST
	var dirty := {}
	for ch in G.characters.get_children():
		if ch is Gummy:
			var d: Dictionary = ch.take_dirty()
			if not d.is_empty():
				dirty[String(ch.name)] = d
	if online and not dirty.is_empty():
		Net.broadcast("CharAttrs", {"chars": dirty, "teleport": {}})
	if not online:
		return
	_snap_accum += delta
	if _snap_accum < SNAP_INTERVAL:
		return
	_snap_accum = 0.0
	var snap := {}
	for ch in G.characters.get_children():
		if ch is Gummy and not ch.is_queued_for_deletion():
			var flags: int = (1 if ch.grounded() else 0) | ((ch.spawn_seq & 0xFF) << 8)
			snap[String(ch.name)] = [ch.global_position, ch.velocity, float(ch.get_attr("Aim", 0.0)), flags]
	if not snap.is_empty():
		Net.broadcast_unreliable("CharSnap", {"t": Net.server_time(), "c": snap})
