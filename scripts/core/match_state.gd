extends Node
## Estado replicado de la partida: variables, combatientes y jugadores.
## Solo el servidor escribe; los cambios viajan como diferencias cada 0,1 s.
##
##   vars        Phase, PhaseEnd, PhaseDuration, Round, Mission, Missions,
##               WinsUSA, WinsVietnam, ProgressUSA, ProgressVietnam,
##               LastWinner, MatchWinner, ...
##   combatants  key -> {Name, Team, Class, IsBot, Kills, Deaths, Headshots, Score}
##   players     peer_id -> {Name, Deployed, Ready, Class, Team, RespawnAt, Money,
##               Owned (Array), EquipSoldier, EquipPyro, Vest, Boots, Mags,
##               GrenadeBonus, BlocksLeft}

signal var_changed(key: String, value)
signal combatant_changed(key: String)
signal combatant_removed(key: String)
signal player_changed(peer_id: int)
signal player_removed(peer_id: int)

const SYNC_INTERVAL := 0.1

var vars := {}
var combatants := {}
var players := {}

var _dirty_vars := {}
var _dirty_combatants := {}
var _removed_combatants := {}
var _dirty_players := {}
var _removed_players := {}
var _accum := 0.0


func reset() -> void:
	vars.clear()
	combatants.clear()
	players.clear()
	_clear_dirty()


func _clear_dirty() -> void:
	_dirty_vars.clear()
	_dirty_combatants.clear()
	_removed_combatants.clear()
	_dirty_players.clear()
	_removed_players.clear()


# --- lectura (ambos lados) -----------------------------------------------

func get_var(key: String, default = null):
	return vars.get(key, default)


func phase() -> String:
	return vars.get("Phase", "Waiting")


func time_left() -> float:
	return float(vars.get("PhaseEnd", 0.0)) - Net.server_time()


func get_player(peer_id: int, key: String = "", default = null):
	var p: Dictionary = players.get(peer_id, {})
	if key == "":
		return p
	return p.get(key, default)


func my_player(key: String = "", default = null):
	return get_player(Net.my_id(), key, default)


func get_combatant(key: String) -> Dictionary:
	return combatants.get(key, {})


# --- escritura (servidor) ------------------------------------------------

func set_var(key: String, value) -> void:
	if not Net.is_server():
		return
	if vars.get(key) == value and vars.has(key):
		return
	vars[key] = value
	_dirty_vars[key] = true
	var_changed.emit(key, value)


func set_combatant(key: String, data: Dictionary) -> void:
	if not Net.is_server():
		return
	var c: Dictionary = combatants.get(key, {})
	c.merge(data, true)
	combatants[key] = c
	_dirty_combatants[key] = true
	_removed_combatants.erase(key)
	combatant_changed.emit(key)


func remove_combatant(key: String) -> void:
	if not Net.is_server() or not combatants.has(key):
		return
	combatants.erase(key)
	_dirty_combatants.erase(key)
	_removed_combatants[key] = true
	combatant_removed.emit(key)


func set_player(peer_id: int, data: Dictionary) -> void:
	if not Net.is_server():
		return
	var p: Dictionary = players.get(peer_id, {})
	p.merge(data, true)
	players[peer_id] = p
	_dirty_players[peer_id] = true
	_removed_players.erase(peer_id)
	player_changed.emit(peer_id)


func set_player_attr(peer_id: int, key: String, value) -> void:
	set_player(peer_id, {key: value})


func remove_player(peer_id: int) -> void:
	if not Net.is_server() or not players.has(peer_id):
		return
	players.erase(peer_id)
	_dirty_players.erase(peer_id)
	_removed_players[peer_id] = true
	player_removed.emit(peer_id)


# --- replicación ---------------------------------------------------------

func _ready() -> void:
	Net.peer_joined.connect(_on_peer_joined)


func _process(delta: float) -> void:
	if Net.mode != Net.Mode.HOST:
		_clear_dirty()
		return
	_accum += delta
	if _accum < SYNC_INTERVAL:
		return
	_accum = 0.0
	if _dirty_vars.is_empty() and _dirty_combatants.is_empty() and _removed_combatants.is_empty() \
			and _dirty_players.is_empty() and _removed_players.is_empty():
		return
	var diff := {
		"v": _pick(vars, _dirty_vars),
		"c": _pick(combatants, _dirty_combatants),
		"cr": _removed_combatants.keys(),
		"p": _pick(players, _dirty_players),
		"pr": _removed_players.keys(),
	}
	_clear_dirty()
	_rpc_apply.rpc(diff, Net.server_time())


func _pick(src: Dictionary, keys: Dictionary) -> Dictionary:
	var out := {}
	for k in keys:
		if src.has(k):
			out[k] = src[k]
	return out


func _on_peer_joined(peer_id: int) -> void:
	var full := {"v": vars, "c": combatants, "cr": [], "p": players, "pr": [], "full": true}
	_rpc_apply.rpc_id(peer_id, full, Net.server_time())


@rpc("authority", "call_remote", "reliable")
func _rpc_apply(diff: Dictionary, server_now: float) -> void:
	Net._sync_time(server_now)
	if diff.get("full", false):
		vars.clear()
		combatants.clear()
		players.clear()
	for k in diff.get("v", {}):
		vars[k] = diff["v"][k]
		var_changed.emit(k, vars[k])
	for k in diff.get("c", {}):
		combatants[k] = diff["c"][k]
		combatant_changed.emit(k)
	for k in diff.get("cr", []):
		combatants.erase(k)
		combatant_removed.emit(k)
	for k in diff.get("p", {}):
		players[int(k)] = diff["p"][k]
		player_changed.emit(int(k))
	for k in diff.get("pr", []):
		players.erase(int(k))
		player_removed.emit(int(k))
