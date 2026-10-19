class_name PinballStyle
extends RoomStyle
## The Arcade, GAME.md 8.1c: the table is a pinball playfield the House printed, kept the way a
## careful restorer keeps a machine of the sixties rather than the way a new one shouts. The
## floor is the playfield under a satin coat, its art in plum, teal, ochre and cream with the
## House's layout laid over it ([PinballPrints]); every pad is set in a plastic insert lit from
## below; the inner walls are guides, a lacquered block in a ring of rubber round chrome posts
## with a printed plastic held over it on ochre spacers and a bulb or two glowing under its edge;
## the boxes are drop targets, ivory blocks with an ace on each face standing in a steel slot;
## the pits are drains, a steel-lined hole with a ball waiting in it; the Junction is a roulette
## insert ringed with chase lamps and a pop bumper's cap on its spindle; a Jackpot is a pile of
## chips under a clear dome on a lit pan; and the machine's head stands behind the far crowd,
## its backglass lit. The House's rail is still the outer wall, as on every table.
##
## The lamps are kept in hand, which is what makes it a restored machine rather than a busy one:
## half of the chase lamps are dark, the inserts glow rather than blaze, and nothing on the floor
## is brighter than a kart or a shot.

const WALNUT := Color("#4E2E20")
const CABINET := Color("#2A1E2C")
const STEEL := Color("#AEB2BA")
const DARK_STEEL := Color("#4F535B")
const RUBBER := Color("#E6DCC4")
const RED_RUBBER := Color("#A83A2C")
const PLASTIC := Color("#E6D9B8")
const PANEL := Color("#2B5A5C")
const OCHRE := Color("#C4943F")
const LACQUER := Color("#4A2B22")
const IVORY := Color("#EEE5D0")
const INK := Color("#141017")
const PLUM := Color("#4A2F50")
## The lamps: an insert round a coin pad, round an item pad, the bulbs under the plastics and the
## chase lamps round the wheel.
const COIN_LAMP := Color("#4F86D6")
const ITEM_LAMP := Color("#F2C77A")
const BULB := Color("#FFD9A0")
const POCKET_RED := Color("#6C2E2B")
const POCKET_GREEN := Color("#2C6449")
## How far a guide's lacquered block stands in from its rubber, and where the rubber runs.
const RUBBER_IN := 0.07
const RUBBER_TALL := 0.14
## The chips a Jackpot's pile is stacked from, never the coin pads' blue.
const PILE: Array[Color] = [
	Color("#B4473C"), Color("#E9DFC8"), Color("#C4943F"), Color("#5B3A63"), Color("#2E6B6C")
]
## The clutter round the table, at the size a pinball's spares are beside a model this big.
const BALL := 0.7
const SQUARE := RoomBuild.Turned.SQUARE
const FLAT := RoomBuild.Turned.FLAT

var _floor: StandardMaterial3D
var _made: Dictionary[String, StandardMaterial3D] = {}


