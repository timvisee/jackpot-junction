class_name GrandPrixFinale
extends Node3D
## The end of a Grand Prix, GAME.md 9.7: a room of its own, put up for one thing, a party for
## whoever won the run.
##
## Not the room the last map was played in, which is full of everything that map needed and has
## its DJ booth tucked behind the far rail with the boards in front of it. This one is a dance floor
## lit on the beat in the colors of the top three, with the podium on it and the three standing on
## it; the booth up on a riser behind them, bigger than usual, so it is seen over the podium rather
## than hidden behind it; a hoarding behind the booth saying who won; the crowd all the way round;
## the disco rig over it at the top of the meter with every light on the winner; and fireworks in
## the three colors going up behind the board, where they frame it rather than cover it. It is
## built in the room's own materials, well away from the arena, which is hidden while it is on.
##
## The camera starts high over the room and flies in slowly to look down on the podium, holds there,
## and only then do the run's standings come up over it. Everybody's own: each machine puts it up
## when its player asks for the run's results, from what it already knows, so nothing about it goes
## over the wire.

const SCENE := preload("res://scenes/finale/grand_prix_finale.tscn")
## How far from the arena the room goes up: out of sight of it, and out of reach of anything still
## rolling about in the match it ended.
const AWAY := Vector3(0.0, 0.0, 600.0)
## The dance floor the crowd stands round, and the tiles it is laid in.
const FLOOR_SIZE := Vector2(18.0, 10.0)
const TILE := 2.0
const TILE_GAP := 0.08
const FLOOR_DARK := Color(0.05, 0.05, 0.07)
const TILE_DARK := Color(0.1, 0.1, 0.13)
## How many of the tiles are lit at a time, as a share, and how brightly.
const TILES_LIT := 0.4
const TILE_GLOW := 1.6
## How far the table the crowd stands on runs past the floor.
const SURROUND := 14.0
## The card room's velvet rope round the floor, GAME.md 8.1: how far out from its edge it stands,
## how big it is against the card room's, and the gap left in it across the front, in front of the
## podium, which is the camera's way in.
const ROPE_OUT := 0.55
const ROPE_SCALE := 0.7
const ROPE_GAP := 8.0
## Stacks of chips the size of the card room's at the two back corners of the floor, in the colors
## of the three on the podium: where they stand in from the corner, and how many chips each is.
const CHIPS_IN := Vector2(1.6, 1.4)
const CHIP_RADIUS := 0.62
const CHIP_HEIGHT := 0.18
const CHIP_STACKS: Array[int] = [9, 6, 12, 7]
## The hall the party is in, GAME.md 8.1: how far out its walls stand from the middle of the floor,
## how tall they are, and a line of neon along them. There is no wall on the near side, where the
## camera is, and the floor runs on past it, so nowhere in the shot does the world stop.
const HALL := Vector2(46.0, 40.0)
const HALL_NEAR := 80.0
const HALL_HEIGHT := 30.0
## How much darker than the table the hall's floor and walls are: the same venue, further off.
const HALL_FLOOR_SHADE := 0.45
const HALL_WALL_SHADE := 0.7
const NEON_HEIGHT := 5.0
## The podium, forward of the middle of the floor so the booth has the back of it: where each place
## stands and how tall its step is, in meters.
const PODIUM_Z := 1.2
const PLACES: Array[Vector2] = [Vector2(0.0, 1.75), Vector2(-2.8, 1.3), Vector2(2.8, 0.95)]
const STEP_SIZE := Vector2(2.4, 2.4)
const STEP_COLOR := Color(0.12, 0.12, 0.16)
## How tall the place painted on the front of a step is, the same on every step: sized to the
## lowest, so the 3 fits its step as well as the 1 does.
const NUMBER_HEIGHT := 0.46
## The band of the player's own color round the top of their step, and how far it stands proud.
const BAND_HEIGHT := 0.12
const BAND_LIFT := 0.03
const KART_SCALE := 1.4
## Seconds for a kart on the podium to turn all the way round, and how high the winner bounces.
const SPIN_SECONDS := 6.0
const BOUNCE := 0.18
const BOUNCE_RATE := 5.0
## The booth: how high the riser under it is, how much bigger than usual it is, and the riser's
## footprint.
const RISER_HEIGHT := 1.6
const BOOTH_SCALE := 1.5
const RISER_SIZE := Vector2(10.5, 4.4)
## The board behind the booth that says who won: how far behind the booth it stands and how much
## bigger it is than a hoarding over the crowd.
const BOARD_BEHIND := 4.2
const BOARD_SCALE := 1.7
## The camera's move: from high over the back of the room down to looking at the podium from in
## front of it over [constant PAN_SECONDS], then held for [constant HOLD_SECONDS] before the
## standings come up.
const PAN_SECONDS := 6.0
const HOLD_SECONDS := 2.0
const OPEN_FROM := Vector3(0.0, 26.0, 36.0)
const OPEN_AT := Vector3(0.0, 0.0, -2.0)
const SHOT_FROM := Vector3(0.0, 8.0, 15.5)
const SHOT_AT := Vector3(0.0, 3.0, -3.0)
const SHOT_FOV := 40.0
## Confetti off the steps, a burst every so often in one of the three colors; how long the
## fireworks keep going, which is longer than anybody reads the standings for; and how far behind
## the board and how wide they go up.
const CONFETTI_EVERY := 0.3
const FIREWORK_SECONDS := 90.0
const FIREWORKS_BEHIND := 5.0
const FIREWORKS_SPAN := Vector2(34.0, 6.0)

