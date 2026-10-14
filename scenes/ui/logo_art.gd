class_name LogoArt
extends Control
## The game's mark, GAME.md 8.1 and 8.1a: a seal, engraved the way a banknote's is. A scalloped
## medallion of foil, a ring of ink with the house's fine print running round it, and in the middle
## the foil chip: a poker chip of foil seen from above with a crossroads cut through it, the
## Junction, the pot a red chip on the crossing. The name says a casino and a road; so does the
## mark. Drawn small, the mark itself under [constant SMALL] across, plate or no plate, it is the
## foil chip alone, since a seal's fine lines and fine print are only mush at that size.
##
## Drawn rather than loaded, the same as every other picture in the game, see 8.3a: it comes out
## sharp at any size. `make logo` renders it to the icons the project wears.

## The mark under this many pixels across is the foil chip alone rather than the seal.
const SMALL := 96.0
## The group a mark waiting on its picture is in, see [KeptPictures].
const KEPT := &"logo_art_kept"
## The seal, as shares of half the side: how far out its scalloped edge is and how deep and how
## many its scallops, the ring of ink and how wide it is, and the foil chip in its middle.
const SEAL := 0.97
const SCALLOP := 0.03
const SCALLOPS := 40
const BAND := 0.83
const BAND_WIDE := 0.14
const SEAL_CHIP := 0.65
## What runs round the ring of ink, and how big, against the seal's radius.
const FINE_PRINT := "JACKPOT JUNCTION  ·  DEPT. OF KARTS  ·  LICENSED ON EVERY TABLE  ·  "
const FINE_SIZE := 0.095
## The foil chip, as shares of its radius: the roads, the notches round its rim, three to each
## quarter, the lane lines, and the pot on the crossing.
const ROAD := 0.4
const NOTCHES := 3
const NOTCH_APART := 17.0
const NOTCH := Vector2(0.13, 0.2)
const DASH := Vector2(0.12, 0.1)
const POT := 0.25
const ROAD_INK := Color("#24222b")
const SHADOW := Color("#0b0a0e")
## On a plate, the mark takes this share of its side.
const ON_PLATE := 0.72

## The plate behind it, the house's ticket, for a mark that has to sit on whatever a desktop puts
## behind an icon. A mark drawn onto a screen of the game's own does not need one.
@export var plate := true
## The foil chip alone at any size, rather than only when it is small.
@export var chip_only := false
## The foil chip in one ink, white on nothing, for a system that tints the mark itself the way
## Android's themed icons do. Never on a plate.
@export var mono := false
## Whether it is drawn once a run into a picture at its size on the screen and shown from then
## on, GAME.md 10.7, for a mark that stays up as it is, the title's and the school's: a seal is
## some three hundred draw calls a frame drawn as itself, its fine print a draw for each letter.
var kept := false
## The words round the seal: the Department's, or what the title's says after the story's ending,
## STORY.md 8.6. The icon, the splash and every other mark keep the Department's.
var fine_print := FINE_PRINT

## The engraving, worked out for a size, and the size it was worked out for.
var _lines: Array[PackedVector2Array] = []
var _inks: Array[Color] = []
var _drawn_for := Vector2.ZERO
var _plate_look: TicketStyle


func _draw() -> void:
	var unit := minf(size.x, size.y)
	if unit < 2.0:
		return
	if kept and _draw_kept():
		return
	var middle := size * 0.5
	var reach := _reach()
	if mono:
		_draw_mono_chip(middle, unit * 0.5 * 0.92)
		return
	if plate:
		_draw_plate(unit)
	if not shows_seal():
		_draw_chip(middle, reach * 0.92, reach * 2.0 >= SMALL)
		return
	_draw_seal(middle, reach)


