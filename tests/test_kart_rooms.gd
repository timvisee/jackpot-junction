extends GdUnitTestSuite
## The kart dialog in a room, GAME.md 4.4: opened from the pause menu of the lobby, which has its
## stalls too, a piece worn there is on the kart in the room at once and said to every screen.

const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	Game.pending_config = MatchConfig.new()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_kart_rooms.cfg"


func after_test() -> void:
	Game.pending_config = null
	get_tree().paused = false
	Net.close()
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


## A lobby on one machine, its match settings put away and the way out of it unhooked, as the
## waiting room's own suite opens one.
func _open() -> Node3D:
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	_runner = scene_runner(room)
	await _runner.simulate_frames(45, 17)
	if room.ready_room.everybody_ready.is_connected(room._begin):
		room.ready_room.everybody_ready.disconnect(room._begin)
	if room.host_settings != null:
		room.host_settings.close()
	return room


## The players here dress their karts from the pause menu as well as at the stalls, GAME.md 4.4:
## Customize kart in its Clubhouse, over Back, puts the kart dialog over the menu, and a piece worn
## there is on the kart in the room at once, said to every screen as a stall's is, and kept in the
## seat's settings.
func test_the_pause_menu_dresses_the_kart_too() -> void:
	var room := await _open()
	var menu: PauseMenu = room.get_node("PauseMenu")
	var entry := menu.find_child("YourKart", true, false) as Button
	assert_object(entry).override_failure_message("no Customize kart in the menu").is_not_null()
	var club := menu.find_child("Clubhouse", true, false) as Control
	assert_object(entry.get_parent()).is_same(club)
	assert_int(entry.get_index()).is_equal(club.get_node("ClubhouseBack").get_index() - 1)
	var dressed: Array[int] = []
	var heard := func(index: int, part: int, _values: PackedInt32Array) -> void:
		dressed.append_array([index, part])
	Events.kart_dressed.connect(heard)
	menu.set_paused(true)
	entry.pressed.emit()
	await _runner.simulate_frames(2, 17)
	var dialog := menu.get_node_or_null("KartDialog") as KartDialog
	assert_object(dialog).is_not_null()
	var slot: PlayerSlot = room.match_node.slots[0]
	assert_object(dialog.kart_owner().slot).is_same(slot)
	var spots := KartStyle.PAINTS.find("Spots")
	assert_bool(dialog.wear(0, spots)).is_true()
	Events.kart_dressed.disconnect(heard)
	assert_int(slot.kart.style.paint).is_equal(spots)
	assert_array(dressed).is_equal([slot.index, 0])
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).paint).is_equal(spots)
	dialog.close()
	await _runner.simulate_frames(2, 17)
	assert_object(menu.get_node_or_null("KartDialog")).is_null()
	assert_bool(menu.is_open()).is_true()
	menu.set_paused(false)
