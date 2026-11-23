extends GdUnitTestSuite
## The lobby's pad as a room fills it, GAME.md 9.6, see [LobbyPad]: a room of eight has to be able
## to get all eight karts onto it and keep them there. The pad grows past four players, a kart may
## roll a little past its edge and still be on it, nothing on it bumps into anything, nor can a shot
## hurt a kart there; the charge waits a moment for a kart that leaves, fills faster in a full room,
## and whoever decides where the room goes can start it without waiting.

const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")
const WaitingRoom := preload("res://scenes/waiting/waiting_room.gd")

var _runner: GdUnitSceneRunner
var _settings_were: Settings


## A player who holds the throttle down and the wheel straight, for driving a kart into another.
class Throttle:
	extends PlayerInput

	func _init(on_device: int, at_seat: int) -> void:
		super(on_device, at_seat)

	func poll(_delta: float) -> void:
		throttle = 1.0
		steer = 0.0
		brake = 0.0


## The room reads the configuration it was opened with off [Game], and closing its match settings
## saves them, so every test runs on settings of its own, not the player's.
func before_test() -> void:
	Game.pending_config = MatchConfig.new()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_lobby_pad.cfg"


func after_test() -> void:
	Game.pending_config = null
	get_tree().paused = false
	Net.close()
	if _settings_were != null:
		Settings.remove_files(Game.settings.path)
		Game.settings = _settings_were
		_settings_were = null


## A room on one machine, its way out unhooked so a full house does not change the scene, and its
## match settings put away.
func _open() -> Node3D:
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	_runner = scene_runner(room)
	await _runner.simulate_frames(45, 17)
	if room.ready_room.everybody_ready.is_connected(room._begin):
		room.ready_room.everybody_ready.disconnect(room._begin)
	if room.host_settings != null:
		room.host_settings.close()
	return room


## Sits players down until [param players] are in the room, each on a pad of their own that nobody
## is holding, so their karts stand where they are put.
func _fill_to(match_node: Match, players: int) -> void:
	var device := 0
	while _humans(match_node) < players:
		match_node._join_with_input(PlayerInput.new(device, device % SeatLimit.MOST_HERE))
		device += 1


func _humans(match_node: Match) -> int:
	var count := 0
	for slot: PlayerSlot in match_node.slots:
		count += 1 if slot.is_human() else 0
	return count


## [param kart] put at [param at] facing [param toward], still.
func _put(kart: Kart, at: Vector3, toward: Vector3) -> void:
	kart.global_position = at
	kart.face(toward)
	kart.velocity = Vector3.ZERO
	kart.motor.velocity = Vector3.ZERO
	kart.protection_left = 0.0


## The pad keeps its size up to four players and grows past that, so every player has as much of it
## as in a room of four, and the ring round it grows with it. Somebody leaving shrinks it back.
func test_the_pad_grows_with_the_room() -> void:
	assert_float(LobbyPad.grown(2.5, 1)).is_equal(2.5)
	assert_float(LobbyPad.grown(2.5, 4)).is_equal(2.5)
	assert_float(LobbyPad.grown(2.5, 8)).is_equal_approx(2.5 * sqrt(2.0), 0.001)
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var lobby_pad: LobbyPad = room.ready_room.lobby_pad
	var pad := match_node.arena.junction
	assert_float(lobby_pad.radius).is_equal(lobby_pad.base)
	_fill_to(match_node, 8)
	await _runner.simulate_frames(60, 17)
	var eight := LobbyPad.grown(lobby_pad.base, 8)
	assert_float(lobby_pad.radius).is_equal_approx(eight, 0.001)
	assert_float(pad.radius).is_equal_approx(eight, 0.001)
	assert_float(pad._cylinder.radius).is_equal_approx(eight, 0.001)
	assert_float(match_node.arena.junction_radius).is_equal_approx(eight, 0.001)
	var block: MeshInstance3D = room.ready_room._segments[0]
	var out := Vector2(block.position.x - pad.position.x, block.position.z - pad.position.z)
	assert_float(out.length()).is_equal_approx(eight * ReadyRoom.RING_OUT, 0.001)
	# The face drawn out with it, never taller.
	for piece: Node3D in pad._face:
		assert_float(piece.scale.x).is_equal_approx(eight / lobby_pad.base, 0.001)
		assert_float(piece.scale.y).is_equal(1.0)
	# Four of them leave, and it is back to the size it was built at.
	for slot: PlayerSlot in match_node.slots.slice(4):
		match_node.leave_human(slot)
	await _runner.simulate_frames(60, 17)
	assert_float(lobby_pad.radius).is_equal_approx(lobby_pad.base, 0.001)


