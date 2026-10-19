class_name StitchStyle
extends RoomStyle
## The Sewing Table, GAME.md 8.1c: the table is felt already, so the House has sewn the rest of it
## from felt too. The floor is a spruce felt muted nearly to gray, the House's layout embroidered
## into it in gold and cream thread; every pad is a piece of felt appliqued round it with its edge
## blanket-stitched; the walls are stuffed bolsters of oatmeal felt, a cushion a cell pinched at
## each seam with a plum top-stitch round its top; the boxes are stuffed plum blocks, every seam
## top-stitched in cream and a cream suit appliqued on each face; a pit is a buttonhole cut in
## the felt, its edge rolled in cream satin stitch and pins standing point up in the dark under
## it; the Junction is a quilted roulette, each pocket puffed between its stitched frets, a stuffed
## cord round it and a felt-covered button sewn through its middle; a Jackpot is a patch of plum
## felt with stitched felt chips piled on it. The table round it is a quilted apron with a stuffed
## roll along its edge, and the sewing things lie about it: spools, a pincushion full of pins,
## buttons, a thimble, scissors and a needle.
##
## The light is soft and warm, and every felt wears the soft lit fuzz at its edges that felt has
## under a lamp ([member BaseMaterial3D.rim]), which is this room's shading as much as its color.

const SPRUCE := Color("#3D5552")
const OATMEAL := Color("#D6C8AC")
const OATMEAL_SHADE := Color("#B6A88C")
const PLUM := Color("#4A2A3E")
const CHARCOAL := Color("#2E2C30")
const CREAM := Color("#ECE2CC")
const AUBERGINE := Color("#33252F")
const ROSE := Color("#9C6E70")
const MUSTARD := Color("#C9A23C")
const STEEL := Color("#B9BCC3")
const SPOOL_WOOD := Color("#C49A6C")
## The House's gold, which in here is only ever thread.
const GOLD := Color("#D8AE4A")
const BOLSTER_PRINT := preload("res://assets/textures/stitch_bolster.png")
const BLOCK_PRINT := preload("res://assets/textures/stitch_blocks.png")
const QUILT := preload("res://assets/textures/quilt_albedo.png")
## One cell of the bolster's print, which is what its top-stitch is laid out to.
const CELL := 1.25
## How far the apron's quilting runs before it repeats.
const QUILT_TILE := 7.0
## The felt chips a Jackpot's pile is sewn from, never the coin pads' blue.
const CHIPS: Array[Color] = [PLUM, CREAM, CHARCOAL, MUSTARD]
## The heads of the pins in a pit and in the pincushion.
const PIN_HEADS: Array[Color] = [
	Color("#B4473C"), Color("#ECE2CC"), Color("#C9A23C"), Color("#5E2F4A"), Color("#2E6B6C")
]
## The threads on the spools.
const THREADS: Array[Color] = [GOLD, CREAM, PLUM, ROSE, Color("#4E6E66")]
const SQUARE := RoomBuild.Turned.SQUARE
const FLAT := RoomBuild.Turned.FLAT

var _floor: StandardMaterial3D
var _made: Dictionary[String, StandardMaterial3D] = {}


## A stuffed bolster: a cushion of oatmeal felt a cell long, pinched where it meets the next, with
## the plum top-stitch round its top that the bolster's print lays on, over a plum welt at its
## foot.
func wall(holder: Node3D, size: Vector3, _index: int) -> bool:
	var long_x := size.x >= size.z
	var length := maxf(size.x, size.z)
	var depth := minf(size.x, size.z)
	# The block and the step first, sharing no plane: the core the cushions are stuffed round,
	# which shows in the pinches between them, and the welt along the foot.
	ToyParts.box(
		holder, Vector3(size.x - 0.12, 0.8, size.z - 0.12), _felt(OATMEAL_SHADE), _up(-0.1)
	)
	ToyParts.box(holder, Vector3(size.x - 0.04, 0.08, size.z - 0.04), _felt(PLUM), _up(-0.45))
	var sections := maxi(roundi(length / CELL), 1)
	var run := length / float(sections)
	for i: int in sections:
		var along := -length * 0.5 + run * (float(i) + 0.5)
		var body := Vector3(run - 0.08, 0.95, depth - 0.04)
		if not long_x:
			body = Vector3(depth - 0.04, 0.95, run - 0.08)
		var at := Vector3(along, 0.005, 0.0) if long_x else Vector3(0.0, 0.005, along)
		ToyParts.puffed(holder, body, 0.2, _felt(OATMEAL), at, 8, _bolster_top())
	return true


