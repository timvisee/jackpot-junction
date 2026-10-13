extends GdUnitTestSuite
## The tie-breaker, GAME.md 9.7a: karts level on points at the end of a Grand Prix play a showdown,
## and the order it settles is what the run's standings go by after points.

## Where a kart can stand around a spawn point, across its cell: a kart is about a cell wide, so a
## line of sight from anywhere on it counts.
const STANDS: Array[Vector2] = [
	Vector2(0.5, 0.5),
	Vector2(0.15, 0.15),
	Vector2(0.85, 0.15),
	Vector2(0.15, 0.85),
	Vector2(0.85, 0.85),
]

## How far along the walls two wall cells may be and still count as the same stretch of wall, see
## [method test_the_showdown_map_has_no_squeeze].
const SQUEEZE_WALK := 8

## The player's own settings, put aside so a lobby opened here starts from the defaults rather
## than from whatever the player last chose, and nothing chosen here is ever theirs.
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_tie_breaker.cfg"


func after_test() -> void:
	Settings.remove_files(Game.settings.path)
	Game.grand_prix = null
	Game.pending_config = null
	Game.settings = _settings_were
	GrandPrix.all_level = false


## A slot standing in for a player, for scoring by hand.
func _seat(index: int) -> PlayerSlot:
	return PlayerSlot.new(index, KartInput.new(), index)


## A run of two maps, both scored: seats 0 and 1 level on 17 at the top, 2 and 3 level on 7 under
## them, and 4 alone on 3. Seat 1 won a map and seat 0 never did, so the old order puts 1 first.
func _level_run() -> GrandPrix:
	var run := GrandPrix.new()
	run.playlist = [&"vault", &"crossfire"]
	run.points = {0: [7, 10], 1: [10, 7], 2: [5, 2], 3: [2, 5], 4: [3, 0]}
	run.places = {0: [2, 2], 1: [1, 2], 2: [3, 5], 3: [5, 3], 4: [4, 6]}
	run.banked = {0: [500, 500], 1: [400, 400], 2: [90, 90], 3: [100, 100], 4: [50, 0]}
	run.scored_round = 1
	run.round = 1
	return run


func _seats(count: int) -> Array[PlayerSlot]:
	var seats: Array[PlayerSlot] = []
	for i: int in count:
		seats.append(_seat(i))
	return seats


func _order(run: GrandPrix, seats: Array[PlayerSlot]) -> Array[int]:
	var order: Array[int] = []
	for slot: PlayerSlot in run.standings(seats):
		order.append(slot.index)
	return order


## Every group level on points, anywhere in the standings, the most points first.
func test_the_run_finds_every_tie() -> void:
	var run := _level_run()
	var ties := run.ties()
	assert_int(ties.size()).is_equal(2)
	assert_array(ties[0]).is_equal([0, 1])
	assert_array(ties[1]).is_equal([2, 3])
	assert_array(run.tied_seats()).is_equal([0, 1, 2, 3])


## A showdown once every map is scored and somebody is level, the switch on, and only once.
func test_a_showdown_is_needed_only_at_the_end_with_the_switch_on() -> void:
	var run := _level_run()
	assert_bool(run.needs_showdown()).is_true()
	run.scored_round = 0
	assert_bool(run.needs_showdown()).is_false()
	run.scored_round = 1
	run.tie_breaker = false
	assert_bool(run.needs_showdown()).is_false()
	run.tie_breaker = true
	var lasted: Dictionary[int, int] = {0: 40, 1: 90, 2: 10, 3: 20}
	run.settle(lasted)
	assert_bool(run.needs_showdown()).is_false()


## Nobody level, nothing to settle.
func test_no_tie_no_showdown() -> void:
	var run := _level_run()
	run.points[1] = [10, 8]
	run.points[3] = [2, 6]
	assert_bool(run.ties().is_empty()).is_true()
	assert_bool(run.needs_showdown()).is_false()


## Without a showdown the old order: maps won, then banked.
func test_without_a_showdown_maps_won_then_banked() -> void:
	var run := _level_run()
	# 1 won a map; 2 and 3 won none, and 3 banked more.
	assert_array(_order(run, _seats(5))).is_equal([1, 0, 3, 2, 4])


