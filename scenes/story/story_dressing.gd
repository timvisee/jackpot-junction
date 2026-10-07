class_name StoryDressing
extends RoomBuild
## What the story puts up in a room, STORY.md 6.1 and 6.8: a poster of the House's on the room's
## back wall and a word painted on the road; the words on the Yard's sign, the days on the
## Workbench's calendar and, after the ending, the picture in After Hours' left frame; and the
## crowd falling into step, 6.9. Only the rooms a match is played in carry any of it; the Garage,
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
## The Workbench's calendar: the month Kit left in and the month after, each how many days it has
## and which day of the week it starts on, Monday 0; the day ringed, a Friday; and the ring's red.
const MONTHS: Array[Vector2i] = [Vector2i(31, 2), Vector2i(30, 5)]
const KIT_LAST_DAY := 17
const RING := Color(0.8, 0.1, 0.08)
## After Hours' picture: how many pixels it is rendered at, once, and its brass plate.
const PICTURE_PIXELS := Vector2i(560, 360)
## The Count Room's monitor: its screen, and how long its cursor holds on or off.
const COUNT_SCREEN := Vector2(8.0, 4.6)
const CURSOR_BLINK := 0.53
const BRASS := Color(0.74, 0.6, 0.3)

## The stage this room was dressed for, read once as it went up.
var stage := Story.Stage.CUSTOMER
## The poster and the road, for whatever wants to look at them, and the rest where a room has it.
var poster: Node3D
var road: Node3D
var sign: Label3D
var calendar: Node3D
var picture: Node3D


## Dresses [param for_arena] for the stage this machine shows, if it is a room a match is played
## in, and returns the dressing, or null.
static func add_to(for_arena: Arena) -> StoryDressing:
	if for_arena.room == null or for_arena.room.id not in ROOMS:
		return null
	var dressing := StoryDressing.new()
	dressing._stand_in(for_arena, "Story")
	dressing.stage = Story.stage_here()
	dressing._build()
	# The house falls into step as the story goes, STORY.md 6.9.
	if for_arena.crowd != null:
		for_arena.crowd.spread = Story.crowd_spread(dressing.stage, Story.clock_here())
	return dressing


func _build() -> void:
	_road()
	var shell := arena.get_node_or_null("Shell") as RoomShell
	match room.id:
		&"workbench":
			_workbench_poster()
			if shell != null:
				_calendar(shell.calendar_at)
		&"after_hours":
			_card_room_poster()
			if shell != null and stage == Story.Stage.OPERATOR:
				_picture(shell.pictures_at[0])
		&"the_yard":
			_yard_poster()
			if shell != null:
				_sign(shell.sign_at)
		&"count_room":
			_count_room_monitor()


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
	var word := StoryFill.fill(StoryLines.at(StoryLines.ROAD, stage, ""), Game.settings.profile)
	var painted := RoadPaint.make(word, size, room.marking)
	painted.name = "Word"
	road.add_child(painted)


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


## The Count Room's poster, STORY.md 8.2: a monitor standing on the middle rack of the back row,
## big enough to read from the table, HUMAN OVERSIGHT: 0 in the room's green over a block cursor
## blinking under it.
func _count_room_monitor() -> void:
	var hall := arena.get_node_or_null("CountRoom") as CountRoom
	if hall == null or hall.back_racks.is_empty():
		return
	var middle := hall.back_racks[0]
	for rack: Vector3 in hall.back_racks:
		if absf(rack.x) < absf(middle.x):
			middle = rack
	poster = Node3D.new()
	poster.name = "Poster"
	poster.position = middle + Vector3(0.0, CountRoom.RACK.y + COUNT_SCREEN.y * 0.5 + 0.4, 0.0)
	add_child(poster)
	var screen := _box(
		Vector3(COUNT_SCREEN.x + 0.4, COUNT_SCREEN.y + 0.4, 0.3),
		surfaces.painted(Color(0.03, 0.04, 0.04)),
		Vector3.ZERO
	)
	remove_child(screen)
	poster.add_child(screen)
	var glass := _box(
		Vector3(COUNT_SCREEN.x, COUNT_SCREEN.y, 0.02),
		surfaces.neon(Color(0.03, 0.16, 0.06), 0.35),
		Vector3(0.0, 0.0, 0.16)
	)
	remove_child(glass)
	poster.add_child(glass)
	var words := _words(StoryLines.MONITOR, COUNT_SCREEN.x * 0.86, COUNT_SCREEN.y * 0.24, room.trim)
	words.name = "Big"
	words.shaded = false
	words.position = Vector3(0.0, COUNT_SCREEN.y * 0.12, 0.18)
	poster.add_child(words)
	var cursor := _box(
		Vector3(COUNT_SCREEN.x * 0.05, COUNT_SCREEN.y * 0.16, 0.02),
		surfaces.neon(room.trim, 1.0),
		Vector3(0.0, -COUNT_SCREEN.y * 0.22, 0.18)
	)
	remove_child(cursor)
	cursor.name = "Cursor"
	poster.add_child(cursor)
	var blink := cursor.create_tween().set_loops()
	(
		blink
		. tween_callback(func() -> void: cursor.visible = not cursor.visible)
		. set_delay(CURSOR_BLINK)
	)


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


