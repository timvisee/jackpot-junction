class_name YardLot
extends RefCounted
## The container yard round Crossfire's table, GAME.md 8.1 and STORY.md 3.9, for [YardStyle]: the
## yard that was a works yard and is a table now, kept the way a yard is kept. The warehouse at the
## back with its lit sign over the doors, the hoarding in front of it with the hard hat still hung
## on it and the House's poster beside it, and the fence the crowd stands at. Over all of it the
## yard's gantry crane straddles the table on its rails, its hook hung high over the Junction; the
## containers stand stacked two high down the left flank by the crane's leg and in the far right
## corner by the site office, two floodlights not yet on stand along the back, and pallets, wrapped
## loads and the forklift are set down in rows down the flanks and along the back. Everything is put
## down by hand, square with the table: a yard is laid out, and what stands in it stands in rows.
##
## Built through the room's [RoomProps] and its [RoomShell], so it is baked with them, in the
## style's corrugated steel and its one plain paint, see [method YardStyle.tinted_box].

## A real container: twenty feet long, eight wide and eight and a half high.
const BOX := Vector3(2.44, 2.6, 6.1)
## How far apart two containers side by side stand.
const GAP := 0.2
## A wrapped load on its pallet, how far apart two in a row stand, and how tall a pallet is.
const LOAD := Vector3(1.3, 1.5, 1.3)
const LOAD_GAP := 0.3
const PALLET := 0.16
## The gantry crane: how far out its legs stand, how far apart its two posts a side are along the
## table, how high its girders run, and the lowest point of the hook hung under it: clear of the
## game's air, GAME.md 8.1, and out of the shot once the camera comes in on the karts.
const CRANE_OUT := 17.0
const CRANE_POSTS := 5.0
const CRANE_HIGH := 22.0
const HOOK_LOW := 14.6
## The crane's paint, the hook block's yellow, and the dark steel of the rails it runs on.
const CRANE := Color("#4E5A62")
const HOOK := Color("#A88E3E")
const DARK := Color("#26282B")
const RAIL := Color("#3A3C3F")
## The site office: a cabin, its windows and its door.
const CABIN := Color("#A09A8C")
const GLASS := Color("#2B333A")
const DOOR := Color("#5E6B73")
## The floodlights' masts and their lamps, which are not on yet.
const MAST := Color("#7B8085")
const LENS := Color("#C8C8BE")
## The forklift's paint, its rubber and the steel of its mast and forks.
const FORKLIFT := Color("#6E4D38")
const RUBBER := Color("#1E1F22")

var style: YardStyle
var props: RoomProps
var shell: RoomShell
var half: Vector2


func _init(for_style: YardStyle, into: RoomProps) -> void:
	style = for_style
	props = into
	shell = into.shell
	half = into.arena.world_size() * 0.5


## Builds the yard and puts everything down in it.
func lay() -> void:
	var wall := shell.enclose(Color(0.2, 0.195, 0.18), Color(0.33, 0.31, 0.28), 3.4, 46.0)
	shell.facade(wall)
	shell.sign(wall)
	shell.skirt(props.room.table.darkened(0.22), 3.2)
	shell.hoarding()
	shell.crowd_fence()
	_crane()
	_stacks()
	_office()
	_floodlights()
	_flanks()


# --- the crane ---------------------------------------------------------------


