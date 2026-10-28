extends Node2D
## Rig 2D de la gomita: sprites por partes.
## Torso, cabeza, casco, manos, arma, fogonazo, corona VIP y bandera son sprites
## originales (Sprites.tex) que se colocan cada frame: apuntado, caminata, squash & stretch, inclinación, recarga,
## cerrojo, retroceso, tinte de daño/quemadura, parpadeo de protección y muerte
## (las mismas piezas-sprite salen volando, como FX.Piece).
##
## Coordenadas internas en unidades de rig (Sprites.UNIT_STUDS), origen en los pies,
## Y hacia ARRIBA; se convierten a px con UPX e invirtiendo Y.

const WHITE := Color(1, 1, 1)
const HIT_COLOR := Color8(255, 90, 90)
const BURN_COLOR := Color8(255, 160, 60)
const STUD := 8.0

## Orden de dibujo (FlagPole 1 ... Crown 8)
const PART_ORDER := ["FlagPole", "Torso", "Head", "Hat", "Gun", "RearHand", "FrontHand", "Flash", "Crown"]

var t := randf() * 10.0
var aim := 0.0
var facing := 1
var recoil := 0.0
var flash := 0.0
var flash_scale := 0.8
var hit_flash := 0.0
var hit_dir := 0.0
var walk_clock := 0.0
var step_count := 0
var was_grounded := true
var air_time := 0.0
var squash := 0.0
var stretch := 0.0
var lean := 0.0
var reload_t := 0.0
var flame_until := 0.0
var dead := false
var bolt_start := -1.0
var bolt_dur := 0.8
var headshotted := false
## Boca del arma y expulsión de casquillos según el dibujo (px, mundo)
var muzzle_world := Vector2.ZERO
var shell_world := Vector2.ZERO

var UPX := 0.96
var _parts := {}      # nombre -> Sprite2D
var _tints := {}      # nombre -> Color (part.Tint)
var _overlay: Node2D


class Piece extends Sprite2D:
	## FX.Piece: pedazo-sprite del personaje (Gravity 95, Life 9, Bounce 0.25, Drag 0.4, FadeLast 2)
	var vel := Vector2.ZERO        # studs/s, Y arriba
	var gravity := 95.0
	var rot_vel := 0.0             # grados/s
	var floor_y := 0.0             # px (mundo, Y abajo)
	var age := 0.0
	const LIFE := 9.0
	const FADE_LAST := 2.0

	func _process(dt: float) -> void:
		age += dt
		if age >= LIFE:
			queue_free()
			return
		vel += Vector2(0, -gravity * dt)
		vel *= exp(-0.4 * dt)
		var pos := global_position + Vector2(vel.x, -vel.y) * 8.0 * dt
		if pos.y > floor_y:
			pos.y = floor_y
			vel = Vector2(vel.x * 0.5, -vel.y * 0.25)
			rot_vel *= 0.5
			if absf(vel.y) < 2.0:
				vel = Vector2(vel.x * 0.8, 0.0)
				rot_vel *= 0.6
				gravity = 0.0
		global_position = pos
		rotation_degrees += rot_vel * dt
		var left := LIFE - age
		if left < FADE_LAST:
			modulate.a = left / FADE_LAST


func _ready() -> void:
	UPX = Sprites.unit_px()
	for n in PART_ORDER:
		var s := Sprite2D.new()
		s.name = n
		s.centered = true
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.visible = false
		add_child(s)
		_parts[n] = s
		_tints[n] = WHITE
	_overlay = Node2D.new()
	_overlay.name = "Overlay"
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	var ch := _ch()
	if ch:
		aim = float(ch.get_attr("Aim", 0.0))


func _ch() -> Node:
	return get_parent()


func _attr(k: String, def = null):
	var ch := _ch()
	if ch == null or not ("attrs" in ch):
		return def
	return ch.attrs.get(k, def)


func _team() -> String:
	return str(_attr("Team", "USA"))


func _is_local() -> bool:
	return String(_ch().name) == Net.my_key() and Net.mode != Net.Mode.NONE


func reset_state() -> void:
	dead = false
	recoil = 0.0
	flash = 0.0
	hit_flash = 0.0
	hit_dir = 0.0
	reload_t = 0.0
	bolt_start = -1.0
	squash = 0.0
	stretch = 0.0
	lean = 0.0
	air_time = 0.0
	walk_clock = 0.0
	headshotted = false
	visible = true


