class_name HandsSheet
extends Control
## The catalog's page of the hands, GAME.md 7.3 and 8.8, printed on its sheet as a pay table: a
## head, a line on how the hands pay, and a row for every hand, the best first, its cards fanned,
## its name, what it is, what it pays and how often the profile has made it. One picture, kept for
## the run for its width and what it says, see [KeptPictures].

const HEAD := "WHAT THE HOUSE PAYS"
const LINE := (
	"A hand pays as well as its jokers. Wild cards join the suit you hold most of; every hand you "
	+ "make pays at once."
)
const NOT_MADE := "Not made yet"
const MADE_ONCE := "Made once"
const MADE := "Made %d times"
## How far in its words are, how tall its head is and a row, how big a row's cards are, and where
## the name, the pay and the count start.
const INSIDE := 24.0
const HEAD_TALL := 88.0
const ROW := 86.0
const CARD := Vector2(38.0, 54.0)
const NAME_AT := 220.0
const PAYS_SHARE := 0.42
const MADE_FROM_END := 190.0
const PICTURES := &"hands_sheet_pictures"

## How many times the profile made each hand, by [enum JokerHands.Hand].
var made: Array[int] = []


## The sheet as a picture, for [KeptPictures].
class Picture:
	extends Control

	var made: Array[int] = []
	var wide := 0.0
	var scale_by := 1.0

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_by)
		HandsSheet.paint(self, wide, made)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_to_group(PICTURES)


func _get_minimum_size() -> Vector2:
	return Vector2(0.0, HEAD_TALL + ROW * JokerHands.Hand.size() + INSIDE)


## The pay table [param wide] across on [param on] from its origin, [param made] each hand's count.
static func paint(on: CanvasItem, wide: float, made: Array[int]) -> void:
	var display := Type.display_font()
	var ink := HouseTheme.INK
	var faint := HouseTheme.INK_FAINT
	var gold := HouseTheme.on_paper(Palette.CHIP_GOLD).darkened(0.2)
	on.draw_string(display, Vector2(INSIDE, 40.0), HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, ink)
	var line_room := wide - INSIDE * 2.0
	on.draw_string(
		Type.STRONG, Vector2(INSIDE, 68.0), LINE, HORIZONTAL_ALIGNMENT_LEFT, line_room, 17, faint
	)
	for hand: int in JokerHands.Hand.size():
		var top := HEAD_TALL + hand * ROW
		if hand > 0:
			on.draw_line(Vector2(INSIDE, top), Vector2(wide - INSIDE, top), Color(ink, 0.15), 1.0)
		var middle := top + ROW * 0.5
		HandsArt.fan(on, Vector2(INSIDE + 8.0, middle), JokerHands.SHOWN[hand], CARD)
		var named := JokerHands.name_of(hand).to_upper()
		on.draw_string(
			display, Vector2(NAME_AT, middle - 4.0), named, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, ink
		)
		on.draw_string(
			Type.STRONG,
			Vector2(NAME_AT, middle + 22.0),
			JokerHands.IS[hand],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			17,
			faint
		)
		var pays_at := maxf(wide * PAYS_SHARE, NAME_AT + 260.0)
		var room := wide - MADE_FROM_END - pays_at - 16.0
		on.draw_string(
			Type.STRONG,
			Vector2(pays_at, middle + 8.0),
			JokerHands.PAYS[hand],
			HORIZONTAL_ALIGNMENT_LEFT,
			room,
			22,
			gold
		)
		var times := made[hand] if hand < made.size() else 0
		var said := NOT_MADE if times == 0 else (MADE_ONCE if times == 1 else MADE % times)
		on.draw_string(
			Type.STRONG,
			Vector2(wide - MADE_FROM_END, middle + 8.0),
			said,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			17,
			faint
		)


func _draw() -> void:
	var wide := size.x
	if wide <= 0.0:
		return
	var scale_by := maxf(KeptPictures.scale_of(self), 0.25)
	var pixels := Vector2i((size * scale_by).ceil())
	var counts := made
	var picture := KeptPictures.of(
		self,
		"hands_sheet|%d|%s" % [roundi(wide), counts],
		pixels,
		func() -> Control:
			var drawing := Picture.new()
			drawing.made = counts
			drawing.wide = wide
			drawing.scale_by = scale_by
			return drawing,
		PICTURES
	)
	if picture == null:
		paint(self, wide, made)
		return
	draw_texture_rect(picture, Rect2(Vector2.ZERO, size), false)