## The showdown's order goes first after points: the longer a kart lasted, the higher, against
## the old order.
func test_the_showdown_orders_each_tie() -> void:
	var run := _level_run()
	var lasted: Dictionary[int, int] = {0: 900, 1: 300, 2: GrandPrix.STOOD + 1, 3: 50}
	run.settle(lasted)
	assert_array(_order(run, _seats(5))).is_equal([0, 1, 2, 3, 4])
	var seats := _seats(5)
	assert_int(run.showdown_place(0, seats)).is_equal(1)
	assert_int(run.showdown_place(1, seats)).is_equal(2)
	assert_int(run.showdown_place(2, seats)).is_equal(1)
	assert_int(run.showdown_place(3, seats)).is_equal(2)
	# Seat 4 played no showdown.
	assert_int(run.showdown_place(4, seats)).is_equal(0)


## Karts that went out in the same moment are level on it, and the old order settles them.
func test_out_in_the_same_moment_falls_to_the_old_order() -> void:
	var run := _level_run()
	var lasted: Dictionary[int, int] = {0: 300, 1: 300, 2: 50, 3: 50}
	run.settle(lasted)
	assert_array(_order(run, _seats(5))).is_equal([1, 0, 3, 2, 4])


## Settled once: the host says the match is over more than once.
func test_the_showdown_settles_the_run_once() -> void:
	var run := _level_run()
	var first: Dictionary[int, int] = {0: 900, 1: 300}
	var again: Dictionary[int, int] = {0: 1, 1: 2}
	run.settle(first)
	run.settle(again)
	assert_int(run.showdown[0]).is_equal(900)


## The order applies to the whole run only: the standings after the first map of it, which the
## arrows of the final standings compare against, go by the old order.
func test_the_showdown_counts_for_the_whole_run_only() -> void:
	var run := _level_run()
	# Level after one map and after both; seat 1 won the first, seat 0 lasted longer.
	run.points[0] = [10, 7]
	run.points[1] = [10, 7]
	run.places[0] = [2, 2]
	run.places[1] = [1, 2]
	var lasted: Dictionary[int, int] = {0: 900, 1: 300, 2: 10, 3: 20}
	run.settle(lasted)
	assert_int(run.standings(_seats(5), 1)[0].index).is_equal(1)
	assert_int(run.standings(_seats(5))[0].index).is_equal(0)


## A client's podium knows a showdown is coming, who is in it and how it went.
func test_the_tie_rides_the_wire() -> void:
	var run := _level_run()
	run.tie_breaker = false
	run.fighters = [0, 1, 2, 3]
	var lasted: Dictionary[int, int] = {0: 900, 1: 300}
	run.settle(lasted)
	var theirs := GrandPrix.from_wire(run.to_wire())
	assert_bool(theirs.tie_breaker).is_false()
	assert_array(theirs.fighters).is_equal([0, 1, 2, 3])
	assert_int(theirs.showdown[0]).is_equal(900)
	assert_int(theirs.showdown[1]).is_equal(300)
	# Off the wire as the host's numbers came, whatever type they arrived as.
	var sent := run.to_wire()
	sent["showdown"] = {"0": 900.0, "1": 300.0}
	theirs = GrandPrix.from_wire(sent)
	assert_int(theirs.showdown[0]).is_equal(900)


## With the debug argument every seat is paid the same for every map, so a run ends level.
func test_all_level_pays_everybody_the_same() -> void:
	GrandPrix.all_level = true
	var run := GrandPrix.new()
	run.playlist = [&"vault", &"crossfire"]
	run.score(_seats(4))
	run.advance()
	run.score(_seats(4))
	assert_int(run.ties().size()).is_equal(1)
	assert_array(run.tied_seats()).is_equal([0, 1, 2, 3])
	assert_bool(run.needs_showdown()).is_true()


