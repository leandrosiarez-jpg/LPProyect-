extends Control
## HUD de combate (HUDController): reloj y marcador, progreso del objetivo, vida,
## arma y munición, dinero, panel del interludio, killfeed, avisos, anuncios de
## fase, mira con hitmarker, viñeta de daño y pantalla de muerte.
## También decide si se ve el cursor del sistema (oculto en juego, visible en menús).

const DEATH_LINES := [
	"Tu familia recibirá una carta y una medalla de caramelo.",
	"El Pentágono lo llama 'pérdida aceptable'.",
	"Mañana te reemplaza otra gomita idéntica.",
	"Moriste por la patria. La patria no se enteró.",
	"Tu sacrificio será recordado hasta el próximo comercial.",
	"Nadie te preguntó si querías venir.",
]
const HINT := "A/D mover · ESPACIO saltar · CLICK disparar · R recargar · G granada · TAB puntajes · M menú"
const NOTICE_H := 26.0
const FEED_H := 28.0

var _game: Control          # todo lo que solo se ve en juego
var _clock: PixelFont.PixelLabel
var _phase: PixelFont.PixelLabel
var _plates := {}
var _strip: UIKit.Box
var _mission_icon: TextureRect
var _mission_name: PixelFont.PixelLabel
var _mission_desc: PixelFont.PixelLabel
var _war_deaths: PixelFont.PixelLabel
var _obj_toast: PixelFont.PixelLabel

var _hp_panel: UIKit.Box
var _portrait_box: UIKit.Box
var _portrait: UIKit.RigPreview
var _class_label: PixelFont.PixelLabel
var _hp_text: PixelFont.PixelLabel
var _hp_lag: UIKit.Box
var _hp_fill: UIKit.Box
var _grenades: PixelFont.PixelLabel
var _wp_panel: UIKit.Box
var _weapon_icon: TextureRect
var _weapon_name: PixelFont.PixelLabel
var _ammo: PixelFont.PixelLabel
var _ammo_max: PixelFont.PixelLabel
var _mag_fill: UIKit.Box
var _reload_text: PixelFont.PixelLabel
var _money_panel: UIKit.Box
var _money: PixelFont.PixelLabel

var _prep: UIKit.Box
var _prep_title: PixelFont.PixelLabel
var _build_btn: UIKit.PButton
var _shop_btn: UIKit.PButton
var _class_btns := {}
var _ready_btn: UIKit.PButton

var _banner: Control
var _banner_back: FadeBar
var _banner_title: PixelFont.PixelLabel
var _banner_sub: PixelFont.PixelLabel
var _banner_token := 0
var _kill_confirm: PixelFont.PixelLabel
var _notices: Control
var _notice_list: Array = []
var _killfeed: Control
var _feed_list: Array = []
var _death: ColorRect
var _death_title: PixelFont.PixelLabel
var _death_sub: PixelFont.PixelLabel
var _death_satire: PixelFont.PixelLabel
var _death_timer: PixelFont.PixelLabel
var _vignette: Vignette
var _cross: Crosshair
var _hint: PixelFont.PixelLabel

var _death_info := {}
var _damage_flash := 0.0
var _last_money := -1
var _last_ammo := -1
var _last_health := -1.0
var _health_lag := 1.0
var _mouse_hidden := false
var _toast_text := ""
var _kill_text := ""


func _ready() -> void:
	UIKit.root(self)
	UIKit.display_order(self, 10)
	_game = UIKit.container(self)
	UIKit.full(_game)
	_build_center_back()
	_build_top()
	_build_vitals()
	_build_prep()
	_build_center()
	Net.event_received.connect(_on_event)
	G.session_ended.connect(_on_session_ended)


# --- construcción -------------------------------------------------------------

