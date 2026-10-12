class_name ClearanceView
extends Control
## A debug drawing over a match of what the camera keeps the karts clear of, GAME.md 8.2: every
## rectangle the HUD says it draws over the room, shaded red; the frame the camera fits the karts
## and their margin of floor into, a little in from the screen's edges; a ring round each kart's
## middle as far out as it is kept clear, green while it is and red while it is under a panel all
## the same; and for each kart driven here, a bar out to the floor kept in view ahead of it, with a
## ring of its own. A line at the foot says how far back the camera is and how its aim is slid.
##
## There is no one rectangle the karts are fitted into: the HUD's panels sit in the corners and down
## the sides, and the camera keeps each kart out from under each of them, see [ClearView]. This
## shows them all, as they come and go.
##
## Drawn to cost next to nothing while it is up, GAME.md 10.7: the panels and the frame are one
## drawing, made again only as they change; each ring and bar is a drawing of its own, made once and
## then moved, turned, scaled and tinted every frame; and the line is written a few times a second.
## Hidden, it does nothing at all.
##
## On with Show what the camera keeps clear on the settings' Debug page, or for a run with
## `++ --show-clearance`.

const COVER_FILL := Color(1.0, 0.2, 0.2, 0.16)
const COVER_EDGE := Color(1.0, 0.3, 0.3, 0.9)
const FRAME := Color(0.35, 0.85, 1.0, 0.85)
const CLEAR := Color(0.35, 1.0, 0.45, 0.95)
const UNDER := Color(1.0, 0.25, 0.25, 0.95)
const LINE := 2.0
## How big a ring is drawn, before it is scaled to the room round what it rings, and how often the
## line at the foot is written again, in seconds.
const RING := 32.0
const SAY_EVERY := 0.25
const SAY_SIZE := 16

## Shown whatever the setting, for a run with `--show-clearance`.
static var forced := false

var hud: MatchHud
## How many times the panels have been drawn, which is as often as they changed.
var panel_draws := 0

var _panels: Control
## The panels and the screen size the panels were last drawn for.
var _drawn_covers: Array[Rect2] = []
var _drawn_size := Vector2.ZERO
var _rings: Array[Control] = []
var _bars: Array[ColorRect] = []
var _line: Label
var _say_left := 0.0
var _under := 0


static func add_to(to: MatchHud) -> ClearanceView:
	var view := ClearanceView.new()
	view.name = "Clearance"
	view.hud = to
	to.add_child(view)
	return view


## Takes `--show-clearance` from [param args], the command line's own arguments.
static func read_arguments(args: PackedStringArray) -> void:
	if "--show-clearance" in args:
		forced = true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Over everything else the HUD draws, which is what it is about.
	z_index = 100
	visible = false
	_panels = Control.new()
	_panels.name = "Panels"
	_panels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panels.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panels.draw.connect(_draw_panels)
	add_child(_panels)
	_line = Label.new()
	_line.name = "Said"
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.add_theme_font_size_override("font_size", SAY_SIZE)
	_line.add_theme_color_override("font_color", FRAME)
	var slip := StyleBoxFlat.new()
	slip.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	slip.set_content_margin_all(6.0)
	_line.add_theme_stylebox_override("normal", slip)
	add_child(_line)


func _process(delta: float) -> void:
	var shown := forced or Game.settings.show_clearance
	if visible != shown:
		visible = shown
	if not shown:
		return
	var rig := hud.match_node.camera_rig if hud.match_node != null else null
	if rig == null or rig.camera == null:
		return
	if rig.covers != _drawn_covers or size != _drawn_size:
		_drawn_covers = rig.covers
		_drawn_size = size
		_panels.queue_redraw()
	_place(rig)
	_say_left -= delta
	if _say_left <= 0.0:
		_say_left = SAY_EVERY
		_say(rig)


## The panels shaded and edged, and the frame, see [constant COVER_FILL].
func _draw_panels() -> void:
	panel_draws += 1
	var screen := _panels.size
	for cover: Rect2 in _drawn_covers:
		var rect := Rect2(cover.position * screen, cover.size * screen)
		_panels.draw_rect(rect, COVER_FILL)
		_panels.draw_rect(rect, COVER_EDGE, false, LINE)
	_panels.draw_rect(_frame(screen), FRAME, false, LINE)


## The frame the karts and their floor are fitted into, on a screen [param screen] big: a view a
## little narrower than the camera's own, see [member CameraRig.zoom_min].
func _frame(screen: Vector2) -> Rect2:
	var rig := hud.match_node.camera_rig
	var fit := tan(deg_to_rad(rig.base_fov * rig.zoom_min) * 0.5)
	var share := fit / tan(deg_to_rad(rig.base_fov) * 0.5)
	return Rect2(screen * (1.0 - share) * 0.5, screen * share)


