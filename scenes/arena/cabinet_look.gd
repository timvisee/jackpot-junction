class_name CabinetLook
extends RefCounted
## What a live cabinet, GAME.md 6.2, shows of how charged it is, on every screen, over the look its
## room gives it, see [LiveCabinet]: a meter of two lamps along its roof filling in toward the
## beacon as it charges, the beacon coming up with them; once it is live, the beacon and the meter
## glowing up and down slowly, a breath rather than a blink, with a soft glow round the beacon that
## comes and goes with them, so a live one reads from the game camera beside a charging one without
## calling to it; and a loose cable out of its roof, over the door's top edge and down its face to a
## bare end, that spits a spark now and then, more often in the last moment of the charge, and
## arcs onto the roof now and then while it is live. As it kills, the beacon strobes. For fewer
## flashes, 8.5, the beacon, the meter and the glow hold steady while it is live and as it kills,
## and the cable throws no arcs.
##
## The cable keeps to the cabinet's footprint, over its roof and against its door, so it is nothing
## a kart can touch without touching the cabinet: it shows the danger without being one of its own.
##
## Cheap: the cable and the meter's slots are plain paint on their vertices, baked with the rest of
## the cabinet, see [method lay]; the meter's lamps are two boxes in one copy of the beacon's lamp,
## the glow a ball in the arcs' own look, and the sparks one small system in the look the nitro's
## sparks are drawn in, all on shaders the title's warm-up has compiled.

## Where the roof of a cabinet's look is, which every room's builds to: the meter lies on it and
## the cable comes out of it, in meters off the floor.
const ROOF := 1.05
## The cable: the points it runs through, from the gland it comes out of the roof by, toward the
## cabinet's end nearer the camera, along x, up off the roof, over the door's top edge, +z, and
## down the door's face to its bare end, in meters off the roof; how thick it is, its rubber, the
## gland's steel and the copper of its end. Hanging against the door it stands no further out of
## the cabinet's box than a kart touching it has to come, see [constant LiveCabinet.TOUCH].
const CABLE: Array[Vector3] = [
	Vector3(0.42, 0.01, -0.12),
	Vector3(0.432, 0.16, -0.085),
	Vector3(0.438, 0.25, 0.03),
	Vector3(0.435, 0.2, 0.18),
	Vector3(0.43, 0.06, 0.272),
	Vector3(0.425, -0.13, 0.294),
	Vector3(0.42, -0.3, 0.296),
]
const CABLE_RADIUS := 0.032
const RUBBER := Color("#1E1F22")
const GLAND := Color("#3A3C40")
const COPPER := Color("#C27A3E")
## The bare end's strands, splayed down off the end of the cable, each from it to here.
const STRANDS: Array[Vector3] = [
	Vector3(0.03, -0.07, 0.015), Vector3(-0.03, -0.075, 0.01), Vector3(0.0, -0.065, 0.035)
]
## The meter: how far along the roof each of its two lamps reaches from the middle, from its inner
## end to its outer, how wide it is, and the paint of the slot it lies in.
const METER_IN := 0.16
const METER_OUT := 0.36
const METER_WIDE := 0.08
const SLOT := Color("#1B1C1F")
## How bright the beacon is with the cabinet spent and charged, and how bright the meter's lamps
## are while it charges. Spent, a lamp's glass is darkened this much as well, so the difference
## reads in the afternoon light too.
const DARKENED := 0.6
const SPENT := 0.12
const CHARGED := 0.55
const FILLING := 0.9
## Live: how long one breath of the beacon and the meter takes, in seconds, well under once a
## second, and how bright they are at the low and the top of it; for fewer flashes, how bright they
## hold.
const BREATH := 2.4
const LOW := 0.7
const TOP := 1.25
const STEADY := 1.05
## The glow round the beacon while it is live, so a live one reads from the game camera, where the
## beacon is a few pixels: how big, its amber, and how see-through at the low and the top of a
## breath, and held for fewer flashes.
const HALO := 0.19
const HALO_INK := Color("#FF9A3C")
const HALO_LOW := 0.12
const HALO_TOP := 0.32
const HALO_STEADY := 0.24
## As the cabinet kills: how bright the beacon strobes, how fast, and how bright between.
const FLASH := 4.0
const STROBE := 14.0
const DIM := 0.25
## The cable's sparks: how long a spit of them lasts; how long between spits while it charges, in
## the last [constant WARN] seconds of the charge, and while it is live; and how long between the
## crackles it throws onto the roof while it is live. A map's detail, not an alarm: a live one is
## live most of the time.
const SPIT := 0.06
const NOW_AND_THEN := Vector2(2.0, 4.0)
const WARN := 0.8
const WARNING := Vector2(0.22, 0.4)
const CRACKLING := Vector2(0.6, 1.6)
const ARCING := Vector2(1.4, 3.2)

