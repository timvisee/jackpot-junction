extends GdUnitTestSuite
## Where the tire marks are laid, GAME.md 4.3: under the wheels making them. And how, the same:
## a stretch at a time, so a finished stretch is never built again, both wheels drawn as one thing
## per stretch, and faded by the shader.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_tire_marks.cfg"


func after_test() -> void:
	Game.settings = _settings_were


func _start_match() -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new()]
	match_node.start(inputs, 7)
	return match_node


## The rear axle is taken from the middle of the tires on the model rather than from a fraction
## of the kart's length or from the point the model hangs a wheel from, either of which puts the
## marks somewhere the rubber is not.
func test_the_marks_are_laid_at_the_middle_of_the_rear_tires() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var wanted := Vector2.ZERO
	var count := 0
	for wheel: MeshInstance3D in kart._wheels:
		if not wheel.name.to_lower().contains("back"):
			continue
		var to_kart := kart.global_transform.affine_inverse() * wheel.global_transform
		var at := (to_kart * wheel.get_aabb()).get_center()
		wanted += Vector2(absf(at.x), at.z)
		count += 1
	assert_int(count).is_equal(2)
	wanted /= float(count)
	assert_float(kart.rear_half_track).is_equal_approx(wanted.x, 0.001)
	assert_float(kart.rear_axle).is_equal_approx(wanted.y, 0.001)
	# And that is wider than the wheels' own origins, which sit at their inner faces.
	var origin := absf(kart.to_local(kart._wheels[0].global_position).x)
	assert_float(kart.rear_half_track).is_greater(origin)


func _marks() -> TireMarks:
	var marks: TireMarks = auto_free(TireMarks.new())
	add_child(marks)
	return marks


## A kart driving [param steps] samples along x from [param from], both wheels, at [param now].
static func _drive(marks: TireMarks, from: float, steps: int, now: float, intensity := 0.5) -> void:
	for i: int in steps:
		var x := from + i * TireMarks.MIN_SAMPLE_DISTANCE * 1.5
		for wheel: int in 2:
			var z := -0.4 if wheel == 0 else 0.4
			marks.add_sample(wheel, Vector3(x, 0.0, z), Vector3(0.0, 0.0, 1.0), intensity, now)


func test_a_full_stretch_is_closed_and_the_next_runs_on_from_it() -> void:
	var marks := _marks()
	_drive(marks, 0.0, TireMarks.STRETCH - 1, 1.0)
	assert_int(marks.stretch_count()).is_equal(1)
	_drive(marks, (TireMarks.STRETCH - 1) * TireMarks.MIN_SAMPLE_DISTANCE * 1.5, 1, 1.0)
	assert_int(marks.stretch_count()).is_equal(2)
	# The stretch still being laid starts where each wheel's mark ended, so there is no gap.
	var closed: MeshInstance3D = marks._closed[0][0]
	assert_object(closed).is_not_same(marks._open_drawn)
	for wheel: int in 2:
		var carried: Dictionary = marks._open[wheel][0]
		assert_bool(carried["start"]).is_false()
		assert_float((carried["left"] as Vector3).x).is_greater(0.0)


## Both wheels, and a break in the mark, are one surface: one thing to draw for the stretch.
func test_a_stretch_is_one_surface_whatever_is_in_it() -> void:
	var marks := _marks()
	_drive(marks, 0.0, 10, 1.0)
	# Put down again well away, as a kart put back on the floor is: a new run of mark.
	_drive(marks, 20.0, 10, 1.0)
	marks._process(0.0)
	var mesh := marks._open_drawn.mesh as ImmediateMesh
	assert_int(mesh.get_surface_count()).is_equal(1)


## A finished stretch is left alone: driving on builds only the one still being laid.
func test_a_closed_stretch_is_not_built_again() -> void:
	var marks := _marks()
	_drive(marks, 0.0, TireMarks.STRETCH, 1.0)
	var closed := (marks._closed[0][0] as MeshInstance3D).mesh as ImmediateMesh
	var drawn := closed.get_rid()
	_drive(marks, 100.0, 20, 1.5)
	marks._process(0.0)
	assert_int(closed.get_surface_count()).is_equal(1)
	assert_that(closed.get_rid()).is_equal(drawn)
	# Nothing new laid, nothing built.
	assert_bool(marks._dirty).is_false()


## A stretch that has faded right out goes; the fading itself is the shader's, told the time.
func test_a_faded_stretch_goes() -> void:
	var marks := _marks()
	_drive(marks, 0.0, TireMarks.STRETCH, 1.0)
	assert_int(marks._closed.size()).is_equal(1)
	marks._expire(1.0 + TireMarks.FADE_SECONDS * 0.5)
	assert_int(marks._closed.size()).is_equal(1)
	marks._expire(1.0 + TireMarks.FADE_SECONDS + 0.1)
	assert_int(marks._closed.size()).is_equal(0)
	marks._process(0.0)
	var now: float = TireMarks.look().get_shader_parameter(&"now")
	assert_float(now).is_equal_approx(Time.get_ticks_msec() * 0.001, 1.0)


## Turned off in the settings, GAME.md 8.5, no marks are laid and those down go at once.
func test_turned_off_there_are_no_marks() -> void:
	var marks := _marks()
	_drive(marks, 0.0, TireMarks.STRETCH + 10, 1.0)
	assert_int(marks.stretch_count()).is_equal(2)
	Game.settings.tire_marks = false
	marks._process(0.0)
	assert_int(marks.stretch_count()).is_equal(1)
	assert_int((marks._open_drawn.mesh as ImmediateMesh).get_surface_count()).is_equal(0)
	_drive(marks, 100.0, 20, 2.0)
	assert_bool(marks._open[0].is_empty() and marks._open[1].is_empty()).is_true()
	# And on again, they are laid again.
	Game.settings.tire_marks = true
	_drive(marks, 200.0, 20, 3.0)
	marks._process(0.0)
	assert_int((marks._open_drawn.mesh as ImmediateMesh).get_surface_count()).is_equal(1)
