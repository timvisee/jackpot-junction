class_name TearTab
extends Button
## The tab at the end of the perforation the House's page hangs from at the Final Hand, STORY.md
## 8.4: a little flap of the slip's paper standing out past its edge, the destroy button drawn on
## it, the one that has skipped picks all game. The House prints nothing about it. Pressed, by that
## button anywhere while the page is in view, or by a click or a tap on the tab, it tears the page
## off, see [HouseEvaluation].

const SIZE := Vector2(74.0, 56.0)
const GLYPH_SIZE := 22
const LEAN := 0.06

var _glyph: Control
var _keyboard := true


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = Vector2(0.0, SIZE.y * 0.5)
	focus_mode = Control.FOCUS_ALL
	flat = true
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	ScreenReader.name(self, StoryLines.TEAR_OFF)
	_keyboard = Game.last_input_keyboard
	_show_glyph()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var was := _keyboard
	_keyboard = LicenseView.keyboard_after(event, _keyboard)
	if was != _keyboard:
		_show_glyph()


func _process(_delta: float) -> void:
	var lifted := is_hovered() or has_focus()
	rotation = lerpf(rotation, LEAN if lifted else 0.0, 0.25)
	queue_redraw()


## The destroy button for the device in hand, on the flap; a finger on a touch screen.
func _show_glyph() -> void:
	if _glyph != null:
		_glyph.queue_free()
		_glyph = null
	# The key's own letter light on its dark cap, as the hints draw it; a finger in the paper's ink.
	var ink := Palette.CHIP_WHITE
	var glyph := (
		InputGlyph.of_finger(HouseTheme.INK, GLYPH_SIZE)
		if TouchInput.enabled
		else InputHint.glyph(InputActions.JOKER_DESTROY, _keyboard, ink, GLYPH_SIZE)
	)
	if glyph == null:
		return
	glyph.name = "DestroyGlyph"
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glyph)
	var wide := glyph.get_combined_minimum_size()
	glyph.position = Vector2(SIZE.x * 0.56 - wide.x * 0.5, (SIZE.y - wide.y) * 0.5)
	_glyph = glyph


func _draw() -> void:
	var lifted := is_hovered() or has_focus()
	var flap := PackedVector2Array(
		[
			Vector2(0.0, 6.0),
			Vector2(SIZE.x - 10.0, 0.0),
			Vector2(SIZE.x, 10.0),
			Vector2(SIZE.x, SIZE.y - 10.0),
			Vector2(SIZE.x - 10.0, SIZE.y),
			Vector2(0.0, SIZE.y - 6.0),
		]
	)
	var shadow := PackedVector2Array()
	for point: Vector2 in flap:
		shadow.append(point + Vector2(3.0, 5.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.25 if lifted else 0.15))
	draw_colored_polygon(flap, HouseTheme.PAPER)
	draw_polyline(flap + PackedVector2Array([flap[0]]), Color(HouseTheme.PAPER_LOW, 0.9), 1.5)
	# Where it joins the slip, the fold it is torn by.
	draw_dashed_line(
		Vector2(5.0, 6.0), Vector2(5.0, SIZE.y - 6.0), Color(HouseTheme.INK_FAINT, 0.6), 1.2, 4.0
	)
	if lifted:
		draw_polyline(flap + PackedVector2Array([flap[0]]), Color(HouseTheme.FOIL_LOW, 0.9), 2.0)