var match_node: Match
var crowd: Crowd
var disco: DiscoLights

var _camera: Camera3D
var _from: Transform3D
var _to: Transform3D
var _karts: Array[Node3D] = []
var _colors: Array[Color] = []
var _tiles: Array[MeshInstance3D] = []
var _tile_dark: StandardMaterial3D
var _tile_lit: Array[StandardMaterial3D] = []
var _beat := -1
var _age := 0.0
var _confetti_left := 0.0
var _shown := false
var _done: Callable
var _rng := RandomNumberGenerator.new()
## The winner's name on the board.
var _champion: Label3D


## Puts the room up for [param standings], best first, hides [param in_match]'s arena while it is
## on, and calls [param done] once the camera has arrived and held, which is when the standings go
## up.
static func stage(in_match: Match, standings: Array[PlayerSlot], done: Callable) -> GrandPrixFinale:
	var finale: GrandPrixFinale = SCENE.instantiate()
	finale.name = "GrandPrixFinale"
	finale.match_node = in_match
	finale._done = done
	in_match.finale = finale
	in_match.add_child(finale)
	finale.global_position = in_match.arena.global_position + AWAY
	finale._build(standings)
	finale._leave_the_arena()
	finale._raise_the_room()
	finale._take_the_shot()
	return finale


## Whether the camera has arrived and the standings are up.
func is_shown() -> bool:
	return _shown


## Skips the camera's move for a player who has seen it, straight to the standings.
func skip() -> void:
	_age = maxf(_age, PAN_SECONDS + HOLD_SECONDS)


func _unhandled_input(event: InputEvent) -> void:
	if not _shown and event.is_action_pressed(&"ui_accept"):
		skip()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_age += delta
	for i: int in _karts.size():
		var kart := _karts[i]
		kart.rotate_y(TAU * delta / SPIN_SECONDS * (1.0 if i != 1 else -1.0))
		if i == 0:
			kart.position.y = PLACES[0].y + BAND_LIFT + absf(sin(_age * BOUNCE_RATE)) * BOUNCE
	_confetti_left -= delta
	if _confetti_left <= 0.0 and not _karts.is_empty():
		_confetti_left = CONFETTI_EVERY
		var place := _rng.randi() % _karts.size()
		var over := _karts[place].global_position + Vector3(0.0, 1.2, 0.0)
		Burst.spawn(self, over, _colors[place], 1.1, 18)
	_light_the_floor()
	var t := smoothstep(0.0, 1.0, clampf(_age / PAN_SECONDS, 0.0, 1.0))
	if _camera != null:
		_camera.global_transform = _from.interpolate_with(_to, t)
	if not _shown and _age >= PAN_SECONDS + HOLD_SECONDS:
		_shown = true
		if _done.is_valid():
			_done.call()


