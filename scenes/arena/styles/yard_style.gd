class_name YardStyle
extends RoomStyle
## The Yard, Crossfire's room, GAME.md 8.1c and STORY.md 3.9: a container yard, kept clean, late
## in the afternoon with no lamp lit. The arena is painted on the concrete as it always was, and
## everything in it is what a yard has: a wall is a shipping container, corrugated steel between
## its corner posts under a flat roof, the long ones in two lines' red and blue with their doors
## on one end and the short ones in sage; a box is a pallet with its load wrapped and strapped on
## it; a pit is an open drain, its grating gone, black water at the foot of it and hazard paint
## round its rim; and the Junction is a roulette painted on the concrete round a manhole cover, with
## the yard's crane's hook hung high over it, out of the way of the game. Round the table, see
## [YardLot], the crane that hook hangs from, stacks of containers, the site office, floodlights
## not yet on, pallets in rows and the forklift, behind the fence the crowd stands at.
##
## Few materials: the corrugated steel in a color for each line, and everything plain in one
## paint, its colors on its vertices, see [method Bake.tinted], so the walls, a box or the whole
## room draw in a handful of meshes, all on shaders the title's warm-up has compiled, GAME.md 10.7.

const LOT := "res://scenes/arena/styles/yard_lot.gd"

## The shipping lines' paints, muted, so the player colors stay the strongest on the table: an
## oxide red, a slate blue, a sage and a sand, with the frame of each a shade darker.
const RUST := Color("#7B4A3C")
const SLATE := Color("#4F6676")
const SAGE := Color("#69755E")
const SAND := Color("#A69A80")
## The steel of the doors' bars and the drain's frame, and the water at the foot of a drain.
const STEEL := Color("#6C7176")
const WATER := Color("#14191C")
## A pallet's timber, the kraft of its load, the strap round it and the label on the front.
const TIMBER := Color("#8D7552")
const KRAFT := Color("#92795B")
const STRAP := Color("#2E3236")
const LABEL := Color("#D9D2C1")
## The roulette's road paint on the concrete, and the cast iron of the manhole in its middle.
const CONCRETE := Color("#615D55")
const POCKET_RED := Color("#7C2D25")
const POCKET_BLACK := Color("#24252A")
const POCKET_GREEN := Color("#2F5E43")
const LINE_PAINT := Color("#B8B1A1")
const IRON := Color("#34363A")
## The hazard paint round a drain: a yellow a step down from the House's gold and the players',
## and black, at a share that leaves the concrete showing through.
const HAZARD := Color("#A38E46")
const HAZARD_BLACK := Color("#1D1D20")
const HAZARD_INK := 0.82
## How far the road paint of the House's word is taken into the concrete, so it is a working mark
## worn into the yard rather than a sign, see [method house_word].
const ROAD_PAINT_FADE := 0.45
## The House's layout in road paint: a worn white for the lines and a warmer one for the words.
const ROAD_LINE := Color("#C9C2B2")
const ROAD_WORD := Color("#D8CFBA")

## How many ribs to a meter the corrugation has, and how many pixels a rib is drawn at.
const RIBS := 5
const RIB_PIXELS := 24
## A container's parts, as shares of its height: how far in its sides stand from its corner
## posts, how thick a post is, how thick the roof, and the doors' bars.
const INSET := 0.04
const POST := 0.09
const ROOF := 0.075
const SILL := 0.07
const RIM := 0.075
const BAR := 0.026
## How much darker a container's frame is than its sides.
const FRAME := 0.32
## Where the doors' bars stand across the end they are on, as shares of its width.
const DOOR_BARS: Array[float] = [-0.38, -0.13, 0.13, 0.38]
## How much longer than wide a container has to be to have its doors on an end of its length
## rather than on the side facing the table's near edge, which a cube of one has.
const LONG := 1.4
## The drain: how wide the steel angle round its top is, how far down the water is as a share of
## the pit's depth, and the band of hazard paint round it and its stripes, as shares of a cell.
const ANGLE := 0.07
const WATER_DOWN := 0.82
const HAZARD_BAND := 0.2
const HAZARD_STRIPE := 0.3
## The painted roulette: how many pockets, how thick the paint and how far each coat stands over
## the one under it, see [RoomKit].
const POCKETS := 28
const PAD := 0.05
const LAYER := 0.006

