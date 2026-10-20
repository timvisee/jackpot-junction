class_name PartyRoom
extends RefCounted
## What the room the run ended in brings to the House's party at the end of a Grand Prix, GAME.md
## 9.7: a few of its own things in the hall's back corners, so the party is plainly that room's.
## Kit's jars and maple boxes in the Workbench; a pair of pinball machines in each corner of the
## Arcade, their backglasses lit; stacked containers and a floodlight in the Yard; High Limit's
## torchères either side of the board and the House's sealed decks; the title's gilded sunburst over
## the board and deco lamps in After Hours; and anywhere else a stack of the room's own boxes, as
## its style builds them. Built of the room's materials and colors, see [PartyDress], plain things
## baked into a mesh of plain paint and one of metal.

## The back corners of the hall, mirrored either side, where the room's things stand.
const CORNER := Vector2(19.2, -16.6)
## The room's own boxes, as the arena builds them, see [method RoomStyle.crate].
const BOX := 1.1
## Kit's jars: how big, and what is in them.
const JAR := Vector2(0.72, 2.0)
## A pinball machine: its body, how high its legs hold it, and its head.
const CABINET := Vector3(0.9, 0.5, 1.6)
const LEGS := 0.75
const HEAD := Vector3(0.9, 1.1, 0.24)
## A container of the Yard's, and its floodlight, how tall and how far in from the corner.
const CONTAINER := Vector3(4.6, 1.3, 1.3)
const MAST := 7.0
## A torchère of High Limit's: where they stand either side of the board, and how tall.
const TORCHERE := Vector2(7.4, -13.4)
const TORCHERE_HIGH := 3.4
## After Hours' sunburst over the board, how big; its deco lamps, how high.
const SUNBURST := 8.5
const PENDANT_HIGH := 8.5

var finale: GrandPrixFinale
var dress: PartyDress
var room: RoomLook
var surfaces: Surfaces

var _root: Node3D
var _bits: Node3D
var _paints: Dictionary[String, StandardMaterial3D] = {}


func _init(
	for_finale: GrandPrixFinale, party_dress: PartyDress, in_room: RoomLook, room_surfaces: Surfaces
) -> void:
	finale = for_finale
	dress = party_dress
	room = in_room
	surfaces = room_surfaces


## Brings the room's things into [param hall], whose baking bakes them.
func bring_in(hall: Node3D) -> void:
	_root = Node3D.new()
	_root.name = "RoomThings"
	hall.add_child(_root)
	_bits = Node3D.new()
	_bits.name = "Bits"
	_root.add_child(_bits)
	var style := surfaces.style
	for side: float in [-1.0, 1.0]:
		var corner := Vector3(side * CORNER.x, Crowd.TABLE_TOP, CORNER.y)
		if style is WorkbenchStyle:
			_kits_corner(style as WorkbenchStyle, corner, side)
		elif style is PinballStyle:
			_arcade_corner(corner, side)
		elif style is YardStyle:
			_yard_corner(style as YardStyle, corner, side)
		elif style is HighLimitStyle:
			_salon_corner(style as HighLimitStyle, corner, side)
		elif style is VaultStyle:
			_lounge_corner(style as VaultStyle, corner, side)
		elif style != null:
			_boxes(style, corner, side)
	if style is VaultStyle:
		_sunburst(style as VaultStyle)
	Bake.tint(_bits)


## Kit's corner: a jar of something taller than anybody, its brass lid on, beside a stack of maple
## boxes with Kit's mark burnt in, the way they stand behind the bench.
func _kits_corner(kit: WorkbenchStyle, corner: Vector3, side: float) -> void:
	_boxes(kit, corner + Vector3(side * 0.6, 0.0, -0.4), side)
	var jar := corner + Vector3(-side * 1.9, 0.0, 0.6)
	var ink: Color = WorkbenchBench.JARS[1 if side < 0.0 else 0]
	var glass := _paint(WorkbenchBench.GLASS, 0.2)
	_cylinder(_bits, JAR.x, JAR.y * 0.62, _paint(ink), jar + Vector3.UP * JAR.y * 0.34)
	_cylinder(_bits, JAR.x + 0.02, JAR.y * 0.3, glass, jar + Vector3.UP * JAR.y * 0.8)
	_cylinder(_bits, JAR.x + 0.02, 0.06, glass, jar + Vector3.UP * 0.03)
	var lid := jar + Vector3.UP * (JAR.y + 0.08)
	_cylinder(_root, JAR.x + 0.05, 0.18, kit.metal(WorkbenchStyle.BRASS), lid)


