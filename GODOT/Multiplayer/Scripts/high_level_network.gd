extends Control

enum State { IDLE, CONNECTING, CONNECTED }

## Tecla para mostrar/ocultar el menu manualmente en cualquier momento.
@export var toggle_key: Key = KEY_TAB

@onready var menu_container: CenterContainer = $CanvasLayer/MenuContainer
@onready var hint_label: Label = $CanvasLayer/HintLabel
@onready var ip_input: LineEdit = $CanvasLayer/MenuContainer/MenuPanel/Margin/VBoxContainer/IPInput
@onready var status_label: Label = $CanvasLayer/MenuContainer/MenuPanel/Margin/VBoxContainer/StatusLabel
@onready var server_button: Button = $CanvasLayer/MenuContainer/MenuPanel/Margin/VBoxContainer/Server
@onready var cliente_button: Button = $CanvasLayer/MenuContainer/MenuPanel/Margin/VBoxContainer/Cliente
@onready var cancelar_button: Button = $CanvasLayer/MenuContainer/MenuPanel/Margin/VBoxContainer/Cancelar

var _state: State = State.IDLE


func _ready() -> void:
	HighLevelNetworkHandler.server_started.connect(_on_server_started)
	HighLevelNetworkHandler.server_start_failed.connect(_on_server_start_failed)
	HighLevelNetworkHandler.client_connected.connect(_on_client_connected)
	HighLevelNetworkHandler.client_connection_failed.connect(_on_client_connection_failed)
	HighLevelNetworkHandler.client_disconnected.connect(_on_client_disconnected)

	_set_state(State.IDLE)
	_update_hint()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == toggle_key:
			_toggle_menu()
			get_viewport().set_input_as_handled()


func _toggle_menu() -> void:
	menu_container.visible = not menu_container.visible
	_update_hint()


func _on_server_pressed() -> void:
	_set_state(State.CONNECTING)
	_set_status("Iniciando servidor...")
	HighLevelNetworkHandler.start_server()


func _on_cliente_pressed() -> void:
	var ip := ip_input.text.strip_edges()

	if ip.is_empty():
		_set_status("Escribi la IP del host antes de conectar.")
		return

	if not _is_valid_ipv4(ip):
		_set_status("IP invalida: %s" % ip)
		return

	_set_state(State.CONNECTING)
	HighLevelNetworkHandler.start_client(ip)
	_set_status("Conectando a %s..." % ip)


# Corta lo que este pasando (intento de conexion, servidor activo o
# cliente conectado) y vuelve al menu inicial para elegir host o
# cliente de nuevo.
func _on_cancelar_pressed() -> void:
	HighLevelNetworkHandler.cancel()
	_set_state(State.IDLE)
	_set_status("Cancelado. Elegi host o cliente.")
	menu_container.visible = true
	_update_hint()


func _on_server_started(local_ips: PackedStringArray) -> void:
	if local_ips.is_empty():
		_set_status("Servidor iniciado. No se detecto IP de LAN.")
	else:
		_set_status("Servidor iniciado. IP: %s" % local_ips[0])
	_set_state(State.CONNECTED)
	_close_menu()


func _on_client_connected() -> void:
	_set_status("Conectado.")
	_set_state(State.CONNECTED)
	_close_menu()


func _close_menu() -> void:
	menu_container.visible = false
	_update_hint()


func _on_server_start_failed(error: int, error_text: String) -> void:
	_set_status("Error al iniciar el servidor: %s" % error_text)
	_set_state(State.IDLE)


func _on_client_connection_failed() -> void:
	_set_status("No se pudo conectar al servidor.")
	_set_state(State.IDLE)


func _on_client_disconnected() -> void:
	_set_status("Se perdio la conexion con el servidor.")
	_set_state(State.IDLE)
	menu_container.visible = true
	_update_hint()


# Controla que botones estan habilitados/visibles segun en que
# etapa esta la conexion. Cancelar/Desconectar aparece apenas se
# arranca un intento y se puede usar tanto mientras conecta como
# despues de estar ya conectado.
func _set_state(state: State) -> void:
	_state = state
	match state:
		State.IDLE:
			server_button.disabled = false
			cliente_button.disabled = false
			cancelar_button.visible = false
		State.CONNECTING:
			server_button.disabled = true
			cliente_button.disabled = true
			cancelar_button.visible = true
			cancelar_button.text = "Cancelar"
		State.CONNECTED:
			server_button.disabled = true
			cliente_button.disabled = true
			cancelar_button.visible = true
			cancelar_button.text = "Desconectar"


func _is_valid_ipv4(ip: String) -> bool:
	var parts := ip.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if not part.is_valid_int():
			return false
		var n := int(part)
		if n < 0 or n > 255:
			return false
	return true


func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text


func _update_hint() -> void:
	if not hint_label:
		return
	var key_name := OS.get_keycode_string(toggle_key)
	if menu_container.visible:
		hint_label.text = "[%s] Ocultar menu" % key_name
	else:
		hint_label.text = "[%s] Mostrar menu" % key_name