var _materials: Dictionary[String, StandardMaterial3D] = {}
var _ribs: ImageTexture
## How many long containers have been dealt their paint, so the lines take turns.
var _long_walls := 0


## A shipping container the block the wall was: its corrugated sides, its posts and its roof, the
## long ones in the lines' red and blue by turns with their doors on one end, the short ones in
## sage with theirs toward the table's near edge. All of it inside the wall's box.
func wall(holder: Node3D, size: Vector3, _index: int) -> bool:
	var ink := SAGE
	if maxf(size.x, size.z) > minf(size.x, size.z) * LONG * 2.0:
		ink = RUST if _long_walls % 2 == 0 else SLATE
		_long_walls += 1
	container(holder, size, Vector3(0.0, -size.y * 0.5, 0.0), ink)
	return true


## A pallet of cargo, wrapped and strapped, inside the box's own cube.
func crate(holder: Node3D, size: Vector3) -> bool:
	var high := rng.randf_range(0.8, 0.9)
	pallet_load(holder, Vector3(size.x, size.y * high, size.z), Vector3(0.0, -size.y * 0.5, 0.0))
	holder.rotation.y = rng.randf_range(-0.05, 0.05)
	return true


## An open drain, GAME.md 8.1: the steel angle its grating sat in round the top, just under the
## floor, and black water down at the foot of it. The hazard paint round it is on the floor's
## print, see [method print_under]. Nothing stands above the floor.
func pit(into: Node3D, size: Vector2) -> bool:
	var steel := surfaces.metal(STEEL)
	for side: float in [-1.0, 1.0]:
		var along := Vector3(size.x, 0.05, ANGLE)
		_box(into, along, steel, Vector3(0.0, -0.03, side * (size.y - ANGLE) * 0.5))
		var across := Vector3(ANGLE, 0.05, size.y - ANGLE * 2.0)
		_box(into, across, steel, Vector3(side * (size.x - ANGLE) * 0.5, -0.03, 0.0))
	var water := Vector3(size.x - 0.02, 0.02, size.y - 0.02)
	_box(into, water, _water(), Vector3(0.0, -Arena.PIT_DEPTH * WATER_DOWN, 0.0))
	return true


## A roulette painted on the concrete, GAME.md 8.1c: road paint, its red and black pockets with a
## green zero between bare concrete, a white line round inside them, and a manhole cover for the
## spindle, its frame, the cross of its ribs and the boss in its middle. Its call to attention,
## 3.4, is the road studs round it lighting up and running round, see [method _road_studs].
func junction(into: Node3D, radius: float, cue: JunctionCue) -> bool:
	var face := radius - RoomKit.RIM
	_tinted_disc(into, radius, CONCRETE, PAD * 0.5, PAD)
	_road_studs(into, radius, cue)
	var outside := face * 0.92
	var inside := face * 0.62
	var deep := outside - inside
	var middle := (outside + inside) * 0.5
	for i: int in POCKETS:
		var turn := TAU * float(i) / float(POCKETS)
		var ink := POCKET_GREEN if i == 0 else (POCKET_RED if i % 2 == 1 else POCKET_BLACK)
		# Short of the arc each sits on, so bare concrete shows between them as between the boxes
		# of any road marking.
		var wide := TAU * middle / float(POCKETS) * 0.84
		var at := Vector3(sin(turn), 0.0, cos(turn)) * middle + _up(PAD + LAYER)
		tinted_box(into, Vector3(wide, 0.01, deep), ink, at).rotation.y = turn
	_tinted_disc(into, inside - 0.08, LINE_PAINT, PAD + LAYER)
	_tinted_disc(into, inside - 0.16, CONCRETE, PAD + LAYER * 2.0)
	# The manhole, a hair proud of the paint, low enough to drive over: its frame, the cover, a
	# ring cast round its middle, the cross of its ribs and the boss.
	var cover := face * 0.3
	_tinted_disc(into, cover + 0.08, STEEL, PAD + LAYER * 3.0, 0.016)
	_tinted_disc(into, cover, IRON, PAD + LAYER * 4.0, 0.016)
	_tinted_disc(into, cover * 0.66, IRON.lightened(0.12), PAD + LAYER * 5.0, 0.014)
	_tinted_disc(into, cover * 0.54, IRON, PAD + LAYER * 6.0, 0.014)
	for i: int in 2:
		var rib := tinted_box(
			into, Vector3(0.07, 0.012, cover * 1.8), IRON.lightened(0.12), _up(PAD + LAYER * 7.0)
		)
		rib.rotation.y = PI * 0.25 + PI * 0.5 * float(i)
	_tinted_disc(into, cover * 0.16, IRON.lightened(0.18), PAD + LAYER * 8.0, 0.014)
	return true


