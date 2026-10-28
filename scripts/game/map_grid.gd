class_name MapGrid
extends Node2D
## Mapa "Frente del Caramelo": grilla de bloques estáticos y construidos, losa
## de suelo, paredes, barreras del interludio y fondo con parallax.
##
## Grilla: col = round(x / 32); la fila r ocupa y ∈ [-32·r, -32·(r-1)] px.
## Debajo de la fila -1 hay una losa continua (filas <= -2 cuentan como sólidas).
##
## Replicación (servidor -> clientes):
##   BlockPlaced  {cell, team, owner, health, max_health}
##   BlockRemoved {cell, destroyed: bool, position}
##   BlockHealth  {cell, health}
##   BlocksSync   {blocks: [{cell, team, owner, health, max_health}, ...]}  (al entrar un par y al limpiar)
## En el anfitrión el estado ya está aplicado; los eventos solo disparan efectos.

## Se emite cada vez que cambia la grilla (bloque puesto, quitado o limpiado).
signal grid_changed

const MapData := preload("res://data/map_frente_caramelo.gd")

const MIN_COL := -64
const MAX_COL := 64
const MIN_ROW := -1
const MAX_ROW := 22
const SLAB_ROW := -2            # filas <= SLAB_ROW son losa
const SLAB_HALF_COLS := 65

## Bloques construidos (BuildSystem.TEXTURES): imagen, color de la Part y tiles en U.
## La textura no lleva tinte; al dañarse su color va de blanco a (90,60,60).
const BUILT_STYLE := {
	"sprinkle": {"image": "TileSprinkle", "color": Color8(235, 232, 240), "tiles": 1},
	"pink": {"image": "BlockPink", "color": Color8(245, 150, 175), "tiles": 3},
}
const DAMAGE_TINT := Color8(90, 60, 60)

## Bloques estáticos: el color de la textura depende del color del bloque
## (los tonos oscuros de cada paleta llevan el tinte oscuro).
const TINT_LIGHT := Color(0.882353, 0.843137, 0.823529)
const TINT_DARK := Color(0.54902, 0.490196, 0.490196)
const DARK_PART_COLORS := [Color8(71, 45, 33), Color8(45, 29, 52)]
## Color de la losa del suelo (se ve en las esquinas transparentes de la textura)
const SLAB_PART_COLOR := Color(0.215686, 0.137255, 0.101961)
## Color del Backdrop
const BACKDROP_IMAGE_COLOR := Color(0.588235, 0.470588, 0.54902)
## Fase horizontal de la Texture de cada capa de jungla
const JUNGLE_PHASE := {"jungle1": 0.347, "jungle2": 0.55}
## Decorados que se espejan cuando están del lado USA (x < 0)
const DECOR_MIRROR_WEST := ["grave", "deadtree", "tank", "sandbags", "wire", "crate"]
## SmokeColumn (Static.Background): X de cada emisor, Y = 10, Z = -140
const SMOKE_X := [-330.0, -200.0, -90.0, 40.0, 170.0, 290.0, 410.0]
const SMOKE_Z := -140.0

## Atmósfera (densidad 0.3, offset 0.25): a la distancia de cada capa
## el color final es color·k + off por canal.
const HAZE := {
	"plane": [Vector3(1.0, 1.0, 1.0), Vector3(-3.0, 6.0, 21.0)],
	"jungle2": [Vector3(0.791, 0.641, 0.553), Vector3(18.3, 40.6, 58.0)],
	"smoke": [Vector3(0.659, 0.590, 0.491), Vector3(34.5, 55.8, 78.6)],
	"jungle1": [Vector3(0.626, 0.578, 0.476), Vector3(38.5, 59.6, 83.7)],
	"backdrop": [Vector3(0.510, 0.210, 0.400), Vector3(53.4, 105.9, 125.3)],
}
const HAZE_SHADER := """
shader_type canvas_item;
uniform vec3 haze_k = vec3(1.0);
uniform vec3 haze_off = vec3(0.0);
void fragment() {
	// COLOR ya trae textura x modulate
	COLOR.rgb = COLOR.rgb * haze_k + haze_off;
}
"""

## Cámara: GC.CAMERA.visible_height_studs de alto
const CAM_DISTANCE := 72.0