func _build_top() -> void:
	var top := UIKit.container(_game)
	UIKit.place(top, [0.5, 0, 0, 54], [0, 860, 0, 74], Vector2(0.5, 0))
	var clock := UIKit.panel(UIKit.LINE, 2.0, true, 0.15, top)
	UIKit.place(clock, [0.5, 0, 0, 0], [0, 170, 0, 74], Vector2(0.5, 0))
	_clock = UIKit.label("5:00", UIKit.TEXT, UIKit.CENTER, clock)
	UIKit.place(_clock, [0, 8, 0, 6], [1, -16, 0, 40])
	_phase = UIKit.label("RONDA 1/3", UIKit.ACCENT, UIKit.CENTER, clock)
	UIKit.place(_phase, [0, 8, 0, 46], [1, -16, 0, 20])
	for i in GC.TEAMS.size():
		var team: String = GC.TEAMS[i]
		var info: Dictionary = GC.TEAM_INFO[team]
		var color: Color = info["color"]
		var left := i == 0
		var plate := UIKit.panel(color, 2.0, true, 0.15, top)
		UIKit.place(plate, [0.5, -92 if left else 92, 0, 6], [0, 330, 0, 62], Vector2(1 if left else 0, 0))
		var strip := UIKit.rect(color, plate)
		UIKit.place(strip, [1, -6, 0, 0] if left else [0, 0, 0, 0], [0, 6, 1, 0])
		var flag := UIKit.sprite(Sprites.TEAM_FLAG[team], Color.WHITE, "fit", plate)
		UIKit.place(flag, [0, 12, 0, 10] if left else [1, -48, 0, 10], [0, 36, 0, 24])
		var name_l := UIKit.label(info["display"], color, UIKit.LEFT if left else UIKit.RIGHT, plate)
		UIKit.place(name_l, [0, 56, 0, 6] if left else [1, -206, 0, 6], [0, 150, 0, 30])
		var pips := []
		for p in 2:
			var pip := UIKit.frame(UIKit.BLACK, 0.0, 0.0, plate)
			pip.stroke = color
			pip.stroke_width = 2.0
			UIKit.place(pip, [1, -20 - p * 22, 0, 20] if left else [0, 20 + p * 22, 0, 20], [0, 16, 0, 16], Vector2(0.5, 0.5))
			pip.rotation_degrees = 45.0
			pips.append(pip)
		var bar_back := UIKit.frame(UIKit.BLACK, 0.0, 3.0, plate)
		UIKit.place(bar_back, [0, 12, 0, 40], [1, -24, 0, 14])
		var fill := UIKit.frame(Color.WHITE, 0.0, 3.0, bar_back)
		fill.gradient = true
		fill.grad_top = color.lerp(Color.WHITE, 0.3)
		fill.grad_bottom = color
		UIKit.place(fill, [1, 0, 0, 0] if left else [0, 0, 0, 0], [0, 0, 1, 0], Vector2(1 if left else 0, 0))
		var txt := UIKit.label("", UIKit.TEXT, UIKit.CENTER, bar_back)
		UIKit.full(txt)
		_plates[team] = {"plate": plate, "pips": pips, "fill": fill, "text": txt, "last": 0.0, "ratio": 0.0, "left": left}

	_strip = UIKit.panel(UIKit.LINE, 2.0, false, 0.15, _game)
	UIKit.place(_strip, [0.5, 0, 0, 134], [0, 700, 0, 40], Vector2(0.5, 0))
	_mission_icon = UIKit.sprite("IcoTarget", Color.WHITE, "fit", _strip)
	UIKit.off(_mission_icon, 10, 6, 28, 28)
	_mission_name = UIKit.label("", UIKit.ACCENT, UIKit.LEFT, _strip)
	UIKit.off(_mission_name, 46, 4, 280, 32)
	_mission_desc = UIKit.label("", UIKit.TEXT, UIKit.LEFT, _strip)
	UIKit.place(_mission_desc, [0, 334, 0, 9], [1, -346, 0, 22])

	_war_deaths = UIKit.label("", Color8(220, 120, 110), UIKit.LEFT, _game)
	UIKit.off(_war_deaths, 16, 24, 330, 22)  # debajo de la placa de USA
	_obj_toast = UIKit.label("", UIKit.ACCENT, UIKit.CENTER, _game)
	_obj_toast.transparency = 1.0
	UIKit.place(_obj_toast, [0.5, 0, 0, 180], [0, 760, 0, 32], Vector2(0.5, 0))


func _build_vitals() -> void:
	_hp_panel = UIKit.panel(UIKit.LINE, 2.0, true, 0.15, _game)
	UIKit.place(_hp_panel, [0, 16, 1, -16], [0, 380, 0, 104], Vector2(0, 1))
	_portrait_box = UIKit.frame(UIKit.BLACK, 0.35, 6.0, _hp_panel)
	_portrait_box.clip_contents = true
	UIKit.off(_portrait_box, 10, 10, 84, 84)
	_portrait = UIKit.rig_preview("Soldier", "USA", "Rifle", _portrait_box)
	UIKit.off(_portrait, -30, -6, 150, 150)
	_class_label = UIKit.label("SOLDADO", UIKit.TEXT, UIKit.LEFT, _hp_panel)
	UIKit.off(_class_label, 104, 8, 260, 22)
	UIKit.off(UIKit.sprite("IcoHeart", Color.WHITE, "fit", _hp_panel), 104, 38, 28, 28)
	_hp_text = UIKit.label("100", UIKit.TEXT, UIKit.LEFT, _hp_panel)
	UIKit.off(_hp_text, 138, 34, 110, 34)
	var bar_back := UIKit.frame(UIKit.BLACK, 0.0, 4.0, _hp_panel)
	bar_back.clip_contents = true
	UIKit.off(bar_back, 104, 72, 262, 20)
	_hp_lag = UIKit.frame(Color8(255, 230, 230), 0.0, 4.0, bar_back)
	UIKit.place(_hp_lag, [0, 0, 0, 0], [1, 0, 1, 0])
	_hp_fill = UIKit.frame(Color.WHITE, 0.0, 4.0, bar_back)
	_hp_fill.gradient = true
	_hp_fill.grad_top = Color8(150, 255, 120)
	_hp_fill.grad_bottom = Color8(60, 190, 60)
	UIKit.place(_hp_fill, [0, 0, 0, 0], [1, 0, 1, 0])
	for i in range(1, 10):
		UIKit.place(UIKit.rect(Color(UIKit.BLACK, 0.7), bar_back), [i / 10.0, 0, 0, 0], [0, 2, 1, 0])
	UIKit.off(UIKit.sprite("Donut", Color.WHITE, "fit", _hp_panel), 254, 38, 28, 28)
	_grenades = UIKit.label("x1", UIKit.TEXT, UIKit.LEFT, _hp_panel)
	UIKit.off(_grenades, 286, 38, 80, 28)

	_wp_panel = UIKit.panel(UIKit.LINE, 2.0, true, 0.15, _game)
	UIKit.place(_wp_panel, [1, -16, 1, -16], [0, 380, 0, 104], Vector2(1, 1))
	_weapon_icon = UIKit.sprite("Rifle", Color.WHITE, "fit", _wp_panel)
	UIKit.off(_weapon_icon, 12, 14, 150, 50)
	_weapon_name = UIKit.label("", UIKit.KHAKI, UIKit.LEFT, _wp_panel)
	UIKit.off(_weapon_name, 12, 70, 170, 22)
	_ammo = UIKit.label("24", UIKit.TEXT, UIKit.RIGHT, _wp_panel)
	UIKit.place(_ammo, [1, -86, 0, 10], [0, 110, 0, 52], Vector2(1, 0))
	_ammo_max = UIKit.label("/24", UIKit.MUTED, UIKit.LEFT, _wp_panel)
	UIKit.place(_ammo_max, [1, -14, 0, 30], [0, 70, 0, 28], Vector2(1, 0))
	var mag_back := UIKit.container(_wp_panel)
	UIKit.place(mag_back, [1, -14, 0, 70], [0, 180, 0, 20], Vector2(1, 0))
	_mag_fill = UIKit.frame(UIKit.ACCENT, 0.0, 3.0, mag_back)
	UIKit.place(_mag_fill, [0, 0, 0, 0], [1, 0, 1, 0])
	var mag_line := UIKit.frame(Color.WHITE, 1.0, 3.0, mag_back)
	mag_line.stroke = UIKit.LINE
	mag_line.stroke_width = 1.5
	mag_line.stroke_alpha = 0.7
	UIKit.full(mag_line)
	_reload_text = UIKit.label("RECARGANDO", UIKit.BLACK, UIKit.CENTER, _wp_panel)
	UIKit.place(_reload_text, [1, -14, 0, 70], [0, 180, 0, 20], Vector2(1, 0))
	_reload_text.visible = false

	_money_panel = UIKit.panel(UIKit.ACCENT, 2.0, false, 0.15, _game)
	UIKit.place(_money_panel, [1, -16, 1, -128], [0, 170, 0, 40], Vector2(1, 1))
	UIKit.off(UIKit.sprite("IcoCoin", Color.WHITE, "fit", _money_panel), 8, 7, 26, 26)
	_money = UIKit.label("$0", UIKit.ACCENT, UIKit.LEFT, _money_panel)
	UIKit.off(_money, 40, 4, 120, 32)


