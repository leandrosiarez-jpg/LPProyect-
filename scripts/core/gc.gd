extends Node
## GameConstants: equipos, reglas de partida, grilla y conversiones.
## Los datos de balance están en "studs" (unidad de diseño). En Godot el mundo
## se mide en píxeles: 1 stud = STUD px y el eje Y va hacia abajo.

const STUD := 8.0
const BLOCK_STUDS := 4.0
const BLOCK := BLOCK_STUDS * STUD   # 32 px por celda
const GRAVITY_STUDS := 196.2        # gravedad base

const PORT := 42069
const MAX_PEERS := 7

const TEAMS := ["USA", "Vietnam"]

const TEAM_INFO := {
	"USA": {
		"display": "USA",
		"long": "Ejército de los Estados Unidos",
		"color": Color8(85, 155, 255),
		"dark": Color8(18, 34, 70),
		"side": -1,
		"commander": "CNEL. HANK McGUMMY",
		"block": "sprinkle",
	},
	"Vietnam": {
		"display": "VIETNAM",
		"long": "Ejército de Vietnam",
		"color": Color8(245, 75, 60),
		"dark": Color8(70, 18, 16),
		"side": 1,
		"commander": "GRAL. LAM VAN GOM",
		"block": "pink",
	},
}

const MATCH := {
	"rounds": 3,
	"round_duration": 300.0,
	"prep_duration": 60.0,
	"round_end_duration": 9.0,
	"match_end_duration": 58.0,
	"team_size": 4,
	"fill_with_bots": true,
	"respawn_time": 4.0,
	"prep_respawn_time": 1.0,
	"spawn_protection": 2.0,
	"start_money": 500,
	"kill_reward": 100,
	"headshot_bonus": 50,
	"objective_reward": 150,
	"round_win_reward": 600,
	"round_loss_reward": 300,
	"blocks_per_prep": 12,
}

const BUILD := {
	"USA": {"min_col": -50, "max_col": -30},
	"Vietnam": {"min_col": 30, "max_col": 50},
	"min_row": 1,
	"max_row": 7,
	"block_health": 160.0,
}

## Medidas del personaje en studs, desde los pies.
const CHARACTER := {
	"feet_offset": 3.2,       # centro del cuerpo sobre los pies
	"shoulder_height": 2.04,
	"muzzle_distance": 3.1,
	"headshot_height": 3.55,
	"height": 5.0,
	"width": 2.0,
}

const CAMERA := {
	"visible_height_studs": 38.6,  # alto visible de la cámara
	"height_offset": 2.0,
	"look_ahead": 0.14,
	"max_look_ahead": 9.0,
}

const MISSIONS := ["Assassination", "KingOfHill", "Radio", "CTF", "Demolition"]

## Capas de colisión (bits 1..n)
const LAYER_WORLD := 1
const LAYER_BUILT_USA := 2
const LAYER_BUILT_VN := 4
const LAYER_CHAR_USA := 8
const LAYER_CHAR_VN := 16
const LAYER_BARRIER := 32
const LAYER_STRUCTURE := 64


func enemy(team: String) -> String:
	return "Vietnam" if team == "USA" else "USA"


func team_color(team: String) -> Color:
	return TEAM_INFO[team]["color"] if TEAM_INFO.has(team) else Color.WHITE


func built_layer(team: String) -> int:
	return LAYER_BUILT_USA if team == "USA" else LAYER_BUILT_VN


func char_layer(team: String) -> int:
	return LAYER_CHAR_USA if team == "USA" else LAYER_CHAR_VN


## Convierte una posición en studs (X, Y arriba) a píxeles de Godot.
func studs_to_px(v: Vector2) -> Vector2:
	return Vector2(v.x * STUD, -v.y * STUD)


func px_to_studs(p: Vector2) -> Vector2:
	return Vector2(p.x / STUD, -p.y / STUD)


## Centro de la celda (col, row). La fila 0 es la superficie: su borde superior está en y = 0.
func cell_center(col: int, row: int) -> Vector2:
	return Vector2(col * BLOCK, -(row * BLOCK_STUDS - BLOCK_STUDS * 0.5) * STUD)


func world_to_cell(p: Vector2) -> Vector2i:
	var col := int(round(p.x / BLOCK))
	var row := int(ceil(-p.y / BLOCK))
	return Vector2i(col, row)


## Dirección de un ángulo de apuntado. Los ángulos se guardan
## (0 = derecha, positivo = hacia arriba), así que Y se invierte.
func angle_to_dir(angle: float) -> Vector2:
	return Vector2(cos(angle), -sin(angle))


func dir_to_angle(d: Vector2) -> float:
	return atan2(-d.y, d.x)


func _ready() -> void:
	_setup_input()


func _add_key(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _add_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _setup_input() -> void:
	_add_key("move_left", [KEY_A, KEY_LEFT])
	_add_key("move_right", [KEY_D, KEY_RIGHT])
	_add_key("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_key("reload", [KEY_R])
	_add_key("grenade", [KEY_G])
	_add_key("build_mode", [KEY_B])
	_add_key("shop", [KEY_T])
	_add_key("ready", [KEY_F])
	_add_key("scoreboard", [KEY_TAB])
	_add_key("pause_menu", [KEY_M, KEY_ESCAPE])
	_add_mouse("fire", MOUSE_BUTTON_LEFT)
	_add_mouse("alt_fire", MOUSE_BUTTON_RIGHT)
