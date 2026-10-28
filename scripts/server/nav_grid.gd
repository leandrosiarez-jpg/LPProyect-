class_name NavGrid
extends Node
## Sistema "Nav": grilla de navegación con las mismas reglas de salto que los bots
## La usan BuildSystem (para que
## un bloque nuevo no corte el camino entre bases y la colina) y BotSystem (BFS).
##
## Internamente un "nodo" es un PISO: celda sólida (r) con dos celdas libres
## arriba (r+1, r+2). Hacia afuera se habla en CELDAS DE PIE: (c, r+1), es decir
## la celda vacía donde está el personaje con la de abajo sólida.
##
## Reglas de movimiento desde un piso (c, r) hacia la columna c1 = c ± 1:
##   - Caminar / caer: si (c1, r+1) y (c1, r+2) están libres, el bot cae por c1
##     hasta el primer sólido (sin límite de caída; DROP_MAX).
##   - Subir: a un piso de c1 con fila r+1 .. r+JUMP_UP si (c, r+3) está libre
##     (cabeza al saltar) y el destino tiene 2 celdas libres arriba.
## Salto de hueco a c2 = c ± 2 (GAP_COLS = 1 columna de hueco):
##   - si (c1, r), (c1, r+1) y (c1, r+2) están libres, puede caer en un piso de c2
##     con fila entre r - GAP_DROP_MAX y r + JUMP_UP, con (c, r+3) libre y, si sube
##     2, también (c1, r+3).
## Salto del personaje: JumpPower 66 studs/s, gravedad 196.2 -> 11,1 studs ≈ 2,8
## bloques; por eso JUMP_UP = 2.

const MIN_COL := -64
const MAX_COL := 64
const MIN_ROW := -1
const MAX_ROW := 20

const JUMP_UP := 2        # filas que se pueden subir a la columna vecina
const GAP_COLS := 1       # ancho de hueco que se salta
const GAP_DROP_MAX := 3   # filas que se puede bajar al saltar un hueco
const DROP_MAX := 99      # caída desde un borde: sin límite
const HEADROOM := 2       # celdas libres que necesita un personaje parado

## Puntos que no se pueden desconectar (pisos): bases y colina.
const BASE_USA := Vector2i(-58, 0)
const BASE_VN := Vector2i(58, 0)
const HILL := Vector2i(0, 3)

var _nodes := {}          # col -> Array[int] filas de piso
var _cached_rev := -1
var _extra := {}          # celdas sólidas hipotéticas
var _adj := {}            # caché de vecinos por piso (se vacía al cambiar el mapa)


func init_system() -> void:
	pass


func start_system() -> void:
	pass


func _map() -> Node:
	return G.map


func _solid(c: int, r: int) -> bool:
	if _extra.has(Vector2i(c, r)):
		return true
	var m := _map()
	return m != null and m.is_solid(c, r)


func _free(c: int, r: int) -> bool:
	return not _solid(c, r)


func _build_nodes() -> Dictionary:
	var nodes := {}
	for c in range(MIN_COL, MAX_COL + 1):
		var list: Array[int] = []
		for r in range(MIN_ROW, MAX_ROW + 1):
			if _solid(c, r) and _free(c, r + 1) and _free(c, r + 2):
				list.append(r)
		nodes[c] = list
	return nodes


func _get_nodes() -> Dictionary:
	if not _extra.is_empty():
		return _build_nodes()
	var m := _map()
	var rev: int = m.revision if m != null and "revision" in m else -2
	if rev != _cached_rev or rev == -2:
		_nodes = _build_nodes()
		_adj = {}
		_cached_rev = rev
	return _nodes


func _nearest_row(nodes: Dictionary, c: int, r: int) -> int:
	var best := -9999
	var best_d := 1 << 30
	for row in nodes.get(c, []):
		var d := absi(int(row) - r)
		if d < best_d:
			best = row
			best_d = d
	return best