func wall(holder: Node3D, size: Vector3, index: int) -> bool:
	var foot := -size.y * 0.5
	var top := size.y * 0.5
	var long_x := size.x >= size.z
	var length := maxf(size.x, size.z)
	var depth := minf(size.x, size.z)
	var plastic_y := top - 0.06
	# The block first and the plastic second, which share no plane, as every room's block and step.
	var under := plastic_y - 0.05
	var body := Vector3(size.x - RUBBER_IN * 2.0, under - foot, size.z - RUBBER_IN * 2.0)
	ToyParts.box(holder, body, _satin(LACQUER), Vector3(0.0, (foot + under) * 0.5, 0.0))
	var plastic := Vector3(size.x - 0.04, 0.035, size.z - 0.04)
	ToyParts.box(holder, plastic, _satin(PLASTIC, 0.3), Vector3(0.0, plastic_y, 0.0))
	ToyParts.box(
		holder,
		Vector3(size.x - 0.012, 0.014, size.z - 0.012),
		_satin(INK),
		Vector3(0.0, plastic_y - 0.024, 0.0)
	)
	var panel := Vector3(size.x - 0.34, 0.01, size.z - 0.34)
	var face := plastic_y + plastic.y * 0.5
	ToyParts.box(holder, panel, _satin(PANEL, 0.3), Vector3(0.0, face + 0.005, 0.0))
	# The ring of rubber round the posts at the height a shot strikes it.
	ToyParts.rounded(
		holder,
		Vector3(size.x, RUBBER_TALL, size.z),
		0.1,
		_rubber(RUBBER),
		Vector3(0.0, foot + 0.38, 0.0)
	)
	# A chrome post at each corner, standing half out of the block, with a red ring round it
	# over the rubber, an ochre spacer under the plastic and a chrome nut over it.
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var at := Vector3((size.x * 0.5 - 0.075) * corner.x, 0.0, (size.z * 0.5 - 0.075) * corner.y)
		var post_top := plastic_y - 0.04
		var post_at := at + Vector3(0.0, (post_top + foot) * 0.5, 0.0)
		ToyParts.cylinder(holder, 0.06, post_top - foot, _steel(), post_at, 8)
		ToyParts.ring(holder, 0.05, 0.075, _rubber(RED_RUBBER), at + _up(foot + 0.62), 12)
		ToyParts.cylinder(holder, 0.07, 0.025, _satin(OCHRE), at + _up(plastic_y - 0.03), 8)
		ToyParts.cylinder(holder, 0.04, 0.03, _steel(), at + _up(face + 0.02), 8)
	# A bulb under the plastic's edge every cell along the long sides, peeking out.
	var cells := maxi(int(length / 1.25), 1)
	for i: int in cells:
		var a := (float(i) + 0.5) * length / float(cells) - length * 0.5
		for side: float in [-1.0, 1.0]:
			var b := side * (depth * 0.5 - 0.045)
			var at := Vector3(a, plastic_y - 0.06, b) if long_x else Vector3(b, plastic_y - 0.06, a)
			ToyParts.flat(ToyParts.ball(holder, 0.035, _lamp(BULB, 0.9), at, 6))
	# Ochre diamonds printed down the plastic of the long guides, one a cell.
	if index % 2 == 0 and length > 2.0 and depth > 0.8:
		for i: int in cells:
			var a := (float(i) + 0.5) * length / float(cells) - length * 0.5
			var at := Vector3(a, face + 0.012, 0.0) if long_x else Vector3(0.0, face + 0.012, a)
			var mark := ToyParts.box(holder, Vector3(0.16, 0.008, 0.16), _satin(OCHRE, 0.3), at)
			mark.rotation.y = PI * 0.25
	return true


## A drop target: an ivory block with an ace on each face, standing in its steel slot.
func crate(holder: Node3D, size: Vector3) -> bool:
	var foot := -size.y * 0.5
	var slot := Vector3(size.x * 0.98, size.y * 0.12, size.z * 0.98)
	ToyParts.box(holder, slot, _satin(DARK_STEEL, 0.4), Vector3(0.0, foot + slot.y * 0.5, 0.0))
	var block := Vector3(size.x * 0.84, size.y * 0.84, size.z * 0.84)
	ToyParts.rounded(
		holder, block, 0.06, _satin(IVORY), Vector3(0.0, foot + slot.y + block.y * 0.5 - 0.01, 0.0)
	)
	var suits := Surfaces.CARD_FACES
	var ace := surfaces.printed(suits[rng.randi_range(0, suits.size() - 1)])
	var card := QuadMesh.new()
	card.size = Vector2(block.x * 0.6, block.y * 0.78)
	var middle := foot + slot.y + block.y * 0.5
	for side: int in 4:
		var turn := PI * 0.5 * float(side)
		var out := Vector3(sin(turn), 0.0, cos(turn)) * (block.x * 0.5 + 0.004)
		var face := ToyParts.put(holder, card, ace, out + Vector3(0.0, middle, 0.0))
		face.rotation.y = turn
	holder.rotation.y = rng.randf_range(-0.03, 0.03)
	return true


