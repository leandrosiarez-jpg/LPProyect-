extends Node2D
## ProjectileRenderer (cliente): dibuja los proyectiles.
## Balas/perdigones/trazadoras = sprite "Bullet" (cuadro de 1,5 / 0,9 / 3,2 studs,
## la trazadora teñida 255,240,200); llamas = sprite "Flash" que crece de 1,2 a 4,8 studs,
## gira ±600°/s y se desvanece (t²·0,85); granadas = sprite "Donut" de 1,6 studs que rueda.
## Solo visual: el daño lo decide el servidor. Escucha Projectile, GrenadeThrown,
## Explosion y Structure. Además hace los efectos de disparo (humo de boca,
## casquillo o chispas, sonido del arma), que en Godot no los emite el rig.

const S := 8.0                        # px por stud
const BULLET_SIZE := {"Tracer": 3.2, "Pellet": 0.9, "Bullet": 1.5}
const TRACER_TINT := Color(1.0, 240.0 / 255.0, 200.0 / 255.0)
const DONUT_SIZE := 1.6
const DEPOT_COLOR := Color(163.0 / 255.0, 162.0 / 255.0, 165.0 / 255.0)   # Part por defecto
const DEPOT_HALF_HEIGHT := 2.1

var _active: Array = []     # {pos, dir, speed, remaining, kind, age, life, team, rot, spin, ignore}
var _grenades := {}         # id -> {pos, vel, age, team, rot}
var _flame_sound_t := {}    # shooter -> seg del último sonido de llama
var _drawn := false
var _tex_bullet: Texture2D
var _tex_flash: Texture2D
var _tex_donut: Texture2D


func _ready() -> void:
	z_index = 55
	z_as_relative = false
	_tex_bullet = Sprites.tex("Bullet")
	_tex_flash = Sprites.tex("Flash")
	_tex_donut = Sprites.tex("Donut")
	Net.event_received.connect(_on_event)
	G.session_ended.connect(clear)


func clear() -> void:
	_active.clear()
	_grenades.clear()
	queue_redraw()


func _fx(kind: String, pos: Vector2, params: Dictionary = {}) -> void:
	if G.fx and is_instance_valid(G.fx) and G.fx.has_method("spawn"):
		G.fx.spawn(kind, pos, params)


func _sound(sound_name: String, pos = null, vol_db := 0.0, pitch := 1.0) -> void:
	var snd = G.controller("Sound")
	if snd and snd.has_method("play"):
		snd.play(sound_name, pos, vol_db, pitch)


func _on_event(event: String, data) -> void:
	if not (data is Dictionary):
		return
	match event:
		"Projectile":
			_on_projectile(data)
		"GrenadeThrown":
			_on_grenade(data)
		"Explosion":
			var pos = data.get("position", null)
			if pos is Vector2:
				var r := float(data.get("radius_px", 12.0 * S))
				_fx("explosion", pos, {"radius_px": r})
				_sound("Explosion", pos, 0.0, 0.8 if r > 15.0 * S else 1.0)
		"Structure":
			_on_structure(data)


func _rig_of(shooter):
	if shooter and is_instance_valid(shooter) and "rig" in shooter and shooter.rig and is_instance_valid(shooter.rig):
		return shooter.rig
	return null


func _on_projectile(d: Dictionary) -> void:
	var origin = d.get("origin", null)
	var angles = d.get("angles", [])
	if not (origin is Vector2) or not (angles is Array):
		return
	var wid := str(d.get("weapon", "Rifle"))
	var w := Data.get_weapon(wid)
	var kind := str(w.get("projectile", "Bullet"))
	var team := str(d.get("team", ""))
	var shooter_key := str(d.get("shooter", ""))
	var shooter = G.get_character(shooter_key)
	var rig = _rig_of(shooter)
	# la boca del arma dibujada
	var muzzle: Vector2 = origin
	if rig and "muzzle_world" in rig and rig.muzzle_world is Vector2 and rig.muzzle_world != Vector2.ZERO:
		muzzle = rig.muzzle_world
	for a in angles:
		if not (a is float or a is int):
			continue
		spawn_projectile(kind, muzzle, float(a), float(w["projectile_speed"]) * S, float(w["range"]) * S, team)
	_on_fire_fx(shooter_key, shooter, rig, w, kind, muzzle, float(angles[0]) if angles.size() > 0 else 0.0)


