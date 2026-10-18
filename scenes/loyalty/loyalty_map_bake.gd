class_name LoyaltyMapBake
extends Node
## The loyalty map's sheet drawn once into a picture of all of it, for [LoyaltyMapView] to show as
## one texture, drawing only what moves over it: the kart, the landmark it is at, the NEW tags and
## the pins. The whole map drawn again every frame the kart moved or the map scrolled, its paper,
## roads, signs and words, was some thousands of draws and most of a frame on its own; see the
## title's chips, drawn once the same way.
##
## The picture is drawn by a second view of the same sheet, [member LoyaltyMapView.baking], whole
## and at the zoom the map rests at, so it is as sharp as the map drawn live, though never more
## than [constant MOST] pixels across. A moment after the zoom has come to rest elsewhere it is
## drawn again at that zoom, the last picture scaled meanwhile; the new one is drawn in a viewport
## of its own while the last is still shown, and takes its place once it is drawn. Until the first
## is, the view draws the sheet itself.

## The longest side of a picture, in pixels; the room round the paper drawn with it, in the map's
## own pixels, for its shadow; how long the zoom rests before the sheet is drawn again at it, in
## seconds; and how many frames a picture is given to be drawn before it is shown.
const MOST := 4096.0
const ROOM := 40.0
const SETTLE := 0.2
const FRAMES := 2

var _view: LoyaltyMapView
## The picture shown and the one being drawn, each its viewport, the scale it is drawn at, the
## sheet it is of and, for the one being drawn, the frames it has had.
var _shown: Dictionary = {}
var _drawing: Dictionary = {}
var _zoom_was := 0.0
var _rest := 0.0


func _init(view: LoyaltyMapView) -> void:
	_view = view
	name = "Bake"


func _process(delta: float) -> void:
	if _view.layout == null:
		return
	if _view.zoom != _zoom_was:
		_zoom_was = _view.zoom
		_rest = 0.0
	else:
		_rest += delta
	var wanted := scale_wanted()
	var lost := not is_up()
	if not _of(_shown, wanted) and not _of(_drawing, wanted) and (lost or _rest >= SETTLE):
		_start(wanted)
	if _drawing.is_empty():
		return
	_drawing["frames"] = int(_drawing["frames"]) + 1
	if int(_drawing["frames"]) <= FRAMES:
		return
	_let_go(_shown)
	_shown = _drawing
	_drawing = {}
	_view.queue_redraw()


## The scale the sheet is wanted at: the zoom, as far as [constant MOST] lets it.
func scale_wanted() -> float:
	var whole := _view.layout.paper + Vector2.ONE * ROOM * 2.0
	return minf(_view.zoom, MOST / maxf(maxf(whole.x, whole.y), 1.0))


## Whether a picture of the sheet shown is up, see [method draw_on].
func is_up() -> bool:
	return not _shown.is_empty() and _shown["sheet"] == _view.sheet


## Whether a picture is being drawn, the last one shown meanwhile.
func is_drawing() -> bool:
	return not _drawing.is_empty()


## The scale of the picture up, or 0 with none.
func scale_up() -> float:
	return float(_shown["scale"]) if is_up() else 0.0


## Draws the picture on the view, where the sheet is at the zoom now, from inside its draw; false
## with none up, for the view to draw the sheet itself.
func draw_on() -> bool:
	if not is_up():
		return false
	var render: SubViewport = _shown["viewport"]
	var scale: float = _shown["scale"]
	var at := _view.offset - Vector2.ONE * ROOM * _view.zoom
	# At the scale it was drawn, on whole pixels, so it is shown as it was drawn and not resampled.
	if is_equal_approx(scale, _view.zoom):
		at = at.round()
	var shown := Vector2(render.size) * _view.zoom / scale
	_view.draw_texture_rect(render.get_texture(), Rect2(at, shown), false)
	return true


## The sheet to be drawn again at once: changed, or another sheet turned to; the picture up is
## shown meanwhile, where it is of the sheet shown.
func refresh() -> void:
	_start(scale_wanted())


func _of(picture: Dictionary, scale: float) -> bool:
	return (
		not picture.is_empty()
		and picture["sheet"] == _view.sheet
		and is_equal_approx(float(picture["scale"]), scale)
	)


## Starts drawing the sheet whole at [param scale], into a viewport of its own.
func _start(scale: float) -> void:
	_let_go(_drawing)
	var sheet := LoyaltyMapView.new()
	sheet.name = "Sheet"
	sheet.baking = true
	sheet.profile = _view.profile
	sheet.program = _view.program
	sheet.sheet = _view.sheet
	sheet.layout = _view.layout
	sheet.zoom = scale
	sheet.offset = Vector2.ONE * ROOM * scale
	var whole := _view.layout.paper + Vector2.ONE * ROOM * 2.0
	DrawnTexture.of(self, sheet, Vector2i((whole * scale).ceil()))
	_drawing = {"viewport": sheet.get_parent(), "scale": scale, "sheet": _view.sheet, "frames": 0}


func _let_go(picture: Dictionary) -> void:
	if not picture.is_empty() and is_instance_valid(picture["viewport"]):
		(picture["viewport"] as Node).queue_free()
