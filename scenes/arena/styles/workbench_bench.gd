class_name WorkbenchBench
extends RefCounted
## The workshop round table one, GAME.md 8.1 and STORY.md 3.10, for [WorkbenchStyle]: the bench's
## edge and legs, the board behind it with the calendar nobody turned over and Kit's slate where the
## pegboard was, the lamp and the vice the room always had, and a handful of things a careful maker
## puts down square and leaves where they belong. Each is placed rather than dealt, at a place of
## its own, so the room reads as a workshop somebody keeps rather than one somebody left, and all
## of it in the few paints of the table, so the room bakes to a few meshes, GAME.md 8.1.
##
## The room's patches, [constant RoomBuild.PATCH], are measured for the props the rooms deal; each
## of Kit's things is put down in the patch of the one whose size it fits, which is what keeps it
## out of everything else on the table and everything else out of it.

const GLASS := Color("#B9C4BC")
## What is in the three jars: buttons in cream, in Kit's red and in ink.
const JARS: Array[Color] = [WorkbenchStyle.CREAM, WorkbenchStyle.RED, WorkbenchStyle.INK]

var style: WorkbenchStyle
var props: RoomProps


func _init(for_style: WorkbenchStyle, into: RoomProps) -> void:
	style = for_style
	props = into


## Builds the room and puts every one of Kit's things down in it.
func lay() -> void:
	var shell := props.shell
	shell.enclose(Color(0.13, 0.115, 0.1), Color(0.25, 0.22, 0.19), 32.0, 80.0)
	shell.skirt(style.room.table.darkened(0.3), 2.4)
	shell.legs(style.room.table.darkened(0.42))
	var board := shell.backboard(24.0, WorkbenchStyle.BOARD)
	shell.calendar(board)
	_slate(shell, board)
	var half := props.arena.world_size() * 0.5
	var top := RoomBuild.TOP
	props._lay(
		&"lamp",
		Vector3(-(half.x + 12.0), top, -(half.y + 10.0)),
		func(at: Vector3, _turn: float) -> void: props._bench_lamp(at),
		true
	)
	props._lay(
		&"vice",
		Vector3(-(half.x + 9.0), top, half.y * 0.25),
		func(at: Vector3, _turn: float) -> void: props._vice(at),
		true
	)
	# Three jars in a row behind the crowd, and the chalk by the slate.
	for i: int in JARS.size():
		var ink: Color = JARS[i]
		_put_down(
			&"glass",
			[Vector3(10.0 + 4.0 * float(i), top, -(half.y + 8.95))],
			func(at: Vector3, _turn: float) -> void: _jar(at, ink)
		)
	_put_down(&"glass", [Vector3(-16.0, top, -(half.y + 8.95))], _chalk_box)
	# Down the right flank, the calculator, the mug and the blocks; the plane on the left.
	_put_down(
		&"tin",
		[Vector3(half.x + 11.6, top, -half.y * 1.07), Vector3(half.x + 11.6, top, -14.0)],
		_calculator
	)
	_put_down(&"tin", [Vector3(half.x + 11.6, top, half.y * 0.04)], _mug)
	_put_down(&"floodlight", [Vector3(half.x + 11.0, top, half.y * 0.8)], _blocks)
	_put_down(&"floodlight", [Vector3(-(half.x + 11.0), top, -half.y * 0.4)], _plane)
	# And on the near apron, flat: the pencil and the rule side by side.
	_put_down(&"pencil", [Vector3(-7.0, top, half.y + 11.25)], _pencil)
	_put_down(&"pencil", [Vector3(7.0, top, half.y + 11.25)], _ruler)


