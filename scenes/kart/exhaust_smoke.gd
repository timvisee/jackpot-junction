class_name ExhaustSmoke
extends GPUParticles3D
## What a kart leaves behind it, GAME.md 4.4. Smoke out of the exhaust by default, and whatever
## else its driver picked instead: sparks, confetti, nothing at all, or what the loyalty program of
## 8.9 pays, poker chips, an afterburn or a pencil's scribbles. Density follows the
## throttle and thickens while drifting, on drift exit boosts and on turbo pads, whichever it is.

const BASE_RATIO := 0.15
## How big a poker chip of the trail is, across its middle: bigger than a scrap of confetti, as a
## chip is, if smaller than the table's.
const CHIP := 0.15
## The gold a Foil trail glints.
const GLINT := Color(1.0, 0.8, 0.28, 1.0)
## A scrap of confetti: how long it is, and how wide and thick for that.
const SCRAP := 0.12
const SCRAP_WIDE := 0.65
const SCRAP_THICK := 0.22
## How far round the color wheel a sheet of confetti is cut off the player's color either way.
const SHEET_TURN := 0.035

## The player's color, for the trails that are made of it.
var color := Color.WHITE
## Which of [constant KartStyle.TRAILS] this kart leaves, and its finish, GAME.md 8.9: none, Foil,
## Holographic or Polychrome.
var trail := 0
var finish := 0


func _ready() -> void:
	local_coords = false
	amount_ratio = BASE_RATIO
	ParticleLook.no_shadows(self)
	_build()


## Rebuilds the trail for a style. Called before the kart is in the tree, so it only records
## what to build; [method _ready] does the building.
func dress(player_color: Color, style: int, finished := 0) -> void:
	color = player_color
	trail = style
	finish = finished
	if is_inside_tree():
		_build()


