extends MultiplayerSpawner

@export var network_player: PackedScene
@export var spawn_radius: float = 150.0

var _spawn_index: int = 0


func _ready() -> void:
	spawn_function = _do_spawn

	multiplayer.peer_connected.connect(_on_peer_connected)
	HighLevelNetworkHandler.server_started.connect(_on_server_started)
	HighLevelNetworkHandler.network_stopped.connect(_on_network_stopped)


func _on_server_started(_local_ips: PackedStringArray) -> void:
	# El host tambien necesita su propio jugador; peer_connected
	# solo se dispara para los clientes que se conectan despues.
	if multiplayer.is_server():
		spawn(multiplayer.get_unique_id())


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		spawn(id)


# Se dispara al cancelar/desconectar (boton Cancelar de la UI, o
# HighLevelNetworkHandler.cancel()). Borra los jugadores que hayan
# quedado en escena (propios si eras host, replicados si eras
# cliente) para que la proxima vez que se hostee o conecte arranque
# limpio, sin "fantasmas" del intento anterior.
func _on_network_stopped() -> void:
	var parent := get_node(spawn_path)
	for child in parent.get_children():
		if child.name.is_valid_int():
			child.queue_free()
	_spawn_index = 0


# spawn_function: el MultiplayerSpawner llama a esto SOLO en el servidor,
# crea el nodo, y se encarga el mismo de hacer add_child de forma segura
# y de replicarlo en todos los clientes. No hay que llamar add_child a mano.
func _do_spawn(id: int) -> Node:
	var player: Node = network_player.instantiate()
	player.name = str(id)
	# Antes todos nacian en (0,0) y quedaban superpuestos, dando la
	# impresion de un solo icono roto al entrar varios jugadores.
	# Los repartimos en circulo para que se vean por separado.
	var angle := _spawn_index * TAU / 8.0
	player.position = Vector2(cos(angle), sin(angle)) * spawn_radius
	_spawn_index += 1
	return player
