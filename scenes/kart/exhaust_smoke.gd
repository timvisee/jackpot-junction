class_name ExhaustSmoke
extends GPUParticles3D
## What a kart leaves behind it, GAME.md 4.4. Smoke out of the exhaust by default, and whatever
## else its driver picked instead: sparks, confetti, or nothing at all. Density follows the
## throttle and thickens while drifting, on drift exit boosts and on turbo pads, whichever it is.

const BASE_RATIO := 0.15

## The player's colour, for the trails that are made of it.
var color := Color.WHITE
## Which of [constant KartStyle.TRAILS] this kart leaves.
var trail := 0


func _ready() -> void:
	local_coords = false
	amount_ratio = BASE_RATIO
	_build()


## Rebuilds the trail for a style. Called before the kart is in the tree, so it only records
## what to build; [method _ready] does the building.
func dress(player_color: Color, style: int) -> void:
	color = player_color
	trail = style
	if is_inside_tree():
		_build()


func _build() -> void:
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	# Confetti lives longer than smoke and has to be thick enough to read as a trail, so it gets
	# more to work with. Everything else keeps the modest handful an exhaust wants.
	amount = 96 if trail == 2 else 48
	var mesh: Mesh = null
	match trail:
		1:
			# Sparks: small, bright, in the player's colour, thrown up and gone quickly.
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
		3:
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
	process_material = process
	draw_pass_1 = mesh


func _sphere(radius: float) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.material = _look()
	return sphere


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
	var ratio := BASE_RATIO + throttle * 0.45
	if drifting:
		ratio += 0.4
	if boosting:
		ratio = 1.0
	amount_ratio = clampf(ratio, 0.0, 1.0)
