extends GdUnitTestSuite
## The shaders compiled behind the title, GAME.md 10.7: a match on a viewport nobody sees, with
## one of everything put into it a step a frame, done once a run, and quiet while it runs.

const STAMP := "user://test_shader_warmup.cfg"


func before_test() -> void:
	ShaderWarmup.done = false
	ShaderWarmup.force = true
	# A stamp of its own, so the player's is neither read nor written by a test.
	ShaderWarmup.stamp_path = STAMP
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STAMP))


func after_test() -> void:
	ShaderWarmup.force = false
	ShaderWarmup.done = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STAMP))
	ShaderWarmup.stamp_path = ShaderWarmup.STAMP_PATH


## Every step is taken, one a frame, and the bar reaches the end; then it is gone, the buses are
## back, and a second title does not run it again.
func test_it_takes_every_step_once_and_says_so() -> void:
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	var runner := scene_runner(holder)
	var warmup := ShaderWarmup.add_to(holder)
	assert_object(warmup).is_not_null()
	var shown: Control = auto_free(Control.new())
	holder.add_child(shown)
	var pane := WarmupPane.over(shown, warmup)
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
	# The pane said so, full, and fades away by itself.
	assert_str(pane.percent.text).is_equal("100%")
	await await_millis(int((WarmupPane.LINGER + WarmupPane.FADE) * 1000.0) + 200)
	assert_bool(is_instance_valid(pane)).is_false()
	assert_object(ShaderWarmup.add_to(holder)).is_null()
	# And it left its stamp: the next start of this build on this card has nothing to compile,
	# as long as the cache is still as full as it left it.
	assert_bool(FileAccess.file_exists(STAMP)).is_true()
	ShaderWarmup.done = false
	assert_bool(ShaderWarmup.stamped()).is_true()
	assert_object(ShaderWarmup.add_to(holder)).is_null()
	assert_bool(ShaderWarmup.done).is_true()
	# A stamp from another build, or a cache that has been emptied since, does not count.
	var stamp := ConfigFile.new()
	stamp.load(STAMP)
	stamp.set_value("warmup", "key", "0.0.0|none|nothing")
	stamp.save(STAMP)
	assert_bool(ShaderWarmup.stamped()).is_false()
	stamp.set_value("warmup", "key", ShaderWarmup._key())
	stamp.set_value("warmup", "entries", ShaderWarmup.cache_entries() + 1)
	stamp.save(STAMP)
	assert_bool(ShaderWarmup.stamped()).is_false()


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


## The pane over the title says how far along it is and holds the cursor on Skip; Skip, or Back,
## stops the compiling and the pane goes, keeping nothing, so the next start asks again.
func test_skip_stops_it_and_puts_the_pane_away() -> void:
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	var runner := scene_runner(holder)
	var warmup := ShaderWarmup.add_to(holder)
	var pane := WarmupPane.over(holder, warmup)
	var gone := [false]
	pane.put_away.connect(func() -> void: gone[0] = true)
	await runner.simulate_frames(4, 17)
	assert_float(pane.bar.value).is_greater(0.0)
	assert_object(get_viewport().gui_get_focus_owner()).is_same(pane.skip_button)
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	pane._unhandled_input(back)
	assert_bool(gone[0]).is_true()
	await runner.simulate_frames(2, 17)
	assert_bool(is_instance_valid(warmup)).is_false()
	assert_bool(is_instance_valid(pane)).is_false()
	assert_bool(ShaderWarmup.done).is_false()
	assert_bool(FileAccess.file_exists(STAMP)).is_false()


## Headless and not forced, there is nothing to compile, and nothing is started.
func test_headless_has_nothing_to_compile() -> void:
	ShaderWarmup.force = false
	var holder: Node = auto_free(Node.new())
	add_child(holder)
	assert_object(ShaderWarmup.add_to(holder)).is_null()
	assert_int(holder.get_child_count()).is_equal(0)
