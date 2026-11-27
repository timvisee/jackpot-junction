class_name IconPress
extends RefCounted
## Prints the pictures of GAME.md 8.3a: every joker's, power-up's and achievement's icon, the
## table's cards, the kinds of game, the ways to drive, the dress, the emotes, the loyalty program's
## landmarks, the glyphs on the buttons and the suits' marks are SVG files in assets/icons, drawn on
## a 48-unit grid with what each shape is written in its class, and printed here the way the house
## prints: in the ink it is handed, its tint, cream for whatever is light, and the shadow side as a
## halftone screen, at the size it is shown. Each picture is rasterized once for an ink and a size
## and kept.
##
## The files are plain SVG and open in any editor or browser. A [code]piece[/code] group of
## [code]ink[/code], [code]tint[/code], [code]cream[/code] or [code]dark[/code] (the black of a
## red-and-black pair, solid) holds its [code]body[/code], its
## [code]shade[/code] (the shadow side, on top of the rim every inked piece gets on its lower
## right), its [code]glint[/code]s and its [code]cut[/code]s; a [code]line[/code] is a stroke; a
## [code]cut-all[/code] group cuts through everything. A piece cuts a gap round itself into what
## came before it unless it says [code]data-seam="false"[/code], and goes without a rim with
## [code]data-shade="false"[/code].

## How the shadow side is printed: nothing, a flat darker ink, or a halftone screen of it. One
## constant, so the whole set goes back to flat by changing one line.
enum Printing { FLAT, TONE, HALFTONE }
## The layers a picture is composed in: flat, with a flat shadow side, or the shadow side alone.
enum Layer { FLAT, TONE, SHADE }
## What a picture is printed on: the dark of a card or the HUD; paper in one ink, flat, its cream
## the paper's own; or paper in two inks, the picture in a colored one with its shadow side screened
## in a dark one, as the achievements' chips are, GAME.md 8.10.
enum Ground { CARD, PAPER, TWO_INKS }

const PRINTING := Printing.HALFTONE
## Where the drawings are, one file per id.
const FOLDERS: Array[String] = [
	"res://assets/icons/jokers/",
	"res://assets/icons/powerups/",
	"res://assets/icons/achievements/",
	"res://assets/icons/table/",
	"res://assets/icons/modes/",
	"res://assets/icons/drive/",
	"res://assets/icons/dress/",
	"res://assets/icons/emotes/",
	"res://assets/icons/landmarks/",
	"res://assets/icons/ui/",
	"res://assets/icons/suits/",
	"res://assets/icons/marks/",
	"res://assets/icons/hud/",
	"res://assets/icons/book/",
	"res://assets/icons/reels/",
]
## The grid the drawings are made on, and the widths every one of them shares, in its units: the
## gap a piece cuts round itself, a glint, and the rim of shadow along every inked piece.
const GRID := 48.0
const GAP := 1.5
const GLINT := 1.5
const RIM := 2.5
## The second ink, and how far the tint and the shade are from the ink.
const CREAM := Color("#f2ead6")
const SHADOW := Color("#0b0a10")
const SHADE := 0.5
## The dark ink the shadow side is screened in on paper, and how far toward it.
const INKY := Color("#17151c")
const INKY_SHADE := 0.55
## What a dark piece prints in on paper: the House's ink, the black beside a red.
const DARK := Color("#211f24")
const TINT := 0.4
## An ink too dark to read on the card is lifted toward white until it does: Oil Stain's purple.
const READABLE := 0.34
const LIFT := 0.1
## Below this many pixels a picture drops its shading and glints, which would only blur it; a toned
## one keeps its shadow side there as a flat darker ink, see [method draw].
const SMALL := 40
## The halftone's screen, the same in screen pixels whatever size a picture is shown at: a tile
## this many pixels a side, a dot every [constant SCREEN] pixels along a row and a row between
## them, each dot this many pixels across.
const TILE := 32
const SCREEN := 4
const DOT := 2.26
## How far inside a shape the screen stops, in pixels, so no dot lands on its softened edge.
const INSET := 0.75
## The sizes a picture is rasterized at, about a quarter apart: a card growing in passes through a
## few of them rather than one for every pixel.
const STEPS: Array[int] = [
	16,
	20,
	24,
	28,
	32,
	40,
	48,
	56,
	64,
	72,
	80,
	96,
	112,
	128,
	144,
	160,
	192,
	224,
	256,
	320,
	384,
	448,
	512,
	640,
	768,
	1024
]
## How many pictures are kept before the oldest go.
const KEPT := 400

