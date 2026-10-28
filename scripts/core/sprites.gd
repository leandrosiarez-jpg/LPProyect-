extends Node
## Sprites 2D del juego (exportados de GummyWars.aseprite) y datos de armado de rigs.
## Posiciones en "unidades de rig" (1 unidad = 1 px del torso), mirando a la
## DERECHA, origen en los pies, Y hacia ARRIBA.
## No se generan texturas nuevas: todo sale de res://assets/sprites.

const DIR := "res://assets/sprites/"

## 1 unidad de rig en studs
const UNIT_STUDS := 0.12

## Tamaño nativo de cada imagen (W, H) y recorte horizontal (RectX)
const IMAGES := {
	"SoldierTorso": [21, 29], "SoldierWalk": [28, 29], "SoldierHead": [30, 26],
	"SoldierHelmet": [32, 17], "HelmetVN": [32, 17], "PyroTorso": [21, 29], "PyroHead": [31, 31],
	"HandOpen": [11, 11], "HandGrip": [11, 11],
	"Rifle": [49, 16], "RifleShort": [36, 16], "Flamer": [52, 11], "Bullet": [9, 3], "Flash": [10, 12],
	"Donut": [32, 32], "DonutPink": [32, 32],
	"FlagUSA": [24, 16], "FlagVN": [24, 16], "Radio": [18, 26], "Depot": [32, 28],
	"GummyFace": [101, 74], "Background": [288, 192], "TileSprinkle": [32, 32], "TileGrid": [32, 32],
	"BlockChoco": [96, 32], "BlockPink": [96, 32],
	"IcoSkull": [16, 16], "IcoBlock": [16, 16], "IcoHill": [16, 16], "IcoCoin": [16, 16], "IcoTnt": [16, 16],
	"IcoRadio": [16, 16], "IcoTarget": [16, 16], "IcoHeart": [16, 16], "IcoVest": [16, 16], "IcoFlag": [16, 16],
	"IcoCrown": [16, 16], "IcoBoots": [16, 16], "IcoAmmo": [16, 16], "Stain": [24, 8],
	"Jungle": [320, 80],
}

## Comandantes: 3 frames de boca
const COMMANDERS := {
	"USA": ["CmdUSA_1", "CmdUSA_2", "CmdUSA_3"],
	"Vietnam": ["CmdVietnam_1", "CmdVietnam_2", "CmdVietnam_3"],
}

## Casco por equipo (TeamInfo.Helmet) y bandera (TeamInfo.Flag)
const TEAM_HELMET := {"USA": "SoldierHelmet", "Vietnam": "HelmetVN"}
const TEAM_FLAG := {"USA": "FlagUSA", "Vietnam": "FlagVN"}
const TEAM_BLOCK := {"USA": "sprinkle", "Vietnam": "pink"}

## Partes del cuerpo por clase. Center en unidades de rig desde los pies (Y arriba).
const RIGS := {
	"Soldier": {
		"Torso": {"image": "SoldierTorso", "center": Vector2(0, 14.5), "scale": 1.0},
		"Walk": {"image": "SoldierWalk", "center": Vector2(1.5, 14.5), "scale": 1.0},
		"Head": {"image": "SoldierHead", "center": Vector2(2, 31), "scale": 0.78},
		"Hat": {"center": Vector2(1.5, 39), "scale": 0.8},
	},
	"Pyro": {
		"Torso": {"image": "PyroTorso", "center": Vector2(0, 14.5), "scale": 1.0},
		"Head": {"image": "PyroHead", "center": Vector2(1, 32), "scale": 0.85},
	},
}

## Visuales de arma: pivot = hombro; offset = centro del arma respecto al pivote;
## manos y boca relativas al centro del arma (sin rotar). tint multiplica el color.
const _RIFLE := {
	"image": "Rifle", "scale": 0.58,
	"pivot": Vector2(2, 17), "offset": Vector2(12, 0),
	"rear_hand": Vector2(-3.4, -0.6), "front_hand": Vector2(5, -0.8),
	"muzzle": Vector2(13.8, 2.6), "tint": Color(1, 1, 1),
}

var WEAPONS := {}

## Texturas de bloques del mapa (studs por mosaico U/V y color de tinte)
const BLOCK_TEXTURES := {
	"choco": {"image": "BlockChoco", "studs_u": 12.0, "studs_v": 4.0, "tint": Color(0.54902, 0.490196, 0.490196)},
	"pink": {"image": "BlockPink", "studs_u": 12.0, "studs_v": 4.0, "tint": Color(0.882353, 0.843137, 0.823529)},
	"sprinkle": {"image": "TileSprinkle", "studs_u": 4.0, "studs_v": 4.0, "tint": Color(0.882353, 0.843137, 0.823529)},
	"grid": {"image": "TileGrid", "studs_u": 4.0, "studs_v": 4.0, "tint": Color(0.54902, 0.490196, 0.490196)},
	"slab": {"image": "BlockChoco", "studs_u": 12.0, "studs_v": 4.0, "tint": Color(0.431373, 0.372549, 0.372549)},
}

