extends Control
## Menú principal (MenuController): título, elección de bando y de clase, cómo jugar,
## ajustes, créditos y menú de pausa (M / Esc). Agrega lo que Godot necesita para la
## red: jugar solo / alojar / unirse por IP y el nombre del jugador.
## Inicia sesiones con G.main.start_session() y despliega con Net.request("Deploy", [team, class]).

const SETTINGS_PATH := "user://settings.cfg"
const TICKER := "NOTICIAS DEL FRENTE ★ El Pentágono asegura que la guerra terminará en dos semanas (otra vez) ★ Se reporta escasez de azúcar en ambos bandos ★ Una gomita pidió volver a casa: denegado ★ Expertos confirman que las donas explosivas no son un desayuno balanceado ★ La colina sigue sin tener ningún valor estratégico ★"

var _bg: Control
var _bg_img: TextureRect
var _face: TextureRect
var _floaters: Array = []
var _ticker_bar: Control
var _ticker: PixelFont.PixelLabel
var _screens := {}
var _current := ""
var _black: ColorRect
var _msg: Control
var _msg_text: PixelFont.PixelLabel

var _title_gummy: PixelFont.PixelLabel
var _title_wars: PixelFont.PixelLabel
var _name_edit: PixelEdit
var _ip_edit: PixelEdit
var _join_status: PixelFont.PixelLabel
var _host_info: PixelFont.PixelLabel
var _host_info_box: UIKit.Box
var _side_cards := {}
var _class_title: PixelFont.PixelLabel
var _class_previews := {}
var _pause_host: PixelFont.PixelLabel
var _deploy_status: PixelFont.PixelLabel
var _typer: UIKit.Typewriter

var _team := ""
var _starting := false
var _connecting := false
var _deploying := false
var _deploy_t := 0.0
var _prev_deployed := false
var _pause_open := false
var _return_to := "Title"
var _time := 0.0
var _last_ip := ""
var _net_error := ""


func _ready() -> void:
	UIKit.root(self)
	UIKit.display_order(self, 50)
	_load_settings()
	_build_background()
	_build_title()
	_build_join()
	_build_side()
	_build_class()
	_build_help()
	_build_settings()
	_build_credits()
	_build_pause()
	_build_host_info()
	_black = UIKit.rect(Color.BLACK, self)
	UIKit.full(_black)
	_black.visible = false
	_build_message()
	_typer = UIKit.Typewriter.new()
	add_child(_typer)

	Net.connection_state_changed.connect(_on_conn_state)
	G.session_ended.connect(_on_session_ended)
	G.menu_open = true
	show_screen("Title")


# --- ajustes persistentes -------------------------------------------------------

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for k in ["music", "sfx", "shake"]:
		G.settings[k] = float(cfg.get_value("settings", k, G.settings.get(k, 1.0)))
	Net.local_name = str(cfg.get_value("player", "name", Net.local_name))
	_last_ip = str(cfg.get_value("player", "last_ip", ""))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in ["music", "sfx", "shake"]:
		cfg.set_value("settings", k, G.settings.get(k, 1.0))
	cfg.set_value("player", "name", Net.local_name)
	cfg.set_value("player", "last_ip", _ip_edit.text.strip_edges() if _ip_edit else _last_ip)
	cfg.save(SETTINGS_PATH)


func _apply_sound_settings() -> void:
	var snd: Node = G.controller("Sound")
	if snd and snd.has_method("apply_settings"):
		snd.apply_settings()


# --- pantallas ----------------------------------------------------------------

## CanvasGroup a pantalla completa (GroupTransparency -> modulate.a)
func _screen(screen_name: String) -> Control:
	var s := UIKit.container(self)
	UIKit.full(s)
	s.name = screen_name
	s.visible = false
	_screens[screen_name] = s
	return s


