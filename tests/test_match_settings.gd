extends GdUnitTestSuite
## The match settings' layout, GAME.md 9.6: two columns that fold, The floor and House rules, side
## by side or one over the other, and a row of presets over them that sets House rules.

## The player's own settings, put aside so the settings opened here start from the defaults, and
## nothing chosen here is ever theirs.
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_match_settings.cfg"


func after_test() -> void:
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


func _pane() -> HostSettings:
	var pane: HostSettings = auto_free(HostSettings.add_to(self, true))
	pane.open()
	return pane


## Folded the first time, saying what their rows are set to; a press on a head opens it with the
## cursor on its first row, and whichever is open is kept for next time.
func test_the_columns_start_folded_and_are_remembered() -> void:
	var pane := _pane()
	var options := pane.options
	assert_bool(options.floor_fold.open).is_false()
	assert_bool(options.rules_fold.open).is_false()
	assert_bool(options.floor_fold.body.visible).is_false()
	assert_str(options.floor_fold._lines[0].text).is_equal("3 maps · Normal and XL · tie-breaker")
	assert_str(options.floor_fold._lines[1].text).is_equal("3 bots, normal · no teams")
	assert_str(options.rules_fold._lines[0].text).is_equal("5 min each · first to 3000 · 5 jokers")
	assert_str(options.rules_fold._lines[1].text).is_equal(
		"own bullets harmless · last one standing · pick one to keep"
	)
	options.rules_fold.head.pressed.emit()
	assert_bool(options.rules_fold.open).is_true()
	assert_bool(options.rules_fold.body.visible).is_true()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(options.minutes_option)
	pane.close()
	assert_bool(Game.settings.rules_open).is_true()
	assert_bool(Game.settings.floor_open).is_false()
	var again: HostSettings = auto_free(HostSettings.add_to(self, true))
	assert_bool(again.options.rules_fold.open).is_true()
	assert_bool(again.options.floor_fold.open).is_false()
	# Pressing the head of an open column folds it.
	again.options.rules_fold.head.pressed.emit()
	assert_bool(again.options.rules_fold.open).is_false()


## A quick match says its arena on the floor's fold, and teams and friendly fire where they are on.
func test_the_floor_says_the_arena_and_the_teams() -> void:
	var options := _pane().options
	options.choose(false)
	options.teams_option.select(1)
	options.teams_option.item_selected.emit(1)
	options.friendly_fire_option.select(1)
	options.friendly_fire_option.item_selected.emit(1)
	var arena := options.map_option.get_item_text(options.map_option.selected)
	assert_str(options.floor_fold._lines[0].text).is_equal(arena)
	assert_str(options.floor_fold._lines[1].text).is_equal(
		"3 bots, normal · 2 teams, friendly fire"
	)
	assert_str(options.rules_fold._lines[0].text).is_equal("5 min · first to 3000 · 5 jokers")


## Standard is lit on the values of GAME.md; a preset sets House rules but leaves the floor, a row
## set to none of them lights Custom, and Custom opens House rules with the cursor in it.
func test_the_presets_set_house_rules() -> void:
	var pane := _pane()
	var options := pane.options
	assert_bool(options.presets.button(0).button_pressed).is_true()
	options.bots_option.select(1)
	options.presets.button(1).pressed.emit()
	var config := MatchConfig.new()
	options.apply_to(config)
	assert_float(config.duration).is_equal(180.0)
	assert_int(config.target_score).is_equal(2000)
	assert_int(config.joker_slots).is_equal(4)
	assert_int(config.bot_count).is_equal(1)
	assert_bool(options.presets.button(1).button_pressed).is_true()
	assert_bool(options.presets.button(0).button_pressed).is_false()
	assert_str(options.rules_fold._lines[0].text).is_equal("3 min each · first to 2000 · 4 jokers")
	# Pressed again it stays lit, rather than letting go of itself as a toggle would.
	options.presets.button(1).pressed.emit()
	assert_bool(options.presets.button(1).button_pressed).is_true()
	options.presets.button(3).pressed.emit()
	options.apply_to(config)
	assert_int(config.target_score).is_zero()
	assert_bool(config.own_bullets_hurt).is_true()
	assert_bool(config.overtime).is_false()
	options.slots_option.select(5)
	options.slots_option.item_selected.emit(5)
	assert_bool(options.presets.button(-1).button_pressed).is_true()
	assert_bool(options.presets.button(3).button_pressed).is_false()
	assert_bool(options.rules_fold.open).is_false()
	options.presets.button(-1).pressed.emit()
	assert_bool(options.rules_fold.open).is_true()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(options.minutes_option)


