class_name PartyHall
extends RefCounted
## The hall the House's party at the end of a Grand Prix is thrown in, GAME.md 9.7: the room's own
## walls round the table the crowd stands on, the room's material up to a dado of the House's rail
## and its wall's finish over that, with lit doorways in them; the rigging the party's lights hang
## from, a truss over the board and down both sides with lamps in the top three's colors under it;
## bunting strung across under it in the three colors and the House's gold; and a banner on the back
## wall for every map of the run, its name in foil and the winner of it in their color. What the
## party sets out among the crowd is [PartyFurniture]'s, and what the room brings [PartyRoom]'s.
##
## Few materials: plain paint, the House's stock and foil, the rail's print and the room's own
## materials, so the hall draws in shaders the room has compiled already, GAME.md 10.7, and the
## whole of it, with what is set out in it, baked into a mesh for each.

## The inside faces of the walls, the edges of the table the crowd stands on, and how far toward
## the camera the side walls run past its near edge; how tall and thick they are.
const HALF := Vector2(23.0, 19.0)
const FRONT := 27.0
const HIGH := 15.0
const THICK := 0.6
## The room's material along the foot of the walls, how high and how far it stands out, and the
## House's rail along its top as a dado, how deep and how tall.
const WAINSCOT := 1.1
const WAINSCOT_DEEP := 0.22
const DADO := Vector2(0.34, 0.3)
## The doorways, a pair in each side wall: how wide and tall, how thick their frames are, how
## brightly the room past them is lit, and where they stand.
const DOOR := Vector2(1.4, 2.2)
const DOOR_FRAME := 0.16
const DOOR_GLOW := 0.22
const SIDE_DOORS: Array[float] = [-12.0, 2.5]
## The lamps along the side walls between the doors, where they hang, how high, and how big their
## lit shades are, so a dark room's walls are seen in their own light.
const SCONCES: Array[float] = [-16.5, -5.0, 9.0, 17.5]
const SCONCE_HIGH := 4.4
const SCONCE := Vector3(0.6, 0.3, 0.3)
const SCONCE_GLOW := 0.9
## The House's runner from the gap in the rail toward the camera: how wide, how far it runs, and the
## foil along its edges.
const RUNNER := Vector2(2.6, 13.0)
const RUNNER_EDGE := 0.08
const RUNNER_FROM := 5.7
## The rigging: where its four towers stand, how high its trusses run, how thick a truss is, its
## chords and its lacing and how far apart the lacing's zigzag goes; and the lamps under it, how
## many across the back and along each side, how big and how brightly lit.
const RIG := Vector2(13.5, 0.0)
const RIG_BACK := -12.6
const RIG_FRONT := 9.0
const RIG_HIGH := 12.0
const TRUSS := 0.5
const CHORD := 0.06
const LACE := 1.0
const CANS_ACROSS := 6
const CANS_ALONG := 4
const CAN := Vector2(0.16, 0.34)
const CAN_GLOW := 1.4
const RIG_INK := Color("#26252B")
## Bunting strung across under the rigging: where each string crosses, how far it sags, and its
## pennants, how big and how far apart.
const SWAGS: Array[float] = [-9.6, -4.2]
const SAG := 0.9
const PENNANT := Vector2(0.36, 0.46)
const PENNANT_GAP := 0.62
## The banners naming the run on the back wall: how big, how high their foot is, where the first
## hangs out from the middle and how far apart the rest are; their corners, how far down their
## perforation is and how deep its bites, and their hairlines.
const BANNER := Vector2(2.6, 5.2)
const BANNER_LIFT := 3.9
const BANNER_FIRST := 10.6
const BANNER_GAP := 3.7
const BANNER_NOTCH := 0.18
const BANNER_HEAD := 0.62
const BANNER_BITE := 0.1
const BANNER_LINE_IN := 0.18
const BANNER_LINE := 0.03

var finale: GrandPrixFinale
var dress: PartyDress
var room: RoomLook
var surfaces: Surfaces
## The colors of the top three, best first.
var colors: Array[Color] = []
## The run, a [code][map name, winner's name, winner's color][/code] for every map of it.
var run: Array[Array] = []

