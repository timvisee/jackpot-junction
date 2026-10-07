class_name SchoolProps
extends RoomBuild
## The driving school's dressing of the driving test, GAME.md 9.4a: traffic cones along the
## start corridor and round the steering pillar, road signs on poles planted in the wall tops
## where a kart will see them, learner blocks in the corners, bunting over the start, a zebra
## crossing and a parking bay painted on the floor, and the examiner's booth on the wall over
## the last room. Boxes and cylinders in the room's own materials, as the rest of the room is,
## 8.1; none of it collides but the learner blocks, which break like boxes, so the rest stands
## where a kart does not go, the edges of the road and the tops of the walls. The L-plate the
## kart wears for the test is the kart's own, see [method KartVisuals.learner_plate].

## The cones along the corridor north, by cell, on the west wall's side and the east wall's.
const CORRIDOR_CONES: Array[Vector2i] = [
	Vector2i(17, 52),
	Vector2i(20, 52),
	Vector2i(17, 49),
	Vector2i(20, 49),
	Vector2i(17, 46),
	Vector2i(20, 46),
	Vector2i(17, 43),
	Vector2i(20, 43),
	Vector2i(17, 40),
	Vector2i(20, 40),
]
## The cones at the four corners of the steering room's pillar, see [TutorialSteer].
const PILLAR := Rect2i(18, 26, 2, 2)
const PILLAR_CONES: Array[Vector2i] = [
	Vector2i(17, 25), Vector2i(20, 25), Vector2i(17, 28), Vector2i(20, 28)
]
## The signs: each its face, the wall cell its pole is planted in, and which way its face turns,
## about the upright, from facing south, toward a kart coming up a corridor north.
const SIGNS: Array[Array] = [
	[SchoolFigure.Kind.LEARNER, Vector2i(16, 52), 0.0],
	[SchoolFigure.Kind.SPEED, Vector2i(21, 44), 0.0],
	[SchoolFigure.Kind.PARKING, Vector2i(38, 23), 0.0],
	[SchoolFigure.Kind.WARNING, Vector2i(84, 23), 0.0],
	[SchoolFigure.Kind.NO_ENTRY, Vector2i(9, 0), 0.0],
]
## The roundabout sign stands on the pillar itself, facing the way in.
const ROUNDABOUT_TURN := 0.0
## The plate pointing on to the final exam, by the join under the start, facing the kart coming
## along the underpass.
const EXAM_PLATE := Vector2i(26, 57)
const EXAM_WORDS := "FINAL EXAM"
## Turned toward the camera, which looks north, and a little toward the kart coming from the
## west, so it can be read rather than seen edge-on.
const EXAM_PLATE_TURN := -PI * 0.2
## The learner blocks, by cell: the corners of the steering room, the jokers room and the drift
## room. In the driving space, so a kart bumps them and a shot breaks them, and they stay broken.
const BLOCKS: Array[Vector2i] = [
	Vector2i(9, 20), Vector2i(28, 20), Vector2i(12, 39), Vector2i(12, 55), Vector2i(63, 2)
]
## The bunting over the start: its two poles, on the wall cells either side of the pocket.
const BUNTING: Array[Vector2i] = [Vector2i(16, 58), Vector2i(21, 58)]
const BUNTING_HEIGHT := 2.6
const PENNANTS := 7
## The zebra crossing over the corridor, by the row it lies on, and the parking bay at the far
## end of the brake and reverse straight.
const CROSSING_ROW := 42
const CROSSING := Rect2i(17, 42, 4, 1)
const BAY := Rect2i(43, 26, 2, 2)
## The examiner's booth, on the wall over the top of the last room.
const BOOTH := Rect2i(36, 37, 2, 2)
## How much bigger than one of the crowd the somebody at the booth's window is, small enough to
## stand in it whole.
const WATCHER_SIZE := 1.1
## How tall the walls are the signs stand on, see [member ArenaLayout.wall_height].
const WALL_TOP := 1.0
## A cone: its base, its height, and the color a cone is.
const CONE := Color(0.94, 0.42, 0.1)
const CONE_HEIGHT := 0.72
const POLE_HEIGHT := 2.6
const SIGN_SIDE := 1.1
## How far in front of its pole a plate stands, past the pole's own radius.
const PLATE_OUT := 0.09
const SIGN_PIXELS := 256
const BLOCK_SIDE := 0.9
const BLOCK_RESPAWN := 3600.0
const STEEL := Color(0.66, 0.68, 0.72)
const PAINT_WHITE := Color(0.93, 0.92, 0.88)


