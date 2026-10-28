extends Node
## InputController (cliente): controles 2D del personaje local.
##   A/D mover, Espacio/W saltar, mouse apuntar, click disparar, R recargar,
##   G granada, F listo (solo en el interludio).
## B (construir) y T (tienda) los manejan sus propios controladores.
## Simula la física del personaje local (controlled_locally) y la manda al
## servidor con "Move" [pos, vel, flags, aim] (unreliable, ~30 Hz).

const AIM_SEND_RATE := 1.0 / 20.0
const MOVE_SEND_RATE := 1.0 / 30.0
const COMBAT_UTIL_PATH := "res://scripts/game/combat_util.gd"

var _fire_held := false
var _trigger_released := true
var _last_fire := -100.0
var _last_aim_sent := 0.0
var _last_aim_value := 999.0
var _last_move_sent := 0.0
var _move_current := 0.0
var _was_grounded := true
var _air_time := 0.0
var _land_slow := 0.0
var _combat_util: Script
var _combat_util_checked := false


func _ready() -> void:
	process_priority = -10   # antes que la cámara y el resto
	Net.event_received.connect(_on_event)
	G.session_ended.connect(_reset)


func _reset() -> void:
	_fire_held = false
	_trigger_released = true
	_move_current = 0.0
	_land_slow = 0.0


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _camera() -> Node:
	return G.controller("Camera")


## Cambiar de clase (lo usan el menú/HUD).
func select_class(class_id: String) -> void:
	Net.request("SelectClass", [class_id])


func _local() -> Gummy:
	if Net.mode == Net.Mode.NONE:
		return null
	return G.local_character() as Gummy


func _alive_local() -> Gummy:
	var ch := _local()
	if ch == null or not ch.is_alive() or not ch.controlled_locally:
		return null
	return ch


func _blocked() -> bool:
	return G.menu_open or G.ui_open or G.cinematic


# --- entrada ------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire"):
		_fire_held = true
		return
	if event.is_echo():
		return
	if G.menu_open:
		return
	if event.is_action_pressed("reload"):
		if _alive_local():
			Net.request("Reload", [])
	elif event.is_action_pressed("grenade"):
		var ch := _alive_local()
		if ch and int(ch.get_attr("Grenades", 0)) > 0 and not G.ui_open:
			Net.request("Grenade", [G.aim_angle])
	elif event.is_action_pressed("ready"):
		if MatchState.phase() == "Prep" and MatchState.my_player("Deployed", false):
			var ready: bool = MatchState.my_player("Ready", false) == true
			Net.request("SetReady", [not ready])


func _input(event: InputEvent) -> void:
	if event.is_action_released("fire"):
		_fire_held = false
		_trigger_released = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_fire_held = false
		_trigger_released = true


func _on_event(event: String, data) -> void:
	if event == "Knockback" and data is Dictionary:
		var ch := _alive_local()
		var v = data.get("velocity")
		if ch and v is Vector2:
			ch.apply_knockback(v)


# --- cada frame -----------------------------------------------------------------

func _process(delta: float) -> void:
	if G.world:
		G.mouse_world = G.world.get_global_mouse_position()
	var ch := _local()
	if ch == null or not ch.controlled_locally:
		return
	var alive := ch.is_alive()
	var blocked := _blocked()

	# Movimiento con inercia (equipo pesado) y aterrizaje pesado
	var target := 0.0
	if alive and not blocked:
		target = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var grounded := ch.is_on_floor()
	var accel := (8.0 if target == 0.0 else 4.5) if grounded else 2.0
	_move_current += (target - _move_current) * minf(1.0, delta * accel)
	if grounded and not _was_grounded and _air_time > 0.45:
		_land_slow = 0.35
		var cam := _camera()
		if cam:
			cam.kick(Vector2(0, minf(_air_time, 1.2) * 1.4 * GC.STUD))
			cam.shake(minf(_air_time * 0.45, 0.6))
	_air_time = 0.0 if grounded else _air_time + delta
	_was_grounded = grounded
	_land_slow = maxf(0.0, _land_slow - delta)
	var mult := 1.0 - (_land_slow / 0.35) * 0.7
	ch.move_input = _move_current * mult
	ch.jump_input = alive and not blocked and _land_slow < 0.15 and Input.is_action_pressed("jump")

	# Apuntado
	var d := G.mouse_world - ch.shoulder_position()
	if d.length_squared() > 0.01:
		G.aim_angle = GC.dir_to_angle(d)
	if alive:
		ch.set_attr("Aim", G.aim_angle)
	var now := _now()
	if not Net.is_server():
		if now - _last_aim_sent >= AIM_SEND_RATE and absf(G.aim_angle - _last_aim_value) > 0.001:
			_last_aim_sent = now
			_last_aim_value = G.aim_angle
			Net.request_unreliable("Aim", [G.aim_angle])
		if now - _last_move_sent >= MOVE_SEND_RATE:
			_last_move_sent = now
			var flags := (1 if grounded else 0) | ((ch.spawn_seq & 0xFF) << 8)
			Net.request_unreliable("Move", [ch.global_position, ch.velocity, flags, G.aim_angle])

	# Disparo
	if _fire_held and alive and not blocked and not G.build_mode:
		_try_fire(ch)


func _spread_angles(weapon_id: String, aim: float, moving: bool) -> Array:
	if not _combat_util_checked:
		_combat_util_checked = true
		if ResourceLoader.exists(COMBAT_UTIL_PATH):
			var s: Script = load(COMBAT_UTIL_PATH)
			if s:
				for m in s.get_script_method_list():
					if m.get("name", "") == "spread_angles":
						_combat_util = s
						break
	if _combat_util:
		var r = _combat_util.call("spread_angles", weapon_id, aim, moving)
		if r is Array and not r.is_empty():
			return r
	return [aim]


func _try_fire(ch: Gummy) -> void:
	var weapon_id: String = str(ch.get_attr("Weapon", "Rifle"))
	var weapon := Data.get_weapon(weapon_id)
	var now := _now()
	if now - _last_fire < float(weapon.get("fire_rate", 0.2)) or ch.get_attr("Reloading", false) == true:
		return
	if not weapon.get("automatic", false) and not _trigger_released:
		return
	var ammo := int(ch.get_attr("Ammo", 0))
	if ammo <= 0:
		if _trigger_released:
			Net.request("Reload", [])
		_trigger_released = false
		return
	_trigger_released = false
	_last_fire = now
	ch.attrs["Ammo"] = ammo - 1   # predicción local; el servidor confirma
	var v := ch.velocity / GC.STUD
	var moving := absf(v.x) > 2.0 or absf(v.y) > 4.0
	var angles := _spread_angles(weapon_id, G.aim_angle, moving)
	Net.request("Fire", [angles])
	var cam := _camera()
	if cam:
		cam.shake(float(weapon.get("shake", 0.1)))
		cam.kick(-GC.angle_to_dir(G.aim_angle) * float(weapon.get("recoil", 1.0)) * 0.06 * GC.STUD)
