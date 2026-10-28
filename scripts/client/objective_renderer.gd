extends Node2D
## ObjectiveRenderer: dibuja los objetivos de la ronda (marcadores que manda el
## servidor con "ObjMarkers") y flechas en el borde de la pantalla hacia ellos.
## Port fiel de StarterPlayerScripts.Controllers.ObjectiveRenderer:
## cada marcador es un cartel de N studs centrado en Position + Offset;
## adentro se dibuja en píxeles de pantalla (rectángulos con borde),
## con los sprites originales (FlagUSA/FlagVN, Radio, Depot, Ico*).
## La bandera cargada en la espalda la dibuja el rig (gummy_rig).

const S := GC.STUD
const BAR_BACK := Color8(15, 15, 15)
const MAST := Color8(70, 60, 50)
const HILL_NEUTRAL := Color8(230, 230, 230)
const ARROW_MARGIN := 60.0

var _markers: Array = []
var _vis := {}             # Id -> {T, LastHealth, Shake, Rot}
var _cur_bb := Transform2D.IDENTITY
var _arrow_layer: CanvasLayer
var _arrows: Node2D
var _font_header: Font
var _font_mono: Font


func _ready() -> void:
	_font_header = UIKit.font("header")
	_font_mono = UIKit.font("mono")
	_arrow_layer = CanvasLayer.new()
	_arrow_layer.name = "ObjectiveArrows"
	_arrow_layer.layer = 4      # DisplayOrder = 4
	add_child(_arrow_layer)
	_arrows = Node2D.new()
	_arrows.name = "Arrows"
	_arrow_layer.add_child(_arrows)
	_arrows.draw.connect(_draw_arrows)
	Net.event_received.connect(_on_event)
	G.session_ended.connect(func():
		_markers = []
		_vis.clear())


func _on_event(event: String, data) -> void:
	if event == "ObjMarkers" and data is Array:
		_markers = data


func _id(m: Dictionary) -> String:
	return String(m.get("Id", m.get("Kind", "")))


func _process(dt: float) -> void:
	var seen := {}
	for m in _markers:
		if not (m is Dictionary):
			continue
		var id := _id(m)
		seen[id] = true
		var v: Dictionary = _vis.get(id, {"T": 0.0, "LastHealth": m.get("Health", null), "Shake": 0.0, "Rot": 0.0})
		v["T"] = float(v["T"]) + dt
		if m.get("Kind", "") == "Depot":
			var hp := float(m.get("Health", 0.0))
			var mx := maxf(float(m.get("MaxHealth", 1.0)), 0.001)
			var p: Vector2 = m.get("position", Vector2.ZERO)
			if v["LastHealth"] != null and hp < float(v["LastHealth"]):
				v["Shake"] = 0.15
				if randf() < 0.3 and G.fx:
					G.fx.spawn("spark", p, {"dir": Vector2(0, -1), "count": 2})
			v["LastHealth"] = hp
			v["Shake"] = maxf(0.0, float(v["Shake"]) - dt)
			v["Rot"] = (randf() - 0.5) * 8.0 if float(v["Shake"]) > 0.0 else 0.0
			if hp / mx < 0.35 and randf() < 0.1 and G.fx:
				G.fx.spawn("smoke", p + Vector2(0, -2.0 * S), {"count": 1, "scale": 0.8, "color": Color8(60, 60, 60)})
		_vis[id] = v
	for id in _vis.keys():
		if not seen.has(id):
			_vis.erase(id)
	queue_redraw()
	_arrows.queue_redraw()


# --- utilidades ----------------------------------------------------------

func _team_color(team: String) -> Color:
	return GC.team_color(team)


func _t(m: Dictionary) -> float:
	return float(_vis.get(_id(m), {}).get("T", 0.0))


func _zoom() -> float:
	return maxf(get_viewport().get_canvas_transform().get_scale().x, 0.001)


func _studs(v: Vector2) -> Vector2:
	return Vector2(v.x, -v.y) * S


## Empieza un cartel centrado en `center` (mundo, px) de `size_studs`.
## Desde acá se dibuja en píxeles de pantalla con origen en el centro del
## billboard (así bordes, esquinas y textos mantienen su medida).
func _bb(center: Vector2, size_studs: Vector2) -> Vector2:
	var z := _zoom()
	_cur_bb = Transform2D(0.0, Vector2(1.0 / z, 1.0 / z), 0.0, center)
	draw_set_transform_matrix(_cur_bb)
	return size_studs * S * z


