class_name GarageGear
extends RoomBuild
## What the Garage of GAME.md 9.4 has standing about it besides the clutter dealt round it, put
## down by hand at the back, where a player sees it every time they come in: a kart up on jack
## stands with its wheels off, the House's soda machine beside the bench, a compressor with its
## hose coiled on the floor, and a mechanic's creeper sticking out from under the bench. Built
## alongside [RoomProps], which keeps its clutter off the patches these stand on, see
## [member taken]. Boxes and cylinders in the room's own materials like the rest of it, baked the
## same way, GAME.md 8.1.

## Where each stands, from the middle of the back of the bay and the bench, see
## [method RoomProps._garage], in meters: the kart out past the back right corner where the bay's
## old lift stood, the soda machine at the bench's left end, the compressor at its right end with
## the hose beside it, and the creeper under the bench's left half.
const KART_OUT := Vector2(6.5, 4.0)
const SODA_AT := Vector2(-8.2, 6.6)
const COMPRESSOR_AT := Vector2(8.4, 5.4)
const HOSE_AT := Vector2(11.2, 4.4)
const CREEPER_AT := Vector2(-2.6, 5.0)
const CREEPER_TURN := 0.12

## The kart: its tray and how high the stands hold it, its wheels' size, and its paint.
const TRAY := Vector3(3.0, 0.25, 5.4)
const RAISED := 1.75
const WHEEL := 0.95
const WHEEL_WIDE := 0.75
const KART_PAINT := Color(0.32, 0.56, 0.4)
## The soda machine: its body, the House's red and the gold of its trim, see [HouseTheme].
const SODA := Vector3(2.6, 5.0, 2.0)
const SODA_RED := Color(0.42, 0.06, 0.08)
const SODA_PANEL := Color(0.97, 0.86, 0.56)
## The compressor's tank, and the paint of it.
const TANK := Vector2(0.65, 2.6)
const TANK_PAINT := Color(0.86, 0.62, 0.16)
const HOSE_RED := Color(0.72, 0.14, 0.12)
const DARK := Color(0.12, 0.12, 0.13)

## The patches of floor these stand on, for the clutter to keep out of.
var taken: Array[Rect2] = []


## The Garage's gear round [param for_arena], at the back of the bay.
static func add_to(for_arena: Arena) -> GarageGear:
	var gear := GarageGear.new()
	gear._stand_in(for_arena, "GarageGear")
	gear._build()
	if for_arena.bake_scenery:
		Bake.merge(gear)
	return gear


func _build() -> void:
	var half := arena.world_size() * 0.5
	var back := -half.y
	var steel := surfaces.metal(Color(0.66, 0.68, 0.72))
	var rubber := surfaces.painted(Color(0.1, 0.1, 0.11))
	var red := surfaces.painted(Color(0.72, 0.18, 0.16))
	var dark := surfaces.painted(DARK)
	_kart_on_stands(Vector3(half.x + KART_OUT.x, TOP, back - KART_OUT.y), steel, rubber, red, dark)
	_soda(Vector3(SODA_AT.x, TOP, back - SODA_AT.y), dark)
	_compressor(Vector3(COMPRESSOR_AT.x, TOP, back - COMPRESSOR_AT.y), steel, rubber, red, dark)
	_hose(Vector3(HOSE_AT.x, TOP, back - HOSE_AT.y))
	_creeper(Vector3(CREEPER_AT.x, TOP, back - CREEPER_AT.y), steel, rubber, dark)


