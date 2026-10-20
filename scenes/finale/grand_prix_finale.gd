class_name GrandPrixFinale
extends Node3D
## The end of a Grand Prix, GAME.md 9.7: a room of its own, put up for one thing, a party for
## whoever won the run.
##
## Not the room the last map was played in, which is full of everything that map needed and has
## its DJ booth tucked behind the far rail with the boards in front of it. This one is a dance floor
## lit on the beat in the colors of the top three, with the podium on it and the three floating
## over it; the booth up on a riser behind them, bigger than usual, so it is seen over the podium
## rather than hidden behind it; a hoarding behind the booth saying who won; the crowd all the way
## round; the disco rig over it at the top of the meter with every light on the winner; and
## fireworks in the three colors going up behind the board, where they frame it rather than cover
## it. It is the House's party, put up in the room's own materials, well away from the arena, which
## is hidden while it is on: the House's podium, three blocks of what the room is made of, see
## [PartyDress], each under a ticket of the room's color with its player's hairline round it and a
## ticket of the House's stock on its front with its place in foil; the House's rail round the
## floor as round every table, GAME.md 8.1c, and along the front of the riser; the booth's desk the
## House's rail too; and the board a ticket of the House's, its header in foil over a perforation
## and the winner's name under it, see [HousePieces].
##
## It opens hushed: the music muffled as if from outside the room, the crowd and the DJ standing
## still, the floor dark, and a rising sound with smoke machines spitting across the floor under
## it. Then it drops, on a downbeat, into all of it at once, the music swept open. The camera
## starts high over the room and flies in slowly to look down on the podium, holds there, and
## only then do the run's standings come up over it. Everybody's own: each machine puts it up
## when its player asks for the run's results, from what it already knows, so nothing about it
## goes over the wire.

