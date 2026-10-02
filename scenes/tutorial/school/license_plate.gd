class_name LicensePlate
extends Control
## The license plate on the back of a kart, GAME.md 4.4: up to eight characters of the holder's
## own choosing, in black on a pale plate with a dark rim and a bolt in each top corner, chosen
## once the license is earned and changed in the settings. Drawn, so the same plate serves the
## box it is typed into and the back of the kart in a match, see [method KartVisuals.license_plate].

## How long a plate may be, and what it may hold: letters, digits, a space and a dash, upper
## case, since a plate is stamped and not written.
const MOST := 8
const ALLOWED := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -"
## What an empty plate reads.
const BLANK := "JJ"
const SIZE := Vector2(224.0, 64.0)
const PLATE := Color(0.96, 0.95, 0.9)
const RIM := Color(0.1, 0.1, 0.12)
const INK := Color(0.08, 0.08, 0.1)
const BOLT := Color(0.55, 0.56, 0.6)

var text := ""


## A plate reading [param words], [param wide] pixels across.
static func of(words: String, wide := SIZE.x) -> LicensePlate:
	var plate := LicensePlate.new()
	plate.text = words
	plate.custom_minimum_size = Vector2(wide, wide * SIZE.y / SIZE.x)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return plate


## [param raw] as a plate may read: upper case, nothing a plate cannot hold, one space at a time,
## no longer than [constant MOST].
static func clean(raw: String) -> String:
	var kept := ""
	for character: String in raw.to_upper():
		if character in ALLOWED:
			kept += character
	while kept.contains("  "):
		kept = kept.replace("  ", " ")
	return kept.strip_edges().substr(0, MOST)


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


func set_text(words: String) -> void:
	text = words
	queue_redraw()


func _draw() -> void:
	var plate := StyleBoxFlat.new()
	plate.bg_color = PLATE
	plate.set_corner_radius_all(roundi(size.y * 0.12))
	plate.set_border_width_all(maxi(roundi(size.y * 0.05), 1))
	plate.border_color = RIM
	draw_style_box(plate, Rect2(Vector2.ZERO, size))
	var inset := size.y * 0.16
	for x: float in [inset, size.x - inset]:
		draw_circle(Vector2(x, inset), size.y * 0.05, BOLT)
	var shown := text if not text.is_empty() else BLANK
	var font := Type.display_font()
	var font_size := roundi(size.y * 0.56)
	var room := size.x - inset * 3.0
	while (
		font_size > 8
		and font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > room
	):
		font_size -= 1
	var baseline := (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(
		font, Vector2(0.0, baseline), shown, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, INK
	)
