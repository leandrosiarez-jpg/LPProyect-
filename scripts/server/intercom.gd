extends Node
## Intercom: el comandante de cada equipo habla. El servidor solo manda la clave
## de la línea; el cliente elige el texto en data/mission_data.gd y anima el retrato.

var _last_said := {}


func init_system() -> void:
	_last_said.clear()


func start_system() -> void:
	pass


func _deployed_peers(team: String) -> Array:
	var out := []
	for peer_id in MatchState.players:
		var p: Dictionary = MatchState.players[peer_id]
		if p.get("Deployed", false) and p.get("Team", "") == team:
			out.append(peer_id)
	return out


## throttle: segundos mínimos entre repeticiones de la misma clave para ese equipo
func team(team_name: String, key: String, throttle: float = 0.0) -> void:
	var id := team_name + key
	var now := Time.get_ticks_msec() / 1000.0
	if throttle > 0.0 and _last_said.has(id) and now - _last_said[id] < throttle:
		return
	_last_said[id] = now
	for peer_id in _deployed_peers(team_name):
		Net.send_to(peer_id, "Intercom", {"team": team_name, "key": key})


func both(key: String, throttle: float = 0.0) -> void:
	team("USA", key, throttle)
	team("Vietnam", key, throttle)


func player(peer_id: int, key: String) -> void:
	var t: String = MatchState.get_player(peer_id, "Team", "")
	if t != "":
		Net.send_to(peer_id, "Intercom", {"team": t, "key": key})