## The switch: on to start with, remembered, and into the run as it is dealt.
func test_the_switch_is_on_to_start_with_and_remembered() -> void:
	assert_bool(Game.settings.grand_prix_tie_breaker).is_true()
	assert_bool(MatchConfig.from_settings(Game.settings).tie_breaker).is_true()
	var pane: HostSettings = auto_free(HostSettings.add_to(self, true))
	pane.options.mode_picker.button(true).pressed.emit()
	assert_bool(pane.options.tie_toggle.button_pressed).is_true()
	assert_bool(pane.options._tie_row.visible).is_true()
	pane.options.tie_toggle.button_pressed = false
	var config := MatchConfig.new()
	pane.options.apply_to(config)
	assert_bool(config.tie_breaker).is_false()
	pane.options.remember(Game.settings)
	assert_bool(Game.settings.grand_prix_tie_breaker).is_false()
	Game.settings.save_to_disk()
	var read := Settings.new()
	read.path = Game.settings.path
	read.load_from_disk()
	assert_bool(read.grand_prix_tie_breaker).is_false()
	# A quick match has no run to tie.
	pane.options.mode_picker.button(false).pressed.emit()
	assert_bool(pane.options._tie_row.visible).is_false()
	var run := GrandPrix.start(2, RandomNumberGenerator.new(), GrandPrix.Keep.NONE, [], false)
	assert_bool(run.tie_breaker).is_false()


## A player hosting at a dedicated server sends the switch with the rest of the rows.
func test_the_switch_goes_to_a_dedicated_server() -> void:
	var config := MatchConfig.new()
	config.tie_breaker = false
	var at_server := MatchConfig.new()
	MatchOptions.from_wire(at_server, MatchOptions.to_wire(config))
	assert_bool(at_server.tie_breaker).is_false()


## Whether a straight line between two points of the grid, in cells, crosses no wall. Crates do not
## count: a bullet breaks them.
func _clear(grid: ArenaGrid, from: Vector2, to: Vector2) -> bool:
	var steps := ceili(from.distance_to(to) * 20.0)
	for i: int in steps + 1:
		var point := from.lerp(to, float(i) / float(steps))
		if grid.is_wall(Vector2i(floori(point.x), floori(point.y))):
			return false
	return true


func _sees(grid: ArenaGrid, a: Vector2i, b: Vector2i) -> bool:
	for here: Vector2 in STANDS:
		for there: Vector2 in STANDS:
			if _clear(grid, Vector2(a) + here, Vector2(b) + there):
				return true
	return false


## GAME.md 6.3: small, none of the usual furniture, walls, crates and four item pads, eight spawn
## points none of which has a line to any other, every lane two cells wide and every cell reachable.
func test_the_showdown_map_hides_every_spawn_from_every_other() -> void:
	var layout := ArenaMaps.layout(ArenaMaps.SHOWDOWN)
	assert_array(layout.validate()).is_empty()
	assert_str(layout.room.id).is_equal("after_hours")
	var grid := layout.parse()
	assert_vector(Vector2(grid.width, grid.height)).is_equal(Vector2(28, 16))
	assert_bool(grid.is_point_symmetric()).is_true()
	assert_int(grid.spawns.size()).is_equal(8)
	assert_int(grid.corner_spawns).is_equal(4)
	assert_int(grid.junctions.size()).is_equal(0)
	assert_int(grid.jackpots.size()).is_equal(0)
	assert_int(grid.pits.size()).is_equal(0)
	assert_int(grid.turbo_pads.size()).is_equal(0)
	assert_int(grid.coin_pads.size()).is_equal(0)
	assert_int(grid.flush_pads.size()).is_equal(0)
	assert_int(grid.power_pads.size()).is_equal(4)
	assert_int(grid.crates.size()).is_equal(12)
	for i: int in grid.spawns.size():
		for j: int in range(i + 1, grid.spawns.size()):
			(
				assert_bool(_sees(grid, grid.spawns[i], grid.spawns[j]))
				. override_failure_message("%s sees %s" % [grid.spawns[i], grid.spawns[j]])
				. is_false()
			)
	var home := grid.region_of(grid.spawns[0])
	for y: int in grid.height:
		for x: int in grid.width:
			var cell := Vector2i(x, y)
			if grid.is_wall(cell):
				continue
			assert_int(grid.region_of(cell)).is_equal(home)
			(
				assert_bool(_in_open_square(grid, cell))
				. override_failure_message("%s is in a lane a cell wide" % cell)
				. is_true()
			)


