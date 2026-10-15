class_name KartStage
extends Control
## The kart in the kart dialog, GAME.md 4.4a: the seat's own kart in a small world of its own,
## standing on the floor between the posts of the Garage's lift, filmed and lit by the bay's lamps,
## and drawn into the dialog with its shadow and its tire marks on the floor. It wears what it is
## dressed in, or whatever is being tried on in the tray of parts, see [method show_kart].
##
## Each part is shown as it is best seen, see [method view]: the hat from the front, the flag from
## the side, the plate from behind, the paint from a front corner, the camera coming in to it; for
## the trail and the tire marks it drives round in front of the lift, its trail streaming behind it
## and its marks laid on the floor. Otherwise it stands showing its back and its side.
##
## Turned by dragging it, by the mouse or a finger, or by the right stick, see [method turn]; let
## go, it sways where it stands and drifts back to where the part shows. Now and then, standing, it
## does something nobody asked it to, see [enum Move]: a jump, a wheelie, a spin, a drift, a donut,
## its wheels going round, its trail thick behind it and its marks on the floor; and it jumps for
## joy at a new piece put on.
##
## Where each part sits on it, as the screen has it, is said for the hooks' ropes, see
## [method anchor].
##
## It stands in the bay itself, built in 3D, see [BaySet]: the wall, the floor, the lift's posts and
## the lamps' light, filmed over the whole of the bay inside the dialog's frame, see [member film],
## and drawn by the dialog behind its pegboards and bench, so the kart casts its shadow on a real
## floor and drives its laps across it.

## What it does by itself, and for how long each.
enum Move { NONE, JUMP, WHEELIE, SPIN, DRIFT, DONUT, REV, SHIMMY, PEEK, BOUNCE, TIP }
## Where it is: standing on the lift, on its way off it, round its laps, on its way back, or out
## in front of the lift doing a move there, see [method perform].
enum Where { LIFT, LEAVING, LAPS, RETURNING, SHOWING }

