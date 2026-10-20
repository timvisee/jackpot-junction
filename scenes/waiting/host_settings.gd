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
## How wide Done is.
const DONE_WIDTH := 460.0

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
## Whether keys rather than a pad were last in hand, and the mouse or a finger since, for Done's
## bind, see [method _show_bind].
var _keyboard := true
var _pointer := false
## Online, the host's session, whose door the first step sets; null on one machine.
var _session: NetSession
## The step before the match settings, while it is up.
var _lobby: LobbySettings
## Whether the House has set this table, STORY.md 8.1: the rows show it and cannot be changed, a
## stamp says so over them, and none of it is remembered as anybody's choice.
var _by_the_house := false
## The column last opened, which stays open where the screen has room for only one, GAME.md 9.6.
var _last_opened: SettingsFold
## The preset lit when the binds were last drawn, see [method _show_bind].
var _bind_lit := -3


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
	column.add_child(MenuTheme.perforation())
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	column.add_child(_scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 12)
	_scroll.add_child(_rows)
	options = MatchOptions.add_to(_rows, Game.settings)
	options.fold_turned.connect(_on_fold)
	# The two kinds of game are tabs, see [method _tab_of], their keys or buttons on them.
	ButtonBinds.mark(options.mode_picker.button(true), InputActions.MENU_PAGE_PREV)
	ButtonBinds.mark(options.mode_picker.button(false), InputActions.MENU_PAGE_NEXT)
	options.settle_widths()
	_rows.minimum_size_changed.connect(_fit)
	_done = MenuTheme.primary(MenuTheme.button("Done"))
	# As wide as a button is, in the middle: across the whole of a pane this wide, a bar of gold.
	_done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_done.custom_minimum_size.x = DONE_WIDTH
	_done.pressed.connect(close)
	# Back is Done, see [method _input], and its key or button is drawn on it to say so.
	ButtonBinds.mark(_done, &"ui_cancel")
	column.add_child(_done)


func is_open() -> bool:
	return _panel.visible


## Tells a player at a client of a dedicated server, over [param room], that the host's say has
## just come to them, GAME.md 9.3a: handed over [param by] somebody, or the host having left, and
## the choosing is theirs now.
static func tell_new_host(room: Node, by := "") -> void:
	var how := "%s made you the host." % by if not by.is_empty() else "The host left."
	NoticePane.tell(room, "You are the host", how + " You choose the match and who may join now.")


## The pane at its own size where the screen has room for it, GAME.md 9.6. Its two columns stand
## side by side where the screen is wide enough for them and one over the other where it is not,
## and where both are open and too tall for it the one opened first is folded. Where the rest is
## still too tall the rows scroll between the title and Done, which stay put; where it is too wide
## it is shrunk about the middle of the screen. What is shrunk is the holder that centers it: a
## container lays its children out at their own scale every time it sorts them, so the pane itself
## would not stay small.
func _fit() -> void:
	var room := _panel.size - Vector2.ONE * FIT_EDGE * 2.0
	if room.x <= 0.0 or room.y <= 0.0:
		return
	var sides := _pane.get_theme_stylebox(&"panel").get_minimum_size().x
	options.set_wide(room.x - sides >= options.wide_need())
	var around := _pane.get_combined_minimum_size().y - _scroll.custom_minimum_size.y
	_fold_to_fit(room.y - around)
	var rows := _rows.get_combined_minimum_size()
	var tall := clampf(room.y - around, minf(LEAST_ROWS, rows.y), rows.y)
	var wanted := Vector2(rows.x, tall)
	if _scroll.custom_minimum_size != wanted:
		_scroll.custom_minimum_size = wanted
	var need := _pane.get_combined_minimum_size().x
	if need <= 0.0:
		return
	_middle.pivot_offset = _middle.size * 0.5
	_middle.scale = Vector2.ONE * clampf(room.x / need, 0.3, 1.0)


## Folds the column opened first where both are open and their rows are taller than [param tall],
## a phone's screen under a big UI scale, so the one just opened is seen whole as far as it can be.
## Not at the Final Hand, whose columns are the House's to have open.
func _fold_to_fit(tall: float) -> void:
	var both := options.floor_fold.open and options.rules_fold.open
	# Only where the pane is up on the screen it is fitted to, not as it is made at whatever size.
	if not both or options.rules_fold.locked or not _panel.visible:
		return
	if _rows.get_combined_minimum_size().y <= tall:
		return
	var keep := _last_opened if _last_opened != null else options.floor_fold
	var other := options.rules_fold if keep == options.floor_fold else options.floor_fold
	other.open = false


## A column opened or folded by its head, or opened by Custom: the cursor on its first row once it
## is open, the rows dealt in under its head, and the other folded where the two do not fit.
func _on_fold(fold: SettingsFold) -> void:
	if not fold.open:
		return
	_last_opened = fold
	_fit()
	MenuTheme.deal(fold.body)
	var first := fold.first_row()
	if first != null:
		first.grab_focus()


## Up, on the match settings, or with [param lobby_first] on the lobby's settings first when there
## is a hosted game for them to be the settings of.
func open(lobby_first := false) -> void:
	_panel.visible = true
	MenuTheme.deal(_pane)
	_fit_seats()
	options.settle_widths()
	_fit()
	if lobby_first and _session != null and _session.host_controls.mine():
		_show_lobby()
		return
	_to_the_top()


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
	_fit_seats()
	_pane.visible = true
	_to_the_top()


