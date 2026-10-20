extends Node2D
## Permite al jugador colocar y romper bloques (tiles) para construir torres.
## Click derecho = colocar bloque en la posición del mouse (mantener para seguir colocando)
## Tecla Q      = romper un bloque que el jugador haya colocado

signal blocks_changed(current: int, max_blocks: int)

@export var tilemap: TileMapLayer            ## Si queda vacío se busca en los padres
@export var player: CharacterBody2D          ## Si queda vacío se usa el padre
@export var tile_source_id: int = 0          ## Source del TileSet (0 = Suelo2.png)
@export var tile_atlas_coords: Vector2i = Vector2i(0, 0)
@export_range(1, 8) var block_size: int = 2  ## Lado del bloque en tiles (2 = 32x32 px, 3 = 48x48 px...)
@export var build_range: float = 160.0       ## Distancia máxima (en píxeles) desde el jugador
@export var max_blocks: int = 30             ## Bloques disponibles
@export var place_cooldown: float = 0.12     ## Tiempo entre bloques al mantener el click

var blocks_left: int
var placed_blocks: Dictionary = {}           ## origen del bloque (Vector2i) -> true
var hover_origin: Vector2i
var can_place_here: bool = false
var can_break_here: bool = false
var _cooldown: float = 0.0


func _ready() -> void:
	_ensure_input_actions()

	if player == null:
		player = get_parent() as CharacterBody2D
	if tilemap == null:
		tilemap = _find_tilemap()

	if player == null or tilemap == null:
		push_warning("BlockBuilder: no encontré el Player o el TileMapLayer.")
		set_physics_process(false)
		return

	blocks_left = max_blocks
	blocks_changed.emit(blocks_left, max_blocks)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)

	var mouse_cell := tilemap.local_to_map(tilemap.to_local(get_global_mouse_position()))
	hover_origin = _snap_to_block_grid(mouse_cell)
	can_place_here = _can_place(hover_origin)
	can_break_here = placed_blocks.has(hover_origin) and _in_range(hover_origin)
	queue_redraw()

	if Input.is_action_pressed("PlaceBlock") and can_place_here and _cooldown <= 0.0:
		_place_block(hover_origin)

	if Input.is_action_just_pressed("BreakBlock") and can_break_here:
		_break_block(hover_origin)


func _place_block(origin: Vector2i) -> void:
	for cell in _block_cells(origin):
		tilemap.set_cell(cell, tile_source_id, tile_atlas_coords)
	placed_blocks[origin] = true
	blocks_left -= 1
	_cooldown = place_cooldown
	blocks_changed.emit(blocks_left, max_blocks)


func _break_block(origin: Vector2i) -> void:
	for cell in _block_cells(origin):
		tilemap.erase_cell(cell)
	placed_blocks.erase(origin)
	blocks_left += 1
	blocks_changed.emit(blocks_left, max_blocks)


# ---------- Validaciones ----------

func _can_place(origin: Vector2i) -> bool:
	if blocks_left <= 0:
		return false
	for cell in _block_cells(origin):             # todas las celdas deben estar libres
		if tilemap.get_cell_source_id(cell) != -1:
			return false
	if not _in_range(origin):
		return false
	if _overlaps_player(_block_center_global(origin)):
		return false
	return true


func _in_range(origin: Vector2i) -> bool:
	return _block_center_global(origin).distance_to(player.global_position) <= build_range


func _overlaps_player(center: Vector2) -> bool:
	# Evita colocar un bloque dentro del jugador (lo dejaría trabado)
	var shape := RectangleShape2D.new()
	shape.size = _block_pixel_size() - Vector2(2, 2)

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, center)
	params.collision_mask = player.collision_layer
	params.collide_with_bodies = true

	var hits := get_world_2d().direct_space_state.intersect_shape(params, 8)
	for hit in hits:
		if hit.collider == player:
			return true
	return false


# ---------- Utilidades ----------

func _snap_to_block_grid(cell: Vector2i) -> Vector2i:
	# Alinea a una grilla de block_size x block_size para que los bloques encajen al apilarse
	return Vector2i(floori(float(cell.x) / block_size), floori(float(cell.y) / block_size)) * block_size


func _block_cells(origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in block_size:
		for y in block_size:
			cells.append(origin + Vector2i(x, y))
	return cells


func _block_pixel_size() -> Vector2:
	return Vector2(tilemap.tile_set.tile_size) * block_size


func _block_center_global(origin: Vector2i) -> Vector2:
	var tile := Vector2(tilemap.tile_set.tile_size)
	var local_center := tilemap.map_to_local(origin) + tile * (block_size - 1) / 2.0
	return tilemap.to_global(local_center)


func _find_tilemap() -> TileMapLayer:
	var n := get_parent()
	while n != null:
		if n is TileMapLayer:
			return n
		n = n.get_parent()
	return null


func _ensure_input_actions() -> void:
	# Crea las acciones por código si no las definiste en Proyecto > Ajustes > Mapa de entrada
	if not InputMap.has_action("PlaceBlock"):
		InputMap.add_action("PlaceBlock")
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("PlaceBlock", mouse_event)

	if not InputMap.has_action("BreakBlock"):
		InputMap.add_action("BreakBlock")
		var key_event := InputEventKey.new()
		key_event.keycode = KEY_Q
		InputMap.action_add_event("BreakBlock", key_event)


# ---------- Vista previa ----------

func _draw() -> void:
	if tilemap == null or player == null:
		return

	var size := _block_pixel_size()
	var rect := Rect2(to_local(_block_center_global(hover_origin)) - size / 2.0, size)

	var color := Color(1.0, 0.2, 0.2, 0.35)            # rojo: no se puede
	if can_place_here:
		color = Color(0.2, 1.0, 0.3, 0.4)              # verde: se puede colocar
	elif can_break_here:
		color = Color(1.0, 0.7, 0.1, 0.4)              # naranja: se puede romper

	draw_rect(rect, color)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.9), false, 1.0)
