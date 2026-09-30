extends GdUnitTestSuite
## The shaders compiled behind the title, GAME.md 10.7: a match on a viewport nobody sees, with
## one of everything put into it a step a frame, done once a run, and quiet while it runs.


func before_test() -> void:
	ShaderWarmup.done = false
	ShaderWarmup.force = true


func after_test() -> void:
	ShaderWarmup.force = false
	ShaderWarmup.done = false


## Every step is taken, one a frame, and the bar reaches the end; then it is gone, the buses are
## back, and a second title does not run it again.
func test_it_takes_every_step_once_and_says_so() -> void:
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	var runner := scene_runner(holder)
	var warmup := ShaderWarmup.add_to(holder)
	assert_object(warmup).is_not_null()
	var strip := ShaderWarmup.strip(warmup)
	holder.add_child(strip)
	var sfx := AudioServer.get_bus_index(Buses.SFX)
	assert_bool(AudioServer.is_bus_mute(sfx)).is_true()
	var ended := [false]
	warmup.finished.connect(func() -> void: ended[0] = true)
	var steps := warmup._steps.size()
	assert_int(steps).is_greater(40)
	await runner.simulate_frames(1, 17)
	assert_float(warmup.progress).is_between(0.005, 0.1)
	# The room goes up a phase a frame, and the match in it stands in its lobby: nothing runs
	# that a step does not run itself.
	assert_object(warmup._match).is_not_null()
	assert_int(warmup._match.slots.size()).is_equal(0)
	var seen_lobby := false
	for i: int in steps + ShaderWarmup.SETTLE + 2:
		await runner.simulate_frames(1, 17)
		if ended[0]:
			break
		if warmup._match.slots.size() == 4:
			seen_lobby = seen_lobby or warmup._match.state == Match.State.LOBBY
	assert_bool(seen_lobby).override_failure_message("the match never stood in its lobby").is_true()
	assert_bool(ended[0]).override_failure_message("never finished").is_true()
	assert_bool(ShaderWarmup.done).is_true()
	assert_bool(AudioServer.is_bus_mute(sfx)).is_false()
	await runner.simulate_frames(2, 17)
	assert_bool(is_instance_valid(warmup)).is_false()
	assert_object(ShaderWarmup.add_to(holder)).is_null()


## Left before it is done, it goes quietly: the buses come back and nothing of it is kept.
func test_leaving_the_title_stops_it_and_unmutes() -> void:
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	var runner := scene_runner(holder)
	var warmup := ShaderWarmup.add_to(holder)
	await runner.simulate_frames(3, 17)
	var kart := AudioServer.get_bus_index(Buses.KART)
	assert_bool(AudioServer.is_bus_mute(kart)).is_true()
	holder.remove_child(warmup)
	warmup.free()
	assert_bool(AudioServer.is_bus_mute(kart)).is_false()
	assert_bool(ShaderWarmup.done).is_false()


## Headless and not forced, there is nothing to compile, and nothing is started.
func test_headless_has_nothing_to_compile() -> void:
	ShaderWarmup.force = false
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	assert_object(ShaderWarmup.add_to(holder)).is_null()
	assert_int(holder.get_child_count()).is_equal(0)
