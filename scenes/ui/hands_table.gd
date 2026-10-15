class_name HandsTable
extends Control
## The pay table of the hands, GAME.md 7.3 and 8.3, beside the hand while its key is held, Tab or a
## pad's Y: every hand with its cards, what it pays, the ones the hand makes lit, and for the next
## one up the hand's own suit how many cards it still wants. Shown only with one seat at the
## screen, two hands sharing it having no room for it, see [JokerHand]. Drawn as one picture, kept
## for the run for what it shows, see [KeptPictures].

const SIZE := Vector2(340.0, 200.0)
## How far down the first row is, how tall a row is, how big its cards are, and where its name and
## its pay start.
const TOP := 34.0
const ROW := 27.0
const CARD := Vector2(13.0, 18.0)
const NAME_AT := 82.0
const PAYS_AT := 186.0
## The back, a made hand's band, and the words of a made and an unmade one and of the one wanted.
const BACK := Color(0.07, 0.07, 0.09, 0.86)
const MADE_BAND := Color(1.0, 0.75, 0.25, 0.06)
const UNMADE := Color(1.0, 1.0, 1.0, 0.55)
const WANTED := Color(1.0, 0.8, 0.4)
const HEAD := "HANDS"
const WANTS := "%d more %s"
const PICTURES := &"hands_table_pictures"

var _made: Array[int] = []
var _wanted: Array = []


## The table as a picture, for [KeptPictures].
class Picture:
	extends Control

	var made: Array[int] = []
	var wanted: Array = []
	var scale_by := 1.0

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_by)
		HandsTable.paint(self, made, wanted)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	add_to_group(PICTURES)


## Shows the hands [param jokers] makes, and what the next one up wants.
func show_hand(jokers: Array[Joker]) -> void:
	var made := JokerHands.of(jokers).hands
	var wanted := JokerHands.next_up(jokers)
	if made != _made or wanted != _wanted:
		_made = made
		_wanted = wanted
		queue_redraw()


## The table on [param on] from its origin: [param made] lit, and [param wanted], the next hand up,
## its cards and suit, said.
static func paint(on: CanvasItem, made: Array[int], wanted: Array) -> void:
	var back := StyleBoxFlat.new()
	back.bg_color = BACK
	back.set_corner_radius_all(6)
	back.set_border_width_all(1)
	back.border_color = Color(Palette.CHIP_GOLD, 0.45)
	on.draw_style_box(back, Rect2(Vector2.ZERO, SIZE))
	var font := Type.STRONG
	on.draw_string(font, Vector2(12.0, 21.0), HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UNMADE)
	for hand: int in JokerHands.Hand.size():
		var y := TOP + hand * ROW
		var lit := hand in made
		if lit:
			on.draw_rect(Rect2(4.0, y - 2.0, SIZE.x - 8.0, ROW - 1.0), MADE_BAND)
		HandsArt.fan(on, Vector2(12.0, y + 11.0), JokerHands.SHOWN[hand], CARD)
		var ink := Palette.CHIP_GOLD if lit else UNMADE
		var named := JokerHands.name_of(hand).to_upper()
		on.draw_string(
			font, Vector2(NAME_AT, y + 16.0), named, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink
		)
		var said := JokerHands.PAYS[hand]
		var said_ink := Color(1.0, 1.0, 1.0, 0.75)
		if not wanted.is_empty() and wanted[0] == hand:
			said = WANTS % [wanted[1], JokerSuits.SYMBOLS[wanted[2]]]
			said_ink = WANTED
		var room := SIZE.x - PAYS_AT - 8.0
		on.draw_string(
			font, Vector2(PAYS_AT, y + 16.0), said, HORIZONTAL_ALIGNMENT_LEFT, room, 12, said_ink
		)


func _draw() -> void:
	var scale_by := maxf(KeptPictures.scale_of(self), 0.25)
	var pixels := Vector2i((SIZE * scale_by).ceil())
	var made := _made
	var wanted := _wanted
	var picture := KeptPictures.of(
		self,
		"hands_table|%s|%s" % [made, wanted],
		pixels,
		func() -> Control:
			var drawing := Picture.new()
			drawing.made = made
			drawing.wanted = wanted
			drawing.scale_by = scale_by
			return drawing,
		PICTURES
	)
	if picture == null:
		paint(self, made, wanted)
		return
	draw_texture_rect(picture, Rect2(Vector2.ZERO, SIZE), false)
