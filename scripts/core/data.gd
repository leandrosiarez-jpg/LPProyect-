extends Node
## Datos de balance compartidos: clases, armas y tienda.
## Valores en studs (1 stud = 8 px) y segundos.

const DEFAULT_CLASS := "Soldier"
const CLASS_ORDER := ["Soldier", "Pyro"]

const CLASSES := {
	"Soldier": {
		"display": "Soldado",
		"description": "Infantería básica. Fusil de cerrojo: un tiro, un muerto. Si falla, reza.",
		"role": "ASALTO",
		"max_health": 100.0,
		"walk_speed": 14.0,
		"jump_power": 66.0,
		"default_weapon": "Rifle",
		"weapons": ["Rifle", "Shotgun", "LMG", "Sniper"],
		"grenades": 1,
	},
	"Pyro": {
		"display": "Pyro",
		"description": "Lanzallamas. Derrite todo lo que toca, incluso a los que se rinden.",
		"role": "CORTA DISTANCIA",
		"max_health": 120.0,
		"walk_speed": 14.5,
		"jump_power": 65.0,
		"default_weapon": "Flamer",
		"weapons": ["Flamer", "Napalm", "Shotgun"],
		"grenades": 0,
	},
}

const WEAPONS := {
	"Rifle": {
		"display": "Fusil de Cerrojo M1", "visual": "Rifle", "projectile": "Bullet",
		"damage": 70.0, "headshot": true, "fire_rate": 1.15, "automatic": false,
		"bolt_action": true, "bolt_time": 0.8, "projectile_speed": 420.0,
		"spread": 0.3, "move_spread": 3.5, "pellets": 1, "range": 240.0, "hit_radius": 0.22,
		"mag_size": 5, "reload_time": 2.6, "recoil": 9.0, "shake": 0.45, "knockback": 14.0,
		"block_damage": 1.6, "sound": "RifleShot",
	},
	"Shotgun": {
		"display": "Escopeta Recortada", "visual": "Shotgun", "projectile": "Pellet",
		"damage": 15.0, "headshot": true, "fire_rate": 0.8, "automatic": false,
		"projectile_speed": 240.0, "spread": 7.0, "move_spread": 2.0, "pellets": 7,
		"range": 55.0, "hit_radius": 0.3, "mag_size": 6, "reload_time": 2.2, "recoil": 8.0,
		"shake": 0.5, "knockback": 4.0, "block_damage": 1.2, "sound": "Shotgun",
	},
	"LMG": {
		"display": "M60 Ametralladora", "visual": "LMG", "projectile": "Bullet",
		"damage": 25.0, "headshot": true, "fire_rate": 0.075, "automatic": true,
		"projectile_speed": 280.0, "spread": 3.2, "move_spread": 4.0, "pellets": 1,
		"range": 180.0, "hit_radius": 0.25, "mag_size": 75, "reload_time": 3.4, "recoil": 2.0,
		"shake": 0.12, "knockback": 5.0, "block_damage": 1.3, "move_multiplier": 0.85,
		"sound": "LMG",
	},
	"Sniper": {
		"display": "Rifle de Francotirador", "visual": "Sniper", "projectile": "Tracer",
		"damage": 95.0, "headshot": true, "fire_rate": 1.15, "automatic": false,
		"projectile_speed": 750.0, "spread": 0.0, "move_spread": 6.0, "pellets": 1,
		"range": 420.0, "hit_radius": 0.2, "mag_size": 5, "reload_time": 2.6, "recoil": 10.0,
		"shake": 0.6, "knockback": 14.0, "block_damage": 1.5, "sound": "Sniper",
	},
	"Flamer": {
		"display": "Lanzallamas", "visual": "Flamer", "projectile": "Flame",
		"damage": 7.0, "headshot": false, "fire_rate": 0.06, "automatic": true,
		"projectile_speed": 55.0, "spread": 9.0, "move_spread": 0.0, "pellets": 2,
		"range": 20.0, "hit_radius": 0.9, "mag_size": 80, "reload_time": 2.2, "recoil": 0.6,
		"shake": 0.05, "knockback": 1.0, "block_damage": 0.6,
		"burn": {"damage": 7.0, "interval": 0.4, "duration": 3.0}, "sound": "Flame",
	},
	"Napalm": {
		"display": "Lanzanapalm", "visual": "Napalm", "projectile": "Flame",
		"damage": 8.0, "headshot": false, "fire_rate": 0.06, "automatic": true,
		"projectile_speed": 62.0, "spread": 8.0, "move_spread": 0.0, "pellets": 2,
		"range": 27.0, "hit_radius": 1.0, "mag_size": 90, "reload_time": 2.4, "recoil": 0.8,
		"shake": 0.06, "knockback": 1.0, "block_damage": 0.8,
		"burn": {"damage": 10.0, "interval": 0.4, "duration": 4.5}, "sound": "Flame",
	},
}

