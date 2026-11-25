class_name KartPointers
extends Control
## Where the karts are when they cannot be seen, GAME.md 8.2 and 8.5: an arrow in its color at the
## edge of the screen for every kart out of the picture, pointing at it, bigger for a kart driven
## here, but for the Garage's dummies, parked targets rather than players; and, asked for in
## Accessibility, a marker over each kart driven here. A camera that keeps
## only some karts in the picture, see [FramedKarts], leaves the rest to these, and one that keeps
## them all still has a kart come back out past the edge for a moment, see [FramedSpots].
##
## Drawn in a handful of triangles, again only on a frame with any to draw, GAME.md 10.7.

## How far in from the edge of the screen an arrow stands, and how long it is, in the HUD's units:
## a rival's, and a kart driven here's.
const INSET := 30.0
const ARROW := 18.0
const ARROW_HERE := 26.0
## The marker over a kart driven here: how wide it is, and how high over the kart's middle it
## floats, in meters, so it clears a hat and a flag; and how far over a hint hung over the kart it
## goes while one is up, such as the drive hint at the start, in the HUD's units, see [ScreenHint].
const MARKER := 26.0
const MARKER_LIFT := 2.4
const OVER_HINT := 6.0
## The ink round every arrow and marker, so it reads on the brightest felt and the darkest vault.
const INK := Color(0.06, 0.05, 0.08, 0.9)
const EDGE := 3.0

var hud: MatchHud
## What is drawn this frame: where, which way, how big and in what color, and whether it is a
## marker rather than an arrow.
var _signs: Array[Dictionary] = []


static func add_to(to: MatchHud) -> KartPointers:
	var pointers := KartPointers.new()
	pointers.name = "KartPointers"
	pointers.hud = to
	pointers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pointers.set_anchors_preset(Control.PRESET_FULL_RECT)
	to.add_child(pointers)
	return pointers


func _process(_delta: float) -> void:
	var had := not _signs.is_empty()
	_signs.clear()
	var match_node := hud.match_node
	var rig := match_node.camera_rig if match_node != null else null
	if rig != null and rig.camera != null and not hud.dismissed and hud.visible:
		_place(match_node, rig)
	if had or not _signs.is_empty():
		queue_redraw()


## [member _signs] for every kart of [param match_node] seen by [param rig].
func _place(match_node: Match, rig: CameraRig) -> void:
	var here := CameraRig._valid(rig.listener_targets)
	var marking := Game.settings.kart_marker
	var screen := Rect2(Vector2.ZERO, size)
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or not kart.alive or not kart.is_inside_tree() or slot.is_dummy():
			continue
		var mine := kart in here
		var middle := kart.global_position + Vector3.UP * CameraRig.KART_MIDDLE
		var behind := rig.camera.is_position_behind(middle)
		var at := rig.camera.unproject_position(middle)
		if not behind and screen.has_point(at):
			if mine and marking:
				var over := _over(kart, middle + Vector3.UP * MARKER_LIFT, rig.camera)
				_signs.append(
					{at = over, way = Vector2.DOWN, length = MARKER, color = slot.color()}
				)
			continue
		var middle_of := size * 0.5
		var way := (at - middle_of) * (-1.0 if behind else 1.0)
		if way.is_zero_approx():
			continue
		way = way.normalized()
		var length := ARROW_HERE if mine else ARROW
		_signs.append(
			{at = _on_edge(middle_of, way), way = way, length = length, color = slot.color()}
		)


## Where the marker over [param kart] points as [param camera] draws it: at [param tip] unless a
## hint hung over the kart is up, and then [constant OVER_HINT] over the top of it, where both can
## be read.
func _over(kart: Kart, tip: Vector3, camera: Camera3D) -> Vector2:
	var at := camera.unproject_position(tip)
	for node: Node in get_tree().get_nodes_in_group(ScreenHint.GROUP):
		var hint := node as ScreenHint
		if hint != null and hint.is_visible_in_tree() and kart.is_ancestor_of(hint):
			at.y = minf(at.y, hint.top_on_screen(camera).y - OVER_HINT)
	return at


## Where a line out of [param from] [param way] meets the edge of the screen, [constant INSET] in.
func _on_edge(from: Vector2, way: Vector2) -> Vector2:
	var reach := (size * 0.5 - Vector2.ONE * INSET).max(Vector2.ONE)
	var scale_to := INF
	if absf(way.x) > 0.0001:
		scale_to = minf(scale_to, reach.x / absf(way.x))
	if absf(way.y) > 0.0001:
		scale_to = minf(scale_to, reach.y / absf(way.y))
	return from + way * scale_to


func _draw() -> void:
	for each: Dictionary in _signs:
		draw_sign(self, each.at, each.way, each.length, each.color)


## An arrow or a marker on [param canvas], its tip at [param tip] pointing [param way],
## [param length] long, in [param color] edged in ink. The marker hangs over the kart, its point
## down at it, as the Accessibility page's preview has it too, see [KartMarksPreview]; an arrow
## points out past the edge.
static func draw_sign(
	canvas: CanvasItem, tip: Vector2, way: Vector2, length: float, color: Color
) -> void:
	var base := tip - way * length
	var side := way.orthogonal() * length * 0.55
	var shape := PackedVector2Array([tip, base + side, base - side])
	canvas.draw_colored_polygon(shape, color)
	shape.append(tip)
	canvas.draw_polyline(shape, INK, EDGE, true)