## Referencia de cámara sin Camera2D activa.
const PARALLAX_REF := Vector2(0, -120)

## Cuenta de cambios (NavGrid la usa para invalidar su caché).
var revision := 0

var _static := {}      # Vector2i -> {kind, color}
var _built := {}       # Vector2i -> {team, owner, health, max_health, body}
var _barriers_on := false
var _barrier_shown := false

var _static_body: StaticBody2D
var _barrier_body: StaticBody2D
var _built_root: Node2D

var _layers := []          # capas de fondo con parallax [{node, z}]
var _static_layer: CanvasPart
var _built_layer: CanvasPart
var _decor_layer: CanvasPart
var _haze_shader: Shader


## Nodo que dibuja con una función externa.
class CanvasPart extends Node2D:
	var draw_fn: Callable

	func _draw() -> void:
		if draw_fn.is_valid():
			draw_fn.call(self)


func _ready() -> void:
	for b in MapData.parse_blocks():
		_static[Vector2i(b["col"], b["row"])] = {"kind": b["kind"], "color": b["color"]}
	_build_visuals()
	_build_collision()
	Net.event_received.connect(_on_event)
	Net.peer_joined.connect(_on_peer_joined)


# --- consultas ------------------------------------------------------------

func is_solid(col: int, row: int) -> bool:
	var c := Vector2i(col, row)
	if _static.has(c) or _built.has(c):
		return true
	return row <= SLAB_ROW and absi(col) <= SLAB_HALF_COLS


func is_built(col: int, row: int) -> bool:
	return _built.has(Vector2i(col, row))


func is_static(col: int, row: int) -> bool:
	return _static.has(Vector2i(col, row))


## {} si la celda está vacía; si no {static, kind, team, health, max_health, owner}.
func get_cell(col: int, row: int) -> Dictionary:
	var c := Vector2i(col, row)
	if _built.has(c):
		var b: Dictionary = _built[c]
		return {"static": false, "kind": "built", "team": b["team"], "health": b["health"],
			"max_health": b["max_health"], "owner": b["owner"]}
	if _static.has(c):
		return {"static": true, "kind": _static[c]["kind"], "team": "", "health": 0.0,
			"max_health": 0.0, "owner": ""}
	if row <= SLAB_ROW and absi(col) <= SLAB_HALF_COLS:
		return {"static": true, "kind": "slab", "team": "", "health": 0.0, "max_health": 0.0, "owner": ""}
	return {}


## Celdas construidas: {Vector2i: {team, owner, health, max_health}} (copia).
func get_built_cells() -> Dictionary:
	var out := {}
	for c in _built:
		var b: Dictionary = _built[c]
		out[c] = {"team": b["team"], "owner": b["owner"], "health": b["health"], "max_health": b["max_health"]}
	return out


func barriers_active() -> bool:
	return _barrier_shown


func _ray_blocked(cell: Vector2i, ignore_team: String) -> bool:
	if _built.has(cell):
		return ignore_team == "" or _built[cell]["team"] != ignore_team
	if _static.has(cell):
		return true
	return cell.y <= SLAB_ROW and absi(cell.x) <= SLAB_HALF_COLS


func _to_grid(p: Vector2) -> Vector2:
	return Vector2((p.x + GC.BLOCK * 0.5) / GC.BLOCK, -p.y / GC.BLOCK + 1.0)