## A rectangular plate with words and an arrow on it, pointing [member arrow_turn] turns
## clockwise from right.
class Plate:
	extends Control

	var words := ""
	var arrow_turn := -0.25

	func _draw() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = SchoolFigure.SIGN_BLUE
		style.set_corner_radius_all(roundi(size.y * 0.1))
		style.set_border_width_all(maxi(roundi(size.y * 0.04), 1))
		style.border_color = SchoolFigure.SIGN_WHITE
		draw_style_box(style, Rect2(Vector2.ZERO, size))
		var font := Type.display_font()
		var font_size := roundi(size.y * 0.42)
		var baseline := (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		var arrow_box := Rect2(
			Vector2(size.x - size.y * 0.95, size.y * 0.15), Vector2.ONE * size.y * 0.7
		)
		draw_string(
			font,
			Vector2(size.y * 0.2, baseline),
			words,
			HORIZONTAL_ALIGNMENT_LEFT,
			arrow_box.position.x - size.y * 0.3,
			font_size,
			SchoolFigure.SIGN_WHITE
		)
		var middle := arrow_box.get_center()
		draw_set_transform(middle, arrow_turn * TAU, Vector2.ONE)
		SchoolFigure.draw_into(
			self,
			Rect2(-arrow_box.size * 0.5, arrow_box.size),
			SchoolFigure.Kind.ARROW,
			SchoolFigure.SIGN_WHITE
		)
		draw_set_transform(Vector2.ZERO)


## Dresses [param for_arena]'s rooms for the test.
static func add_to(for_arena: Arena) -> SchoolProps:
	var props := SchoolProps.new()
	props._stand_in(for_arena, "SchoolProps")
	props._build()
	return props


func _build() -> void:
	var grid := arena.grid
	var steel := surfaces.metal(STEEL)
	for cell: Vector2i in CORRIDOR_CONES:
		# Toward the wall it stands by, so the middle of the road is clear.
		var toward := -0.3 if cell.x == CORRIDOR_CONES[0].x else 0.3
		_cone(grid.cell_center(cell) + Vector3(toward, 0.0, 0.0))
	var pillar := grid.rect_center(PILLAR)
	for cell: Vector2i in PILLAR_CONES:
		var at := grid.cell_center(cell)
		# Tucked into the pillar's corner.
		at += (pillar - at).normalized() * 0.25
		_cone(at)
	for sign: Array in SIGNS:
		_sign(sign[0], grid.cell_center(sign[1]) + Vector3(0.0, WALL_TOP, 0.0), sign[2], steel)
	_sign(
		SchoolFigure.Kind.ROUNDABOUT, pillar + Vector3(0.0, WALL_TOP, 0.0), ROUNDABOUT_TURN, steel
	)
	_plate(grid.cell_center(EXAM_PLATE) + Vector3(0.0, WALL_TOP, 0.0), EXAM_PLATE_TURN, steel)
	for i: int in BLOCKS.size():
		_block(grid.cell_center(BLOCKS[i]), i)
	_bunting(
		grid.cell_center(BUNTING[0]) + Vector3(0.0, WALL_TOP, 0.0),
		grid.cell_center(BUNTING[1]) + Vector3(0.0, WALL_TOP, 0.0),
		steel
	)
	_crossing(grid)
	_bay(grid)
	_booth(grid.rect_center(BOOTH) + Vector3(0.0, WALL_TOP, 0.0), steel)


## A traffic cone, kart-sized: a square foot and a tapering body in cone orange with a pale band.
func _cone(at: Vector3) -> void:
	var cone := surfaces.painted(CONE)
	var base := surfaces.painted(Color(0.16, 0.16, 0.18))
	var band := surfaces.painted(PAINT_WHITE)
	_box(Vector3(0.5, 0.06, 0.5), base, at + Vector3(0.0, 0.03, 0.0))
	_taper(0.2, 0.05, CONE_HEIGHT, cone, at + Vector3(0.0, CONE_HEIGHT * 0.5 + 0.06, 0.0))
	_taper(0.145, 0.115, 0.12, band, at + Vector3(0.0, CONE_HEIGHT * 0.5 + 0.1, 0.0))


## A road sign: a pole planted at [param foot], the face [param kind] near the top of it turned
## [param turn] from facing south, with a dark back.
func _sign(kind: SchoolFigure.Kind, foot: Vector3, turn: float, steel: Material) -> void:
	_cylinder(0.05, POLE_HEIGHT, steel, foot + Vector3(0.0, POLE_HEIGHT * 0.5, 0.0))
	var face := SchoolFigure.of(kind, SIGN_PIXELS)
	var drawn := DrawnTexture.of(self, face, Vector2i(SIGN_PIXELS, SIGN_PIXELS))
	var front := DrawnTexture.face(Vector2(SIGN_SIDE, SIGN_SIDE), DrawnTexture.decal(drawn))
	var forward := Vector3(sin(turn), 0.0, cos(turn))
	# The plate stands in front of its pole, not round it.
	var at := foot + Vector3(0.0, POLE_HEIGHT - SIGN_SIDE * 0.5 - 0.1, 0.0) + forward * PLATE_OUT
	front.position = at + forward * 0.025
	front.rotation.y = turn
	add_child(front)
	var back := _box(
		Vector3(SIGN_SIDE * 0.92, SIGN_SIDE * 0.92, 0.04),
		surfaces.painted(Color(0.2, 0.2, 0.22)),
		at
	)
	back.rotation.y = turn


## The plate on to the final exam: words and an arrow pointing up the way, on a pole.
func _plate(foot: Vector3, turn: float, steel: Material) -> void:
	_cylinder(0.05, POLE_HEIGHT, steel, foot + Vector3(0.0, POLE_HEIGHT * 0.5, 0.0))
	var face := Plate.new()
	face.words = EXAM_WORDS
	var pixels := Vector2i(512, 128)
	var drawn := DrawnTexture.of(self, face, pixels)
	var front := DrawnTexture.face(Vector2(2.4, 0.6), DrawnTexture.decal(drawn))
	var forward := Vector3(sin(turn), 0.0, cos(turn))
	var at := foot + Vector3(0.0, POLE_HEIGHT - 0.45, 0.0) + forward * PLATE_OUT
	front.position = at + forward * 0.025
	front.rotation.y = turn
	add_child(front)
	var back := _box(Vector3(2.3, 0.56, 0.04), surfaces.painted(Color(0.2, 0.2, 0.22)), at)
	back.rotation.y = turn


## A learner block: a white cube with the L on each side of it, a box like the arena's, see
## [Crate], that a kart bumps and a shot breaks, and that stays broken for the rest of the test.
func _block(at: Vector3, index: int) -> void:
	var block := Crate.new()
	block.name = "LearnerBlock%d" % index
	block.respawn_delay = BLOCK_RESPAWN
	block.position = at + Vector3(0.0, BLOCK_SIDE * 0.5, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * BLOCK_SIDE
	shape.shape = box
	block.add_child(shape)
	var cube := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * BLOCK_SIDE
	cube.mesh = mesh
	cube.material_override = surfaces.painted(PAINT_WHITE)
	block.add_child(cube)
	var face := SchoolFigure.of(SchoolFigure.Kind.LEARNER, 128.0)
	var drawn := DrawnTexture.of(block, face, Vector2i(128, 128))
	var decal := DrawnTexture.decal(drawn)
	for side: int in 4:
		var turn := PI * 0.5 * float(side)
		var front := DrawnTexture.face(Vector2(BLOCK_SIDE * 0.82, BLOCK_SIDE * 0.82), decal)
		front.position = Vector3(sin(turn), 0.0, cos(turn)) * (BLOCK_SIDE * 0.5 + 0.01)
		front.rotation.y = turn
		block.add_child(front)
	add_child(block)


## Bunting: a string between two poles with pennants in the players' colors along it.
func _bunting(from: Vector3, to: Vector3, steel: Material) -> void:
	for foot: Vector3 in [from, to]:
		_cylinder(0.04, BUNTING_HEIGHT, steel, foot + Vector3(0.0, BUNTING_HEIGHT * 0.5, 0.0))
	var top_from := from + Vector3(0.0, BUNTING_HEIGHT, 0.0)
	var top_to := to + Vector3(0.0, BUNTING_HEIGHT, 0.0)
	var along := top_to - top_from
	var line := _box(
		Vector3(along.length(), 0.02, 0.02),
		surfaces.painted(Color(0.3, 0.3, 0.32)),
		top_from + along * 0.5
	)
	line.rotation.y = atan2(-along.z, along.x)
	for i: int in PENNANTS:
		var share := (float(i) + 0.5) / float(PENNANTS)
		var at := top_from + along * share
		# The string sags a little in the middle, the way one does.
		at.y -= sin(share * PI) * 0.18
		var color := Palette.PLAYER_COLORS[i % Palette.PLAYER_COLORS.size()]
		var pennant := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.28, 0.36, 0.02)
		mesh.left_to_right = 0.5
		pennant.mesh = mesh
		pennant.material_override = surfaces.painted(color)
		pennant.position = at + Vector3(0.0, -0.18, 0.0)
		# Point down: a prism points up.
		pennant.rotation.z = PI
		pennant.rotation.y = atan2(-along.z, along.x)
		add_child(pennant)


## A zebra crossing painted over the corridor, flat on the floor.
func _crossing(grid: ArenaGrid) -> void:
	var paint := surfaces.marking(PAINT_WHITE)
	var middle := grid.rect_center(CROSSING)
	var across := float(CROSSING.size.x) * grid.cell_size
	var stripes := 6
	for i: int in stripes:
		var x := middle.x - across * 0.5 + across * (float(i) + 0.5) / float(stripes)
		_box(
			Vector3(across / float(stripes) * 0.55, 0.012, 1.0), paint, Vector3(x, 0.006, middle.z)
		)


## A parking bay painted at the end of the brake and reverse straight: three sides of a box,
## open to the way the kart comes.
func _bay(grid: ArenaGrid) -> void:
	var paint := surfaces.marking(PAINT_WHITE)
	var middle := grid.rect_center(BAY)
	var size := Vector2(BAY.size) * grid.cell_size
	var width := 0.12
	_box(Vector3(width, 0.012, size.y), paint, middle + Vector3(size.x * 0.5, 0.006, 0.0))
	for side: float in [-1.0, 1.0]:
		_box(
			Vector3(size.x, 0.012, width), paint, middle + Vector3(0.0, 0.006, side * size.y * 0.5)
		)


## The examiner's booth: a cabin with a lit window looking over the last room, a roof, and a
## pennant on a pole either side of it; after the ending, somebody at the window.
func _booth(at: Vector3, steel: Material) -> void:
	var wall := surfaces.painted(Color(0.24, 0.3, 0.38))
	var trim := surfaces.painted(PAINT_WHITE)
	var glass := surfaces.neon(Color(0.95, 0.9, 0.7), 0.5)
	var size := Vector3(2.6, 2.0, 2.0)
	_box(size, wall, at + Vector3(0.0, size.y * 0.5, 0.0))
	_box(Vector3(size.x + 0.4, 0.14, size.z + 0.4), trim, at + Vector3(0.0, size.y + 0.07, 0.0))
	# The window on the south face, toward the room, with a sill under it.
	_box(Vector3(1.7, 0.8, 0.04), glass, at + Vector3(0.0, 1.25, size.z * 0.5 + 0.02))
	_box(Vector3(1.9, 0.08, 0.16), trim, at + Vector3(0.0, 0.82, size.z * 0.5 + 0.06))
	if Story.stage_here() == Story.Stage.OPERATOR:
		_watcher(at + Vector3(0.0, 0.84, size.z * 0.5 + 0.1))
	for side: float in [-1.0, 1.0]:
		var foot := at + Vector3(side * (size.x * 0.5 + 0.6), 0.0, 0.0)
		_cylinder(0.04, 3.2, steel, foot + Vector3(0.0, 1.6, 0.0))
		var flag := _box(
			Vector3(0.5, 0.3, 0.02),
			surfaces.painted(Palette.CHIP_GOLD),
			foot + Vector3(side * 0.27, 3.0, 0.0)
		)
		flag.rotation.y = 0.0


## Somebody standing at the booth's window, STORY.md 6.7: built as an inspector is, a suit and a
## head with hair on it, no vest and no clipboard, on the sill and up against the glass, the light
## behind them, facing the room. Who it is is not said.
func _watcher(foot: Vector3) -> void:
	var figure := Node3D.new()
	figure.name = "Watcher"
	figure.position = foot
	figure.scale = Vector3(WATCHER_SIZE, WATCHER_SIZE, WATCHER_SIZE * 0.35)
	add_child(figure)
	var suit := CapsuleMesh.new()
	suit.radius = 0.15
	suit.height = Crowd.BODY
	var body := MeshInstance3D.new()
	body.mesh = suit
	body.material_override = surfaces.painted(SchoolInspectors.SUIT)
	body.position = Vector3(0.0, Crowd.BODY * 0.5, 0.0)
	figure.add_child(body)
	var middle := Crowd.BODY + Crowd.HEAD * 0.7
	var face := SphereMesh.new()
	face.radius = Crowd.HEAD
	face.height = Crowd.HEAD * 2.0
	var head := MeshInstance3D.new()
	head.mesh = face
	head.material_override = surfaces.painted(SchoolInspectors.SKINS[0])
	head.position = Vector3(0.0, middle, 0.0)
	figure.add_child(head)
	var hair := SphereMesh.new()
	hair.radius = Crowd.HEAD * 1.03
	hair.height = Crowd.HEAD * 2.06
	var cap := MeshInstance3D.new()
	cap.mesh = hair
	cap.material_override = surfaces.painted(SchoolInspectors.HAIR[0])
	cap.position = Vector3(0.0, middle + Crowd.HEAD * 0.42, -Crowd.HEAD * 0.14)
	cap.scale = Vector3(1.0, 0.62, 1.0)
	figure.add_child(cap)