static func _wrap(a: float) -> float:
	return atan2(sin(a), cos(a))


static func _rot(v: Vector2, a: float) -> Vector2:
	var c := cos(a)
	var s := sin(a)
	return Vector2(v.x * c - v.y * s, v.x * s + v.y * c)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _weapon_id() -> String:
	var cls: String = str(_attr("Class", Data.DEFAULT_CLASS))
	var w = _attr("Weapon", "")
	if w is String and w != "":
		return w
	return Data.get_class_data(cls)["default_weapon"]


func _visual() -> Dictionary:
	var weapon := Data.get_weapon(_weapon_id())
	return Sprites.weapon_visual(str(weapon.get("visual", "Rifle")))


func _rig_def() -> Dictionary:
	return Sprites.RIGS.get(str(_attr("Class", "Soldier")), Sprites.RIGS["Soldier"])


func _fx(kind: String, pos: Vector2, params: Dictionary = {}) -> void:
	if G.fx and is_instance_valid(G.fx) and G.fx.has_method("spawn"):
		G.fx.spawn(kind, pos, params)


func _sound(sound_name: String, pos: Vector2, vol_db := 0.0, pitch := 1.0) -> void:
	var snd = G.controller("Sound")
	if snd and snd.has_method("play"):
		snd.play(sound_name, pos, vol_db, pitch)


## Rig (unidades, Y arriba, relativo a los pies) -> px locales
func _px(x: float, y: float) -> Vector2:
	return Vector2(x, -y) * UPX


## draw(): x, y en unidades de rig; rot en grados de pantalla (horario)
func _draw_part(part: String, sprite_name: String, x: float, y: float, sx: float, sy: float,
		rot: float, flip: bool, tint: Color) -> void:
	var s: Sprite2D = _parts[part]
	var tex := Sprites.tex(sprite_name)
	if s.texture != tex:
		s.texture = tex
	s.flip_h = flip
	s.position = _px(x, y)
	s.scale = Vector2(sx, sy) * UPX
	s.rotation_degrees = rot
	s.visible = true
	_tints[part] = tint


func _hide(part: String) -> void:
	_parts[part].visible = false


# --- eventos -------------------------------------------------------------------

## Efecto de disparo (lo llama CharacterReplicator con el evento Projectile).
func on_fire(projectile_kind: String = "") -> void:
	var weapon := Data.get_weapon(_weapon_id())
	if projectile_kind == "":
		projectile_kind = weapon.get("projectile", "Bullet")
	recoil = float(weapon.get("recoil", 0.0))
	if projectile_kind == "Flame":
		flame_until = _now() + 0.12
		return
	var bolt: bool = weapon.get("bolt_action", false)
	flash = 0.08 if bolt else 0.05
	if projectile_kind == "Pellet":
		flash_scale = 1.1
	elif projectile_kind == "Tracer" or bolt:
		flash_scale = 1.25
	else:
		flash_scale = 0.75
	if bolt:
		bolt_start = _now() + 0.15
		bolt_dur = float(weapon.get("bolt_time", 0.8))


## Efecto de golpe. attacker_x: X del atacante en px (NAN si no se sabe).
func on_hit(headshot: bool, attacker_x: float = NAN) -> void:
	hit_flash = 0.1
	if not is_nan(attacker_x):
		hit_dir = signf(_ch().global_position.x - attacker_x)
	if headshot:
		headshotted = true


# --- actualización (updateRig) ------------------------------------------------

