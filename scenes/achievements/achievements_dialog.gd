class_name AchievementsDialog
extends CanvasLayer
## The achievements of GAME.md 8.10 for the profile playing: a large dialog over whatever screen
## opens it, as the catalog of 8.8 is, on a layer of its own, filling the screen on a short one. Its
## head says how many of how many are earned, a gold tick once all of them are, and carries the
## switch Sort, In order, Earned or To do, which the machine remembers. The pane is a card table:
## its felt inside a padded leather rail, see [FeltArt] and [LeatherArt], the buttons printed on the
## felt, see [FeltPrintStyle], and the switch a craps table's puck. Under the head a line printed
## round the rows, a row each, see [AchievementRow], under the groups' headings in order; the hidden
## ones last in every order. Read only, but for the NEW tags, which go as the cursor comes to them
## and are kept gone as the dialog is put away; Next new in the head, or N or a pad's View, takes
## the cursor to the next row wearing one, see [NextNew].

## Put away, the cursor back where it was.
signal put_away

## The orders the list can be in, see [constant ORDERS] for what the switch says of each.
enum Order { IN_ORDER, EARNED, TO_DO }

const LAYER := CatalogDialog.LAYER
## Every achievements dialog up, so a toast clicked shows its achievement in the one up, see
## [method show_in].
const GROUP := &"achievements_dialogs"
## The group a room's pause menu is in, [code]PauseMenu.GROUP[/code], see [method show_in].
const ROOM_MENUS := &"pause_menu"
const TITLE := "Achievements"
const COUNT := "%d / %d"
const ORDERS: Array[String] = ["In order", "Earned", "To do"]
const SORT := "Sort: %s"
const SORT_ACTION := InputActions.MENU_VIEW
## The switch that leaves out what is earned, and its bind, the dialogs' option key as the
## catalog's second switch has it, see [DialogBinds]; and what the list says with nothing left in
## it.
const HIDE := "Hide earned"
const HIDE_ACTION := InputActions.MENU_OPTION
const ALL_EARNED := "Every achievement is earned."
## How tall Sort and Back are, a little short of a menu's button.
const SORT_TALL := 48.0
## How far the hide-earned switch's bind is lifted to sit on the line the Sort and Next new buttons'
## binds keep: the switch stands 58 tall against their SORT_TALL, and centred in the row its foot is
## half that difference lower, so its bind would hang that much below theirs without the lift.
const HIDE_BIND_LIFT := (58.0 - SORT_TALL) * 0.5
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
## The room round the rows inside the printed line and between them, and round everything inside
## the rail, less on a short screen.
const AROUND := 10
const PANE_ROOM := 18.0
const PANE_ROOM_SHORT := 12.0
const BETWEEN := 4
## How fast a pad's right stick scrolls the case, at its full push, in pixels a second.
const STICK_SCROLL := 1400.0
## How wide the leather rail round the felt is, narrower on a short screen, where every row's
## worth of room counts and the pane fills the screen: there the rail runs on past the screen's
## edges by this share of it, its outer stitching out of sight and its inner seam and a strip of
## its leather left. Then how far inside the printed line the rows are cut off, a little further at
## its foot to clear the table's motto printed there, see [method motto].
const LEATHER_WIDE := 36.0
const LEATHER_WIDE_SHORT := 26.0
const LEATHER_CUT := 0.45
const LINE_ROOM := 8.0
const MOTTO_ROOM := 14.0
## How far in from the printed line's right side the scroll bar runs, clear of the line.
const BAR_ROOM := 12.0
## How far the rows fade out toward the window's top or foot while there are more of them past it.
const FADE := 30.0
## How big the craps puck the switch is, from its middle to its edge.
const PUCK := 22


## The rows' window, a line printed round it on the felt, as a blackjack table's layout is, with the
## table's motto in its foot; the rows scroll a little inside it, through a [Fade].
class Case:
	extends PanelContainer

	func _ready() -> void:
		var room := StyleBoxEmpty.new()
		room.content_margin_top = AchievementsDialog.LINE_ROOM
		room.content_margin_bottom = AchievementsDialog.MOTTO_ROOM
		room.content_margin_right = AchievementsDialog.BAR_ROOM
		add_theme_stylebox_override("panel", room)
		resized.connect(queue_redraw)

	func _draw() -> void:
		FeltArt.print_line(self, Rect2(Vector2.ZERO, size), AchievementsDialog.motto(), Type.LABEL)


