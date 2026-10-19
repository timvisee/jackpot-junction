extends GdUnitTestSuite
## The waiting room's cone, GAME.md 9.6: the driving test's own, see [SchoolCone], knocked over by
## a kart and standing itself up again.

const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")

var _runner: GdUnitSceneRunner
## The player's own settings, put aside: the room puts its match settings up, and closing them
## saves them.
var _settings_were: Settings


func before_test() -> void:
	Game.pending_config = MatchConfig.new()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_waiting_cone.cfg"


func after_test() -> void:
	Game.pending_config = null
	get_tree().paused = false
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


## A room on one machine, its settings put away and its way out unhooked.
func _open() -> Node3D:
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	_runner = scene_runner(room)
	await _runner.simulate_frames(45, 17)
	if room.ready_room.everybody_ready.is_connected(room._begin):
		room.ready_room.everybody_ready.disconnect(room._begin)
	if room.host_settings != null:
		room.host_settings.close()
	return room


## Standing from the first: a kart through it knocks it over, and a while later it stands itself up
## again where it stood, to be knocked over again; and a puppet's kart knocks it too, so every
## screen of a room sees it go.
func test_the_cone_goes_over_and_stands_up_again() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var cone := match_node.arena.get_node("WaitingProps/Cone") as SchoolCone
	assert_object(cone).is_not_null()
	assert_bool(RisingPiece.is_up(cone)).is_true()
	assert_float(cone.rights_after).is_equal(WaitingProps.CONE_UP_AFTER)
	var feel := cone.get_node("Feel") as Area3D
	assert_int(feel.collision_mask & Layers.PUPPET).is_not_zero()
	var stood := cone.position
	cone.rights_after = 0.1
	cone.knock(0, cone.global_position + Vector3(-2.0, 0.0, 0.0))
	assert_bool(cone.down).is_true()
	await await_millis(int((SchoolCone.FALL + 0.1 + SchoolCone.RIGHTING) * 1000.0) + 400)
	assert_bool(cone.down).is_false()
	assert_vector(cone.position).is_equal_approx(stood, Vector3.ONE * 0.01)
	assert_bool(feel.monitoring).is_true()