## A drain: a steel lip round the hole, steel down its sides and a ball waiting at the bottom.
func pit(into: Node3D, size: Vector2) -> bool:
	var lip := 0.16
	for side: int in 4:
		var along := side % 2 == 0
		var out := ((size.y if along else size.x) * 0.5 + lip * 0.5) * (1.0 if side < 2 else -1.0)
		var run := Vector3(size.x + lip * 2.0, 0.012, lip) if along else Vector3(lip, 0.012, size.y)
		var at := Vector3(0.0, 0.007, out) if along else Vector3(out, 0.007, 0.0)
		ToyParts.flat(ToyParts.box(into, run, _steel(), at))
		var deep := Arena.PIT_DEPTH * 0.8
		var inside := ((size.y if along else size.x) * 0.5 - 0.03) * (1.0 if side < 2 else -1.0)
		var plate := (
			Vector3(size.x - 0.06, deep, 0.03) if along else Vector3(0.03, deep, size.y - 0.06)
		)
		var down := -0.03 - deep * 0.5
		var plate_at := Vector3(0.0, down, inside) if along else Vector3(inside, down, 0.0)
		ToyParts.box(into, plate, _satin(DARK_STEEL, 0.35), plate_at)
	var radius := minf(size.x, size.y) * 0.17
	var rest := Vector3(
		rng.randf_range(-0.2, 0.2) * size.x,
		-Arena.PIT_DEPTH + radius,
		rng.randf_range(-0.2, 0.2) * size.y
	)
	ToyParts.ball(into, radius, _chrome(), rest, 16)
	return true


## The Junction as a roulette insert let into the playfield: a walnut rim with chase lamps round
## it, half of them lit, muted pockets, a cream ball track, a plum turntable with ochre spokes and
## the red cap of a pop bumper on its spindle. All of it flat, for the karts to bank on.
func junction(into: Node3D, radius: float) -> bool:
	var pad := RoomKit.PAD
	var layer := RoomKit.LAYER
	var face := radius - RoomKit.RIM
	ToyParts.flat(ToyParts.disc(into, face, _satin(WALNUT, 0.4), pad * 0.5, pad, 48))
	var lamps := 24
	for i: int in lamps:
		var turn := TAU * (float(i) + 0.5) / float(lamps)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * (face - 0.13)
		var lit := _lamp(BULB, 1.1) if i % 2 == 0 else _satin(Color("#6B5A44"), 0.3)
		ToyParts.flat(ToyParts.cylinder(into, 0.07, 0.01, lit, at + _up(pad + layer), 8))
	var outer := face - 0.26
	var inner := radius * 0.5
	var deep := outer - inner
	var pockets := RoomKit.POCKETS
	for i: int in pockets:
		var turn := TAU * float(i) / float(pockets)
		var ink := (
			_satin(POCKET_GREEN, 0.4) if i == 0 else _satin(POCKET_RED if i % 2 == 1 else INK, 0.4)
		)
		var lift := pad + layer + (layer * 0.25 if i % 2 == 1 else 0.0)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * (inner + deep * 0.5)
		var wide := TAU * (inner + deep * 0.5) / float(pockets) * 1.12
		var pocket := ToyParts.box(into, Vector3(wide, 0.01, deep), ink, at + _up(lift))
		pocket.rotation.y = turn
		ToyParts.flat(pocket)
	ToyParts.flat(ToyParts.disc(into, inner, _lamp(PLASTIC, 0.25), pad + layer * 2.0, 0.01, 48))
	ToyParts.flat(ToyParts.disc(into, inner - 0.12, _satin(PLUM, 0.4), pad + layer * 3.0, 0.01, 48))
	for i: int in 4:
		var spoke := ToyParts.box(
			into,
			Vector3(0.08, 0.01, (inner - 0.16) * 2.0),
			_satin(OCHRE, 0.3),
			_up(pad + layer * 4.0)
		)
		spoke.rotation.y = PI * 0.25 + PI * 0.5 * float(i)
		ToyParts.flat(spoke)
	ToyParts.flat(ToyParts.disc(into, 0.32, _steel(), pad + layer * 5.0, 0.02, 24))
	ToyParts.flat(ToyParts.disc(into, 0.22, _lamp(Color("#D2483A"), 0.7), pad + 0.04, 0.05, 16))
	return true


