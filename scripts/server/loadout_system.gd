extends Node
## LoadoutSystem: registro de combatientes (humanos y bots), economía,
## estadísticas, tienda y equipo. Es el registro del que dependen todos los
## demás sistemas.
##
## Combatiente (Dictionary):
##   key, name, team, class, is_bot, peer_id (0 en bots),
##   loadout {money, owned{id:true}, equipped{Soldier, Pyro}, Vest, Boots, Mags,
##            grenade_bonus, blocks_left}
##   stats {Kills, Deaths, Headshots, Score}

signal changed(key: String)

var _combatants := {}


func init_system() -> void:
	_combatants.clear()


func start_system() -> void:
	Net.register_handler("Buy", _on_buy)
	Net.register_handler("Equip", _on_equip)


func _new_loadout() -> Dictionary:
	return {
		"money": GC.MATCH["start_money"],
		"owned": {"Rifle": true, "Flamer": true},
		"equipped": {"Soldier": "Rifle", "Pyro": "Flamer"},
		"Vest": false,
		"Boots": false,
		"Mags": false,
		"grenade_bonus": 0,
		"blocks_left": GC.MATCH["blocks_per_prep"],
	}


func _new_stats() -> Dictionary:
	return {"Kills": 0, "Deaths": 0, "Headshots": 0, "Score": 0}


## Replica el combatiente (scoreboard) y, si es humano, los atributos del jugador.
func sync(c: Dictionary) -> void:
	MatchState.set_combatant(c["key"], {
		"Name": c["name"], "Team": c["team"], "Class": c["class"], "IsBot": c["is_bot"],
		"Kills": c["stats"]["Kills"], "Deaths": c["stats"]["Deaths"],
		"Headshots": c["stats"]["Headshots"], "Score": c["stats"]["Score"],
	})
	var peer: int = c.get("peer_id", 0)
	if peer != 0:
		var l: Dictionary = c["loadout"]
		MatchState.set_player(peer, {
			"Money": l["money"],
			"Owned": l["owned"].keys(),
			"EquipSoldier": l["equipped"]["Soldier"],
			"EquipPyro": l["equipped"]["Pyro"],
			"Vest": l["Vest"],
			"Boots": l["Boots"],
			"Mags": l["Mags"],
			"GrenadeBonus": l["grenade_bonus"],
			"BlocksLeft": l["blocks_left"],
		})


## info: {name, team, class, is_bot, peer_id}
func register(key: String, info: Dictionary) -> Dictionary:
	var c: Dictionary = _combatants.get(key, {})
	if c.is_empty():
		c = {"key": key, "loadout": _new_loadout(), "stats": _new_stats(), "class": Data.DEFAULT_CLASS}
		_combatants[key] = c
	c["name"] = info.get("name", key)
	c["team"] = info.get("team", "USA")
	c["class"] = info.get("class", c["class"])
	c["is_bot"] = info.get("is_bot", false)
	c["peer_id"] = info.get("peer_id", 0)
	sync(c)
	return c


func unregister(key: String) -> void:
	if _combatants.erase(key):
		MatchState.remove_combatant(key)


func get_combatant(key: String) -> Dictionary:
	return _combatants.get(key, {})


func get_all() -> Dictionary:
	return _combatants


func get_weapon_id(c: Dictionary) -> String:
	var cls: String = c["class"]
	var id: String = c["loadout"]["equipped"].get(cls, "")
	if id == "" or not c["loadout"]["owned"].has(id) or not Data.can_use(cls, id):
		id = Data.get_class_data(cls)["default_weapon"]
	return id


## Valores para armar al personaje al aparecer.
func get_spawn_stats(c: Dictionary) -> Dictionary:
	var cls := Data.get_class_data(c["class"])
	var weapon_id := get_weapon_id(c)
	var weapon := Data.get_weapon(weapon_id)
	var l: Dictionary = c["loadout"]
	return {
		"max_health": cls["max_health"] + (30.0 if l["Vest"] else 0.0),
		"walk_speed": cls["walk_speed"] * (1.12 if l["Boots"] else 1.0) * weapon.get("move_multiplier", 1.0),
		"jump_power": cls["jump_power"],
		"weapon": weapon_id,
		"mag_size": int(floor(weapon["mag_size"] * (1.5 if l["Mags"] else 1.0))),
		"grenades": cls["grenades"] + l["grenade_bonus"],
	}


