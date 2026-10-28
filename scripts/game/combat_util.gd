class_name CombatUtil
extends RefCounted
## Utilidades de combate compartidas cliente/servidor.
## Todo en píxeles salvo que diga lo contrario; los ángulos usan 0 = derecha y positivo = arriba
## (0 = derecha, positivo = arriba).


## Ángulos de cada perdigón con la dispersión del arma (en grados).
## extra_spread: retroceso acumulado del cliente (ClientState.Spread), opcional.
static func spread_angles(weapon_id: String, aim: float, moving: bool, extra_spread: float = 0.0) -> Array:
	var w: Dictionary = Data.get_weapon(weapon_id)
	var spread: float = float(w.get("spread", 0.0)) + (float(w.get("move_spread", 0.0)) if moving else 0.0) + extra_spread * 0.5
	var out: Array = []
	for i in int(w.get("pellets", 1)):
		out.append(aim + deg_to_rad(randf_range(-1.0, 1.0) * spread))
	return out


## Se considera en movimiento si |vx| > 2 o |vy| > 4 studs/s.
static func is_moving(velocity_px: Vector2) -> bool:
	return absf(velocity_px.x) > 2.0 * GC.STUD or absf(velocity_px.y) > 4.0 * GC.STUD


## Recoil que suma el cliente al disparar (ClientState.Spread), con tope 8.
static func add_recoil(current: float, weapon_id: String) -> float:
	return minf(current + float(Data.get_weapon(weapon_id).get("recoil", 0.0)) * 0.6, 8.0)


static func is_alive(ch) -> bool:
	if ch == null or not is_instance_valid(ch) or not ch.is_inside_tree():
		return false
	if ch.has_method("is_alive"):
		return ch.is_alive()
	return not bool(ch.get_attr("Dead", false))


static func get_characters() -> Array:
	return G.all_characters()


static func team_of(ch) -> String:
	if ch == null or not is_instance_valid(ch):
		return ""
	if ch.has_method("team"):
		return ch.team()
	return str(ch.get_attr("Team", ""))


static func key_of(ch) -> String:
	if ch == null or not is_instance_valid(ch):
		return ""
	if ch.has_method("key"):
		return ch.key()
	return str(ch.name)


static func display_name(ch) -> String:
	if ch == null or not is_instance_valid(ch):
		return ""
	var n = ch.get_attr("DisplayName", "")
	if n is String and n != "":
		return n
	var c: Dictionary = MatchState.get_combatant(key_of(ch))
	return str(c.get("Name", ch.name))


## Hombro del personaje en px (con respaldo si el personaje no implementa el método).
static func shoulder(ch) -> Vector2:
	if ch.has_method("shoulder_position"):
		return ch.shoulder_position()
	return ch.global_position


static func muzzle(ch, angle: float) -> Vector2:
	if ch.has_method("muzzle_position"):
		return ch.muzzle_position(angle)
	return shoulder(ch) + GC.angle_to_dir(angle) * GC.CHARACTER["muzzle_distance"] * GC.STUD


## Normal aproximada de un choque contra la celda `cell` (o según el paso si no hay celda).
static func hit_normal(hit_pos: Vector2, cell, step: Vector2) -> Vector2:
	if cell is Vector2i:
		var c: Vector2 = GC.cell_center(cell.x, cell.y)
		var d := (hit_pos - c) / (GC.BLOCK * 0.5)
		if absf(d.x) > absf(d.y):
			return Vector2(signf(d.x) if d.x != 0.0 else -signf(step.x), 0.0)
		return Vector2(0.0, signf(d.y) if d.y != 0.0 else -signf(step.y))
	if absf(step.x) > absf(step.y):
		return Vector2(-signf(step.x), 0.0)
	return Vector2(0.0, -signf(step.y) if step.y != 0.0 else -1.0)


## Choque del segmento con el mapa. Devuelve {hit, position, cell} (hit=false si no hay mapa).
static func map_hit(from: Vector2, to: Vector2, ignore_team: String) -> Dictionary:
	if G.map and G.map.has_method("segment_hit"):
		var r = G.map.segment_hit(from, to, ignore_team)
		if r is Dictionary:
			return r
	# respaldo: la losa continua bajo la fila -1 y el suelo plano en y = 0 si no hay mapa
	if to.y > 0.0 and from.y <= 0.0:
		var t := (0.0 - from.y) / maxf(to.y - from.y, 0.0001)
		return {"hit": true, "position": from.lerp(to, t), "cell": null}
	return {"hit": false}
