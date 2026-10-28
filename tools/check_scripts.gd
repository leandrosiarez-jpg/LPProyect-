extends RefCounted
## Compila todos los .gd de res://scripts y res://data y reporta errores.
## Se invoca desde main.gd con: godot --headless --path . -- --check

static func run() -> int:
	var errors := [0]
	for dir in ["res://scripts", "res://data"]:
		_scan(dir, errors)
	print("CHECK DONE: %d script(s) con error" % errors[0])
	return errors[0]


static func _scan(path: String, errors: Array) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd"):
			var full := path.path_join(f)
			var s: GDScript = ResourceLoader.load(full, "GDScript")
			if s == null or not s.can_instantiate():
				errors[0] += 1
				print("ERROR en ", full)
	for sub in d.get_directories():
		_scan(path.path_join(sub), errors)