const _SVG := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">'
const _FULL := '<rect x="-10" y="-10" width="68" height="68" fill="%s"/>'
const _MASK := '<mask id="%s" maskUnits="userSpaceOnUse" x="-10" y="-10" width="68" height="68">'

static var _drawings := {}
static var _pictures := {}
static var _tiles := {}


## Whether [param id] has a drawing of its own.
static func has(id: StringName) -> bool:
	return not _drawing(id).is_empty()


## Draws [param id] into the square in the middle of [param box] on [param on], in [param ink],
## at the size it will show on screen, on [param ground]; on paper, what is cream is printed in
## [param paper], or left bare where that is clear. Its alpha fades the picture. [param toned]
## keeps its shadow side when it is small, flat rather than screened, as the map's pin does.
## False if there is no drawing.
static func draw(
	on: CanvasItem,
	box: Rect2,
	id: StringName,
	ink: Color,
	ground := Ground.CARD,
	paper := Color.TRANSPARENT,
	toned := false
) -> bool:
	var side := minf(box.size.x, box.size.y)
	if side <= 0.0:
		return false
	var square := Rect2(box.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))
	var pixels := side * KeptPictures.scale_of(on)
	var picture := texture(id, Color(ink, 1.0), pixels, ground, paper, toned)
	if picture == null:
		return false
	on.draw_texture_rect(picture, square, false, Color(1.0, 1.0, 1.0, ink.a))
	return true


## [param id] printed in [param ink] for about [param pixels] a side, kept for the next asker.
static func texture(
	id: StringName,
	ink: Color,
	pixels: float,
	ground := Ground.CARD,
	paper := Color.TRANSPARENT,
	toned := false
) -> Texture2D:
	var side := step(pixels)
	var key := "%s|%s|%d|%d|%s|%s" % [id, ink.to_html(false), side, ground, paper.to_html(), toned]
	var kept: Texture2D = _pictures.get(key)
	if kept != null:
		return kept
	var drawing := _drawing(id)
	if drawing.is_empty():
		return null
	var picture := ImageTexture.create_from_image(
		image(drawing, ink, side, ground, paper, 0, toned)
	)
	if _pictures.size() >= KEPT:
		_pictures.erase(_pictures.keys()[0])
	_pictures[key] = picture
	return picture


## [param id] printed in [param ink], [param side] pixels a side, on [param ground], for a picture
## that is kept elsewhere, as the house's buttons keep theirs, and shown at [param shown] pixels;
## null if there is no drawing.
static func printed(
	id: StringName,
	ink: Color,
	side: int,
	ground := Ground.CARD,
	paper := Color.TRANSPARENT,
	shown := 0,
	toned := false
) -> Image:
	var drawing := _drawing(id)
	if drawing.is_empty():
		return null
	return image(drawing, ink, side, ground, paper, shown, toned)


## The size of the steps that [param pixels] is rasterized at.
static func step(pixels: float) -> int:
	for size: int in STEPS:
		if size >= pixels:
			return size
	return STEPS[-1]