func _prep_button(text: String, x: float, w: float, style: String) -> UIKit.PButton:
	var b := UIKit.button(text, style, Color.WHITE, _prep)
	UIKit.off(b, x, 46, w, 40)
	return b


func _build_prep() -> void:
	_prep = UIKit.panel(UIKit.LINE, 2.0, true, 0.15, _game)
	# Se apoya sobre los paneles de vida y arma para no taparlos.
	UIKit.place(_prep, [0.5, 0, 1, -128], [0, 720, 0, 96], Vector2(0.5, 1))
	_prep.visible = false
	UIKit.place(UIKit.hazard(_prep), [0, 0, 0, 0], [1, 0, 0, 6])
	_prep_title = UIKit.label("INTERLUDIO · PREPARÁ LA DEFENSA", UIKit.ACCENT, UIKit.CENTER, _prep)
	UIKit.place(_prep_title, [0, 14, 0, 12], [1, -28, 0, 28])
	_build_btn = _prep_button("[B] CONSTRUIR", 14, 186, "Secondary")
	_build_btn.pressed.connect(_toggle_build)
	_shop_btn = _prep_button("[T] INTENDENCIA", 208, 170, "Secondary")
	_shop_btn.pressed.connect(func():
		var shop: Node = G.controller("Shop")
		if shop and shop.has_method("toggle"):
			shop.toggle())
	_class_btns["Soldier"] = _prep_button("[1] SOLDADO", 386, 104, "Secondary")
	_class_btns["Pyro"] = _prep_button("[2] PYRO", 496, 90, "Secondary")
	for cls in _class_btns:
		_class_btns[cls].pressed.connect(func(): Net.request("SelectClass", [cls]))
	_ready_btn = _prep_button("[F] ¡LISTO!", 594, 112, "Primary")
	_ready_btn.pressed.connect(_toggle_ready)


## Viñeta (debajo de todo lo demás del HUD)
func _build_center_back() -> void:
	_vignette = Vignette.new()
	_game.add_child(_vignette)
	UIKit.full(_vignette)


