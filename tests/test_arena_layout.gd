extends GdUnitTestSuite
## The Lucky Crossing layout parses into the elements GAME.md 6.3 describes, and the parser
## rejects broken grids.

const LAYOUT_PATH := "res://data/maps/lucky_crossing.tres"

var _grid: ArenaGrid


func before() -> void:
	var layout: ArenaLayout = load(LAYOUT_PATH)
	_grid = layout.parse()


func test_dimensions_and_world_size() -> void:
	assert_int(_grid.width).is_equal(32)
	assert_int(_grid.height).is_equal(18)
	assert_vector(_grid.world_size()).is_equal(Vector2(40.0, 22.5))


func test_element_counts_match_the_design() -> void:
	assert_int(_grid.spawns.size()).is_equal(4)
	assert_int(_grid.coin_pads.size()).is_equal(12)
	assert_int(_grid.power_pads.size()).is_equal(4)
	assert_int(_grid.flush_pads.size()).is_equal(4)
	assert_int(_grid.turbo_pads.size()).is_equal(4)
	assert_int(_grid.crates.size()).is_equal(8)
	assert_int(_grid.pits.size()).is_equal(2)
	assert_int(_grid.jackpots.size()).is_equal(2)


func test_areas_are_rectangles_at_the_designed_spots() -> void:
	assert_that(_grid.junction).is_equal(Rect2i(14, 7, 4, 4))
	assert_array(_grid.pits).contains_exactly_in_any_order(
		[Rect2i(15, 5, 2, 2), Rect2i(15, 11, 2, 2)]
	)
	assert_array(_grid.jackpots).contains_exactly_in_any_order(
		[Rect2i(4, 8, 2, 2), Rect2i(26, 8, 2, 2)]
	)


func test_layout_is_point_symmetric() -> void:
	assert_bool(_grid.is_point_symmetric()).is_true()


func test_wall_rectangles_cover_every_wall_cell_exactly_once() -> void:
	var covered: Dictionary[Vector2i, int] = {}
	var area := 0
	for rect: Rect2i in _grid.walls:
		area += rect.get_area()
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				(
					assert_bool(_grid.is_wall(cell))
					. override_failure_message("%s is not a wall" % cell)
					. is_true()
				)
				covered[cell] = covered.get(cell, 0) + 1
	assert_int(area).is_equal(_grid.wall_cell_count())
	assert_int(covered.size()).is_equal(_grid.wall_cell_count())
	for cell: Vector2i in covered:
		assert_int(covered[cell]).is_equal(1)


func test_walls_are_merged_into_few_rectangles() -> void:
	# 4 border pieces, 4 short horizontal segments, 2 vertical segments.
	assert_int(_grid.walls.size()).is_less_equal(10)


func test_cell_and_rect_centres_are_around_the_origin() -> void:
	assert_vector(_grid.cell_center(Vector2i(16, 9))).is_equal_approx(
		Vector3(0.625, 0.0, 0.625), Vector3.ONE * 0.001
	)
	assert_vector(_grid.rect_center(_grid.junction)).is_equal_approx(
		Vector3.ZERO, Vector3.ONE * 0.001
	)
	assert_vector(_grid.cell_center(Vector2i(0, 0))).is_equal_approx(
		Vector3(-19.375, 0.0, -10.625), Vector3.ONE * 0.001
	)


func test_turbo_pads_point_along_their_lanes_toward_the_far_half() -> void:
	assert_vector(_grid.turbo_direction(Vector2i(10, 4))).is_equal(Vector3(0.0, 0.0, 1.0))
	assert_vector(_grid.turbo_direction(Vector2i(21, 13))).is_equal(Vector3(0.0, 0.0, -1.0))


func test_arrow_glyphs_give_explicit_directions() -> void:
	var layout := ArenaLayout.new()
	layout.grid = "#####\n#^<.#\n#>v.#\n#####"
	var grid := layout.parse()
	assert_vector(grid.turbo_direction(Vector2i(1, 1))).is_equal(Vector3(0.0, 0.0, -1.0))
	assert_vector(grid.turbo_direction(Vector2i(2, 1))).is_equal(Vector3(-1.0, 0.0, 0.0))
	assert_vector(grid.turbo_direction(Vector2i(1, 2))).is_equal(Vector3(1.0, 0.0, 0.0))
	assert_vector(grid.turbo_direction(Vector2i(2, 2))).is_equal(Vector3(0.0, 0.0, 1.0))
	assert_int(grid.turbo_pads.size()).is_equal(4)


func test_validate_reports_ragged_rows_open_borders_and_unknown_glyphs() -> void:
	var layout := ArenaLayout.new()
	layout.grid = "#####\n#..Z#\n#...\n####"
	var problems := layout.validate()
	assert_int(problems.size()).is_greater_equal(2)
	assert_str(",".join(problems)).contains("unknown glyph 'Z'")
	assert_str(",".join(problems)).contains("length")


func test_arena_scene_builds_from_the_layout() -> void:
	var scene: PackedScene = load("res://scenes/arena/arena.tscn")
	var arena: Arena = auto_free(scene.instantiate())
	add_child(arena)
	assert_int(arena.spawn_points.size()).is_equal(4)
	assert_int(arena.turbo_pads.size()).is_equal(4)
	assert_int(arena.flush_pads.size()).is_equal(4)
	assert_int(arena.pits.size()).is_equal(2)
	assert_int(arena.get_node("Walls").get_child_count()).is_equal(arena.grid.walls.size())
	assert_float(arena.junction_radius).is_equal_approx(2.5, 0.001)
	assert_vector(arena.bounds().size).is_equal_approx(
		Vector3(40.0, 1.0, 22.5), Vector3.ONE * 0.001
	)


## GAME.md 8.1: the room is lit round its edge and painted inside it. The blocks standing in the
## middle of it are wooden toys and stay that way.
func test_the_room_is_lit_round_its_edge_and_painted_inside_it() -> void:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load(LAYOUT_PATH)
	add_child(arena)
	var walls: Node3D = arena.get_node("Walls")
	var lit := 0
	var plain := 0
	for wall: Node3D in walls.get_children():
		# A wall wearing neon has a second mesh on top of the block itself.
		if wall.get_child_count() > 2:
			lit += 1
		else:
			plain += 1
	assert_int(lit).is_greater_equal(4)
	assert_int(plain).is_greater(0)
	# The painted line runs inside the wall face rather than under the wall.
	var markings: Node3D = arena.get_node("Markings")
	assert_int(markings.get_child_count()).is_equal(4)
	var half := arena.world_size() * 0.5
	for strip: Node3D in markings.get_children():
		assert_float(absf(strip.position.x)).is_less(half.x - arena.layout.cell_size)
		assert_float(absf(strip.position.z)).is_less(half.y - arena.layout.cell_size)
