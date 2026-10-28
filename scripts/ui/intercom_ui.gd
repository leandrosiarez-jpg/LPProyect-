extends Control
## Intercom del comandante (IntercomController): retrato con los 3 frames reales
## (Sprites.COMMANDERS), texto tipo máquina de escribir, estática de radio,
## líneas de escaneo y "voz" de bips. Escucha el evento de red Intercom {team, key}
## y busca la línea en MissionData.

const SHOWN_X := 16.0
const HIDDEN_X := -520.0
## Debajo de la franja de misión
const TOP := 220.0

var _panel: UIKit.Box
var _portrait: TextureRect
var _static: ColorRect
var _name: PixelFont.PixelLabel
var _text: PixelFont.PixelLabel
var _dot: UIKit.Box
var _typer: UIKit.Typewriter
var _queue: Array = []
var _busy := false
var _hold := 0.0
var _state := "idle"   # idle | in | talk | hold | out
var _tick := 0.0
var _clock := 0.0


func _ready() -> void:
	UIKit.root(self)
	UIKit.display_order(self, 12)
	_panel = UIKit.panel(UIKit.LINE, 2.0, true, 0.15, self)
	UIKit.off(_panel, HIDDEN_X, TOP, 470, 132)
	_panel.visible = false

	var frame := UIKit.frame(UIKit.BLACK, 0.0, 4.0, _panel)
	frame.stroke = UIKit.LINE
	frame.stroke_width = 2.0
	frame.stroke_alpha = 0.7
	frame.clip_contents = true
	UIKit.off(frame, 10, 10, 112, 112)
	_portrait = TextureRect.new()
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait.texture = UIKit.commander_frame("USA", 1)
	frame.add_child(_portrait)
	UIKit.off(_portrait, 0, 0, 112, 112)
	# líneas de escaneo CRT
	for i in 28:
		var line := UIKit.rect(Color(0, 0, 0, 0.25), frame)
		UIKit.off(line, 0, i * 4, 112, 1)
	_static = UIKit.rect(Color(200 / 255.0, 1, 200 / 255.0, 0.08), frame)
	UIKit.full(_static)

	_dot = UIKit.frame(UIKit.DANGER, 0.0, 5.0, _panel)
	UIKit.off(_dot, 136, 14, 10, 10)
	UIKit.off(UIKit.label("TRANSMISIÓN", UIKit.DANGER, UIKit.LEFT, _panel), 152, 10, 120, 18)
	_name = UIKit.label("", UIKit.TEXT, UIKit.LEFT, _panel)
	UIKit.off(_name, 136, 30, 320, 24)
	_text = UIKit.label("", UIKit.TEXT, UIKit.LEFT, _panel)
	_text.scaled = false
	_text.text_size = 17
	_text.wrapped = true
	_text.y_align = 0
	UIKit.off(_text, 136, 56, 322, 68)

	_typer = UIKit.Typewriter.new()
	add_child(_typer)
	_typer.finished.connect(_on_typed)

	Net.event_received.connect(_on_event)
	G.session_ended.connect(_clear)


func _on_event(event: String, data) -> void:
	if event != "Intercom" or not (data is Dictionary):
		return
	var team: String = str(data.get("team", ""))
	var key: String = str(data.get("key", ""))
	say(team, MissionData.get_line(team, key))


## Encola una línea (máximo 2 en espera).
func say(team: String, text: String) -> void:
	if text == "":
		return
	if _queue.size() >= 2:
		_queue.pop_front()
	_queue.append({"team": team, "text": text})
	if not _busy:
		_next()


func _radio_loop(on: bool) -> void:
	var snd: Node = G.controller("Sound")
	if snd and snd.has_method("set_loop"):
		snd.set_loop("intercom", "Radio", on)


func _clear() -> void:
	_queue.clear()
	_typer.stop()
	_radio_loop(false)
	_busy = false
	_state = "idle"
	_panel.visible = false
	_panel.position.x = HIDDEN_X


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var item: Dictionary = _queue.pop_front()
	var team: String = item["team"]
	var info: Dictionary = GC.TEAM_INFO.get(team, {})
	_name.text = info.get("commander", "COMANDO")
	_name.color = info.get("color", UIKit.ACCENT)
	_panel.stroke = info.get("color", UIKit.LINE)
	_portrait.texture = UIKit.commander_frame(team, 1)
	_text.text = ""
	_panel.visible = true
	UIKit.sfx("Squelch")
	_radio_loop(true)
	_state = "in"
	var tw := create_tween()
	tw.tween_property(_panel, "position:x", SHOWN_X, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.3)
	tw.tween_callback(func():
		if _state == "in":
			_state = "talk"
			_typer.start(_text, _portrait, item["text"], 42.0, team))


func _on_typed() -> void:
	if _state != "talk":
		return
	_radio_loop(false)
	_state = "hold"
	_hold = 2.2 + _text.text.to_utf8_buffer().size() * 0.02


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	_clock += delta
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.08
		_dot.bg_alpha = 1.0 if fmod(_clock, 1.0) < 0.5 else 0.3
		_static.color.a = 1.0 - (0.86 + randf() * 0.12)
		_portrait.position.x = float(randi_range(-2, 2)) if randf() < 0.1 else 0.0
	if _state == "hold":
		_hold -= delta
		if _hold <= 0.0:
			_state = "out"
			UIKit.sfx("Squelch", linear_to_db(0.6))
			var tw := create_tween()
			tw.tween_property(_panel, "position:x", HIDDEN_X, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_interval(0.02)
			tw.tween_callback(func():
				if _state == "out":
					_state = "idle"
					_panel.visible = false
					_next())
