class_name ApprovalRecord
extends Control
## The House's approval record after the last line, STORY.md 8.5: a strip of its statement paper fed
## up into the middle of the screen off its roll, a line at a time with a till's chatter and nothing
## else, HOUSE OPERATIONS · APPROVAL RECORD at its head; and on it the decisions approved in the
## player's name since the stamp came down, counting up at the House's own rate for as long as it is
## looked at, in fits and starts as decisions come in, never as a clock runs.

const WIDTH := 860.0
const ROOM := 44.0
const STEP := 44.0
const HEAD := 82.0
const TYPE := 25
## How long each line takes to feed up, and the gap between two.
const FEED := 0.18
const GAP := 0.32
## The roll it comes off, under it.
const ROLL := 18.0
## How long the count waits between two jumps, now and then a while longer, and how much of what
## came in meanwhile each jump takes at least.
const JUMP_SOON := 0.03
const JUMP_LATE := 0.32
const LULL_ONE_IN := 8
const LULL := 0.9
const JUMP_LEAST := 0.45

## When the stamp came down, in seconds of the system clock, from which the count runs.
var since := 0.0
var profile: Profile
## How many of its lines have been fed up, and how far the one feeding is.
var fed := 0
var _feeding := 0.0
var _lines: Array[Array] = []
var _shown := -1
var _jump_left := 0.0
var _rng := RandomNumberGenerator.new()


## The record of [param of]'s approvals, counting from [param from], over [param holder].
static func feed(holder: Control, of: Profile, from: float) -> ApprovalRecord:
	var record := ApprovalRecord.new()
	record.name = "ApprovalRecord"
	record.profile = of
	record.since = from
	record.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(record)
	return record


func _ready() -> void:
	for line: Array in StoryLines.APPROVAL_RECORD:
		_lines.append([str(line[0]), str(line[1])])
	size = Vector2(WIDTH, HEAD + STEP * float(_lines.size()) + ROOM)
	_place()
	get_parent().resized.connect(_place)


## Whether every line is up.
func is_fed() -> bool:
	return fed >= _lines.size()


func _place() -> void:
	var room := (get_parent() as Control).size
	position = Vector2((room.x - size.x) * 0.5, (room.y - size.y) * 0.5)


func _process(delta: float) -> void:
	if not is_fed():
		_feeding += delta
		if _feeding >= FEED + GAP:
			_feeding = 0.0
			fed += 1
			Audio.play_sfx(&"bank_tick", -10.0, 0.12)
	_jump(delta)
	queue_redraw()


## The count shown jumps on to the approvals by now, or some of the way, when its wait is up.
func _jump(delta: float) -> void:
	_jump_left -= delta
	if _jump_left > 0.0 and _shown >= 0:
		return
	var now := approved_now()
	var took := _rng.randf_range(JUMP_LEAST, 1.0)
	_shown = now if _shown < 0 else maxi(_shown + roundi(float(now - _shown) * took), _shown)
	var lull := _rng.randi_range(1, LULL_ONE_IN) == 1
	_jump_left = (
		_rng.randf_range(JUMP_LATE, LULL) if lull else _rng.randf_range(JUMP_SOON, JUMP_LATE)
	)


## The approvals the record shows, as it last jumped.
func shown() -> int:
	return _shown


## The approvals by now, counted from the stamp.
func approved_now() -> int:
	return FinalHand.approvals_in(Time.get_unix_time_from_system() - since)


func _draw() -> void:
	var showing := minf(float(fed) + clampf(_feeding / FEED, 0.0, 1.0), float(_lines.size()))
	var tall := HEAD + STEP * showing + ROOM * 0.5
	var bottom := size.y
	var paper := Rect2(Vector2(0.0, bottom - tall), Vector2(size.x, tall))
	# The roll it is coming off, a shadowed cylinder under where it feeds out.
	draw_rect(
		Rect2(Vector2(-8.0, bottom - 2.0), Vector2(size.x + 16.0, ROLL)), HouseTheme.PAPER_LOW
	)
	draw_rect(
		Rect2(Vector2(-8.0, bottom + ROLL * 0.55), Vector2(size.x + 16.0, ROLL * 0.45)),
		Color(0.0, 0.0, 0.0, 0.25)
	)
	draw_colored_polygon(NotePaper.torn(paper, 5.0, true, false), HouseTheme.PAPER)
	# Its edge down the sides and along the foot, none across the top, which is torn.
	var edge := PackedVector2Array(
		[
			paper.position + Vector2(0.0, 6.0),
			Vector2(paper.position.x, bottom),
			Vector2(paper.end.x, bottom),
			Vector2(paper.end.x, paper.position.y + 6.0),
		]
	)
	draw_polyline(edge, Color(HouseTheme.PAPER_LOW, 0.6), 1.5)
	var font := NotePage.TYPED
	var y := paper.position.y + 50.0
	var title := StoryLines.APPROVAL_TITLE
	var wide := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, TYPE).x
	draw_string(
		font,
		Vector2((size.x - wide) * 0.5, y),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		TYPE,
		HouseTheme.INK
	)
	draw_line(
		Vector2(ROOM, y + 16.0), Vector2(size.x - ROOM, y + 16.0), Color(HouseTheme.INK, 0.5), 1.4
	)
	y = paper.position.y + HEAD + STEP * 0.8
	var count := mini(ceili(showing), _lines.size())
	for i: int in count:
		var line: Array = _lines[i]
		_leader(str(line[0]), _value(str(line[1])), font, ROOM, y, size.x - ROOM * 2.0)
		y += STEP


## A line's value: the profile's number filled in, and the approvals as they stand now.
func _value(value: String) -> String:
	if value.contains("{approved}"):
		return value.replace("{approved}", StoryFill.number(maxi(_shown, 0)))
	return StoryFill.fill(value, profile) if profile != null else value


func _leader(label: String, value: String, font: Font, x: float, y: float, width: float) -> void:
	var said := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, TYPE).x
	var led := font.get_string_size(label + " ", HORIZONTAL_ALIGNMENT_LEFT, -1, TYPE).x
	var dot := font.get_string_size(".", HORIZONTAL_ALIGNMENT_LEFT, -1, TYPE).x
	var dots := " " + ".".repeat(maxi(int((width - said - led - dot) / maxf(dot, 1.0)), 2))
	draw_string(
		font, Vector2(x, y), label + dots, HORIZONTAL_ALIGNMENT_LEFT, -1, TYPE, HouseTheme.INK
	)
	draw_string(
		font,
		Vector2(x + width - said, y),
		value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		TYPE,
		HouseTheme.INK
	)
