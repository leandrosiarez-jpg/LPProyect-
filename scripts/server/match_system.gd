extends Node
## MatchSystem: flujo de la partida al mejor de 3 rondas.
##   Waiting -> [Prep (construir + tienda) -> Round (misión) -> RoundEnd] x3 -> MatchEnd
## El estado se replica en MatchState.vars. Los cambios de fase se avisan con el
## evento de red "Round": {kind, round, mission, winner, reason, ...}.

var skip_requested := false
## Atajo de pruebas: "Radio,Assassination,CTF"
var force_missions := ""
var _running := false


func init_system() -> void:
	MatchState.set_var("Round", 0)
	MatchState.set_var("WinsUSA", 0)
	MatchState.set_var("WinsVietnam", 0)
	MatchState.set_var("ProgressUSA", 0.0)
	MatchState.set_var("ProgressVietnam", 0.0)
	MatchState.set_var("Mission", "")
	_set_phase("Waiting")


func start_system() -> void:
	_main_loop()


func is_active() -> bool:
	return MatchState.phase() == "Round"


func _sys(n: String) -> Node:
	return G.system(n)


func _now() -> float:
	return Net.server_time()


func _set_phase(phase: String, duration: float = 0.0) -> void:
	skip_requested = false
	MatchState.set_var("Phase", phase)
	MatchState.set_var("PhaseEnd", _now() + duration if duration > 0.0 else 0.0)
	MatchState.set_var("PhaseDuration", duration)
	ServerEvents.phase_changed.emit(phase, int(MatchState.get_var("Round", 0)))


func _time_left() -> float:
	return float(MatchState.get_var("PhaseEnd", 0.0)) - _now()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shuffled_missions() -> Array:
	var list := GC.MISSIONS.duplicate()
	list.shuffle()
	return list


func _all_humans_ready() -> bool:
	var any := false
	for p in MatchState.players.values():
		if p.get("Deployed", false):
			any = true
			if not p.get("Ready", false):
				return false
	return any


func _has_deployed() -> bool:
	var cs := _sys("Character")
	return cs != null and cs.has_deployed_players()


## Espera hasta que termine la fase (o stop_fn devuelva true).
## Devuelve false si no quedan jugadores desplegados.
func _wait_phase(stop_fn: Callable = Callable()) -> bool:
	while true:
		await _wait(0.1)
		if not _has_deployed():
			return false
		if skip_requested or _time_left() <= 0.0 or (stop_fn.is_valid() and stop_fn.call()):
			return true
	return false


func _reset_round() -> void:
	for t in GC.TEAMS:
		MatchState.set_var("Progress" + t, 0.0)
	_sys("Character").respawn_all_players()


func _intercom() -> Node:
	return _sys("Intercom")


## Devuelve {ok, winner, reason}
func _play_round(round_number: int, mission_id: String) -> Dictionary:
	MatchState.set_var("Round", round_number)
	MatchState.set_var("Mission", mission_id)

	# Interludio
	for peer_id in MatchState.players.keys():
		MatchState.set_player_attr(peer_id, "Ready", false)
	_sys("Character").set_barriers(true)
	_sys("Loadout").prep_refill()
	_set_phase("Prep", GC.MATCH["prep_duration"])
	_reset_round()
	Net.broadcast("Round", {"kind": "Prep", "round": round_number, "mission": mission_id})
	if round_number == 1:
		_intercom().both("Welcome")
		get_tree().create_timer(7.0).timeout.connect(func(): _intercom().both("Briefing_" + mission_id))
	else:
		_intercom().both("Briefing_" + mission_id)
	var still := await _wait_phase(func():
		if _all_humans_ready() and _time_left() > 4.0:
			MatchState.set_var("PhaseEnd", _now() + 3.0)
		return false)
	if not still:
		return {"ok": false}

	# Ronda
	var objectives := _sys("Objective")
	_sys("Character").set_barriers(false)
	objectives.start_mission(mission_id)
	_set_phase("Round", GC.MATCH["round_duration"])
	_reset_round()
	Net.broadcast("Round", {"kind": "Round", "round": round_number, "mission": mission_id})
	_intercom().both("Start")
	var warned := [false]
	still = await _wait_phase(func():
		if not warned[0] and _time_left() <= 60.0:
			warned[0] = true
			_intercom().both("OneMinute")
			Net.broadcast("Round", {"kind": "OneMinute"})
		return objectives.get_winner() != "")

	var winner: String = objectives.get_winner()
	var reason := "Objective" if winner != "" else "Time"
	if winner == "":
		var a: float = objectives.get_progress("USA")
		var b: float = objectives.get_progress("Vietnam")
		if absf(a - b) > 0.001:
			winner = "USA" if a > b else "Vietnam"
	objectives.stop_mission()
	if not still:
		return {"ok": false}
	return {"ok": true, "winner": winner, "reason": reason}


