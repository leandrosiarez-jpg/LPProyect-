extends Control
## Fin de partida (panel ui.MatchEnd de HUDController): quién ganó la guerra, el
## marcador de rondas, el MVP, una cita y la cuenta regresiva a la nueva partida.
## Escucha el evento Round kind "MatchEnd" {winner, mvp_name, mvp_team, mvp_kills, finale}.

const QUOTES := [
	"La guerra nunca fue dulce.",
	"Nadie gana una guerra. Algunos pierden menos.",
	"Ellos también tenían madre. Y eran de gomita.",
	"Mañana los libros dirán que fue necesario.",
]

var _panel: UIKit.Box
var _title: PixelFont.PixelLabel
var _score: PixelFont.PixelLabel
var _mvp: PixelFont.PixelLabel
var _quote: PixelFont.PixelLabel
var _next: PixelFont.PixelLabel


func _ready() -> void:
	UIKit.root(self)
	UIKit.display_order(self, 30)
	_panel = UIKit.panel(UIKit.LINE, 2.0, true, 0.15, self)
	UIKit.at(_panel, Vector2(0.5, 0.5), Vector2.ZERO, Vector2(720, 340))
	UIKit.place(UIKit.hazard(_panel), [0, 0, 0, 0], [1, 0, 0, 8])
	_title = UIKit.label("", UIKit.TEXT, UIKit.CENTER, _panel)
	UIKit.place(_title, [0, 20, 0, 26], [1, -40, 0, 70])
	_score = UIKit.label("", UIKit.TEXT, UIKit.CENTER, _panel)
	UIKit.place(_score, [0, 20, 0, 104], [1, -40, 0, 44])
	_mvp = UIKit.label("", UIKit.ACCENT, UIKit.CENTER, _panel)
	UIKit.place(_mvp, [0, 20, 0, 160], [1, -40, 0, 30])
	_quote = UIKit.label("", UIKit.MUTED, UIKit.CENTER, _panel)
	_quote.wrapped = true
	UIKit.place(_quote, [0, 40, 0, 210], [1, -80, 0, 50])
	_next = UIKit.label("", UIKit.TEXT, UIKit.CENTER, _panel)
	UIKit.place(_next, [0, 20, 0, 280], [1, -40, 0, 30])
	visible = false
	Net.event_received.connect(_on_event)
	G.session_ended.connect(func(): visible = false)
	MatchState.var_changed.connect(func(key: String, value):
		if key == "Phase" and value != "MatchEnd":
			visible = false)


func _on_event(event: String, data) -> void:
	if event == "Round" and data is Dictionary and data.get("kind", "") == "MatchEnd":
		show_results(data)


func show_results(data: Dictionary) -> void:
	var winner: String = str(data.get("winner", "")) if data.get("winner") != null else ""
	if GC.TEAM_INFO.has(winner):
		_title.text = UIKit.team_display(winner) + " GANA LA GUERRA"
		_title.color = UIKit.team_color(winner)
		if winner == str(MatchState.my_player("Team", "")):
			UIKit.sfx("Victory")
	else:
		_title.text = "EMPATE"
		_title.color = UIKit.KHAKI
	_score.text = "USA  %d  —  %d  VIETNAM" % [int(MatchState.get_var("WinsUSA", 0)), int(MatchState.get_var("WinsVietnam", 0))]
	var mvp_name: String = str(data.get("mvp_name", "")) if data.get("mvp_name") != null else ""
	_mvp.text = ("★ MVP: %s (%d bajas) ★" % [mvp_name, int(data.get("mvp_kills", 0))]) if mvp_name != "" else ""
	var mvp_team: String = str(data.get("mvp_team", ""))
	_mvp.color = UIKit.team_color(mvp_team) if GC.TEAM_INFO.has(mvp_team) else UIKit.ACCENT
	_quote.text = "\"" + QUOTES[randi() % QUOTES.size()] + "\""
	visible = true
	UIKit.pop(_panel, 0.7)


func _process(_delta: float) -> void:
	if not visible:
		return
	if G.menu_open and not bool(MatchState.my_player("Deployed", false)):
		visible = false
		return
	if MatchState.phase() == "MatchEnd":
		_next.text = "Nueva partida en %d..." % maxi(0, int(ceil(MatchState.time_left())))
