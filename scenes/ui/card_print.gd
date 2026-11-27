class_name CardPrint
extends RefCounted
## The fine print on the face of a joker's card and a power-up's, GAME.md 8.3: what the House prints
## under the picture and the words. Along the top a halftone screen of the card's ink, its lower
## edge an arch, highest in the middle; round the picture a guilloche rosette, as a banknote is
## engraved; the foot a stub torn off along a perforation, a shade of the ink on it and waves across
## it. A rare joker's screen drifts from its ink into magenta and on into cyan, a split fountain; a
## cursed one's has a crimson plate slipped under it, out of register. A power-up's stub is solid in
## its color, and its screen rises from the stub instead, a smaller arch the other way up that
## stays clear of the rosette.
##
## Drawn as an SVG on the card's own 120 by 168 units and rasterized once for a look and a size,
## then kept. A card shown small sheds the fine lines in steps, see [enum Level], as a picture under
## 40 pixels drops its shading, so it never blurs to a smudge.

## How much is printed: all of it from [constant FULL_FROM] pixels across; then without the
## rosette and the waves, the screen coarser and the perforation's holes fewer; and under
## [constant PLAIN_FROM] the screen as one flat shape of the same curve, with no holes.
enum Level { FULL, PLAIN, FLAT }

const FULL_FROM := 100.0
const PLAIN_FROM := 64.0
## The card's units, the stub's top, and the bite out of either side of it.
const WIDE := 120.0
const TALL := 168.0
const STUB := 124.0
const BITE := 6.5
## The card's dark, as its stock is, and the dark of the holes punched through it.
const STOCK := Color(0.11, 0.11, 0.14)
const HOLE := Color("#0c0b10")
## The second and third inks of a rare card's split fountain, and how far its ink drifts into them.
const MAGENTA := Color("#FF4FA3")
const CYAN := Color("#35D0FF")
const FOUNTAIN := 0.65
## A cursed card's slipped plate: its crimson, how far it slips, and how strongly it prints.
const CRIMSON := Color("#8c1c2c")
const SLIP := Vector2(1.2, 1.0)
const SLIPPED := 0.75
## How tall a power-up's screen rises from its stub, as a share of a joker's arch.
const RISE := 0.34
## How many looks are kept before the oldest go.
const KEPT := 160

## The middle of the rosette, and the radius inside which a power-up's screen does not print.
const ROSETTE := Vector2(60.0, 71.0)
const ROSETTE_CLEAR := 50.0

static var _kept := {}
## The shapes, the same on every card: worked out once, then wrapped in a card's inks.
static var _shapes := {}


## The level a card [param pixels] across is printed at.
static func level_of(pixels: float) -> Level:
	if pixels >= FULL_FROM:
		return Level.FULL
	if pixels >= PLAIN_FROM:
		return Level.PLAIN
	return Level.FLAT


## The print for a card in [param ink] shown [param pixels] across: a power-up's for [param item],
## a rare joker's or a cursed one's as [param rare] and [param cursed] say.
static func texture(
	ink: Color, pixels: float, item := false, rare := false, cursed := false
) -> Texture2D:
	var side := IconPress.step(pixels)
	var level := level_of(pixels)
	var key := (
		"%s|%d|%d|%d|%d|%d" % [ink.to_html(false), int(item), int(rare), int(cursed), level, side]
	)
	var kept: Texture2D = _kept.get(key)
	if kept != null:
		return kept
	var image := Image.new()
	var svg := svg_of(ink, level, item, rare, cursed)
	if image.load_svg_from_string(svg, side / WIDE) != OK:
		return null
	var printed := ImageTexture.create_from_image(image)
	if _kept.size() >= KEPT:
		_kept.erase(_kept.keys()[0])
	_kept[key] = printed
	return printed


## The arch the screen's lower edge follows: how far down it reaches at [param x], deepest at the
## card's sides.
static func arch(x: float) -> float:
	return 24.0 + 24.0 * (1.0 - sin(PI * x / WIDE))


## The print as SVG, see [method texture].
static func svg_of(ink: Color, level: Level, item: bool, rare: bool, cursed: bool) -> String:
	var hex := "#" + ink.to_html(false)
	var inside := PackedStringArray()
	# The stub: a shade of the ink on a joker's, the ink itself on a power-up's.
	inside.append(_rect(0.0, STUB, WIDE, TALL - STUB, hex, 1.0 if item else 0.07))
	if item:
		inside.append(_rising(hex, level))
	else:
		inside.append(_screen(ink, level, rare, cursed))
	if level == Level.FULL:
		inside.append(_rosette(hex))
		inside.append(_waves(hex))
	var outside := PackedStringArray()
	outside.append(_holes(level, item))
	outside.append(_hairline(hex))
	return (
		(
			'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">'
			+ '<defs><clipPath id="in"><rect x="5" y="5" width="110" height="158" rx="6"/>'
			+ '</clipPath></defs><g clip-path="url(#in)">%s</g>%s</svg>'
		)
		% [WIDE, TALL, WIDE, TALL, "".join(inside), "".join(outside)]
	)


