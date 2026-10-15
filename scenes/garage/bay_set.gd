class_name BaySet
extends Node3D
## The Garage's bay in 3D, GAME.md 4.4a, for the kart dialog's kart to stand and drive in rather
## than over a picture of one, see [KartStage]: the block wall painted in two tones with its red
## line, the concrete floor with an oil stain on it, the lift's two red posts with their hazard
## bands, carriages let down and arms folded along the floor, and the two green enamel shop lamps on
## their cords, each a light. Laid out so the camera at rest frames it as the bay's picture had it,
## see [BayArt]: the wall's foot, the posts and the lamps where they were drawn.
##
## Kept cheap, GAME.md 10.7: every plain-colored box of it is one mesh with its colors on its
## vertices, see [method Bake.tinted], the two hazard bands, the two shades and the two bulbs a
## mesh each, the wall two quads with a small texture of blocks laid over and over; none of it
## casts a shadow, only the kart does, and the lamps' lights cast none. About ten things to draw.

## Where the back wall stands behind the kart, where the side walls stand either side of it and how
## far they run on toward the camera, well past where it ever stands, how tall the walls are, far
## taller than any screen's shape shows, under a dark ceiling over the whole room, the height of
## their paint line, and a course of their blocks and a block's length.
const WALL_Z := -2.55
const SIDE_X := 6.4
const SIDE_TO := 30.0
const WALL := Vector2(SIDE_X * 2.0, 14.0)
const CEILING := Color("#2a2d33")
const PAINT_LINE := 1.45
const COURSE := 0.4
const BLOCK := 0.84
## The posts either side of the kart: how far out from its middle, and how big.
const POST_X := 1.95
const POST := Vector3(0.21, 2.05, 0.21)
## The lamps: where they hang, the light they throw down, and how far they lean back toward the
## wall, for their light to fall on it too.
const LAMPS: Array[Vector3] = [Vector3(-1.1, 2.0, -0.8), Vector3(1.1, 2.0, -0.8)]
const LAMP_ENERGY := 3.2
const LAMP_ANGLE := 52.0
const LAMP_REACH := 7.5
const LAMP_LEAN := 0.22
const LAMP_LIGHT := Color(1.0, 0.88, 0.64)
## The haze each lamp's light is seen in, as the bay's picture drew it: how far down it reaches, how
## wide it is at its foot, and how bright at its top.
const BEAM := Vector2(2.0, 1.0)
const BEAM_GLOW := 0.05
## How much lighter the wall's paint is than the bay's picture had it, the picture having been
## drawn flat and this lit.
const WALL_LIFT := 0.12
## Where the oil stain is on the floor, behind the lift, out of the way of the kart's laps in front
## of it, and how big.
const STAIN := Vector3(-0.95, 0.0, -1.35)
const STAIN_SIZE := Vector2(1.2, 0.55)
## The traffic cone in the middle of the kart's laps that it drifts round, see
## [constant KartStage.LAP_MIDDLE]: how tall and how wide at its foot, and its colors.
const CONE := Vector2(0.55, 0.17)
const CONE_ORANGE := Color("#f26b1d")
const CONE_WHITE := Color("#f2f0ea")
## The tool chest by the wall beside the right post, and the stack of tires beside the left one.
const CHEST_AT := Vector3(3.2, 0.0, -1.95)
const CHEST := Vector3(1.0, 0.95, 0.5)
const CHEST_RED := Color("#b8312b")
const TIRES_AT := Vector3(-3.1, 0.0, -1.85)
const TIRE := Vector2(0.34, 0.2)
const RUBBER := Color("#1c1c1f")
## What hangs and stands along the side walls, see [method _left_wall] and [method _right_wall].
const WOOD := Color("#8c6b47")
const STEEL := Color("#6d7178")
const STEEL_DARK := Color("#3a3d44")
const GLASS := Color("#a9bccb")
const PAPER := Color("#efe6cf")
const EXTINGUISHER := Color("#c22a22")
const HOSE := Color("#e2b324")
const POSTER := Color("#1d2440")
const DRUM := Color("#385970")
const JACK := Color("#c8382f")
## Where the story's things hang on the back wall, either side of the kart: the calendar, as the
## Workbench's, and a note found, pinned up, STORY.md 6.10; how big the note's paper is for its
## pixels, and how high both hang.
const CALENDAR_AT := Vector3(-1.6, 1.75, WALL_Z)
## The cork board the last notes found are pinned up on, right of the lift: its middle on the back
## wall, its size, how many notes it holds at the most, where on it each goes, from its middle,
## and how big a note's paper is for its pixels.
const BOARD_AT := Vector3(1.5, 1.56, WALL_Z)
const BOARD := Vector2(0.92, 1.0)
const NOTES_PINNED := 6
const NOTE_SLOTS: Array[Vector2] = [
	Vector2(-0.2, 0.27),
	Vector2(0.22, 0.24),
	Vector2(-0.24, -0.04),
	Vector2(0.2, -0.06),
	Vector2(-0.18, -0.32),
	Vector2(0.24, -0.34),
]
const NOTE_SCALE := 0.00072
const CORK := Color("#b08a5a")
const FIRST_AID := Color("#eeeae0")
## The lift's turntable: how far round it reaches, and its steel and its stripes.
const PAD_REACH := 0.92
const PAD := Color("#2c2f35")
const LINE_YELLOW := Color("#dbad33")
const PINNED_RED := Color("#c8312b")
const PAINTS: Array[Color] = [
	Color("#c8382f"), Color("#3f74c9"), Color("#e2b324"), Color("#3f9a52"), Color("#efe9dc")
]
const ARM := Color("#5b5f66")
const BASE := Color("#202024")
const CORD := Color(0.05, 0.05, 0.06)

