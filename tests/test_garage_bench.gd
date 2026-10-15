extends GdUnitTestSuite
## The Garage's tests of a kart, GAME.md 9.4: the rolling road that holds a kart and reads its top
## speed, the speed trap across the straight, and the test bench both are read off. See [Dyno],
## [SpeedTrap] and [TestBench].

const GARAGE_SCENE := preload("res://scenes/garage/garage.tscn")
const GARAGE_SCRIPT := preload("res://scenes/garage/garage.gd")
const LAYOUT: ArenaLayout = preload("res://data/maps/garage.tres")


## A foot on the pedal: full throttle, or backing off on the brake for less than none.
class Pedal:
	extends KartInput
	var held := 1.0

	func poll(_delta: float) -> void:
		throttle = maxf(held, 0.0)
		brake = maxf(-held, 0.0)
		steer = 0.0


var _runner: GdUnitSceneRunner


func _garage() -> Node3D:
	var garage: Node3D = auto_free(GARAGE_SCENE.instantiate())
	_runner = scene_runner(garage)
	await _runner.simulate_frames(60, 17)
	return garage


## [param kart] put down at [param at] facing [param facing] with a foot on the pedal.
static func _drive(kart: Kart, at: Vector3, facing: Vector3) -> Pedal:
	kart.global_position = at
	kart.face(facing)
	kart.motor.velocity = Vector3.ZERO
	kart.motor.forward_speed = 0.0
	var pedal := Pedal.new()
	kart.input = pedal
	return pedal


## Driven onto the rollers nose to the wall, the kart is held there while its motor runs up to its
## top speed, which is the dyno's and stays as the best; backing off lets it go.
func test_the_rolling_road_holds_a_kart_and_reads_its_top_speed() -> void:
	var garage := await _garage()
	var match_node: Match = garage.get_node("Match")
	var dyno: Dyno = garage.get("dyno")
	var kart := match_node.kart_of(0)
	var way_in := Vector3(dyno.area.position.x - 1.5, 0.0, dyno.area.get_center().y)
	var pedal := _drive(kart, way_in, Dyno.FACING)
	await _runner.simulate_frames(150, 17)
	assert_object(dyno.held).is_same(kart)
	assert_bool(dyno.holds(kart)).is_true()
	var held_at := kart.global_position
	await _runner.simulate_frames(30, 17)
	# Going flat out without going anywhere.
	assert_vector(kart.global_position).is_equal_approx(held_at, Vector3.ONE * 0.01)
	assert_float(dyno.speed).is_equal_approx(kart.stats.top_speed, 0.3)
	assert_float(dyno.best).is_greater_equal(dyno.speed)
	assert_object(dyno.best_slot).is_same(match_node.slots[0])
	# Strapped down once it has rolled into place.
	assert_float(dyno.strapped).is_equal(1.0)
	# A close look at the board is up while the kart is on the rollers, at the left of the screen,
	# away from the rolling road, and the camera keeps the karts out from under it.
	var bench: TestBench = garage.get("bench")
	assert_object(bench.view).is_not_null()
	assert_str(bench.view.heading.text).is_equal(TestBench.DYNO_TITLE)
	# Shown as a feed off a camera, see [VideoFeed]: its picture drawn through the feed's look.
	var feed := bench.view.feed
	assert_object((feed.get_parent() as TextureRect).material.shader).is_same(VideoFeed.SHADER)
	assert_float(feed.running).is_greater(0.0)
	var covers: Array[Rect2] = (match_node.hud.get_node("Covers") as HudCovers).covers()
	var pane := bench.view.pane.get_global_rect()
	var screen := match_node.hud.get_viewport().get_visible_rect().size
	var share := Rect2(pane.position / screen, pane.size / screen)
	assert_float(share.get_center().x).is_less(0.5)
	assert_bool(covers.any(func(r: Rect2) -> bool: return r.is_equal_approx(share))).is_true()
	pedal.held = -1.0
	await _runner.simulate_frames(120, 17)
	assert_object(dyno.held).is_null()
	assert_float(kart.global_position.x).is_less(held_at.x - 0.5)
	assert_float(dyno.best).is_equal_approx(kart.stats.top_speed, 0.3)
	assert_float(dyno.strapped).is_equal(0.0)
	# Up a little while after with the best, then down.
	assert_object(bench.view).is_not_null()
	await _runner.simulate_frames(roundi(TestBench.LOOK_HOLD * 60.0) + 30, 17)
	assert_object(bench.view).is_null()


