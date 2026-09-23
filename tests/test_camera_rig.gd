extends GdUnitTestSuite
## The camera rig from GAME.md 8.2: it frames the karts rather than the arena, coming in as close
## as it can while keeping every one of them on screen.

const BOUNDS := AABB(Vector3(-20.0, 0.0, -11.25), Vector3(40.0, 1.0, 22.5))
const RIG_SCENE := preload("res://scenes/camera/camera_rig.tscn")

## The fixed camera is a setting on the one shared [Settings], so a test that turns it on puts it
## back afterwards rather than at the end of itself. A test that gives up half way through leaves
## an inline restore unrun, and the next thing to save the settings writes what it left behind to
## the player's own file: that is how this suite once left every rig in the run refusing to
## follow anything.
var _was_fixed := false


func before_test() -> void:
	_was_fixed = Game.settings.fixed_camera
	# Off to start with, whatever the machine running the tests has in its own settings file.
	# Every test here but the two about the fixed camera is a test about one that follows karts,
	# and a player who had turned it on would watch this suite fail twelve ways.
	Game.settings.fixed_camera = false


func after_test() -> void:
	Game.settings.fixed_camera = _was_fixed


## A rig watching karts parked at [param places], settled.
func _watching(places: Array) -> CameraRig:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var karts: Array[Node3D] = []
	for at: Vector3 in places:
		var kart: Node3D = auto_free(Node3D.new())
		add_child(kart)
		kart.global_position = at
		karts.append(kart)
	rig.targets.assign(karts)
	for i: int in 400:
		rig._process(0.05)
	return rig


func test_framing_distance_is_sensible_and_the_camera_looks_down_at_the_center() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	assert_float(rig._distance).is_between(25.0, 90.0)
	var forward := -rig.camera.global_basis.z
	assert_float(forward.y).is_less(-0.7)
	assert_float(rig.camera.global_position.y).is_greater(20.0)


## A match opens on the room it is played in, GAME.md 8.2: further back than the arena's own
## framing, centered, with every corner of the floor in the shot and room to spare.
func test_a_match_opens_on_the_room() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var framed := rig._distance
	var kart: Node3D = auto_free(Node3D.new())
	add_child(kart)
	kart.global_position = Vector3(2.0, 0.0, 1.0)
	rig.targets.assign([kart] as Array[Node3D])
	rig.open_on_the_room()
	assert_float(rig._distance).is_greater(framed * 1.05)
	assert_vector(rig._pan).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.01)
	await await_idle_frame()
	for x: float in [-20.0, 20.0]:
		for z: float in [-11.25, 11.25]:
			assert_bool(rig.camera.is_position_in_frustum(Vector3(x, 0.0, z))).is_true()


## And comes in from there at once rather than waiting for the lights: the move is the whole of
## the countdown, not something that happens after it.
func test_it_comes_in_from_the_opening_shot_at_once() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var kart: Node3D = auto_free(Node3D.new())
	add_child(kart)
	kart.global_position = Vector3(6.0, 0.0, 2.0)
	rig.targets.assign([kart] as Array[Node3D])
	rig.open_on_the_room()
	var opening := rig._distance
	# Half a second of it, which is nothing like the three seconds a countdown runs for.
	for i: int in 10:
		rig._process(0.05)
	assert_float(rig._distance).is_less(opening)
	for i: int in 200:
		rig._process(0.05)
	assert_float(rig._distance).is_less(opening * 0.9)
	assert_float(rig._distance).is_greater_equal(rig.follow_min_distance - 0.01)


## Opening is a one-off. A match that waits in a lobby and then counts down does not jump back
## out to the opening shot as the countdown starts.
func test_a_room_only_opens_once() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	rig.open_on_the_room()
	for i: int in 40:
		rig._process(0.05)
	var settled := rig._distance
	rig.open_on_the_room()
	assert_float(rig._distance).is_equal_approx(settled, 0.001)


func test_every_arena_corner_is_inside_the_frustum_after_a_frame() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	await await_idle_frame()
	rig.camera.fov = rig.base_fov * rig.zoom_min
	for x: float in [-20.0, 20.0]:
		for z: float in [-11.25, 11.25]:
			for y: float in [0.0, 1.0]:
				var corner := Vector3(x, y, z)
				(
					assert_bool(rig.camera.is_position_in_frustum(corner))
					. override_failure_message("corner %s not visible" % corner)
					. is_true()
				)


