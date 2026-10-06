extends GdUnitTestSuite
## The game's mark, GAME.md 8.1: drawn by [LogoArt] and written out as the icon and the splash
## the project wears. The picture is code, so the files on disk can fall behind it; this checks they
## are there, are the shape an icon has to be, and are still the mark rather than whatever was there
## before.

const ICON := "res://icon.png"
const ICO := "res://icon.ico"
const SPLASH := "res://splash.png"
const SPLASH_ICO := "res://splash.ico"
const SHEET := "res://assets/logo/"
## Android's launcher icon: the export's option for each picture, the file and its side.
const ANDROID := {
	"launcher_icons/main_192x192": ["android-main-192.png", 192],
	"launcher_icons/adaptive_foreground_432x432": ["android-foreground-432.png", 432],
	"launcher_icons/adaptive_background_432x432": ["android-background-432.png", 432],
	"launcher_icons/adaptive_monochrome_432x432": ["android-monochrome-432.png", 432],
}
## The circle in the middle of a layer that no launcher's shape cuts into, 66 of its 108 dp.
const ANDROID_SAFE := 66.0 / 108.0


## Where a fraction of the way across the icon lands, in pixels.
func _pixel(image: Image, x: float, y: float) -> Color:
	return image.get_pixel(
		clampi(roundi(x * image.get_width()), 0, image.get_width() - 1),
		clampi(roundi(y * image.get_height()), 0, image.get_height() - 1)
	)


func _picture(path: String) -> Image:
	var texture: Texture2D = load(path)
	assert_object(texture).is_not_null()
	return texture.get_image()


func test_the_project_wears_the_icon_and_the_splash_and_they_are_there() -> void:
	assert_str(str(ProjectSettings.get_setting("application/config/icon"))).is_equal(ICON)
	var splash := str(ProjectSettings.get_setting("application/boot_splash/image"))
	if splash.begins_with("uid://"):
		splash = ResourceUID.uid_to_path(splash)
	assert_str(splash).is_equal(SPLASH)
	for path: String in [ICON, SPLASH]:
		assert_bool(FileAccess.file_exists(path)).is_true()
		var image := _picture(path)
		# Square, and big enough for a desktop icon on a dense screen.
		assert_int(image.get_width()).is_equal(image.get_height())
		assert_int(image.get_width()).is_greater_equal(256)
	# And Windows wears the icon file of every size it asks for, small ones and all.
	var native := str(ProjectSettings.get_setting("application/config/windows_native_icon"))
	assert_str(native).is_equal(ICO)
	for path: String in [ICO, SPLASH_ICO]:
		var file := FileAccess.open(path, FileAccess.READ)
		assert_object(file).is_not_null()
		assert_int(file.get_16()).is_equal(0)
		assert_int(file.get_16()).is_equal(1)
		assert_int(file.get_16()).is_greater_equal(4)


## The icon is the seal on nothing, its corners left to whatever is behind it.
func test_the_icon_is_the_seal_rather_than_a_picture_of_something_else() -> void:
	var image := _picture(ICON)
	_assert_seal(image, 0.5 * LogoArt.SEAL)
	assert_float(_pixel(image, 0.03, 0.03).a).is_equal(0.0)


## The splash is the seal on its plate, a ticket whose notched corners leave the corners to
## whatever is behind it.
func test_the_splash_is_the_seal_on_its_plate() -> void:
	var image := _picture(SPLASH)
	_assert_seal(image, 0.5 * LogoArt.ON_PLATE * LogoArt.SEAL)
	var plate := _pixel(image, 0.5, 0.03)
	assert_float(plate.a).is_equal(1.0)
	assert_float(plate.get_luminance()).is_less(0.2)
	assert_float(_pixel(image, 0.015, 0.015).a).is_equal(0.0)


## The pictures kept for use anywhere else: the icon, the foil chip alone and the splash at each
## size, and the README's banner, wider than it is tall.
func test_the_sheet_has_every_picture() -> void:
	for kind: String in ["icon", "chip", "splash"]:
		for side: int in [128, 512, 2048]:
			var image := Image.load_from_file(
				ProjectSettings.globalize_path(SHEET + "%s-%d.png" % [kind, side])
			)
			assert_object(image).is_not_null()
			assert_int(image.get_width()).is_equal(side)
			assert_int(image.get_height()).is_equal(side)
	var banner := Image.load_from_file(ProjectSettings.globalize_path(SHEET + "banner.png"))
	assert_object(banner).is_not_null()
	assert_int(banner.get_width()).is_greater(banner.get_height() * 3)


