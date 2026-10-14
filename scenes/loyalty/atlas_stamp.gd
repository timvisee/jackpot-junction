class_name AtlasStamp
extends Control
## What is stamped on the details' slip while it is on the plans, GAME.md 8.9: a landmark not open
## yet, its slip blueprint paper, see [member AtlasSlipStyle.planned]. A rubber stamp, CONCEPT, in
## white over the slip's words, a little askew and worn; and on a keystone's a seal of red wax with
## a star in it over the foot's right corner. Each is drawn once a run into a picture, see
## [KeptPictures], and shown from that. It stands in the slip, over its words and under its coil,
## and takes no input.

## The stamp: its word, how big the word is, the room round it in its box, its ink, how far it is
## turned, and where it stands, how far across the slip and how far down past the middle of the
## line it is stamped over.
const WORD := "CONCEPT"
const WORD_SIZE := 34
const BOX_ROOM := Vector2(14.0, 6.0)
const INK := Color(0.95, 0.97, 1.0, 0.82)
const TURN := -0.2
const ACROSS := 0.64
const DOWN := 4.0
## How many worn specks of the paper there are through its ink.
const SPECKS := 70
## The wax seal: how big it is round, its wax, the pressed middle and its rim and star, and how
## far in from the slip's foot's right corner its middle is.
const SEAL := 21.0
const WAX := Color("#9b1b1b")
const PRESSED := Color("#b52626")
const PRESSED_RIM := Color("#7a1212")
const SEAL_IN := Vector2(16.0, 20.0)
## The room round each picture for its edge and its shadow.
const ROOM := 6.0

## The line it is stamped over, and the paper it is stamped on, for the specks.
var over: Control
var paper := Color.WHITE
## Whether it is stamped, and whether the seal is on it too.
var stamped := false
var sealed := false


## A picture of the stamp or of the seal, drawn once a run.
class Drawing:
	extends Control

	var seal := false
	var paper := Color.WHITE
	var scale_by := 1.0

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_by)
		var room := size / scale_by
		if seal:
			AtlasStamp.draw_seal(self, room * 0.5)
		else:
			AtlasStamp.draw_stamp(self, room * 0.5, paper)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(AtlasCover.PICTURES)
	resized.connect(queue_redraw)


## Stamped on the plans or not, with the seal or without, see [member stamped].
func show_as(on_plans: bool, with_seal: bool) -> void:
	stamped = on_plans
	sealed = on_plans and with_seal
	queue_redraw()


## How big the stamp is, its box and the room round it.
static func stamp_size() -> Vector2:
	var font := Type.mark_font()
	var wide := font.get_string_size(WORD, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE).x
	return Vector2(wide, WORD_SIZE * 1.24) + BOX_ROOM * 2.0 + Vector2.ONE * ROOM * 2.0


## The stamp on [param on] round [param middle], unturned: its word in a box, a heavy line and a
## fine one inside it, and specks of [param paper] through it where it is worn.
static func draw_stamp(on: CanvasItem, middle: Vector2, paper: Color) -> void:
	var font := Type.mark_font()
	var wide := font.get_string_size(WORD, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE).x
	var box := Rect2(middle - Vector2(wide * 0.5, WORD_SIZE * 0.62) - BOX_ROOM, Vector2.ZERO)
	box.size = Vector2(wide, WORD_SIZE * 1.24) + BOX_ROOM * 2.0
	on.draw_rect(box, INK, false, 3.0)
	on.draw_rect(box.grow(-5.0), Color(INK, INK.a * 0.7), false, 1.5)
	var at := middle + Vector2(-wide * 0.5, WORD_SIZE * 0.36)
	on.draw_string(font, at, WORD, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE, INK)
	var rolls := RandomNumberGenerator.new()
	rolls.seed = 3
	for i: int in SPECKS:
		var speck := Vector2(
			rolls.randf_range(box.position.x, box.end.x),
			rolls.randf_range(box.position.y, box.end.y)
		)
		on.draw_circle(speck, rolls.randf_range(0.6, 1.6), Color(paper, 0.55))


## The wax seal on [param on] round [param middle]: a blob of wax, its edge uneven, the pressed
## round in it with its rim and a star, and a gleam.
static func draw_seal(on: CanvasItem, middle: Vector2) -> void:
	var rolls := RandomNumberGenerator.new()
	rolls.seed = 11
	var blob := PackedVector2Array()
	for i: int in 24:
		blob.append(
			middle + Vector2.from_angle(TAU * i / 24.0) * (SEAL + rolls.randf_range(-2.0, 2.0))
		)
	var fallen := PackedVector2Array()
	for point: Vector2 in blob:
		fallen.append(point + Vector2(1.5, 2.5))
	on.draw_colored_polygon(fallen, Color(0.0, 0.0, 0.0, 0.35))
	on.draw_colored_polygon(blob, WAX)
	var pressed := SEAL * 0.72
	on.draw_circle(middle, pressed, PRESSED)
	on.draw_arc(middle, pressed, 0.0, TAU, 32, PRESSED_RIM, 1.5, true)
	var star := PackedVector2Array()
	for i: int in 10:
		var a := -PI * 0.5 + TAU * i / 10.0
		star.append(middle + Vector2.from_angle(a) * (pressed * (0.6 if i % 2 == 0 else 0.25)))
	on.draw_colored_polygon(star, PRESSED_RIM)
	on.draw_circle(
		middle + Vector2(-0.4, -0.45) * pressed, pressed * 0.22, Color(1.0, 0.8, 0.8, 0.25)
	)


func _draw() -> void:
	if not stamped:
		return
	# Where the slip is in this, which stands inside the slip's room.
	var slip := Rect2(-position, get_parent_control().size)
	var line := over.get_global_rect()
	line.position -= get_global_rect().position
	var middle := Vector2(slip.position.x + slip.size.x * ACROSS, line.get_center().y + DOWN)
	_picture(false, middle, TURN)
	if sealed:
		_picture(true, slip.end - SEAL_IN, 0.0)


## The stamp, or with [param seal] the seal, round [param middle] turned [param turn]: from its
## picture, or drawn as itself until that is ready.
func _picture(seal: bool, middle: Vector2, turn: float) -> void:
	var room := Vector2.ONE * (SEAL + ROOM) * 2.0 if seal else stamp_size()
	var scale_by := maxf(KeptPictures.scale_of(self), 0.25)
	var picture := KeptPictures.of(
		self,
		"atlas_seal" if seal else "atlas_stamp|%s" % WORD,
		Vector2i((room * scale_by).ceil()),
		func() -> Control:
			var drawing := Drawing.new()
			drawing.seal = seal
			drawing.paper = paper
			drawing.scale_by = scale_by
			return drawing,
		AtlasCover.PICTURES
	)
	draw_set_transform(middle, turn, Vector2.ONE)
	if picture == null:
		if seal:
			draw_seal(self, Vector2.ZERO)
		else:
			draw_stamp(self, Vector2.ZERO, paper)
	else:
		draw_texture_rect_region(
			picture, Rect2(-room * 0.5, room), Rect2(Vector2.ZERO, room * scale_by)
		)
	draw_set_transform(Vector2.ZERO)