## Recorre la grilla (DDA) de from_px a to_px. Ignora los construidos de ignore_team.
## Devuelve {hit: bool, position: Vector2 px, cell: Vector2i}.
func segment_hit(from_px: Vector2, to_px: Vector2, ignore_team: String = "") -> Dictionary:
	var a := _to_grid(from_px)
	var b := _to_grid(to_px)
	var d := b - a
	var cell := Vector2i(floori(a.x), floori(a.y))
	var end_cell := Vector2i(floori(b.x), floori(b.y))
	if _ray_blocked(cell, ignore_team):
		return {"hit": true, "position": from_px, "cell": cell}
	var sx := 1 if d.x > 0.0 else -1
	var sy := 1 if d.y > 0.0 else -1
	var tdx := INF if is_zero_approx(d.x) else 1.0 / absf(d.x)
	var tdy := INF if is_zero_approx(d.y) else 1.0 / absf(d.y)
	var tmx := INF
	if d.x > 0.0:
		tmx = (cell.x + 1 - a.x) * tdx
	elif d.x < 0.0:
		tmx = (a.x - cell.x) * tdx
	var tmy := INF
	if d.y > 0.0:
		tmy = (cell.y + 1 - a.y) * tdy
	elif d.y < 0.0:
		tmy = (a.y - cell.y) * tdy
	var steps := absi(end_cell.x - cell.x) + absi(end_cell.y - cell.y) + 2
	for i in steps:
		var t: float
		if tmx < tmy:
			t = tmx
			cell.x += sx
			tmx += tdx
		else:
			t = tmy
			cell.y += sy
			tmy += tdy
		if t > 1.0:
			break
		if _ray_blocked(cell, ignore_team):
			return {"hit": true, "position": from_px.lerp(to_px, t), "cell": cell}
	return {"hit": false, "position": to_px, "cell": end_cell}


# --- servidor -------------------------------------------------------------

func place_built(cell: Vector2i, team: String, owner_key: String) -> bool:
	if is_solid(cell.x, cell.y):
		return false
	var hp: float = GC.BUILD["block_health"]
	_add_built(cell, team, owner_key, hp, hp)
	Net.broadcast("BlockPlaced", {"cell": cell, "team": team, "owner": owner_key,
		"health": hp, "max_health": hp})
	return true


func remove_built(cell: Vector2i) -> bool:
	if not _built.has(cell):
		return false
	_remove_local(cell)
	Net.broadcast("BlockRemoved", {"cell": cell, "destroyed": false, "position": GC.cell_center(cell.x, cell.y)})
	return true


## Daña un bloque construido. Devuelve true si se destruyó. Los estáticos y los
## bloques del propio equipo no se dañan.
func damage_cell(cell: Vector2i, amount: float, attacker_team: String, attacker_key: String) -> bool:
	if not Net.is_server() or not _built.has(cell) or amount <= 0.0:
		return false
	var b: Dictionary = _built[cell]
	if attacker_team != "" and attacker_team == b["team"]:
		return false
	var team: String = b["team"]
	b["health"] = maxf(0.0, float(b["health"]) - amount)
	var target := {"kind": "block", "cell": cell}
	ServerEvents.structure_damaged.emit(target, amount, attacker_team, attacker_key)
	if b["health"] <= 0.0:
		_remove_local(cell)
		var pos := GC.cell_center(cell.x, cell.y)
		ServerEvents.structure_destroyed.emit(target, attacker_team, attacker_key)
		Net.broadcast("Structure", {"kind": "block", "cell": cell, "position": pos, "destroyed": true, "team": team})
		Net.broadcast("BlockRemoved", {"cell": cell, "destroyed": true, "position": pos})
		return true
	_built_layer.queue_redraw()
	Net.broadcast("BlockHealth", {"cell": cell, "health": b["health"]})
	return false


func clear_built() -> void:
	_clear_local()
	if Net.is_server():
		Net.broadcast("BlocksSync", {"blocks": []})


## Vuelve el mapa al estado inicial (sin red).
func reset() -> void:
	_clear_local()
	_barriers_on = false
	_apply_barriers(false)


## Barreras del interludio (x = ±114 studs). En clientes se muestran según la fase.
func set_barriers(on: bool) -> void:
	_barriers_on = on
	_apply_barriers(on)


func _apply_barriers(on: bool) -> void:
	if on == _barrier_shown:
		return
	_barrier_shown = on
	# Barreras del interludio: invisibles; solo colisionan
	for s in _barrier_body.get_children():
		(s as CollisionShape2D).set_deferred("disabled", not on)


# --- estado local ---------------------------------------------------------

func _add_built(cell: Vector2i, team: String, owner_key: String, hp: float, max_hp: float) -> void:
	if _built.has(cell):
		_remove_local(cell)
	var body := StaticBody2D.new()
	body.collision_layer = GC.built_layer(team)
	body.collision_mask = 0
	body.position = GC.cell_center(cell.x, cell.y)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(GC.BLOCK, GC.BLOCK)
	cs.shape = rect
	body.add_child(cs)
	body.set_meta("cell", cell)
	body.set_meta("team", team)
	_built_root.add_child(body)
	_built[cell] = {"team": team, "owner": owner_key, "health": hp, "max_health": max_hp, "body": body}
	_changed()


