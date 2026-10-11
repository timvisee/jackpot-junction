extends GdUnitTestSuite
## Text over the arena, GAME.md 8.3: a player's banked score fitted to its corner's width rather
## than clipped by it, however many figures it runs to.


## A score of a few figures is set at its full size; one of five or six, too wide for the label at
## that size, smaller, as far as it takes to fit, and back at its full size once it fits again.
func test_a_long_score_is_set_smaller_to_fit() -> void:
	var label: Label = auto_free(Label.new())
	Type.numbers(label, Type.SCORE)
	label.clip_text = true
	add_child(label)
	label.size = Vector2(170.0, 80.0)
	HudText.fit(label, "820", Type.SCORE)
	assert_int(label.get_theme_font_size(&"font_size")).is_equal(Type.SCORE)
	HudText.fit(label, "123456", Type.SCORE)
	var size := label.get_theme_font_size(&"font_size")
	assert_int(size).is_less(Type.SCORE)
	var font := label.get_theme_font(&"font")
	var wide := font.get_string_size("123456", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	assert_float(wide).is_less_equal(label.size.x)
	HudText.fit(label, "900", Type.SCORE)
	assert_int(label.get_theme_font_size(&"font_size")).is_equal(Type.SCORE)
	remove_child(label)