func _build_center() -> void:
	_banner = UIKit.container(self)
	UIKit.place(_banner, [0.5, 0, 0.34, 0], [0, 900, 0, 150], Vector2(0.5, 0.5))
	_banner.visible = false
	_banner_back = FadeBar.new()
	_banner.add_child(_banner_back)
	UIKit.place(_banner_back, [0.5, 0, 0.5, 0], [1.4, 0, 0, 110], Vector2(0.5, 0.5))
	_banner_title = UIKit.label("", UIKit.TEXT, UIKit.CENTER, _banner)
	UIKit.place(_banner_title, [0.5, 0, 0.08, 0], [1, 0, 0.55, 0], Vector2(0.5, 0))
	_banner_sub = UIKit.label("", UIKit.KHAKI, UIKit.CENTER, _banner)
	UIKit.place(_banner_sub, [0.5, 0, 0.66, 0], [1, 0, 0.22, 0], Vector2(0.5, 0))

	_kill_confirm = UIKit.label("", UIKit.ACCENT, UIKit.CENTER, _game)
	_kill_confirm.transparency = 1.0
	UIKit.place(_kill_confirm, [0.5, 0, 0.62, 0], [0, 500, 0, 44], Vector2(0.5, 0.5))

	_notices = UIKit.container(_game)
	UIKit.place(_notices, [0.5, 0, 1, -128], [0, 500, 0, 160], Vector2(0.5, 1))
	_killfeed = UIKit.container(_game)
	UIKit.place(_killfeed, [1, -16, 0, 180], [0, 380, 0, 260], Vector2(1, 0))  # debajo de la placa de Vietnam

	_death = UIKit.rect(Color(40 / 255.0, 0, 0, 0.0), _game)
	UIKit.full(_death)
	_death.visible = false
	_death_title = UIKit.label("CAÍSTE", UIKit.DANGER, UIKit.CENTER, _death)
	UIKit.place(_death_title, [0.5, 0, 0.42, 0], [0, 700, 0, 70], Vector2(0.5, 0.5))
	_death_sub = UIKit.label("", UIKit.TEXT, UIKit.CENTER, _death)
	UIKit.place(_death_sub, [0.5, 0, 0.5, 0], [0, 700, 0, 28], Vector2(0.5, 0.5))
	_death_satire = UIKit.label("", Color8(200, 190, 170), UIKit.CENTER, _death)
	UIKit.place(_death_satire, [0.5, 0, 0.64, 0], [0, 820, 0, 24], Vector2(0.5, 0.5))
	_death_timer = UIKit.label("", UIKit.ACCENT, UIKit.CENTER, _death)
	UIKit.place(_death_timer, [0.5, 0, 0.57, 0], [0, 500, 0, 34], Vector2(0.5, 0.5))

	_hint = UIKit.label(HINT, UIKit.MUTED, UIKit.CENTER, _game)
	UIKit.place(_hint, [0.5, 0, 1, -4], [0, 820, 0, 16], Vector2(0.5, 1))

	_cross = Crosshair.new()
	add_child(_cross)
	UIKit.full(_cross)


# --- helpers ------------------------------------------------------------------

func _attr(ch: Node, key: String, def = null):
	if ch and ch.has_method("get_attr"):
		return ch.get_attr(key, def)
	return def


func _alive(ch: Node) -> bool:
	if ch == null:
		return false
	if ch.has_method("is_alive"):
		return ch.is_alive()
	return not bool(_attr(ch, "Dead", false)) and float(_attr(ch, "Health", 1.0)) > 0.0


func _my_team() -> String:
	var t: String = str(MatchState.my_player("Team", ""))
	if t == "":
		t = str(MatchState.get_combatant(Net.my_key()).get("Team", ""))
	return t


func _my_name() -> String:
	return str(MatchState.get_combatant(Net.my_key()).get("Name", Net.local_name))


func _deployed() -> bool:
	return Net.mode != Net.Mode.NONE and bool(MatchState.my_player("Deployed", false))


func _shake(amount: float) -> void:
	var amt := amount * float(G.settings.get("shake", 1.0))
	for n in [G.controller("Camera"), G.fx]:
		if n and n.has_method("add_shake"):
			n.add_shake(amt)
			return


func _toggle_build() -> void:
	var b: Node = G.controller("Build")
	if b and b.has_method("toggle"):
		b.toggle()


func _toggle_ready() -> void:
	if MatchState.phase() == "Prep":
		Net.request("SetReady", [not bool(MatchState.my_player("Ready", false))])
		UIKit.sfx("Click")


func _total_deaths() -> int:
	if MatchState.vars.has("TotalDeaths"):
		return int(MatchState.get_var("TotalDeaths", 0))
	var n := 0
	for c in MatchState.combatants.values():
		n += int(c.get("Deaths", 0))
	return n


# --- entrada ------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if G.menu_open or G.ui_open or not _deployed():
		return
	if event.is_action("ready"):
		_toggle_ready()
	elif event is InputEventKey:
		var k: Key = (event as InputEventKey).physical_keycode
		if k == KEY_1:
			Net.request("SelectClass", ["Soldier"])
		elif k == KEY_2:
			Net.request("SelectClass", ["Pyro"])


# --- efectos ------------------------------------------------------------------

