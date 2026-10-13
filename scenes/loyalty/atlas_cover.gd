class_name AtlasCover
extends Control
## What dresses the loyalty dialog's pane as the House's road atlas, GAME.md 8.9, see [AtlasArt].
## Under everything in the pane, the cover and what lies on it: drawn once into a picture of the
## pane at its size and shown from that every frame, and drawn as itself only until that picture is
## ready, or while the pane is still changing size. Over everything, the tape at the map's corners
## and the slits that hold the card. It stands last in the pane, over the rest, and takes no input.

## How many frames the pane keeps its size and its layout before its cover is drawn into a picture
## at them: the dialog's layout settles over the first frame or two it is up, and a window dragged
## to another size changes it every frame until it is let go of, so a picture is drawn once rather
## than at every size it passes.
const REST := 2
## The room round the pane the picture takes in, for the cover's shadow and its ribbons.
const ROOM := 48.0
## The room inside the cover round what is in the pane, left, top, right and foot, with room and
## short of it.
const INSIDE: Array[float] = [50.0, 48.0, 50.0, 50.0]
const INSIDE_SHORT: Array[float] = [24.0, 22.0, 24.0, 26.0]
## How long a strip of tape at a corner of the map is, with room and short of it.
const TAPE := 80.0
const TAPE_SHORT := 64.0
## The group of what shows the tape's and the slits' pictures, told once they are drawn, and the
## room round each picture for its shadow and its torn ends.
const PICTURES := &"atlas_pictures"
const PICTURE_ROOM := 6.0
## How much of the foot left of Back the pencil needs to lie in, how long it is at the most, how
## far in from the map's edge its end lies, and how far short of Back what lies in the foot stops.
const PENCIL_ROOM := 260.0
const PENCIL_LONG := 490.0
const PENCIL_IN := 16.0
const BACK_ROOM := 60.0
## The dividers past the pencil in the foot: how far past its point their hinge is, how long their
## legs are, the way they point, a little down from level, and the room they need.
const DIVIDERS_PAST := 120.0
const DIVIDERS_REACH := 160.0
const DIVIDERS_TOWARD := 0.05
const DIVIDERS_ROOM := 200.0

## The cover last drawn into a picture, and what it was drawn for. Kept for the run, so the dialog
## opened again at the same size shows it from its first frame.
static var _kept: Texture2D
static var _kept_key := ""

## The pane it dresses, and what in it the things on and over the cover go by: the map's well, the
## card's place, the foot row and Back.
var pane: PanelContainer
var well: Control
var card: Control
var foot: Control
var back: Control
## Whether the pane fills a short screen, see [method fit].
var short := false
## The atlas's name, in the foot of its rules, the story's at the stage it is at.
var motto := ""

## What the cover is being drawn into a picture for, what it was last asked for, and the frame that
## last changed on.
var _drawing := ""
var _wanted := ""
var _changed_frame := 0


## The cover as a picture, drawn by [DrawnTexture] at its pixels: the pane's room and the room round
## it, scaled up to them.
class Drawing:
	extends Control

	var room: Vector2
	var scale_by := 1.0
	var short := false
	var motto := ""
	var places: AtlasArt.Places

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		var room_round := Vector2.ONE * AtlasCover.ROOM * scale_by
		var base := Transform2D(0.0, Vector2.ONE * scale_by, 0.0, room_round)
		draw_set_transform_matrix(base)
		AtlasArt.cover(self, Rect2(Vector2.ZERO, room), short, motto, places, base)


## A strip of tape or the flap of a slit, its top left corner's, as a picture drawn once a run: the
## thing's middle, or the card's corner, at [member middle] of the picture's room.
class Piece:
	extends Control

	var tape := 0.0
	var middle: Vector2
	var scale_by := 1.0

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		draw_set_transform(middle * scale_by, 0.0, Vector2.ONE * scale_by)
		if tape > 0.0:
			AtlasArt.tape(self, Vector2.ZERO, 0.0, tape)
		else:
			AtlasArt.slit(self, Vector2.ZERO, Vector2.ONE)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(PICTURES)
	pane.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	pane.draw.connect(_draw_cover)
	# What lies on the cover goes by where these are; what lies over it, by the well and the card.
	for each: Control in [foot, back, well]:
		each.item_rect_changed.connect(pane.queue_redraw)
		each.visibility_changed.connect(pane.queue_redraw)
	for each: Control in [well, card]:
		each.item_rect_changed.connect(queue_redraw)
		each.visibility_changed.connect(queue_redraw)
	set_process(false)


## The cover with room round the pane or [param short] of it, where the pane fills the screen: the
## room inside it round the pane's contents, and it drawn again.
func fit(is_short: bool) -> void:
	short = is_short
	var inside := pane.get_theme_stylebox(&"panel") as StyleBoxEmpty
	var room := INSIDE_SHORT if short else INSIDE
	for side: int in 4:
		inside.set_content_margin(side as Side, room[side])
	pane.queue_redraw()
	queue_redraw()


## The room inside a cover with room round the pane, as a pane's own look, to be put on the pane
## before it is laid out.
static func inside() -> StyleBoxEmpty:
	var room := StyleBoxEmpty.new()
	for side: int in 4:
		room.set_content_margin(side as Side, INSIDE[side])
	return room