## [param drawing] printed in [param ink], [param side] pixels a side, on [param ground].
## Drawn [param side] pixels a side for a screen showing it at [param shown], the same when 0: a
## picture kept bigger than it shows is shaded as what it shows at. [param toned] keeps the
## shadow side of a small one as a flat tone.
static func image(
	drawing: Dictionary,
	ink: Color,
	side: int,
	ground := Ground.CARD,
	paper := Color.TRANSPARENT,
	shown := 0,
	toned := false
) -> Image:
	var seen := shown if shown > 0 else side
	var look := look_of(ink, seen, ground, paper)
	ink = look["ink"]
	var big := seen >= SMALL
	var shaded := ground != Ground.PAPER and (big or toned) and PRINTING != Printing.FLAT
	var flat_shade := shaded and (PRINTING == Printing.TONE or not big)
	var layer := Layer.TONE if flat_shade else Layer.FLAT
	var printed := _raster(compose(drawing, ink, look, layer, side), side)
	if shaded and not flat_shade and PRINTING == Printing.HALFTONE:
		var mask := _raster(compose(drawing, ink, look, Layer.SHADE, side), side)
		var screen := _screen(side, look["shade"])
		printed.blend_rect_mask(screen, mask, Rect2i(0, 0, side, side), Vector2i.ZERO)
	return printed


## How [param ink] prints on [param ground] at [param side] pixels: the ink itself, lifted on a card
## if it is too dark to read there; what cream is printed in, transparent for bare paper; the shadow
## side's ink; what a dark piece is printed in; and whether glints show.
static func look_of(
	ink: Color, side: int, ground := Ground.CARD, paper := Color.TRANSPARENT
) -> Dictionary:
	var card := ground == Ground.CARD
	if card:
		ink = lifted(ink)
	return {
		"ink": ink,
		"cream": CREAM if card else paper,
		"shade": ink.lerp(SHADOW, SHADE) if card else ink.lerp(INKY, INKY_SHADE),
		"dark": ink.lerp(SHADOW, SHADE) if card else DARK,
		"glints": ground != Ground.PAPER and side >= SMALL,
	}


## [param ink] lifted toward white until it reads on a dark card.
static func lifted(ink: Color) -> Color:
	for i: int in 10:
		if ink.get_luminance() >= READABLE:
			break
		ink = ink.lerp(Color.WHITE, LIFT)
	return ink


## The drawing of [param id], read from its file once: its icon transform, its parts, and what
## cuts through all of them. Empty if it has none.
static func _drawing(id: StringName) -> Dictionary:
	if _drawings.has(id):
		return _drawings[id]
	var found := {}
	for folder: String in FOLDERS:
		var path := folder + String(id) + ".svg"
		if FileAccess.file_exists(path):
			found = parse(FileAccess.get_file_as_string(path))
			break
	_drawings[id] = found
	return found


## Reads a drawing out of the SVG [param text]: what each shape is, from its class.
static func parse(text: String) -> Dictionary:
	var drawing := {"t": "", "parts": [], "cut_all": []}
	var reader := XMLParser.new()
	if reader.open_buffer(text.to_utf8_buffer()) != OK:
		return {}
	var piece := {}
	var in_cut_all := false
	while reader.read() == OK:
		var node := reader.get_node_type()
		if node == XMLParser.NODE_ELEMENT_END and reader.get_node_name() == "g":
			piece = {}
			in_cut_all = false
			continue
		if node != XMLParser.NODE_ELEMENT:
			continue
		var classes := reader.get_named_attribute_value_safe("class").split(" ", false)
		if reader.get_node_name() == "g":
			if "icon" in classes:
				drawing["t"] = reader.get_named_attribute_value_safe("transform")
			elif "cut-all" in classes:
				in_cut_all = true
			elif "piece" in classes:
				piece = _part(reader, classes, false)
				drawing["parts"].append(piece)
			continue
		if reader.get_node_name() != "path":
			continue
		var shape := _shape(reader)
		if in_cut_all:
			drawing["cut_all"].append(shape)
		elif "line" in classes:
			var line := _part(reader, classes, true)
			line.merge(shape, true)
			drawing["parts"].append(line)
		elif not piece.is_empty():
			_add(piece, classes, shape)
	return drawing


