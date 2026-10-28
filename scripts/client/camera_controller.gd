extends Node
## CameraController (cliente): cámara lateral estilo juego flash.
## Sigue al personaje local, se adelanta hacia el mouse, tiene sacudidas
## (shake) y empujones (kick) y hace un paneo lento sobre el mapa con el menú abierto.
## Se ven ~38,6 studs de alto.

const BASE_DISTANCE := 72.0
const MIN_X_STUDS := -260.0
const MAX_X_STUDS := 260.0
const MIN_Y_STUDS := 4.0
const MAX_Y_STUDS := 44.0

var camera: Camera2D
## Opcional: {focus: Vector2 px, distance: float, speed: float} (cinemáticas)
var override := {}

var _focus := Vector2.ZERO
var _has_focus := false
var _distance := BASE_DISTANCE
var _menu_t := 0.0
var _shake := 0.0
var _kick := Vector2.ZERO
var _noise := FastNoiseLite.new()


func _ready() -> void:
	process_priority = 10   # después del input y la física del personaje
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 1.0
	camera = Camera2D.new()
	camera.name = "GameCamera"
	camera.ignore_rotation = false
	camera.position_smoothing_enabled = false
	G.camera = camera
	if G.world:
		G.world.add_child.call_deferred(camera)
	else:
		add_child(camera)
	camera.ready.connect(func(): camera.make_current(), CONNECT_ONE_SHOT)


## Sacudida de cámara.
func shake(amount: float) -> void:
	var mult: float = float(G.settings.get("shake", 1.0))
	_shake = minf(_shake + amount * mult, 3.0)


## Empujón de cámara en px (retroceso, explosiones, aterrizajes).
func kick(vec: Vector2) -> void:
	_kick += vec


func _visible_height_px(distance: float) -> float:
	return GC.CAMERA["visible_height_studs"] * GC.STUD * distance / BASE_DISTANCE


func _process(delta: float) -> void:
	if camera == null:
		return
	var target_distance := BASE_DISTANCE
	var ch := G.local_character() if Net.mode != Net.Mode.NONE else null
	var deployed: bool = Net.mode != Net.Mode.NONE and MatchState.my_player("Deployed", false) == true
	var target := _focus
	var rate := 5.5
	if not override.is_empty():
		target = override.get("focus", _focus)
		target_distance = float(override.get("distance", BASE_DISTANCE))
		rate = float(override.get("speed", 3.0))
	elif (G.menu_open and not deployed) or ch == null:
		# paneo lento sobre el campo de batalla
		_menu_t += delta
		var x := sin(_menu_t * 0.08) * 70.0
		target = GC.studs_to_px(Vector2(x, 14.0 + sin(_menu_t * 0.21) * 3.0))
		rate = 2.0
		target_distance = BASE_DISTANCE + 22.0
	else:
		var feet: Vector2 = ch.global_position
		target = feet + Vector2(0, -(GC.CHARACTER["feet_offset"] + GC.CAMERA["height_offset"]) * GC.STUD)
		var look := (G.mouse_world - target) * GC.CAMERA["look_ahead"]
		var max_look: float = GC.CAMERA["max_look_ahead"] * GC.STUD
		if look.length() > max_look:
			look = look.normalized() * max_look
		target += look
		if MatchState.phase() == "Prep" or G.build_mode:
			target_distance = BASE_DISTANCE + 12.0
	if not _has_focus:
		_focus = target
		_has_focus = true
	else:
		_focus = _focus.lerp(target, 1.0 - exp(-delta * rate))
	_distance += (target_distance - _distance) * (1.0 - exp(-delta * 3.0))

	var shake_off := Vector2.ZERO
	var roll := 0.0
	if _shake > 0.001:
		var tt := Time.get_ticks_msec() / 1000.0 * 40.0
		shake_off = Vector2(_noise.get_noise_2d(tt, 0.0), _noise.get_noise_2d(0.0, tt)) * _shake * 2.2 * GC.STUD
		if _shake > 0.05:
			roll = _noise.get_noise_2d(tt * 0.6, 7.0) * _shake * 0.03
		_shake *= exp(-delta * 9.0)
	_kick *= exp(-delta * 14.0)
	_apply(_focus, _distance, roll, shake_off + _kick)


func _apply(focus: Vector2, distance: float, roll: float, extra: Vector2 = Vector2.ZERO) -> void:
	var vp := camera.get_viewport_rect().size if camera.is_inside_tree() else Vector2(1280, 720)
	if vp.y <= 0.0:
		vp = Vector2(1280, 720)
	var view_h := _visible_height_px(distance)
	var z := vp.y / view_h
	camera.zoom = Vector2(z, z)
	var half_w := vp.x / z * 0.5
	var min_x := MIN_X_STUDS * GC.STUD
	var max_x := MAX_X_STUDS * GC.STUD
	var fx := focus.x
	if min_x + half_w < max_x - half_w:
		fx = clampf(fx, min_x + half_w, max_x - half_w)
	else:
		fx = (min_x + max_x) * 0.5
	var fy := clampf(focus.y, -MAX_Y_STUDS * GC.STUD, -MIN_Y_STUDS * GC.STUD)
	camera.global_position = Vector2(fx, fy) + extra
	camera.rotation = roll