## The mark from its picture, see [member kept]; false while that is still being drawn, for the
## mark to be drawn as itself meanwhile.
func _draw_kept() -> bool:
	var pixels := KeptPictures.scale_of(self) * size
	var step := Vector2i(KeptPictures.step_up(pixels.x, 8), KeptPictures.step_up(pixels.y, 8))
	var key := "logo|%s|%s|%s|%s" % [plate, chip_only, mono, fine_print]
	if not is_in_group(KEPT):
		add_to_group(KEPT)
	var picture := KeptPictures.of(self, key, step, _picture.bind(step), KEPT)
	if picture == null:
		return false
	draw_texture_rect(picture, Rect2(Vector2.ZERO, size), false)
	return true


## The mark at [param pixels], drawn as itself, for its picture.
func _picture(pixels: Vector2i) -> Control:
	var drawn := LogoArt.new()
	drawn.plate = plate
	drawn.chip_only = chip_only
	drawn.mono = mono
	drawn.fine_print = fine_print
	drawn.size = Vector2(pixels)
	return drawn


## Whether it is drawn as the seal, or as the foil chip alone, which it is when it is small or
## asked to be.
func shows_seal() -> bool:
	return not chip_only and not mono and _reach() * 2.0 >= SMALL


## How far out from the middle the mark itself reaches, the plate left round it where there is one.
func _reach() -> float:
	return minf(size.x, size.y) * 0.5 * (ON_PLATE if plate else 1.0)


## The plate: a ticket of the house's stock with notched corners, banknote waves engraved across
## it and a foil hairline inside its edge, see [TicketStyle].
func _draw_plate(unit: float) -> void:
	if _plate_look == null:
		_plate_look = TicketStyle.cut(HouseTheme.STOCK_RAISED, 0.0, 0.0, 0.0)
		_plate_look.engraving = Color(HouseTheme.FOIL, 0.1)
		_plate_look.frame = Color(HouseTheme.FOIL, 0.5)
	_plate_look.notch = unit * 0.13
	_plate_look.frame_inset = unit * 0.04
	_plate_look.waves = unit
	var square := Rect2((size - Vector2.ONE * unit) * 0.5, Vector2.ONE * unit)
	draw_style_box(_plate_look, square)


## The seal round [param middle], [param reach] out.
func _draw_seal(middle: Vector2, reach: float) -> void:
	var r := reach * SEAL
	var edge := PackedVector2Array()
	for i: int in 720:
		var turn := TAU * float(i) / 720.0
		var out := r * (1.0 - SCALLOP + SCALLOP * cos(float(SCALLOPS) * turn))
		edge.append(middle + Vector2.from_angle(turn) * out)
	var shadow := edge.duplicate()
	for i: int in shadow.size():
		shadow[i] += Vector2(0.0, r * 0.03)
	draw_colored_polygon(shadow, SHADOW)
	_draw_foil(edge, middle.y - r, middle.y + r)
	if size != _drawn_for:
		_engrave(middle, r)
	for i: int in _lines.size():
		draw_polyline(_lines[i], _inks[i], maxf(r * 0.004, 0.6), true)
	draw_arc(middle, r * BAND, 0.0, TAU, 128, HouseTheme.INK, r * BAND_WIDE, true)
	_draw_fine_print(middle, r)
	_draw_chip(middle, r * SEAL_CHIP, true)


## The seal's engraving: a guilloché band in the foil between the chip and the ring of ink, and
## a finer one between the ring and the scalloped edge.
func _engrave(middle: Vector2, r: float) -> void:
	_drawn_for = size
	_lines.clear()
	_inks.clear()
	var inner := Engraving.rings(middle, r * 0.715, r * 0.022, 48, 7, 720)
	var outer := Engraving.rings(middle, r * 0.935, r * 0.012, 72, 4, 720)
	for line: PackedVector2Array in inner:
		_lines.append(line)
		_inks.append(Color(HouseTheme.INK, 0.24))
	for line: PackedVector2Array in outer:
		_lines.append(line)
		_inks.append(Color(HouseTheme.INK, 0.22))