static func _part(reader: XMLParser, classes: PackedStringArray, line: bool) -> Dictionary:
	var tone := "ink"
	for name: String in ["tint", "cream", "dark"]:
		if name in classes:
			tone = name
	return {
		"line": line,
		"tone": tone,
		"t": reader.get_named_attribute_value_safe("transform"),
		"seam": reader.get_named_attribute_value_safe("data-seam") != "false",
		"shade": reader.get_named_attribute_value_safe("data-shade") != "false",
		"d": "",
		"rule": "",
		"sh": [],
		"gl": [],
		"ct": [],
	}


static func _shape(reader: XMLParser) -> Dictionary:
	return {
		"d": reader.get_named_attribute_value_safe("d"),
		"rule": reader.get_named_attribute_value_safe("fill-rule"),
		"w": reader.get_named_attribute_value_safe("stroke-width").to_float(),
		"dash": reader.get_named_attribute_value_safe("stroke-dasharray"),
		"cap": reader.get_named_attribute_value_safe("stroke-linecap"),
	}


static func _add(piece: Dictionary, classes: PackedStringArray, shape: Dictionary) -> void:
	if "body" in classes:
		piece["d"] = shape["d"]
		piece["rule"] = shape["rule"]
	elif "shade" in classes:
		piece["sh"].append(shape)
	elif "glint" in classes:
		piece["gl"].append(shape)
	elif "cut" in classes:
		piece["ct"].append(shape)


## The SVG that prints one [param layer] of [param drawing], as [param look] says, see
## [method look_of]: the picture flat or with its shadow side in a flat darker ink, or only the
## shadow side, white, for the halftone to be laid through.
static func compose(
	drawing: Dictionary, ink: Color, look: Dictionary, layer: int, side: int
) -> String:
	var defs := PackedStringArray()
	var out := PackedStringArray()
	var parts: Array = drawing["parts"]
	# In the shadow layer every cut and gap is widened by the inset, so no dot touches an edge.
	var grow := INSET * GRID / side if layer == Layer.SHADE else 0.0
	var bare := (look["cream"] as Color).a <= 0.0
	for i: int in parts.size():
		var piece: Dictionary = parts[i]
		var body := ""
		if layer == Layer.SHADE:
			body = _shadow(drawing, i, defs)
		else:
			body = _body(drawing, i, ink, look, layer == Layer.TONE, defs)
		if body.is_empty():
			continue
		var mask := _seams(drawing, i, layer == Layer.SHADE, grow, bare, defs)
		out.append(body if mask.is_empty() else '<g mask="url(#%s)">%s</g>' % [mask, body])
	return _SVG + "<defs>%s</defs>%s</svg>" % ["".join(defs), "".join(out)]


## Where [param piece] sits: the icon's transform and then its own.
static func _placed(drawing: Dictionary, piece: Dictionary) -> String:
	return ("%s %s" % [drawing["t"], piece["t"]]).strip_edges()


static func _hex(color: Color) -> String:
	return "#" + color.to_html(false)


## One SVG path element with [param attributes], those left empty left out.
static func _path(d: String, attributes: Dictionary) -> String:
	var written := ""
	for name: String in attributes:
		var value: Variant = attributes[name]
		if value is String and value == "":
			continue
		written += ' %s="%s"' % [name, value]
	return '<path d="%s"%s/>' % [d, written]


static func _stroke(d: String, placed: String, paint: String, width: float, shape := {}) -> String:
	return _path(
		d,
		{
			"transform": placed,
			"fill": "none",
			"stroke": paint,
			"stroke-width": width,
			"stroke-linecap": shape.get("cap", "") if shape.get("cap", "") != "" else "round",
			"stroke-linejoin": "round",
			"stroke-dasharray": shape.get("dash", ""),
		}
	)


static func _fill(d: String, placed: String, paint: String, rule := "", extra := {}) -> String:
	var attributes := {"transform": placed, "fill": paint, "fill-rule": rule}
	attributes.merge(extra)
	return _path(d, attributes)


