class_name LicensePlate
extends Control
## The license plate on the back of a kart, GAME.md 4.4: up to eight characters of the holder's
## own choosing, chosen once the license is earned and changed in the settings. Small, on the back
## of a kart or in a list of players, it is a plain plate, the letters in black on pale with a dark
## rim and a bolt in each top corner, which is what reads at that size. Big, where it is chosen,
## it is printed as the house's documents are, GAME.md 8.1a, see [member printed]: the school's
## cream paper with rounded corners, a hairline of ink inside its edge, a screw in each top corner
## with DEPT. OF KARTS in microprint between, and the letters in the condensed capitals,
## spaced a little as a stamped plate's are.
## Drawn, so the same plate serves the box it is typed into and the back of the kart in a match,
## see [method KartVisuals.license_plate].

## How long a plate may be, and what it may hold: letters, digits, a space and a dash, upper
## case, since a plate is stamped and not written.
const MOST := 8
const ALLOWED := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -"  # NO_TRANSLATE
## And the characters a Chinese plate carries, GAME.md 10.9: the short name of a province at its
## front, and at its end a learner's, the police's, a trailer's, Hong Kong's and Macau's, an
## embassy's and a consulate's. No more than two on a plate, each taking two of its places, as a
## Chinese character is drawn twice as wide, see [method PlayerNames.width].
const CHINESE := "京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼学警挂港澳使领"  # NO_TRANSLATE
const MOST_CHINESE := 2
## The star a plate may hold where the Steam supporter pack is owned, GAME.md 10.8: typed as an
## asterisk, or as a star itself, kept as the asterisk and drawn as a five-pointed star, see
## [method draw_words]. Any plate off the wire may hold it, whoever owns what.
const STAR := "*"
const STAR_TYPED := "★"
## What an empty plate reads.
const BLANK := "JJ"
const SIZE := Vector2(224.0, 64.0)
## The plain plate: its plate, its rim, its letters and its bolts.
const PLAIN := Color(0.96, 0.95, 0.9)
const PLAIN_RIM := Color(0.1, 0.1, 0.12)
const PLAIN_INK := Color(0.08, 0.08, 0.1)
const PLAIN_BOLT := Color(0.55, 0.56, 0.6)
## The gold plate the loyalty program pays, GAME.md 8.9: the plate itself gold, a darker gold rim
## and bolts, the letters as black as ever.
const GOLD := Color(0.98, 0.78, 0.2)
const GOLD_RIM := Color(0.55, 0.36, 0.06)
const GOLD_BOLT := Color(0.66, 0.47, 0.12)
## The printed plate: the school's paper, its ink and its bolts.
const PLATE := HouseTheme.PAPER
const RIM := HouseTheme.INK
const INK := HouseTheme.INK
const BOLT := Color("#a59b80")
## What is printed over the letters, shown through tr(), and how far apart the letters stand,
## against the plate's height.
const ISSUER := "DEPT. OF KARTS"
const SPACING := 0.045

var text := ""
## Whether it is the printed plate rather than the plain one, see the top of this script.
var printed := false
## Whether the plain plate is the gold one, see [constant GOLD].
var gold := false


## A plate reading [param words], [param wide] pixels across, the printed one with [param print].
static func of(words: String, wide := SIZE.x, print := false, golden := false) -> LicensePlate:
	var plate := LicensePlate.new()
	plate.text = words
	plate.printed = print
	plate.gold = golden
	plate.custom_minimum_size = Vector2(wide, wide * SIZE.y / SIZE.x)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return plate


## What a kart wears on its back as a list shows it, [param wide] pixels across, see
## [method KartVisuals.plate_worn]: the plate, or for "L" the learner's L itself rather than a plate
## reading L, or for nothing the room a plate would take, so a column of them lines up.
static func badge(worn: String, wide: float) -> Control:
	var room := CenterContainer.new()
	room.custom_minimum_size = Vector2(wide, wide * SIZE.y / SIZE.x)
	room.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if worn == "L":
		var learner := SchoolFigure.of(SchoolFigure.Kind.LEARNER, room.custom_minimum_size.y)
		learner.name = "Learner"
		room.add_child(learner)
	elif not worn.is_empty():
		var plate := LicensePlate.of(worn, wide)
		plate.name = "Plate"
		room.add_child(plate)
	return room