static var _blocks: Texture2D
static var _hazard: Texture2D
static var _stain: Texture2D

## What it is built of before it is baked: each plain box with where it is and its color; each
## hazard band, shade and bulb with where it is.
## The cone in the middle of the kart's laps, which stands only while it drives them, see
## [method KartStage.raise_cone].
var cone: Node3D
## The turntable let into the floor between the lift's posts, which the kart stands on and which
## turns with it, see [method KartStage._turn_pad].
var pad: Node3D

var _solid: Array[Array] = []
var _bands: Array[Array] = []
var _shades: Array[Array] = []
var _bulbs: Array[Array] = []
var _beams: Array[Array] = []


static func make() -> BaySet:
	var bay := BaySet.new()
	bay.name = "Bay"
	bay._floor()
	bay._wall(Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, WALL_Z)), WALL.x)
	var side_length := SIDE_TO - WALL_Z
	for side: float in [-1.0, 1.0]:
		var facing_in := Basis(Vector3.UP, -side * PI * 0.5)
		var middle := Vector3(side * SIDE_X, 0.0, WALL_Z + side_length * 0.5)
		bay._wall(Transform3D(facing_in, middle), side_length)
		bay._post(side)
	bay._box(
		Vector3(SIDE_X * 2.0, 0.1, SIDE_TO - WALL_Z),
		Vector3(0.0, WALL.y, (WALL_Z + SIDE_TO) * 0.5),
		CEILING
	)
	bay._left_wall()
	bay._right_wall()
	bay._cone(KartStage.LAP_MIDDLE)
	bay._turntable()
	bay._chest(CHEST_AT)
	bay._tires(TIRES_AT)
	bay._props()
	bay._story(Story.stage_here(), Game.settings.profile)
	for at: Vector3 in LAMPS:
		bay._lamp(at)
	bay._bake()
	return bay


## The concrete floor, and the oil stain on it beside the lift.
func _floor() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(80.0, 80.0)
	_add(plane, _paint(BayArt.FLOOR, 0.92), Transform3D.IDENTITY)
	var quad := QuadMesh.new()
	quad.size = STAIN_SIZE
	var look := StandardMaterial3D.new()
	look.albedo_texture = _stain_texture()
	look.albedo_color = Color(0.0, 0.0, 0.0, 0.5)
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.roughness = 0.4
	_add(quad, look, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), STAIN + Vector3.UP * 0.004))


## The wall: blocks painted in a darker tone up to the red line and a lighter one over it, the
## grime of the floor along its foot.
## A wall [param wide] across at [param at], its foot's middle, facing into the bay: blocks painted
## in a darker tone up to the red line and a lighter one over it, the grime of the floor along its
## foot. The back one behind the lift, and one either side, so that a camera stood back for the
## kart's laps sees a room round them rather than the end of a wall.
func _wall(at: Transform3D, wide: float) -> void:
	var upper := WALL.y - PAINT_LINE
	var low := BayArt.WALL_LOW.lightened(WALL_LIFT)
	_blocks_of(at, Vector2(wide, PAINT_LINE), PAINT_LINE * 0.5, low)
	_blocks_of(
		at, Vector2(wide, upper), PAINT_LINE + upper * 0.5, BayArt.WALL_HIGH.lightened(WALL_LIFT)
	)
	_box(Vector3(wide, 0.09, 0.02), at * Vector3(0.0, PAINT_LINE, 0.01), BayArt.RED_LINE, at.basis)
	_box(Vector3(wide, 0.16, 0.02), at * Vector3(0.0, 0.08, 0.01), low.darkened(0.5), at.basis)


## A stretch of the wall at [param at], [param size] big, its middle [param middle] up it, in
## [param tone].
func _blocks_of(at: Transform3D, size: Vector2, middle: float, tone: Color) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var look := _paint(tone, 0.95)
	look.albedo_texture = _blocks_texture()
	look.uv1_scale = Vector3(size.x / BLOCK, size.y / (COURSE * 2.0), 1.0)
	_add(quad, look, at * Transform3D(Basis.IDENTITY, Vector3(0.0, middle, 0.0)))


