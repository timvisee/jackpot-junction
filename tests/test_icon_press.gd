extends GdUnitTestSuite
## The house print of GAME.md 8.3a: every joker's, power-up's and achievement's drawing, the table's
## cards', the kinds of game's, the ways to drive's, the dress's, the emotes', the loyalty program's
## landmarks', the buttons' glyphs', the suits' and the slot machines' reels', is an SVG file that
## IconPress reads and prints,
## and the files are held to the lists the way the lists are held to the catalog.

const FOLDERS := {
	"res://assets/icons/jokers/": "jokers",
	"res://assets/icons/powerups/": "powerups",
	"res://assets/icons/achievements/": "achievements",
	"res://assets/icons/table/": "table",
	"res://assets/icons/modes/": "modes",
	"res://assets/icons/drive/": "drive",
	"res://assets/icons/dress/": "dress",
	"res://assets/icons/emotes/": "emotes",
	"res://assets/icons/landmarks/": "landmarks",
	"res://assets/icons/ui/": "ui",
	"res://assets/icons/suits/": "suits",
	"res://assets/icons/marks/": "marks",
	"res://assets/icons/hud/": "hud",
	"res://assets/icons/book/": "book",
	"res://assets/icons/reels/": "reel",
}


static func _files(folder: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for file: String in DirAccess.get_files_at(folder):
		if file.ends_with(".svg"):
			ids.append(StringName(file.get_basename()))
	return ids


## Every joker has a drawing, Kit's pencil ones too, and every drawing is a joker's.
func test_every_joker_has_a_drawing_and_every_drawing_a_joker() -> void:
	var files := _files("res://assets/icons/jokers/")
	for id: StringName in JokerArt.known():
		assert_bool(id in files).override_failure_message("%s has no drawing" % id).is_true()
	for id: StringName in files:
		(
			assert_bool(id in JokerArt.known())
			. override_failure_message("%s is no joker" % id)
			. is_true()
		)


## And every power-up, the same way.
func test_every_power_up_has_a_drawing_and_every_drawing_a_power_up() -> void:
	var files := _files("res://assets/icons/powerups/")
	for id: StringName in PowerUpArt.known():
		assert_bool(id in files).override_failure_message("%s has no drawing" % id).is_true()
	for id: StringName in files:
		(
			assert_bool(id in PowerUpArt.known())
			. override_failure_message("%s is no item" % id)
			. is_true()
		)


## And every achievement, held to the list of them, GAME.md 8.10.
func test_every_achievement_has_a_drawing_and_every_drawing_an_achievement() -> void:
	var files := _files("res://assets/icons/achievements/")
	var ids: Array[StringName] = []
	for each: Achievement in Achievements.all():
		ids.append(each.id)
		(
			assert_bool(each.id in files)
			. override_failure_message("%s has no drawing" % each.id)
			. is_true()
		)
	for id: StringName in files:
		assert_bool(id in ids).override_failure_message("%s is no achievement" % id).is_true()


## And every landmark of the loyalty program's map, GAME.md 8.9.
func test_every_landmark_has_a_drawing_and_every_drawing_a_landmark() -> void:
	var files := _files("res://assets/icons/landmarks/")
	var ids: Array[StringName] = []
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		var drawing := LandmarkIcons.drawing_of(each)
		ids.append(drawing)
		(
			assert_bool(drawing in files)
			. override_failure_message("%s has no drawing" % each.id)
			. is_true()
		)
	for id: StringName in files:
		assert_bool(id in ids).override_failure_message("%s is no landmark" % id).is_true()


## Every glyph a button wears and the padlock of a sealed card, and every suit's mark with the
## jester's two drawings, have their drawings, and nothing else is in their folders.
func test_every_glyph_and_suit_has_a_drawing() -> void:
	assert_int(IconButton.PICTURES.size()).is_equal(IconButton.Kind.size())
	assert_int(JokerSuits.PICTURES.size()).is_equal(Joker.Suit.WILD)
	var glyphs: Array[StringName] = [
		&"ui_magnifier",
		&"ui_cross",
		&"ui_turning",
		&"ui_pin",
		&"ui_arrow",
		&"ui_padlock",
		&"ui_star",
		&"ui_sliders"
	]
	glyphs.append_array(IconButton.PICTURES)
	var suits: Array[StringName] = [JokerSuits.JESTER, JokerSuits.JESTER_BAND]
	suits.append_array(JokerSuits.PICTURES)
	var lists := {"res://assets/icons/ui/": glyphs, "res://assets/icons/suits/": suits}
	for folder: String in lists:
		var files := _files(folder)
		var wanted: Array = lists[folder]
		assert_int(files.size()).override_failure_message(folder).is_equal(wanted.size())
		for id: StringName in wanted:
			assert_bool(id in files).override_failure_message("%s has no drawing" % id).is_true()
	for texture: Texture2D in [
		HouseArt.magnifier(), HouseArt.cross(), HouseArt.turning(), HouseArt.pin(), HouseArt.arrow()
	]:
		assert_object(texture).is_not_null()


## The loyalty map's marks have their drawings: the seal in two, the stamp, Kit's tick, a
## keystone's crest and the roundabout's pot, and nothing else is in their folder.
func test_every_mark_of_the_map_has_a_drawing() -> void:
	var marks: Array[StringName] = [
		&"medal_seal",
		&"medal_seal_red",
		&"stamp_ring",
		&"stamp_house",
		&"tick_print",
		&"crest_disc",
		&"pot_chip",
		&"note_scrap",
	]
	var files := _files("res://assets/icons/marks/")
	assert_int(files.size()).is_equal(marks.size())
	for id: StringName in marks:
		assert_bool(id in files).override_failure_message("%s has no drawing" % id).is_true()


## The HUD's marks and the mult's die have their drawings, and a life is the deck's heart: as wide
## as its box, its point at the foot of its middle.
func test_the_hud_marks_have_drawings_and_a_life_is_the_decks_heart() -> void:
	var marks: Array[StringName] = [&"hud_crown", &"hud_robot", &"hud_skull", &"hud_die"]
	var files := _files("res://assets/icons/hud/")
	assert_int(files.size()).is_equal(marks.size())
	for id: StringName in marks:
		assert_bool(id in files).override_failure_message("%s has no drawing" % id).is_true()
	var heart := Heart.unit_shape()
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for point: Vector2 in heart:
		low = Vector2(minf(low.x, point.x), minf(low.y, point.y))
		high = Vector2(maxf(high.x, point.x), maxf(high.y, point.y))
	assert_float(low.x).is_equal_approx(0.0, 0.01)
	assert_float(high.x).is_equal_approx(1.0, 0.01)
	assert_vector(heart[0]).is_equal_approx(Vector2(0.5, 0.96), Vector2(0.01, 0.01))


## Every figure of the theory book has its drawing, the game's own where it has one, and every
## drawing in the book's folder is one of its figures; the House's star and a note's scrap too.
func test_every_figure_of_the_book_has_a_drawing() -> void:
	var book := _files("res://assets/icons/book/")
	var used := 0
	for kind: SchoolFigure.Kind in SchoolFigure.FIGURES:
		var id: StringName = SchoolFigure.FIGURES[kind]
		assert_bool(IconPress.has(id)).override_failure_message("%s has no drawing" % id).is_true()
		if id in book:
			used += 1
	assert_int(used).is_equal(book.size())
	assert_int(SchoolFigure.FIGURES.size() + SchoolFigure.SIGNS.size()).is_equal(
		SchoolFigure.Kind.size()
	)
	assert_bool(IconPress.has(&"ui_star")).is_true()
	assert_bool(IconPress.has(&"note_scrap")).is_true()


## Every face of the slot machines' reels has its drawing and every drawing in the reels' folder is
## a face's; printed for the size the table shows them at, their shadow side is a flat shade, not
## dots that would shimmer as the reels shrink.
func test_every_face_of_the_reels_has_a_drawing() -> void:
	assert_int(SlotPad.FACE_DRAWINGS.size()).is_equal(SlotPad.Face.size())
	assert_int(SlotPad.FACE_INKS.size()).is_equal(SlotPad.Face.size())
	var files := _files("res://assets/icons/reels/")
	assert_int(files.size()).is_equal(SlotPad.Face.size())
	for id: StringName in SlotPad.FACE_DRAWINGS:
		assert_bool(id in files).override_failure_message("%s has no drawing" % id).is_true()
	var red: Color = SlotPad.FACE_INKS[SlotPad.Face.CHERRY]
	var shade := red.lerp(IconPress.INKY, IconPress.INKY_SHADE)
	var cherry := IconPress.printed(
		&"reel_cherry",
		red,
		128,
		IconPress.Ground.TWO_INKS,
		SlotPad.Strip.CREAM,
		SlotPad.FACE_SHOWN,
		true
	)
	assert_object(cherry).is_not_null()
	assert_int(_count_near(cherry, shade)).is_greater(40)


## Every card of the table, kind of game, way to drive, part of the dress and emote has its drawing,
## and every drawing in their folders is one of theirs.
func test_every_card_button_and_emote_has_a_drawing() -> void:
	assert_int(TableCardArt.PICTURES.size()).is_equal(TableCards.Card.size())
	assert_int(TableCardArt.INKS.size()).is_equal(TableCards.Card.size())
	assert_int(DressArt.PICTURES.size()).is_equal(KartStyle.CHOICES.size() + 1)
	assert_int(EmoteArt.PICTURES.size()).is_equal(EmoteArt.EMOTES.size())
	var drive: Array[StringName] = [
		&"drive_simple", &"drive_advanced", &"drive_slider", &"drive_buttons"
	]
	var modes: Array[StringName] = [&"mode_grand_prix", &"mode_quick_match"]
	var lists := {
		"res://assets/icons/table/": TableCardArt.PICTURES,
		"res://assets/icons/modes/": modes,
		"res://assets/icons/drive/": drive,
		"res://assets/icons/dress/": DressArt.PICTURES,
		"res://assets/icons/emotes/": EmoteArt.PICTURES,
	}
	for folder: String in lists:
		var files := _files(folder)
		var wanted: Array = lists[folder]
		assert_int(files.size()).override_failure_message(folder).is_equal(wanted.size())
		for id: StringName in wanted:
			assert_bool(id in files).override_failure_message("%s has no drawing" % id).is_true()


## Every drawing reads: its pieces each have a shape, its lines a width, its cuts a shape too.
func test_every_drawing_reads() -> void:
	for folder: String in FOLDERS:
		for id: StringName in _files(folder):
			var drawing := IconPress.parse(FileAccess.get_file_as_string(folder + id + ".svg"))
			var parts: Array = drawing.get("parts", [])
			assert_int(parts.size()).override_failure_message("%s is empty" % id).is_greater(0)
			for part: Dictionary in parts:
				(
					assert_str(part["d"])
					. override_failure_message("%s has a piece with no shape" % id)
					. is_not_empty()
				)
				assert_str(part["tone"]).is_not_empty()
				if part["line"]:
					(
						assert_float(part["w"])
						. override_failure_message("%s has a line with no width" % id)
						. is_greater(0.0)
					)
				for cut: Dictionary in part["ct"]:
					assert_str(cut["d"]).is_not_empty()


## Every drawing prints, at a card's size and a HUD's, square and with something on it.
func test_every_drawing_prints_at_every_size() -> void:
	var ids: Array[StringName] = []
	for folder: String in FOLDERS:
		ids.append_array(_files(folder))
	for id: StringName in ids:
		for pixels: float in [30.0, 96.0]:
			var printed := IconPress.texture(id, Color("#f2c14e"), pixels)
			assert_object(printed).override_failure_message("%s did not print" % id).is_not_null()
			var image := printed.get_image()
			assert_int(image.get_width()).is_equal(IconPress.step(pixels))
			assert_int(image.get_height()).is_equal(IconPress.step(pixels))
			(
				assert_bool(image.is_invisible())
				. override_failure_message("%s printed blank" % id)
				. is_false()
			)


## The shadow side is a screen of dots on a dark card and on a chip's two inks, and nothing on
## paper in one ink: the printed ball differs from its flat print on a card, and on paper it is
## that flat print.
func test_the_shadow_side_is_a_halftone_but_not_on_flat_paper() -> void:
	var drawing := IconPress.parse(
		FileAccess.get_file_as_string("res://assets/icons/powerups/bomb.svg")
	)
	var ink := Color("#e64d33")
	var card := IconPress.look_of(ink, 128)
	(
		assert_bool(
			IconPress.image(drawing, ink, 128).get_data() == _flat(drawing, card).get_data()
		)
		. is_false()
	)
	var paper := Color("#f2ead6")
	var two := IconPress.look_of(ink, 128, IconPress.Ground.TWO_INKS, paper)
	var on_chip := IconPress.image(drawing, ink, 128, IconPress.Ground.TWO_INKS, paper)
	assert_bool(on_chip.get_data() == _flat(drawing, two).get_data()).is_false()
	var dark := Color("#211f24")
	var flat := IconPress.look_of(dark, 128, IconPress.Ground.PAPER, paper)
	var on_paper := IconPress.image(drawing, dark, 128, IconPress.Ground.PAPER, paper)
	assert_bool(on_paper.get_data() == _flat(drawing, flat).get_data()).is_true()


## On paper the ink is never lifted, and cream is the paper's own: printed in the paper given, or
## left bare with none.
func test_on_paper_cream_is_the_paper() -> void:
	var oil := Color("#3d334f")
	assert_object(IconPress.look_of(oil, 96, IconPress.Ground.PAPER)["ink"]).is_equal(oil)
	assert_float(IconPress.look_of(oil, 96)["ink"].get_luminance()).is_greater_equal(
		IconPress.READABLE
	)
	var paper := Color("#c9c6bf")
	assert_object(IconPress.look_of(oil, 96, IconPress.Ground.PAPER, paper)["cream"]).is_equal(
		paper
	)
	assert_float(IconPress.look_of(oil, 96, IconPress.Ground.PAPER)["cream"].a).is_equal(0.0)
	assert_bool(IconPress.look_of(oil, 96, IconPress.Ground.PAPER)["glints"]).is_false()
	assert_bool(IconPress.look_of(oil, 96, IconPress.Ground.TWO_INKS, paper)["glints"]).is_true()


## A toned picture keeps its shadow side when it is too small for the screen, as a flat darker ink,
## where any other drops it: the map's pin. Kept bigger than it shows, it is shaded as what it shows
## at.
func test_a_toned_picture_keeps_its_shadow_side_when_small() -> void:
	var drawing := IconPress.parse(
		FileAccess.get_file_as_string("res://assets/icons/ui/ui_pin.svg")
	)
	var red := LoyaltyArt.PIN_RED
	var shade := red.lerp(IconPress.INKY, IconPress.INKY_SHADE)
	var two := IconPress.Ground.TWO_INKS
	var flat := IconPress.image(drawing, red, 28, two, IconPress.CREAM)
	var toned := IconPress.image(drawing, red, 28, two, IconPress.CREAM, 0, true)
	var kept := IconPress.image(drawing, red, 112, two, IconPress.CREAM, 28, true)
	assert_int(_count_near(flat, shade)).is_equal(0)
	assert_int(_count_near(toned, shade)).is_greater(4)
	assert_int(_count_near(kept, shade)).is_greater(40)


static func _count_near(picture: Image, color: Color) -> int:
	var count := 0
	for y: int in picture.get_height():
		for x: int in picture.get_width():
			var pixel := picture.get_pixel(x, y)
			if pixel.a > 0.9 and _near(pixel, color):
				count += 1
	return count


## On bare paper what is cream is left unprinted, even where it lies on ink without a gap round it:
## a slot machine's reels show the button under them, the cabinet round them is ink.
func test_cream_on_bare_paper_shows_what_is_under_it() -> void:
	var drawing := IconPress.parse(
		FileAccess.get_file_as_string("res://assets/icons/table/table_slot_machines.svg")
	)
	var ink := Color("#e0e0eb")
	var printed := IconPress.image(drawing, ink, 96, IconPress.Ground.PAPER)
	assert_float(printed.get_pixel(29, 41).a).is_less(0.1)
	assert_float(printed.get_pixel(24, 22).a).is_greater(0.9)


## A dark piece prints in the House's ink beside a red: Royal Flush's spade pad is dark and its
## heart pad red.
func test_a_dark_piece_prints_in_the_house_ink() -> void:
	var drawing := IconPress.parse(
		FileAccess.get_file_as_string("res://assets/icons/table/table_royal_flush.svg")
	)
	var red := Color("#b8332c")
	var printed := IconPress.image(drawing, red, 96, IconPress.Ground.TWO_INKS, Color("#f2ead6"))
	assert_bool(_near(printed.get_pixel(13, 42), IconPress.DARK)).is_true()
	assert_bool(_near(printed.get_pixel(53, 13), red)).is_true()


## Whether [param a] is [param b] but for a step of rounding in the raster.
static func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.02 and absf(a.g - b.g) < 0.02 and absf(a.b - b.b) < 0.02


static func _flat(drawing: Dictionary, look: Dictionary) -> Image:
	var flat := Image.new()
	flat.load_svg_from_string(
		IconPress.compose(drawing, look["ink"], look, IconPress.Layer.FLAT, 128), 128 / 48.0
	)
	return flat


## Sizes come in steps, so a card growing in prints a few sizes rather than one a pixel.
func test_sizes_come_in_steps() -> void:
	assert_int(IconPress.step(1.0)).is_equal(16)
	assert_int(IconPress.step(30.0)).is_equal(32)
	assert_int(IconPress.step(97.0)).is_equal(112)
	assert_int(IconPress.step(5000.0)).is_equal(1024)


## An ink as dark as the card is lifted until it reads, and a bright one is left alone.
func test_a_dark_ink_is_lifted_and_a_bright_one_is_not() -> void:
	var oil := Color("#3d334f")
	assert_float(IconPress.lifted(oil).get_luminance()).is_greater_equal(IconPress.READABLE)
	assert_object(IconPress.lifted(Color("#f2c14e"))).is_equal(Color("#f2c14e"))


## A picture is printed once for an ink and a size and kept: asking again gives the same one.
func test_a_picture_is_kept() -> void:
	var first := IconPress.texture(&"aimbot", Color("#f2c14e"), 64.0)
	assert_object(IconPress.texture(&"aimbot", Color("#f2c14e"), 60.0)).is_same(first)
	assert_object(IconPress.texture(&"aimbot", Color("#dddddd"), 64.0)).is_not_same(first)
	assert_object(IconPress.texture(&"no_such_icon", Color.WHITE, 64.0)).is_null()