func test_pan_follows_the_targets_but_stays_within_the_limit() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var far_target: Node3D = auto_free(Node3D.new())
	add_child(far_target)
	far_target.global_position = Vector3(18.0, 0.0, 10.0)
	rig.targets.assign([far_target])
	var pan: Vector3 = rig._target_pan()
	assert_float(pan.length()).is_equal_approx(rig.pan_limit, 0.001)
	assert_float(pan.x).is_greater(0.0)
	assert_float(pan.z).is_greater(0.0)


## GAME.md 8.4: a frantic match gives the camera a faint constant tremble, and the toggle in 8.5
## still switches every kind of shake off.
func test_a_tremble_keeps_the_camera_shaking_and_the_setting_still_silences_it() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var shake_was := Game.settings.screen_shake
	Game.settings.screen_shake = true
	rig._shake = 0.0
	rig.tremble = 1.0
	await await_idle_frame()
	await await_idle_frame()
	assert_float(rig._shake).is_greater(0.0)
	rig.tremble = 0.0
	# Stepped by hand rather than by idle frames, which in a headless run are however long they
	# happen to be and say nothing about how long a shake takes to die away.
	for i: int in 40:
		rig._process(0.1)
	assert_float(rig._shake).is_equal_approx(0.0, 0.001)
	Game.settings.screen_shake = false
	rig.tremble = 1.0
	for i: int in 4:
		rig._process(0.1)
	assert_float(rig._shake).is_equal_approx(0.0, 0.001)
	Game.settings.screen_shake = shake_was


## GAME.md 8.2: the camera comes in on the karts. A fight in one corner of the arena is not a
## reason to keep the other three corners and the crowd on the screen.
func test_the_camera_comes_in_when_the_karts_are_together() -> void:
	var huddle: Array[Vector3] = [
		Vector3(4.0, 0.0, 2.0),
		Vector3(6.0, 0.0, 3.0),
		Vector3(5.0, 0.0, 4.5),
	]
	var rig := _watching(huddle)
	var wide: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(wide)
	wide.frame_arena(BOUNDS)
	assert_float(rig._distance).is_less(wide._distance * 0.8)
	assert_float(rig._distance).is_greater_equal(rig.follow_min_distance - 0.01)
	# And it is looking at them rather than at the middle of the floor.
	assert_float((rig._center + rig._pan).distance_to(Vector3(5.0, 0.0, 3.25))).is_less(1.0)


## However far apart they get, every one of them is still on the screen.
func test_every_kart_stays_on_screen_wherever_they_are() -> void:
	var spreads: Array = [
		[Vector3(4.0, 0.0, 2.0), Vector3(6.0, 0.0, 3.0)],
		[Vector3(-18.0, 0.0, -9.0), Vector3(18.0, 0.0, 9.0)],
		[Vector3(-18.0, 0.0, 9.0), Vector3(0.0, 0.0, 0.0), Vector3(18.0, 0.0, -9.0)],
	]
	for places: Array in spreads:
		var rig := _watching(places)
		for at: Vector3 in places:
			(
				assert_bool(rig.camera.is_position_in_frustum(at))
				. override_failure_message("a kart at %s is off the screen" % at)
				. is_true()
			)


## Spread to opposite corners they need the whole room again, and with nobody to follow the rig
## waits at the widest it goes.
func test_the_camera_pulls_back_out_for_a_spread_field_and_for_nobody() -> void:
	var huddled := _watching([Vector3(4.0, 0.0, 2.0), Vector3(6.0, 0.0, 3.0)])
	var spread := _watching([Vector3(-18.0, 0.0, -9.0), Vector3(18.0, 0.0, 9.0)])
	assert_float(spread._distance).is_greater(huddled._distance * 1.4)
	var empty := _watching([])
	assert_float(empty._distance).is_equal_approx(empty._arena_distance, 0.01)