## A traffic cone standing at [param at]: orange, a white band round it, on its square foot.
## Its one mesh of its own, rather than in with the rest, for it to stand up and lie down by
## itself; out of sight until it stands.
func _cone(at: Vector3) -> void:
	var foot := BoxMesh.new()
	foot.size = Vector3(CONE.y * 2.4, 0.04, CONE.y * 2.4)
	var body := CylinderMesh.new()
	body.top_radius = 0.025
	body.bottom_radius = CONE.y
	body.height = CONE.x
	body.radial_segments = 16
	var band := CylinderMesh.new()
	band.top_radius = CONE.y * 0.42
	band.bottom_radius = CONE.y * 0.58
	band.height = CONE.x * 0.16
	band.radial_segments = 16
	var middle := Vector3.UP * (0.04 + CONE.x * 0.5)
	var pieces: Array[Array] = [
		[foot, Transform3D(Basis.IDENTITY, Vector3.UP * 0.02), CONE_ORANGE.darkened(0.1)],
		[body, Transform3D(Basis.IDENTITY, middle), CONE_ORANGE],
		[band, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.02), middle), CONE_WHITE],
	]
	var plain := StandardMaterial3D.new()
	plain.vertex_color_use_as_albedo = true
	plain.roughness = 0.6
	var made := MeshInstance3D.new()
	made.name = "Cone"
	made.mesh = Bake.tinted(pieces)
	made.material_override = plain
	made.position = at
	made.visible = false
	made.scale = Vector3.ONE * 0.001
	add_child(made)
	cone = made


## A red rolling tool chest standing at [param at] against the wall: its body, the dark lines of
## its drawers, their chrome pulls, a dark top, and its casters.
func _chest(at: Vector3) -> void:
	var middle := at + Vector3.UP * (0.08 + CHEST.y * 0.5)
	_box(CHEST, middle, CHEST_RED)
	_box(Vector3(CHEST.x + 0.04, 0.04, CHEST.z + 0.04), middle + Vector3.UP * CHEST.y * 0.5, BASE)
	for k: int in 4:
		var y := 0.08 + CHEST.y * (0.2 + 0.2 * k)
		var front := at + Vector3(0.0, y, CHEST.z * 0.5 + 0.005)
		_box(Vector3(CHEST.x - 0.06, 0.012, 0.01), front, CHEST_RED.darkened(0.45))
		_box(Vector3(CHEST.x * 0.4, 0.025, 0.03), front + Vector3(0.0, -0.06, 0.01), BayArt.CHROME)
	for x: float in [-1.0, 1.0]:
		_box(Vector3(0.07, 0.08, 0.07), at + Vector3(x * CHEST.x * 0.42, 0.04, 0.0), BASE)


## The left wall: a workbench along it with a vise, a red toolbox and a shelf under it, a shelf of
## paint cans over it, a window high up, and a fire extinguisher on its bracket nearer the front.
func _left_wall() -> void:
	var side := -1.0
	var bench_at := -0.9
	_on_side(side, Vector3(2.2, 0.06, 0.7), bench_at, 0.92, 0.36, WOOD)
	_on_side(side, Vector3(2.0, 0.04, 0.6), bench_at, 0.26, 0.36, WOOD.darkened(0.2))
	for along: float in [-1.0, 1.0]:
		for out: float in [0.08, 0.64]:
			_on_side(side, Vector3(0.06, 0.9, 0.06), bench_at + along * 1.0, 0.45, out, STEEL_DARK)
	_on_side(side, Vector3(0.22, 0.14, 0.16), bench_at + 0.85, 1.02, 0.56, STEEL_DARK)
	_on_side(side, Vector3(0.12, 0.06, 0.24), bench_at + 0.85, 1.12, 0.56, STEEL)
	_on_side(side, Vector3(0.5, 0.24, 0.28), bench_at - 0.45, 1.07, 0.3, EXTINGUISHER.darkened(0.1))
	_on_side(side, Vector3(0.52, 0.03, 0.3), bench_at - 0.45, 1.2, 0.3, EXTINGUISHER.darkened(0.35))
	_on_side(side, Vector3(1.8, 0.04, 0.3), bench_at, 1.85, 0.15, WOOD)
	for k: int in PAINTS.size():
		var can := Vector3(side * (SIDE_X - 0.15), 1.96, bench_at - 0.7 + k * 0.35)
		_upright(0.08, 0.18, can, PAINTS[k])
		_upright(0.082, 0.03, can + Vector3.UP * 0.1, STEEL)
	var window := 1.25
	_on_side(side, Vector3(2.4, 1.3, 0.06), window, 3.2, 0.02, STEEL_DARK)
	for row: int in 2:
		for column: int in 3:
			var along := window - 0.76 + column * 0.76
			_on_side(side, Vector3(0.68, 0.56, 0.02), along, 2.9 + row * 0.6, 0.05, GLASS)
	_on_side(side, Vector3(2.5, 0.06, 0.16), window, 2.53, 0.06, STEEL)
	var extinguisher := Vector3(side * (SIDE_X - 0.14), 0.0, 2.4)
	_on_side(side, Vector3(0.16, 0.6, 0.04), 2.4, 0.95, 0.02, STEEL_DARK)
	_upright(0.1, 0.52, extinguisher + Vector3.UP * 0.92, EXTINGUISHER)
	_upright(0.05, 0.1, extinguisher + Vector3.UP * 1.23, RUBBER)
	_on_side(side, Vector3(0.03, 0.4, 0.03), 2.52, 0.95, 0.2, RUBBER)
	_on_side(side, Vector3(0.3, 0.3, 0.01), 2.4, 1.6, 0.02, EXTINGUISHER)


