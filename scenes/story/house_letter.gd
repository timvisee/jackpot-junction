class_name HouseLetter
extends Control
## One of the House's letters, STORY.md 6.11: a form letter on its cream letterhead, JACKPOT
## JUNCTION and THE HOUSE at its head under a double rule of gold, typed, the House's labels and
## values with dots run between them; or the Operator's duties, a card the size of a license, dark,
## typed in gold. Shown at the title by [HouseMail] and kept in Kit's folder, see [FolderBack]. Its
## back is bare paper with the letterhead showing through, backward, or the card's the House's seal.
## Drawn in code at its size, see [method size_of].

const LETTER := Vector2(760.0, 980.0)
const CARD := Vector2(680.0, 428.0)
const ROOM := 64.0
const CARD_ROOM := 44.0
const BODY := 21
const CARD_BODY := 19
const STEP := 36.0
const CARD_STEP := 34.0
const NAME := "JACKPOT JUNCTION"
const HOUSE := "THE HOUSE"
const CARD_INK := Color(0.11, 0.1, 0.13)
## What every letter carries besides its lines: its reference and date under the letterhead, the
## House's seal pressed in gold low on the right, and the line along its foot.
const REFERENCE := "REF. %s"
const FOOT := "THIS LETTER REMAINS THE PROPERTY OF THE HOUSE  ·  NO REPLY IS REQUIRED"
const OPERATOR := "OPERATOR %s"

var key: StringName = &"statement"
var profile: Profile
## Whether it is seen from the back, as Kit's folder turns it over.
var face_down := false

var _lines: Array[PackedStringArray] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Letter [param of_key] to [param to], filled in for them.
static func of(of_key: StringName, to: Profile) -> HouseLetter:
	var letter := HouseLetter.new()
	letter.key = of_key
	letter.profile = to
	letter.size = size_of(of_key)
	letter.custom_minimum_size = letter.size
	# Scaled about its middle, as the folder lays what it keeps, see [FolderBack].
	letter.pivot_offset = letter.size * 0.5
	return letter


## How big letter [param of_key] is drawn: a letter's sheet, or a card the size of a license.
static func size_of(of_key: StringName) -> Vector2:
	return CARD if is_card(of_key) else LETTER


## Whether letter [param of_key] is a card rather than a letter.
static func is_card(of_key: StringName) -> bool:
	return bool(StoryLines.HOUSE_LETTERS.get(of_key, {}).get("card", false))


func _ready() -> void:
	_lines = StoryLetters.lines_for(key, profile)