## Efectos de disparo.
func _on_fire_fx(shooter_key: String, shooter, rig, w: Dictionary, kind: String, muzzle: Vector2, aim: float) -> void:
	if kind == "Flame":
		var now := Time.get_ticks_msec() / 1000.0
		if now - float(_flame_sound_t.get(shooter_key, 0.0)) > 0.12:
			_flame_sound_t[shooter_key] = now
			_sound("Flame", muzzle)
		return
	var bolt: bool = w.get("bolt_action", false)
	_fx("smoke", muzzle, {"count": 3 if bolt else 1, "scale": 0.6 if bolt else 0.35, "color": Color8(200, 200, 200)})
	var feet_y := muzzle.y + 2.0 * S
	if shooter and is_instance_valid(shooter) and shooter.has_method("feet_position"):
		feet_y = shooter.feet_position().y
	if bolt:
		_fx("sparks", muzzle, {"dir": GC.angle_to_dir(aim), "count": 5})
	else:
		_fx("shell", _shell_pos(rig, muzzle), {"facing": _facing(rig, aim), "floor": feet_y - 0.15 * S})
	_sound(str(w.get("sound", "Rifle")), muzzle)
	if bolt:
		# rig.BoltStart = now + 0.15; cerrojo atrás en t = 0,4 y adelante en t = 0,68
		var dur := float(w.get("bolt_time", 0.8))
		var key := shooter_key
		get_tree().create_timer(0.15 + 0.4 * dur).timeout.connect(func(): _bolt_back(key))
		get_tree().create_timer(0.15 + 0.68 * dur).timeout.connect(func(): _bolt_sound(key, "BoltForward"))


func _shell_pos(rig, fallback: Vector2) -> Vector2:
	if rig and "shell_world" in rig and rig.shell_world is Vector2 and rig.shell_world != Vector2.ZERO:
		return rig.shell_world
	return fallback


func _facing(rig, aim: float) -> float:
	if rig and "facing" in rig:
		return float(rig.facing)
	return 1.0 if cos(aim) >= 0.0 else -1.0


func _bolt_back(key: String) -> void:
	var ch = G.get_character(key)
	if ch == null or not is_instance_valid(ch) or not CombatUtil.is_alive(ch):
		return
	var rig = _rig_of(ch)
	var feet: Vector2 = ch.global_position
	var at := _shell_pos(rig, feet)
	_sound("BoltBack", ch.global_position)
	_fx("shell", at, {"facing": _facing(rig, 0.0), "floor": feet.y - 0.15 * S})
	_fx("smoke", at, {"count": 1, "scale": 0.3, "color": Color8(210, 210, 210)})


func _bolt_sound(key: String, sound_name: String) -> void:
	var ch = G.get_character(key)
	if ch and is_instance_valid(ch) and CombatUtil.is_alive(ch):
		_sound(sound_name, ch.global_position)


func spawn_projectile(kind: String, origin: Vector2, angle: float, speed_px: float, range_px: float, team: String) -> void:
	var dir := GC.angle_to_dir(angle)
	var p := {
		"pos": origin, "dir": dir, "speed": speed_px, "remaining": range_px,
		"kind": kind, "age": 0.0, "life": range_px / maxf(speed_px, 1.0), "team": team,
		"rot": dir.angle(), "spin": 0.0, "ignore": [],
	}
	if kind == "Flame":
		p["rot"] = deg_to_rad(randi_range(0, 359))
		p["spin"] = deg_to_rad((randf() * 2.0 - 1.0) * 600.0)
	_active.append(p)


func _on_grenade(d: Dictionary) -> void:
	var id = d.get("id", null)
	if id == null:
		return
	if d.get("remove", false):
		_grenades.erase(id)
		queue_redraw()
		return
	var pos = d.get("origin", null)
	var vel = d.get("velocity", null)
	if pos is Vector2 and vel is Vector2:
		_grenades[id] = {"pos": pos, "vel": vel, "age": 0.0, "team": str(d.get("team", "")), "rot": 0.0}


func _on_structure(d: Dictionary) -> void:
	if not d.get("destroyed", false):
		return
	var pos = d.get("position", null)
	if not (pos is Vector2):
		return
	var depot := str(d.get("kind", "")).to_lower() == "depot"
	var color: Color = d.get("color", DEPOT_COLOR) if d.get("color", null) is Color else DEPOT_COLOR
	var half_h := float(d.get("half_height_studs", DEPOT_HALF_HEIGHT))
	_fx("debris", pos, {"color": color, "count": 30 if depot else 14, "scale": 0.9, "floor": pos.y + half_h * S})
	_fx("smoke", pos, {"count": 5, "scale": 1.0, "color": color.lerp(Color.WHITE, 0.5)})
	_fx("sparks", pos, {"count": 6, "color": Color.WHITE})
	_sound("BlockBreak", pos)
	if G.fx and G.fx.has_method("shake"):
		G.fx.shake(0.25)


# --- simulación visual -------------------------------------------------------

## Personaje (no compañero, no filtrado) que intercepta el punto.
func _victim_at(point: Vector2, team: String, ignore: Array):
	for ch in G.all_characters():
		if not is_instance_valid(ch) or ch in ignore or CombatUtil.team_of(ch) == team:
			continue
		if ch.has_method("hit_test") and ch.hit_test(point, 0.5) != "":
			return ch
	return null


func _block_color(cell) -> Color:
	var m = G.map
	if m and cell is Vector2i:
		if "_static" in m and m._static.has(cell):
			return m._static[cell]["color"]
		if m.has_method("is_built") and m.is_built(cell.x, cell.y) and m.has_method("_built_color"):
			return m._built_color(cell)
	return Color8(86, 56, 40)   # GroundSlab


