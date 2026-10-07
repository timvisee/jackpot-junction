class_name NoteCollected
extends Control
## NOTE COLLECTED once a player has driven over one of Kit's notes, STORY.md 7.1: a big torn scrap
## of paper unfolds in the middle of the screen, where the announcer's calls go, and the words are
## written on it in pencil as it is watched, with the pencil's scratch; it holds, then shrinks away
## into the player's corner, beside the corner's block toward the middle of the screen, and stays
## there for two seconds. The one thing on the HUD the House did not print. A call of the
## announcer's already up goes first. It never says which note or how many.

enum Phase { WAITING, WRITING, HOLDING, GOING, CORNER }

## The scrap as it is written on, and as it is in the corner.
const BIG := Vector2(560.0, 118.0)
const SMALL := Vector2(250.0, 53.0)
const FONT_SIZE := 64
## How long it unfolds, how long the words take to write, how long it holds, how long it takes to
## go to the corner, how long it stays there and how long it fades for.
const FOLD_IN := 0.22
const WRITE := 0.6
const HOLD := 1.0
const GO := 0.38
const LASTS := 2.0
const FADE := 0.3
## The longest it waits for a call already up before it is written anyway.
const WAIT_AT_MOST := 4.0
## How far off the corner's block it sits, and how far in from the screen's edge.
const GAP := 12.0
const INSET := 18.0
const PAPER := Color(0.93, 0.91, 0.85)
const PENCIL := Color(0.26, 0.26, 0.3)
const TILT := -0.04
## How far under the middle of the screen it is written, with the announcer's calls.
const DROP := 120.0

var phase := Phase.WAITING

var _hud: Node
var _block: Control
var _right := false
var _bottom := false
var _age := 0.0
var _waited := 0.0
var _written := 0.0


## Puts the scrap up in [param hud], to go beside [param block], the corner of the player who took
## the note, or to the top left corner with no block to go beside.
static func show_beside(hud: Node, block: Control) -> NoteCollected:
	var scrap := NoteCollected.new()
	scrap.name = "NoteCollected"
	scrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrap.size = BIG
	scrap._hud = hud
	scrap._block = block
	if block != null:
		scrap._right = block.anchor_left >= 0.5
		scrap._bottom = block.anchor_top >= 0.5
	scrap.visible = false
	hud.add_child(scrap)
	return scrap


func _process(delta: float) -> void:
	_age += delta
	match phase:
		Phase.WAITING:
			_waited += delta
			if not _call_up() or _waited >= WAIT_AT_MOST:
				_begin()
		Phase.WRITING:
			_written = clampf(_age / WRITE, 0.0, 1.0)
			_place_middle(clampf(_age / FOLD_IN, 0.0, 1.0))
			queue_redraw()
			if _age >= WRITE:
				_next(Phase.HOLDING)
		Phase.HOLDING:
			_place_middle(1.0)
			if _age >= HOLD:
				_next(Phase.GOING)
		Phase.GOING:
			var t := ease(clampf(_age / GO, 0.0, 1.0), -2.0)
			var from := _middle() - BIG * 0.5
			var to := _corner()
			position = from.lerp(to, t)
			scale = Vector2.ONE * lerpf(1.0, SMALL.x / BIG.x, t)
			rotation = lerpf(0.0, _tilt(), t)
			if _age >= GO:
				_next(Phase.CORNER)
		Phase.CORNER:
			position = _corner()
			scale = Vector2.ONE * (SMALL.x / BIG.x)
			rotation = _tilt()
			modulate.a = clampf((LASTS - _age) / FADE, 0.0, 1.0)
			if _age >= LASTS:
				queue_free()


func _begin() -> void:
	visible = true
	_next(Phase.WRITING)
	_place_middle(0.0)
	Audio.play_sfx(&"pencil", -4.0, 0.06)


func _next(to: Phase) -> void:
	phase = to
	_age = 0.0
	pivot_offset = BIG * 0.5 if to == Phase.WRITING or to == Phase.HOLDING else Vector2.ZERO


## Whether one of the announcer's calls is up, under the middle of the screen.
func _call_up() -> bool:
	var call := _hud.get_node_or_null("Call") as Control if _hud != null else null
	return call != null and call.visible


## Under the middle of the screen, unfolding: across first, then down, the way a scrap is
## flattened out, [param opening] of the way.
func _place_middle(opening: float) -> void:
	position = _middle() - BIG * 0.5
	scale = Vector2(
		lerpf(0.15, 1.0, ease(opening, 0.4)), ease(clampf(opening * 1.4, 0.0, 1.0), 0.5)
	)
	rotation = 0.0


func _middle() -> Vector2:
	var screen := get_viewport_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
	return screen * 0.5 + Vector2(0.0, DROP)


func _tilt() -> float:
	return TILT * (-1.0 if _right else 1.0)


## Beside the block on the side toward the middle of the screen, level with its inner edge, or in
## the corner with no block: where the scrap's top left goes, at its small size.
func _corner() -> Vector2:
	var screen := get_viewport_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
	if _block == null or not is_instance_valid(_block):
		return Vector2(INSET, INSET)
	var x := _block.position.x + _block.size.x + GAP
	if _right:
		x = _block.position.x - GAP - SMALL.x
	var y := _block.position.y + _block.size.y - SMALL.y
	if _bottom:
		y = _block.position.y
	return Vector2(clampf(x, 0.0, screen.x - SMALL.x), clampf(y, 0.0, screen.y - SMALL.y))


func _draw() -> void:
	# The scrap, its long edges torn: a zigzag along the top and the bottom, the same every time.
	var points := PackedVector2Array()
	var teeth := 22
	for i: int in teeth + 1:
		var x := BIG.x * float(i) / float(teeth)
		points.append(Vector2(x, 5.0 + (4.0 if i % 2 == 0 else 0.0) + float(i % 3) * 1.4))
	for i: int in range(teeth, -1, -1):
		var x := BIG.x * float(i) / float(teeth)
		points.append(Vector2(x, BIG.y - 5.0 - (3.5 if i % 2 == 1 else 0.0) - float(i % 4)))
	draw_colored_polygon(
		_shifted(points, Vector2(4.0, 6.0)),
		Color(0.0, 0.0, 0.0, 0.25 if phase != Phase.CORNER else 0.0)
	)
	draw_colored_polygon(points, PAPER)
	# The words as far as the pencil has got.
	var font := NotePage.HAND
	var words := StoryLines.NOTE_COLLECTED
	var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var shown := (
		words.substr(0, ceili(words.length() * _written)) if phase == Phase.WRITING else words
	)
	var baseline := (BIG.y + font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) * 0.5
	draw_string(
		font,
		Vector2((BIG.x - wide) * 0.5, baseline),
		shown,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		FONT_SIZE,
		PENCIL
	)


static func _shifted(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for point: Vector2 in points:
		moved.append(point + by)
	return moved
