class_name RisingPiece
extends Node3D
## A piece of the driving test's lot coming up, GAME.md 9.4a: nothing of a lesson pops in. The
## piece is outlined on the floor where it will stand, in the school's cyan, a moment before it
## comes, so the eye finds it; then a piece that stands up rises out of the floor, slowly, with a
## low rumble, as the House's racks do at the Final Hand, and a flat one comes up on a panel of the
## floor that turns over like a card, the floor's gray on its back and the piece on its face. A
## piece is in play once it is up, and not before: until then it is held, not seen and out of the
## physics world, see [method hold].
##
## Each coming is a node of its own beside the piece, which runs the outline and the move while the
## piece itself is held still, and goes once the piece is up.

## How a piece comes: rising out of the floor, or turned over on a panel of it.
enum Way { RISE, FLIP }

## How long the outline is up before the piece comes, how long a rise and a turn take, how far
## under the floor a rising piece starts, and how high a turning panel lifts at its middle.
const MARK := 0.5
const RISE := 1.1
const FLIP := 0.8
const DEPTH := 2.2
const LIFT := 0.6
## The outline: how wide its line is, its cyan, and how much it pulses while it waits.
const LINE := 0.07
const INK := Palette.NEON_CYAN
const PULSE := 6.0
## The rumble a rise makes.
const RUMBLE := &"turret_place"
const RUMBLE_DB := -12.0
const RUMBLE_PITCH := 0.62

var piece: Node3D
var way := Way.RISE
var footprint := Vector2.ONE
## What the back of a turning panel is drawn in: the floor's own look.
var back_skin: Material
var _age := 0.0
var _wait := 0.0
var _rest: Transform3D
var _outline: MeshInstance3D
var _ink: StandardMaterial3D
var _back: MeshInstance3D
var _rumbled := false
var _done: Callable
## Whether it is going back into the floor rather than coming out of it, see [method lower].
var _down := false


## Brings [param of] up over [param across] of floor, in meters, the [param how] way, after
## [param after] seconds; [param done] is called once it is up and in play. A piece already
## coming, or already up, is left as it is.
static func bring(
	of: Node3D,
	across: Vector2,
	how := Way.RISE,
	after := 0.0,
	skin: Material = null,
	done := Callable()
) -> RisingPiece:
	if of == null or not is_instance_valid(of) or of.has_meta(&"rising"):
		return null
	if of.visible and of.process_mode != Node.PROCESS_MODE_DISABLED:
		return null
	var coming := RisingPiece.new()
	coming.name = "Rising"
	coming.piece = of
	coming.way = how
	coming.footprint = across
	coming.back_skin = skin
	coming._wait = after
	coming._done = done
	of.set_meta(&"rising", true)
	of.get_parent().add_child(coming)
	return coming


## [param of] back into the floor, the way it came, and held there: for what a lesson needs no
## more, the pads that switch the way of driving.
static func lower(of: Node3D, across: Vector2, how := Way.FLIP) -> RisingPiece:
	if of == null or not is_instance_valid(of) or of.has_meta(&"rising") or not of.visible:
		return null
	var going := RisingPiece.new()
	going.name = "Lowering"
	going.piece = of
	going.way = how
	going.footprint = across
	going._down = true
	of.set_meta(&"rising", true)
	of.process_mode = Node.PROCESS_MODE_DISABLED
	of.get_parent().add_child(going)
	return going


## [param node] up at once, in play, with nothing to see of its coming: for a lesson skipped and
## the exam gone to straight, whose pieces are all there already.
static func at_once(node: Node3D) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.set_meta(&"rising", null)
	node.visible = true
	node.process_mode = Node.PROCESS_MODE_INHERIT


## [param node] held back: unseen and not in play, not processed and out of the physics world with
## it, which is what a paused body or area is. A Jackpot is shut, and a pad's pickup taken off it.
static func hold(node: Node3D) -> void:
	node.visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is JackpotZone:
		(node as JackpotZone).deactivate()
	if node is SpawningPad:
		var pad := node as SpawningPad
		if pad.current != null and is_instance_valid(pad.current):
			pad.current.queue_free()
			pad.current = null


## Whether [param node] is up and in play.
static func is_up(node: Node3D) -> bool:
	return (
		node != null
		and is_instance_valid(node)
		and node.visible
		and node.process_mode != Node.PROCESS_MODE_DISABLED
		and not node.has_meta(&"rising")
	)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rest = piece.transform
	global_position = Vector3(piece.global_position.x, 0.0, piece.global_position.z)
	_outline = outline_for(footprint, LINE)
	_ink = _outline.material_override as StandardMaterial3D
	add_child(_outline)


