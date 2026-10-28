extends Node2D
## FXController (cliente): efectos visuales.
## Las partículas son rectángulos de color plano (Square), rectángulos redondeados
## (Round), anillos con borde de 3 px (Ring), imágenes (Image: "Stain" y pedazos
## de rig) y textos con PixelFont (Text). Acá se dibujan igual: rectángulos y
## círculos de color plano, el sprite y la tipografía pixel.
##
## API: spawn(kind, position_px, params = {}), shake(amount), screen_flash(color, alpha), clear()
## kinds (nombre / alias):
##   "goo"/"gummy", "sparks"/"spark", "smoke", "fire", "debris", "dust", "shell"/"casing",
##   "piece", "stain"/"splat", "flash", "ring", "text", "explosion"
## params: count, scale, color, dir (Vector2 en coords de Godot, Y abajo), floor (y px),
##   radius_px, size (studs), life, text, facing, image, flip, vel (px/s), rot_vel (°/s), tint

const MAX_PARTICLES := 420
const S := 8.0  # 1 stud en px

const GOO := [Color(95 / 255.0, 225 / 255.0, 95 / 255.0), Color(60 / 255.0, 175 / 255.0, 60 / 255.0),
	Color(150 / 255.0, 1.0, 140 / 255.0)]
const FIRE := [Color(1.0, 230 / 255.0, 120 / 255.0), Color(1.0, 160 / 255.0, 40 / 255.0),
	Color(240 / 255.0, 80 / 255.0, 30 / 255.0)]
const DANGER := Color(235 / 255.0, 70 / 255.0, 60 / 255.0)   # UIKit.Colors.Danger

## kind: 0 Square, 1 Round, 2 Ring, 3 Image, 4 Text
enum { SQUARE, ROUND, RING, IMAGE, TEXT }

var _parts: Array = []
var _flash_layer: CanvasLayer
var _flash_rect: ColorRect
var _seq := 0


