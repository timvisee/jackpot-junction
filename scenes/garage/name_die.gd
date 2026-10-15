class_name NameDie
extends Button
## The die at the right end of the kart dialog's name tape, GAME.md 4.4a: pressed, it rolls a name
## the house makes up, see [method KartDialog.roll_name]. The mouse over it or the cursor on it
## picks it up off the tape, tilted and rocking in the hand as if about to be thrown, a warm glow
## round it and, for the cursor, a gold ring; pressed, it is thrown: a cube tumbling over and over
## up off the tape, its faces coming round one after another as a die's do, bouncing as it comes
## down, slowing, and coming to rest on a face at random, see [method _draw_cube].

## How far it rises picked up, how far it is tilted and rocks either way of that and how fast, and
## how far its glow reaches round it, for its size.
const LIFT := 5.0
const TILT := 0.2
const ROCK := 0.09
const ROCK_SPEED := 6.0
const GLOW := 0.95
## How long a throw takes, how many times over it tumbles on its way to the face it lands on, and
## how far into the throw it has stopped turning; how high it is thrown, and its hops as it comes
## down: from where to where in the throw each goes, and how high, a share of the throw's.
const TUMBLE := 0.85
const TURNS := 1.0
const ROLLED := 0.86
const THROW := 18.0
const HOPS: Array[Vector3] = [
	Vector3(0.0, 0.52, 1.0), Vector3(0.52, 0.74, 0.28), Vector3(0.74, 0.88, 0.08)
]
## How round its corners are; where the light falls on it from, up and to the left of the viewer,
## for how bright each face is; and how much darker its rounded edges are than its faces.
const CORNER := 7.0
const LIGHT := Vector3(-0.35, -0.55, 1.0)
const EDGE_SHADE := 0.3
## Where the pips of each face are, from its middle, in steps of a quarter of its side.
const PIPS: Array[Array] = [
	[Vector2(0, 0)],
	[Vector2(-1, -1), Vector2(1, 1)],
	[Vector2(-1, -1), Vector2(0, 0), Vector2(1, 1)],
	[Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
	[Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)],
	[Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)],
]

## The face up, from 1 to 6.
var face := 5
var _clock := 0.0
## How far into a throw it is, or -1 lying still; how it was turned as it was thrown and how it
## lands, and the way it tumbles over on its way.
var _thrown := -1.0
var _from := Quaternion.IDENTITY
var _to := Quaternion.IDENTITY
var _over := Vector3.RIGHT
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	for look: StringName in [
		&"normal", &"hover", &"pressed", &"disabled", &"focus", &"hover_pressed"
	]:
		add_theme_stylebox_override(look, StyleBoxEmpty.new())
	add_to_group(FocusGlide.GROUP)
	_rng.randomize()
	for told: Signal in [mouse_entered, mouse_exited, focus_entered, focus_exited]:
		told.connect(_wake)
	pressed.connect(throw)
	set_process(false)


## Whether it is picked up: the mouse over it or the cursor on it.
func held() -> bool:
	return is_hovered() or has_focus()


## Whether it is still tumbling from a throw.
func is_thrown() -> bool:
	return _thrown >= 0.0


## Thrown: it tumbles and lands on a face at random, from wherever it is, a throw again in the air.
func throw() -> void:
	_from = _turned() if _thrown >= 0.0 else _lying()
	face = _another_face()
	_to = Quaternion(Vector3.BACK, TILT if held() else 0.0) * facing(face)
	var way := _rng.randf_range(0.0, TAU)
	_over = Vector3(cos(way), sin(way), 0.3).normalized()
	_thrown = 0.0
	_wake()


## How the cube is turned for [param face_up] to face out of the screen, x to the right, y down it
## and z out of it: opposite faces add up to seven.
static func facing(face_up: int) -> Quaternion:
	match face_up:
		2:
			return Quaternion(Vector3.RIGHT, PI * 0.5)
		3:
			return Quaternion(Vector3.UP, -PI * 0.5)
		4:
			return Quaternion(Vector3.UP, PI * 0.5)
		5:
			return Quaternion(Vector3.RIGHT, -PI * 0.5)
		6:
			return Quaternion(Vector3.UP, PI)
	return Quaternion.IDENTITY


func focus_frame() -> Rect2:
	return Rect2(Vector2.ZERO, size).grow(4.0)


func _wake() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	if _thrown >= 0.0:
		_thrown += delta
		if _thrown >= TUMBLE:
			_thrown = -1.0
	if _thrown < 0.0 and not held():
		set_process(false)
	queue_redraw()


