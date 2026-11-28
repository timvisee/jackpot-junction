extends GdUnitTestSuite
## How a bind glyph is painted by where it stands, GAME.md 8.3: the look a place gives the glyphs
## under it, a player's own lines in their color, and an outline that stays a line however small.

const INK := Color(0.9, 0.9, 0.94)
const ORANGE := Color("#F28C3D")


func _key(code: Key) -> InputGlyph:
	var press := InputEventKey.new()
	press.keycode = code
	press.physical_keycode = code
	return InputGlyph.of_event(press, INK, 18)


func test_a_place_paints_every_glyph_under_it_in_its_look() -> void:
	var place: Control = auto_free(Control.new())
	add_child(place)
	var before := _key(KEY_Q)
	place.add_child(before)
	assert_int(before.look).is_equal(GlyphArt.Look.LIGHT)
	InputGlyph.look_under(place, GlyphArt.Look.OUTLINE)
	assert_int(before.look).is_equal(GlyphArt.Look.OUTLINE)
	# A row built later, as one is when the player picks up another device, takes it as it goes in.
	var row := HBoxContainer.new()
	var later := _key(KEY_E)
	row.add_child(later)
	place.add_child(row)
	assert_int(later.look).is_equal(GlyphArt.Look.OUTLINE)
	# A glyph that says its own look keeps it: a button's bind in a dialog of quiet lines.
	var own := _key(KEY_ESCAPE)
	InputGlyph.look_under(own, GlyphArt.Look.DARK)
	row.add_child(own)
	assert_int(own.look).is_equal(GlyphArt.Look.DARK)
	# And one anywhere else is drawn light.
	var loose: InputGlyph = auto_free(_key(KEY_W))
	add_child(loose)
	assert_int(loose.look).is_equal(GlyphArt.Look.LIGHT)


func test_a_players_lines_wear_their_color() -> void:
	var block: Control = auto_free(Control.new())
	add_child(block)
	InputGlyph.seat_under(block, ORANGE)
	var glyph := _key(KEY_CTRL)
	block.add_child(glyph)
	assert_that(glyph.seat).is_equal(ORANGE)
	# A color changed in the lobby reaches the glyphs already drawn.
	InputGlyph.seat_under(block, Palette.PLAYER_COLORS[1])
	assert_that(glyph.seat).is_equal(Palette.PLAYER_COLORS[1])
	# A light glyph is drawn in it; a dark one wears it as its rim.
	var art := GlyphArt.key("Ctrl")
	var hex := "#" + ORANGE.to_html(false)
	assert_str(GlyphArt.svg(art, INK, Vector2i(40, 32), GlyphArt.Look.LIGHT, ORANGE)).contains(
		'fill="%s"' % hex
	)
	var dark := GlyphArt.svg(art, INK, Vector2i(40, 32), GlyphArt.Look.DARK, ORANGE)
	assert_str(dark).contains('stroke="%s"' % hex)
	assert_str(GlyphArt.svg(art, INK, Vector2i(40, 32), GlyphArt.Look.DARK)).not_contains(hex)
	# A face button keeps its pad's colors: a PlayStation shape on a disc of the player's was lost.
	var cross := GlyphArt.face("", JOY_BUTTON_A, "face", InputGlyph.SHAPE_DEEP[JOY_BUTTON_A])
	for drawn: GlyphArt.Art in [cross, GlyphArt.face("B", JOY_BUTTON_INVALID)]:
		var light := GlyphArt.svg(drawn, INK, Vector2i(32, 32), GlyphArt.Look.LIGHT, ORANGE)
		assert_str(light).not_contains(hex)


func test_an_outline_stays_a_line_however_small() -> void:
	var art := GlyphArt.key("Q")
	var widths := func(px: int) -> float:
		var text := GlyphArt.svg(art, INK, Vector2i(px, px), GlyphArt.Look.OUTLINE)
		var found := RegEx.create_from_string('stroke-width="([0-9.]+)"').search_all(text)
		return float(found[-1].get_string(1))
	# Big, it is its own width in units; at a Steam Deck's 15 pixels, never under one pixel.
	assert_float(widths.call(64)).is_equal_approx(GlyphArt.LINE, 0.01)
	assert_float(widths.call(15)).is_equal_approx(GlyphArt.TALL / 15.0, 0.01)


func test_outlined_letters_are_set_lighter() -> void:
	var art := GlyphArt.key("Q")
	var letters := func(look: GlyphArt.Look) -> String:
		var text := GlyphArt.svg(art, INK, Vector2i(32, 32), look)
		return text.split("\n")[-2]
	assert_str(letters.call(GlyphArt.Look.OUTLINE)).is_not_equal(letters.call(GlyphArt.Look.LIGHT))


## A glyph drawn round has no line through it, GAME.md 8.3: the shapes an outlined glyph draws a
## line round never overlap, so no line crosses another or the words on it. The stick pressed in is
## its head and its stick, apart; a mouse is one line round with its grooves drawn in; a pad's
## small button its disc alone, its picture drawn on it.
func test_an_outlined_glyph_has_no_lines_through_it() -> void:
	assert_int(_outlined(GlyphArt.click("R3"))).is_equal(2)
	for button: MouseButton in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		assert_int(_outlined(GlyphArt.mouse(button, "", InputGlyph.MOUSE_WIDE))).is_equal(1)
	for name: String in GlyphArt.ICONS:
		assert_int(_outlined(GlyphArt.icon(name))).override_failure_message(name).is_equal(1)
	# Filled, a mouse is its body in the dim tone, the button pressed lit on it to its edge, and the
	# groove and the wheel over both: nothing under its edge to show past it.
	var filled := GlyphArt.mouse(MOUSE_BUTTON_LEFT, "", InputGlyph.MOUSE_WIDE).parts.filter(
		func(part: Dictionary) -> bool: return not part.get("only", false)
	)
	var fills: Array = filled.map(func(part: Dictionary) -> Variant: return part["fill"])
	assert_array(fills).is_equal(["dim", "lit", null, "dim"])
	var outlined := GlyphArt.svg(
		GlyphArt.mouse(MOUSE_BUTTON_LEFT, "", InputGlyph.MOUSE_WIDE),
		INK,
		Vector2i(64, 64),
		GlyphArt.Look.OUTLINE
	)
	assert_object(GlyphArt.texture(outlined)).is_not_null()


## How many of [param art]'s shapes are drawn as a line round them where it is outlined.
static func _outlined(art: GlyphArt.Art) -> int:
	var count := 0
	for part: Dictionary in art.parts:
		if part.get("only", true) and part["fill"] in ["body", "face", "dim"]:
			count += 1
	return count
