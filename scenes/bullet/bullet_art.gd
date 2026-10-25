extends RefCounted
## Everything a bullet is drawn with, GAME.md 10.7: a ball and its trail, and the rocket, grenade,
## railgun, chain-lightning and boomerang looks of 5.3, built from a handful of shared meshes and
## materials so a shot builds nothing of its own. Kept out of [Bullet] and loaded at runtime the way
## [Blast] is, see [constant Bullet.BULLET_ART_SCRIPT], both to keep the bullet short and so it does
## not compile-depend on this. Every call takes the host to hang the look on and the plain numbers
## it is drawn by, so this depends on nothing of the arena's.

## A flame's colour, the same behind every rocket whoever fired it, so a rocket reads as one and not
## just a fat bullet in a player's colour; and an electric blue for chain lightning's spark.
const FLAME := Color(1.0, 0.55, 0.12)
## The white-hot heart of a rocket's flame, inside the orange [constant FLAME].
const FLAME_HOT := Color(1.0, 0.93, 0.62)
const SPARK := Color(0.6, 0.85, 1.0)
## A rocket's smoke, and how many puffs trail behind the flame; and how many arcs crackle round a
## chain-lightning bolt, re-struck each tick, see [method crackle].
const SMOKE := Color(0.46, 0.46, 0.5)
const SMOKE_PUFFS := 6
const SPARK_ARCS := 5

## What a bullet is drawn with, by its radius and its colour, shared by every bullet: a ball of
## eight segments is all a plain bullet ever shows.
static var _cores: Dictionary[float, SphereMesh] = {}
static var _cones: Dictionary[float, CylinderMesh] = {}
static var _glows: Dictionary[Color, StandardMaterial3D] = {}
static var _trails: Dictionary[Color, StandardMaterial3D] = {}
## A rocket's smoke, by how faint each puff is, shared across every rocket, see [method _smoke].
static var _smokes: Dictionary[float, StandardMaterial3D] = {}
## A grenade's dark casing and a rocket's dark body, the same behind every one.
static var _grenade_casing: StandardMaterial3D
static var _rocket_shell: StandardMaterial3D


## Hangs the look of a [param kind] shot of radius [param radius] and colour [param color] on
## [param host], and returns the arcs a chain-lightning bolt is re-struck by each tick, see [method
## crackle], or an empty array for every other kind.
static func build(
	host: Node3D, kind: StringName, radius: float, color: Color
) -> Array[MeshInstance3D]:
	match kind:
		&"rocket":
			_rocket(host, radius, color)
		&"grenade":
			_grenade(host, radius, color)
		&"railgun":
			_railgun(host, radius, color)
		&"lightning":
			return _lightning(host, radius)
		&"boomerang":
			_boomerang(host, radius, color)
		_:
			_ball(host, radius, color)
	return []


static func _ball(host: Node3D, radius: float, color: Color) -> void:
	var core := MeshInstance3D.new()
	core.name = "Core"
	core.mesh = _core_mesh(radius)
	core.material_override = _glow(color)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(core)
	var trail := MeshInstance3D.new()
	trail.name = "Trail"
	trail.mesh = _cone_mesh(radius)
	trail.material_override = _trail(color)
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The cylinder's axis is Y; lay it along +Z, which is behind the bullet after look_at.
	trail.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	trail.position = Vector3(0.0, 0.0, 0.5)
	host.add_child(trail)


## A rocket: a slim dark body with a black nose and two bands of the shooter's colour, nose-first
## (-Z after look_at), with a bright layered flame at the nozzle and a tail of smoke behind it. Dark
## and striped rather than a fat ball in a player's colour, so it reads as a rocket.
static func _rocket(host: Node3D, radius: float, color: Color) -> void:
	var body := MeshInstance3D.new()
	body.name = "Core"
	var tube := CylinderMesh.new()
	tube.top_radius = radius * 0.8
	tube.bottom_radius = radius * 0.8
	tube.height = radius * 3.2
	tube.radial_segments = 8
	tube.rings = 1
	body.mesh = tube
	body.material_override = _rocket_casing()
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The cylinder's axis is Y; lay it along Z, the line the bullet faces after look_at.
	body.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	host.add_child(body)
	var nose := MeshInstance3D.new()
	nose.name = "Nose"
	var tip := CylinderMesh.new()
	tip.top_radius = 0.01
	tip.bottom_radius = radius * 0.8
	tip.height = radius * 1.5
	tip.radial_segments = 8
	tip.rings = 1
	nose.mesh = tip
	nose.material_override = _rocket_casing()
	nose.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Point the cone forward, -Z, its tip the nose of the rocket.
	nose.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	nose.position = Vector3(0.0, 0.0, -(radius * 1.6 + radius * 0.75))
	host.add_child(nose)
	for z: float in [-radius * 0.45, radius * 0.75]:
		var stripe := MeshInstance3D.new()
		stripe.name = "Stripe%d" % int(signf(z))
		var ring := TorusMesh.new()
		ring.inner_radius = radius * 0.78
		ring.outer_radius = radius * 0.98
		ring.rings = 10
		ring.ring_segments = 6
		stripe.mesh = ring
		stripe.material_override = _glow(color)
		stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# The torus hole is along Y; turn it to ring the body's Z axis.
		stripe.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		stripe.position = Vector3(0.0, 0.0, z)
		host.add_child(stripe)
	_rocket_fire(host, radius, radius * 1.6)
	_rocket_smoke(host, radius, radius * 1.6 + radius * 3.8)


