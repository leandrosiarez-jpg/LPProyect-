extends Node
## Arranque del juego: servidor y cliente.
## Arma el mundo y los controladores del cliente al iniciar; los sistemas del
## servidor se crean solo al empezar una sesión como anfitrión o en modo solo.
## Patrón Init/Start: init_system() en todos y luego start_system() en todos.
## Un error en un módulo se registra y no detiene al resto.

## Sistemas del servidor (nombre -> script)
const SERVER_SYSTEMS := [
	["Intercom", "res://scripts/server/intercom.gd"],
	["Loadout", "res://scripts/server/loadout_system.gd"],
	["Nav", "res://scripts/server/nav_grid.gd"],
	["Character", "res://scripts/server/character_system.gd"],
	["Combat", "res://scripts/server/combat_system.gd"],
	["Build", "res://scripts/server/build_system.gd"],
	["Objective", "res://scripts/server/objective_system.gd"],
	["Bot", "res://scripts/server/bot_system.gd"],
	["Match", "res://scripts/server/match_system.gd"],
]

## Controladores del cliente en orden fijo: [nombre, script, padre]
## padre: "world" (dibuja en el mundo), "client" (lógica) o "ui" (interfaz)
const CLIENT_CONTROLLERS := [
	["Sound", "res://scripts/client/sound_controller.gd", "client"],
	["FX", "res://scripts/client/fx_controller.gd", "world"],
	["CharacterReplicator", "res://scripts/client/character_replicator.gd", "client"],
	["Projectiles", "res://scripts/client/projectile_renderer.gd", "world"],
	["ObjectiveRenderer", "res://scripts/client/objective_renderer.gd", "world"],
	["Camera", "res://scripts/client/camera_controller.gd", "client"],
	["Cinema", "res://scripts/client/cinema_controller.gd", "client"],
	["Input", "res://scripts/client/input_controller.gd", "client"],
	["Build", "res://scripts/client/build_controller.gd", "world"],
	["Intercom", "res://scripts/ui/intercom_ui.gd", "ui"],
	["Shop", "res://scripts/ui/shop_ui.gd", "ui"],
	["HUD", "res://scripts/ui/hud.gd", "ui"],
	["Scoreboard", "res://scripts/ui/scoreboard.gd", "ui"],
	["Results", "res://scripts/ui/results_ui.gd", "ui"],
	["Menu", "res://scripts/ui/menu.gd", "ui"],
]

var _systems_root: Node
var _client_root: Node


func _ready() -> void:
	G.main = self
	if "--check" in OS.get_cmdline_user_args():
		var errors: int = load("res://tools/check_scripts.gd").run()
		get_tree().quit(1 if errors > 0 else 0)
		return
	_build_world()
	_build_client()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autotest="):
			_autotest(float(arg.get_slice("=", 1)))
		elif arg.begins_with("--nettest="):
			_nettest(arg.get_slice("=", 1))


## Prueba automática: partida solo, despliega al jugador y acelera las fases.
func _autotest(seconds: float) -> void:
	print("AUTOTEST start ", seconds, "s")
	var err := start_session("offline")
	if err != "":
		print("AUTOTEST FAIL ", err)
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.5).timeout
	Net.request("Deploy", ["USA", "Soldier"])
	var shots_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.get_slice("=", 1)
			DirAccess.make_dir_recursive_absolute(shots_dir)
	var elapsed := 0.0
	while elapsed < seconds:
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0
		if shots_dir != "" and int(elapsed) % 2 == 0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/t%02d.png" % [shots_dir, int(elapsed)])
		# saltear el interludio para probar la ronda
		if MatchState.phase() == "Prep" and MatchState.time_left() > 3.0 and G.system("Match"):
			G.system("Match").skip_requested = true
	print("AUTOTEST phase=%s round=%s chars=%d combatants=%d" % [MatchState.phase(),
		MatchState.get_var("Round"), G.characters.get_child_count(), MatchState.combatants.size()])
	print("AUTOTEST OK")
	get_tree().quit(0)