func _remove_local(cell: Vector2i) -> void:
	if not _built.has(cell):
		return
	var body: Node = _built[cell]["body"]
	if is_instance_valid(body):
		body.queue_free()
	_built.erase(cell)
	_changed()


func _clear_local() -> void:
	for c in _built.keys():
		var body: Node = _built[c]["body"]
		if is_instance_valid(body):
			body.queue_free()
	_built.clear()
	_changed()


func _changed() -> void:
	revision += 1
	if _built_layer:
		_built_layer.queue_redraw()
	grid_changed.emit()


# --- red ------------------------------------------------------------------

func _on_peer_joined(peer_id: int) -> void:
	var list := []
	for c in _built:
		var b: Dictionary = _built[c]
		list.append({"cell": c, "team": b["team"], "owner": b["owner"], "health": b["health"],
			"max_health": b["max_health"]})
	Net.send_to(peer_id, "BlocksSync", {"blocks": list})


func _on_event(event: String, data) -> void:
	if not (data is Dictionary):
		return
	var server := Net.is_server()
	match event:
		"BlockPlaced":
			var cell: Vector2i = data.get("cell", Vector2i.ZERO)
			if not server:
				_add_built(cell, str(data.get("team", "")), str(data.get("owner", "")),
					float(data.get("health", 160.0)), float(data.get("max_health", 160.0)))
			_spawn_debris(GC.cell_center(cell.x, cell.y) + Vector2(0, GC.BLOCK * 0.5), Color8(200, 180, 160), 5, 60.0)
		"BlockRemoved":
			var cell: Vector2i = data.get("cell", Vector2i.ZERO)
			var color := _built_color(cell)
			if not server:
				_remove_local(cell)
			if data.get("destroyed", false):
				_spawn_debris(GC.cell_center(cell.x, cell.y), color, 14, 180.0)
		"BlockHealth":
			if not server:
				var cell: Vector2i = data.get("cell", Vector2i.ZERO)
				if _built.has(cell):
					_built[cell]["health"] = float(data.get("health", 0.0))
					_built_layer.queue_redraw()
		"BlocksSync":
			if not server:
				_clear_local()
				for b in data.get("blocks", []):
					if b is Dictionary:
						_add_built(b.get("cell", Vector2i.ZERO), str(b.get("team", "")), str(b.get("owner", "")),
							float(b.get("health", 160.0)), float(b.get("max_health", 160.0)))


func _built_color(cell: Vector2i) -> Color:
	if _built.has(cell):
		return _built_style(_built[cell]["team"])["color"]
	return Color8(220, 200, 210)


func _built_style(team: String) -> Dictionary:
	var key: String = GC.TEAM_INFO.get(team, {}).get("block", "sprinkle")
	return BUILT_STYLE.get(key, BUILT_STYLE["sprinkle"])


## Escombros simples (partículas de un disparo).
func _spawn_debris(pos: Vector2, color: Color, amount: int, speed: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 15
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.8
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, GC.GRAVITY_STUDS * GC.STUD * 0.6)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = color
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(GC.BLOCK * 0.4, GC.BLOCK * 0.4)
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


# --- colisión -------------------------------------------------------------

func _add_rect(body: StaticBody2D, rect: Rect2) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.get_center()
	body.add_child(cs)
	return cs