## A stuffed block of plum felt, its seams top-stitched in cream and a cream suit appliqued on
## each face, one suit to a block.
func crate(holder: Node3D, size: Vector3) -> bool:
	var block := size * 0.86
	var at := Vector3(0.0, -size.y * 0.5 + block.y * 0.5, 0.0)
	var suit := rng.randi_range(0, 3)
	ToyParts.puffed(holder, block, 0.13, _block(suit), at, 8, _block(suit), _felt(PLUM))
	holder.rotation.y = rng.randf_range(-0.05, 0.05)
	return true


## A buttonhole cut in the felt: its edge rolled in cream satin stitch, a bar tack across each
## corner, and sewing pins standing point up in the dark under it.
func pit(into: Node3D, size: Vector2) -> bool:
	var roll := 0.07
	for side: int in 4:
		var along := side % 2 == 0
		var span := (size.x if along else size.y) + roll * 2.0
		var out := ((size.y if along else size.x) * 0.5) * (1.0 if side < 2 else -1.0)
		var at := Vector3(0.0, 0.01 - roll, out) if along else Vector3(out, 0.01 - roll, 0.0)
		var edge := ToyParts.cylinder(into, roll, span, _thread(CREAM), at, 8)
		edge.rotation = Vector3(0.0, 0.0, PI * 0.5) if along else Vector3(PI * 0.5, 0.0, 0.0)
	var rows := maxi(int(size.y / 0.5), 3)
	var columns := maxi(int(size.x / 0.5), 3)
	for row: int in rows:
		for column: int in columns:
			var spot := Vector3(
				(float(column) - float(columns - 1) * 0.5) * size.x / float(columns),
				-Arena.PIT_DEPTH,
				(float(row) - float(rows - 1) * 0.5) * size.y / float(rows)
			)
			spot += Vector3(rng.randf_range(-0.08, 0.08), 0.0, rng.randf_range(-0.08, 0.08))
			var tall := rng.randf_range(0.45, 0.62)
			var head: Color = PIN_HEADS[rng.randi_range(0, PIN_HEADS.size() - 1)]
			ToyParts.ball(into, 0.07, _thread(head), spot + _up(0.07), 8)
			var shaft := ToyParts.taper(
				into, 0.02, 0.0, tall, _steel(), spot + _up(tall * 0.5 + 0.1), 6
			)
			shaft.rotation = Vector3(
				rng.randf_range(-0.12, 0.12), 0.0, rng.randf_range(-0.12, 0.12)
			)
	return true


