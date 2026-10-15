class_name BayCover
extends Control
## Everything of the kart dialog's bay that stands still, GAME.md 4.4a, see [BayArt]: the wall, the
## floor and the storage on it, the lamps, the lift, the pegboards and their hooks, the bench and
## the sign, drawn once into a picture of the screen's own size and shown from then on, GAME.md
## 10.7; drawn as itself only until that is ready. The stage it is laid out on stands at [member
## at], scaled [member stage], and the wall and the floor run on out to the edges round it; or to
## the inside of the dialog's frame, see [method BoardArt.draw_frame], while it is [member framed].

## How many frames the bay has to stand at one size before it is drawn again for it, and how many
## of its pictures are kept for a window moved back and forth between sizes.
const REST := 2
const KEPT := 2
## How far a size or a place may wobble before it counts as moved: the hair a layout settles by.
const NEAR := 1.5
## How far round the bay its picture reaches, for the frame's shadow.
const AROUND := 24.0

static var _kept: Dictionary[String, Texture2D] = {}

## Where the stage stands in the bay, how big it is shown, and whether the bay is in its frame.
var at := Vector2.ZERO
var stage := 1.0
var framed := false

var _wanted := ""
var _drawing := ""
var _changed_frame := 0
var _settled_size := Vector2.ZERO
var _settled_at := Vector2.ZERO
var _settled_stage := 1.0
var _settled_framed := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	resized.connect(queue_redraw)


## The stage placed at [param place_at], [param scale_by] big, the bay in its frame for
## [param in_frame].
func place(place_at: Vector2, scale_by: float, in_frame: bool) -> void:
	at = place_at
	stage = scale_by
	framed = in_frame
	queue_redraw()


func _draw() -> void:
	_settle()
	var scale_by := maxf(KeptPictures.scale_of(self), 0.25)
	var key := (
		"%s|%s|%.4f|%.3f|%s"
		% [_settled_size, _settled_at, _settled_stage, scale_by, _settled_framed]
	)
	var kept: Texture2D = _kept.get(key)
	if kept != null:
		draw_texture_rect(kept, Rect2(Vector2.ZERO, _settled_size).grow(AROUND), false)
		return
	paint(self, _settled_size, _settled_at, _settled_stage, _settled_framed, Transform2D.IDENTITY)
	_want(key, scale_by)


## The bay [param room] big, its stage at [param place_at] shown [param scale_by] big, in its
## frame for [param in_frame], drawn on [param on] under [param under].
static func paint(
	on: CanvasItem,
	room: Vector2,
	place_at: Vector2,
	scale_by: float,
	in_frame: bool,
	under: Transform2D
) -> void:
	if in_frame:
		BayArt.base = under
		on.draw_set_transform_matrix(under)
		BoardArt.draw_frame(on, Rect2(Vector2.ZERO, room))
	BayArt.base = under * Transform2D(0.0, Vector2.ONE * scale_by, 0.0, place_at)
	on.draw_set_transform_matrix(BayArt.base)
	BayArt.draw_bay(on)
	BayArt.base = Transform2D.IDENTITY
	on.draw_set_transform_matrix(Transform2D.IDENTITY)


## The size and the place the bay is drawn for: as they are, unless neither has moved by more than
## a hair since it was last drawn, which would draw it all again for nothing to see.
func _settle() -> void:
	var near := (
		size.distance_to(_settled_size) < NEAR
		and at.distance_to(_settled_at) < NEAR
		and absf(stage - _settled_stage) < 0.002
		and framed == _settled_framed
	)
	if not near:
		_settled_size = size.round()
		_settled_at = at.round()
		_settled_stage = snappedf(stage, 0.001)
		_settled_framed = framed


## Its picture for [param key] asked for, once what is wanted has stood still for [constant REST]
## frames.
func _want(key: String, scale_by: float) -> void:
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
	var drawn := BayArt.Drawn.new()
	var room := _settled_size
	var place_at := _settled_at
	var stage_now := _settled_stage
	var in_frame := _settled_framed
	var by := Transform2D(0.0, Vector2.ONE * scale_by, 0.0, Vector2.ONE * AROUND * scale_by)
	drawn.paint = func(on: CanvasItem) -> void: paint(on, room, place_at, stage_now, in_frame, by)
	var pixels := Vector2i(((room + Vector2.ONE * AROUND * 2.0) * scale_by).ceil())
	DrawnTexture.kept(self, drawn, pixels, _keep.bind(key))


func _keep(texture: Texture2D, key: String) -> void:
	if _drawing == key:
		_drawing = ""
	_kept[key] = texture
	while _kept.size() > KEPT:
		_kept.erase(_kept.keys()[0])
	if key == _wanted:
		queue_redraw()


func _process(_delta: float) -> void:
	if Engine.get_process_frames() - _changed_frame < REST:
		return
	set_process(false)
	queue_redraw()