## The room round the table, built by [YardLot]: the crane, the stacks, the office, the floodlights
## and the rest, put down by hand round the fence the crowd stands behind.
##
## The lot is asked for by its path as the room goes up rather than named here, as the Workbench's
## bench is, see [method WorkbenchStyle.room_round]: naming it and the room's parts it builds with
## would have this script wait on them as it compiles.
func room_round(props: RoomProps) -> bool:
	load(LOT).new(self, props).lay()
	return true


## The House's layout in road paint, GAME.md 8.1b.
func layout_inks() -> Array[Color]:
	return [ROAD_LINE, ROAD_WORD]


## The hazard paint round each drain, on the floor's print under the House's layout: a band of
## yellow with black stripes across it at a slant, the one marking on the floor that is a warning
## rather than a decoration, GAME.md 8.1.
func print_under(on: LayoutPrint) -> void:
	var cell := float(LayoutPrint.CELL_PIXELS)
	var band := cell * HAZARD_BAND
	var lip := cell * Arena.PIT_RIM / on.grid.cell_size
	var yellow := Color(HAZARD, HAZARD_INK)
	var black := Color(HAZARD_BLACK, HAZARD_INK)
	for rect: Rect2i in on.grid.pits:
		var hole := Rect2(Vector2(rect.position) * cell, Vector2(rect.size) * cell).grow(lip)
		var outer := hole.grow(band)
		var strips: Array[Rect2] = [
			Rect2(outer.position, Vector2(outer.size.x, band)),
			Rect2(Vector2(outer.position.x, hole.end.y), Vector2(outer.size.x, band)),
			Rect2(Vector2(outer.position.x, hole.position.y), Vector2(band, hole.size.y)),
			Rect2(Vector2(hole.end.x, hole.position.y), Vector2(band, hole.size.y)),
		]
		# Slanted stripes, black and yellow by turns, each cut to the band it lies on.
		var step := cell * HAZARD_STRIPE
		var count := int((outer.size.x + outer.size.y) / step) + 2
		for k: int in count:
			var x := outer.position.x - outer.size.y + float(k) * step
			var stripe := PackedVector2Array(
				[
					Vector2(x, outer.end.y),
					Vector2(x + step, outer.end.y),
					Vector2(x + step + outer.size.y, outer.position.y),
					Vector2(x + outer.size.y, outer.position.y),
				]
			)
			for strip: Rect2 in strips:
				var cut := PackedVector2Array(
					[
						strip.position,
						Vector2(strip.end.x, strip.position.y),
						strip.end,
						Vector2(strip.position.x, strip.end.y),
					]
				)
				for piece: PackedVector2Array in Geometry2D.intersect_polygons(stripe, cut):
					on.draw_colored_polygon(piece, black if k % 2 == 0 else yellow)


# --- the things a yard is made of --------------------------------------------


