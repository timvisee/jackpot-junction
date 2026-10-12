class_name HouseArt
extends RefCounted
## The small pictures the house's controls wear, GAME.md 8.1a: a switch, the mark beside an entry
## of a list, the arrow on a box that opens one, the knob of a slider, and the icons on buttons
## that say what they do without words: a magnifying glass, a cross, two arrows turning. Anything
## round is a chip, with notches round its rim, and a track is a lane with its center line dashed.
##
## Each is drawn once, the first time it is asked for, [constant DETAIL] times bigger than it is
## shown and with soft edges, so a screen that scales the menu up has something to scale up: a
## switch drawn at its own size is a staircase round every curve on a big display.

## How many times bigger than shown everything here is drawn.
const DETAIL := 4
## How big a switch, a mark, an arrow and a knob are shown, in pixels.
const SWITCH := Vector2i(48, 24)
const MARK := 16
const ARROW := 16
const KNOB := 26
const MAGNIFIER := 30
const ICON := 28
## The red of a map pin's head, as [constant LoyaltyArt.PIN_RED]: named here rather than through
## it, which would load the loyalty program's art with every icon, and the program loads these.
const PIN_RED := Color(0.86, 0.2, 0.18)
## The steel a chip is made of when it is not the house's gold, and the cream of its notches.
const STEEL := Color(0.37, 0.36, 0.42)
const NOTCHES := Color(0.97, 0.95, 0.9)

static var _drawn: Dictionary[String, ImageTexture] = {}


## A switch: a lane with a chip in it, at the near end and steel when it is off, at the far end and
## gold, in a lane lit gold, when it is on.
static func switch(on: bool) -> ImageTexture:
	var key := "switch_%s" % on
	if _drawn.has(key):
		return _drawn[key]
	var wide := SWITCH.x * DETAIL
	var high := SWITCH.y * DETAIL
	var image := Image.create(wide, high, true, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var radius := float(high) * 0.5
	var foil := HouseTheme.FOIL
	var track := foil.darkened(0.55) if on else Color(0.05, 0.05, 0.07)
	var rim := foil if on else Color(0.52, 0.51, 0.57)
	var dash := Color(foil, 0.6) if on else Color(1.0, 1.0, 1.0, 0.24)
	var dash_long := 6.0 * DETAIL
	var dash_gap := 5.0 * DETAIL
	for y: int in high:
		for x: int in wide:
			var at := Vector2(float(x) + 0.5, float(y) + 0.5)
			var spine := Vector2(clampf(at.x, radius, float(wide) - radius), radius)
			# How far inside the track's own edge this pixel is, which is also how much of it is
			# covered: half a pixel either side of the edge is the whole of the softness.
			var inside := radius - at.distance_to(spine)
			var covered := clampf(inside + 0.5, 0.0, 1.0)
			if covered <= 0.0:
				continue
			var ink := track.lerp(rim, clampf(1.4 * DETAIL - inside, 0.0, 1.0))
			# The lane's center line, dashed, between the two round ends.
			var along := at.x - radius * 0.6
			var on_dash := fposmod(along, dash_long + dash_gap) < dash_long
			if (
				on_dash
				and absf(at.y - radius) < DETAIL
				and along > 0.0
				and at.x < wide - radius * 0.6
			):
				ink = ink.blend(dash)
			image.set_pixel(x, y, Color(ink, covered))
	var knob := Vector2(float(wide) - radius if on else radius, radius)
	_chip(image, knob, radius - 2.5 * DETAIL, foil if on else STEEL, 6)
	image.generate_mipmaps()
	return _keep(key, image, Vector2i.ZERO)


## The mark beside an entry of a list: a gold chip on the one picked, a faint ring round each of
## the others so the list reads as a choice of one.
static func mark(on: bool) -> ImageTexture:
	var key := "mark_%s" % on
	if _drawn.has(key):
		return _drawn[key]
	var side := MARK * DETAIL
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var middle := Vector2(side, side) * 0.5
	var radius := float(side) * 0.5 - 1.0
	if on:
		_chip(image, middle, radius, HouseTheme.FOIL, 6)
	else:
		var ring := 1.5 * DETAIL
		for y: int in side:
			for x: int in side:
				var inside := radius - (Vector2(x, y) + Vector2.ONE * 0.5).distance_to(middle)
				var covered := clampf(inside + 0.5, 0.0, 1.0)
				covered *= clampf(ring - inside + 0.5, 0.0, 1.0) * 0.35
				if covered > 0.0:
					image.set_pixel(x, y, Color(0.86, 0.86, 0.92, covered))
	return _keep(key, image, Vector2i(MARK, MARK))


## The arrow on a box that opens a list: a chevron pointing down, in foil.
static func arrow() -> ImageTexture:
	if _drawn.has("arrow"):
		return _drawn["arrow"]
	var side := ARROW * DETAIL
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var s := float(side)
	var stroke := [Vector2(0.18, 0.36) * s, Vector2(0.5, 0.66) * s, Vector2(0.82, 0.36) * s]
	var half := 0.075 * s
	for y: int in side:
		for x: int in side:
			var at := Vector2(x, y) + Vector2.ONE * 0.5
			var near := minf(
				at.distance_to(Geometry2D.get_closest_point_to_segment(at, stroke[0], stroke[1])),
				at.distance_to(Geometry2D.get_closest_point_to_segment(at, stroke[1], stroke[2]))
			)
			var covered := clampf(half - near + 0.5, 0.0, 1.0)
			if covered > 0.0:
				image.set_pixel(x, y, Color(HouseTheme.FOIL, covered))
	return _keep("arrow", image, Vector2i(ARROW, ARROW))


## A magnifying glass, for a button that looks closer: a ring for its lens, a faint glint in it,
## and its handle down to the right. White, for the button to tint as it tints its words.
static func magnifier() -> ImageTexture:
	if _drawn.has("magnifier"):
		return _drawn["magnifier"]
	var side := MAGNIFIER * DETAIL
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var s := float(side)
	var lens := Vector2(0.42, 0.42) * s
	var radius := 0.27 * s
	var rim := 0.055 * s
	var handle := [lens + Vector2.ONE * (radius + rim) * 0.7, Vector2(0.88, 0.88) * s]
	var grip := 0.085 * s
	for y: int in side:
		for x: int in side:
			var at := Vector2(x, y) + Vector2.ONE * 0.5
			var from_lens := at.distance_to(lens)
			var ring := clampf(rim - absf(from_lens - radius) + 0.5, 0.0, 1.0)
			var near := at.distance_to(
				Geometry2D.get_closest_point_to_segment(at, handle[0], handle[1])
			)
			var held := clampf(grip - near + 0.5, 0.0, 1.0)
			# The glint: a short bright arc inside the lens, up on the left.
			var glint := 0.0
			var way := (at - lens).angle()
			if way > -PI * 0.92 and way < -PI * 0.62:
				glint = clampf(0.03 * s - absf(from_lens - radius * 0.68) + 0.5, 0.0, 1.0) * 0.7
			var covered := maxf(maxf(ring, held), glint)
			if covered > 0.0:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, covered))
	return _keep("magnifier", image, Vector2i(MAGNIFIER, MAGNIFIER))