func show_screen(screen_name: String) -> void:
	if screen_name == "Class":
		_refresh_class()
	if screen_name == "Side" or screen_name == "Class":
		_deploy_status.text = ""
	if _current == screen_name:
		return
	var old: Control = _screens.get(_current)
	_current = screen_name
	if old:
		var tw_old := old.create_tween()
		tw_old.tween_property(old, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_old.tween_callback(func():
			if _current != old.name:
				old.visible = false)
	var s: Control = _screens.get(screen_name)
	if s:
		s.visible = true
		s.modulate.a = 0.0
		s.scale = Vector2.ONE * 1.04
		var tw := s.create_tween().set_parallel(true)
		tw.tween_property(s, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var deploy_menu := screen_name != "" and not _pause_open
	_bg.visible = deploy_menu
	G.menu_open = deploy_menu
	_host_info_box.visible = Net.mode == Net.Mode.HOST and screen_name in ["Side", "Class"]


func _close_menu() -> void:
	_pause_open = false
	show_screen("")
	_bg.visible = false
	G.menu_open = false
	G.ui_open = false


func _back_button(parent: Control, target: String) -> UIKit.PButton:
	var b := UIKit.button("◄ VOLVER", "Secondary", Color.WHITE, parent)
	UIKit.place(b, [0, 40, 1, -100], [0, 160, 0, 46])
	b.pressed.connect(func(): _go_back(target))
	return b


func _go_back(target: String) -> void:
	if target == "Title" and Net.mode != Net.Mode.NONE:
		_end_session()
		return
	show_screen(target)


## Panel centrado con franja de peligro arriba
func _panel_center(parent: Control, sz: Vector2) -> UIKit.Box:
	var p := UIKit.panel(UIKit.LINE, 2.0, true, 0.15, parent)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.at(p, Vector2(0.5, 0.5), Vector2.ZERO, sz)
	UIKit.place(UIKit.hazard(p), [0, 0, 0, 0], [1, 0, 0, 8])
	return p


func _big_title(parent: Control, text: String) -> PixelFont.PixelLabel:
	var l := UIKit.label(text, UIKit.TEXT, UIKit.CENTER, parent)
	UIKit.place(l, [0.5, 0, 0, 70], [0, 800, 0, 70], Vector2(0.5, 0))
	return l


# --- fondo ----------------------------------------------------------------------

func _build_background() -> void:
	_bg = UIKit.frame(Color8(30, 10, 30), 0.0, 0.0, self)
	UIKit.full(_bg, false)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.clip_contents = true
	_bg_img = UIKit.sprite("Background", Color8(170, 140, 170), "crop", _bg)
	UIKit.place(_bg_img, [-0.05, 0, -0.05, 0], [1.1, 0, 1.1, 0])
	var shade := Shade.new()
	_bg.add_child(shade)
	UIKit.place(shade, [0, 0, 0, 0], [0.62, 0, 1, 0])
	# caramelos flotando
	for i in range(1, 11):
		var img := "DonutPink" if i % 3 == 0 else ("Donut" if i % 3 == 1 else "IcoCoin")
		var d := UIKit.sprite(img, Color(1, 1, 1, 0.65), "fit", _bg)
		var sz := 40.0 + (i % 4) * 14.0
		d.size = Vector2(sz, sz)
		d.pivot_offset = d.size * 0.5
		_floaters.append({"gui": d, "x": randf(), "y": randf(), "speed": 0.02 + randf() * 0.04,
			"spin": (randf() - 0.5) * 60.0, "phase": randf() * 6.0})
	# gomita gigante
	_face = UIKit.sprite("GummyFace", Color.WHITE, "fit", _bg)
	UIKit.place(_face, [0.76, 0, 0.5, 0], [0.42, 0, 0.62, 0], Vector2(0.5, 0.5))
	# cinta de noticias
	_ticker_bar = UIKit.rect(Color(UIKit.BLACK, 0.85), _bg)
	_ticker_bar.clip_contents = true
	UIKit.place(_ticker_bar, [0, 0, 1, 0], [1, 0, 0, 32], Vector2(0, 1))
	UIKit.place(UIKit.hazard(_ticker_bar), [0, 0, 0, 0], [1, 0, 0, 4])
	_ticker = UIKit.label(TICKER, UIKit.KHAKI, UIKit.LEFT, _ticker_bar)
	_ticker.scaled = false
	_ticker.text_size = 18
	_ticker.size = Vector2(2600, 24)
	_ticker.position = Vector2(0, 6)


# --- título -------------------------------------------------------------------

func _build_title() -> void:
	var s := _screen("Title")
	var col := UIKit.container(s)
	UIKit.place(col, [0, 70, 0.5, -250], [0, 560, 0, 520])
	_title_gummy = UIKit.label("GUMMY", Color8(110, 235, 100), UIKit.LEFT, col)
	UIKit.off(_title_gummy, 0, 0, 520, 120)
	_title_wars = UIKit.label("WARS", Color8(255, 80, 70), UIKit.LEFT, col)
	UIKit.off(_title_wars, 60, 100, 460, 120)
	var stamp := UIKit.frame(Color.WHITE, 1.0, 0.0, col)
	stamp.stroke = UIKit.DANGER
	stamp.stroke_width = 3.0
	UIKit.off(stamp, 330, 90, 200, 40)
	stamp.rotation_degrees = -12.0
	UIKit.full(UIKit.label("VIETNAM · 1968", UIKit.DANGER, UIKit.CENTER, stamp))
	UIKit.off(UIKit.label("La guerra nunca fue dulce.", UIKit.KHAKI, UIKit.LEFT, col), 4, 226, 500, 30)

	var y := 280.0
	var play := UIKit.button("JUGAR VS BOTS", "Primary", Color.WHITE, col)
	UIKit.off(play, 0, y, 360, 64)
	play.pressed.connect(func(): _start("offline"))
	y += 76.0
	# Red local: alojar y unirse por IP
	var host := UIKit.button("ALOJAR (LAN)", "Secondary", Color.WHITE, col)
	UIKit.off(host, 0, y, 174, 52)
	host.pressed.connect(func(): _start("host"))
	var join := UIKit.button("UNIRSE (LAN)", "Secondary", Color.WHITE, col)
	UIKit.off(join, 186, y, 174, 52)
	join.pressed.connect(func(): show_screen("Join"))
	y += 64.0
	var help := UIKit.button("CÓMO JUGAR", "Secondary", Color.WHITE, col)
	UIKit.off(help, 0, y, 300, 52)
	help.pressed.connect(func():
		_return_to = "Title"
		show_screen("Help"))
	y += 64.0
	var settings := UIKit.button("AJUSTES", "Secondary", Color.WHITE, col)
	UIKit.off(settings, 0, y, 300, 52)
	settings.pressed.connect(func():
		_return_to = "Title"
		show_screen("Settings"))

	var credits := UIKit.button("CRÉDITOS", "Secondary", Color.WHITE, s)
	UIKit.place(credits, [1, -20, 1, -46], [0, 150, 0, 38], Vector2(1, 1))
	credits.pressed.connect(func():
		_return_to = "Title"
		show_screen("Credits"))
	var quit := UIKit.button("SALIR", "Danger", Color.WHITE, s)
	UIKit.place(quit, [1, -180, 1, -46], [0, 110, 0, 38], Vector2(1, 1))
	quit.pressed.connect(func():
		_save_settings()
		get_tree().quit())


# --- unirse (solo Godot) ------------------------------------------------------

func _build_join() -> void:
	var s := _screen("Join")
	var p := _panel_center(s, Vector2(600, 360))
	UIKit.place(UIKit.label("UNIRSE A PARTIDA", UIKit.TEXT, UIKit.LEFT, p), [0, 24, 0, 20], [1, -48, 0, 50])
	UIKit.off(UIKit.label("IP DEL ANFITRIÓN (misma red local)", UIKit.ACCENT, UIKit.LEFT, p), 28, 84, 540, 24)
	_ip_edit = PixelEdit.new()
	_ip_edit.text = _last_ip
	_ip_edit.placeholder = "192.168.0.10"
	p.add_child(_ip_edit)
	UIKit.off(_ip_edit, 28, 116, 400, 44)
	_ip_edit.text_submitted.connect(func(_t): _join())
	UIKit.off(UIKit.label("UDP %d" % GC.PORT, UIKit.MUTED, UIKit.LEFT, p), 442, 124, 130, 28)
	_join_status = UIKit.label("", UIKit.TEXT, UIKit.LEFT, p)
	_join_status.scaled = false
	_join_status.text_size = 16
	_join_status.wrapped = true
	UIKit.off(_join_status, 28, 170, 544, 56)
	var connect_btn := UIKit.button("CONECTAR", "Primary", Color.WHITE, p)
	UIKit.off(connect_btn, 28, 236, 300, 56)
	connect_btn.pressed.connect(_join)
	var back := UIKit.button("◄ VOLVER", "Secondary", Color.WHITE, p)
	UIKit.off(back, 412, 240, 160, 46)
	back.pressed.connect(func():
		if _connecting:
			_connecting = false
			_end_session()
		show_screen("Title"))
	UIKit.off(UIKit.label("Pedile al anfitrión la IP que le muestra el juego al alojar.", UIKit.MUTED, UIKit.LEFT, p), 28, 310, 544, 20)


func _set_join_status(text: String, color: Color) -> void:
	_join_status.text = text
	_join_status.color = color


func _join() -> void:
	if _connecting:
		return
	var ip := _ip_edit.text.strip_edges()
	if ip == "" or not (ip.is_valid_ip_address() or ip == "localhost"):
		_set_join_status("Dirección inválida. Escribí una IP como 192.168.0.10", UIKit.DANGER)
		UIKit.sfx("Click", 0.0, 0.5)
		return
	_save_settings()
	_connecting = true
	_set_join_status("Conectando a %s:%d..." % [ip, GC.PORT], UIKit.ACCENT)
	var err := _start_session("client", ip)
	if err != "":
		_connecting = false
		_set_join_status(err, UIKit.DANGER)


# --- sesión -------------------------------------------------------------------

func _start_session(mode: String, ip: String = "") -> String:
	_net_error = ""
	_starting = true
	var err: String = G.main.start_session(mode, ip) if G.main else "No hay juego cargado"
	_starting = false
	if err != "" and _net_error != "":
		err = _net_error
	return err


func _start(mode: String) -> void:
	_save_settings()
	var err := _start_session(mode)
	if err != "":
		if mode == "host":
			err += "\n¿Ya hay otra partida alojada en esta PC? (puerto ocupado)"
		_message(err)
		return
	_team = ""
	show_screen("Side")


func _end_session() -> void:
	if G.main:
		G.main.end_session()


func _on_conn_state(state: String, detail: String) -> void:
	match state:
		"error":
			_net_error = detail
			if _connecting:
				_connecting = false
				_set_join_status(detail, UIKit.DANGER)
				call_deferred("_end_session")
		"connecting":
			_set_join_status(detail, UIKit.ACCENT)
		"connected":
			if _connecting:
				_connecting = false
				_set_join_status("Conectado", UIKit.GOOD)
				_team = ""
				show_screen("Side")
		"disconnected":
			_connecting = false
			call_deferred("_end_session")
			_message(detail if detail != "" else "Se perdió la conexión con el anfitrión")


func _on_session_ended() -> void:
	if _starting:
		return
	_deploying = false
	_black.visible = false
	_pause_open = false
	G.ui_open = false
	_prev_deployed = false
	show_screen("Join" if _current == "Join" else "Title")


# --- bando --------------------------------------------------------------------

func _build_side() -> void:
	var s := _screen("Side")
	_big_title(s, "ELEGÍ TU BANDO")
	var row := UIKit.container(s)
	UIKit.place(row, [0.5, 0, 0.55, 0], [0, 860, 0, 470], Vector2(0.5, 0.5))
	for i in GC.TEAMS.size():
		var team: String = GC.TEAMS[i]
		var info: Dictionary = GC.TEAM_INFO[team]
		var color: Color = info["color"]
		var card := UIKit.panel(color, 3.0, true, 0.15, row)
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		UIKit.off(card, i * 450, 0, 410, 470)
		UIKit.place(UIKit.rect(color, card), [0, 0, 0, 0], [1, 0, 0, 10])
		var frame := UIKit.frame(UIKit.BLACK, 0.0, 6.0, card)
		frame.stroke = color
		frame.stroke_width = 3.0
		frame.clip_contents = true
		UIKit.place(frame, [0.5, 0, 0, 26], [0, 170, 0, 170], Vector2(0.5, 0))
		var portrait := TextureRect.new()
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_SCALE
		portrait.texture = UIKit.commander_frame(team, 1)
		frame.add_child(portrait)
		UIKit.full(portrait)
		UIKit.off(UIKit.sprite(Sprites.TEAM_FLAG[team], Color.WHITE, "fit", card), 16, 26, 54, 36)
		UIKit.place(UIKit.label(info["display"], color, UIKit.CENTER, card), [0, 16, 0, 206], [1, -32, 0, 56])
		UIKit.place(UIKit.label(UIKit.upper(info["long"]) + "  ·  " + info["commander"], UIKit.MUTED, UIKit.CENTER, card), [0, 16, 0, 262], [1, -32, 0, 22])
		var quote := UIKit.label("", UIKit.TEXT, UIKit.CENTER, card)
		quote.scaled = false
		quote.text_size = 15
		quote.wrapped = true
		quote.y_align = 0
		UIKit.place(quote, [0, 20, 0, 290], [1, -40, 0, 78])
		var count := UIKit.label("", UIKit.KHAKI, UIKit.CENTER, card)
		UIKit.place(count, [0, 16, 0, 368], [1, -32, 0, 22])
		var join := UIKit.button("UNIRSE A " + info["display"], "Team", color, card)
		UIKit.place(join, [0.5, 0, 1, -16], [0, 300, 0, 58], Vector2(0.5, 1))
		join.pressed.connect(func():
			_team = team
			show_screen("Class"))
		card.mouse_entered.connect(func(): _side_hover(team))
		card.mouse_exited.connect(func(): UIKit.tween_scale(card, 1.0, 0.15))
		_side_cards[team] = {"card": card, "count": count, "quote": quote, "portrait": portrait}
	_back_button(s, "Title")


func _side_hover(team: String) -> void:
	var e: Dictionary = _side_cards[team]
	UIKit.tween_scale(e["card"], 1.03, 0.15)
	_typer.stop()
	_typer.start(e["quote"], e["portrait"], MissionData.get_line(team, "Welcome"), 55.0, team)


func _team_count(team: String) -> Vector2i:
	var humans := 0
	var bots := 0
	for c in MatchState.combatants.values():
		if c.get("Team", "") == team:
			if c.get("IsBot", false):
				bots += 1
			else:
				humans += 1
	return Vector2i(humans, bots)


# --- clase --------------------------------------------------------------------

func _stat_bar(parent: Control, y: float, text: String, value: float) -> void:
	UIKit.off(UIKit.label(text, UIKit.MUTED, UIKit.LEFT, parent), 20, y, 110, 20)
	var back := UIKit.frame(UIKit.BLACK, 0.0, 3.0, parent)
	UIKit.off(back, 130, y + 4, 220, 12)
	var fill := UIKit.frame(UIKit.ACCENT, 0.0, 3.0, back)
	UIKit.place(fill, [0, 0, 0, 0], [clampf(value, 0.05, 1.0), 0, 1, 0])


func _build_class() -> void:
	var s := _screen("Class")
	_class_title = _big_title(s, "ELEGÍ TU CLASE")
	var row := UIKit.container(s)
	UIKit.place(row, [0.5, 0, 0.55, 0], [0, 860, 0, 480], Vector2(0.5, 0.5))
	for i in Data.CLASS_ORDER.size():
		var cls: String = Data.CLASS_ORDER[i]
		var c := Data.get_class_data(cls)
		var w := Data.get_weapon(c["default_weapon"])
		var card := UIKit.panel(UIKit.LINE, 2.0, true, 0.15, row)
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		UIKit.off(card, i * 450, 0, 410, 480)
		var stage := UIKit.frame(UIKit.BLACK, 0.4, 6.0, card)
		stage.clip_contents = true
		UIKit.place(stage, [0.5, 0, 0, 16], [0, 370, 0, 190], Vector2(0.5, 0))
		var preview := UIKit.rig_preview(cls, "USA", "", stage)
		UIKit.place(preview, [0.5, 0, 0.5, 0], [0, 300, 0, 300], Vector2(0.5, 0.5))
		_class_previews[cls] = preview
		UIKit.off(UIKit.label(UIKit.upper(c["display"]), UIKit.TEXT, UIKit.LEFT, card), 20, 214, 250, 44)
		var tag := UIKit.frame(UIKit.ACCENT, 0.0, 4.0, card)
		UIKit.place(tag, [1, -20, 0, 222], [0, 140, 0, 28], Vector2(1, 0))
		UIKit.full(UIKit.label(c["role"], UIKit.BLACK, UIKit.CENTER, tag))
		var desc := UIKit.label(c["description"], UIKit.TEXT, UIKit.LEFT, card)
		desc.scaled = false
		desc.text_size = 16
		desc.wrapped = true
		UIKit.place(desc, [0, 20, 0, 260], [1, -40, 0, 40])
		var dps: float = w["damage"] * w["pellets"] / w["fire_rate"]
		_stat_bar(card, 306, "VIDA", c["max_health"] / 150.0)
		_stat_bar(card, 330, "VELOCIDAD", (c["walk_speed"] - 12.0) / 8.0)
		_stat_bar(card, 354, "ALCANCE", w["range"] / 200.0)
		_stat_bar(card, 378, "DAÑO/SEG", dps / 300.0)
		var deploy := UIKit.button("DESPLEGAR", "Primary", Color.WHITE, card)
		UIKit.place(deploy, [0.5, 0, 1, -16], [0, 300, 0, 58], Vector2(0.5, 1))
		deploy.pressed.connect(func(): _deploy(cls))
		card.mouse_entered.connect(func(): UIKit.tween_scale(card, 1.03, 0.15))
		card.mouse_exited.connect(func(): UIKit.tween_scale(card, 1.0, 0.15))
	_deploy_status = UIKit.label("", UIKit.ACCENT, UIKit.CENTER, s)
	UIKit.place(_deploy_status, [0.5, 0, 1, -60], [0, 600, 0, 22], Vector2(0.5, 1))
	_back_button(s, "Side")


func _refresh_class() -> void:
	var team := _team if _team != "" else "USA"
	for cls in _class_previews:
		_class_previews[cls].setup(cls, team, "")
	_class_title.text = "ELEGÍ TU CLASE · " + UIKit.team_display(team)
	_class_title.color = UIKit.team_color(team)


func _deploy(cls: String) -> void:
	if _deploying:
		return
	if Net.mode == Net.Mode.NONE:
		show_screen("Title")
		return
	if Net.mode == Net.Mode.CLIENT and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		_deploy_status.text = "Todavía no hay conexión con el anfitrión"
		return
	_deploying = true
	_deploy_t = 6.0
	UIKit.sfx("Horn", linear_to_db(0.6))
	_black.visible = true
	_black.modulate.a = 0.0
	var tw := _black.create_tween()
	tw.tween_property(_black, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.05)
	tw.tween_callback(func(): Net.request("Deploy", [_team if _team != "" else "USA", cls]))


func _fade_black_out() -> void:
	if not _black.visible:
		return
	var tw := _black.create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(_black, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _black.visible = false)


# --- ayuda / ajustes / créditos ----------------------------------------------

func _text_panel(screen_name: String, title: String, sections: Array) -> UIKit.Box:
	var s := _screen(screen_name)
	var p := _panel_center(s, Vector2(900, 560))
	UIKit.place(UIKit.label(title, UIKit.TEXT, UIKit.LEFT, p), [0, 24, 0, 20], [1, -48, 0, 50])
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	p.add_child(scroll)
	UIKit.place(scroll, [0, 24, 0, 80], [1, -48, 1, -150])
	var body := UIKit.container()
	scroll.add_child(body)
	var w := 900.0 - 48.0 - 10.0
	var y := 0.0
	for sec in sections:
		var h := UIKit.label(sec[0], UIKit.ACCENT, UIKit.LEFT, body)
		UIKit.off(h, 0, y, w, 28)
		y += 38.0
		var t := UIKit.label(sec[1], UIKit.TEXT, UIKit.LEFT, body)
		t.scaled = false
		t.text_size = 16
		t.wrapped = true
		t.rich = true
		t.y_align = 0
		var th := PixelFont.measure(sec[1], 2.0, w, true).y
		UIKit.off(t, 0, y, w, th)
		y += th + 10.0
	body.custom_minimum_size = Vector2(w, y)
	var back := UIKit.button("◄ VOLVER", "Secondary", Color.WHITE, p)
	UIKit.place(back, [0, 24, 1, -16], [0, 160, 0, 46], Vector2(0, 1))
	back.pressed.connect(func(): show_screen("Pause" if _pause_open else _return_to))
	return p


func _build_help() -> void:
	var missions := []
	for id in GC.MISSIONS:
		var m := MissionData.get_mission(id)
		missions.append("<b>%s</b>: %s" % [m["name"], m["short"]])
	_text_panel("Help", "CÓMO JUGAR", [
		["CONTROLES", "A / D: moverse   ·   ESPACIO / W: saltar   ·   MOUSE: apuntar   ·   CLICK: disparar\nR: recargar   ·   G: dona explosiva (granada)   ·   TAB: parte de guerra   ·   M: menú\nEn el interludio: B construir   ·   T intendencia   ·   1/2 clase   ·   F listo"],
		["LA PARTIDA", "USA contra Vietnam, 4 contra 4 (los bots completan los equipos). Al mejor de 3 rondas de 5 minutos. Antes de cada ronda hay 1 minuto de interludio: construí tu base con bloques de caramelo, comprá armas y equipo, y elegí clase. El comandante te avisa por el intercom cuál es la misión."],
		["MISIONES", "\n".join(missions) + "\nGana el equipo que cumpla el objetivo. Si se acaba el tiempo, gana el que esté más cerca."],
		["COMBATE", "Un tiro en la cabeza es muerte instantánea. Moverte y saltar abre la dispersión: frená para tirar preciso. El lanzallamas quema enemigos y bloques. Las donas explosivas rompen paredes. Cada baja paga azúcar de guerra para la intendencia."],
		["EN RED (LAN)", "Un jugador elige ALOJAR y el juego le muestra su IP. Los demás eligen UNIRSE y escriben esa IP. Se usa el puerto UDP %d: si no conecta, revisá el firewall." % GC.PORT],
	])


func _build_settings() -> void:
	var p := _text_panel("Settings", "AJUSTES", [])
	var y := 90.0
	for def in [["music", "MÚSICA"], ["sfx", "EFECTOS DE SONIDO"], ["shake", "SACUDIDA DE CÁMARA"]]:
		var key: String = def[0]
		UIKit.off(UIKit.label(def[1], UIKit.TEXT, UIKit.LEFT, p), 40, y, 400, 40)
		var on := float(G.settings.get(key, 1.0)) > 0.0
		var b := UIKit.button("SÍ" if on else "NO", "Secondary", Color.WHITE, p)
		UIKit.off(b, 460, y, 160, 44)
		b.pressed.connect(func():
			var now_on := not (float(G.settings.get(key, 1.0)) > 0.0)
			G.settings[key] = 1.0 if now_on else 0.0
			b.set_text("SÍ" if now_on else "NO")
			_apply_sound_settings()
			_save_settings())
		y += 64.0
	# nombre del jugador
	UIKit.off(UIKit.label("NOMBRE", UIKit.TEXT, UIKit.LEFT, p), 40, y, 400, 40)
	_name_edit = PixelEdit.new()
	_name_edit.text = Net.local_name
	_name_edit.max_length = 16
	_name_edit.placeholder = "Tu nombre de gomita"
	p.add_child(_name_edit)
	UIKit.off(_name_edit, 460, y, 300, 44)
	_name_edit.text_changed.connect(func(t: String):
		var n := t.strip_edges()
		Net.local_name = n if n != "" else "Gomita"
		_save_settings())


func _build_credits() -> void:
	_text_panel("Credits", "CRÉDITOS", [
		["GUMMY WARS", "Una parodia de la guerra de Vietnam con gomitas. Sprites y arte: equipo GummyWars (GummyWars.aseprite)."],
		["SONIDO", "Efectos de sonido sintetizados por el propio juego."],
		["MENSAJE", "Ningún bando sale entero de una guerra. Ni siquiera los de caramelo."],
	])


# --- pausa --------------------------------------------------------------------

func _build_pause() -> void:
	var s := _screen("Pause")
	var dim := UIKit.rect(Color(UIKit.BLACK, 0.55), s)
	UIKit.full(dim, false)
	var p := UIKit.panel(UIKit.LINE, 2.0, true, 0.15, s)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.at(p, Vector2(0.5, 0.5), Vector2.ZERO, Vector2(420, 420))
	UIKit.place(UIKit.label("PAUSA", UIKit.TEXT, UIKit.CENTER, p), [0, 20, 0, 18], [1, -40, 0, 54])
	var y := 90.0
	var entries := [
		["CONTINUAR", "Primary", close_pause],
		["CAMBIAR DE BANDO", "Secondary", func():
			Net.request("ReturnToMenu", [])
			_pause_open = false
			G.ui_open = false
			_team = ""
			show_screen("Side")],
		["CÓMO JUGAR", "Secondary", func(): show_screen("Help")],
		["SALIR AL MENÚ", "Danger", func():
			_pause_open = false
			_end_session()],
	]
	for e in entries:
		var b := UIKit.button(e[0], e[1], Color.WHITE, p)
		UIKit.place(b, [0.5, 0, 0, y], [0, 340, 0, 52], Vector2(0.5, 0))
		b.pressed.connect(e[2])
		y += 64.0
	_pause_host = UIKit.label("", UIKit.KHAKI, UIKit.CENTER, p)
	_pause_host.scaled = false
	_pause_host.text_size = 8
	_pause_host.wrapped = true
	UIKit.place(_pause_host, [0, 20, 0, 352], [1, -40, 0, 56])


func _build_host_info() -> void:
	_host_info_box = UIKit.panel(UIKit.ACCENT, 2.0, false, 0.15, self)
	UIKit.at(_host_info_box, Vector2(1, 0), Vector2(-16, 16), Vector2(320, 84))
	_host_info = UIKit.label("", UIKit.TEXT, UIKit.LEFT, _host_info_box)
	_host_info.scaled = false
	_host_info.text_size = 8
	_host_info.wrapped = true
	UIKit.off(_host_info, 12, 8, 296, 68)
	_host_info_box.visible = false


static func local_ipv4() -> Array:
	var out := []
	for a in IP.get_local_addresses():
		var s: String = a
		if ":" in s or not s.is_valid_ip_address():
			continue
		if s.begins_with("127.") or s.begins_with("169.254.") or s == "0.0.0.0":
			continue
		out.append(s)
	return out


func _host_text() -> String:
	var ips := local_ipv4()
	var peers := multiplayer.get_peers().size() if Net.mode == Net.Mode.HOST else 0
	return "PARTIDA ALOJADA · UDP %d\nTu IP: %s\nParticipantes conectados: %d" % [
		GC.PORT, " · ".join(ips) if not ips.is_empty() else "(sin red local)", peers]


func open_pause() -> void:
	if not bool(MatchState.my_player("Deployed", false)):
		return
	_pause_open = true
	G.ui_open = true
	_current = ""
	show_screen("Pause")
	G.menu_open = false


func close_pause() -> void:
	_pause_open = false
	G.ui_open = false
	show_screen("")
	G.menu_open = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_menu") or event.is_echo():
		return
	if Net.mode == Net.Mode.NONE or not bool(MatchState.my_player("Deployed", false)):
		return
	if _pause_open:
		if _current == "Pause":
			close_pause()
		else:
			show_screen("Pause")
		get_viewport().set_input_as_handled()
	elif not G.menu_open and not G.ui_open:
		open_pause()
		get_viewport().set_input_as_handled()


# --- mensaje de error (solo Godot) ---------------------------------------------

func _build_message() -> void:
	_msg = UIKit.container(self)
	UIKit.full(_msg)
	var dim := UIKit.rect(Color(UIKit.BLACK, 0.55), _msg)
	UIKit.full(dim, false)
	var p := _panel_center(_msg, Vector2(520, 220))
	UIKit.place(UIKit.label("¡ATENCIÓN!", UIKit.DANGER, UIKit.CENTER, p), [0, 20, 0, 20], [1, -40, 0, 44])
	_msg_text = UIKit.label("", UIKit.TEXT, UIKit.CENTER, p)
	_msg_text.scaled = false
	_msg_text.text_size = 16
	_msg_text.wrapped = true
	UIKit.place(_msg_text, [0, 24, 0, 70], [1, -48, 0, 70])
	var ok := UIKit.button("ENTENDIDO", "Primary", Color.WHITE, p)
	UIKit.place(ok, [0.5, 0, 1, -16], [0, 220, 0, 48], Vector2(0.5, 1))
	ok.pressed.connect(func(): _msg.visible = false)
	_msg.visible = false


func _message(text: String) -> void:
	_msg_text.text = text
	_msg.visible = true
	UIKit.sfx("Click", 0.0, 0.5)


# --- animación y estado -------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	var deployed := Net.mode != Net.Mode.NONE and bool(MatchState.my_player("Deployed", false))
	if deployed and not _prev_deployed:
		_deploying = false
		if not _pause_open:
			_close_menu()
		_fade_black_out()
	elif not deployed and _prev_deployed and Net.mode != Net.Mode.NONE:
		_pause_open = false
		G.ui_open = false
		if _current == "" or _current == "Pause":
			_team = ""
			show_screen("Side")
	_prev_deployed = deployed
	if _deploying:
		_deploy_t -= delta
		if _deploy_t <= 0.0:
			_deploying = false
			_deploy_status.text = "El servidor no respondió al despliegue. Probá de nuevo."
			_fade_black_out()

	if _bg.visible:
		var m := get_local_mouse_position() / size - Vector2(0.5, 0.5) if size.x > 0.0 else Vector2.ZERO
		_bg_img.anchor_left = -0.05 - m.x * 0.02
		_bg_img.anchor_right = _bg_img.anchor_left + 1.1
		_bg_img.anchor_top = -0.05 - m.y * 0.02
		_bg_img.anchor_bottom = _bg_img.anchor_top + 1.1
		var fx := 0.76 + m.x * 0.03
		var fy := 0.5 + sin(_time * 1.3) * 0.02 + m.y * 0.03
		_face.anchor_left = fx - 0.21
		_face.anchor_right = fx + 0.21
		_face.anchor_top = fy - 0.31
		_face.anchor_bottom = fy + 0.31
		_face.rotation_degrees = sin(_time * 0.9) * 6.0
		for f in _floaters:
			f["y"] -= f["speed"] * delta
			if f["y"] < -0.1:
				f["y"] = 1.1
				f["x"] = randf()
			var g: TextureRect = f["gui"]
			g.position = Vector2((f["x"] + sin(_time + f["phase"]) * 0.02) * size.x, f["y"] * size.y) - g.size * 0.5
			g.rotation_degrees += f["spin"] * delta
		_ticker.position.x -= delta * 70.0
		if _ticker.position.x < -2600.0:
			_ticker.position.x = size.x
	if _current == "Title":
		_title_gummy.rotation_degrees = sin(_time * 2.0) * 2.5
		_title_wars.rotation_degrees = sin(_time * 2.0 + 1.4) * -3.0
		_title_wars.position.y = 100.0 + sin(_time * 3.0) * 3.0
	elif _current == "Side":
		for team in _side_cards:
			var n := _team_count(team)
			_side_cards[team]["count"].text = "%d JUGADORES · %d BOTS" % [n.x, n.y]
	if _host_info_box.visible:
		_host_info.text = _host_text()
	if _current == "Pause":
		_pause_host.text = _host_text() if Net.mode == Net.Mode.HOST else ""


# --- piezas -------------------------------------------------------------------

## Sombra del lado del menú: rectángulo (10,6,12) con transparencia 0,1 -> 0,45 (70 %) -> 1.
class Shade extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var base := Color8(10, 6, 12)
		var xs := [0.0, 0.7, 1.0]
		var al := [0.9, 0.55, 0.0]
		for i in 2:
			var x0: float = xs[i] * size.x
			var x1: float = xs[i + 1] * size.x
			var c0 := Color(base, al[i])
			var c1 := Color(base, al[i + 1])
			draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, size.y), Vector2(x0, size.y)]),
				PackedColorArray([c0, c1, c1, c0]))