func banner(title: String, sub: String = "", color: Color = UIKit.TEXT, duration: float = 3.0) -> void:
	_banner_token += 1
	var token := _banner_token
	_banner.visible = true
	_banner_title.text = title
	_banner_title.color = color
	_banner_sub.text = sub
	_banner_title.transparency = 0.0
	_banner_sub.transparency = 0.0
	_banner_back.alpha = 0.65
	_banner.scale = Vector2.ONE * 2.2
	UIKit.tween_scale(_banner, 1.0, 0.35, Tween.TRANS_BACK)
	_banner.rotation_degrees = randi_range(-3, 3)
	create_tween().tween_property(_banner, "rotation_degrees", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_shake(0.25)
	get_tree().create_timer(duration).timeout.connect(func():
		if token != _banner_token:
			return
		UIKit.fade_text(_banner_title, 1.0, 0.4)
		UIKit.fade_text(_banner_sub, 1.0, 0.4)
		var t2 := create_tween()
		t2.tween_property(_banner_back, "alpha", 0.0, 0.4)
		t2.tween_interval(0.02)
		t2.tween_callback(func():
			if token == _banner_token:
				_banner.visible = false))


func notice(text: String, kind: String = "Info") -> void:
	var color := UIKit.TEXT
	match kind:
		"Money":
			color = UIKit.GOOD
		"Error":
			color = UIKit.DANGER
			UIKit.sfx("Click", 0.0, 0.5)
		"Buy":
			color = UIKit.ACCENT
			UIKit.sfx("Kill", linear_to_db(0.6), 1.3)
	var l := UIKit.label(text, color, UIKit.CENTER, _notices)
	l.size = Vector2(500, NOTICE_H)
	_notice_list.append(l)
	if _notice_list.size() > 5:
		var first: Control = _notice_list.pop_front()
		first.queue_free()
	_layout_notices()
	UIKit.pop(l, 1.4)
	var tw := l.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(l, "transparency", 1.0, 0.4)
	tw.tween_interval(0.05)
	tw.tween_callback(func():
		_notice_list.erase(l)
		l.queue_free()
		_layout_notices())


## UIListLayout abajo y centrado, separación 4
func _layout_notices() -> void:
	var y := 160.0
	for i in range(_notice_list.size() - 1, -1, -1):
		y -= NOTICE_H
		_notice_list[i].position = Vector2(0, y)
		y -= 4.0


func _layout_feed() -> void:
	for i in _feed_list.size():
		_feed_list[i].position = Vector2(0, i * (FEED_H + 4.0))


func _toast(text: String, team: String) -> void:
	_toast_text = text
	_obj_toast.text = text
	_obj_toast.color = UIKit.team_color(team) if GC.TEAM_INFO.has(team) else UIKit.ACCENT
	_obj_toast.transparency = 0.0
	UIKit.pop(_obj_toast, 1.3)
	get_tree().create_timer(3.0).timeout.connect(func():
		if _toast_text == text:
			UIKit.fade_text(_obj_toast, 1.0, 0.5))


func _confirm(text: String, color: Color) -> void:
	_kill_text = text + str(Time.get_ticks_msec())
	var token := _kill_text
	_kill_confirm.text = text
	_kill_confirm.color = color
	_kill_confirm.transparency = 0.0
	UIKit.pop(_kill_confirm, 1.8)
	get_tree().create_timer(1.1).timeout.connect(func():
		if _kill_text == token:
			UIKit.fade_text(_kill_confirm, 1.0, 0.4))


func _add_killfeed(d: Dictionary) -> void:
	var killer: String = str(d.get("killer", "")) if d.get("killer") != null else ""
	var victim: String = str(d.get("victim", "?"))
	var kteam: String = str(d.get("killer_team", ""))
	var vteam: String = str(d.get("victim_team", ""))
	var headshot: bool = bool(d.get("headshot", false))
	var weapon: String = UIKit.weapon_display(str(d.get("weapon", "?")))
	var me := _my_name()
	var my_key := Net.my_key()
	var i_killed: bool = (str(d.get("killer_key", "")) == my_key) if d.has("killer_key") else (killer != "" and killer == me)
	var i_died: bool = (str(d.get("victim_key", "")) == my_key) if d.has("victim_key") else (victim == me)
	var involved := i_killed or i_died

	var entry := UIKit.frame(UIKit.BLACK, 0.3, 4.0, _killfeed)
	entry.stroke = UIKit.ACCENT if involved else UIKit.LINE
	entry.stroke_width = 2.0 if involved else 1.0
	entry.stroke_alpha = 1.0 if involved else 0.4
	entry.size = Vector2(380, FEED_H)
	entry.pivot_offset = entry.size * 0.5
	var label := UIKit.label("", UIKit.TEXT, UIKit.RIGHT, entry)
	label.rich = true
	UIKit.place(label, [0, 8, 0, 3], [1, -40 if headshot else -16, 1, -6])
	var colored := func(n: String, t: String) -> String:
		return "<font color=\"#%s\">%s</font>" % [UIKit.team_color(t).to_html(false), n]
	if killer != "":
		label.text = "%s  <font color=\"#C8C090\">[%s]</font>  %s" % [colored.call(killer, kteam), weapon, colored.call(victim, vteam)]
	else:
		label.text = colored.call(victim, vteam) + "  <font color=\"#C8C090\">se derritió</font>"
	if headshot:
		UIKit.place(UIKit.sprite("IcoSkull", Color.WHITE, "fit", entry), [1, -6, 0.5, 0], [0, 22, 0, 22], Vector2(1, 0.5))
	_feed_list.push_front(entry)
	if _feed_list.size() > 6:
		var last: Control = _feed_list.pop_back()
		last.queue_free()
	_layout_feed()
	UIKit.pop(entry, 1.15)
	var tw := entry.create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(entry, "bg_alpha", 0.0, 0.4)
	tw.parallel().tween_property(entry, "stroke_alpha", 0.0, 0.4)
	tw.parallel().tween_property(label, "transparency", 1.0, 0.4)
	tw.tween_interval(0.05)
	tw.tween_callback(func():
		_feed_list.erase(entry)
		entry.queue_free()
		_layout_feed())

	if i_killed and not i_died:
		if headshot:
			_confirm("¡TIRO A LA CABEZA!", UIKit.DANGER)
			UIKit.sfx("Headshot")
		else:
			_confirm("BAJA CONFIRMADA", UIKit.ACCENT)
		UIKit.sfx("Kill")
		_cross.hit(true)
	if i_died:
		_death_info = {
			"killer": killer, "weapon": weapon, "headshot": headshot,
			"satire": "Fuiste la gomita nº %d en caer. %s" % [_total_deaths(), DEATH_LINES[randi() % DEATH_LINES.size()]],
		}


func _on_event(event: String, data) -> void:
	match event:
		"Round":
			if data is Dictionary:
				_on_round(data)
		"Notice":
			if data is Dictionary:
				notice(str(data.get("text", "")), str(data.get("kind", "Info")))
		"ObjectiveEvent":
			if data is Dictionary and str(data.get("text", "")) != "":
				_toast(str(data.get("text", "")), str(data.get("team", "")))
				UIKit.sfx("Squelch", linear_to_db(0.5))
		"KillFeed":
			if data is Dictionary:
				_add_killfeed(data)
		"Hit":
			if data is Dictionary:
				var me := Net.my_key()
				var attacker: String = str(data.get("attacker", ""))
				var victim: String = str(data.get("victim", ""))
				if attacker == me and victim != me and not bool(data.get("burn", false)):
					_cross.hit(false)
					UIKit.sfx("Hit", linear_to_db(0.7))
				if victim == me:
					_shake(1.0 if bool(data.get("headshot", false)) else 0.35)


func _on_round(d: Dictionary) -> void:
	var kind: String = str(d.get("kind", ""))
	var mission: Dictionary = MissionData.get_mission(str(d.get("mission", "")))
	var round_n := int(d.get("round", MatchState.get_var("Round", 0)))
	match kind:
		"Prep":
			banner("INTERLUDIO", "Ronda %d · Próxima misión: %s · Construí [B] y equipate [T]" % [round_n, mission.get("name", "?")], UIKit.ACCENT, 4.0)
		"Round":
			banner("RONDA %d" % round_n, (mission["name"] + " — " + mission["short"]) if not mission.is_empty() else "", UIKit.TEXT, 3.5)
			UIKit.sfx("Horn")
		"OneMinute":
			banner("¡ÚLTIMO MINUTO!", "", UIKit.DANGER, 2.0)
		"RoundEnd":
			var winner: String = str(d.get("winner", "")) if d.get("winner") != null else ""
			var reason: String = str(d.get("reason", ""))
			var title := "EMPATE"
			var color := UIKit.KHAKI
			if winner != "" and winner == _my_team():
				title = "¡VICTORIA!"
				color = UIKit.team_color(winner)
				UIKit.sfx("Victory")
			elif winner != "":
				title = "DERROTA"
				color = UIKit.DANGER
			var sub := "Nadie cumplió el objetivo"
			if winner != "":
				sub = UIKit.team_display(winner) + (" cumplió el objetivo" if reason == "Objective" else " estaba más cerca del objetivo")
			banner(title, sub, color, 6.0)
			_shake(0.6)
		"MatchEnd":
			_banner_token += 1
			_banner.visible = false


func _on_session_ended() -> void:
	for c in _feed_list:
		c.queue_free()
	_feed_list.clear()
	for c in _notice_list:
		c.queue_free()
	_notice_list.clear()
	_banner.visible = false
	_death_info = {}
	_last_health = -1.0


# --- actualización ------------------------------------------------------------

func _progress_text(team: String) -> String:
	var mission: String = str(MatchState.get_var("Mission", ""))
	if mission == "Radio":
		return "%d/3 SEÑALES" % int(MatchState.get_var("Signals" + team, 0))
	if mission == "CTF":
		return "%d/2 BANDERAS" % int(MatchState.get_var("Captures" + team, 0))
	return "%d%%" % int(floor(float(MatchState.get_var("Progress" + team, 0.0)) * 100.0))


func _update_mouse(in_game: bool, dead: bool) -> void:
	var want_hidden := in_game and not G.ui_open and not dead and MatchState.phase() != "MatchEnd" and not G.cinematic
	if want_hidden != _mouse_hidden or (want_hidden and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE) or (not want_hidden and Input.mouse_mode == Input.MOUSE_MODE_HIDDEN):
		_mouse_hidden = want_hidden
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if want_hidden else Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	var in_game := _deployed() and not G.menu_open
	var ch: Node = G.local_character() if in_game else null
	var alive := _alive(ch)
	var now := Net.server_time()
	var respawn_at := float(MatchState.my_player("RespawnAt", 0.0))
	var dead := in_game and ((ch != null and not alive) or (ch == null and respawn_at > now))
	_update_mouse(in_game, dead)
	_game.visible = in_game and not G.cinematic
	_cross.visible = in_game and alive and not G.ui_open and not G.cinematic
	if not _game.visible:
		_banner.visible = _banner.visible and in_game
		return
	var phase := MatchState.phase()
	var left := MatchState.time_left()

	# reloj y fase
	var round_n := int(MatchState.get_var("Round", 0))
	if phase == "Waiting":
		_clock.text = "--:--"
		_phase.text = "ESPERANDO"
	else:
		_clock.text = UIKit.format_time(left)
		var blink := phase == "Round" and left <= 30.0 and fmod(left, 1.0) < 0.5
		_clock.color = UIKit.DANGER if blink else UIKit.TEXT
		_phase.text = {"Prep": "INTERLUDIO", "Round": "RONDA %d/3" % round_n,
			"RoundEnd": "FIN DE RONDA", "MatchEnd": "FIN"}.get(phase, phase)
	for team in _plates:
		var p: Dictionary = _plates[team]
		var wins := int(MatchState.get_var("Wins" + team, 0))
		for i in p["pips"].size():
			p["pips"][i].bg = UIKit.team_color(team) if i < wins else UIKit.BLACK
		var prog := float(MatchState.get_var("Progress" + team, 0.0))
		p["ratio"] = lerpf(float(p["ratio"]), prog, minf(1.0, delta * 8.0))
		var fill: Control = p["fill"]
		fill.anchor_left = 1.0 - float(p["ratio"]) if p["left"] else 0.0
		fill.anchor_right = 1.0 if p["left"] else float(p["ratio"])
		if prog > float(p["last"]) + 0.001 and phase == "Round" and floor(prog * 20.0) > floor(float(p["last"]) * 20.0):
			UIKit.pop(p["plate"], 1.04)
		p["last"] = prog
		p["text"].text = _progress_text(team) if phase == "Round" else ""
	var mission := MissionData.get_mission(str(MatchState.get_var("Mission", "")))
	_strip.visible = not mission.is_empty()
	if not mission.is_empty():
		UIKit.set_sprite(_mission_icon, mission["icon"])
		_mission_name.text = ("PRÓXIMA: " if phase == "Prep" else "") + str(mission["name"])
		_mission_desc.text = mission["short"]

	# personaje
	var team := _my_team()
	if ch:
		var cls: String = str(_attr(ch, "Class", MatchState.my_player("Class", Data.DEFAULT_CLASS)))
		var weapon_id: String = str(_attr(ch, "Weapon", Data.get_class_data(cls)["default_weapon"]))
		if _portrait.class_id != cls or _portrait.team != team:
			_portrait.setup(cls, team, "Rifle")
		_class_label.text = UIKit.upper(Data.get_class_data(cls)["display"]) + ("  ·  ¡SOS EL OBJETIVO!" if bool(_attr(ch, "VIP", false)) else "")
		_class_label.color = UIKit.team_color(team)
		var hp := float(_attr(ch, "Health", 100.0))
		var max_hp := maxf(1.0, float(_attr(ch, "MaxHealth", 100.0)))
		var ratio := clampf(hp / max_hp, 0.0, 1.0)
		_hp_fill.anchor_right = ratio
		_health_lag += (ratio - _health_lag) * minf(1.0, delta * 3.0)
		_hp_lag.anchor_right = maxf(ratio, _health_lag)
		_hp_text.text = str(maxi(0, int(ceil(hp))))
		_hp_text.color = UIKit.DANGER if ratio < 0.3 else UIKit.TEXT
		if _last_health >= 0.0 and hp < _last_health - 0.5:
			_damage_flash = clampf((_last_health - hp) / 40.0, 0.25, 0.8)
			UIKit.shake(_hp_panel, 6.0, 0.25)
		_last_health = hp
		_grenades.text = "x%d" % int(_attr(ch, "Grenades", 0))
		var visual: Dictionary = Sprites.weapon_visual(weapon_id)
		UIKit.set_sprite(_weapon_icon, visual["image"], visual.get("tint", Color.WHITE))
		_weapon_name.text = UIKit.upper(UIKit.weapon_display(weapon_id))
		var ammo := int(_attr(ch, "Ammo", 0))
		var max_ammo := maxi(1, int(_attr(ch, "MaxAmmo", 1)))
		if _last_ammo >= 0 and ammo < _last_ammo:
			UIKit.pop(_ammo, 1.12)
		_last_ammo = ammo
		_ammo.text = str(ammo)
		_ammo.color = UIKit.DANGER if float(ammo) / max_ammo < 0.25 else UIKit.TEXT
		_ammo_max.text = "/%d" % max_ammo
		var reloading := bool(_attr(ch, "Reloading", false))
		_reload_text.visible = reloading
		_mag_fill.anchor_right = fmod(Time.get_ticks_msec() / 500.0, 1.0) if reloading else float(ammo) / max_ammo
		_mag_fill.bg = UIKit.KHAKI if reloading else UIKit.ACCENT
	var money := int(MatchState.my_player("Money", 0))
	if _last_money >= 0 and money != _last_money:
		UIKit.pop(_money_panel, 1.08)
	_last_money = money
	_money.text = "$%d" % money
	_war_deaths.text = "GOMITAS DERRETIDAS: %d" % _total_deaths()

	# interludio
	_prep.visible = phase == "Prep"
	_notices.offset_top = (-128.0 - 112.0 if _prep.visible else -128.0) - 160.0
	_notices.offset_bottom = _notices.offset_top + 160.0
	if phase == "Prep":
		_build_btn.set_text("[B] CONSTRUIR (%d)" % int(MatchState.my_player("BlocksLeft", 0)))
		_build_btn.stroke = UIKit.ACCENT if G.build_mode else UIKit.LINE
		var my_cls: String = str(MatchState.my_player("Class", ""))
		for c in _class_btns:
			_class_btns[c].stroke = UIKit.ACCENT if c == my_cls else UIKit.LINE
			_class_btns[c].label.color = UIKit.ACCENT if c == my_cls else UIKit.TEXT
		_ready_btn.set_text("ESPERANDO..." if bool(MatchState.my_player("Ready", false)) else "[F] ¡LISTO!")
		_prep_title.text = "CLICK: poner bloque · CLICK DERECHO: quitar · B: salir" if G.build_mode else "INTERLUDIO · CONSTRUÍ TU BASE Y EQUIPATE"
	_hp_panel.visible = phase != "MatchEnd" and ch != null
	_wp_panel.visible = phase != "MatchEnd" and ch != null

	# muerte
	if dead:
		if not _death.visible:
			_death.visible = true
			_death.color.a = 0.0
		_death.color.a = minf(0.45, _death.color.a + delta)
		if str(_death_info.get("killer", "")) != "":
			_death_sub.text = "%s te eliminó con %s%s" % [_death_info["killer"], _death_info.get("weapon", "?"),
				" (tiro a la cabeza)" if _death_info.get("headshot", false) else ""]
		else:
			_death_sub.text = "Otra gomita derretida por la patria."
		_death_satire.text = _death_info.get("satire", "")
		_death_timer.text = ("Reapareciendo en %d" % maxi(0, int(ceil(respawn_at - now)))) if respawn_at > 0.0 else ""
	else:
		_death.visible = false
		if alive:
			_death_info = {}

	# viñeta
	_damage_flash = maxf(0.0, _damage_flash - delta * 1.8)
	var low := 0.0
	if ch and alive:
		low = clampf(1.0 - float(_attr(ch, "Health", 100.0)) / maxf(1.0, float(_attr(ch, "MaxHealth", 100.0))) * 2.5, 0.0, 1.0)
	var pulse := low * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 6.0))
	_vignette.set_amount(maxf(_damage_flash, pulse * 0.6))

	# mira: 7 + dispersión del arma (y del movimiento) * 1.5
	var gap := 7.0
	if ch:
		var w := Data.get_weapon(str(_attr(ch, "Weapon", "Rifle")))
		gap += float(w.get("spread", 0.0)) * 1.5
		if ch is CharacterBody2D and absf((ch as CharacterBody2D).velocity.x) > 10.0:
			gap += float(w.get("move_spread", 0.0)) * 3.0
	_cross.gap = gap
	_cross.build = G.build_mode
	_cross.pos = _cross.get_local_mouse_position()
	_cross.queue_redraw()


