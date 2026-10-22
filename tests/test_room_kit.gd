extends GdUnitTestSuite
## What the things inside the arena are made of, GAME.md 8.1. A room decides what its cover is
## built out of and what is left on top of its walls, and neither is allowed to change what the
## karts drive into: a box is the cube its collider is, and a wall is the block it always was
## with something small on top of it.

## Every room with a table of its own: the three maps, and the three XL maps in rooms of their
## own, GAME.md 8.1c.
const MAPS: Array[String] = [
	"lucky_crossing", "vault", "crossfire", "loose_threads", "pin_alley", "toy_box"
]
## And the rooms the Garage's maps, the driving school's lot and the showdown stand in, which
## drop litter of their own too, GAME.md 8.1c.
const LITTERED: Array[String] = MAPS + ["garage", "waiting_room", "tutorial", "showdown"]
## How far outside the shape it is allowed to be. Nothing should be; this is float slack.
const SLACK := 0.002
## How many vertices a table's litter may come to, all of it: a few hundred is what it is.
const LITTER_VERTICES := 1200


## Unbaked: after the merge of 8.1 there is no wall left to look at, only the result.
## Every mesh under [param node], however deep it is hung.
func _meshes(node: Node, into: Array[MeshInstance3D] = []) -> Array[MeshInstance3D]:
	for child: Node in node.get_children():
		_meshes(child, into)
		var part := child as MeshInstance3D
		if part != null and part.mesh != null:
			into.append(part)
	return into


func _arena(map: String) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
	arena.bake_scenery = false
	add_child(arena)
	return arena


## Every room builds its cover out of something rather than out of one painted cube: card packs
## in the card room, offcuts on the bench, sacks in the yard.
func test_every_room_builds_its_own_boxes() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		assert_int(arena.crates.size()).is_greater(0)
		for crate: Crate in arena.crates:
			var box := crate.get_node_or_null("Box")
			assert_object(box).override_failure_message("%s: undressed box" % map).is_not_null()
			assert_int(box.get_child_count()).is_greater(2)


## And builds it inside the cube the collider is. A sack hanging over the edge of its own footing
## is a box that is bumped into before it is reached.
func test_the_cover_is_the_shape_it_looks_like() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		for crate: Crate in arena.crates:
			var shape: CollisionShape3D = crate.get_child(0)
			var cube: BoxShape3D = shape.shape
			var room := AABB(
				-cube.size * 0.5 - Vector3.ONE * SLACK, cube.size + Vector3.ONE * SLACK * 2.0
			)
			for part: MeshInstance3D in crate.get_node("Box").get_children():
				var box := part.transform * part.mesh.get_aabb()
				var out := "%s: a piece of a box sticks out of it at %v" % [map, part.position]
				assert_bool(room.encloses(box)).override_failure_message(out).is_true()


## A wall is the block it always was. What the room adds to it -- the step on top, the odd thing
## left up there -- stays inside the footprint the collider has, so a kart never meets anything
## that was not part of the wall.
func test_a_wall_is_still_the_block_it_was() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		for body: Node in arena.get_node("Walls").get_children():
			var shape: CollisionShape3D = body.get_child(0)
			var cube: BoxShape3D = shape.shape
			var half := cube.size * 0.5
			for part: MeshInstance3D in body.get_node("Wall").get_children():
				var box := part.transform * part.mesh.get_aabb()
				var over := "%s: something on a wall hangs over the side of it" % map
				assert_float(box.position.x).override_failure_message(over).is_greater_equal(
					-half.x - SLACK
				)
				assert_float(box.end.x).override_failure_message(over).is_less_equal(half.x + SLACK)
				assert_float(box.position.z).override_failure_message(over).is_greater_equal(
					-half.z - SLACK
				)
				assert_float(box.end.z).override_failure_message(over).is_less_equal(half.z + SLACK)
				var under := "%s: a wall has something hanging below it" % map
				assert_float(box.position.y).override_failure_message(under).is_greater_equal(
					-half.y - SLACK
				)


## And the block and the step on it share no plane. Two surfaces at the same depth flicker
## against each other as the camera moves, which is what a strip laid into the top face of a wall
## does and why there is not one any more.
func test_the_block_and_its_step_share_no_plane() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		for body: Node in arena.get_node("Walls").get_children():
			var parts := body.get_node("Wall").get_children()
			var block: MeshInstance3D = parts[0]
			var step: MeshInstance3D = parts[1]
			var one := block.transform * block.mesh.get_aabb()
			var two := step.transform * step.mesh.get_aabb()
			var flat := "%s: the step on a wall lies in a face of the wall" % map
			for axis: int in 3:
				var low := absf(one.position[axis] - two.position[axis])
				var high := absf(one.end[axis] - two.end[axis])
				assert_float(low).override_failure_message(flat).is_greater(SLACK)
				assert_float(high).override_failure_message(flat).is_greater(SLACK)


