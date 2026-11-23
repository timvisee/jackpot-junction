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
	var named := TableCards.NAMES[card].to_upper()
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


## [param card] not opened yet, 8.9a: its face grayed, a padlock over its picture and a gold band
## along its foot saying after which map the House opens it.
static func sealed(on: CanvasItem, box: Rect2, card: int) -> void:
	face(on, box, card, true)
	var side := box.size.x * 0.4
	var art_middle := box.position.y + box.size.y * PICTURE_TOP + box.size.x * PICTURE * 0.5
	var lock := Rect2(
		Vector2(box.get_center().x - side * 0.5, art_middle - side * 0.5), Vector2.ONE * side
	)
	IconShapes.arc(on, lock, 0.5, 0.42, 0.26, 180.0, 360.0, HouseTheme.INK)
	IconShapes.bar(on, lock, 0.14, 0.4, 0.72, 0.56, HouseTheme.INK)
	IconShapes.disc(on, lock, 0.5, 0.64, 0.08, Palette.CHIP_GOLD)
	var tall := box.size.y * 0.14
	var band := Rect2(
		Vector2(box.position.x, box.end.y - tall - box.size.y * 0.04), Vector2(box.size.x, tall)
	)
	on.draw_rect(band, Palette.CHIP_GOLD)
	var size := roundi(tall * 0.7)
	on.draw_string(
		Type.display_font(),
		Vector2(band.position.x, band.get_center().y + size * Type.CAP_HEIGHT * 0.5),
		"AFTER MAP %d" % TableCards.opens_after(card),
		HORIZONTAL_ALIGNMENT_CENTER,
		band.size.x,
		size,
		HouseTheme.ON_FOIL
	)


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


## The picture of [param card] in the square [param box].
static func picture(on: CanvasItem, box: Rect2, card: int) -> void:
	match card:
		TableCards.Card.ITEMS:
			_item_box(on, box)
		TableCards.Card.JACKPOT:
			_chip_stack(on, box)
		TableCards.Card.JOKERS:
			JokerSuits.draw_jester(on, box.grow(-box.size.x * 0.06), true)
		TableCards.Card.FLUSH:
			_four_suits(on, box)
		TableCards.Card.TRICKS:
			_bumper(on, box)
		TableCards.Card.SLOTS:
			_reels(on, box)
		TableCards.Card.BOUNTY:
			IconShapes.crown(on, box, HouseTheme.FOIL_LOW)
		TableCards.Card.SUITS:
			_fan(on, box)


## A power-up's box: gold, with a band across its lid and a question mark under it.
static func _item_box(on: CanvasItem, box: Rect2) -> void:
	IconShapes.bar(on, box, 0.12, 0.14, 0.76, 0.74, HouseTheme.INK)
	IconShapes.bar(on, box, 0.17, 0.19, 0.66, 0.64, Palette.CHIP_GOLD)
	IconShapes.bar(on, box, 0.12, 0.34, 0.76, 0.06, HouseTheme.INK)
	CardBack.draw_mark(on, IconShapes.at(box, 0.5, 0.62), roundi(box.size.y * 0.4), HouseTheme.INK)


## Four chips stacked, as a Jackpot's pile is, 3.5.
static func _chip_stack(on: CanvasItem, box: Rect2) -> void:
	var faces: Array[Color] = [
		Palette.CHIP_RED, Palette.CHIPS, Palette.CHIP_WHITE, Palette.CHIP_GOLD
	]
	var radius := box.size.x * 0.3
	for i: int in faces.size():
		var middle := IconShapes.at(box, 0.5 + (0.04 if i % 2 == 1 else -0.03), 0.74 - 0.16 * i)
		on.draw_circle(middle + Vector2(0, radius * 0.12), radius, HouseTheme.INK, true, -1.0, true)
		ChipArt.chip(on, middle, radius, faces[i])


## The four suits of the Royal Flush pads, 3.9, a pad each.
static func _four_suits(on: CanvasItem, box: Rect2) -> void:
	var suits: Array[int] = [
		Joker.Suit.SPADES, Joker.Suit.HEARTS, Joker.Suit.DIAMONDS, Joker.Suit.CLUBS
	]
	for i: int in suits.size():
		var x := 0.05 + 0.48 * (i % 2)
		var y := 0.05 + 0.48 * (i / 2)
		IconShapes.bar(on, box, x, y, 0.42, 0.42, HouseTheme.INK)
		IconShapes.bar(on, box, x + 0.03, y + 0.03, 0.36, 0.36, HouseTheme.PAPER)
		var cell := Rect2(IconShapes.at(box, x + 0.08, y + 0.08), box.size * 0.26)
		JokerSuits.draw_mark(on, cell, suits[i], true)


## A pinball machine's pop bumper seen from over it, 6.2: a room's trick.
static func _bumper(on: CanvasItem, box: Rect2) -> void:
	IconShapes.disc(on, box, 0.5, 0.5, 0.46, HouseTheme.INK)
	IconShapes.disc(on, box, 0.5, 0.5, 0.4, Palette.CHIP_RED)
	IconShapes.disc(on, box, 0.5, 0.5, 0.27, HouseTheme.PAPER)
	IconShapes.star(on, box, 0.5, 0.5, 0.3, Palette.CHIP_GOLD)


## A slot machine's three reels, three sevens, 3.15.
static func _reels(on: CanvasItem, box: Rect2) -> void:
	IconShapes.bar(on, box, 0.0, 0.16, 1.0, 0.68, HouseTheme.INK)
	IconShapes.bar(on, box, 0.04, 0.2, 0.92, 0.6, Palette.CHIP_GOLD)
	var font := Type.display_font()
	var size := roundi(box.size.y * 0.42)
	for i: int in 3:
		var x := 0.08 + 0.29 * i
		IconShapes.bar(on, box, x, 0.27, 0.26, 0.46, HouseTheme.PAPER)
		var at := IconShapes.at(box, x, 0.5 + Type.CAP_HEIGHT * 0.21)
		on.draw_string(
			font,
			at,
			"7",
			HORIZONTAL_ALIGNMENT_CENTER,
			box.size.x * 0.26,
			size,
			HouseTheme.on_paper(Palette.CHIP_RED)
		)


## Three cards fanned, all of one suit: a Suited hand, 7.3. Turned by hand rather than by the
## canvas's transform, which the picture of a face is drawn under, see [TableStrip].
static func _fan(on: CanvasItem, box: Rect2) -> void:
	var pivot := IconShapes.at(box, 0.5, 0.95)
	var half := box.size * Vector2(0.2, 0.28)
	for i: int in 3:
		var turn := (i - 1) * 0.3
		var middle := pivot + Vector2(0.0, -box.size.y * 0.54).rotated(turn)
		for pass_at: int in 2:
			var grow := 1.5 if pass_at == 0 else 0.0
			var corners := PackedVector2Array()
			for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				corners.append(middle + ((half + Vector2.ONE * grow) * corner).rotated(turn))
			on.draw_colored_polygon(corners, HouseTheme.INK if pass_at == 0 else HouseTheme.PAPER)
		var mark := box.size.x * 0.22
		var at := middle + Vector2(0.0, -half.y * 0.35).rotated(turn) - Vector2.ONE * mark * 0.5
		JokerSuits.draw_mark(on, Rect2(at, Vector2.ONE * mark), Joker.Suit.CLUBS, true)