## A quilted roulette: a plum disc with a stuffed cord round it, a cream ball track with the
## House's gold diamonds stitched on it, plum and charcoal pockets with a spruce zero each puffed
## between frets of cream thread, the middle quilted into wedges, a felt-covered gold button sewn
## through it, and a cream felt ball resting in a pocket.
func junction(into: Node3D, radius: float) -> bool:
	var pad := RoomKit.PAD
	var layer := RoomKit.LAYER
	var face := radius - RoomKit.RIM
	ToyParts.flat(ToyParts.disc(into, face, _felt(PLUM), pad * 0.5, pad, 48))
	ToyParts.ring(into, face - 0.16, face - 0.02, _felt(PLUM), _up(pad + 0.02), 48, 8)
	var track := face - 0.2
	ToyParts.flat(ToyParts.disc(into, track, _felt(CREAM), pad + layer, 0.01, 48))
	for i: int in 8:
		var turn := TAU * (float(i) + 0.5) / 8.0
		var at := Vector3(sin(turn), 0.0, cos(turn)) * (track - 0.13)
		var diamond := ToyParts.box(
			into, Vector3(0.12, 0.012, 0.12), _thread(GOLD), at + _up(pad + layer * 2.0)
		)
		diamond.rotation.y = turn + PI * 0.25
	var outer := track - 0.28
	var inner := radius * 0.52
	var deep := outer - inner
	var pockets := RoomKit.POCKETS
	for i: int in pockets:
		var turn := TAU * float(i) / float(pockets)
		var ink := SPRUCE if i == 0 else (PLUM if i % 2 == 1 else CHARCOAL)
		var middle := Vector3(sin(turn), 0.0, cos(turn)) * (inner + deep * 0.5)
		var wide := TAU * (inner + deep * 0.5) / float(pockets)
		var pocket := ToyParts.box(
			into, Vector3(wide * 1.08, 0.012, deep), _felt(ink), middle + _up(pad + layer * 2.0)
		)
		pocket.rotation.y = turn
		ToyParts.flat(pocket)
		var puff := ToyParts.dome(
			into, wide * 0.42, 0.05, _felt(ink), middle + _up(pad + layer * 2.0), 8
		)
		puff.scale = Vector3(1.0, 0.05 / (wide * 0.42), deep * 0.46 / (wide * 0.42))
		puff.rotation.y = turn
		ToyParts.flat(puff)
		var fret_turn := turn + PI / float(pockets)
		var fret := ToyParts.box(
			into,
			Vector3(0.025, 0.02, deep),
			_thread(CREAM),
			Vector3(sin(fret_turn), 0.0, cos(fret_turn)) * (inner + deep * 0.5) + _up(pad + 0.03)
		)
		fret.rotation.y = fret_turn
	ToyParts.flat(ToyParts.disc(into, inner, _felt(PLUM), pad + layer * 3.0, 0.012, 48))
	for i: int in 8:
		var turn := TAU * (float(i) + 0.5) / 8.0
		var wedge := ToyParts.dome(
			into, inner * 0.3, 0.06, _felt(PLUM if i % 2 == 0 else CHARCOAL), Vector3.ZERO, 8
		)
		wedge.position = Vector3(sin(turn), 0.0, cos(turn)) * inner * 0.55 + _up(pad + layer * 3.0)
		wedge.scale = Vector3(1.0, 0.06 / (inner * 0.3), 1.0)
		ToyParts.flat(wedge)
	for i: int in 4:
		var turn := PI * 0.25 * float(i)
		var seam := ToyParts.box(
			into, Vector3(0.025, 0.02, inner * 2.0 - 0.1), _thread(CREAM), _up(pad + 0.05)
		)
		seam.rotation.y = turn
	_button(into, _up(pad + 0.06), 0.3, _thread(GOLD), 0.04)
	var rest := TAU * float(rng.randi_range(1, pockets - 1)) / float(pockets)
	var ball_at := Vector3(sin(rest), 0.0, cos(rest)) * (inner + deep * 0.5)
	ToyParts.ball(into, 0.12, _felt(CREAM), ball_at + _up(pad + 0.13), 10)
	return true


## A patch of plum felt sewn down on the tile, and stitched felt chips piled on it in leaning
## stacks round its edge, one fallen off, the middle left for the count.
func jackpot(into: Node3D, size: Vector2) -> bool:
	var patch := Vector3(size.x * 0.8, 0.012, size.y * 0.8)
	var lift := 0.088
	ToyParts.flat(ToyParts.box(into, patch, _felt(PLUM), _up(lift)))
	var spots: Array[Vector2] = [
		Vector2(-0.6, -0.6),
		Vector2(0.6, -0.6),
		Vector2(0.6, 0.6),
		Vector2(-0.6, 0.6),
		Vector2(0.0, -0.66),
		Vector2(-0.66, 0.0)
	]
	for k: int in spots.size():
		var at := Vector3(spots[k].x, 0.0, spots[k].y) + _up(lift + 0.006)
		var high := rng.randi_range(2, 5)
		var lean := Vector3(rng.randf_range(-0.02, 0.02), 0.0, rng.randf_range(-0.02, 0.02))
		for chip: int in high:
			var ink: Color = CHIPS[(k + chip) % CHIPS.size()]
			var spot := at + lean * float(chip) + _up(0.035 + 0.07 * float(chip))
			ToyParts.cylinder(into, 0.22, 0.07, _felt(ink), spot, 12)
			ToyParts.ring(into, 0.2, 0.23, _thread(CREAM), spot + _up(0.036), 16, 4)
	var fallen := ToyParts.cylinder(
		into, 0.22, 0.07, _felt(MUSTARD), Vector3(0.62, lift + 0.05, 0.05), 12
	)
	fallen.rotation = Vector3(0.4, 0.0, 0.25)
	return true


