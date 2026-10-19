class_name HouseEvaluation
extends VBoxContainer
## The House's page at the end of the Final Hand's payout slip, STORY.md 8.4: past a perforation,
## the evaluation line by line with dotted leaders, filled in for the candidate, STATUS blank. The
## slip's ways on are gone, the arrow down on to this page in their place; here the House's rubber
## stamp hangs off the slip beside STATUS, gold rather than the Department's red, with "Click the
## stamp to make it official" printed under it, or Tap, or Press, and the cursor on it once the
## page is in view. Pressed by anybody at this machine, it comes down over STATUS, the House marking
## its own forecast at the end of PREDICTED's line as it lands, which writes the Final Hand into
## the profile, see [method FinalHand.stamp_down], and then there is one way on, Continue, in foil.
## Or the paper is torn straight across over STATUS, by the tab beside the stamp, see [TearTab],
## Kit's pencil under the House's line pointing it out, see [KitPencil], or by the destroy button
## that has skipped picks all game: noted and counted, see [method FinalHand.decline], the strip
## with STATUS and the stamp on it falls off the slip, see [TornPage], the evaluation left on it
## over the torn edge with the House's note of it, and the slip's ways on come back.

## Continue pressed, after the stamp.
signal finished
## The page torn off the slip.
signal torn_off

const INK := HouseTheme.INK
const FAINT := HouseTheme.INK_FAINT
const SIZE := Type.LABEL
const DOT := Color(HouseTheme.INK, 0.4)
## How much room STATUS's blank and the stamp hanging beside it take.
const BLANK := Vector2(250.0, 60.0)
const STAMP_ROOM := Vector2(150.0, 130.0)
## How far down from STATUS's row the stamp hangs, and how far over the row the paper tears.
const STAMP_HANG := 6.0
const TEAR_ABOVE := 2.0

var match_node: Match
var lines: Array[Array] = []
var stamp: RubberStamp
var hint: Label
var pencil: KitPencil
## The foot of the page from STATUS down, what tears off it.
var strip: VBoxContainer
var go_on: Button
var ways: VBoxContainer
## The tab beside the stamp, and whether the page has been torn off by it.
var tab: TearTab
var torn := false
## Whether the stamp writes the Final Hand into the profile playing, STORY.md 8.1: where it was
## due for it; online, for anybody else at the table, the stamp comes down and nothing is kept.
var counts := true

var _blank: Control
var _bill: PayoutBill
var _screen: ResultsScreen
var _predicted: Label


## The page and its stamp put on [param screen], the slip of [param in_match]'s whistle.
static func add_to(screen: ResultsScreen, in_match: Match) -> HouseEvaluation:
	var section := HouseEvaluation.new()
	section.name = "HouseEvaluation"
	section.match_node = in_match
	section.lines = FinalHand.evaluation(in_match)
	section._build()
	section._bill = screen.bill
	section._screen = screen
	screen.bill.turned.connect(section._on_turned)
	screen.take_the_house(section, section.ways)
	section.tab = TearTab.new()
	section.tab.name = "TearTab"
	section.tab.visible = false
	section.tab.pressed.connect(section.tear_off)
	screen.add_child(section.tab)
	return section