## A cross, for a button that puts something away. White, for the button to tint.
static func cross() -> ImageTexture:
	if _drawn.has("cross"):
		return _drawn["cross"]
	var side := ICON * DETAIL
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var s := float(side)
	var strokes := [
		[Vector2(0.24, 0.24) * s, Vector2(0.76, 0.76) * s],
		[Vector2(0.76, 0.24) * s, Vector2(0.24, 0.76) * s],
	]
	var half := 0.07 * s
	for y: int in side:
		for x: int in side:
			var at := Vector2(x, y) + Vector2.ONE * 0.5
			var near := INF
			for stroke: Array in strokes:
				var on := Geometry2D.get_closest_point_to_segment(at, stroke[0], stroke[1])
				near = minf(near, at.distance_to(on))
			var covered := clampf(half - near + 0.5, 0.0, 1.0)
			if covered > 0.0:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, covered))
	return _keep("cross", image, Vector2i(ICON, ICON))


## A map pin standing a little aslant, for the button that pins a bet of the loyalty program,
## GAME.md 8.9: a steel needle under a red head with a gleam on it, as the map's own pins are drawn,
## see [method LoyaltyArt.draw_pin]. In its own colors, which the house's white icon tint leaves be.
static func pin() -> ImageTexture:
	if _drawn.has("pin"):
		return _drawn["pin"]
	var side := ICON * DETAIL
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var s := float(side)
	var tip := Vector2(0.34, 0.9) * s
	var head := Vector2(0.6, 0.34) * s
	var radius := 0.24 * s
	var needle := 0.045 * s
	var gleam := head - Vector2(0.08, 0.08) * s
	var steel := Color(0.72, 0.73, 0.78)
	for y: int in side:
		for x: int in side:
			var at := Vector2(x, y) + Vector2.ONE * 0.5
			var on := Geometry2D.get_closest_point_to_segment(at, tip, head)
			var ink := Color(steel, clampf(needle - at.distance_to(on) + 0.5, 0.0, 1.0))
			var disc := clampf(radius - at.distance_to(head) + 0.5, 0.0, 1.0)
			if disc > 0.0:
				var red := PIN_RED
				var shine := clampf(0.07 * s - at.distance_to(gleam) + 0.5, 0.0, 1.0)
				red = red.lerp(Color(1.0, 0.85, 0.82), shine * 0.8)
				ink = Color(red.lerp(ink, ink.a * (1.0 - disc)), maxf(ink.a, disc))
			if ink.a > 0.0:
				image.set_pixel(x, y, ink)
	return _keep("pin", image, Vector2i(ICON, ICON))


