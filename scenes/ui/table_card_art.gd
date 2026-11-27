class_name TableCardArt
extends RefCounted
## The face of a card of the table, GAME.md 3.17: a playing card of the House's cream stock, the
## card's own picture in its middle and its name under it in ink. The same face in the match
## settings, on the payout slip's coupon and on the loading screen, 8.6.

## How a card stands, a playing card's own proportions, and how round its corners are.
const ASPECT := 1.4
const CORNER := 0.09
## How much of a card's width its picture takes, and how far down the card it starts.
const PICTURE := 0.64
const PICTURE_TOP := 0.11
## The name's size as a share of the card's width, and the most it is, whatever the card.
const NAME := 0.14
const NAME_MOST := 17
## A card that cannot be played, Suits & hands without Jokers or one not opened yet, under a wash
## of its own paper this strong.
const DIM := 0.62
## Each card's drawing, in [enum TableCards.Card] order, and the ink it is printed in, one for each
## so the row reads at a glance: a power-up's box, the jackpot's pile, the jester's hat, the four
## suits' pads, a pinball bumper, a slot machine, the crown the leader wears and a suited hand.
const PICTURES: Array[StringName] = [
	&"table_power_ups",
	&"table_jackpot",
	&"table_jokers",
	&"table_royal_flush",
	&"table_room_tricks",
	&"table_slot_machines",
	&"table_bounty",
	&"table_suits_and_hands",
]
const INKS: Array[Color] = [
	Color("#2f5ea8"),
	Color("#2c7a52"),
	Color("#7a3f9e"),
	Color("#b8332c"),
	Color("#1f7f86"),
	Color("#c8502a"),
	Color("#b07a1e"),
	Color("#2a2830"),
]

static var _paper: StyleBoxFlat


## The face of [param card] in [param box], dimmed where [param dim].
static func face(on: CanvasItem, box: Rect2, card: int, dim := false) -> void:
	if _paper == null:
		_paper = StyleBoxFlat.new()
		_paper.bg_color = HouseTheme.PAPER
		_paper.border_color = HouseTheme.PAPER_LOW
		_paper.set_border_width_all(1)
		_paper.anti_aliasing = true
	_paper.set_corner_radius_all(roundi(box.size.x * CORNER))
	on.draw_style_box(_paper, box)
	var side := box.size.x * PICTURE
	var art := Rect2(
		box.position + Vector2((box.size.x - side) * 0.5, box.size.y * PICTURE_TOP),
		Vector2(side, side)
	)
	picture(on, art, card)
	var font := Type.display_font()
	var size := mini(roundi(box.size.x * NAME), NAME_MOST)
	var named := Lang.t(TableCards.NAMES[card]).to_upper()
	var top := art.end.y + box.size.y * 0.04
	var lines := PackedStringArray([named])
	if font.get_string_size(named, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > box.size.x * 0.9:
		lines = _two_lines(named)
	for i: int in lines.size():
		var baseline := top + float(size) * (Type.CAP_HEIGHT + 0.25) + float(i) * float(size) * 0.95
		on.draw_string(
			font,
			Vector2(box.position.x, baseline),
			lines[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			box.size.x,
			size,
			HouseTheme.INK
		)
	if dim:
		var wash := _paper.duplicate() as StyleBoxFlat
		wash.bg_color = Color(HouseTheme.PAPER_LOW, DIM)
		wash.border_color = Color(0, 0, 0, 0)
		on.draw_style_box(wash, box)


## [param card] not opened yet, 8.9a: its face grayed, a padlock over its picture and its foot a
## gold band saying after which map the House opens it.
static func sealed(on: CanvasItem, box: Rect2, card: int) -> void:
	face(on, box, card, true)
	var side := box.size.x * 0.4
	var art_middle := box.position.y + box.size.y * PICTURE_TOP + box.size.x * PICTURE * 0.5
	var lock := Rect2(
		Vector2(box.get_center().x - side * 0.5, art_middle - side * 0.5), Vector2.ONE * side
	)
	IconPress.draw(on, lock, &"ui_padlock", HouseTheme.INK, IconPress.Ground.PAPER)
	var band := band_of(box)
	for piece: PackedVector2Array in band_shape(box):
		on.draw_colored_polygon(piece, Palette.CHIP_GOLD)
	var size := roundi(band.size.y * 0.7)
	on.draw_string(
		Type.display_font(),
		Vector2(band.position.x, band.get_center().y + size * Type.CAP_HEIGHT * 0.5),
		Lang.t("AFTER MAP %d") % TableCards.opens_after(card),
		HORIZONTAL_ALIGNMENT_CENTER,
		band.size.x,
		size,
		HouseTheme.ON_FOIL
	)


## Where a sealed card's gold band lies across [param box], see [method sealed]: its foot.
static func band_of(box: Rect2) -> Rect2:
	var tall := box.size.y * 0.14
	return Rect2(Vector2(box.position.x, box.end.y - tall), Vector2(box.size.x, tall))


## A sealed card's gold band in [param box] as drawn: the card's foot, its own rounded corners and
## all, so the band is of the card's shape rather than a strip standing out past its corners.
static func band_shape(box: Rect2) -> Array[PackedVector2Array]:
	var band := band_of(box)
	var inside := FeltArt.rounded(box, roundi(box.size.x * CORNER))
	var across := PackedVector2Array(
		[
			band.position,
			Vector2(band.end.x, band.position.y),
			band.end,
			Vector2(band.position.x, band.end.y)
		]
	)
	return Geometry2D.intersect_polygons(inside, across)


## [param named] broken into two lines at the space nearest its middle.
static func _two_lines(named: String) -> PackedStringArray:
	var best := -1
	for i: int in named.length():
		if (
			named[i] == " "
			and (best < 0 or absi(i * 2 - named.length()) < absi(best * 2 - named.length()))
		):
			best = i
	if best < 0:
		return PackedStringArray([named])
	return PackedStringArray([named.left(best), named.substr(best + 1)])


## The picture of [param card] in the square [param box]: its drawing of 8.3a, in its own ink,
## printed in two inks on the card's stock.
static func picture(on: CanvasItem, box: Rect2, card: int) -> void:
	IconPress.draw(on, box, PICTURES[card], INKS[card], IconPress.Ground.TWO_INKS, HouseTheme.PAPER)