## What is dropped on the floor of the arena stays flat and stays on the floor, GAME.md 8.1: a
## card lying on the baize is scenery, and anything standing up out there is an obstacle nobody
## put in the layout.
func test_the_litter_lies_flat_on_empty_floor() -> void:
	for map: String in LITTERED:
		var arena := _arena(map)
		var litter := arena.get_node("Litter")
		assert_int(litter.get_child_count()).is_greater(0)
		var grid := arena.grid
		for part: MeshInstance3D in litter.get_children():
			var box := part.transform * part.mesh.get_aabb()
			var tall := "%s: something on the floor stands %.2fm tall" % [map, box.size.y]
			assert_float(box.end.y).override_failure_message(tall).is_less_equal(RoomKit.LITTER)
			assert_float(box.position.y).is_greater_equal(-0.01)
			# On floor the karts drive on rather than on a pad, in a pit or under a wall.
			var cell := Vector2i(
				int((box.get_center().x + grid.world_size().x * 0.5) / grid.cell_size),
				int((box.get_center().z + grid.world_size().y * 0.5) / grid.cell_size)
			)
			var where := "%s: litter on a %s" % [map, grid.glyph(cell)]
			(
				assert_bool(grid.glyph(cell) == ArenaGrid.FLOOR)
				. override_failure_message(where)
				. is_true()
			)


## Every piece of litter keeps to the spot it was dropped on, GAME.md 8.1c, and no spot is left
## bare: a part reaching past [constant RoomKit.LITTER_REACH] would reach past the clear floor the
## kit found for it.
func test_every_piece_of_litter_keeps_to_its_spot() -> void:
	for map: String in LITTERED:
		var arena := _arena(map)
		var spots := arena.kit.dropped_at
		assert_int(spots.size()).override_failure_message("%s: little litter" % map).is_equal(
			Arena.LITTER_COUNT
		)
		var used: Dictionary[int, bool] = {}
		for part: MeshInstance3D in arena.get_node("Litter").get_children():
			var box := part.mesh.get_aabb()
			var nearest := -1
			for i: int in spots.size():
				var near := true
				for corner: int in 8:
					var at: Vector3 = part.transform * box.get_endpoint(corner)
					var off := Vector2(at.x - spots[i].x, at.z - spots[i].z)
					near = near and off.length() <= RoomKit.LITTER_REACH + SLACK
				if near:
					nearest = i
			var stray := "%s: a piece of litter at %v strays off its spot" % [map, part.position]
			assert_int(nearest).override_failure_message(stray).is_not_negative()
			used[nearest] = true
		assert_int(used.size()).override_failure_message("%s: a bare spot" % map).is_equal(
			spots.size()
		)


## No two pieces of litter lie together, GAME.md 8.1c: each reads as one thing on its own rather
## than as a heap, as two pads side by side read as one.
func test_no_two_pieces_of_litter_lie_together() -> void:
	for map: String in LITTERED:
		var arena := _arena(map)
		var grid := arena.grid
		var spots := arena.kit.dropped_at
		for i: int in spots.size():
			for j: int in range(i + 1, spots.size()):
				var gap := (grid.cell_of(spots[i]) - grid.cell_of(spots[j])).abs()
				(
					assert_int(maxi(gap.x, gap.y))
					. override_failure_message("%s: two pieces of litter together" % map)
					. is_greater_equal(RoomKit.LITTER_APART)
				)


## Nothing is dropped on or beside anything on the floor, GAME.md 8.1c: not a pad, a turbo plate or
## the lane it fires down, the Junction, a Jackpot or a pit, whose rims the litter keeps a cell
## off. Only floor and wall are round a piece.
func test_the_litter_keeps_clear_of_the_play() -> void:
	for map: String in LITTERED:
		var arena := _arena(map)
		var grid := arena.grid
		var lanes: Dictionary[Vector2i, bool] = {}
		for pad: Vector2i in grid.turbo_pads:
			var way3 := grid.turbo_direction(pad)
			var way := Vector2i(roundi(way3.x), roundi(way3.z))
			var ahead := pad + way
			while grid.glyph(ahead) == ArenaGrid.FLOOR:
				lanes[ahead] = true
				ahead += way
		for spot: Vector3 in arena.kit.dropped_at:
			var cell := grid.cell_of(spot)
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var near := cell + Vector2i(dx, dy)
					var glyph := grid.glyph(near)
					var what := "%s: litter at %v beside a %s" % [map, spot, glyph]
					if lanes.has(near):
						what = "%s: litter at %v in a turbo lane" % [map, spot]
					var clear := glyph in [ArenaGrid.FLOOR, ArenaGrid.WALL] and not lanes.has(near)
					assert_bool(clear).override_failure_message(what).is_true()


