extends GdUnitTestSuite
## The way a kart driven here is traveling, as the camera looks ahead of it, GAME.md 8.2, see
## [KartTravel]: eased, so a knock that turns a kart round in a frame does not swing the camera.

const FRAME := 1.0 / 60.0


func _kart(velocity: Vector3) -> CharacterBody3D:
	var kart: CharacterBody3D = auto_free(CharacterBody3D.new())
	kart.velocity = velocity
	return kart


func test_a_kart_new_to_it_is_taken_as_it_is_going() -> void:
	var travel := KartTravel.new()
	var kart := _kart(Vector3(10.0, 0.0, 0.0))
	assert_vector(travel.of(kart)).is_equal(Vector3(10.0, 0.0, 0.0))
	travel.follow([kart] as Array[Node3D], FRAME)
	assert_vector(travel.of(kart)).is_equal(Vector3(10.0, 0.0, 0.0))


func test_a_sudden_turn_comes_through_over_its_ease() -> void:
	var travel := KartTravel.new()
	var kart := _kart(Vector3(10.0, 0.0, 0.0))
	travel.follow([kart] as Array[Node3D], FRAME)
	# Knocked straight back the way it came.
	kart.velocity = Vector3(-10.0, 0.0, 0.0)
	travel.follow([kart] as Array[Node3D], FRAME)
	assert_float(travel.of(kart).x).is_greater(9.0)
	for i: int in int(KartTravel.EASE / FRAME):
		travel.follow([kart] as Array[Node3D], FRAME)
	# About two thirds of the way after its ease, and nearly all of it after three.
	assert_float(travel.of(kart).x).is_between(-4.0, -2.0)
	for i: int in int(KartTravel.EASE * 2.0 / FRAME):
		travel.follow([kart] as Array[Node3D], FRAME)
	assert_float(travel.of(kart).x).is_less(-8.5)


func test_up_and_down_is_left_out_and_a_kart_gone_is_forgotten() -> void:
	var travel := KartTravel.new()
	var kart := _kart(Vector3(3.0, 5.0, 4.0))
	travel.follow([kart] as Array[Node3D], FRAME)
	assert_vector(travel.of(kart)).is_equal(Vector3(3.0, 0.0, 4.0))
	travel.follow([] as Array[Node3D], FRAME)
	kart.velocity = Vector3(-6.0, 0.0, 0.0)
	assert_vector(travel.of(kart)).is_equal(Vector3(-6.0, 0.0, 0.0))