## A shipping container of [param size] standing on [param foot] under [param into], in
## [param ink]: its corrugated sides between the rails along its top and its foot and a little in
## from its corner posts, all of the frame a shade darker, the roof inside the top rails, and its
## doors, four bars down them, on the end of its length or, for one as wide as it is long, on the
## side facing the table's near edge. Square with the table, its length along x or z.
func container(into: Node3D, size: Vector3, foot: Vector3, ink: Color) -> void:
	var tall := size.y
	var inset := tall * INSET
	var roof := tall * ROOF
	var sill := tall * SILL
	var body := Vector3(size.x - inset * 2.0, tall - roof - sill + 0.02, size.z - inset * 2.0)
	_box(into, body, corrugated(ink), foot + _up(sill - 0.01 + body.y * 0.5))
	var frame := ink.darkened(FRAME)
	# The top rails round the roof, a little out over the sides and a hair under the posts, which
	# stand proud of them at the corners as their castings do; the roof inside them; the rails
	# along the foot.
	var lid := Vector3(size.x - inset, roof, size.z - inset)
	tinted_box(into, lid, frame, foot + _up(tall - 0.006 - roof * 0.5))
	var rim := tall * RIM
	var panel := Vector3(lid.x - rim * 2.0, 0.01, lid.z - rim * 2.0)
	tinted_box(into, panel, ink.lightened(0.05), foot + _up(tall - 0.006))
	tinted_box(into, Vector3(lid.x, sill, lid.z), frame, foot + _up(sill * 0.5))
	var post := tall * POST
	var corner := Vector2(size.x - post, size.z - post) * 0.5
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var at := foot + Vector3(x * corner.x, tall * 0.5, z * corner.y)
			tinted_box(into, Vector3(post, tall, post), frame, at)
	# The doors' bars, two to a leaf, in bare steel, standing just proud of the end they are on.
	var along_x := size.x > size.z * LONG
	var bar := tall * BAR
	var high := (tall - roof - sill) * 0.9
	var out := (size.x if along_x else size.z) * 0.5 - inset + bar * 0.5
	var across := size.z if along_x else size.x
	for share: float in DOOR_BARS:
		var at := Vector3(out, sill + (tall - roof - sill) * 0.5, share * across)
		if not along_x:
			at = Vector3(share * across, at.y, out)
		tinted_box(into, Vector3(bar, high, bar), STEEL, foot + at)


## A pallet with its load wrapped and strapped on it, [param size] over all, standing on
## [param foot] under [param into]: the deck on three runners, the load in kraft a little in from
## the deck's edge, two straps round it and a label on its front.
func pallet_load(into: Node3D, size: Vector3, foot: Vector3) -> void:
	var runner := size.y * 0.11
	var deck := size.y * 0.04
	for i: int in 3:
		var z := (float(i) - 1.0) * (size.z * 0.5 - size.z * 0.07)
		var at := foot + Vector3(0.0, runner * 0.5, z)
		tinted_box(into, Vector3(size.x * 0.98, runner, size.z * 0.14), TIMBER.darkened(0.12), at)
	tinted_box(
		into,
		Vector3(size.x * 0.98, deck, size.z * 0.98),
		TIMBER,
		foot + _up(runner + deck * 0.5 - 0.002)
	)
	var load := Vector3(size.x * 0.9, size.y - runner - deck, size.z * 0.9)
	var low := runner + deck - 0.004
	tinted_box(into, load, KRAFT, foot + _up(low + load.y * 0.5))
	for side: float in [-1.0, 1.0]:
		var strap := Vector3(size.x * 0.05, load.y + 0.012, load.z + 0.012)
		tinted_box(
			into, strap, STRAP, foot + Vector3(side * size.x * 0.24, low + load.y * 0.5, 0.0)
		)
	var label := Vector3(size.x * 0.22, load.y * 0.18, 0.012)
	var face := foot + Vector3(-size.x * 0.06, low + load.y * 0.62, load.z * 0.5 + 0.004)
	tinted_box(into, label, LABEL, face)