## GAME.md 8.2: at the whistle the camera lets the room back in. It opens out to the whole arena
## and stops following, over the pause the podium waits out.
func test_the_camera_opens_out_to_the_room_at_the_whistle() -> void:
	var rig := _watching([Vector3(4.0, 0.0, 2.0), Vector3(6.0, 0.0, 3.0)])
	var close := rig._distance
	assert_float(close).is_less(rig._arena_distance * 0.8)
	rig.show_the_room(2.5)
	for i: int in 200:
		rig._process(0.05)
	assert_float(rig._distance).is_equal_approx(rig._arena_distance, 0.5)
	# And it is looking at the middle of the room rather than at whoever is standing about.
	assert_float(rig._pan.length()).is_less(0.5)
	# Every corner of the arena is back on screen, which is what opening out is for.
	rig.camera.fov = rig.base_fov * rig.zoom_min
	for x: float in [-20.0, 20.0]:
		for z: float in [-11.25, 11.25]:
			var corner := Vector3(x, 0.0, z)
			(
				assert_bool(rig.camera.is_position_in_frustum(corner))
				. override_failure_message("corner %s not visible" % corner)
				. is_true()
			)


## GAME.md 8.2: the camera is tilted, so what it is framing does not project symmetrically and a
## fit that only picks a distance sits it against the bottom of the frame with all the slack
## piled above. The aim slides to put the slack on both sides.
func test_what_is_framed_sits_in_the_middle_of_the_frame() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	rig.show_the_room(0.1)
	for i: int in 200:
		rig._process(0.05)
	rig._place(rig._distance, rig._pan, rig.zoom_min)
	var centered := _imbalance(rig)
	# Against the same distance with the aim left where it was, which is what it used to do.
	rig._lift = 0.0
	rig._place(rig._distance, rig._pan, rig.zoom_min)
	var lopsided := _imbalance(rig)
	assert_float(centered).is_less(0.05)
	assert_float(lopsided).is_greater(centered * 3.0)


## How lopsided the arena sits in the frame: 0 when the room's corners straddle the middle of the
## screen evenly, 1 when they are all on one side of it.
func _imbalance(rig: CameraRig) -> float:
	var middle := rig.get_viewport().get_visible_rect().size.y * 0.5
	var above := 0.0
	var below := 0.0
	for x: float in [-20.0, 20.0]:
		for z: float in [-11.25, 11.25]:
			for y: float in [0.0, 1.0]:
				var at := rig.camera.unproject_position(Vector3(x, y, z))
				above = maxf(above, middle - at.y)
				below = maxf(below, at.y - middle)
	return absf(above - below) / maxf(maxf(above, below), 0.001)


## GAME.md 8.2: the camera holds still for the pull-out. The tremble is only refreshed while a
## match is being played, so one that ends at the top level used to keep its last value and shake
## all the way through the whistle and on under the podium.
func test_the_whistle_stops_the_screen_shaking() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var was := Game.settings.screen_shake
	Game.settings.screen_shake = true
	rig.tremble = 1.0
	rig._process(0.05)
	assert_float(rig._shake).is_greater(0.0)
	rig.show_the_room(2.5)
	assert_float(rig._shake).is_equal(0.0)
	assert_float(rig.tremble).is_equal(0.0)
	# And nothing landing afterwards starts it up again: a bomb already in the air, a death
	# still resolving, a cash-out being counted.
	rig.shake(1.0)
	for i: int in 10:
		rig._process(0.05)
	assert_float(rig._shake).is_equal(0.0)
	Game.settings.screen_shake = was


## GAME.md 8.2: the camera looks ahead of the karts being driven on this machine, so the player at
## the wheel has more screen in front of them than behind. Only those karts lead it -- a rival's is
## something to watch rather than somewhere to look.
func test_the_camera_looks_ahead_of_the_kart_being_driven_here() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var kart: CharacterBody3D = auto_free(CharacterBody3D.new())
	add_child(kart)
	kart.global_position = Vector3(2.0, 0.0, 0.0)
	rig.targets.assign([kart] as Array[Node3D])
	# Nobody driving it from here, so the aim sits on it however fast it is going.
	kart.velocity = Vector3(10.5, 0.0, 0.0)
	assert_float(rig._target_pan().x).is_equal_approx(2.0, 0.01)
	# Driven from here and going right: the aim slides right of it, onto the road ahead.
	rig.listener_targets.assign([kart] as Array[Node3D])
	var led := rig._target_pan()
	assert_float(led.x).is_greater(3.0)
	assert_float(absf(led.z)).is_less(0.5)
	# The other way leads the other way, and standing still leads nowhere.
	kart.velocity = Vector3(-10.5, 0.0, 0.0)
	assert_float(rig._target_pan().x).is_less(0.0)
	kart.velocity = Vector3.ZERO
	assert_float(rig._target_pan().x).is_equal_approx(2.0, 0.01)


