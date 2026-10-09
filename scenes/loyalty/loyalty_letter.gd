class_name LoyaltyLetter
extends Control
## The House's letter welcoming a player to its loyalty program, STORY.md 6.6b: a form letter on
## its cream letterhead, JACKPOT JUNCTION and the program's name at its head, the same to everybody
## bar the name, signed THE HOUSE, the program's card glued on below the lines, see
## [LoyaltyWelcome]. The card is not drawn here, being peeled off it: the letter draws where it is
## glued, a darker shade of the paper the size of the card and two spots of glue on it, and once it
## has been torn off, [member taken], the paper torn up where the glue held it. Drawn in code at
## [constant SIZE].

const SIZE := Vector2(760.0, 980.0)
## Where the card's middle is glued on the letter, and how big the card is on it, a share of its
## own size.
const CARD_AT := Vector2(380.0, 730.0)
const CARD_SCALE := 0.8
const ROOM := 64.0
const BODY := 23
const STEP := 33.0
const NAME := "JACKPOT JUNCTION"
const GLUE := Color(0.74, 0.64, 0.36, 0.5)
## The shade of the paper where the card sits, a little bigger than the card; and the paper torn up
## where the glue held it, its fibers lighter and rough.
const SPOT := Color(0.45, 0.38, 0.26, 0.3)
const SPOT_OUT := 7.0
const TORN := Color(0.99, 0.97, 0.92, 0.95)
const FIBER := Color(0.62, 0.55, 0.42, 0.55)
## Where the two spots of glue are, a share of the card's size either way from its middle.
const GLUED: Array[Vector2] = [Vector2(-0.3, 0.0), Vector2(0.3, 0.0)]

## The program's name and its line, and who the letter is to.
var program := "Loyalty Program"
var line := ""
var to := ""
## Whether the card has been torn off it, the paper torn up where it was glued; and whether it is
## seen from the back, bare paper, as Kit's folder turns it over.
var taken := false
var face_down := false


func _init() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	# Scaled about its middle, as the folder lays what it keeps, see [FolderBack].
	pivot_offset = SIZE * 0.5
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
	if face_down:
		return
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
	_draw_spot()
	draw_string(
		Type.micro_font(),
		Vector2(ROOM, SIZE.y - 40.0),
		line,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide,
		11,
		HouseTheme.INK_FAINT
	)


## Where the card is glued: the paper a shade darker the size of the card, two spots of glue on it,
## and once it has been torn off the paper torn up where the glue held, lighter and rough, a few
## fibers loose round it.
func _draw_spot() -> void:
	var card := LoyaltyCard.SIZE * CARD_SCALE
	var shade := StyleBoxFlat.new()
	shade.bg_color = SPOT
	shade.set_corner_radius_all(int(LoyaltyCard.CORNER * CARD_SCALE + SPOT_OUT))
	shade.anti_aliasing = true
	draw_style_box(shade, Rect2(CARD_AT - card * 0.5, card).grow(SPOT_OUT))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7343
	for spot: Vector2 in GLUED:
		var at := CARD_AT + spot * card
		draw_circle(at, 26.0, GLUE)
		draw_circle(at + Vector2(6.0, -4.0), 16.0, Color(GLUE, 0.3))
		if not taken:
			continue
		var rough := PackedVector2Array()
		for i: int in 18:
			var reach := rng.randf_range(15.0, 27.0)
			rough.append(at + Vector2.from_angle(TAU * i / 18.0) * reach)
		draw_colored_polygon(rough, TORN)
		for i: int in 9:
			var from := at + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(18.0, 26.0)
			var to := from + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(4.0, 10.0)
			draw_line(from, to, FIBER, 1.0, true)
