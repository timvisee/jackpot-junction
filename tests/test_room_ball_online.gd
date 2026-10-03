extends GdUnitTestSuite
## The waiting room's football online, GAME.md 9.6: kicked at once by a client whose own kart meets
## it, run there and told to the host, which goes by that client's word until the client lets go
## or somebody else kicks it. In a room on one machine, with the ball of a client and the host's
## ball each made by the test and fed what the wire would carry.

const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")
## Where the balls made here are put: well away from the room's own ball and the pad.
const SPOT := Vector3(-6.0, 0.0, 3.0)
## A client's peer, as the host would know it.
const CLIENT := 7

var _runner: GdUnitSceneRunner
## The player's own settings, put aside: the room's match settings save as they close, and a test
## writing the player's real file would be deciding their next match for them.
var _settings_were: Settings


func before_test() -> void:
	Game.pending_config = MatchConfig.new()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_room_ball_online.cfg"


func after_test() -> void:
	Game.pending_config = null
	DirAccess.remove_absolute(Game.settings.path)
	Game.settings = _settings_were


func _open() -> Node3D:
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	_runner = scene_runner(room)
	await _runner.simulate_frames(45, 17)
	if room.ready_room.everybody_ready.is_connected(room._begin):
		room.ready_room.everybody_ready.disconnect(room._begin)
	if room.host_settings != null:
		room.host_settings.close()
	return room


## The kart in slot 0 driven at [param ball] from four meters off, flat out.
func _drive_at(match_node: Match, ball: RoomBall) -> Kart:
	var kart := match_node.kart_of(0)
	var at := ball.global_position
	kart.global_position = Vector3(at.x - 4.0, 0.0, at.z)
	kart.face(Vector3.RIGHT)
	var driver := KartInput.new()
	driver.throttle = 1.0
	kart.input = driver
	return kart


## A ball as a client has it, told where it is by the host, with the kart in slot 0 its own.
func _client_ball(match_node: Match) -> RoomBall:
	var ball := RoomBall.add_to(match_node, SPOT, false)
	ball.here = CLIENT
	match_node.kart_of(0).predicted = true
	return ball


## Whether the ball is taken by this machine's kart within a second and a half.
func _taken(ball: RoomBall) -> bool:
	for i: int in 30:
		if ball.simulating:
			return true
		await _runner.simulate_frames(3, 17)
	return ball.simulating


## A client's own kart meeting the ball kicks it there and then, and the client runs it from there
## on and tells the host where it is, which kick of its own that is, as often as the host does.
func test_a_client_kicks_the_ball_its_own_kart_meets_at_once() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball := _client_ball(match_node)
	var said: Array[Array] = []
	ball.claimed.connect(func(state: Array) -> void: said.append(state))
	await _runner.simulate_frames(2, 17)
	assert_bool(ball.freeze).is_true()
	var start := ball.global_position
	_drive_at(match_node, ball)
	await _runner.simulate_frames(60, 17)
	assert_bool(ball.simulating).override_failure_message("it waited for the host").is_true()
	assert_bool(ball.freeze).is_false()
	assert_float(ball.global_position.x - start.x).is_greater(1.0)
	assert_float(ball.linear_velocity.x).is_greater(0.5)
	assert_float(ball.global_position.y).is_equal_approx(RoomBall.RADIUS, 0.01)
	assert_bool(said.is_empty()).override_failure_message("the host was never told").is_false()
	assert_int(int(said[-1][4])).is_equal(1)


## Somebody else's kart on a client is not this machine's to kick with: the host does that.
func test_a_client_leaves_other_karts_to_the_host() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball := _client_ball(match_node)
	match_node.kart_of(0).predicted = false
	await _runner.simulate_frames(2, 17)
	_drive_at(match_node, ball)
	await _runner.simulate_frames(60, 17)
	assert_bool(ball.simulating).is_false()