func _build() -> void:
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	# Confetti lives longer than smoke and has to be thick enough to read as a trail, so it gets
	# more to work with. Everything else keeps the modest handful an exhaust wants.
	amount = 96 if trail == 2 else (40 if trail == 4 else (64 if trail == 1 else 48))
	var mesh: Mesh = null
	match trail:
		1:
			# Sparks: hot streaks thrown up and back fast, drawn out along the way each flies and
			# falling in an arc as grinding metal throws them, white-hot as they leave, cooling
			# through the player's color and gone in half a second, some sooner. Round flecks
			# drifting up read as embers, not sparks.
			lifetime = 0.55
			randomness = 0.3
			process.lifetime_randomness = 0.5
			process.spread = 32.0
			process.initial_velocity_min = 3.0
			process.initial_velocity_max = 5.5
			process.gravity = Vector3(0.0, -9.8, 0.0)
			process.particle_flag_align_y = true
			process.scale_min = 0.6
			process.scale_max = 1.1
			process.scale_curve = _shrinking()
			process.color = Color.WHITE
			process.color_ramp = _cooling(color)
			mesh = _streak()
		2:
			# Confetti: little slips tumbling down behind the kart, cut from a few sheets of the
			# player's color, a shade or a hue apart, see [method _sheets]. Slips with some
			# thickness rather than flat squares, which spend half a tumble edge-on and
			# invisible, and still big enough to be seen from where the camera actually is.
			lifetime = 2.2
			process.spread = 55.0
			process.initial_velocity_min = 1.0
			process.initial_velocity_max = 2.4
			process.gravity = Vector3(0.0, -2.6, 0.0)
			process.angle_min = -180.0
			process.angle_max = 180.0
			process.angular_velocity_min = -540.0
			process.angular_velocity_max = 540.0
			process.scale_min = 0.8
			process.scale_max = 1.3
			process.color = Color(color.lightened(0.15), 1.0)
			# A finish colors it its own way, see [method _finish].
			if finish <= 0:
				process.color = Color.WHITE
				process.color_initial_ramp = _sheets(color.lightened(0.15))
			mesh = _scrap()
		4:
			# Poker chips: chips as the table's are, the player's color with a lighter face and
			# pale notches round the rim, see [method Chip.mesh_for], which is what says chip
			# rather than a scrap of confetti in it. Tossed up and back, flipping over as a coin
			# tossed does, and down hard: a chip is heavy, and falls rather than flutters.
			lifetime = 1.3
			process.spread = 30.0
			process.initial_velocity_min = 2.0
			process.initial_velocity_max = 3.2
			process.gravity = Vector3(0.0, -9.0, 0.0)
			# Its face turned the way it flies, so it turns over as it goes up and comes down:
			# the turn a mesh's angle never gives it in 3D.
			process.particle_flag_align_y = true
			process.scale_min = 0.9
			process.scale_max = 1.15
			# The chip's own colors are in it: the particle's color only lights them, white
			# but for a finish's.
			process.color = Color.WHITE
			mesh = _chip(CHIP)
		5:
			# An afterburn: quick hot puffs in a lighter shade of the player's color, thrown back
			# hard.
			lifetime = 0.45
			process.spread = 12.0
			process.initial_velocity_min = 2.2
			process.initial_velocity_max = 3.4
			process.gravity = Vector3.ZERO
			process.scale_min = 0.7
			process.scale_max = 1.3
			process.color = Color(color.lightened(0.5), 0.85)
			mesh = _sphere(0.11)
		6:
			# Kit's pencil: graphite scribbles left lying behind, a few at a time, each turned its
			# own way, which a mesh's angle only does about its up with the flag for it.
			lifetime = 1.6
			process.spread = 40.0
			process.initial_velocity_min = 0.3
			process.initial_velocity_max = 0.9
			process.gravity = Vector3(0.0, -1.2, 0.0)
			process.particle_flag_rotate_y = true
			process.angle_min = -180.0
			process.angle_max = 180.0
			process.scale_min = 0.8
			process.scale_max = 1.4
			process.color = Color(0.22, 0.22, 0.24, 0.9)
			mesh = _stroke()
		3:
			# Nothing at all: a trail that is not there is not simulated either.
			lifetime = 0.1
			process.color = Color(1.0, 1.0, 1.0, 0.0)
			mesh = _sphere(0.01)
		_:
			lifetime = 1.4
			process.spread = 35.0
			process.initial_velocity_min = 0.4
			process.initial_velocity_max = 1.1
			process.gravity = Vector3.ZERO
			process.scale_min = 0.6
			process.scale_max = 1.4
			process.color = Color(0.75, 0.75, 0.78, 0.35)
			mesh = _sphere(0.12)
	if trail != 3:
		_finish(process)
	process_material = process
	draw_pass_1 = mesh
	emitting = trail != 3


## The sheets confetti is cut from, round [param base], each piece from one of them at random: a
## little lighter, a hue round the wheel either way, the color itself, and a little darker.
static func _sheets(base: Color) -> GradientTexture1D:
	var shades := PackedColorArray(
		[
			base.lightened(0.25),
			_turned(base, SHEET_TURN),
			Color(base, 1.0),
			_turned(base, -SHEET_TURN),
			base.darkened(0.18),
		]
	)
	var ramp := Gradient.new()
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	ramp.colors = shades
	var texture := GradientTexture1D.new()
	texture.gradient = ramp
	return texture


## [param base] turned [param by] round the color wheel.
static func _turned(base: Color, by: float) -> Color:
	return Color.from_hsv(fposmod(base.h + by, 1.0), base.s, base.v)


## A color of the rainbow at [param share] round it, a touch of [param base] in it.
static func _hue(share: float, base: Color) -> Color:
	return Color.from_hsv(fmod(share, 1.0), 0.85, 1.0).lerp(Color(base, 1.0), 0.15)