var _cabinet: LiveCabinet
## Which end of the cabinet, along its x, the cable is at: the one nearer the camera.
var _near := 1.0
var _beacons: Array[StandardMaterial3D] = []
var _rest: Array[float] = []
var _glass: Array[Color] = []
var _meter: Array[Node3D] = []
var _meter_glow: StandardMaterial3D
var _meter_rest := 1.0
var _meter_glass := Color.WHITE
var _sparks: GPUParticles3D
var _halo: MeshInstance3D
var _halo_glow: StandardMaterial3D
var _clock := 0.0
var _spit_left := 0.0
var _next_spit := 0.0
var _next_arc := 0.0
var _gap := Vector2.ZERO
var _dice := RandomNumberGenerator.new()


## The cable and the meter's slots onto [param look], the cable at the end [param near] says, in
## plain paint on their vertices, to be baked with the rest of the cabinet.
static func lay(look: Node3D, near: float) -> void:
	var pieces: Array[Array] = []
	var at := _points(near)
	var gland := CylinderMesh.new()
	gland.top_radius = CABLE_RADIUS * 1.7
	gland.bottom_radius = CABLE_RADIUS * 1.9
	gland.height = 0.05
	gland.radial_segments = 8
	gland.rings = 1
	pieces.append([gland, Transform3D(Basis.IDENTITY, at[0] + Vector3(0.0, 0.015, 0.0)), GLAND])
	for i: int in range(1, at.size()):
		pieces.append(_rod(at[i - 1], at[i], CABLE_RADIUS, RUBBER, CABLE_RADIUS * 0.7))
		if i < at.size() - 1:
			var joint := SphereMesh.new()
			joint.radius = CABLE_RADIUS
			joint.height = CABLE_RADIUS * 2.0
			joint.radial_segments = 6
			joint.rings = 3
			pieces.append([joint, Transform3D(Basis.IDENTITY, at[i]), RUBBER])
	var end := at[at.size() - 1]
	var into := (end - at[at.size() - 2]).normalized()
	pieces.append(_rod(end - into * 0.01, end + into * 0.025, CABLE_RADIUS * 0.9, COPPER))
	for strand: Vector3 in STRANDS:
		var out := Vector3(strand.x * near, strand.y, strand.z)
		pieces.append(_rod(end, end + out, 0.012, COPPER))
	for side: float in [-1.0, 1.0]:
		var slot := BoxMesh.new()
		slot.size = Vector3(METER_OUT - METER_IN + 0.04, 0.016, METER_WIDE + 0.04)
		var middle := Vector3(side * (METER_IN + METER_OUT) * 0.5, ROOF + 0.008, 0.0)
		pieces.append([slot, Transform3D(Basis.IDENTITY, middle), SLOT])
	var cable := MeshInstance3D.new()
	cable.name = "Cable"
	cable.mesh = Bake.tinted(pieces)
	cable.material_override = Bake.tinted_look(false)
	look.add_child(cable)


## The cable's points in the cabinet's own space, at the end [param near] says.
static func _points(near: float) -> Array[Vector3]:
	var at: Array[Vector3] = []
	for point: Vector3 in CABLE:
		at.append(Vector3(point.x * near, ROOF + point.y, point.z))
	return at


## Where the cable's bare end is, at the end [param near] says, in the cabinet's own space: where
## its sparks fly from.
static func tip(near: float) -> Vector3:
	var at := _points(near)
	return at[at.size() - 1] + Vector3(0.0, -0.06, 0.02)