const MOVE_TIME: Dictionary[int, float] = {
	Move.JUMP: 0.9,
	Move.WHEELIE: 1.8,
	Move.SPIN: 0.8,
	Move.DRIFT: 1.6,
	Move.DONUT: 2.4,
	Move.REV: 1.3,
	Move.SHIMMY: 1.1,
	Move.PEEK: 2.2,
	Move.BOUNCE: 1.2,
	Move.TIP: 1.7,
}
## The moves it does by itself standing on the lift, and those it drives out in front of it for,
## see [method perform], only from the view of it standing, not while a part is looked at.
const ON_THE_LIFT: Array[Move] = [
	Move.JUMP, Move.WHEELIE, Move.SPIN, Move.REV, Move.SHIMMY, Move.PEEK, Move.BOUNCE, Move.TIP
]
const OUT_FRONT: Array[Move] = [Move.DRIFT, Move.DONUT]
## How long between moves at the least and the most, and how long one waits after a hand was on
## the kart, so it never does one in somebody's hands.
const BETWEEN := Vector2(6.0, 11.0)
const AFTER_HANDS := 2.5
## How far it sways either side of where it is turned to, how slowly, how soon after a hand let go
## it heads back there and how slowly it does, how quickly it turns to a part's way of being seen
## when that part is looked at, and how quickly the camera goes from one way of looking at it to
## the next.
const SWAY := 0.22
const SWAY_SPEED := 0.45
const BACK_AFTER := 3.0
const BACK_RATE := 1.6
const VIEW_RATE := 0.12
const CAMERA_RATE := 0.16
## How near the way it is to be turned it has to come before a quick turn to a view is done.
const TURNED := 0.04
## How far a drag across the kart turns it, by the pixel, and the right stick at full tilt by the
## second.
const DRAG_TURN := 0.012
const STICK_TURN := 3.2
## The way it is shown standing, and for each part, by the part, -1 for none: how it is turned
## from showing the camera its back, where the camera stands and what it looks at, how wide its
## lens is, whether it sways, and whether it drives round in front of the lift. The kart stands in
## the middle of the floor, its wheels on it; the camera stands back from its laps, in front.
const VIEWS: Dictionary[int, Dictionary] = {
	-1:
	{"yaw": -0.95, "eye": Vector3(0.0, 1.45, 5.2), "look": Vector3(0.0, 0.62, 0.0), "fov": 37.0},
	0: {"yaw": 2.25, "eye": Vector3(0.0, 1.35, 4.6), "look": Vector3(0.0, 0.55, 0.0), "fov": 37.0},
	1: {"yaw": 2.75, "eye": Vector3(0.0, 1.8, 4.6), "look": Vector3(0.0, 0.84, 0.0), "fov": 34.0},
	2: {"yaw": 1.2, "eye": Vector3(0.0, 1.5, 4.4), "look": Vector3(0.0, 0.85, 0.0), "fov": 36.0},
	3: {"drive": true, "eye": Vector3(0.0, 4.1, 12.8), "look": Vector3(0.0, 0.2, 3.0), "fov": 37.0},
	4: {"yaw": 0.25, "eye": Vector3(0.0, 1.05, 4.4), "look": Vector3(0.0, 0.5, 0.0), "fov": 34.0},
	5: {"drive": true, "eye": Vector3(0.0, 6.6, 12.0), "look": Vector3(0.0, 0.0, 3.3), "fov": 37.0},
	6: {"keep": true, "eye": Vector3(0.0, 1.55, 6.0), "look": Vector3(0.0, 0.85, 0.7), "fov": 37.0},
}
## Its laps for the trail and the tire marks: an ellipse on the open floor in front of the lift,
## clear of its posts, its middle, how far across and how deep, and how long one takes; where on
## them it joins them, as a share of the way round, the back of them nearest the lift; how far it
## rolls the way it faces as it pulls off the lift; how far along its way back it hops up onto it;
## and how quickly it turns to face the way it goes.
const LAP_MIDDLE := Vector3(0.0, 0.0, 3.05)
const LAP := Vector2(1.85, 1.85)
const LAP_TIME := 2.5
const LAP_JOIN := 0.92
const PULL_OUT := 0.5
## How long it takes, at the most, to turn round on the spot to face the way out before it sets
## off from a stop, and the least turn worth doing so for.
const PIVOT_TIME := 0.45
const PIVOT_LEAST := 0.2
const HOP_AT := 0.4
const STEER_RATE := 0.08
## How far its nose is turned into its laps beyond the way it goes, drifting round the cone in
## their middle, see [BaySet].
const DRIFT_SLIP := 0.62
## How far the drift's nose angle swings either way of that and how fast, how far the front wheels
## are turned against it, how far the body leans out of the turn, and how quickly it comes into all
## of that and out of it again.
const SLIP_SWING := 0.14
const SLIP_SWING_SPEED := 2.6
const COUNTERSTEER := 0.75
const LEAN := 0.075
const DRIFT_RATE := 0.25
## How fast its wheels go round, in radians a second, while it goes anywhere.
const WHEEL_SPIN := 18.0
## How long its cone takes to pop up out of the floor, or sink into it.
const CONE_TIME := 0.35
## Where in front of the lift it does a move that needs room, a drift or a donut, and the way it
## comes in to it; and how often a move it does by itself is one of those, driven out to.
const SHOW_SPOT := Vector3(-0.35, 0.0, 2.2)
## Where the camera stands while it is off the lift but for its laps, out doing a move or on its
## way back: stood back, so the floor in front of the lift is in sight. The part's own view only
## once it is back on the lift, which it would be too close for out there.
const AWAY_VIEW := {"eye": Vector3(0.0, 3.1, 10.9), "look": Vector3(0.0, 0.35, 1.9), "fov": 37.0}
const SHOW_FACING := Vector3(1.0, 0.0, 0.35)
## The render's pixels are rounded up to steps of this, so a window being dragged does not
## make it again at every pixel, and kept within this, for a big screen's sake.
const STEP := 16
const MOST := Vector2i(2048, 1280)
## Where the exhaust is, in the kart's own space, which the trail comes out of; how far behind the
## middle the rear axle is, and ahead of it the front, the wheelie's and the donut's pivots; and how
## far out from the middle the rear wheels lay their marks.
const EXHAUST := Vector3(0.0, 0.35, 0.72)
const REAR_AXLE := 0.45
const FRONT_AXLE := -0.45
const REAR_TRACK := 0.5
## How high a jump takes it, its hat still in the picture at the top of it.
const JUMP := 0.42
## Where each part of the dress sits on the kart, in its own space, for the ropes: the body's side
## and the rear wheel taken on whichever side is toward the camera. The card back is on no kart.
const ANCHORS: Array[Vector3] = [
	Vector3(0.42, 0.78, -0.05),
	Vector3(0.0, 1.92, -0.06),
	Vector3(0.0, 1.45, 0.5),
	Vector3(0.0, 0.35, 0.95),
	Vector3(0.0, 0.5, 0.72),
	Vector3(0.62, 0.42, 0.45),
]
## How many frames the camera takes to see through its lens the size its picture is, before then
## saying where anything is on it.
const SETTLE_FRAMES := 2
## Which anchors are on a side, taken on the side toward the camera.
const SIDED: Array[int] = [0, 5]

## What [method anchor] says for a part that is on no kart.
const NO_ANCHOR := Vector2(-1e9, -1e9)
## The card back's part, past the kart's own, see [constant KartDialog.CARD_BACK], which the kart is
## shown for from further back, left turned as it was, the dialog holding up a hand of cards in
## front of it, see [CardFan].
const CARD_BACK := 6
## How fast it turns, in radians a second, for what flies from it to feel it, far faster than it
## sways about standing, and how long they swing about after, before they settle, see
## [method _settle_sways]; and how near and how far its camera sees, close enough together for the
## cork board's notes to keep in front of one another.
const TURN_FELT := 0.5
const TURN_SWING := 1.4
const NEAR := 0.1
const FAR := 120.0