var _hall: Node3D
## Everything of the hall in plain paint, baked into a mesh of plain paint and one of metal with its
## colors on its vertices once the hall is up, see [method Bake.tint].
var _plain: Node3D
var _paints: Dictionary[String, StandardMaterial3D] = {}


func _init(
	for_finale: GrandPrixFinale,
	party_dress: PartyDress,
	in_room: RoomLook,
	room_surfaces: Surfaces,
	top_three: Array[Color],
	maps: Array[Array]
) -> void:
	finale = for_finale
	dress = party_dress
	room = in_room
	surfaces = room_surfaces
	colors = top_three
	run = maps


## Puts the hall up round the party, and returns it, to be baked once everything else the party
## puts in it is in, see [method GrandPrixFinale._throw_the_party].
func raise() -> Node3D:
	_hall = Node3D.new()
	_hall.name = "Hall"
	finale.add_child(_hall)
	_plain = _group("Plain")
	_walls()
	_doorways()
	_sconces()
	_runner()
	_rigging()
	_bunting()
	_banners()
	Bake.tint(_plain)
	return _hall


## The walls at the table's edges, open on the near side where the camera comes in: the room's wall
## finish, the room's darker material along their foot and the House's rail along its top.
func _walls() -> void:
	var walls := _group("Walls")
	var foot := Crowd.TABLE_TOP
	var finish := surfaces.painted(dress.hall_wall)
	var long := HALF.y + FRONT
	var middle_z := (FRONT - HALF.y) * 0.5
	var up := foot + HIGH * 0.5
	_box(
		walls,
		Vector3(HALF.x * 2.0 + THICK * 2.0, HIGH, THICK),
		finish,
		Vector3(0.0, up, -HALF.y - THICK * 0.5)
	)
	for side: float in [-1.0, 1.0]:
		_box(
			walls,
			Vector3(THICK, HIGH, long),
			finish,
			Vector3(side * (HALF.x + THICK * 0.5), up, middle_z)
		)
	# The room's material along the foot, and the House's rail along its top.
	var low := foot + WAINSCOT * 0.5
	var out := WAINSCOT_DEEP * 0.5
	_box(
		walls,
		Vector3(HALF.x * 2.0, WAINSCOT, WAINSCOT_DEEP),
		dress.base,
		Vector3(0.0, low, -HALF.y + out)
	)
	var rail_y := foot + WAINSCOT + DADO.y * 0.5
	var world := finale.global_position.y + foot + WAINSCOT
	var across := Vector3(HALF.x * 2.0, DADO.y, DADO.x)
	HousePieces.rail(walls, across, Vector3(0.0, rail_y, -HALF.y + DADO.x * 0.5), world)
	for side: float in [-1.0, 1.0]:
		var run_z := long - WAINSCOT_DEEP
		var at := Vector3(side * (HALF.x - out), low, middle_z + WAINSCOT_DEEP * 0.5)
		_box(walls, Vector3(WAINSCOT_DEEP, WAINSCOT, run_z), dress.base, at)
		var down := Vector3(DADO.x, DADO.y, run_z - DADO.x)
		var on := Vector3(side * (HALF.x - DADO.x * 0.5), rail_y, middle_z + DADO.x * 0.5)
		HousePieces.rail(walls, down, on, world)


## Doorways into lit rooms past the hall: a frame of the room's metal round an opening the room's
## lamp-light comes through, a pair in each side wall. The back wall's corners are the room's own
## things', see [PartyRoom].
func _doorways() -> void:
	var doors := _group("Doorways")
	var light := _lamplight(DOOR_GLOW)
	var foot := Crowd.TABLE_TOP
	for side: float in [-1.0, 1.0]:
		for z: float in SIDE_DOORS:
			var face := side * (HALF.x - DADO.x - 0.02)
			_door(doors, Vector3(face, foot, z), Vector3(-side, 0.0, 0.0), light)


