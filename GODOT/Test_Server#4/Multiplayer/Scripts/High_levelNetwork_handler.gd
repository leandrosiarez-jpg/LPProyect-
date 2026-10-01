extends Node

signal server_started(local_ips: PackedStringArray)
signal server_start_failed(error: int, error_text: String)
signal client_connected
signal client_connection_failed
signal client_disconnected
signal network_stopped

const PORT: int = 42069
const MAX_PLAYERS: int = 8
const CONNECTION_TIMEOUT: float = 8.0

var peer: ENetMultiplayerPeer
var _connect_timeout_timer: Timer


func start_server() -> void:
	cancel()
	peer = ENetMultiplayerPeer.new()

	var error := peer.create_server(PORT, MAX_PLAYERS)

	if error != OK:
		var msg := error_string(error)
		print("ERROR AL CREAR SERVIDOR (%d): %s" % [error, msg])
		server_start_failed.emit(error, msg)
		return

	multiplayer.multiplayer_peer = peer

	var ips := _get_lan_addresses()
	print("SERVIDOR INICIADO")
	print("PUERTO: ", PORT)
	print("IP(s) PARA EL CLIENTE: ", ips)

	server_started.emit(ips)


func start_client(ip: String) -> void:
	cancel()
	peer = ENetMultiplayerPeer.new()

	var error := peer.create_client(ip, PORT)

	if error != OK:
		var msg := error_string(error)
		print("ERROR AL CREAR CLIENTE (%d): %s" % [error, msg])
		client_connection_failed.emit()
		return

	multiplayer.multiplayer_peer = peer

	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		multiplayer.connection_failed.connect(_on_connection_failed)
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	_start_connection_timeout()

	print("CONECTANDO A: ", ip, ":", PORT)


# Corta el servidor o la conexion actual, en cualquier etapa (todavia
# conectando, o ya conectado/hosteando). Deja todo listo para que se
# pueda arrancar de nuevo como host o como cliente sin reiniciar la app.
func cancel() -> void:
	var was_active := multiplayer.multiplayer_peer != null or peer != null

	if _connect_timeout_timer:
		_connect_timeout_timer.stop()

	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
		multiplayer.connection_failed.disconnect(_on_connection_failed)
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)

	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	peer = null

	if was_active:
		print("RED DETENIDA POR EL USUARIO")
		network_stopped.emit()


# Si el server no responde (IP mal escrita, firewall, puerto cerrado),
# ENet puede tardar mucho tiempo en avisar el fallo. Este timeout
# fuerza un aviso mas rapido al usuario.
func _start_connection_timeout() -> void:
	if _connect_timeout_timer == null:
		_connect_timeout_timer = Timer.new()
		_connect_timeout_timer.one_shot = true
		add_child(_connect_timeout_timer)
		_connect_timeout_timer.timeout.connect(_on_connection_timeout)
	_connect_timeout_timer.start(CONNECTION_TIMEOUT)


func _on_connection_timeout() -> void:
	var still_connecting := multiplayer.multiplayer_peer != null \
		and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED
	if still_connecting:
		print("TIMEOUT: no se pudo conectar en %ds" % CONNECTION_TIMEOUT)
		_on_connection_failed()


func _on_connected_to_server() -> void:
	if _connect_timeout_timer:
		_connect_timeout_timer.stop()
	print("CONECTADO AL SERVIDOR")
	client_connected.emit()


func _on_connection_failed() -> void:
	if _connect_timeout_timer:
		_connect_timeout_timer.stop()
	print("FALLO LA CONEXION")
	client_connection_failed.emit()


func _on_server_disconnected() -> void:
	print("SERVIDOR DESCONECTADO")
	client_disconnected.emit()


func _get_lan_addresses() -> PackedStringArray:
	var result := PackedStringArray()
	for ip in IP.get_local_addresses():
		if _is_private_lan_ip(ip):
			result.append(ip)
	return result


# Filtra IPv4 privadas reales (192.168.x.x, 10.x.x.x, 172.16-31.x.x) y
# descarta localhost, link-local (169.254.x.x) e IPv6. El filtro anterior
# solo sacaba localhost e IPv6, asi que adaptadores virtuales (VPN,
# Docker, Hyper-V, etc.) tambien aparecian y confundian a los usuarios
# sobre cual IP pasarle realmente a sus amigos.
func _is_private_lan_ip(ip: String) -> bool:
	if ip.count(".") != 3:
		return false
	if ip.begins_with("127.") or ip.begins_with("169.254."):
		return false
	if ip.begins_with("192.168.") or ip.begins_with("10."):
		return true
	if ip.begins_with("172."):
		var second := int(ip.split(".")[1])
		return second >= 16 and second <= 31
	return false