## The right wall: a rack of tires standing in a row, an electrical panel with its conduit up the
## wall, a racing poster, a clock high up, and an air hose coiled on its reel.
func _right_wall() -> void:
	var side := 1.0
	var rack := -0.6
	for up: float in [0.12, 0.72]:
		_on_side(side, Vector3(2.0, 0.05, 0.05), rack, up, 0.45, STEEL)
	for along: float in [-1.0, 1.0]:
		_on_side(side, Vector3(0.05, 0.8, 0.5), rack + along, 0.4, 0.25, STEEL_DARK)
	var standing := Basis(Vector3.RIGHT, PI * 0.5)
	for k: int in 7:
		var tire := CylinderMesh.new()
		tire.top_radius = TIRE.x
		tire.bottom_radius = TIRE.x
		tire.height = TIRE.y * 0.95
		tire.radial_segments = 18
		var at := Vector3(side * (SIDE_X - 0.42), TIRE.x + 0.06, rack - 0.84 + k * 0.28)
		_solid.append([tire, Transform3D(standing, at), RUBBER])
	var panel := 1.75
	_on_side(side, Vector3(0.5, 0.7, 0.12), panel, 1.6, 0.06, STEEL)
	_on_side(side, Vector3(0.46, 0.66, 0.01), panel, 1.6, 0.125, STEEL.lightened(0.15))
	_on_side(side, Vector3(0.12, 0.1, 0.01), panel, 1.75, 0.135, HouseTheme.FOIL)
	_on_side(side, Vector3(0.05, 2.6, 0.05), panel + 0.12, 3.25, 0.03, STEEL_DARK)
	# A racing poster: a night sky, a gold stripe across it and a red kart's round in it.
	var poster := 0.4
	_on_side(side, Vector3(0.7, 0.95, 0.01), poster, 2.45, 0.01, POSTER)
	_on_side(side, Vector3(0.7, 0.07, 0.01), poster, 2.3, 0.02, HouseTheme.FOIL)
	_on_side(side, Vector3(0.3, 0.3, 0.01), poster, 2.62, 0.022, BayArt.LIFT_RED, 0.785)
	_on_side(side, Vector3(0.6, 0.06, 0.01), poster, 2.05, 0.02, PAPER)
	var face := Basis(Vector3.FORWARD, PI * 0.5)
	var clock := Vector3(side * (SIDE_X - 0.03), 3.4, 1.0)
	var disc := CylinderMesh.new()
	disc.top_radius = 0.24
	disc.bottom_radius = 0.24
	disc.height = 0.05
	disc.radial_segments = 20
	_solid.append([disc, Transform3D(face, clock), RUBBER])
	var dial := CylinderMesh.new()
	dial.top_radius = 0.21
	dial.bottom_radius = 0.21
	dial.height = 0.06
	dial.radial_segments = 20
	_solid.append([dial, Transform3D(face, clock), PAPER])
	_on_side(side, Vector3(0.025, 0.15, 0.01), 1.0, 3.46, 0.065, RUBBER)
	_on_side(side, Vector3(0.11, 0.025, 0.01), 0.96, 3.4, 0.065, RUBBER)
	var reel := Vector3(side * (SIDE_X - 0.1), 1.9, -2.0)
	var drum := CylinderMesh.new()
	drum.top_radius = 0.26
	drum.bottom_radius = 0.26
	drum.height = 0.14
	drum.radial_segments = 18
	_solid.append([drum, Transform3D(face, reel), HOSE])
	var hub := CylinderMesh.new()
	hub.top_radius = 0.09
	hub.bottom_radius = 0.09
	hub.height = 0.16
	hub.radial_segments = 12
	_solid.append([hub, Transform3D(face, reel), STEEL_DARK])
	_on_side(side, Vector3(0.03, 1.2, 0.03), -1.78, 1.3, 0.12, HOSE.darkened(0.2))


## A box on the side wall on [param side], -1 the left and 1 the right, [param size] big: along the
## wall, up it and out from it; its middle [param along] the wall, [param up] it, and [param out]
## from it into the bay; turned [param tilt] on the wall, as a thing pinned up crooked is.
func _on_side(
	side: float, size: Vector3, along: float, up: float, out: float, tone: Color, tilt := 0.0
) -> void:
	var facing := Basis(Vector3.UP, -side * PI * 0.5) * Basis(Vector3.BACK, tilt)
	_box(size, Vector3(side * (SIDE_X - out), up, along), tone, facing)


## A round thing standing upright at [param at], its middle, [param reach] round and [param tall].
func _upright(reach: float, tall: float, at: Vector3, tone: Color) -> void:
	var round_it := CylinderMesh.new()
	round_it.top_radius = reach
	round_it.bottom_radius = reach
	round_it.height = tall
	round_it.radial_segments = 14
	_solid.append([round_it, Transform3D(Basis.IDENTITY, at), tone])