## The rows' window, fading them out toward its top while there are rows above it and toward its
## foot while there are rows below it, rather than cutting them off; at the list's start or its
## end that edge is sharp. Its own picture, clear at a fading edge and solid elsewhere, is what its
## children are drawn through. Each fade comes in over the first [constant FADE] pixels scrolled.
class Fade:
	extends Control

	var _scroll: ScrollContainer

	func _ready() -> void:
		clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		mouse_filter = Control.MOUSE_FILTER_PASS
		resized.connect(queue_redraw)

	## Watches [param scroll], the window's own, to fade as it scrolls.
	func watch(scroll: ScrollContainer) -> void:
		_scroll = scroll
		var bar := scroll.get_v_scroll_bar()
		bar.value_changed.connect(func(_value: float) -> void: queue_redraw())
		bar.changed.connect(queue_redraw)
		bar.visibility_changed.connect(queue_redraw)

	func _draw() -> void:
		var reach := minf(AchievementsDialog.FADE, size.y * 0.5)
		var bar := _scroll.get_v_scroll_bar() if _scroll != null else null
		var above := 0.0
		var below := 0.0
		var strip := 0.0
		if bar != null and bar.visible:
			above = clampf(bar.value / reach, 0.0, 1.0)
			below = clampf((bar.max_value - bar.page - bar.value) / reach, 0.0, 1.0)
			strip = bar.size.x
		var wide := size.x - strip
		var solid := Color.WHITE
		var top := Color(1.0, 1.0, 1.0, 1.0 - above)
		var foot := Color(1.0, 1.0, 1.0, 1.0 - below)
		var points := PackedVector2Array(
			[
				Vector2.ZERO,
				Vector2(wide, 0.0),
				Vector2(wide, reach),
				Vector2(wide, size.y - reach),
				Vector2(wide, size.y),
				Vector2(0.0, size.y),
				Vector2(0.0, size.y - reach),
				Vector2(0.0, reach),
			]
		)
		draw_polygon(
			PackedVector2Array([points[0], points[1], points[2], points[7]]),
			PackedColorArray([top, top, solid, solid])
		)
		draw_rect(Rect2(0.0, reach, wide, size.y - reach * 2.0), solid)
		draw_polygon(
			PackedVector2Array([points[6], points[3], points[4], points[5]]),
			PackedColorArray([solid, solid, foot, foot])
		)
		# The scroll bar is never faded.
		draw_rect(Rect2(wide, 0.0, strip, size.y), solid)


var back: Button
var sort: Button
var hide_earned: CheckButton
## Next new, first of what is at the head's right, see [NextNew].
var next_new: NextNew
var count: Label
var list: VBoxContainer
var scroll: ScrollContainer

var _settings: Settings
## Whose achievements these are, the profile playing's unless another was asked for; and the one
## the cursor starts on, see [method show_achievement].
var _profile: Profile
var _at := &""
var _root: Control
var _shade: ColorRect
var _around: MarginContainer
var _pane: PanelContainer
var _head: HBoxContainer
var _title: Label
var _foot_row: HBoxContainer
## The words before the switch, left out where the head has no room for them, see
## [method _fit_head].
var _hide_words: Label
var _from: Control
var _looked := false
var _closing := false
var _keyboard := true
var _pointer := false
## How wide the leather rail is for this screen, how far of it lies past the screen's edges, and
## its cushion, kept while the pane draws it.
var _rail := LEATHER_WIDE
var _rail_cut := 0.0
var _cushion: ArrayMesh


## The achievements over [param parent], for the profile playing or [param whose], the cursor on
## the first row, or on [param at]'s, shown even where earned ones are left out.
## The motto printed on the table's felt in the foot of the line round the rows, the House's at the
## stage the story is at, STORY.md 6.6c.
static func motto() -> String:
	return str(StoryLines.at(StoryLines.TABLE_MOTTO, Story.stage_here()))


static func open(parent: Node, at := &"", whose: Profile = null) -> AchievementsDialog:
	var dialog := AchievementsDialog.new()
	dialog.name = "Achievements"
	dialog._at = at
	dialog._profile = whose
	if parent.is_inside_tree():
		dialog._from = parent.get_viewport().gui_get_focus_owner()
	parent.add_child(dialog)
	return dialog


