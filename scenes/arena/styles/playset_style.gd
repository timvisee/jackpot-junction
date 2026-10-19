class_name PlaysetStyle
extends RoomStyle
## The Playroom, GAME.md 8.1c: the table is one of the House's molded playsets, the case open with
## the arena in its tray and its lid standing behind the far crowd. Everything is satin
## injection-molded plastic in four colors, plum, petrol teal, cream and ochre, and everything
## printed is a sticker: the floor is one big sticker sheet with the House's layout on it
## ([PlaysetPrints]), its far right corner peeled up off the tray. The walls are barrier sections
## clipped into the base by plum feet, plum clips with an ochre pin joining them; the boxes are
## molded dice, rolled where they lie; a pit is a trapdoor molded in the base with its two ribbed
## leaves hanging open and a stripe printed round it; the Junction is a molded roulette, a plum
## rotor with ochre arms and a cream ball in a pocket; a Jackpot is an ochre tray of molded chips,
## two stacks tipped over. The lid carries the rest of the room as molded scenery: a skyline of
## the House's strip at night, the marquee with its bulbs and the House's seal.
##
## A toy, but the House's: the palette is kept dark enough and the fine print fine enough that it
## reads as a casino's toy rather than a nursery's, and nothing is glossy.

const PLUM := Color("#47304A")
const DEEP := Color("#2B2430")
const TEAL := Color("#23535A")
## The lid's night: its sky and the lighter of its buildings.
const SKY := Color("#1D3B42")
const NIGHT := Color("#3E3043")
const DUSK := Color("#2A474D")
const CREAM := Color("#E9DFC8")
const SHADE := Color("#CFC3A8")
## The backing of a spare sheet of stickers.
const BACKING := Color("#B3A891")
const OCHRE := Color("#C38F3C")
## The Jackpot's tray, an ochre a shade deeper so the chips on it read.
const TRAY := Color("#80602F")
const PIPS := Color("#3A2340")
## The chips a Jackpot's tray holds, never the coin pads' blue.
const CHIPS: Array[Color] = [Color("#5A3460"), Color("#E9DFC8"), Color("#CF9A3E")]
## How big a die is in its cube, and how far it may be turned as it landed: a die turned further
## would reach out of the cube it is.
const DIE := 0.8
const ROLL := 0.2
const SQUARE := RoomBuild.Turned.SQUARE
const FLAT := RoomBuild.Turned.FLAT
const THROWN := RoomBuild.Turned.THROWN
## The lid: how tall it stands, how far it leans back off its hinge, in degrees, and how deep the
## deepest of it reaches behind its front, the strip along its top.
const LID_TALL := 62.0
const LID_LEAN := 9.0
const LID_DEEP := 2.1

var _floor: StandardMaterial3D
## Where the lid's hinge is and how it leans: its own frame, x across, y up it and z out of it.
var _lid_at := Transform3D.IDENTITY
var _made: Dictionary[String, StandardMaterial3D] = {}


## A barrier of molded sections, one a cell, each a cream cushion of plastic with a plum sticker
## round its middle, standing in plum feet at its joints and its ends, a plum clip with an ochre
## pin over each joint.
func wall(holder: Node3D, size: Vector3, _index: int) -> bool:
	var foot := -size.y * 0.5
	var long_x := size.x >= size.z
	var length := maxf(size.x, size.z)
	var depth := minf(size.x, size.z)
	# The block and the step first, sharing no plane: the molded rail the sections stand on and
	# the core they are molded round, which shows in the grooves between them.
	ToyParts.box(
		holder, Vector3(size.x - 0.04, 0.06, size.z - 0.04), _plastic(PLUM), _up(foot + 0.03)
	)
	ToyParts.box(
		holder, Vector3(size.x - 0.16, 0.84, size.z - 0.16), _plastic(SHADE), _up(foot + 0.45)
	)
	var sections := maxi(roundi(length / 1.25), 1)
	var run := length / float(sections)
	for i: int in sections + 1:
		var along := -length * 0.5 + run * float(i)
		along = clampf(along, -length * 0.5 + 0.13, length * 0.5 - 0.13)
		var at := _along(long_x, along, foot + 0.1)
		ToyParts.rounded(holder, _sized(long_x, 0.26, 0.2, depth), 0.05, _plastic(PLUM), at, 6)
		if i == 0 or i == sections:
			continue
		var clip := _along(long_x, along, 0.42)
		ToyParts.rounded(
			holder, _sized(long_x, 0.24, 0.09, depth - 0.22), 0.04, _plastic(PLUM), clip, 6
		)
		ToyParts.cylinder(holder, 0.04, 0.03, _plastic(OCHRE), clip + _up(0.06), 8)
	for i: int in sections:
		var along := -length * 0.5 + run * (float(i) + 0.5)
		var body := _sized(long_x, run - 0.07, 0.86, depth - 0.12)
		ToyParts.puffed(holder, body, 0.09, _plastic(CREAM), _along(long_x, along, -0.01), 6)
		var band := _sized(long_x, run - 0.3, 0.1, depth - 0.11)
		ToyParts.box(holder, band, _plastic(PLUM), _along(long_x, along, -0.06))
	return true