## How it is turned now, whether a hand is on it, and the part it is shown for, or -1.
var yaw := -0.95
var held := false
var part_shown := -1
## Whether it is on its quick way round to the view it is shown in, see [constant VIEW_RATE].
var turning_to_view := false
## Whether it may do things by itself, which the dialog says: not while a part's rack is out.
var restless := true
## Where on the stage its picture is filmed for, in the stage's own space: the whole of the bay
## inside the dialog's frame, see [method KartDialog._fit], or its own rect over the bay's picture.
## The views are framed for [constant BayArt.VIEW] whatever it is, see [method _place_camera].
var film := Rect2()
## What it wears now, in which color and with which plate on its back.
var shown: KartStyle
var shown_color := -1
var shown_plate := ""

var _render: SubViewport
var _camera: Camera3D
var _spot: Node3D
var _move_node: Node3D
var _kart: Node3D
var _smoke: ExhaustSmoke
var _marks: StageMarks
## Whether each rear wheel has been on the turntable since its last mark, for its next to start
## afresh rather than run across it.
var _on_pad: Array[bool] = [false, false]
var _wheels: Array[MeshInstance3D] = []
## What flies from it, a flag, a windsock, a tape or dice, see [DressSway].
var _sways: Array[DressSway] = []
## Its wheels as they stand on the model, for turning and spinning them from, how far round they
## have spun, and which are the front ones, that steer.
var _wheel_rest: Array[Transform3D] = []
var _front: Array[bool] = []
var _spin := 0.0
## How far into a drift it is, 0 out of one to 1 drifting round its laps, which way it turns, -1 or
## 1, and the white sparks a drift throws off its rear wheels, as in a match, see [DriftSparks].
var _drifting := 0.0
var _turn_way := 1.0
var _sparks: DriftSparks
## The bay it stands in, built in 3D, and how far its cone stands up, 0 lying down to 1 up.
var _bay: BaySet
var _cone_up := 0.0
## How far its lift's turntable is turned from the way it faces, kept as it comes back onto it, and
## whether it is off the turntable, which then stays as it was.
var _pad_offset := 0.0
var _off_pad := false
## Where on it, in its own space, the hat's rope is tied: the top of the hat it wears, or of its
## driver's head without one; worked out once it is up.
var _hat_point := Vector3.INF
var _clock := 0.0
var _clock_frames := 0
var _since_hands := 99.0
## Its turn the frame before, and how long since it last turned fast enough to swing what flies
## from it about, see [method _settle_sways].
var _yaw_before := 0.0
var _since_turned := 99.0
var _move := Move.NONE
## The move asked for while it was in another, to start once that one is done.
var _queued := Move.NONE
var _move_t := 0.0
var _next_move := 0.0
var _rng := RandomNumberGenerator.new()
## What it wears now, so the same again is not built again.
var _worn := ""
## Where the camera stands, looks and how wide its lens is now, on its way to the view's.
var _eye := Vector3.ZERO
var _look := Vector3.ZERO
var _fov := 37.0
## Where it is, see [enum Where], how far round its laps, and how fast it goes, in meters a second;
## the way it is taking, a curve of four points, how long it is, how far along it, how long it
## takes, and how fast it goes at either end; whether that way leads out to do a move in front of
## the lift rather than to its laps, and which move; and whether it has hopped onto the lift yet on
## its way back.
var _where := Where.LIFT
var _lap := LAP_JOIN
var _speed := 0.0
var _path := PackedVector3Array()
var _path_length := 1.0
var _path_t := 0.0
var _path_time := 1.0
var _from_speed := 0.0
var _to_speed := 0.0
var _bound_out := false
## The way it goes, whatever way its nose points in a drift; and its turn on the spot before it sets
## off from a stop: which way it faced, which way it is turning to face, how long that takes, and
## how far into it it is.
var _travel := Vector3.FORWARD
var _pivot_from := 0.0
var _pivot_to := 0.0
var _pivot_time := 0.0
var _pivot_t := 0.0
var _show := Move.NONE
var _hopped := false


## Lays its marks whatever the settings say of the marks of a match: here they are the point.
class StageMarks:
	extends TireMarks

	func laying() -> bool:
		return true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_rng.randomize()
	_next_move = _rng.randf_range(BETWEEN.x * 0.5, BETWEEN.y * 0.6)
	if film.size == Vector2.ZERO:
		film = Rect2(position, size)
	_render = SubViewport.new()
	_render.name = "Render"
	_render.own_world_3d = true
	# Smoothed as the screen is, which the shaders are warmed up for, see [ShaderWarmup].
	_render.msaa_3d = get_viewport().msaa_3d
	_render.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_render.world_3d = _world()
	_render.size = Vector2i(STEP, STEP)
	# Everything in its world moves by the frame, the camera too, never by the physics tick.
	_render.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_render)
	_bay = BaySet.make()
	_render.add_child(_bay)
	_marks = StageMarks.new()
	_marks.name = "TireMarks"
	_render.add_child(_marks)
	_spot = Node3D.new()
	_spot.name = "Spot"
	_render.add_child(_spot)
	_move_node = Node3D.new()
	_move_node.name = "Moves"
	_spot.add_child(_move_node)
	_camera = Camera3D.new()
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.near = NEAR
	_camera.far = FAR
	_render.add_child(_camera)
	_place_camera(VIEWS[-1], true)
	# The bay's lamps are lights of their own, see [BaySet]: this one, warm, only casts the kart's
	# shadow on the floor, nearly overhead as the lamps are, so it lies under it where it is seen;
	# and a cool fill from behind.
	var key := DirectionalLight3D.new()
	key.light_energy = 0.75
	key.light_color = Color(1.0, 0.96, 0.88)
	key.rotation_degrees = Vector3(-76.0, 20.0, 0.0)
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 14.0
	key.shadow_blur = 1.5
	_render.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.4
	fill.light_color = Color(0.8, 0.86, 1.0)
	fill.rotation_degrees = Vector3(-18.0, 150.0, 0.0)
	_render.add_child(fill)