## A pile of chips under a clear dome on a lit amber pan, the chips round its edge so the count
## painted in the middle of the tile still shows through the glass.
func jackpot(into: Node3D, size: Vector2) -> bool:
	var reach := minf(size.x, size.y) * 0.42
	var pan := 0.085
	ToyParts.flat(ToyParts.disc(into, reach, _lamp(Color("#E0A040"), 0.45), pan, 0.01, 32))
	ToyParts.flat(ToyParts.ring(into, reach - 0.04, reach + 0.03, _steel(), _up(pan + 0.01), 32))
	var stacks := 7
	for i: int in stacks:
		var turn := TAU * (float(i) + rng.randf_range(-0.15, 0.15)) / float(stacks)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * reach * 0.66 + _up(pan + 0.005)
		var high := rng.randi_range(2, 5)
		for chip: int in high:
			var ink: Color = PILE[(i + chip) % PILE.size()]
			var piece := ToyParts.cylinder(
				into,
				0.17,
				0.045,
				surfaces.printed(Surfaces.CHIP_FACE, ink),
				at + _up(0.0225 + 0.045 * float(chip)),
				12
			)
			piece.position.x += rng.randf_range(-0.015, 0.015)
	var glass := ToyParts.dome(into, reach + 0.02, 0.36, _glass(), _up(pan + 0.005), 24)
	ToyParts.flat(glass)
	return true


func floor_top() -> StandardMaterial3D:
	if _floor == null:
		_floor = StandardMaterial3D.new()
		_floor.albedo_color = PinballPrints.GROUND
		_floor.roughness = 0.4
		_floor.metallic_specular = 0.55
		_floor.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		# The coat over the print, on the renderer that can afford one; satin either way.
		if Settings.full_renderer():
			_floor.clearcoat_enabled = true
			_floor.clearcoat = 0.3
			_floor.clearcoat_roughness = 0.4
	return _floor


## The cabinet the playfield is set in, where the crowd stands: painted the dark plum of a
## machine's cabinet under a satin varnish, the grain of the wood just showing through it.
func surround() -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = CABINET
	paint.albedo_texture = Surfaces.WOOD_ALBEDO
	paint.normal_enabled = true
	paint.normal_texture = Surfaces.WOOD_NORMAL
	paint.normal_scale = 0.2
	paint.uv1_scale = Vector3.ONE / Surfaces.WOOD_TILE
	paint.roughness = 0.5
	paint.metallic_specular = 0.45
	return paint