## The trail's finish over its color, GAME.md 8.9: Foil a glint of gold as each piece goes,
## Holographic its color turning through the rainbow as it lives, Polychrome every piece a color of
## its own.
func _finish(process: ParticleProcessMaterial) -> void:
	if finish <= 0:
		return
	var base := process.color
	var ramp := Gradient.new()
	match finish:
		1:
			# Its own color but for a quick glint of gold partway through its life.
			process.color = Color(1.0, 1.0, 1.0, base.a)
			ramp.set_color(0, Color(base, 1.0))
			ramp.set_color(1, Color(base, 1.0))
			ramp.add_point(0.34, Color(base, 1.0))
			ramp.add_point(0.42, GLINT)
			ramp.add_point(0.5, Color(base, 1.0))
		_:
			process.color = Color(1.0, 1.0, 1.0, base.a)
			ramp.set_color(0, _hue(0.0, base))
			ramp.set_color(1, _hue(1.0, base))
			for i: int in range(1, 6):
				ramp.add_point(i / 6.0, _hue(i / 6.0, base))
	var texture := GradientTexture1D.new()
	texture.gradient = ramp
	if finish == 3:
		process.color_initial_ramp = texture
	else:
		process.color_ramp = texture


## A puff is eight segments round: a fleck of one flat color, at a fiftieth of the triangles a
## SphereMesh comes with, see [method ParticleLook.ball].
func _sphere(radius: float) -> SphereMesh:
	return ParticleLook.ball(radius, 8)


## A poker chip of [param radius], as [method Chip.mesh_for] makes the table's, in this kart's
## color: the disc, its face lighter and a hair proud of it, and the pale notches round its rim.
## Lit, as a [Burst]'s chunks are, so it reads as a thing rather than a fleck.
func _chip(radius: float) -> ArrayMesh:
	var thick := radius * 0.3
	var ink := Color(color, 1.0)
	var pieces: Array[Array] = [
		[_disc(radius, thick, 14), Transform3D.IDENTITY, ink],
		[_disc(radius * 0.62, thick * 1.06, 14), Transform3D.IDENTITY, ink.lightened(0.2)],
	]
	for i: int in Chip.NOTCHES:
		var angle := TAU * float(i) / float(Chip.NOTCHES)
		var notch := BoxMesh.new()
		notch.size = Vector3(radius * 0.32, thick * 1.04, radius * 0.3)
		var at := Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.86
		pieces.append([notch, Transform3D(Basis(Vector3.UP, -angle), at), Palette.CHIP_WHITE])
	var chip := Bake.tinted(pieces)
	var look := _look()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	chip.surface_set_material(0, look)
	return chip


static func _disc(radius: float, height: float, sides: int) -> CylinderMesh:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = height
	disc.radial_segments = sides
	disc.rings = 1
	return disc


## A spark: a thin streak, long along its own y, which the trail turns the way it flies.
func _streak() -> BoxMesh:
	var streak := BoxMesh.new()
	streak.size = Vector3(0.022, 0.2, 0.022)
	streak.material = _look()
	return streak


## A spark's colors as it lives: white-hot, past bright enough to bloom where the room glows, then
## [param ink] lightened, then the player's own as it cools, and gone.
static func _cooling(ink: Color) -> GradientTexture1D:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.6, 1.5, 1.2, 1.0))
	ramp.set_color(1, Color(ink.r, ink.g, ink.b, 0.0))
	ramp.add_point(0.25, Color(ink.lightened(0.55), 1.0))
	ramp.add_point(0.6, Color(ink, 0.9))
	var texture := GradientTexture1D.new()
	texture.gradient = ramp
	texture.use_hdr = true
	return texture


## A spark burning down over its life, from its whole length to a fleck.
static func _shrinking() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.25))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


## A pencil stroke: a short thin dash.
func _stroke() -> BoxMesh:
	var stroke := BoxMesh.new()
	stroke.size = Vector3(0.26, 0.02, 0.05)
	stroke.material = _look()
	return stroke


## A slip of confetti, longer than it is wide and thin, see [constant SCRAP].
func _scrap() -> BoxMesh:
	var box := BoxMesh.new()
	box.size = Vector3(SCRAP, SCRAP * SCRAP_THICK, SCRAP * SCRAP_WIDE)
	box.material = _look()
	return box


func _look() -> StandardMaterial3D:
	var material := ParticleLook.material()
	material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	return material


## Updates the emission density from the kart state.
func update_state(throttle: float, drifting: bool, boosting: bool) -> void:
	if trail == 3:
		return
	var ratio := BASE_RATIO + throttle * 0.45
	if drifting:
		ratio += 0.4
	if boosting:
		ratio = 1.0
	amount_ratio = clampf(ratio, 0.0, 1.0)