## Los más destacados de un equipo (para la cinemática final)
func _top_of(team: String, n: int) -> Array:
	var loadout := _sys("Loadout")
	var list := []
	for c in loadout.get_all().values():
		if c["team"] == team:
			list.append(c)
	list.sort_custom(func(x, y):
		if x["stats"]["Score"] != y["stats"]["Score"]:
			return x["stats"]["Score"] > y["stats"]["Score"]
		return x["stats"]["Kills"] > y["stats"]["Kills"])
	var out := []
	for i in mini(n, list.size()):
		var c: Dictionary = list[i]
		out.append({
			"Name": c["name"], "Class": c["class"], "Team": c["team"], "IsBot": c["is_bot"],
			"Weapon": loadout.get_weapon_id(c), "Kills": c["stats"]["Kills"], "Deaths": c["stats"]["Deaths"],
			"Headshots": c["stats"]["Headshots"], "Score": c["stats"]["Score"],
		})
	return out


func _run_match() -> bool:
	var missions := _shuffled_missions()
	if force_missions != "":
		var forced := force_missions.split(",", false)
		for i in forced.size():
			if i < missions.size():
				missions[i] = forced[i]
	var wins := {"USA": 0, "Vietnam": 0}
	MatchState.set_var("WinsUSA", 0)
	MatchState.set_var("WinsVietnam", 0)
	MatchState.set_var("Missions", ",".join(missions.slice(0, GC.MATCH["rounds"])))
	var loadout := _sys("Loadout")
	loadout.reset_for_match()
	_sys("Build").clear()

	for round_number in range(1, GC.MATCH["rounds"] + 1):
		var mission: String = missions[round_number - 1]
		var r: Dictionary = await _play_round(round_number, mission)
		if not r["ok"]:
			return false
		var winner: String = r["winner"]
		if winner != "":
			wins[winner] += 1
			MatchState.set_var("Wins" + winner, wins[winner])
		for key in loadout.get_all().keys():
			var c: Dictionary = loadout.get_combatant(key)
			if winner != "" and c["team"] == winner:
				loadout.add_money(key, GC.MATCH["round_win_reward"], "RONDA GANADA")
			else:
				loadout.add_money(key, GC.MATCH["round_loss_reward"], "PAGA DE RONDA")
		MatchState.set_var("LastWinner", winner)
		_set_phase("RoundEnd", GC.MATCH["round_end_duration"])
		Net.broadcast("Round", {"kind": "RoundEnd", "round": round_number, "mission": mission,
			"winner": winner, "reason": r["reason"]})
		for t in GC.TEAMS:
			if winner == "":
				_intercom().team(t, "RoundDraw")
			elif t == winner:
				_intercom().team(t, "RoundWon")
			else:
				_intercom().team(t, "RoundLost")
		if not await _wait_phase():
			return false
		var needed := int(GC.MATCH["rounds"] / 2) + 1
		if wins["USA"] >= needed or wins["Vietnam"] >= needed:
			break

	# Fin de partida
	var match_winner := ""
	if wins["USA"] > wins["Vietnam"]:
		match_winner = "USA"
	elif wins["Vietnam"] > wins["USA"]:
		match_winner = "Vietnam"
	var mvp := {}
	var best := -1
	for c in loadout.get_all().values():
		if c["stats"]["Score"] > best:
			mvp = c
			best = c["stats"]["Score"]
	MatchState.set_var("MatchWinner", match_winner)
	_set_phase("MatchEnd", GC.MATCH["match_end_duration"])
	var finale = null
	if match_winner != "":
		finale = {"Winner": match_winner, "Heroes": _top_of(match_winner, 3),
			"Losers": _top_of(GC.enemy(match_winner), 3)}
	Net.broadcast("Round", {"kind": "MatchEnd", "winner": match_winner,
		"mvp_name": mvp.get("name", ""), "mvp_team": mvp.get("team", ""),
		"mvp_kills": mvp.get("stats", {}).get("Kills", 0), "finale": finale})
	if match_winner != "":
		for t in GC.TEAMS:
			_intercom().team(t, "MatchWon" if t == match_winner else "MatchLost")
	await _wait_phase()
	return true


func _main_loop() -> void:
	if _running:
		return
	_running = true
	while is_inside_tree():
		_set_phase("Waiting")
		_sys("Character").set_barriers(false)
		while not _has_deployed():
			await ServerEvents.deployed
		await _wait(1.0)
		await _run_match()
	_running = false
