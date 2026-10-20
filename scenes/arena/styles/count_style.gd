class_name CountStyle
extends RoomStyle
## The Count Room's own make, GAME.md 8.1c, the room the House built for itself and the Final
## Hand's, STORY.md 8.2: the table is a circuit board. Its boxes are heat sinks, bright aluminum
## finned along their tops on a copper plate, light against the dark racks of the walls; and under
## the
## House's layout the floor is printed with the board's copper, traces running from every pad in
## toward the processor at its middle in straight runs and forty-five degree bends, each ending on
## a via, with a fine grid of test points between, all of it dim, in the green of the solder mask a
## little lighter, so it reads as the board and never as a line to drive along. Its walls, racks
## with lit faces, the racks round it, the processor, the banks of memory and the vents stay the
## room's own kit's, 8.1, see [CountKit].

## The board's inks: the copper under the mask, the vias' rings and the test points.
const TRACE := Color(0.42, 0.78, 0.5, 0.75)
const VIA := Color(0.8, 0.66, 0.38, 0.85)
const POINT := Color(0.42, 0.78, 0.5, 0.4)
## The heat sinks the boxes are: their aluminum and the copper they stand on.
const ALUMINUM := Color("#C3C9CF")
const COPPER := Color("#B87A45")

var _materials: Dictionary[String, StandardMaterial3D] = {}


## A heat sink off the board, what a box is here: a copper base plate, a bright aluminum block on
## it and fins standing along its top, so a box reads at a glance against the dark racks of the
## walls, light where they are dark.
func crate(holder: Node3D, size: Vector3) -> bool:
	var half := size * 0.5
	var base := 0.06
	var block := size.y * 0.3
	var foot := Vector3(size.x * 0.96, base, size.z * 0.96)
	_box(holder, foot, _paint("copper", COPPER, 0.4, 0.85), _up(-half.y + base * 0.5))
	var body := Vector3(size.x * 0.9, block, size.z * 0.9)
	var aluminum := _paint("aluminum", ALUMINUM, 0.35, 0.8)
	_box(holder, body, aluminum, _up(-half.y + base + block * 0.5))
	var fin_high := size.y - base - block
	var fins := 7
	for i: int in fins:
		var z := -body.z * 0.5 + body.z * (float(i) + 0.5) / float(fins)
		var at := Vector3(0.0, -half.y + base + block + fin_high * 0.5, z)
		_box(holder, Vector3(body.x, fin_high, 0.045), aluminum, at)
	return true


## The board's copper under the House's layout: a trace from every pad toward the processor, and a
## grid of test points over the open floor.
func print_under(on: LayoutPrint) -> void:
	var grid := on.grid
	var cell := float(LayoutPrint.CELL_PIXELS)
	for y: int in range(1, grid.height - 1, 2):
		for x: int in range(1, grid.width - 1, 2):
			if grid.glyph(Vector2i(x, y)) == ArenaGrid.FLOOR:
				on.draw_circle(Vector2(x + 1, y + 1) * cell, cell * 0.035, POINT)
	var middle := Vector2(grid.width, grid.height) * 0.5 * cell
	var from: Array[Vector2i] = []
	from.append_array(grid.coin_pads)
	from.append_array(grid.power_pads)
	from.append_array(grid.flush_pads)
	from.append_array(grid.slot_pads)
	from.append_array(grid.spawns)
	for i: int in from.size():
		_trace(on, grid, from[i], middle, cell, i)


## One trace from [param start] toward [param middle]: across in a straight run, a bend of forty
## five degrees, and on, stopping short of the first wall it meets, a via at each end. Each a little
## off its neighbors, by [param index], so two that run together lie side by side.
func _trace(
	on: LayoutPrint, grid: ArenaGrid, start: Vector2i, middle: Vector2, cell: float, index: int
) -> void:
	var at := (Vector2(start) + Vector2.ONE * 0.5) * cell
	var lane := (float(index % 3) - 1.0) * cell * 0.12
	var toward := middle - at
	var points := PackedVector2Array([at])
	# Straight along the longer way till what is left is a diagonal, then the diagonal in.
	var straight := absf(toward.x) - absf(toward.y)
	var bend := at
	if straight > 0.0:
		bend = at + Vector2(signf(toward.x) * straight, lane)
	else:
		bend = at + Vector2(lane, signf(toward.y) * -straight)
	points.append(bend)
	points.append(middle + (at - middle).normalized() * cell * 3.2)
	# Cut short at the first wall along it.
	var kept := PackedVector2Array([points[0]])
	for k: int in range(1, points.size()):
		var a := kept[kept.size() - 1]
		var b := points[k]
		var steps := maxi(ceili(a.distance_to(b) / (cell * 0.25)), 1)
		var stop := b
		var blocked := false
		for s: int in range(1, steps + 1):
			var p := a.lerp(b, float(s) / float(steps))
			var c := Vector2i(floori(p.x / cell), floori(p.y / cell))
			if grid.glyph(c) != ArenaGrid.FLOOR and c != start:
				stop = a.lerp(b, float(s - 1) / float(steps))
				blocked = true
				break
		kept.append(stop)
		if blocked:
			break
	if kept.size() < 2 or kept[0].distance_to(kept[kept.size() - 1]) < cell * 0.6:
		return
	on.draw_polyline(kept, TRACE, cell * 0.08, true)
	for end: Vector2 in [kept[0], kept[kept.size() - 1]]:
		on.draw_arc(end, cell * 0.09, 0.0, TAU, 16, VIA, cell * 0.035, true)


func _paint(key: String, color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	if not _materials.has(key):
		var paint := StandardMaterial3D.new()
		paint.albedo_color = color
		paint.roughness = roughness
		paint.metallic = metallic
		paint.metallic_specular = 0.5
		_materials[key] = paint
	return _materials[key]


func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)


func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	return ToyParts.box(into, size, skin, at)
