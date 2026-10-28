class_name UIKit
extends RefCounted
## Kit de UI: estilo "militar de caramelo".
## Paneles oliva con degradado, borde caqui y remaches; botones con degradado y
## escala al pasar el mouse; franja de peligro; sprites pixel-art; vista previa de rig
## con los sprites originales; tipografía pixel (PixelFont) en todas las etiquetas.

const PANEL := Color8(24, 28, 18)
const PANEL2 := Color8(38, 44, 28)
const PANEL3 := Color8(56, 64, 40)
const LINE := Color8(196, 180, 120)
const KHAKI := Color8(222, 204, 140)
const ACCENT := Color8(255, 212, 60)
const TEXT := Color8(246, 240, 222)
const MUTED := Color8(168, 162, 136)
const DANGER := Color8(235, 70, 60)
const GOOD := Color8(120, 225, 90)
const PINK := Color8(255, 120, 190)
const BLACK := Color8(8, 10, 6)

const LEFT := 0
const CENTER := 1
const RIGHT := 2


# --- posicionamiento (anclaje + posición/tamaño en escala y offset) -------------

## Ancla en el punto relativo `anchor` del padre, con el punto `pivot` del control
## (punto de anclaje; por defecto = anchor) en `pos` píxeles de ese ancla. Tamaño fijo.
static func at(c: Control, anchor: Vector2, pos: Vector2, size: Vector2, pivot: Vector2 = Vector2(-1, -1)) -> Control:
	if pivot.x < 0.0:
		pivot = anchor
	return place(c, [anchor.x, pos.x, anchor.y, pos.y], [0, size.x, 0, size.y], pivot)


## Posición completa: pos = [escalaX, offsetX, escalaY, offsetY], size igual, ap = punto de anclaje.
static func place(c: Control, pos: Array, size: Array, ap: Vector2 = Vector2.ZERO) -> Control:
	c.anchor_left = pos[0] - ap.x * size[0]
	c.anchor_right = c.anchor_left + size[0]
	c.anchor_top = pos[2] - ap.y * size[2]
	c.anchor_bottom = c.anchor_top + size[2]
	c.offset_left = pos[1] - ap.x * size[1]
	c.offset_right = c.offset_left + size[1]
	c.offset_top = pos[3] - ap.y * size[3]
	c.offset_bottom = c.offset_top + size[3]
	_center_pivot(c)
	return c


## Position = fromOffset(x, y), Size = fromOffset(w, h)
static func off(c: Control, x: float, y: float, w: float, h: float) -> Control:
	return place(c, [0, x, 0, y], [0, w, 0, h])


static func _center_pivot(c: Control) -> void:
	c.pivot_offset = c.size * 0.5
	if not c.has_meta("_pivot"):
		c.set_meta("_pivot", true)
		c.resized.connect(func(): c.pivot_offset = c.size * 0.5)


static func full(c: Control, ignore_mouse: bool = true) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0
	_center_pivot(c)
	if ignore_mouse:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func root(c: Control) -> void:
	full(c, true)


## ScreenGui.DisplayOrder: ordena los controladores de UI hermanos (dibujo y entrada).
static func display_order(c: Control, order: int) -> void:
	c.set_meta("display_order", order)
	(func():
		var parent := c.get_parent()
		if parent == null:
			return
		var nodes := []
		for ch in parent.get_children():
			if ch.has_meta("display_order"):
				nodes.append(ch)
		nodes.sort_custom(func(a, b): return int(a.get_meta("display_order")) < int(b.get_meta("display_order")))
		var idx := parent.get_child_count() - nodes.size()
		for n in nodes:
			parent.move_child(n, idx)
			idx += 1).call_deferred()


static func container(parent: Node = null) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent:
		parent.add_child(c)
	return c


# --- widgets ------------------------------------------------------------------

## UIKit.Label: texto escalado por defecto, tipografía pixel.
static func label(text: String, color: Color = TEXT, x_align: int = CENTER, parent: Node = null) -> PixelFont.PixelLabel:
	var l := PixelFont.PixelLabel.new()
	l.text = text
	l.color = color
	l.x_align = x_align
	if parent:
		parent.add_child(l)
	return l


