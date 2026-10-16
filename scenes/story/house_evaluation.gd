class_name HouseEvaluation
extends VBoxContainer
## The House's page at the end of the Final Hand's payout slip, STORY.md 8.4: past a perforation,
## the evaluation line by line with dotted leaders, filled in for the candidate, STATUS blank. The
## slip's ways on are gone, the arrow down on to this page in their place; here the House's rubber
## stamp hangs off the slip beside STATUS, gold rather than the Department's red, with "Click the
## stamp to make it official" printed under it, or Tap, or Press, and the cursor on it once the
## page is in view. Pressed by anybody at this machine, it comes down over STATUS, which writes the
## Final Hand into the profile, see [method FinalHand.stamp_down], and then there is one way on,
## Continue, in foil.

## Continue pressed, after the stamp.
signal finished

const INK := HouseTheme.INK
const FAINT := HouseTheme.INK_FAINT
const SIZE := Type.LABEL
const DOT := Color(HouseTheme.INK, 0.4)
## How much room STATUS's blank and the stamp hanging beside it take.
const BLANK := Vector2(250.0, 60.0)
const STAMP_ROOM := Vector2(150.0, 130.0)

var match_node: Match
var lines: Array[Array] = []
var stamp: RubberStamp
var hint: Label
var go_on: Button
var ways: VBoxContainer
## Whether the stamp writes the Final Hand into the profile playing, STORY.md 8.1: where it was
## due for it; online, for anybody else at the table, the stamp comes down and nothing is kept.
var counts := true

var _blank: Control
var _bill: PayoutBill


## The page and its stamp put on [param screen], the slip of [param in_match]'s whistle.
static func add_to(screen: ResultsScreen, in_match: Match) -> HouseEvaluation:
	var section := HouseEvaluation.new()
	section.name = "HouseEvaluation"
	section.match_node = in_match
	section.lines = FinalHand.evaluation(in_match)
	section._build()
	section._bill = screen.bill
	screen.bill.turned.connect(section._on_turned)
	screen.take_the_house(section, section.ways)
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
			stamp.position = Vector2(0.0, -40.0)
			stamp.stamped.connect(_on_stamped)
			stamp.device_changed.connect(_say_how)
			hangs.add_child(stamp)
			row.add_child(hangs)
		else:
			row.add_child(_text(str(line[1]), Type.numbers_text_font(), INK))
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
	add_child(under)
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


## Where it comes down: over STATUS's blank, whatever has moved since it was hung.
func _process(_delta: float) -> void:
	if stamp != null and not stamp.has_slammed() and _blank != null:
		var over := (
			_blank.global_position
			+ _blank.size * 0.5
			- (stamp.get_parent() as Control).global_position
		)
		stamp.lands_at = over - Vector2(RubberStamp.SIZE.x * 0.5, RubberStamp.SIZE.y * 0.82)


## The cursor on the stamp once this page, the bill's last, is in view.
func _on_turned(page: int) -> void:
	if page != _bill.page_count() - 1 or stamp.has_slammed() or not is_visible_in_tree():
		return
	stamp.grab_focus()


func _say_how() -> void:
	if hint != null and stamp != null:
		hint.text = LicenseScreen.STAMP_LINE % stamp.press_word()


## The stamp down: the House's APPROVED over STATUS, the Final Hand written, and Continue.
func _on_stamped() -> void:
	var date := LicenseCard.today()
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
