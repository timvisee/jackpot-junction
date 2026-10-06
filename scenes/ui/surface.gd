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
static func pieces(edge: PackedVector2Array, size: Vector2, tile: float) -> Array[Dictionary]:
	var made: Array[Dictionary] = []
	for row: int in ceili(size.y / tile):
		for column: int in ceili(size.x / tile):
			var corner := Vector2(column, row) * tile
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
## The shape's pieces are kept in [param kept], the shape's own worked-out dictionary, and worked
## out again only when the screen's scale has moved.
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
	if kept.get(&"surface_at", 0.0) != at:
		kept[&"surface_pieces"] = pieces(edge, size, float(TILE) / at)
		kept[&"surface_at"] = at
	var made: Array[Dictionary] = kept[&"surface_pieces"]
	var texture := tile_of(kind).get_rid()
	var ink := PackedColorArray([Color(1.0, 1.0, 1.0, strength)])
	for piece: Dictionary in made:
		RenderingServer.canvas_item_add_polygon(item, piece[&"points"], ink, piece[&"uvs"], texture)


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


## Trying them out: which kind [param part] wears and how strongly, from JJ_SURFACE, written as
## "pane=scratched@0.1,slip=paper@0.2,light=0.05"; [param kind] at [param strength] where it is not
## named.
static func chosen(part: String, kind: Kind, strength: float) -> Vector2:
	for each: String in OS.get_environment("JJ_SURFACE").split(",", false):
		var said := each.split("=")
		if said.size() != 2 or said[0].strip_edges() != part:
			continue
		var how := said[1].split("@")
		var picked := named(how[0]) if not how[0].is_valid_float() else Kind.NONE
		var much := float(how[1]) if how.size() > 1 else strength
		if how[0].is_valid_float():
			return Vector2(Kind.NONE, float(how[0]))
		return Vector2(picked, much)
	return Vector2(kind, strength)


## Puts on [param style], a [TicketStyle] or a [StripStyle], what [param part] wears, see
## [method chosen], and the light [param part]_light names.
static func wear(style: StyleBox, part: String) -> void:
	var picked := chosen(part, Kind.NONE, 0.0)
	style.set(&"surface", int(picked.x))
	style.set(&"surface_ink", picked.y)
	style.set(&"light", chosen(part + "_light", Kind.NONE, 0.0).y)


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
			_strokes(field, 30, 14.0, 90.0, 0.8, false, 0.08, dice)
			_strokes(field, 120, 3.0, 12.0, 0.55, false, 0.5, dice)
		Kind.FELT:
			_noise(field, 0.25, 0.35, dice)
			_strokes(field, 900, 2.0, 6.0, 0.45, true, 3.0, dice)
		Kind.BRUSHED:
			_brushed(field, dice)
		Kind.LINEN:
			_linen(field, dice)
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