## Fuente de mapa de bits de PixelFont para dibujar con draw_string (todas las
## variantes usan la misma tipografía pixel; `kind` queda por compatibilidad).
static func font(_kind: String = "body") -> Font:
	return PixelFont.font()


static func set_color(l: Control, color: Color) -> void:
	if l is PixelFont.PixelLabel:
		(l as PixelFont.PixelLabel).color = color


static func rect(color: Color, parent: Node = null) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent:
		parent.add_child(r)
	return r


## Rectángulo de color plano con esquinas redondeadas opcionales (y borde con stroke_width).
static func frame(color: Color, transparency: float = 0.0, corner: float = 0.0, parent: Node = null) -> Box:
	var b := Box.new()
	b.bg = color
	b.bg_alpha = 1.0 - transparency
	b.radius = corner
	if parent:
		parent.add_child(b)
	return b


## UIKit.Panel: degradado Panel2 -> Panel, esquinas 6, borde (2, transp. 0.15) y remaches.
static func panel(stroke: Color = LINE, thickness: float = 2.0, rivets: bool = true, stroke_transparency: float = 0.15,
		parent: Node = null) -> Box:
	var p := Box.new()
	p.gradient = true
	p.grad_top = PANEL2
	p.grad_bottom = PANEL
	p.radius = 6.0
	p.stroke = stroke
	p.stroke_width = thickness
	p.stroke_alpha = 1.0 - stroke_transparency
	p.rivets = rivets
	if parent:
		parent.add_child(p)
	return p


## UIKit.Button. style: "Primary" | "Secondary" | "Danger" | "Team"
static func button(text: String, style: String = "Secondary", team_color: Color = Color.WHITE, parent: Node = null) -> PButton:
	var b := PButton.new()
	b.setup(text, style, team_color)
	if parent:
		parent.add_child(b)
	return b


static func hazard(parent: Node = null) -> Hazard:
	var h := Hazard.new()
	if parent:
		parent.add_child(h)
	return h


## UIKit.Sprite: imagen pixel-art con ScaleType Fit (o "stretch" / "crop").
static func sprite(image_name: String, tint: Color = Color.WHITE, scale_type: String = "fit", parent: Node = null) -> TextureRect:
	var t := TextureRect.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	match scale_type:
		"stretch":
			t.stretch_mode = TextureRect.STRETCH_SCALE
		"crop":
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			t.clip_contents = true
		_:
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture = Sprites.tex(image_name)
	t.self_modulate = tint
	if parent:
		parent.add_child(t)
	return t


static func set_sprite(t: TextureRect, image_name: String, tint: Color = Color.WHITE) -> void:
	t.texture = Sprites.tex(image_name)
	t.self_modulate = tint


## UIKit.RigPreview: vista previa estática de un personaje con sus sprites.
static func rig_preview(class_id: String, team: String, weapon_id: String = "", parent: Node = null) -> RigPreview:
	var r := RigPreview.new()
	r.setup(class_id, team, weapon_id)
	if parent:
		parent.add_child(r)
	return r


## Retrato de comandante (frame 1..3 de Sprites.COMMANDERS)
static func commander_frame(team: String, i: int) -> Texture2D:
	var frames: Array = Sprites.COMMANDERS.get(team, Sprites.COMMANDERS["USA"])
	return Sprites.tex(frames[clampi(i, 1, 3) - 1])


# --- animaciones ------------------------------------------------------------

static func tween_scale(c: Control, to: float, t: float, trans: Tween.TransitionType = Tween.TRANS_QUAD) -> void:
	if not c.is_inside_tree():
		c.scale = Vector2.ONE * to
		return
	c.pivot_offset = c.size * 0.5
	if c.has_meta("_scale_tw"):
		var old = c.get_meta("_scale_tw")
		if old is Tween and old.is_valid():
			old.kill()
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * to, t).set_trans(trans).set_ease(Tween.EASE_OUT)
	c.set_meta("_scale_tw", tw)


## UIKit.Pop: rebote de escala (UIScale = amount -> 1 con Back en 0,35 s).
static func pop(c: Control, amount: float = 1.25) -> void:
	c.scale = Vector2.ONE * amount
	tween_scale(c, 1.0, 0.35, Tween.TRANS_BACK)