## A rocket's fire at [param nozzle] behind it: a white-hot inner flame inside a softer orange
## flare, both tapering back off the tail.
## The cone meshes are a metre tall, so scale them down to the rocket's size: a short bright core and
## a flare half again as long behind it, both starting at the nozzle and tapering back.
static func _rocket_fire(host: Node3D, radius: float, nozzle: float) -> void:
	var inner := MeshInstance3D.new()
	inner.name = "Flame"
	inner.mesh = _cone_mesh(radius * 1.1)
	inner.material_override = _glow(FLAME_HOT)
	inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inner.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	inner.scale = Vector3(1.0, radius * 2.4, 1.0)
	inner.position = Vector3(0.0, 0.0, nozzle + radius * 1.2)
	host.add_child(inner)
	var flare := MeshInstance3D.new()
	flare.name = "Flare"
	flare.mesh = _cone_mesh(radius * 1.7)
	flare.material_override = _trail(FLAME)
	flare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flare.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	flare.scale = Vector3(1.0, radius * 3.6, 1.0)
	flare.position = Vector3(0.0, 0.0, nozzle + radius * 1.8)
	host.add_child(flare)


## A rocket's smoke, starting [param back] behind it: a column of puffs that grow wider and fade as
## they trail off, wandering a little side to side so it reads as drifting smoke, not a string of
## beads.
static func _rocket_smoke(host: Node3D, radius: float, back: float) -> void:
	for i: int in SMOKE_PUFFS:
		var puff := MeshInstance3D.new()
		puff.name = "Smoke%d" % i
		var share := float(i) / float(SMOKE_PUFFS)
		var puff_size := radius * (1.0 + 1.5 * share)
		puff.mesh = _core_mesh(puff_size)
		puff.material_override = _smoke(0.42 * (1.0 - share))
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puff.position = Vector3(sin(i * 2.1) * radius * 0.5, sin(i * 1.3) * radius * 0.3, back)
		back += puff_size * 1.05
		host.add_child(puff)


## A grenade: a dark casing the size of a fist with a band of the shooter's colour round it, no
## flame and no bright core, so it reads as a thing lobbed rather than a shot fired.
static func _grenade(host: Node3D, radius: float, color: Color) -> void:
	var body := MeshInstance3D.new()
	body.name = "Core"
	body.mesh = _core_mesh(radius)
	body.material_override = _grenade_body()
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(body)
	var band := MeshInstance3D.new()
	band.name = "Band"
	var ring := TorusMesh.new()
	ring.inner_radius = radius * 0.7
	ring.outer_radius = radius * 1.08
	ring.rings = 12
	ring.ring_segments = 6
	band.mesh = ring
	band.material_override = _glow(color)
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	band.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	host.add_child(band)


## A railgun bolt: a long, thin streak nose-first in the shooter's colour, so it reads as a bolt
## that runs clean through a line of karts rather than a single ball.
static func _railgun(host: Node3D, radius: float, color: Color) -> void:
	var bolt := MeshInstance3D.new()
	bolt.name = "Core"
	var streak := CylinderMesh.new()
	streak.top_radius = radius * 0.6
	streak.bottom_radius = radius * 0.6
	streak.height = 1.3
	streak.radial_segments = 6
	streak.rings = 1
	bolt.mesh = streak
	bolt.material_override = _glow(color)
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bolt.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	host.add_child(bolt)