## Whether [param cell] is in a square of two by two with no wall in it.
func _in_open_square(grid: ArenaGrid, cell: Vector2i) -> bool:
	for corner: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i.ZERO]:
		var open := true
		for step: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]:
			open = open and not grid.is_wall(cell + corner + step)
		if open:
			return true
	return false


## Never less than two cells between two walls, GAME.md 6.3: no two wall cells within two of each
## other unless they are near along the wall as well, which a straight wall's are and a notch's, two
## arms of the room round a corner from each other, are not; and no crate within two of a wall.
func test_the_showdown_map_has_no_squeeze() -> void:
	var grid := ArenaMaps.layout(ArenaMaps.SHOWDOWN).parse()
	for y: int in grid.height:
		for x: int in grid.width:
			var cell := Vector2i(x, y)
			if _glyph(grid, cell) != ArenaGrid.WALL:
				continue
			var near := _along_the_wall(grid, cell, SQUEEZE_WALK)
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					var other := cell + Vector2i(dx, dy)
					if _glyph(grid, other) != ArenaGrid.WALL:
						continue
					(
						assert_bool(near.has(other))
						. override_failure_message("a squeeze between %s and %s" % [cell, other])
						. is_true()
					)
	for crate: Vector2i in grid.crates:
		for dy: int in range(-2, 3):
			for dx: int in range(-2, 3):
				(
					assert_str(_glyph(grid, crate + Vector2i(dx, dy)))
					. override_failure_message("a crate at %s squeezes a wall" % crate)
					. is_not_equal(ArenaGrid.WALL)
				)


## What is at [param cell], or nothing off the grid.
func _glyph(grid: ArenaGrid, cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= grid.width or cell.y >= grid.height:
		return ""
	return grid.glyph(cell)


## The wall cells [param steps] or fewer from [param from] along the walls, corners and all.
func _along_the_wall(grid: ArenaGrid, from: Vector2i, steps: int) -> Dictionary[Vector2i, int]:
	var reached: Dictionary[Vector2i, int] = {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if reached[cell] >= steps:
			continue
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var next := cell + Vector2i(dx, dy)
				if _glyph(grid, next) == ArenaGrid.WALL and not reached.has(next):
					reached[next] = reached[cell] + 1
					queue.append(next)
	return reached


## No Grand Prix deals it; a quick match's list offers it last, in a debug build alone, which is
## what a test runs in.
func test_the_showdown_map_is_never_dealt_and_offered_only_for_debugging() -> void:
	for normal: bool in [true, false]:
		for xl: bool in [true, false]:
			assert_bool(ArenaMaps.SHOWDOWN in ArenaMaps.pool(normal, xl)).is_false()
	var rng := RandomNumberGenerator.new()
	for seed: int in 40:
		rng.seed = seed
		assert_bool(ArenaMaps.SHOWDOWN in GrandPrix.deal(6, rng)).is_false()
	assert_str(String(ArenaMaps.IDS[-1])).is_equal(String(ArenaMaps.SHOWDOWN))
	assert_str(ArenaMaps.NAMES[-1]).is_equal("Showdown")
	assert_bool(OS.is_debug_build()).is_true()
	var offered := ArenaMaps.offered(Game.settings.profile)
	assert_str(String(offered[-1])).is_equal(String(ArenaMaps.SHOWDOWN))
	var pane: HostSettings = auto_free(HostSettings.add_to(self, true))
	pane.options.mode_picker.button(false).pressed.emit()
	assert_int(pane.options.map_option.item_count).is_equal(offered.size())
	pane.options.map_option.select(offered.size() - 1)
	var config := MatchConfig.new()
	pane.options.apply_to(config)
	assert_str(String(config.map)).is_equal(String(ArenaMaps.SHOWDOWN))
