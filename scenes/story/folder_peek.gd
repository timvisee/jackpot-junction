class_name FolderPeek
extends Control
## Kit's notes on the title, STORY.md 7.2: a plain manila folder, dog-eared, nothing printed on it,
## peeking in from the left edge the way the license peeks in from the right. It slides out under
## the cursor, or when the menu's cursor comes to it from the buttons, and opens on a click, a tap
## or the accept button. While a note is new a corner of that note's own paper sticks up out of the
## folder's top edge with an exclamation mark pencilled on it, the first new note's when there are
## several. Not the House's: no foil, no engraving, no notches.

signal opened

const SIZE := Vector2(300.0, 230.0)
## How much of it shows, how far it leans, where it sits over the bottom edge and how far in it
## comes out under the cursor, mirroring the license's.
const PEEK := 0.62
const TILT := 0.14
const TILT_OUT := 0.04
const BOTTOM := 72.0
const IN := 28.0
const SLIDE := 0.25
const DIM := Color(0.8, 0.8, 0.82, 0.9)
const MANILA := NotesFolder.MANILA
const MANILA_DARK := NotesFolder.MANILA_DARK
const DOG_EAR := 30.0

## The note whose corner sticks up, 0 for none.
var corner := 0
var out := false


## The folder for [param of]'s notes in [param title], the menu's cursor reaching it from
## [param buttons] going left and going back to the first of them going right.
static func add_to(title: Control, of: Profile, buttons: Array[Control]) -> FolderPeek:
	var peek := FolderPeek.new()
	peek.name = "FolderPeek"
	peek.corner = first_new(of.story)
	title.add_child(peek)
	for button: Control in buttons:
		button.focus_neighbor_left = button.get_path_to(peek)
	if not buttons.is_empty():
		peek.focus_neighbor_right = peek.get_path_to(buttons[0])
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_BOTTOM]:
		peek.set_focus_neighbor(side, peek.get_path())
	title.resized.connect(peek.place)
	peek.place()
	return peek


## The first note [param story] has found and not read, 0 for none.
static func first_new(story: StoryState) -> int:
	for number: int in NotesFolder.in_order(story):
		if story.is_new(number):
			return number
	return 0


func _ready() -> void:
	size = SIZE
	pivot_offset = SIZE * 0.5
	rotation = TILT
	modulate = DIM
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not TouchInput.enabled:
		mouse_entered.connect(slide.bind(true))
		mouse_exited.connect(func() -> void: slide(has_focus()))
	focus_entered.connect(slide.bind(true))
	focus_exited.connect(slide.bind(false))
	gui_input.connect(_on_input)
	# Nothing round it: it is not one of the House's buttons.
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Where its middle is, out or peeking in, on the left edge of its parent.
func middle(is_out: bool) -> Vector2:
	var parent := get_parent() as Control
	var tall := parent.size.y if parent != null else 1080.0
	var y := tall - SIZE.y * 0.5 - BOTTOM
	if is_out:
		return Vector2(SIZE.x * 0.5 + IN, y)
	return Vector2(SIZE.x * PEEK - SIZE.x * 0.5, y)


func place() -> void:
	position = middle(out) - SIZE * 0.5


func slide(to_out: bool) -> void:
	if to_out == out:
		return
	out = to_out
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(self, "position", middle(out) - SIZE * 0.5, SLIDE)
	tween.tween_property(self, "rotation", TILT_OUT if out else TILT, SLIDE)
	tween.tween_property(self, "modulate", Color.WHITE if out else DIM, SLIDE)
	if out:
		Audio.play_sfx(&"ui_move", MenuTheme.MOVE_DB, 0.0)


func _on_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (
		(click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
		or (touch != null and touch.pressed)
		or event.is_action_pressed(&"ui_accept")
	):
		accept_event()
		opened.emit()


func _draw() -> void:
	# The back of the folder with its tab, the leaves inside showing over the front's edge, the
	# new note's corner, and the front, its top right corner dog-eared.
	var back := Rect2(0.0, 26.0, SIZE.x, SIZE.y - 26.0)
	draw_rect(back, MANILA_DARK)
	var tab := StyleBoxFlat.new()
	tab.bg_color = MANILA_DARK
	tab.corner_radius_top_left = 8
	tab.corner_radius_top_right = 8
	draw_style_box(tab, Rect2(18.0, 4.0, 110.0, 30.0))
	draw_rect(Rect2(10.0, 20.0, SIZE.x - 30.0, 60.0), NotePage.LEAF)
	draw_rect(Rect2(16.0, 16.0, SIZE.x - 44.0, 40.0), NotePage.LEAF.darkened(0.04))
	if corner > 0:
		_draw_corner()
	var front := PackedVector2Array(
		[
			Vector2(0.0, 44.0),
			Vector2(SIZE.x - DOG_EAR, 44.0),
			Vector2(SIZE.x, 44.0 + DOG_EAR),
			Vector2(SIZE.x, SIZE.y),
			Vector2(0.0, SIZE.y),
		]
	)
	draw_colored_polygon(front, MANILA)
	var ear := PackedVector2Array(
		[
			Vector2(SIZE.x - DOG_EAR, 44.0),
			Vector2(SIZE.x, 44.0 + DOG_EAR),
			Vector2(SIZE.x - DOG_EAR, 44.0 + DOG_EAR),
		]
	)
	draw_colored_polygon(ear, MANILA.darkened(0.12))
	draw_polyline(front, MANILA_DARK.darkened(0.15), 1.0, true)


## A corner of the new note's own paper up out of the folder, an exclamation mark pencilled on it.
func _draw_corner() -> void:
	var kind := StringName(StoryNotes.NOTES.get(corner, {}).get("paper", &"sheet"))
	var spec: Array = NotePage.PAPERS.get(kind, NotePage.PAPERS[&"sheet"])
	var paper: Color = spec[1]
	draw_set_transform(Vector2(SIZE.x * 0.62, 30.0), -0.16, Vector2.ONE)
	var sheet := Rect2(Vector2(-34.0, -28.0), Vector2(68.0, 60.0))
	draw_rect(Rect2(sheet.position + Vector2(2.0, 2.0), sheet.size), Color(0.0, 0.0, 0.0, 0.15))
	draw_rect(sheet, paper)
	if kind == &"graph" or kind == &"graph_torn":
		for i: int in 6:
			draw_line(
				Vector2(-34.0 + i * 12.0, -28.0),
				Vector2(-34.0 + i * 12.0, 32.0),
				NotePaper.GRAPH_LINE,
				1.0
			)
	var ink := Color(0.92, 0.9, 0.84) if paper.get_luminance() < 0.4 else NotePage.PENCIL
	draw_arc(Vector2(0.0, -6.0), 13.0, 0.3, TAU + 0.1, 20, ink, 1.6, true)
	draw_char(NotePage.HAND, Vector2(-4.0, 3.0), "!", 20, ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
