extends GdUnitTestSuite
## The aim guide and the free-aim arrow, GAME.md 5.1: drawn from the kart as it is drawn, between
## physics ticks, not from where the last tick left it. On a screen that draws faster than the
## physics runs, a phone's at 90 Hz, dots placed off the tick jumped back and forth against the
## smoothed kart every frame.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")


func _start() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	add_child(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), KartInput.new()]
	match_node.start(inputs, 5)
	return match_node


## Neither is smoothed again by the engine: they are placed every drawn frame already, and
## smoothing that would put them a tick behind the kart they hang off.
func test_the_guide_and_the_arrow_are_not_smoothed_twice() -> void:
	var match_node := _start()
	await await_millis(80)
	var kart := match_node.kart_of(0)
	assert_object(kart._aim_guide).is_not_null()
	assert_int(kart._aim_guide.physics_interpolation_mode).is_equal(
		Node.PHYSICS_INTERPOLATION_MODE_OFF
	)
	assert_int(kart._aim_arrow.physics_interpolation_mode).is_equal(
		Node.PHYSICS_INTERPOLATION_MODE_OFF
	)


## Aimed down the nose, the guide turns with the kart as drawn; aimed by a stick, it points where
## the stick does, whichever way the drawn kart has turned.
func test_the_aim_turns_with_the_drawn_kart_only_when_it_follows_the_nose() -> void:
	var match_node := _start()
	await await_millis(80)
	var kart := match_node.kart_of(0)
	kart.global_basis = Basis.IDENTITY
	# Drawn a quarter turn round from where the tick has it.
	var shown := Transform3D(Basis(Vector3.UP, PI * 0.5), kart.global_position)
	var nose := KartAim.shown_direction(kart, shown)
	assert_vector(nose).is_equal_approx(-shown.basis.z, Vector3.ONE * 0.001)
	# A swivel cannon, as a client knows it from the arrow the host sends: the stick's way.
	kart.puppet = true
	kart.aim_arrow_visible = true
	(kart.input as PlayerInput).aim = Vector2(1.0, 0.0)
	assert_vector(KartAim.shown_direction(kart, shown)).is_equal_approx(
		Vector3.RIGHT, Vector3.ONE * 0.001
	)
	kart.puppet = false
	kart.aim_arrow_visible = false


## The first dot stands a muzzle and a spacing ahead of the kart as drawn, at a shot's height.
func test_the_dots_hang_off_the_drawn_kart() -> void:
	var match_node := _start()
	await await_millis(80)
	var kart := match_node.kart_of(0)
	var guide := KartAim.draw(kart, kart._aim_arrow, kart._aim_guide)
	var shown := kart.get_global_transform_interpolated()
	var toward := KartAim.shown_direction(kart, shown)
	var first: Vector3 = guide._dots[0].global_position
	var expected := shown.origin + toward * (kart.cannon_stats.muzzle_offset + AimGuide.SPACING)
	assert_float(first.y).is_equal_approx(Bullet.HEIGHT, 0.001)
	assert_float(Vector2(first.x, first.z).distance_to(Vector2(expected.x, expected.z))).is_less(
		0.001
	)


## The tutorial's guide arrow is placed the same way, GAME.md 10.7: off the kart as drawn, and not
## smoothed again, nor is the ring round the spot it points at.
func test_the_tutorial_arrow_follows_the_kart_as_drawn() -> void:
	var match_node := _start()
	await await_millis(80)
	var kart := match_node.kart_of(0)
	var arrow := GuideArrow.add_to(match_node)
	arrow.kart = kart
	arrow.point_at(kart.global_position + Vector3(20.0, 0.0, 0.0))
	await await_idle_frame()
	await await_idle_frame()
	assert_int(arrow.physics_interpolation_mode).is_equal(Node.PHYSICS_INTERPOLATION_MODE_OFF)
	assert_int(arrow._ring.physics_interpolation_mode).is_equal(Node.PHYSICS_INTERPOLATION_MODE_OFF)
	var drawn := kart.get_global_transform_interpolated().origin
	var flat := Vector3(arrow.global_position.x - drawn.x, 0.0, arrow.global_position.z - drawn.z)
	assert_float(flat.length()).is_equal_approx(GuideArrow.AHEAD, 0.2)