func _build_collision() -> void:
	_static_body = StaticBody2D.new()
	_static_body.name = "StaticCollision"
	_static_body.collision_layer = GC.LAYER_WORLD
	_static_body.collision_mask = 0
	add_child(_static_body)
	# bloques estáticos fusionados en tiras horizontales por fila
	for row in range(MIN_ROW, MAX_ROW + 1):
		var col := MIN_COL - 1
		while col <= MAX_COL + 1:
			if _static.has(Vector2i(col, row)):
				var start := col
				while _static.has(Vector2i(col + 1, row)):
					col += 1
				var x0 := start * GC.BLOCK - GC.BLOCK * 0.5
				var x1 := col * GC.BLOCK + GC.BLOCK * 0.5
				_add_rect(_static_body, Rect2(x0, -row * GC.BLOCK, x1 - x0, GC.BLOCK))
			col += 1
	# losa de suelo
	var slab: Dictionary = MapData.GROUND_SLAB
	var hw: float = slab["half_width_studs"] * GC.STUD
	var top: float = -slab["top_studs"] * GC.STUD
	var bottom: float = -slab["bottom_studs"] * GC.STUD
	_add_rect(_static_body, Rect2(-hw, top, hw * 2.0, bottom - top))
	# paredes laterales (por encima de las columnas ±64, hasta muy arriba)
	var wall_x := MAX_COL * GC.BLOCK + GC.BLOCK * 0.5
	_add_rect(_static_body, Rect2(wall_x, -4000.0, 64.0, 4000.0 + bottom))
	_add_rect(_static_body, Rect2(-wall_x - 64.0, -4000.0, 64.0, 4000.0 + bottom))

	_built_root = Node2D.new()
	_built_root.name = "BuiltCollision"
	add_child(_built_root)

	_barrier_body = StaticBody2D.new()
	_barrier_body.name = "Barriers"
	_barrier_body.collision_layer = GC.LAYER_BARRIER
	_barrier_body.collision_mask = 0
	add_child(_barrier_body)
	for x in MapData.PREP_BARRIERS:
		var cs := _add_rect(_barrier_body, Rect2(x * GC.STUD - GC.STUD * 0.5, -80.0 * GC.STUD, GC.STUD, 80.0 * GC.STUD + GC.BLOCK))
		cs.disabled = true


# --- dibujo ---------------------------------------------------------------
# Todo sale de las texturas originales (Sprites) con sus parámetros:
# Color del bloque debajo, textura (studs por mosaico, desplazamiento, tinte) encima.

func _haze_material(layer: String) -> ShaderMaterial:
	if _haze_shader == null:
		_haze_shader = Shader.new()
		_haze_shader.code = HAZE_SHADER
	var m := ShaderMaterial.new()
	m.shader = _haze_shader
	var h: Array = HAZE[layer]
	m.set_shader_parameter("haze_k", h[0])
	m.set_shader_parameter("haze_off", (h[1] as Vector3) / 255.0)
	return m


func _make_layer(lname: String, z: int, fn: Callable, haze: String, parent: Node = self) -> CanvasPart:
	var n := CanvasPart.new()
	n.name = lname
	n.z_index = z
	n.draw_fn = fn
	n.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	n.material = _haze_material(haze)
	parent.add_child(n)
	return n


## Capa de fondo a profundidad z (studs, negativa) con parallax de perspectiva.
func _make_depth_layer(lname: String, z_index_: int, depth: float) -> Node2D:
	var n := Node2D.new()
	n.name = lname
	n.z_index = z_index_
	add_child(n)
	_layers.append({"node": n, "z": depth})
	return n


func _build_visuals() -> void:
	var bg: Dictionary = Sprites.BACKGROUND
	var back := _make_depth_layer("Backdrop", -100, bg["backdrop"]["z"])
	_make_layer("Image", 0, _draw_backdrop, "backdrop", back)
	var j1 := _make_depth_layer("Jungle1", -98, bg["jungle1"]["z"])
	_make_layer("Image", 0, _draw_jungle.bind("jungle1"), "jungle1", j1)
	var smoke := _make_depth_layer("Smoke", -97, SMOKE_Z)
	_build_smoke(smoke)
	var j2 := _make_depth_layer("Jungle2", -96, bg["jungle2"]["z"])
	_make_layer("Image", 0, _draw_jungle.bind("jungle2"), "jungle2", j2)
	_static_layer = _make_layer("Static", -10, _draw_static, "plane")
	_built_layer = _make_layer("Built", -9, _draw_built, "plane")
	# Decor_* están en z = 2.1, delante de la cara de los bloques
	_decor_layer = _make_layer("Decor", -8, _draw_decor, "plane")
	_update_parallax()