## What else stands about the bay: two oil drums in the back left corner, an air compressor under
## the hose reel in the back right with a stack of cones beside it, a floor jack by the left post,
## and a broom leaning on the back wall.
func _props() -> void:
	for at: Vector3 in [Vector3(-5.6, 0.0, -2.0), Vector3(-4.9, 0.0, -2.15)]:
		_upright(0.3, 0.88, at + Vector3.UP * 0.44, DRUM)
		for up: float in [0.25, 0.63]:
			_upright(0.305, 0.04, at + Vector3.UP * up, DRUM.darkened(0.35))
		_upright(0.31, 0.03, at + Vector3.UP * 0.88, DRUM.darkened(0.2))
	var compressor := Vector3(5.75, 0.0, -1.85)
	_box(Vector3(0.5, 0.06, 0.8), compressor + Vector3.UP * 0.12, STEEL_DARK)
	var tank := CylinderMesh.new()
	tank.top_radius = 0.2
	tank.bottom_radius = 0.2
	tank.height = 0.78
	tank.radial_segments = 16
	var lying := Basis(Vector3.RIGHT, PI * 0.5)
	_solid.append([tank, Transform3D(lying, compressor + Vector3.UP * 0.36), JACK])
	_box(Vector3(0.3, 0.24, 0.3), compressor + Vector3(0.0, 0.66, -0.1), STEEL)
	_upright(0.07, 0.05, compressor + Vector3(0.0, 0.8, 0.12), RUBBER)
	# Each cone of the stack with its own square foot, the feet stacked up a little apart.
	for k: int in 3:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.025
		cone.bottom_radius = CONE.y
		cone.height = CONE.x
		cone.radial_segments = 14
		var foot := Vector3(4.55, 0.025 + k * 0.1, -2.15)
		_box(
			Vector3(CONE.y * 2.4, 0.05, CONE.y * 2.4),
			foot,
			CONE_ORANGE.darkened(0.1 + k * 0.04),
			Basis(Vector3.UP, k * 0.07)
		)
		var at := foot + Vector3.UP * (0.035 + CONE.x * 0.5)
		_solid.append([cone, Transform3D(Basis.IDENTITY, at), CONE_ORANGE])
	var jack := Vector3(-2.75, 0.0, 1.0)
	var turned := Basis(Vector3.UP, 0.5)
	_box(Vector3(0.28, 0.14, 0.7), jack + Vector3.UP * 0.1, JACK, turned)
	_box(Vector3(0.2, 0.05, 0.2), jack + turned * Vector3(0.0, 0.2, -0.3), STEEL_DARK, turned)
	var handle := turned * Basis(Vector3.RIGHT, 0.75)
	_box(Vector3(0.04, 0.04, 1.0), jack + turned * Vector3(0.0, 0.42, 0.62), STEEL, handle)
	for x: float in [-0.12, 0.12]:
		_upright(0.05, 0.05, jack + turned * Vector3(x, 0.05, 0.28), RUBBER)
	var broom := Basis(Vector3.BACK, 0.16)
	_box(Vector3(0.035, 1.4, 0.035), Vector3(-2.45, 0.75, WALL_Z + 0.12), WOOD, broom)
	_box(Vector3(0.36, 0.12, 0.1), Vector3(-2.33, 0.07, WALL_Z + 0.12), RUBBER.lightened(0.2))


## The story's things in the bay, STORY.md 6.10, as [param stage] and [param profile] have it, and
## nothing new to find here: the calendar on the back wall left of the lift, the Workbench's own,
## Kit's last day ringed in red from the third stage and turned over to the next month once the
## last note is found; and right of the lift a cork board with the last notes found pinned up on
## it and red string between them, see [method _mystery].
func _story(stage: int, profile: Profile) -> void:
	var turned := (
		stage >= Story.Stage.PARTICIPANT
		and profile != null
		and profile.story.has_note(Story.NOTE_COUNT)
	)
	var month := StoryDressing.MONTHS[1] if turned else StoryDressing.MONTHS[0]
	var at := CALENDAR_AT + Vector3(0.0, 0.0, 0.012)
	_box(Vector3(0.46, 0.66, 0.012), at, PAPER.lightened(0.15))
	_box(Vector3(0.4, 0.22, 0.01), at + Vector3(0.0, 0.18, 0.008), POSTER)
	_box(Vector3(0.4, 0.03, 0.01), at + Vector3(0.0, 0.055, 0.008), BayArt.LIFT_RED)
	for day: int in month.x:
		var square := month.y + day
		var spot := (
			at + Vector3(-0.18 + (square % 7) * 0.06, 0.0 - floori(square / 7.0) * 0.055, 0.008)
		)
		_box(Vector3(0.045, 0.04, 0.006), spot, STEEL.lightened(0.25))
	if stage >= Story.Stage.PARTICIPANT and not turned:
		var square := month.y + StoryDressing.KIT_LAST_DAY - 1
		var ring := TorusMesh.new()
		ring.inner_radius = 0.026
		ring.outer_radius = 0.036
		ring.rings = 12
		ring.ring_segments = 6
		var spot := at + Vector3(-0.18 + (square % 7) * 0.06, -floori(square / 7.0) * 0.055, 0.014)
		_solid.append([ring, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), spot), PINNED_RED])
	_box(Vector3(0.02, 0.02, 0.03), at + Vector3(0.0, 0.31, 0.012), STEEL_DARK)
	_mystery(_last_notes(profile, NOTES_PINNED))


