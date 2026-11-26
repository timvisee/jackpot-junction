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
	# Every card of the table opened, GAME.md 8.9a, so the rows of each are there to set.
	Game.settings.profile.stats[&"maps"] = float(TableCards.Card.size())


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


## Standard is lit on the values of GAME.md; a preset sets House rules and the table but leaves the
## floor, a row set to none of them lights Custom, and Custom opens both columns with the cursor in
## House rules.
func test_the_presets_set_house_rules() -> void:
	var pane := _pane()
	var options := pane.options
	assert_bool(options.presets.button(1).button_pressed).is_true()
	options.bots_option.select(1)
	options.presets.button(0).pressed.emit()
	var config := MatchConfig.new()
	options.apply_to(config)
	assert_float(config.duration).is_equal(180.0)
	assert_int(config.target_score).is_equal(1500)
	assert_bool(config.overtime).is_false()
	assert_int(config.table).is_equal(TableCards.FIRST)
	assert_int(config.bot_count).is_equal(1)
	assert_bool(options.presets.button(0).button_pressed).is_true()
	assert_bool(options.presets.button(1).button_pressed).is_false()
	assert_str(options.rules_fold._lines[0].text).is_equal("3 min each · first to 1500")
	# Pressed again it stays lit, rather than letting go of itself as a toggle would.
	options.presets.button(0).pressed.emit()
	assert_bool(options.presets.button(0).button_pressed).is_true()
	options.presets.button(4).pressed.emit()
	options.apply_to(config)
	assert_int(config.target_score).is_zero()
	assert_bool(config.own_bullets_hurt).is_true()
	assert_bool(config.overtime).is_false()
	assert_int(config.table).is_equal(TableCards.ALL)
	options.slots_option.select(5)
	options.slots_option.item_selected.emit(5)
	assert_bool(options.presets.button(-1).button_pressed).is_true()
	assert_bool(options.presets.button(4).button_pressed).is_false()
	assert_bool(options.rules_fold.open).is_false()
	assert_bool(options.floor_fold.open).is_false()
	pane._panel.size = Vector2(1920.0, 1600.0)
	options.presets.button(-1).pressed.emit()
	assert_bool(options.rules_fold.open).is_true()
	assert_bool(options.floor_fold.open).is_true()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(options.minutes_option)


## Pressing Quick match deals its arena, again on every press, and so does a preset in one, GAME.md
## 9.7: a map at the usual size, never the one shown. A preset in a Grand Prix leaves it alone.
func test_quick_match_and_its_presets_deal_the_arena() -> void:
	var options := _pane().options
	var usual := ArenaMaps.pool(true, false)
	var shown := options._map_id()
	for press: int in 6:
		options.mode_picker.button(false).pressed.emit()
		assert_bool(options._map_id() in usual).is_true()
		assert_str(String(options._map_id())).is_not_equal(String(shown))
		shown = options._map_id()
	options.presets.button(2).pressed.emit()
	assert_str(String(options._map_id())).is_not_equal(String(shown))
	var arena := options.map_option.get_item_text(options.map_option.selected)
	assert_str(options.floor_fold._lines[0].text).is_equal(arena)
	options.mode_picker.button(true).pressed.emit()
	shown = options._map_id()
	options.presets.button(1).pressed.emit()
	assert_str(String(options._map_id())).is_equal(String(shown))


## Catch up is a House rule, GAME.md 3.16: on by default, set in the lobby, and turned off by
## Cutthroat alone. Only its absence shows in the folded fine print.
func test_catch_up_is_a_house_rule() -> void:
	var options := _pane().options
	var config := MatchConfig.new()
	options.apply_to(config)
	assert_bool(config.catch_up).is_true()
	options.catch_up_option.select(MatchOptions.CATCH_UP.find(false))
	options.catch_up_option.item_selected.emit(options.catch_up_option.selected)
	options.apply_to(config)
	assert_bool(config.catch_up).is_false()
	assert_str(options.rules_fold._lines[1].text).contains("no catch-up")
	options.presets.button(0).pressed.emit()
	options.apply_to(config)
	assert_bool(config.catch_up).is_true()
	options.presets.button(4).pressed.emit()
	options.apply_to(config)
	assert_bool(config.catch_up).is_false()


