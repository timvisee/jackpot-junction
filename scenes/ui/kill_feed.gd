class_name KillFeed
extends VBoxContainer
## The last few kills in the top right, GAME.md 8.3, newest at the top: who took out whom and
## how. Lines hold for a few seconds and fade away, and only the newest handful are kept, so the
## feed never grows into the arena.

const MAX_ROWS := 5
const HOLD := 6.0
const FADE := 1.2
const FONT_SIZE := 18
## Colour for the verb between the two names, and for a death nobody gets credit for.
const NEUTRAL := Color(0.78, 0.78, 0.82)

## How a death reads, by the cause the match reports.
const VERBS: Dictionary[StringName, String] = {
	&"bullet": "shot",
	&"ram": "rammed",
	&"bomb": "bombed",
	&"pit": "shoved",
}

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
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	label.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	label.add_theme_color_override("default_color", NEUTRAL)
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
## bumped the victim into it.
func _line(
	victim: String, victim_color: Color, killer: String, killer_color: Color, cause: StringName
) -> String:
	var red := _tag(victim, victim_color)
	if cause == &"line":
		return red
	if killer.is_empty():
		return "%s %s" % [red, "fell in" if cause == &"pit" else "wrecked itself"]
	if killer == victim:
		return "%s wrecked itself" % red
	var verb: String = VERBS.get(cause, "took out")
	if cause == &"pit":
		return "%s shoved %s in" % [_tag(killer, killer_color), red]
	return "%s %s %s" % [_tag(killer, killer_color), verb, red]


func _tag(text: String, color: Color) -> String:
	return "[b][color=#%s]%s[/color][/b]" % [color.to_html(false), text]
