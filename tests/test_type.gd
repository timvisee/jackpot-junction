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


## The three cuts are three weights of the same face, GAME.md 8.1a, so a heading and a sentence
## look like the same game: each heavier than the one before and set narrower with it, the display
## cut condensed so a score and a clock take less of the corner.
func test_the_three_cuts_are_the_same_face_at_three_weights() -> void:
	# The cuts name themselves Barlow, Barlow Semi Condensed and Barlow Condensed, which is how a
	# family with more than four weights and three widths ships: one face, named per width.
	var cuts: Array[FontFile] = [Type.TEXT, Type.STRONG, Type.DISPLAY]
	for font: FontFile in cuts:
		assert_bool(font.get_font_name().begins_with("Barlow")).is_true()
	for i: int in range(1, cuts.size()):
		assert_int(cuts[i].font_weight).is_greater(cuts[i - 1].font_weight)
	var body := Type.TEXT.get_string_size("Jackpot", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
	var heading := Type.DISPLAY.get_string_size("Jackpot", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
	assert_float(heading).is_less(body)


## Each cut falls back on Inter for what Barlow does not draw, so a name in Cyrillic is still a
## name.
func test_every_cut_can_fall_back() -> void:
	for font: FontFile in [Type.TEXT, Type.STRONG, Type.DISPLAY, Type.MARK]:
		assert_bool(font.fallbacks.has(Type.FALLBACK)).is_true()
	assert_bool(Type.FALLBACK.has_char("Ж".unicode_at(0))).is_true()


## A card's name too long for one line, as a translation's can be, is set smaller on the two it
## wraps onto, GAME.md 10.9; one that fits keeps its size, as every English one does.
func test_a_name_too_long_for_one_line_is_set_smaller() -> void:
	assert_int(JokerCard.title_size("Big Tank")).is_equal(JokerCard.TITLE)
	assert_int(JokerCard.title_size("Onder de toonbank")).is_equal(JokerCard.TITLE_WRAPPED)
	assert_int(Type.wrapping("Paid", Type.STRONG, 20, 10, 10.0)).is_equal(10)
	assert_int(Type.wrapping("Paid", Type.STRONG, 20, 10, 400.0)).is_equal(20)


## English breaks into rows at its spaces, GAME.md 10.9.
func test_english_breaks_at_its_spaces() -> void:
	var wide := Type.TEXT.get_string_size("ab ab", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
	var rows := Type.rows("ab ab ab ab", Type.TEXT, SAMPLE, wide + 1.0)
	assert_array(Array(rows)).is_equal(["ab ab", "ab ab"])


## Chinese has no spaces and breaks between any two characters, but never before a closing mark:
## a full stop is not left to start a row, GAME.md 10.9.
func test_chinese_breaks_between_its_characters() -> void:
	var text := "他们留我当顾问。从那以后，没人问过我任何事。"  # NO_TRANSLATE
	var wide := Type.TEXT.get_string_size("我当顾问", HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
	var rows := Type.rows(text, Type.TEXT, SAMPLE, wide + 1.0)
	assert_int(rows.size()).is_greater(3)
	assert_str("".join(rows)).is_equal(text)
	for row: String in rows:
		assert_bool(row.begins_with("。") or row.begins_with("，")).is_false()
