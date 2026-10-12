class_name ClearanceView
extends Control
## A debug drawing over a match of what the camera keeps the karts clear of, GAME.md 8.2: every
## rectangle the HUD says it draws over the room, shaded red; the frame the camera fits the karts
## and their margin of floor into, a little in from the screen's edges; and a ring round each kart's
## middle as far out as it is kept clear, green while it is and red while it is under a panel all
## the same. A line in the corner says how far back the camera is and how its aim is slid.
##
## There is no one rectangle the karts are fitted into: the HUD's panels sit in the corners and down
## the sides, and the camera keeps each kart out from under each of them, see [ClearView]. This
## shows them all, as they come and go.
##
## On with Show what the camera keeps clear on the settings' Debug page, or for a run with
## `++ --show-clearance`.

const COVER_FILL := Color(1.0, 0.2, 0.2, 0.16)
const COVER_EDGE := Color(1.0, 0.3, 0.3, 0.9)
const FRAME := Color(0.35, 0.85, 1.0, 0.85)
const CLEAR := Color(0.35, 1.0, 0.45, 0.95)
const UNDER := Color(1.0, 0.25, 0.25, 0.95)
const LINE := 2.0

## Shown whatever the setting, for a run with `--show-clearance`.
static var forced := false

var hud: MatchHud


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


func _process(_delta: float) -> void:
	visible = forced or Game.settings.show_clearance
	if visible:
		queue_redraw()


func _draw() -> void:
	var rig := hud.match_node.camera_rig if hud.match_node != null else null
	if rig == null or rig.camera == null:
		return
	var screen := size
	for cover: Rect2 in rig.covers:
		var rect := Rect2(cover.position * screen, cover.size * screen)
		draw_rect(rect, COVER_FILL)
		draw_rect(rect, COVER_EDGE, false, LINE)
	# The karts and their floor are fitted into a view a little narrower than the camera's own.
	var fit := tan(deg_to_rad(rig.base_fov * rig.zoom_min) * 0.5)
	var share := fit / tan(deg_to_rad(rig.base_fov) * 0.5)
	var frame := Rect2(screen * (1.0 - share) * 0.5, screen * share)
	draw_rect(frame, FRAME, false, LINE)
	var under := 0
	for target: Node3D in rig._alive_targets():
		var middle := target.global_position + Vector3.UP * CameraRig.KART_MIDDLE
		if rig.camera.is_position_behind(middle):
			continue
		var at := rig.camera.unproject_position(middle)
		var side := rig.camera.global_basis.x * ClearView.KART_ROOM
		var reach := at.distance_to(rig.camera.unproject_position(middle + side))
		var hit := _under_a_cover(rig.covers, at, reach, screen)
		if hit:
			under += 1
		draw_arc(at, reach, 0.0, TAU, 32, UNDER if hit else CLEAR, LINE, true)
		draw_circle(at, 3.0, UNDER if hit else CLEAR)
	var said := (
		"camera %.1f m   slide %+.1f, %+.1f   %d under   %d panels"
		% [rig._distance, rig._slide.x, rig._slide.y, under, rig.covers.size()]
	)
	# On a dark slip in the middle of the frame's foot, legible over whatever is under it.
	var font := get_theme_default_font()
	var wide := font.get_string_size(said, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	var at_line := Vector2(screen.x * 0.5 - wide.x * 0.5, frame.end.y - 10.0)
	draw_rect(Rect2(at_line - Vector2(8.0, 18.0), wide + Vector2(16.0, 10.0)), Color(0, 0, 0, 0.7))
	draw_string(font, at_line, said, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, FRAME)


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
