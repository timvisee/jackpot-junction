class_name FeltArt
extends RefCounted
## The green felt the achievements are kept on, GAME.md 8.10: a card table's cloth rather than a
## flat green, its nap mottled lighter and darker in soft patches, a fine grain over that, and short
## fibers lying every which way; stitched round inside its edge with brass over its corners. Drawn
## from two seamless noise textures made once a run and a scatter of fibers the same every time, so
## it costs a few draws however big it is, and only as it is laid out again.

## The felt, the stitching round it, and its brass corners.
const CLOTH := Palette.FELT
const STITCH := Color(0.62, 0.78, 0.66, 0.45)
const BRASS := HouseTheme.FOIL_LOW
## How big the noise textures are, tiled over the cloth, and how strongly each shows: the patches
## darker, the grain lighter.
const TILE := 256
const PATCHES := 0.32
const GRAIN := 0.14
## How many fibers a square of cloth this many pixels on a side has, and how long they are.
const FIBER_SQUARE := 34.0
const FIBER_SHORTEST := 2.0
const FIBER_LONGEST := 6.0

static var _patches: Texture2D
static var _grain: Texture2D


## The soft patches of the nap, a seamless tile.
static func patches() -> Texture2D:
	if _patches == null:
		_patches = _noise(0.012, 3, 7)
	return _patches


## The fine grain over it, a seamless tile.
static func grain() -> Texture2D:
	if _grain == null:
		_grain = _noise(0.45, 1, 23)
	return _grain


static func _noise(frequency: float, octaves: int, seed_of: int) -> Texture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.seed = seed_of
	return ImageTexture.create_from_image(noise.get_seamless_image(TILE, TILE))


## Cloth of [param cloth] over [param rect] on [param on]: its nap, its grain and its fibers.
static func cloth(on: CanvasItem, rect: Rect2, cloth_ink: Color, seed_of := 1) -> void:
	on.draw_rect(rect, cloth_ink)
	on.draw_texture_rect(patches(), rect, true, Color(cloth_ink.darkened(0.55), PATCHES))
	on.draw_texture_rect(grain(), rect, true, Color(cloth_ink.lightened(0.45), GRAIN))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_of
	var fibers := int(rect.size.x * rect.size.y / (FIBER_SQUARE * FIBER_SQUARE))
	var light := PackedVector2Array()
	var dark := PackedVector2Array()
	for i: int in fibers:
		var at := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		var way := (
			Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(FIBER_SHORTEST, FIBER_LONGEST)
		)
		var into := light if i % 3 != 0 else dark
		into.append(at)
		into.append(at + way)
	on.draw_multiline(light, Color(cloth_ink.lightened(0.5), 0.18), 1.0)
	on.draw_multiline(dark, Color(cloth_ink.darkened(0.6), 0.22), 1.0)


## A seam stitched [param inset] in from [param rect]'s edge.
static func stitching(on: CanvasItem, rect: Rect2, inset: float) -> void:
	var seam := rect.grow(-inset)
	var corners := [
		seam.position,
		Vector2(seam.end.x, seam.position.y),
		seam.end,
		Vector2(seam.position.x, seam.end.y),
	]
	for i: int in 4:
		on.draw_dashed_line(corners[i], corners[(i + 1) % 4], STITCH, 1.5, 6.0)


## Brass over [param rect]'s four corners, [param reach] along each edge, a screw in each.
static func corners(on: CanvasItem, rect: Rect2, reach: float) -> void:
	for corner: Vector2 in [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]:
		var inward := Vector2(
			1.0 if corner.x <= rect.position.x else -1.0,
			1.0 if corner.y <= rect.position.y else -1.0
		)
		on.draw_colored_polygon(
			PackedVector2Array(
				[
					corner,
					corner + Vector2(inward.x * reach, 0.0),
					corner + Vector2(0.0, inward.y * reach)
				]
			),
			BRASS
		)
		on.draw_circle(corner + inward * reach * 0.28, 2.0, HouseTheme.ON_FOIL)


## A tray pressed into the cloth: [param rect] a little darker, shaded along its top and left where
## the light does not reach, as the case the rows lie in is.
static func tray(on: CanvasItem, rect: Rect2, seed_of := 2) -> void:
	cloth(on, rect, CLOTH.darkened(0.14), seed_of)
	for i: int in 6:
		var shade := Color(0.0, 0.0, 0.0, 0.16 - i * 0.025)
		on.draw_line(
			rect.position + Vector2(0.0, i + 0.5),
			Vector2(rect.end.x, rect.position.y + i + 0.5),
			shade
		)
		on.draw_line(
			rect.position + Vector2(i + 0.5, 0.0),
			Vector2(rect.position.x + i + 0.5, rect.end.y),
			shade
		)