const SCENE := preload("res://scenes/finale/grand_prix_finale.tscn")
## How far from the arena the room goes up: out of sight of it, and out of reach of anything still
## rolling about in the match it ended.
const AWAY := Vector3(0.0, 0.0, 600.0)
## The dance floor the crowd stands round, and the tiles let into it, a shade off its floor as the
## House's pads are, GAME.md 8.1c.
const FLOOR_SIZE := Vector2(18.0, 10.0)
const TILE := 2.0
const TILE_GAP := 0.08
## How many of the tiles are lit at a time, as a share, and how brightly: fewer and softer than a
## disco's floor, so the floor keeps the beat under the podium rather than outshining the karts.
const TILES_LIT := 0.28
const TILE_GLOW := 0.7
## How much of a tile lights: a lamp let into it with a rim of the tile left dark round it. A round
## lamp, a pinball playfield's insert, is smaller than its square and lights whole.
const LAMP := 0.74
const INSERT := 0.62
## How far the table the crowd stands on runs past the floor.
const SURROUND := 14.0
## The House's rail round the floor, the edge of every table, GAME.md 8.1c: how wide and tall it is,
## how far out from the floor's edge its middle stands, and the gap left in it across the front, in
## front of the podium, which is the camera's way in.
const RAIL := Vector2(0.5, 0.55)
const RAIL_OUT := 0.3
const RAIL_GAP := 7.0
## How much further toward the camera than the rig puts them its lamps along the front of the floor
## stand, and how far aside of the runner the middle one does, see [method _move_the_front_row].
const RIG_FORWARD := 1.6
const RIG_ASIDE := PartyHall.RUNNER.x * 0.5 + 0.6
## Two smoke machines on the floor behind the podium, one each side of it, both spitting down the
## floor past it for as long as the rising sound runs: where they stand, and how far out from
## straight ahead they point, so the smoke runs out past the steps toward the floor's front corners
## rather than into the steps or across the floor in front of them.
const SMOKE_AT := Vector2(4.6, -3.8)
const SMOKE_OUT := 0.45
## The floor the hall stands on, see [PartyHall]: how far out it runs from the middle of the dance
## floor and on past the camera, and how much darker than the table it is.
const HALL := Vector2(46.0, 40.0)
const HALL_NEAR := 80.0
const HALL_FLOOR_SHADE := 0.45
## The podium, forward of the middle of the floor so the booth has the back of it: where each place
## stands and how tall its step is, in meters.
const PODIUM_Z := 1.2
const PLACES: Array[Vector2] = [Vector2(0.0, 1.75), Vector2(-2.8, 1.3), Vector2(2.8, 0.95)]
const STEP_SIZE := Vector2(2.4, 2.4)
## How far apart its steps stand, how much room a kart takes beside its teammates on a team's step,
## GAME.md 3.14, and how wide the podium may be between the smoke machines, past which it is drawn
## smaller.
const STEP_GAP := 0.4
const KART_ROOM := 1.9
const PODIUM_ROOM := 8.6
## The ticket laid on top of a step, GAME.md 8.1a: how thick it is and how deep its corners are
## punched, which is how far in from its edge the block under it stands; the room's metal piped
## round the block under it; the hairline of the player's color just inside its edge, how far in
## and how wide; and how far over it a kart's float starts.
const CAP := 0.16
const CAP_NOTCH := 0.16
const PIPING := 0.05
const LINE_IN := 0.17
const LINE := 0.06
const TOP_LIFT := 0.03
## How brightly a hairline in a player's color is lit: enough to read on the dark, never as bright
## as the kart it is about.
const LINE_GLOW := 0.6
## The plaque on the front of every step: a ticket of the House's stock, the same size on every
## step, sized to the lowest, its corners punched, the hairline of the player's color inside it,
## and the place in foil, as tall on all three, so the 3 fits its step as well as the 1 does.
const PLAQUE := Vector2(1.16, 0.62)
const PLAQUE_NOTCH := 0.1
const PLAQUE_THICK := 0.03
const PLAQUE_LINE_IN := 0.1
const PLAQUE_LINE := 0.028
const NUMBER_HEIGHT := 0.36
const KART_SCALE := 1.4
## The karts on the podium face the camera and float over their steps rather than stand on them:
## the least they are off it, how far further they rise, and how long one rise and fall takes.
const FLOAT_LIFT := 0.1
const FLOAT_HEIGHT := 0.14
const FLOAT_SECONDS := 2.6
## The booth: how high the riser under it is, how much bigger than usual it is, the riser's
## footprint, and the House's rail along its front edge, how tall and how deep.
const RISER_HEIGHT := 1.6
const BOOTH_SCALE := 1.5
const RISER_SIZE := Vector2(10.5, 4.4)
const RISER_LIP := Vector2(0.45, 0.5)
## The board behind the booth that says who won: how far behind the booth it stands and how much
## bigger it is than a hoarding over the crowd.
const BOARD_BEHIND := 4.2
const BOARD_SCALE := 1.7
## The ticket the board's face is, GAME.md 8.1a, in the board's own meters: its size, a little
## over the frame it hangs in, so its punched corners show; how deep they are, and how thick it
## is; the perforation under its header, how far down and how deep the bite out of either side,
## and its holes, how far apart and how big; and the hairline inside each part, how far in and how
## wide, and what the header's words and the winner's name stand at the most.
const TICKET := Vector2(6.1, 2.7)
const TICKET_NOTCH := 0.2
const TICKET_THICK := 0.03
const PERFORATION := 0.74
const BITE := 0.12
const HOLE_GAP := 0.1
const HOLE := 0.032
const TICKET_LINE_IN := 0.2
const TICKET_LINE := 0.035
const HEADER_SIZE := 0.24
const NAME_SIZE := 0.7
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
## How long the room holds its breath before the drop at the least: it drops on the first bar of
## the music after that. And the rise under it: the nitro swell, slowed and deepened, played so
## that its loudest, [constant RISER_PEAK] seconds into it at its own speed, lands on the drop.
const HUSH_SECONDS := 1.7
const RISER_PITCH := 0.75
const RISER_PEAK := 1.27
const RISER_DB := -3.0
## Confetti off the steps, a burst every so often in one of the three colors after one off every
## step on the drop; how long the fireworks keep going, which is longer than anybody reads the
## standings for; and how far behind the board and how wide they go up.
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
## How high each of [member _karts] stands, its step's top, and the color of its step's hairline:
## in team play several share a step.
var _standing_on: Array[float] = []
var _tints: Array[Color] = []
var _colors: Array[Color] = []
## What the room's party is built of, and the booth it has dressed: the crowd puts its booth up
## again whenever it stands the house up again, and the new one is dressed in turn.
var _dress: PartyDress
var _booth: Node3D
## Where each tile of the dance floor lies, the tile's own mesh, and the floor's lit tiles in each
## of the three colors, a mesh each, laid again on every beat.
var _tile_spots: Array[Vector3] = []
var _plate: PrimitiveMesh
var _lit_tiles: Array[MeshInstance3D] = []
var _beat := -1
var _age := 0.0
var _confetti_left := 0.0
var _drop_at := HUSH_SECONDS
var _smoke: Array[SmokeMachine] = []
var _rising := false
var _dropped := false
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
	finale._hush_the_room()
	finale._take_the_shot()
	return finale


