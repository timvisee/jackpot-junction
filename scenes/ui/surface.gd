class_name Surface
extends RefCounted
## What a piece of the house print feels like, GAME.md 8.1a: a fine texture laid over its stock so
## it reads as a thing rather than a flat color, paper's fibers on a slip, the scratches a laminated
## card picks up on a pane. Each is worked out in code the first time it is asked for, as a tile
## that repeats without a seam, and laid inside a shape cut into tiles, so a pane of any size takes
## it without stretching it. Each pixel of a tile lightens or darkens what is under it by a little,
## so a texture moves no color, only gives it a grain.

enum Kind { NONE, PAPER, FLECKED, GRAIN, SCRATCHED, FELT, BRUSHED, LINEN }

## How big a tile is, in its own pixels, each laid over one of the screen's, so the grain is as
## fine on a big screen as on a small one, see [method screen_scale].
const TILE := 256
## What each part of the house print wears, GAME.md 8.1a: its texture, how strongly, and how much
## light falls on it from its top left. Panes and the buttons on them are laminated card, a few
## fine scratches under a soft light, and the HUD's strips the same; gold foil is brushed, faintly,
## under a sheen; the payout slip is fine paper; joker cards have a playing card's linen; the
## clock board is behind glass, a light with no texture; and the menus' backdrop is card-table
## felt.
const FINISHES: Dictionary[String, Array] = {
	"pane": [Kind.SCRATCHED, 0.08, 0.06],
	"button": [Kind.SCRATCHED, 0.06, 0.05],
	"foil": [Kind.BRUSHED, 0.11, 0.07],
	"hud": [Kind.SCRATCHED, 0.08, 0.05],
	"slip": [Kind.PAPER, 0.3, 0.0],
	"card": [Kind.LINEN, 0.3, 0.0],
	"clock": [Kind.NONE, 0.0, 0.1],
	"backdrop": [Kind.FELT, 0.16, 0.0],
}
## How much bigger than one texel to a screen pixel a kind is laid: a playing card's linen is a
## weave coarser than the rest's grain, and laid stronger, so it reads as cloth on a dark card.
const ZOOM: Dictionary[int, float] = {Kind.LINEN: 2.0}
## The kinds laid over big fields, laid twice at two scales that never line up, so no clump of
## the tile is seen repeating across the screen as a grid of lines: the second scale, and how
## strongly each layer is laid against the one strength asked for.
const LAYERED: Dictionary[int, float] = {Kind.FELT: 1.618, Kind.GRAIN: 1.618}
const LAYER_SHARE := 0.62
## How many shapes' pieces are kept at one size, a phase each, see [method draw].
const PHASES_KEPT := 48

static var _tiles: Dictionary[int, ImageTexture] = {}


## The kind named [param word], as a choice is written down: paper, scratched and so on.
static func named(word: String) -> Kind:
	var found := Kind.keys().find(word.strip_edges().to_upper())
	return Kind.NONE if found < 0 else Kind.values()[found] as Kind


## How many of the screen's pixels a unit of the interface is drawn over: more than one on a big
## screen or at a large UI scale.
static func screen_scale() -> float:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return 1.0
	return clampf(tree.root.get_final_transform().get_scale().x, 0.5, 4.0)


## [param edge], a shape [param size] big, cut along tiles [param tile] across, each piece with
## the place in its tile each of its points takes the texture from.
static func pieces(
	edge: PackedVector2Array, size: Vector2, tile: float, shift := Vector2.ZERO
) -> Array[Dictionary]:
	var made: Array[Dictionary] = []
	for row: int in ceili((size.y + shift.y) / tile):
		for column: int in ceili((size.x + shift.x) / tile):
			var corner := Vector2(column, row) * tile - shift
			var square := PackedVector2Array(
				[
					corner,
					corner + Vector2(tile, 0.0),
					corner + Vector2.ONE * tile,
					corner + Vector2(0.0, tile)
				]
			)
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(edge, square):
				if piece.size() < 3:
					continue
				var uvs := PackedVector2Array()
				for point: Vector2 in piece:
					uvs.append((point - corner) / tile)
				made.append({&"points": piece, &"uvs": uvs})
	return made