## Rect de un hijo del billboard (en escala) con punto de anclaje.
func _child_rect(bb: Vector2, anchor: Vector2, pos: Vector2, size: Vector2) -> Rect2:
	var sz := size * bb
	return Rect2(-bb * 0.5 + pos * bb - anchor * sz, sz)


## Rectángulo de color plano con borde por fuera.
func _frame(r: Rect2, color: Color, stroke: float) -> void:
	if stroke > 0.0:
		draw_rect(r.grow(stroke), Color.BLACK)
	draw_rect(r, color)


## Barra: fondo (15,15,15), borde 1.5 negro y relleno a `frac`.
func _bar(r: Rect2, color: Color, frac: float) -> void:
	_frame(r, BAR_BACK, 1.5)
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), color)


## Texto escalado: el texto se ajusta a la caja (centrado), con borde negro.
func _label(ci: CanvasItem, r: Rect2, text: String, color: Color, font: Font) -> void:
	var fs := int(clampf(r.size.y, 1.0, 100.0))
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if w > r.size.x and w > 0.0:
		fs = maxi(1, int(fs * r.size.x / w))
		w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := Vector2(r.get_center().x - w * 0.5, r.get_center().y - font.get_height(fs) * 0.5 + font.get_ascent(fs))
	ci.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(2, int(fs * 0.18)), Color(UIKit.BLACK, color.a))
	ci.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


## Imagen estirada con rotación `deg` alrededor de su centro.
func _sprite(r: Rect2, image: String, deg: float) -> void:
	var tex := Sprites.tex(image)
	if tex == null:
		return
	draw_set_transform_matrix(_cur_bb * Transform2D(deg_to_rad(deg), r.get_center()))
	draw_texture_rect(tex, Rect2(-r.size * 0.5, r.size), false)
	draw_set_transform_matrix(_cur_bb)


func _root_of(ch: Node) -> Vector2:
	if ch.has_method("center_position"):
		return ch.center_position()
	return ch.feet_position() + Vector2(0, -GC.CHARACTER["feet_offset"] * S)


func _show_arrows() -> bool:
	return not G.menu_open and MatchState.phase() == "Round" and Net.mode != Net.Mode.NONE


# --- dibujo en el mundo --------------------------------------------------

func _draw() -> void:
	if _markers.is_empty():
		return
	for kind in ["Hill", "FlagStand", "Depot", "Radio", "Flag"]:
		for m in _markers:
			if m is Dictionary and m.get("Kind", "") == kind:
				match kind:
					"Hill":
						_draw_hill(m)
					"FlagStand":
						_draw_stand(m)
					"Depot":
						_draw_depot(m)
					"Radio":
						_draw_radio(m)
					"Flag":
						_draw_flag(m)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _hill_color(m: Dictionary) -> Color:
	var owner: String = m.get("Owner", "")
	if owner == "Contested":
		return _team_color("USA") if sin(_t(m) * 10.0) > 0.0 else _team_color("Vietnam")
	if owner == "USA" or owner == "Vietnam":
		return _team_color(owner)
	return HILL_NEUTRAL


func _hill_label(m: Dictionary) -> String:
	var owner: String = m.get("Owner", "")
	if owner == "Contested":
		return "¡EN DISPUTA!"
	if owner == "USA" or owner == "Vietnam":
		return "COLINA · " + String(GC.TEAM_INFO[owner]["display"])
	return "★ COLINA ★"


func _draw_hill(m: Dictionary) -> void:
	var a: Vector2 = m.get("Min", Vector2(-34 * S, -30 * S))
	var b: Vector2 = m.get("Max", Vector2(34 * S, 0))
	var bb := _bb((a + b) * 0.5, (b - a).abs() / S)
	var color := _hill_color(m)
	# Fondo: transparencia 0.84 + sin(T*3)*0.04, borde 3 (transp. 0.2), esquinas 8
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 1.0 - (0.84 + sin(_t(m) * 3.0) * 0.04))
	sb.border_color = Color(color, 0.8)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(11)
	draw_style_box(sb, Rect2(-bb * 0.5, bb).grow(3.0))
	_label(self, _child_rect(bb, Vector2(0.5, 0), Vector2(0.5, 0.02), Vector2(0.6, 0.09)),
		_hill_label(m), UIKit.TEXT, _font_header)