## The gantry crane over the table: a leg each side, two posts on a sill on its bogies, standing
## on its rail; two girders across the top from leg to leg, the trolley on them over the Junction
## and the hook block hung from it on its ropes. The shell's, since it stands over the table rather
## than in a patch of it; only its legs are kept clear on the ground.
func _crane() -> void:
	var over := props.arena.junction_position
	var top := RoomBuild.TOP
	var out := half.x + CRANE_OUT
	for side: float in [-1.0, 1.0]:
		var x := side * out
		# The rail, the length of the table, which the crane runs along.
		var reach := props._table().y - 1.0
		_flat(Vector3(0.5, 0.08, reach * 2.0), RAIL, Vector3(x, top + 0.04, 0.0))
		for end: float in [-1.0, 1.0]:
			var bogie := Vector3(x, top + 0.55, over.z + end * (CRANE_POSTS + 0.8))
			_shell_box(Vector3(1.6, 1.1, 2.2), DARK, bogie)
		var sill := Vector3(x, top + 1.7, over.z)
		_shell_box(Vector3(1.3, 1.2, CRANE_POSTS * 2.0 + 3.0), CRANE, sill)
		for end: float in [-1.0, 1.0]:
			var post := Vector3(x, top + 2.3 + CRANE_HIGH * 0.5, over.z + end * CRANE_POSTS)
			_shell_box(Vector3(0.8, CRANE_HIGH, 0.8), CRANE, post)
		var brace := Vector3(x, top + CRANE_HIGH * 0.45, over.z)
		_shell_box(Vector3(0.6, 0.6, CRANE_POSTS * 2.0), CRANE, brace)
		var tie := Vector3(x, top + 2.3 + CRANE_HIGH + 0.8, over.z)
		_shell_box(Vector3(1.2, 1.2, CRANE_POSTS * 2.0 + 0.8), CRANE, tie)
		shell._keep(
			Vector3(x, top, over.z - CRANE_POSTS - 2.0),
			Vector3(x, top, over.z + CRANE_POSTS + 2.0),
			2.4
		)
	var girder_y := top + 2.3 + CRANE_HIGH + 0.8
	for side: float in [-1.0, 1.0]:
		var girder := Vector3(over.x, girder_y, over.z + side * 1.3)
		_shell_box(Vector3(out * 2.0 + 1.2, 1.1, 0.7), CRANE, girder)
	var trolley := Vector3(over.x, girder_y + 1.25, over.z)
	_shell_box(Vector3(3.4, 1.4, 3.6), CRANE.darkened(0.15), trolley)
	_hook(over, girder_y + 0.55)


## The hook block hung over [param over] on its ropes from [param from] up: the yellow block, the
## black housing of its sheaves over it and the swivel under it, and the hook, its lowest point at
## [constant HOOK_LOW], turned so the camera sees its bend.
func _hook(over: Vector3, from: float) -> void:
	var swivel := HOOK_LOW + 0.5
	var block_y := swivel + 0.2 + 0.5
	var top := block_y + 0.5 + 0.3
	for side: float in [-1.0, 1.0]:
		var rope := Vector3(over.x + side * 0.3, (from + top) * 0.5, over.z)
		_shell_box(Vector3(0.07, from - top, 0.07), DARK, rope)
	_shell_box(Vector3(1.0, 0.32, 0.72), DARK, Vector3(over.x, block_y + 0.64, over.z))
	_shell_box(Vector3(0.9, 1.0, 0.62), HOOK, Vector3(over.x, block_y, over.z))
	_shell_box(Vector3(0.3, 0.24, 0.3), DARK, Vector3(over.x, swivel + 0.08, over.z))
	# The hook, in bare steel: its shank down from the swivel, the bend and the tip turned up.
	var shank := Vector3(over.x, (HOOK_LOW + swivel) * 0.5, over.z)
	_shell_box(Vector3(0.2, swivel - HOOK_LOW, 0.2), YardStyle.STEEL, shank)
	var bend := Vector3(over.x + 0.28, HOOK_LOW + 0.1, over.z)
	_shell_box(Vector3(0.76, 0.2, 0.2), YardStyle.STEEL, bend)
	var tip := Vector3(over.x + 0.56, HOOK_LOW + 0.2, over.z)
	_shell_box(Vector3(0.2, 0.4, 0.2), YardStyle.STEEL, tip)


# --- the stacks and the office -----------------------------------------------


## The containers, end on to the table with their doors toward it, two side by side and one on top
## of one of them: a stack down the left flank by the crane's leg, and one in the far right corner
## by the office.
func _stacks() -> void:
	var pair := Rect2(-BOX.x - GAP * 0.5, -BOX.z * 0.5, BOX.x * 2.0 + GAP, BOX.z)
	var left := Vector3(-(half.x + 13.0), RoomBuild.TOP, -half.y * 0.3)
	_place(&"stack", pair, left, _stack.bind([YardStyle.SLATE, YardStyle.RUST, YardStyle.SAND]))
	var right := Vector3(half.x + 15.6, RoomBuild.TOP, -(half.y + 8.2))
	_place(&"stack", pair, right, _stack.bind([YardStyle.SAGE, YardStyle.RUST, YardStyle.SLATE]))


## Two containers side by side at [param at] in the first two of [param inks], and one on top of
## the first in the third.
func _stack(at: Vector3, _turn: float, inks: Array) -> void:
	var apart := Vector3((BOX.x + GAP) * 0.5, 0.0, 0.0)
	_container(at - apart, inks[0])
	_container(at + apart, inks[1])
	_container(at - apart + Vector3(0.0, BOX.y, 0.0), inks[2])


func _container(foot: Vector3, ink: Color) -> void:
	style.container(props, BOX, foot, ink)


