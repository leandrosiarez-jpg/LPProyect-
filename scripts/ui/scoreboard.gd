extends Control
## Parte de guerra (ScoreboardController): mantener TAB. Dos columnas, una por
## equipo, con MatchState.combatants (Name, Kills, Deaths, Headshots, Score).

var _panel: UIKit.Box
var _lists := {}
var _refresh := 0.0


func _ready() -> void:
	UIKit.root(self)
	UIKit.display_order(self, 18)
	_panel = UIKit.panel(UIKit.LINE, 2.0, true, 0.15, self)
	UIKit.at(_panel, Vector2(0.5, 0.5), Vector2.ZERO, Vector2(980, 420))
	UIKit.place(UIKit.label("PARTE DE GUERRA", UIKit.TEXT, UIKit.CENTER, _panel), [0, 20, 0, 12], [1, -40, 0, 40])
	for i in GC.TEAMS.size():
		var team: String = GC.TEAMS[i]
		var info: Dictionary = GC.TEAM_INFO[team]
		var col := UIKit.container(_panel)
		UIKit.place(col, [i * 0.5, 16, 0, 64], [0.5, -24, 1, -80])
		var header := UIKit.frame(Color.WHITE, 0.0, 4.0, col)
		header.gradient = true
		header.grad_top = info["color"]
		header.grad_bottom = info["dark"]
		UIKit.place(header, [0, 0, 0, 0], [1, 0, 0, 36])
		UIKit.place(UIKit.label(info["display"], UIKit.TEXT, UIKit.LEFT, header), [0, 10, 0, 4], [0.46, -10, 1, -8])
		var heads := [[0.46, "K"], [0.58, "M"], [0.70, "HS"], [0.82, "PTS"]]
		for j in heads.size():
			UIKit.place(UIKit.label(heads[j][1], UIKit.TEXT, UIKit.CENTER, header), [heads[j][0], 0, 0, 8], [0.18 if j == 3 else 0.12, 0, 1, -16])
		var list := UIKit.container(col)
		UIKit.place(list, [0, 0, 0, 42], [1, 0, 1, -42])
		_lists[team] = list
	visible = false


func _input(event: InputEvent) -> void:
	if not event.is_action("scoreboard") or event.is_echo():
		return
	if event.is_pressed():
		if G.menu_open or Net.mode == Net.Mode.NONE:
			return
		set_shown(true)
	else:
		set_shown(false)


func set_shown(on: bool) -> void:
	if on == visible:
		return
	visible = on
	if on:
		_rebuild()
		UIKit.pop(_panel, 0.92)


func _process(delta: float) -> void:
	if not visible:
		return
	if G.menu_open:
		visible = false
		return
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = 0.3
		_rebuild()


func _rebuild() -> void:
	for team in _lists:
		for c in _lists[team].get_children():
			c.queue_free()
	var keys: Array = MatchState.combatants.keys()
	keys.sort_custom(func(a, b):
		return int(MatchState.combatants[a].get("Score", 0)) > int(MatchState.combatants[b].get("Score", 0)))
	var me := Net.my_key()
	var count := {}
	for key in keys:
		var c: Dictionary = MatchState.combatants[key]
		var team: String = str(c.get("Team", ""))
		if not _lists.has(team):
			continue
		var n: int = count.get(team, 0)
		count[team] = n + 1
		var is_me: bool = key == me
		var row := UIKit.frame(UIKit.PANEL3 if is_me else UIKit.BLACK, 0.1 if is_me else 0.55, 4.0, _lists[team])
		UIKit.place(row, [0, 0, 0, n * 34], [1, 0, 0, 30])
		var cell := func(x: float, w: float, text: String, align: int, color: Color):
			UIKit.place(UIKit.label(text, color, align, row), [x, 4, 0, 4], [w, -8, 1, -8])
		var name := str(c.get("Name", "?")) + ("  [BOT]" if c.get("IsBot", false) else "")
		cell.call(0.0, 0.46, name, UIKit.LEFT, UIKit.ACCENT if is_me else UIKit.TEXT)
		cell.call(0.46, 0.12, str(int(c.get("Kills", 0))), UIKit.CENTER, UIKit.TEXT)
		cell.call(0.58, 0.12, str(int(c.get("Deaths", 0))), UIKit.CENTER, UIKit.TEXT)
		cell.call(0.70, 0.12, str(int(c.get("Headshots", 0))), UIKit.CENTER, UIKit.TEXT)
		cell.call(0.82, 0.18, str(int(c.get("Score", 0))), UIKit.CENTER, UIKit.ACCENT)