## A molded die, mostly cream with plum pips and now and then plum with cream ones, turned the way
## it landed.
func crate(holder: Node3D, size: Vector3) -> bool:
	var plum := rng.randf() < 0.2
	var body := _plastic(PLUM if plum else CREAM)
	var spots := _plastic(CREAM if plum else PIPS)
	var middle := Vector3(0.0, -size.y * 0.5 + DIE * 0.5, 0.0)
	ToyParts.puffed(holder, Vector3.ONE * DIE, 0.12, body, middle, 8)
	var top := rng.randi_range(1, 6)
	var rest: Array[int] = []
	for number: int in range(1, 7):
		if number != top and number != 7 - top:
			rest.append(number)
	var first: int = rest[0]
	var second: int = rest[1] if rest[1] != 7 - first else rest[2]
	var faces: Array[int] = [top, first, second, 7 - first, 7 - second]
	var outs: Array[Vector3] = [
		Vector3.UP, Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT
	]
	for i: int in faces.size():
		_pips(holder, middle, outs[i], faces[i], spots)
	holder.rotation.y = rng.randf_range(-ROLL, ROLL)
	return true


## A trapdoor molded in the base: the hole drops into the case's hollow, its two ribbed leaves hang
## open from the edges they are hinged on, and a stripe of ochre and plum is printed round it.
func pit(into: Node3D, size: Vector2) -> bool:
	var band := 0.22
	var step := 0.42
	for side: int in 4:
		var along := side % 2 == 0
		var span := (size.x + band * 2.0) if along else size.y
		var count := maxi(int(span / step), 2)
		for i: int in count:
			var offset := (float(i) + 0.5) * span / float(count) - span * 0.5
			var out := (
				((size.y if along else size.x) * 0.5 + band * 0.5) * (1.0 if side < 2 else -1.0)
			)
			var at := Vector3(offset, 0.006, out) if along else Vector3(out, 0.006, offset)
			var tile := (
				Vector3(span / float(count), 0.01, band)
				if along
				else Vector3(band, 0.01, span / float(count))
			)
			var ink := _plastic(OCHRE if i % 2 == 0 else PLUM)
			ToyParts.flat(ToyParts.box(into, tile, ink, at))
	var leaf := minf(size.y * 0.5 - 0.1, 0.9)
	for side: float in [-1.0, 1.0]:
		var hinge := Vector3(0.0, -0.04, side * (size.y * 0.5 - 0.04))
		var hang := 0.25
		var down := Vector3(0.0, -cos(hang), -side * sin(hang)) * leaf * 0.5
		var panel := ToyParts.box(
			into, Vector3(size.x - 0.12, leaf, 0.05), _plastic(DEEP), hinge + down
		)
		panel.rotation.x = side * hang
		for rib: int in 3:
			var across := (float(rib) - 1.0) * (size.x - 0.4) * 0.4
			var ridge := ToyParts.box(
				into,
				Vector3(0.08, leaf * 0.9, 0.05),
				_plastic(PLUM),
				hinge + down + Vector3(across, 0.0, -side * 0.04)
			)
			ridge.rotation.x = side * hang
	return true