## Shows [param id] in the achievements of the profile playing or [param whose], GAME.md 8.10, as
## a toast clicked asks: in the dialog up, if one is; in a room over its menu, put up first, which
## pauses the match as Escape does and online asks the room to, the menu left up to resume from
## once the dialog is put away; on the title over it; and anywhere else over the screen.
static func show_in(tree: SceneTree, id: StringName, whose: Profile = null) -> void:
	var up := tree.get_first_node_in_group(GROUP) as AchievementsDialog
	if up != null and not up.is_closing():
		up.show_achievement(id)
		return
	# The room's menu by its group and its methods' names: the menu names this dialog, and a class
	# naming the other back is a cycle among the rooms' scripts, which broke the online check the way
	# the toasts once named in Game did, see [Game].
	var menu := tree.get_first_node_in_group(ROOM_MENUS)
	if menu != null:
		if not menu.call(&"is_open"):
			menu.call(&"set_paused", true)
		menu.call(&"open_achievements", id, whose)
		return
	var scene := tree.current_scene
	if scene == null:
		return
	if scene.has_method(&"show_achievements"):
		scene.call(&"show_achievements", id, whose)
	else:
		open(scene, id, whose)


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
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	# A finger on it is its own: nothing under it, a room's menu say, hears it first.
	TouchInput.keep_touches(self)
	_settings = Game.settings
	if _profile == null:
		_profile = _settings.profile
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
	# The whole pane is a card table, felt inside a leather rail, see _draw_pane.
	_pane = PanelContainer.new()
	var inside := StyleBoxEmpty.new()
	inside.set_content_margin_all(LEATHER_WIDE + PANE_ROOM)
	_pane.add_theme_stylebox_override("panel", inside)
	_pane.draw.connect(_draw_pane)
	_pane.resized.connect(_pane.queue_redraw)
	# The leather's grain repeats along the rail; nothing inside it is to.
	_pane.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_pane.name = "Pane"
	_pane.mouse_filter = Control.MOUSE_FILTER_STOP
	_around.add_child(_pane)
	var column := VBoxContainer.new()
	column.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
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
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	# Its bind hung on its foot like the other buttons', the pad's B or Escape, see [ButtonBinds].
	ButtonBinds.mark(back, &"ui_cancel")
	_foot_row.add_child(back)
	fill()
	_dress_buttons()
	_root.resized.connect(_fit)
	_fit()
	_show_binds()
	MenuTheme.deal(_pane)
	_focus_first.call_deferred()


func _exit_tree() -> void:
	_keep_looks()


## The head: the title, how many are earned of how many with a gold tick once all are, and at its
## right the switches with their binds, and Next new just left of Sort.
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
	# Whose they are, for a profile sitting in at another seat, its toast clicked.
	if _profile != _settings.profile:
		var whose := Label.new()
		whose.name = "Whose"
		whose.text = _profile.display_name()
		Type.strong(whose, Type.BODY, HouseTheme.WORDS)
		whose.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_head.add_child(whose)
	var room := Control.new()
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_head.add_child(room)
	# Hide earned, the switch with its words before it, left of Sort; both left to the mouse and a
	# finger, while keys and a pad get the switch's bind hung on its own foot, as Sort's is.
	_hide_words = Label.new()
	_hide_words.name = "HideEarned"
	_hide_words.text = HIDE
	Type.strong(_hide_words, Type.BODY, HouseTheme.WORDS)
	_hide_words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_head.add_child(_hide_words)
	hide_earned = MenuTheme.toggle(_settings.achievements_hide_earned)
	hide_earned.name = "HideSwitch"
	ScreenReader.name(hide_earned, HIDE)
	hide_earned.focus_mode = Control.FOCUS_NONE
	hide_earned.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hide_earned.toggled.connect(set_hide_earned)
	# Its bind hung on its own foot rather than stood before its words, and lifted to the line the
	# shorter Sort and Next new keep, [constant HIDE_BIND_LIFT], see [ButtonBinds].
	ButtonBinds.mark(hide_earned, HIDE_ACTION, KEY_NONE, JOY_BUTTON_INVALID, HIDE_BIND_LIFT)
	_head.add_child(hide_earned)
	# Next new, printed on the felt as Sort is and as tall, just left of it.
	var printed := MenuTheme.button("", Type.BODY)
	FeltPrintStyle.dress(printed)
	printed.custom_minimum_size = Vector2(0.0, SORT_TALL)
	next_new = NextNew.around(printed)
	next_new.asked.connect(next_new_row)
	next_new.visibility_changed.connect(_fit_head, CONNECT_DEFERRED)
	_head.add_child(next_new)
	# As wide as what it says and no wider: a menu's button is wide for a column of them.
	sort = MenuTheme.button("", Type.BODY)
	sort.name = "Sort"
	sort.custom_minimum_size = Vector2(0.0, SORT_TALL)
	sort.focus_mode = Control.FOCUS_NONE
	sort.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sort.pressed.connect(step_order)
	# Its bind hung on its foot, as Next new's is, see [ButtonBinds].
	ButtonBinds.mark(sort, SORT_ACTION)
	_head.add_child(sort)
	return _head