## A face other than the one up.
func _another_face() -> int:
	var next := _rng.randi_range(1, 5)
	return next + 1 if next >= face else next


## How it is turned lying still, or picked up, tilted and rocking.
func _lying() -> Quaternion:
	var turn := TILT + sin(_clock * ROCK_SPEED) * ROCK if held() else 0.0
	return Quaternion(Vector3.BACK, turn) * facing(face)


## How it is turned in the air: tumbling over on its way from how it was thrown to how it lands,
## fast and then slowing, still once it has rolled.
func _turned() -> Quaternion:
	var t := clampf(_thrown / (TUMBLE * ROLLED), 0.0, 1.0)
	var rolled := 1.0 - (1.0 - t) * (1.0 - t)
	return Quaternion(_over, TAU * TURNS * rolled) * _from.slerp(_to, rolled)


## How high it is in the air: thrown up and hopping as it comes down, from the hand to the hand if
## it is still held, onto the tape if not.
func _rise() -> float:
	var t := _thrown / TUMBLE
	var up := lerpf(LIFT, LIFT if held() else 0.0, t)
	for hop: Vector3 in HOPS:
		if t >= hop.x and t < hop.y:
			var s := (t - hop.x) / (hop.y - hop.x)
			up += 4.0 * s * (1.0 - s) * hop.z * THROW
	return up


func _draw() -> void:
	var middle := size * 0.5
	var side := minf(size.x, size.y) - 10.0
	var up := held() or _thrown >= 0.0
	var rise := _rise() if _thrown >= 0.0 else (LIFT if up else 0.0)
	if up:
		BayArt.glow(self, middle, side * GLOW, Color(HouseTheme.FOIL, 0.4))
	if has_focus():
		draw_arc(middle, side * 0.8, 0.0, TAU, 40, Color(HouseTheme.FOIL, 0.9), 2.0, true)
	# Its shadow on the tape, wider and fainter the higher it is.
	var shade := Rect2(middle - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	BayArt.box(
		self,
		shade.grow(rise * 0.25).grow(1.0),
		CORNER + rise * 0.25,
		Color(0, 0, 0, 0.4 - rise * 0.012)
	)
	var tone := BayArt.DIE_FACE.lightened(0.04) if up else BayArt.DIE_FACE
	var turned := _turned() if _thrown >= 0.0 else _lying()
	_draw_cube(middle - Vector2(0.0, rise), side, turned, tone)


## The die as a cube turned [param turned], its middle at [param at], [param side] across: each face
## turned toward the viewer drawn as it is seen, flattened the further it is turned away and lit by
## how it faces [constant LIGHT], its pips with it; behind them the rounded edges between them,
## darker. Lying still, it is only its face up, in [param tone].
func _draw_cube(at: Vector2, side: float, turned: Quaternion, tone: Color) -> void:
	var half := side * 0.5
	var outline := FeltArt.rounded(Rect2(-Vector2.ONE * half, Vector2.ONE * side), CORNER)
	var light := LIGHT.normalized()
	var seen: Array[Transform2D] = []
	var shown: Array[int] = []
	var lit: Array[float] = []
	var rim := PackedVector2Array()
	for each: int in range(1, 7):
		var own := turned * facing(each).inverse()
		var out := own * Vector3.BACK
		if out.z <= 0.02:
			continue
		# Across the face and down it, as they are seen; y is down the screen.
		var across := own * Vector3.RIGHT
		var down := own * Vector3.UP
		var place := Transform2D(
			Vector2(across.x, across.y), Vector2(down.x, down.y), at + Vector2(out.x, out.y) * half
		)
		seen.append(place)
		shown.append(each)
		lit.append(out.dot(light) / light.z)
		for point: Vector2 in outline:
			rim.append(place * point)
	var edges := Geometry2D.convex_hull(rim)
	if edges.size() > 3:
		edges.resize(edges.size() - 1)
		draw_colored_polygon(edges, tone.darkened(EDGE_SHADE))
	for i: int in seen.size():
		var dim := (1.0 - lit[i]) * 0.45
		draw_set_transform_matrix(seen[i])
		draw_colored_polygon(
			outline, tone.darkened(dim) if dim > 0.0 else tone.lightened(-dim * 1.1)
		)
		for pip: Vector2 in PIPS[shown[i] - 1]:
			draw_circle(pip * side * 0.25, side * 0.09, BayArt.DIE_PIP.darkened(maxf(dim, 0.0)))
	draw_set_transform(Vector2.ZERO)
