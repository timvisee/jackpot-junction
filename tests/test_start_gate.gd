extends GdUnitTestSuite
## The lamps held for whoever is still putting the room up, GAME.md 10.3: for everybody, for
## nobody who has left, and for no longer than the deadline.


func test_it_waits_until_every_client_has_the_room_up() -> void:
	var gate := StartGate.new(PackedInt32Array([7, 9]), 1)
	var connected := PackedInt32Array([7, 9])
	assert_that(gate.count()).is_equal(Vector2i(1, 3))
	assert_bool(gate.step(1.0, connected)).is_false()
	gate.arrived(9)
	assert_that(gate.count()).is_equal(Vector2i(2, 3))
	assert_bool(gate.step(1.0, connected)).is_false()
	gate.arrived(7)
	assert_bool(gate.step(1.0, connected)).is_true()
	assert_that(gate.count()).is_equal(Vector2i(3, 3))


func test_a_player_who_left_is_not_waited_for() -> void:
	var gate := StartGate.new(PackedInt32Array([7, 9]), 2)
	gate.arrived(7)
	assert_bool(gate.step(0.5, PackedInt32Array([7]))).is_true()
	# And they are not counted among the players either.
	assert_that(gate.count()).is_equal(Vector2i(3, 3))


func test_nobody_is_waited_for_past_the_deadline() -> void:
	var gate := StartGate.new(PackedInt32Array([7]), 1)
	var connected := PackedInt32Array([7])
	assert_bool(gate.step(StartGate.DEADLINE - 0.5, connected)).is_false()
	assert_bool(gate.step(1.0, connected)).is_true()
	# Still one short, and the lamps go anyway.
	assert_that(gate.count()).is_equal(Vector2i(1, 2))


func test_with_nobody_to_wait_for_it_opens_at_once() -> void:
	var gate := StartGate.new(PackedInt32Array(), 2)
	assert_bool(gate.step(0.0, PackedInt32Array())).is_true()