## The arcade the machine stands in, dark past the table: the playfield's art drawn from the map,
## its inserts set round the pads, the cabinet's edge and its chrome legs, the machine's head
## behind the far crowd with its backglass lit, and a pinball's spares laid out round the table.
func room_round(props: RoomProps) -> bool:
	var arena := props.arena
	_print_field(arena)
	_inserts(arena)
	var shell := props.shell
	shell.enclose(Color("#0E0A10"), Color("#1A1220"), 32.0, 80.0)
	shell.skirt(WALNUT.darkened(0.25), 2.4)
	shell.legs(Color("#8E929A"))
	var half := arena.world_size() * 0.5
	var back := -(half.y + RoomBuild.BACK_FAR + RoomBuild.BACK_WALL)
	_backbox(shell, arena, Vector3(0.0, RoomBuild.TOP, back))
	_side_rails(shell)
	var balls := [Rect2(-2.5, -1.0, 5.0, 2.0), SQUARE, _balls.bind(props)]
	var rubbers := [Rect2(-1.6, -1.6, 3.2, 3.2), FLAT, _rubbers.bind(props)]
	var near := {
		&"balls": balls,
		&"rubbers": rubbers,
		&"bulbs": [Rect2(-2.5, -1.0, 5.0, 2.0), SQUARE, _bulbs.bind(props)],
		&"quarters": [Rect2(-2.1, -0.8, 4.2, 1.6), SQUARE, _quarters.bind(props)],
	}
	var far := {
		&"flipper": [Rect2(-1.0, -2.4, 2.0, 4.8), SQUARE, _flipper.bind(props)],
		&"targets": [Rect2(-2.8, -1.0, 5.6, 2.0), SQUARE, _targets.bind(props)],
		&"balls": balls,
	}
	ToyParts.deal_round(props, 18, near, far)
	var card := [Rect2(-3.2, -2.0, 6.4, 4.0), RoomBuild.Turned.ALONG, _card.bind(props)]
	ToyParts.deal_apron(props, 4, {&"card": card, &"rubbers": rubbers})
	return true


func layout_inks() -> Array[Color]:
	return [Color("#C79A45"), Color("#E3D5B2")]


## A steel pinball, the Arcade's emblem.
func emblem() -> Node3D:
	var holder := Node3D.new()
	holder.name = "Pinball"
	ToyParts.ball(holder, 0.3, _chrome(), Vector3(0.0, 0.26, 0.0), 24)
	ToyParts.ring(holder, 0.2, 0.34, _rubber(RED_RUBBER), Vector3(0.0, 0.04, 0.0), 24, 8)
	return holder


# --- the playfield ---------------------------------------------------------------


## Draws the playfield's art for this map and lays it on the floor, corner to corner over the
## arena as the layout is, once it has been drawn.
func _print_field(arena: Arena) -> void:
	var across := arena.world_size()
	var field := floor_top()
	field.uv1_scale = Vector3(1.0 / across.x, 1.0 / across.y, 1.0)
	field.uv1_offset = Vector3(0.5, 0.5, 0.0)
	DrawnTexture.kept(
		arena,
		PinballPrints.field(arena.grid),
		PinballPrints.field_pixels(arena.grid),
		func(texture: Texture2D) -> void:
			field.albedo_color = Color.WHITE
			field.albedo_texture = texture
	)


## A plastic insert under every coin pad and item pad, lit from below: the coin's blue and the
## item's warm white, flush with the coat and a little wider than the pad's rim.
func _inserts(arena: Arena) -> void:
	var inserts := Node3D.new()
	inserts.name = "Inserts"
	arena.add_child(inserts)
	for pad: Node3D in arena.coin_pads:
		var disc := ToyParts.disc(inserts, 0.66, _lamp(COIN_LAMP, 0.55), 0.006, 0.01, 24)
		disc.position += pad.position
		ToyParts.flat(disc)
	for pad: Node3D in arena.power_pads:
		var disc := ToyParts.disc(inserts, 0.86, _lamp(ITEM_LAMP, 0.45), 0.006, 0.01, 24)
		disc.position += pad.position
		ToyParts.flat(disc)
	if arena.bake_scenery:
		Bake.merge(inserts)


# --- the room round the table ---------------------------------------------------------