## A cork board right of the lift with the last notes found pinned up on it, [param numbers], the
## latest first, each in its paper's size and color with its lines in pencil, a red pin through
## it, and red string from pin to pin, as somebody working something out would have it; a first-aid
## kit in its place until one is found, see [method _first_aid].
func _mystery(numbers: Array[int]) -> void:
	if numbers.is_empty():
		_first_aid(BOARD_AT)
		return
	var board := BOARD_AT + Vector3(0.0, 0.0, 0.03)
	_first_aid(Vector3(BOARD_AT.x + 0.08, 0.19, WALL_Z + 0.02))
	# The cork stands proud of the wood behind it: their fronts as one flickered as the camera moved.
	_box(Vector3(BOARD.x + 0.08, BOARD.y + 0.08, 0.04), BOARD_AT + Vector3(0.0, 0.0, 0.02), WOOD)
	_box(Vector3(BOARD.x, BOARD.y, 0.02), board + Vector3(0.0, 0.0, 0.01), CORK)
	var pins: Array[Vector3] = []
	for i: int in numbers.size():
		var number := numbers[i]
		var kind := StringName(StoryNotes.NOTES.get(number, {}).get("paper", &"sheet"))
		var spec: Array = NotePage.PAPERS.get(kind, NotePage.PAPERS[&"sheet"])
		var size: Vector2 = spec[0] * NOTE_SCALE
		var paper: Color = spec[1]
		var slot: Vector2 = NOTE_SLOTS[i]
		var tilt := Basis(Vector3.BACK, sin(number * 2.3) * 0.14)
		# Each well clear of the one under it and its lines clear of it, so none flickers through.
		var note := board + Vector3(slot.x, slot.y, 0.03 + i * 0.012)
		_box(Vector3(size.x, size.y, 0.003), note, paper, tilt)
		var ink := (
			Color(0.85, 0.85, 0.85) if paper.get_luminance() < 0.4 else Color(0.32, 0.32, 0.36)
		)
		for row: int in 4:
			var wide := size.x * (0.76 - (row % 3) * 0.16)
			var line := tilt * Vector3(-size.x * 0.06, size.y * (0.25 - row * 0.15), 0.004)
			_box(Vector3(wide, 0.007, 0.002), note + line, ink, tilt)
		var pin := note + tilt * Vector3(0.0, size.y * 0.38, 0.008)
		_box(Vector3(0.025, 0.025, 0.025), pin, PINNED_RED)
		pins.append(Vector3(pin.x, pin.y, board.z + 0.03 + NOTES_PINNED * 0.012 + 0.02))
	# The string from each to the next, and across from the first to the fourth and the last.
	var ties: Array[Vector2i] = []
	for i: int in pins.size() - 1:
		ties.append(Vector2i(i, i + 1))
	if pins.size() >= 4:
		ties.append(Vector2i(0, 3))
	if pins.size() >= 3:
		ties.append(Vector2i(0, pins.size() - 1))
	for tie: Vector2i in ties:
		var from := pins[tie.x]
		var to := pins[tie.y]
		var along := to - from
		var turned := Basis(Vector3.BACK, atan2(along.y, along.x))
		_box(
			Vector3(along.length(), 0.009, 0.006),
			(from + to) * 0.5,
			PINNED_RED.darkened(0.1),
			turned
		)


## A first-aid kit at [param at], its middle: a white case with a red cross on it, its handle on top
## and a bracket under it. On the wall where the cork board goes until a note is found, and on the
## floor under the board once it is up.
func _first_aid(at: Vector3) -> void:
	var front := at + Vector3(0.0, 0.0, 0.125)
	_box(Vector3(0.46, 0.34, 0.12), at + Vector3(0.0, 0.0, 0.06), FIRST_AID)
	_box(Vector3(0.46, 0.03, 0.125), at + Vector3(0.0, 0.05, 0.06), FIRST_AID.darkened(0.12))
	_box(Vector3(0.2, 0.06, 0.01), front + Vector3(0.0, -0.04, 0.0), EXTINGUISHER)
	_box(Vector3(0.06, 0.2, 0.01), front + Vector3(0.0, -0.04, 0.0), EXTINGUISHER)
	_box(Vector3(0.16, 0.035, 0.035), at + Vector3(0.0, 0.19, 0.06), STEEL_DARK)
	_box(Vector3(0.5, 0.03, 0.14), at + Vector3(0.0, -0.185, 0.07), STEEL)


## The lift's turntable, let into the floor between its posts: a dark steel disc flush with the
## floor, bolts round its rim and two stripes of the lift's yellow across it, so it is seen to turn;
## a mesh of its own, for it to turn.
func _turntable() -> void:
	var ring := CylinderMesh.new()
	ring.top_radius = PAD_REACH + 0.05
	ring.bottom_radius = PAD_REACH + 0.05
	ring.height = 0.006
	ring.radial_segments = 40
	_solid.append([ring, Transform3D(Basis.IDENTITY, Vector3.UP * 0.002), BASE])
	var disc := CylinderMesh.new()
	disc.top_radius = PAD_REACH
	disc.bottom_radius = PAD_REACH
	disc.height = 0.01
	disc.radial_segments = 40
	var pieces: Array[Array] = [[disc, Transform3D(Basis.IDENTITY, Vector3.UP * 0.004), PAD]]
	for k: int in 2:
		var stripe := BoxMesh.new()
		stripe.size = Vector3(PAD_REACH * 1.7, 0.004, 0.07)
		var across := Basis(Vector3.UP, k * PI * 0.5)
		pieces.append([stripe, Transform3D(across, Vector3.UP * 0.01), LINE_YELLOW])
	for k: int in 10:
		var bolt := CylinderMesh.new()
		bolt.top_radius = 0.025
		bolt.bottom_radius = 0.025
		bolt.height = 0.008
		bolt.radial_segments = 8
		var at := Vector3.FORWARD.rotated(Vector3.UP, TAU * k / 10.0) * (PAD_REACH - 0.08)
		pieces.append([bolt, Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.01), STEEL])
	var plain := StandardMaterial3D.new()
	plain.vertex_color_use_as_albedo = true
	plain.roughness = 0.55
	var made := MeshInstance3D.new()
	made.name = "Turntable"
	made.mesh = Bake.tinted(pieces)
	made.material_override = plain
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(made)
	pad = made