## A stack of the room's own boxes, two side by side and one over them, turned a little apiece, as
## its style builds them for its table.
func _boxes(style: RoomStyle, corner: Vector3, side: float) -> void:
	var spots: Array[Vector3] = [
		Vector3(-0.6, 0.0, 0.0), Vector3(0.6, 0.0, 0.1), Vector3(0.0, BOX, 0.05)
	]
	for spot: Vector3 in spots:
		var holder := Node3D.new()
		_root.add_child(holder)
		var size := Vector3.ONE * BOX
		if not style.crate(holder, size):
			holder.free()
			continue
		holder.position = corner + Vector3(spot.x * side, spot.y + BOX * 0.5, spot.z)


## A pair of pinball machines standing side by side in the corner, turned a little toward the
## floor: a cabinet on chrome legs, its playfield under glass with its lamps lit, and its head
## behind with the backglass lit.
func _arcade_corner(corner: Vector3, side: float) -> void:
	for k: int in 2:
		var machine := Node3D.new()
		_root.add_child(machine)
		machine.position = corner + Vector3(side * (float(k) * 1.3 - 0.4), 0.0, float(k) * 0.5)
		machine.rotation.y = side * -0.35
		_pinball(machine)


func _pinball(machine: Node3D) -> void:
	var body := _paint(PinballStyle.CABINET)
	var chrome := _paint(PinballStyle.STEEL, 0.32, 0.6)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var leg := Vector3(
				x * (CABINET.x * 0.5 - 0.06), LEGS * 0.5, z * (CABINET.z * 0.5 - 0.08)
			)
			_box(_bits_of(machine), Vector3(0.07, LEGS, 0.07), chrome, leg)
	var cabinet := Vector3(0.0, LEGS + CABINET.y * 0.5, 0.0)
	_box(_bits_of(machine), CABINET, body, cabinet)
	var side_rail := Vector3(CABINET.x + 0.04, 0.05, CABINET.z)
	_box(_bits_of(machine), side_rail, chrome, cabinet + Vector3.UP * (CABINET.y * 0.5))
	var field := Vector3(CABINET.x - 0.14, 0.02, CABINET.z - 0.14)
	_box(
		machine,
		field,
		HousePieces.lit(PinballStyle.PLUM.lerp(PinballStyle.BULB, 0.25), 0.5),
		cabinet + Vector3.UP * (CABINET.y * 0.5 + 0.02)
	)
	var head := Vector3(0.0, LEGS + CABINET.y + HEAD.y * 0.5, -CABINET.z * 0.5 + HEAD.z * 0.5)
	_box(_bits_of(machine), HEAD, body, head)
	var glass := Vector3(HEAD.x - 0.16, HEAD.y - 0.2, 0.02)
	_box(
		machine,
		glass,
		HousePieces.lit(PinballStyle.PANEL.lerp(PinballStyle.OCHRE, 0.3), 0.9),
		head + Vector3(0.0, 0.02, HEAD.z * 0.5 + 0.01)
	)


## A corner of the Yard: two containers side by side and one crosswise over them in the lines'
## paint, and a floodlight on its mast in front of them, on for the party.
func _yard_corner(yard: YardStyle, corner: Vector3, side: float) -> void:
	var inks: Array[Color] = [YardStyle.RUST, YardStyle.SLATE, YardStyle.SAGE]
	for k: int in 2:
		var at := corner + Vector3(0.0, 0.0, -0.75 + 1.45 * float(k))
		yard.container(_root, CONTAINER, at, inks[k])
	var over := Vector3(CONTAINER.z * 2.2, CONTAINER.y, CONTAINER.z)
	yard.container(
		_root,
		Vector3(over.z, over.y, over.x),
		corner + Vector3(side * 1.4, CONTAINER.y, 0.0),
		inks[2]
	)
	var mast := corner + Vector3(-side * 3.4, 0.0, 3.4)
	var steel := _paint(YardStyle.STEEL, 0.4, 0.6)
	_box(_bits, Vector3(0.18, MAST, 0.18), steel, mast + Vector3.UP * MAST * 0.5)
	_box(_bits, Vector3(1.0, 0.12, 0.6), steel, mast + Vector3.UP * 0.06)
	var head := mast + Vector3(0.0, MAST, 0.25)
	_box(_bits, Vector3(1.3, 0.7, 0.3), _paint(YardStyle.IRON), head)
	_box(
		_root,
		Vector3(1.1, 0.5, 0.04),
		HousePieces.lit(Color(1.0, 0.92, 0.78), 1.2),
		head + Vector3(0.0, 0.0, 0.16)
	)