## A low fence down either side of the bay: a kart driven at it from the side is stopped by it
## rather than taken onto the rollers, so the way on is from the room, nose to the wall.
func test_the_fence_keeps_karts_to_the_open_end() -> void:
	var garage := await _garage()
	var match_node: Match = garage.get_node("Match")
	var dyno: Dyno = garage.get("dyno")
	var kart := match_node.kart_of(0)
	_drive(kart, Vector3(dyno.area.get_center().x, 0.0, dyno.area.end.y + 1.5), Vector3.FORWARD)
	await _runner.simulate_frames(90, 17)
	assert_object(dyno.held).is_null()
	assert_float(kart.global_position.z).is_greater(dyno.area.end.y)


## A kart driven through the trap has its speed taken there, the last and the best, and the test
## bench reads them, and the rolling road's best on its dial.
func test_the_speed_trap_times_a_kart_and_the_bench_reads_it() -> void:
	var garage := await _garage()
	var match_node: Match = garage.get_node("Match")
	var trap: SpeedTrap = garage.get("trap")
	var bench: TestBench = garage.get("bench")
	var kart := match_node.kart_of(0)
	var cell := GARAGE_SCRIPT.TRAP as Vector2i
	var line := match_node.arena.grid.cell_center(cell)
	_drive(kart, line - Vector3(9.0, 0.0, 0.0), Vector3.RIGHT)
	assert_float(trap.last).is_equal(0.0)
	await _runner.simulate_frames(150, 17)
	assert_float(trap.last).is_greater(SpeedTrap.SLOWEST)
	assert_float(trap.best).is_equal(trap.last)
	assert_object(trap.best_slot).is_same(match_node.slots[0])
	var unit := Game.settings.speed_unit()
	var shown := "%3d" % roundi(SpeedUnits.from_kmh(trap.last * MatchHud.SPEED_SCALE, unit))
	assert_str(bench._shown).contains(shown)
	# And a close look at the board comes up, titled for the trap.
	assert_object(bench.view).is_not_null()
	assert_str(bench.view.heading.text).is_equal(TestBench.SPEED_TRAP)


## The board stands on the floor out past the right wall beside the rolling road, a little back
## from it so the kart on the rollers is never behind it, on floor the clutter keeps clear of.
func test_the_bench_stands_beside_the_rolling_road() -> void:
	var garage := await _garage()
	var match_node: Match = garage.get_node("Match")
	var dyno: Dyno = garage.get("dyno")
	var bench: TestBench = garage.get("bench")
	var half := match_node.arena.world_size() * 0.5
	assert_float(bench.global_position.x).is_greater(half.x)
	assert_float(bench.global_position.y).is_equal(0.0)
	var bay := dyno.area.get_center()
	assert_float(bench.global_position.z).is_less(bay.y)
	assert_float(bay.y - bench.global_position.z).is_less(3.0)


## The rolling road's bay and the speed trap's posts stand on open floor off the rings.
func test_the_dyno_and_the_trap_stand_clear_of_the_rings() -> void:
	var grid := LAYOUT.parse()
	var middle := grid.rect_center(grid.junction)
	var ring := grid.cell_center(grid.flush_pads[0]).distance_to(middle)
	var clear := ring + grid.cell_size * 0.5
	var corner := GARAGE_SCRIPT.DYNO as Vector2i
	for y: int in Dyno.CELLS.y:
		for x: int in Dyno.CELLS.x:
			var cell := corner + Vector2i(x, y)
			assert_str(grid.glyph(cell)).is_equal(ArenaGrid.FLOOR)
			assert_float(grid.cell_center(cell).distance_to(middle)).is_greater(clear)
	var trap := grid.cell_center(GARAGE_SCRIPT.TRAP as Vector2i)
	for side: float in [-1.0, 1.0]:
		var post := trap + Vector3(0.0, 0.0, side * grid.cell_size * SpeedTrap.REACH)
		assert_float(post.distance_to(middle)).is_greater(clear)
