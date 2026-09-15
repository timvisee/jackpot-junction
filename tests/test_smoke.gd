extends GdUnitTestSuite
## Sanity checks that the project is wired up: settings, palette, input actions, dev scene.


func test_project_name() -> void:
	assert_str(ProjectSettings.get_setting("application/config/name")).is_equal("Jackpot Junction")


func test_every_action_is_registered_with_events() -> void:
	InputActions.register_defaults()
	for action: StringName in InputActions.all():
		(
			assert_bool(InputMap.has_action(action))
			. override_failure_message("missing action %s" % action)
			. is_true()
		)
		assert_int(InputMap.action_get_events(action).size()).is_greater(0)


func test_register_defaults_is_idempotent() -> void:
	InputActions.register_defaults()
	var before := InputMap.action_get_events(InputActions.FIRE).size()
	InputActions.register_defaults()
	assert_int(InputMap.action_get_events(InputActions.FIRE).size()).is_equal(before)


func test_player_colors_wrap_around() -> void:
	assert_object(Palette.player_color(8)).is_equal(Palette.player_color(0))
	assert_object(Palette.player_color(3)).is_not_equal(Palette.player_color(0))


func test_playground_scene_builds() -> void:
	var scene: PackedScene = load("res://scenes/dev/playground.tscn")
	var playground: Node3D = auto_free(scene.instantiate())
	add_child(playground)
	assert_object(playground.get_node("Table")).is_not_null()
	assert_object(playground.get_node("Camera")).is_not_null()