## The fine print running round the ring of ink, clockwise, the game's name over the top, in the
## foil it is printed in; spaced out to go once all the way round.
func _draw_fine_print(middle: Vector2, r: float) -> void:
	var font := Type.micro_font()
	var font_size := maxi(roundi(r * FINE_SIZE), 4)
	# Measured letter by letter, as they are set, so the spacing worked out closes the circle.
	var advances := PackedFloat32Array()
	var wide := 0.0
	for character: String in fine_print:
		var advance := font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		advances.append(advance)
		wide += advance
	var round_by := TAU * r * BAND
	var extra := (round_by - wide) / float(fine_print.length())
	# The game's name centered over the top.
	var along := 0.0
	for i: int in "JACKPOT JUNCTION".length():
		along -= (advances[i] + extra) * 0.5
	var baseline := r * BAND - float(font_size) * Type.CAP_HEIGHT * 0.5
	var ink := Color(HouseTheme.FOIL, 0.9)
	for i: int in fine_print.length():
		var advance := advances[i]
		var turn := -PI * 0.5 + (along + advance * 0.5) / (r * BAND)
		var at := middle + Vector2.from_angle(turn) * baseline
		draw_set_transform(at, turn + PI * 0.5)
		draw_char(font, Vector2(-advance * 0.5, 0.0), fine_print[i], font_size, ink)
		along += advance + extra
	draw_set_transform(Vector2.ZERO)


## The foil chip round [param middle], [param r] out; with [param fine] its engraving and the
## curbs along its roads, which a small one leaves off.
func _draw_chip(middle: Vector2, r: float, fine: bool) -> void:
	draw_circle(middle, r * 1.05, SHADOW, true, -1.0, true)
	var disc := _circle(middle, r, 72)
	_draw_foil(disc, middle.y - r, middle.y + r)
	if fine:
		for ring: Array in [[0.8, 0.045, 22, 12, 0.2], [0.58, 0.04, 16, 9, 0.16]]:
			var lines := Engraving.rings(middle, r * ring[0], r * ring[1], ring[2], ring[3], 420)
			Engraving.draw_on(self, lines, Color(HouseTheme.INK, ring[4]), maxf(r * 0.006, 0.6))
	for quarter: int in 4:
		for i: int in NOTCHES:
			var lean := (float(i) - float(NOTCHES - 1) * 0.5) * NOTCH_APART
			_draw_notch(middle, r, deg_to_rad(45.0 + 90.0 * float(quarter) + lean))
	_draw_roads(middle, r, disc)
	if fine:
		_draw_curbs(middle, r)
	_draw_dashes(middle, r, HouseTheme.PAPER)
	ChipArt.chip(self, middle, r * POT, Palette.CHIP_RED, 6)
	draw_arc(middle, r, 0.0, TAU, 72, HouseTheme.INK, r * 0.06, true)
	draw_arc(
		middle, r * 1.03, 0.0, TAU, 72, Color(HouseTheme.FOIL_HIGH, 0.7), maxf(r * 0.012, 0.8), true
	)


## [param edge] in foil, the highlight at [param top] running down to the low at [param foot].
func _draw_foil(edge: PackedVector2Array, top: float, foot: float) -> void:
	var inks := PackedColorArray()
	for point: Vector2 in edge:
		var down := clampf((point.y - top) / maxf(foot - top, 1.0), 0.0, 1.0)
		inks.append(HouseTheme.FOIL_HIGH.lerp(HouseTheme.FOIL_LOW, down))
	draw_polygon(edge, inks)
	var line := edge.duplicate()
	line.append(edge[0])
	draw_polyline(line, HouseTheme.FOIL, 1.0, true)