## The rows' window inside the printed line, scrolling where there are more than it has room for.
func _make_case() -> Control:
	var lining := Case.new()
	lining.name = "Lining"
	lining.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	var fade := Fade.new()
	fade.name = "Fade"
	lining.add_child(fade)
	fade.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.watch(scroll)
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
	return lining


## Sort and Back printed on the felt, and the switch a craps table's puck.
func _dress_buttons() -> void:
	# The two the same size, as wide as the widest of what Sort says or Back, so neither changes
	# as the orders go round.
	var font := Type.STRONG
	var wide := font.get_string_size(back.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Type.BODY).x
	for order: String in ORDERS:
		wide = maxf(
			wide, font.get_string_size(SORT % order, HORIZONTAL_ALIGNMENT_LEFT, -1, Type.BODY).x
		)
	for button: Button in [sort, back]:
		FeltPrintStyle.dress(button)
		Type.set_font(button, Type.STRONG, Type.BODY)
		button.custom_minimum_size = Vector2(
			ceilf(wide + FeltPrintStyle.ACROSS * 2.0 + 4.0), SORT_TALL
		)
	_puck()


## The switch as a craps table's puck, black and OFF or white and ON, drawn over a clear picture
## of its size.
func _puck() -> void:
	var clear := Image.create(PUCK * 2, PUCK * 2, false, Image.FORMAT_RGBA8)
	clear.fill(Color(0.0, 0.0, 0.0, 0.0))
	var room := ImageTexture.create_from_image(clear)
	for state: String in [
		"unchecked",
		"unchecked_mirrored",
		"unchecked_disabled",
		"checked",
		"checked_mirrored",
		"checked_disabled"
	]:
		hide_earned.add_theme_icon_override(state, room)
	hide_earned.add_theme_constant_override("icon_max_width", PUCK * 2)
	hide_earned.draw.connect(
		func() -> void:
			var on := hide_earned.button_pressed
			var at := Vector2(hide_earned.size.x - PUCK - 6.0, hide_earned.size.y * 0.5)
			var face := Color("#f2eee6") if on else Color("#141314")
			var mark := Color("#141314") if on else Color("#f2eee6")
			hide_earned.draw_circle(at + Vector2(0.0, 3.0), PUCK, Color(0.0, 0.0, 0.0, 0.45))
			hide_earned.draw_circle(at, PUCK, face)
			hide_earned.draw_arc(at, PUCK - 4.0, 0.0, TAU, 40, Color(mark, 0.7), 1.5, true)
			var words := "ON" if on else "OFF"
			var font := Type.STRONG
			var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, Type.SMALL)
			var baseline := (
				at.y + (font.get_ascent(Type.SMALL) - font.get_descent(Type.SMALL)) * 0.5
			)
			hide_earned.draw_string(
				font,
				Vector2(at.x - wide.x * 0.5, baseline),
				words,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				Type.SMALL,
				mark
			)
	)


## The pane as the card table it is: the felt, and the leather rail round it, over the felt's square
## corners; on a short screen the table a little bigger than the screen, its rail cut by its edges
## and square on its outside, flush with the screen's corners.
func _draw_pane() -> void:
	var table := Rect2(Vector2.ZERO, _pane.size).grow(_rail_cut)
	FeltArt.cloth(_pane, table.grow(-_rail * 0.5), FeltArt.CLOTH, 5)
	_cushion = LeatherArt.rail(_pane, table, _rail, _rail_cut > 0.0)