## Every beat of the music the dance floor lights again, a different few tiles in each of the
## three colors.
func _light_the_floor() -> void:
	var beat := Audio.music_beat_index()
	if beat == _beat or _tile_lit.is_empty():
		return
	_beat = beat
	for tile: MeshInstance3D in _tiles:
		var lit := _rng.randf() < TILES_LIT
		tile.material_override = _tile_lit[_rng.randi() % _tile_lit.size()] if lit else _tile_dark


## The room: the floor, the table round it, the crowd and the booth on its riser, the podium and
## the three on it, the board behind the booth, the disco rig and a light on the podium.
func _build(standings: Array[PlayerSlot]) -> void:
	var room := match_node.arena.room if match_node.arena != null else RoomLook.fallback()
	var shown := mini(standings.size(), PLACES.size())
	for place: int in shown:
		_colors.append(standings[place].color())
	var surfaces := Surfaces.new(room)
	_lay_the_floor(surfaces)
	_fence_the_floor(room, surfaces)
	_stack_the_chips(surfaces)
	crowd = Crowd.add_to(self, FLOOR_SIZE, room, RISER_HEIGHT, BOOTH_SCALE)
	_raise_the_riser()
	var podium := Node3D.new()
	podium.name = "Podium"
	podium.position = Vector3(0.0, 0.0, PODIUM_Z)
	add_child(podium)
	for place: int in shown:
		_add_step(podium, standings[place], place)
	if shown > 0:
		_raise_the_board(standings[0], room)
	disco = DiscoLights.new()
	disco.name = "DiscoLights"
	add_child(disco)
	disco.setup(FLOOR_SIZE)
	var spot := SpotLight3D.new()
	spot.name = "Spot"
	spot.light_color = Color(1.0, 0.94, 0.82)
	spot.light_energy = 6.0
	spot.spot_range = 18.0
	spot.spot_angle = 30.0
	spot.position = Vector3(0.0, 10.0, PODIUM_Z + 5.0)
	add_child(spot)
	spot.look_at(global_position + Vector3(0.0, 1.0, PODIUM_Z), Vector3.UP)


## A dance floor of dark tiles, some of them lit in the colors of the three on the podium, on the
## room's own table, which runs out under the crowd.
func _lay_the_floor(surfaces: Surfaces) -> void:
	_build_the_hall(surfaces)
	var table := MeshInstance3D.new()
	table.name = "Table"
	var slab := BoxMesh.new()
	var reach := FLOOR_SIZE + Vector2.ONE * SURROUND * 2.0
	slab.size = Vector3(reach.x, 0.5, reach.y)
	table.mesh = slab
	table.material_override = surfaces.surround()
	table.position = Vector3(0.0, Crowd.TABLE_TOP - 0.25, 0.0)
	add_child(table)
	var base := MeshInstance3D.new()
	base.name = "DanceFloor"
	var box := BoxMesh.new()
	box.size = Vector3(FLOOR_SIZE.x, Arena.FLOOR_THICKNESS, FLOOR_SIZE.y)
	base.mesh = box
	base.material_override = _material(FLOOR_DARK)
	base.position = Vector3(0.0, -Arena.FLOOR_THICKNESS * 0.5, 0.0)
	add_child(base)
	_tile_dark = _material(TILE_DARK)
	for color: Color in _colors:
		var lit := _material(color, true)
		lit.emission_energy_multiplier = TILE_GLOW
		_tile_lit.append(lit)
	var across := floori(FLOOR_SIZE.x / TILE)
	var down := floori(FLOOR_SIZE.y / TILE)
	var plate := PlaneMesh.new()
	plate.size = Vector2.ONE * (TILE - TILE_GAP)
	for x: int in across:
		for z: int in down:
			var tile := MeshInstance3D.new()
			tile.mesh = plate
			tile.material_override = _tile_dark
			tile.position = Vector3(
				(x - (across - 1) * 0.5) * TILE, 0.005, (z - (down - 1) * 0.5) * TILE
			)
			add_child(tile)
			_tiles.append(tile)