## Centro de cámara (px) y distancia equivalente de la cámara (studs).
func _camera_state() -> Array:
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	if cam == null or cam.zoom.y <= 0.0:
		return [PARALLAX_REF, CAM_DISTANCE]
	var vis_h := get_viewport().get_visible_rect().size.y / cam.zoom.y
	var dist := CAM_DISTANCE * vis_h / (float(GC.CAMERA["visible_height_studs"]) * GC.STUD)
	return [cam.get_screen_center_position(), dist]


func _update_parallax() -> void:
	var st := _camera_state()
	var c: Vector2 = st[0]
	var dist: float = st[1]
	for l in _layers:
		# proyección de un plano a profundidad z: escala dist / (dist - z) alrededor de la cámara
		var s := dist / (dist - float(l["z"]))
		var n: Node2D = l["node"]
		n.scale = Vector2(s, s)
		n.position = c * (1.0 - s)


func _process(_delta: float) -> void:
	_update_parallax()
	# en clientes las barreras siguen la fase replicada
	if not Net.is_server():
		_apply_barriers(Net.mode != Net.Mode.NONE and MatchState.phase() == "Prep")
	elif Net.mode == Net.Mode.NONE and _barrier_shown:
		_apply_barriers(false)
	# transparencia de los bloques propios depende del equipo local
	var my_team: String = str(MatchState.my_player("Team", ""))
	if my_team != _last_team:
		_last_team = my_team
		_built_layer.queue_redraw()

var _last_team := ""


## Rect en px de un rectángulo dado por centro y tamaño en studs.
func _studs_rect(center: Vector2, size: Vector2) -> Rect2:
	return Rect2(center.x * GC.STUD - size.x * GC.STUD * 0.5, -center.y * GC.STUD - size.y * GC.STUD * 0.5,
		size.x * GC.STUD, size.y * GC.STUD)


func _draw_backdrop(ci: CanvasItem) -> void:
	var d: Dictionary = Sprites.BACKGROUND["backdrop"]
	var tex := Sprites.tex(d["image"])
	if tex:
		ci.draw_texture_rect(tex, _studs_rect(d["center"], d["size"]), false, BACKDROP_IMAGE_COLOR)


func _draw_jungle(ci: CanvasItem, key: String) -> void:
	var d: Dictionary = Sprites.BACKGROUND[key]
	var tex := Sprites.tex(d["image"])
	if tex == null:
		return
	var size: Vector2 = d["size"]
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var src := Rect2(float(JUNGLE_PHASE[key]) * tw, 0, size.x / float(d["studs_u"]) * tw, size.y / float(d["studs_v"]) * th)
	ci.draw_texture_rect_region(tex, _studs_rect(d["center"], size), src, d["tint"])


## SmokeColumn: emisor de humo (Rate 1.5, Lifetime 10-14,
## Speed 5-8 hacia arriba, Spread 8, Acceleration (3,1), Size 8->40,
## Transparency 0.4->1, Color (60,50,60)->(120,100,110), LightInfluence 0).
func _build_smoke(parent: Node2D) -> void:
	var tex := Sprites.tex("Smoke")
	if tex == null:
		return
	var holder := Node2D.new()
	holder.name = "Columns"
	holder.material = _haze_material("smoke")
	holder.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(holder)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.235294, 0.196078, 0.235294, 0.6))
	ramp.set_color(1, Color(0.470588, 0.392157, 0.431373, 0.0))
	var size_curve := Curve.new()
	size_curve.add_point(Vector2(0, 8.0 / 40.0))
	size_curve.add_point(Vector2(1, 1.0))
	var full_scale := 40.0 * GC.STUD / float(tex.get_width())
	for x in SMOKE_X:
		var p := CPUParticles2D.new()
		p.texture = tex
		p.use_parent_material = true
		p.position = Vector2(x * GC.STUD, -10.0 * GC.STUD)
		p.amount = 21
		p.lifetime = 14.0
		p.lifetime_randomness = 4.0 / 14.0
		p.preprocess = 14.0
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(4.0 * GC.STUD, 0.5 * GC.STUD)
		p.direction = Vector2(0, -1)
		p.spread = 8.0
		p.initial_velocity_min = 5.0 * GC.STUD
		p.initial_velocity_max = 8.0 * GC.STUD
		p.gravity = Vector2(3.0 * GC.STUD, -1.0 * GC.STUD)
		p.scale_amount_min = full_scale
		p.scale_amount_max = full_scale
		p.scale_amount_curve = size_curve
		p.color_ramp = ramp
		holder.add_child(p)