func _draw_stand(m: Dictionary) -> void:
	var team: String = m.get("Team", "")
	var p: Vector2 = m.get("position", Vector2.ZERO)
	var bb := _bb(p + _studs(Vector2(0, 4)), Vector2(4, 8))
	# mástil (color 70,60,50 + borde 1)
	_frame(_child_rect(bb, Vector2(0.5, 1), Vector2(0.42, 1), Vector2(0.07, 0.95)), MAST, 1.0)
	# base (color del equipo oscurecido + borde 1)
	_frame(_child_rect(bb, Vector2(0.5, 1), Vector2(0.5, 1), Vector2(0.9, 0.08)),
		_team_color(team).lerp(Color.BLACK, 0.4), 1.0)


func _draw_flag(m: Dictionary) -> void:
	var st: String = m.get("State", "Home")
	if st == "Carried":
		return   # la dibuja el rig del portador (CarryingFlag)
	var team: String = m.get("Team", "")
	var p: Vector2 = m.get("position", Vector2.ZERO)
	var bb := _bb(p + _studs(Vector2(1.4, 6.6)), Vector2(3.6, 2.4))
	var t := _t(m)
	var rot := sin(t * 6.0) * 5.0
	if st == "Dropped":
		rot = 70.0 + sin(t * 3.0) * 5.0
	_sprite(Rect2(-bb * 0.5, bb), Sprites.TEAM_FLAG.get(team, "FlagUSA"), rot)


func _draw_radio(m: Dictionary) -> void:
	if not m.get("Active", false):
		return
	var p: Vector2 = m.get("position", Vector2.ZERO)
	var t := _t(m)
	var bb := _bb(p + _studs(Vector2(0, 3)), Vector2(6, 6))
	var rot := sin(t * 20.0) * (6.0 if m.get("Contested", false) else 2.0)
	_sprite(_child_rect(bb, Vector2(0.5, 1), Vector2(0.5, 1), Vector2(0.42, 0.6)), "Radio", rot)
	_label(self, _child_rect(bb, Vector2(0.5, 1), Vector2(0.5, 0.18), Vector2(1.6, 0.16)), "SEÑAL",
		Color(UIKit.GOOD, 1.0 - (0.2 + sin(t * 6.0) * 0.2)), _font_header)
	_bar(_child_rect(bb, Vector2(0.5, 0), Vector2(0.5, 0.2), Vector2(1, 0.06)), _team_color("USA"), float(m.get("HackUSA", 0.0)))
	_bar(_child_rect(bb, Vector2(0.5, 0), Vector2(0.5, 0.28), Vector2(1, 0.06)), _team_color("Vietnam"), float(m.get("HackVietnam", 0.0)))


func _draw_depot(m: Dictionary) -> void:
	var hp := float(m.get("Health", 0.0))
	if hp <= 0.0:
		return   # Bb.Enabled = hp > 0
	var team: String = m.get("Team", "")
	var p: Vector2 = m.get("position", Vector2.ZERO)   # centro de la parte (4.4 x 4.2 studs)
	var mx := maxf(float(m.get("MaxHealth", 1.0)), 0.001)
	var bb := _bb(p + _studs(Vector2(0, 1.4)), Vector2(5.2, 7))
	var rot := float(_vis.get(_id(m), {}).get("Rot", 0.0))
	_sprite(_child_rect(bb, Vector2(0.5, 1), Vector2(0.5, 1), Vector2(1, 0.65)), "Depot", rot)
	_bar(_child_rect(bb, Vector2(0.5, 0), Vector2(0.5, 0.12), Vector2(1, 0.07)), _team_color(team), hp / mx)
	_label(self, _child_rect(bb, Vector2(0.5, 1), Vector2(0.5, 0.11), Vector2(1.6, 0.12)),
		"DEPÓSITO " + String(GC.TEAM_INFO.get(team, {}).get("display", team)), _team_color(team), _font_header)


# --- flechas en el borde de pantalla ------------------------------------