## And looking ahead never loses anybody. The fit still has to hold every kart on screen from
## wherever the lead has taken the aim, so it pays for the lead in distance.
func test_looking_ahead_still_keeps_every_kart_on_screen() -> void:
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var driven: CharacterBody3D = auto_free(CharacterBody3D.new())
	add_child(driven)
	driven.global_position = Vector3(14.0, 0.0, 6.0)
	driven.velocity = Vector3(10.5, 0.0, 0.0)
	var rival: Node3D = auto_free(Node3D.new())
	add_child(rival)
	rival.global_position = Vector3(-14.0, 0.0, -6.0)
	rig.targets.assign([driven, rival] as Array[Node3D])
	rig.listener_targets.assign([driven] as Array[Node3D])
	for i: int in 400:
		rig._process(0.05)
	await await_idle_frame()
	rig.camera.fov = rig.base_fov * rig.zoom_min
	for at: Vector3 in [driven.global_position, rival.global_position]:
		(
			assert_bool(rig.camera.is_position_in_frustum(at))
			. override_failure_message("a kart at %s is off the screen" % at)
			. is_true()
		)
	# The aim is ahead of the driven kart rather than on the middle of the two.
	assert_float(rig._pan.x).is_greater(3.0)


## GAME.md 8.5: with the fixed camera on, the rig holds the whole arena and goes nowhere the
## karts go. It is for a player who would rather have a picture that never moves than one that
## comes in on the action.
func test_the_fixed_camera_holds_the_arena_and_follows_nobody() -> void:
	Game.settings.fixed_camera = true
	var rig := _watching([Vector3(4.0, 0.0, 2.0), Vector3(6.0, 0.0, 3.0)])
	assert_float(rig._distance).is_equal_approx(rig._fixed_distance, 0.01)
	assert_float(rig._pan.length()).is_less(0.01)
	# A shade closer than the framing the rig waits at, which keeps a meter of floor round the
	# arena for karts to arrive into. A shot held all match knows where they are.
	assert_float(rig._distance).is_less(rig._arena_distance)
	assert_float(rig._distance).is_greater(rig._arena_distance * 0.9)
	# And every corner of the floor is on screen, which is the whole of what it promises.
	await await_idle_frame()
	rig.camera.fov = rig.base_fov * rig.zoom_min
	for x: float in [-20.0, 20.0]:
		for z: float in [-11.25, 11.25]:
			var corner := Vector3(x, 0.0, z)
			(
				assert_bool(rig.camera.is_position_in_frustum(corner))
				. override_failure_message("corner %s not visible" % corner)
				. is_true()
			)


## It still opens on the room and still comes in from there. That move is the map being shown
## rather than the karts being chased, and a fixed camera that refused to arrive would sit every
## match three meters further out than it belongs.
func test_the_fixed_camera_still_comes_in_at_the_start() -> void:
	Game.settings.fixed_camera = true
	var rig: CameraRig = auto_free(RIG_SCENE.instantiate())
	add_child(rig)
	rig.frame_arena(BOUNDS)
	var kart: Node3D = auto_free(Node3D.new())
	add_child(kart)
	kart.global_position = Vector3(6.0, 0.0, 2.0)
	rig.targets.assign([kart] as Array[Node3D])
	rig.open_on_the_room()
	var opening := rig._distance
	assert_float(opening).is_greater(rig._fixed_distance * 1.05)
	for i: int in 400:
		rig._process(0.05)
	assert_float(rig._distance).is_less(opening)
	assert_float(rig._distance).is_equal_approx(rig._fixed_distance, 0.01)