## The machine's head: a walnut box standing on the table behind the far crowd, chrome round its
## glass and the backglass lit from behind. Part of the room rather than its clutter, as the
## Workbench's board is, so what is dealt round the table keeps off its patch.
func _backbox(shell: RoomShell, arena: Arena, at: Vector3) -> void:
	var wide := 40.0
	var tall := 25.0
	var deep := 4.0
	shell._keep(at - Vector3(wide * 0.5, 0.0, 0.0), at + Vector3(wide * 0.5, 0.0, 0.0), deep + 2.0)
	var walnut := _satin(WALNUT, 0.45)
	_dim(ToyParts.box(shell, Vector3(wide, tall, deep), walnut, at + _up(tall * 0.5)))
	var glass_at := at + Vector3(0.0, tall * 0.56, deep * 0.5 + 0.05)
	var glass := Vector2(wide - 6.0, (wide - 6.0) * 9.0 / 16.0)
	for side: float in [-1.0, 1.0]:
		var across := Vector3(0.0, side * (glass.y * 0.5 + 0.4), 0.0)
		_dim(ToyParts.box(shell, Vector3(glass.x + 1.6, 0.8, 0.5), _steel(), glass_at + across))
		var down := Vector3(side * (glass.x * 0.5 + 0.4), 0.0, 0.0)
		_dim(ToyParts.box(shell, Vector3(0.8, glass.y, 0.5), _steel(), glass_at + down))
	var cap := Vector3(wide + 0.6, 0.9, deep + 0.6)
	_dim(ToyParts.box(shell, cap, _satin(OCHRE, 0.4), at + _up(tall)))
	# Lit from behind: the picture as it is, whatever light the room has on it.
	var lit := StandardMaterial3D.new()
	lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lit.albedo_color = Color(0.1, 0.07, 0.11)
	var pane := QuadMesh.new()
	pane.size = glass
	_dim(ToyParts.put(shell, pane, lit, glass_at))
	DrawnTexture.kept(
		arena,
		PinballPrints.glass(),
		PinballPrints.GLASS_PIXELS,
		func(texture: Texture2D) -> void:
			lit.albedo_color = Color(0.85, 0.85, 0.85)
			lit.albedo_texture = texture
	)


## The chrome strip down the cabinet's side rails, along the top of the table's edge all round.
func _side_rails(shell: RoomShell) -> void:
	var half := shell._table()
	for side: int in 4:
		var along := side % 2 == 0
		var out := (half.y if along else half.x) * (1.0 if side < 2 else -1.0)
		var run := (
			Vector3(half.x * 2.0 + 0.4, 0.5, 0.4) if along else Vector3(0.4, 0.5, half.y * 2.0)
		)
		var at := (
			Vector3(0.0, RoomBuild.TOP - 0.4, out)
			if along
			else Vector3(out, RoomBuild.TOP - 0.4, 0.0)
		)
		_dim(ToyParts.box(shell, run, _steel(), at))


func _dim(node: MeshInstance3D) -> MeshInstance3D:
	return ToyParts.flat(node)


## Three spare balls on a little walnut rail, in a row.
func _balls(at: Vector3, turn: float, props: RoomProps) -> void:
	_turned(
		ToyParts.box(
			props, Vector3(4.8, 0.3, 1.8), _satin(WALNUT, 0.45), _local(at, turn, 0.0, 0.15, 0.0)
		),
		turn
	)
	for i: int in 3:
		var spot := _local(at, turn, (float(i) - 1.0) * 1.55, 0.3 + BALL, 0.0)
		ToyParts.ball(props, BALL, _chrome(), spot, 16)


## A stack of spare rubber rings, cream, red and black, each a little off the one under it.
func _rubbers(at: Vector3, _turn: float, props: RoomProps) -> void:
	var inks: Array[Color] = [RUBBER, RED_RUBBER, Color("#1D1A1E"), RUBBER]
	var count := props._rng.randi_range(2, 4)
	for i: int in count:
		var spot := at + Vector3(props._rng.randf_range(-0.12, 0.12), 0.18 + 0.3 * float(i), 0.0)
		ToyParts.ring(props, 0.85, 1.35, _rubber(inks[i]), spot, 24, 6)