# --- piezas dibujadas (rectángulos planos) ----------------------------

## Fondo del anuncio: rectángulo negro (transp. 0,35) con degradado de transparencia
## 1 -> 0 (20 %) -> 0 (80 %) -> 1 a lo ancho.
class FadeBar extends Control:
	var alpha := 0.65:
		set(v):
			alpha = v
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Color(UIKit.BLACK, alpha)
		var t := Color(UIKit.BLACK, 0.0)
		var xs := [0.0, 0.2, 0.8, 1.0]
		var cs := [t, c, c, t]
		for i in 3:
			var x0: float = xs[i] * size.x
			var x1: float = xs[i + 1] * size.x
			draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, size.y), Vector2(x0, size.y)]),
				PackedColorArray([cs[i], cs[i + 1], cs[i + 1], cs[i]]))


## Viñeta: 4 rectángulos rojos (200,0,0) con degradado de transparencia 0 -> 1 hacia adentro.
class Vignette extends Control:
	var amount := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_amount(a: float) -> void:
		if absf(a - amount) > 0.003 or (a == 0.0 and amount != 0.0):
			amount = a
			queue_redraw()

	func _draw() -> void:
		if amount <= 0.01:
			return
		var c := Color(200 / 255.0, 0, 0, amount)
		var t := Color(200 / 255.0, 0, 0, 0)
		var w := size.x
		var h := size.y
		var ey := h * 0.22
		var ex := w * 0.16
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, ey), Vector2(0, ey)]), PackedColorArray([c, c, t, t]))
		draw_polygon(PackedVector2Array([Vector2(0, h - ey), Vector2(w, h - ey), Vector2(w, h), Vector2(0, h)]), PackedColorArray([t, t, c, c]))
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(ex, 0), Vector2(ex, h), Vector2(0, h)]), PackedColorArray([c, t, t, c]))
		draw_polygon(PackedVector2Array([Vector2(w - ex, 0), Vector2(w, 0), Vector2(w, h), Vector2(w - ex, h)]), PackedColorArray([t, c, c, t]))


