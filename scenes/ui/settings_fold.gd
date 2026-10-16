class_name SettingsFold
extends VBoxContainer
## One of the match settings' two columns, GAME.md 9.6, The floor or House rules: a head with the
## column's name on it and a chevron at its end, over the column's rows. Folded, the rows are put
## away and the head carries two lines of fine print saying what they are set to instead, and a
## press anywhere on it opens it again. Pressing the head of an open column folds it.

## The head was pressed: it is open or folded now as [param open] says.
signal turned(open: bool)

## How tall the head is open, with only the name on it, and folded, with the fine print under.
const HEAD_OPEN := 52.0
const HEAD_FOLDED := 104.0
## How far in from the head's sides its words keep, and how long the fine print takes to come back
## from gold after a preset changed it.
const HEAD_ROOM := 22.0
const FLASH := 0.9
## The chevron at the head's end: how far across it is and how thick its stroke.
const CHEVRON := 9.0
const CHEVRON_WIDTH := 2.4

## The rows: put them in here.
var body: VBoxContainer
## The head, the one thing of it that takes the cursor while it is folded.
var head: Button
## Whether the rows show.
var open := true:
	set = _set_open
## Whether it is fixed open or folded, as the Final Hand has both columns open, STORY.md 8.1.
var locked := false:
	set(value):
		locked = value
		head.disabled = value
		# No chevron on a head that does not fold, which would say it did.
		_chevron.visible = not value

var _name: Label
var _lines: Array[Label] = []
var _chevron: Control
var _flash: Tween


static func make(named: String, starts_open: bool) -> SettingsFold:
	var fold := SettingsFold.new()
	fold._build(named)
	fold.open = starts_open
	return fold


func _build(named: String) -> void:
	add_theme_constant_override("separation", 12)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	head = MenuTheme.button("", Type.BODY)
	head.name = "Head"
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.pressed.connect(_on_head)
	add_child(head)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 2)
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.offset_left = HEAD_ROOM
	words.offset_right = -HEAD_ROOM - CHEVRON * 2.0
	head.add_child(words)
	_name = MenuTheme.title(named, Type.LARGE)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ScreenReader.name(head, named)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(_name)
	for i: int in 2:
		var line := Label.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.clip_text = true
		Type.text(line, Type.LABEL, HouseTheme.QUIET)
		words.add_child(line)
		_lines.append(line)
	_chevron = Control.new()
	_chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chevron.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_chevron.offset_left = -HEAD_ROOM - CHEVRON
	_chevron.offset_right = -HEAD_ROOM
	_chevron.draw.connect(_draw_chevron)
	head.add_child(_chevron)
	body = VBoxContainer.new()
	body.name = "Rows"
	body.add_theme_constant_override("separation", 12)
	add_child(body)


## What the rows are set to, in two lines of fine print for the head while it is folded.
func summarize(first: String, second: String) -> void:
	_lines[0].text = first
	_lines[1].text = second
	ScreenReader.name(head, _name.text, ScreenReader.line([first, second]))


## The fine print in gold for a moment, coming back to its own ink: something other than the rows
## themselves changed what they are set to, a preset, and the head says so while they are folded.
func flash() -> void:
	if open or not is_inside_tree():
		return
	if _flash != null and _flash.is_valid():
		_flash.kill()
	_flash = create_tween()
	_flash.tween_method(_ink, 0.0, 1.0, FLASH).set_ease(Tween.EASE_IN)


## The first thing in the rows that takes the cursor, or null.
func first_row() -> Control:
	return _first_in(body)


static func _first_in(node: Node) -> Control:
	var control := node as Control
	if (
		control != null
		and control.focus_mode == Control.FOCUS_ALL
		and control.is_visible_in_tree()
		and not (control is BaseButton and (control as BaseButton).disabled)
	):
		return control
	for child: Node in node.get_children():
		var found := _first_in(child)
		if found != null:
			return found
	return null


func _set_open(value: bool) -> void:
	open = value
	body.visible = value
	for line: Label in _lines:
		line.visible = not value
	head.custom_minimum_size.y = HEAD_OPEN if value else HEAD_FOLDED
	_chevron.queue_redraw()


func _on_head() -> void:
	if locked:
		return
	open = not open
	turned.emit(open)


func _ink(along: float) -> void:
	var ink := HouseTheme.FOIL.lerp(HouseTheme.QUIET, along)
	for line: Label in _lines:
		line.add_theme_color_override("font_color", ink)


## A chevron pointing down at the rows while they show, and to the side while they are folded.
func _draw_chevron() -> void:
	var middle := _chevron.size * 0.5
	var half := CHEVRON * 0.5
	var points := (
		PackedVector2Array(
			[
				middle + Vector2(-half, -half * 0.5),
				middle + Vector2(0.0, half * 0.5),
				middle + Vector2(half, -half * 0.5)
			]
		)
		if open
		else PackedVector2Array(
			[
				middle + Vector2(-half * 0.5, -half),
				middle + Vector2(half * 0.5, 0.0),
				middle + Vector2(-half * 0.5, half)
			]
		)
	)
	_chevron.draw_polyline(points, HouseTheme.FOIL, CHEVRON_WIDTH, true)