func _process(dt: float) -> void:
	var ch := _ch()
	if ch == null or not ch.has_method("is_alive"):
		return
	t += dt
	var feet: Vector2 = ch.global_position

	if not ch.is_alive():
		if not dead:
			dead = true
			_explode(feet)
		return
	elif dead:
		reset_state()

	# Apuntado
	var target_aim: float = float(_attr("Aim", 0.0))
	if _is_local() and ch.controlled_locally:
		aim = target_aim
	else:
		aim = aim + _wrap(target_aim - aim) * (1.0 - exp(-dt * 20.0))
	facing = 1 if cos(aim) >= 0.0 else -1
	var flip := facing == -1
	var local_angle := clampf(_wrap(aim if facing == 1 else PI - aim), -1.45, 1.45)

	# Movimiento (studs/s, Y arriba)
	var vel := Vector2(ch.velocity.x, -ch.velocity.y) / STUD
	var grounded: bool = ch.grounded() if ch.controlled_locally else absf(vel.y) < 2.5
	if grounded and not was_grounded and air_time > 0.22:
		squash = clampf(air_time * 1.6, 0.5, 1.0)
		_fx("dust", feet, {"count": 5, "dir": Vector2.ZERO})
	if not grounded and was_grounded and vel.y > 15.0:
		stretch = 1.0
		_fx("dust", feet, {"count": 3, "dir": Vector2(-signf(vel.x), 0)})
	air_time = 0.0 if grounded else air_time + dt
	was_grounded = grounded
	squash *= exp(-dt * 10.0)
	stretch *= exp(-dt * 8.0)

	var walking := grounded and absf(vel.x) > 2.0
	var bob: float
	if walking:
		walk_clock += dt * absf(vel.x) / 18.0
		bob = absf(sin(walk_clock * 9.0)) * 1.6
		var steps := int(floor(walk_clock * 9.0 / PI))
		if steps != step_count:
			step_count = steps
			_fx("dust", feet + Vector2(-signf(vel.x) * 0.8 * STUD, 0), {"count": 1, "dir": Vector2(-signf(vel.x), 0)})
	else:
		walk_clock = 0.0
		bob = sin(t * 3.0) * 0.35
	var forward := clampf(vel.x * facing / 18.0, -1.0, 1.0)
	lean += ((forward if (walking or not grounded) else 0.0) - lean) * minf(1.0, dt * 10.0)
	lean = clampf(lean, -1.0, 1.0)
	var lean_rot := -lean * deg_to_rad(6.0)

	var sx := 1.0 + squash * 0.16 - stretch * 0.08
	var sy := 1.0 - squash * 0.16 + stretch * 0.12
	var hit_shift := (hit_dir * facing * hit_flash * 10.0) if hit_flash > 0.0 else 0.0

	var body_point := func(p: Vector2) -> Vector2:
		p = Vector2(p.x * sx + hit_shift, p.y * sy)
		p = _rot(p, lean_rot)
		return Vector2(facing * p.x, p.y)
	var screen_rot := func(a: float) -> float:
		var deg := rad_to_deg(a)
		return deg if flip else -deg

	var tint := WHITE
	if hit_flash > 0.0:
		tint = HIT_COLOR
	elif _attr("Burning", false) == true and sin(t * 30.0) > 0.0:
		tint = BURN_COLOR

	# Cuerpo
	var rig_def := _rig_def()
	var torso_def: Dictionary = rig_def["Torso"]
	if rig_def.has("Walk") and (not grounded or (walking and int(floor(walk_clock * 9.0 / PI)) % 2 == 1)):
		torso_def = rig_def["Walk"]
	var lean_deg: float = screen_rot.call(lean_rot)
	var p: Vector2 = body_point.call(torso_def["center"] + Vector2(0, bob * 0.4))
	_draw_part("Torso", torso_def["image"], p.x, p.y, torso_def["scale"] * sx, torso_def["scale"] * sy, lean_deg, flip, tint)
	var head_bob := bob + sin(t * 3.0 + 1.0) * 0.2
	var head_def: Dictionary = rig_def["Head"]
	p = body_point.call(head_def["center"] + Vector2(0, head_bob))
	_draw_part("Head", head_def["image"], p.x, p.y, head_def["scale"] * sx, head_def["scale"] * sy, lean_deg, flip, tint)
	if rig_def.has("Hat"):
		var hat_def: Dictionary = rig_def["Hat"]
		p = body_point.call(hat_def["center"] + Vector2(0, head_bob + stretch * 1.5))
		var helmet: String = Sprites.TEAM_HELMET.get(_team(), "SoldierHelmet")
		_draw_part("Hat", helmet, p.x, p.y, hat_def["scale"] * sx, hat_def["scale"] * sy, lean_deg, flip, tint)
	else:
		_hide("Hat")

	# Arma + manos
	var vis := _visual()
	recoil *= exp(-dt * 14.0)
	var reloading: bool = _attr("Reloading", false) == true
	reload_t = minf(reload_t + dt * 5.0, 1.0) if reloading else maxf(reload_t - dt * 6.0, 0.0)
	var gun_angle := local_angle + recoil * 0.05
	gun_angle = gun_angle + (-0.75 - gun_angle) * reload_t
	var pivot: Vector2 = vis["pivot"] + Vector2(0, bob * 0.6)
	var gun_center: Vector2 = pivot + _rot(vis["offset"] - Vector2(recoil, 0), gun_angle)
	var front_off: Vector2 = vis["front_hand"]
	if reload_t > 0.0:
		front_off += Vector2(-3, -4 - absf(sin(t * 9.0)) * 3.0) * reload_t
	var rear_off: Vector2 = vis["rear_hand"]
	var now := _now()
	if bolt_start >= 0.0 and now >= bolt_start:
		var bt := (now - bolt_start) / bolt_dur
		if bt >= 1.0:
			bolt_start = -1.0
		else:
			var grip: Vector2 = vis["rear_hand"]
			var handle := Vector2(-2.5, 2.4)
			var back := Vector2(-6.5, 2.4)
			if bt < 0.2:
				rear_off = grip.lerp(handle, bt / 0.2)
			elif bt < 0.45:
				rear_off = handle.lerp(back, (bt - 0.2) / 0.25)
			elif bt < 0.7:
				rear_off = back.lerp(handle, (bt - 0.45) / 0.25)
			else:
				rear_off = handle.lerp(grip, (bt - 0.7) / 0.3)
			gun_angle += sin(bt * PI) * 0.14
			gun_center = pivot + _rot(vis["offset"] - Vector2(recoil, 0), gun_angle)
	var rear := gun_center + _rot(rear_off, gun_angle)
	var front := gun_center + _rot(front_off, gun_angle)
	var gun_deg: float = screen_rot.call(gun_angle)
	var vis_tint: Color = vis.get("tint", WHITE)
	var gun_tint := vis_tint if tint == WHITE else tint
	_draw_part("Gun", vis["image"], facing * gun_center.x + hit_shift * facing, gun_center.y,
		vis["scale"], vis["scale"], gun_deg, flip, gun_tint)
	_draw_part("RearHand", "HandGrip", facing * rear.x + hit_shift * facing, rear.y, 0.58, 0.58, gun_deg, flip, tint)
	_draw_part("FrontHand", "HandGrip", facing * front.x + hit_shift * facing, front.y, 0.58, 0.58, gun_deg, flip, tint)

	var muzzle: Vector2 = gun_center + _rot(vis["muzzle"], gun_angle)
	muzzle_world = feet + _px(facing * muzzle.x, muzzle.y)
	shell_world = feet + _px(facing * (gun_center.x - 2.0), gun_center.y + 1.0)

	flash -= dt
	if flash > 0.0:
		var f := muzzle + _rot(Vector2(3.5, 0), gun_angle)
		_draw_part("Flash", "Flash", facing * f.x, f.y, flash_scale, flash_scale, gun_deg, flip, WHITE)
	else:
		_hide("Flash")

	# VIP: corona
	if _attr("VIP", false) == true:
		_draw_part("Crown", "IcoCrown", 0, 52 + sin(t * 4.0) * 1.2, 0.55, 0.55, sin(t * 2.0) * 8.0, false, WHITE)
	else:
		_hide("Crown")
	# Bandera cargada en la espalda
	var carrying = _attr("CarryingFlag", "")
	if carrying is String and carrying != "":
		var flag_sprite: String = Sprites.TEAM_FLAG.get(carrying, "FlagUSA")
		p = body_point.call(Vector2(-9, 44 + bob))
		_draw_part("FlagPole", flag_sprite, p.x, p.y, 0.9, 0.9, sin(t * 7.0) * 6.0 + (8.0 if flip else -8.0), flip, WHITE)
	else:
		_hide("FlagPole")

	# Transparencia (protección de aparición)
	hit_flash -= dt
	var transparency := 0.0
	if ch.has_method("is_protected") and ch.is_protected():
		transparency = 0.65 if sin(t * 25.0) > 0.0 else 0.15
	for n in PART_ORDER:
		var c: Color = WHITE if n == "Flash" else _tints[n]
		_parts[n].modulate = Color(c.r, c.g, c.b, 1.0 - transparency)
	_overlay.visible = not _is_local()
	_overlay.queue_redraw()


