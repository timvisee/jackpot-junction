class_name HostSettings
extends CanvasLayer
## The host choosing what the next match is going to be, in the waiting room, GAME.md 9.6: the
## same rows the lobby puts in front of a local match, laid over the room rather than instead of
## it.
##
## Over it, because the room is already open. Friends can join and drive round while the host is
## still choosing, and a host who has made up their mind closes it and drives too. It comes up
## when the room is first opened, since that is when the choosing is done, and again from the
## pause menu for a host who changes their mind.
##
## Hosting a LAN game, the first time it comes up it starts one step earlier, on the lobby's own
## settings, who may come in, see [LobbySettings], since friends are knocking from the moment the
## room is open: Next goes on from there to the match.

## The host has finished choosing. What they chose is in [member options].
signal closed

## How far in from the edges of the screen the pane keeps, when it has to be fitted to it, and
## the least of the rows it shows however short the screen.
const FIT_EDGE := 12.0
const LEAST_ROWS := 160.0

var options: MatchOptions
## Whether this is a room on one machine rather than an online one, which is only a matter of who
## it says can join while the choosing goes on.
var alone := false

var _panel: Control
var _middle: CenterContainer
var _pane: PanelContainer
var _scroll: ScrollContainer
var _rows: VBoxContainer
var _done: Button
## Online, the host's session, whose door the first step sets; null on one machine.
var _session: NetSession
## The step before the match settings, while it is up.
var _lobby: LobbySettings


static func add_to(
	parent: Node, on_one_machine := false, hosting: NetSession = null
) -> HostSettings:
	var pane := HostSettings.new()
	pane._session = hosting
	pane.name = "HostSettings"
	pane.alone = on_one_machine
	parent.add_child(pane)
	return pane


func _ready() -> void:
	# Under the pause menu and over the HUD: it is a menu, but not the one that stops the room.
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = Control.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	# Beside the pane rather than in with it, as the pause menu's is, or the centering would shrink
	# it to nothing. The room carries on under it, so it lets everything through.
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(middle)
	var pane := MenuTheme.pane()
	middle.add_child(pane)
	_pane = pane
	_middle = middle
	# Scrolled on a screen too short for it, a phone's under a big UI scale, GAME.md 8.5, rather
	# than running off the top and the bottom with Done out of reach.
	middle.resized.connect(_fit)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	pane.add_child(column)
	column.add_child(MenuTheme.title("Match settings", 44))
	var joining := (
		"Anybody else here joins with J or Start while you choose."
		if alone
		else "Friends can join and drive while you choose."
	)
	column.add_child(MenuTheme.subtitle(joining, Type.LABEL))
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	column.add_child(_scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 12)
	_scroll.add_child(_rows)
	options = MatchOptions.add_to(_rows, Game.settings)
	_rows.minimum_size_changed.connect(_fit)
	_done = MenuTheme.button("Done")
	_done.pressed.connect(close)
	column.add_child(_done)


func is_open() -> bool:
	return _panel.visible


## The pane at its own size where the screen has room for it. Where it is too tall the rows scroll
## between the title and Done, which stay put; where it is too wide it is shrunk about the middle
## of the screen. What is shrunk is the holder that centers it: a container lays its children out
## at their own scale every time it sorts them, so the pane itself would not stay small.
func _fit() -> void:
	var room := _panel.size - Vector2.ONE * FIT_EDGE * 2.0
	var rows := _rows.get_combined_minimum_size()
	var around := _pane.get_combined_minimum_size().y - _scroll.custom_minimum_size.y
	var tall := clampf(room.y - around, minf(LEAST_ROWS, rows.y), rows.y)
	var wanted := Vector2(rows.x, tall)
	if _scroll.custom_minimum_size != wanted:
		_scroll.custom_minimum_size = wanted
	var need := _pane.get_combined_minimum_size().x
	if need <= 0.0:
		return
	_middle.pivot_offset = _middle.size * 0.5
	_middle.scale = Vector2.ONE * clampf(room.x / need, 0.3, 1.0)


## Up, on the match settings, or with [param lobby_first] on the lobby's settings first when there
## is a hosted game for them to be the settings of.
func open(lobby_first := false) -> void:
	_panel.visible = true
	if lobby_first and _session != null and _session.host_controls.mine():
		_show_lobby()
		return
	_done.grab_focus()


## Whether it is on the step before the match settings.
func on_lobby() -> bool:
	return _lobby != null and _lobby.visible


func _show_lobby() -> void:
	if _lobby == null:
		_lobby = LobbySettings.new()
		_lobby.session = _session
		_lobby.onward = true
		_lobby.closed.connect(_show_match)
		_middle.add_child(_lobby)
	_pane.visible = false
	_lobby.open()


## On from the lobby's settings to the match's.
func _show_match() -> void:
	if _lobby != null:
		_lobby.visible = false
	_pane.visible = true
	_done.grab_focus()


## Puts the choices away for next time and says the host is done. Closing is the only way out,
## so there is no choosing that is not kept: the rows are what the host was looking at.
func close() -> void:
	if not _panel.visible:
		return
	_show_match()
	_panel.visible = false
	options.remember(Game.settings)
	Game.settings.save_to_disk()
	closed.emit()


## Back closes it, or on the lobby's settings goes on to the match's, caught before anything else
## sees it so the pause menu does not open on the same press of Escape; an open list of choices
## is a window of its own and closes itself first. A pad's Start is left alone: it is also how
## somebody new takes a seat, and a friend sitting down should not close the host's menu for them.
func _input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		if on_lobby():
			_show_match()
		else:
			close()
		get_viewport().set_input_as_handled()