# --- the rooms' own --------------------------------------------------------------------------


## The words on the lit board over the Yard's doors, in its own light, STORY.md 6.8.
func _sign(at: Vector3) -> void:
	sign = _words(str(StoryLines.at(StoryLines.YARD_SIGN, stage, "")), 38.0, 2.8, room.trim)
	sign.name = "Sign"
	sign.shaded = false
	sign.position = at + Vector3(0.0, 0.0, 0.45)
	add_child(sign)


## The days on the Workbench's calendar, STORY.md 6.8: a month's grid under its band, from the
## third stage the day Kit left ringed in red, and once the last note is found the next month's
## page, with nothing ringed.
func _calendar(at: Vector3) -> void:
	calendar = Node3D.new()
	calendar.name = "Calendar"
	calendar.position = at + Vector3(0.0, 0.0, 0.17)
	add_child(calendar)
	var turned := (
		stage >= Story.Stage.PARTICIPANT and Game.settings.profile.story.has_note(Story.NOTE_COUNT)
	)
	var month := MONTHS[1] if turned else MONTHS[0]
	var days := MultiMesh.new()
	days.transform_format = MultiMesh.TRANSFORM_3D
	var mark := BoxMesh.new()
	mark.size = Vector3(0.5, 0.36, 0.04)
	days.mesh = mark
	days.instance_count = month.x
	for day: int in month.x:
		days.set_instance_transform(day, Transform3D(Basis.IDENTITY, _day_at(month.y + day)))
	var grid := MultiMeshInstance3D.new()
	grid.name = "Days"
	grid.multimesh = days
	grid.material_override = surfaces.painted(Color(0.3, 0.29, 0.3))
	grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	calendar.add_child(grid)
	if stage < Story.Stage.PARTICIPANT or turned:
		return
	var ring := TorusMesh.new()
	ring.inner_radius = 0.42
	ring.outer_radius = 0.62
	var circled := MeshInstance3D.new()
	circled.name = "Ring"
	circled.mesh = ring
	circled.material_override = surfaces.painted(RING)
	circled.position = _day_at(month.y + KIT_LAST_DAY - 1) + Vector3(0.0, 0.0, 0.04)
	circled.rotation.x = PI * 0.5
	circled.scale = Vector3(1.2, 1.0, 1.0)
	calendar.add_child(circled)


## Where the [param index]th square of the calendar's grid is, from its first row's Monday: seven
## to a row under the band, five rows.
func _day_at(index: int) -> Vector3:
	return Vector3(-2.7 + float(index % 7) * 0.9, 1.3 - floorf(index / 7.0) * 1.2, 0.0)


## After the ending, the player's kart in After Hours' left frame the way the license photo has
## it, rendered once as the room goes up, over a brass plate reading EMPLOYEE OF THE MONTH,
## STORY.md 6.8. The right frame stays dark.
func _picture(at: Vector3) -> void:
	picture = Node3D.new()
	picture.name = "Picture"
	picture.position = at
	add_child(picture)
	var viewport := SubViewport.new()
	viewport.size = PICTURE_PIXELS
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = LicenseCard.PHOTO_BACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.62, 0.7)
	world.environment = environment
	viewport.world_3d = world
	picture.add_child(viewport)
	var settings := Game.settings
	var kart := KartVisuals.display_model(
		maxi(settings.seat_color(0), 0), KartStyle.from_array(settings.kart_styles[0])
	)
	kart.rotation.y = KartVisuals.facing_soon(LicenseCard.SPIN_SECONDS)
	kart.position.y = -0.27
	viewport.add_child(kart)
	var camera := Camera3D.new()
	camera.fov = 34.0
	camera.look_at_from_position(Vector3(0.0, 1.55, 3.3), Vector3(0.0, 0.9, 0.0), Vector3.UP)
	viewport.add_child(camera)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.1
	light.rotation_degrees = Vector3(-40.0, -30.0, 0.0)
	viewport.add_child(light)
	var print := QuadMesh.new()
	print.size = Vector2(14.0, 9.0)
	var skin := StandardMaterial3D.new()
	skin.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skin.albedo_texture = viewport.get_texture()
	var photo := MeshInstance3D.new()
	photo.name = "Photo"
	photo.mesh = print
	photo.material_override = skin
	photo.position = Vector3(0.0, 0.0, 0.36)
	photo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	picture.add_child(photo)
	var plate := _box(Vector3(9.0, 1.4, 0.3), surfaces.neon(BRASS, 0.3), Vector3(0.0, -6.6, 0.2))
	remove_child(plate)
	picture.add_child(plate)
	var words := _words(StoryLines.EMPLOYEE, 8.2, 0.8, Color(0.16, 0.12, 0.06))
	words.name = "Plate"
	words.position = Vector3(0.0, -6.6, 0.37)
	picture.add_child(words)
