extends GdUnitTestSuite
## The game's mark, GAME.md 8.1: drawn by [LogoArt] and written out as the icon the project
## wears. The picture is code, so the file on disk can fall behind it; this checks the file is
## there, is the shape an icon has to be, and is still the mark rather than whatever was there
## before.

const ICON := "res://icon.png"


## Where a fraction of the way across the icon lands, in pixels.
func _pixel(image: Image, x: float, y: float) -> Color:
	return image.get_pixel(
		clampi(roundi(x * image.get_width()), 0, image.get_width() - 1),
		clampi(roundi(y * image.get_height()), 0, image.get_height() - 1)
	)


func _icon() -> Image:
	var texture: Texture2D = load(ICON)
	assert_object(texture).is_not_null()
	return texture.get_image()


func test_the_project_wears_the_icon_and_the_icon_is_there() -> void:
	assert_str(str(ProjectSettings.get_setting("application/config/icon"))).is_equal(ICON)
	assert_bool(FileAccess.file_exists(ICON)).is_true()
	var image := _icon()
	# Square, and big enough for a desktop icon on a dense screen.
	assert_int(image.get_width()).is_equal(image.get_height())
	assert_int(image.get_width()).is_greater_equal(256)


## The mark itself: a gold chip with a crossroads cut through it, the Junction lit in the middle
## and the rim in neon, on a plate that leaves the corners to whatever is behind it.
func test_the_icon_is_the_mark_rather_than_a_picture_of_something_else() -> void:
	var image := _icon()
	var out := LogoArt.CHIP * 0.7071
	_assert_ink(_pixel(image, 0.5, 0.5), Palette.CHIP_GOLD, "the pot in the middle")
	_assert_ink(
		_pixel(image, 0.5 + 0.3 * 0.7071, 0.5 - 0.3 * 0.7071), Palette.CHIP_GOLD, "a gold quarter"
	)
	_assert_ink(_pixel(image, 0.5 + 0.3, 0.5), Palette.ASPHALT, "the road east")
	_assert_ink(_pixel(image, 0.5 + out, 0.5 - out), Palette.NEON_MAGENTA, "the neon rim")
	_assert_ink(_pixel(image, 0.5, 0.03), LogoArt.PLATE_INK, "the plate")
	assert_float(_pixel(image, 0.015, 0.015).a).is_equal(0.0)


## One pixel of the icon, named so a failure says which part of the mark moved. Compared to
## within a step of eight-bit color, which is all a PNG keeps.
func _assert_ink(got: Color, wanted: Color, part: String) -> void:
	var off := maxf(maxf(absf(got.r - wanted.r), absf(got.g - wanted.g)), absf(got.b - wanted.b))
	(
		assert_float(off)
		. override_failure_message("%s is %s rather than %s" % [part, got, wanted])
		. is_less(0.01)
	)
