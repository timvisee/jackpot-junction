class_name HandsTable
extends Control
## The pay table of the hands, GAME.md 7.3 and 8.3, beside the hand while its key is held, Tab or a
## pad's Y: every hand with its cards, what it pays, the ones the hand makes lit, and for the next
## one up the hand's own suit how many cards it still wants. Shown only with one seat at the
## screen, two hands sharing it having no room for it, see [JokerHand]. Drawn as one picture, kept
## for the run for what it shows, see [KeptPictures].

const SIZE := Vector2(392.0, 222.0)
## How far down the first row is, how tall a row is, how big its cards are, where its name and its
## pay start, and how big their words are.
const TOP := 38.0
const ROW := 30.0
const CARD := Vector2(15.0, 21.0)
const NAME_AT := 92.0
const PAYS_AT := 222.0
const NAME_SIZE := 15
const PAYS_SIZE := 14
const HEAD_SIZE := 14
## The back, a made hand's band and the bar at its left, and the words of a made and an unmade one
## and of the one wanted.
const BACK := Color(0.07, 0.07, 0.09, 0.9)
const MADE_BAND := Color(1.0, 0.75, 0.25, 0.16)
const MADE_BAR := 3.0
const UNMADE := Color(1.0, 1.0, 1.0, 0.6)
const WANTED := Color(1.0, 0.8, 0.4)
const HEAD := "HANDS"
const WANTS := "%d more %s"
const PICTURES := &"hands_table_pictures"

var _made: Array[int] = []
var _wanted: Array = []
## Shared between two players at one screen, see [method show_shared]: each player's color and the
## hands theirs makes, a bar of that color by each; empty for a table of one player's own.
var _marks: Array = []


## The table as a picture, for [KeptPictures].
class Picture:
	extends Control

	var made: Array[int] = []
	var wanted: Array = []
	var marks: Array = []
	var scale_by := 1.0

	func _draw() -> void:
		var base := Transform2D().scaled(Vector2.ONE * scale_by)
		HandsTable.paint(self, made, wanted, base, marks)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	add_to_group(PICTURES)


## Shows the hands [param jokers] makes, and what the next one up wants.
func show_hand(jokers: Array[Joker]) -> void:
	var made := JokerHands.of(jokers).hands
	var wanted := JokerHands.next_up(jokers)
	if made != _made or wanted != _wanted or not _marks.is_empty():
		_made = made
		_wanted = wanted
		_marks = []
		queue_redraw()


## Shows the table shared by two players at one screen, GAME.md 8.3: [param marks], each player's
## color and the hands theirs makes, every hand made by either lit with a bar of each maker's color
## by it; and [param wanted] the next hand up of the one player holding their key, or nothing.
func show_shared(marks: Array, wanted: Array) -> void:
	var made: Array[int] = []
	for mark: Array in marks:
		for hand: int in mark[1]:
			if hand not in made:
				made.append(hand)
	made.sort()
	if made != _made or wanted != _wanted or str(marks) != str(_marks):
		_made = made
		_wanted = wanted
		_marks = marks.duplicate(true)
		queue_redraw()


## The table on [param on] from the origin of [param base], the transform it is drawn with: [param
## made] lit, and [param wanted], the next hand up, its cards and suit, said.
static func paint(
	on: CanvasItem, made: Array[int], wanted: Array, base := Transform2D(), marks: Array = []
) -> void:
	on.draw_set_transform_matrix(base)
	# Standing on the screen's edge: its top corners rounded and no edge along its foot.
	var back := StyleBoxFlat.new()
	back.bg_color = BACK
	back.corner_radius_top_left = 8
	back.corner_radius_top_right = 8
	back.border_width_top = 1
	back.border_width_left = 1
	back.border_width_right = 1
	back.border_color = Color(Palette.CHIP_GOLD, 0.5)
	on.draw_style_box(back, Rect2(Vector2.ZERO, SIZE))
	var font := Type.STRONG
	var head_wide := font.get_string_size(HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1, HEAD_SIZE).x
	var head_at := Vector2((SIZE.x - head_wide) * 0.5, 24.0)
	on.draw_string(font, head_at, HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1, HEAD_SIZE, UNMADE)
	for hand: int in JokerHands.Hand.size():
		var y := TOP + hand * ROW
		var lit := hand in made
		if lit:
			on.draw_rect(Rect2(4.0, y - 2.0, SIZE.x - 8.0, ROW - 2.0), MADE_BAND)
			_draw_bars(on, hand, y, marks)
		HandsArt.fan(on, Vector2(14.0, y + 13.0), JokerHands.SHOWN[hand], CARD, base)
		var ink := Palette.CHIP_GOLD if lit else UNMADE
		var named := JokerHands.name_of(hand).to_upper()
		var row_at := y + 18.0
		on.draw_string(
			font, Vector2(NAME_AT, row_at), named, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, ink
		)
		var said := JokerHands.PAYS[hand]
		var said_ink := Color(1.0, 1.0, 1.0, 0.8)
		if not wanted.is_empty() and wanted[0] == hand:
			said = WANTS % [wanted[1], JokerSuits.SYMBOLS[wanted[2]]]
			said_ink = WANTED
		var room := SIZE.x - PAYS_AT - 8.0
		on.draw_string(
			font,
			Vector2(PAYS_AT, row_at),
			said,
			HORIZONTAL_ALIGNMENT_LEFT,
			room,
			PAYS_SIZE,
			said_ink
		)


## The bar by a made [param hand]'s row at [param y]: gold for one player's own table, and one of
## each maker's color, side by side, for a table [param marks] shares between two.
static func _draw_bars(on: CanvasItem, hand: int, y: float, marks: Array) -> void:
	if marks.is_empty():
		on.draw_rect(Rect2(4.0, y - 2.0, MADE_BAR, ROW - 2.0), Palette.CHIP_GOLD)
		return
	var x := 4.0
	for mark: Array in marks:
		if hand in mark[1]:
			on.draw_rect(Rect2(x, y - 2.0, MADE_BAR + 1.0, ROW - 2.0), mark[0])
			x += MADE_BAR + 3.0


func _draw() -> void:
	var scale_by := maxf(KeptPictures.scale_of(self), 0.25)
	var pixels := Vector2i((SIZE * scale_by).ceil())
	var made := _made
	var wanted := _wanted
	var marks := _marks
	var picture := KeptPictures.of(
		self,
		"hands_table|%s|%s|%s" % [made, wanted, marks],
		pixels,
		func() -> Control:
			var drawing := Picture.new()
			drawing.made = made
			drawing.wanted = wanted
			drawing.marks = marks
			drawing.scale_by = scale_by
			return drawing,
		PICTURES
	)
	if picture == null:
		paint(self, made, wanted, Transform2D(), marks)
		return
	# One of the picture's pixels to one of the screen's, so it is as sharp as drawn as itself.
	draw_texture_rect(picture, Rect2(Vector2.ZERO, Vector2(pixels) / scale_by), false)
