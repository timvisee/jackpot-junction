extends GdUnitTestSuite
## The Steam Input switch on the Controls page, GAME.md 10.8: it asks first, saying to set Steam's
## own switch in the game's properties alike, and goes only on a yes; Cancel and Back leave it as it
## was. Against [FakeSteamInput]; nothing here talks to Steam.

var _root: Control
var _switch: CheckButton
## Each time the switch went, which way.
var _went: Array[bool] = []


func before_test() -> void:
	_root = Control.new()
	add_child(_root)
	_switch = MenuTheme.toggle(true)
	_root.add_child(_switch)
	_went.clear()


func after_test() -> void:
	_root.free()


## Asks before the switch goes [param on].
func _ask(on: bool) -> ConfirmPane:
	return SteamInputRow.ask(_switch, on, func() -> void: _went.append(on))


func test_turning_it_off_asks_first_and_says_to_in_steam() -> void:
	var pane := _ask(false)
	# Still on while the question is up.
	assert_bool(_switch.button_pressed).is_true()
	assert_str(pane.said()).contains("Disable Steam Input")
	# The way there a paragraph of its own, after the colon.
	assert_str(pane.said()).contains(":\n\nIn your Steam Library")
	pane.yes_button().pressed.emit()
	assert_bool(_switch.button_pressed).is_false()
	assert_array(_went).is_equal([false])


func test_turning_it_on_says_to_in_steam_too() -> void:
	_switch.set_pressed_no_signal(false)
	var pane := _ask(true)
	assert_str(pane.said()).contains("Enable Steam Input")
	pane.yes_button().pressed.emit()
	assert_bool(_switch.button_pressed).is_true()
	assert_array(_went).is_equal([true])


func test_cancel_leaves_it_as_it_was() -> void:
	var pane := _ask(false)
	assert_str(pane.no_button().text).is_equal(SteamInputRow.CANCEL)
	pane.no_button().pressed.emit()
	assert_bool(_switch.button_pressed).is_true()
	assert_array(_went).is_empty()


func test_back_cancels_rather_than_leaving_the_page() -> void:
	_ask(false)
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	var question := _root.get_node("SteamInputQuestion") as ConfirmPane.Question
	question._unhandled_input(back)
	assert_bool(_switch.button_pressed).is_true()
	assert_array(_went).is_empty()


func test_the_switch_on_the_page_changes_the_setting_only_on_a_yes() -> void:
	var was := Store.steam
	Store.steam = SteamStore.new(FakeSteamInput.new())
	var settings := Settings.new()
	var column := VBoxContainer.new()
	_root.add_child(column)
	SteamInputRow.add_to(column, settings)
	var switch := column.find_child("SteamInput", true, false) as CheckButton
	switch.button_pressed = false
	assert_bool(settings.steam_input).is_true()
	assert_bool(switch.button_pressed).is_true()
	var pane := _root.find_children("*", "ConfirmPane", true, false)[0] as ConfirmPane
	pane.yes_button().pressed.emit()
	assert_bool(settings.steam_input).is_false()
	assert_bool((column.find_child("SteamLayout", true, false) as Button).disabled).is_true()
	Store.steam = was
