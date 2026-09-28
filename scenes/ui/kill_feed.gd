class_name KillFeed
extends VBoxContainer
## The last few kills in the top right, GAME.md 8.3, newest at the top: who took out whom and
## how. Lines hold for a few seconds and fade away, and only the newest handful are kept, so the
## feed never grows into the arena.

const MAX_ROWS := 5
const HOLD := 6.0
const FADE := 1.2
const FONT_SIZE := 18
## Color for the verb between the two names, and for a death nobody gets credit for.
const NEUTRAL := Color(0.78, 0.78, 0.82)

## How a death reads, by the cause the match reports.
const VERBS: Dictionary[StringName, String] = {
	&"bullet": "shot",
	&"ram": "rammed",
	&"bomb": "bombed",
	&"pit": "shoved",
}

## How tall the feed may grow, or 0 for as tall as its rows make it. On a touch screen it hangs over
## the corner the driving buttons are in and stops short of them, GAME.md 4.2, dropping its oldest
## lines first.
var room := 0.0

## Row labels newest first, each with the seconds it has been up.
var _rows: Array[RichTextLabel] = []
var _ages: PackedFloat32Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_right = -16.0
	offset_top = 16.0
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func row_count() -> int:
	return _rows.size()


## The newest line's plain text, for tests.
func newest_text() -> String:
	return _rows[0].get_parsed_text() if not _rows.is_empty() else ""


## Adds a kill. [param killer] is empty when nobody gets the credit, for example a kart that
## drove into a pit by itself.
func add_kill(
	victim: String, victim_color: Color, killer: String, killer_color: Color, cause: StringName
) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("normal_font", Type.TEXT)
	label.add_theme_font_override("bold_font", Type.STRONG)
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	label.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	label.add_theme_color_override("default_color", NEUTRAL)
	# A line of colored names over a bright table is a line nobody can read, GAME.md 8.3, so
	# every one of them carries its own scrim rather than trusting the felt to be dark.
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	_push(label, _line(victim, victim_color, killer, killer_color, cause))


## Adds a line of its own, for news that is not a kill: a bounty called or collected.
func add_line(text: String, color: Color) -> void:
	add_kill(text, color, "", color, &"line")


func _push(label: RichTextLabel, line: String) -> void:
	label.text = "[right]%s[/right]" % line
	add_child(label)
	move_child(label, 0)
	_rows.push_front(label)
	_ages.insert(0, 0.0)
	while _rows.size() > MAX_ROWS:
		_drop(_rows.size() - 1)


func _process(delta: float) -> void:
	while room > 0.0 and _rows.size() > 1 and get_combined_minimum_size().y > room:
		_drop(_rows.size() - 1)
	for i: int in range(_rows.size() - 1, -1, -1):
		_ages[i] += delta
		var over := _ages[i] - HOLD
		if over >= FADE:
			_drop(i)
		elif over > 0.0:
			_rows[i].modulate.a = 1.0 - over / FADE


func _drop(index: int) -> void:
	_rows[index].queue_free()
	_rows.remove_at(index)
	_ages.remove_at(index)


## The wording. Without a killer the kart wrecked itself, and a pit is a fall unless someone
## bumped the victim into it. A turret's kill is its owner's, and says whose turret it was: a
## player who was shot by somebody on the far side of the room wants to know it was the turret
## that got them, not the kart they can see nowhere near.
func _line(
	victim: String, victim_color: Color, killer: String, killer_color: Color, cause: StringName
) -> String:
	var red := _tag(victim, victim_color)
	if cause == &"line":
		return red
	if killer.is_empty():
		return "%s %s" % [red, "fell in" if cause == &"pit" else "wrecked itself"]
	if killer == victim:
		var own := "was shot by their own turret" if cause == &"turret" else "wrecked itself"
		return "%s %s" % [red, own]
	return _by(_tag(killer, killer_color), red, cause)


## A kill somebody else made, by [param cause]: [param blue] did it to [param red].
static func _by(blue: String, red: String, cause: StringName) -> String:
	match cause:
		&"pit":
			return "%s shoved %s in" % [blue, red]
		&"turret":
			return "%s's turret shot %s" % [blue, red]
	return "%s %s %s" % [blue, VERBS.get(cause, "took out"), red]


func _tag(text: String, color: Color) -> String:
	return "[b][color=#%s]%s[/color][/b]" % [color.to_html(false), text]