## High roller's all items only where the loyalty program has added them: without the row there is
## no other set, and the preset is still lit on the basic one.
func test_high_roller_takes_all_items_only_when_there_are_any() -> void:
	var options := _pane().options
	assert_bool(options.has_items()).is_false()
	options.presets.button(2).pressed.emit()
	var config := MatchConfig.new()
	options.apply_to(config)
	assert_str(config.item_set).is_equal("first")
	assert_int(config.joker_slots).is_equal(8)
	assert_bool(options.presets.button(2).button_pressed).is_true()


## A Grand Prix's map sizes are two chips, one of them always lit.
func test_one_map_size_is_always_lit() -> void:
	var options := _pane().options
	options.normal_toggle.button_pressed = false
	assert_bool(options.xl_toggle.button_pressed).is_true()
	options.xl_toggle.button_pressed = false
	assert_bool(options.normal_toggle.button_pressed).is_true()
	assert_str(options.floor_fold._lines[0].text).is_equal("3 maps · Normal maps · tie-breaker")


## Too short for both open, the one opened first is folded; too narrow for two side by side, they
## stack with the perforation across between them; wide and tall, both stay open side by side.
func test_the_columns_fit_the_screen() -> void:
	Game.settings.floor_open = true
	Game.settings.rules_open = true
	var pane := _pane()
	var options := pane.options
	pane._panel.size = Vector2(1920.0, 1080.0)
	pane._fit()
	assert_bool(options.columns.vertical).is_false()
	assert_bool(options.floor_fold.open).is_true()
	assert_bool(options.rules_fold.open).is_true()
	pane._panel.size = Vector2(1600.0, 720.0)
	pane._fit()
	assert_bool(options.columns.vertical).is_false()
	assert_bool(options.floor_fold.open).is_true()
	assert_bool(options.rules_fold.open).is_false()
	options.rules_fold.head.pressed.emit()
	assert_bool(options.rules_fold.open).is_true()
	assert_bool(options.floor_fold.open).is_false()
	pane._panel.size = Vector2(1100.0, 2000.0)
	pane._fit()
	assert_bool(options.columns.vertical).is_true()
	assert_bool(options._tear.across).is_true()
	pane._panel.size = Vector2(1920.0, 2000.0)
	pane._fit()
	assert_bool(options.columns.vertical).is_false()
	assert_bool(options._tear.across).is_false()
	pane._panel.visible = false


## The Final Hand's table, STORY.md 8.1: both columns open and fixed so, since folded their fine
## print would say what is blacked out, and the presets blacked out and not to be pressed.
func test_the_final_hand_opens_both_columns_for_good() -> void:
	var pane := _pane()
	var config := MatchConfig.new()
	FinalHand.set_table(config, "normal")
	pane.set_by_the_house(config)
	var options := pane.options
	assert_bool(options.floor_fold.open).is_true()
	assert_bool(options.rules_fold.open).is_true()
	options.rules_fold.head.pressed.emit()
	assert_bool(options.rules_fold.open).is_true()
	pane._panel.size = Vector2(1600.0, 480.0)
	pane._fit()
	assert_bool(options.floor_fold.open).is_true()
	assert_bool(options.rules_fold.open).is_true()
	for chip: Button in options.presets.buttons():
		assert_bool(chip.disabled).is_true()
		assert_object(chip.find_child("Redacted", false, false)).is_not_null()
	pane.close()
	assert_bool(Game.settings.floor_open).is_false()
	pane._panel.visible = false


## The cursor walks the pane as it is laid out, GAME.md 9.6: down from the kinds of game to the
## presets and the columns' heads, and across from one column to what is level with it in the
## other, after the chip beside it in a row of two.
func test_the_cursor_walks_the_columns() -> void:
	Game.settings.floor_open = true
	Game.settings.rules_open = true
	var pane := _pane()
	pane._panel.size = Vector2(1920.0, 1080.0)
	pane._fit()
	await await_idle_frame()
	var options := pane.options
	options.mode_picker.button(true).grab_focus()
	_press(&"ui_down")
	assert_bool(options.presets.buttons().has(get_viewport().gui_get_focus_owner())).is_true()
	options.presets.button(0).grab_focus()
	_walk(
		[
			[&"ui_down", options.floor_fold.head],
			[&"ui_right", options.rules_fold.head],
			[&"ui_down", options.minutes_option],
			[&"ui_left", options.maps_option],
		]
	)
	# Down from Maps is one of the two chips under it; across from either the other first.
	options.normal_toggle.grab_focus()
	_walk(
		[
			[&"ui_right", options.xl_toggle],
			[&"ui_right", options.target_option],
			[&"ui_left", options.xl_toggle],
			[&"ui_left", options.normal_toggle],
		]
	)
	pane._panel.visible = false


func _walk(steps: Array) -> void:
	for step: Array in steps:
		_press(step[0])
		var held := get_viewport().gui_get_focus_owner()
		var went := "%s went to %s" % [step[0], held.name if held != null else "nothing"]
		assert_object(held).override_failure_message(went).is_same(step[1])


func _press(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	get_viewport().push_input(press)
