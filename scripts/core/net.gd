extends Node
## Red: ENet sobre UDP 42069 con un anfitrión autoritativo.
## En modo OFFLINE se usa el OfflineMultiplayerPeer de Godot: el jugador local
## es el servidor (id 1) y todos los caminos de código son los mismos.
##
## Contrato:
##   Net.request(action, args)        cliente -> servidor (confiable)
##   Net.request_unreliable(action, args)
##   Net.register_handler(action, callable(peer_id: int, args: Array))   (servidor)
##   Net.broadcast(event, data)       servidor -> todos (incluido el anfitrión local)
##   Net.broadcast_unreliable(event, data)
##   Net.send_to(peer_id, event, data) servidor -> un jugador
##   señal event_received(event: String, data) en todos los pares

signal event_received(event: String, data)
signal connection_state_changed(state: String, detail: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

enum Mode { NONE, OFFLINE, HOST, CLIENT }

var mode: int = Mode.NONE
var local_name := "Gomita"
var _handlers := {}
var _time_offset := 0.0
var _connect_timer: SceneTreeTimer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func is_server() -> bool:
	return mode == Mode.OFFLINE or mode == Mode.HOST


func is_online() -> bool:
	return mode == Mode.HOST or mode == Mode.CLIENT


func my_id() -> int:
	return multiplayer.get_unique_id() if mode != Mode.NONE else 1


## Clave de combatiente de un humano.
func key_for_peer(peer_id: int) -> String:
	return "P%d" % peer_id


func peer_for_key(key: String) -> int:
	if key.begins_with("P"):
		return int(key.substr(1))
	return 0


func my_key() -> String:
	return key_for_peer(my_id())


# --- sesión ---------------------------------------------------------------

func start_offline() -> void:
	close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = Mode.OFFLINE
	connection_state_changed.emit("offline", "")


func start_host(port: int = GC.PORT) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, GC.MAX_PEERS)
	if err != OK:
		connection_state_changed.emit("error", "No se pudo abrir el puerto UDP %d" % port)
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	connection_state_changed.emit("hosting", "Esperando participantes en UDP %d" % port)
	return OK


func start_client(address: String, port: int = GC.PORT) -> Error:
	close()
	address = address.strip_edges()
	if address == "" or not (address.is_valid_ip_address() or address == "localhost"):
		connection_state_changed.emit("error", "Dirección inválida")
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		connection_state_changed.emit("error", "No se pudo iniciar el cliente")
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	connection_state_changed.emit("connecting", "Conectando a %s:%d..." % [address, port])
	_connect_timer = get_tree().create_timer(8.0)
	_connect_timer.timeout.connect(func():
		if mode == Mode.CLIENT and multiplayer.multiplayer_peer and \
				multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			close()
			connection_state_changed.emit("error", "La conexión expiró"))
	return OK


func close() -> void:
	if multiplayer.multiplayer_peer and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = Mode.NONE
	_handlers.clear()


# --- reloj del servidor ---------------------------------------------------

func _local_time() -> float:
	return Time.get_ticks_msec() / 1000.0


## Reloj del servidor, sincronizado en los clientes.
func server_time() -> float:
	return _local_time() + (0.0 if is_server() else _time_offset)


func _sync_time(server_now: float) -> void:
	var target := server_now - _local_time()
	if absf(target - _time_offset) > 1.0:
		_time_offset = target
	else:
		_time_offset = lerpf(_time_offset, target, 0.2)


# --- pedidos cliente -> servidor -----------------------------------------

func register_handler(action: String, handler: Callable) -> void:
	_handlers[action] = handler


func request(action: String, args: Array = []) -> void:
	if mode == Mode.NONE:
		return
	if is_server():
		_dispatch(1, action, args)
	else:
		_rpc_request.rpc_id(1, action, args)


func request_unreliable(action: String, args: Array = []) -> void:
	if mode == Mode.NONE:
		return
	if is_server():
		_dispatch(1, action, args)
	else:
		_rpc_request_unreliable.rpc_id(1, action, args)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request(action: String, args: Array) -> void:
	if is_server():
		_dispatch(multiplayer.get_remote_sender_id(), action, args)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_request_unreliable(action: String, args: Array) -> void:
	if is_server():
		_dispatch(multiplayer.get_remote_sender_id(), action, args)


func _dispatch(peer_id: int, action: String, args) -> void:
	if not (args is Array):
		return
	var h: Callable = _handlers.get(action, Callable())
	if h.is_valid():
		h.call(peer_id, args)


# --- eventos servidor -> clientes ----------------------------------------

func broadcast(event: String, data = null) -> void:
	if not is_server():
		return
	if mode == Mode.HOST:
		_rpc_event.rpc(event, data, server_time())
	event_received.emit(event, data)


func broadcast_unreliable(event: String, data = null) -> void:
	if not is_server():
		return
	if mode == Mode.HOST:
		_rpc_event_unreliable.rpc(event, data, server_time())
	event_received.emit(event, data)


func send_to(peer_id: int, event: String, data = null) -> void:
	if not is_server():
		return
	if peer_id == my_id():
		event_received.emit(event, data)
	elif mode == Mode.HOST and peer_id in multiplayer.get_peers():
		_rpc_event.rpc_id(peer_id, event, data, server_time())


@rpc("authority", "call_remote", "reliable")
func _rpc_event(event: String, data, server_now: float) -> void:
	_sync_time(server_now)
	event_received.emit(event, data)


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_event_unreliable(event: String, data, server_now: float) -> void:
	_sync_time(server_now)
	event_received.emit(event, data)


# --- conexión -------------------------------------------------------------

func _on_peer_connected(peer_id: int) -> void:
	if is_server():
		peer_joined.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if is_server():
		peer_left.emit(peer_id)


func _on_connected() -> void:
	connection_state_changed.emit("connected", "Conectado")


func _on_connection_failed() -> void:
	close()
	connection_state_changed.emit("error", "La conexión fue rechazada")


func _on_server_disconnected() -> void:
	close()
	connection_state_changed.emit("disconnected", "Se perdió la conexión con el anfitrión")
