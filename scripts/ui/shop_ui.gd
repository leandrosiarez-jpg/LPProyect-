extends Control
## Intendencia (ShopController): tienda del interludio. Tecla T ("shop").
## Lee MatchState.my_player (Money, Owned, EquipSoldier, EquipPyro, Vest, Boots,
## Mags, GrenadeBonus) y manda Net.request("Buy", [id]) / ("Equip", [weapon]).

## Ícono de cada artículo de la tienda
const ICONS := {"Vest": "IcoVest", "Boots": "IcoBoots", "Mags": "IcoAmmo", "Grenades": "Donut", "Blocks": "IcoBlock"}

var _modal: UIKit.Box
var _money: PixelFont.PixelLabel
var _grid: Control
var _tabs := {}
var _cards: Array = []
var _category := "ARMAS"
var is_open := false


func _ready() -> void:
	UIKit.root(self)
	UIKit.display_order(self, 20)
	_modal = UIKit.panel(UIKit.LINE, 2.0, true, 0.15, self)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.place(_modal, [0.5, 0, 0.52, 0], [0, 830, 0, 520], Vector2(0.5, 0.5))
	UIKit.place(UIKit.hazard(_modal), [0, 0, 0, 0], [1, 0, 0, 8])
	UIKit.off(UIKit.label("INTENDENCIA", UIKit.TEXT, UIKit.LEFT, _modal), 24, 18, 360, 46)
	UIKit.off(UIKit.label("Lo que compres dura toda la partida. Pagás con azúcar de guerra.", UIKit.MUTED, UIKit.LEFT, _modal), 26, 62, 500, 20)

	var money_box := UIKit.frame(UIKit.BLACK, 0.3, 6.0, _modal)
	money_box.stroke = UIKit.ACCENT
	money_box.stroke_width = 2.0
	money_box.stroke_alpha = 0.8
	UIKit.place(money_box, [1, -70, 0, 22], [0, 170, 0, 44], Vector2(1, 0))
	UIKit.off(UIKit.sprite("IcoCoin", Color.WHITE, "fit", money_box), 8, 8, 28, 28)
	_money = UIKit.label("$0", UIKit.ACCENT, UIKit.LEFT, money_box)
	UIKit.off(_money, 42, 6, 120, 32)

	var close := UIKit.button("X", "Danger", Color.WHITE, _modal)
	UIKit.place(close, [1, -14, 0, 22], [0, 44, 0, 44], Vector2(1, 0))
	close.pressed.connect(func(): set_open(false))

	for i in Data.SHOP_CATEGORIES.size():
		var cat: String = Data.SHOP_CATEGORIES[i]
		var tab := UIKit.button(cat, "Secondary", Color.WHITE, _modal)
		UIKit.off(tab, 24 + i * 168, 92, 158, 38)
		tab.pressed.connect(func():
			_category = cat
			_refresh())
		_tabs[cat] = tab

	_grid = UIKit.container(_modal)
	UIKit.place(_grid, [0, 24, 0, 144], [1, -48, 1, -190])
	for item in Data.SHOP_ITEMS:
		_cards.append(_make_card(item))

	UIKit.place(UIKit.label("[T] cerrar  ·  Las armas nuevas se equipan solas en la clase que las usa", UIKit.MUTED, UIKit.CENTER, _modal),
		[0.5, 0, 1, -12], [0, 600, 0, 18], Vector2(0.5, 1))

	visible = false
	MatchState.player_changed.connect(func(peer_id: int):
		if peer_id == Net.my_id():
			_refresh())
	MatchState.var_changed.connect(func(key: String, value):
		if key == "Phase" and is_open and value != "Prep":
			set_open(false))
	G.session_ended.connect(func(): set_open(false))


func _classes_for(weapon_id: String) -> String:
	var names := []
	for cls in Data.CLASS_ORDER:
		if Data.can_use(cls, weapon_id):
			names.append(UIKit.upper(Data.get_class_data(cls)["display"]))
	return " / ".join(names)