## Lista de {pos (mundo), icon, color}.
func _arrow_targets() -> Array:
	var out: Array = []
	for m in _markers:
		if not (m is Dictionary):
			continue
		var p: Vector2 = m.get("position", Vector2.ZERO)
		match m.get("Kind", ""):
			"Flag":
				out.append({"pos": p + _studs(Vector2(0, 4)), "icon": "IcoFlag", "color": _team_color(m.get("Team", ""))})
			"Hill":
				var a: Vector2 = m.get("Min", p)
				var b: Vector2 = m.get("Max", p)
				out.append({"pos": (a + b) * 0.5, "icon": "IcoHill", "color": _hill_color(m)})
			"Radio":
				if m.get("Active", false):
					out.append({"pos": p + _studs(Vector2(0, 3)), "icon": "IcoRadio", "color": UIKit.GOOD})
			"Depot":
				out.append({"pos": p + _studs(Vector2(0, 3)), "icon": "IcoTnt", "color": _team_color(m.get("Team", ""))})
	# VIPs: corona si es aliado, blanco si es enemigo
	var mine: String = MatchState.my_player("Team", "")
	var me := G.local_character()
	for ch in G.all_characters():
		if ch == me or not ch.has_method("get_attr"):
			continue
		if ch.get_attr("VIP", false) and ch.has_method("is_alive") and ch.is_alive():
			var t: String = ch.team()
			out.append({"pos": _root_of(ch) + _studs(Vector2(0, 4)),
				"icon": "IcoCrown" if t == mine else "IcoTarget", "color": _team_color(t)})
	return out


func _draw_arrows() -> void:
	if not _show_arrows():
		return
	var targets := _arrow_targets()
	if targets.is_empty():
		return
	var xf := get_viewport().get_canvas_transform()
	var vp := get_viewport().get_visible_rect().size
	var cx := vp.x * 0.5
	var cy := vp.y * 0.5
	var me := G.local_character()
	var me_pos = _root_of(me) if me and is_instance_valid(me) else null
	var a := _arrows
	for tg in targets:
		var world: Vector2 = tg["pos"]
		var color: Color = tg["color"]
		var sp := xf * world
		var inside := sp.x > ARROW_MARGIN and sp.x < vp.x - ARROW_MARGIN \
			and sp.y > ARROW_MARGIN + 60.0 and sp.y < vp.y - ARROW_MARGIN - 80.0
		var pos: Vector2
		var size: float
		var pointer: Vector2
		if inside:
			pos = Vector2(sp.x, sp.y - 70.0)
			size = 34.0
			pointer = pos + Vector2(0, size * 0.5 + 2.0)
		else:
			var dx := sp.x - cx
			var dy := sp.y - cy
			var sx := (vp.x * 0.5 - ARROW_MARGIN) / maxf(absf(dx), 1.0)
			var sy := (vp.y * 0.5 - ARROW_MARGIN - 70.0) / maxf(absf(dy), 1.0)
			var s := minf(sx, sy)
			pos = Vector2(cx + dx * s, cy + dy * s)
			size = 46.0
			var ang := atan2(dy, dx)
			pointer = pos + Vector2(cos(ang), sin(ang)) * 0.62 * size
		var r := size * 0.5
		# Anillo: panel con transparencia 0.15, redondo, borde 2.5 del color
		a.draw_circle(pos, r, Color(UIKit.PANEL, 0.85))
		a.draw_arc(pos, r + 1.25, 0.0, TAU, 48, color, 2.5)
		# Icon: sprite al 60 %
		var tex := Sprites.tex(String(tg["icon"]))
		if tex:
			var isz := size * 0.6
			a.draw_texture_rect(tex, Rect2(pos - Vector2(isz, isz) * 0.5, Vector2(isz, isz)), false)
		# Puntero: cuadrado 12x12 rotado 45°
		var h := 6.0 * sqrt(2.0)
		a.draw_colored_polygon(PackedVector2Array([pointer + Vector2(0, -h), pointer + Vector2(h, 0),
			pointer + Vector2(0, h), pointer + Vector2(-h, 0)]), color)
		# Dist: 60x14, fuente Mono, debajo del aro
		if me_pos != null:
			var dist := int(floor((Vector2(me_pos) - world).length() / S / 4.0))
			_label(a, Rect2(pos + Vector2(-30, r + 2.0), Vector2(60, 14)), "%dm" % dist, UIKit.TEXT, _font_mono)