## A row of spare bulbs lying on their sides, glass and brass.
func _bulbs(at: Vector3, turn: float, props: RoomProps) -> void:
	var glass := _satin(Color("#F1E9D6"), 0.25)
	var brass := _satin(OCHRE, 0.35)
	for i: int in 4:
		var x := (float(i) - 1.5) * 1.2
		var bulb := ToyParts.ball(props, 0.42, glass, _local(at, turn, x, 0.42, 0.3), 12)
		bulb.scale = Vector3(1.0, 1.0, 1.25)
		bulb.rotation.y = turn
		var base := ToyParts.cylinder(props, 0.3, 0.6, brass, _local(at, turn, x, 0.32, -0.45), 10)
		base.rotation = Vector3(PI * 0.5, turn, 0.0)


## Quarters for the machine, stacked in front of it.
func _quarters(at: Vector3, turn: float, props: RoomProps) -> void:
	var silver := _steel()
	for i: int in 3:
		var high := props._rng.randi_range(3, 9)
		ToyParts.chips(
			props, 0.6, 0.09, high, silver, _local(at, turn, (float(i) - 1.0) * 1.35, 0.0, 0.0)
		)


## A spare flipper lying flat: the bat in ivory in its red rubber, and its shaft.
func _flipper(at: Vector3, turn: float, props: RoomProps) -> void:
	var ivory := _satin(IVORY)
	var red := _rubber(RED_RUBBER)
	ToyParts.cylinder(props, 0.82, 0.5, red, _local(at, turn, 0.0, 0.25, -1.4), 16)
	ToyParts.cylinder(props, 0.42, 0.5, red, _local(at, turn, 0.0, 0.25, 1.9), 12)
	_turned(
		ToyParts.box(props, Vector3(1.2, 0.5, 3.3), red, _local(at, turn, 0.0, 0.25, 0.25)), turn
	)
	ToyParts.cylinder(props, 0.7, 0.62, ivory, _local(at, turn, 0.0, 0.31, -1.4), 16)
	ToyParts.cylinder(props, 0.3, 0.62, ivory, _local(at, turn, 0.0, 0.31, 1.9), 12)
	_turned(
		ToyParts.box(props, Vector3(0.96, 0.62, 3.3), ivory, _local(at, turn, 0.0, 0.31, 0.25)),
		turn
	)
	ToyParts.cylinder(props, 0.16, 0.3, _steel(), _local(at, turn, 0.0, 0.76, -1.4), 8)


## A spare bank of drop targets: three ivory targets standing in a steel rail.
func _targets(at: Vector3, turn: float, props: RoomProps) -> void:
	_turned(
		ToyParts.box(
			props, Vector3(5.4, 0.7, 1.8), _satin(DARK_STEEL, 0.4), _local(at, turn, 0.0, 0.35, 0.0)
		),
		turn
	)
	var ace := surfaces.printed(Surfaces.CARD_FACES[props._rng.randi_range(0, 3)])
	var card := QuadMesh.new()
	card.size = Vector2(1.0, 1.4)
	for i: int in 3:
		var x := (float(i) - 1.0) * 1.75
		_turned(
			ToyParts.box(
				props, Vector3(1.5, 2.2, 0.7), _satin(IVORY), _local(at, turn, x, 1.8, 0.0)
			),
			turn
		)
		var face := ToyParts.put(props, card, ace, _local(at, turn, x, 1.8, 0.36))
		face.rotation.y = turn


## An instruction card left on the table, the kind a machine keeps under its glass: cream, with
## its lines of print.
func _card(at: Vector3, turn: float, props: RoomProps) -> void:
	_turned(
		ToyParts.box(
			props, Vector3(6.0, 0.06, 3.6), _satin(PLASTIC, 0.3), _local(at, turn, 0.0, 0.03, 0.0)
		),
		turn
	)
	var ink := _satin(Color("#5A3E46"), 0.3)
	for i: int in 5:
		var line := Vector3(4.6 - float(i % 2) * 1.2, 0.02, 0.16)
		_turned(
			ToyParts.box(props, line, ink, _local(at, turn, 0.0, 0.07, -1.1 + 0.55 * float(i))),
			turn
		)


