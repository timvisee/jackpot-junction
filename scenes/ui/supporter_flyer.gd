class_name SupporterFlyer
extends Control
## The Steam supporter pack's flyer, GAME.md 10.8, taped up in the Garage's bay where the pack is
## offered and not owned, which the thank-you card takes the place of once the pack is bought, see
## [BaySet]: cream stock in a night-blue rim, the pack's star, its name in the house's display
## letters and a line in red pen under it. Drawn at the card's size, [constant ThankYouCard.SIZE].

const SIZE := ThankYouCard.SIZE
const NAME := "SUPPORTER PACK"
const LINE := "Chip in, wear your thanks"
const RED := Color("#b8402f")
## Where the star stands and how big it is, and how big the name and the line are.
const STAR_AT := Vector2(330.0, 140.0)
const STAR := 64.0
const NAME_SIZE := 70
const LINE_SIZE := 38


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, SIZE)
	draw_rect(box, ThankYouCard.CARD)
	draw_rect(box.grow(-16.0), PartTray.SUPPORTER_TAPE, false, 6.0)
	PartTray.draw_star(self, STAR_AT, STAR)
	_centered(Type.display_font(), NAME, 300.0, NAME_SIZE, PartTray.SUPPORTER_TAPE)
	_centered(BayArt.hand_font(), LINE, 372.0, LINE_SIZE, RED)


## [param words] in [param font] at [param tall], across the middle with their foot at [param y].
func _centered(font: Font, words: String, y: float, tall: int, ink: Color) -> void:
	var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, tall).x
	draw_string(
		font, Vector2((SIZE.x - wide) / 2.0, y), words, HORIZONTAL_ALIGNMENT_LEFT, -1, tall, ink
	)