## Mira: 4 barras blancas (3x10) con borde negro 1,5, punto central Accent 3x3
## y hitmarker de 4 barras a 45° (10x3 blancas; 14x4 rojas al matar).
class Crosshair extends Control:
	var pos := Vector2.ZERO
	var gap := 7.0
	var build := false
	var _hit_t := 0.0
	var _kill := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func hit(kill: bool) -> void:
		_hit_t = 0.35 if kill else 0.15
		_kill = kill

	func _process(delta: float) -> void:
		_hit_t -= delta

	func _bar(center: Vector2, sz: Vector2, color: Color, stroke: float) -> void:
		var r := Rect2(center - sz * 0.5, sz)
		draw_rect(r.grow(stroke), Color.BLACK)
		draw_rect(r, color)

	func _draw() -> void:
		var col := UIKit.GOOD if build else Color.WHITE
		for d in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
			_bar(pos + d * gap, Vector2(3, 10) if d.x == 0 else Vector2(10, 3), col, 1.5)
		draw_rect(Rect2(pos - Vector2(1.5, 1.5), Vector2(3, 3)), UIKit.ACCENT)
		if _hit_t > 0.0:
			var sz := Vector2(14, 4) if _kill else Vector2(10, 3)
			var hc := UIKit.DANGER if _kill else Color.WHITE
			for a in [45.0, 135.0, 225.0, 315.0]:
				var r := deg_to_rad(a)
				draw_set_transform(pos + Vector2(cos(r), sin(r)) * 13.0, r, Vector2.ONE)
				_bar(Vector2.ZERO, sz, hc, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