## Whether the camera has arrived and the standings are up.
func is_shown() -> bool:
	return _shown


## Whether the room has dropped yet.
func has_dropped() -> bool:
	return _dropped


## Skips the camera's move for a player who has seen it, straight to the drop and the standings.
func skip() -> void:
	_age = maxf(_age, PAN_SECONDS + HOLD_SECONDS)


func _unhandled_input(event: InputEvent) -> void:
	if not _shown and event.is_action_pressed(&"ui_accept"):
		skip()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	# Gone before it dropped, back to a lobby or into a rematch: the music comes back regardless.
	if not _dropped:
		Audio.hush_music(false)


func _process(delta: float) -> void:
	_age += delta
	if crowd != null and not is_instance_valid(_booth):
		_dress_the_booth()
	# Each a third of a rise behind the one before, so the three never move as one.
	for i: int in _karts.size():
		var rise := 0.5 - 0.5 * cos(TAU * (_age / FLOAT_SECONDS - float(i) / 3.0))
		_karts[i].position.y = _standing_on[i] + TOP_LIFT + FLOAT_LIFT + rise * FLOAT_HEIGHT
	if not _rising and not _dropped and _age >= _drop_at - RISER_PEAK / RISER_PITCH:
		_rising = true
		Audio.play_sfx(&"nitro_swell", RISER_DB, 0.0, RISER_PITCH)
		for machine: SmokeMachine in _smoke:
			machine.spit(true)
	if not _dropped and _age >= _drop_at:
		_drop()
	if _dropped:
		_confetti_left -= delta
		if _confetti_left <= 0.0 and not _karts.is_empty():
			_confetti_left = CONFETTI_EVERY
			_confetti(_rng.randi() % _karts.size(), 1.1, 18)
		_light_the_floor()
	var t := smoothstep(0.0, 1.0, clampf(_age / PAN_SECONDS, 0.0, 1.0))
	if _camera != null:
		_camera.global_transform = _from.interpolate_with(_to, t)
	if not _shown and _age >= PAN_SECONDS + HOLD_SECONDS:
		_shown = true
		if _done.is_valid():
			_done.call()


## Every beat of the music the dance floor lights again, a different few tiles in each of the
## three colors: the lit tiles of each color laid again into the one mesh that color has.
func _light_the_floor() -> void:
	var beat := Audio.music_beat_index()
	if beat == _beat or _lit_tiles.is_empty():
		return
	_beat = beat
	var tools: Array[SurfaceTool] = []
	var used: Array[bool] = []
	for i: int in _lit_tiles.size():
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools.append(tool)
		used.append(false)
	for at: Vector3 in _tile_spots:
		if _rng.randf() >= TILES_LIT:
			continue
		var color := _rng.randi() % tools.size()
		var share := 1.0 if _dress.round else LAMP
		var lamp := Transform3D(
			Basis.from_scale(Vector3(share, 1.0, share)), at + Vector3.UP * 0.003
		)
		tools[color].append_from(_plate, 0, lamp)
		used[color] = true
	for i: int in _lit_tiles.size():
		_lit_tiles[i].mesh = tools[i].commit() if used[i] else null