## The felt the karts drive on: spruce, with the room's felt in it and its soft edge.
func floor_top() -> StandardMaterial3D:
	if _floor == null:
		_floor = StandardMaterial3D.new()
		_floor.albedo_color = SPRUCE
		_floor.albedo_texture = Surfaces.FELT_ALBEDO
		_floor.normal_enabled = true
		_floor.normal_texture = Surfaces.FELT_NORMAL
		_floor.normal_scale = 0.18
		_floor.uv1_scale = Vector3.ONE / Surfaces.FELT_TILE
		_floor.roughness = 1.0
		_floor.metallic_specular = 0.12
		_floor.rim_enabled = true
		_floor.rim = 0.25
		_floor.rim_tint = 0.6
	return _floor


## The quilted aubergine apron the crowd stands on.
func surround() -> StandardMaterial3D:
	var quilted := StandardMaterial3D.new()
	quilted.albedo_color = AUBERGINE
	quilted.albedo_texture = QUILT
	quilted.uv1_scale = Vector3.ONE / QUILT_TILE
	quilted.roughness = 1.0
	quilted.metallic_specular = 0.12
	quilted.rim_enabled = true
	quilted.rim = 0.3
	quilted.rim_tint = 0.6
	return quilted


## The sewing table: its quilted apron with a stuffed roll along the edge and its legs, a board
## at the back with swatches pinned to it, every pad appliqued, a pincushion at the back corner
## and the rest of the sewing things lying about.
func room_round(props: RoomProps) -> bool:
	var arena := props.arena
	_line_up_stitches(arena)
	_appliques(arena)
	var shell := props.shell
	shell.enclose(Color("#2C211C"), Color("#3A2E2A"), 32.0, 80.0)
	shell.skirt(AUBERGINE.darkened(0.2), 2.4)
	shell.legs(Color("#5A4030"))
	_edge_roll(shell)
	_swatches(shell, shell.backboard(24.0, Color("#4A3E38")))
	var half := arena.world_size() * 0.5
	var cushion := [Rect2(-4.6, -4.6, 9.2, 9.2), FLAT, _pincushion.bind(props)]
	ToyParts.lay(
		props,
		&"pincushion",
		cushion,
		Vector3(-(half.x + 11.0), RoomBuild.TOP, -(half.y + 7.0)),
		true
	)
	var spool := [Rect2(-2.2, -2.2, 4.4, 4.4), SQUARE, _spool.bind(props)]
	var near := {
		&"spool": spool,
		&"buttons": [Rect2(-3.4, -1.3, 6.8, 2.6), SQUARE, _buttons.bind(props)],
		&"thimble": [Rect2(-1.2, -1.2, 2.4, 2.4), FLAT, _thimble.bind(props)],
	}
	var far := {
		&"scissors": [Rect2(-2.6, -5.6, 5.2, 11.2), SQUARE, _scissors.bind(props)],
		&"spool": spool,
	}
	ToyParts.deal_round(props, 18, near, far)
	var apron := {
		&"thread": [Rect2(-2.3, -6.2, 4.6, 12.4), RoomBuild.Turned.ALONG, _lying_spool.bind(props)],
		&"needle": [Rect2(-0.5, -4.6, 1.0, 9.2), RoomBuild.Turned.ALONG, _needle.bind(props)],
	}
	ToyParts.deal_apron(props, 4, apron)
	# The last hook a room asks: let go of its surfaces, which hold this style in turn, or the
	# pair and every material the room made would keep each other for good.
	surfaces = null
	return true