## A joker's screen along the top, its lower edge the arch, whole dots down to a little above it:
## in the ink, a crimson plate slipped under it for a cursed card, and for a rare one each column
## of dots a step further from the ink into magenta and on into cyan.
static func _screen(ink: Color, level: Level, rare: bool, cursed: bool) -> String:
	var hex := "#" + ink.to_html(false)
	if level == Level.FLAT:
		return '<path d="%s" fill="%s" fill-opacity="0.42"/>' % [_flat_screen(), hex]
	var columns := _columns(level)
	var printed := ""
	if cursed:
		printed += (
			'<g transform="translate(%s,%s)" fill="#%s" fill-opacity="%s">%s</g>'
			% [SLIP.x, SLIP.y, CRIMSON.to_html(false), SLIPPED, "".join(columns.values())]
		)
	if not rare:
		return printed + '<g fill="%s" fill-opacity="0.7">%s</g>' % [hex, "".join(columns.values())]
	for x: float in columns:
		var t := x / WIDE
		var color := ink.lerp(MAGENTA, t * 0.9 * FOUNTAIN)
		if t >= 0.5:
			color = ink.lerp(MAGENTA, 0.45 * FOUNTAIN).lerp(CYAN, (t - 0.5) * 1.1 * FOUNTAIN)
		printed += ('<g fill="#%s" fill-opacity="0.7">%s</g>' % [color.to_html(false), columns[x]])
	return printed


## The screen's dots at [param level], column by column: their x to their circles.
static func _columns(level: Level) -> Dictionary:
	var key := "columns|%d" % level
	if _shapes.has(key):
		return _shapes[key]
	var grid := 4.0 if level == Level.FULL else 6.0
	var columns := {}
	var y := 2.0
	var row := 0
	while y < STUB:
		var x := 2.0 + (row % 2) * grid * 0.5
		while x < WIDE:
			var r := grid / 4.0 * 1.6 * clampf((arch(x) - y) / 16.0, 0.0, 1.0)
			if r > 0.2:
				columns[x] = columns.get(x, "") + _circle(x, y, r)
			x += grid
		y += grid
		row += 1
	var sorted := {}
	var xs := columns.keys()
	xs.sort()
	for x: float in xs:
		sorted[x] = columns[x]
	_shapes[key] = sorted
	return sorted


## The screen as one flat shape, for a card too small for its dots.
static func _flat_screen() -> String:
	if not _shapes.has("flat"):
		var shape := "M0,0H120"
		var x := WIDE
		while x >= 0.0:
			shape += "L%.1f,%.1f" % [x, arch(x) - 8.0]
			x -= 2.0
		_shapes["flat"] = shape + "Z"
	return _shapes["flat"]


## A power-up's screen rising from its stub, the arch turned over and smaller, kept off the
## rosette where that is printed.
static func _rising(hex: String, level: Level) -> String:
	var key := "rising|%d" % level
	if not _shapes.has(key):
		_shapes[key] = _rising_shape(level)
	if level == Level.FLAT:
		return '<path d="%s" fill="%s" fill-opacity="0.42"/>' % [_shapes[key], hex]
	return '<g fill="%s" fill-opacity="0.8">%s</g>' % [hex, _shapes[key]]


static func _rising_shape(level: Level) -> String:
	var foot := STUB - 3.0
	if level == Level.FLAT:
		var shape := "M0,%.1fH120" % STUB
		var x := WIDE
		while x >= 0.0:
			shape += "L%.1f,%.1f" % [x, STUB - maxf(0.0, arch(x) * RISE - 4.0)]
			x -= 2.0
		return shape + "Z"
	var grid := 4.0 if level == Level.FULL else 6.0
	var dots := PackedStringArray()
	var y := 2.0
	var row := 0
	while y < STUB:
		var x := 2.0 + (row % 2) * grid * 0.5
		while x < WIDE:
			var top := arch(x) * RISE
			if level == Level.FULL and absf(x - ROSETTE.x) < ROSETTE_CLEAR:
				var under := foot - (ROSETTE.y + sqrt(ROSETTE_CLEAR ** 2 - (x - ROSETTE.x) ** 2))
				top = maxf(0.0, minf(top, under))
			var fade := maxf(4.0, minf(10.0, top))
			var r := grid / 4.0 * 1.6 * clampf((top - (foot - y)) / fade, 0.0, 1.0)
			if r > 0.2:
				dots.append(_circle(x, y, r))
			x += grid
		y += grid
		row += 1
	return "".join(dots)


