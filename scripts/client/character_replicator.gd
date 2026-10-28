extends Node
## CharacterReplicator (cliente): crea, actualiza e interpola los títeres de los
## personajes a partir de CharSpawn / CharRemove / CharAttrs / CharSnap.
## En el anfitrión y en modo solo los nodos ya existen (los crea CharacterSystem),
## así que solo se encarga de los efectos visuales del rig (disparo, impacto).
## También refleja las barreras del interludio en los clientes (fase Prep).

const SNAP_RATE := 18.0


func _ready() -> void:
	Net.event_received.connect(_on_event)
	MatchState.var_changed.connect(_on_var_changed)
	G.session_ended.connect(_on_session_ended)


func _is_client() -> bool:
	return Net.mode == Net.Mode.CLIENT


func _on_session_ended() -> void:
	if G.world and G.world.get_node_or_null("PrepBarriers"):
		G.world.get_node("PrepBarriers").queue_free()


func _on_var_changed(key: String, value) -> void:
	if key == "Phase" and _is_client():
		Gummy.ensure_barriers(value == "Prep")


func _on_event(event: String, data) -> void:
	match event:
		"Projectile":
			_on_projectile(data)
		"Hit":
			_on_hit(data)
	if not _is_client() or not (data is Dictionary):
		return
	match event:
		"CharSpawn":
			_on_spawn(data)
		"CharRemove":
			var ch := G.get_character(str(data.get("key", "")))
			if ch:
				G.characters.remove_child(ch)
				ch.queue_free()
		"CharAttrs":
			_on_attrs(data)
		"CharSnap":
			_on_snap(data)


func _on_spawn(data: Dictionary) -> void:
	if G.characters == null:
		return
	var key: String = str(data.get("key", ""))
	if key == "":
		return
	var ch := G.get_character(key) as Gummy
	if ch == null or ch.is_queued_for_deletion():
		ch = Gummy.new()
		ch.name = key
		G.characters.add_child(ch)
	ch.controlled_locally = key == Net.my_key()
	ch.move_input = 0.0
	ch.jump_input = false
	ch.attrs = {}
	var attrs: Dictionary = data.get("attrs", {})
	ch.apply_attrs(attrs)
	ch.spawn_seq = int(data.get("seq", 0))
	var pos: Vector2 = data.get("pos", Vector2.ZERO)
	ch.teleport(pos)
	if not ch.controlled_locally:
		ch.apply_remote_state(pos, Vector2.ZERO, true, Net.server_time(), SNAP_RATE)


func _on_attrs(data: Dictionary) -> void:
	var chars: Dictionary = data.get("chars", {})
	for key in chars:
		var ch := G.get_character(str(key)) as Gummy
		if ch == null:
			continue
		var d: Dictionary = chars[key]
		if ch.controlled_locally and d.has("Aim"):
			d = d.duplicate()
			d.erase("Aim")
		ch.apply_attrs(d)
	var tp: Dictionary = data.get("teleport", {})
	for key in tp:
		var ch := G.get_character(str(key)) as Gummy
		var entry: Array = tp[key]
		if ch and entry.size() >= 2 and int(entry[1]) == ch.spawn_seq:
			ch.global_position = entry[0]
			ch.velocity = Vector2.ZERO


func _on_snap(data: Dictionary) -> void:
	var t: float = float(data.get("t", Net.server_time()))
	var list: Dictionary = data.get("c", {})
	for key in list:
		var ch := G.get_character(str(key)) as Gummy
		if ch == null or ch.controlled_locally:
			continue
		var e: Array = list[key]
		if e.size() < 4:
			continue
		var flags: int = int(e[3])
		if ((flags >> 8) & 0xFF) != (ch.spawn_seq & 0xFF):
			continue
		ch.attrs["Aim"] = float(e[2])
		ch.apply_remote_state(e[0], e[1], (flags & 1) == 1, t, SNAP_RATE)


# --- efectos del rig (todos los pares) -----------------------------------------

func _on_projectile(data) -> void:
	if not (data is Dictionary):
		return
	var ch := G.get_character(str(data.get("shooter", "")))
	if ch == null or ch.rig == null:
		return
	var weapon := Data.get_weapon(str(data.get("weapon", ch.get_attr("Weapon", "Rifle"))))
	ch.rig.on_fire(str(weapon.get("projectile", "Bullet")))


func _on_hit(data) -> void:
	if not (data is Dictionary):
		return
	var ch := G.get_character(str(data.get("victim", "")))
	if ch == null or ch.rig == null:
		return
	var attacker := G.get_character(str(data.get("attacker", "")))
	var ax := NAN
	if attacker:
		ax = attacker.global_position.x
	elif data.get("position") is Vector2:
		ax = (data["position"] as Vector2).x
	ch.rig.on_hit(data.get("headshot", false) == true, ax)