# --- the materials -----------------------------------------------------------


## Corrugated steel in [param ink]: the ribs drawn once and laid on from the side in the world's
## meters, [constant RIBS] to the meter, so every container in the yard has them at the same pitch;
## laid on as the House's tin walls are, so it is a shader the warm-up has already compiled.
func corrugated(ink: Color) -> StandardMaterial3D:
	var key := "ribs:" + ink.to_html(false)
	if not _materials.has(key):
		var steel := StandardMaterial3D.new()
		steel.albedo_color = ink
		steel.albedo_texture = _corrugation()
		steel.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		steel.uv1_triplanar = true
		steel.uv1_world_triplanar = true
		steel.uv1_triplanar_sharpness = 40.0
		steel.roughness = 0.62
		steel.metallic = 0.15
		steel.metallic_specular = 0.4
		_materials[key] = steel
	return _materials[key]


## One meter of the ribs: a lit outer face, a slope in shade, the inner face and a slope in the
## light, across; the same all the way up.
func _corrugation() -> ImageTexture:
	if _ribs != null:
		return _ribs
	var wide := RIBS * RIB_PIXELS
	var image := Image.create_empty(wide, 8, false, Image.FORMAT_RGB8)
	for x: int in wide:
		var t := float(x % RIB_PIXELS) / float(RIB_PIXELS)
		var shade := 1.0
		if t >= 0.4 and t < 0.5:
			shade = 0.8
		elif t >= 0.5 and t < 0.9:
			shade = 0.9
		elif t >= 0.9:
			shade = 0.96
		image.fill_rect(Rect2i(x, 0, 1, 8), Color(shade, shade, shade))
	image.generate_mipmaps()
	_ribs = ImageTexture.create_from_image(image)
	return _ribs


## The black water at the foot of a drain, with the sky's light lying on it.
func _water() -> StandardMaterial3D:
	if not _materials.has("water"):
		var still := StandardMaterial3D.new()
		still.albedo_color = WATER
		still.roughness = 0.12
		still.metallic_specular = 0.7
		_materials["water"] = still
	return _materials["water"]


# --- the parts ---------------------------------------------------------------