const GRENADE := {
	"display": "Dona Explosiva", "damage": 120.0, "radius": 13.0, "block_damage": 260.0,
	"throw_speed": 62.0, "up_boost": 18.0, "gravity": 110.0, "fuse": 1.7, "bounce": 0.45,
	"cooldown": 0.8, "knockback": 55.0,
}

const SHOP_CATEGORIES := ["ARMAS", "EQUIPO", "SUMINISTROS"]

const SHOP_ITEMS := [
	{"id": "Shotgun", "category": "ARMAS", "kind": "Weapon", "weapon": "Shotgun", "price": 450, "desc": "7 perdigones. Brutal de cerca."},
	{"id": "LMG", "category": "ARMAS", "kind": "Weapon", "weapon": "LMG", "price": 650, "desc": "75 balas por cargador. Te hace más lento."},
	{"id": "Sniper", "category": "ARMAS", "kind": "Weapon", "weapon": "Sniper", "price": 700, "desc": "Un tiro, una gomita menos."},
	{"id": "Napalm", "category": "ARMAS", "kind": "Weapon", "weapon": "Napalm", "price": 600, "desc": "Más alcance y quemaduras más largas."},
	{"id": "Vest", "category": "EQUIPO", "kind": "Upgrade", "name": "Chaleco antibalas", "price": 300, "desc": "+30 de vida máxima."},
	{"id": "Boots", "category": "EQUIPO", "kind": "Upgrade", "name": "Botas de jungla", "price": 250, "desc": "+12% de velocidad."},
	{"id": "Mags", "category": "EQUIPO", "kind": "Upgrade", "name": "Cargadores extra", "price": 200, "desc": "+50% de munición por cargador."},
	{"id": "Grenades", "category": "SUMINISTROS", "kind": "Consumable", "name": "Donas explosivas x2", "price": 200, "desc": "Granadas de azúcar. Tecla G. Rompen bloques.", "max": 4},
	{"id": "Blocks", "category": "SUMINISTROS", "kind": "Consumable", "name": "Bloques de caramelo x8", "price": 150, "desc": "Más bloques para fortificar la base."},
]


func get_class_data(class_id: String) -> Dictionary:
	return CLASSES.get(class_id, CLASSES[DEFAULT_CLASS])


func is_valid_class(class_id) -> bool:
	return class_id is String and CLASSES.has(class_id)


func can_use(class_id: String, weapon_id: String) -> bool:
	return weapon_id in get_class_data(class_id)["weapons"]


func get_weapon(weapon_id: String) -> Dictionary:
	return WEAPONS.get(weapon_id, WEAPONS["Rifle"])


func get_shop_item(item_id: String) -> Dictionary:
	for item in SHOP_ITEMS:
		if item["id"] == item_id:
			return item
	return {}


func item_name(item: Dictionary) -> String:
	if item.has("name"):
		return item["name"]
	return get_weapon(item.get("weapon", "")).get("display", item.get("id", "?"))