## A molded roulette: a cream rim, a sticker of plum and cream pockets with an ochre zero between
## molded frets, a plum rotor with four ochre arms, an ochre turret and a cream ball in a pocket.
func junction(into: Node3D, radius: float) -> bool:
	var pad := RoomKit.PAD
	var layer := RoomKit.LAYER
	var face := radius - RoomKit.RIM
	ToyParts.flat(ToyParts.disc(into, face, _plastic(CREAM), pad * 0.5, pad, 48))
	var outer := face - 0.16
	var inner := radius * 0.56
	var deep := outer - inner
	var pockets := RoomKit.POCKETS
	for i: int in pockets:
		var turn := TAU * float(i) / float(pockets)
		var ink := _plastic(OCHRE if i == 0 else (PLUM if i % 2 == 1 else SHADE))
		var lift := pad + layer + (layer * 0.25 if i % 2 == 1 else 0.0)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * (inner + deep * 0.5)
		var wide := TAU * (inner + deep * 0.5) / float(pockets) * 1.12
		var pocket := ToyParts.box(into, Vector3(wide, 0.01, deep), ink, at + _up(lift))
		pocket.rotation.y = turn
		ToyParts.flat(pocket)
		var fret_turn := turn + PI / float(pockets)
		var fret_at := Vector3(sin(fret_turn), 0.0, cos(fret_turn)) * (inner + deep * 0.5)
		var fret := ToyParts.box(
			into, Vector3(0.04, 0.04, deep), _plastic(DEEP), fret_at + _up(pad + 0.02)
		)
		fret.rotation.y = fret_turn
	ToyParts.flat(ToyParts.disc(into, inner, _plastic(PLUM), pad + layer * 2.0, 0.02, 48))
	for i: int in 4:
		var turn := PI * 0.25 + PI * 0.5 * float(i)
		var out := Vector3(sin(turn), 0.0, cos(turn))
		var arm := ToyParts.box(
			into,
			Vector3(0.12, 0.04, inner - 0.2),
			_plastic(OCHRE),
			out * (inner - 0.2) * 0.5 + _up(pad + 0.04)
		)
		arm.rotation.y = turn
		ToyParts.cylinder(
			into, 0.08, 0.06, _plastic(OCHRE), out * (inner - 0.2) + _up(pad + 0.05), 8
		)
	ToyParts.cylinder(into, 0.3, 0.08, _plastic(OCHRE), _up(pad + 0.06), 16)
	ToyParts.taper(into, 0.18, 0.06, 0.08, _plastic(OCHRE), _up(pad + 0.14), 12)
	var rest := TAU * (float(rng.randi_range(1, pockets - 1)) + 0.0) / float(pockets)
	var ball_at := Vector3(sin(rest), 0.0, cos(rest)) * (inner + deep * 0.62)
	ToyParts.ball(into, 0.1, _plastic(CREAM), ball_at + _up(pad + 0.1), 8)
	return true


## An ochre tray of molded chips with a lip round it, the stacks round its edge so the count in the
## middle still shows, and two of them tipped over once it is full, the pile as much of that as the
## Jackpot is, [JackpotPile]. The tray is as far in from the tile on every side and its lip as wide
## whatever the Jackpot's size, and a long tray has more stacks along it rather than the same ones
## further apart.
func jackpot(into: Node3D, size: Vector2) -> bool:
	var inside := RoomKit.tray(size) - Vector2.ONE * 0.18
	var tray := Vector3(inside.x, 0.012, inside.y)
	var lift := 0.088
	ToyParts.flat(ToyParts.box(into, tray, _plastic(TRAY), _up(lift)))
	for side: int in 4:
		var along := side % 2 == 0
		var out := (tray.z if along else tray.x) * 0.5 * (1.0 if side < 2 else -1.0)
		var lip := Vector3(tray.x, 0.07, 0.07) if along else Vector3(0.07, 0.07, tray.z)
		var at := Vector3(0.0, lift + 0.03, out) if along else Vector3(out, lift + 0.03, 0.0)
		ToyParts.rounded(into, lip, 0.03, _plastic(OCHRE), at, 6)
	# Stacks along the back and the front, a stack's width and a little in from the lip and no
	# more than a meter apart.
	var reach := inside * 0.5 - Vector2.ONE * 0.38
	var along_count := maxi(ceili(reach.x * 2.0 / 1.0), 2)
	var spots: Array[Vector2] = []
	for i: int in along_count + 1:
		var x := -reach.x + reach.x * 2.0 * float(i) / float(along_count)
		spots.append(Vector2(x, -reach.y))
		spots.append(Vector2(x, reach.y))
	var pile := JackpotPile.on(into)
	for k: int in spots.size():
		var at := Vector3(spots[k].x, 0.0, spots[k].y) + _up(lift + 0.006)
		var high := rng.randi_range(3, 6)
		var stack := pile.stack()
		for chip: int in high:
			var ink: Color = CHIPS[(k + chip) % CHIPS.size()]
			var piece := ToyParts.cylinder(
				stack,
				0.22,
				0.06,
				surfaces.printed(Surfaces.CHIP_FACE, ink),
				at + _up(0.03 + 0.06 * float(chip)),
				12
			)
			piece.position.x += rng.randf_range(-0.015, 0.015)
	# Two stacks tipped over, lying along the tray's short sides in a fallen roll.
	var short := inside.x * 0.5 - 0.34
	for side: float in [-1.0, 1.0]:
		var foot := Vector3(-short * side, 0.0, 0.05 * side) + _up(lift + 0.226)
		var stack := pile.stack(true)
		for chip: int in 4:
			var ink: Color = CHIPS[chip % CHIPS.size()]
			var piece := ToyParts.cylinder(
				stack,
				0.22,
				0.06,
				surfaces.printed(Surfaces.CHIP_FACE, ink),
				foot + Vector3(0.0, 0.0, side * (0.07 * float(chip) - 0.12)),
				12
			)
			piece.rotation.x = PI * 0.5 + side * 0.25
	return true


