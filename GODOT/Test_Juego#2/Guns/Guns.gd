extends Node2D

const Bullet = preload("res://Scene/bullet.tscn")

signal ammo_changed(current: int, max_ammo: int)
signal reload_started
signal reload_finished

var max_ammo: int = 6
var reload_time: float = 1.5
var cooldown_time: float = 0.5 

var can_shoot: bool = true
var current_ammo = 6
var is_reloading: bool = false

func _ready() -> void:
	current_ammo = max_ammo
	ammo_changed.emit(current_ammo, max_ammo)


func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1


	if Input.is_action_just_pressed("Shoot") and can_shoot and not is_reloading:
		if current_ammo > 0:
			shoot()
		else:
			pass

	if Input.is_action_just_pressed("Reload") and not is_reloading and current_ammo < max_ammo:
		reload()


func shoot() -> void:
	var bullet_instance = Bullet.instantiate()
	get_tree().root.add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.rotation = rotation
	
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)
	
	can_shoot = false
	await get_tree().create_timer(cooldown_time).timeout
	can_shoot = true  

func reload() -> void:
	is_reloading = true
	reload_started.emit()
	
	await get_tree().create_timer(reload_time).timeout
	
	current_ammo = max_ammo
	is_reloading = false
	ammo_changed.emit(current_ammo, max_ammo)
	reload_finished.emit()