## Chain lightning: a bright white-blue core with a cage of thin electric arcs round it, re-struck
## at fresh random angles every tick, see [method crackle], so it crackles like a live shock.
## Returns the arcs for the bolt to keep and re-strike.
static func _lightning(host: Node3D, radius: float) -> Array[MeshInstance3D]:
	var core := MeshInstance3D.new()
	core.name = "Core"
	core.mesh = _core_mesh(radius * 1.1)
	core.material_override = _glow(Color(0.85, 0.93, 1.0))
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(core)
	var sparks: Array[MeshInstance3D] = []
	for i: int in SPARK_ARCS:
		var arc := MeshInstance3D.new()
		arc.name = "Arc%d" % i
		var rod := CylinderMesh.new()
		rod.top_radius = radius * 0.16
		rod.bottom_radius = radius * 0.16
		rod.height = 1.0
		rod.radial_segments = 4
		rod.rings = 1
		arc.mesh = rod
		arc.material_override = _glow(SPARK)
		arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sparks.append(arc)
		host.add_child(arc)
	crackle(sparks, radius)
	return sparks


## The lightning's arcs struck afresh: each a thin bolt from the core out to a new random point, so
## the shot spits electricity in every direction and flickers from tick to tick.
static func crackle(sparks: Array[MeshInstance3D], radius: float) -> void:
	for arc: MeshInstance3D in sparks:
		var dir := Vector3(randf_range(-1.0, 1.0), randf_range(-0.6, 0.6), randf_range(-1.0, 1.0))
		if dir.length() < 0.1:
			dir = Vector3.BACK
		_aim_rod(arc, Vector3.ZERO, dir.normalized() * radius * randf_range(2.0, 4.0))


## Points the unit-height cylinder [param rod] (its axis is Y) to span from [param a] to [param b].
static func _aim_rod(rod: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var along := b - a
	var length := along.length()
	if length < 0.001:
		return
	var up := along / length
	var side := up.cross(Vector3.FORWARD)
	if side.length() < 0.01:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	rod.transform = Transform3D(Basis(side, up, side.cross(up).normalized()), (a + b) * 0.5)
	rod.scale = Vector3(1.0, length, 1.0)


## A boomerang: two arms in the shooter's colour bent into a V, lying flat and spinning, see [method
## Bullet._orient], so it reads as a boomerang thrown to come back rather than a disc or a shot.
static func _boomerang(host: Node3D, radius: float, color: Color) -> void:
	var length := radius * 3.6
	for side: float in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.name = "Arm%d" % int(side)
		var box := BoxMesh.new()
		box.size = Vector3(radius * 0.55, radius * 0.45, length)
		arm.mesh = box
		arm.material_override = _glow(color)
		arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var angle := deg_to_rad(side * 52.0)
		arm.rotation = Vector3(0.0, angle, 0.0)
		arm.position = Vector3(sin(angle), 0.0, cos(angle)) * (length * 0.5)
		host.add_child(arm)


static func _rocket_casing() -> StandardMaterial3D:
	if _rocket_shell == null:
		_rocket_shell = StandardMaterial3D.new()
		_rocket_shell.albedo_color = Color(0.08, 0.08, 0.09)
		_rocket_shell.metallic = 0.3
		_rocket_shell.roughness = 0.45
	return _rocket_shell


static func _grenade_body() -> StandardMaterial3D:
	if _grenade_casing == null:
		_grenade_casing = StandardMaterial3D.new()
		_grenade_casing.albedo_color = Color(0.17, 0.21, 0.14)
		_grenade_casing.metallic = 0.2
		_grenade_casing.roughness = 0.5
	return _grenade_casing


## A smoke puff's material, grey and [param alpha] faint, unshaded, shared by every rocket.
static func _smoke(alpha: float) -> StandardMaterial3D:
	if not _smokes.has(alpha):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(SMOKE.r, SMOKE.g, SMOKE.b, alpha)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_smokes[alpha] = material
	return _smokes[alpha]


static func _core_mesh(size: float) -> SphereMesh:
	if not _cores.has(size):
		var sphere := SphereMesh.new()
		sphere.radius = size
		sphere.height = size * 2.0
		sphere.radial_segments = 8
		sphere.rings = 4
		_cores[size] = sphere
	return _cores[size]


static func _cone_mesh(size: float) -> CylinderMesh:
	if not _cones.has(size):
		var cone := CylinderMesh.new()
		cone.top_radius = size * 0.8
		cone.bottom_radius = 0.01
		cone.height = 1.0
		cone.radial_segments = 8
		cone.rings = 1
		_cones[size] = cone
	return _cones[size]


static func _glow(tint: Color) -> StandardMaterial3D:
	if not _glows.has(tint):
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.emission_enabled = true
		material.emission = tint
		material.emission_energy_multiplier = 2.0
		_glows[tint] = material
	return _glows[tint]


static func _trail(tint: Color) -> StandardMaterial3D:
	if not _trails.has(tint):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(tint.r, tint.g, tint.b, 0.45)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_trails[tint] = material
	return _trails[tint]