## Lays [param kind] over [param edge], a shape [param size] big, at [param strength]: how far its
## lightest and darkest pixels move what is under them, from 0 for nothing to 1 for white and black.
## Each control drawing it takes the tile from a place of its own, by [param item], so two buttons
## side by side are not one texture twice. The shape's pieces are kept in [param kept], the shape's
## own worked-out dictionary, by that place, and worked out again only when the screen's scale has
## moved.
static func draw(
	item: RID,
	kept: Dictionary,
	edge: PackedVector2Array,
	size: Vector2,
	kind: Kind,
	strength: float
) -> void:
	if kind == Kind.NONE or strength <= 0.0 or edge.size() < 3:
		return
	var at := screen_scale()
	if kept.get(&"surface_at", 0.0) != at or kept.get(&"surface_kind", -1) != kind:
		kept[&"surface_by_phase"] = {}
		kept[&"surface_at"] = at
		kept[&"surface_kind"] = kind
	var by_phase: Dictionary = kept[&"surface_by_phase"]
	var phase := item.get_id() % 997
	if not by_phase.has(phase):
		if by_phase.size() >= PHASES_KEPT:
			by_phase.clear()
		by_phase[phase] = _laid(edge, size, kind, at, phase)
	var texture := tile_of(kind).get_rid()
	var layers: Array = by_phase[phase]
	var share := LAYER_SHARE if layers.size() > 1 else 1.0
	var ink := PackedColorArray([Color(1.0, 1.0, 1.0, strength * share)])
	for made: Array in layers:
		for piece: Dictionary in made:
			RenderingServer.canvas_item_add_polygon(
				item, piece[&"points"], ink, piece[&"uvs"], texture
			)


## The pieces of [param edge] for each layer [param kind] is laid in, from the place in the tile
## [param phase] picks.
static func _laid(
	edge: PackedVector2Array, size: Vector2, kind: Kind, at: float, phase: int
) -> Array:
	var tile := float(TILE) * float(ZOOM.get(kind, 1.0)) / at
	var shift := Vector2(fposmod(phase * 0.618034, 1.0), fposmod(phase * 0.414214, 1.0)) * tile
	var layers := [pieces(edge, size, tile, shift)]
	if LAYERED.has(kind):
		var wider := tile * float(LAYERED[kind])
		layers.append(pieces(edge, size, wider, shift.rotated(1.1).abs() + Vector2(37.0, 61.0)))
	return layers


## A light falling on [param edge] from its top left, [param strength] at its brightest, and the
## shade it leaves in the bottom right: two washes, each running evenly across the shape, so the
## shape's own corners are all they need.
static func light(item: RID, edge: PackedVector2Array, size: Vector2, strength: float) -> void:
	if strength <= 0.0 or edge.size() < 3:
		return
	var lit := PackedColorArray()
	var shade := PackedColorArray()
	for point: Vector2 in edge:
		var down := clampf(point.x / size.x * 0.35 + point.y / size.y * 0.65, 0.0, 1.0)
		lit.append(Color(1.0, 1.0, 1.0, strength * (1.0 - down)))
		shade.append(Color(0.0, 0.0, 0.0, strength * 1.6 * down))
	RenderingServer.canvas_item_add_polygon(item, edge, lit)
	RenderingServer.canvas_item_add_polygon(item, edge, shade)


## What [param part] wears, see [constant FINISHES]: its kind, how strongly and how much light, or
## nothing at all for a part with no finish.
static func finish(part: String) -> Array:
	return FINISHES.get(part, [Kind.NONE, 0.0, 0.0])


## Puts on [param style], a [TicketStyle] or a [StripStyle], what [param part] wears, see
## [method finish].
static func wear(style: StyleBox, part: String) -> void:
	var look := finish(part)
	style.set(&"surface", int(look[0]))
	style.set(&"surface_ink", float(look[1]))
	style.set(&"light", float(look[2]))


