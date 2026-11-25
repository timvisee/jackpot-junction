extends GdUnitTestSuite
## How a bind glyph is painted by where it stands, GAME.md 8.3: the look a place gives the glyphs
## under it, and an outline that stays a line however small.

const INK := Color(0.9, 0.9, 0.94)


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
