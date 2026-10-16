class_name FolderPeek
extends Control
## Kit's notes on the title, STORY.md 7.2: a plain manila folder standing upright, as it is when it
## opens, dog-eared, nothing of the House's on it but OFF THE BOOKS in marker across it, its front
## laid out as the cover's, see [FolderCover], peeking in from the left edge the way the license
## peeks in from the right. It slides out under the cursor, or when the menu's cursor comes to it
## from the buttons, and opens on a click, a tap or the accept button. While a note is new a corner
## of that note's own paper sticks up out of the folder's top edge with an exclamation mark
## pencilled on it, the first new note's when there are several. Not the House's: no foil, no
## engraving, no notches. [member standing], it is the folder as the License tab of the settings
## shows it beside the license, upright and still, taking the cursor under the mouse, and opening
## the same way; and [member waiting], grayed with an hourglass on it while a note taken in the map
## under way waits for the map to be over.

signal opened

## How big it is, and how far down its front starts, under the back's tab and the leaves showing
## over the front's top edge: the front in the open folder's cover's proportions.
const SIZE := Vector2(236.0, 354.0)
const FRONT_TOP := 44.0
## How much of it shows, how far it leans, where it sits over the bottom edge and how far in it
## comes out under the cursor, mirroring the license's.
const PEEK := 0.7
const TILT := 0.14
const TILT_OUT := 0.04
const BOTTOM := 72.0
const IN := 28.0
const SLIDE := 0.25
const DIM := Color(0.8, 0.8, 0.82, 0.9)
const MANILA := NotesFolder.MANILA
const MANILA_DARK := NotesFolder.MANILA_DARK
const DOG_EAR := 30.0
## Drawing the eye after a map, see [method beckon]: how many times the cover opens a little and
## shuts, how far, a share of its width left as it swings toward the eye, and how long between.
const BECKONS := 3
const BECKON_OPEN := 0.32
const BECKON_GAP := 1.4
## Waiting, see [member waiting]: how gray it is, and the hourglass on its front, how big its disc
## is and its ink.
const WAITING_TINT := Color(0.5, 0.5, 0.52)
const HOURGLASS := 44.0
const HOURGLASS_INK := HouseTheme.FOIL

## The note whose corner sticks up, 0 for none.
var corner := 0
var out := false
## Standing in a layout rather than peeking in at an edge: upright, lit and still, see the class.
var standing := false
## A note taken in the map under way, not to be read until the map is over, STORY.md 7.2: grayed,
## an hourglass on it, and it neither takes the cursor nor opens. Set before it is added.
var waiting := false

## The title's buttons, which going right comes back to, see [method add_to].
var _buttons: Array[Control] = []
## The front cover, a child of its own so it can swing open, and the opening and shutting under way.
var _front: Control
var _beckoning: Tween


## The folder for [param of]'s notes in [param title], the menu's cursor reaching it from
## [param buttons] going left and going back to whichever of them showing is nearest its height
## going right, see [PeekWays].
static func add_to(title: Control, of: Profile, buttons: Array[Control]) -> FolderPeek:
	var peek := FolderPeek.new()
	peek.name = "FolderPeek"
	peek.corner = first_new(of.story)
	peek._buttons = buttons
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
	if not standing:
		rotation = TILT
		modulate = DIM
	focus_mode = Control.FOCUS_NONE if waiting else Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	PointerHand.point(self, not waiting)
	if standing and not TouchInput.enabled and not waiting:
		# Under the mouse it takes the cursor, mark and all, to say it can be clicked.
		mouse_entered.connect(grab_focus)
	elif not standing and not TouchInput.enabled:
		mouse_entered.connect(slide.bind(true))
		mouse_exited.connect(func() -> void: slide(has_focus()))
	focus_entered.connect(slide.bind(true))
	focus_exited.connect(slide.bind(false))
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	gui_input.connect(_on_input)
	# Nothing round it: it is not one of the House's buttons.
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# The cover, hinged on the spine at its left edge.
	_front = Control.new()
	_front.name = "Front"
	_front.size = SIZE
	_front.pivot_offset = Vector2(0.0, SIZE.y * 0.5)
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.draw.connect(_draw_front)
	add_child(_front)
	focus_entered.connect(_front.queue_redraw)
	focus_exited.connect(_front.queue_redraw)
	if waiting:
		self_modulate = WAITING_TINT
		_front.modulate = WAITING_TINT
		var glass := Control.new()
		glass.name = "Hourglass"
		glass.size = SIZE
		glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glass.draw.connect(_draw_hourglass.bind(glass))
		add_child(glass)


## Draws the eye to it, after a map in which a note was taken, STORY.md 7.2: it comes out from the
## edge, and its cover opens a little and shuts again, a few times over, the way a folder is shown
## to somebody across a table; then back as it was.
func beckon() -> void:
	if _beckoning != null and _beckoning.is_valid():
		_beckoning.kill()
	slide(true)
	_beckoning = create_tween()
	for i: int in BECKONS:
		_beckoning.tween_interval(0.35 if i == 0 else BECKON_GAP)
		_beckoning.tween_callback(Audio.play_sfx.bind(&"leaf", -16.0, 0.1))
		(
			_beckoning
			. tween_property(_front, "scale:x", BECKON_OPEN, 0.32)
			. set_trans(Tween.TRANS_SINE)
			. set_ease(Tween.EASE_OUT)
		)
		_beckoning.parallel().tween_property(_front, "modulate", Color(0.8, 0.8, 0.8), 0.32)
		_beckoning.tween_interval(0.22)
		(
			_beckoning
			. tween_property(_front, "scale:x", 1.0, 0.28)
			. set_trans(Tween.TRANS_SINE)
			. set_ease(Tween.EASE_IN)
		)
		_beckoning.parallel().tween_property(_front, "modulate", Color.WHITE, 0.28)
	_beckoning.tween_callback(func() -> void: slide(has_focus()))