## The sticker sheet: satin vinyl, its print laid on once the map's sheet has been drawn.
func floor_top() -> StandardMaterial3D:
	if _floor == null:
		_floor = StandardMaterial3D.new()
		_floor.albedo_color = PlaysetPrints.SHEET
		_floor.roughness = 0.55
		_floor.metallic_specular = 0.35
		_floor.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return _floor


## The tray of the case, molded in plum.
func surround() -> StandardMaterial3D:
	return _plastic(DEEP)


## The case, open: its tray on the floor of a playroom with its rim molded in plum and cream like a
## chip's edge, the sticker sheet printed for the map with a corner peeled up, the lid standing
## behind the far crowd with the House's strip molded on it, and the toys round it.
func room_round(props: RoomProps) -> bool:
	var arena := props.arena
	_print_sheet(arena)
	_peeled(arena)
	var shell := props.shell
	shell.enclose(Color("#4A3A30"), Color("#3B3036"), 3.0, 70.0, _lid_room())
	shell.skirt(PLUM, 3.0)
	_rim_inserts(shell)
	_lid(shell, arena)
	var near := {
		&"dice": [Rect2(-1.9, -1.1, 3.8, 2.2), THROWN, _dice.bind(props)],
		&"chips": [Rect2(-3.6, -1.2, 7.2, 2.4), SQUARE, _chips.bind(props)],
		&"sprue": [Rect2(-3.4, -2.4, 6.8, 4.8), SQUARE, _sprue.bind(props)],
	}
	var far := {
		&"carton": [Rect2(-4.8, -3.8, 9.6, 7.6), SQUARE, _carton.bind(props)],
		&"blocks": [Rect2(-2.4, -2.4, 4.8, 4.8), SQUARE, _blocks.bind(props)],
	}
	ToyParts.deal_round(props, 18, near, far)
	var sheet := [Rect2(-2.7, -2.0, 5.4, 4.0), RoomBuild.Turned.ALONG, _stickers.bind(props)]
	ToyParts.deal_apron(props, 4, {&"stickers": sheet, &"sprue": near[&"sprue"]})
	return true


func layout_inks() -> Array[Color]:
	return [Color("#D2A54E"), Color("#E6DCC4")]


func _print_sheet(arena: Arena) -> void:
	var across := arena.world_size()
	var sheet := floor_top()
	sheet.uv1_scale = Vector3(1.0 / across.x, 1.0 / across.y, 1.0)
	sheet.uv1_offset = Vector3(0.5, 0.5, 0.0)
	DrawnTexture.kept(
		arena,
		PlaysetPrints.sheet(arena.grid),
		PlaysetPrints.sheet_pixels(arena.grid),
		func(texture: Texture2D) -> void:
			sheet.albedo_color = Color.WHITE
			sheet.albedo_texture = texture
	)


## The sheet's far right corner, peeled up off the tray: the tray molded plum where it was, and the
## corner itself, printed as the sheet is, curling up from where it still sticks, its cream backing
## under it. It stands a hand high at its tip, low enough to be driven over without a thought.
func _peeled(arena: Arena) -> void:
	var holder := Node3D.new()
	holder.name = "Sheet"
	arena.add_child(holder)
	var half := arena.world_size() * 0.5
	var inset := arena.grid.cell_size * PlaysetPrints.SHEET_IN
	var corner := Vector3(half.x - inset, 0.0, -(half.y - inset))
	var reach := PlaysetPrints.PEEL
	var a := corner - Vector3(reach, 0.0, 0.0)
	var b := corner + Vector3(0.0, 0.0, reach)
	# Where the tray shows, covering the layout printed there as well as the sheet.
	var bare := _triangles([[a, b, corner]], Vector3(0.0, 0.003, 0.0), 0.0)
	ToyParts.flat(ToyParts.put(holder, bare, _plastic(DEEP), Vector3.ZERO))
	# The corner: flat for most of the way and curling over the last of it.
	var hinge := (a + b) * 0.5
	var out := (corner - hinge).normalized()
	var length := (corner - hinge).length()
	var bend := 0.55
	var lift := func(point: Vector3) -> Vector3:
		var t := (point - hinge).dot(out) / length
		var rise := 0.02 * t + (0.0 if t < bend else 0.14 * pow((t - bend) / (1.0 - bend), 1.6))
		return point + Vector3(0.0, 0.004 + rise, 0.0) - out * rise * 0.4
	var a_bend := a.lerp(corner, bend)
	var b_bend := b.lerp(corner, bend)
	var pieces := [[a, b, b_bend], [a, b_bend, a_bend], [a_bend, b_bend, corner]]
	var curl := _triangles(pieces, Vector3.ZERO, 1.0, lift, half * 2.0)
	ToyParts.flat(ToyParts.put(holder, curl, floor_top(), Vector3.ZERO))
	var back := _triangles(pieces, Vector3(0.0, -0.006, 0.0), -1.0, lift)
	ToyParts.flat(ToyParts.put(holder, back, _plastic(CREAM), Vector3.ZERO))
	if arena.bake_scenery:
		Bake.merge(holder)


