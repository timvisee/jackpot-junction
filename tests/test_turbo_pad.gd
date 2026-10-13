extends GdUnitTestSuite
## Turbo pads launch a kart once its center is on the pad, not when its bumper touches the edge,
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
	pad.half_extents = Vector2(0.625, 0.625)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.25, 1.0, 1.25)
	shape.shape = box
	shape.position = Vector3(0.0, 0.5, 0.0)
	pad.add_child(shape)
	return pad


func test_the_pad_waits_until_the_karts_center_is_on_it_and_arms_again_after_leaving() -> void:
	var root: Node3D = auto_free(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(root)
	var pad := _pad()
	root.add_child(pad)
	var kart := StubKart.new()
	root.add_child(kart)
	# The bumper overlaps the pad but the center is still 1.2 m out: no launch yet.
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


## GAME.md 6.3: two pads side by side that fire the same way are one section, and a kart driven
## exactly down the line between them is launched, where as two pads its center was on the edge of
## both and well onto neither.
func test_the_line_between_two_pads_side_by_side_launches() -> void:
	var root: Node3D = auto_free(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(root)
	var pad := TurboPad.new()
	pad.direction = Vector3(0.0, 0.0, -1.0)
	pad.half_extents = Vector2(1.25, 0.625)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 1.0, 1.25)
	shape.shape = box
	shape.position = Vector3(0.0, 0.5, 0.0)
	pad.add_child(shape)
	root.add_child(pad)
	var kart := StubKart.new()
	root.add_child(kart)
	kart.global_position = Vector3(0.0, 0.0, 0.3)
	await runner.simulate_frames(3, 17)
	assert_int(kart.launches.size()).is_equal(1)
	# And only once for the whole section, however much of it the kart drives over.
	kart.global_position = Vector3(0.9, 0.0, 0.0)
	await runner.simulate_frames(3, 17)
	assert_int(kart.launches.size()).is_equal(1)


## Every XL map's turbo pads are four sections of two, each launched as one pad.
func test_pads_side_by_side_are_one_section() -> void:
	for id: StringName in ArenaMaps.IDS:
		# The showdown's map has none, GAME.md 6.3.
		if id == ArenaMaps.SHOWDOWN:
			continue
		var grid := ArenaMaps.layout(id).parse()
		var sections := grid.turbo_sections()
		assert_int(sections.size()).is_equal(4)
		for section: Rect2i in sections:
			assert_int(section.get_area()).is_equal(2 if ArenaMaps.is_xl(id) else 1)
