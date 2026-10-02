class_name SealWords
extends Control
## The words round the ring of the hologram on the back of the license, GAME.md 9.4a, the way a
## seal or a coin has them: one word over the top and the other along the foot, both reading left
## to right and upright, a star between them at either side, and a thin ring inside and outside
## the band they stand in. White on clear, drawn once into a picture for the hologram's shader,
## which strikes them in a foil of their own, see [LicenseCard].

## Where the band's middle runs and how wide it is, as shares of the disc's radius; how much of
## the way round a word may take, in radians; how tall the letters stand in the band; how far
## apart they are, as a share of their size; and how big the stars are, as a share of the band.
const BAND_AT := 0.68
const BAND := 0.3
const SPAN := 2.1
const LETTERS := 0.6
const TRACK := 0.1
const STAR := 0.2
## How tall a capital stands in the face, as a share of its size.
const CAP := 0.727

var top := "JACKPOT"
var bottom := "JUNCTION"


func _draw() -> void:
	var middle := size * 0.5
	var disc := minf(size.x, size.y) * 0.5
	var at := disc * BAND_AT
	var band := disc * BAND
	var ink := Color.WHITE
	var line := maxf(disc * 0.012, 1.0)
	draw_arc(middle, at - band * 0.5, 0.0, TAU, 160, ink, line, true)
	draw_arc(middle, at + band * 0.5, 0.0, TAU, 160, ink, line, true)
	# As tall as the band has room for, and no wider than the way round a word may take.
	var tall := band * LETTERS / CAP
	var widest := maxf(_width(top, 100), _width(bottom, 100))
	var font_size := int(minf(tall, 100.0 * SPAN * at / maxf(widest, 1.0)))
	_word(top, middle, at, font_size, true)
	_word(bottom, middle, at, font_size, false)
	for side: float in [0.0, PI]:
		_star(middle + Vector2.from_angle(side) * at, band * STAR, ink)


## How wide [param word] is at [param font_size], its letters as far apart as they are drawn.
func _width(word: String, font_size: int) -> float:
	var total := 0.0
	for letter: String in word:
		total += Type.DISPLAY.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return total + TRACK * font_size * float(maxi(word.length() - 1, 0))


## [param word] round the circle [param radius] about [param middle], over the top when [param
## over], its letters' tops outward, or along the foot, their tops inward, each a letter at a time
## turned to the circle, the word's middle at the top or the foot.
func _word(word: String, middle: Vector2, radius: float, font_size: int, over: bool) -> void:
	var x := -_width(word, font_size) * 0.5
	var cap := CAP * font_size
	for letter: String in word:
		var wide := Type.DISPLAY.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var along := (x + wide * 0.5) / radius
		var angle := -PI * 0.5 + along if over else PI * 0.5 - along
		var turned := angle + PI * 0.5 if over else angle - PI * 0.5
		draw_set_transform(middle + Vector2.from_angle(angle) * radius, turned)
		draw_string(
			Type.DISPLAY,
			Vector2(-wide * 0.5, cap * 0.5),
			letter,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			Color.WHITE
		)
		x += wide + TRACK * font_size
	draw_set_transform(Vector2.ZERO)


## A five-pointed star [param outer] across from its middle to a point, at [param at].
func _star(at: Vector2, outer: float, ink: Color) -> void:
	var points := PackedVector2Array()
	for i: int in 10:
		var reach := outer if i % 2 == 0 else outer * 0.42
		points.append(at + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * reach)
	draw_colored_polygon(points, ink)