## The rows in the order the switch says, under the groups' headings in order, the count, Next new
## and the switch as they now are.
func fill() -> void:
	var order := clampi(_settings.achievement_order, 0, ORDERS.size() - 1) as Order
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var profile := _profile
	var hide := _settings.achievements_hide_earned
	var group := -1
	for shown: Achievement in ordered(profile, order):
		if hide and profile.achievements.has(shown.id) and shown.id != _at:
			continue
		if order == Order.IN_ORDER and shown.group != group:
			group = shown.group
			list.add_child(_heading(HEADINGS[clampi(group, 0, HEADINGS.size() - 1)]))
		var row := AchievementRow.of(shown, profile)
		row.looked_at.connect(_on_looked_at)
		list.add_child(row)
	if list.get_child_count() == 0:
		var done := Label.new()
		done.name = "AllEarned"
		done.text = ALL_EARNED
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Type.text(done, Type.BODY, HouseTheme.WORDS)
		list.add_child(done)
	var earned := Achievements.earned_count(profile)
	var every := Achievements.all().size()
	count.text = COUNT % [earned, every]
	_count_new()
	if earned >= every and _head.get_node_or_null("Tick") == null:
		var tick := TextureRect.new()
		tick.name = "Tick"
		tick.texture = MenuTheme.tick()
		tick.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_head.add_child(tick)
		_head.move_child(tick, count.get_index() + 1)
		_fit_head.call_deferred()
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


## Leaves out the achievements already earned, or shows them again, remembered by the machine, the
## cursor on the first row again.
func set_hide_earned(on: bool) -> void:
	_at = &""
	_settings.achievements_hide_earned = on
	hide_earned.set_pressed_no_signal(on)
	_settings.save_to_disk()
	fill()
	_focus_first.call_deferred()


func set_order(order: Order) -> void:
	_at = &""
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


## The switches' keys and Next new's, heard before the cursor would take them.
func _input(event: InputEvent) -> void:
	var keyboard := LicenseView.keyboard_after(event, _keyboard)
	var pointer := ButtonBinds.pointer_after(event, _pointer)
	if keyboard != _keyboard or pointer != _pointer:
		_keyboard = keyboard
		_pointer = pointer
		_show_binds()
	if _closing:
		return
	# WASD moves the cursor down the list as the arrows do, see [DialogBinds].
	if DialogBinds.moved_focus(event, get_viewport()):
		get_viewport().set_input_as_handled()
		return
	if event.is_echo():
		return
	if event.is_action_pressed(SORT_ACTION):
		step_order()
	elif event.is_action_pressed(HIDE_ACTION):
		set_hide_earned(not _settings.achievements_hide_earned)
	elif next_new.heard(event):
		pass
	else:
		return
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
		_looked = _profile.achievements.look_at(row.achievement.id) or _looked
		_count_new()


## Next new says how many of the profile's achievements are new, see
## [method Achievements.has_fresh].
func _count_new() -> void:
	var left := 0
	for each: Achievement in Achievements.all():
		left += 1 if _profile.achievements.is_fresh(each.id) else 0
	next_new.show_left(left)


## Next new, GAME.md 8.10: the cursor at once on the next row wearing NEW after the one it is on, in
## the order the list is in, round past the last, the case scrolled to it. One that Hide earned
## leaves out is shown all the same, as a toast clicked shows its own, the list kept as it was
## otherwise. The cursor coming to it takes its tag off, see [method _on_looked_at].
func next_new_row() -> void:
	if _closing:
		return
	var ids: Array = []
	var order := clampi(_settings.achievement_order, 0, ORDERS.size() - 1) as Order
	for each: Achievement in ordered(_profile, order):
		ids.append(each.id)
	var on := get_viewport().gui_get_focus_owner() as AchievementRow
	var at: Variant = on.achievement.id if on != null and on.is_inside_tree() else null
	var next: Variant = NextNew.after(ids, at, _profile.achievements.is_fresh)
	if next == null:
		return
	var row := _row_of(next)
	if row == null:
		_at = next
		fill()
		row = _row_of(next)
	# In the middle of the case rather than at its edge, where its rings would be cut off.
	_bring_to_middle.call_deferred(row)
	row.grab_focus()
	# Come to from afar, perhaps a screen away: the eye drawn to it, the row coming up only a little,
	# wide as it is, and the rings going out from its label.
	LandingCue.on(row, LandingCue.GENTLE, row.focus_frame())


## The row of the achievement [param id] among those shown, or null.
func _row_of(id: StringName) -> AchievementRow:
	for row: AchievementRow in rows():
		if row.achievement.id == id:
			return row
	return null