## A kart up on four jack stands with its wheels off, the stubs of its axles showing, one wheel
## leaning on its side and another lying flat beside it, the way a kart waiting on parts is left.
func _kart_on_stands(
	at: Vector3, steel: Material, rubber: Material, red: Material, dark: Material
) -> void:
	var paint := surfaces.painted(KART_PAINT)
	var tray := at + Vector3(0.0, RAISED, 0.0)
	var corner := Vector2(TRAY.x * 0.5 - 0.3, TRAY.z * 0.5 - 0.6)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var foot := at + Vector3(x * corner.x, 0.0, z * corner.y)
			_taper(0.5, 0.18, 0.3, red, foot + Vector3(0.0, 0.15, 0.0))
			_cylinder(
				0.12, RAISED - 0.35, steel, foot + Vector3(0.0, 0.3 + (RAISED - 0.35) * 0.5, 0.0)
			)
			_box(Vector3(0.45, 0.14, 0.45), red, foot + Vector3(0.0, RAISED - 0.12, 0.0))
			# The stub of the axle the wheel came off, out past the side of the tray.
			var stub := _cylinder(
				0.16, 0.6, steel, tray + Vector3(x * (TRAY.x * 0.5 + 0.2), 0.0, z * corner.y)
			)
			stub.rotation.z = PI * 0.5
	_box(TRAY, steel, tray)
	# The body on the tray: the nose, the pods down either side, the seat and the engine behind it.
	_box(Vector3(2.4, 0.55, 1.3), paint, tray + Vector3(0.0, 0.4, -TRAY.z * 0.5 + 0.75))
	for x: float in [-1.0, 1.0]:
		_box(Vector3(0.55, 0.5, 2.4), paint, tray + Vector3(x * 1.2, 0.38, 0.3))
	# The seat: its pan, and its back leant back.
	_box(Vector3(1.2, 0.3, 1.0), dark, tray + Vector3(0.0, 0.28, 0.5))
	var seat_back := _box(Vector3(1.2, 1.1, 0.24), dark, tray + Vector3(0.0, 0.75, 1.05))
	seat_back.rotation.x = -0.35
	# The engine beside the seat at the back, in bare metal, its exhaust out to the side.
	_box(Vector3(0.9, 0.8, 0.9), steel, tray + Vector3(0.85, 0.52, 1.9))
	var exhaust := _cylinder(0.14, 0.9, red, tray + Vector3(1.45, 0.62, 2.1))
	exhaust.rotation.z = PI * 0.5
	# The steering column up from the nose toward the seat, the wheel on the end of it.
	var tilt := 0.6
	var column := _cylinder(0.08, 1.0, steel, tray + Vector3(0.0, 0.75, -1.2))
	column.rotation.x = tilt
	var wheel := _cylinder(
		0.42, 0.1, dark, tray + Vector3(0.0, 0.75 + cos(tilt) * 0.5, -1.2 + sin(tilt) * 0.5)
	)
	wheel.rotation.x = tilt
	# One wheel leaning on the kart's left side, another flat on the floor off its right front.
	var lean := 0.3
	var leaning := Vector3(
		at.x - TRAY.x * 0.5 - WHEEL * sin(lean) - WHEEL_WIDE * 0.5,
		at.y + WHEEL * cos(lean) + WHEEL_WIDE * 0.5 * sin(lean),
		at.z + 0.2
	)
	for part: Array in [[rubber, WHEEL, WHEEL_WIDE], [steel, WHEEL * 0.5, WHEEL_WIDE + 0.06]]:
		var leant := _cylinder(part[1], part[2], part[0], leaning)
		leant.rotation.z = PI * 0.5 - lean
	var flat := Vector3(
		at.x + TRAY.x * 0.5 + 1.4, at.y + WHEEL_WIDE * 0.5, at.z - TRAY.z * 0.5 + 0.6
	)
	_cylinder(WHEEL, WHEEL_WIDE, rubber, flat)
	_cylinder(WHEEL * 0.5, WHEEL_WIDE + 0.06, steel, flat)
	_keep(Rect2(at.x - TRAY.x * 0.5 - 2.0, at.z - TRAY.z * 0.5 - 0.5, TRAY.x + 4.6, TRAY.z + 1.0))


## The House's soda machine, standing by the bench in its red with a gold trim: a lit window of
## what it sells, a coin slot and the flap the can comes out of, all on the side facing the bay.
func _soda(at: Vector3, dark: Material) -> void:
	var body := surfaces.painted(SODA_RED)
	var gold := surfaces.metal(HouseTheme.FOIL)
	var front := at.z + SODA.z * 0.5
	_box(SODA, body, at + Vector3(0.0, SODA.y * 0.5, 0.0))
	_box(Vector3(SODA.x + 0.2, 0.22, SODA.z + 0.2), gold, at + Vector3(0.0, SODA.y + 0.11, 0.0))
	_box(Vector3(SODA.x + 0.2, 0.3, SODA.z + 0.2), gold, at + Vector3(0.0, 0.15, 0.0))
	for x: float in [-1.0, 1.0]:
		_box(
			Vector3(0.12, SODA.y, 0.12),
			gold,
			Vector3(at.x + x * SODA.x * 0.5, SODA.y * 0.5 + at.y, front)
		)
	# The window, its rows of cans in the House's red across it.
	var window := Vector3(at.x - 0.35, at.y + 3.1, front + 0.03)
	_box(Vector3(1.6, 2.6, 0.06), surfaces.painted(SODA_PANEL), window)
	for row: int in 3:
		_box(Vector3(1.3, 0.22, 0.04), body, window + Vector3(0.0, 0.8 - row * 0.8, 0.04))
	# The coin slot on a plate of gold beside the window, and the flap under them.
	var slot := Vector3(at.x + 0.85, at.y + 3.2, front + 0.03)
	_box(Vector3(0.5, 0.9, 0.05), gold, slot)
	_box(Vector3(0.1, 0.36, 0.04), dark, slot + Vector3(0.0, 0.12, 0.04))
	_box(Vector3(1.7, 0.6, 0.08), dark, Vector3(at.x, at.y + 1.0, front + 0.04))
	_keep(Rect2(at.x - SODA.x * 0.5 - 0.1, at.z - SODA.z * 0.5 - 0.1, SODA.x + 0.2, SODA.z + 0.3))