## One doorway standing at [param foot] on a wall, facing [param facing].
func _door(into: Node3D, foot: Vector3, facing: Vector3, light: Material) -> void:
	var door := Node3D.new()
	into.add_child(door)
	door.position = foot
	door.basis = Basis.looking_at(-facing, Vector3.UP)
	var frame := DOOR_FRAME
	var opening := Vector3(DOOR.x, DOOR.y, 0.04)
	_box(door, opening, light, Vector3(0.0, DOOR.y * 0.5, 0.0))
	for side: float in [-1.0, 1.0]:
		var jamb := Vector3(frame, DOOR.y + frame, frame)
		_box(door, jamb, dress.trim, Vector3(side * (DOOR.x + frame) * 0.5, jamb.y * 0.5, 0.04))
	var lintel := Vector3(DOOR.x + frame * 2.0, frame, frame)
	_box(door, lintel, dress.trim, Vector3(0.0, DOOR.y + frame * 0.5, 0.04))


## A lamp on each side wall between and either side of the doors: a foil plate on the wall and a
## shade over it lit in the room's lamp-light.
func _sconces() -> void:
	var lamps := _group("Sconces")
	var light := _lamplight(SCONCE_GLOW)
	var y := Crowd.TABLE_TOP + SCONCE_HIGH
	for side: float in [-1.0, 1.0]:
		for z: float in SCONCES:
			var wall := side * HALF.x
			var plate := Vector3(0.04, 0.7, 0.32)
			_box(lamps, plate, HousePieces.foil(), Vector3(wall - side * 0.02, y - 0.1, z))
			var shade := Vector3(SCONCE.z, SCONCE.y, SCONCE.x)
			_box(lamps, shade, light, Vector3(wall - side * (SCONCE.z * 0.5 + 0.04), y, z))


## The House's runner from the gap in the rail in front of the podium out toward the camera, the way
## in, in its stock edged in foil; the crowd stands either side of it.
func _runner() -> void:
	var runner := _plain
	var near := RUNNER_FROM
	var middle := Vector3(0.0, Crowd.TABLE_TOP + 0.01, near + RUNNER.y * 0.5)
	_box(
		runner, Vector3(RUNNER.x, 0.02, RUNNER.y), _paint(HouseTheme.STOCK_RAISED, 0.7, 0.0), middle
	)
	for side: float in [-1.0, 1.0]:
		var edge := Vector3(RUNNER_EDGE, 0.024, RUNNER.y)
		var at := middle + Vector3(side * (RUNNER.x * 0.5 - RUNNER_EDGE * 1.5), 0.0, 0.0)
		_box(runner, edge, HousePieces.foil(), at)
	var clear := Vector2(RUNNER.x + 0.6, RUNNER.y)
	finale.crowd.keep_clear(Rect2(Vector2(-clear.x * 0.5, near), clear))


## The rigging the party's lights hang from: a truss over the board between two towers, a truss
## down each side to a tower near the front, and lamps under them in the top three's colors.
func _rigging() -> void:
	var rig := _plain
	var steel := _paint(RIG_INK, 0.4, 0.6)
	var foot := Crowd.TABLE_TOP
	var top := RIG_HIGH + TRUSS * 0.5
	var corners: Array[Vector3] = []
	for z: float in [RIG_BACK, RIG_FRONT]:
		for side: float in [-1.0, 1.0]:
			corners.append(Vector3(side * RIG.x, 0.0, z))
	for corner: Vector3 in corners:
		_truss(rig, corner + Vector3.UP * foot, corner + Vector3.UP * top, steel)
		_box(rig, Vector3(1.0, 0.08, 1.0), steel, corner + Vector3.UP * (foot + 0.04))
		finale.crowd.keep_clear(Rect2(corner.x - 0.7, corner.z - 0.7, 1.4, 1.4))
	var back_left := Vector3(-RIG.x, RIG_HIGH, RIG_BACK)
	_truss(rig, back_left, Vector3(RIG.x, RIG_HIGH, RIG_BACK), steel)
	for side: float in [-1.0, 1.0]:
		var back := Vector3(side * RIG.x, RIG_HIGH, RIG_BACK)
		_truss(rig, back, Vector3(side * RIG.x, RIG_HIGH, RIG_FRONT), steel)
	var cans := _group("Lamps")
	var body := _paint(RIG_INK, 0.5, 0.0)
	var under := RIG_HIGH - TRUSS * 0.5 - CAN.y * 0.5
	var spots: Array[Vector3] = []
	for i: int in CANS_ACROSS:
		var x := lerpf(-RIG.x, RIG.x, (float(i) + 0.5) / float(CANS_ACROSS))
		spots.append(Vector3(x, under, RIG_BACK))
	for side: float in [-1.0, 1.0]:
		for i: int in CANS_ALONG:
			var z := lerpf(RIG_BACK, RIG_FRONT, (float(i) + 1.0) / float(CANS_ALONG + 1))
			spots.append(Vector3(side * RIG.x, under, z))
	for i: int in spots.size():
		var ink := colors[i % colors.size()] if not colors.is_empty() else HousePieces.FOIL
		_cylinder(_plain, CAN.x, CAN.y, body, spots[i])
		_cylinder(
			cans,
			CAN.x * 0.8,
			0.02,
			HousePieces.lit(ink, CAN_GLOW),
			spots[i] - Vector3.UP * CAN.y * 0.5
		)