## The last [param most] of the story's own notes [param profile] found, the latest first, none
## before one is: the loose ones of STORY.md 7.3 never.
static func _last_notes(profile: Profile, most: int) -> Array[int]:
	var found: Array[int] = []
	if profile == null:
		return found
	var notes := profile.story.notes
	for i: int in range(notes.size() - 1, -1, -1):
		if found.size() >= most:
			break
		if notes[i] >= 1 and notes[i] <= Story.NOTE_COUNT and notes[i] not in found:
			found.append(notes[i])
	return found


## A stack of three tires lying at [param at], a little out of line, as tires are stacked.
func _tires(at: Vector3) -> void:
	for k: int in 3:
		var tire := CylinderMesh.new()
		tire.top_radius = TIRE.x
		tire.bottom_radius = TIRE.x
		tire.height = TIRE.y
		tire.radial_segments = 18
		var shift := Vector3(0.04 * (k % 2), TIRE.y * (k + 0.5), -0.03 * k)
		_solid.append([tire, Transform3D(Basis.IDENTITY, at + shift), RUBBER])
		var hub := CylinderMesh.new()
		hub.top_radius = TIRE.x * 0.5
		hub.bottom_radius = TIRE.x * 0.5
		hub.height = TIRE.y + 0.004
		hub.radial_segments = 12
		_solid.append([hub, Transform3D(Basis.IDENTITY, at + shift), RUBBER.lightened(0.12)])


## A post of the lift on [param side] of the kart: red, a cap on it, its hazard band, its carriage
## let down to its foot on a dark base plate, and its two arms folded in along the floor, a pad at
## the tip of each.
func _post(side: float) -> void:
	var x := side * POST_X
	_box(POST, Vector3(x, POST.y * 0.5, 0.0), BayArt.LIFT_RED)
	var cap := Vector3(POST.x + 0.1, 0.1, POST.z + 0.1)
	_box(cap, Vector3(x, POST.y + 0.05, 0.0), BayArt.LIFT_RED.darkened(0.25))
	var band := BoxMesh.new()
	band.size = Vector3(POST.x + 0.01, 0.24, POST.z + 0.01)
	_bands.append([band, Transform3D(Basis.IDENTITY, Vector3(x, 0.78, 0.0))])
	var carriage := Vector3(POST.x + 0.12, 0.34, POST.z + 0.14)
	_box(carriage, Vector3(x, 0.4, 0.0), BayArt.LIFT_RED.darkened(0.15))
	_box(Vector3(POST.x + 0.3, 0.05, POST.z + 0.3), Vector3(x, 0.025, 0.0), BASE)
	for z: float in [-1.0, 1.0]:
		var turned := Basis(Vector3.UP, z * side * 0.16)
		var at := Vector3(x - side * 0.6, 0.04, z * 0.33)
		_box(Vector3(0.9, 0.06, 0.11), at, ARM, turned)
		_box(Vector3(0.16, 0.05, 0.16), at + turned.x * -side * 0.45 + Vector3.UP * 0.01, BASE)


## An enamel shop lamp hanging at [param at] on its cord: a green shade open below, its bulb lit,
## and its light thrown down on the floor and the wall.
func _lamp(at: Vector3) -> void:
	_box(Vector3(0.015, 4.0, 0.015), at + Vector3(0.0, 2.0, 0.0), CORD)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 0.24
	cone.height = 0.2
	cone.cap_bottom = false
	cone.radial_segments = 20
	_shades.append([cone, Transform3D(Basis.IDENTITY, at + Vector3(0.0, 0.1, 0.0))])
	var ball := SphereMesh.new()
	ball.radius = 0.06
	ball.height = 0.12
	ball.radial_segments = 12
	ball.rings = 6
	_bulbs.append([ball, Transform3D(Basis.IDENTITY, at + Vector3(0.0, 0.02, 0.0))])
	var haze := CylinderMesh.new()
	haze.top_radius = 0.2
	haze.bottom_radius = BEAM.y
	haze.height = BEAM.x
	haze.cap_top = false
	haze.cap_bottom = false
	haze.radial_segments = 20
	var leaned := Basis(Vector3.RIGHT, -LAMP_LEAN)
	var foot := at + leaned * Vector3(0.0, -BEAM.x * 0.5, 0.0)
	_beams.append([haze, Transform3D(leaned, foot)])
	var light := SpotLight3D.new()
	light.position = at
	light.rotation.x = -PI * 0.5 + LAMP_LEAN
	light.light_color = LAMP_LIGHT
	light.light_energy = LAMP_ENERGY
	light.spot_angle = LAMP_ANGLE
	light.spot_range = LAMP_REACH
	light.spot_attenuation = 0.6
	light.shadow_enabled = false
	add_child(light)