## Has the kart wear [param style] in [param color_index] with [param plate] on its back: built
## again only when that is not what it wears already. [param cheer] has it jump for joy at it.
func show_kart(style: KartStyle, color_index: int, plate: String, cheer := false) -> void:
	var worn := "%s|%d|%s" % [style.to_array(), color_index, plate]
	shown = style
	shown_color = color_index
	shown_plate = plate
	if worn != _worn:
		_worn = worn
		_build(style, color_index, plate)
	if cheer and not is_away():
		play(Move.JUMP if _rng.randf() < 0.6 else Move.SPIN)


func _build(style: KartStyle, color_index: int, plate: String) -> void:
	if _kart != null:
		_kart.name = "KartGone"
		_kart.queue_free()
	_kart = KartVisuals.display_model(color_index, style)
	# A model stands for display with its wheels the model's lift off the ground; here they are on it.
	_kart.position.y = -KartVisuals.MODEL_LIFT
	KartVisuals.plate_like(_kart, plate)
	_wheels.clear()
	_wheel_rest.clear()
	_front.clear()
	for node: Node in _kart.find_children("*", "MeshInstance3D", true, false):
		var called := node.name.to_lower()
		if called.begins_with("wheel"):
			_wheels.append(node as MeshInstance3D)
			_wheel_rest.append((node as MeshInstance3D).transform)
			_front.append(not called.contains("back"))
	_hat_point = Vector3.INF
	_sparks = DriftSparks.new()
	_sparks.name = "DriftSparks"
	_kart.add_child(_sparks)
	_sways.clear()
	for node: Node in _kart.find_children("*", "DressSway", true, false):
		_sways.append(node as DressSway)
	_smoke = ExhaustSmoke.new()
	_smoke.name = "Smoke"
	_smoke.position = EXHAUST
	_smoke.dress(Palette.player_color(color_index), style.trail, style.finish(3))
	_smoke.emitting = false
	_kart.add_child(_smoke)
	_move_node.add_child(_kart)
	_marks.marks = style.marks
	_marks.finish = style.finish(5)


## Shows it for [param part], see [constant VIEWS], or standing for -1 or a part with no view of its
## own, the card back's.
func view(part: int) -> void:
	var shown_for := part if VIEWS.has(part) else -1
	if shown_for == part_shown:
		return
	part_shown = shown_for
	_since_hands = 99.0
	turning_to_view = true


## Whether it is off the lift: on its way to its laps, on them, or on its way back.
func is_away() -> bool:
	return _where != Where.LIFT


## Whether a hand can turn it now: standing on the lift, not off on its laps or on its way to them,
## nor behind the hand of cards held up for the card back.
func can_turn() -> bool:
	return not driving() and not is_away() and part_shown != CARD_BACK


## Whether it drives its laps for the part it is shown for now.
func driving() -> bool:
	return bool(VIEWS[part_shown].get("drive", false))


## Starts [param kind] now, or, while it is in a move already, once that one is done. Every move
## starts and ends with the kart standing as it was, so one after another runs on smoothly, where a
## move cut short, a shuffle pressed in a donut, jumped back to its start.
func play(kind: Move) -> void:
	if _move != Move.NONE:
		_queued = kind
		return
	_move = kind
	_move_t = 0.0
	_next_move = _rng.randf_range(BETWEEN.x, BETWEEN.y)


## Turns it by [param by], as a hand on it does.
func turn(by: float) -> void:
	if not can_turn():
		return
	yaw = wrapf(yaw + by, -PI, PI)
	_since_hands = 0.0
	turning_to_view = false


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		held = button.pressed
		accept_event()
		return
	var touch := event as InputEventScreenTouch
	if touch != null:
		held = touch.pressed
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and held:
		turn(motion.relative.x * DRAG_TURN)
		accept_event()
		return
	var drag := event as InputEventScreenDrag
	if drag != null:
		turn(drag.relative.x * DRAG_TURN)
		accept_event()