## The lobby's choices, kept in a file of their own, survive a save and a fresh load, catch up with
## the rest. Guards the move of this block out of [Settings] into lobby_settings_io.gd.
func test_the_lobby_settings_round_trip_through_disk() -> void:
	Game.settings.catch_up = false
	Game.settings.own_bullets_hurt = true
	Game.settings.joker_slots = 7
	Game.settings.save_to_disk()
	var reloaded := Settings.new()
	reloaded.path = Game.settings.path
	reloaded.load_from_disk()
	assert_bool(reloaded.catch_up).is_false()
	assert_bool(reloaded.own_bullets_hurt).is_true()
	assert_int(reloaded.joker_slots).is_equal(7)


## A preset is pressed by a click on its poker chip as much as on its words: the chip lets the
## mouse through to the button under it.
func test_a_click_on_a_presets_chip_presses_it() -> void:
	var pane := _pane()
	pane._panel.size = Vector2(1920.0, 1080.0)
	pane._fit()
	await await_idle_frame()
	var chip := pane.options.presets.button(0).find_children("*", "Control", true, false)[1]
	assert_str(chip.get_class()).is_equal("Control")
	var at := (chip as Control).get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = at
	move.global_position = at
	get_viewport().push_input(move, true)
	assert_object(get_viewport().gui_get_hovered_control()).is_same(pane.options.presets.button(0))
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		click.pressed = down
		click.position = at
		click.global_position = at
		get_viewport().push_input(click, true)
	assert_bool(pane.options.presets.button(0).button_pressed).is_true()
	assert_int(pane.options.target_option.selected).is_equal(MatchOptions.TARGETS.find(1500))
	pane._panel.visible = false


## High roller's all items only where the loyalty program has added them: without the row there is
## no other set, and the preset is still lit on the basic one.
func test_high_roller_takes_all_items_only_when_there_are_any() -> void:
	var options := _pane().options
	assert_bool(options.has_items()).is_false()
	options.presets.button(3).pressed.emit()
	var config := MatchConfig.new()
	options.apply_to(config)
	assert_str(config.item_set).is_equal("first")
	assert_int(config.joker_slots).is_equal(8)
	assert_bool(options.presets.button(3).button_pressed).is_true()


## A Grand Prix's map sizes are two chips, one of them always lit.
func test_one_map_size_is_always_lit() -> void:
	var options := _pane().options
	options.normal_toggle.button_pressed = false
	assert_bool(options.xl_toggle.button_pressed).is_true()
	options.xl_toggle.button_pressed = false
	assert_bool(options.normal_toggle.button_pressed).is_true()
	assert_str(options.floor_fold._lines[0].text).is_equal("3 maps · Normal maps · tie-breaker")