## The mask that cuts [param i]'s own cuts and everything cut through all, and a gap round every
## piece after it that seams; in the shadow layer also the exact shape of those that do not, and a
## band along the piece's own edge, so the screen stops short of it. On [param bare] paper, where
## cream is left unprinted, a cream piece that does not seam is cut out exactly, so the paper shows
## through it.
static func _seams(
	drawing: Dictionary, i: int, shadow: bool, grow: float, bare: bool, defs: PackedStringArray
) -> String:
	var parts: Array = drawing["parts"]
	var piece: Dictionary = parts[i]
	var black := PackedStringArray()
	if shadow:
		black.append(_fill(piece["d"], _placed(drawing, piece), "none", "", _outline(grow)))
	for cut: Dictionary in piece["ct"]:
		black.append(_cut(cut, _placed(drawing, piece), grow))
	for cut: Dictionary in drawing["cut_all"]:
		black.append(_cut(cut, drawing["t"], grow))
	for j: int in range(i + 1, parts.size()):
		var later: Dictionary = parts[j]
		if later["seam"]:
			black.append(_knock(drawing, later, GAP + grow))
		elif shadow or (bare and later["tone"] == "cream"):
			black.append(_knock(drawing, later, grow))
	if black.is_empty():
		return ""
	var id := "m%d" % i
	defs.append(_MASK % id + _FULL % "#fff" + "".join(black) + "</mask>")
	return id


static func _cut(cut: Dictionary, placed: String, grow: float) -> String:
	if cut["w"] > 0.0:
		return _stroke(cut["d"], placed, "#000", cut["w"] + grow * 2.0)
	if grow > 0.0:
		return _fill(cut["d"], placed, "#000", cut["rule"], _outline(grow))
	return _fill(cut["d"], placed, "#000", cut["rule"])


static func _knock(drawing: Dictionary, piece: Dictionary, grow: float) -> String:
	var placed := _placed(drawing, piece)
	if piece["line"]:
		return _stroke(piece["d"], placed, "#000", piece["w"] + grow * 2.0, piece)
	if grow <= 0.0:
		return _fill(piece["d"], placed, "#000", piece["rule"])
	return _fill(piece["d"], placed, "#000", piece["rule"], _outline(grow))


static func _outline(grow: float) -> Dictionary:
	return {"stroke": "#000", "stroke-width": grow * 2.0, "stroke-linejoin": "round"}


static func _clip(drawing: Dictionary, i: int, defs: PackedStringArray) -> String:
	var piece: Dictionary = drawing["parts"][i]
	var id := "c%d" % i
	var shape := _path(
		piece["d"], {"transform": _placed(drawing, piece), "clip-rule": piece["rule"]}
	)
	defs.append('<clipPath id="%s">%s</clipPath>' % [id, shape])
	return id


## Piece [param i] as printed: a line, a cream, dark or tinted shape, or an inked one with its
## shadow side in a flat darker ink when [param tone], and its glints.
static func _body(
	drawing: Dictionary, i: int, ink: Color, look: Dictionary, tone: bool, defs: PackedStringArray
) -> String:
	var piece: Dictionary = drawing["parts"][i]
	var placed := _placed(drawing, piece)
	var kind: String = piece["tone"]
	var cream: Color = look["cream"]
	if piece["line"]:
		if kind == "cream" and cream.a <= 0.0:
			return ""
		var line := _stroke(
			piece["d"], placed, _hex(cream if kind == "cream" else ink), piece["w"], piece
		)
		return '<g opacity="%s">%s</g>' % [TINT, line] if kind == "tint" else line
	if kind == "cream":
		return _fill(piece["d"], placed, _hex(cream), piece["rule"]) if cream.a > 0.0 else ""
	if kind == "dark":
		return _fill(piece["d"], placed, _hex(look["dark"]), piece["rule"])
	var printed := ""
	var inner := PackedStringArray()
	if kind == "tint":
		printed = _fill(piece["d"], placed, _hex(ink), piece["rule"], {"opacity": TINT})
	else:
		printed = _fill(piece["d"], placed, _hex(ink), piece["rule"])
		if tone and piece["shade"]:
			var shade := _hex(look["shade"])
			inner.append(_FULL % shade)
			var back := "translate(%s,%s) %s" % [-RIM, -RIM, placed]
			inner.append(_fill(piece["d"], back, _hex(ink), piece["rule"]))
			for region: Dictionary in piece["sh"]:
				inner.append(_fill(region["d"], placed, shade, region["rule"]))
	if look["glints"] and cream.a > 0.0:
		for glint: Dictionary in piece["gl"]:
			var width: float = glint["w"] if glint["w"] > 0.0 else GLINT
			inner.append(_stroke(glint["d"], placed, _hex(cream), width))
	if not inner.is_empty():
		printed += '<g clip-path="url(#%s)">%s</g>' % [_clip(drawing, i, defs), "".join(inner)]
	return printed


