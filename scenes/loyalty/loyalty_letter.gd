class_name LoyaltyLetter
extends Control
## The House's letter welcoming a player to its loyalty program, STORY.md 6.6b: a form letter on
## its cream letterhead, JACKPOT JUNCTION and the program's name at its head, the same to everybody
## bar the name, signed THE HOUSE, the program's card glued on below the lines, see
## [LoyaltyWelcome]. The card is not drawn here, being peeled off it: the letter draws only where it
## was glued, two spots of glue that stay once it has gone. Drawn in code at [constant SIZE].

const SIZE := Vector2(760.0, 980.0)
## Where the card's middle is glued on the letter, and how big the card is on it, a share of its
## own size.
const CARD_AT := Vector2(380.0, 770.0)
const CARD_SCALE := 0.8
const ROOM := 64.0
const BODY := 23
const STEP := 33.0
const NAME := "JACKPOT JUNCTION"
const GLUE := Color(0.82, 0.74, 0.46, 0.35)

## The program's name and its line, and who the letter is to.
var program := "Loyalty Program"
var line := ""
var to := ""


func _init() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The letter to [param profile], as its screens show the program now.
static func to_profile(profile: Profile) -> LoyaltyLetter:
	var letter := LoyaltyLetter.new()
	letter.program = LoyaltyDialog.program_name(profile)
	letter.line = LoyaltyDialog.program_line(profile)
	letter.to = LoyaltyCard.holder_of(profile)
	return letter


## The letter's paragraphs, the name and the program's name put in.
func paragraphs() -> PackedStringArray:
	var said := PackedStringArray()
	for paragraph: String in StoryLines.WELCOME_LETTER:
		said.append(paragraph.replace("{name}", to).replace("{program}", program))
	return said


func _draw() -> void:
	draw_rect(Rect2(Vector2(6.0, 10.0), SIZE), Color(0.0, 0.0, 0.0, 0.4))
	draw_rect(Rect2(Vector2.ZERO, SIZE), HouseTheme.PAPER)
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(HouseTheme.PAPER_LOW, 0.8), false, 2.0)
	var display := Type.display_font()
	var wide := SIZE.x - ROOM * 2.0
	draw_string(
		display, Vector2(ROOM, 108.0), NAME, HORIZONTAL_ALIGNMENT_CENTER, wide, 52, HouseTheme.INK
	)
	draw_string(
		Type.micro_font(),
		Vector2(ROOM, 142.0),
		program.to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER,
		wide,
		15,
		HouseTheme.FOIL_LOW
	)
	for y: float in [160.0, 165.0]:
		draw_line(
			Vector2(ROOM, y),
			Vector2(SIZE.x - ROOM, y),
			Color(HouseTheme.FOIL_LOW, 0.7),
			1.2 if y > 160.0 else 2.2
		)
	var y := 224.0
	var font := Type.TEXT
	for paragraph: String in paragraphs():
		for words: String in LoyaltyArt.lines_of(font, paragraph, BODY, wide, 12):
			draw_string(
				font, Vector2(ROOM, y), words, HORIZONTAL_ALIGNMENT_LEFT, wide, BODY, HouseTheme.INK
			)
			y += STEP
		y += STEP * 0.45
	draw_string(
		display,
		Vector2(ROOM, y + 14.0),
		StoryLines.WELCOME_SIGNED,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		30,
		HouseTheme.INK
	)
	# Where the card is glued: two spots of glue that stay once it is peeled off.
	var card := LoyaltyCard.SIZE * CARD_SCALE
	for spot: Vector2 in [Vector2(-0.3, 0.0), Vector2(0.3, 0.0)]:
		var at := CARD_AT + spot * card
		draw_circle(at, 26.0, GLUE)
		draw_circle(at + Vector2(6.0, -4.0), 16.0, Color(GLUE, 0.3))
	draw_string(
		Type.micro_font(),
		Vector2(ROOM, SIZE.y - 40.0),
		line,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide,
		11,
		HouseTheme.INK_FAINT
	)