## The NEW tags gone are kept in the profile: the playing one's with the settings, another's by
## itself.
func _keep_looks() -> void:
	if _looked:
		_looked = false
		if _profile == _settings.profile:
			_settings.save_to_disk()
		else:
			_profile.save_to_disk()


## The cursor on [param id]'s row, from a toast clicked while the dialog is up, see
## [method show_in].
func show_achievement(id: StringName) -> void:
	if _closing:
		return
	_at = id
	fill()
	_focus_first.call_deferred()


## The pane over nearly all the screen, or all of it short of room, as the catalog's is, and on a
## short screen its rail narrower and Back in the head; the head fitted to the room, see
## [method _fit_head].
func _fit() -> void:
	var room := _root.size
	CatalogDialog.fill_screen(_pane, _around, room)
	_fit_head.call_deferred()
	var short := room.y < CatalogDialog.SHORT
	var rail := LEATHER_WIDE_SHORT if short else LEATHER_WIDE
	if rail != _rail:
		_rail = rail
		_rail_cut = rail * LEATHER_CUT if short else 0.0
		var inside := _pane.get_theme_stylebox("panel") as StyleBoxEmpty
		inside.set_content_margin_all(rail - _rail_cut + (PANE_ROOM_SHORT if short else PANE_ROOM))
		_pane.queue_redraw()
	if short == (back.get_parent() == _head):
		return
	var had_cursor := back.has_focus()
	back.reparent(_head if short else _foot_row, false)
	_foot_row.visible = not short
	if had_cursor:
		back.grab_focus()


## The binds while keys or a pad are in hand: Hide earned's just before its words, and Sort's and
## Next new's hung on their feet, see [ButtonBinds]; none for the mouse alone.
func _show_binds() -> void:
	var keys := _keyboard and not _pointer
	var pad := SettingsScreen.pad_plugged_in()
	next_new.show_bind(keys, keys or pad)
	# Each button's bind hung on its own foot: Hide earned's and Sort's, and Back's too.
	ButtonBinds.show([sort, hide_earned, back], keys, keys or pad)
	_fit_head.call_deferred()


## The head on the one row the pane has room for, and never wider, as the loyalty program's is: the
## title and the count, Next new, the switch and Sort, and Back where it is there, always. Where
## there is not room for all of it, Back gives up the width it keeps for Sort's longest words for
## its own, and last the words before the switch go, the puck saying OFF or ON by itself. Every
## bind hangs on its own button's foot and takes no room of the row.
func _fit_head() -> void:
	if not is_inside_tree():
		return
	_hide_words.visible = true
	back.custom_minimum_size.x = sort.custom_minimum_size.x
	var room := head_room()
	for step: int in 2:
		if _head_wide() <= room:
			return
		match step:
			0:
				back.custom_minimum_size.x = 0.0
			1:
				_hide_words.visible = false


## How wide the head is laid out with what shows in it now, at the least.
func _head_wide() -> float:
	var wide := 0.0
	var shown := 0
	for child: Node in _head.get_children():
		var each := child as Control
		if each != null and each.visible and not each.is_queued_for_deletion():
			wide += each.get_combined_minimum_size().x
			shown += 1
	return wide + float(maxi(shown - 1, 0) * _head.get_theme_constant(&"separation"))


## How wide the head can be: the inside of the pane as wide as the screen lets it be, whatever is
## in it, see [method _fit].
func head_room() -> float:
	var around := float(_around.get_theme_constant(&"margin_left"))
	around += float(_around.get_theme_constant(&"margin_right"))
	var inside := _pane.get_theme_stylebox(&"panel")
	return _root.size.x - around - inside.get_margin(SIDE_LEFT) - inside.get_margin(SIDE_RIGHT)


func _focus_first() -> void:
	if not is_inside_tree() or _closing:
		return
	var shown := rows()
	if shown.is_empty():
		back.grab_focus()
		return
	for row: AchievementRow in shown:
		if row.achievement.id == _at and row != shown[0]:
			row.grab_focus()
			_bring_to_middle.call_deferred(row)
			return
	shown[0].grab_focus()
	scroll.scroll_vertical = 0


## The case scrolled to have [param row] in its middle, once the rows are laid out.
func _bring_to_middle(row: AchievementRow) -> void:
	if not is_instance_valid(row) or not row.is_inside_tree():
		return
	var top := row.get_global_rect().position.y - list.get_global_rect().position.y
	scroll.scroll_vertical = roundi(top - (scroll.size.y - row.size.y) * 0.5)