## Whether it is opening and shutting to draw the eye.
func is_beckoning() -> bool:
	return _beckoning != null and _beckoning.is_valid()


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
	if standing or to_out == out:
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
	if waiting:
		return
	if not standing and event.is_action_pressed(&"ui_right", true):
		var button := PeekWays.nearest(_buttons, self)
		if button != null:
			accept_event()
			button.grab_focus()
		return
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
	# The back of the folder with its tab, the leaves inside showing over the front's edge, the new
	# note's corner, and inside under the front, which is a child of its own, see [method
	# _draw_front].
	var back := Rect2(0.0, 26.0, SIZE.x, SIZE.y - 26.0)
	draw_rect(back, MANILA_DARK)
	var tab := StyleBoxFlat.new()
	tab.bg_color = MANILA_DARK
	tab.corner_radius_top_left = 8
	tab.corner_radius_top_right = 8
	draw_style_box(tab, Rect2(14.0, 4.0, 92.0, 30.0))
	draw_rect(Rect2(8.0, 20.0, SIZE.x - 24.0, 60.0), NotePage.LEAF)
	draw_rect(Rect2(14.0, 16.0, SIZE.x - 36.0, 40.0), NotePage.LEAF.darkened(0.04))
	if corner > 0:
		_draw_corner()
	# Inside, under the cover: the manila, and the first page lying on it.
	draw_rect(Rect2(0.0, FRONT_TOP, SIZE.x, SIZE.y - FRONT_TOP), NotesFolder.MANILA_INSIDE)
	draw_rect(Rect2(10.0, FRONT_TOP + 8.0, SIZE.x - 22.0, SIZE.y - FRONT_TOP - 16.0), NotePage.LEAF)
	draw_line(Vector2(5.0, FRONT_TOP), Vector2(5.0, SIZE.y), MANILA_DARK, 2.0)


## The front cover, on its own child: its top right corner dog-eared, and the cursor's mark while
## the menu's cursor is on the folder, the menu being off to its right.
func _draw_front() -> void:
	var front := PackedVector2Array(
		[
			Vector2(0.0, FRONT_TOP),
			Vector2(SIZE.x - DOG_EAR, FRONT_TOP),
			Vector2(SIZE.x, FRONT_TOP + DOG_EAR),
			Vector2(SIZE.x, SIZE.y),
			Vector2(0.0, SIZE.y),
		]
	)
	_front.draw_colored_polygon(front, MANILA)
	var ear := PackedVector2Array(
		[
			Vector2(SIZE.x - DOG_EAR, FRONT_TOP),
			Vector2(SIZE.x, FRONT_TOP + DOG_EAR),
			Vector2(SIZE.x - DOG_EAR, FRONT_TOP + DOG_EAR),
		]
	)
	_front.draw_colored_polygon(ear, MANILA.darkened(0.12))
	_front.draw_polyline(front, MANILA_DARK.darkened(0.15), 1.0, true)
	FolderCover.draw_front(_front, Rect2(0.0, FRONT_TOP, SIZE.x, SIZE.y - FRONT_TOP))
	if has_focus():
		FocusMark.draw_on(_front, Rect2(0.0, 4.0, SIZE.x, SIZE.y - 4.0), 6.0, SIDE_RIGHT, scale.x)


## An hourglass on a dark disc low on the front, under OFF THE BOOKS, its sand mostly run through,
## while the folder waits for the map to be over.
func _draw_hourglass(on: Control) -> void:
	var at := Vector2(SIZE.x * 0.5, FRONT_TOP + (SIZE.y - FRONT_TOP) * 0.74)
	on.draw_circle(at, HOURGLASS, Color(0.08, 0.08, 0.1, 0.92))
	on.draw_arc(at, HOURGLASS, 0.0, TAU, 48, HOURGLASS_INK, 3.0, true)
	var half := Vector2(HOURGLASS * 0.42, HOURGLASS * 0.56)
	for way: float in [-1.0, 1.0]:
		var bar := at.y + way * half.y
		on.draw_line(
			Vector2(at.x - half.x - 5.0, bar), Vector2(at.x + half.x + 5.0, bar), HOURGLASS_INK, 4.0
		)
	var glass := PackedVector2Array(
		[
			at + Vector2(-half.x, -half.y + 3.0),
			at + Vector2(half.x, -half.y + 3.0),
			at + Vector2(3.0, 0.0),
			at + Vector2(half.x, half.y - 3.0),
			at + Vector2(-half.x, half.y - 3.0),
			at + Vector2(-3.0, 0.0),
			at + Vector2(-half.x, -half.y + 3.0),
		]
	)
	on.draw_polyline(glass, HOURGLASS_INK, 2.5, true)
	# A little sand left over the waist, a thread of it falling, and the heap under it.
	var top := PackedVector2Array(
		[at + Vector2(-half.x * 0.42, -6.0), at + Vector2(half.x * 0.42, -6.0), at]
	)
	on.draw_colored_polygon(top, HOURGLASS_INK)
	on.draw_line(at, at + Vector2(0.0, half.y - 10.0), HOURGLASS_INK, 1.5)
	var heap := PackedVector2Array(
		[
			at + Vector2(-half.x + 5.0, half.y - 5.0),
			at + Vector2(half.x - 5.0, half.y - 5.0),
			at + Vector2(0.0, half.y * 0.4),
		]
	)
	on.draw_colored_polygon(heap, HOURGLASS_INK)


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
	NotePage.new_mark(self, Vector2(0.0, -6.0), 13.0 / 15.0, ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