## Prueba de red: "host" o "client" (se conecta a 127.0.0.1). Corre 14 s,
## el cliente camina a la derecha y ambos imprimen lo que ven.
func _nettest(role: String) -> void:
	var err := start_session("host" if role == "host" else "client", "127.0.0.1")
	print("NETTEST %s start err='%s'" % [role, err])
	if role == "client":
		await Net.connection_state_changed
		print("NETTEST client state peers=", multiplayer.get_peers())
		await get_tree().create_timer(1.0).timeout
		Net.request("Deploy", ["Vietnam", "Soldier"])
		await get_tree().create_timer(2.0).timeout
		Input.action_press("move_right")
	else:
		await get_tree().create_timer(1.0).timeout
		Net.request("Deploy", ["USA", "Soldier"])
		await get_tree().create_timer(4.0).timeout
		Input.action_press("move_left")
	for i in 14:
		await get_tree().create_timer(1.0).timeout
		var pos := []
		for c in G.characters.get_children():
			if String(c.name).begins_with("B"):
				continue
			pos.append("%s@%d,%d" % [c.name, c.position.x, c.position.y])
		print("NETTEST %s t=%d phase=%s combatants=%d players=%d chars=%s" % [role, i,
			MatchState.phase(), MatchState.combatants.size(), MatchState.players.size(), pos])
	print("NETTEST %s DONE" % role)
	get_tree().quit(0)


func _build_world() -> void:
	var world := Node2D.new()
	world.name = "World"
	add_child(world)
	G.world = world

	var map_script := _load("res://scripts/game/map_grid.gd")
	var map: Node2D = map_script.new() if map_script else Node2D.new()
	map.name = "Map"
	world.add_child(map)
	G.map = map

	for n in ["Objectives", "Characters", "Projectiles"]:
		var node := Node2D.new()
		node.name = n
		world.add_child(node)
	G.objectives = world.get_node("Objectives")
	G.characters = world.get_node("Characters")
	G.projectiles = world.get_node("Projectiles")

	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.layer = 10
	add_child(ui)
	G.ui = ui


func _build_client() -> void:
	_client_root = Node.new()
	_client_root.name = "Client"
	add_child(_client_root)
	for entry in CLIENT_CONTROLLERS:
		var script := _load(entry[1])
		if script == null:
			continue
		var node: Node = script.new()
		node.name = entry[0]
		match entry[2]:
			"world":
				G.world.add_child(node)
			"ui":
				G.ui.add_child(node)
			_:
				_client_root.add_child(node)
		G.client[entry[0]] = node
	G.fx = G.client.get("FX")


func _load(path: String) -> Script:
	if not ResourceLoader.exists(path):
		push_warning("[GummyWars] falta el módulo " + path)
		return null
	var s = load(path)
	if s == null:
		push_warning("[GummyWars] no se pudo cargar " + path)
	return s


# --- sesiones -------------------------------------------------------------

## mode: "offline", "host" o "client". Devuelve "" si salió bien o el error.
func start_session(mode: String, address: String = "") -> String:
	end_session()
	var err := OK
	match mode:
		"offline":
			Net.start_offline()
		"host":
			err = Net.start_host()
		"client":
			err = Net.start_client(address)
	if err != OK:
		return "No se pudo iniciar la sesión"
	if Net.is_server():
		_build_systems()
	G.session_started.emit()
	return ""


func end_session() -> void:
	if _systems_root:
		_systems_root.queue_free()
		_systems_root = null
	G.systems.clear()
	for c in G.characters.get_children():
		c.queue_free()
	for p in G.projectiles.get_children():
		p.queue_free()
	if G.map and G.map.has_method("reset"):
		G.map.reset()
	if Net.mode != Net.Mode.NONE:
		Net.close()
	MatchState.reset()
	G.session_ended.emit()


func _build_systems() -> void:
	_systems_root = Node.new()
	_systems_root.name = "Systems"
	add_child(_systems_root)
	for entry in SERVER_SYSTEMS:
		var script := _load(entry[1])
		if script == null:
			continue
		var node: Node = script.new()
		node.name = entry[0]
		_systems_root.add_child(node)
		G.systems[entry[0]] = node
	for n in G.systems:
		var sys: Node = G.systems[n]
		if sys.has_method("init_system"):
			sys.init_system()
	for n in G.systems:
		var sys: Node = G.systems[n]
		if sys.has_method("start_system"):
			sys.call_deferred("start_system")