## Campo de texto (solo Godot) que muestra lo escrito con la tipografía pixel.
class PixelEdit extends LineEdit:
	var placeholder := ""
	var _box: UIKit.Box
	var _shown: PixelFont.PixelLabel
	var _blink := 0.0

	func _init() -> void:
		focus_mode = Control.FOCUS_CLICK
		context_menu_enabled = false
		add_theme_color_override("font_color", Color(0, 0, 0, 0))
		add_theme_color_override("font_placeholder_color", Color(0, 0, 0, 0))
		add_theme_color_override("caret_color", Color(0, 0, 0, 0))
		add_theme_color_override("selection_color", Color(0, 0, 0, 0))
		add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		add_theme_stylebox_override("read_only", StyleBoxEmpty.new())
		_box = UIKit.frame(UIKit.BLACK, 0.3, 6.0, self)
		_box.stroke = UIKit.LINE
		_box.stroke_width = 2.0
		_box.show_behind_parent = true
		UIKit.full(_box)
		_shown = UIKit.label("", UIKit.TEXT, UIKit.LEFT, self)
		UIKit.place(_shown, [0, 10, 0, 6], [1, -20, 1, -12])

	func _process(delta: float) -> void:
		_blink += delta
		var focused := has_focus()
		_box.stroke = UIKit.ACCENT if focused else UIKit.LINE
		if text == "" and not focused:
			_shown.text = placeholder
			_shown.color = UIKit.MUTED
		else:
			_shown.text = text + ("_" if focused and fmod(_blink, 1.0) < 0.5 else "")
			_shown.color = UIKit.TEXT