func _draw() -> void:
	if is_card(key):
		_draw_card()
		return
	draw_rect(Rect2(Vector2(6.0, 10.0), size), Color(0.0, 0.0, 0.0, 0.4))
	draw_rect(Rect2(Vector2.ZERO, size), HouseTheme.PAPER)
	draw_rect(Rect2(Vector2.ZERO, size), Color(HouseTheme.PAPER_LOW, 0.8), false, 2.0)
	if face_down:
		# The letterhead showing through the paper, backward and faint.
		draw_set_transform(Vector2(size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
		_draw_head(0.12)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	_draw_head(1.0)
	var y := 230.0
	var heading := str(StoryLines.HOUSE_LETTERS[key].get("heading", ""))
	if not heading.is_empty():
		draw_string(
			NotePage.TYPED,
			Vector2(ROOM, y),
			heading,
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x - ROOM * 2.0,
			BODY + 4,
			HouseTheme.INK
		)
		y += STEP * 1.6
	var bottom := _write(
		Rect2(ROOM, y, size.x - ROOM * 2.0, size.y - y), BODY, STEP, HouseTheme.INK
	)
	if bool(StoryLines.HOUSE_LETTERS[key].get("signed", false)):
		draw_string(
			Type.display_font(),
			Vector2(ROOM, bottom + STEP),
			StoryLines.WELCOME_SIGNED,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			30,
			HouseTheme.INK
		)
	_draw_reference()
	_draw_seal(Vector2(size.x - 150.0, size.y - 190.0), 1.0)
	draw_string(
		Type.micro_font(),
		Vector2(ROOM, size.y - 40.0),
		FOOT,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x - ROOM * 2.0,
		11,
		HouseTheme.INK_FAINT
	)


## Under the letterhead: the reference, the player's license number, at the left, and the day at
## the right, typed small.
func _draw_reference() -> void:
	var number := profile.license_number if profile != null else ""
	var font := NotePage.TYPED
	draw_string(font, Vector2(ROOM, 196.0), REFERENCE % number, 0, -1, 15, HouseTheme.INK_FAINT)
	var day := LicenseCard.today()
	var wide := font.get_string_size(day, 0, -1, 15).x
	draw_string(font, Vector2(size.x - ROOM - wide, 196.0), day, 0, -1, 15, HouseTheme.INK_FAINT)


## The House's seal pressed in gold at [param middle]: its rings and its star, at [param scale].
func _draw_seal(middle: Vector2, scale: float) -> void:
	var ink := Color(HouseTheme.FOIL_LOW, 0.75)
	for ring: float in [56.0, 44.0, 20.0]:
		draw_arc(middle, ring * scale, 0.0, TAU, 64, ink, 2.2, true)
	var star := PackedVector2Array()
	for i: int in 10:
		var reach := (12.0 if i % 2 == 0 else 5.0) * scale
		star.append(middle + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * reach)
	draw_colored_polygon(star, ink)


## The letterhead: the name in the display face, THE HOUSE under it in gold, and a double rule.
func _draw_head(alpha: float) -> void:
	var display := Type.display_font()
	var wide := size.x - ROOM * 2.0
	draw_string(
		display,
		Vector2(ROOM, 108.0),
		NAME,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide,
		52,
		Color(HouseTheme.INK, alpha)
	)
	draw_string(
		Type.micro_font(),
		Vector2(ROOM, 142.0),
		HOUSE,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide,
		15,
		Color(HouseTheme.FOIL_LOW, alpha)
	)
	for y: float in [160.0, 165.0]:
		draw_line(
			Vector2(ROOM, y),
			Vector2(size.x - ROOM, y),
			Color(HouseTheme.FOIL_LOW, 0.7 * alpha),
			1.2 if y > 160.0 else 2.2
		)


## The duties: a dark card edged in gold, typed in gold, or its back, the House's seal.
func _draw_card() -> void:
	var card := StyleBoxFlat.new()
	card.bg_color = CARD_INK
	card.set_corner_radius_all(18)
	card.set_border_width_all(3)
	card.border_color = HouseTheme.FOIL
	card.anti_aliasing = true
	draw_style_box(card, Rect2(Vector2.ZERO, size))
	if face_down:
		var middle := size * 0.5
		for ring: float in [64.0, 50.0, 24.0]:
			draw_arc(middle, ring, 0.0, TAU, 64, HouseTheme.FOIL, 2.4, true)
		return
	var heading := str(StoryLines.HOUSE_LETTERS[key].get("heading", ""))
	draw_string(
		NotePage.TYPED,
		Vector2(CARD_ROOM, 70.0),
		heading,
		HORIZONTAL_ALIGNMENT_LEFT,
		size.x - CARD_ROOM * 2.0,
		CARD_BODY + 3,
		HouseTheme.FOIL
	)
	draw_line(
		Vector2(CARD_ROOM, 88.0),
		Vector2(size.x - CARD_ROOM, 88.0),
		Color(HouseTheme.FOIL, 0.6),
		1.4
	)
	_write(
		Rect2(CARD_ROOM, 136.0, size.x - CARD_ROOM * 2.0, size.y - 136.0),
		CARD_BODY,
		CARD_STEP,
		HouseTheme.FOIL
	)
	var number := profile.license_number if profile != null else ""
	draw_string(
		NotePage.TYPED,
		Vector2(CARD_ROOM, size.y - 36.0),
		OPERATOR % number,
		0,
		-1,
		15,
		Color(HouseTheme.FOIL, 0.7)
	)
	_draw_seal(Vector2(size.x - 96.0, size.y - 92.0), 0.9)


## The lines down [param area], typed: a label and its value with dots run between them, or a line
## alone wrapped to the width, an empty one a gap; where the last of them ends.
func _write(area: Rect2, type_size: int, step: float, ink: Color) -> float:
	var font := NotePage.TYPED
	var y := area.position.y
	for line: PackedStringArray in _lines:
		if line.size() >= 2:
			_leader(line[0], line[1], font, type_size, ink, area.position.x, y, area.size.x)
			y += step
			continue
		var words := line[0] if line.size() == 1 else ""
		if words.is_empty():
			y += step * 0.5
			continue
		var rows := LoyaltyArt.lines_of(font, words, type_size, area.size.x, 6)
		for row: String in rows:
			draw_string(font, Vector2(area.position.x, y), row, 0, -1, type_size, ink)
			y += step * (0.8 if row != rows[rows.size() - 1] else 1.0)
	return y


## [param label] at [param x], [param value] flush right at [param width], and dots between them.
func _leader(
	label: String,
	value: String,
	font: Font,
	type_size: int,
	ink: Color,
	x: float,
	y: float,
	width: float
) -> void:
	var said := font.get_string_size(value, 0, -1, type_size).x
	var led := font.get_string_size(label + " ", 0, -1, type_size).x
	var dot := font.get_string_size(".", 0, -1, type_size).x
	var room := width - said - led - dot
	var dots := " " + ".".repeat(maxi(int(room / maxf(dot, 1.0)), 2))
	draw_string(font, Vector2(x, y), label + dots, 0, -1, type_size, ink)
	draw_string(font, Vector2(x + width - said, y), value, 0, -1, type_size, ink)