## A square truss from [param from] to [param to], its four chords and a zigzag of lacing down two
## opposite faces of it, all of [param steel].
func _truss(into: Node3D, from: Vector3, to: Vector3, steel: Material) -> void:
	var along := (to - from).normalized()
	var across := Vector3.UP.cross(along).normalized()
	if across.length() < 0.5:
		across = Vector3.RIGHT
	var up := along.cross(across).normalized()
	var half := TRUSS * 0.5 - CHORD * 0.5
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			var shift := across * a * half + up * b * half
			_rod(into, from + shift, to + shift, CHORD, steel)
	var length := from.distance_to(to)
	var steps := maxi(roundi(length / LACE), 1)
	for face: float in [-1.0, 1.0]:
		for i: int in steps:
			var low := float(i) / float(steps)
			var high := float(i + 1) / float(steps)
			var side := across * face * half
			var a := from.lerp(to, low) + side + up * half * (1.0 if i % 2 == 0 else -1.0)
			var b := from.lerp(to, high) + side + up * half * (-1.0 if i % 2 == 0 else 1.0)
			_rod(into, a, b, CHORD * 0.6, steel)


## Bunting strung across the hall under the rigging, sagging between the side trusses: pennants in
## the top three's colors and the House's gold in turn on a dark cord.
func _bunting() -> void:
	var strings := _plain
	var cord := _paint(RIG_INK, 0.6, 0.0)
	var inks: Array[Color] = colors.duplicate()
	inks.append(HousePieces.FOIL)
	var flag := _pennant()
	var hang := RIG_HIGH - TRUSS * 0.5
	var pieces: Array[Array] = []
	for z: float in SWAGS:
		var count := floori(RIG.x * 2.0 / PENNANT_GAP)
		var last := Vector3(-RIG.x, hang, z)
		for i: int in range(1, count + 1):
			var t := float(i) / float(count + 1)
			var x := lerpf(-RIG.x, RIG.x, t)
			var at := Vector3(x, hang - SAG * 4.0 * t * (1.0 - t), z)
			_rod(strings, last, at, 0.02, cord)
			last = at
			var place := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), at + Vector3(0.0, 0.0, -0.005))
			pieces.append([flag, place, inks[i % inks.size()]])
		_rod(strings, last, Vector3(RIG.x, hang, z), 0.02, cord)
	# Not among the plain paint: the pennants carry their colors on their vertices already.
	var flags := MeshInstance3D.new()
	flags.name = "Pennants"
	flags.mesh = Bake.tinted(pieces)
	flags.material_override = Bake.tinted_look(false)
	flags.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hall.add_child(flags)


## One pennant, a triangle hanging point down from its cord, lying face up as
## [method RoomStyle.cutout] cuts it, its top edge toward -z.
func _pennant() -> ArrayMesh:
	var w := PENNANT.x * 0.5
	var outline := PackedVector2Array([Vector2(-w, 0.0), Vector2(w, 0.0), Vector2(0.0, PENNANT.y)])
	return RoomStyle.cutout(outline, 0.01)


