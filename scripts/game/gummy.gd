class_name Gummy
extends CharacterBody2D
## Personaje (gomita) de un humano o de un bot.
## El nodo se llama como la clave del combatiente ("P<peer>" o "B<n>") y vive en G.characters.
## La posición del nodo son los PIES del personaje (px, Y hacia abajo).
##
## Física: el par que "controla localmente" (su humano, o el servidor para los bots)
## simula con: velocidad de caminata, salto con JumpPower,
## gravedad del juego (230) y fijación al plano 2D.
## El resto de los pares lo muestra como títere interpolado.

signal attr_changed(key: String, value)

## Gravedad del juego, en studs/s².
const GRAVITY_STUDS := 230.0
## Hitbox (2,4 x 5,6 studs + 0,4 de cadera): del pie hasta 6 studs.
const BODY_WIDTH_STUDS := 2.4
const BODY_HEIGHT_STUDS := 6.0
const HITBOX_BOTTOM_STUDS := 0.4
## Respuesta del movimiento: qué tan rápido alcanza la velocidad pedida (1/s).
const GROUND_ACCEL := 40.0
const AIR_ACCEL := 12.0
const MAX_FALL_STUDS := 260.0
## Atributos que no viajan por CharAttrs (van en CharSnap).
const NO_REPLICATE := {"Aim": true}

var attrs := {}
var move_input := 0.0
var jump_input := false
var controlled_locally := false
## Número de aparición (lo usa la validación de Move para descartar paquetes viejos).
var spawn_seq := 0
var rig: Node2D

var _dirty := {}
var _remote_pos := Vector2.ZERO
var _remote_vel := Vector2.ZERO
var _remote_time := 0.0
var _remote_grounded := true
var _remote_rate := 18.0
var _has_remote := false


func _init() -> void:
	collision_layer = 0
	collision_mask = GC.LAYER_WORLD | GC.LAYER_BUILT_USA | GC.LAYER_BUILT_VN | GC.LAYER_BARRIER
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(50.0)
	safe_margin = 0.1


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(BODY_WIDTH_STUDS, BODY_HEIGHT_STUDS) * GC.STUD
	var col := CollisionShape2D.new()
	col.name = "Shape"
	col.shape = shape
	col.position = Vector2(0, -BODY_HEIGHT_STUDS * 0.5 * GC.STUD)
	add_child(col)
	var rig_script: Script = load("res://scripts/game/gummy_rig.gd")
	rig = rig_script.new()
	rig.name = "Rig"
	add_child(rig)
	_apply_team_layer()


# --- atributos -------------------------------------------------------------

func get_attr(k: String, def = null):
	return attrs.get(k, def)


func set_attr(k: String, v) -> void:
	if attrs.has(k) and typeof(attrs[k]) == typeof(v) and attrs[k] == v:
		return
	attrs[k] = v
	if Net.is_server() and not NO_REPLICATE.has(k):
		_dirty[k] = v
	if k == "Team":
		_apply_team_layer()
	attr_changed.emit(k, v)


## Reemplaza/mezcla varios atributos (los que llegan por red no se vuelven a marcar).
func apply_attrs(data: Dictionary, mark_dirty: bool = false) -> void:
	for k in data:
		attrs[k] = data[k]
		if mark_dirty and Net.is_server() and not NO_REPLICATE.has(k):
			_dirty[k] = data[k]
		attr_changed.emit(k, data[k])
	if data.has("Team"):
		_apply_team_layer()


## Atributos cambiados desde la última vez (servidor -> CharAttrs).
func take_dirty() -> Dictionary:
	if _dirty.is_empty():
		return {}
	var d := _dirty
	_dirty = {}
	return d


func _apply_team_layer() -> void:
	var t: String = attrs.get("Team", "")
	collision_layer = GC.char_layer(t) if t != "" else 0


# --- consultas ---------------------------------------------------------------

func key() -> String:
	return attrs.get("Key", String(name))


func team() -> String:
	return attrs.get("Team", "")


func is_alive() -> bool:
	if attrs.get("Dead", false):
		return false
	return float(attrs.get("Health", 1.0)) > 0.0


func is_protected() -> bool:
	return Net.server_time() < float(attrs.get("ProtectedUntil", 0.0))


## Velocidad de caminata actual en studs/s.
func walk_speed() -> float:
	var base: float = float(attrs.get("BaseSpeed", 14.0))
	var mult: float = float(attrs.get("SpeedMult", 1.0))
	return base * mult


func grounded() -> bool:
	if controlled_locally:
		return is_on_floor()
	return _remote_grounded


func feet_position() -> Vector2:
	return global_position


func shoulder_position() -> Vector2:
	return global_position + Vector2(0, -GC.CHARACTER["shoulder_height"] * GC.STUD)


func muzzle_position(angle: float) -> Vector2:
	return shoulder_position() + GC.angle_to_dir(angle) * GC.CHARACTER["muzzle_distance"] * GC.STUD