func _process(delta: float) -> void:
	_clock += delta
	_clock_frames += 1
	_since_hands = 0.0 if held else _since_hands + delta
	_fit_render()
	var shown_as: Dictionary = VIEWS[part_shown]
	if is_away() and not driving():
		shown_as = AWAY_VIEW
	_place_camera(shown_as, false, delta)
	var laps := driving()
	# The hand that turns it, only while one can.
	mouse_default_cursor_shape = Control.CURSOR_DRAG if can_turn() else Control.CURSOR_ARROW
	if not can_turn():
		held = false
	var keep := bool(shown_as.get("keep", false))
	if _since_hands > BACK_AFTER and not laps and not is_away() and not keep:
		var sway := SWAY if part_shown < 0 else SWAY * 0.3
		var rest: float = shown_as.get("yaw", VIEWS[-1]["yaw"]) + sin(_clock * SWAY_SPEED) * sway
		var rate := VIEW_RATE if turning_to_view else BACK_RATE
		yaw = lerp_angle(yaw, rest, 1.0 - exp(-delta / rate))
		turning_to_view = turning_to_view and absf(angle_difference(yaw, rest)) > TURNED
	_drive(delta)
	if _move == Move.NONE and restless and not is_away() and not laps:
		_next_move -= delta
		if _next_move <= 0.0 and _since_hands > AFTER_HANDS and _kart != null:
			var kinds: Array[Move] = ON_THE_LIFT.duplicate()
			if part_shown < 0:
				kinds.append_array(OUT_FRONT)
			var kind := kinds[_rng.randi_range(0, kinds.size() - 1)]
			if kind in OUT_FRONT:
				perform(kind)
			else:
				play(kind)
	_step_move(delta)
	_settle_sways(delta)
	_raise_cone(delta)
	_turn_pad()


## The cone in the middle of its laps popping up out of the floor as it sets off round them, a
## little past standing and back, and sinking into it again once it heads for home: it is in the way
## of every other view, standing in front of the lift.
func _raise_cone(delta: float) -> void:
	if _bay == null:
		return
	var up := _where in [Where.LAPS, Where.LEAVING] and not _bound_out
	_cone_up = move_toward(_cone_up, 1.0 if up else 0.0, delta / CONE_TIME)
	var cone := _bay.cone
	cone.visible = _cone_up > 0.0
	var size := ease(_cone_up, 0.4) * (1.0 + sin(_cone_up * PI) * 0.18)
	cone.scale = Vector3(1.0, maxf(size, 0.001), 1.0) * maxf(size, 0.001)


## What flies from it feels the wind while it goes somewhere, on its laps or in a move, and while
## it is turned, by a hand or to a part, and a little after: the dice swing on their strings and a
## flag swings round its pole. Standing still, it hangs straight back, see [method
## DressSway.settle]; being turned about its own middle is no wind to leave a flag round to.
func _settle_sways(delta: float) -> void:
	var turned := absf(angle_difference(yaw, _yaw_before)) > TURN_FELT * delta
	_yaw_before = yaw
	_since_turned = 0.0 if turned else _since_turned + delta
	var standing := not is_away() and _move == Move.NONE and _since_turned > TURN_SWING
	for sway: DressSway in _sways:
		if not is_instance_valid(sway):
			continue
		sway.set_physics_process(not standing)
		if standing:
			sway.settle(delta)


## The camera on its way to [param pose]'s place, there at once for [param at_once]. Its lens is
## shifted and widened from the view's own so that what the view frames in [constant BayArt.VIEW]
## stays where it is on the stage however much more round it [member film] takes in.
func _place_camera(pose: Dictionary, at_once: bool, delta := 0.0) -> void:
	var to_eye: Vector3 = pose["eye"]
	var to_look: Vector3 = pose["look"]
	var to_fov: float = pose["fov"]
	var weight := 1.0 if at_once else 1.0 - exp(-delta / CAMERA_RATE)
	_eye = _eye.lerp(to_eye, weight)
	_look = _look.lerp(to_look, weight)
	_fov = lerpf(_fov, to_fov, weight)
	var near := _camera.near
	var per_pixel := near * tan(deg_to_rad(_fov) * 0.5) / (BayArt.VIEW.size.y * 0.5)
	var shift := film.get_center() - BayArt.VIEW.get_center()
	_camera.set_frustum(
		per_pixel * film.size.y, Vector2(shift.x, -shift.y) * per_pixel, near, _camera.far
	)
	if _camera.is_inside_tree():
		_camera.look_at_from_position(_eye, _look)
	else:
		_camera.transform = Transform3D(Basis.looking_at(_look - _eye), _eye)


## [param kind] done out on the floor in front of the lift, where there is room for it, rather than
## between the lift's posts: a drift, or the shuffle's donut. Driven out to, done there, and driven
## back onto the lift after; round its laps, done there.
func perform(kind: Move) -> void:
	if _where == Where.LAPS or driving():
		play(kind)
		return
	if _where == Where.SHOWING:
		play(kind)
		return
	_show = kind
	_set_off(SHOW_SPOT, SHOW_FACING, 0.0)
	_where = Where.LEAVING
	_bound_out = true