## Vecinos de un piso (c, r) según las reglas de salto.
func _neighbors(nodes: Dictionary, c: int, r: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dir in [-1, 1]:
		var c1: int = c + dir
		if c1 < MIN_COL or c1 > MAX_COL:
			continue
		var c1_rows: Array = nodes.get(c1, [])
		# caminar o caer por c1
		if _free(c1, r + 1) and _free(c1, r + 2):
			var k := r
			while k >= MIN_ROW and r - k <= DROP_MAX and _free(c1, k):
				k -= 1
			if k >= MIN_ROW and c1_rows.has(k):
				out.append(Vector2i(c1, k))
		# subir
		if _free(c, r + 3):
			for r2 in c1_rows:
				if r2 > r and r2 <= r + JUMP_UP and _free(c1, r2 + 1) and _free(c1, r2 + 2):
					out.append(Vector2i(c1, r2))
		# saltar un hueco de una columna
		var c2: int = c + dir * (GAP_COLS + 1)
		if c2 < MIN_COL or c2 > MAX_COL:
			continue
		if _free(c1, r) and _free(c1, r + 1) and _free(c1, r + 2):
			for r2 in nodes.get(c2, []):
				if r2 > r + JUMP_UP or r2 < r - GAP_DROP_MAX:
					continue
				var headroom: bool = _free(c, r + 3) and (r2 <= r + 1 or _free(c1, r + 3))
				if not headroom:
					continue
				# si cae, la columna de destino tiene que estar libre hasta el piso
				var clear := true
				for k in range(r2 + 1, maxi(r, r2) + 3):
					if _solid(c2, k):
						clear = false
						break
				if clear:
					out.append(Vector2i(c2, r2))
	return out


## BFS sobre pisos. Devuelve {seen: {Vector2i: padre}, start}
func _bfs(nodes: Dictionary, start: Vector2i, goal: Vector2i = Vector2i(9999, 9999), memo = null) -> Dictionary:
	var parent := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var n: Vector2i = queue[head]
		head += 1
		if n == goal:
			break
		var nbs: Array[Vector2i]
		if memo is Dictionary:
			if not memo.has(n):
				memo[n] = _neighbors(nodes, n.x, n.y)
			nbs = memo[n]
		else:
			nbs = _neighbors(nodes, n.x, n.y)
		for nb in nbs:
			if not parent.has(nb):
				parent[nb] = n
				queue.append(nb)
	return parent


func _reachable(nodes: Dictionary, from_floor: Vector2i, targets: Array) -> bool:
	var r := _nearest_row(nodes, from_floor.x, from_floor.y)
	if r == -9999:
		return false
	var seen := _bfs(nodes, Vector2i(from_floor.x, r))
	for t in targets:
		var tr := _nearest_row(nodes, t.x, t.y)
		if tr == -9999 or not seen.has(Vector2i(t.x, tr)):
			return false
	return true


# --- API pública ----------------------------------------------------------

## Celda de pie: vacía, con 2 celdas libres (ella y la de arriba) y sólida abajo.
func standable(cell: Vector2i) -> bool:
	return _solid(cell.x, cell.y - 1) and _free(cell.x, cell.y) and _free(cell.x, cell.y + 1)


## Celda de pie más cercana a una posición en px (busca hacia abajo y luego arriba).
func cell_at(pos_px: Vector2) -> Vector2i:
	var c := GC.world_to_cell(pos_px + Vector2(0, -GC.BLOCK * 0.25))
	for d in range(0, 6):
		if standable(Vector2i(c.x, c.y - d)):
			return Vector2i(c.x, c.y - d)
		if d > 0 and standable(Vector2i(c.x, c.y + d)):
			return Vector2i(c.x, c.y + d)
	return c


## Camino de celdas de pie desde from_cell hasta to_cell (ambas incluidas).
## Se ajustan al piso más cercano de su columna. Si no hay camino devuelve []
## (o, con allow_partial, el camino al nodo alcanzado más cercano al destino).
func find_path(from_cell: Vector2i, to_cell: Vector2i, allow_partial: bool = false) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var nodes := _get_nodes()
	var fc := clampi(from_cell.x, MIN_COL, MAX_COL)
	var tc := clampi(to_cell.x, MIN_COL, MAX_COL)
	var fr := _nearest_row(nodes, fc, from_cell.y - 1)
	var tr := _nearest_row(nodes, tc, to_cell.y - 1)
	if fr == -9999:
		return result
	var start := Vector2i(fc, fr)
	var goal := Vector2i(tc, tr) if tr != -9999 else Vector2i(9999, 9999)
	var parent := _bfs(nodes, start, goal, _adj)
	var end := goal
	if not parent.has(goal):
		if not allow_partial:
			return result
		var best_d := INF
		for n in parent:
			var d := absf(n.x - to_cell.x) * 4.0 + absf(n.y + 1 - to_cell.y)
			if d < best_d:
				best_d = d
				end = n
	var n: Vector2i = end
	while true:
		result.push_front(Vector2i(n.x, n.y + 1))
		if n == start:
			break
		n = parent[n]
	return result


## true si agregar un sólido en cell desconecta bases ↔ colina central.
func would_cut_paths(cell: Vector2i) -> bool:
	_extra = {cell: true}
	var nodes := _build_nodes()
	var ok := _reachable(nodes, BASE_USA, [BASE_VN, HILL]) and _reachable(nodes, BASE_VN, [BASE_USA, HILL])
	_extra = {}
	return not ok


## true si hoy (sin bloques extra) las bases y la colina están conectadas.
func paths_open() -> bool:
	var nodes := _get_nodes()
	return _reachable(nodes, BASE_USA, [BASE_VN, HILL]) and _reachable(nodes, BASE_VN, [BASE_USA, HILL])