## Kit's slate on the board behind the bench where the pegboard was: the plan of table one in chalk,
## in a maple frame, a ledge under it with chalk and a duster on it.
func _slate(shell: RoomShell, face: float) -> void:
	var middle := Vector3(0.0, RoomBuild.TOP + 6.2, face + 0.3)
	var size := Vector2(20.0, 10.0)
	var slate := QuadMesh.new()
	slate.size = size
	shell._dim(
		shell._put(slate, style.printed(WorkbenchStyle.SLATE), middle + Vector3(0.0, 0.0, 0.32))
	)
	var maple := style.wood(WorkbenchStyle.MAPLE)
	var rail := 0.8
	for side: float in [-1.0, 1.0]:
		var up := Vector3(0.0, side * (size.y + rail) * 0.5, 0.0)
		shell._dim(shell._box(Vector3(size.x + rail * 2.0, rail, 0.7), maple, middle + up))
		var out := Vector3(side * (size.x + rail) * 0.5, 0.0, 0.0)
		shell._dim(shell._box(Vector3(rail, size.y, 0.7), maple, middle + out))
	var ledge := middle + Vector3(0.0, -size.y * 0.5 - rail - 0.2, 0.9)
	shell._dim(shell._box(Vector3(size.x * 0.7, 0.4, 2.0), maple, ledge))
	var chalk := style.paint(WorkbenchStyle.CREAM)
	for i: int in 3:
		var stick := shell._cylinder(0.22, 1.6, chalk, ledge + Vector3(4.0 + i * 1.2, 0.42, 0.2))
		stick.rotation = Vector3(0.0, 0.0, PI * 0.5)
	shell._dim(
		shell._box(
			Vector3(3.0, 0.7, 1.2),
			style.wood(WorkbenchStyle.WALNUT),
			ledge + Vector3(-5.0, 0.55, 0.0)
		)
	)
	shell._dim(
		shell._box(
			Vector3(3.0, 0.3, 1.2), style.paint(WorkbenchStyle.INK), ledge + Vector3(-5.0, 0.1, 0.0)
		)
	)


## Puts a [param kind] down at the first of [param spots] that is free, trying each a few times,
## since the turn of a patch is rolled anew every time.
func _put_down(kind: StringName, spots: Array, build: Callable) -> void:
	for spot: Vector3 in spots:
		for attempt: int in 8:
			if props._lay(kind, spot, build):
				return


## A box of [param size] at [param offset] in a thing's own frame, the thing standing at
## [param at] turned [param turn].
func _piece(
	size: Vector3, skin: Material, at: Vector3, turn: float, offset: Vector3
) -> MeshInstance3D:
	var part := props._box(size, skin, at + offset.rotated(Vector3.UP, turn))
	part.rotation.y = turn
	return part


## A jar of buttons, [param ink] showing through the glass, its lid screwed on.
func _jar(at: Vector3, ink: Color) -> void:
	props._cylinder(1.08, 1.5, style.paint(ink), at + Vector3(0.0, 0.85, 0.0))
	props._cylinder(1.1, 0.1, style.paint(GLASS), at + Vector3(0.0, 0.05, 0.0))
	props._cylinder(1.1, 0.7, style.paint(GLASS), at + Vector3(0.0, 1.95, 0.0))
	props._cylinder(1.16, 0.36, style.metal(WorkbenchStyle.BRASS), at + Vector3(0.0, 2.48, 0.0))


## A box of chalk in ink with a red band round it and four sticks laid on top.
func _chalk_box(at: Vector3, _turn: float) -> void:
	props._box(
		Vector3(2.0, 0.9, 2.4), style.paint(WorkbenchStyle.INK), at + Vector3(0.0, 0.45, 0.0)
	)
	props._box(
		Vector3(2.04, 0.3, 2.44), style.paint(WorkbenchStyle.RED), at + Vector3(0.0, 0.45, 0.0)
	)
	var chalk := style.paint(WorkbenchStyle.CREAM)
	for i: int in 4:
		var stick := props._cylinder(
			0.16, 1.8, chalk, at + Vector3(0.0, 1.06, -0.75 + 0.5 * float(i))
		)
		stick.rotation = Vector3(0.0, 0.0, PI * 0.5)


## Kit's pocket calculator lying on the bench, switched on and reading 0.
func _calculator(at: Vector3, _turn: float) -> void:
	props._box(
		Vector3(4.2, 0.6, 6.2), style.paint(WorkbenchStyle.CREAM), at + Vector3(0.0, 0.3, 0.0)
	)
	var face := PlaneMesh.new()
	face.size = Vector2(4.0, 6.0)
	props._put(face, style.printed(WorkbenchStyle.CALCULATOR), at + Vector3(0.0, 0.61, 0.0))


