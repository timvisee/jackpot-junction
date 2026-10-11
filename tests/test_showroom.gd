extends GdUnitTestSuite
## The Showroom off the Garage, GAME.md 8.9: open once the Department's keystone is won, the Garage
## laid out with its bay; shut, the roller door down; and its turntable, which turns a kart of this
## machine's left standing on it and puts up a close look at it. See [Showroom].

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const GARAGE: ArenaLayout = preload("res://data/maps/garage.tres")
const RULES: MatchRules = preload("res://data/match/garage.tres")
const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const PATH := "user://test_showroom.cfg"

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()


func after_test() -> void:
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _garage(layout: ArenaLayout) -> Match:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0)]
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = layout
	match_node.joker_catalog = JOKERS
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, inputs.size())
	return match_node


## Open once the landmark that opens it is won, and not before.
func test_open_once_its_keystone_is_won() -> void:
	var profile := Game.settings.profile
	assert_bool(Loyalty.showroom_open(profile)).is_false()
	profile.loyalty.win(&"showroom")
	assert_bool(Loyalty.showroom_open(profile)).is_true()


## The Garage with the bay behind it is the Garage as it was, its back wall a partition with the way
## in through it and the bay's rows over it.
func test_the_bay_behind_the_back_wall() -> void:
	var garage := GARAGE.lines()
	var open := Showroom.LAYOUT.lines()
	assert_int(open.size()).is_equal(garage.size() + Showroom.BAY)
	for row: int in range(1, garage.size()):
		assert_str(open[row + Showroom.BAY]).is_equal(garage[row])
	var partition := open[Showroom.BAY]
	for column: int in partition.length():
		var inside := column >= Showroom.OPENING.x and column < Showroom.OPENING.y
		assert_str(partition[column]).is_equal("." if inside else "#")
	assert_array(Showroom.LAYOUT.validate()).is_empty()


## Shut, the roller door is down across the Garage's back wall and there is no turntable.
func test_shut_the_door_is_down() -> void:
	var match_node := _garage(GARAGE)
	await _runner.simulate_frames(2, 17)
	var showroom := Showroom.add_to(match_node, false)
	await _runner.simulate_frames(1, 17)
	assert_object(showroom.turntable).is_null()
	assert_int(showroom.get_child_count()).is_greater(4)


## Open, a kart of this machine's left standing on the turntable is turned round and looked at up
## close; driven off it, the look is put away.
func test_the_turntable_turns_and_shows_the_kart() -> void:
	var match_node := _garage(Showroom.LAYOUT)
	await _runner.simulate_frames(2, 17)
	var showroom := Showroom.add_to(match_node, true)
	await _runner.simulate_frames(1, 17)
	assert_object(showroom.turntable).is_not_null()
	var kart := match_node.slots[0].kart
	kart.global_position = showroom.turntable.global_position
	kart.velocity = Vector3.ZERO
	var facing := kart.rotation.y
	var heading := kart.motor.heading
	await _runner.simulate_frames(20, 17)
	assert_object(showroom.on_it).is_same(kart)
	assert_object(showroom.view).is_not_null()
	# Turning, however slowly the frames come under a busy machine.
	assert_float(absf(angle_difference(facing, kart.rotation.y))).is_greater(0.001)
	# The kart itself, its heading, not a picture of it the next step puts back.
	assert_float(absf(angle_difference(heading, kart.motor.heading))).is_greater(0.001)
	kart.global_position = showroom.turntable.global_position + Vector3(8.0, 0.0, 8.0)
	await _runner.simulate_frames(3, 17)
	assert_object(showroom.on_it).is_null()


## A kart standing off the middle of the turntable is carried round with it, not turned where it
## stands: it keeps its distance from the middle, goes round it as far as it turns, and keeps its
## place on the disc.
func test_a_kart_off_the_middle_is_carried_round() -> void:
	var match_node := _garage(Showroom.LAYOUT)
	await _runner.simulate_frames(2, 17)
	var showroom := Showroom.add_to(match_node, true)
	await _runner.simulate_frames(1, 17)
	var kart := match_node.slots[0].kart
	var middle := showroom.turntable.global_position
	var off := Vector3(Showroom.TURNTABLE * 0.6, 0.0, 0.0)
	kart.global_position = middle + off
	kart.velocity = Vector3.ZERO
	var heading := kart.motor.heading
	for step: int in 30:
		showroom.carry(kart, 0.02)
	var apart := kart.global_position - middle
	apart.y = 0.0
	assert_float(apart.length()).is_equal_approx(off.length(), 0.001)
	assert_float(off.signed_angle_to(apart, Vector3.UP)).is_equal_approx(0.6, 0.001)
	assert_float(angle_difference(heading, kart.motor.heading)).is_equal_approx(0.6, 0.001)
	assert_float(kart.rotation.y).is_equal_approx(kart.motor.heading, 0.0001)
	# Left on it, the room's own steps carry it: off the middle still, but somewhere else.
	await _runner.simulate_frames(20, 17)
	assert_object(showroom.on_it).is_same(kart)
	var later := kart.global_position - middle
	later.y = 0.0
	assert_float(later.length()).is_equal_approx(off.length(), 0.05)
	assert_float(absf(apart.signed_angle_to(later, Vector3.UP))).is_greater(0.01)