## An air compressor: its tank lying on two wheels and a foot, the motor and the guard over its
## belt on top, a gauge on the side facing the bay, and the handle it is wheeled about by.
func _compressor(
	at: Vector3, steel: Material, rubber: Material, red: Material, dark: Material
) -> void:
	var middle := at + Vector3(0.0, TANK.x + 0.35, 0.0)
	var tank := _cylinder(TANK.x, TANK.y, surfaces.painted(TANK_PAINT), middle)
	tank.rotation.z = PI * 0.5
	for z: float in [-1.0, 1.0]:
		var wheel := _cylinder(0.36, 0.22, rubber, at + Vector3(-TANK.y * 0.35, 0.36, z * 0.62))
		wheel.rotation.x = PI * 0.5
	_box(Vector3(0.3, 0.4, 0.9), steel, at + Vector3(TANK.y * 0.38, 0.2, 0.0))
	_box(Vector3(1.0, 0.7, 0.8), dark, middle + Vector3(0.25, TANK.x + 0.3, 0.0))
	var guard := _cylinder(0.42, 0.24, red, middle + Vector3(-0.55, TANK.x + 0.3, 0.0))
	guard.rotation.x = PI * 0.5
	var gauge := _cylinder(0.16, 0.08, steel, middle + Vector3(0.5, 0.15, TANK.x + 0.04))
	gauge.rotation.x = PI * 0.5
	var handle := _box(
		Vector3(0.12, 1.2, 0.12), steel, at + Vector3(-TANK.y * 0.5 - 0.15, 1.3, 0.0)
	)
	handle.rotation.z = 0.35
	_keep(Rect2(at.x - TANK.y * 0.5 - 0.6, at.z - 0.85, TANK.y + 1.2, 1.7))


## The compressor's hose, coiled on the floor beside it, and the run of it back to the tank.
func _hose(at: Vector3) -> void:
	var red := surfaces.painted(HOSE_RED)
	for i: int in 3:
		var coil := TorusMesh.new()
		coil.inner_radius = 0.62 + i * 0.05
		coil.outer_radius = 0.8 + i * 0.05
		coil.rings = 18
		coil.ring_segments = 6
		_put(coil, red, at + Vector3(i * 0.08, 0.09 + i * 0.16, -i * 0.06))
	var run := _box(Vector3(1.9, 0.14, 0.14), red, at + Vector3(-1.5, 0.07, -0.45))
	run.rotation.y = 0.45
	_keep(Rect2(at.x - 2.6, at.z - 1.2, 3.7, 2.2))


## A mechanic's creeper: a padded board on castors, half under the bench where it was left.
func _creeper(at: Vector3, steel: Material, rubber: Material, dark: Material) -> void:
	var across := Vector3(cos(CREEPER_TURN), 0.0, -sin(CREEPER_TURN))
	var along := Vector3(sin(CREEPER_TURN), 0.0, cos(CREEPER_TURN))
	_turned(_box(Vector3(1.3, 0.12, 3.0), steel, at + Vector3(0.0, 0.3, 0.0)), CREEPER_TURN)
	var pad := at + Vector3(0.0, 0.41, 0.0)
	_turned(_box(Vector3(1.1, 0.1, 2.3), dark, pad + along * 0.25), CREEPER_TURN)
	_turned(
		_box(Vector3(0.7, 0.16, 0.45), dark, pad + Vector3.UP * 0.04 - along * 1.15), CREEPER_TURN
	)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 0.0, 1.0]:
			var castor := at + across * x * 0.5 + along * z * 1.25 + Vector3(0.0, 0.12, 0.0)
			_cylinder(0.12, 0.14, rubber, castor)
	_keep(Rect2(at.x - 1.0, at.z - 1.8, 2.0, 3.6))


## Marks [param patch] as taken, with the same room round it the clutter leaves round its own.
func _keep(patch: Rect2) -> void:
	taken.append(patch.grow(RoomProps.ELBOW))