func layout_inks() -> Array[Color]:
	return [GOLD, Color("#E2D6BA")]


## A sewing button with its thread through it, the Sewing Table's emblem.
func emblem() -> Node3D:
	var holder := Node3D.new()
	holder.name = "Button"
	_button(holder, _up(0.06), 0.44, _thread(Color("#6B3A57")), 0.12)
	return holder


# --- the table ---------------------------------------------------------------------


## Lays the bolsters' top-stitch out from the arena's corner, so it falls round every cushion
## whatever size the map is.
func _line_up_stitches(arena: Arena) -> void:
	var half := arena.world_size() * 0.5
	var top := _bolster_top()
	top.uv1_offset = Vector3(fposmod(half.x / CELL, 1.0), 0.0, fposmod(half.y / CELL, 1.0))


## A piece of felt appliqued round every coin pad, a shade up from the floor with its edge
## blanket-stitched in the House's gold, and a deeper ticket of felt under every item pad
## stitched in cream.
func _appliques(arena: Arena) -> void:
	var patches := Node3D.new()
	patches.name = "Appliques"
	arena.add_child(patches)
	for pad: Node3D in arena.coin_pads:
		var disc := ToyParts.disc(patches, 0.72, _felt(SPRUCE.lightened(0.12)), 0.006, 0.012, 24)
		disc.position += pad.position
		ToyParts.flat(disc)
		_blanket(patches, pad.position, 0.72, 20, _thread(GOLD))
	for pad: Node3D in arena.power_pads:
		var ticket := Vector3(1.75, 0.012, 1.75)
		var tile := ToyParts.box(
			patches, ticket, _felt(SPRUCE.darkened(0.3)), pad.position + _up(0.006)
		)
		ToyParts.flat(tile)
		for side: int in 4:
			var along := side % 2 == 0
			var out := 0.86 * (1.0 if side < 2 else -1.0)
			for k: int in 9:
				var t := (float(k) + 0.5) / 9.0 * 1.6 - 0.8
				var at := Vector3(t, 0.014, out) if along else Vector3(out, 0.014, t)
				var tick := Vector3(0.025, 0.008, 0.1) if along else Vector3(0.1, 0.008, 0.025)
				ToyParts.flat(ToyParts.box(patches, tick, _thread(CREAM), pad.position + at))
	if arena.bake_scenery:
		Bake.merge(patches)


## Blanket stitch round a disc at [param at] out to [param radius]: a short stitch over its edge
## every so often, square to it.
func _blanket(into: Node3D, at: Vector3, radius: float, count: int, thread: Material) -> void:
	for k: int in count:
		var turn := TAU * float(k) / float(count)
		var tick := ToyParts.box(
			into,
			Vector3(0.025, 0.008, 0.1),
			thread,
			at + Vector3(sin(turn), 0.0, cos(turn)) * (radius - 0.03) + _up(0.014)
		)
		tick.rotation.y = turn
		ToyParts.flat(tick)


## The stuffed roll along the edge of the apron, all the way round.
func _edge_roll(shell: RoomShell) -> void:
	var half := shell._table()
	var radius := 1.0
	for side: int in 4:
		var along := side % 2 == 0
		var out := ((half.y if along else half.x) - radius) * (1.0 if side < 2 else -1.0)
		var run := (half.x if along else half.y) * 2.0
		var at := Vector3(0.0, RoomBuild.TOP + radius * 0.6, out)
		if not along:
			at = Vector3(out, RoomBuild.TOP + radius * 0.6, 0.0)
		var tube := ToyParts.cylinder(shell, radius, run, _felt(AUBERGINE), at, 10)
		tube.rotation = Vector3(0.0, 0.0, PI * 0.5) if along else Vector3(PI * 0.5, 0.0, 0.0)
		ToyParts.flat(tube)
		var keep_from := (
			at - (Vector3(run * 0.5, 0.0, 0.0) if along else Vector3(0.0, 0.0, run * 0.5))
		)
		var keep_to := (
			at + (Vector3(run * 0.5, 0.0, 0.0) if along else Vector3(0.0, 0.0, run * 0.5))
		)
		shell._keep(keep_from, keep_to, radius * 2.4)


