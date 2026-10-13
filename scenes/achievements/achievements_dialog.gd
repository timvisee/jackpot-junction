class_name AchievementsDialog
extends CanvasLayer
## The achievements of GAME.md 8.10 for the profile playing: a large dialog over whatever screen
## opens it, as the catalog of 8.8 is, on a layer of its own, filling the screen on a short one. Its
## head says how many of how many are earned, a gold tick once all of them are, and carries the
## switch Sort, In order, Earned or To do, which the machine remembers. The well under it is a
## collector's case lined in the felt's green, a row each, see [AchievementRow], under the groups'
## headings in order; the hidden ones last in every order. Read only, but for the NEW tags, which
## go as the cursor comes to them and are kept gone as the dialog is put away.

## Put away, the cursor back where it was.
signal put_away

## The orders the list can be in, see [constant ORDERS] for what the switch says of each.
enum Order { IN_ORDER, EARNED, TO_DO }

const LAYER := CatalogDialog.LAYER
const TITLE := "Achievements"
const COUNT := "%d / %d"
const ORDERS: Array[String] = ["In order", "Earned", "To do"]
const SORT := "Sort: %s"
const SORT_ACTION := InputActions.DETAILS
## Each group's heading, in the list's order, see [enum Achievement.Group].
const HEADINGS: Array[String] = [
	"Getting started",
	"Winning",
	"The tables",
	"Fighting",
	"The hand",
	"Company",
	"The Clubhouse",
	"The story",
]
## The felt lining the case, and the room round the rows in it and between them.
const LINING := Palette.FELT
const LINING_LOW := Color("#244a37")
const AROUND := 10
const BETWEEN := 4
## How fast a pad's right stick scrolls the case, at its full push, in pixels a second.
const STICK_SCROLL := 1400.0
## The case's stitching round its lining, its brass corners, and the flecks of the felt.
const STITCH := Color(0.55, 0.72, 0.6, 0.45)
const STITCH_IN := 5.0
const BRASS := HouseTheme.FOIL_LOW
const CORNER := 22.0
const FLECKS := 260


## The collector's case the rows lie in: felt with its nap flecked, stitched round inside its edge,
## brass over its corners.
class Case:
	extends PanelContainer

	var _flecks := PackedVector3Array()

	func _ready() -> void:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var dice := RandomNumberGenerator.new()
		dice.seed = 81
		for i: int in AchievementsDialog.FLECKS:
			_flecks.append(Vector3(dice.randf(), dice.randf(), 1.0 if i % 3 == 0 else -1.0))
		resized.connect(queue_redraw)

	func _draw() -> void:
		var whole := Rect2(Vector2.ZERO, size)
		draw_rect(whole, AchievementsDialog.LINING)
		var light := Color(AchievementsDialog.LINING.lightened(0.25), 0.25)
		var dark := Color(AchievementsDialog.LINING_LOW.darkened(0.3), 0.3)
		for fleck: Vector3 in _flecks:
			var at := Vector2(fleck.x * size.x, fleck.y * size.y)
			draw_circle(at, 1.1, light if fleck.z > 0.0 else dark)
		var stitched := whole.grow(-AchievementsDialog.STITCH_IN)
		var corners := [
			stitched.position,
			Vector2(stitched.end.x, stitched.position.y),
			stitched.end,
			Vector2(stitched.position.x, stitched.end.y),
		]
		for i: int in 4:
			draw_dashed_line(corners[i], corners[(i + 1) % 4], AchievementsDialog.STITCH, 1.5, 6.0)
		var reach := AchievementsDialog.CORNER
		for corner: Vector2 in [Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]:
			var inward := Vector2(
				1.0 if corner.x == 0.0 else -1.0, 1.0 if corner.y == 0.0 else -1.0
			)
			draw_colored_polygon(
				PackedVector2Array(
					[
						corner,
						corner + Vector2(inward.x * reach, 0.0),
						corner + Vector2(0.0, inward.y * reach)
					]
				),
				AchievementsDialog.BRASS
			)
			draw_circle(corner + inward * reach * 0.28, 2.0, HouseTheme.ON_FOIL)


var back: Button
var sort: Button
var count: Label
var list: VBoxContainer
var scroll: ScrollContainer

var _settings: Settings
var _root: Control
var _shade: ColorRect
var _around: MarginContainer
var _pane: PanelContainer
var _head: HBoxContainer
var _title: Label
var _foot_row: HBoxContainer
var _sort_hint: Control
var _from: Control
var _looked := false
var _closing := false
var _keyboard := true
var _pointer := false


## The achievements over [param parent], for the profile playing, the cursor on the first row.
static func open(parent: Node) -> AchievementsDialog:
	var dialog := AchievementsDialog.new()
	dialog.name = "Achievements"
	if parent.is_inside_tree():
		dialog._from = parent.get_viewport().gui_get_focus_owner()
	parent.add_child(dialog)
	return dialog


