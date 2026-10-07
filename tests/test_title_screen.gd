extends GdUnitTestSuite
## The title screen, GAME.md 8.1a: a calm sunburst that stops short of the screen's sides, and
## chips out at the edges.

const TEST_SETTINGS_PATH := "user://test_title_screen.cfg"

var _real: Settings


func before_test() -> void:
	_real = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = TEST_SETTINGS_PATH


func after_test() -> void:
	Game.settings = _real
	Settings.remove_files(TEST_SETTINGS_PATH)


## A title's background over a screen of [param size], centered on a mark like the title's.
func _background(size: Vector2) -> TitleBackground:
	var screen := Control.new()
	screen.size = size
	add_child(screen)
	var back := TitleBackground.add_to(screen)
	back.size = size
	var mark := Control.new()
	mark.size = Vector2(132.0, 132.0)
	mark.position = Vector2(size.x * 0.5 - 66.0, 90.0)
	screen.add_child(mark)
	back.anchor = mark
	return back


## The sunburst reaches neither side of the screen nor its foot, and is faded to nothing by its
## edge, whatever shape the screen is: the light is round the mark, not over the menu.
func test_the_sunburst_stops_short_of_the_sides_and_the_foot() -> void:
	for size: Vector2 in [Vector2(1600.0, 900.0), Vector2(1600.0, 720.0), Vector2(720.0, 1280.0)]:
		var back := _background(size)
		await await_idle_frame()
		var at := back.focus()
		var reach := back.reach()
		assert_float(reach).is_greater(0.0)
		assert_float(at.x - reach).is_greater(0.0)
		assert_float(at.x + reach).is_less(size.x)
		assert_float(at.y + reach).is_less(size.y)
		assert_float(TitleBackground.Sunburst.light_at(0.0, reach)).is_equal(1.0)
		assert_float(TitleBackground.Sunburst.light_at(reach * 0.6, reach)).is_less(0.6)
		assert_float(TitleBackground.Sunburst.light_at(reach, reach)).is_equal(0.0)
		back.get_parent().free()


## The chips fade the other way to the beams: gone at the mark, all there out at the edges.
func test_the_chips_fade_out_toward_the_mark() -> void:
	var back := _background(Vector2(1600.0, 900.0))
	await await_idle_frame()
	var at := back.focus()
	assert_float(back.chip_strength(at)).is_equal(0.0)
	assert_float(back.chip_strength(at + Vector2(back.reach() * 0.3, 0.0))).is_equal(0.0)
	assert_float(back.chip_strength(Vector2(0.0, 900.0))).is_equal(1.0)
	assert_float(back.chip_strength(Vector2(20.0, 450.0))).is_greater(
		back.chip_strength(Vector2(700.0, 450.0))
	)
	back.get_parent().free()


## The seal's rings come up band by band, the inner one first.
func test_the_seal_comes_up_band_by_band() -> void:
	var back := _background(Vector2(1600.0, 900.0))
	await await_idle_frame()
	back.rings = 0.3
	assert_float(back._seal.band_shown(0)).is_greater(back._seal.band_shown(1))
	assert_float(back._seal.band_shown(2)).is_equal(0.0)
	back.rings = 1.0
	for band: int in TitleBackground.SEAL_BANDS.size():
		assert_float(back._seal.band_shown(band)).is_equal(1.0)
	back.get_parent().free()