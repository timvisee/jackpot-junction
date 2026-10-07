class_name StoryDressing
extends RoomBuild
## What the story puts up in a room, STORY.md 6.1: a poster of the House's on the room's back wall
## and a word painted on the road. Only the rooms a match is played in carry any of it; the Garage,
## the lobby and the driving school are dressed as they always were. None of it collides with
## anything or decides anything, and it is kept out of the room's bake, since its words are drawn
## rather than built.

## The rooms that are dressed, the ones a match is played in.
const ROOMS: Array[StringName] = [&"workbench", &"after_hours", &"the_yard", &"count_room"]
## The road's box: how many cells across and how many deep it is, and what it keeps clear of. Two
## cells deep, since a lane's worth of letters is too small to read from where the camera stands
## back to, and six across, which fits between the near row's spawns and pads on every map. Only
## bare floor goes under it, and nothing a kart falls down or banks on stands beside it. The
## letters stand a little proud of the floor, and are stretched along the camera's line of sight
## as a road stretches its own, so they read from above.
const ROAD_CELLS := 6
const ROAD_ROWS := 2
const ROAD_LIFT := 0.014
const ROAD_STRETCH := 1.7
const ROAD_LINE := 0.09
const AVOID: Array[String] = [
	ArenaGrid.PIT,
	ArenaGrid.JUNCTION,
	ArenaGrid.JACKPOT,
	ArenaGrid.GATE,
	ArenaGrid.PORTAL,
]
## A poster's paper and ink, and the font size its words are drawn at before being scaled to
## meters.
const PAPER := Color(0.9, 0.87, 0.79)
const INK := Color(0.13, 0.12, 0.14)
const FONT_SIZE := 96

## The stage this room was dressed for, read once as it went up.
var stage := Story.Stage.CUSTOMER
## The poster and the road, for whatever wants to look at them.
var poster: Node3D
var road: Node3D


## Dresses [param for_arena] for the stage this machine shows, if it is a room a match is played
## in, and returns the dressing, or null.
static func add_to(for_arena: Arena) -> StoryDressing:
	if for_arena.room == null or for_arena.room.id not in ROOMS:
		return null
	var dressing := StoryDressing.new()
	dressing._stand_in(for_arena, "Story")
	dressing.stage = Story.stage_here()
	dressing._build()
	return dressing


func _build() -> void:
	_road()
	match room.id:
		&"workbench":
			_workbench_poster()
		&"after_hours":
			_card_room_poster()
		&"the_yard":
			_yard_poster()


# --- the road --------------------------------------------------------------------------------


## The word in its box across a lane on the near side, STORY.md 6.1.
func _road() -> void:
	var spot := road_spot(arena.grid, ROAD_CELLS)
	if spot.size == Vector2i.ZERO:
		return
	road = Node3D.new()
	road.name = "Road"
	add_child(road)
	var cell := arena.grid.cell_size
	var middle := (
		(arena.grid.cell_center(spot.position) + arena.grid.cell_center(spot.end - Vector2i.ONE))
		* 0.5
	)
	middle.y = ROAD_LIFT
	road.position = middle
	var size := Vector2(spot.size) * cell - Vector2.ONE * 0.2
	var paint := surfaces.marking(room.marking)
	for edge: float in [-1.0, 1.0]:
		var across := BoxMesh.new()
		across.size = Vector3(size.x, 0.01, ROAD_LINE)
		_lay(across, paint, Vector3(0.0, 0.0, edge * (size.y - ROAD_LINE) * 0.5))
		var down := BoxMesh.new()
		down.size = Vector3(ROAD_LINE, 0.01, size.y)
		_lay(down, paint, Vector3(edge * (size.x - ROAD_LINE) * 0.5, 0.0, 0.0))
	var word: String = StoryLines.at(StoryLines.ROAD, stage, "")
	var letters := _words(word, size.x * 0.86, size.y * 0.6 / ROAD_STRETCH, room.marking)
	letters.name = "Word"
	letters.rotation.x = -PI * 0.5
	letters.scale = Vector3(1.0, ROAD_STRETCH, 1.0)
	letters.shaded = true
	letters.position = Vector3(0.0, 0.006, 0.0)
	road.add_child(letters)


func _lay(mesh: Mesh, skin: Material, at: Vector3) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = skin
	part.position = at
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	road.add_child(part)