## Swatches of the room's felts pinned to the board at the back, at head height, each a little
## askew with a pin through its corner.
func _swatches(shell: RoomShell, face: float) -> void:
	var half := shell._table()
	var inks: Array[Color] = [OATMEAL_SHADE, SPRUCE, ROSE, CHARCOAL, PLUM]
	var count := inks.size()
	for i: int in count:
		var x := -half.x * 0.6 + float(i) * half.x * 1.2 / float(count - 1)
		var at := Vector3(x, RoomBuild.TOP + 5.5 + float(i % 2) * 1.6, face + 0.25)
		var swatch := ToyParts.box(shell, Vector3(5.5, 4.2, 0.3), _felt(inks[i]), at)
		swatch.rotation.z = rng.randf_range(-0.12, 0.12)
		ToyParts.flat(swatch)
		var head: Color = PIN_HEADS[i % PIN_HEADS.size()]
		var pin_at := at + Vector3(-1.8, 1.4, 0.4)
		ToyParts.flat(ToyParts.ball(shell, 0.3, _thread(head), pin_at, 8))


# --- the sewing things ---------------------------------------------------------------


## A tomato pincushion of plum felt, its segments stitched, a green cap on it and pins stuck in it.
func _pincushion(at: Vector3, _turn: float, props: RoomProps) -> void:
	var cushion := ToyParts.ball(props, 4.0, _felt(PLUM), at + _up(2.2), 16)
	cushion.scale = Vector3(1.0, 0.6, 1.0)
	# Its segments, a stitched seam down each from the cap, squashed as the cushion is.
	var squash := Basis.from_scale(Vector3(1.0, 0.6, 1.0))
	for k: int in 6:
		var seam := ToyParts.ring(props, 3.96, 4.1, _thread(CREAM), at + _up(2.2), 32, 4)
		var upright := Basis(Vector3.UP, PI / 6.0 * float(k)) * Basis(Vector3.RIGHT, PI * 0.5)
		seam.basis = squash * upright
	ToyParts.cylinder(props, 0.9, 0.5, _felt(Color("#4E6E66")), at + _up(4.65), 10)
	for k: int in 10:
		var turn := TAU * float(k) / 10.0 + props._rng.randf_range(-0.2, 0.2)
		var reach := props._rng.randf_range(1.2, 3.0)
		var root := (
			at
			+ Vector3(sin(turn), 0.0, cos(turn)) * reach
			+ _up(2.2 + 2.4 * sqrt(1.0 - pow(reach / 4.0, 2.0)) * 0.95)
		)
		var lean := Vector3(sin(turn), 2.0, cos(turn)).normalized()
		var tip := root + lean * 1.4
		var shaft := ToyParts.cylinder(props, 0.06, 1.4, _steel(), (root + tip) * 0.5, 6)
		shaft.basis = Basis(Quaternion(Vector3.UP, lean))
		ToyParts.ball(props, 0.28, _thread(PIN_HEADS[k % PIN_HEADS.size()]), tip, 8)


## A spool of thread standing on end: wooden flanges and the thread wound between them.
func _spool(at: Vector3, _turn: float, props: RoomProps) -> void:
	var wood := _satin(SPOOL_WOOD)
	ToyParts.cylinder(props, 2.0, 0.4, wood, at + _up(0.2), 16)
	ToyParts.cylinder(props, 2.0, 0.4, wood, at + _up(3.8), 16)
	var thread: Color = THREADS[props._rng.randi_range(0, THREADS.size() - 1)]
	ToyParts.cylinder(props, 1.65, 3.2, _thread(thread), at + _up(2.0), 16)
	ToyParts.cylinder(props, 0.45, 0.05, _satin(SPOOL_WOOD.darkened(0.5)), at + _up(4.02), 10)