## Where a point [param x] across, [param y] up and [param z] along a prop standing at [param at]
## turned [param turn] is, in the room: across and along as [method RoomProps._ground] has them.
func _local(at: Vector3, turn: float, x: float, y: float, z: float) -> Vector3:
	var across := Vector3(cos(turn), 0.0, -sin(turn))
	var along := Vector3(sin(turn), 0.0, cos(turn))
	return at + across * x + along * z + Vector3(0.0, y, 0.0)


func _turned(node: MeshInstance3D, turn: float) -> MeshInstance3D:
	node.rotation.y = turn
	return node


func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)


# --- the materials ---------------------------------------------------------------


## Satin: the lacquer, the plastics and the ivory, each with a soft highlight and no mirror in it.
func _satin(color: Color, roughness := 0.45) -> StandardMaterial3D:
	var key := "satin%s%.2f" % [color.to_html(false), roughness]
	if not _made.has(key):
		var paint := StandardMaterial3D.new()
		paint.albedo_color = color
		paint.roughness = roughness
		paint.metallic_specular = 0.5
		_made[key] = paint
	return _made[key]


## Rubber: matte, with the barest sheen.
func _rubber(color: Color) -> StandardMaterial3D:
	var key := "rubber" + color.to_html(false)
	if not _made.has(key):
		var band := StandardMaterial3D.new()
		band.albedo_color = color
		band.roughness = 0.8
		band.metallic_specular = 0.25
		_made[key] = band
	return _made[key]


## Satin steel: the posts, the rails and the lip of a drain. Light rather than metal, since a
## dark room gives a metal nothing to show but the dark.
func _steel() -> StandardMaterial3D:
	if not _made.has("steel"):
		var steel := StandardMaterial3D.new()
		steel.albedo_color = STEEL
		steel.metallic = 0.35
		steel.roughness = 0.32
		steel.metallic_specular = 0.7
		_made["steel"] = steel
	return _made["steel"]


## The chrome of a ball, brighter than the steel and with a hard highlight.
func _chrome() -> StandardMaterial3D:
	if not _made.has("chrome"):
		var chrome := StandardMaterial3D.new()
		chrome.albedo_color = Color("#B4B9C2")
		chrome.metallic = 0.7
		chrome.roughness = 0.24
		chrome.metallic_specular = 0.6
		chrome.rim_enabled = true
		chrome.rim = 0.5
		chrome.rim_tint = 0.3
		_made["chrome"] = chrome
	return _made["chrome"]


## A lamp under plastic: lit from inside at [param energy], kept low so a shot outshines it.
func _lamp(color: Color, energy: float) -> StandardMaterial3D:
	var key := "lamp%s%.2f" % [color.to_html(false), energy]
	if not _made.has(key):
		var lit := StandardMaterial3D.new()
		lit.albedo_color = color.darkened(0.25)
		lit.roughness = 0.35
		lit.emission_enabled = true
		lit.emission = color
		lit.emission_energy_multiplier = energy
		_made[key] = lit
	return _made[key]


## The clear dome over a Jackpot's pile: a glint of glass and little else.
func _glass() -> StandardMaterial3D:
	if not _made.has("glass"):
		var clear := StandardMaterial3D.new()
		clear.albedo_color = Color(0.85, 0.9, 0.95, 0.16)
		clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		clear.roughness = 0.08
		clear.metallic_specular = 0.9
		clear.rim_enabled = true
		clear.rim = 0.6
		clear.rim_tint = 0.0
		_made["glass"] = clear
	return _made["glass"]
