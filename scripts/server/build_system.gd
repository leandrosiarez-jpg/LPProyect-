extends Node
## Sistema "Build": construcción de bases durante el interludio. Bloques de
## caramelo en la grilla, dentro de la zona de cada equipo. Son estructuras
## destructibles (G.map.damage_cell) y duran toda la partida.
##
## Reglas:
##   - solo en fase Prep, dentro de la zona del equipo (cols -50..-30 USA, 30..50 Vietnam; filas 1..7)
##   - celda libre (sin bloques ni personajes)
##   - con apoyo: fila 1, o sólido abajo / a la izquierda / a la derecha
##   - dos celdas libres arriba, sin dejar un túnel de una celda abajo y sin apilar más de 2 construidos
##   - no cortar el camino bases ↔ colina (NavGrid.would_cut_paths)
##   - 160 de vida; quitar un bloque del equipo lo devuelve al que lo quita

const RATE_LIMIT := 0.1

var _last_request := {}   # peer_id -> tiempo


func init_system() -> void:
	_last_request.clear()


func start_system() -> void:
	Net.register_handler("Place", _on_place)
	Net.register_handler("RemoveBlock", _on_remove)
	Net.peer_left.connect(_on_peer_left)


func _on_peer_left(peer_id: int) -> void:
	_last_request.erase(peer_id)


func _loadout() -> Node:
	return G.system("Loadout")


func _nav() -> Node:
	return G.system("Nav")


func _team_of(key: String) -> String:
	var lo := _loadout()
	if lo:
		var c: Dictionary = lo.get_combatant(key)
		if not c.is_empty():
			return str(c.get("team", ""))
	var mc := MatchState.get_combatant(key)
	return str(mc.get("Team", ""))


static func in_zone(team: String, cell: Vector2i) -> bool:
	if not GC.BUILD.has(team):
		return false
	var z: Dictionary = GC.BUILD[team]
	return cell.x >= z["min_col"] and cell.x <= z["max_col"] \
		and cell.y >= GC.BUILD["min_row"] and cell.y <= GC.BUILD["max_row"]


func _solid(c: int, r: int) -> bool:
	return G.map != null and G.map.is_solid(c, r)


func _built(c: int, r: int) -> bool:
	return G.map != null and G.map.is_built(c, r)


## Hay un personaje vivo ocupando (aunque sea en parte) la celda.
func _character_in(cell: Vector2i) -> bool:
	var center := GC.cell_center(cell.x, cell.y)
	var half := GC.BLOCK * 0.5 - 0.2 * GC.STUD
	var crect := Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0)
	for ch in G.all_characters():
		if ch.has_method("is_alive") and not ch.is_alive():
			continue
		var feet: Vector2 = ch.feet_position() if ch.has_method("feet_position") else ch.global_position
		var w: float = GC.CHARACTER["width"] * GC.STUD
		var h: float = GC.CHARACTER["height"] * GC.STUD
		if Rect2(feet.x - w * 0.5, feet.y - h, w, h).intersects(crect):
			return true
	return false


func _supported(cell: Vector2i) -> bool:
	if cell.y <= 1:
		return true
	return _solid(cell.x, cell.y - 1) or _solid(cell.x - 1, cell.y) or _solid(cell.x + 1, cell.y)


## "" si se puede, si no el motivo.
func _ceiling_error(cell: Vector2i) -> String:
	var c := cell.x
	var r := cell.y
	if _solid(c, r + 1) or _solid(c, r + 2):
		return "Dejá dos lugares libres arriba del bloque"
	if not _solid(c, r - 1) and _solid(c, r - 2):
		return "No dejes un túnel de una sola celda"
	if _built(c, r - 1) and _built(c, r - 2):
		return "No apiles más de dos bloques"
	return ""


## Valida todas las reglas sin gastar bloques. "" = se puede.
func can_place(key: String, cell: Vector2i) -> String:
	if MatchState.phase() != "Prep":
		return "Solo podés construir en el interludio"
	var team := _team_of(key)
	if team == "":
		return "No estás en ningún equipo"
	if not in_zone(team, cell):
		return "Fuera de tu zona de construcción"
	var lo := _loadout()
	if lo:
		var c: Dictionary = lo.get_combatant(key)
		if c.is_empty() or int(c["loadout"]["blocks_left"]) <= 0:
			return "No te quedan bloques"
	if G.map == null or _solid(cell.x, cell.y) or _character_in(cell):
		return "Ese lugar está ocupado"
	if not _supported(cell):
		return "El bloque necesita apoyo"
	var ce := _ceiling_error(cell)
	if ce != "":
		return ce
	var nav := _nav()
	if nav and nav.would_cut_paths(cell):
		return "Ese bloque cortaría el camino"
	return ""