## A plain box [param size] big at [param at], turned [param turned], in [param tone], put with
## the rest to be baked into one mesh, as everything else of one plain color is.
func _box(size: Vector3, at: Vector3, tone: Color, turned := Basis.IDENTITY) -> void:
	var box := BoxMesh.new()
	box.size = size
	_solid.append([box, Transform3D(turned, at), tone])


## The plain boxes baked into one mesh, and the bands, the shades and the bulbs each into one.
func _bake() -> void:
	var plain := StandardMaterial3D.new()
	plain.vertex_color_use_as_albedo = true
	plain.roughness = 0.6
	_add(Bake.tinted(_solid), plain, Transform3D.IDENTITY)
	var stripes := _paint(Color.WHITE, 0.6)
	stripes.albedo_texture = _hazard_texture()
	stripes.uv1_scale = Vector3(3.0, 1.0, 1.0)
	_add(Bake.joined(_bands), stripes, Transform3D.IDENTITY)
	var green := _paint(BayArt.LAMP_SHADE, 0.45)
	green.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add(Bake.joined(_shades), green, Transform3D.IDENTITY)
	var lit := StandardMaterial3D.new()
	lit.albedo_color = BayArt.BULB
	lit.emission_enabled = true
	lit.emission = BayArt.BULB
	lit.emission_energy_multiplier = 3.0
	_add(Bake.joined(_bulbs), lit, Transform3D.IDENTITY)
	var haze := StandardMaterial3D.new()
	haze.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	haze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	haze.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	haze.cull_mode = BaseMaterial3D.CULL_DISABLED
	haze.no_depth_test = false
	haze.albedo_texture = _beam_texture()
	haze.albedo_color = Color(LAMP_LIGHT, BEAM_GLOW)
	_add(Bake.joined(_beams), haze, Transform3D.IDENTITY)
	_solid.clear()
	_bands.clear()
	_shades.clear()
	_bulbs.clear()
	_beams.clear()


## [param mesh] in [param look] at [param at], casting no shadow.
func _add(mesh: Mesh, look: Material, at: Transform3D) -> void:
	var made := MeshInstance3D.new()
	made.mesh = mesh
	made.material_override = look
	made.transform = at
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(made)


static func _paint(tone: Color, rough := 0.8) -> StandardMaterial3D:
	var look := StandardMaterial3D.new()
	look.albedo_color = tone
	look.roughness = rough
	return look


## Two courses of blocks, one block across, in white with the mortar between them darker, to be
## tinted the wall's tones and laid over and over.
static func _blocks_texture() -> Texture2D:
	if _blocks == null:
		var image := Image.create_empty(128, 64, true, Image.FORMAT_RGB8)
		image.fill(Color.WHITE)
		var mortar := Color(0.72, 0.72, 0.72)
		for x: int in 128:
			for y: int in [0, 1, 32, 33]:
				image.set_pixel(x, y, mortar)
		for y: int in 64:
			var joint := 0 if y < 32 else 64
			for x: int in [joint, joint + 1]:
				image.set_pixel(x, y, mortar)
		image.generate_mipmaps()
		_blocks = ImageTexture.create_from_image(image)
	return _blocks


## The lift's hazard stripes, the house's gold on black, leaning, to be laid round a post.
static func _hazard_texture() -> Texture2D:
	if _hazard == null:
		var image := Image.create_empty(64, 64, true, Image.FORMAT_RGB8)
		var gold := HouseTheme.FOIL
		var black := Color("#1b1b1f")
		for y: int in 64:
			for x: int in 64:
				image.set_pixel(x, y, gold if posmod(x + y, 32) < 14 else black)
		image.generate_mipmaps()
		_hazard = ImageTexture.create_from_image(image)
	return _hazard


## A lamp's haze from its top down: brightest at the shade, gone by its foot.
static func _beam_texture() -> Texture2D:
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = fade
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	texture.width = 4
	texture.height = 64
	return texture


## An oil stain: a soft dark blot, darkest in its middle, its edge uneven.
static func _stain_texture() -> Texture2D:
	if _stain == null:
		var image := Image.create_empty(64, 32, true, Image.FORMAT_RGBA8)
		for y: int in 32:
			for x: int in 64:
				var at := Vector2((x + 0.5) / 64.0 - 0.5, (y + 0.5) / 32.0 - 0.5) * 2.0
				var angle := atan2(at.y, at.x)
				var reach := 0.85 + 0.12 * sin(angle * 3.0) + 0.05 * sin(angle * 7.0)
				var dark := clampf(1.0 - at.length() / reach, 0.0, 1.0)
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, smoothstep(0.0, 0.6, dark)))
		image.generate_mipmaps()
		_stain = ImageTexture.create_from_image(image)
	return _stain