## A mesh of [param pieces], each three points, moved by [param shift] and, if given, by
## [param bend]; its normals up for a [param facing] of 1, down for -1, and either for 0. With
## [param across], the arena's size, each point is mapped as the floor is, so a piece printed with
## the floor's material wears the print it was cut from.
func _triangles(
	pieces: Array,
	shift: Vector3,
	facing: float,
	bend: Callable = Callable(),
	across := Vector2.ZERO
) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for piece: Array in pieces:
		var moved: Array[Vector3] = []
		for point: Vector3 in piece:
			moved.append((bend.call(point) if bend.is_valid() else point) + shift)
		var drawn := (moved[1] - moved[0]).cross(moved[2] - moved[0]).normalized()
		var normal := drawn
		if normal.y * (facing if facing != 0.0 else 1.0) < 0.0:
			normal = -normal
		# Godot's front faces wind clockwise as seen from the side they face.
		var order: Array[int] = [0, 1, 2]
		if drawn.dot(normal) > 0.0:
			order = [0, 2, 1]
		for k: int in order:
			var flat_at: Vector3 = piece[k]
			tool.set_normal(normal)
			tool.set_uv(Vector2(flat_at.x, flat_at.z))
			if across != Vector2.ZERO:
				tool.set_uv2(Vector2(flat_at.x / across.x + 0.5, flat_at.z / across.y + 0.5))
			tool.add_vertex(moved[k])
	return tool.commit()


# --- the case and its lid ------------------------------------------------------------


## Cream inserts down the plum rim of the case, as a chip's edge has them.
func _rim_inserts(shell: RoomShell) -> void:
	var half := shell._table()
	var spacing := 7.0
	for side: int in 4:
		var along := side % 2 == 0
		var run := half.x if along else half.y
		var out := (half.y if along else half.x) * (1.0 if side < 2 else -1.0)
		var count := int(run * 2.0 / spacing)
		for i: int in count:
			var at := -run + spacing * (float(i) + 0.5) + (run * 2.0 - spacing * count) * 0.5
			var size := Vector3(2.6, 2.2, 0.3) if along else Vector3(0.3, 2.2, 2.6)
			var spot := (
				Vector3(at, RoomBuild.TOP - 1.5, out)
				if along
				else Vector3(out, RoomBuild.TOP - 1.5, at)
			)
			ToyParts.flat(ToyParts.box(shell, size, _plastic(CREAM), spot))


