extends GdUnitTestSuite
## Sanity checks that the project is wired up: settings, palette, input actions, dev scene.

## What a scene or a resource may not carry inside it, see [method _embedded_in].
const EMBEDDED: Array[String] = ["GDScript", "Shader", "VisualShader", "ShaderInclude"]


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
	assert_object(playground.get_node("Match/Arena")).is_not_null()
	assert_object(playground.get_node("Match/CameraRig")).is_not_null()
	assert_object(playground.get_node("Match/Bullets")).is_not_null()
	assert_object(playground.get_node("Match/Kart0")).is_not_null()
	assert_object(playground.get_node("Match/Kart1")).is_not_null()


func test_autoloads_are_available_in_tests() -> void:
	assert_object(get_tree().root.get_node_or_null("Events")).is_not_null()
	assert_object(get_tree().root.get_node_or_null("Game")).is_not_null()


## Scripts and shaders live in files of their own, GAME.md 10.4: none inside a scene or a
## resource, where an outside editor, the linter and a diff cannot get at them, and no shader as a
## string in a script. The addons are somebody else's.
func test_no_script_or_shader_is_embedded() -> void:
	var sample := '[gd_scene format=3]\n\n[sub_resource type="GDScript" id="GDScript_a1b2c"]\n'
	assert_array(_embedded_in(sample)).is_equal(["GDScript"] as Array[String])
	var files := _project_files("res://")
	assert_bool("res://scenes/match/match.tscn" in files).is_true()
	var found: Array[String] = []
	for path: String in files:
		if path.get_extension() in ["tscn", "tres"]:
			for kind: String in _embedded_in(FileAccess.get_file_as_string(path)):
				found.append("%s holds a %s" % [path, kind])
		elif path.get_extension() == "gd" and not path.begins_with("res://tests/"):
			if FileAccess.get_file_as_string(path).contains("shader_type "):
				found.append("%s holds shader code" % path)
	assert_array(found).is_empty()


## Which of [constant EMBEDDED] the text of a scene or a resource is, or carries.
func _embedded_in(text: String) -> Array[String]:
	var kinds: Array[String] = []
	for kind: String in EMBEDDED:
		for form: String in ['[sub_resource type="%s"', '[gd_resource type="%s"']:
			if text.contains(form % kind) and kind not in kinds:
				kinds.append(kind)
	return kinds


## Every file of the project's own under [param dir]: not the addons, nothing hidden, and nothing
## the engine is told to leave alone.
func _project_files(dir: String) -> Array[String]:
	var found: Array[String] = []
	var access := DirAccess.open(dir)
	if access == null or access.file_exists(".gdignore"):
		return found
	for file: String in access.get_files():
		found.append(dir.path_join(file))
	for sub: String in access.get_directories():
		if dir.path_join(sub) != "res://addons":
			found.append_array(_project_files(dir.path_join(sub)))
	return found