## kind: "Money", "Buy", "Error", "Info"
func notice(c: Dictionary, text: String, kind: String = "Info") -> void:
	var peer: int = c.get("peer_id", 0)
	if peer != 0:
		Net.send_to(peer, "Notice", {"text": text, "kind": kind})


func add_money(key: String, amount: int, reason: String = "") -> void:
	var c := get_combatant(key)
	if c.is_empty():
		return
	c["loadout"]["money"] += amount
	c["stats"]["Score"] += maxi(0, amount)
	sync(c)
	if reason != "":
		notice(c, "+$%d  %s" % [amount, reason], "Money")


func add_stat(key: String, stat: String, amount: int = 1) -> void:
	var c := get_combatant(key)
	if not c.is_empty():
		c["stats"][stat] += amount
		sync(c)


func use_block(key: String) -> bool:
	var c := get_combatant(key)
	if c.is_empty() or c["loadout"]["blocks_left"] <= 0:
		return false
	c["loadout"]["blocks_left"] -= 1
	sync(c)
	return true


func refund_block(key: String) -> void:
	var c := get_combatant(key)
	if not c.is_empty():
		c["loadout"]["blocks_left"] += 1
		sync(c)


## Devuelve "" si la compra salió bien, o el mensaje de error.
func buy(key: String, item_id: String) -> String:
	var c := get_combatant(key)
	var item := Data.get_shop_item(item_id)
	if c.is_empty() or item.is_empty():
		return "Artículo inválido"
	var l: Dictionary = c["loadout"]
	if l["money"] < item["price"]:
		return "No te alcanza el azúcar"
	if item["kind"] == "Weapon":
		var w: String = item["weapon"]
		if l["owned"].has(w):
			return "Ya la tenés"
		l["owned"][w] = true
		for cls in Data.CLASSES:
			if Data.can_use(cls, w) and (cls == c["class"] or not Data.can_use(c["class"], w)):
				l["equipped"][cls] = w
	elif item["kind"] == "Upgrade":
		if l[item_id]:
			return "Ya lo tenés"
		l[item_id] = true
	elif item_id == "Grenades":
		if l["grenade_bonus"] >= item.get("max", 4):
			return "Máximo alcanzado"
		l["grenade_bonus"] += 2
	elif item_id == "Blocks":
		l["blocks_left"] += 8
	l["money"] -= item["price"]
	sync(c)
	changed.emit(key)
	return ""


func equip(key: String, weapon_id: String) -> bool:
	var c := get_combatant(key)
	if c.is_empty() or not c["loadout"]["owned"].has(weapon_id):
		return false
	for cls in Data.CLASSES:
		if Data.can_use(cls, weapon_id):
			c["loadout"]["equipped"][cls] = weapon_id
	sync(c)
	changed.emit(key)
	return true


func reset_for_match() -> void:
	for c in _combatants.values():
		c["loadout"] = _new_loadout()
		c["stats"] = _new_stats()
		sync(c)


func prep_refill() -> void:
	for c in _combatants.values():
		c["loadout"]["blocks_left"] = maxi(c["loadout"]["blocks_left"], GC.MATCH["blocks_per_prep"])
		sync(c)


func _on_buy(peer_id: int, args: Array) -> void:
	if args.size() < 1 or not (args[0] is String):
		return
	var key := Net.key_for_peer(peer_id)
	var c := get_combatant(key)
	if c.is_empty():
		return
	var phase := MatchState.phase()
	if phase != "Prep" and phase != "Waiting":
		notice(c, "La intendencia solo abre en el interludio", "Error")
		return
	var err := buy(key, args[0])
	if err == "":
		notice(c, "Comprado: " + Data.item_name(Data.get_shop_item(args[0])), "Buy")
	else:
		notice(c, err, "Error")


func _on_equip(peer_id: int, args: Array) -> void:
	if args.size() >= 1 and args[0] is String:
		equip(Net.key_for_peer(peer_id), args[0])
