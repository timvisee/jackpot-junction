class_name TearTab
extends Button
## The tab the House's page tears by at the Final Hand, STORY.md 8.4: a flap of the slip's paper
## standing out past its edge beside the stamp's handle, its corner curling up, the destroy button
## drawn on it, the one that has skipped picks all game; level with where the paper tears straight
## across over STATUS, already torn in for a hand's width from the edge. Now and then it flutters,
## as paper does in a draft. The House prints nothing about it; Kit's pencil does, see
## [KitPencil]. Pressed, by that button anywhere while the page is in view, or by a click or a tap
## on the tab, it tears the strip with STATUS on it off, see [HouseEvaluation].

const SIZE := Vector2(96.0, 74.0)
const GLYPH_SIZE := 28
const LEAN := 0.06
## How deep its corner curls, how much of it stands over the tear, and how far in from the slip's
## edge the paper is torn already.
const CURL := 24.0
const HANG := 0.3
const BEGUN := 56.0
## How often it flutters, for how long, and how far.
const FLUTTER_EVERY := 3.4
const FLUTTER_FOR := 0.5
const FLUTTER := 0.07

## Where the paper tears, down from its top, in pixels.
var tear_at := 0.0

var _glyph: Control
var _keyboard := true
var _clock := 0.0


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


func _process(delta: float) -> void:
	_clock += delta
	var lifted := is_hovered() or has_focus()
	var into := fmod(_clock, FLUTTER_EVERY) - (FLUTTER_EVERY - FLUTTER_FOR)
	var flutter := 0.0
	if into > 0.0 and not lifted:
		flutter = FLUTTER * sin(into * 38.0) * sin(PI * into / FLUTTER_FOR)
	rotation = lerpf(rotation, LEAN if lifted else 0.0, 0.25) + flutter * 0.5
	queue_redraw()


## Torn off with the strip, see [TornPage]: nothing more to press, and no more fluttering.
func let_go() -> void:
	disabled = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	set_process_input(false)


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
	glyph.position = Vector2(SIZE.x * 0.52 - wide.x * 0.5, (SIZE.y - wide.y) * 0.5 + 2.0)
	_glyph = glyph


func _draw() -> void:
	var lifted := is_hovered() or has_focus()
	_draw_begun()
	var flap := PackedVector2Array(
		[
			Vector2(0.0, 8.0),
			Vector2(SIZE.x - CURL, 0.0),
			Vector2(SIZE.x, CURL - 2.0),
			Vector2(SIZE.x, SIZE.y - 12.0),
			Vector2(SIZE.x - 12.0, SIZE.y),
			Vector2(0.0, SIZE.y - 8.0),
		]
	)
	var shadow := PackedVector2Array()
	for point: Vector2 in flap:
		shadow.append(point + (Vector2(6.0, 9.0) if lifted else Vector2(4.0, 6.0)))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.32 if lifted else 0.22))
	draw_colored_polygon(flap, HouseTheme.PAPER)
	draw_polyline(flap + PackedVector2Array([flap[0]]), Color(HouseTheme.PAPER_LOW, 0.9), 1.5)
	# Its corner curling up off it, the paper's back showing.
	var curl := PackedVector2Array([flap[1], flap[2], Vector2(SIZE.x - CURL + 2.0, CURL - 4.0)])
	draw_colored_polygon(curl, HouseTheme.PAPER_LOW)
	draw_line(curl[0], curl[1], Color(HouseTheme.INK_FAINT, 0.5), 1.2)
	# Where it joins the slip, the fold it is torn by.
	draw_dashed_line(
		Vector2(5.0, 8.0), Vector2(5.0, SIZE.y - 8.0), Color(HouseTheme.INK_FAINT, 0.6), 1.2, 4.0
	)
	if lifted:
		draw_polyline(flap + PackedVector2Array([flap[0]]), Color(HouseTheme.FOIL_LOW, 0.9), 2.0)


## The paper torn in already from the slip's edge by the tab, straight across where it will tear.
func _draw_begun() -> void:
	# On the slip, which stays put however the tab leans.
	var pivot := pivot_offset
	draw_set_transform_matrix(Transform2D(-rotation, pivot - pivot.rotated(-rotation)))
	var crack := PackedVector2Array()
	var steps := 14
	for i: int in steps + 1:
		var t := float(i) / float(steps)
		var open := 2.6 * pow(1.0 - t, 1.3)
		crack.append(Vector2(8.0 - BEGUN * t, tear_at - open - (0.6 if i % 3 == 1 else 0.0)))
	for i: int in range(steps, -1, -1):
		var t := float(i) / float(steps)
		var open := 2.6 * pow(1.0 - t, 1.3)
		crack.append(Vector2(8.0 - BEGUN * t, tear_at + open + (0.6 if i % 3 == 2 else 0.0)))
	draw_colored_polygon(crack, Color(0.04, 0.04, 0.05, 0.85))
	draw_set_transform_matrix(Transform2D.IDENTITY)