## The rosette round the picture: two bands of fine wavy rings, a banknote's.
static func _rosette(hex: String) -> String:
	if not _shapes.has("rosette"):
		_shapes["rosette"] = [_band(37.0, 2.6, 9.0, 6), _band(45.0, 1.6, 18.0, 3)]
	var bands: Array = _shapes["rosette"]
	return (
		(
			'<g fill="none" stroke="%s" stroke-width="0.45"><g stroke-opacity="0.1">%s</g>'
			+ '<g stroke-opacity="0.07">%s</g></g>'
		)
		% [hex, bands[0], bands[1]]
	)


static func _band(reach: float, swing: float, waves: float, count: int) -> String:
	var lines := PackedStringArray()
	for j: int in count:
		var line := PackedStringArray()
		for t: int in 241:
			var a := TAU * t / 240.0
			var r := reach + swing * sin(waves * a + TAU * j / count)
			line.append("%.2f,%.2f" % [ROSETTE.x + cos(a) * r, ROSETTE.y + sin(a) * r])
		lines.append('<path d="M%sZ"/>' % "L".join(line))
	return "".join(lines)


## Waves across the stub, as today's foot has them.
static func _waves(hex: String) -> String:
	if not _shapes.has("waves"):
		var lines := PackedStringArray()
		for k: int in 6:
			var line := PackedStringArray()
			var x := 5
			while x <= 115:
				var y := STUB + 6.0 + k * 5.0 + sin((x + k * 6.0) / 26.0 * TAU) * 1.6
				line.append("%d,%.2f" % [x, y])
				x += 2
			lines.append('<path d="M%s"/>' % "L".join(line))
		_shapes["waves"] = "".join(lines)
	return (
		'<g fill="none" stroke="%s" stroke-opacity="0.12" stroke-width="0.7">%s</g>'
		% [hex, _shapes["waves"]]
	)


## The perforation the stub was torn along: a row of holes, fewer and bigger on a smaller card.
static func _holes(level: Level, item: bool) -> String:
	if level == Level.FLAT:
		return ""
	var key := "holes|%d" % level
	if not _shapes.has(key):
		var step := 6 if level == Level.FULL else 12
		var r := 1.1 if level == Level.FULL else 1.6
		var holes := PackedStringArray()
		var x := 12
		while x <= 108:
			holes.append(_circle(x, STUB, r))
			x += step
		_shapes[key] = "".join(holes)
	var ink := "#17161c" if item else "#" + HOLE.to_html(false)
	return '<g fill="%s">%s</g>' % [ink, _shapes[key]]


static func _circle(x: float, y: float, r: float) -> String:
	return '<circle cx="%.1f" cy="%.1f" r="%.2f"/>' % [x, y, r]


## The hairline inside the frame, broken where the stub's bites are.
static func _hairline(hex: String) -> String:
	var line := (
		(
			"M5,%.1fV11A6,6 0 0 1 11,5H109A6,6 0 0 1 115,11V%.1f"
			+ "M5,%.1fV157A6,6 0 0 0 11,163H109A6,6 0 0 0 115,157V%.1f"
		)
		% [STUB - 3.0, STUB - 3.0, STUB + 3.0, STUB + 3.0]
	)
	return '<path d="%s" fill="none" stroke="%s" stroke-opacity="0.35"/>' % [line, hex]


static func _rect(x: float, y: float, w: float, h: float, hex: String, op: float) -> String:
	return (
		'<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" fill-opacity="%s"/>'
		% [x, y, w, h, hex, op]
	)


## The card's outline [param inset] in from its edge, a round [param corner] at each corner and the
## stub's bite out of either side, as points in its units, for its body and its frame. Its sides
## run straight from corner to bite: a bite is the round of the card's own bite grown by the inset,
## and it starts and ends where that round crosses the side, [param inset] in from the edge, not on
## the edge itself, so a frame drawn in from the edge does not lean out to meet it. Not
## [param bitten], it is the card whole, as a card with no stub is, a table card's back.
static func outline(inset: float, corner: float, bitten := true) -> PackedVector2Array:
	var points := PackedVector2Array()
	var bite := BITE + inset
	var corners: Array[Vector2] = [
		Vector2(inset + corner, inset + corner),
		Vector2(WIDE - inset - corner, inset + corner),
		Vector2(WIDE - inset - corner, TALL - inset - corner),
		Vector2(inset + corner, TALL - inset - corner),
	]
	for i: int in 4:
		for step: int in 7:
			var angle := PI + i * PI * 0.5 + step * PI / 12.0
			points.append(corners[i] + Vector2.from_angle(angle) * corner)
		# Down the right side, the bite into it; up the left, the bite into that: the round about
		# the side's middle at the stub, turning into the card, from where it crosses the side to
		# where it crosses it again, half a circle for an outline on the edge itself.
		if bitten and (i == 1 or i == 3):
			var right := i == 1
			var middle := Vector2(WIDE if right else 0.0, STUB)
			var meet := acos(clampf(inset / bite, -1.0, 1.0))
			var from := -(PI - meet) if right else meet
			for step: int in 13:
				var angle := from - 2.0 * meet * step / 12.0
				points.append(middle + Vector2.from_angle(angle) * bite)
	return points