## An outline round [param across] of floor, [param width] wide, in the school's cyan, lying on the
## floor and clear until it is shown: what marks a piece about to come and the trench about to open.
static func outline_for(across: Vector2, width: float) -> MeshInstance3D:
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.albedo_color = Color(INK, 0.0)
	var outline := MeshInstance3D.new()
	outline.name = "Outline"
	outline.mesh = frame_mesh(across, width)
	outline.material_override = ink
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outline.position.y = 0.03
	return outline


## The back of a turning panel, [param across] of floor in [param skin], facing down under what it
## carries.
static func panel_back(across: Vector2, skin: Material) -> MeshInstance3D:
	var back := MeshInstance3D.new()
	back.name = "PanelBack"
	var quad := PlaneMesh.new()
	quad.size = across
	quad.flip_faces = true
	back.mesh = quad
	if skin != null:
		back.material_override = skin
	back.position.y = -0.02
	return back


func _process(delta: float) -> void:
	if not is_instance_valid(piece):
		queue_free()
		return
	# Brought up at once meanwhile, see [method at_once]: it is where it belongs, and no more comes.
	if not piece.has_meta(&"rising"):
		piece.transform = _rest
		if _back != null and is_instance_valid(_back):
			_back.queue_free()
		queue_free()
		return
	if _wait > 0.0:
		_wait -= delta
		return
	_age += delta
	if _down:
		_go_down()
		return
	if _age < MARK:
		_ink.albedo_color.a = 0.55 + 0.35 * sin(_age * PULSE * TAU / 2.0)
		return
	var going := RISE if way == Way.RISE else FLIP
	var share := clampf((_age - MARK) / going, 0.0, 1.0)
	if not _rumbled:
		_rumbled = true
		piece.visible = true
		if way == Way.FLIP:
			_lay_back()
		Audio.play_sfx(RUMBLE, RUMBLE_DB, 0.05, RUMBLE_PITCH if way == Way.RISE else 1.0)
	_ink.albedo_color.a = 0.9 * (1.0 - share)
	if way == Way.RISE:
		_rise_to(share)
	else:
		_turn_to(share)
	if share >= 1.0:
		_arrive()


## Up out of the floor, [param share] of the way, slowing as it comes.
func _rise_to(share: float) -> void:
	var eased := 1.0 - pow(1.0 - share, 3.0)
	var at := _rest
	at.origin.y -= DEPTH * (1.0 - eased)
	piece.transform = at


## Over on its panel, [param share] of the way: face down under the floor at the start, lifted at
## the middle, face up where it belongs at the end.
func _turn_to(share: float) -> void:
	var eased := share * share * (3.0 - 2.0 * share)
	var at := _rest
	at.basis = _rest.basis * Basis(Vector3.RIGHT, PI * (1.0 - eased))
	at.origin.y += LIFT * sin(PI * eased)
	piece.transform = at


## The back of a turning panel: a piece of the floor's own look under the piece, which faces up
## while the piece is face down and is the floor until it turns.
func _lay_back() -> void:
	_back = panel_back(footprint, back_skin)
	piece.add_child(_back)


## Back into the floor, [param _age] along: the rise or the turn played backward, then held.
func _go_down() -> void:
	var going := RISE if way == Way.RISE else FLIP
	var share := clampf(_age / going, 0.0, 1.0)
	if way == Way.RISE:
		_rise_to(1.0 - share)
	else:
		_turn_to(1.0 - share)
	if share < 1.0:
		return
	piece.transform = _rest
	piece.set_meta(&"rising", null)
	hold(piece)
	queue_free()


func _arrive() -> void:
	piece.transform = _rest
	if _back != null and is_instance_valid(_back):
		_back.queue_free()
	piece.set_meta(&"rising", null)
	piece.process_mode = Node.PROCESS_MODE_INHERIT
	if _done.is_valid():
		_done.call()
	queue_free()


## A frame round [param across] of floor, [param width] wide, flat on it.
static func frame_mesh(across: Vector2, width: float) -> ArrayMesh:
	var half := across * 0.5
	var inner := half - Vector2.ONE * width
	var points := PackedVector3Array()
	var corners: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for i: int in 4:
		var a := corners[i]
		var b := corners[(i + 1) % 4]
		var outer_a := Vector3(a.x * half.x, 0.0, a.y * half.y)
		var outer_b := Vector3(b.x * half.x, 0.0, b.y * half.y)
		var inner_a := Vector3(a.x * inner.x, 0.0, a.y * inner.y)
		var inner_b := Vector3(b.x * inner.x, 0.0, b.y * inner.y)
		points.append_array([outer_a, outer_b, inner_b, outer_a, inner_b, inner_a])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var up := PackedVector3Array()
	up.resize(points.size())
	up.fill(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = up
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
