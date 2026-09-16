extends GdUnitTestSuite
## Turbo pads launch a kart once its centre is on the pad, not when its bumper touches the edge,
## GAME.md 4.1, and arm again after the kart has left.


class StubKart:
	extends CharacterBody3D

	var launches: Array[Vector3] = []

	func _init() -> void:
		collision_layer = Layers.KART
		collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 0.8, 1.6)
		shape.shape = box
		shape.position = Vector3(0.0, 0.4, 0.0)
		add_child(shape)

	func apply_turbo(direction: Vector3) -> void:
		launches.append(direction)


func _pad() -> TurboPad:
	var pad := TurboPad.new()
	pad.direction = Vector3(0.0, 0.0, -1.0)
	pad.half_size = 0.625
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.25, 1.0, 1.25)
	shape.shape = box
	shape.position = Vector3(0.0, 0.5, 0.0)
	pad.add_child(shape)
	return pad


func test_the_pad_waits_until_the_karts_centre_is_on_it_and_arms_again_after_leaving() -> void:
	var root: Node3D = auto_free(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(root)
	var pad := _pad()
	root.add_child(pad)
	var kart := StubKart.new()
	root.add_child(kart)
	# The bumper overlaps the pad but the centre is still 1.2 m out: no launch yet.
	kart.global_position = Vector3(0.0, 0.0, 1.2)
	await runner.simulate_frames(3, 17)
	assert_int(kart.launches.size()).is_equal(0)
	kart.global_position = Vector3(0.0, 0.0, 0.4)
	await runner.simulate_frames(3, 17)
	assert_int(kart.launches.size()).is_equal(1)
	assert_vector(kart.launches[0]).is_equal(Vector3(0.0, 0.0, -1.0))
	# Sitting on the pad does not launch again; leaving and coming back does.
	await runner.simulate_frames(3, 17)
	assert_int(kart.launches.size()).is_equal(1)
	kart.global_position = Vector3(0.0, 0.0, 4.0)
	await runner.simulate_frames(3, 17)
	kart.global_position = Vector3(0.3, 0.0, -0.2)
	await runner.simulate_frames(3, 17)
	assert_int(kart.launches.size()).is_equal(2)