## impact(hit, kind, dir). victim = personaje alcanzado (o null si fue el mapa).
func _impact(pos: Vector2, kind: String, victim, cell, step: Vector2) -> void:
	if kind == "Flame":
		_fx("fire", pos, {"count": 2, "scale": 0.5})
		return
	if victim != null:
		return  # la goma la tira el evento Hit del servidor
	var normal := CombatUtil.hit_normal(pos, cell, step)
	var col := _block_color(cell)
	_fx("sparks", pos, {"dir": normal, "count": 3 if kind == "Pellet" else 6})
	_fx("debris", pos, {"color": col, "count": 6 if kind == "Tracer" else 2, "scale": 0.4, "floor": pos.y + 4.0 * S})
	_fx("smoke", pos, {"count": 1, "scale": 0.4, "color": col.lerp(Color.WHITE, 0.4)})


func _process(dt: float) -> void:
	if _active.is_empty() and _grenades.is_empty():
		if _drawn:
			_drawn = false
			queue_redraw()
		return
	_drawn = true
	var i := _active.size() - 1
	while i >= 0:
		var p: Dictionary = _active[i]
		p["age"] = p["age"] + dt
		var dist: float = minf(float(p["speed"]) * dt, float(p["remaining"]))
		var from: Vector2 = p["pos"]
		var dir: Vector2 = p["dir"]
		var to: Vector2 = from + dir * dist
		var dead := false
		var mh := CombatUtil.map_hit(from, to, p["team"])
		var free_dist := dist
		if mh.get("hit", false):
			free_dist = from.distance_to(mh.get("position", to))
		# raycast contra personajes (los muertos se agregan al filtro y se atraviesan)
		var steps := int(ceil(free_dist / 4.0))
		for s in range(1, steps + 1):
			var pt := from + dir * minf(s * 4.0, free_dist)
			var victim = _victim_at(pt, p["team"], p["ignore"])
			if victim != null:
				if not CombatUtil.is_alive(victim):
					p["ignore"].append(victim)
					continue
				_impact(pt, p["kind"], victim, null, dir * dist)
				dead = true
				break
		if not dead and mh.get("hit", false):
			_impact(mh.get("position", to), p["kind"], null, mh.get("cell", null), dir * dist)
			dead = true
		if not dead:
			p["pos"] = to
			p["remaining"] = float(p["remaining"]) - dist
			dead = float(p["remaining"]) <= 0.0
		if dead:
			_active.remove_at(i)
		elif p["kind"] == "Flame":
			p["rot"] = float(p["rot"]) + float(p["spin"]) * dt
			if randf() < 0.08:
				_fx("smoke", p["pos"], {"count": 1, "scale": 0.5, "color": Color8(80, 70, 70)})
		i -= 1

	# Granadas: misma física que el servidor (solo visual)
	var g: Dictionary = Data.GRENADE
	var grav: float = float(g["gravity"]) * S
	for id in _grenades.keys():
		var n: Dictionary = _grenades[id]
		var vel: Vector2 = n["vel"] + Vector2(0.0, grav * dt)
		var pos: Vector2 = n["pos"]
		var step := vel * dt
		var mh2 := CombatUtil.map_hit(pos, pos + step, n["team"])
		if mh2.get("hit", false):
			var hp2: Vector2 = mh2.get("position", pos + step)
			var normal := CombatUtil.hit_normal(hp2, mh2.get("cell", null), step)
			vel = (vel - 2.0 * vel.dot(normal) * normal) * float(g["bounce"])
			pos = hp2 + normal * 0.25 * S
			if vel.length() > 8.0 * S:
				_fx("dust", pos, {"count": 2, "dir": Vector2.ZERO})
		else:
			pos += step
		n["vel"] = vel
		n["pos"] = pos
		# Img.Rotation += Vel.X * dt * 40 (grados, Vel en studs/s)
		n["rot"] = float(n["rot"]) + deg_to_rad(vel.x / S * dt * 40.0)
		n["age"] = float(n["age"]) + dt
		if n["age"] > 4.0:
			_grenades.erase(id)
	queue_redraw()


## Imagen dentro de un cuadro de box_px x box_px (imagen de W/m x H/m dentro del
## cuadro), centrada y rotada.
func _draw_boxed(tex: Texture2D, pos: Vector2, box_px: float, rot: float, color: Color) -> void:
	if tex == null:
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var m := maxf(tw, th)
	var size := Vector2(tw / m, th / m) * box_px
	draw_set_transform(pos, rot, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-size * 0.5, size), false, color)


func _draw() -> void:
	for p in _active:
		var pos: Vector2 = p["pos"]
		var t: float = clampf(p["age"] / p["life"], 0.0, 1.0)
		var kind := str(p["kind"])
		if kind == "Flame":
			_draw_boxed(_tex_flash, pos, (1.2 + t * 3.6) * S, p["rot"], Color(1, 1, 1, 1.0 - t * t * 0.85))
		else:
			var col := TRACER_TINT if kind == "Tracer" else Color.WHITE
			_draw_boxed(_tex_bullet, pos, float(BULLET_SIZE.get(kind, 1.5)) * S, p["rot"], col)
	for id in _grenades:
		var n: Dictionary = _grenades[id]
		_draw_boxed(_tex_donut, n["pos"], DONUT_SIZE * S, n["rot"], Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
