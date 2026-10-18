class_name PinPicture
extends Control
## A picture of what a pin gives, for the House's first look, GAME.md 8.9: a bet's name and count
## along its little road as a match shows it pinned, drawn by what draws the thing itself. Beside
## a match's clock as the strip hangs there, see [PinnedStrip], or on a screen with no room for the
## strip, a phone's, the pause menu's note, see [PinnedNote]; a caption in the House's capitals
## over it saying where it is, all of it on a pane of the dark the arena's top is.

const BY_THE_CLOCK := "IN A MATCH, BY THE CLOCK"
const IN_THE_MENU := "IN THE PAUSE MENU"
## The room round it inside its pane, the caption's line, and the gap between the clock and the
## strip, which a match leaves wider for Kit's scrap.
const ROOM := 16.0
const CAPTION := 30.0
const BESIDE := 22.0
const PANE := Color(0.06, 0.06, 0.09, 0.96)

## What it says: the bet's name and count, its bet, its road's share; and whether it is the strip
## by the clock or the menu's note.
var words: Array[String] = []
var bet := ""
var share := 0.0
var strip := true

var _clock: ClockBoard


## A picture of [param id] on [param of]'s map as a pin shows it, the strip where a screen
## [param wide] has room for it and the note otherwise.
static func of(of_profile: Profile, id: StringName, wide: float) -> PinPicture:
	var picture := PinPicture.new()
	picture.name = "PinPicture"
	picture.words = Loyalty.words_of(of_profile, id)
	var landmark := Loyalty.map().landmark(id)
	picture.bet = Loyalty.bet_of(landmark) if landmark != null else ""
	picture.share = Loyalty.nearness(of_profile, landmark) if landmark != null else 0.0
	picture.strip = PinnedStrip.room_for_it(wide)
	return picture


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if strip:
		_clock = ClockBoard.new()
		_clock.name = "Clock"
		_clock.text = "4:55"
		add_child(_clock)
	custom_minimum_size = wanted()
	size = custom_minimum_size
	if _clock != null:
		_clock.position = Vector2(ROOM, ROOM + CAPTION)
	ScreenReader.name(self, ScreenReader.spoken(_caption()), ScreenReader.line(words))


## How big it is: its pane round the caption and the clock and strip, or the note.
func wanted() -> Vector2:
	if strip:
		var across := ClockBoard.TOP + BESIDE + PinnedStrip.BESIDE_SIZE.x
		var down := maxf(ClockBoard.TALL, PinnedStrip.BESIDE_SIZE.y)
		return Vector2(across, down + CAPTION) + Vector2.ONE * ROOM * 2.0
	return PinnedNote.SIZE + Vector2(0.0, CAPTION) + Vector2.ONE * ROOM * 2.0


func _caption() -> String:
	return BY_THE_CLOCK if strip else IN_THE_MENU


func _draw() -> void:
	var pane := StyleBoxFlat.new()
	pane.bg_color = PANE
	pane.set_corner_radius_all(6)
	pane.set_border_width_all(2)
	pane.border_color = Color(HouseTheme.FOIL, 0.55)
	draw_style_box(pane, Rect2(Vector2.ZERO, size))
	var font := Type.display_font()
	draw_string(
		font,
		Vector2(ROOM, ROOM + Type.LABEL + 2.0),
		_caption(),
		HORIZONTAL_ALIGNMENT_LEFT,
		size.x - ROOM * 2.0,
		Type.LABEL + 1,
		HouseTheme.FOIL
	)
	var at := Vector2(ROOM, ROOM + CAPTION)
	if strip:
		at.x += ClockBoard.TOP + BESIDE
		draw_set_transform(at)
		PinnedStrip.draw_strip(self, PinnedStrip.BESIDE_SIZE, words, share, false)
	else:
		draw_set_transform(at)
		PinnedNote.draw_note(self, words, bet, share, false)
	draw_set_transform(Vector2.ZERO)