## The foil chip in one ink round [param middle], [param r] out: the roads and the notches cut
## out of the disc, the lane lines and the pot printed in the roads. Every cut runs past the rim,
## so what is left has no holes to draw.
func _draw_mono_chip(middle: Vector2, r: float) -> void:
	var cuts := _road_bands(middle, r)
	for quarter: int in 4:
		for i: int in NOTCHES:
			var lean := (float(i) - float(NOTCHES - 1) * 0.5) * NOTCH_APART
			cuts.append(_notch(middle, r, deg_to_rad(45.0 + 90.0 * float(quarter) + lean), 1.1))
	var pieces: Array[PackedVector2Array] = [_circle(middle, r, 96)]
	for cut: PackedVector2Array in cuts:
		var left: Array[PackedVector2Array] = []
		for piece: PackedVector2Array in pieces:
			left.append_array(Geometry2D.clip_polygons(piece, cut))
		pieces = left
	for piece: PackedVector2Array in pieces:
		draw_colored_polygon(piece, Color.WHITE)
	_draw_dashes(middle, r, Color.WHITE)
	draw_circle(middle, r * POT, Color.WHITE, true, -1.0, true)


## A cream notch at the rim, the way a poker chip's are, set between the roads.
func _draw_notch(middle: Vector2, r: float, angle: float) -> void:
	draw_colored_polygon(_notch(middle, r, angle, 1.0), HouseTheme.PAPER)


## The notch at [param angle] as a shape, from inside the rim to [param out] of the radius.
static func _notch(middle: Vector2, r: float, angle: float, out: float) -> PackedVector2Array:
	var toward := Vector2.from_angle(angle)
	var across := toward.orthogonal() * r * NOTCH.x * 0.5
	var outer := middle + toward * r * out
	var inn := middle + toward * r * (1.0 - NOTCH.y)
	return PackedVector2Array([outer + across, outer - across, inn - across, inn + across])


## The crossroads, cut out of the chip: each band clipped to [param disc], so the four arms end
## exactly at the rim.
func _draw_roads(middle: Vector2, r: float, disc: PackedVector2Array) -> void:
	for band: PackedVector2Array in _road_bands(middle, r):
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(band, disc):
			draw_colored_polygon(piece, ROAD_INK)


## The two roads as bands running past the rim either way, across and down.
static func _road_bands(middle: Vector2, r: float) -> Array[PackedVector2Array]:
	var bands: Array[PackedVector2Array] = []
	var wide := r * ROAD * 0.5
	for across: bool in [true, false]:
		var span := Vector2(r * 1.2, wide) if across else Vector2(wide, r * 1.2)
		(
			bands
			. append(
				PackedVector2Array(
					[
						middle + Vector2(-span.x, -span.y),
						middle + Vector2(span.x, -span.y),
						middle + Vector2(span.x, span.y),
						middle + Vector2(-span.x, span.y),
					]
				)
			)
		)
	return bands


## The curbs: a foil line along each edge of the roads, turning the corner at the crossing.
func _draw_curbs(middle: Vector2, r: float) -> void:
	var half := r * ROAD * 0.5
	var rim := sqrt(r * r - half * half)
	var ink := Color(HouseTheme.FOIL, 0.55)
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			var corner := PackedVector2Array(
				[
					middle + Vector2(sx * half, sy * rim),
					middle + Vector2(sx * half, sy * half),
					middle + Vector2(sx * rim, sy * half),
				]
			)
			draw_polyline(corner, ink, maxf(r * 0.012, 0.6), true)


## The lane lines down each arm in [param ink], stopping short of the crossing the way a real
## one's do.
func _draw_dashes(middle: Vector2, r: float, ink: Color) -> void:
	var width := maxf(r * 0.05, 1.0)
	for quarter: int in 4:
		var facing := Vector2.from_angle(TAU * float(quarter) / 4.0)
		var out := r * 0.34
		while out < r * 0.97:
			var to := minf(out + r * DASH.x, r * 0.97)
			draw_line(middle + facing * out, middle + facing * to, ink, width, true)
			out += r * (DASH.x + DASH.y)


static func _circle(middle: Vector2, r: float, points: int) -> PackedVector2Array:
	var made := PackedVector2Array()
	for i: int in points:
		made.append(middle + Vector2.from_angle(TAU * float(i) / float(points)) * r)
	return made
