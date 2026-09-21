class_name Fireworks
extends Node3D
## The display over the arena once a match is won, GAME.md 8.3. Shells go up off the table and
## break overhead in the winner's colour, through the pause the podium waits out and on under
## the standings, so the room the match was played in is still celebrating behind them.
##
## Every shell is the two parts a real one has: a comet that climbs trailing sparks, and the
## break at the top of the climb. The winner's colour carries the show, with the odd gold shell
## among them so the sky is not one flat colour.

## Seconds between shells going up, give or take [constant SPACING_SPREAD].
const SPACING := 0.42
const SPACING_SPREAD := 0.18
## How high a shell breaks above the floor. High enough to be over the table rather than in
## among the karts, and to clear the podium screen that comes up under them.
const BREAK_LOW := 9.0
const BREAK_HIGH := 13.5
## Shells go up from inside this share of the arena footprint, so none breaks off the screen.
const FOOTPRINT := 0.45
## One shell in this many is gold rather than the winner's colour.
const GOLD_EVERY := 4

## The winner's colour, which most of the shells are.
var color := Color.WHITE

var _left := 0.0
var _next := 0.0
var _count := 0
var _rng := RandomNumberGenerator.new()
var _spread := Vector2.ONE * 10.0


## Sets shells going over [param bounds] in [param tint] for [param seconds]. The node frees
## itself once the last one has burned out.
static func celebrate(parent: Node, bounds: AABB, tint: Color, seconds: float) -> Fireworks:
	var show := Fireworks.new()
	show.name = "Fireworks"
	show.color = tint
	show._left = seconds
	show._spread = Vector2(bounds.size.x, bounds.size.z) * FOOTPRINT * 0.5
	parent.add_child(show)
	show.global_position = bounds.get_center() * Vector3(1.0, 0.0, 1.0)
	return show


func _ready() -> void:
	add_to_group(&"fireworks")
	_rng.randomize()


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		# The last shells are still in the air: the node goes once they have burned out.
		if get_child_count() == 0:
			queue_free()
		return
	_next -= delta
	if _next > 0.0:
		return
	_next = SPACING + _rng.randf_range(-SPACING_SPREAD, SPACING_SPREAD)
	_launch()


## One shell, from a random spot on the floor to a random height above it.
func _launch() -> void:
	var from := Vector3(
		_rng.randf_range(-_spread.x, _spread.x), 0.4, _rng.randf_range(-_spread.y, _spread.y)
	)
	_count += 1
	var shell := Shell.new()
	shell.tint = Palette.CHIP_GOLD if _count % GOLD_EVERY == 0 else color
	shell.height = _rng.randf_range(BREAK_LOW, BREAK_HIGH)
	add_child(shell)
	shell.position = from