func _cell_rect(c: Vector2i) -> Rect2:
	return Rect2(c.x * GC.BLOCK - GC.BLOCK * 0.5, -c.y * GC.BLOCK, GC.BLOCK, GC.BLOCK)


## Recorte de la textura para la celda: la Texture cubre tiles·4 studs y su
## OffsetStudsU = (col mod tiles)·4, así el dibujo sigue continuo entre bloques.
func _block_src(tex: Texture2D, tiles: int, col: int) -> Rect2:
	var w := float(tex.get_width()) / tiles
	return Rect2(posmod(col, tiles) * w, 0, w, tex.get_height())


func _draw_static(ci: CanvasItem) -> void:
	# GroundSlab: 520x8 studs, BlockChoco 12x4 desde su borde izquierdo, tinte "slab"
	var slab: Dictionary = MapData.GROUND_SLAB
	var hw: float = slab["half_width_studs"] * GC.STUD
	var top: float = -slab["top_studs"] * GC.STUD
	var bottom: float = -slab["bottom_studs"] * GC.STUD
	var srect := Rect2(-hw, top, hw * 2, bottom - top)
	ci.draw_rect(srect, SLAB_PART_COLOR)
	var st: Dictionary = Sprites.BLOCK_TEXTURES["slab"]
	var stex := Sprites.tex(st["image"])
	if stex:
		var su := srect.size.x / (float(st["studs_u"]) * GC.STUD) * stex.get_width()
		var sv := srect.size.y / (float(st["studs_v"]) * GC.STUD) * stex.get_height()
		ci.draw_texture_rect_region(stex, srect, Rect2(0, 0, su, sv), st["tint"])
	for c in _static:
		var b: Dictionary = _static[c]
		var info: Dictionary = Sprites.BLOCK_TEXTURES[b["kind"]]
		var tint := TINT_DARK if DARK_PART_COLORS.has(b["color"]) else TINT_LIGHT
		var r := _cell_rect(c)
		ci.draw_rect(r, b["color"])
		var tex := Sprites.tex(info["image"])
		if tex:
			var tiles := int(round(float(info["studs_u"]) / GC.BLOCK_STUDS))
			ci.draw_texture_rect_region(tex, r, _block_src(tex, tiles, c.x), tint)


func _draw_built(ci: CanvasItem) -> void:
	for c in _built:
		var b: Dictionary = _built[c]
		var style := _built_style(b["team"])
		var ratio := clampf(float(b["health"]) / maxf(1.0, float(b["max_health"])), 0.0, 1.0)
		var tint := Color.WHITE.lerp(DAMAGE_TINT, 1.0 - ratio)
		# LocalTransparencyModifier 0.2 en los bloques del propio equipo
		var alpha := 0.8 if b["team"] == _last_team else 1.0
		var r := _cell_rect(c)
		var pc: Color = style["color"]
		ci.draw_rect(r, Color(pc, alpha))
		var tex := Sprites.tex(style["image"])
		if tex:
			tint.a = alpha
			ci.draw_texture_rect_region(tex, r, _block_src(tex, int(style["tiles"]), c.x), tint)


func _draw_decor(ci: CanvasItem) -> void:
	for d in MapData.DECOR:
		var info: Dictionary = Sprites.DECOR.get(d[0], {})
		var tex := Sprites.tex(info.get("image", ""))
		if tex == null:
			continue
		var r := _studs_rect(Vector2(d[1], d[2]), Vector2(d[3], d[4]))
		if DECOR_MIRROR_WEST.has(d[0]) and float(d[1]) < 0.0:
			var cx := r.get_center().x
			ci.draw_set_transform(Vector2(cx, 0), 0.0, Vector2(-1, 1))
			ci.draw_texture_rect(tex, Rect2(r.position.x - cx, r.position.y, r.size.x, r.size.y), false)
			ci.draw_set_transform(Vector2.ZERO)
		else:
			ci.draw_texture_rect(tex, r, false)
