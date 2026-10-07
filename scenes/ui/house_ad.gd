class_name HouseAd
extends SchoolAd
## The Final Hand advertised on the title while it is due, STORY.md 8.1: a flyer at Play cut like
## the driving school's at its own button, GAME.md 3.8, in the House's gold rather than the
## school's red, on the House's dark stock: YOUR TABLE IS READY blinking in foil over "One more
## hand. Then we should talk." and "Attendance is voluntary.", the House's mark where the school's
## L is. A click or a tap on it is Play's.

const MARK_SIDE := 54.0


func _ready() -> void:
	super()
	name = "HouseAd"


func _dress() -> void:
	headline_words = StoryLines.FLYER
	line_words = StoryLines.FLYER_LINES[0]
	small_words = StoryLines.FLYER_LINES[1]
	fill = HouseTheme.STOCK_RAISED
	edge = HouseTheme.FOIL
	headline_ink = HouseTheme.FOIL_HIGH
	ink = HouseTheme.WORDS
	faint = HouseTheme.QUIET
	finish = "pane"


## The House's mark, the seal, where the school has its L.
func _mark() -> Control:
	var mark := LogoArt.new()
	mark.plate = false
	mark.custom_minimum_size = Vector2(MARK_SIDE, MARK_SIDE)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return mark
