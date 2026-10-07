class_name NoteCollected
extends Control
## The torn scrap that says NOTE COLLECTED in a player's corner for two seconds once they have
## driven over one of Kit's notes, STORY.md 7.1: paper folding itself away into the corner, the
## words in pencil, the one thing on the HUD the House did not print. Beside the corner's block,
## toward the middle of the screen, rather than on it, the block being the House's tag, and clear of
## the control hints under it. It never says which note or how many.

const LASTS := 2.0
const FOLD_IN := 0.22
const FADE := 0.3
const SIZE := Vector2(250.0, 56.0)
## How far off the corner's block it sits, and how far in from the screen's edge.
const GAP := 12.0
const INSET := 18.0
const PAPER := Color(0.93, 0.91, 0.85)
const PENCIL := Color(0.28, 0.28, 0.31)
const FONT_SIZE := 21
const TILT := -0.04

var _block: Control
var _right := false
var _bottom := false
var _age := 0.0


## Puts the scrap up in [param hud] beside [param block], the corner of the player who took the
## note, or in the top left corner with no block to go beside.
static func show_beside(hud: Node, block: Control) -> NoteCollected:
	var scrap := NoteCollected.new()
	scrap.name = "NoteCollected"
	scrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrap.size = SIZE
	scrap._block = block
	if block != null:
		scrap._right = block.anchor_left >= 0.5
		scrap._bottom = block.anchor_top >= 0.5
	scrap.pivot_offset = Vector2(SIZE.x if scrap._right else 0.0, SIZE.y if scrap._bottom else 0.0)
	scrap.rotation = TILT * (-1.0 if scrap._right else 1.0)
	hud.add_child(scrap)
	scrap._place()
	scrap.scale = Vector2(0.15, 0.0)
	return scrap


func _process(delta: float) -> void:
	_age += delta
	if _age >= LASTS:
		queue_free()
		return
	_place()
	var opening := clampf(_age / FOLD_IN, 0.0, 1.0)
	# Unfolding into the corner: across first, then down, the way a scrap is flattened out.
	scale = Vector2(
		lerpf(0.15, 1.0, ease(opening, 0.4)), ease(clampf(opening * 1.4, 0.0, 1.0), 0.5)
	)
	modulate.a = clampf((LASTS - _age) / FADE, 0.0, 1.0)


## Beside the block on the side toward the middle of the screen, level with its inner edge, or in
## the corner with no block.
func _place() -> void:
	var screen := get_viewport_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
	if _block == null or not is_instance_valid(_block):
		position = Vector2(INSET, INSET)
		return
	var x := _block.position.x + _block.size.x + GAP
	if _right:
		x = _block.position.x - GAP - SIZE.x
	var y := _block.position.y + _block.size.y - SIZE.y
	if _bottom:
		y = _block.position.y
	position = Vector2(clampf(x, 0.0, screen.x - SIZE.x), clampf(y, 0.0, screen.y - SIZE.y))


func _draw() -> void:
	# The scrap, its long edges torn: a zigzag along the top and the bottom, the same every time.
	var points := PackedVector2Array()
	var teeth := 14
	for i: int in teeth + 1:
		var x := SIZE.x * float(i) / float(teeth)
		points.append(Vector2(x, 3.0 + (2.5 if i % 2 == 0 else 0.0) + float(i % 3)))
	for i: int in range(teeth, -1, -1):
		var x := SIZE.x * float(i) / float(teeth)
		points.append(Vector2(x, SIZE.y - 3.0 - (2.0 if i % 2 == 1 else 0.0) - float(i % 4) * 0.7))
	draw_colored_polygon(points, PAPER)
	var font := LicenseCard.SIGNATURE_FONT
	var line := font.get_string_size(
		StoryLines.NOTE_COLLECTED, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE
	)
	var baseline := (SIZE.y + font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) * 0.5
	draw_string(
		font,
		Vector2((SIZE.x - line.x) * 0.5, baseline),
		StoryLines.NOTE_COLLECTED,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		FONT_SIZE,
		PENCIL
	)