## The lid, standing open behind the far crowd on its hinge at the far edge of the tray and
## leaning back a little: plum, a night sky of teal inside it with ochre stars, the House's strip
## molded along its foot with its windows lit, the marquee over the strip and the House's seal at
## the top.
func _lid(shell: RoomShell, arena: Arena) -> void:
	var half := shell._table()
	var wide := half.x * 2.0
	var tall := LID_TALL
	var hinge := Vector3(0.0, RoomBuild.TOP, -half.y)
	_lid_at = Transform3D(Basis(Vector3.RIGHT, -deg_to_rad(LID_LEAN)), hinge)
	shell._keep(hinge - Vector3(half.x, 0.0, 0.0), hinge + Vector3(half.x, 0.0, 0.0), 6.0)
	_on_lid(
		ToyParts.box(shell, Vector3(wide, tall, 2.0), _plastic(PLUM), Vector3.ZERO),
		Vector3(0.0, tall * 0.5, -1.0)
	)
	_on_lid(
		ToyParts.box(shell, Vector3(wide - 5.0, tall - 5.0, 0.4), _plastic(SKY), Vector3.ZERO),
		Vector3(0.0, tall * 0.5, 0.2)
	)
	var spacing := 8.0
	for i: int in int(wide / spacing):
		var x := -wide * 0.5 + spacing * (float(i) + 0.5)
		_on_lid(
			ToyParts.box(shell, Vector3(3.0, 2.0, 2.3), _plastic(CREAM), Vector3.ZERO),
			Vector3(x, tall - 0.6, -0.95)
		)
	var lit := _lit(Color("#F4E3B5"), 0.9)
	var x := -wide * 0.5 + 3.0
	var skyline := 0
	while x < wide * 0.5 - 6.0:
		var width := rng.randf_range(4.0, 8.0)
		var middle := absf(x + width * 0.5) / (wide * 0.5)
		var high := rng.randf_range(9.0, 16.0) + 12.0 * (1.0 - middle)
		var ink := _plastic([DEEP, NIGHT, DUSK][skyline % 3])
		var centre := Vector3(x + width * 0.5, high * 0.5 + 0.5, 1.0)
		_on_lid(ToyParts.box(shell, Vector3(width, high, 1.6), ink, Vector3.ZERO), centre)
		var columns := int((width - 1.0) / 1.8)
		var rows := int((high - 2.0) / 2.6)
		for row: int in rows:
			for column: int in columns:
				if rng.randf() > 0.38:
					continue
				var wx := x + 1.0 + (width - 2.0) * (float(column) + 0.5) / float(columns)
				var window := Vector3(wx, 2.0 + 2.6 * float(row), 1.82)
				_on_lid(ToyParts.box(shell, Vector3(0.8, 1.1, 0.1), lit, Vector3.ZERO), window)
		x += width + rng.randf_range(0.3, 1.5)
		skyline += 1
	for k: int in 16:
		var star := Vector3(rng.randf_range(-0.45, 0.45) * wide, rng.randf_range(34.0, 54.0), 0.45)
		if absf(star.x) < 18.0 and star.y < 42.0:
			continue
		_on_lid(
			ToyParts.box(shell, Vector3(0.9, 0.9, 0.2), _plastic(OCHRE), Vector3.ZERO),
			star,
			Basis(Vector3.BACK, PI * 0.25)
		)
	# The marquee over the strip, lit, its picture drawn once.
	var sign := StandardMaterial3D.new()
	sign.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sign.albedo_color = OCHRE
	var board := QuadMesh.new()
	board.size = Vector2(32.0, 12.0)
	_on_lid(ToyParts.put(shell, board, sign, Vector3.ZERO), Vector3(0.0, 34.0, 0.5))
	DrawnTexture.kept(
		arena,
		PlaysetPrints.marquee(),
		PlaysetPrints.MARQUEE_PIXELS,
		func(texture: Texture2D) -> void:
			sign.albedo_color = Color(0.92, 0.92, 0.92)
			sign.albedo_texture = texture
	)
	# The House's seal at the top: foil, the one gold in the case.
	var upright := Basis(Vector3.RIGHT, PI * 0.5)
	var seal := ToyParts.cylinder(shell, 4.2, 0.4, _foil(), Vector3.ZERO, 32)
	_on_lid(seal, Vector3(0.0, tall - 9.0, 0.5), upright)
	var ring := ToyParts.cylinder(shell, 3.3, 0.5, _plastic(CREAM), Vector3.ZERO, 32)
	_on_lid(ring, Vector3(0.0, tall - 9.0, 0.55), upright)
	var chip := ToyParts.cylinder(shell, 2.8, 0.6, _plastic(PLUM), Vector3.ZERO, 32)
	_on_lid(chip, Vector3(0.0, tall - 9.0, 0.6), upright)


## How much further back than the room's own clearance its far wall has to stand for the lid to
## lean back clear of it, a meter to spare: its top leans back the better part of ten meters past
## the hinge, and against the wall the room has round any other table it went into the wall from
## a fifth of the way up, the marquee and the seal hidden behind it and the skyline through it.
static func _lid_room() -> float:
	var lean := deg_to_rad(LID_LEAN)
	var reach := LID_TALL * sin(lean) + LID_DEEP * cos(lean)
	return maxf(reach - RoomBuild.ROOM_CLEAR + 1.0, 0.0)


## Stands [param node] on the lid at [param local] in the lid's own frame, turned [param turn]
## in it.
func _on_lid(node: MeshInstance3D, local: Vector3, turn := Basis.IDENTITY) -> void:
	node.transform = Transform3D(_lid_at.basis * turn, _lid_at * local)
	ToyParts.flat(node)


# --- the toys round the case -----------------------------------------------------------


## A pair of big molded dice, rolled and come to rest apart.
func _dice(at: Vector3, turn: float, props: RoomProps) -> void:
	var size := 1.3
	for i: int in 2:
		var spot := _local(at, turn, (float(i) - 0.5) * 2.2, size * 0.5, 0.0)
		var plum := props._rng.randf() < 0.3
		var body := _plastic(PLUM if plum else CREAM)
		ToyParts.puffed(props, Vector3.ONE * size, 0.2, body, spot, 8)
		var top := props._rng.randi_range(1, 6)
		_face(props, spot + _up(size * 0.5), size, top, _plastic(CREAM if plum else PIPS))


## Stacks of molded chips, squared off side by side.
func _chips(at: Vector3, turn: float, props: RoomProps) -> void:
	for stack: int in 3:
		var ink: Color = CHIPS[(stack + props._rng.randi_range(0, 2)) % CHIPS.size()]
		var high := props._rng.randi_range(4, 9)
		var foot := _local(at, turn, (float(stack) - 1.0) * 2.3, 0.0, 0.0)
		var skin := surfaces.printed(Surfaces.CHIP_FACE, ink)
		for i: int in high:
			ToyParts.cylinder(props, 1.05, 0.3, skin, foot + _up(0.15 + 0.3 * float(i)), 16)