## Where it stands and which way it faces: on the lift turned as it is; pulling off it, rolling the
## way it faces and turning out onto a curve that meets its laps at their own speed, or comes to a
## stop out in front of the lift to do a move; round its laps, drifting round the cone in their
## middle; or back onto the lift, slowing to a stop and hopping up onto it on the way. Each way is
## taken from wherever it is and at whatever speed it goes, so a part looked at halfway turns it
## round smoothly. Its marks are laid behind it wherever it drives.
func _drive(delta: float) -> void:
	var laps := driving()
	var to_laps := _where == Where.LEAVING and not _bound_out
	if laps and _where != Where.LAPS and not to_laps:
		_set_off(_lap_point(LAP_JOIN), _lap_heading(LAP_JOIN), _lap_speed())
		_where = Where.LEAVING
		_bound_out = false
	elif not laps and (_where == Where.LAPS or to_laps):
		_head_home()
	elif _where == Where.SHOWING and not is_moving():
		_head_home()
	match _where:
		Where.LIFT:
			_speed = 0.0
			_spot.position = Vector3.ZERO
			_spot.rotation.y = yaw
			return
		Where.SHOWING:
			_speed = 0.0
		Where.LAPS:
			_lap = fmod(_lap + delta / LAP_TIME, 1.0)
			_speed = _lap_speed()
			_spot.position = _lap_point(_lap)
			var heading := _lap_heading(_lap)
			var inward := LAP_MIDDLE - _spot.position
			var into := signf(heading.cross(inward).y)
			_turn_way = into
			_travel = heading.normalized()
			_steer(_travel, delta)
		_:
			_along(delta)
	yaw = _spot.rotation.y
	if _where != Where.SHOWING:
		_lay_marks(lerpf(0.9, 1.0, _drifting))


## Back onto the lift from wherever it is.
func _head_home() -> void:
	_set_off(Vector3.ZERO, Vector3.FORWARD, 0.0)
	_where = Where.RETURNING
	_hopped = false


## A way from where it is to [param to], arriving going [param arriving] at [param to_speed],
## gathering speed or losing it smoothly along the way. Going already, it goes on the way it goes;
## from a stop it first turns round on the spot to face the way out, so it never rolls off the way
## it happened to face and swings round after.
func _set_off(to: Vector3, arriving: Vector3, to_speed: float) -> void:
	var from := _spot.position
	var handle := maxf(from.distance_to(to) / 3.0, PULL_OUT)
	var landing := to - arriving.normalized() * handle
	var moving := _speed > 0.1
	var away := _travel if moving else (landing - from).normalized()
	if away.length() < 0.5:
		away = Vector3.FORWARD.rotated(Vector3.UP, _spot.rotation.y)
	_path = PackedVector3Array([from, from + away * handle, landing, to])
	_pivot_t = 0.0
	_pivot_time = 0.0
	if not moving:
		_pivot_from = _spot.rotation.y
		_pivot_to = _yaw_of(away)
		var turn := absf(angle_difference(_pivot_from, _pivot_to))
		if turn > PIVOT_LEAST:
			_pivot_time = PIVOT_TIME * (0.4 + 0.6 * turn / PI)
	_path_length = 0.0
	for k: int in 12:
		_path_length += _on_path(k / 12.0).distance_to(_on_path((k + 1) / 12.0))
	_from_speed = _speed
	_to_speed = to_speed
	# As long as at the speed between its two ends, or at half its laps' from a stop to a stop.
	var going := maxf((_from_speed + _to_speed) * 0.5, _lap_speed() * 0.5)
	_path_time = maxf(_path_length / going, 0.3)
	_path_t = 0.0


## A step along its way, turning to face the way it goes, hopping onto the lift partway back;
## there, it is round its laps, out in front of the lift doing its move, or standing on the lift
## turning to the part shown.
func _along(delta: float) -> void:
	if _pivot_t < _pivot_time:
		_pivot_t = minf(_pivot_t + delta, _pivot_time)
		var k := smoothstep(0.0, 1.0, _pivot_t / _pivot_time)
		_spot.rotation.y = lerp_angle(_pivot_from, _pivot_to, k)
		_speed = 0.0
		return
	_path_t = minf(_path_t + delta / _path_time, 1.0)
	var before := _spot.position
	_spot.position = _on_path(_travelled(_path_t))
	var going := _spot.position - before
	_speed = going.length() / maxf(delta, 0.0001)
	if going.length() > 0.0001:
		_travel = going.normalized()
		_steer(_travel, delta)
	if _where == Where.RETURNING and not _hopped and _path_t >= HOP_AT:
		_hopped = true
		play(Move.JUMP)
	if _path_t < 1.0:
		return
	if _where == Where.LEAVING and _bound_out:
		_where = Where.SHOWING
		_speed = 0.0
		if _show != Move.NONE:
			play(_show)
			_show = Move.NONE
	elif _where == Where.LEAVING:
		_where = Where.LAPS
		_lap = LAP_JOIN
	else:
		_where = Where.LIFT
		_spot.position = Vector3.ZERO
		yaw = _spot.rotation.y
		turning_to_view = true
		_since_hands = 99.0