## Every room drops litter of its own, GAME.md 8.1c, in inks no other room's is all in: a pencil
## and shavings on the bench, a cigarette card After Hours, a bolt in the Yard.
func test_every_room_drops_its_own_litter() -> void:
	var seen: Array[String] = []
	for map: String in LITTERED:
		var arena := _arena(map)
		var dice := RandomNumberGenerator.new()
		var piece: Node3D = auto_free(Node3D.new())
		(
			assert_bool(arena.kit.style.litter(piece, 0, dice))
			. override_failure_message("%s drops the kit's litter" % map)
			. is_true()
		)
		var inks: Array[String] = []
		for part: MeshInstance3D in arena.get_node("Litter").get_children():
			var arrays := part.mesh.surface_get_arrays(0)
			var ink := str((arrays[Mesh.ARRAY_COLOR] as PackedColorArray)[0])
			if not inks.has(ink):
				inks.append(ink)
		inks.sort()
		var drops := ",".join(inks)
		if map == "waiting_room":
			continue
		(
			assert_bool(seen.has(drops))
			. override_failure_message("%s drops another room's litter" % map)
			. is_false()
		)
		seen.append(drops)


## And it costs next to nothing, GAME.md 10.7: a few hundred vertices a table, baked into a mesh or
## two in the plain paint and the metal the warm-up has compiled.
func test_the_litter_is_cheap() -> void:
	for map: String in LITTERED:
		var arena: Arena = auto_free(Arena.new())
		arena.layout = load("res://data/maps/%s.tres" % map)
		add_child(arena)
		var litter := arena.get_node("Litter")
		var looks := [Bake.tinted_look(false), Bake.tinted_look(true)]
		var count := 0
		for part: MeshInstance3D in litter.get_children():
			assert_bool(part.material_override in looks).is_true()
			for surface: int in part.mesh.get_surface_count():
				count += part.mesh.surface_get_array_len(surface)
		(
			assert_int(litter.get_child_count())
			. override_failure_message("%s: litter in %d meshes" % [map, litter.get_child_count()])
			. is_less_equal(2)
		)
		(
			assert_int(count)
			. override_failure_message("%s: litter of %d vertices" % [map, count])
			. is_less_equal(LITTER_VERTICES)
		)


## What is at the bottom of a pit stays at the bottom of it, GAME.md 8.1. A spike standing proud
## of the floor would be something to drive into rather than something to look down at.
func test_the_spikes_stay_in_the_pit() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		assert_int(arena.pits.size()).is_greater(0)
		for pit: Pit in arena.pits:
			var parts := _meshes(pit)
			assert_int(parts.size()).is_greater(1)
			for part: MeshInstance3D in parts:
				var box := part.transform * part.mesh.get_aabb()
				var proud := (
					"%s: something in a pit stands %.2fm above the floor" % [map, box.end.y]
				)
				assert_float(box.end.y).override_failure_message(proud).is_less_equal(0.02)


## Nothing a room lines a pit with lies in the dark rim the arena lays just inside every pit's
## opening, GAME.md 8.1: the Workbench's maple lining had its top at the rim's height and in its
## place, and the edges of the hole flickered between maple and black. A part over the rim stands
## clear above it or below it.
func test_nothing_lies_in_a_pit_s_rim() -> void:
	var rim := 0.004
	for map: String in MAPS:
		var arena := _arena(map)
		for pit: Pit in arena.pits:
			var hole := Rect2()
			for part: MeshInstance3D in _meshes(pit):
				if part.name == "Shaft":
					var box := part.mesh.get_aabb()
					hole = Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
			var inside := hole.grow(-Arena.PIT_RIM)
			for part: MeshInstance3D in _meshes(pit):
				if part.name == "Shaft":
					continue
				var box := part.transform * part.mesh.get_aabb()
				var flat := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
				var over := flat.intersects(hole) and not inside.encloses(flat)
				var level := absf(box.end.y - rim) < 0.002 or absf(box.position.y - rim) < 0.002
				(
					assert_bool(over and level)
					. override_failure_message("%s: a part of a pit lies in its rim" % map)
					. is_false()
				)