## Every achievement in [param order] for [param profile], GAME.md 8.10: in the list's own order;
## those earned first, the latest of them first; or those not earned yet first, the nearest done
## at the top; and in every order the hidden ones not earned yet last.
static func ordered(profile: Profile, order: Order) -> Array[Achievement]:
	var listed := Achievements.all().duplicate()
	var place := {}
	for i: int in listed.size():
		place[listed[i].id] = i
	var state := profile.achievements
	var key := func(shown: Achievement) -> Array:
		var earned := state.has(shown.id)
		var hidden := shown.hidden and not earned
		match order:
			Order.EARNED:
				return [
					1 if hidden else 0, 0 if earned else 1, -state.when(shown.id), place[shown.id]
				]
			Order.TO_DO:
				var come := Achievements.progress(profile, shown)
				var share := float(come.x) / float(come.y) if come.y > 0 else 0.0
				return [1 if hidden else 0, 1 if earned else 0, -share, place[shown.id]]
		return [1 if hidden else 0, 0, 0, place[shown.id]]
	listed.sort_custom(
		func(a: Achievement, b: Achievement) -> bool:
			var left: Array = key.call(a)
			var right: Array = key.call(b)
			for i: int in left.size():
				if left[i] != right[i]:
					return left[i] < right[i]
			return false
	)
	var shown: Array[Achievement] = []
	shown.assign(listed)
	return shown


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings = Game.settings
	_keyboard = Game.last_input_keyboard
	_pointer = Game.last_input_pointer
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = CatalogDialog.SHADE
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.gui_input.connect(_on_shade_input)
	_root.add_child(_shade)
	_around = MarginContainer.new()
	_around.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_around.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_around)
	_pane = MenuTheme.pane()
	_pane.name = "Pane"
	_pane.mouse_filter = Control.MOUSE_FILTER_STOP
	_around.add_child(_pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_pane.add_child(column)
	column.add_child(_make_head())
	column.add_child(_make_case())
	_foot_row = HBoxContainer.new()
	_foot_row.name = "Foot"
	column.add_child(_foot_row)
	var room := Control.new()
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_foot_row.add_child(room)
	back = MenuTheme.button("Back")
	back.name = "Back"
	back.custom_minimum_size.x = 200.0
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	_foot_row.add_child(back)
	fill()
	_root.resized.connect(_fit)
	_fit()
	_show_binds()
	MenuTheme.deal(_pane)
	_focus_first.call_deferred()


func _exit_tree() -> void:
	_keep_looks()


## The head: the title, how many are earned of how many with a gold tick once all are, and the
## switch with its bind.
func _make_head() -> HBoxContainer:
	_head = HBoxContainer.new()
	_head.name = "Head"
	_head.add_theme_constant_override("separation", 20)
	_title = MenuTheme.title(TITLE, Type.TITLE)
	_head.add_child(_title)
	count = Label.new()
	count.name = "Count"
	Type.numbers(count, Type.LARGE, HouseTheme.FOIL)
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_head.add_child(count)
	var room := Control.new()
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_head.add_child(room)
	_sort_hint = Control.new()
	_head.add_child(_sort_hint)
	sort = MenuTheme.button("", Type.BODY)
	sort.name = "Sort"
	sort.focus_mode = Control.FOCUS_NONE
	sort.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sort.pressed.connect(step_order)
	_head.add_child(sort)
	return _head


## The well, a case lined in felt, its rows scrolling where there are more than it has room for.
func _make_case() -> Control:
	var well := ListBox.Well.new()
	well.name = "Well"
	well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lining := Case.new()
	lining.name = "Lining"
	well.add_child(lining)
	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	lining.add_child(scroll)
	TouchScroll.attach(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, AROUND)
	scroll.add_child(margin)
	list = VBoxContainer.new()
	list.name = "List"
	list.add_theme_constant_override("separation", BETWEEN)
	margin.add_child(list)
	return well


## The rows in the order the switch says, under the groups' headings in order, the count and the
## switch as they now are.
func fill() -> void:
	var order := clampi(_settings.achievement_order, 0, ORDERS.size() - 1) as Order
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var profile := _settings.profile
	var group := -1
	for shown: Achievement in ordered(profile, order):
		if order == Order.IN_ORDER and shown.group != group:
			group = shown.group
			list.add_child(_heading(HEADINGS[clampi(group, 0, HEADINGS.size() - 1)]))
		var row := AchievementRow.of(shown, profile)
		row.looked_at.connect(_on_looked_at)
		list.add_child(row)
	var earned := Achievements.earned_count(profile)
	var every := Achievements.all().size()
	count.text = COUNT % [earned, every]
	if earned >= every and _head.get_node_or_null("Tick") == null:
		var tick := TextureRect.new()
		tick.name = "Tick"
		tick.texture = MenuTheme.tick()
		tick.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_head.add_child(tick)
		_head.move_child(tick, count.get_index() + 1)
	sort.text = SORT % ORDERS[order]


## A group's heading, a little brass plate screwed to the felt with its name engraved on it.
func _heading(words: String) -> Control:
	var heading := Label.new()
	heading.name = "Heading"
	heading.text = words.to_upper()
	Type.strong(heading, Type.LABEL, HouseTheme.ON_FOIL)
	var plate := PanelContainer.new()
	plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var brass := TicketStyle.cut(HouseTheme.FOIL, 4.0, 22.0, 3.0)
	brass.shadow = 4.0
	plate.add_theme_stylebox_override("panel", brass)
	plate.add_child(heading)
	plate.draw.connect(
		func() -> void:
			for x: float in [9.0, plate.size.x - 9.0]:
				var at := Vector2(x, plate.size.y * 0.5)
				plate.draw_circle(at, 3.0, HouseTheme.FOIL_LOW)
				plate.draw_line(
					at - Vector2(2.0, 1.0), at + Vector2(2.0, 1.0), HouseTheme.ON_FOIL, 1.0
				)
	)
	var room := MarginContainer.new()
	room.add_theme_constant_override("margin_left", 12)
	room.add_theme_constant_override("margin_top", 12)
	room.add_theme_constant_override("margin_bottom", 2)
	room.add_child(plate)
	return room


## The rows in the order they are shown.
func rows() -> Array[AchievementRow]:
	var found: Array[AchievementRow] = []
	for child: Node in list.get_children():
		if child is AchievementRow and not child.is_queued_for_deletion():
			found.append(child)
	return found


## The next order round, remembered by the machine, the cursor on the first row again.
func step_order() -> void:
	set_order(posmod(_settings.achievement_order + 1, ORDERS.size()) as Order)


func set_order(order: Order) -> void:
	_settings.achievement_order = order
	_settings.save_to_disk()
	fill()
	_focus_first.call_deferred()


## Puts the dialog away, the cursor going back to whatever had it before.
func close() -> void:
	if _closing:
		return
	_closing = true
	_keep_looks()
	var shades: Array[CanvasItem] = [_shade]
	MenuTheme.put_away(_pane, _gone, shades)


func is_closing() -> bool:
	return _closing


func _gone() -> void:
	if _from != null and is_instance_valid(_from) and _from.is_inside_tree():
		_from.grab_focus()
	put_away.emit()
	queue_free()


func _process(delta: float) -> void:
	var push := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(push) > 0.25 and scroll != null:
		scroll.scroll_vertical += roundi(push * STICK_SCROLL * delta)


## The switch's key, heard before the cursor would take it.
func _input(event: InputEvent) -> void:
	var keyboard := LicenseView.keyboard_after(event, _keyboard)
	var pointer := ButtonBinds.pointer_after(event, _pointer)
	if keyboard != _keyboard or pointer != _pointer:
		_keyboard = keyboard
		_pointer = pointer
		_show_binds()
	if _closing or event.is_echo() or not event.is_action_pressed(SORT_ACTION):
		return
	step_order()
	get_viewport().set_input_as_handled()


## B on a pad, or Escape, is Back. Nothing gets past the dialog to the screen under it.
func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed(&"ui_cancel"):
		MenuTheme.back_sound()
		close()
	elif not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()


func _on_shade_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.pressed) or (touch != null and touch.pressed):
		_shade.accept_event()
		close()