## A banner on the back wall for every map of the run, nearest the board first and either side of
## it in turn, so they read in order from it: a ticket of the House's stock hung from a rod of the
## room's metal, framed in foil, the map's name in foil and under a perforation whoever won it, in
## their color.
func _banners() -> void:
	for i: int in run.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * (BANNER_FIRST + float(i / 2) * BANNER_GAP)
		var banner := Node3D.new()
		banner.name = "Banner%d" % (i + 1)
		var y := Crowd.TABLE_TOP + BANNER_LIFT + BANNER.y * 0.5
		banner.position = Vector3(x, y, -HALF.y + 0.04)
		_hall.add_child(banner)
		_banner(banner, run[i])


## The banner for a map of the run, [param map], on [param banner].
func _banner(banner: Node3D, map: Array) -> void:
	var perforation := BANNER.y * BANNER_HEAD
	var cut := HousePieces.ticket(BANNER, BANNER_NOTCH, 0.03, [perforation], BANNER_BITE)
	var stock := MeshInstance3D.new()
	stock.mesh = Bake.tinted([[cut, HousePieces.standing(Vector3.ZERO), HouseTheme.STOCK]])
	stock.material_override = Bake.tinted_look(false)
	banner.add_child(stock)
	var lines := Node3D.new()
	banner.add_child(lines)
	var plane := HousePieces.standing(Vector3(0.0, 0.0, 0.034))
	var inset := BANNER_LINE_IN
	var head := Rect2(-BANNER.x * 0.5 + inset, -BANNER.y * 0.5 + inset, BANNER.x - inset * 2.0, 0.0)
	var gap := BANNER_BITE + BANNER_LINE * 2.0
	head.size.y = perforation - gap - inset
	HousePieces.hairline(lines, head, BANNER_LINE, HousePieces.foil(), plane)
	var body := Rect2(head.position.x, -BANNER.y * 0.5 + perforation + gap, head.size.x, 0.0)
	body.size.y = BANNER.y * 0.5 - inset - body.position.y
	var winner: Color = map[2]
	HousePieces.hairline(
		lines, body, BANNER_LINE, HousePieces.lit(winner, GrandPrixFinale.LINE_GLOW), plane
	)
	_box(
		lines,
		Vector3(BANNER.x + 0.3, 0.07, 0.07),
		dress.metal,
		Vector3(0.0, BANNER.y * 0.5 + 0.04, 0.05)
	)
	var room_for := head.size.x - 0.3
	var lift := 0.045
	var foil := HousePieces.FOIL
	var called := String(map[0]).to_upper()
	var name := HousePieces.words(banner, called, 0.4, room_for, foil, lift)
	name.position.y = -head.get_center().y
	var won := HousePieces.words(banner, String(map[1]), 0.3, room_for, winner, lift)
	won.position.y = -body.get_center().y


# --- the parts ---------------------------------------------------------------


## The room's lamp-light lit at [param glow], its sun's where it has no lamp.
func _lamplight(glow: float) -> StandardMaterial3D:
	return HousePieces.lit(room.lamp_color if room.lamp_energy > 0.0 else room.key_color, glow)


func _group(called: String) -> Node3D:
	var group := Node3D.new()
	group.name = called
	_hall.add_child(group)
	return group


func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node


func _cylinder(into: Node3D, radius: float, height: float, skin: Material, at: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)


## A rod [param thick] across from [param a] to [param b].
func _rod(into: Node3D, a: Vector3, b: Vector3, thick: float, skin: Material) -> void:
	var length := a.distance_to(b)
	if length < 0.001:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thick, thick, length)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	var up := Vector3.UP if absf((b - a).normalized().y) < 0.95 else Vector3.RIGHT
	node.transform = Transform3D(Basis.looking_at(b - a, up), (a + b) * 0.5)
	into.add_child(node)


## Plain paint, one for each color and finish, so a group of it bakes together.
func _paint(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var key := "%s:%.2f:%.2f" % [color.to_html(false), roughness, metallic]
	if not _paints.has(key):
		var paint := PartyDress.plain(color, roughness)
		paint.metallic = metallic
		_paints[key] = paint
	return _paints[key]
