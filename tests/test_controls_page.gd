extends GdUnitTestSuite
## The Controls page of the settings, GAME.md 8.5: how the first player drives and the bindings,
## in groups under headings, every action that can be bound in one of them.

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")

var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_controls_page.cfg"


func after_test() -> void:
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


## Every action that can be bound is in exactly one group, so none goes missing from the page.
func test_every_rebindable_action_is_in_one_group() -> void:
	var grouped: Array[StringName] = []
	for named: String in SettingsScreen.BINDINGS:
		for action: StringName in SettingsScreen.BINDINGS[named]:
			grouped.append(action)
	assert_int(grouped.size()).is_equal(SettingsScreen.REBINDABLE.size())
	assert_array(grouped).contains_exactly_in_any_order(SettingsScreen.REBINDABLE)


## The groups stand in order under their headings, driving, fighting and the game down the left and
## the controllers, jokers and emotes down the right, each binding group with its columns named.
func test_the_groups_stand_under_headings() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	var groups := screen.tabs.get_node("Controls/Groups") as SettingsColumns
	var headings: Array[String] = []
	for each: Node in groups.get_children():
		headings.append((each.get_node("Heading/Title") as Label).text)
	var wanted: Array[String] = [
		SettingsScreen.DRIVING,
		SettingsScreen.FIGHTING,
		SettingsScreen.GAME,
		SettingsScreen.CONTROLLERS,
		SettingsScreen.JOKERS,
		SettingsScreen.EMOTES,
	]
	assert_array(headings).is_equal(wanted)
	assert_int(groups.split).is_equal(3)
	for named: String in SettingsScreen.BINDINGS:
		var group := groups.get_node(named)
		var head := group.get_child(
			group.get_child_count() - SettingsScreen.BINDINGS[named].size() - 1
		)
		assert_str((head.get_child(1) as Label).text).is_equal(SettingsScreen.BINDING_HEADS[1])
	(
		assert_object(
			groups.get_node(SettingsScreen.CONTROLLERS).find_child("ResetBindings", true, false)
		)
		. is_not_null()
	)


## Every action is named in sentence case, as every other row of the settings is, the jokers' by
## what they do; and so while its new key is awaited.
func test_the_actions_are_named_in_sentence_case() -> void:
	for action: StringName in SettingsScreen.REBINDABLE:
		var words := SettingsScreen._action_words(action)
		assert_str(words.substr(1)).is_equal(words.substr(1).to_lower())
		assert_str(words.substr(0, 1)).is_equal(words.substr(0, 1).to_upper())
	assert_str(SettingsScreen._action_words(InputActions.JOKER_PREV)).is_equal("Previous joker")
	assert_str(SettingsScreen._action_words(InputActions.STEER_LEFT)).is_equal("Steer left")
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	var sockets: Array = screen._binding_labels[InputActions.JOKER_NEXT]
	(sockets[0] as Button).pressed.emit()
	assert_str(screen.status.text).contains("Next joker")
	screen._stop_listening("")
	# The keys taken out of the sockets go at the end of the frame.
	await await_idle_frame()