## Eight karts parked on the pad, some of them on top of one another, all ready up and the room
## goes: nobody is shoved off by anybody else, and the pad takes as long as a full room's charge.
func test_a_room_of_eight_all_stand_on_the_pad_and_go() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	var went := {"count": 0}
	ready_room.everybody_ready.connect(func() -> void: went["count"] += 1)
	_fill_to(match_node, 8)
	await _runner.simulate_frames(60, 17)
	assert_int(ready_room.player_count()).is_equal(8)
	assert_float(ready_room.charge_time()).is_equal(ReadyRoom.CHARGE_FULL)
	var middle := match_node.arena.junction.global_position
	var spots: Array[Vector3] = []
	for i: int in 8:
		# Two to a spot, pointing every which way: the second of each pair is on top of the first.
		var turn := TAU * float(i / 2) / 4.0
		spots.append(middle + Vector3(cos(turn), 0.0, sin(turn)) * 1.6)
		_put(match_node.slots[i].kart, spots[i], Vector3(sin(float(i)), 0.0, cos(float(i))))
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_FULL * 60.0) + 10, 17)
	assert_int(ready_room.ready_count()).is_equal(8)
	assert_bool(ready_room.all_ready()).is_true()
	for i: int in 8:
		var moved := match_node.slots[i].kart.global_position.distance_to(spots[i])
		assert_float(moved).is_less(0.1)
	await _runner.simulate_frames(int(ReadyRoom.GO_DELAY * 60.0) + 10, 17)
	assert_int(went["count"]).is_equal(1)


## A kart driving onto the pad goes through one parked on it rather than bumping it off, and the
## parked one stays where it is. Off the pad, two karts still bump as ever.
func test_a_kart_drives_through_one_parked_on_the_pad() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	_fill_to(match_node, 2)
	await _runner.simulate_frames(5, 17)
	var middle := match_node.arena.junction.global_position
	var parked := match_node.slots[0].kart
	var driver := match_node.slots[1]
	driver.input = Throttle.new(1, 1)
	driver.kart.input = driver.input
	_put(parked, middle, Vector3.RIGHT)
	_put(driver.kart, middle + Vector3(0.0, 0.0, 5.0), Vector3.FORWARD)
	await _runner.simulate_frames(90, 17)
	assert_float(parked.global_position.distance_to(middle)).is_less(0.05)
	# Through it and out the other side, not thrown back the way it came.
	assert_float(driver.kart.global_position.z).is_less(middle.z - 1.0)
	# Off in the corner of the room, the same drive is a bump.
	var corner := middle + Vector3(-10.0, 0.0, 4.0)
	_put(parked, corner, Vector3.RIGHT)
	_put(driver.kart, corner + Vector3(0.0, 0.0, 3.0), Vector3.FORWARD)
	await _runner.simulate_frames(5, 17)
	assert_bool(parked.get_collision_exceptions().has(driver.kart)).is_false()
	await _runner.simulate_frames(90, 17)
	assert_bool(driver.kart.last_bump_slot == parked.slot or parked.last_bump_slot == 1).is_true()
	assert_float(parked.global_position.distance_to(corner)).is_greater(0.3)


## A kart standing on the pad may roll a little past its edge and still be on it; one that was not
## on it yet does not start charging there, and one further out than the slack has left.
func test_a_kart_may_roll_a_little_past_the_edge() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	var lobby_pad: LobbyPad = ready_room.lobby_pad
	var kart := match_node.kart_of(0)
	var middle := match_node.arena.junction.global_position
	_put(kart, middle, Vector3.FORWARD)
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 60.0) + 10, 17)
	assert_bool(ready_room.all_ready()).is_true()
	# Across the edge by half the slack, still ready.
	var edge := lobby_pad.radius + LobbyPad.SLACK * 0.5 + kart.stats.width * 0.5
	_put(kart, middle + Vector3(edge, 0.0, 0.0), Vector3.FORWARD)
	await _runner.simulate_frames(10, 17)
	assert_float(lobby_pad.reach(kart)).is_greater(lobby_pad.radius)
	assert_bool(ready_room.all_ready()).is_true()
	assert_bool(kart.sheltered).is_true()
	# Past the slack: gone.
	_put(kart, middle + Vector3(edge + LobbyPad.SLACK, 0.0, 0.0), Vector3.FORWARD)
	await _runner.simulate_frames(3, 17)
	assert_bool(ready_room.all_ready()).is_false()
	assert_bool(kart.sheltered).is_false()
	# Long after its charge has gone, back to the spot inside the slack, which is not the pad.
	await _runner.simulate_frames(int(ReadyRoom.GRACE * 60.0) + 10, 17)
	_put(kart, middle + Vector3(edge, 0.0, 0.0), Vector3.FORWARD)
	await _runner.simulate_frames(30, 17)
	assert_float(ready_room.charge[0]).is_equal(0.0)