## A single shell: the climb, the break, and the sparks falling out of it.
class Shell:
	extends Node3D

	## How long the climb takes, how long the sparks off the break burn, and how long the flash
	## at the break lasts.
	const CLIMB := 0.9
	const SPARKS := 90
	const SPARK_LIFETIME := 1.3
	const FLASH := 0.25
	## How brightly the break lights the room, and how far that reaches.
	const LIGHT_ENERGY := 7.0
	const LIGHT_RANGE := 22.0

	var tint := Color.WHITE
	var height := 7.0

	var _age := 0.0
	var _broken := false
	var _from := 0.0
	var _head: MeshInstance3D
	var _head_material: StandardMaterial3D
	var _trail: GPUParticles3D
	var _glow: OmniLight3D

	func _ready() -> void:
		_from = position.y
		_head = MeshInstance3D.new()
		_head.name = "Comet"
		_head.mesh = _spark_mesh(0.13)
		_head_material = StandardMaterial3D.new()
		_head_material.albedo_color = tint.lightened(0.5)
		_head_material.emission_enabled = true
		_head_material.emission = tint
		_head_material.emission_energy_multiplier = 4.0
		_head_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_head_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_head.material_override = _head_material
		_head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_head)
		_trail = _build_trail()
		add_child(_trail)

	func _process(delta: float) -> void:
		_age += delta
		if not _broken:
			# Eased out, so the comet slows as it reaches the top the way a shell does.
			var climb := clampf(_age / CLIMB, 0.0, 1.0)
			position.y = lerpf(_from, height, 1.0 - pow(1.0 - climb, 2.0))
			if climb >= 1.0:
				_break()
			return
		# The comet blooms into the flash of the break and goes out with it, and the room is lit
		# in the shell's colour for as long as that lasts.
		var flash := clampf((_age - CLIMB) / FLASH, 0.0, 1.0)
		_head.visible = flash < 1.0
		_head.scale = Vector3.ONE * (1.0 + 9.0 * flash)
		_head_material.albedo_color.a = 1.0 - flash
		_glow.light_energy = LIGHT_ENERGY * (1.0 - flash) * (1.0 - flash)
		if _age >= CLIMB + SPARK_LIFETIME + 0.4:
			queue_free()

	## The top of the climb: the comet goes out and the sparks come out of it.
	func _break() -> void:
		_broken = true
		_trail.emitting = false
		add_child(_build_sparks())
		_glow = OmniLight3D.new()
		_glow.name = "Flash"
		_glow.light_color = tint
		_glow.omni_range = LIGHT_RANGE
		_glow.shadow_enabled = false
		add_child(_glow)
		Audio.play_sfx(&"firework", -8.0, 0.12, 0.7)

	## The sparks the climb leaves behind it, thin and short-lived so they read as a tail.
	func _build_trail() -> GPUParticles3D:
		var particles := GPUParticles3D.new()
		particles.name = "Trail"
		particles.amount = 30
		particles.lifetime = 0.4
		particles.local_coords = false
		var process := ParticleProcessMaterial.new()
		process.direction = Vector3(0.0, -1.0, 0.0)
		process.spread = 12.0
		process.initial_velocity_min = 0.5
		process.initial_velocity_max = 1.5
		process.gravity = Vector3(0.0, -2.0, 0.0)
		process.scale_min = 0.5
		process.scale_max = 1.0
		process.color_ramp = ParticleLook.fade_out(tint.lightened(0.5), tint)
		particles.process_material = process
		particles.draw_pass_1 = _spark_mesh(0.07)
		particles.emitting = true
		return particles

	## The break itself: a ball of sparks thrown outward, falling, shrinking and going out
	## before they reach the floor.
	func _build_sparks() -> GPUParticles3D:
		var particles := GPUParticles3D.new()
		particles.name = "Break"
		particles.amount = SPARKS
		particles.lifetime = SPARK_LIFETIME
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.local_coords = false
		var process := ParticleProcessMaterial.new()
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		process.emission_sphere_radius = 0.25
		process.direction = Vector3(0.0, 1.0, 0.0)
		process.spread = 180.0
		process.initial_velocity_min = 6.0
		process.initial_velocity_max = 11.0
		process.gravity = Vector3(0.0, -8.0, 0.0)
		process.damping_min = 1.5
		process.damping_max = 3.5
		process.scale_min = 0.7
		process.scale_max = 1.4
		process.scale_curve = _dying_curve()
		process.color_ramp = _spark_ramp()
		particles.process_material = process
		# Drawn as streaks rather than dots: a spark that leaves a tail behind it reads as a
		# firework, and a field of dots reads as confetti coming down.
		particles.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Y_TO_VELOCITY
		particles.trail_enabled = true
		particles.trail_lifetime = 0.3
		particles.draw_pass_1 = _streak_mesh()
		particles.emitting = true
		return particles

	## One spark: a small ball, lit by nothing and coloured by the ramp, the way the sparks off
	## a drift are drawn.
	func _spark_mesh(radius: float) -> SphereMesh:
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 6
		mesh.rings = 3
		mesh.material = ParticleLook.material()
		return mesh

	## The streak a spark is drawn as: a tapered ribbon, thickest where the spark is and drawn
	## out behind it along the way it is travelling.
	func _streak_mesh() -> RibbonTrailMesh:
		var mesh := RibbonTrailMesh.new()
		mesh.shape = RibbonTrailMesh.SHAPE_FLAT
		mesh.size = 0.18
		mesh.sections = 4
		mesh.section_length = 0.22
		mesh.section_segments = 1
		var taper := Curve.new()
		taper.add_point(Vector2(0.0, 1.0))
		taper.add_point(Vector2(1.0, 0.0))
		mesh.curve = taper
		mesh.material = ParticleLook.material()
		return mesh

	## White-hot at the break, the shell's colour for most of the fall, and gone before it
	## lands. A spark that starts fading the moment it is born is a puff of smoke.
	func _spark_ramp() -> GradientTexture1D:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.08, 0.7, 1.0])
		# Written linear: what goes into a ramp is used as it is, so a colour picked by eye has
		# to be converted or it comes out washed out.
		var lit := tint.srgb_to_linear()
		var colors: PackedColorArray = [Color.WHITE, lit, lit, Color(lit.r, lit.g, lit.b, 0.0)]
		gradient.colors = colors
		var ramp := GradientTexture1D.new()
		ramp.gradient = gradient
		return ramp

	## Sparks shrink as they burn down, which is what stops them reading as falling confetti.
	func _dying_curve() -> CurveTexture:
		var curve := Curve.new()
		curve.add_point(Vector2(0.0, 1.0))
		curve.add_point(Vector2(1.0, 0.2))
		var texture := CurveTexture.new()
		texture.curve = curve
		return texture