## Every ring and bar where it belongs this frame, the rest put away.
func _place(rig: CameraRig) -> void:
	var used := 0
	var bars := 0
	_under = 0
	for target: Node3D in rig._alive_targets():
		var middle := target.global_position + Vector3.UP * CameraRig.KART_MIDDLE
		if _ring_at(rig, middle, used):
			used += 1
	for i: int in rig._ahead.size():
		var ahead := rig._ahead[i]
		if not _ring_at(rig, ahead, used):
			continue
		used += 1
		# From the nearest kart driven here, which is the one it is ahead of.
		var from := _nearest(rig._valid(rig.listener_targets), ahead)
		if from != null and not rig.camera.is_position_behind(from.global_position):
			var start := rig.camera.unproject_position(
				from.global_position + Vector3.UP * CameraRig.KART_MIDDLE
			)
			_bar(bars, start, _rings[used - 1].position + _rings[used - 1].pivot_offset)
			bars += 1
	for i: int in range(used, _rings.size()):
		_rings[i].visible = false
	for i: int in range(bars, _bars.size()):
		_bars[i].visible = false


## Ring [param index] round [param point], sized to the room kept round it and tinted for whether
## it is under a panel; false where the point is behind the camera.
func _ring_at(rig: CameraRig, point: Vector3, index: int) -> bool:
	if rig.camera.is_position_behind(point):
		return false
	while _rings.size() <= index:
		_rings.append(_new_ring())
	var at := rig.camera.unproject_position(point)
	var side := rig.camera.global_basis.x * ClearView.KART_ROOM
	var reach := at.distance_to(rig.camera.unproject_position(point + side))
	var hit := _under_a_cover(rig.covers, at, reach, size)
	if hit:
		_under += 1
	var ring := _rings[index]
	ring.visible = true
	ring.position = at - ring.pivot_offset
	ring.scale = Vector2.ONE * (reach / RING)
	ring.modulate = UNDER if hit else CLEAR
	return true


## A ring drawn once in white at [constant RING], to be moved, scaled and tinted.
func _new_ring() -> Control:
	var ring := Control.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.size = Vector2.ONE * (RING + LINE) * 2.0
	ring.pivot_offset = ring.size * 0.5
	ring.draw.connect(
		func() -> void:
			ring.draw_arc(ring.pivot_offset, RING, 0.0, TAU, 32, Color.WHITE, LINE, true)
			ring.draw_circle(ring.pivot_offset, 3.0, Color.WHITE)
	)
	add_child(ring)
	return ring


## Bar [param index] from [param from] to [param to] on the screen: a thin rectangle turned and
## stretched, rather than a line drawn again.
func _bar(index: int, from: Vector2, to: Vector2) -> void:
	while _bars.size() <= index:
		var made := ColorRect.new()
		made.mouse_filter = Control.MOUSE_FILTER_IGNORE
		made.color = CLEAR
		made.size = Vector2(1.0, LINE)
		made.pivot_offset = Vector2(0.0, LINE * 0.5)
		add_child(made)
		_bars.append(made)
	var bar := _bars[index]
	bar.visible = true
	bar.position = from - bar.pivot_offset
	bar.rotation = (to - from).angle()
	bar.scale = Vector2(from.distance_to(to), 1.0)


## The line at the foot, in the middle of the frame's foot.
func _say(rig: CameraRig) -> void:
	_line.text = (
		"camera %.1f m   slide %+.1f, %+.1f   %d under   %d panels"
		% [rig._distance, rig._slide.x, rig._slide.y, _under, rig.covers.size()]
	)
	var wide := _line.get_combined_minimum_size()
	var foot := _frame(size).end.y
	_line.position = Vector2(size.x * 0.5 - wide.x * 0.5, foot - wide.y - 4.0)


## The one of [param karts] nearest [param point], or null for none.
static func _nearest(karts: Array[Node3D], point: Vector3) -> Node3D:
	var best: Node3D = null
	var gap := INF
	for kart: Node3D in karts:
		var this_gap := kart.global_position.distance_squared_to(point)
		if this_gap < gap:
			best = kart
			gap = this_gap
	return best


## Whether a ring of [param reach] round [param at] on a screen [param screen] big touches one of
## [param covers], given in shares of it.
static func _under_a_cover(
	covers: Array[Rect2], at: Vector2, reach: float, screen: Vector2
) -> bool:
	for cover: Rect2 in covers:
		var rect := Rect2(cover.position * screen, cover.size * screen)
		var nearest := at.clamp(rect.position, rect.end)
		if nearest.distance_to(at) < reach:
			return true
	return false
