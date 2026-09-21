extends GdUnitTestSuite
## The type the game is set in, GAME.md 8.3: three cuts of one face, and numbers that do not
## move about while they change.

const SAMPLE := 64


## A score counting up and a clock counting down are read while driving. Proportional digits are
## different widths, so every tick shifts the whole line sideways and the eye has to find it
## again; tabular ones do not.
func test_numbers_are_the_same_width_whatever_the_digits() -> void:
	for font: Font in [Type.numbers_font(), Type.numbers_text_font()]:
		var ones := font.get_string_size("111", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
		var eights := font.get_string_size("888", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
		var mixed := font.get_string_size("4:07", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
		var other := font.get_string_size("1:11", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
		assert_float(ones).is_equal_approx(eights, 0.01)
		assert_float(mixed).is_equal_approx(other, 0.01)


## Words are still set the ordinary way: tabular figures are for numbers, and a name set in
## them looks like a spreadsheet.
func test_words_keep_their_own_widths() -> void:
	var text := Type.TEXT
	var thin := text.get_string_size("lllll", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
	var wide := text.get_string_size("mmmmm", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
	assert_float(wide).is_greater(thin * 1.5)


## The three cuts are three different weights of the same face, so a heading and a sentence
## look like the same game.
func test_the_three_cuts_are_the_same_face_at_three_weights() -> void:
	# The heavier cuts name themselves Inter SemiBold and Inter Black, which is how a family
	# with more than four weights ships: one face, named per weight.
	for font: Font in [Type.TEXT, Type.STRONG, Type.DISPLAY]:
		assert_bool(font.get_font_name().begins_with("Inter")).is_true()
	var body := Type.TEXT.get_string_size("Jackpot", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
	var heavy := Type.DISPLAY.get_string_size("Jackpot", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
	assert_float(heavy).is_greater(body)
