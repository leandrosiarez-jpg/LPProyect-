extends CharacterBody2D

const SPEED: float = 500.0


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	# Color distinto por jugador para poder diferenciar los iconos.
	# Se calcula igual en todas las maquinas a partir del ID (nombre
	# del nodo), asi que no hace falta replicarlo por red.
	var icon := get_node_or_null("Icon") as Sprite2D
	if icon != null:
		icon.modulate = Color.from_hsv(fmod(name.to_int() * 0.618033, 1.0), 0.65, 1.0)


func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return

	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED

	move_and_slide()