## A rod of [param radius] in [param ink] from [param from] to [param to], [param over] longer at
## each end, as a piece for [method Bake.tinted].
static func _rod(from: Vector3, to: Vector3, radius: float, ink: Color, over := 0.0) -> Array:
	var span := to - from
	var rod := CylinderMesh.new()
	rod.top_radius = radius
	rod.bottom_radius = radius
	rod.height = span.length() + over * 2.0
	rod.radial_segments = 6
	rod.rings = 1
	var turn := Basis(Quaternion(Vector3.UP, span.normalized()))
	return [rod, Transform3D(turn, (from + to) * 0.5), ink]


## What [param cabinet] shows of how charged it is, its look [param look] dressed and the cable at
## the end [param near] says: a lamp of its own for each part of the look named `Beacon`, and the
## meter's lamps, the glow and the cable's sparks put on the cabinet beside the look, out of what it
## bakes.
func _init(cabinet: LiveCabinet, look: Node3D, near: float, surfaces: Surfaces) -> void:
	_cabinet = cabinet
	_near = near
	_dice.randomize()
	_own_beacons(look)
	var worn := _beacons[0] if not _beacons.is_empty() else surfaces.neon(LiveCabinet.BEACON, 0.6)
	_meter_glow = worn.duplicate() as StandardMaterial3D
	_meter_glow.emission_enabled = true
	_meter_rest = _meter_glow.emission_energy_multiplier
	_meter_glass = _meter_glow.albedo_color
	var long := METER_OUT - METER_IN
	for side: float in [-1.0, 1.0]:
		# Each lamp grows from the roof's end in toward the beacon: its pivot at the outer end.
		var pivot := Node3D.new()
		pivot.name = "Meter%d" % _meter.size()
		pivot.position = Vector3(side * METER_OUT, ROOF + 0.02, 0.0)
		pivot.scale = Vector3(0.001, 1.0, 1.0)
		var lamp := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(long, 0.02, METER_WIDE)
		lamp.mesh = box
		lamp.material_override = _meter_glow
		lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lamp.position = Vector3(-side * long * 0.5, 0.0, 0.0)
		pivot.add_child(lamp)
		cabinet.add_child(pivot)
		_meter.append(pivot)
	_sparks = _spitting()
	_sparks.position = tip(near)
	cabinet.add_child(_sparks)
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	_halo.mesh = ParticleLook.ball(HALO, 16)
	_halo_glow = SpawnRing.glow(HALO_INK, HALO_TOP)
	_halo.material_override = _halo_glow
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.position = Vector3(0.0, LiveCabinet.SIZE.y - 0.05, 0.0)
	_halo.visible = false
	cabinet.add_child(_halo)


## How full the meter is, 0 to 1, for the tests.
func meter() -> float:
	return _meter[0].scale.x if not _meter.is_empty() else 0.0


## How see-through the glow round the beacon is, nought while it is down, for the tests.
func halo() -> float:
	return _halo_glow.albedo_color.a if _halo.visible else 0.0


## How bright the beacon is just now against its own lamp, for the tests.
func beacon() -> float:
	if _beacons.is_empty():
		return 0.0
	return _beacons[0].emission_energy_multiplier / maxf(_rest[0], 0.001)


## A frame of it, the cabinet charged for [param charged] seconds, see
## [method LiveCabinet.charged_for], with [param flash_left] seconds left of the beacon's flash as
## it kills.
func step(delta: float, charged: float, flash_left: float) -> void:
	_clock += delta
	var steady := Game.settings != null and Game.settings.flash_reduction
	var live := charged >= LiveCabinet.CHARGE
	var share := 1.0 if live else clampf(charged / LiveCabinet.CHARGE, 0.0, 1.0)
	var lamp := lerpf(SPENT, CHARGED, share)
	var meter_lamp := FILLING
	if live:
		# From the top of a breath as it goes live, so the moment it does is the brightest.
		var breath := 0.5 + 0.5 * cos(TAU * (charged - LiveCabinet.CHARGE) / BREATH)
		lamp = STEADY if steady else lerpf(LOW, TOP, breath)
		meter_lamp = lamp
		_halo_glow.albedo_color.a = HALO_STEADY if steady else lerpf(HALO_LOW, HALO_TOP, breath)
	if flash_left > 0.0:
		lamp = FLASH if steady or fmod(_clock * STROBE, 1.0) < 0.5 else DIM
	for i: int in _beacons.size():
		_light(_beacons[i], _rest[i], _glass[i], lamp)
	_light(_meter_glow, _meter_rest, _meter_glass, meter_lamp)
	for pivot: Node3D in _meter:
		pivot.scale.x = maxf(share, 0.001)
	_halo.visible = live
	_step_sparks(delta, charged, live, steady)


