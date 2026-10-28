extends Node2D
## Modo construcción (solo en el interludio): bloque fantasma en la grilla,
## click izquierdo coloca, click derecho quita. Tecla B (acción "build_mode").
## Como BuildController.lua: el fantasma es una Part Neon de 4x4 con
## Transparency 0.55 y SelectionBox (0,08 studs) del mismo color, verde si la celda
## está en la zona y quedan bloques, rojo si no. La zona (BuildZone) es una Part
## Neon del color del equipo con Transparency 0.8 detrás de los bloques (z = -2,2),
## desde el suelo hasta Build.MaxRow.

const OK_COLOR := Color8(120, 255, 120)
const BAD_COLOR := Color8(255, 80, 80)
const GHOST_ALPHA := 1.0 - 0.55
const ZONE_ALPHA := 1.0 - 0.8
const BOX_THICKNESS_STUDS := 0.08

var _hover := Vector2i.ZERO
var _hover_ok := false
var _zone: Node2D


## Zona de construcción: se dibuja detrás de los bloques del mapa.
class ZonePart extends Node2D:
	var ctrl: Node

	func _draw() -> void:
		ctrl.draw_zone(self)


func _ready() -> void:
	z_index = 12
	visible = false
	_zone = ZonePart.new()
	_zone.ctrl = self
	_zone.z_as_relative = false
	_zone.z_index = -11
	add_child(_zone)
	G.session_ended.connect(_on_session_ended)
	MatchState.var_changed.connect(_on_var_changed)


func _on_session_ended() -> void:
	set_enabled(false)


func _on_var_changed(k: String, v) -> void:
	if k == "Phase" and str(v) != "Prep":
		set_enabled(false)


func _my_team() -> String:
	return str(MatchState.my_player("Team", ""))


func _can_enable() -> bool:
	return Net.mode != Net.Mode.NONE and MatchState.phase() == "Prep" \
		and bool(MatchState.my_player("Deployed", false)) and GC.BUILD.has(_my_team())


func set_enabled(on: bool) -> void:
	if on and not _can_enable():
		on = false
	G.build_mode = on
	visible = on
	queue_redraw()
	_zone.queue_redraw()


func toggle() -> void:
	set_enabled(not G.build_mode)


func _in_zone(cell: Vector2i) -> bool:
	var team := _my_team()
	if not GC.BUILD.has(team):
		return false
	var z: Dictionary = GC.BUILD[team]
	return cell.x >= z["min_col"] and cell.x <= z["max_col"] \
		and cell.y >= GC.BUILD["min_row"] and cell.y <= GC.BUILD["max_row"]


## Solo mira la zona y los bloques restantes (el servidor valida el resto).
func _ghost_ok(cell: Vector2i) -> bool:
	return _in_zone(cell) and int(MatchState.my_player("BlocksLeft", 0)) > 0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_mode") and not event.is_echo():
		if not G.menu_open:
			toggle()
		return
	if not G.build_mode or G.ui_open:
		return
	if event.is_action_pressed("fire"):
		if _hover_ok:
			Net.request("Place", [_hover.x, _hover.y])
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("alt_fire"):
		Net.request("RemoveBlock", [_hover.x, _hover.y])
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not G.build_mode:
		if visible:
			visible = false
		return
	if not _can_enable():
		set_enabled(false)
		return
	var mouse := get_global_mouse_position()
	G.mouse_world = mouse
	_hover = GC.world_to_cell(mouse)
	_hover_ok = _ghost_ok(_hover)
	queue_redraw()


func draw_zone(ci: CanvasItem) -> void:
	var team := _my_team()
	if not G.build_mode or not GC.BUILD.has(team):
		return
	var z: Dictionary = GC.BUILD[team]
	var x0: float = z["min_col"] * GC.BLOCK - GC.BLOCK * 0.5
	var x1: float = z["max_col"] * GC.BLOCK + GC.BLOCK * 0.5
	var h: float = GC.BUILD["max_row"] * GC.BLOCK
	ci.draw_rect(Rect2(x0, -h, x1 - x0, h), Color(GC.team_color(team), ZONE_ALPHA))


func _draw() -> void:
	if not G.build_mode:
		return
	var col := OK_COLOR if _hover_ok else BAD_COLOR
	var r := Rect2(_hover.x * GC.BLOCK - GC.BLOCK * 0.5, -_hover.y * GC.BLOCK, GC.BLOCK, GC.BLOCK)
	draw_rect(r, Color(col, GHOST_ALPHA))
	draw_rect(r, col, false, maxf(1.0, BOX_THICKNESS_STUDS * GC.STUD))
