class_name LeatherArt
extends RefCounted
## The padded rail round a card table's felt, GAME.md 8.10: a cushion of brown leather with rounded
## corners, its pebbled grain catching the light along the top of its crown, top-stitched in gold
## along both its edges, and its shadow on the felt inside it. The cushion is one mesh, shaded at
## its points and laid out again only as the rail is, so it costs a few draws however big it is.

## The leather, the light its sheen catches, the thread, and where the light comes from.
const HIDE := Color("#5a3322")
const SHEEN := Color("#d9b496")
const THREAD := Color(0.76, 0.58, 0.27, 0.9)
const LIGHT := Vector2(-0.45, -1.0)
## How round the rail's outer corners are, as a share of how wide it is, and how many rings of
## points run along it, outer edge to inner.
const ROUND := 1.4
const ACROSS := 10
## How far in from each of its edges the stitching runs, as a share of how wide it is, and its
## stitches and the gaps between them.
const STITCH_IN := 0.16
const STITCH := 6.0
const STITCH_GAP := 4.0
## How big the pebbled grain's tile is, and how deep its creases go.
const PEBBLE_TILE := 128
const PEBBLE_DEPTH := 0.3
## How far the rail's shadow reaches onto the felt, and how dark it is at the rail.
const SHADOW := 10
const SHADOW_DARK := 0.4
## How far the rail's own shadow reaches out round it, and how far down it falls.
const CAST := 8
const CAST_DOWN := 3.0

static var _pebbles: Texture2D


## The leather's pebbled grain, a seamless tile: cells, with the creases between them darker.
static func pebbles() -> Texture2D:
	if _pebbles == null:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_CELLULAR
		noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
		noise.frequency = 0.16
		noise.seed = 5
		var image := noise.get_seamless_image(PEBBLE_TILE, PEBBLE_TILE)
		image.convert(Image.FORMAT_L8)
		var data := image.get_data()
		for i: int in data.size():
			data[i] = int(255.0 * (1.0 - PEBBLE_DEPTH + PEBBLE_DEPTH * data[i] / 255.0))
		_pebbles = ImageTexture.create_from_image(
			Image.create_from_data(PEBBLE_TILE, PEBBLE_TILE, false, Image.FORMAT_L8, data)
		)
	return _pebbles


## The rail round the inside of [param rect] on [param on], [param wide] across: the felt inside it
## is the caller's, drawn first under its middle, as its square corners are hidden under the rail's
## round ones. [param on] needs its texture repeat on, for the grain to run the rail's whole length.
## The cushion's mesh is returned, to be kept for as long as it is drawn: the canvas holds only its
## name, and a mesh nobody keeps is gone, with the rail, by the next frame. [param square_out] makes
## its outside square, rounding toward its inside, for a rail cut by the screen's edges: a round
## outside would show its edge and its outer stitching in the screen's corners.
static func rail(on: CanvasItem, rect: Rect2, wide: float, square_out := false) -> ArrayMesh:
	# Its shadow round it, fallen a little down, on whatever the pane is over.
	for i: int in CAST:
		var ink := Color(0.0, 0.0, 0.0, 0.3 * (1.0 - float(i) / CAST))
		var ring := FeltArt.rounded(rect.grow(i + 0.5), _round_at(wide, 0.0, square_out) + i)
		ring.append(ring[0])
		for j: int in ring.size():
			ring[j].y += CAST_DOWN
		on.draw_polyline(ring, ink, 1.0)
	# Its shadow on the felt, darkest at the rail, and the seam where the two meet.
	for i: int in SHADOW:
		var ink := Color(0.0, 0.0, 0.0, SHADOW_DARK * (1.0 - float(i) / SHADOW))
		var ring := FeltArt.rounded(
			rect.grow(-wide - i - 0.5), maxf(_round_at(wide, 1.0, square_out) - i, 0.0)
		)
		ring.append(ring[0])
		on.draw_polyline(ring, ink, 1.0)
	var mesh := cushion(rect, wide, square_out)
	on.draw_mesh(mesh, pebbles())
	for share: float in [STITCH_IN, 1.0 - STITCH_IN]:
		var seam := FeltArt.rounded(rect.grow(-wide * share), _round_at(wide, share, square_out))
		var stitches := dashes(seam, STITCH, STITCH_GAP)
		var holes := PackedVector2Array()
		for point: Vector2 in stitches:
			holes.append(point + Vector2(0.5, 1.0))
		on.draw_multiline(holes, Color(0.0, 0.0, 0.0, 0.6), 1.5)
		on.draw_multiline(stitches, THREAD, 1.5)
	return mesh


## The cushion as one mesh of rings, outer edge to inner: each point shaded as a padded roll is
## lit, the half facing the light lighter, a sheen along the crown on the sides facing it, the
## grain's tile laid on it flat.
static func cushion(rect: Rect2, wide: float, square_out := false) -> ArrayMesh:
	var light := LIGHT.normalized()
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var around := 0
	for ring: int in ACROSS + 1:
		var t := float(ring) / ACROSS
		var inset := wide * t
		var line := FeltArt.rounded(rect.grow(-inset), _round_at(wide, t, square_out))
		around = line.size()
		for i: int in around:
			var facing := Vector2.from_angle(FeltArt.facing(i))
			var normal := facing * cos(PI * t) * 0.85
			var lit := 0.5 + 0.5 * normal.dot(light)
			var height := sin(PI * t)
			var shade := lerpf(0.4, 1.1, lit) * (0.5 + 0.5 * height)
			var sheen := (
				exp(-pow((t - 0.34) / 0.12, 2.0)) * maxf(facing.dot(light), 0.0) * 0.5
				+ exp(-pow((t - 0.45) / 0.22, 2.0)) * 0.1
			)
			points.append(line[i])
			colors.append(
				Color(
					HIDE.r * shade + SHEEN.r * sheen,
					HIDE.g * shade + SHEEN.g * sheen,
					HIDE.b * shade + SHEEN.b * sheen
				)
			)
			uvs.append(line[i] / PEBBLE_TILE)
	var indices := PackedInt32Array()
	for ring: int in ACROSS:
		for i: int in around:
			var a := ring * around + i
			var b := ring * around + (i + 1) % around
			indices.append_array([a, b, b + around, a, b + around, a + around])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## How round the rail's corners are [param t] of the way across it, outer edge to inner, on a rail
## [param wide] across: rings round one middle, or with [param square_out] square at its outer edge
## and as round as ever at its inner.
static func _round_at(wide: float, t: float, square_out: bool) -> float:
	var inner := wide * (ROUND - 1.0)
	return lerpf(0.0 if square_out else wide * ROUND, inner, t)


## Stitches along the closed [param line], [param long] each with [param gap] between them, as the
## pairs of points [method CanvasItem.draw_multiline] draws.
static func dashes(line: PackedVector2Array, long: float, gap: float) -> PackedVector2Array:
	var stitches := PackedVector2Array()
	var stitching := true
	var left := long
	for i: int in line.size():
		var from := line[i]
		var to := line[(i + 1) % line.size()]
		var length := from.distance_to(to)
		var along := 0.0
		while along < length:
			var step := minf(left, length - along)
			if stitching:
				stitches.append(from.lerp(to, along / length))
				stitches.append(from.lerp(to, (along + step) / length))
			along += step
			left -= step
			if left <= 0.0:
				stitching = not stitching
				left = long if stitching else gap
	return stitches