## The site office by the right-hand stack: a cabin on blocks, two windows along the side facing
## the table and the door between them, the steps up to it, and a roof a little over its walls.
func _office() -> void:
	var size := Vector3(2.6, 2.7, 6.4)
	var at := Vector3(half.x + 10.0, RoomBuild.TOP, -(half.y + 7.8))
	var patch := Rect2(-size.x * 0.5 - 1.2, -size.z * 0.5 - 0.2, size.x + 1.4, size.z + 0.4)
	_place(&"office", patch, at, _cabin.bind(size))


func _cabin(foot: Vector3, _turn: float, size: Vector3) -> void:
	var lift := 0.3
	for z: float in [-1.0, 1.0]:
		_prop_box(Vector3(size.x * 0.8, lift, 0.5), DARK, foot + Vector3(0.0, lift * 0.5, z * 2.4))
	var body := Vector3(size.x, size.y, size.z)
	_prop_box(body, CABIN, foot + Vector3(0.0, lift + size.y * 0.5, 0.0))
	_prop_box(
		Vector3(size.x + 0.2, 0.18, size.z + 0.2),
		CABIN.darkened(0.25),
		foot + Vector3(0.0, lift + size.y + 0.09, 0.0)
	)
	# The side facing the table: two windows and the door between them, and the steps.
	var face := -size.x * 0.5 - 0.03
	for z: float in [-1.0, 1.0]:
		var window := foot + Vector3(face, lift + size.y * 0.62, z * 1.9)
		_prop_box(Vector3(0.08, 0.9, 1.6), GLASS, window)
	_prop_box(Vector3(0.08, 2.0, 0.9), DOOR, foot + Vector3(face, lift + 1.0, 0.0))
	for i: int in 2:
		var step := foot + Vector3(face - 0.35 - 0.3 * float(i), 0.1 + 0.1 * float(1 - i), 0.0)
		_prop_box(Vector3(0.6, 0.2 + 0.2 * float(1 - i), 1.2), DARK.lightened(0.2), step)


# --- the back ----------------------------------------------------------------


## Two floodlights along the back, on masts, their lamps not yet on: the day is not done.
func _floodlights() -> void:
	for side: float in [-1.0, 1.0]:
		var at := Vector3(side * half.x * 0.8, RoomBuild.TOP, -(half.y + 10.8))
		_place(&"floodlight", Rect2(-3.5, -2.0, 7.0, 4.0), at, _floodlight)


func _floodlight(at: Vector3, _turn: float) -> void:
	_prop_box(Vector3(2.2, 0.4, 2.2), DARK.lightened(0.15), at + Vector3(0.0, 0.2, 0.0))
	style.tinted_cylinder(props, 0.32, 17.0, MAST, at + Vector3(0.0, 8.9, 0.0), 8)
	_prop_box(Vector3(6.4, 0.3, 0.3), MAST, at + Vector3(0.0, 17.2, 0.0))
	for i: int in 3:
		var head := _prop_box(
			Vector3(1.7, 1.3, 0.5), DARK, at + Vector3((float(i) - 1.0) * 2.1, 17.6, 0.45)
		)
		head.rotation.x = 0.4
		var lens := _prop_box(
			Vector3(1.4, 1.0, 0.06), LENS, at + Vector3((float(i) - 1.0) * 2.1, 17.52, 0.72)
		)
		lens.rotation.x = 0.4


# --- the flanks --------------------------------------------------------------


## Down the flanks, short of the crane's legs: the forklift parked nose out on the right with a
## row of wrapped loads beside it, and on the left a row of loads and a stack of empty pallets
## either side of the containers; along the back, behind the crowd, two more loads in a row and
## another stack of pallets.
func _flanks() -> void:
	var parked := Vector3(half.x + 9.8, RoomBuild.TOP, -half.y * 0.7)
	_place(&"forklift", Rect2(-1.3, -3.4, 2.6, 6.0), parked, _forklift)
	_loads(Vector3(half.x + 9.8, RoomBuild.TOP, half.y * 0.05), 3, true)
	_loads(Vector3(-(half.x + 9.8), RoomBuild.TOP, -half.y), 3, true)
	_pallets(Vector3(-(half.x + 9.8), RoomBuild.TOP, half.y * 0.3))
	_loads(Vector3(half.x * 0.36, RoomBuild.TOP, -(half.y + 9.0)), 2, false)
	_pallets(Vector3(-half.x * 0.36 + 6.0, RoomBuild.TOP, -(half.y + 9.0)))