## A mug with three carpenter's pencils standing in it.
func _mug(at: Vector3, _turn: float) -> void:
	var china := style.paint(WorkbenchStyle.CREAM)
	props._cylinder(2.2, 4.6, china, at + Vector3(0.0, 2.3, 0.0))
	props._box(Vector3(0.6, 2.6, 0.7), china, at + Vector3(2.55, 2.6, 0.0))
	props._cylinder(1.95, 0.1, style.paint(WorkbenchStyle.INK), at + Vector3(0.0, 4.4, 0.0))
	var red := style.paint(WorkbenchStyle.RED)
	for i: int in 3:
		var turn := TAU * float(i) / 3.0 + 0.4
		var lean := Vector3(sin(turn), 0.0, cos(turn))
		var pencil := props._box(Vector3(0.6, 6.4, 0.32), red, at + Vector3(0.0, 5.0, 0.0) + lean)
		pencil.rotation = Vector3(0.0, turn, 0.12)


## Three of Kit's blocks, two down and one on top, each with the mark the boxes have.
func _blocks(at: Vector3, _turn: float) -> void:
	var maple := style.wood(WorkbenchStyle.MAPLE)
	var mark := style.burn()
	var side := 1.5
	for spot: Vector3 in [
		Vector3(-0.78, 0.0, 0.0), Vector3(0.78, 0.0, 0.0), Vector3(0.0, side, 0.0)
	]:
		var middle := at + spot + Vector3(0.0, side * 0.5, 0.0)
		props._box(Vector3.ONE * side, maple, middle)
		var face := PlaneMesh.new()
		face.size = Vector2.ONE * side * 0.84
		props._put(face, mark, middle + Vector3(0.0, side * 0.5 + 0.01, 0.0))


## A wooden plane: a walnut stock on an ink sole, its iron set in a wedge, the knob and tote red.
func _plane(at: Vector3, _turn: float) -> void:
	props._box(
		Vector3(3.0, 0.9, 1.3), style.wood(WorkbenchStyle.WALNUT), at + Vector3(0.0, 0.55, 0.0)
	)
	props._box(
		Vector3(3.0, 0.1, 1.3), style.paint(WorkbenchStyle.INK), at + Vector3(0.0, 0.05, 0.0)
	)
	var iron := props._box(
		Vector3(0.12, 1.2, 1.0), style.metal(WorkbenchStyle.BRASS), at + Vector3(-0.1, 1.1, 0.0)
	)
	iron.rotation.z = 0.7
	var red := style.paint(WorkbenchStyle.RED)
	props._cylinder(0.3, 0.5, red, at + Vector3(1.0, 1.25, 0.0))
	props._box(Vector3(0.9, 0.8, 0.4), red, at + Vector3(-1.0, 1.35, 0.0))


## A carpenter's pencil in Kit's red, flat so it lies where it is put, sharpened at one end.
func _pencil(at: Vector3, turn: float) -> void:
	_piece(Vector3(0.9, 0.45, 6.8), style.paint(WorkbenchStyle.RED), at, turn, Vector3(0, 0.23, 0))
	var wood := style.wood(WorkbenchStyle.MAPLE)
	_piece(Vector3(0.8, 0.4, 0.9), wood, at, turn, Vector3(0.0, 0.21, 3.85))
	_piece(Vector3(0.3, 0.16, 0.5), style.paint(WorkbenchStyle.INK), at, turn, Vector3(0, 0.2, 4.5))


## A maple rule with the walls' own markings along it, eight meters of it.
func _ruler(at: Vector3, turn: float) -> void:
	# Set a little forward on its patch, which reaches further out than back.
	var shift := Vector3(0.0, 0.0, 0.45)
	_piece(
		Vector3(0.9, 0.16, 8.0),
		style.wood(WorkbenchStyle.MAPLE),
		at,
		turn,
		shift + Vector3(0, 0.08, 0)
	)
	var strip := SurfaceTool.new()
	strip.begin(Mesh.PRIMITIVE_TRIANGLES)
	strip.set_normal(Vector3.UP)
	var corners: Array[Vector3] = [
		Vector3(-0.4, 0.165, -4.0),
		Vector3(-0.4, 0.165, 4.0),
		Vector3(0.4, 0.165, 4.0),
		Vector3(0.4, 0.165, -4.0)
	]
	var reach := 8.0 / WorkbenchStyle.RULE_RUN
	var uvs: Array[Vector2] = [Vector2(0, 0), Vector2(reach, 0), Vector2(reach, 1), Vector2(0, 1)]
	for i: int in [0, 2, 1, 0, 3, 2]:
		strip.set_uv(uvs[i])
		strip.add_vertex(corners[i] + shift)
	var face := props._put(strip.commit(), style.printed(WorkbenchStyle.RULE), at)
	face.rotation.y = turn
