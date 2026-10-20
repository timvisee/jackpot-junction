extends TutorialSuite
## The driving test's camera and the spot the arrow on the floor points at, GAME.md 9.4a, see
## [SpotFraming]: the spot comes into the shot once the kart is within 15 m of it, stays in it until
## the kart is 17 m off, so a kart on the edge does not pump the camera, and is not framed at all
## where the camera is wanted on the kart alone.


func test_the_arrows_spot_comes_into_the_shot_near_it_and_leaves_it_well_away() -> void:
	SpotFraming.on = true
	var tutorial := await _start()
	var run := tutorial.run
	var rig := tutorial.match_node.camera_rig
	var framing := run.get_node("SpotFraming") as SpotFraming
	# On to the shooting lesson, the arrow on the nearest target against the east wall.
	for i: int in 2:
		run.skip()
		await _runner.simulate_frames(3, 17)
	assert_str(run.current_lesson().title).is_equal("Shooting")
	_put(tutorial, TestGround.TARGETS[1] - Vector2i(12, 0), TestGround.EAST)
	await _runner.simulate_frames(3, 17)
	var at := run.arrow.target
	assert_bool(at.is_finite()).is_true()
	var afield := func(meters: float) -> void:
		run.kart().respawn(Vector3(at.x - meters, 0.0, at.z), TestGround.EAST, 0.0)
		await _runner.simulate_frames(3, 17)
	# Well away, the kart alone.
	await afield.call(25.0)
	assert_bool(framing.framed).is_false()
	assert_array(rig.targets).is_equal([run.kart()] as Array[Node3D])
	# Near it, the spot is in the shot, where the arrow points.
	await afield.call(10.0)
	assert_bool(framing.framed).is_true()
	assert_bool(rig.targets.has(framing.spot)).is_true()
	var spot := framing.spot.global_position
	assert_float(Vector2(spot.x - at.x, spot.z - at.z).length()).is_less(0.01)
	# A little past its reach it stays, and only well past it does it go.
	await afield.call(16.0)
	assert_bool(rig.targets.has(framing.spot)).is_true()
	await afield.call(18.0)
	assert_bool(rig.targets.has(framing.spot)).is_false()
	# And coming back as far, it does not come in again until the kart is within its reach.
	await afield.call(16.0)
	assert_bool(rig.targets.has(framing.spot)).is_false()
	await afield.call(14.0)
	assert_bool(rig.targets.has(framing.spot)).is_true()
	# Off, the shot is on the kart alone again.
	SpotFraming.on = false
	await _runner.simulate_frames(2, 17)
	assert_array(rig.targets).is_equal([run.kart()] as Array[Node3D])