## Coloca un bloque gastando uno del jugador. "" = colocado.
func place_block(key: String, cell: Vector2i) -> String:
	var err := can_place(key, cell)
	if err != "":
		return err
	var lo := _loadout()
	if lo and not lo.use_block(key):
		return "No te quedan bloques"
	if not G.map.place_built(cell, _team_of(key), key):
		if lo:
			lo.refund_block(key)
		return "Ese lugar está ocupado"
	return ""


## Quita un bloque construido del propio equipo y se lo devuelve a quien lo quita.
func remove_block(key: String, cell: Vector2i) -> String:
	if MatchState.phase() != "Prep":
		return "Solo podés quitar bloques en el interludio"
	if G.map == null or not G.map.is_built(cell.x, cell.y):
		return "Ahí no hay un bloque construido"
	var info: Dictionary = G.map.get_cell(cell.x, cell.y)
	if str(info.get("team", "")) != _team_of(key):
		return "Ese bloque no es de tu equipo"
	G.map.remove_built(cell)
	var lo := _loadout()
	if lo:
		lo.refund_block(key)
	return ""


func clear() -> void:
	if G.map:
		G.map.clear_built()


## Construcción automática de un bot: coberturas espaciadas
## de 1-2 bloques, nunca murallas. Devuelve cuántos bloques puso.
func bot_build(key: String) -> int:
	var team := _team_of(key)
	if not GC.BUILD.has(team):
		return 0
	var lo := _loadout()
	var left := 0
	if lo:
		var c: Dictionary = lo.get_combatant(key)
		if c.is_empty():
			return 0
		left = int(c["loadout"]["blocks_left"])
	var zone: Dictionary = GC.BUILD[team]
	var side: int = GC.TEAM_INFO[team]["side"]
	var budget := mini(left, randi_range(3, 5))
	var placed := 0
	var tries := 0
	while budget > 0 and tries < 30:
		tries += 1
		var t := pow(randf(), 0.7)
		var span: int = zone["max_col"] - zone["min_col"]
		var col: int
		if side == -1:
			col = int(floor(zone["min_col"] + span * t + 0.5))
		else:
			col = int(floor(zone["max_col"] - span * t + 0.5))
		var crowded := false
		for dc in [-2, -1, 1, 2]:
			if _built(col + dc, 1):
				crowded = true
		if crowded:
			continue
		if place_block(key, Vector2i(col, 1)) == "":
			budget -= 1
			placed += 1
			if budget > 0 and randf() < 0.5 and place_block(key, Vector2i(col, 2)) == "":
				budget -= 1
				placed += 1
	return placed


# --- handlers -------------------------------------------------------------

func _read_cell(args: Array) -> Variant:
	if args.size() != 2:
		return null
	for a in args:
		if typeof(a) != TYPE_INT and typeof(a) != TYPE_FLOAT:
			return null
	return Vector2i(int(floor(float(args[0]))), int(floor(float(args[1]))))


func _throttled(peer_id: int) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_request.get(peer_id, -10.0)) < RATE_LIMIT:
		return true
	_last_request[peer_id] = now
	return false


func _on_place(peer_id: int, args: Array) -> void:
	if MatchState.phase() != "Prep" or _throttled(peer_id):
		return
	var cell = _read_cell(args)
	if cell == null:
		return
	var key := Net.key_for_peer(peer_id)
	var lo := _loadout()
	var c: Dictionary = lo.get_combatant(key) if lo else {}
	if c.is_empty():
		return
	var err := place_block(key, cell)
	if err != "":
		lo.notice(c, err, "Error")


func _on_remove(peer_id: int, args: Array) -> void:
	if MatchState.phase() != "Prep" or _throttled(peer_id):
		return
	var cell = _read_cell(args)
	if cell == null:
		return
	var key := Net.key_for_peer(peer_id)
	var lo := _loadout()
	var c: Dictionary = lo.get_combatant(key) if lo else {}
	if c.is_empty():
		return
	var err := remove_block(key, cell)
	if err != "" and G.map and G.map.is_built(cell.x, cell.y):
		lo.notice(c, err, "Error")