## High Limit's corner: the House's sealed decks stacked three high; and either side of the board,
## once, a torchère of black lacquer and chrome with its ivory bowl lit.
func _salon_corner(salon: HighLimitStyle, corner: Vector3, side: float) -> void:
	for k: int in 3:
		var stack := corner + Vector3(side * (float(k) - 1.0) * 1.2, 0.0, 0.2 * float(k % 2))
		for level: int in 3 - absi(k - 1):
			salon.carton(_root, Vector3(1.0, 0.5, 0.75), stack + Vector3.UP * 0.4 * float(level))
	var foot := Vector3(side * TORCHERE.x, Crowd.TABLE_TOP, TORCHERE.y)
	_cylinder(_bits, 0.4, 0.12, _paint(HighLimitStyle.LACQUER), foot + Vector3.UP * 0.06)
	var chrome := _paint(HighLimitStyle.CHROME, 0.3, 0.7)
	_cylinder(_bits, 0.05, TORCHERE_HIGH, chrome, foot + Vector3.UP * TORCHERE_HIGH * 0.5)
	var bowl := foot + Vector3.UP * (TORCHERE_HIGH + 0.2)
	_cylinder(_bits, 0.55, 0.42, _paint(HighLimitStyle.IVORY, 0.42), bowl, 0.26)
	_cylinder(_root, 0.5, 0.04, HousePieces.lit(room.lamp_color, 0.8), bowl + Vector3.UP * 0.2)
	finale.crowd.keep_clear(Rect2(foot.x - 0.6, foot.z - 0.6, 1.2, 1.2))


## After Hours' corner: a stack of its catalin cigarette cases, and a deco lamp hung over it, a
## shade stepping up like a ziggurat in brass with its glow under it.
func _lounge_corner(deco: VaultStyle, corner: Vector3, side: float) -> void:
	_boxes(deco, corner, side)
	var brass := deco.metal(VaultStyle.BRASS)
	var lamp := corner + Vector3(-side * 2.6, PENDANT_HIGH, 2.4)
	_cylinder(_root, 0.04, 6.0, brass, lamp + Vector3.UP * 3.6)
	var tiers: Array[float] = [1.0, 0.75, 0.48]
	for i: int in tiers.size():
		_cylinder(_root, tiers[i], 0.18, brass, lamp + Vector3.UP * (0.09 + 0.18 * float(i)))
	_cylinder(_root, 0.9, 0.08, deco.neon(room.lamp_color, 0.45), lamp - Vector3.UP * 0.04)


## The title's gilded sunburst on the back wall, rising from behind the board, as After Hours has
## it over its own back wall.
func _sunburst(deco: VaultStyle) -> void:
	var fan := QuadMesh.new()
	fan.size = Vector2(SUNBURST * 2.0, SUNBURST)
	var node := MeshInstance3D.new()
	node.mesh = fan
	node.material_override = deco.gilt()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var wall := -PartyHall.HALF.y + PartyHall.DADO.x + 0.1
	node.position = Vector3(0.0, Crowd.TABLE_TOP + 2.0 + SUNBURST * 0.5, wall)
	finale.add_child(node)


# --- the parts ---------------------------------------------------------------


## Where a machine's plain parts go: a holder under the plain bits that turns as the machine does.
func _bits_of(machine: Node3D) -> Node3D:
	if machine.has_meta(&"bits"):
		return machine.get_meta(&"bits")
	var bits := Node3D.new()
	_bits.add_child(bits)
	bits.transform = machine.transform
	machine.set_meta(&"bits", bits)
	return bits


func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node


## An upright cylinder [param height] tall with its middle at [param at], [param radius] round at
## its top and [param bottom] at its foot where that is given.
func _cylinder(
	into: Node3D, radius: float, height: float, skin: Material, at: Vector3, bottom := -1.0
) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius if bottom < 0.0 else bottom
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)


## Plain paint, one for each color and finish, so the lot bakes into a mesh or two.
func _paint(color: Color, roughness := PartyDress.SATIN, metallic := 0.0) -> StandardMaterial3D:
	var key := "%s:%.2f:%.2f" % [color.to_html(false), roughness, metallic]
	if not _paints.has(key):
		var paint := PartyDress.plain(color, roughness)
		paint.metallic = metallic
		_paints[key] = paint
	return _paints[key]