## While a client has the ball, the host's word for it from before is let be; the host going by the
## client's kick is heard as such; and once it has, word of anybody else's has the client let go
## and follow again. And it lets go by itself once its kart has left it alone for a while.
func test_a_client_keeps_the_ball_until_somebody_else_kicks_it() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball := _client_ball(match_node)
	await _runner.simulate_frames(2, 17)
	var kart := _drive_at(match_node, ball)
	assert_bool(await _taken(ball)).override_failure_message("never kicked").is_true()
	kart.input = KartInput.new()
	kart.global_position += Vector3(0.0, 0.0, 8.0)
	# The host's word from before the kick: the ball where it was, on its own word.
	var there := ball.global_position
	ball.follow([SPOT.x, SPOT.z, 0.0, 0.0, 1, 0])
	await _runner.simulate_frames(2, 17)
	assert_bool(ball.simulating).is_true()
	assert_float(ball.global_position.distance_to(there)).is_less(1.0)
	# Somebody else's word, before the host has heard this machine's, is from before it too.
	ball.follow([SPOT.x, SPOT.z, 0.0, 0.0, 9, 1])
	assert_bool(ball.simulating).is_true()
	ball.follow([there.x, there.z, 1.0, 0.0, CLIENT, 1])
	assert_bool(ball.agreed).is_true()
	assert_bool(ball.simulating).is_true()
	# Now somebody else has kicked it since.
	ball.follow([2.0, 2.0, 0.0, 0.0, 9, 1])
	assert_bool(ball.simulating).is_false()
	assert_bool(ball.freeze).is_true()
	await _runner.simulate_frames(40, 17)
	assert_float(ball.global_position.distance_to(Vector3(2.0, RoomBall.RADIUS, 2.0))).is_less(0.3)
	# Kicked again, and left alone: it goes back to the host's word by itself.
	_drive_at(match_node, ball)
	assert_bool(await _taken(ball)).override_failure_message("never kicked again").is_true()
	kart.input = KartInput.new()
	kart.global_position += Vector3(0.0, 0.0, 8.0)
	await _runner.simulate_frames(int(RoomBall.OWN_TIME * 60.0) + 10, 17)
	assert_bool(ball.simulating).override_failure_message("it never let go").is_false()


## The host goes by a client's word for the ball its kart kicked, and says whose word it is; an old
## kick of a client's is nothing once somebody has kicked it since; and it is the host's again once
## the client goes quiet about it.
func test_the_host_goes_by_the_client_that_kicked_it() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball := RoomBall.add_to(match_node, SPOT, true)
	var told: Array[Array] = []
	ball.moved.connect(func(state: Array) -> void: told.append(state))
	await _runner.simulate_frames(2, 17)
	ball.adopt(CLIENT, [SPOT.x + 1.0, SPOT.z, 3.0, 0.0, 1])
	await _runner.simulate_frames(4, 17)
	assert_int(ball.owner_peer).is_equal(CLIENT)
	assert_float(ball.global_position.x).is_greater(SPOT.x + 1.0)
	assert_int(int(told[-1][4])).is_equal(CLIENT)
	assert_int(int(told[-1][5])).is_equal(1)
	# Another client kicks it after, and the first's word for its old kick is nothing now.
	ball.adopt(9, [SPOT.x, SPOT.z + 1.0, 0.0, 2.0, 1])
	assert_int(ball.owner_peer).is_equal(9)
	ball.adopt(CLIENT, [SPOT.x + 5.0, SPOT.z, 3.0, 0.0, 1])
	assert_int(ball.owner_peer).is_equal(9)
	# A new kick of the first's is the latest, and it has the ball again.
	ball.adopt(CLIENT, [SPOT.x + 1.0, SPOT.z, 3.0, 0.0, 2])
	assert_int(ball.owner_peer).is_equal(CLIENT)
	await _runner.simulate_frames(int(RoomBall.OWNER_QUIET * 60.0) + 6, 17)
	assert_int(ball.owner_peer).override_failure_message("never taken back").is_equal(1)


## A kart the host drives itself kicks the ball the host's way whoever had it; one played at a
## client does not kick it on the host at all, since its client does and says so.
func test_the_host_kicks_with_its_own_karts_only() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball := RoomBall.add_to(match_node, SPOT, true)
	await _runner.simulate_frames(2, 17)
	var kart := _drive_at(match_node, ball)
	var controls := kart.input
	kart.input = NetInput.new()
	kart.global_position = ball.global_position
	await _runner.simulate_frames(10, 17)
	assert_float(ball.linear_velocity.length()).is_less(0.1)
	# A client has it, and goes on saying so, when the host's own kart drives into it.
	ball.adopt(CLIENT, [SPOT.x, SPOT.z, 0.0, 0.0, 1])
	kart.input = controls
	kart.global_position = ball.global_position - Vector3(4.0, 0.0, 0.0)
	for i: int in 20:
		var at := ball.global_position
		ball.adopt(CLIENT, [at.x, at.z, ball.linear_velocity.x, ball.linear_velocity.z, 1])
		await _runner.simulate_frames(3, 17)
	assert_int(ball.owner_peer).override_failure_message("the client kept it").is_equal(1)
	assert_float(ball.linear_velocity.x).is_greater(0.5)