func _make_card(item: Dictionary) -> Dictionary:
	var card := UIKit.panel(UIKit.LINE, 2.0, false, 0.5, _grid)
	card.size = Vector2(250, 150)
	var box := UIKit.frame(UIKit.BLACK, 0.4, 4.0, card)
	UIKit.off(box, 10, 10, 84, 60)
	var icon_name: String = ICONS.get(item["id"], "IcoCoin")
	var tint := Color.WHITE
	if item["kind"] == "Weapon":
		var visual: Dictionary = Sprites.weapon_visual(item["weapon"])
		icon_name = visual["image"]
		tint = visual.get("tint", Color.WHITE)
	UIKit.place(UIKit.sprite(icon_name, tint, "fit", box), [0.5, 0, 0.5, 0], [0.9, 0, 0.8, 0], Vector2(0.5, 0.5))
	UIKit.off(UIKit.label(UIKit.upper(Data.item_name(item)), UIKit.TEXT, UIKit.LEFT, card), 102, 8, 140, 22)
	var desc := UIKit.label(item["desc"], UIKit.MUTED, UIKit.LEFT, card)
	desc.scaled = false
	desc.text_size = 14
	desc.wrapped = true
	desc.y_align = 0
	UIKit.off(desc, 102, 32, 140, 40)
	if item["kind"] == "Weapon":
		UIKit.off(UIKit.label("CLASE: " + _classes_for(item["weapon"]), UIKit.KHAKI, UIKit.LEFT, card), 10, 76, 230, 16)
	var b := UIKit.button("", "Primary", Color.WHITE, card)
	UIKit.off(b, 10, 100, 230, 40)
	b.pressed.connect(func(): _on_card(item))
	return {"item": item, "card": card, "button": b}


func _owned() -> Array:
	var o = MatchState.my_player("Owned", [])
	return o if o is Array else []


func _on_card(item: Dictionary) -> void:
	if item["kind"] == "Weapon" and item["weapon"] in _owned():
		Net.request("Equip", [item["weapon"]])
	else:
		Net.request("Buy", [item["id"]])


func _refresh() -> void:
	if not is_open:
		return
	var money := int(MatchState.my_player("Money", 0))
	_money.text = "$%d" % money
	var owned := _owned()
	var equipped := [MatchState.my_player("EquipSoldier", ""), MatchState.my_player("EquipPyro", "")]
	var slot := 0
	for entry in _cards:
		var item: Dictionary = entry["item"]
		var b: UIKit.PButton = entry["button"]
		var card: Control = entry["card"]
		card.visible = item["category"] == _category
		if card.visible:
			# UIGridLayout: celdas de 250x150 con separación 16 x 14, solo las visibles
			card.position = Vector2((slot % 3) * 266, (slot / 3) * 164)
			slot += 1
		var text := "COMPRAR  $%d" % item["price"]
		if item["kind"] == "Weapon" and item["weapon"] in owned:
			text = "EQUIPADA" if item["weapon"] in equipped else "EQUIPAR"
		elif item["kind"] == "Upgrade" and MatchState.my_player(item["id"], false):
			text = "ADQUIRIDO"
		b.set_text(text)
		b.label.transparency = 0.55 if text.begins_with("COMPRAR") and money < int(item["price"]) else 0.0
	for cat in _tabs:
		var tab: UIKit.PButton = _tabs[cat]
		tab.stroke = UIKit.ACCENT if cat == _category else UIKit.LINE
		tab.label.color = UIKit.ACCENT if cat == _category else UIKit.TEXT


func can_open() -> bool:
	var phase := MatchState.phase()
	return Net.mode != Net.Mode.NONE and not G.menu_open and bool(MatchState.my_player("Deployed", false)) \
		and (phase == "Prep" or phase == "Waiting")


func toggle() -> void:
	set_open(not is_open)


func set_open(on: bool) -> void:
	if on and not can_open():
		if Net.mode != Net.Mode.NONE and bool(MatchState.my_player("Deployed", false)):
			UIKit.sfx("Click", 0.0, 0.5)
		return
	if on == is_open:
		return
	is_open = on
	visible = on
	G.ui_open = on
	if on:
		_refresh()
		UIKit.pop(_modal, 0.85)


func _input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_pressed():
		return
	if event.is_action("shop"):
		if G.menu_open:
			return
		toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action("pause_menu") and is_open:
		set_open(false)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if is_open and (G.menu_open or not bool(MatchState.my_player("Deployed", false))):
		set_open(false)