## The room: the floor, the table round it, the crowd and the booth on its riser, the podium and
## the three on it, the board behind the booth, the disco rig, the room's lamp over the floor and
## a light on the podium.
func _build(standings: Array[PlayerSlot]) -> void:
	var room := match_node.arena.room if match_node.arena != null else RoomLook.fallback()
	var sides := Teams.sides_of(standings)
	var shown := mini(sides.size(), PLACES.size())
	for place: int in shown:
		_colors.append((sides[place][0] as PlayerSlot).color())
	# The arena's own surfaces rather than a fresh set, GAME.md 10.7: the arena turns the culling
	# off on its table's wood, so a fresh set's wood is a shader of its own, compiled the first
	# time a Grand Prix ends and nowhere else. And its style, which lends the party its materials.
	var surfaces := match_node.arena.surfaces if match_node.arena != null else Surfaces.new(room)
	_dress = PartyDress.of(room, surfaces)
	_lay_the_floor(surfaces)
	_rail_the_floor()
	_place_the_smoke()
	crowd = Crowd.add_to(self, FLOOR_SIZE, room, RISER_HEIGHT, BOOTH_SCALE)
	_raise_the_riser()
	_dress_the_booth()
	var podium := Node3D.new()
	podium.name = "Podium"
	podium.position = Vector3(0.0, 0.0, PODIUM_Z)
	add_child(podium)
	# The steps are built apart from the karts on them and baked into a mesh for each material.
	var steps := Node3D.new()
	steps.name = "Steps"
	podium.add_child(steps)
	var widths: Array[float] = []
	for place: int in shown:
		widths.append(
			ResultsPodium.step_width((sides[place] as Array).size(), STEP_SIZE.x, KART_ROOM)
		)
	var across := ResultsPodium.spread(widths, STEP_GAP)
	var reach := 0.0
	for place: int in shown:
		_add_step(podium, steps, sides[place], place, across[place], widths[place])
		reach = maxf(reach, absf(across[place]) + widths[place] * 0.5)
	Bake.merge(steps)
	# A podium of teams too wide for the room between the smoke machines is drawn smaller, GAME.md
	# 3.14, rather than standing in their smoke.
	podium.scale = Vector3.ONE * minf(1.0, PODIUM_ROOM / maxf(reach * 2.0, 0.001))
	if shown > 0:
		_raise_the_board(standings[0], room)
	_throw_the_party(room, surfaces)
	disco = DiscoLights.new()
	disco.name = "DiscoLights"
	add_child(disco)
	# The rig walks through the three colors on the podium rather than its own.
	disco.setup(FLOOR_SIZE, PackedColorArray(_colors))
	_move_the_front_row()
	_hang_the_lamp(room)
	var spot := SpotLight3D.new()
	spot.name = "Spot"
	spot.light_color = Color(1.0, 0.94, 0.82)
	spot.light_energy = 6.0
	spot.spot_range = 18.0
	spot.spot_angle = 30.0
	spot.position = Vector3(0.0, 10.0, PODIUM_Z + 5.0)
	add_child(spot)
	spot.look_at(global_position + Vector3(0.0, 1.0, PODIUM_Z), Vector3.UP)


