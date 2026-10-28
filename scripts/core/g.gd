extends Node
## Registro global de referencias a nodos de la partida (lo llena main.gd).

signal session_started
signal session_ended

var main: Node
var world: Node2D
var map: Node2D            # scripts/game/map_grid.gd
var characters: Node2D     # hijos = personajes, nombre del nodo = clave del combatiente
var projectiles: Node2D
var objectives: Node2D
var fx: Node2D             # FXController
var camera: Camera2D
var ui: CanvasLayer
var systems := {}          # solo en el servidor: "Match", "Loadout", "Character", ...
var client := {}           # controladores del cliente: "Input", "Build", "Sound", ...

## Estado local del cliente
var aim_angle := 0.0
var mouse_world := Vector2.ZERO
var menu_open := true
var ui_open := false       # tienda/pausa abiertas: no disparar
var build_mode := false
var cinematic := false
var settings := {"music": 0.6, "sfx": 0.8, "shake": 1.0}


func system(name: String) -> Node:
	return systems.get(name)


func controller(name: String) -> Node:
	return client.get(name)


func local_character() -> Node:
	if characters == null:
		return null
	return characters.get_node_or_null(Net.my_key())


func get_character(key: String) -> Node:
	if characters == null:
		return null
	return characters.get_node_or_null(key)


func all_characters() -> Array:
	return characters.get_children() if characters else []