## The hall round all of it: a floor under the table that runs on past the camera, and walls at the
## back and the sides with a line of neon along them in the colors of the three on the podium.
func _build_the_hall(surfaces: Surfaces) -> void:
	# Just under the top of the table the crowd stands on, so the table is a platform on it.
	var ground := Crowd.TABLE_TOP - 0.02
	var depth := HALL.y + HALL_NEAR
	var table := surfaces.surround().albedo_color
	var floor_box := Vector3(HALL.x * 2.0, 1.0, depth)
	_hall_box(
		floor_box,
		surfaces.painted(table.darkened(HALL_FLOOR_SHADE)),
		Vector3(0.0, ground - 0.5, (HALL_NEAR - HALL.y) * 0.5)
	)
	var wall := surfaces.painted(table.darkened(HALL_WALL_SHADE))
	var middle := ground + HALL_HEIGHT * 0.5
	_hall_box(Vector3(HALL.x * 2.0, HALL_HEIGHT, 1.0), wall, Vector3(0.0, middle, -HALL.y))
	for side: float in [-1.0, 1.0]:
		_hall_box(
			Vector3(1.0, HALL_HEIGHT, depth),
			wall,
			Vector3(side * HALL.x, middle, (HALL_NEAR - HALL.y) * 0.5)
		)
	var neon := _colors.duplicate() if not _colors.is_empty() else [Palette.NEON_MAGENTA]
	var line := ground + NEON_HEIGHT
	var back_strip := Vector3(HALL.x * 2.0, 0.25, 0.1)
	_hall_box(back_strip, _material(neon[0], true), Vector3(0.0, line, -HALL.y + 0.55))
	for i: int in 2:
		var side := -1.0 if i == 0 else 1.0
		var ink: Color = neon[(i + 1) % neon.size()]
		_hall_box(
			Vector3(0.1, 0.25, depth),
			_material(ink, true),
			Vector3(side * (HALL.x - 0.55), line, (HALL_NEAR - HALL.y) * 0.5)
		)


func _hall_box(size: Vector3, paint: Material, at: Vector3) -> void:
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.material_override = paint
	box.position = at
	box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(box)


## The velvet rope of the card room round the floor, between the dancing and the crowd: down both
## sides, and across the front either side of the gap in front of the podium. The back is the
## booth's.
func _fence_the_floor(room: RoomLook, surfaces: Surfaces) -> void:
	var fence := RoomShell.new()
	fence.name = "Rope"
	fence.room = room
	fence.surfaces = surfaces
	fence.scale = Vector3.ONE * ROPE_SCALE
	add_child(fence)
	var half := FLOOR_SIZE * 0.5 + Vector2.ONE * ROPE_OUT
	# The fence is built at the card room's size and shrunk, so where it goes is given unshrunk.
	var at := func(x: float, z: float) -> Vector3:
		return Vector3(x, Crowd.TABLE_TOP, z) / ROPE_SCALE
	for side: float in [-1.0, 1.0]:
		fence.rope_run(at.call(side * half.x, -half.y), at.call(side * half.x, half.y), 4)
		fence.rope_run(at.call(side * half.x, half.y), at.call(side * ROPE_GAP * 0.5, half.y), 2)


