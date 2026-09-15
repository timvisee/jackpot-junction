class_name Kart
extends CharacterBody3D
## A player's or bot's kart. Movement is planar, gravity-free and driven by a [KartMotor]; the
## [KartInput] decides who is at the wheel.

signal turbo_taken(direction: Vector3)

const WHEEL_RADIUS := 0.24

@export var stats: KartStats
## Player slot, 0 to 3, decides the colour.
@export var slot := 0

var input: KartInput = KartInput.new()
var motor: KartMotor

var _tire_marks: TireMarks
var _smoke: ExhaustSmoke
var _tint: StandardMaterial3D


func _ready() -> void:
	if stats == null:
		stats = load("res://data/kart/default.tres")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = Layers.KART
	collision_mask = Layers.WORLD | Layers.KART
	motor = KartMotor.new(stats)
	motor.heading = rotation.y
	_build_visuals()
	_tire_marks = TireMarks.new()
	_tire_marks.name = "TireMarks"
	add_child(_tire_marks)
	_smoke = ExhaustSmoke.new()
	_smoke.name = "Smoke"
	_smoke.position = Vector3(0.0, 0.35, stats.length * 0.5)
	add_child(_smoke)


func _physics_process(delta: float) -> void:
	input.poll(delta)
	var heading_before := motor.heading
	motor.step(input, delta)
	velocity = motor.velocity
	move_and_slide()
	_resolve_collisions()
	motor.velocity = Vector3(velocity.x, 0.0, velocity.z)
	position.y = 0.0
	rotation = Vector3(0.0, motor.heading, 0.0)
	_update_trails(delta, heading_before)


## Sets the facing direction, for spawning.
func face(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.is_zero_approx():
		return
	var heading := atan2(-flat.x, -flat.z)
	rotation = Vector3(0.0, heading, 0.0)
	if motor != null:
		motor.heading = heading


## Called by a [TurboPad] when the kart drives over it.
func apply_turbo(direction: Vector3) -> void:
	motor.apply_turbo(direction)
	turbo_taken.emit(direction)


func _resolve_collisions() -> void:
	var pre := motor.velocity
	for i: int in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()
		if absf(normal.y) > 0.7:
			continue
		var collider := collision.get_collider()
		if collider is Kart:
			motor.apply_bump(normal)
			velocity = motor.velocity
		else:
			motor.velocity = Vector3(velocity.x, 0.0, velocity.z)
			motor.apply_wall_hit(-pre.dot(normal))
			velocity = motor.velocity


func _update_trails(delta: float, heading_before: float) -> void:
	var speed := motor.speed()
	if speed < 0.8:
		_smoke.update_state(input.throttle, false, false)
		return
	var turning := absf(wrapf(motor.heading - heading_before, -PI, PI)) / maxf(delta, 0.0001)
	var intensity := 0.15
	if motor.drifting:
		intensity = 1.0
	elif input.brake > 0.3 and motor.forward_speed > 1.0:
		intensity = 0.6
	elif turning > 1.5:
		intensity = 0.35
	var side := global_basis.x
	var rear := global_position + global_basis.z * stats.length * 0.4
	var now := Time.get_ticks_msec() * 0.001
	var half_track := stats.width * 0.42
	_tire_marks.add_sample(0, rear - side * half_track, side, intensity, now)
	_tire_marks.add_sample(1, rear + side * half_track, side, intensity, now)
	_smoke.update_state(input.throttle, motor.drifting, motor.boosting() or motor.turboing())


func _build_visuals() -> void:
	var color := Palette.player_color(slot)
	_tint = StandardMaterial3D.new()
	_tint.albedo_color = color
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.12, 0.13)
	var body := Node3D.new()
	body.name = "Body"
	add_child(body)
	var chassis := _box(Vector3(stats.width * 0.8, 0.3, stats.length), _tint)
	chassis.position = Vector3(0.0, 0.32, 0.0)
	body.add_child(chassis)
	var seat := _box(Vector3(stats.width * 0.5, 0.35, stats.length * 0.35), dark)
	seat.position = Vector3(0.0, 0.62, stats.length * 0.1)
	body.add_child(seat)
	var white := StandardMaterial3D.new()
	white.albedo_color = Palette.CHIP_WHITE
	var nose := _box(Vector3(stats.width * 0.5, 0.12, 0.3), white)
	nose.position = Vector3(0.0, 0.5, -stats.length * 0.45)
	body.add_child(nose)
	for x: int in [-1, 1]:
		for z: int in [-1, 1]:
			var wheel := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = WHEEL_RADIUS
			cylinder.bottom_radius = WHEEL_RADIUS
			cylinder.height = 0.22
			wheel.mesh = cylinder
			wheel.material_override = dark
			wheel.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			wheel.position = Vector3(x * stats.width * 0.5, WHEEL_RADIUS, z * stats.length * 0.32)
			body.add_child(wheel)


func _box(size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	return instance