## GAME.md 8.5: the guide is drawn as the settings say, how many dots, how big, how solid and in
## what color, and drawn again at once when they change over a room; and the settings keep it.
func test_the_guide_is_drawn_as_the_settings_say() -> void:
	var settings_were := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_aim_guide.cfg"
	var match_node := _start()
	await await_millis(80)
	var guide: AimGuide = match_node.kart_of(0)._aim_guide
	assert_int(guide._dots.size()).is_equal(AimGuide.DOTS)
	Game.settings.aim_guide_length = 7
	Game.settings.aim_guide_size = 2.0
	Game.settings.aim_guide_opacity = 0.9
	Game.settings.aim_guide_style = 2
	guide.update_line(Vector3.ZERO, Vector3.FORWARD)
	assert_int(guide._dots.size()).is_equal(7)
	var dot := guide._dots[0]
	assert_float((dot.mesh as SphereMesh).radius).is_equal_approx(AimGuide.RADIUS * 2.0, 0.0001)
	var ink := (dot.material_override as StandardMaterial3D).albedo_color
	assert_float(ink.a).is_equal_approx(0.9, 0.0001)
	assert_bool(Color(ink, 1.0).is_equal_approx(AimGuide.YELLOW)).is_true()
	Game.settings.save_to_disk()
	var read := Settings.new()
	read.path = Game.settings.path
	read.load_from_disk()
	assert_int(read.aim_guide_length).is_equal(7)
	assert_float(read.aim_guide_size).is_equal_approx(2.0, 0.0001)
	assert_int(read.aim_guide_style).is_equal(2)
	Settings.remove_files(Game.settings.path)
	Game.settings = settings_were


## GAME.md 8.5: the Accessibility page shows the guide as it is set, under its switch, the dots
## built again the moment a setting changes, and none while the guide is switched off.
func test_the_accessibility_page_shows_the_guide_as_it_is_set() -> void:
	var settings_were := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_aim_guide.cfg"
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	screen.tabs.current_tab = screen.tabs.get_node("Accessibility").get_index()
	await await_idle_frame()
	var preview: AimGuidePreview = screen.find_child("AimGuidePreview", true, false)
	assert_int(preview._dots.size()).is_equal(AimGuide.DOTS)
	(screen.find_child("AimGuideLength", true, false) as HSlider).value = 6.0
	await await_idle_frame()
	assert_int(preview._dots.size()).is_equal(6)
	assert_bool(preview._dots[0].visible).is_true()
	Game.settings.aim_guide = false
	await await_idle_frame()
	assert_bool(preview._dots[0].visible).is_false()
	Settings.remove_files(Game.settings.path)
	Game.settings = settings_were


## GAME.md 8.5: Reset beside the aim guide's controls puts its length, size, opacity and color back
## as they were at first, the controls and the preview with them, and is there to press only while
## one of them is not.
func test_reset_puts_the_aim_guide_back_as_it_was() -> void:
	var settings_were := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_aim_guide.cfg"
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	screen.tabs.current_tab = screen.tabs.get_node("Accessibility").get_index()
	await await_idle_frame()
	var rows: AimGuideRows = screen.find_child("AimGuideRows", true, false)
	var preview: AimGuidePreview = screen.find_child("AimGuidePreview", true, false)
	assert_bool(rows.reset_button.disabled).is_true()
	rows.length.value = 7.0
	rows.opacity.value = 0.9
	rows.style.item_selected.emit(2)
	assert_bool(rows.reset_button.disabled).is_false()
	rows.reset_button.pressed.emit()
	assert_bool(Game.settings.aim_guide_as_at_first()).is_true()
	assert_float(rows.length.value).is_equal(float(AimGuide.DOTS))
	assert_float(rows.opacity.value).is_equal_approx(AimGuide.ALPHA, 0.001)
	assert_int(rows.style.selected).is_equal(0)
	assert_bool(rows.reset_button.disabled).is_true()
	assert_str(screen.status.text).is_equal("Aim guide reset")
	await await_idle_frame()
	assert_int(preview._dots.size()).is_equal(AimGuide.DOTS)
	Settings.remove_files(Game.settings.path)
	Game.settings = settings_were


## GAME.md 8.5: a palette for color blindness chosen on the Accessibility page shows on its preview
## of the aim guide at once, the dots in the color it gives the first seat.
func test_the_preview_takes_a_palette_at_once() -> void:
	var settings_were := Game.settings
	var vision_was := Palette.vision
	Game.settings = Settings.new()
	Game.settings.path = "user://test_aim_guide.cfg"
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	screen.tabs.current_tab = screen.tabs.get_node("Accessibility").get_index()
	await await_idle_frame()
	var preview: AimGuidePreview = screen.find_child("AimGuidePreview", true, false)
	var was := (preview._dots[0].material_override as StandardMaterial3D).albedo_color
	Palette.vision = Settings.VISIONS[1]
	await await_idle_frame()
	await await_idle_frame()
	var now := (preview._dots[0].material_override as StandardMaterial3D).albedo_color
	assert_bool(Color(now, 1.0).is_equal_approx(Palette.player_color(0))).is_true()
	assert_bool(now.is_equal_approx(was)).is_false()
	Palette.vision = vision_was
	Settings.remove_files(Game.settings.path)
	Game.settings = settings_were