## Two stacks of chips at each back corner of the floor, one each side of the booth: the house's
## own money, in the colors of the three it has just paid out to.
func _stack_the_chips(surfaces: Surfaces) -> void:
	var half := FLOOR_SIZE * 0.5
	var coin := CylinderMesh.new()
	coin.top_radius = CHIP_RADIUS
	coin.bottom_radius = CHIP_RADIUS
	coin.height = CHIP_HEIGHT
	coin.radial_segments = 16
	coin.rings = 1
	var inks := _colors.duplicate() if not _colors.is_empty() else [Palette.CHIP_RED]
	for i: int in CHIP_STACKS.size():
		var side := -1.0 if i < 2 else 1.0
		var foot := Vector3(
			side * (half.x - CHIPS_IN.x - float(i % 2) * CHIP_RADIUS * 2.2),
			0.0,
			-(half.y - CHIPS_IN.y) + float(i % 2) * CHIP_RADIUS * 0.6
		)
		var paint := surfaces.printed(Surfaces.CHIP_FACE, inks[i % inks.size()])
		for chip: int in CHIP_STACKS[i]:
			var piece := MeshInstance3D.new()
			piece.mesh = coin
			piece.material_override = paint
			# A little off true as it climbs, the way a stack somebody has been counting stands.
			var lean := Vector3(sin(chip * 1.7 + i), 0.0, cos(chip * 2.3 + i)) * 0.025
			piece.position = foot + lean + Vector3(0.0, CHIP_HEIGHT * (float(chip) + 0.5), 0.0)
			add_child(piece)


## The stage the booth stands on, at the back of the floor where the crowd puts it, with a line of
## neon along its front edge.
func _raise_the_riser() -> void:
	var z := -(FLOOR_SIZE.y * 0.5 + Crowd.BOOTH_OUT)
	var riser := MeshInstance3D.new()
	riser.name = "Riser"
	var box := BoxMesh.new()
	box.size = Vector3(RISER_SIZE.x, RISER_HEIGHT, RISER_SIZE.y)
	riser.mesh = box
	riser.material_override = _material(STEP_COLOR)
	riser.position = Vector3(0.0, Crowd.TABLE_TOP + RISER_HEIGHT * 0.5, z)
	add_child(riser)
	var edge := MeshInstance3D.new()
	var strip := BoxMesh.new()
	strip.size = Vector3(RISER_SIZE.x + 0.04, 0.1, 0.06)
	edge.mesh = strip
	edge.material_override = _material(Palette.NEON_MAGENTA, true)
	edge.position = Vector3(0.0, Crowd.TABLE_TOP + RISER_HEIGHT - 0.05, z + RISER_SIZE.y * 0.5)
	add_child(edge)


## A hoarding of the room's own kind behind the booth, GAME.md 8.1, bigger than the ones over a
## crowd and facing the floor: GRAND PRIX CHAMPION, and the winner's name in their color under it.
## A sign rather than words hanging in the air, so it is part of the room.
func _raise_the_board(winner: PlayerSlot, room: RoomLook) -> void:
	var z := -(FLOOR_SIZE.y * 0.5 + Crowd.BOOTH_OUT + BOARD_BEHIND)
	var at := global_position + Vector3(0.0, Crowd.TABLE_TOP, z)
	var toward := global_position + Vector3(0.0, 0.0, SHOT_FROM.z)
	var board := Billboard.add_to(self, at, toward, room)
	board.name = "ChampionBoard"
	board.scale = Vector3.ONE * BOARD_SCALE
	board.panel(Vector2(0.0, 0.62), Vector2(Billboard.WIDTH, 0.08), Palette.CHIP_GOLD, true)
	board.words("GRAND PRIX CHAMPION", Vector2(0.0, 0.84), 0.34, Palette.CHIP_GOLD)
	_champion = board.words(winner.display_name(), Vector2(0.0, -0.2), 0.95, winner.color())
	_champion.name = "Champion"
	var width := Billboard.WIDTH * BOARD_SCALE + 1.0
	crowd.keep_clear(Rect2(-width * 0.5, z - 1.8, width, 3.6))