## Too short for both open, the one opened first is folded, which a screen of 1080 lines is now the
## table's cards are over them; too narrow for two side by side, they stack with the perforation
## across between them; wide and tall, both stay open side by side.
func test_the_columns_fit_the_screen() -> void:
	Game.settings.floor_open = true
	Game.settings.rules_open = true
	var pane := _pane()
	var options := pane.options
	pane._panel.size = Vector2(1920.0, 1600.0)
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
	pane._panel.size = Vector2(1920.0, 1600.0)
	pane._fit()
	await await_idle_frame()
	var options := pane.options
	options.mode_picker.button(true).grab_focus()
	_press(&"ui_down")
	assert_bool(options.presets.buttons().has(get_viewport().gui_get_focus_owner())).is_true()
	options.presets.button(2).grab_focus()
	_press(&"ui_down")
	assert_bool(options.table_strip.buttons().has(get_viewport().gui_get_focus_owner())).is_true()
	options.table_strip.button(TableCards.Card.ITEMS).grab_focus()
	_walk(
		[
			[&"ui_right", options.table_strip.button(TableCards.Card.JACKPOT)],
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


## A pad's shoulder buttons, or Q and E, go between the two kinds of game as tabs, GAME.md 9.6,
## drawn on them: left to the Grand Prix, right to the quick match, its arena dealt as a press of it
## deals it.
func test_the_tab_keys_are_the_kinds_of_game() -> void:
	var pane := _pane()
	var picker := pane.options.mode_picker
	picker.button(true).pressed.emit()
	var right := InputEventJoypadButton.new()
	right.button_index = JOY_BUTTON_RIGHT_SHOULDER
	right.pressed = true
	pane._input(right)
	assert_bool(picker.grand_prix).is_false()
	assert_bool(pane.options._map_id() in ArenaMaps.pool(true, false)).is_true()
	pane._input(_key(KEY_Q))
	assert_bool(picker.grand_prix).is_true()
	pane._input(_key(KEY_E))
	assert_bool(picker.grand_prix).is_false()
	pane._keyboard = false
	pane._pointer = false
	pane._show_bind()
	assert_object(picker.button(true).get_node_or_null("Bind")).is_not_null()
	pane._pointer = true
	pane._show_bind()
	assert_object(picker.button(true).get_node_or_null("Bind")).is_null()


## X on a pad, or F, goes round the presets, GAME.md 9.6: the next chip along from the one lit
## pressed, Custom after the four and the first after Custom, its bind drawn on the one lit.
func test_the_option_key_goes_round_the_presets() -> void:
	var pane := _pane()
	var bar := pane.options.presets
	bar.button(0).pressed.emit()
	assert_int(bar.lit()).is_equal(0)
	var seen: Array[int] = []
	for press: int in MatchPresets.PRESETS.size() + 1:
		pane._input(_key(KEY_F))
		seen.append(bar.lit())
	var expected: Array[int] = []
	for i: int in range(1, MatchPresets.PRESETS.size()):
		expected.append(i)
	expected.append_array([-1, 0])
	assert_array(seen).is_equal(expected)
	pane._keyboard = true
	pane._pointer = false
	pane._show_bind()
	assert_object(bar.button(0).get_node_or_null("Bind")).is_not_null()
	assert_object(bar.button(1).get_node_or_null("Bind")).is_null()


func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.keycode = code
	key.pressed = true
	return key


## The cards on the table, GAME.md 3.17 and 9.6: a press turns one over and lights Custom, Jokers
## down take Suits & hands and the jokers' rows with them, Suits & hands up bring Jokers back, and
## what was turned is kept with the profile.
func test_the_cards_on_the_table() -> void:
	var pane := _pane()
	var options := pane.options
	var strip := options.table_strip
	assert_int(strip.table).is_equal(TableCards.ALL)
	strip.button(TableCards.Card.SLOTS).pressed.emit()
	assert_bool(TableCards.has(strip.table, TableCards.Card.SLOTS)).is_false()
	assert_bool(options.presets.button(-1).button_pressed).is_true()
	assert_bool(options._slots_row.visible).is_true()
	strip.button(TableCards.Card.JOKERS).pressed.emit()
	assert_bool(TableCards.has(strip.table, TableCards.Card.SUITS)).is_false()
	assert_bool(options._slots_row.visible).is_false()
	assert_str(options.rules_fold._lines[0].text).not_contains("jokers")
	strip.button(TableCards.Card.SUITS).pressed.emit()
	assert_bool(TableCards.has(strip.table, TableCards.Card.SUITS)).is_true()
	assert_bool(TableCards.has(strip.table, TableCards.Card.JOKERS)).is_true()
	assert_bool(strip.button(TableCards.Card.JOKERS).up).is_true()
	assert_bool(options._slots_row.visible).is_true()
	strip.button(TableCards.Card.SLOTS).pressed.emit()
	assert_bool(options.presets.button(1).button_pressed).is_true()
	strip.button(TableCards.Card.BOUNTY).pressed.emit()
	var config := MatchConfig.new()
	options.apply_to(config)
	assert_bool(TableCards.has(config.table, TableCards.Card.BOUNTY)).is_false()
	pane.close()
	assert_int(Game.settings.profile.table.off).is_equal(TableCards.bit(TableCards.Card.BOUNTY))


## Suits & hands opened early bring Jokers with them where those are not opened yet either, the
## question saying so, both face up.
func test_suits_opened_early_open_jokers_too() -> void:
	Game.settings.profile.stats[&"maps"] = 1.0
	var pane := _pane()
	var strip := pane.options.table_strip
	strip.button(TableCards.Card.SUITS).pressed.emit()
	assert_str(pane._confirm.said()).contains("Jokers open with it")
	pane._confirm.yes_button().pressed.emit()
	for card: int in [TableCards.Card.SUITS, TableCards.Card.JOKERS]:
		assert_bool(TableCards.has(strip.opened, card)).is_true()
		assert_bool(TableCards.has(strip.table, card)).is_true()
	var config := MatchConfig.new()
	pane.options.apply_to(config)
	(
		assert_bool(
			TableCards.has(
				config.rules(load("res://data/match/default.tres")).table, TableCards.Card.SUITS
			)
		)
		. is_true()
	)
	pane._panel.visible = false


## Roulette's cards are its deck: one turned is out of it and Roulette stays lit.
func test_roulette_deals_from_the_cards_turned_up() -> void:
	var options := _pane().options
	options.presets.button(2).pressed.emit()
	assert_bool(options.table_strip.roulette).is_true()
	options.table_strip.button(TableCards.Card.FLUSH).pressed.emit()
	assert_bool(options.presets.button(2).button_pressed).is_true()
	var config := MatchConfig.new()
	options.apply_to(config)
	assert_bool(config.roulette).is_true()
	assert_bool(TableCards.has(config.table, TableCards.Card.FLUSH)).is_false()
	options.presets.button(1).pressed.emit()
	options.apply_to(config)
	assert_bool(config.roulette).is_false()
	assert_int(config.table).is_equal(TableCards.ALL)


## A card the House has not opened yet is sealed: pressed, it asks first, and opened it comes face
## up and stays opened; not now leaves it sealed.
func test_a_sealed_card_asks_to_open_early() -> void:
	Game.settings.profile.stats[&"maps"] = 1.0
	var pane := _pane()
	var strip := pane.options.table_strip
	assert_int(strip.opened).is_equal(TableCards.opened_by(1))
	strip.button(TableCards.Card.SLOTS).pressed.emit()
	assert_bool(pane._confirm.visible).is_true()
	assert_str(pane._confirm.said()).contains("Slot machines")
	pane._confirm.no_button().pressed.emit()
	assert_bool(TableCards.has(strip.opened, TableCards.Card.SLOTS)).is_false()
	strip.button(TableCards.Card.SLOTS).pressed.emit()
	pane._confirm.yes_button().pressed.emit()
	assert_bool(pane._confirm.visible).is_false()
	assert_bool(TableCards.has(strip.opened, TableCards.Card.SLOTS)).is_true()
	assert_bool(TableCards.has(strip.table, TableCards.Card.SLOTS)).is_true()
	(
		assert_bool(TableCards.has(Game.settings.profile.table_opened(), TableCards.Card.SLOTS))
		. is_true()
	)
	assert_object(get_viewport().gui_get_focus_owner()).is_same(strip.button(TableCards.Card.SLOTS))
	pane._panel.visible = false


## The Penny table kept: a card the House opens after stays down on it, while on Standard it comes
## up, GAME.md 8.9a.
func test_a_card_opened_later_stays_down_on_the_penny_table() -> void:
	Game.settings.profile.stats[&"maps"] = 2.0
	var pane := _pane()
	pane.options.presets.button(0).pressed.emit()
	pane.close()
	Game.settings.profile.stats[&"maps"] = 3.0
	assert_int(Game.settings.profile.table_set()).is_equal(TableCards.FIRST)
	var again: HostSettings = auto_free(HostSettings.add_to(self, true))
	again.open()
	again.options.presets.button(1).pressed.emit()
	again.close()
	Game.settings.profile.stats[&"maps"] = 4.0
	assert_int(Game.settings.profile.table_set()).is_equal(TableCards.opened_by(4))


## A card's hint, GAME.md 9.6: under the card under the mouse or the cursor, the mouse's first, its
## name and line as the loading screen says them, a sealed card's map on a chip; none once the House
## has locked the table.
func test_a_card_says_what_it_is_under_the_cursor() -> void:
	Game.settings.profile.stats[&"maps"] = 2.0
	var pane := _pane()
	pane._panel.size = Vector2(1920.0, 1080.0)
	pane._fit()
	await await_idle_frame()
	var strip := pane.options.table_strip
	var tip := strip._tip
	assert_bool(tip.visible).is_false()
	strip.button(TableCards.Card.JACKPOT).grab_focus()
	await await_idle_frame()
	assert_bool(tip.visible).is_true()
	assert_int(tip.card).is_equal(TableCards.Card.JACKPOT)
	assert_str(tip._line.text).is_equal(TableCards.LINES[TableCards.Card.JACKPOT])
	assert_bool(tip._chip.visible).is_false()
	# Under the card, clear of the presets over the strip.
	var card_foot := strip.button(TableCards.Card.JACKPOT).get_global_rect().end.y
	assert_float(tip.global_position.y).is_greater_equal(card_foot)
	strip._point(TableCards.Card.BOUNTY, true, true)
	assert_int(tip.card).is_equal(TableCards.Card.BOUNTY)
	assert_str(tip._chip.text).contains("AFTER MAP 6")
	strip._point(TableCards.Card.BOUNTY, true, false)
	assert_int(tip.card).is_equal(TableCards.Card.JACKPOT)
	strip.button(TableCards.Card.JACKPOT).release_focus()
	await await_idle_frame()
	assert_bool(tip.visible).is_false()
	strip.lock()
	strip._point(TableCards.Card.ITEMS, true, true)
	assert_bool(tip.visible).is_false()
	pane._panel.visible = false


## Under the cursor with keys or a pad in hand, a card's hint says which button turns it over, or
## for a sealed card asks to open it early, drawn for the device in hand, GAME.md 9.6; none for
## the mouse, whose press the line over the cards says, nor for a card only under the mouse.
func test_a_card_under_the_cursor_says_what_turns_it_over() -> void:
	Game.settings.profile.stats[&"maps"] = 2.0
	var pane := _pane()
	pane._panel.size = Vector2(1920.0, 1080.0)
	pane._fit()
	await await_idle_frame()
	var strip := pane.options.table_strip
	var tip := strip._tip
	strip.show_bind(true, true)
	strip.button(TableCards.Card.JACKPOT).grab_focus()
	await await_idle_frame()
	assert_bool(tip._bind.visible).is_true()
	assert_str(ScreenReader.words_in(tip._bind)).is_equal("Turn over")
	var keys := tip._bind_row
	assert_object(keys.find_children("*", "InputGlyph", true, false).front()).is_not_null()
	strip.show_bind(false, true)
	assert_bool(tip._bind.visible).is_true()
	assert_object(tip._bind_row).is_not_same(keys)
	strip.button(TableCards.Card.BOUNTY).grab_focus()
	await await_idle_frame()
	assert_str(ScreenReader.words_in(tip._bind)).is_equal("Open early")
	# A card under the mouse says nothing of a button, nor any with the mouse in hand.
	strip._point(TableCards.Card.ITEMS, true, true)
	assert_int(tip.card).is_equal(TableCards.Card.ITEMS)
	assert_bool(tip._bind.visible).is_false()
	strip._point(TableCards.Card.ITEMS, true, false)
	assert_bool(tip._bind.visible).is_true()
	strip.show_bind(false, false)
	assert_int(tip.card).is_equal(TableCards.Card.BOUNTY)
	assert_bool(tip._bind.visible).is_false()
	pane._panel.visible = false


## The binds hung under the two kinds of game and the lit preset, GAME.md 9.6, clear of the row
## under each, which is drawn after them and would cover their feet: the presets, and the cards.
func test_the_binds_hang_clear_of_the_row_under_them() -> void:
	var pane := _pane()
	pane._keyboard = true
	pane._pointer = false
	pane._show_bind()
	await await_idle_frame()
	var options := pane.options
	var presets_top := options.presets.get_global_rect().position.y
	for grand_prix: bool in [true, false]:
		var tab_bind := options.mode_picker.button(grand_prix).get_node("Bind") as Control
		assert_float(tab_bind.get_global_rect().end.y).is_less_equal(presets_top)
	var lit := options.presets.button(options.presets.lit())
	var preset_bind := lit.get_node("Bind") as Control
	var cards_top := options.table_strip.get_global_rect().position.y
	assert_float(preset_bind.get_global_rect().end.y).is_less_equal(cards_top)
	pane._panel.visible = false


## The cursor walks the cards across their row however they turn, GAME.md 9.6: a card turning over
## is narrowed as it is drawn and keeps its place and size, so across from it, or from beside it
## onto it, is the card beside rather than a column's head under the strip; and past either end of
## the row, the first card or the die after the last, the cursor stays where it is.
func test_the_cursor_walks_the_cards_as_they_turn() -> void:
	var pane := _pane()
	pane._panel.size = Vector2(1920.0, 1080.0)
	pane._fit()
	await await_idle_frame()
	var strip := pane.options.table_strip
	var jackpot := strip.button(TableCards.Card.JACKPOT)
	var jokers := strip.button(TableCards.Card.JOKERS)
	for turning: TableStrip.TableCardButton in [jackpot, jokers]:
		jackpot.grab_focus()
		# Halfway through its turn, where it is drawn at its narrowest.
		turning.turn()
		turning._turning = 0.5
		turning._process(0.0)
		assert_float(turning.scale.x).is_equal(1.0)
		_press(&"ui_right")
		assert_object(get_viewport().gui_get_focus_owner()).is_same(jokers)
		turning._turning = 0.0
	var first := strip.button(0)
	for end: Array in [[first, &"ui_left"], [strip.die, &"ui_right"]]:
		(end[0] as Control).grab_focus()
		_press(end[1])
		assert_object(get_viewport().gui_get_focus_owner()).is_same(end[0])
	pane._panel.visible = false


## Once the House has opened every card a die lies at the row's end, GAME.md 9.6, the kart dialog's
## name die: thrown, it deals the table at random, never every card down, never the table it was,
## and Suits & hands never without Jokers, turning the cards it changes over in a wave along the
## row as a preset does, and lighting whichever preset the table now matches. The cursor reaches it
## going right from the last card and stops there; its hint says what it does and, with keys in
## hand, its bind. Not before every card is opened, nor on a table the House has set.
func test_the_die_deals_the_table_at_random() -> void:
	var pane := _pane()
	pane._panel.size = Vector2(1920.0, 1080.0)
	pane._fit()
	await await_idle_frame()
	var options := pane.options
	var strip := options.table_strip
	assert_bool(strip.die.visible).is_true()
	strip._rng.seed = 7
	var heard := [0]
	strip.changed.connect(func() -> void: heard[0] += 1)
	for throw: int in 40:
		var was := strip.table
		for card: int in TableCards.Card.size():
			strip.button(card)._turning = 0.0
		strip.die.pressed.emit()
		var dealt := strip.table
		assert_int(dealt).is_not_equal(was)
		assert_int(dealt).is_not_equal(0)
		if TableCards.has(dealt, TableCards.Card.SUITS):
			assert_bool(TableCards.has(dealt, TableCards.Card.JOKERS)).is_true()
		var waits: Array[float] = []
		for card: int in TableCards.Card.size():
			var each := strip.button(card)
			assert_bool(each.up).is_equal(TableCards.has(dealt, card))
			var turned := TableCards.has(dealt, card) != TableCards.has(was, card)
			assert_bool(each._turning > 0.0).is_equal(turned)
			if turned:
				waits.append(each._wait)
		for i: int in range(1, waits.size()):
			assert_float(waits[i]).is_greater(waits[i - 1])
	assert_int(heard[0]).is_equal(40)
	assert_int(options.presets.lit()).is_equal(MatchPresets.matching(options))
	# The cursor on to it from the last card, and no further; its hint, with its bind for keys.
	strip.show_bind(true, true)
	strip.button(TableCards.Card.size() - 1).grab_focus()
	_press(&"ui_right")
	assert_object(get_viewport().gui_get_focus_owner()).is_same(strip.die)
	_press(&"ui_right")
	assert_object(get_viewport().gui_get_focus_owner()).is_same(strip.die)
	await await_idle_frame()
	assert_bool(strip._tip.visible).is_true()
	assert_str(strip._tip._name.text).is_equal(TableStrip.DIE_NAME.to_upper())
	assert_str(ScreenReader.words_in(strip._tip._bind)).is_equal(TableStrip.DIE_WORD)
	_press(&"ui_left")
	assert_object(get_viewport().gui_get_focus_owner()).is_same(
		strip.button(TableCards.Card.size() - 1)
	)
	# Not with a card still sealed, and not on a table the House has set.
	strip.set_table(strip.table, false, TableCards.opened_by(3))
	assert_bool(strip.die.visible).is_false()
	var sealed_table := strip.table
	strip.roll()
	assert_int(strip.table).is_equal(sealed_table)
	strip.set_table(strip.table, false, TableCards.ALL)
	assert_bool(strip.die.visible).is_true()
	strip.lock()
	assert_bool(strip.die.visible).is_false()
	pane._panel.visible = false


## A preset turns the cards it changes over as a press would, one after another along the row, and
## leaves the rest still, GAME.md 9.6.
func test_a_preset_turns_its_cards_in_a_wave() -> void:
	var options := _pane().options
	var strip := options.table_strip
	options.presets.button(0).pressed.emit()
	var items := strip.button(TableCards.Card.ITEMS)
	assert_float(items._turning).is_zero()
	var waits: Array[float] = []
	for card: int in range(TableCards.Card.JACKPOT, TableCards.Card.size()):
		var each := strip.button(card)
		assert_float(each._turning).override_failure_message(TableCards.NAMES[card]).is_greater(0.0)
		waits.append(each._wait)
	for i: int in range(1, waits.size()):
		assert_float(waits[i]).is_greater(waits[i - 1])
	assert_float(waits[0]).is_zero()