## The tile of [param kind], made the first time it is asked for.
static func tile_of(kind: Kind) -> ImageTexture:
	if _tiles.has(kind):
		return _tiles[kind]
	var field := PackedFloat32Array()
	field.resize(TILE * TILE)
	var dice := RandomNumberGenerator.new()
	dice.seed = 7919 * (int(kind) + 1)
	match kind:
		Kind.PAPER:
			_noise(field, 0.02, 0.16, dice)
			_noise(field, 0.9, 0.22, dice)
			_strokes(field, 240, 3.0, 14.0, 0.5, true, 1.2, dice)
		Kind.FLECKED:
			_noise(field, 0.02, 0.16, dice)
			_noise(field, 0.9, 0.22, dice)
			_strokes(field, 160, 3.0, 12.0, 0.45, true, 1.2, dice)
			_flecks(field, 70, dice)
		Kind.GRAIN:
			_noise(field, 0.7, 0.7, dice)
			_noise(field, 0.05, 0.25, dice)
		Kind.SCRATCHED:
			_noise(field, 0.7, 0.25, dice)
			_strokes(field, 18, 14.0, 80.0, 0.55, false, 0.08, dice)
			_strokes(field, 90, 3.0, 12.0, 0.4, false, 0.5, dice)
		Kind.FELT:
			_noise(field, 0.25, 0.35, dice)
			_strokes(field, 900, 2.0, 6.0, 0.45, true, 3.0, dice)
		Kind.BRUSHED:
			_brushed(field, dice)
		Kind.LINEN:
			_linen(field, dice)
	# Every column and every row evened out to nothing on the whole: one a shade lighter or darker
	# than the rest is a line clean across the screen once the tile repeats down it. Brushed metal
	# keeps its rows, which are the streaks it is brushed in.
	_even_out(field, kind != Kind.BRUSHED)
	# Paper darkens toward a warm brown, the way fibers and flecks in cream stock do; the rest
	# toward black.
	var dark := Color(0.42, 0.33, 0.2) if kind in [Kind.PAPER, Kind.FLECKED] else Color.BLACK
	_tiles[kind] = ImageTexture.create_from_image(_image(field, dark))
	return _tiles[kind]


## Seamless noise at [param frequency] added into [param field], [param weight] at its strongest.
static func _noise(
	field: PackedFloat32Array, frequency: float, weight: float, dice: RandomNumberGenerator
) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = dice.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = 2
	var image := noise.get_seamless_image(TILE, TILE, false, false, 0.1, true)
	var bytes := image.get_data()
	for i: int in field.size():
		field[i] += (float(bytes[i]) / 127.5 - 1.0) * weight


## [param count] fine strokes from [param shortest] to [param longest] long, lighter or darker by
## up to [param weight]; [param both] lets them darken as well as lighten, and [param bend] is how
## much each curls along its length. Wrapped round the tile's edges, so it stays seamless.
static func _strokes(
	field: PackedFloat32Array,
	count: int,
	shortest: float,
	longest: float,
	weight: float,
	both: bool,
	bend: float,
	dice: RandomNumberGenerator
) -> void:
	for _i: int in count:
		var at := Vector2(dice.randf() * TILE, dice.randf() * TILE)
		var heading := dice.randf() * TAU
		var length := dice.randf_range(shortest, longest)
		var ink := dice.randf_range(0.35, 1.0) * weight
		if both and dice.randf() < 0.5:
			ink = -ink
		var turn := dice.randf_range(-bend, bend) / length
		var walked := 0.0
		while walked < length:
			# Strongest along the middle of the stroke, fading out at both its ends.
			var fade := sin(walked / length * PI)
			_splat(field, at, ink * fade)
			at += Vector2.from_angle(heading) * 0.5
			heading += turn * 0.5
			walked += 0.5


## Small dark flecks, a pixel or two across, the way recycled stock has them.
static func _flecks(field: PackedFloat32Array, count: int, dice: RandomNumberGenerator) -> void:
	for _i: int in count:
		var at := Vector2(dice.randf() * TILE, dice.randf() * TILE)
		var ink := -dice.randf_range(0.6, 1.4)
		_splat(field, at, ink)
		if dice.randf() < 0.5:
			_splat(
				field, at + Vector2(dice.randf_range(-1.0, 1.0), dice.randf_range(-1.0, 1.0)), ink
			)