func _ready() -> void:
	z_index = 60
	z_as_relative = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 5
	add_child(_flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_layer.add_child(_flash_rect)
	Net.event_received.connect(_on_event)
	G.session_ended.connect(clear)


func clear() -> void:
	_parts.clear()
	if _flash_rect:
		_flash_rect.color.a = 0.0
	queue_redraw()


func _on_event(event: String, data) -> void:
	if not (data is Dictionary):
		return
	match event:
		"Hit":
			_on_hit(data)


## Evento Hit: golpe en el rig (goma) + texto y sacudida.
func _on_hit(d: Dictionary) -> void:
	var headshot: bool = d.get("headshot", false)
	var burn: bool = d.get("burn", false)
	var victim = G.get_character(str(d.get("victim", "")))
	if victim and is_instance_valid(victim):
		var feet: Vector2 = victim.global_position
		var hit_dir := 0.0
		var att = G.get_character(str(d.get("attacker", "")))
		if att and is_instance_valid(att):
			hit_dir = signf(feet.x - att.global_position.x)
		elif "rig" in victim and victim.rig and "hit_dir" in victim.rig:
			hit_dir = float(victim.rig.hit_dir)
		var hit_y := 4.3 if headshot else 2.2
		goo(Vector2(feet.x, feet.y - hit_y * S), Vector2(hit_dir, -0.2), 10 if headshot else 4,
			feet.y - 0.2 * S, 0.8)
	var pos = d.get("position", null)
	if pos is Vector2:
		var color: Color = DANGER if headshot else (Color(1.0, 160 / 255.0, 60 / 255.0) if burn else Color(1.0, 240 / 255.0, 90 / 255.0))
		var label := "¡CABEZA!" if headshot else str(int(floor(float(d.get("amount", 0.0)) + 0.5)))
		text(pos + Vector2(0, -1.5 * S), label, color, 3.4 if headshot else 2.4)
	if str(d.get("victim", "")) == Net.my_key():
		shake(1.0 if headshot else 0.35)


# --- núcleo (FX.Spawn / step) ---------------------------------------------------

func _rand(a: float, b: float) -> float:
	return a + randf() * (b - a)


## def: kind, pos, vel, grav, drag, life, size, size_end, aspect, color, tr, tr_end,
## rot, rot_vel (rad), floor, bounce, fade_last, z, tex, flip, text. Unidades: px, px/s, rad.
func _spawn(def: Dictionary) -> Dictionary:
	if _parts.size() >= MAX_PARTICLES:
		_parts.pop_front()
	def["age"] = 0.0
	if not def.has("kind"): def["kind"] = SQUARE
	if not def.has("vel"): def["vel"] = Vector2.ZERO
	if not def.has("grav"): def["grav"] = 0.0
	if not def.has("size"): def["size"] = 0.4 * S
	if not def.has("size_end"): def["size_end"] = def["size"]
	if not def.has("aspect"): def["aspect"] = 1.0
	if not def.has("tr"): def["tr"] = 0.0
	if not def.has("tr_end"): def["tr_end"] = def["tr"]
	if not def.has("rot"): def["rot"] = 0.0
	if not def.has("rot_vel"): def["rot_vel"] = 0.0
	if not def.has("color"): def["color"] = Color.WHITE
	if not def.has("z"): def["z"] = 1
	if def["kind"] == IMAGE and def.get("tex") is Texture2D:
		var tex: Texture2D = def["tex"]
		def["aspect"] = float(tex.get_height()) / float(tex.get_width())
	_seq += 1
	def["seq"] = _seq
	_parts.append(def)
	return def


func _process(dt: float) -> void:
	if _flash_rect and _flash_rect.color.a > 0.0:
		_flash_rect.color.a = maxf(0.0, _flash_rect.color.a - dt * 4.0)
	if _parts.is_empty():
		return
	var i := _parts.size() - 1
	while i >= 0:
		var p: Dictionary = _parts[i]
		p["age"] = p["age"] + dt
		if p["age"] / p["life"] >= 1.0:
			_parts.remove_at(i)
			i -= 1
			continue
		var v: Vector2 = p["vel"]
		v.y += float(p["grav"]) * dt
		if p.has("drag"):
			v *= exp(-float(p["drag"]) * dt)
		var pos: Vector2 = p["pos"] + v * dt
		var fl = p.get("floor", null)
		if fl != null and pos.y > float(fl):
			pos.y = float(fl)
			v = Vector2(v.x * 0.5, -v.y * float(p.get("bounce", 0.3)))
			p["rot_vel"] = float(p["rot_vel"]) * 0.5
			if absf(v.y) < 2.0 * S:
				v = Vector2(v.x * 0.8, 0.0)
				p["rot_vel"] = float(p["rot_vel"]) * 0.6
				p["grav"] = 0.0
		p["pos"] = pos
		p["vel"] = v
		p["rot"] = float(p["rot"]) + float(p["rot_vel"]) * dt
		i -= 1
	queue_redraw()


# --- emisores (Y de Godot hacia abajo) ------

func goo(pos: Vector2, dir: Vector2, count: int = 8, floor_y = null, scale: float = 1.0) -> void:
	for _i in count:
		var v := dir * _rand(6, 22) * S + Vector2(_rand(-8, 8), -_rand(5, 16)) * S
		_spawn({"kind": ROUND if randf() < 0.5 else SQUARE, "pos": pos, "vel": v, "grav": 85.0 * S,
			"life": _rand(0.6, 1.2), "size": _rand(0.22, 0.5) * scale * S, "size_end": 0.1 * S,
			"color": GOO[randi() % GOO.size()], "floor": floor_y, "bounce": 0.25, "z": 3,
			"rot_vel": deg_to_rad(_rand(-300, 300))})


func sparks(pos: Vector2, dir: Vector2, count: int = 6, color = null) -> void:
	for _i in count:
		var v := dir * _rand(10, 30) * S + Vector2(_rand(-14, 14), -_rand(-6, 16)) * S
		_spawn({"kind": SQUARE, "pos": pos, "vel": v, "grav": 60.0 * S, "life": _rand(0.12, 0.3),
			"size": _rand(0.1, 0.22) * S, "size_end": 0.05 * S,
			"color": color if color is Color else Color(1.0, 240 / 255.0, 160 / 255.0), "z": 4})


func smoke(pos: Vector2, count: int = 6, scale: float = 1.0, color = null) -> void:
	for _i in count:
		_spawn({"kind": ROUND, "pos": pos + Vector2(_rand(-1, 1), -_rand(-0.5, 0.5)) * scale * S,
			"vel": Vector2(_rand(-4, 4), -_rand(2, 7)) * scale * S, "grav": -2.0 * S, "drag": 1.5,
			"life": _rand(0.8, 1.6), "size": _rand(0.8, 1.4) * scale * S, "size_end": _rand(2.5, 4) * scale * S,
			"color": color if color is Color else Color(120 / 255.0, 110 / 255.0, 120 / 255.0),
			"tr": 0.25, "tr_end": 1.0, "z": 1})


func fire(pos: Vector2, count: int = 8, scale: float = 1.0) -> void:
	for _i in count:
		var u := Vector2(_rand(-1, 1), -_rand(-0.6, 1))
		u = u.normalized() if u.length() > 0.0 else Vector2.ZERO
		_spawn({"kind": ROUND, "pos": pos, "vel": u * _rand(6, 22) * scale * S,
			"drag": 4.0, "grav": -6.0 * S, "life": _rand(0.25, 0.55),
			"size": _rand(1, 2) * scale * S, "size_end": _rand(0.2, 0.6) * S,
			"color": FIRE[randi() % FIRE.size()], "tr": 0.0, "tr_end": 0.8, "z": 5})


func debris(pos: Vector2, color = null, count: int = 8, scale: float = 1.0, floor_y = null) -> void:
	var base: Color = color if color is Color else Color(0.5, 0.4, 0.3)
	for _i in count:
		_spawn({"kind": SQUARE, "pos": pos + Vector2(_rand(-1.5, 1.5), -_rand(-1.5, 1.5)) * scale * S,
			"vel": Vector2(_rand(-18, 18), -_rand(10, 30)) * scale * S, "grav": 95.0 * S,
			"life": _rand(0.9, 1.6), "size": _rand(0.35, 0.9) * scale * S,
			"color": base.lerp(Color.BLACK, _rand(0, 0.35)), "rot_vel": deg_to_rad(_rand(-500, 500)),
			"floor": floor_y, "bounce": 0.35, "fade_last": 0.4, "z": 3})


func dust(pos: Vector2, count: int = 4, dir_x: float = 0.0) -> void:
	for _i in count:
		_spawn({"kind": ROUND, "pos": pos + Vector2(_rand(-0.6, 0.6), -0.2) * S,
			"vel": Vector2(dir_x * _rand(1, 4) + _rand(-3, 3), -_rand(1, 3)) * S, "drag": 3.0,
			"life": _rand(0.3, 0.55), "size": _rand(0.4, 0.7) * S, "size_end": _rand(1, 1.5) * S,
			"color": Color(200 / 255.0, 170 / 255.0, 140 / 255.0), "tr": 0.35, "tr_end": 1.0, "z": 1})


func shell(pos: Vector2, facing: float, floor_y = null) -> void:
	_spawn({"kind": SQUARE, "pos": pos, "vel": Vector2(-facing * _rand(5, 11), -_rand(9, 15)) * S,
		"grav": 90.0 * S, "life": 1.2, "size": 0.28 * S, "aspect": 0.45,
		"color": Color(230 / 255.0, 180 / 255.0, 60 / 255.0), "rot_vel": deg_to_rad(_rand(600, 1100)),
		"floor": floor_y, "bounce": 0.4, "fade_last": 0.3, "z": 2})


## Pedazo de rig (sprite) que sale volando. vel en px/s, size en studs.
func piece(image: String, pos: Vector2, vel: Vector2, size_studs: float, flip: bool, floor_y = null,
		rot_vel_deg = null, tint = null) -> Dictionary:
	return _spawn({"kind": IMAGE, "tex": Sprites.tex(image), "pos": pos, "vel": vel, "grav": 95.0 * S,
		"life": 9.0, "size": size_studs * S, "flip": flip, "floor": floor_y, "bounce": 0.25,
		"rot_vel": deg_to_rad(float(rot_vel_deg) if rot_vel_deg != null else _rand(-400, 400)),
		"fade_last": 2.0, "color": tint if tint is Color else Color.WHITE, "z": 2, "drag": 0.4})


## Mancha de goma (sprite "Stain"). floor_y = y px del piso (pies).
func stain(pos: Vector2, floor_y: float, size_studs = null) -> void:
	_spawn({"kind": IMAGE, "tex": Sprites.tex("Stain"),
		"pos": Vector2(pos.x + _rand(-1.5, 1.5) * S, floor_y - 0.15 * S), "life": 30.0,
		"size": (float(size_studs) if size_studs != null else _rand(1.8, 3.2)) * S, "fade_last": 5.0, "z": 1,
		"color": Color(150 / 255.0, 1.0, 150 / 255.0).lerp(Color(80 / 255.0, 160 / 255.0, 80 / 255.0), randf())})


func flash(pos: Vector2, size_studs: float, color = null) -> void:
	_spawn({"kind": ROUND, "pos": pos, "life": 0.12, "size": size_studs * 0.6 * S, "size_end": size_studs * S,
		"color": color if color is Color else Color(1.0, 240 / 255.0, 200 / 255.0), "tr": 0.0, "tr_end": 1.0, "z": 6})


func ring(pos: Vector2, radius_studs: float, color = null, life: float = 0.35) -> void:
	_spawn({"kind": RING, "pos": pos, "life": life, "size": radius_studs * 0.3 * S, "size_end": radius_studs * 2.0 * S,
		"color": color if color is Color else Color.WHITE, "tr": 0.0, "tr_end": 1.0, "z": 6})


func text(pos: Vector2, txt: String, color = null, size_studs: float = 2.6, life: float = 0.9) -> void:
	_spawn({"kind": TEXT, "pos": pos, "vel": Vector2(_rand(-2, 2), -9.0) * S, "drag": 3.0, "life": life,
		"size": size_studs * S, "aspect": 0.45, "text": txt,
		"color": color if color is Color else Color.WHITE, "tr": 0.0, "tr_end": 1.0, "z": 8})


func explosion(pos: Vector2, radius: float = 12.0) -> void:
	var s := radius / 12.0
	flash(pos, radius * 1.6, Color(1.0, 250 / 255.0, 220 / 255.0))
	ring(pos, radius, Color(1.0, 230 / 255.0, 170 / 255.0), 0.4)
	fire(pos, int(floor(16 * s)), s)
	smoke(pos, int(floor(12 * s)), s)
	debris(pos, Color(70 / 255.0, 50 / 255.0, 40 / 255.0), int(floor(10 * s)), s, pos.y + 6.0 * S)
	sparks(pos, Vector2.ZERO, int(floor(14 * s)))
	var cam := _camera_center()
	var d := absf(cam.x - pos.x) / S + absf(cam.y - pos.y) / S * 0.5
	var k := clampf(1.0 - d / 80.0, 0.0, 1.0)
	shake(1.4 * k * s)
	if k > 0.5:
		screen_flash(Color(1.0, 230 / 255.0, 190 / 255.0), 0.25 * k)


## Interfaz genérica (la usan ProjectileRenderer y el rig).
func spawn(kind: String, position_px: Vector2, params: Dictionary = {}) -> void:
	var sc: float = float(params.get("scale", 1.0))
	var dir: Vector2 = params["dir"] if params.get("dir", null) is Vector2 else Vector2.ZERO
	var floor_y = params.get("floor", null)
	var col = params.get("color", null)
	match kind:
		"goo", "gummy":
			goo(position_px, dir, int(params.get("count", 8)), floor_y, sc)
		"sparks", "spark":
			sparks(position_px, dir, int(params.get("count", 6)), col)
		"smoke":
			smoke(position_px, int(params.get("count", 6)), sc, col)
		"fire":
			fire(position_px, int(params.get("count", 8)), sc)
		"debris":
			debris(position_px, col, int(params.get("count", 8)), sc, floor_y)
		"dust":
			dust(position_px, int(params.get("count", 4)), float(params.get("dir_x", dir.x)))
		"shell", "casing":
			shell(position_px, float(params.get("facing", 1.0)), floor_y)
		"piece":
			piece(str(params.get("image", "")), position_px, params.get("vel", Vector2.ZERO),
				float(params.get("size", 1.0)), bool(params.get("flip", false)), floor_y,
				params.get("rot_vel", null), params.get("tint", null))
		"stain", "splat":
			# floor = y del piso; sin floor se toma la posición como pies
			var fy: float = float(floor_y) + 0.15 * S if (kind == "splat" and floor_y != null) \
				else (float(floor_y) if floor_y != null else position_px.y)
			stain(position_px, fy, params.get("size", null))
		"flash":
			flash(position_px, float(params.get("size", 2.0)), col)
		"ring":
			ring(position_px, float(params.get("radius_px", 12.0 * S)) / S, col, float(params.get("life", 0.35)))
		"text":
			text(position_px, str(params.get("text", "")), col, float(params.get("size", 2.6)), float(params.get("life", 0.9)))
		"explosion":
			explosion(position_px, float(params.get("radius_px", 12.0 * S)) / S)


func _camera_center() -> Vector2:
	var vp := get_viewport()
	if vp:
		return vp.get_canvas_transform().affine_inverse() * (vp.get_visible_rect().size * 0.5)
	return Vector2.ZERO


## FX.AddShake (la cámara aplica el ajuste de sacudida del jugador).
func shake(amount: float) -> void:
	if float(G.settings.get("shake", 1.0)) <= 0.0:
		return
	var cam = G.controller("Camera")
	if cam and is_instance_valid(cam) and cam.has_method("shake"):
		cam.shake(amount)


func add_shake(amount: float) -> void:
	shake(amount)


## FX.ScreenFlash: Transparency = min(actual, 1 - alpha); se desvanece a 4/s.
func screen_flash(color: Color, alpha: float = 0.4) -> void:
	if _flash_rect:
		var a := maxf(_flash_rect.color.a, alpha)
		_flash_rect.color = Color(color.r, color.g, color.b, a)


# --- dibujo ----------------------------------------------------------------------

func _draw() -> void:
	if _parts.is_empty():
		return
	var order := _parts.duplicate()
	order.sort_custom(func(a, b): return a["z"] < b["z"] or (a["z"] == b["z"] and a["seq"] < b["seq"]))
	var zoom := get_viewport().get_canvas_transform().get_scale().x if get_viewport() else 1.0
	zoom = maxf(zoom, 0.01)
	for p in order:
		_draw_part(p, zoom)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_part(p: Dictionary, zoom: float) -> void:
	var t: float = p["age"] / p["life"]
	var size: float = lerpf(p["size"], p["size_end"], t)
	var tr: float = lerpf(p["tr"], p["tr_end"], t)
	if p.has("fade_last"):
		var left: float = p["life"] - p["age"]
		if left < float(p["fade_last"]):
			tr = maxf(tr, 1.0 - left / float(p["fade_last"]))
	var a := 1.0 - tr
	if a <= 0.0:
		return
	var c: Color = p["color"]
	c.a = a
	var pos: Vector2 = p["pos"]
	var h: float = size * float(p["aspect"])
	match int(p["kind"]):
		SQUARE:
			draw_set_transform(pos, p["rot"], Vector2.ONE)
			draw_rect(Rect2(-size * 0.5, -h * 0.5, size, h), c)
		ROUND:
			draw_set_transform(pos, p["rot"], Vector2(1.0, float(p["aspect"])))
			draw_circle(Vector2.ZERO, size * 0.5, c)
		RING:
			# borde de 3 px de pantalla
			draw_set_transform(pos, 0.0, Vector2.ONE)
			var w := 3.0 / zoom
			draw_arc(Vector2.ZERO, size * 0.5 + w * 0.5, 0.0, TAU, 48, c, w, false)
		IMAGE:
			var tex: Texture2D = p.get("tex")
			if tex == null:
				return
			draw_set_transform(pos, p["rot"], Vector2(-1.0 if p.get("flip", false) else 1.0, 1.0))
			draw_texture_rect(tex, Rect2(-size * 0.5, -h * 0.5, size, h), false, c)
		TEXT:
			_draw_text(p, pos, size * zoom, h * zoom, zoom, c)


## Texto escalado con PixelFont: cuadro de size x size*0,45 centrado en pos.
## Usa la tipografía pixel (scripts/ui/pixel_font.gd); si no carga, la fuente por defecto.
func _draw_text(p: Dictionary, pos: Vector2, box_w: float, box_h: float, zoom: float, c: Color) -> void:
	var txt: String = p["text"]
	if txt == "":
		return
	draw_set_transform(pos, 0.0, Vector2.ONE / zoom)
	var origin := Vector2(-box_w * 0.5, -box_h * 0.5)
	var pf = _pixel_font()
	if pf == null:
		var font := ThemeDB.fallback_font
		var fs := maxi(1, int(box_h))
		var sw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		if sw > box_w:
			fs = maxi(1, int(fs * box_w / sw))
			sw = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(-sw * 0.5, font.get_ascent(fs) - font.get_height(fs) * 0.5), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
		return
	var lines: Array = pf.layout(pf.parse(txt, false), -1.0)
	var width := 0
	for l in lines:
		width = maxi(width, int(l["width"]))
	var bh: int = pf.block_height(lines.size())
	var sc := 0.0
	var s := 14.0
	while s >= 1.0:
		if width * s <= box_w + 0.5 and bh * s <= box_h + 0.5:
			sc = s
			break
		s -= 0.5
	if sc == 0.0:
		sc = maxf(0.4, minf(box_w / maxf(width, 1.0), box_h / maxf(bh, 1.0)))
	var cw: int = pf.CW
	var chh: int = pf.CH
	var cols: int = pf.COLS
	var y0 := (box_h - bh * sc) / 2.0
	var quads := []
	for li in lines.size():
		var line: Dictionary = lines[li]
		var x := (box_w - float(line["width"]) * sc) / 2.0
		var y := y0 + li * (int(pf.LINE_H) + int(pf.LINE_GAP)) * sc
		for item in line["chars"]:
			var ch: String = item[0]
			if ch != " ":
				var idx: int = pf.glyph_of(ch)[0]
				var src := Rect2((idx % cols) * cw, floori(float(idx) / cols) * chh, cw, chh)
				var dst := Rect2(origin + Vector2(floorf(x - sc + 0.5), floorf(y - sc + 0.5)), Vector2(cw, chh) * sc)
				quads.append([src, dst])
			x += float(pf.advance(ch)) * sc
	if c.r * 0.3 + c.g * 0.59 + c.b * 0.11 >= 0.28:
		var bt: Texture2D = pf.back_texture()
		for q in quads:
			draw_texture_rect_region(bt, q[1], q[0], Color(1, 1, 1, c.a))
	var ft: Texture2D = pf.fill_texture()
	for q in quads:
		draw_texture_rect_region(ft, q[1], q[0], c)


var _pf_script = null
var _pf_tried := false

func _pixel_font():
	if not _pf_tried:
		_pf_tried = true
		if ResourceLoader.exists("res://scripts/ui/pixel_font.gd"):
			var scr = load("res://scripts/ui/pixel_font.gd")
			if scr is GDScript and scr.can_instantiate():
				_pf_script = scr
	return _pf_script
