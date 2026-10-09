class_name ExhaustSmoke
extends GPUParticles3D
## What a kart leaves behind it, GAME.md 4.4. Smoke out of the exhaust by default, and whatever
## else its driver picked instead: sparks, confetti, nothing at all, or what the loyalty program of
## 8.9 pays, poker chips, an afterburn or a pencil's scribbles. Density follows the
## throttle and thickens while drifting, on drift exit boosts and on turbo pads, whichever it is.

const BASE_RATIO := 0.15
## The gold a Foil trail glints.
const GLINT := Color(1.0, 0.8, 0.28, 1.0)

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
	amount = 96 if trail == 2 else (64 if trail == 4 else 48)
	var mesh: Mesh = null
	match trail:
		1:
			# Sparks: small, bright, in the player's color, thrown up and gone quickly.
			lifetime = 0.7
			process.spread = 25.0
			process.initial_velocity_min = 1.2
			process.initial_velocity_max = 2.6
			process.gravity = Vector3(0.0, -2.0, 0.0)
			process.scale_min = 0.25
			process.scale_max = 0.7
			process.color = Color(color.lightened(0.35), 0.95)
			mesh = _sphere(0.09)
		2:
			# Confetti: little blocks tumbling down behind the kart. Blocks rather than flat
			# squares, which spend half a tumble edge-on and invisible, and big enough to be
			# seen from where the camera actually is, which is the other end of the room.
			lifetime = 2.2
			process.spread = 55.0
			process.initial_velocity_min = 1.0
			process.initial_velocity_max = 2.4
			process.gravity = Vector3(0.0, -2.6, 0.0)
			process.angle_min = -180.0
			process.angle_max = 180.0
			process.angular_velocity_min = -540.0
			process.angular_velocity_max = 540.0
			process.scale_min = 0.9
			process.scale_max = 1.7
			process.color = Color(color.lightened(0.15), 1.0)
			mesh = _block(0.17)
		4:
			# Poker chips: flat discs in the player's color tumbling down behind, as confetti does,
			# fewer of them since a chip is bigger than a scrap of paper.
			lifetime = 1.8
			process.spread = 50.0
			process.initial_velocity_min = 1.0
			process.initial_velocity_max = 2.2
			process.gravity = Vector3(0.0, -2.8, 0.0)
			process.angle_min = -180.0
			process.angle_max = 180.0
			process.angular_velocity_min = -360.0
			process.angular_velocity_max = 360.0
			process.scale_min = 0.9
			process.scale_max = 1.3
			process.color = Color(color.lightened(0.15), 1.0)
			mesh = _chip(0.1)
		5:
			# An afterburn: quick hot puffs in a lighter shade of the player's color, thrown back hard.
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
			# Kit's pencil: graphite scribbles left lying behind, a few at a time.
			lifetime = 1.6
			process.spread = 40.0
			process.initial_velocity_min = 0.3
			process.initial_velocity_max = 0.9
			process.gravity = Vector3(0.0, -1.2, 0.0)
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


## Sparks are six segments round and smoke eight: a fleck of one flat color, at a fiftieth of
## the triangles a SphereMesh comes with, see [method ParticleLook.ball].
func _sphere(radius: float) -> SphereMesh:
	return ParticleLook.ball(radius, 6 if trail == 1 else 8)


## A poker chip: a flat disc, eight sides round, the scale the confetti's blocks are.
func _chip(radius: float) -> CylinderMesh:
	var chip := CylinderMesh.new()
	chip.top_radius = radius
	chip.bottom_radius = radius
	chip.height = radius * 0.28
	chip.radial_segments = 8
	chip.rings = 1
	chip.material = _look()
	return chip


## A pencil stroke: a short thin dash.
func _stroke() -> BoxMesh:
	var stroke := BoxMesh.new()
	stroke.size = Vector3(0.26, 0.02, 0.05)
	stroke.material = _look()
	return stroke


func _block(side: float) -> BoxMesh:
	var box := BoxMesh.new()
	box.size = Vector3(side, side * 0.35, side)
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