## [param count] wrapped loads on their pallets in a row at [param at], down the flank when
## [param down], along the back otherwise: the arena's own boxes, full size.
func _loads(at: Vector3, count: int, down: bool) -> void:
	var long := float(count) * (LOAD.x + LOAD_GAP) - LOAD_GAP
	var patch := Rect2(-LOAD.x * 0.5, -long * 0.5, LOAD.x, long)
	if not down:
		patch = Rect2(-long * 0.5, -LOAD.z * 0.5, long, LOAD.z)
	_place(&"loads", patch, at, _row_of_loads.bind(count, down))


func _row_of_loads(foot: Vector3, _turn: float, count: int, down: bool) -> void:
	for i: int in count:
		var along := (float(i) - float(count - 1) * 0.5) * (LOAD.x + LOAD_GAP)
		var spot := foot + (Vector3(0.0, 0.0, along) if down else Vector3(along, 0.0, 0.0))
		style.pallet_load(props, LOAD, spot)


## A stack of empty pallets at [param at], squared up, five high.
func _pallets(at: Vector3) -> void:
	var patch := Rect2(-LOAD.x * 0.5, -LOAD.z * 0.5, LOAD.x, LOAD.z)
	_place(&"pallets", patch, at, _pallet_stack)


func _pallet_stack(foot: Vector3, _turn: float) -> void:
	var timber := YardStyle.TIMBER
	for i: int in 5:
		var lift := foot + Vector3(0.0, float(i) * PALLET, 0.0)
		for z: float in [-1.0, 0.0, 1.0]:
			var runner := lift + Vector3(0.0, PALLET * 0.35, z * LOAD.z * 0.42)
			_prop_box(Vector3(LOAD.x, PALLET * 0.7, 0.16), timber.darkened(0.12), runner)
		var deck := lift + Vector3(0.0, PALLET * 0.85, 0.0)
		_prop_box(Vector3(LOAD.x, PALLET * 0.3, LOAD.z), timber, deck)


## The forklift, parked nose out toward the back of the yard: its body and counterweight, the cage
## over the seat, the mast with two uprights in front and the forks on the ground, on four wheels.
func _forklift(at: Vector3, _turn: float) -> void:
	_prop_box(Vector3(1.9, 1.3, 2.8), FORKLIFT, at + Vector3(0.0, 0.95, 0.5))
	_prop_box(Vector3(1.8, 0.9, 0.9), FORKLIFT.darkened(0.2), at + Vector3(0.0, 1.4, 1.6))
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var post := at + Vector3(x * 0.8, 2.6, 0.5 + z * 0.9)
			_prop_box(Vector3(0.1, 1.9, 0.1), DARK, post)
		_prop_box(Vector3(0.16, 3.2, 0.16), DARK, at + Vector3(x * 0.6, 1.6, -1.05))
		_prop_box(Vector3(0.22, 0.1, 1.9), YardStyle.STEEL, at + Vector3(x * 0.42, 0.05, -2.2))
		for z: float in [-0.5, 1.5]:
			var wheel := style.tinted_cylinder(
				props, 0.42, 0.36, RUBBER, at + Vector3(x * 0.85, 0.42, z), 12
			)
			wheel.rotation.z = PI * 0.5
	_prop_box(Vector3(1.8, 0.1, 1.9), DARK, at + Vector3(0.0, 3.55, 0.5))
	_prop_box(Vector3(1.3, 0.12, 0.12), DARK, at + Vector3(0.0, 3.1, -1.05))


# --- putting things down -----------------------------------------------------


## Puts [param build] down at [param at] over [param patch] of the table in its own frame, as
## [method RoomProps._lay] puts down a kind it has measured: the patch is kept, so nothing put down
## afterwards lands in it, and the parts are listed under it, so the rules of 8.1 can be checked.
func _place(kind: StringName, patch: Rect2, at: Vector3, build: Callable) -> void:
	var box := props._ground(patch, at, 0.0)
	var from := props.get_child_count()
	build.call(at, 0.0)
	props._taken.append(box)
	props.laid_out.append(
		{"kind": kind, "box": box, "from": from, "to": props.get_child_count(), "turn": 0.0}
	)


func _prop_box(size: Vector3, ink: Color, at: Vector3) -> MeshInstance3D:
	return style.tinted_box(props, size, ink, at)


func _shell_box(size: Vector3, ink: Color, at: Vector3) -> MeshInstance3D:
	return shell._dim(style.tinted_box(shell, size, ink, at))


## Lies flat on the ground: casts no shadow, since there is nothing under it to cast one on.
func _flat(size: Vector3, ink: Color, at: Vector3) -> MeshInstance3D:
	return shell._dim(style.tinted_box(shell, size, ink, at))