## Metal brushed one way: each row a streak of its own, lighter or darker, varying slowly along
## its length with waves that fit the tile, so it repeats without a seam either way.
static func _brushed(field: PackedFloat32Array, dice: RandomNumberGenerator) -> void:
	var rows := PackedFloat32Array()
	rows.resize(TILE)
	for y: int in TILE:
		rows[y] = dice.randfn(0.0, 0.5)
	for y: int in TILE:
		var row := rows[y] * 0.6 + (rows[(y + 1) % TILE] + rows[(y + TILE - 1) % TILE]) * 0.2
		var waves: Array[Vector2] = []
		for k: int in 3:
			waves.append(Vector2(dice.randi_range(1, 4), dice.randf() * TAU))
		for x: int in TILE:
			var along := 0.0
			for wave: Vector2 in waves:
				along += sin(TAU * wave.x * float(x) / TILE + wave.y)
			field[y * TILE + x] += row * (0.75 + along * 0.12)
	_noise(field, 0.8, 0.12, dice)


## A playing card's linen finish: a fine weave of crossing ridges pressed into the stock, a little
## uneven so it reads as cloth rather than a grid.
static func _linen(field: PackedFloat32Array, dice: RandomNumberGenerator) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = dice.randi()
	noise.frequency = 0.08
	var image := noise.get_seamless_image(TILE, TILE, false, false, 0.1, true)
	var bytes := image.get_data()
	for y: int in TILE:
		for x: int in TILE:
			var i := y * TILE + x
			var wobble := float(bytes[i]) / 255.0
			var warp := sin(TAU * float(x) / 4.0 + wobble * 1.5)
			var weft := sin(TAU * float(y) / 4.0 + wobble * 2.5)
			field[i] += (warp * 0.5 + weft * 0.5) * (0.55 + wobble * 0.45)
	_noise(field, 0.6, 0.2, dice)


## Takes each column's own average out of [param field], and each row's with [param rows].
static func _even_out(field: PackedFloat32Array, rows: bool) -> void:
	for x: int in TILE:
		var sum := 0.0
		for y: int in TILE:
			sum += field[y * TILE + x]
		var mean := sum / TILE
		for y: int in TILE:
			field[y * TILE + x] -= mean
	if not rows:
		return
	for y: int in TILE:
		var sum := 0.0
		for x: int in TILE:
			sum += field[y * TILE + x]
		var mean := sum / TILE
		for x: int in TILE:
			field[y * TILE + x] -= mean


## Spreads [param ink] over the four pixels round [param at], wrapping round the tile.
static func _splat(field: PackedFloat32Array, at: Vector2, ink: float) -> void:
	var x0 := floori(at.x)
	var y0 := floori(at.y)
	var fx := at.x - float(x0)
	var fy := at.y - float(y0)
	for dy: int in 2:
		for dx: int in 2:
			var share := (fx if dx == 1 else 1.0 - fx) * (fy if dy == 1 else 1.0 - fy)
			var i := posmod(y0 + dy, TILE) * TILE + posmod(x0 + dx, TILE)
			field[i] += ink * share


## The tile as an image: white where [param field] lightens, [param dark] where it darkens, and as
## clear as it is near nothing.
static func _image(field: PackedFloat32Array, dark: Color) -> Image:
	var bytes := PackedByteArray()
	bytes.resize(TILE * TILE * 4)
	var low := PackedByteArray([dark.r8, dark.g8, dark.b8])
	for i: int in field.size():
		var value := clampf(field[i], -1.0, 1.0)
		var at := i * 4
		for channel: int in 3:
			bytes[at + channel] = 255 if value > 0.0 else low[channel]
		bytes[at + 3] = roundi(absf(value) * 255.0)
	return Image.create_from_data(TILE, TILE, false, Image.FORMAT_RGBA8, bytes)