## UIKit.Shake: sacude la posición durante `duration` segundos.
static func shake(c: Control, intensity: float, duration: float = 0.3) -> void:
	if not c.is_inside_tree() or c.has_meta("_shaking"):
		return
	c.set_meta("_shaking", true)
	var base := c.position
	var tw := c.create_tween()
	var steps := maxi(1, int(duration / 0.03))
	for i in steps:
		var k := 1.0 - float(i) / steps
		tw.tween_callback(func(): c.position = base + Vector2(randf() - 0.5, randf() - 0.5) * intensity * k * 2.0)
		tw.tween_interval(0.03)
	tw.tween_callback(func():
		c.position = base
		c.remove_meta("_shaking"))


static func fade_text(l: PixelFont.PixelLabel, to: float, t: float) -> Tween:
	var tw := l.create_tween()
	tw.tween_property(l, "transparency", to, t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tw


# --- utilidades ---------------------------------------------------------------

static func upper(text: String) -> String:
	return text.to_upper()


static func format_time(seconds: float) -> String:
	var s := maxi(0, int(floor(seconds + 0.5)))
	return "%d:%02d" % [s / 60, s % 60]


static func team_display(team: String) -> String:
	return GC.TEAM_INFO[team]["display"] if GC.TEAM_INFO.has(team) else "?"


static func team_color(team: String) -> Color:
	return GC.TEAM_INFO[team]["color"] if GC.TEAM_INFO.has(team) else KHAKI


## Sonido de interfaz (SoundController.play_ui).
static func sfx(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var snd: Node = G.controller("Sound")
	if snd and snd.has_method("play_ui"):
		snd.call("play_ui", sound_name, volume_db, pitch)


static func weapon_display(weapon_id: String) -> String:
	if Data.WEAPONS.has(weapon_id):
		return Data.WEAPONS[weapon_id]["display"]
	return weapon_id


# --- clases de nodos ----------------------------------------------------------

## Panel: fondo (plano o degradado vertical), esquinas redondeadas, borde (por
## fuera del borde, como ApplyStrokeMode.Border) y remaches opcionales de UIKit.Panel.
class Box extends Control:
	var bg := Color.WHITE:
		set(v):
			bg = v
			queue_redraw()
	var bg_alpha := 1.0:
		set(v):
			bg_alpha = v
			queue_redraw()
	var gradient := false
	var grad_top := Color.WHITE
	var grad_bottom := Color.WHITE
	var radius := 0.0
	var stroke := UIKit.LINE:
		set(v):
			stroke = v
			queue_redraw()
	var stroke_width := 0.0
	var stroke_alpha := 1.0:
		set(v):
			stroke_alpha = v
			queue_redraw()
	var rivets := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _rounded_points(r: Rect2, rad: float) -> PackedVector2Array:
		rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
		if rad <= 0.5:
			return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		var pts := PackedVector2Array()
		var centers := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
			Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
		var start := [-PI / 2.0, 0.0, PI / 2.0, PI]
		for k in 4:
			for s in 6:
				var a: float = start[k] + (PI / 2.0) * s / 5.0
				pts.append(centers[k] + Vector2(cos(a), sin(a)) * rad)
		return pts

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if size.x <= 0.0 or size.y <= 0.0:
			return
		if bg_alpha > 0.0:
			if gradient:
				var pts := _rounded_points(r, radius)
				var cols := PackedColorArray()
				for p in pts:
					var t := clampf(p.y / size.y, 0.0, 1.0)
					var c: Color = grad_top.lerp(grad_bottom, t) * bg
					c.a = bg_alpha
					cols.append(c)
				draw_polygon(pts, cols)
			else:
				var sb := StyleBoxFlat.new()
				sb.bg_color = Color(bg, bg_alpha)
				sb.set_corner_radius_all(int(radius))
				draw_style_box(sb, r)
		if stroke_width > 0.0 and stroke_alpha > 0.0:
			var w := ceilf(stroke_width)
			var sb2 := StyleBoxFlat.new()
			sb2.draw_center = false
			sb2.border_color = Color(stroke, stroke_alpha)
			sb2.set_border_width_all(int(w))
			sb2.set_expand_margin_all(w)
			sb2.set_corner_radius_all(int(radius + w) if radius > 0.0 else 0)
			draw_style_box(sb2, r)
		if rivets:
			var rv := StyleBoxFlat.new()
			rv.bg_color = Color(UIKit.LINE, 0.65)
			rv.set_corner_radius_all(2)
			for p in [Vector2(5, 5), Vector2(size.x - 9, 5), Vector2(5, size.y - 9), Vector2(size.x - 9, size.y - 9)]:
				draw_style_box(rv, Rect2(p, Vector2(4, 4)))


## Botón de UIKit: degradado vertical, esquinas 6, borde 2, etiqueta pixel
## (8, 5, -16, -10) y escala 1,06 al pasar el mouse / 0,95 al apretar.
class PButton extends Box:
	signal pressed
	var label: PixelFont.PixelLabel
	var style := "Secondary"
	var _down := false
	var _hover := false

	func setup(text: String, st: String, team_color: Color = Color.WHITE) -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		gradient = true
		radius = 6.0
		stroke_width = 2.0
		if label == null:
			label = UIKit.label(text, UIKit.TEXT, UIKit.CENTER, self)
			UIKit.place(label, [0, 8, 0, 5], [1, -16, 1, -10])
		else:
			label.text = text
		set_style(st, team_color)
		if not mouse_entered.is_connected(_on_enter):
			mouse_entered.connect(_on_enter)
			mouse_exited.connect(_on_exit)

	func set_style(st: String, team_color: Color = Color.WHITE) -> void:
		style = st
		var txt := UIKit.TEXT
		match st:
			"Primary":
				grad_top = Color8(255, 220, 90)
				grad_bottom = Color8(225, 160, 30)
				stroke = Color8(90, 60, 10)
				txt = UIKit.BLACK
			"Danger":
				grad_top = Color8(240, 90, 80)
				grad_bottom = Color8(170, 40, 34)
				stroke = Color8(70, 14, 10)
			"Team":
				grad_top = team_color.lerp(Color.WHITE, 0.15)
				grad_bottom = team_color.lerp(Color.BLACK, 0.35)
				stroke = team_color.lerp(Color.BLACK, 0.7)
			_:
				grad_top = UIKit.PANEL3
				grad_bottom = UIKit.PANEL2
				stroke = UIKit.LINE
		label.color = txt
		queue_redraw()

	func set_text(t: String) -> void:
		label.text = t

	func _on_enter() -> void:
		_hover = true
		UIKit.tween_scale(self, 1.06, 0.12)
		UIKit.sfx("Click", -16.0, 1.6)

	func _on_exit() -> void:
		_hover = false
		_down = false
		UIKit.tween_scale(self, 1.0, 0.12)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_down = true
				UIKit.tween_scale(self, 0.95, 0.06)
			elif _down:
				_down = false
				UIKit.tween_scale(self, 1.06 if _hover else 1.0, 0.1)
				if _hover:
					UIKit.sfx("Click")
					pressed.emit()
			accept_event()


## UIKit.HazardStripe: fondo Accent con UIGradient de 11 puntos Accent/Negro a 20°.
class Hazard extends Control:
	var _tex: ImageTexture

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		resized.connect(_rebuild)

	func _rebuild() -> void:
		var w := maxi(1, int(size.x))
		var h := maxi(1, int(size.y))
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var ca := cos(deg_to_rad(20.0))
		var sa := sin(deg_to_rad(20.0))
		for y in h:
			for x in w:
				var u := (x + 0.5) / w
				var v := (y + 0.5) / h
				var t := clampf(0.5 + (u - 0.5) * ca + (v - 0.5) * sa, 0.0, 1.0)
				var seg := minf(floorf(t * 10.0), 9.0)
				var f := t * 10.0 - seg
				var even := int(seg) % 2 == 0
				var c0 := UIKit.ACCENT if even else UIKit.BLACK
				var c1 := UIKit.BLACK if even else UIKit.ACCENT
				img.set_pixel(x, y, c0.lerp(c1, f))
		_tex = ImageTexture.create_from_image(img)
		queue_redraw()

	func _draw() -> void:
		if _tex:
			draw_texture_rect(_tex, Rect2(Vector2.ZERO, size), false)


## UIKit.RigPreview: lienzo de 64 unidades (CY = 26) con torso, cabeza, casco del
## bando, arma (con su tinte) y las dos manos, todo con los sprites del rig.
class RigPreview extends Control:
	const CANVAS := 64.0
	const CY := 26.0
	var parts: Array = []
	var class_id := ""
	var team := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		resized.connect(queue_redraw)

	func setup(cls: String, tm: String, weapon_id: String = "") -> void:
		class_id = cls
		team = tm
		var rig: Dictionary = Sprites.RIGS.get(cls, Sprites.RIGS["Soldier"])
		if weapon_id == "":
			weapon_id = str(Data.get_class_data(cls).get("default_weapon", "Rifle"))
		var visual: Dictionary = Sprites.weapon_visual(weapon_id)
		parts = []
		parts.append([rig["Torso"]["image"], rig["Torso"]["center"], rig["Torso"]["scale"], Color.WHITE])
		parts.append([rig["Head"]["image"], rig["Head"]["center"], rig["Head"]["scale"], Color.WHITE])
		if rig.has("Hat"):
			parts.append([Sprites.TEAM_HELMET.get(tm, "SoldierHelmet"), rig["Hat"]["center"], rig["Hat"]["scale"], Color.WHITE])
		var gun: Vector2 = visual["pivot"] + visual["offset"]
		parts.append([visual["image"], gun, visual["scale"], visual.get("tint", Color.WHITE)])
		parts.append(["HandGrip", gun + visual["rear_hand"], 0.58, Color.WHITE])
		parts.append(["HandGrip", gun + visual["front_hand"], 0.58, Color.WHITE])
		queue_redraw()

	func _draw() -> void:
		for p in parts:
			var img: String = p[0]
			var center: Vector2 = p[1]
			var sc: float = p[2]
			var wh: Array = Sprites.IMAGES.get(img, [16, 16])
			var sz := Vector2(wh[0] * sc / CANVAS, wh[1] * sc / CANVAS) * size
			var pos := Vector2(0.5 + center.x / CANVAS, 0.5 - (center.y - CY) / CANVAS) * size
			var tex := Sprites.tex(img)
			if tex:
				draw_texture_rect(tex, Rect2(pos - sz * 0.5, sz), false, p[3])


## IntercomController.Talk: escribe el texto letra por letra y anima la boca del
## retrato (frame 1 en espacios y signos, 2 o 3 al azar en letras) con bips.
class Typewriter extends Node:
	signal finished
	var label: PixelFont.PixelLabel
	var portrait: TextureRect
	var text := ""
	var cps := 40.0
	var team := "USA"
	var running := false
	var _t := 0.0
	var _shown := 0

	func start(l: PixelFont.PixelLabel, p: TextureRect, t: String, chars_per_sec: float = 40.0, tm: String = "USA") -> void:
		label = l
		portrait = p
		text = t
		cps = chars_per_sec
		team = tm if Sprites.COMMANDERS.has(tm) else "USA"
		_t = 0.0
		_shown = 0
		label.text = ""
		running = true

	func stop() -> void:
		running = false
		if is_instance_valid(portrait):
			portrait.texture = UIKit.commander_frame(team, 1)

	func _process(delta: float) -> void:
		if not running:
			return
		if not is_instance_valid(label):
			running = false
			return
		_t += delta * cps
		var n := mini(int(_t), text.length())
		while _shown < n:
			_shown += 1
			var ch := text[_shown - 1]
			if is_instance_valid(portrait):
				if ch in " \t\n.,!?¡¿":
					portrait.texture = UIKit.commander_frame(team, 1)
				else:
					portrait.texture = UIKit.commander_frame(team, randi_range(2, 3))
					if _shown % 2 == 0:
						UIKit.sfx("Click", linear_to_db(0.25), (1.5 if team == "USA" else 1.9) * randf_range(0.75, 1.25))
		label.text = text.substr(0, _shown)
		if _shown >= text.length():
			label.text = text
			stop()
			finished.emit()