## [param raw] as a plate may read: upper case, nothing a plate cannot hold, one space at a time,
## no longer than [constant MOST], a Chinese character taking two places.
static func clean(raw: String, starred := Supporter.owned()) -> String:
	return clean_typed(raw, starred).strip_edges()


## [param raw] as it is being typed: cleaned as [method clean] does, but a space at the end is left
## standing, since the next letter may be on its way.
static func clean_typed(raw: String, starred := Supporter.owned()) -> String:
	var kept := ""
	var chinese := 0
	for character: String in raw.to_upper().replace(STAR_TYPED, STAR):
		if character in CHINESE:
			if chinese < MOST_CHINESE:
				kept += character
				chinese += 1
		elif character in ALLOWED or (starred and character == STAR):
			kept += character
	while kept.contains("  "):
		kept = kept.replace("  ", " ")
	return PlayerNames.cut(kept.strip_edges(true, false), MOST)


## A plate for [param holder], numbered [param number], to start from: the initials of the name,
## up to three, and the last three digits of the number, "TLT-123".
static func suggest(holder: String, number: String) -> String:
	var letters := ""
	var words := holder.strip_edges().split(" ", false)
	if words.size() >= 2:
		for word: String in words:
			if letters.length() < 3:
				letters += word.substr(0, 1)
	elif words.size() == 1:
		letters = words[0].substr(0, 3)
	letters = clean(letters)
	if letters.is_empty():
		letters = "JJ"
	var digits := ""
	for character: String in number:
		if character.is_valid_int():
			digits += character
	digits = digits.substr(maxi(digits.length() - 3, 0))
	if digits.is_empty():
		return letters
	return "%s-%s" % [letters, digits]


## A plate for a bot called [param trait_name], its digits drawn with [param rng]: "HUN-382" for
## a Hunter, "BOT" and digits for one with no name.
static func for_bot(trait_name: String, rng: RandomNumberGenerator) -> String:
	var called := trait_name if not trait_name.is_empty() else "Bot"  # NO_TRANSLATE
	return suggest(called, "%06d" % rng.randi_range(0, 999999))


## [param worn] as a kart may wear it, off the wire, GAME.md 10.3: nothing, the learner's L, or a
## plate's text cleaned the way a typed one is.
static func valid(worn: String) -> String:
	if worn == "L":
		return worn
	return clean(worn, true)


func set_text(words: String) -> void:
	text = words
	queue_redraw()


func _draw() -> void:
	if not printed:
		_draw_plain()
		return
	var plate := StyleBoxFlat.new()
	plate.bg_color = PLATE
	plate.set_corner_radius_all(roundi(size.y * 0.15))
	plate.anti_aliasing = true
	draw_style_box(plate, Rect2(Vector2.ZERO, size))
	dress(self, size)
	var shown := text if not text.is_empty() else BLANK
	var font := lettering(size.y)
	var font_size := _fitted(font, shown, roundi(size.y * 0.5), size.x - size.y * 0.5)
	# In the middle of the plate under the microprint, by the height of its capitals.
	var baseline := size.y * 0.6 + float(font_size) * Type.CAP_HEIGHT * 0.5
	draw_words(self, font, baseline, shown, font_size, INK)