## How far along its way it is, as a share of the way, [param t] of the time it takes: a curve that
## leaves at the speed it set off at and arrives at the one it is to, see [method _set_off].
func _travelled(t: float) -> float:
	var leaving := _from_speed * _path_time / _path_length
	var arriving := _to_speed * _path_time / _path_length
	var t2 := t * t
	var t3 := t2 * t
	return (t3 - 2.0 * t2 + t) * leaving + (3.0 * t2 - 2.0 * t3) + (t3 - t2) * arriving


## Turned toward going [param way], quickly but never at once: its nose turned in beyond it the
## further into a drift it is, see [member _drifting], swinging a little, so a drift comes on and
## goes off with the laps rather than at once.
func _steer(way: Vector3, delta: float) -> void:
	var slip := (DRIFT_SLIP + sin(_clock * SLIP_SWING_SPEED) * SLIP_SWING) * _drifting
	var facing := _yaw_of(way.rotated(Vector3.UP, _turn_way * slip))
	_spot.rotation.y = lerp_angle(_spot.rotation.y, facing, 1.0 - exp(-delta / STEER_RATE))


## Which way it is turned to face going [param way].
static func _yaw_of(way: Vector3) -> float:
	return atan2(-way.x, -way.z)


## The point [param u] along its way on or off its laps.
func _on_path(u: float) -> Vector3:
	var v := 1.0 - u
	return (
		_path[0] * v * v * v
		+ _path[1] * 3.0 * v * v * u
		+ _path[2] * 3.0 * v * u * u
		+ _path[3] * u * u * u
	)


## The point of its laps [param share] of the way round them, and the way it goes there.
static func _lap_point(share: float) -> Vector3:
	var angle := share * TAU
	return LAP_MIDDLE + Vector3(cos(angle) * LAP.x, 0.0, sin(angle) * LAP.y)


static func _lap_heading(share: float) -> Vector3:
	var angle := share * TAU
	return Vector3(-sin(angle) * LAP.x, 0.0, cos(angle) * LAP.y)


## How fast it goes round its laps, in meters a second.
static func _lap_speed() -> float:
	var h := pow(LAP.x - LAP.y, 2.0) / pow(LAP.x + LAP.y, 2.0)
	var round_it := PI * (LAP.x + LAP.y) * (1.0 + 3.0 * h / (10.0 + sqrt(4.0 - 3.0 * h)))
	return round_it / LAP_TIME


## Lays the rear wheels' marks where they are now, darker for a harder [param intensity]; none
## on the lift's turntable.
func _lay_marks(intensity: float) -> void:
	if _kart == null or not _kart.is_inside_tree():
		return
	var side := _kart.global_transform.basis.x.normalized()
	var now := Time.get_ticks_msec() * 0.001
	for wheel: int in 2:
		var at := _kart.to_global(
			Vector3(REAR_TRACK if wheel == 1 else -REAR_TRACK, 0.0, REAR_AXLE)
		)
		# None on the lift's turntable, which turns with it rather than under it.
		if _bay != null and Vector2(at.x, at.z).length() < BaySet.PAD_REACH:
			_on_pad[wheel] = true
			continue
		_marks.add_sample(wheel, Vector3(at.x, 0.0, at.z), side, intensity, now, _on_pad[wheel])
		_on_pad[wheel] = false


## The render as many pixels tall as [member film] takes up on the screen, give or take a step,
## and as wide as that makes it in the film's own proportions, the whole of it made smaller on a
## screen too big for [constant MOST]. Its lens is as wide as the render, so a render of other
## proportions than the film it is drawn over would draw everything in it stretched: a render held
## to the most on one side alone drew the kart wide and flat on a big screen.
func _fit_render() -> void:
	if not is_inside_tree() or film.size.y <= 0.0:
		return
	var pixels := film.size * KeptPictures.scale_of(self)
	pixels *= minf(1.0, minf(MOST.x / pixels.x, MOST.y / pixels.y))
	var tall := maxi(KeptPictures.step_up(pixels.y, STEP), STEP)
	var wanted := Vector2i(roundi(tall * film.size.x / film.size.y), tall)
	if _render.size != wanted:
		_render.size = wanted