## A sprue of spare parts lying flat: the plum runner round its frame with barrier sections, clips
## and chips still on it.
func _sprue(at: Vector3, turn: float, props: RoomProps) -> void:
	var runner := _plastic(PLUM)
	for side: float in [-1.0, 1.0]:
		_turned(
			ToyParts.box(
				props, Vector3(6.4, 0.3, 0.3), runner, _local(at, turn, 0.0, 0.15, side * 2.1)
			),
			turn
		)
		_turned(
			ToyParts.box(
				props, Vector3(0.3, 0.3, 4.5), runner, _local(at, turn, side * 3.1, 0.15, 0.0)
			),
			turn
		)
	_turned(
		ToyParts.box(props, Vector3(6.0, 0.25, 0.25), runner, _local(at, turn, 0.0, 0.13, 0.0)),
		turn
	)
	for i: int in 3:
		var x := (float(i) - 1.0) * 1.9
		_turned(
			ToyParts.box(
				props, Vector3(1.5, 0.6, 0.9), _plastic(CREAM), _local(at, turn, x, 0.3, -1.05)
			),
			turn
		)
		ToyParts.cylinder(
			props,
			0.55,
			0.25,
			_plastic(OCHRE if i == 1 else CREAM),
			_local(at, turn, x, 0.13, 1.05),
			12
		)


## The carton the set came in, standing: plum, a cream band round it and the House's seal in ochre
## on its lid.
func _carton(at: Vector3, turn: float, props: RoomProps) -> void:
	var high := 5.0
	_turned(
		ToyParts.box(
			props, Vector3(9.0, high, 7.0), _plastic(PLUM), _local(at, turn, 0.0, high * 0.5, 0.0)
		),
		turn
	)
	_turned(
		ToyParts.box(
			props, Vector3(9.1, 1.2, 7.1), _plastic(CREAM), _local(at, turn, 0.0, high * 0.62, 0.0)
		),
		turn
	)
	ToyParts.cylinder(props, 1.8, 0.1, _plastic(OCHRE), _local(at, turn, 0.0, high + 0.05, 0.0), 24)


## Building blocks, four in a square and one on top, in the case's colors.
func _blocks(at: Vector3, turn: float, props: RoomProps) -> void:
	var inks: Array[Color] = [PLUM, TEAL, CREAM, OCHRE]
	var size := 2.0
	var k := props._rng.randi_range(0, 3)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var spot := _local(at, turn, corner.x * 1.05, size * 0.5, corner.y * 1.05)
		_turned(ToyParts.box(props, Vector3.ONE * size, _plastic(inks[k % 4]), spot), turn)
		k += 1
	var top := _local(at, turn, 0.0, size * 1.5, 0.0)
	_turned(ToyParts.box(props, Vector3.ONE * size, _plastic(inks[k % 4]), top), turn + 0.3)


## A spare sheet of stickers lying flat: cream, with its round stickers in the case's colors.
func _stickers(at: Vector3, turn: float, props: RoomProps) -> void:
	var paper := ToyParts.box(
		props, Vector3(5.0, 0.06, 3.6), _plastic(BACKING), _local(at, turn, 0.0, 0.03, 0.0)
	)
	_turned(paper, turn)
	var inks: Array[Color] = [PLUM, TEAL]
	for row: int in 2:
		for column: int in 3:
			var spot := _local(
				at, turn, (float(column) - 1.0) * 1.5, 0.07, (float(row) - 0.5) * 1.6
			)
			ToyParts.cylinder(props, 0.42, 0.03, _plastic(inks[(row + column) % 2]), spot, 16)


# --- the parts -------------------------------------------------------------------


## The pips of one face of a die whose middle is at [param middle], on the face out along
## [param out]: corners, then the middle, then two halfway down the sides for a six.
func _pips(holder: Node3D, middle: Vector3, out: Vector3, number: int, spots: Material) -> void:
	var across := Vector3.UP.cross(out)
	if across.length() < 0.01:
		across = Vector3.RIGHT
	across = across.normalized()
	var down := out.cross(across).normalized()
	for place: Vector2 in _pip_places(number):
		var at := middle + out * (DIE * 0.5 + 0.002) + (across * place.x + down * place.y) * 0.2
		var pip := ToyParts.cylinder(holder, 0.065, 0.02, spots, at, 8)
		if absf(out.y) < 0.5:
			pip.basis = Basis(across, out, -down).orthonormalized()