## Where the road's box goes on [param grid]: [param cells] floor cells across and [param rows]
## deep, nothing on any of them and no pit, Junction, Jackpot, gate or portal beside them,
## as near the near side as it fits and as near the middle of its rows as it will go. Its bottom row
## is kept one up from the wall where it can be, since the near wall stands in front of the row
## against it. An empty rect for a map with no such place.
static func road_spot(grid: ArenaGrid, cells: int, rows: int = ROAD_ROWS) -> Rect2i:
	var bottoms: Array[int] = [grid.height - 3, grid.height - 2]
	for row: int in range(grid.height - 4, grid.height / 2, -1):
		bottoms.append(row)
	for bottom: int in bottoms:
		var top := bottom - rows + 1
		var best := Rect2i()
		var nearest := INF
		for start: int in range(1, grid.width - cells):
			if not _clear(grid, Rect2i(start, top, cells, rows)):
				continue
			var off := absf(start + cells * 0.5 - grid.width * 0.5)
			if off < nearest:
				nearest = off
				best = Rect2i(start, top, cells, rows)
		if best.size != Vector2i.ZERO:
			return best
	return Rect2i()


static func _clear(grid: ArenaGrid, box: Rect2i) -> bool:
	for y: int in range(box.position.y, box.end.y):
		for x: int in range(box.position.x, box.end.x):
			if grid.glyph(Vector2i(x, y)) != ArenaGrid.FLOOR:
				return false
	for y: int in range(box.position.y - 1, box.end.y + 1):
		for x: int in range(box.position.x - 1, box.end.x + 1):
			if x < 0 or y < 0 or x >= grid.width or y >= grid.height:
				continue
			if grid.glyph(Vector2i(x, y)) in AVOID:
				return false
	return true


# --- the posters -----------------------------------------------------------------------------


## Pinned on the board at the back of the bench, across from the calendar.
func _workbench_poster() -> void:
	var half := _table()
	var face := -(arena.world_size().y * 0.5 + BACK_FAR + BACK_WALL) + 1.0
	_poster(Vector3(-half.x * 0.62, TOP + 13.0, face + 0.5), Vector2(12.0, 8.4), false)
	for side: float in [-1.0, 1.0]:
		var pin := _box(
			Vector3(0.5, 0.5, 0.4),
			surfaces.painted(Color(0.72, 0.16, 0.14)),
			Vector3(side * 5.2, 3.6, 0.3)
		)
		remove_child(pin)
		poster.add_child(pin)


## Framed and lit on the card room's far wall, out in front of the drape and high enough over the
## table that the camera sees it as it pulls out, the room being dark and the poster its own light.
func _card_room_poster() -> void:
	var wall := -(_room_half().y + WALL_THICKNESS * 0.5)
	_poster(Vector3(0.0, TOP + 9.0, wall + 4.6), Vector2(16.0, 11.0), true)


## Pasted across two panels of the yard's hoarding, beside the hard hat.
func _yard_poster() -> void:
	var half := arena.world_size() * 0.5
	var wide := half.x + FAR
	var span := wide * 2.0 / 15.0
	var z := -(half.y + BACK_FAR + BACK_WALL)
	_poster(Vector3(-wide + 6.0 * span, TOP + 3.3, z + 0.3), Vector2(span * 1.8, 5.4), false)


## The stage's poster at [param at], [param size] across: paper with the House's two lines on it,
## or, [param lit], a lit sign of the House's stock with its words in foil.
func _poster(at: Vector3, size: Vector2, lit: bool) -> void:
	poster = Node3D.new()
	poster.name = "Poster"
	poster.position = at
	add_child(poster)
	var lines: Array = StoryLines.at(StoryLines.POSTERS, stage, ["", ""])
	var back := _box(
		Vector3(size.x, size.y, 0.3),
		surfaces.painted(Color(0.08, 0.075, 0.09) if lit else PAPER),
		Vector3.ZERO
	)
	_dim(back)
	remove_child(back)
	poster.add_child(back)
	var ink := Palette.CHIP_GOLD if lit else INK
	var big := _words(str(lines[0]), size.x * 0.84, size.y * 0.3, ink)
	big.name = "Big"
	big.position = Vector3(0.0, size.y * 0.12, 0.17)
	var small := _words(str(lines[1]), size.x * 0.7, size.y * 0.14, ink)
	small.name = "Small"
	small.position = Vector3(0.0, -size.y * 0.26, 0.17)
	for words: Label3D in [big, small]:
		words.shaded = not lit
		poster.add_child(words)


## A line of [param text] [param tall] meters high at most, brought down to fit [param wide]
## meters across, in [param ink].
func _words(text: String, wide: float, tall: float, ink: Color) -> Label3D:
	var label := Label3D.new()
	label.text = StoryFill.fill(text, Game.settings.profile)
	label.font = Type.display_font()
	label.font_size = FONT_SIZE
	var span := label.font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var height := tall if span <= 0.0 else minf(tall, wide * FONT_SIZE / span)
	label.pixel_size = height / float(FONT_SIZE)
	label.modulate = ink
	label.outline_size = 0
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	return label