## One step with its kart on top, its place painted on the front and a band of its color round
## the top.
func _add_step(podium: Node3D, slot: PlayerSlot, place: int) -> void:
	var at := PLACES[place]
	var step := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(STEP_SIZE.x, at.y, STEP_SIZE.y)
	step.mesh = box
	step.material_override = _material(STEP_COLOR)
	step.position = Vector3(at.x, at.y * 0.5, 0.0)
	podium.add_child(step)
	var band := MeshInstance3D.new()
	var band_box := BoxMesh.new()
	band_box.size = Vector3(STEP_SIZE.x + 0.08, BAND_HEIGHT, STEP_SIZE.y + 0.08)
	band.mesh = band_box
	band.material_override = _material(slot.color(), true)
	band.position = Vector3(at.x, at.y - BAND_HEIGHT * 0.5 + BAND_LIFT, 0.0)
	podium.add_child(band)
	var number := Label3D.new()
	number.text = str(place + 1)
	number.font_size = 180
	# A font's size is the height of its em, and a figure is about seven tenths of that.
	number.pixel_size = NUMBER_HEIGHT / 0.7 / float(number.font_size)
	number.modulate = Palette.CHIP_GOLD if place == 0 else Color(0.86, 0.86, 0.9)
	number.position = Vector3(at.x, at.y * 0.5, STEP_SIZE.y * 0.5 + 0.01)
	podium.add_child(number)
	var kart := Node3D.new()
	kart.name = "Kart%d" % place
	kart.position = Vector3(at.x, at.y + BAND_LIFT, 0.0)
	kart.scale = Vector3.ONE * KART_SCALE
	kart.add_child(KartVisuals.display_model(slot.color_index, slot.style))
	podium.add_child(kart)
	_karts.append(kart)


## The arena the last map was played in goes, with everything standing round it and the HUD, so
## nothing of the match is left on the screen but the results the standings go up on.
func _leave_the_arena() -> void:
	for node: Node3D in [match_node.arena, match_node.score_tanks, match_node.led_clock]:
		if node != null:
			node.visible = false
	for child: Node in match_node.get_children():
		var kart := child as Kart
		if kart != null:
			kart.visible = false
	if match_node.bullets != null:
		match_node.bullets.visible = false
	if match_node.hud != null:
		match_node.hud.stand_aside()


## The room at the top of its meter for the party, GAME.md 8.4: the crowd on its feet, the lights
## on the winner, the music at its loudest and fireworks in all three colors behind the board.
func _raise_the_room() -> void:
	match_node.intensity.level = MatchIntensity.LEVELS
	match_node.intensity.value = 1.0
	disco.level = MatchIntensity.LEVELS
	crowd.level = MatchIntensity.LEVELS
	if not _karts.is_empty():
		disco.focus(_karts[0])
	Audio.duck_music(false)
	Audio.play_sfx(&"fanfare", -4.0, 0.0)
	var span := Vector3(FIREWORKS_SPAN.x, 1.0, FIREWORKS_SPAN.y)
	var behind := FLOOR_SIZE.y * 0.5 + Crowd.BOOTH_OUT + BOARD_BEHIND + FIREWORKS_BEHIND
	var sky := AABB(global_position + Vector3(0.0, 0.0, -behind) - span * 0.5, span)
	for color: Color in _colors:
		Fireworks.celebrate(self, sky, color, FIREWORK_SECONDS)


## The camera of its own that the move is made with: high over the room to begin with, looking
## down on all of it, and in front of the podium at the end.
func _take_the_shot() -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.fov = SHOT_FOV
	add_child(_camera)
	var origin := global_position
	_from = Transform3D(Basis.IDENTITY, origin + OPEN_FROM).looking_at(origin + OPEN_AT, Vector3.UP)
	_to = Transform3D(Basis.IDENTITY, origin + SHOT_FROM).looking_at(origin + SHOT_AT, Vector3.UP)
	_camera.global_transform = _from
	_camera.make_current()


func _material(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if glowing:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.2
	return material