## Where the things on the cover lie, in the foot left of Back, by where the foot and Back are now:
## the pencil, and past it the dividers where there is room for them too. A short screen's pane
## has no foot, and nothing lies on its cover; the atlas's name there is under the map's middle,
## clear of the tape on its corners, which come down near it.
func places() -> AtlasArt.Places:
	var placed := AtlasArt.Places.new()
	if short:
		placed.name_at = _on_pane(well).get_center().x
	if not foot.is_visible_in_tree():
		return placed
	var y := _on_pane(foot).get_center().y
	var from := Vector2(_on_pane(well).position.x + PENCIL_IN, y + 8.0)
	var stop := _on_pane(back).position.x - BACK_ROOM
	var to := Vector2(minf(from.x + PENCIL_LONG, stop), y - 6.0)
	if to.x - from.x < PENCIL_ROOM:
		return placed
	placed.pencil_from = from
	placed.pencil_to = to
	var hinge := Vector2(to.x + DIVIDERS_PAST, y)
	if stop - hinge.x >= DIVIDERS_ROOM:
		placed.hinge = hinge
		placed.toward = DIVIDERS_TOWARD
		placed.reach = DIVIDERS_REACH
	return placed


## The cover under the pane's contents: its picture, or, until that is ready for the pane as it
## now is, the cover drawn as itself and its picture asked for.
func _draw_cover() -> void:
	var rect := Rect2(Vector2.ZERO, pane.size)
	var placed := places()
	var scale_by := maxf(KeptPictures.scale_of(pane), 0.25)
	var key := "%s|%s|%.3f|%s|%s" % [short, pane.size.round(), scale_by, motto, placed.key()]
	if _kept != null and key == _kept_key:
		var whole := rect.grow(ROOM)
		pane.draw_texture_rect_region(_kept, whole, Rect2(Vector2.ZERO, whole.size * scale_by))
		return
	AtlasArt.cover(pane, rect, short, motto, placed)
	_want(key, scale_by, placed)


## The picture of the cover for [param key] asked for: drawn once what is wanted has stayed the
## same for [constant REST] frames, and until then waited for.
func _want(key: String, scale_by: float, placed: AtlasArt.Places) -> void:
	if not is_inside_tree() or Game.is_headless():
		return
	var frame := Engine.get_process_frames()
	if key != _wanted:
		_wanted = key
		_changed_frame = frame
	if frame - _changed_frame < REST:
		set_process(true)
		return
	if _drawing == key:
		return
	_drawing = key
	var drawing := Drawing.new()
	drawing.room = pane.size
	drawing.scale_by = scale_by
	drawing.short = short
	drawing.motto = motto
	drawing.places = placed
	var pixels := Vector2i(((pane.size + Vector2.ONE * ROOM * 2.0) * scale_by).ceil())
	DrawnTexture.kept(self, drawing, pixels, _keep.bind(key))


## The picture drawn for [param key], kept and shown should the pane still be as it was drawn for.
func _keep(texture: Texture2D, key: String) -> void:
	if _drawing == key:
		_drawing = ""
	if key != _wanted:
		return
	_kept = texture
	_kept_key = key
	pane.queue_redraw()


## Waits for the pane to rest at its size, then asks for its picture again.
func _process(_delta: float) -> void:
	if Engine.get_process_frames() - _changed_frame < REST:
		return
	set_process(false)
	pane.queue_redraw()


## Over the pane's contents: tape at the map's corners, but its foot's left on a short screen,
## where that corner is the screen's own; and the card held in its slits.
func _draw() -> void:
	var map := _on_self(well)
	var long := TAPE_SHORT if short else TAPE
	var strips: Array[Array] = [
		[Vector2(map.end.x, map.position.y), PI * 0.25], [map.end, -PI * 0.25]
	]
	if not short:
		strips.append([Vector2(map.position.x, map.end.y), PI * 0.25])
	for strip: Array in strips:
		_piece(strip[0], strip[1], long)
	if card.is_visible_in_tree():
		var turn := 0.0
		for corner: Array in AtlasArt.corners_of(_on_self(card)):
			_piece(corner[0], turn, 0.0)
			turn += PI * 0.5


## A strip of tape [param tape] long, or with none the flap of a slit, at [param at] turned
## [param turn]: from its picture, or drawn as itself until that is ready.
func _piece(at: Vector2, turn: float, tape: float) -> void:
	var room := (
		Vector2(tape, tape * AtlasArt.TAPE_WIDE) if tape > 0.0 else Vector2.ONE * AtlasArt.SLIT
	)
	var middle := room * 0.5 if tape > 0.0 else Vector2.ONE * AtlasArt.SLIT_OUT
	if tape <= 0.0:
		room += Vector2.ONE * AtlasArt.SLIT_OUT
	room += Vector2.ONE * PICTURE_ROOM * 2.0
	middle += Vector2.ONE * PICTURE_ROOM
	var scale_by := maxf(KeptPictures.scale_of(self), 0.25)
	var picture := KeptPictures.of(
		self,
		"atlas_piece|%d" % roundi(tape),
		Vector2i((room * scale_by).ceil()),
		func() -> Control:
			var drawing := Piece.new()
			drawing.tape = tape
			drawing.middle = middle
			drawing.scale_by = scale_by
			return drawing,
		PICTURES
	)
	if picture == null:
		if tape > 0.0:
			AtlasArt.tape(self, at, turn, tape)
		else:
			AtlasArt.slit(self, at, Vector2.from_angle(turn + PI * 0.25) * sqrt(2.0))
		return
	draw_set_transform(at, turn, Vector2.ONE)
	draw_texture_rect_region(picture, Rect2(-middle, room), Rect2(Vector2.ZERO, room * scale_by))
	draw_set_transform(Vector2.ZERO)


func _on_pane(node: Control) -> Rect2:
	var rect := node.get_global_rect()
	rect.position -= pane.global_position
	return rect


func _on_self(node: Control) -> Rect2:
	var rect := node.get_global_rect()
	rect.position -= global_position
	return rect