## A small spool lying on its side along the front of the table, low enough for the near side,
## its thread run out along it.
func _lying_spool(at: Vector3, turn: float, props: RoomProps) -> void:
	var along := Vector3(sin(turn), 0.0, cos(turn))
	var across := Vector3(cos(turn), 0.0, -sin(turn))
	var lying := Basis(Quaternion(Vector3.UP, along))
	var wood := _satin(SPOOL_WOOD)
	var spool_at := _local(at, turn, 0.0, 1.25, -3.6)
	for end: float in [-1.1, 1.1]:
		var flange := ToyParts.cylinder(props, 1.25, 0.3, wood, spool_at + along * end, 16)
		flange.basis = lying
	var thread: Color = THREADS[props._rng.randi_range(0, THREADS.size() - 1)]
	var core := ToyParts.cylinder(props, 1.0, 2.0, _thread(thread), spool_at, 16)
	core.basis = lying
	var run_at := _local(at, turn, 0.6, 0.07, 1.8)
	var run := ToyParts.cylinder(props, 0.07, 8.0, _thread(thread), run_at, 6)
	run.basis = Basis(Quaternion(Vector3.UP, (along + across * 0.12).normalized()))


## A stack or three of spare buttons, charcoal and plum, squared off side by side.
func _buttons(at: Vector3, turn: float, props: RoomProps) -> void:
	for stack: int in 3:
		var foot := _local(at, turn, (float(stack) - 1.0) * 2.3, 0.0, 0.0)
		var ink := CHARCOAL if stack % 2 == 0 else Color("#6B3A57")
		var high := props._rng.randi_range(1, 4)
		for i: int in high:
			_button(props, foot + _up(0.15 + 0.3 * float(i)), 1.0, _satin(ink), 0.3, i == high - 1)


## A steel thimble, standing open end down.
func _thimble(at: Vector3, _turn: float, props: RoomProps) -> void:
	ToyParts.taper(props, 0.95, 0.8, 1.8, _steel(), at + _up(0.9), 16)
	ToyParts.dome(props, 0.8, 0.35, _steel(), at + _up(1.8), 16)
	ToyParts.cylinder(props, 1.0, 0.18, _steel(), at + _up(0.09), 16)


## A pair of scissors lying open: two steel blades crossed at the screw, plum handles.
func _scissors(at: Vector3, turn: float, props: RoomProps) -> void:
	for side: float in [-1.0, 1.0]:
		var blade := ToyParts.box(
			props, Vector3(0.5, 0.25, 6.5), _steel(), _local(at, turn, side * 0.55, 0.3, -1.6)
		)
		blade.rotation.y = turn + side * 0.16
		var ring := ToyParts.ring(
			props,
			0.9,
			1.35,
			_satin(Color("#6B3A57")),
			_local(at, turn, side * 1.25, 0.3, 3.6),
			16,
			6
		)
		ring.rotation.y = turn
	ToyParts.cylinder(props, 0.3, 0.6, _steel(), _local(at, turn, 0.0, 0.3, 1.5), 8)


## A needle lying along the front of the table, its eye toward the light.
func _needle(at: Vector3, turn: float, props: RoomProps) -> void:
	var along := Vector3(sin(turn), 0.0, cos(turn))
	var shaft := ToyParts.taper(props, 0.14, 0.02, 8.6, _steel(), at + _up(0.14), 8)
	shaft.basis = Basis(Quaternion(Vector3.UP, along))
	ToyParts.ring(props, 0.12, 0.2, _steel(), at - along * 4.1 + _up(0.14), 12, 6)