## The cursor has come to [param row]: no longer new.
func _on_looked_at(row: AchievementRow) -> void:
	if row.is_fresh():
		row.set_fresh(false)
		_looked = _settings.profile.achievements.look_at(row.achievement.id) or _looked


## The NEW tags gone are kept in the profile.
func _keep_looks() -> void:
	if _looked:
		_looked = false
		_settings.save_to_disk()


## The pane over nearly all the screen, or all of it short of room, as the catalog's is, and Back
## in the head on a short screen.
func _fit() -> void:
	var room := _root.size
	CatalogDialog.fill_screen(_pane, _around, room)
	var short := room.y < CatalogDialog.SHORT
	if short == (back.get_parent() == _head):
		return
	var had_cursor := back.has_focus()
	back.reparent(_head if short else _foot_row, false)
	_foot_row.visible = not short
	if had_cursor:
		back.grab_focus()


## The switch's bind beside it while keys or a pad are in hand, and none for the mouse alone.
func _show_binds() -> void:
	var keys := _keyboard and not _pointer
	var pad := SettingsScreen.pad_plugged_in()
	var at := _sort_hint.get_index()
	_sort_hint.name = "Gone"
	_sort_hint.queue_free()
	var ink := SettingsScreen.TAB_HINT_INK
	var size := SettingsScreen.TAB_HINT_SIZE
	if keys or pad:
		var parts: Array = [InputGlyph.of_action(SORT_ACTION, keys, ink, size)]
		_sort_hint = InputHint.row("%s", parts, ink, size)
	else:
		_sort_hint = Control.new()
	_sort_hint.name = "SortHint"
	_sort_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_head.add_child(_sort_hint)
	_head.move_child(_sort_hint, at)


func _focus_first() -> void:
	if not is_inside_tree() or _closing:
		return
	var shown := rows()
	if shown.is_empty():
		back.grab_focus()
	else:
		shown[0].grab_focus()
		scroll.scroll_vertical = 0