## [param lamp] lit [param bright] against its own [param rest], its [param glass] darkened toward
## spent.
static func _light(lamp: StandardMaterial3D, rest: float, glass: Color, bright: float) -> void:
	lamp.emission_energy_multiplier = rest * bright
	var dark := clampf((CHARGED - bright) / (CHARGED - SPENT), 0.0, 1.0)
	lamp.albedo_color = glass.darkened(DARKENED * dark)


## The cable spitting sparks, now and then while the cabinet charges, more often in the last moment
## of the charge, and a little more often once it is live, with a crackle onto the roof now and
## then but for fewer flashes.
func _step_sparks(delta: float, charged: float, live: bool, steady: bool) -> void:
	# Spitting as often as how charged it is has it, from the moment it is that charged.
	var gap := NOW_AND_THEN
	if live:
		gap = CRACKLING
	elif charged >= LiveCabinet.CHARGE - WARN:
		gap = WARNING
	if gap != _gap:
		_gap = gap
		_next_spit = 0.0
	_spit_left -= delta
	if _spit_left <= 0.0 and _sparks.emitting:
		_sparks.emitting = false
	_next_spit -= delta
	if _next_spit <= 0.0:
		_sparks.emitting = true
		_spit_left = SPIT
		_next_spit = _dice.randf_range(gap.x, gap.y)
	if not live or steady or not _cabinet.is_inside_tree():
		return
	_next_arc -= delta
	if _next_arc > 0.0:
		return
	_next_arc = _dice.randf_range(ARCING.x, ARCING.y)
	var onto := Vector3(
		_near * _dice.randf_range(0.05, METER_OUT), ROOF + 0.01, _dice.randf_range(0.0, 0.27)
	)
	var tip_at := _cabinet.to_global(tip(_near))
	ZapArc.crackle(_cabinet.get_parent(), tip_at, _cabinet.to_global(onto), LiveCabinet.SPARK)


## The sparks off the cable's bare end: the nitro's own, smaller and fewer, thrown out and falling,
## so they are drawn in a look the warm-up has compiled, see [NitroFlame].
func _spitting() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Sparks"
	particles.amount = 32
	particles.lifetime = 0.45
	particles.local_coords = false
	particles.emitting = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.6, 1.0)
	process.spread = 70.0
	process.initial_velocity_min = 1.2
	process.initial_velocity_max = 2.8
	process.gravity = Vector3(0.0, -9.0, 0.0)
	process.damping_min = 0.5
	process.damping_max = 1.5
	process.scale_min = 0.5
	process.scale_max = 1.1
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.03
	process.color_ramp = ParticleLook.fade_out(
		Color(0.95, 0.98, 1.0, 1.0), Color(LiveCabinet.SPARK, 0.0)
	)
	particles.process_material = process
	particles.draw_pass_1 = ParticleLook.ball(0.045, 6)
	ParticleLook.no_shadows(particles)
	return particles


## Gives every part named Beacon under [param node] a lamp of this cabinet's own.
func _own_beacons(node: Node) -> void:
	for child: Node in node.get_children():
		_own_beacons(child)
		var part := child as MeshInstance3D
		if part == null or not String(part.name).begins_with("Beacon"):
			continue
		var worn := part.material_override as StandardMaterial3D
		if worn == null:
			continue
		var own := worn.duplicate() as StandardMaterial3D
		own.emission_enabled = true
		part.material_override = own
		_beacons.append(own)
		_rest.append(own.emission_energy_multiplier)
		_glass.append(own.albedo_color)
