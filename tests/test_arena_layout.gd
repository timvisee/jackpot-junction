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
	assert_int(_grid.spawns.size()).is_equal(8)
	assert_int(_grid.corner_spawns).is_equal(4)
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
		[Rect2i(15, 4, 2, 2), Rect2i(15, 12, 2, 2)]
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


func test_cell_and_rect_centers_are_around_the_origin() -> void:
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


## A hole two cells long or less keeps its trigger to the middle of it, a wheel over the rim no fall
## yet; a longer one keeps that rim and no more, so the driving test's trench, sixteen cells long,
## is a pit right to its ends rather than along its middle only.
func test_a_long_hole_is_a_pit_to_its_ends() -> void:
	var cell := 1.25
	var square := Vector2(2.5, 2.5)
	assert_vector(Pit.trigger_size(square, cell)).is_equal_approx(
		square * Pit.TRIGGER_SHARE, Vector2.ONE * 0.001
	)
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/tutorial.tres")
	arena.bake_scenery = false
	add_child(arena)
	var trench := arena.grid.rect_size(TestGround.TRENCH)
	assert_float(trench.y).is_equal_approx(20.0, 0.001)
	var rim := square.y * (1.0 - Pit.TRIGGER_SHARE)
	for pit: Pit in arena.pits:
		if pit.position.distance_to(arena.grid.rect_center(TestGround.TRENCH)) > 0.01:
			continue
		var box := (pit.get_child(0) as CollisionShape3D).shape as BoxShape3D
		assert_float(box.size.z).is_equal_approx(trench.y - rim, 0.001)
		assert_float(box.size.x).is_equal_approx(trench.x * Pit.TRIGGER_SHARE, 0.001)
		return
	fail("no pit under the trench")


func test_arena_scene_builds_from_the_layout() -> void:
	var scene: PackedScene = load("res://scenes/arena/arena.tscn")
	var arena: Arena = auto_free(scene.instantiate())
	add_child(arena)
	assert_int(arena.spawn_points.size()).is_equal(8)
	# A match of four uses the corners alone, as it always has; the fifth kart opens up the rest.
	assert_array(arena.spawns_for(4)).is_equal(arena.spawn_points.slice(0, 4))
	assert_array(arena.spawns_for(5)).is_equal(arena.spawn_points)
	assert_int(arena.turbo_pads.size()).is_equal(4)
	assert_int(arena.flush_pads.size()).is_equal(4)
	assert_int(arena.pits.size()).is_equal(2)
	# One body per wall in the layout. The meshes are baked into a handful of merged ones, see
	# GAME.md 8.1, so the bodies are what there is to count.
	var bodies := 0
	for wall: Node in arena.get_node("Walls").get_children():
		bodies += 1 if wall is StaticBody3D else 0
	assert_int(bodies).is_equal(arena.grid.walls.size())
	assert_float(arena.junction_radius).is_equal_approx(2.5, 0.001)
	assert_vector(arena.bounds().size).is_equal_approx(
		Vector3(40.0, 1.0, 22.5), Vector3.ONE * 0.001
	)