## A box of [param size] in plain paint of [param ink] under [param into]: its color on its
## vertices, so every one of them in the room bakes into one mesh, see [method Bake.tinted].
func tinted_box(into: Node3D, size: Vector3, ink: Color, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _tinted(into, mesh, ink, at)


## An upright cylinder of [param radius] and [param height] in plain paint, [param sides] round.
func tinted_cylinder(
	into: Node3D, radius: float, height: float, ink: Color, at: Vector3, sides := 10
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return _tinted(into, mesh, ink, at)


func _tinted(into: Node3D, mesh: Mesh, ink: Color, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = Bake.tinted([[mesh, Transform3D.IDENTITY, ink]])
	node.material_override = Bake.tinted_look(false)
	node.position = at
	into.add_child(node)
	return node


func _tinted_disc(
	into: Node3D, radius: float, ink: Color, lift: float, thick := 0.01
) -> MeshInstance3D:
	return tinted_cylinder(into, radius, thick, ink, _up(lift), 48)


func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)


func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node


## The House's word, STORY.md 6.1: painted on the yard's concrete in a box across a lane on the
## near side, as a yard paints KEEP CLEAR in front of what must be kept clear, here the electrical
## cabinet behind the near rail, see [method YardLot]; in the yard's marking worn into the concrete,
## a working mark rather than a sign. Stenciled on the hoarding at the back of the yard for a map
## with no lane to paint it in.
func house_word(word: HouseWord, arena: Arena) -> bool:
	var box := HouseWord.road_box(arena.grid)
	if box.size != Vector2i.ZERO:
		var grid := arena.grid
		var middle := (
			(grid.cell_center(box.position) + grid.cell_center(box.end - Vector2i.ONE)) * 0.5
		)
		middle.y = HouseWord.ROAD_LIFT
		var across := Vector2(box.size) * grid.cell_size - Vector2.ONE * 0.2
		var ink := room.marking.lerp(room.felt, ROAD_PAINT_FADE)
		word.boxed = true
		word.lay(middle, across, ink, HouseWord.Medium.PAINT, HouseWord.FLAT, HouseWord.STRETCH)
		return true
	var half := arena.world_size() * 0.5
	var wide := half.x + RoomBuild.FAR
	var z := -(half.y + RoomBuild.BACK_FAR + RoomBuild.BACK_WALL)
	var at := Vector3(wide * 0.2, RoomBuild.TOP + 4.6, z + 0.2)
	word.lay(at, Vector2(wide * 0.26, 2.4), HAZARD_BLACK, HouseWord.Medium.STENCIL)
	return true


## What the yard's floor gathers, GAME.md 8.1c: a bolt with its nut run down it, the snipped end
## of a pallet strap with its seal still crimped on, and a shipping label come unstuck.
func litter(into: Node3D, which: int, dice: RandomNumberGenerator) -> bool:
	var along := Vector3(0.0, 0.0, PI * 0.5)
	match which % 3:
		0:
			dropped(into, RoomStyle.rod(0.055, 0.045, 6), STEEL, Vector3(-0.14, 0.055, 0.0), along)
			dropped(into, RoomStyle.rod(0.026, 0.26, 6), STEEL, Vector3(0.0, 0.055, 0.0), along)
			dropped(into, RoomStyle.rod(0.05, 0.04, 6), STEEL, Vector3(0.06, 0.055, 0.0), along)
		1:
			var bend := dice.randf_range(0.25, 0.5)
			var way := Vector3(cos(bend), 0.0, -sin(bend))
			var strap := RoomStyle.slab(Vector3(0.2, 0.006, 0.05))
			dropped(into, strap, STRAP, Vector3(-0.1, 0.003, 0.0))
			var leg := RoomStyle.slab(Vector3(0.2, 0.008, 0.05))
			dropped(into, leg, STRAP, way * 0.1 + _up(0.004), Vector3(0.0, bend, 0.0))
			var seal := RoomStyle.slab(Vector3(0.06, 0.022, 0.066))
			dropped(into, seal, STEEL, way * 0.2 + _up(0.011), Vector3(0.0, bend, 0.0))
		_:
			dropped(into, RoomStyle.slab(Vector3(0.22, 0.006, 0.15)), LABEL, _up(0.003))
			for line: int in 2:
				var print_line := RoomStyle.slab(Vector3(0.14 - line * 0.04, 0.004, 0.014))
				var at := Vector3(-0.02 - line * 0.02, 0.006, -0.03 + line * 0.035)
				dropped(into, print_line, STRAP, at)
	return true


## Road studs let into the concrete round the roundel out to [param radius], the kind a yard's
## lanes are lit with at night: a steel housing flush with the paint and an amber lens in it, dull
## glass unlit, so the roundel is a painted one with nothing at stake, and lit by [param cue] in
## four sets that run round it one after the other, the lane lights of a yard leading a truck in.
func _road_studs(into: Node3D, radius: float, cue: JunctionCue) -> void:
	var studs := 28
	cue.lit = Color("#FF8C1A")
	cue.glow = 2.4
	cue.steps = Vector2(3.0, 10.0)
	var lenses := cue.chase_lamps(4, Color("#4A3A20"))
	var round_at := radius - RoomKit.RIM * 0.6
	for i: int in studs:
		var turn := TAU * (float(i) + 0.5) / float(studs)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * round_at
		var housing := Vector3(0.44, 0.02, 0.2)
		tinted_box(into, housing, IRON, at + _up(PAD + 0.01)).rotation.y = turn
		var lens := _box(into, Vector3(0.36, 0.02, 0.13), lenses[i % 4], at + _up(PAD + 0.018))
		lens.rotation.y = turn