## The cursor on the first of the rows, the top of the pane, rather than on Done, which Back is too,
## its bind drawn on it; on Done where nothing above it can be changed, a table the House set.
func _to_the_top() -> void:
	_keyboard = Game.last_input_keyboard
	_show_bind()
	var first := _first_row(_rows)
	(first if first != null else _done).grab_focus()
	_scroll.scroll_vertical = 0


## The first thing under [param node] that takes the cursor, or null.
static func _first_row(node: Node) -> Control:
	var control := node as Control
	if (
		control != null
		and control.focus_mode == Control.FOCUS_ALL
		and control.is_visible_in_tree()
		and not (control is BaseButton and (control as BaseButton).disabled)
	):
		return control
	for child: Node in node.get_children():
		var found := _first_row(child)
		if found != null:
			return found
	return null


## Done's bind, Back's key or button, drawn on it while keys or a pad are in hand; the tabs' on the
## two kinds of game, see [method _tab_of], and the presets' on the one lit, see [method
## _next_preset].
func _show_bind() -> void:
	var shown := not _pointer
	var picker := options.mode_picker
	var tabs: Array[Button] = [picker.button(true), picker.button(false)]
	ButtonBinds.show([_done], _keyboard, shown)
	ButtonBinds.show(tabs, _keyboard, shown and not picker.locked)
	var bar := options.presets
	var chips := bar.buttons()
	_bind_lit = bar.lit()
	for chip: Button in chips:
		chip.remove_meta(&"bind_action")
	var lit := bar.button(_bind_lit) if _bind_lit >= -1 else null
	if lit != null:
		ButtonBinds.mark(lit, InputActions.MENU_OPTION)
	ButtonBinds.show(chips, _keyboard, shown)


## The binds drawn again when the preset lit changes, a row set to match another say.
func _process(_delta: float) -> void:
	if _panel.visible and options.presets.lit() != _bind_lit:
		_show_bind()


## Which way [param event] goes between the two kinds of game, GAME.md 9.6: a pad's shoulder
## buttons, or Q and E, as they page a dialog, -1 to the Grand Prix on the left and 1 to the quick
## match on the right, or 0 for neither.
func _tab_of(event: InputEvent) -> int:
	if on_lobby():
		return 0
	if event.is_action_pressed(InputActions.MENU_PAGE_PREV):
		return -1
	if event.is_action_pressed(InputActions.MENU_PAGE_NEXT):
		return 1
	return 0


## The presets gone round, GAME.md 9.6, a pad's X or F: the next chip along from the one lit
## pressed, Custom after the four and Standard after Custom. Not at the Final Hand.
func _next_preset() -> void:
	var bar := options.presets
	var next := bar.next_along()
	if next.disabled:
		return
	next.pressed.emit()
	# Custom lights by itself only once the rows match no preset; gone round to, it is lit at once,
	# so the next press goes on to the first.
	if next == bar.button(-1):
		bar.light(-1)
	next.grab_focus()


## The Grand Prix, or the quick match, chosen as a press of its button chooses it, unless it is the
## one chosen already or the House chose; the cursor on it if what had it went with the other.
func _switch_mode(grand_prix: bool) -> void:
	var picker := options.mode_picker
	if picker.locked or picker.grand_prix == grand_prix:
		return
	picker.button(grand_prix).pressed.emit()
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not focused.is_visible_in_tree():
		picker.button(grand_prix).grab_focus()


## The bots on offer, as many as the arena will have seats for, GAME.md 9.3: four on one machine,
## and online as many as the lobby lets play when that is more, which its settings just before may
## have changed.
func _fit_seats() -> void:
	var most := _session.door.max_players if _session != null else SeatLimit.SEATS
	options.fit_seats(SeatLimit.seats_for(most))


## The table the House has set, [param config], shown in the rows and locked under its stamp,
## STORY.md 8.1.
func set_by_the_house(config: MatchConfig) -> void:
	_by_the_house = true
	options.show(config)
	options.lock()
	options.settle_widths()
	options.redact()


## Puts the choices away for next time and says the host is done. Closing is the only way out,
## so there is no choosing that is not kept: the rows are what the host was looking at. A table
## the House set is nobody's choice, and the lobby's remembered ones are left as they were.
func close() -> void:
	if not _panel.visible:
		return
	_show_match()
	_panel.visible = false
	if not _by_the_house:
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
	var keyboard := LicenseView.keyboard_after(event, _keyboard)
	var pointer := ButtonBinds.pointer_after(event, _pointer)
	if keyboard != _keyboard or pointer != _pointer:
		_keyboard = keyboard
		_pointer = pointer
		_show_bind()
	var tab := _tab_of(event)
	if tab != 0:
		_switch_mode(tab < 0)
		get_viewport().set_input_as_handled()
		return
	if not on_lobby() and event.is_action_pressed(InputActions.MENU_OPTION):
		_next_preset()
		get_viewport().set_input_as_handled()
		return
	# Across from one column to the other, to what is level with it, see [method MatchOptions.across].
	var right := event.is_action_pressed(&"ui_right")
	if right or event.is_action_pressed(&"ui_left"):
		var to := options.across(get_viewport().gui_get_focus_owner(), right)
		if to != null:
			to.grab_focus()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed(&"ui_cancel"):
		MenuTheme.back_sound()
		if on_lobby():
			_show_match()
		else:
			close()
		get_viewport().set_input_as_handled()
