extends GdUnitTestSuite
## Bullet marks, GAME.md 8.3: a shot that lands on a wall leaves a scorch there, on every screen,
## and a room only ever wears so many at once.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 21)
	return match_node


func _marks(match_node: Match) -> Array:
	var found: Array = []
	for child: Node in match_node.arena.get_children():
		if child is BulletMark:
			found.append(child)
	return found


## A shot fired straight into a wall leaves a mark lying against it, facing back the way the
## bullet came.
func test_a_shot_into_a_wall_leaves_a_mark_on_it() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	assert_array(_marks(match_node)).is_empty()
	var at := Vector3(4.0, Bullet.HEIGHT, 0.0)
	Events.bullet_struck.emit(at, Vector3(-1.0, 0.0, 0.0), Palette.NEON_CYAN)
	var marks := _marks(match_node)
	assert_int(marks.size()).is_equal(1)
	var mark: BulletMark = marks[0]
	# Just off the wall, and its face pointing back along the normal it was given.
	assert_vector(mark.global_position).is_equal_approx(
		at + Vector3(-BulletMark.LIFT, 0.0, 0.0), Vector3.ONE * 0.001
	)
	assert_vector(mark.global_basis.z.normalized()).is_equal_approx(
		Vector3(-1.0, 0.0, 0.0), Vector3.ONE * 0.01
	)


## A firefight against one wall does not end with the room made of scorch marks.
func test_a_room_wears_only_so_many_marks() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	for i: int in BulletMark.MAX_MARKS + 20:
		Events.bullet_struck.emit(
			Vector3(4.0, Bullet.HEIGHT, i * 0.1), Vector3(-1.0, 0.0, 0.0), Palette.NEON_CYAN
		)
	await _runner.simulate_frames(2, 17)
	assert_int(_marks(match_node).size()).is_equal(BulletMark.MAX_MARKS)


## A mark is gone a few seconds later, whether or not anything pushed it out.
func test_a_mark_fades_and_goes() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	Events.bullet_struck.emit(
		Vector3(4.0, Bullet.HEIGHT, 0.0), Vector3(-1.0, 0.0, 0.0), Palette.NEON_CYAN
	)
	var mark: BulletMark = _marks(match_node)[0]
	var fresh := mark._material.albedo_color.a
	mark._age = BulletMark.LIFETIME * (1.0 - BulletMark.FADE * 0.5)
	await _runner.simulate_frames(2, 17)
	assert_float(mark._material.albedo_color.a).is_less(fresh)
	mark._age = BulletMark.LIFETIME
	await _runner.simulate_frames(4, 17)
	assert_array(_marks(match_node)).is_empty()