## The charge waits a moment for a kart that leaves the pad: back within [constant
## ReadyRoom.GRACE] seconds it is ready again at once, and later it starts over.
func test_coming_straight_back_is_ready_at_once() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	var kart := match_node.kart_of(0)
	var middle := match_node.arena.junction.global_position
	_put(kart, middle, Vector3.FORWARD)
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 60.0) + 10, 17)
	assert_bool(ready_room.all_ready()).is_true()
	_put(kart, Vector3(10.0, 0.0, 6.0), Vector3.FORWARD)
	await _runner.simulate_frames(45, 17)
	assert_bool(ready_room.all_ready()).is_false()
	_put(kart, middle, Vector3.FORWARD)
	await _runner.simulate_frames(3, 17)
	assert_bool(ready_room.all_ready()).is_true()
	assert_bool(ready_room._ticks.has(0)).is_true()
	# Away for longer than that, and the pad has to be charged again.
	_put(kart, Vector3(10.0, 0.0, 6.0), Vector3.FORWARD)
	await _runner.simulate_frames(int(ReadyRoom.GRACE * 60.0) + 10, 17)
	_put(kart, middle, Vector3.FORWARD)
	await _runner.simulate_frames(10, 17)
	assert_bool(ready_room.all_ready()).is_false()
	assert_float(ready_room.charge[0]).is_less(0.5)


## The pad charges faster the more are in the room: a player alone takes the usual time, a room
## of eight the shorter one, so the last of eight keeps nobody long.
func test_a_full_room_charges_faster() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	assert_float(ready_room.charge_time()).is_equal(ReadyRoom.CHARGE_TIME)
	_fill_to(match_node, 4)
	var four := ready_room.charge_time()
	assert_float(four).is_less(ReadyRoom.CHARGE_TIME)
	assert_float(four).is_greater(ReadyRoom.CHARGE_FULL)
	_fill_to(match_node, 8)
	assert_float(ready_room.charge_time()).is_equal(ReadyRoom.CHARGE_FULL)


## A shot at a kart on the pad is spent on it harmlessly: nothing knocks a kart off the pad, and a
## kart that died there would be put back somewhere else in the room.
func test_nothing_hurts_a_kart_on_the_pad() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var kart := match_node.kart_of(0)
	_put(kart, match_node.arena.junction.global_position, Vector3.FORWARD)
	await _runner.simulate_frames(3, 17)
	assert_bool(kart.sheltered).is_true()
	assert_bool(kart.is_targetable()).is_false()
	_put(kart, Vector3(10.0, 0.0, 6.0), Vector3.FORWARD)
	await _runner.simulate_frames(3, 17)
	assert_bool(kart.sheltered).is_false()
	assert_bool(kart.is_targetable()).is_true()


## Start now on the pause menu, at the machine that decides where the room goes: it asks first,
## saying how many are not ready, and yes sends the room on the way a full room goes.
func test_start_now_asks_and_goes() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	_fill_to(match_node, 3)
	await _runner.simulate_frames(5, 17)
	var went := {"count": 0}
	ready_room.everybody_ready.connect(func() -> void: went["count"] += 1)
	var menu: PauseMenu = room._menu
	menu.set_paused(true)
	await _runner.simulate_frames(2, 17)
	var start: Button = room._start_now
	assert_bool(start.is_visible_in_tree()).is_true()
	start.pressed.emit()
	assert_bool(menu.asking()).is_true()
	assert_str(menu._confirm._message.text).contains("3 of 3 players are not ready")
	# No stays.
	menu._answered(false)
	assert_bool(menu.asking()).is_false()
	assert_int(went["count"]).is_equal(0)
	start.pressed.emit()
	menu._answered(true)
	await _runner.simulate_frames(2, 17)
	assert_int(went["count"]).is_equal(1)
	assert_bool(menu.is_open()).is_false()


## What Start now says: who is not ready, one or several, or that everybody is.
func test_start_now_says_who_is_not_ready() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	_fill_to(match_node, 2)
	ready_room.ready_slots[0] = true
	assert_str(WaitingRoom.start_words(ready_room)[1]).starts_with("1 of 2 players is not ready")
	ready_room.ready_slots[match_node.slots[1].index] = true
	assert_str(WaitingRoom.start_words(ready_room)[1]).is_equal("Everybody is ready.")
	assert_str(WaitingRoom.start_words(ready_room)[2]).is_equal(WaitingRoom.START_NOW)
