class_name LogoArt
extends Control
## The game's mark, GAME.md 8.1: the Junction seen from above. A gold chip with a crossroads cut
## through it, the notches every poker chip wears round its rim, and the neon ring the pad lights
## up while somebody is banking. The name says a casino and a road; so does the mark.
##
## Drawn rather than loaded, the same as every other picture in the game, see 8.3a: it is one
## file, it is built out of the palette rather than out of a memory of it, and it comes out sharp
## at any size. `make logo` renders it to the icon the project wears.

## Everything is a fraction of the shorter side, so the mark is the same at 64 pixels and 1024.
const CHIP := 0.44
const ROAD := 0.2
const RIM := 0.036
## The notches round the rim: how many sit in each quarter of the chip, how far in they cut, how
## wide each one is, and how far apart they stand.
const NOTCHES := 3
const NOTCH_DEPTH := 0.075
const NOTCH_WIDE := 0.075
const NOTCH_APART := 17.0
## The roundel in the middle of the crossing: the Junction itself, with the pot sitting on it.
const HUB := 0.085
const POT := 0.05
## Road markings: the dashes along each arm, as a fraction out from the middle.
const DASHES: Array[float] = [0.25, 0.36]
const DASH := Vector2(0.028, 0.07)
const PLATE_INK := Color(0.07, 0.07, 0.09)
const PLATE_ROUND := 0.22

## The plate behind it, for a mark that has to sit on whatever a desktop puts behind an icon. A
## mark drawn onto a screen of the game's own does not need one.
@export var plate := true


func _draw() -> void:
	var unit := minf(size.x, size.y)
	var middle := size * 0.5
	if plate:
		var style := StyleBoxFlat.new()
		style.bg_color = PLATE_INK
		style.set_corner_radius_all(roundi(unit * PLATE_ROUND))
		draw_style_box(style, Rect2(Vector2.ZERO, size))
	draw_circle(middle, unit * CHIP, Palette.CHIP_GOLD)
	_draw_notches(middle, unit)
	_draw_roads(middle, unit)
	_draw_markings(middle, unit)
	# The neon, GAME.md 8.1: the magenta the chip's rim is lit in, and the cyan ring the Junction
	# wears while a pot is going into it, with the pot itself sitting in the middle of it.
	draw_arc(middle, unit * CHIP, 0.0, TAU, 72, Palette.NEON_MAGENTA, unit * RIM)
	draw_arc(middle, unit * HUB, 0.0, TAU, 32, Palette.NEON_CYAN, unit * RIM * 0.8)
	draw_circle(middle, unit * POT, Palette.CHIP_GOLD)


## The pale notches round the edge of a poker chip, set between the roads rather than across
## them: it is the notches that say chip, and a road running through one says neither.
func _draw_notches(middle: Vector2, unit: float) -> void:
	for quarter: int in 4:
		for i: int in NOTCHES:
			var lean := (float(i) - float(NOTCHES - 1) * 0.5) * NOTCH_APART
			_draw_notch(middle, unit, deg_to_rad(45.0 + 90.0 * float(quarter) + lean))


func _draw_notch(middle: Vector2, unit: float, angle: float) -> void:
	var half := NOTCH_WIDE * 0.5
	var points := PackedVector2Array()
	for step: Array in [[-half, CHIP], [half, CHIP], [half, CHIP - NOTCH_DEPTH]]:
		points.append(middle + Vector2.RIGHT.rotated(angle + step[0]) * unit * (step[1] as float))
	points.append(middle + Vector2.RIGHT.rotated(angle - half) * unit * (CHIP - NOTCH_DEPTH))
	draw_colored_polygon(points, Palette.CHIP_WHITE)


## The crossroads, cut out of the chip rather than laid over it: each band is clipped to the
## chip's own circle, so the four arms end exactly at the rim and the gold is left in quarters.
func _draw_roads(middle: Vector2, unit: float) -> void:
	var chip := PackedVector2Array()
	for i: int in 64:
		chip.append(middle + Vector2.RIGHT.rotated(TAU * float(i) / 64.0) * unit * CHIP)
	var reach := unit * CHIP * 1.2
	var wide := unit * ROAD * 0.5
	for across: bool in [true, false]:
		var span := Vector2(reach, wide) if across else Vector2(wide, reach)
		var band := PackedVector2Array(
			[
				middle + Vector2(-span.x, -span.y),
				middle + Vector2(span.x, -span.y),
				middle + Vector2(span.x, span.y),
				middle + Vector2(-span.x, span.y),
			]
		)
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(band, chip):
			draw_colored_polygon(piece, Palette.ASPHALT)


## The painted line down each arm, stopping short of the junction itself the way a real one does.
func _draw_markings(middle: Vector2, unit: float) -> void:
	for quarter: int in 4:
		var facing := Vector2.RIGHT.rotated(TAU * float(quarter) / 4.0)
		for out: float in DASHES:
			var dash := Vector2(DASH.y, DASH.x) if quarter % 2 == 0 else Vector2(DASH.x, DASH.y)
			var at := middle + facing * unit * out
			draw_rect(Rect2(at - dash * unit * 0.5, dash * unit), Palette.MARKING_CREAM)
