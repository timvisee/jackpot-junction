extends GdUnitTestSuite
## Whom the camera keeps in the picture, GAME.md 8.2, see [FramedKarts]: every kart, the karts
## driven here and the rivals near them, or the karts driven here alone.

const ARENA := Vector2(40.0, 22.5)


func _kart(at: Vector3) -> Node3D:
	var kart: Node3D = auto_free(Node3D.new())
	add_child(kart)
	kart.global_position = at
	return kart


func test_everyone_keeps_every_kart_and_nobody_here_keeps_them_all_too() -> void:
	var mine := _kart(Vector3.ZERO)
	var far := _kart(Vector3(18.0, 0.0, 9.0))
	var framing := FramedKarts.new()
	var all: Array[Node3D] = [mine, far]
	var here: Array[Node3D] = [mine]
	assert_array(framing.pick(all, here, ViewChoices.FOLLOW_EVERYONE, ARENA)).is_equal(all)
	# A screen with nobody driving at it, one watching, follows everybody whatever was chosen.
	var nobody: Array[Node3D] = []
	assert_array(framing.pick(all, nobody, ViewChoices.FOLLOW_MINE, ARENA)).is_equal(all)


func test_my_kart_keeps_only_the_karts_driven_here() -> void:
	var mine := _kart(Vector3.ZERO)
	var also_mine := _kart(Vector3(-15.0, 0.0, 0.0))
	var close := _kart(Vector3(2.0, 0.0, 0.0))
	var framing := FramedKarts.new()
	var all: Array[Node3D] = [mine, close, also_mine]
	var here: Array[Node3D] = [mine, also_mine]
	var kept := framing.pick(all, here, ViewChoices.FOLLOW_MINE, ARENA)
	assert_array(kept).contains_exactly([mine, also_mine])


## Nearby keeps a rival within reach of a kart driven here, and lets it go only once it is well
## past that, so one driving along the line does not come and go.
func test_nearby_keeps_the_rivals_near_and_lets_them_go_further_out() -> void:
	var reach := ARENA.x * FramedKarts.NEAR
	var mine := _kart(Vector3.ZERO)
	var rival := _kart(Vector3(reach * 0.9, 0.0, 0.0))
	var far := _kart(Vector3(-reach * 1.5, 0.0, 0.0))
	var framing := FramedKarts.new()
	var all: Array[Node3D] = [mine, rival, far]
	var here: Array[Node3D] = [mine]
	assert_array(framing.pick(all, here, ViewChoices.FOLLOW_NEARBY, ARENA)).contains_exactly(
		[mine, rival]
	)
	# A little past the line: still kept.
	rival.global_position = Vector3(reach * 1.1, 0.0, 0.0)
	assert_array(framing.pick(all, here, ViewChoices.FOLLOW_NEARBY, ARENA)).contains([rival])
	# Well past it: let go, and not taken back until it is inside the line again.
	rival.global_position = Vector3(reach * (FramedKarts.LET_GO + 0.05), 0.0, 0.0)
	assert_array(framing.pick(all, here, ViewChoices.FOLLOW_NEARBY, ARENA)).not_contains([rival])
	rival.global_position = Vector3(reach * 1.1, 0.0, 0.0)
	assert_array(framing.pick(all, here, ViewChoices.FOLLOW_NEARBY, ARENA)).not_contains([rival])


## Following the rivals near, the picture is aimed at the karts driven here, not at the middle of
## them and their rivals, so the player's own kart stays in the middle of the screen; everywhere
## else at the middle of every kart in the picture.
func test_nearby_aims_at_the_karts_driven_here() -> void:
	var mine := _kart(Vector3.ZERO)
	var rival := _kart(Vector3(6.0, 0.0, 3.0))
	var framing := FramedKarts.new()
	var all: Array[Node3D] = [mine, rival]
	var here: Array[Node3D] = [mine]
	var places := PackedVector3Array([Vector3(0.5, 0.0, 0.0), Vector3(6.0, 0.0, 3.0)])
	var kept := framing.pick(all, here, ViewChoices.FOLLOW_NEARBY, ARENA)
	assert_array(kept).contains_exactly([mine, rival])
	var aimed := framing.aim_places(kept, places, here)
	assert_vector(FramedKarts.box(aimed).get_center()).is_equal(Vector3(0.5, 0.0, 0.0))
	framing.pick(all, here, ViewChoices.FOLLOW_EVERYONE, ARENA)
	aimed = framing.aim_places(all, places, here)
	assert_vector(FramedKarts.box(aimed).get_center()).is_equal(Vector3(3.25, 0.0, 1.5))


## Following the rivals near, the camera comes no closer than a share of the whole arena, however
## close the rig would come for a kart alone; and never further than the whole arena for it.
func test_nearby_comes_no_closer_than_a_share_of_the_arena() -> void:
	var mine := _kart(Vector3.ZERO)
	var framing := FramedKarts.new()
	var here: Array[Node3D] = [mine]
	framing.pick(here, here, ViewChoices.FOLLOW_NEARBY, ARENA)
	assert_float(framing.least(14.0, 50.0)).is_equal_approx(50.0 * FramedKarts.NEARBY_CLOSEST, 0.01)
	assert_float(framing.least(40.0, 50.0)).is_equal_approx(40.0, 0.01)
	assert_float(framing.least(60.0, 50.0)).is_equal_approx(50.0, 0.01)
	framing.pick(here, here, ViewChoices.FOLLOW_MINE, ARENA)
	assert_float(framing.least(14.0, 50.0)).is_equal_approx(14.0, 0.01)
