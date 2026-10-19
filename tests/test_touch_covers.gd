extends GdUnitTestSuite
## The touch controls as covers, GAME.md 4.2 and 8.2: on a touch screen the camera keeps the karts
## out from under the middle of the stick, the slider and each round driving button, as it does from
## under the HUD's panels; never anything more than is drawn, and nothing without touch.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _was_enabled := false
var _was_layout := Settings.TOUCH_SLIDER
var _runner: GdUnitSceneRunner


func before_test() -> void:
	_was_enabled = TouchInput.enabled
	_was_layout = Game.settings.touch_layout
	Game.settings.touch_layout = Settings.TOUCH_SLIDER


func after_test() -> void:
	TouchInput.enabled = _was_enabled
	Game.settings.touch_layout = _was_layout
	TouchInput.release()
	Input.emulate_touch_from_mouse = false


## A match with a player at this screen on a touch screen, and the controls the HUD put up for them.
func _driving() -> TouchControls:
	TouchInput.enabled = true
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, -1), KartInput.new()]
	match_node.start(inputs, 5)
	await _runner.simulate_frames(12, 17)
	return match_node.hud.get_node("TouchControls")


## The square [param controls] draw a ring of [param radius] round [param center] in, on the screen.
static func _drawn(controls: TouchControls, center: Vector2, radius: float) -> Rect2:
	var square := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	return controls.get_global_transform() * square


## Whether [param covers] hold a cover that is [param drawn] made [constant TouchHud.COVERED] of its
## size about its middle.
static func _inset_of(covers: Array[Rect2], drawn: Rect2) -> bool:
	for cover: Rect2 in covers:
		var middle_same := cover.get_center().distance_to(drawn.get_center()) < 0.5
		var size_same := (cover.size - drawn.size * TouchHud.COVERED).length() < 0.5
		if middle_same and size_same:
			return true
	return false


## The stick, the slider and each round driving button are covers, each its middle only: smaller
## than what is drawn, about the same middle. The menu button in the corner is not.
func test_the_touch_controls_are_covers_inset() -> void:
	var controls := await _driving()
	var covers := TouchHud.covers(controls)
	var buttons := controls.driving_buttons()
	assert_int(covers.size()).is_equal(buttons.size() + 2)
	var stick := _drawn(controls, controls.stick.center, TouchStick.RADIUS)
	assert_bool(_inset_of(covers, stick)).is_true()
	for id: StringName in buttons:
		var each := controls.pad(id)
		assert_bool(_inset_of(covers, _drawn(controls, each.center, each.radius))).is_true()
	var slider := controls.get_global_transform() * controls.slider.rect
	assert_bool(_inset_of(covers, slider)).is_true()
	var menu := controls.pad(TouchControls.MENU)
	for cover: Rect2 in covers:
		assert_bool(cover.has_point(controls.get_global_transform() * menu.center)).is_false()
	# A third or so smaller than drawn, as the request has it: a kart partly under one is still seen.
	assert_float(TouchHud.COVERED).is_between(0.65, 0.75)


## And the camera is told about them with the rest of the HUD, in shares of the screen: a kart's
## middle at the middle of the stick is under a cover, one just inside the stick's ring is not.
func test_the_camera_keeps_the_karts_out_from_under_the_touch_controls() -> void:
	var controls := await _driving()
	var hud := controls.match_node.hud
	var gathering := hud.get_node("Covers") as HudCovers
	gathering._process(HudCovers.EVERY)
	var covers := controls.match_node.camera_rig.covers
	assert_array(covers).is_equal(gathering.covers())
	var screen := hud.get_viewport().get_visible_rect().size
	var stick := controls.get_global_transform() * controls.stick.center
	var held := covers.any(func(cover: Rect2) -> bool: return cover.has_point(stick / screen))
	assert_bool(held).is_true()
	var rim := stick + Vector2(TouchStick.RADIUS * 0.9, 0.0)
	var rim_held := covers.any(func(cover: Rect2) -> bool: return cover.has_point(rim / screen))
	assert_bool(rim_held).is_false()


## Only what is drawn: nothing once the controls are hidden, nothing without a kart here to drive,
## when only the menu button is drawn, and nothing at all off a touch screen.
func test_no_touch_covers_unless_the_controls_are_drawn() -> void:
	var controls := await _driving()
	assert_array(TouchHud.covers(controls)).is_not_empty()
	controls.visible = false
	assert_array(TouchHud.covers(controls)).is_empty()
	controls.visible = true
	TouchInput.enabled = false
	assert_array(TouchHud.covers(controls)).is_empty()
	TouchInput.enabled = true
	# The controls with no match under them: the menu and nothing to drive.
	var layer: CanvasLayer = auto_free(CanvasLayer.new())
	var alone := TouchControls.new()
	layer.add_child(alone)
	add_child(layer)
	assert_bool(alone.driving()).is_false()
	assert_array(TouchHud.covers(alone)).is_empty()