## The pips on the top face of a die [param size] across, at [param top].
func _face(into: Node3D, top: Vector3, size: float, number: int, spots: Material) -> void:
	for place: Vector2 in _pip_places(number):
		var at := top + Vector3(place.x, 0.002, place.y) * size * 0.25
		ToyParts.cylinder(into, size * 0.08, 0.03, spots, at, 8)


func _pip_places(number: int) -> Array[Vector2]:
	var places: Array[Vector2] = []
	if number % 2 == 1:
		places.append(Vector2.ZERO)
	if number > 1:
		places.append_array([Vector2(-1.0, -1.0), Vector2(1.0, 1.0)])
	if number > 3:
		places.append_array([Vector2(1.0, -1.0), Vector2(-1.0, 1.0)])
	if number == 6:
		places.append_array([Vector2(-1.0, 0.0), Vector2(1.0, 0.0)])
	return places


## A size laid along the wall: [param run] along it, [param tall] up and [param across] over it.
func _sized(long_x: bool, run: float, tall: float, across: float) -> Vector3:
	return Vector3(run, tall, across) if long_x else Vector3(across, tall, run)


## The point [param along] the wall's length at [param height].
func _along(long_x: bool, along: float, height: float) -> Vector3:
	return Vector3(along, height, 0.0) if long_x else Vector3(0.0, height, along)


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


## Satin molded plastic: a soft, broad highlight and nothing glossy, which is what keeps plastic
## from looking cheap.
func _plastic(color: Color) -> StandardMaterial3D:
	var key := "plastic" + color.to_html(false)
	if not _made.has(key):
		var molded := StandardMaterial3D.new()
		molded.albedo_color = color
		molded.roughness = 0.46
		molded.metallic_specular = 0.4
		_made[key] = molded
	return _made[key]


## A window lit in the lid's strip.
func _lit(color: Color, energy: float) -> StandardMaterial3D:
	var key := "lit" + color.to_html(false)
	if not _made.has(key):
		var glow := StandardMaterial3D.new()
		glow.albedo_color = color.darkened(0.3)
		glow.emission_enabled = true
		glow.emission = color
		glow.emission_energy_multiplier = energy
		_made[key] = glow
	return _made[key]


## The House's foil, for its seal on the lid.
func _foil() -> StandardMaterial3D:
	if not _made.has("foil"):
		var foil := StandardMaterial3D.new()
		foil.albedo_color = room.trim
		foil.metallic = 0.6
		foil.roughness = 0.38
		_made["foil"] = foil
	return _made["foil"]


## The House's word, STORY.md 6.1: a sticker stuck across the skyline on the lid, a little askew,
## where the shot a match opens on looks past the far crowd.
func house_word(word: HouseWord, _arena: Arena) -> bool:
	var askew := _lid_at.basis * Basis(Vector3.BACK, 0.035)
	var at := _lid_at * Vector3(16.0, 11.5, 1.95)
	word.lay(at, Vector2(10.0, 2.6), PLUM, HouseWord.Medium.STICKER, askew, 1.0, SHADE)
	return true


## What a playset's box loses to the floor, GAME.md 8.1c: a die out of a smaller game than the
## set's, a tenth the size of the boxes and plum with cream pips; a sticker off the sheet, its star
## still on its backing; and a snapped-off bit of sprue with a part's stub on it.
func litter(into: Node3D, which: int, _dice: RandomNumberGenerator) -> bool:
	match which % 3:
		0:
			var size := 0.1
			dropped(into, RoomStyle.slab(Vector3.ONE * size), PLUM, _up(size * 0.5))
			for spot: Vector2 in [Vector2(-1.0, -1.0), Vector2.ZERO, Vector2(1.0, 1.0)]:
				var pip := RoomStyle.rod(0.012, 0.004, 6)
				dropped(into, pip, CREAM, Vector3(spot.x * 0.026, size + 0.001, spot.y * 0.026))
		1:
			dropped(into, RoomStyle.slab(Vector3(0.2, 0.006, 0.16)), BACKING, _up(0.003))
			var star := PackedVector2Array()
			for i: int in 10:
				var reach := 0.062 if i % 2 == 0 else 0.026
				star.append(Vector2.from_angle(float(i) / 10.0 * TAU - PI * 0.5) * reach)
			dropped(into, RoomStyle.cutout(star, 0.004), OCHRE, _up(0.005))
		_:
			var along := Vector3(0.0, 0.0, PI * 0.5)
			dropped(into, RoomStyle.rod(0.013, 0.3, 6), PLUM, _up(0.013), along)
			var branch := RoomStyle.rod(0.011, 0.12, 6)
			dropped(into, branch, PLUM, Vector3(0.07, 0.013, 0.06), Vector3(PI * 0.5, 0.0, 0.0))
			dropped(into, RoomStyle.rod(0.03, 0.012, 8), PLUM, Vector3(0.07, 0.006, 0.13))
	return true