## Decorado del mapa. "flip" es orientativo: el espejado real es por instancia
## (en x < 0) y lo resuelve map_grid.gd.
const DECOR := {
	"sign_mines": {"image": "Decor_sign_mines", "flip": false},
	"grave": {"image": "Decor_grave", "flip": true},
	"poster_vn": {"image": "Decor_poster_vn", "flip": false},
	"sandbags": {"image": "Decor_sandbags", "flip": false},
	"deadtree": {"image": "Decor_deadtree", "flip": true},
	"sign_war": {"image": "Decor_sign_war", "flip": false},
	"crate": {"image": "Decor_crate", "flip": false},
	"poster_usa": {"image": "Decor_poster_usa", "flip": false},
	"tank": {"image": "Decor_tank", "flip": true},
	"poster_peace": {"image": "Decor_poster_peace", "flip": false},
	"sign_peace": {"image": "Decor_sign_peace", "flip": false},
	"wire": {"image": "Decor_wire", "flip": false},
}

## Fondo, en studs; z = profundidad de cada capa
const BACKGROUND := {
	"backdrop": {"image": "Background", "center": Vector2(0, 80), "size": Vector2(1500, 1000), "z": -600.0},
	"jungle1": {"image": "Jungle", "center": Vector2(0, 20), "size": Vector2(1400, 60), "z": -160.0,
		"studs_u": 240.0, "studs_v": 60.0, "tint": Color(1, 0.9, 1)},
	"jungle2": {"image": "Jungle", "center": Vector2(0, 16), "size": Vector2(1400, 52), "z": -60.0,
		"studs_u": 208.0, "studs_v": 52.0, "tint": Color(0.75, 0.675, 0.75)},
}

var _cache := {}


func _ready() -> void:
	WEAPONS = {
		"Rifle": _RIFLE,
		"Shotgun": _variant(_RIFLE, {"image": "RifleShort", "scale": 0.64, "offset": Vector2(8.5, 0),
			"rear_hand": Vector2(-5.5, -0.6), "front_hand": Vector2(3, -0.8),
			"muzzle": Vector2(11.5, 2.6), "tint": Color8(200, 170, 150)}),
		"LMG": _variant(_RIFLE, {"scale": 0.66, "offset": Vector2(13, -0.5), "tint": Color8(120, 130, 110),
			"rear_hand": Vector2(-4, -0.6), "front_hand": Vector2(5.6, -0.9), "muzzle": Vector2(15.6, 2.8)}),
		"Sniper": _variant(_RIFLE, {"scale": 0.74, "offset": Vector2(15, 0.5), "tint": Color8(150, 160, 120),
			"rear_hand": Vector2(-4.4, -0.7), "front_hand": Vector2(6.5, -1), "muzzle": Vector2(17.5, 3.2)}),
		"Flamer": {"image": "Flamer", "scale": 0.58, "pivot": Vector2(2, 16.5), "offset": Vector2(13.5, -0.5),
			"rear_hand": Vector2(-9.6, 0.3), "front_hand": Vector2(-4.1, 0.3), "muzzle": Vector2(15, 0.6),
			"tint": Color(1, 1, 1)},
	}
	WEAPONS["Napalm"] = _variant(WEAPONS["Flamer"], {"tint": Color8(255, 185, 120)})


func _variant(base: Dictionary, changes: Dictionary) -> Dictionary:
	var t := base.duplicate()
	t.merge(changes, true)
	return t


## Textura por nombre (sin extensión). "RifleShort" es el Rifle recortado a 36 px.
func tex(image_name: String) -> Texture2D:
	if _cache.has(image_name):
		return _cache[image_name]
	var t: Texture2D = null
	if image_name == "RifleShort":
		var at := AtlasTexture.new()
		at.atlas = tex("Rifle")
		at.region = Rect2(0, 0, 36, 16)
		t = at
	else:
		var path := DIR + image_name + ".png"
		if ResourceLoader.exists(path):
			t = load(path)
		else:
			push_warning("[Sprites] falta " + path)
	_cache[image_name] = t
	return t


func weapon_visual(weapon_id: String) -> Dictionary:
	return WEAPONS.get(weapon_id, WEAPONS.get("Rifle", {}))


## Px de mundo por unidad de rig
func unit_px() -> float:
	return UNIT_STUDS * GC.STUD