# --- muerte (explodeRig) -----------------------------------------------------------

func _explode(feet: Vector2) -> void:
	var headshot: bool = _attr("Headshotted", headshotted) == true
	var dir := hit_dir if hit_dir != 0.0 else float(-facing)
	# las piezas viven en el mundo (no en Characters, que solo tiene personajes)
	var host: Node = null
	if G.world and is_instance_valid(G.world):
		host = G.world.get_node_or_null("RigPieces")
		if host == null:
			host = Node2D.new()
			host.name = "RigPieces"
			G.world.add_child(host)
	for n in ["Torso", "Head", "Hat", "Gun", "RearHand", "FrontHand"]:
		var s: Sprite2D = _parts[n]
		if s.visible and s.texture and host:
			var piece := Piece.new()
			piece.texture = s.texture
			piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			piece.flip_h = s.flip_h
			# FX.Piece: tamaño = ancho de la imagen, alto = ancho * H/W (escala uniforme)
			var w_px: float = s.texture.get_width() * s.scale.x
			piece.scale = Vector2.ONE * (w_px / s.texture.get_width())
			var tint: Color = _tints[n]
			if tint != WHITE:
				piece.modulate = tint
			piece.vel = Vector2(dir * randf_range(6, 18) + randf_range(-6, 6), randf_range(10, 24))
			if headshot and (n == "Head" or n == "Hat"):
				piece.vel = Vector2(dir * randf_range(10, 20), randf_range(30, 42))
			piece.rot_vel = randf_range(-600, 600)
			piece.floor_y = feet.y - 0.3 * STUD
			host.add_child(piece)
			piece.global_position = feet + s.position
		s.visible = false
	for n in ["Flash", "Crown", "FlagPole"]:
		_hide(n)
	_overlay.visible = false
	var center := feet + Vector2(0, -2.5 * STUD)
	var floor_px := feet.y - 0.2 * STUD
	_fx("gummy", center, {"dir": Vector2(dir, -0.4), "count": 34, "floor": floor_px, "scale": 1.5})
	_fx("gummy", center, {"dir": Vector2(-dir, -0.2), "count": 12, "floor": floor_px, "scale": 1.0})
	if headshot:
		var head_pos := feet + Vector2(0, -4.4 * STUD)
		_fx("gummy", head_pos, {"dir": Vector2(0, -1), "count": 24, "floor": floor_px, "scale": 1.2})
		_fx("ring", head_pos, {"radius_px": 2.5 * STUD, "color": Color8(150, 255, 150), "life": 0.25})
	for i in 3:
		_fx("splat", feet, {"floor": feet.y - 0.15 * STUD})
	_fx("smoke", center, {"count": 5, "scale": 0.8, "color": Color8(130, 200, 130)})
	_fx("flash", center, {"size": 4.0, "color": Color8(200, 255, 200)})
	_sound("Squish", center, 0.0, 0.75 if headshot else 0.9)
	_sound("Squish", center, linear_to_db(0.7), 0.6)