## Where it is in the move it is doing: its lift, its tilt and its turn round the pivot the move
## has, the wheels going round while it does, its trail thick and its marks laid in a drift, a donut
## and a spin. Driving its laps, the wheels go round and the trail streams all the while.
func _step_move(delta: float) -> void:
	var lift := 0.0
	var pitch := 0.0
	var roll := 0.0
	var turned := 0.0
	var slide := 0.0
	var squash := 1.0
	var pivot := Vector3.ZERO
	var busy := _move != Move.NONE
	if busy:
		_move_t += delta
		var length: float = MOVE_TIME[_move]
		var pose := KartMoves.pose(_move, _move_t, length)
		lift = pose["lift"]
		pitch = pose["pitch"]
		roll = pose["roll"]
		turned = pose["turned"]
		slide = pose["slide"]
		squash = pose["squash"]
		pivot = pose["pivot"]
		if _move_t >= length:
			_move = Move.NONE
			busy = false
			if _queued != Move.NONE:
				var next := _queued
				_queued = Move.NONE
				play(next)
	# Round its laps, a drift: leaning out of the turn, its front wheels turned against it, white
	# sparks off its rear wheels, all eased in as it joins them and out as it leaves.
	var on_laps := _where == Where.LAPS
	_drifting = move_toward(_drifting, 1.0 if on_laps else 0.0, delta / DRIFT_RATE)
	roll += -_turn_way * LEAN * _drifting
	if _sparks != null and is_instance_valid(_sparks):
		_sparks.set_state(_drifting > 0.5, _drifting > 0.5)
	var basis := Basis.from_euler(Vector3(pitch, turned, roll)).scaled(
		Vector3(1.0 / sqrt(squash), squash, 1.0 / sqrt(squash))
	)
	var offset := Vector3(slide, lift, 0.0)
	_move_node.transform = Transform3D(basis, pivot - basis * pivot + offset)
	var going := busy or is_away()
	if going:
		_spin = wrapf(_spin - delta * WHEEL_SPIN, -PI, PI)
	var steer := -_turn_way * DRIFT_SLIP * COUNTERSTEER * _drifting
	for i: int in _wheels.size():
		var wheel := _wheels[i]
		if not is_instance_valid(wheel):
			continue
		var rest := _wheel_rest[i]
		var turned_by := Basis(Vector3.UP, steer if _front[i] else 0.0)
		wheel.transform = Transform3D(
			turned_by * rest.basis * Basis(Vector3.RIGHT, _spin), rest.origin
		)
	if busy and _move in [Move.DRIFT, Move.DONUT, Move.SPIN]:
		_lay_marks(1.0)
	# The trail only while it goes somewhere: confetti or chips round a kart standing still are only
	# in the way.
	if _smoke != null and is_instance_valid(_smoke):
		_smoke.emitting = going
		_smoke.update_state(
			1.0 if going else 0.0,
			busy and _move in [Move.DRIFT, Move.DONUT] or _where == Where.LAPS,
			false
		)


## Whether it is doing one of its moves now.
func is_moving() -> bool:
	return _move != Move.NONE


## Where on the stage [param part] sits on the kart now, in the stage's own space, or
## [constant NO_ANCHOR] for one that is on no kart, the card back, or with no kart up yet.
func anchor(part: int) -> Vector2:
	if not _ready_to_film() or part < 0:
		return NO_ANCHOR
	if part >= ANCHORS.size():
		return NO_ANCHOR
	var point := ANCHORS[part]
	if part == 1:
		point = _hat()
	if part in SIDED:
		var other := Vector3(-point.x, point.y, point.z)
		if _kart.to_global(other).distance_to(_eye) < _kart.to_global(point).distance_to(_eye):
			point = other
	return _on_film(_kart.to_global(point))


## Where [param world] is on the stage, as it is filmed.
func _on_film(world: Vector3) -> Vector2:
	var on_render := _camera.unproject_position(world)
	return film.position + on_render / Vector2(_render.size) * film.size


## Where the hat's rope is tied, in its own space: the upper middle of the hat it wears, as the hat
## is, or the top of its driver's head without one.
func _hat() -> Vector3:
	if _hat_point != Vector3.INF:
		return _hat_point
	var to_kart := _kart.global_transform.affine_inverse()
	var hat := _kart.find_child("Hat", true, false) as Node3D
	var found := AABB()
	var any := false
	for node: Node in (hat if hat != null else _kart).find_children(
		"*", "MeshInstance3D", true, false
	):
		var mesh := node as MeshInstance3D
		if hat == null and not mesh.name.to_lower().contains("character"):
			continue
		var box := to_kart * mesh.global_transform * mesh.get_aabb()
		found = box if not any else found.merge(box)
		any = true
	if not any:
		_hat_point = ANCHORS[1]
	elif hat != null:
		_hat_point = found.get_center() + Vector3.UP * found.size.y * 0.15
	else:
		_hat_point = found.get_center() + Vector3.UP * found.size.y * 0.42
	return _hat_point


## Its lift's turntable turning with it while it stands on it, its own turns and its moves' alike,
## and left where it was while it is off it; taken up again from there as it comes back.
func _turn_pad() -> void:
	if _bay == null or _bay.pad == null:
		return
	var on_pad := _spot.position.length() < 0.02
	var facing := _spot.rotation.y + _move_node.rotation.y
	if not on_pad:
		_off_pad = true
		return
	if _off_pad:
		_off_pad = false
		_pad_offset = _bay.pad.rotation.y - facing
	_bay.pad.rotation.y = facing + _pad_offset


## Its picture: the kart and the bay round it, filmed for [member film], which the dialog draws
## behind its pegboards and bench.
func picture() -> Texture2D:
	return _render.get_texture()


## Whether there is a kart up and a picture of it the size of the stage to say where things are on.
func _ready_to_film() -> bool:
	if _kart == null or not _kart.is_inside_tree() or _clock_frames < SETTLE_FRAMES:
		return false
	return _render.size.x > STEP and _render.size.y > STEP


static func _world() -> World3D:
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.6, 0.68)
	environment.ambient_light_energy = 1.05
	environment.background_color = BayArt.WALL_HIGH
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	return world