## A sewing button [param radius] across: a disc with a rolled rim, four holes and a cross of
## cream thread through them.
func _button(
	into: Node3D, at: Vector3, radius: float, skin: Material, thick: float, threaded := true
) -> void:
	ToyParts.cylinder(into, radius, thick, skin, at, 24)
	ToyParts.ring(into, radius * 0.78, radius, skin, at + _up(thick * 0.5), 24, 6)
	var hole := radius * 0.13
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var spot := Vector3(corner.x, 0.0, corner.y) * radius * 0.22
		ToyParts.cylinder(into, hole, thick * 1.05, _felt(CHARCOAL.darkened(0.4)), at + spot, 8)
	if not threaded:
		return
	for k: int in 2:
		var stitch := ToyParts.box(
			into,
			Vector3(radius * 0.09, thick * 0.3, radius * 0.75),
			_thread(CREAM),
			at + _up(thick * 0.55)
		)
		stitch.rotation.y = PI * 0.25 + PI * 0.5 * float(k)


func _local(at: Vector3, turn: float, x: float, y: float, z: float) -> Vector3:
	var across := Vector3(cos(turn), 0.0, -sin(turn))
	var along := Vector3(sin(turn), 0.0, cos(turn))
	return at + across * x + along * z + Vector3(0.0, y, 0.0)


func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)


# --- the materials ---------------------------------------------------------------


## Felt: matte, its fibers in it, and the soft lit edge felt has under a lamp.
func _felt(color: Color) -> StandardMaterial3D:
	var key := "felt" + color.to_html(false)
	if not _made.has(key):
		var felt := StandardMaterial3D.new()
		felt.albedo_color = color
		felt.albedo_texture = Surfaces.FELT_ALBEDO
		felt.uv1_triplanar = true
		felt.uv1_world_triplanar = true
		felt.uv1_scale = Vector3.ONE / Surfaces.FELT_TILE
		_soft(felt)
		_made[key] = felt
	return _made[key]


## The top of a bolster, its top-stitch printed on in the world's meters, a cell to a tile.
func _bolster_top() -> StandardMaterial3D:
	if not _made.has("bolster"):
		var top := StandardMaterial3D.new()
		top.albedo_texture = BOLSTER_PRINT
		top.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		top.uv1_triplanar = true
		top.uv1_world_triplanar = true
		top.uv1_scale = Vector3.ONE / CELL
		_soft(top)
		_made["bolster"] = top
	return _made["bolster"]


## A stuffed block's faces in [param suit]: one quarter of the blocks' print.
func _block(suit: int) -> StandardMaterial3D:
	var key := "block%d" % suit
	if not _made.has(key):
		var faces := StandardMaterial3D.new()
		faces.albedo_color = Color(0.78, 0.74, 0.78)
		faces.albedo_texture = BLOCK_PRINT
		faces.uv1_scale = Vector3(0.5, 0.5, 1.0)
		faces.uv1_offset = Vector3(0.5 * float(suit % 2), 0.5 * float(suit / 2), 0.0)
		_soft(faces)
		_made[key] = faces
	return _made[key]


func _soft(felt: StandardMaterial3D) -> void:
	felt.roughness = 1.0
	felt.metallic_specular = 0.12
	felt.rim_enabled = true
	felt.rim = 0.32
	felt.rim_tint = 0.45


## Thread: a sheen along it that felt does not have.
func _thread(color: Color) -> StandardMaterial3D:
	var key := "thread" + color.to_html(false)
	if not _made.has(key):
		var thread := StandardMaterial3D.new()
		thread.albedo_color = color
		thread.roughness = 0.55
		thread.metallic_specular = 0.45
		_made[key] = thread
	return _made[key]


## The wood of a spool and the plastic of a button: satin.
func _satin(color: Color) -> StandardMaterial3D:
	var key := "satin" + color.to_html(false)
	if not _made.has(key):
		var satin := StandardMaterial3D.new()
		satin.albedo_color = color
		satin.roughness = 0.45
		satin.metallic_specular = 0.5
		_made[key] = satin
	return _made[key]


## A pin's steel and the thimble's: light, since a room this soft has little for a metal to show.
func _steel() -> StandardMaterial3D:
	if not _made.has("steel"):
		var steel := StandardMaterial3D.new()
		steel.albedo_color = STEEL
		steel.metallic = 0.4
		steel.roughness = 0.3
		steel.metallic_specular = 0.7
		_made["steel"] = steel
	return _made["steel"]