# --- nombre y barra de vida --------------------

func _local_team() -> String:
	var lc := G.local_character()
	if lc and "attrs" in lc:
		return str(lc.attrs.get("Team", ""))
	var p = MatchState.my_player("Team", "")
	return str(p) if p != null else ""


func _draw_overlay() -> void:
	if dead or _is_local():
		return
	var team := _team()
	var team_col := GC.team_color(team)
	var ally := _local_team() == team
	# Nombre: caja de 80 x (5 aliado / 6,5 enemigo) unidades centrada en y = 60, texto escalado
	var name_col := Color8(255, 215, 60) if _attr("VIP", false) == true else team_col
	var font: Font = PixelFont.font()
	if font == null:
		font = ThemeDB.fallback_font
	var text := str(_attr("DisplayName", _ch().name))
	const FS := 32
	var box := Vector2(80.0, 5.0 if ally else 6.5) * UPX
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x
	var th := font.get_height(FS)
	var k := minf(box.y / th, box.x / maxf(tw, 1.0))
	var center := _px(0, 60)
	_overlay.draw_set_transform(center, 0.0, Vector2(k, k))
	var at := Vector2(-tw * 0.5, -th * 0.5 + font.get_ascent(FS))
	_overlay.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FS, int(ceil(2.0 / k)), Color.BLACK)
	_overlay.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FS, name_col)
	_overlay.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Barra de vida (solo enemigos): fondo 26 x 2,2 unidades en y = 55,5, relleno color de equipo
	if ally:
		return
	var bw := 26.0 * UPX
	var bh := 2.2 * UPX
	var bc := _px(0, 55.5)
	var r := Rect2(bc.x - bw * 0.5, bc.y - bh * 0.5, bw, bh)
	var hp: float = float(_attr("Health", 100.0))
	var mhp: float = maxf(float(_attr("MaxHealth", 100.0)), 1.0)
	_overlay.draw_rect(r, Color8(15, 15, 15))
	_overlay.draw_rect(Rect2(r.position, Vector2(bw * clampf(hp / mhp, 0.0, 1.0), bh)), team_col)
