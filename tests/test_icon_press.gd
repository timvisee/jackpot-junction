extends GdUnitTestSuite
## The house print of GAME.md 8.3a: every joker's and power-up's drawing is an SVG file that
## IconPress reads and prints, and the files are held to the lists the way the lists are held to
## the catalog.

const FOLDERS := {
	"res://assets/icons/jokers/": "jokers",
	"res://assets/icons/powerups/": "powerups",
}


static func _files(folder: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for file: String in DirAccess.get_files_at(folder):
		if file.ends_with(".svg"):
			ids.append(StringName(file.get_basename()))
	return ids


## Every joker but Kit's pencil ones has a drawing, and every drawing is a joker's.
func test_every_house_joker_has_a_drawing_and_every_drawing_a_joker() -> void:
	var files := _files("res://assets/icons/jokers/")
	for id: StringName in JokerArt.known():
		if id in JokerArt.KIT:
			assert_bool(id in files).override_failure_message("%s is Kit's" % id).is_false()
			continue
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
	var ids: Array[StringName] = _files("res://assets/icons/jokers/")
	ids.append_array(_files("res://assets/icons/powerups/"))
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


## The shadow side is a screen of dots on a dark card and nothing on paper or when small: the
## halftone layer of a ball has something on it at a card's size and the printed ball differs
## from its flat print, while at a HUD's size there is no shadow layer at all.
func test_the_shadow_side_is_a_halftone_on_a_card_only() -> void:
	var drawing := IconPress.parse(
		FileAccess.get_file_as_string("res://assets/icons/powerups/bomb.svg")
	)
	var ink := Color("#e64d33")
	var flat := Image.new()
	flat.load_svg_from_string(
		IconPress.compose(drawing, ink, true, false, IconPress.Layer.FLAT, 128), 128 / 48.0
	)
	var printed := IconPress.image(drawing, ink, 128)
	assert_bool(printed.get_data() == flat.get_data()).is_false()
	var on_paper := IconPress.image(drawing, Color("#211f24"), 128, true)
	var paper_flat := Image.new()
	paper_flat.load_svg_from_string(
		IconPress.compose(drawing, Color("#211f24"), false, false, IconPress.Layer.FLAT, 128),
		128 / 48.0
	)
	assert_bool(on_paper.get_data() == paper_flat.get_data()).is_true()


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
