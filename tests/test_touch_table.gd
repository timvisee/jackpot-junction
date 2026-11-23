extends GdUnitTestSuite
## The touch controls at a table of the cards dealt, GAME.md 3.17 and 4.2: the item button goes
## where Power-ups are not on the table.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const SHIELD: PowerUp = preload("res://data/powerups/shield.tres")

var _was_enabled := false
var _was_layout := Settings.TOUCH_SLIDER
var _runner: GdUnitSceneRunner


func before_test() -> void:
	_was_enabled = TouchInput.enabled
	_was_layout = Game.settings.touch_layout


func after_test() -> void:
	TouchInput.enabled = _was_enabled
	Game.settings.touch_layout = _was_layout
	TouchInput.release()


## A match with a player at this screen on a touch screen in [param layout], at a table without
## Power-ups, and the controls the HUD put up for them.
func _driving(layout: String) -> TouchControls:
	TouchInput.enabled = true
	Game.settings.touch_layout = layout
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.table = TableCards.with(TableCards.ALL, TableCards.Card.ITEMS, false)
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([PlayerInput.new(DeviceInput.ANY, -1), KartInput.new()] as Array[KartInput], 5)
	await _runner.simulate_frames(12, 17)
	return match_node.hud.get_node("TouchControls")


func _touch(controls: TouchControls, at: Vector2, down: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = at
	touch.pressed = down
	controls._input(touch)


## At a table without Power-ups the item button is gone, in either way to hold the wheel: not drawn,
## not pressed and covering nothing for the camera, the other buttons where they were; but for an
## item handed all the same, a Hearts hand's Shield, and while what it started runs.
func test_the_item_button_goes_without_power_ups() -> void:
	for layout: String in [Settings.TOUCH_SLIDER, Settings.TOUCH_BUTTONS]:
		var controls := await _driving(layout)
		var kart := controls.match_node.kart_of(0)
		var item := controls.pad(TouchControls.ITEM)
		var fire_at := controls.pad(TouchControls.FIRE).center
		kart.held_item = null
		assert_bool(controls.item_shown()).override_failure_message(layout).is_false()
		var hidden := TouchHud.covers(controls).size()
		_touch(controls, item.center, true)
		assert_int(item.held).is_zero()
		assert_bool(TouchInput.use_item).is_false()
		_touch(controls, item.center, false)
		kart.held_item = SHIELD
		kart.item_reveal_left = 0.0
		assert_bool(controls.item_shown()).is_true()
		assert_int(TouchHud.covers(controls).size()).is_equal(hidden + 1)
		assert_vector(controls.pad(TouchControls.FIRE).center).is_equal(fire_at)
		kart.use_item()
		assert_bool(controls.item_shown()).is_true()
		for effect: KartEffect in kart.effects:
			effect.finished = true
		await _runner.simulate_frames(2, 17)
		assert_bool(controls.item_shown()).is_false()
		controls.match_node.rules.table = TableCards.ALL
		assert_bool(controls.item_shown()).is_true()
