extends GdUnitTestSuite
## A player's name and color changed in the lobby and the Garage, GAME.md 4.4: from their switch in
## the pause menu, at once on this machine, and across the wire by way of the host.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const DT := 1.0 / 60.0

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_seat_identity.cfg"


func after_test() -> void:
	PlayerInput.typing = false
	Input.action_release(InputActions.THROTTLE)
	get_tree().paused = false
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


func _room(inputs: Array[KartInput]) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 3)
	return match_node


func test_a_player_moves_on_to_the_next_color_nobody_else_is_in() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(0, 1)]
	var match_node := _room(inputs)
	await _runner.simulate_frames(3, 17)
	var slot := match_node.slots[0]
	var kart := slot.kart
	assert_int(match_node.slots[1].color_index).is_equal(1)
	SeatIdentity.recolor(match_node, slot)
	# The second color is the other player's, so it is the third.
	assert_int(slot.color_index).is_equal(2)
	assert_int(kart.color_index).is_equal(2)
	assert_that(kart._tint.albedo_color).is_equal(Palette.player_color(2))
	var marker: MeshInstance3D = kart.get_node("Body/RoofMarker")
	var paint := marker.material_override as StandardMaterial3D
	assert_that(paint.albedo_color).is_equal(Palette.player_color(2))
	# The shape goes with the color, GAME.md 4.4: the third color's is the wedge.
	assert_bool(marker.mesh is PrismMesh).is_true()
	# Nobody is put in a color somebody else is already in.
	SeatIdentity.paint(match_node, slot, 1)
	assert_int(slot.color_index).is_equal(2)


func test_a_typed_name_is_the_players_and_kept_in_their_seat() -> void:
	var match_node := _room([PlayerInput.new(DeviceInput.KEYBOARD, 0)] as Array[KartInput])
	await _runner.simulate_frames(3, 17)
	var slot := match_node.slots[0]
	SeatIdentity.rename(slot, "  Zoom  ")
	assert_str(slot.player_name).is_equal("Zoom")
	assert_str(Game.settings.player_names[0]).is_equal("Zoom")
	# Emptied, the seat goes back to being handed a funny name, from the next match on.
	SeatIdentity.rename(slot, "")
	assert_str(Game.settings.player_names[0]).is_equal("")
	assert_str(slot.player_name).is_equal("Zoom")


func test_the_switch_in_the_lobby_has_the_name_and_the_color_on_it() -> void:
	var match_node := _room([PlayerInput.new(DeviceInput.ANY, 0)] as Array[KartInput])
	await _runner.simulate_frames(3, 17)
	var slot := match_node.slots[0]
	var menu := PauseMenu.add_to(match_node)
	menu.names_and_colors = true
	menu.set_paused(true)
	await await_idle_frame()
	var each: Dictionary = menu._switches._up[0]
	var box: LineEdit = each["box"]
	# Nothing typed yet: the funny name shows faintly, and leaving the box does not make it theirs.
	assert_str(box.text).is_empty()
	assert_str(box.placeholder_text).is_equal(slot.display_name())
	var buttons: Array[Control] = each["buttons"]
	assert_int(buttons.size()).is_equal(3)
	assert_str((each["color_word"] as Label).text).is_equal("Red")
	(buttons[1] as Button).pressed.emit()
	assert_int(slot.color_index).is_equal(1)
	await await_idle_frame()
	assert_str((each["color_word"] as Label).text).is_equal("Blue")
	var label: Label = each["name"]
	assert_that(label.get_theme_color("font_color")).is_equal(Palette.player_color(1))
	# The keys are the box's while it has the cursor.
	box.grab_focus()
	assert_bool(PlayerInput.typing).is_true()
	box.text = "Speedy"
	box.text_submitted.emit(box.text)
	assert_str(slot.player_name).is_equal("Speedy")
	menu.set_paused(false)
	assert_bool(PlayerInput.typing).is_false()
	assert_str(Game.settings.player_names[0]).is_equal("Speedy")
	# And the corner of the HUD under the switch is theirs again, in the new name and color.
	await _runner.simulate_frames(2, 17)
	var corner_name: Label = match_node.hud._blocks[0]["name"]
	assert_str(corner_name.text).is_equal("Speedy")
	assert_that(corner_name.get_theme_color("font_color")).is_equal(Palette.player_color(1))


func test_a_maps_switch_is_only_the_driving() -> void:
	var match_node := _room([PlayerInput.new(DeviceInput.ANY, 0)] as Array[KartInput])
	await _runner.simulate_frames(3, 17)
	var menu := PauseMenu.add_to(match_node)
	menu.set_paused(true)
	await await_idle_frame()
	var each: Dictionary = menu._switches._up[0]
	assert_bool(each.has("box")).is_false()
	assert_int((each["buttons"] as Array).size()).is_equal(1)
	menu.set_paused(false)


func test_typing_keeps_the_keyboard_player_still() -> void:
	var player := PlayerInput.new(DeviceInput.ANY, -1)
	Input.action_press(InputActions.THROTTLE)
	PlayerInput.typing = true
	player.poll(DT)
	assert_float(player.throttle).is_equal(0.0)
	PlayerInput.typing = false
	player.poll(DT)
	assert_float(player.throttle).is_equal(1.0)


func test_a_new_color_reaches_a_clients_screen() -> void:
	var host := _room([KartInput.new(), KartInput.new()] as Array[KartInput])
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = RULES.duplicate()
	client.arena_layout = LAYOUT
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	await _runner.simulate_frames(5, 17)
	client.apply_snapshot(host.build_snapshot())
	var puppet: Kart = client.slots[0].kart
	assert_int(puppet.color_index).is_equal(0)
	SeatIdentity.paint(host, host.slots[0], 5)
	client.apply_snapshot(host.build_snapshot())
	assert_int(client.slots[0].color_index).is_equal(5)
	assert_int(puppet.color_index).is_equal(5)
	assert_that(puppet._tint.albedo_color).is_equal(Palette.player_color(5))