## The plain plate, for a small one: pale, a dark rim, a bolt in each top corner, the letters in
## the middle of it.
func _draw_plain() -> void:
	var plate := StyleBoxFlat.new()
	plate.bg_color = GOLD if gold else PLAIN
	plate.set_corner_radius_all(roundi(size.y * 0.12))
	plate.set_border_width_all(maxi(roundi(size.y * (0.08 if gold else 0.05)), 1))
	plate.border_color = GOLD_RIM if gold else PLAIN_RIM
	draw_style_box(plate, Rect2(Vector2.ZERO, size))
	var inset := size.y * 0.16
	for x: float in [inset, size.x - inset]:
		draw_circle(Vector2(x, inset), size.y * 0.05, GOLD_BOLT if gold else PLAIN_BOLT)
	var shown := text if not text.is_empty() else BLANK
	var font := Type.display_font()
	var font_size := _fitted(font, shown, roundi(size.y * 0.56), size.x - inset * 3.0)
	var baseline := (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_words(self, font, baseline, shown, font_size, PLAIN_INK)


## [param shown] across the middle of [param on], on [param baseline] in [param font] at
## [param font_size] in [param ink]: its letters as they are, and a supporter's star, see
## [constant STAR], drawn as a five-pointed star as tall as the capitals.
static func draw_words(
	on: Control, font: Font, baseline: float, shown: String, font_size: int, ink: Color
) -> void:
	if not shown.contains(STAR):
		on.draw_string(
			font,
			Vector2(0.0, baseline),
			shown,
			HORIZONTAL_ALIGNMENT_CENTER,
			on.size.x,
			font_size,
			ink
		)
		return
	var cap := float(font_size) * Type.CAP_HEIGHT
	var star_wide := cap * 1.15
	var pieces := shown.split(STAR)
	var wide := star_wide * float(pieces.size() - 1)
	for piece: String in pieces:
		wide += font.get_string_size(piece, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x := (on.size.x - wide) * 0.5
	for i: int in pieces.size():
		on.draw_string(
			font, Vector2(x, baseline), pieces[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink
		)
		x += font.get_string_size(pieces[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if i < pieces.size() - 1:
			var middle := Vector2(x + star_wide * 0.5, baseline - cap * 0.5)
			var points := PackedVector2Array()
			for k: int in 10:
				var reach := cap * (0.62 if k % 2 == 0 else 0.25)
				points.append(middle + Vector2.UP.rotated(TAU * k / 10.0) * reach)
			on.draw_colored_polygon(points, ink)
			x += star_wide


## The biggest size up to [param most] that [param shown] fits [param room] at in [param font].
static func _fitted(font: Font, shown: String, most: int, room: float) -> int:
	var font_size := most
	while (
		font_size > 8
		and font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > room
	):
		font_size -= 1
	return font_size


## What a plate wears over its paper, onto [param canvas] [param plate] big: the hairline of ink
## inside its edge, a bolt either side at its top, and the issuer in microprint between them. Shared
## with the plate that is a text box, see [PlateField].
static func dress(canvas: CanvasItem, plate: Vector2) -> void:
	var h := plate.y
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.set_border_width_all(maxi(roundi(h * 0.03), 1))
	frame.border_color = Color(RIM, 0.7)
	frame.set_corner_radius_all(roundi(h * 0.1))
	frame.anti_aliasing = true
	var inset := h * 0.075
	canvas.draw_style_box(frame, Rect2(Vector2.ONE * inset, plate - Vector2.ONE * inset * 2.0))
	# A screw in each top corner, in from the frame, as on the plain plate.
	var corner := h * 0.2
	for x: float in [corner, plate.x - corner]:
		canvas.draw_circle(Vector2(x, corner), h * 0.046, BOLT, true, -1.0, true)
	var micro := Type.micro_font()
	var micro_size := maxi(roundi(h * 0.13), 6)
	var issuer := Lang.t(ISSUER)
	var wide := micro.get_string_size(issuer, HORIZONTAL_ALIGNMENT_LEFT, -1, micro_size).x
	var room := plate.x - h * 0.7
	if wide <= room:
		canvas.draw_string(
			micro,
			Vector2((plate.x - wide) * 0.5, h * 0.25),
			issuer,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			micro_size,
			Color(INK, 0.6)
		)


## The plate's lettering at a plate [param tall] high: the display cut, spaced.
static func lettering(tall: float) -> Font:
	var spaced := FontVariation.new()
	spaced.base_font = Type.display_font()
	spaced.spacing_glyph = roundi(tall * SPACING)
	return spaced