## Nothing a room lays on its floor lies at the height of the pads' inlays where a pad is, GAME.md
## 8.1c: the Sewing Table's felt round its coin and item pads had its top there, and the two fought
## over every pixel of the pad.
func test_nothing_lies_in_a_pad_s_inlay() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		var pads: Array[Rect2] = []
		for pad: Node3D in arena.coin_pads + arena.power_pads:
			var at := Vector2(pad.position.x, pad.position.z)
			pads.append(Rect2(at - Vector2.ONE * 0.6, Vector2.ONE * 1.2))
		for part: MeshInstance3D in _meshes(arena):
			if part.get_parent() is CoinPad or part.get_parent() is PowerUpPad:
				continue
			var box := part.global_transform * part.mesh.get_aabb()
			var lift := ArenaPads.LIFT
			if absf(box.end.y - lift) > 0.0005 and absf(box.position.y - lift) > 0.0005:
				continue
			var flat := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
			for pad: Rect2 in pads:
				(
					assert_bool(flat.intersects(pad))
					. override_failure_message(
						"%s: %s lies in a pad at %s" % [map, part.get_path(), str(box)]
					)
					. is_false()
				)


## GAME.md 8.1: a card room's pit is edged in red neon, since its one lamp leaves a dark hole in
## dark felt out past the brightest of it.
func test_a_card_room_pit_is_edged_in_neon() -> void:
	for map: String in ["vault"]:
		var arena := _arena(map)
		for pit: Pit in arena.pits:
			var lit := _meshes(pit).filter(
				func(part: MeshInstance3D) -> bool:
					var paint := part.material_override as StandardMaterial3D
					return paint != null and paint.emission_enabled
			)
			assert_int(lit.size()).override_failure_message("%s: an unlit pit" % map).is_equal(4)
	for pit: Pit in _arena("lucky_crossing").pits:
		for part: MeshInstance3D in _meshes(pit):
			var paint := part.material_override as StandardMaterial3D
			assert_bool(paint != null and paint.emission_enabled).is_false()


## Every room paints its own face on the cash-out pad, GAME.md 8.1: a roulette wheel After Hours,
## a hazard border in the Yard, a machined plate on the bench. No two of them are the same set of
## colors, which is the whole of what "map specific" means here.
func test_every_room_paints_its_own_cash_out_pad() -> void:
	var seen: Array[String] = []
	for map: String in MAPS:
		var arena := _arena(map)
		var parts := _meshes(arena.junction)
		assert_int(parts.size()).override_failure_message("%s has a bare pad" % map).is_greater(8)
		var inks: Array[String] = []
		for part: MeshInstance3D in parts:
			var skin := part.material_override as StandardMaterial3D
			if skin != null and not inks.has(str(skin.albedo_color)):
				inks.append(str(skin.albedo_color))
		inks.sort()
		var face := ",".join(inks)
		(
			assert_bool(seen.has(face))
			. override_failure_message("%s wears another room's pad" % map)
			. is_false()
		)
		seen.append(face)


## And the pad is still the pad. What a room paints on it changes nothing a kart can touch: the
## same disc of the same size in the same place, and the same rim blinking the hint of 3.4.
func test_the_painted_pad_is_still_the_pad_underneath() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		var pad := arena.junction
		assert_float(pad.radius).is_equal_approx(arena.junction_radius, 0.001)
		assert_vector(pad.position).is_equal_approx(arena.junction_position, Vector3.ONE * 0.001)
		var shapes := 0
		for child: Node in pad.get_children():
			if child is CollisionShape3D:
				shapes += 1
		assert_int(shapes).override_failure_message("%s: the pad has no shape" % map).is_equal(1)
		# Nothing painted on it stands high enough to be in anybody's way.
		for part: MeshInstance3D in _meshes(pad):
			var top: float = (part.transform * part.get_aabb()).end.y
			(
				assert_float(top)
				. override_failure_message("%s: the pad stands %.2f m up" % [map, top])
				. is_less(0.5)
			)


## The Junction calls for a pot to be banked, GAME.md 3.4, and its lamps light on their own. They
## are the one part of the pad that changes, and the materials that do it are built for it rather
## than taken from the room's shared ones: a lamp that borrowed the room's neon would take every
## other light of that color in the room along with it.
func test_the_junction_calls_without_taking_the_room_with_it() -> void:
	for map: String in MAPS:
		var arena := _arena(map)
		var pad := arena.junction
		assert_object(pad.cue).is_not_null()
		assert_float(pad.cue.glow_now()).is_equal_approx(pad.cue.rest_glow, 0.0001)
		pad.hint = 1.0
		var brightest := 0.0
		for i: int in 40:
			pad._process(0.02)
			brightest = maxf(brightest, pad.cue.glow_now())
		assert_float(brightest).is_greater(pad.cue.rest_glow + 0.5)
		# Nothing else in the room wears its lamps.
		var lamps := pad.cue.lamps()
		for part: MeshInstance3D in _meshes(arena):
			if pad.is_ancestor_of(part):
				continue
			assert_bool(lamps.has(part.material_override)).is_false()
