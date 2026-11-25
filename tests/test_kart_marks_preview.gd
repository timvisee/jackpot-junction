extends GdUnitTestSuite
## The Accessibility page's window onto three karts, GAME.md 8.5, see [KartMarksPreview]: the first
## seat's kart between the second and third seats', rings under them as Kart rings says.

var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_kart_marks_preview.cfg"


func after_test() -> void:
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


## With no favorites, each kart has the color its seat gives it, the first seat's in the middle and
## the fourth seat's out of the picture; with them, the second and third seats' favorites either
## side; and never two the same.
func test_the_karts_wear_the_seats_colors() -> void:
	var settings := Game.settings
	for seat: int in 4:
		settings.set_seat_color(seat, -1)
	assert_array(KartMarksPreview.colors_of(settings)).is_equal([1, 0, 2, 3])
	settings.set_seat_color(0, 4)
	settings.set_seat_color(1, 6)
	settings.set_seat_color(2, 7)
	assert_array(KartMarksPreview.colors_of(settings)).is_equal([6, 4, 7, 3])
	settings.set_seat_color(1, 4)
	assert_array(KartMarksPreview.colors_of(settings)).is_equal([0, 4, 7, 3])


## A ring under none, under the first seat's kart in the middle, or under all three, as Kart rings
## is set.
func test_the_rings_follow_the_setting() -> void:
	var preview: KartMarksPreview = auto_free(KartMarksPreview.new())
	add_child(preview)
	var shown := func() -> Array[bool]:
		preview._process(0.016)
		var on: Array[bool] = []
		for rings: Array in preview._rings:
			on.append((rings[1] as MeshInstance3D).visible)
		return on
	Game.settings.kart_rings = ViewChoices.RINGS_OFF
	assert_array(shown.call()).is_equal([false, false, false])
	Game.settings.kart_rings = ViewChoices.RINGS_HERE
	assert_array(shown.call()).is_equal([false, true, false])
	Game.settings.kart_rings = ViewChoices.RINGS_ALL
	assert_array(shown.call()).is_equal([true, true, true])


## At the window's left edge, an arrow at a fourth kart out of the picture, pointing left, as Rival
## arrows says: faint out of the box, full, or none.
func test_an_arrow_points_at_a_kart_out_of_the_picture() -> void:
	var preview: KartMarksPreview = auto_free(KartMarksPreview.new())
	add_child(preview)
	await await_idle_frame()
	Game.settings.rival_arrows = ViewChoices.RIVAL_ARROWS_FAINT
	var arrow := preview.rival_arrow()
	assert_float(arrow.length).is_equal(KartPointers.ARROW_FAINT)
	assert_float(arrow.shows).is_equal_approx(KartPointers.FAINT, 0.0001)
	assert_float((arrow.way as Vector2).x).is_less(-0.9)
	assert_float((arrow.at as Vector2).x).is_equal_approx(KartPointers.INSET, 1.0)
	Game.settings.rival_arrows = ViewChoices.RIVAL_ARROWS_FULL
	assert_float(preview.rival_arrow().length).is_equal(KartPointers.ARROW)
	Game.settings.rival_arrows = ViewChoices.RIVAL_ARROWS_OFF
	assert_dict(preview.rival_arrow()).is_empty()
