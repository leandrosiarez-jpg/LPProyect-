extends Node2D

const SPEED: int = 300
const LIFETIME: float = 2.0

func _ready() -> void:
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta
