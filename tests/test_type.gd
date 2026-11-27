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


## Kit's signature stays whole: a row may end before its dash but not after, GAME.md 10.9.
func test_a_signature_keeps_its_dash() -> void:
	var text := "说明他们给你印了一张。—K."  # NO_TRANSLATE
	var before := "说明他们给你印了一张。—"  # NO_TRANSLATE
	var wide := Type.TEXT.get_string_size(before, HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
	var rows := Type.rows(text, Type.TEXT, SAMPLE, wide + 1.0)
	assert_str("".join(rows)).is_equal(text)
	assert_str(rows[rows.size() - 1]).ends_with("—K.")
	assert_array(Array(Type.rows("Not this time. —K.", Type.TEXT, SAMPLE, 1.0))).contains(["—K."])


## A hurried line goes over its first word, and in Chinese, which has no spaces, over the words up
## to the first mark, not over the whole line, GAME.md 10.9.
func test_a_hurried_line_goes_over_its_first_word() -> void:
	var font := NotePage.HAND
	assert_str(NotePage.first_word("Don't stamp it! Not this time.", font, 20, 400.0)).is_equal(
		"Don't"
	)
	var chinese := "别盖章！别接受他们的条款。这次不行。—K."  # NO_TRANSLATE
	assert_str(NotePage.first_word(chinese, font, 20, 400.0)).is_equal("别盖章")  # NO_TRANSLATE
	assert_str(NotePage.first_word(chinese, font, 20, 30.0)).is_equal("别")  # NO_TRANSLATE


## Every face the game is set in has its Chinese partner behind it, GAME.md 10.9, and behind every
## partner but its own the text face's, which holds every character a name may have.
func test_every_face_has_its_chinese_partner_behind_it() -> void:
	var partners: Dictionary = (load(Type.PARTNERED) as JSON).data
	var faces: Dictionary = partners["faces"]
	var last := load(Type.PARTNERS + String(partners["last"])) as Font
	for file: String in DirAccess.get_files_at(Type.FACES):
		if file.ends_with(".ttf") and file != Type.FALLBACK.resource_path.get_file():
			assert_bool(faces.has(file)).override_failure_message(file).is_true()
	for face: String in faces:
		var font := load(Type.FACES + face) as FontFile
		var partner := load(Type.PARTNERS + String(faces[face])) as Font
		assert_bool(font.fallbacks.has(partner)).override_failure_message(face).is_true()
		assert_bool(font.fallbacks.has(last)).override_failure_message(face).is_true()
		assert_bool(partner.has_char("。".unicode_at(0))).is_true()


## A line with Chinese in it stands no taller than one without, and no face measures taller for the
## partners behind it: each is no taller over the baseline nor deeper under it than its faces,
## GAME.md 10.9.
func test_chinese_makes_no_line_taller() -> void:
	var partners: Dictionary = (load(Type.PARTNERED) as JSON).data
	var faces: Dictionary = partners["faces"]
	for face: String in faces:
		var font := load(Type.FACES + face) as FontFile
		var alone := FontFile.new()
		alone.data = font.data
		for behind: Font in font.fallbacks:
			if behind == Type.FALLBACK:
				continue
			var named := "%s behind %s" % [behind.resource_path.get_file(), face]
			assert_float(behind.get_ascent(SAMPLE)).override_failure_message(named).is_less_equal(
				alone.get_ascent(SAMPLE) + 0.5
			)
			assert_float(behind.get_descent(SAMPLE)).override_failure_message(named).is_less_equal(
				alone.get_descent(SAMPLE) + 0.5
			)
	for font: Font in [Type.TEXT, Type.DISPLAY, NotePage.HAND, NotePage.TYPED]:
		var english := TextLine.new()
		english.add_string("Jackpot", font, SAMPLE)
		var mixed := TextLine.new()
		mixed.add_string("Jackpot 头奖。", font, SAMPLE)  # NO_TRANSLATE
		assert_float(mixed.get_size().y).is_equal(english.get_size().y)


## A name typed in Chinese shows in every face, the House's plates' characters among them: a face
## whose partner lacks one falls back on the text face's, GAME.md 10.9.
func test_a_chinese_name_shows_in_every_face() -> void:
	var faces: Dictionary = ((load(Type.PARTNERED) as JSON).data)["faces"]
	for face: String in faces:
		var font := load(Type.FACES + face) as Font
		for character: String in "张伟王秀英林小雨鑫淼京沪粤学警":  # NO_TRANSLATE
			(
				assert_bool(font.has_char(character.unicode_at(0)))
				. override_failure_message("%s in %s" % [character, face])
				. is_true()
			)


## Every character the Chinese translation uses is drawn by each face or by its own partner, not
## left to the text face's behind it: `make fonts` cuts the partners again when one is missing,
## GAME.md 10.9.
func test_every_character_the_chinese_translation_uses_is_drawn() -> void:
	var faces: Dictionary = ((load(Type.PARTNERED) as JSON).data)["faces"]
	var used := {}
	var chinese := TranslationServer.get_translation_object("zh_CN")
	for said: String in chinese.get_translated_message_list():
		for character: String in said:
			if character.unicode_at(0) > 0x20:
				used[character] = true
	for face: String in faces:
		var alone := FontFile.new()
		alone.data = (load(Type.FACES + face) as FontFile).data
		var partner := load(Type.PARTNERS + String(faces[face])) as Font
		var missing: Array[String] = []
		for character: String in used:
			var code := character.unicode_at(0)
			if not alone.has_char(code) and not partner.has_char(code):
				missing.append(character)
		(
			assert_array(missing)
			. override_failure_message("%s lacks %s: make fonts" % [face, "".join(missing)])
			. is_empty()
		)


## Chinese in a face is drawn in that face's own partner, at its size, not in another partner behind
## it: the engine reckons every partner draws Han, GAME.md 10.9.
func test_chinese_is_drawn_in_the_faces_own_partner() -> void:
	var faces: Dictionary = ((load(Type.PARTNERED) as JSON).data)["faces"]
	var server := TextServerManager.get_primary_interface()
	for face: String in faces:
		var font := load(Type.FACES + face) as Font
		var partner := load(Type.PARTNERS + String(faces[face])) as Font
		assert_bool(server.font_is_script_supported(partner.get_rids()[0], "Hani")).is_true()
		var han := "国"  # NO_TRANSLATE
		if partner.has_char(han.unicode_at(0)):
			var own := partner.get_string_size(han, HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
			var drawn := font.get_string_size(han, HORIZONTAL_ALIGNMENT_LEFT, -1, SAMPLE).x
			assert_float(drawn).override_failure_message(face).is_equal(own)