## The shadow side of piece [param i], white: the rim along its lower right and its own shade
## regions. The piece's mask keeps them a little inside its edge, see [method _seams].
static func _shadow(drawing: Dictionary, i: int, defs: PackedStringArray) -> String:
	var piece: Dictionary = drawing["parts"][i]
	if piece["line"] or piece["tone"] != "ink" or not piece["shade"]:
		return ""
	var placed := _placed(drawing, piece)
	var rim := "r%d" % i
	var back := "translate(%s,%s) %s" % [-RIM, -RIM, placed]
	var outside := _fill(piece["d"], placed, "#fff", piece["rule"])
	var inside := _fill(piece["d"], back, "#000", piece["rule"])
	defs.append(_MASK % rim + outside + inside + "</mask>")
	var regions := PackedStringArray()
	for region: Dictionary in piece["sh"]:
		regions.append(_fill(region["d"], placed, "#fff", region["rule"]))
	return (
		'<g clip-path="url(#%s)"><g mask="url(#%s)">%s</g>%s</g>'
		% [_clip(drawing, i, defs), rim, _FULL % "#fff", "".join(regions)]
	)


static func _raster(svg: String, side: int) -> Image:
	var printed := Image.new()
	printed.load_svg_from_string(svg, side / GRID)
	if printed.get_width() != side or printed.get_height() != side:
		printed.resize(side, side)
	if printed.get_format() != Image.FORMAT_RGBA8:
		printed.convert(Image.FORMAT_RGBA8)
	return printed


## The halftone screen in [param ink], [param side] pixels a side: one tile, laid edge to edge.
static func _screen(side: int, ink: Color) -> Image:
	var key := ink.to_html(false)
	var tile: Image = _tiles.get(key)
	if tile == null:
		tile = _tile(ink)
		_tiles[key] = tile
	var screen := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	for y: int in range(0, side, TILE):
		for x: int in range(0, side, TILE):
			screen.blit_rect(tile, Rect2i(0, 0, TILE, TILE), Vector2i(x, y))
	return screen


## One tile of the screen: a dot every [constant SCREEN] pixels and one in the middle of each of
## those squares, which is a square grid of dots turned on its corner, as a printer's screen is.
static func _tile(ink: Color) -> Image:
	var r := DOT * 0.5
	var dots := PackedStringArray()
	for y: int in range(-1, TILE / SCREEN + 1):
		for x: int in range(-1, TILE / SCREEN + 1):
			for half: float in [0.5, 0.5 + SCREEN * 0.5]:
				var at := Vector2(x * SCREEN + half, y * SCREEN + half)
				dots.append(
					(
						"M%s,%sa%s,%s 0 1 0 %s,0a%s,%s 0 1 0 %s,0"
						% [at.x - r, at.y, r, r, 2 * r, r, r, -2 * r]
					)
				)
	var svg := (
		(
			'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">'
			% [TILE, TILE, TILE, TILE]
		)
		+ '<path fill="%s" d="%s"/></svg>' % [_hex(ink), "".join(dots)]
	)
	var tile := Image.new()
	tile.load_svg_from_string(svg, 1.0)
	if tile.get_format() != Image.FORMAT_RGBA8:
		tile.convert(Image.FORMAT_RGBA8)
	return tile