## What the close look says a kart wears: its parts that are not the plain one, by name, and a
## plain one as a dealer says it.
func test_what_the_kart_wears() -> void:
	var style := KartStyle.from_array([4, 7, 0, 1, 1, 0])
	assert_str(ShowroomView.worn_words(style)).is_equal("Card suits  ·  Fedora  ·  Sparks  ·  Gold")
	assert_str(ShowroomView.worn_words(KartStyle.new())).is_equal(ShowroomView.STANDARD)


## The close look films the bay itself, the room's own world, with a camera of its own that leaves
## out the hints hung over karts; it cuts to another shot, never the same one twice running, each
## looking at the kart wherever it is on the table, never from behind the table, where the bay's
## back wall is.
func test_the_close_look_films_the_bay_in_shots() -> void:
	var match_node := _garage(Showroom.LAYOUT)
	await _runner.simulate_frames(2, 17)
	var showroom := Showroom.add_to(match_node, true)
	await _runner.simulate_frames(1, 17)
	var kart := match_node.slots[0].kart
	kart.global_position = showroom.turntable.global_position
	kart.velocity = Vector3.ZERO
	await _runner.simulate_frames(5, 17)
	var view := showroom.view
	assert_object(view).is_not_null()
	var sheet := view.find_child("Sheet", true, false) as SubViewport
	assert_bool(sheet.own_world_3d).is_false()
	assert_object(sheet.find_world_3d()).is_same(match_node.get_viewport().find_world_3d())
	var camera := sheet.find_child("Camera", true, false) as Camera3D
	assert_int(camera.cull_mask & InputHint.WORLD_LAYER).is_equal(0)
	assert_int(view.shot).is_equal(0)
	var dice := RandomNumberGenerator.new()
	dice.seed = 7
	for i: int in 40:
		var now := i % ShowroomView.SHOTS.size()
		var after := ShowroomView.next_shot(now, dice)
		assert_int(after).is_not_equal(now)
		assert_bool(after >= 0 and after < ShowroomView.SHOTS.size()).is_true()
	var middle := Vector3(2.0, 0.0, -3.0)
	var kart_at := middle + Vector3(0.5, 0.0, -0.4)
	for index: int in ShowroomView.SHOTS.size():
		for through: float in [0.0, 0.5, 1.0]:
			var pose := ShowroomView.camera_at(index, through, middle, kart_at)
			var from: Vector3 = pose[0]
			var at: Vector3 = pose[1]
			assert_float(from.z).is_greater(middle.z)
			assert_float(at.x).is_equal_approx(kart_at.x, 0.0001)
			assert_float(at.z).is_equal_approx(kart_at.z, 0.0001)
			assert_float(pose[2]).is_between(15.0, 45.0)
	# The lens closes in over a zoom, and the camera goes round over an orbit, at the same height.
	var zoom := ShowroomView.SHOTS.find_custom(func(s: Dictionary) -> bool: return s.has("zoom"))
	assert_float(ShowroomView.camera_at(zoom, 1.0, middle, kart_at)[2]).is_less(
		ShowroomView.camera_at(zoom, 0.0, middle, kart_at)[2]
	)
	var orbit := ShowroomView.SHOTS.find_custom(func(s: Dictionary) -> bool: return s.has("orbit"))
	var went: Vector3 = ShowroomView.camera_at(orbit, 0.0, middle, kart_at)[0]
	var came: Vector3 = ShowroomView.camera_at(orbit, 1.0, middle, kart_at)[0]
	assert_float(went.y).is_equal_approx(came.y, 0.0001)
	assert_float((went - middle).length()).is_equal_approx((came - middle).length(), 0.0001)
	assert_float(went.distance_to(came)).is_greater(1.0)