func center_position() -> Vector2:
	return global_position + Vector2(0, -GC.CHARACTER["feet_offset"] * GC.STUD)


## "" | "body" | "head". point en px (mundo), radius_px el radio del proyectil.
func hit_test(point: Vector2, radius_px: float) -> String:
	if not is_alive():
		return ""
	var rel := point - global_position
	var half_w := BODY_WIDTH_STUDS * 0.5 * GC.STUD
	var top := -BODY_HEIGHT_STUDS * GC.STUD
	var bottom := -HITBOX_BOTTOM_STUDS * GC.STUD
	var cx := clampf(rel.x, -half_w, half_w)
	var cy := clampf(rel.y, top, bottom)
	if Vector2(rel.x - cx, rel.y - cy).length() > radius_px:
		return ""
	var height_studs := -rel.y / GC.STUD
	return "head" if height_studs >= GC.CHARACTER["headshot_height"] else "body"


# --- acciones ----------------------------------------------------------------

func apply_knockback(velocity_px: Vector2) -> void:
	velocity += velocity_px


func teleport(pos_px: Vector2) -> void:
	global_position = pos_px
	velocity = Vector2.ZERO
	_remote_pos = pos_px
	_remote_vel = Vector2.ZERO
	_remote_time = Net.server_time()
	_has_remote = false
	if rig and rig.has_method("reset_state"):
		rig.reset_state()


## Estado que llega por red para un títere (Move en el servidor, CharSnap en clientes).
## rate: suavizado de la interpolación (1/s). t: hora del servidor del dato.
func apply_remote_state(pos: Vector2, vel: Vector2, on_floor: bool, t: float, rate: float = 18.0) -> void:
	_remote_pos = pos
	_remote_vel = vel
	_remote_time = t
	_remote_grounded = on_floor
	_remote_rate = rate
	if not _has_remote or pos.distance_to(global_position) > 96.0:
		global_position = pos
	_has_remote = true


# --- simulación --------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if controlled_locally:
		_simulate(delta)
	else:
		_follow_remote(delta)


func _simulate(delta: float) -> void:
	var alive := is_alive()
	var target := (clampf(move_input, -1.0, 1.0) * walk_speed() * GC.STUD) if alive else 0.0
	var on_floor := is_on_floor()
	var accel := GROUND_ACCEL if on_floor else AIR_ACCEL
	if not alive and on_floor:
		accel = 8.0
	velocity.x += (target - velocity.x) * minf(1.0, delta * accel)
	velocity.y += GRAVITY_STUDS * GC.STUD * delta
	if alive and jump_input and on_floor:
		velocity.y = -float(attrs.get("JumpPower", 66.0)) * GC.STUD
	velocity.y = minf(velocity.y, MAX_FALL_STUDS * GC.STUD)
	move_and_slide()
	# red de seguridad: si se cae del mapa, vuelve a la base
	if global_position.y > 60.0 * GC.STUD or absf(global_position.x) > 300.0 * GC.STUD:
		var cs := G.system("Character") if Net.is_server() else null
		if cs and cs.has_method("get_spawn_point"):
			teleport(cs.get_spawn_point(team()))
		else:
			teleport(Vector2(GC.TEAM_INFO.get(team(), {"side": -1})["side"] * 232.0 * GC.STUD, -GC.STUD))


func _follow_remote(delta: float) -> void:
	if not _has_remote:
		return
	var age := clampf(Net.server_time() - _remote_time, 0.0, 0.12)
	var target := _remote_pos + _remote_vel * age
	global_position = global_position.lerp(target, 1.0 - exp(-delta * _remote_rate))
	velocity = _remote_vel


# --- barreras del interludio (fallback si el mapa no las implementa) ---------

static func ensure_barriers(on: bool) -> void:
	if G.map and G.map.has_method("set_barriers"):
		G.map.set_barriers(on)
		return
	if G.world == null:
		return
	var root: Node2D = G.world.get_node_or_null("PrepBarriers")
	if root == null:
		if not on:
			return
		root = Node2D.new()
		root.name = "PrepBarriers"
		G.world.add_child(root)
		var map_data: Script = load("res://data/map_frente_caramelo.gd")
		var xs: Array = [-114.0, 114.0]
		if map_data:
			xs = map_data.get_script_constant_map().get("PREP_BARRIERS", xs)
		for x in xs:
			var body := StaticBody2D.new()
			body.collision_layer = GC.LAYER_BARRIER
			body.collision_mask = 0
			body.position = GC.studs_to_px(Vector2(float(x), 40.0))
			var shape := RectangleShape2D.new()
			shape.size = Vector2(1.0, 80.0) * GC.STUD
			var col := CollisionShape2D.new()
			col.shape = shape
			body.add_child(col)
			root.add_child(body)
	for body in root.get_children():
		for col in body.get_children():
			if col is CollisionShape2D:
				col.set_deferred("disabled", not on)