## Two arrows chasing each other round a circle, for a button that turns something over. White, for
## the button to tint.
static func turning() -> ImageTexture:
	if _drawn.has("turning"):
		return _drawn["turning"]
	var side := ICON * DETAIL
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var s := float(side)
	var middle := Vector2.ONE * s * 0.5
	var radius := 0.3 * s
	var half := 0.055 * s
	# Each arrow: an arc over the top or under the bottom, clockwise, its head at the end.
	var arcs := [[deg_to_rad(-165.0), deg_to_rad(-30.0)], [deg_to_rad(15.0), deg_to_rad(150.0)]]
	var heads: Array[PackedVector2Array] = []
	for arc: Array in arcs:
		var end: float = arc[1]
		var at := middle + Vector2.from_angle(end) * radius
		var along := Vector2.from_angle(end + PI * 0.5)
		var out := Vector2.from_angle(end)
		heads.append(
			PackedVector2Array(
				[at + along * 0.16 * s, at + out * 0.13 * s, at - out * 0.13 * s - along * 0.01 * s]
			)
		)
	for y: int in side:
		for x: int in side:
			var at := Vector2(x, y) + Vector2.ONE * 0.5
			var covered := 0.0
			var way := (at - middle).angle()
			for arc: Array in arcs:
				if way >= arc[0] and way <= arc[1]:
					var off := absf(at.distance_to(middle) - radius)
					covered = maxf(covered, clampf(half - off + 0.5, 0.0, 1.0))
			for head: PackedVector2Array in heads:
				covered = maxf(covered, _inside(at, head))
			if covered > 0.0:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, covered))
	return _keep("turning", image, Vector2i(ICON, ICON))


## How much of the pixel at [param at] a triangle covers, soft over its last pixel: the least of how
## far inside each of its edges it is.
static func _inside(at: Vector2, triangle: PackedVector2Array) -> float:
	var clockwise := (triangle[1] - triangle[0]).cross(triangle[2] - triangle[0]) > 0.0
	var least := INF
	for i: int in 3:
		var from := triangle[i]
		var to := triangle[(i + 1) % 3]
		var edge := (to - from).normalized()
		var inward := Vector2(-edge.y, edge.x) if clockwise else Vector2(edge.y, -edge.x)
		least = minf(least, (at - from).dot(inward))
	return clampf(least + 0.5, 0.0, 1.0)


## The knob of a slider: a gold chip, a shade lighter under the cursor.
static func knob(lit: bool) -> ImageTexture:
	var key := "knob_%s" % lit
	if _drawn.has(key):
		return _drawn[key]
	var side := KNOB * DETAIL
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var face := HouseTheme.FOIL_HIGH if lit else HouseTheme.FOIL
	_chip(image, Vector2(side, side) * 0.5, float(side) * 0.5 - 1.0, face, 8)
	return _keep(key, image, Vector2i(KNOB, KNOB))


## A chip of [param radius] about [param middle] laid over what is already in [param image]: a
## disc of [param face] with [param notches] cream notches cut round its rim and a darker ring
## inside them, the way a poker chip's edge reads at any size.
static func _chip(image: Image, middle: Vector2, radius: float, face: Color, notches: int) -> void:
	var step := TAU / float(notches)
	var ring := face.darkened(0.22)
	var from := Vector2i(maxi(int(middle.x - radius) - 1, 0), maxi(int(middle.y - radius) - 1, 0))
	var to := Vector2i(
		mini(int(middle.x + radius) + 2, image.get_width()),
		mini(int(middle.y + radius) + 2, image.get_height())
	)
	for y: int in range(from.y, to.y):
		for x: int in range(from.x, to.x):
			var at := Vector2(float(x) + 0.5, float(y) + 0.5) - middle
			var far := at.length()
			var covered := clampf(radius - far + 0.5, 0.0, 1.0)
			if covered <= 0.0:
				continue
			var ink := face
			var band := radius * 0.035 + 0.5
			ink = ink.lerp(ring, clampf(1.0 - absf(far - radius * 0.64) / band, 0.0, 1.0) * 0.8)
			if far > radius * 0.72:
				var off := absf(wrapf(at.angle(), -step * 0.5, step * 0.5)) * far
				ink = ink.lerp(NOTCHES, clampf(radius * 0.15 - off + 0.5, 0.0, 1.0))
			var under := image.get_pixel(x, y)
			image.set_pixel(x, y, under.blend(Color(ink, covered)))


static func _keep(key: String, image: Image, shown: Vector2i) -> ImageTexture:
	var drawn := ImageTexture.create_from_image(image)
	if shown != Vector2i.ZERO:
		drawn.set_size_override(shown)
	_drawn[key] = drawn
	return drawn