## Android's launcher icon is pictures of its own, each the size Android asks for: the layer behind
## fills its square, and the seal in front and the chip in one ink keep inside the circle no
## launcher's shape cuts into, the chip all one ink for the launcher to tint.
func test_android_wears_a_launcher_icon_of_its_own() -> void:
	var presets := ConfigFile.new()
	assert_int(presets.load("res://export_presets.cfg")).is_equal(OK)
	var options := ""
	for section: String in presets.get_sections():
		if str(presets.get_value(section, "platform", "")) == "Android":
			options = section + ".options"
	assert_str(options).is_not_empty()
	var layers: Dictionary[String, Image] = {}
	for option: String in ANDROID:
		var path := str(presets.get_value(options, option, ""))
		assert_str(path).is_equal(SHEET + str(ANDROID[option][0]))
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_object(image).is_not_null()
		assert_int(image.get_width()).is_equal(int(ANDROID[option][1]))
		assert_int(image.get_height()).is_equal(int(ANDROID[option][1]))
		layers[option.get_slice("/", 1)] = image
	var behind := layers["adaptive_background_432x432"]
	for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		assert_float(_pixel(behind, corner.x, corner.y).a).is_equal(1.0)
	var front := layers["adaptive_foreground_432x432"]
	var tinted := layers["adaptive_monochrome_432x432"]
	for layer: Image in [front, tinted]:
		assert_float(_pixel(layer, 0.5, 0.5).a).is_equal(1.0)
		for step: int in 120:
			var toward := Vector2.from_angle(TAU * float(step) / 120.0)
			var out := ANDROID_SAFE * 0.5 + 0.01
			while out < 0.5:
				var at := Vector2(0.5, 0.5) + toward * out
				var cover := _pixel(layer, at.x, at.y).a
				(
					assert_float(cover)
					. override_failure_message("cut off at %s: %s" % [at, cover])
					. is_equal(0.0)
				)
				out += 0.02
	var exporter: GDScript = load("res://scenes/dev/logo_export.gd")
	var mark: float = exporter.get_script_constant_map()["ANDROID_MARK"]
	_assert_seal(front, 0.5 * mark * LogoArt.SEAL)
	for x: int in range(0, tinted.get_width(), 3):
		for y: int in range(0, tinted.get_height(), 3):
			var ink := tinted.get_pixel(x, y)
			if ink.a > 0.0:
				assert_float(minf(minf(ink.r, ink.g), ink.b)).is_greater(0.98)


## The mark itself, the seal [param seal] of the side out: the pot a red chip in the middle of the
## foil chip, a road running out of it, the foil between them, the ring of ink round it all.
func _assert_seal(image: Image, seal: float) -> void:
	var chip := seal * LogoArt.SEAL_CHIP
	var pot := _pixel(image, 0.5 + chip * LogoArt.POT * 0.3, 0.5)
	assert_bool(pot.r > 0.55 and pot.g < 0.4).override_failure_message("the pot %s" % pot).is_true()
	_assert_ink(_pixel(image, 0.5 + chip * 0.65, 0.5 + chip * 0.13), LogoArt.ROAD_INK, "the road")
	var foil := _pixel(image, 0.5 + chip * 0.4 * 0.7071, 0.5 - chip * 0.4 * 0.7071)
	(
		assert_bool(foil.r > 0.75 and foil.b < 0.45)
		. override_failure_message("foil %s" % foil)
		. is_true()
	)
	var band := seal * (LogoArt.BAND + LogoArt.BAND_WIDE * 0.38)
	var ink := _pixel(image, 0.5 + band * 0.7071, 0.5 + band * 0.7071)
	assert_float(ink.get_luminance()).override_failure_message("the band %s" % ink).is_less(0.2)


## Drawn small the mark is the foil chip alone, the seal only once there is room for its fine
## lines and its fine print: the license's band and the small icons are the chip, the title and
## the big icon the seal. Asked to, it is the chip at any size.
func test_the_mark_is_the_chip_alone_when_it_is_small() -> void:
	var mark := LogoArt.new()
	mark.plate = false
	mark.size = Vector2(44.0, 44.0)
	assert_bool(mark.shows_seal()).is_false()
	mark.size = Vector2(132.0, 132.0)
	assert_bool(mark.shows_seal()).is_true()
	mark.plate = true
	mark.size = Vector2(64.0, 64.0)
	assert_bool(mark.shows_seal()).is_false()
	mark.size = Vector2(512.0, 512.0)
	assert_bool(mark.shows_seal()).is_true()
	mark.chip_only = true
	assert_bool(mark.shows_seal()).is_false()
	mark.chip_only = false
	mark.mono = true
	assert_bool(mark.shows_seal()).is_false()
	mark.free()


## One pixel of the icon, named so a failure says which part of the mark moved. Compared to
## within a step of eight-bit color, which is all a PNG keeps.
func _assert_ink(got: Color, wanted: Color, part: String) -> void:
	var off := maxf(maxf(absf(got.r - wanted.r), absf(got.g - wanted.g)), absf(got.b - wanted.b))
	(
		assert_float(off)
		. override_failure_message("%s is %s rather than %s" % [part, got, wanted])
		. is_less(0.02)
	)