func _build() -> void:
	add_theme_constant_override("separation", 4)
	var title := _text(StoryLines.EVALUATION_TITLE, Type.STRONG, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	for line: Array in lines:
		var label := str(line[0])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(_text(label, Type.numbers_text_font(), INK))
		var leader := Control.new()
		leader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		leader.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		leader.custom_minimum_size = Vector2(24.0, 18.0)
		leader.draw.connect(_dots.bind(leader))
		row.add_child(leader)
		if label == "STATUS":
			strip = VBoxContainer.new()
			strip.name = "Strip"
			strip.add_theme_constant_override("separation", 4)
			add_child(strip)
			_blank = Control.new()
			_blank.name = "Status"
			_blank.custom_minimum_size = BLANK
			_blank.draw.connect(_draw_blank)
			row.add_child(_blank)
			var hangs := Control.new()
			hangs.custom_minimum_size = STAMP_ROOM
			stamp = RubberStamp.create()
			stamp.rubber = HouseTheme.FOIL
			stamp.rubber_dark = HouseTheme.FOIL_LOW
			# Hung low enough to leave PREDICTED's line over STATUS to be read.
			stamp.position = Vector2(0.0, STAMP_HANG)
			stamp.stamped.connect(_on_stamped)
			stamp.device_changed.connect(_say_how)
			hangs.add_child(stamp)
			row.add_child(hangs)
		else:
			var value := _text(str(line[1]), Type.numbers_text_font(), INK)
			if label == "PREDICTED":
				_predicted = value
			row.add_child(value)
		if strip != null:
			strip.add_child(row)
		else:
			add_child(row)
	# How to bring the stamp down, printed under STATUS's blank as a form says how it is filled in,
	# clear of the stamp hanging beside it.
	var under := HBoxContainer.new()
	under.add_theme_constant_override("separation", 0)
	hint = _text("", Type.numbers_text_font(), FAINT)
	hint.name = "HowToStamp"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	under.add_child(hint)
	var beside := Control.new()
	beside.custom_minimum_size = Vector2(STAMP_ROOM.x + 8.0, 0.0)
	under.add_child(beside)
	strip.add_child(under)
	pencil = KitPencil.new()
	pencil.name = "KitsPencil"
	strip.add_child(pencil)
	ways = VBoxContainer.new()
	ways.name = "HouseWays"
	ways.alignment = BoxContainer.ALIGNMENT_CENTER
	go_on = MenuTheme.button(StoryLines.CONTINUE, 26)
	go_on.name = "Continue"
	go_on.theme_type_variation = HouseTheme.PRIMARY
	go_on.custom_minimum_size.x = ResultsScreen.WAY_WIDTH
	go_on.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go_on.visible = false
	go_on.pressed.connect(func() -> void: finished.emit())
	ways.add_child(go_on)
	_say_how()


## Where it comes down: over STATUS's blank, whatever has moved since it was hung; and the tab
## beside the stamp, while the page is in view and still to be answered.
func _process(_delta: float) -> void:
	if not torn and stamp != null and not stamp.has_slammed() and _blank != null:
		var over := (
			_blank.global_position
			+ _blank.size * 0.5
			- (stamp.get_parent() as Control).global_position
		)
		stamp.lands_at = over - Vector2(RubberStamp.SIZE.x * 0.5, RubberStamp.SIZE.y * 0.82)
	_hang_the_tab()


## The tab out past the slip's edge beside the stamp's handle, at the top of the strip it tears
## off by, shown while the page is the one in view and neither stamped nor torn; and Kit's arrow up
## to it.
func _hang_the_tab() -> void:
	if tab == null or not is_instance_valid(tab):
		# Torn off with the strip, the pencil goes with it.
		if not torn:
			pencil.points_to = Vector2.INF
		return
	# The stamp on its way down: the tab stays where it is until the stamp shakes it loose.
	if not torn and stamp != null and stamp.has_slammed():
		return
	var line := _perforation()
	var shown := (
		line != null
		and is_visible_in_tree()
		and _answerable()
		and _bill.page == _bill.page_count() - 1
		and not _bill.is_turning()
	)
	tab.visible = shown
	if not shown:
		pencil.points_to = Vector2.INF
		return
	var edge := _bill.paper.get_global_rect().end.x
	var tear := strip.global_position.y - TEAR_ABOVE
	tab.global_position = Vector2(edge - 8.0, tear - TearTab.SIZE.y * TearTab.HANG)
	tab.tear_at = tear - tab.global_position.y
	pencil.right_end = hint.get_global_rect().end.x - pencil.global_position.x - 6.0
	pencil.points_to = (
		tab.global_position + Vector2(2.0, TearTab.SIZE.y - 4.0) - pencil.global_position
	)


## The perforation this page hangs from on the bill, or null.
func _perforation() -> Control:
	var leaf := get_parent()
	if leaf == null or leaf.get_parent() == null or leaf.get_index() == 0:
		return null
	return leaf.get_parent().get_child(leaf.get_index() - 1) as Perforation


## Whether the page is still to be answered, by the stamp or the tear.
func _answerable() -> bool:
	return not torn and stamp != null and not stamp.has_slammed()


## The destroy button, the one that has skipped picks all game, tears the page off while it is the
## one in view, STORY.md 8.4.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.JOKER_DESTROY) or event.is_echo():
		return
	if not _answerable() or not is_visible_in_tree():
		return
	if _bill.page != _bill.page_count() - 1:
		return
	get_viewport().set_input_as_handled()
	tear_off()


## Torn straight across over STATUS, STORY.md 8.4: noted and counted where the Final Hand is due
## here, the strip off the slip and falling with the tab, and the slip's ways on back.
func tear_off() -> void:
	if not _answerable():
		return
	torn = true
	# The tab goes with the strip it tore off, Kit's arrow still at it.
	var flap := tab if tab != null and is_instance_valid(tab) else null
	tab = null
	if flap != null:
		flap.let_go()
	if counts:
		FinalHand.decline(Game.settings.profile, lines, LicenseCard.today())
	if _screen != null:
		_screen.house_torn(flap)
	elif flap != null:
		flap.queue_free()
	torn_off.emit()


## What is left on the slip once the strip is torn off and gone: the House's note of it stamped
## over the foot of the evaluation, in the slip's ink, see [NotedStamp].
func print_declined() -> void:
	if find_child("Declined", true, false) != null or get_child_count() == 0:
		return
	NotedStamp.down_on(self, get_child(get_child_count() - 1) as Control)


## The cursor on the stamp once this page, the bill's last, is in view.
func _on_turned(page: int) -> void:
	if torn or page != _bill.page_count() - 1 or stamp.has_slammed() or not is_visible_in_tree():
		return
	stamp.grab_focus()


func _say_how() -> void:
	if hint != null and stamp != null:
		hint.text = LicenseScreen.STAMP_LINE % stamp.press_word()


## The stamp down: the House's APPROVED over STATUS, its verdict on its own forecast at the end of
## PREDICTED's line, the Final Hand written, and Continue.
func _on_stamped() -> void:
	var date := LicenseCard.today()
	# Nothing left to tear: the tab shaken loose by the stamp, falling off the screen.
	if tab != null and is_instance_valid(tab):
		tab.fall_away()
	tab = null
	var verdict := FinalHand.verdict(Game.settings.profile)
	if _predicted != null:
		_predicted.text = verdict
	for line: Array in lines:
		if str(line[0]) == "PREDICTED":
			line[1] = verdict
	var mark := ApprovedStamp.new()
	mark.name = "Approved"
	mark.date = date
	mark.radius = 44.0
	mark.size = Vector2.ONE * mark.radius * 2.2
	# Over the blank's line, a little short of its middle, as a stamp brought down by hand lands.
	mark.position = Vector2(_blank.size.x * 0.46, _blank.size.y * 0.7) - mark.size * 0.5
	_blank.add_child(mark)
	if counts:
		FinalHand.stamp_down(Game.settings.profile, lines, date)
		# Terms Accepted there and then, as the stamp comes down, GAME.md 8.10 and STORY.md 8.7.
		Achievements.arrive(Game.settings.profile)
	# Gone once it is done, keeping its line so the page stays as it was.
	hint.modulate.a = 0.0
	go_on.visible = true
	go_on.grab_focus()


func _text(words: String, font: Font, ink: Color) -> Label:
	var label := Label.new()
	label.text = words
	Type.set_font(label, font, SIZE)
	label.add_theme_color_override("font_color", ink)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _dots(leader: Control) -> void:
	var y := leader.size.y * 0.7
	var x := 2.0
	while x < leader.size.x - 2.0:
		leader.draw_circle(Vector2(x, y), 1.1, DOT)
		x += 7.0


## STATUS's blank: a line to be stamped over.
func _draw_blank() -> void:
	var y := _blank.size.y * 0.7
	_blank.draw_line(Vector2(4.0, y), Vector2(_blank.size.x - 4.0, y), INK, 1.5)


## Online, this screen through and the room not yet, STORY.md 8.6: Continue gone, and in its
## place a line saying the others are still with the House, see [FinalHandRoll].
func wait_for_the_others() -> void:
	if go_on != null:
		go_on.visible = false
	if hint != null:
		hint.text = StoryLines.STILL_WITH_THE_HOUSE
		hint.modulate.a = 1.0