## The hall round the party, GAME.md 9.7: its walls and rigging, see [PartyHall], what the House
## sets out among the crowd, see [PartyFurniture], and what the room brings, see [PartyRoom]; none
## of it casting a shadow, and all of it baked together into a mesh for each of its few materials.
func _throw_the_party(room: RoomLook, surfaces: Surfaces) -> void:
	var hall := PartyHall.new(self, _dress, room, surfaces, _colors, _the_run()).raise()
	PartyFurniture.new(self, _dress, surfaces, crowd, _colors).set_out(hall)
	PartyRoom.new(self, _dress, room, surfaces).bring_in(hall)
	var parts: Array[Node] = hall.find_children("*", "GeometryInstance3D", true, false)
	for part: Node in parts:
		(part as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Bake.merge(hall)


## Every map of the run so far as [code][name, winner's name, winner's color][/code], for the
## hall's banners: the side that came first on it, the first of them where a team won it.
func _the_run() -> Array[Array]:
	var maps: Array[Array] = []
	var run := Game.grand_prix
	if run == null:
		return maps
	for i: int in mini(run.playlist.size(), run.scored_round + 1):
		var name := ArenaMaps.NAMES[ArenaMaps.index_of(run.playlist[i])]
		var winner: PlayerSlot = null
		for slot: PlayerSlot in match_node.slots:
			var places: Array = run.places.get(slot.index, [])
			if i < places.size() and places[i] == 1:
				winner = slot
				break
		if winner == null:
			maps.append([name, "", HousePieces.FOIL])
		else:
			maps.append([name, Teams.called(winner), winner.color()])
	return maps


## The room's own lamp over the dance floor, as over its table, GAME.md 8.1, so the party is lit
## the way the room it is in is: a warm pool in the Workbench, the Arcade's lamp over its machine.
## Without its shadows, and none in a room lit by daylight, whose sun lights the party already.
func _hang_the_lamp(room: RoomLook) -> void:
	if room.lamp_energy <= 0.0:
		return
	var lamp := SpotLight3D.new()
	lamp.name = "Lamp"
	lamp.light_color = room.lamp_color
	lamp.light_energy = room.lamp_energy
	lamp.spot_range = room.lamp_reach
	var height := maxf(room.lamp_height, 1.0)
	var corner := rad_to_deg(atan((FLOOR_SIZE * 0.5).length() / height))
	lamp.spot_angle = minf(maxf(room.lamp_angle, corner + ArenaEnvironment.LAMP_SPARE), 89.0)
	lamp.spot_angle_attenuation = room.lamp_fade
	lamp.position = Vector3(0.0, height, 0.0)
	lamp.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(lamp)


## The rig's row along the front of the floor stands a little further toward the camera than the
## rig puts it, out of the shot: at the floor's edge its middle lamp stood on its post between the
## camera and the podium. And that middle one a step aside, off the House's runner, see
## [PartyHall]. Each head is aimed from where it stands every frame, so it is only moved.
func _move_the_front_row() -> void:
	var middle := DiscoLights.COUNT / 2 + 1
	for i: int in range(DiscoLights.COUNT / 2, DiscoLights.COUNT):
		for part: String in ["Post%d" % i, "Head%d" % i]:
			var node := disco.get_node_or_null(NodePath(part)) as Node3D
			if node != null:
				node.position.z += RIG_FORWARD
				if i == middle:
					node.position.x += RIG_ASIDE


## A dance floor in the room's own floor color with its tiles let into it a shade off it, the way
## the House lets its pads into a table, GAME.md 8.1c, all of it one mesh; and over it a mesh for
## each of the three colors the lit tiles are laid into on the beat. On the room's own table, which
## runs out under the crowd.
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
	var base := BoxMesh.new()
	base.size = Vector3(FLOOR_SIZE.x, Arena.FLOOR_THICKNESS, FLOOR_SIZE.y)
	var under := Vector3(0.0, -Arena.FLOOR_THICKNESS * 0.5, 0.0)
	var pieces: Array[Array] = [[base, Transform3D(Basis.IDENTITY, under), _dress.ground]]
	_plate = _tile_mesh()
	var across := floori(FLOOR_SIZE.x / TILE)
	var down := floori(FLOOR_SIZE.y / TILE)
	for x: int in across:
		for z: int in down:
			var at := Vector3((x - (across - 1) * 0.5) * TILE, 0.004, (z - (down - 1) * 0.5) * TILE)
			_tile_spots.append(at)
			pieces.append([_plate, Transform3D(Basis.IDENTITY, at), _dress.tile])
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "DanceFloor"
	floor_mesh.mesh = Bake.tinted(pieces)
	floor_mesh.material_override = Bake.tinted_look(false)
	add_child(floor_mesh)
	for color: Color in _colors:
		var lit := MeshInstance3D.new()
		lit.name = "LitTiles"
		lit.material_override = HousePieces.lit(color, TILE_GLOW)
		lit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(lit)
		_lit_tiles.append(lit)


## One tile of the floor: a square, or a disc in a room whose floor lamps are round, see
## [member PartyDress.round].
func _tile_mesh() -> PrimitiveMesh:
	var across := TILE - TILE_GAP
	if not _dress.round:
		var square := PlaneMesh.new()
		square.size = Vector2.ONE * across
		return square
	var disc := CylinderMesh.new()
	disc.top_radius = across * INSERT * 0.5
	disc.bottom_radius = across * INSERT * 0.5
	disc.height = 0.004
	disc.radial_segments = 20
	disc.rings = 1
	disc.cap_bottom = false
	return disc


## The floor under the table, running on past the camera where the hall has no wall, so nowhere in
## the shot does the world stop; the hall's walls and all that stands in it are [PartyHall]'s.
func _build_the_hall(surfaces: Surfaces) -> void:
	# Just under the top of the table the crowd stands on, so the table is a platform on it.
	var ground := Crowd.TABLE_TOP - 0.02
	var depth := HALL.y + HALL_NEAR
	var table := surfaces.surround().albedo_color
	var under := MeshInstance3D.new()
	under.name = "HallFloor"
	var slab := BoxMesh.new()
	slab.size = Vector3(HALL.x * 2.0, 1.0, depth)
	under.mesh = slab
	under.material_override = surfaces.painted(table.darkened(HALL_FLOOR_SHADE))
	under.position = Vector3(0.0, ground - 0.5, (HALL_NEAR - HALL.y) * 0.5)
	under.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(under)


## The House's rail round the floor, between the dancing and the crowd, the edge of every table,
## GAME.md 8.1c: down both sides and across the front either side of the gap in front of the
## podium, a seal at the end of every run. The back is the riser's.
func _rail_the_floor() -> void:
	var rails := Node3D.new()
	rails.name = "Rail"
	add_child(rails)
	var half := FLOOR_SIZE * 0.5 + Vector2.ONE * RAIL_OUT
	var y := Crowd.TABLE_TOP + RAIL.y * 0.5
	var foot := global_position.y + Crowd.TABLE_TOP
	var side_run := FLOOR_SIZE.y + RAIL_OUT * 2.0 + RAIL.x
	var front_run := half.x - RAIL_GAP * 0.5 - RAIL.x * 0.5
	for side: float in [-1.0, 1.0]:
		var down_side := Vector3(RAIL.x, RAIL.y, side_run)
		HousePieces.rail(rails, down_side, Vector3(side * half.x, y, 0.0), foot)
		var front := Vector3(front_run, RAIL.y, RAIL.x)
		var at := Vector3(side * (RAIL_GAP * 0.5 + front_run * 0.5), y, half.y)
		HousePieces.rail(rails, front, at, foot)
	Bake.merge(rails)


## The two smoke machines, one each side of the podium and behind it, pointed down the floor.
func _place_the_smoke() -> void:
	for side: float in [-1.0, 1.0]:
		var machine := SmokeMachine.new()
		machine.name = "SmokeMachine%s" % ("Left" if side < 0.0 else "Right")
		machine.position = Vector3(side * SMOKE_AT.x, 0.0, SMOKE_AT.y)
		# Toward the camera and a little out. A machine's nozzle is along its -Z.
		machine.rotation.y = atan2(-side * sin(SMOKE_OUT), -cos(SMOKE_OUT))
		add_child(machine)
		_smoke.append(machine)


## The stage the booth stands on, at the back of the floor where the crowd puts it: the room's
## darker material, see [PartyDress], with the House's rail along its front edge as along a table's.
func _raise_the_riser() -> void:
	var z := -(FLOOR_SIZE.y * 0.5 + Crowd.BOOTH_OUT)
	var stage := Node3D.new()
	stage.name = "Riser"
	add_child(stage)
	var block := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(RISER_SIZE.x, RISER_HEIGHT, RISER_SIZE.y)
	block.mesh = box
	block.material_override = _dress.base
	block.position = Vector3(0.0, Crowd.TABLE_TOP + RISER_HEIGHT * 0.5, z)
	stage.add_child(block)
	var top := Crowd.TABLE_TOP + RISER_HEIGHT + 0.02
	var lip := Vector3(RISER_SIZE.x + 0.1, RISER_LIP.y, RISER_LIP.x)
	var front := z + RISER_SIZE.y * 0.5 - lip.z * 0.5 + 0.05
	var at := Vector3(0.0, top - lip.y * 0.5, front)
	HousePieces.rail(stage, lip, at, global_position.y + top - lip.y)
	Bake.merge(stage)


## The booth the crowd put up on the riser, dressed for the party: its desk the House's rail, its
## deck the rail's lit stock, its speakers built of what the riser is with the room's metal for
## their cones, see [PartyDress]. The crowd still keeps it dancing on the beat.
func _dress_the_booth() -> void:
	var booth := crowd.get_node_or_null(^"DjBooth") as Node3D
	_booth = booth
	if booth == null:
		return
	for child: Node in booth.get_children():
		var part := child as MeshInstance3D
		if part != null:
			var box := part.mesh as BoxMesh
			if box != null and box.size.y > PIPING * 4.0:
				# The desk.
				part.visible = false
				var foot := (
					booth.global_position.y + (part.position.y - box.size.y * 0.5) * BOOTH_SCALE
				)
				# In a node of its own, baked apart from the speakers the crowd keeps moving.
				var desk := Node3D.new()
				desk.name = "Desk"
				booth.add_child(desk)
				HousePieces.rail(desk, box.size, part.position, foot, BOOTH_SCALE)
				Bake.merge(desk)
			elif box != null:
				part.material_override = HousePieces.lit_stock()
			continue
		# A speaker, its cabinet and its cone; the one behind the decks is left as they are.
		for piece: Node in child.get_children():
			var mesh := piece as MeshInstance3D
			if mesh == null:
				continue
			if mesh.mesh is CylinderMesh:
				mesh.material_override = _dress.metal
			elif mesh.mesh is BoxMesh:
				mesh.material_override = _dress.base


## A hoarding of the room's own kind behind the booth, GAME.md 8.1, bigger than the ones over a
## crowd and facing the floor, its face a ticket of the House's, see [method _print_the_ticket]:
## GRAND PRIX CHAMPION, and the winner's name in their color under it. A sign rather than words
## hanging in the air, so it is part of the room.
func _raise_the_board(winner: PlayerSlot, room: RoomLook) -> void:
	var z := -(FLOOR_SIZE.y * 0.5 + Crowd.BOOTH_OUT + BOARD_BEHIND)
	var at := global_position + Vector3(0.0, Crowd.TABLE_TOP, z)
	var toward := global_position + Vector3(0.0, 0.0, SHOT_FROM.z)
	var board := Billboard.add_to(self, at, toward, room)
	board.name = "ChampionBoard"
	board.scale = Vector3.ONE * BOARD_SCALE
	_print_the_ticket(board, winner)
	var width := Billboard.WIDTH * BOARD_SCALE + 1.0
	crowd.keep_clear(Rect2(-width * 0.5, z - 1.8, width, 3.6))


## The board's face as one of the House's tickets, GAME.md 8.1a, over the blank one it had: its
## stock with its corners punched, the header framed in foil and GRAND PRIX CHAMPION in foil in it,
## a perforation under the header with a bite out of either side, and the body under it framed in
## the winner's color, their name in it in their color, since the body is about them.
func _print_the_ticket(board: Billboard, winner: PlayerSlot) -> void:
	for blank: Node in board.face.get_children():
		(blank as Node3D).visible = false
	var ticket := Node3D.new()
	ticket.name = "Ticket"
	board.face.add_child(ticket)
	var cut := HousePieces.ticket(TICKET, TICKET_NOTCH, TICKET_THICK, [PERFORATION], BITE)
	var pieces: Array[Array] = [[cut, HousePieces.standing(Vector3.ZERO), HouseTheme.STOCK]]
	var hole := BoxMesh.new()
	hole.size = Vector3(HOLE, HOLE, 0.004)
	var across := TICKET.x * 0.5 - BITE - HOLE_GAP
	var perforated := TICKET.y * 0.5 - PERFORATION
	var x := -across
	while x <= across:
		var on := Vector3(x, perforated, TICKET_THICK)
		pieces.append([hole, Transform3D(Basis.IDENTITY, on), TicketStyle.HOLE_INK])
		x += HOLE_GAP
	var face := MeshInstance3D.new()
	face.name = "Stock"
	face.mesh = Bake.tinted(pieces)
	face.material_override = Bake.tinted_look(false)
	ticket.add_child(face)
	var plane := HousePieces.standing(Vector3(0.0, 0.0, TICKET_THICK + 0.004))
	var inset := TICKET_LINE_IN
	var gap := BITE + TICKET_LINE * 2.0
	var head := Rect2(-TICKET.x * 0.5 + inset, -TICKET.y * 0.5 + inset, TICKET.x - inset * 2.0, 0.0)
	head.size.y = PERFORATION - gap - inset
	HousePieces.hairline(ticket, head, TICKET_LINE, HousePieces.foil(), plane)
	var body := Rect2(head.position.x, -TICKET.y * 0.5 + PERFORATION + gap, head.size.x, 0.0)
	body.size.y = TICKET.y * 0.5 - inset - body.position.y
	HousePieces.hairline(
		ticket, body, TICKET_LINE, HousePieces.lit(winner.color(), LINE_GLOW), plane
	)
	Bake.merge(ticket)
	var room := head.size.x - 0.4
	var lift := TICKET_THICK + 0.012
	var header := HousePieces.words(
		board.face, "GRAND PRIX CHAMPION", HEADER_SIZE, room, HousePieces.FOIL, lift
	)
	header.position.y = -head.get_center().y
	_champion = HousePieces.words(
		board.face, Teams.called(winner), NAME_SIZE, room, winner.color(), lift
	)
	_champion.name = "Champion"
	_champion.position.y = -body.get_center().y


## One step [param width] wide at [param x] with [param side]'s karts over it, GAME.md 9.7: a
## block of the room's own, see [PartyDress], the room's metal piped round its top and a ticket of
## the room's color laid on it with a hairline of the step's color inside its edge; and on its
## front a plaque, a ticket of the House's stock with the same hairline and the place in foil. The
## step is built under [param steps], which is baked, and the karts under [param podium].
func _add_step(
	podium: Node3D, steps: Node3D, side: Array, place: int, x: float, width: float
) -> void:
	var at := Vector2(x, PLACES[place].y)
	var first: PlayerSlot = side[0]
	var color := first.color()
	var step := Node3D.new()
	step.name = "Step%d" % place
	step.position = Vector3(at.x, 0.0, 0.0)
	steps.add_child(step)
	var high := at.y - CAP
	var block := Vector3(width - CAP_NOTCH * 2.0, high, STEP_SIZE.y - CAP_NOTCH * 2.0)
	_part(step, block, _dress.body, Vector3(0.0, high * 0.5, 0.0))
	var piping := block + Vector3(0.04, 0.0, 0.04)
	piping.y = PIPING
	_part(step, piping, _dress.trim, Vector3(0.0, high - PIPING * 0.5 + 0.01, 0.0))
	var cap := HousePieces.ticket(Vector2(width, STEP_SIZE.y), CAP_NOTCH, CAP)
	var front := block.z * 0.5
	var plaque := HousePieces.ticket(PLAQUE, PLAQUE_NOTCH, PLAQUE_THICK)
	var on_front := HousePieces.standing(Vector3(0.0, high * 0.5, front))
	var top_at := Transform3D(Basis.IDENTITY, Vector3(0.0, high, 0.0))
	var pieces: Array[Array] = [
		[cap, top_at, _dress.cap], [plaque, on_front, HouseTheme.STOCK_RAISED]
	]
	var cut := MeshInstance3D.new()
	cut.mesh = Bake.tinted(pieces)
	cut.material_override = Bake.tinted_look(false)
	step.add_child(cut)
	var line := HousePieces.lit(color, LINE_GLOW)
	var top := Rect2(-width * 0.5, -STEP_SIZE.y * 0.5, width, STEP_SIZE.y).grow(-LINE_IN)
	HousePieces.hairline(step, top, LINE, line, Transform3D(Basis.IDENTITY, Vector3.UP * at.y))
	var framed := Rect2(-PLAQUE * 0.5, PLAQUE).grow(-PLAQUE_LINE_IN)
	var over := on_front * Transform3D(Basis.IDENTITY, Vector3.UP * (PLAQUE_THICK + 0.004))
	HousePieces.hairline(step, framed, PLAQUE_LINE, line, over)
	var number := Label3D.new()
	number.text = str(place + 1)
	number.font = Type.display_font()
	number.font_size = 180
	number.pixel_size = NUMBER_HEIGHT / Type.CAP_HEIGHT / float(number.font_size)
	number.modulate = HousePieces.FOIL
	number.outline_size = 0
	number.double_sided = false
	number.position = Vector3(at.x, high * 0.5, front + PLAQUE_THICK + 0.01)
	podium.add_child(number)
	for k: int in side.size():
		var slot: PlayerSlot = side[k]
		var kart := Node3D.new()
		kart.name = "Kart%d_%d" % [place, k]
		var along := at.x + (float(k) - float(side.size() - 1) * 0.5) * KART_ROOM
		kart.position = Vector3(along, at.y + TOP_LIFT + FLOAT_LIFT, 0.0)
		kart.scale = Vector3.ONE * KART_SCALE
		# Nose toward where the camera ends up. A kart's nose is along its -Z.
		var toward := Vector2(SHOT_FROM.x - along, SHOT_FROM.z - PODIUM_Z)
		kart.rotation.y = atan2(-toward.x, -toward.y)
		kart.add_child(KartVisuals.display_model(slot.paint_index(), slot.style))
		podium.add_child(kart)
		_karts.append(kart)
		_standing_on.append(at.y)
		_tints.append(color)


## A box of [param size] in [param skin] with its middle at [param at] under [param into].
func _part(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)


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


## The room holding its breath before the drop: the music muffled, the crowd and the DJ still, the
## floor dark and one light drifting over it. The meter is already at the top, so what comes back
## is the full track and a crowd on its feet.
func _hush_the_room() -> void:
	match_node.intensity.level = MatchIntensity.LEVELS
	match_node.intensity.value = 1.0
	crowd.level = MatchIntensity.LEVELS
	crowd.still = true
	disco.level = 1
	Audio.duck_music(false)
	Audio.hush_music(true)
	_drop_at = Audio.seconds_to_bar(HUSH_SECONDS)


## The drop, the room at the top of its meter for the party, GAME.md 8.4: the music swept open to
## its loudest, the crowd dancing, the floor lit, the lights on the winner, confetti off every step
## and fireworks in all three colors behind the board.
func _drop() -> void:
	_dropped = true
	Audio.hush_music(false)
	for machine: SmokeMachine in _smoke:
		machine.spit(false)
	crowd.still = false
	disco.level = MatchIntensity.LEVELS
	if not _karts.is_empty():
		disco.focus(_karts[0])
	Audio.play_sfx(&"fanfare", -4.0, 0.0)
	for index: int in _karts.size():
		_confetti(index, 1.6, 36)
	_confetti_left = CONFETTI_EVERY
	var span := Vector3(FIREWORKS_SPAN.x, 1.0, FIREWORKS_SPAN.y)
	var behind := FLOOR_SIZE.y * 0.5 + Crowd.BOOTH_OUT + BOARD_BEHIND + FIREWORKS_BEHIND
	var sky := AABB(global_position + Vector3(0.0, 0.0, -behind) - span * 0.5, span)
	for color: Color in _colors:
		Fireworks.celebrate(self, sky, color, FIREWORK_SECONDS)


## A burst of confetti off the step of [member _karts]' [param index], in its color.
func _confetti(index: int, size: float, count: int) -> void:
	var over := _karts[index].global_position + Vector3(0.0, 1.2, 0.0)
	Burst.spawn(self, over, _tints[index], size, count)


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
