class_name Kart
extends CharacterBody3D
## A player's or bot's kart. Movement is planar, gravity-free and driven by a [KartMotor]; the
## [KartInput] decides who is at the wheel; the [Cannon] fires forward. Death, falling into pits
## and spawn protection follow GAME.md 3.6.

signal died(cause: StringName, killer_slot: int)
signal respawned
signal fired(bullets: Array[Bullet])
signal turbo_taken(direction: Vector3)
signal coins_collected(amount: int)
signal mult_changed(amount: float, reason: StringName)

const WHEEL_RADIUS := 0.24
const FALL_SPEED := 2.5
const FALL_SPIN := 7.0
const BLINK_PERIOD := 0.25
const RING_RADIUS_EMPTY := 0.6
const RING_RADIUS_FULL := 1.4

@export var stats: KartStats
@export var cannon_stats: CannonStats
@export var rules: MatchRules
## Player slot, 0 to 3, decides the colour and who gets the credit.
@export var slot := 0

var input: KartInput = KartInput.new()
var motor: KartMotor
var cannon: Cannon
var bullet_system: BulletSystem
var pot := Pot.new()
var alive := true
var falling := false
## Set by the match during the countdown and the results: no input, no movement.
var frozen := false
var protection_left := 0.0
## Fraction of the pot still to bank while on the Junction, -1 when not banking.
var channel_progress := -1.0
## Set by the Boost power-up: contact with another kart kills it.
var ramming := false
var last_bump_slot := -1
var last_bump_time := -INF

var _body: Node3D
var _ring: MeshInstance3D
var _pickup_area: Area3D
var _tire_marks: TireMarks
var _smoke: ExhaustSmoke
var _pickup_shape: SphereShape3D
var _fall_left := 0.0
var _graze_cooldown_left := 0.0


func _ready() -> void:
	if stats == null:
		stats = load("res://data/kart/default.tres")
	if cannon_stats == null:
		cannon_stats = load("res://data/cannons/default.tres")
	if rules == null:
		rules = load("res://data/match/default.tres")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = Layers.KART
	collision_mask = Layers.WORLD | Layers.KART | Layers.PROTECTED
	add_to_group(&"karts")
	add_to_group(Bullet.TARGET_GROUP)
	motor = KartMotor.new(stats)
	motor.heading = rotation.y
	cannon = Cannon.new(cannon_stats)
	if bullet_system == null:
		bullet_system = get_tree().get_first_node_in_group(&"bullet_system") as BulletSystem
	_build_visuals()
	_tire_marks = TireMarks.new()
	_tire_marks.name = "TireMarks"
	add_child(_tire_marks)
	_smoke = ExhaustSmoke.new()
	_smoke.name = "Smoke"
	_smoke.position = Vector3(0.0, 0.35, stats.length * 0.5)
	add_child(_smoke)
	_build_pickup_area()


func _physics_process(delta: float) -> void:
	if not alive or frozen:
		return
	if falling:
		_step_fall(delta)
		return
	_step_protection(delta)
	_graze_cooldown_left = maxf(_graze_cooldown_left - delta, 0.0)
	input.poll(delta)
	cannon.step(delta)
	if input.fire and protection_left <= 0.0 and cannon.can_fire() and bullet_system != null:
		_fire()
	var heading_before := motor.heading
	motor.step(input, delta)
	velocity = motor.velocity
	move_and_slide()
	_resolve_collisions()
	motor.velocity = Vector3(velocity.x, 0.0, velocity.z)
	position.y = 0.0
	rotation = Vector3(0.0, motor.heading, 0.0)
	_collect_overlapping_pickups()
	_update_trails(delta, heading_before)


func _process(_delta: float) -> void:
	_ring.visible = channel_progress >= 0.0 and alive
	if _ring.visible:
		var radius := lerpf(RING_RADIUS_EMPTY, RING_RADIUS_FULL, channel_progress)
		_ring.scale = Vector3(radius, 1.0, radius)


## True while bullets may hit and aim assist may pick this kart.
func is_targetable() -> bool:
	return alive and not falling and protection_left <= 0.0


## Coins picked up from chips, crates or the Jackpot.
func collect_coins(amount: int, _source: Pickup) -> void:
	if amount <= 0:
		return
	pot.add_coins(amount)
	coins_collected.emit(amount)
	Events.coin_collected.emit(slot, amount)


func gain_mult(amount: float, reason: StringName) -> void:
	if amount == 0.0:
		return
	pot.add_mult(amount)
	mult_changed.emit(amount, reason)
	Events.mult_gained.emit(slot, amount, reason)


## An enemy bullet passed close without hitting, GAME.md 3.3.
func graze(_by_slot: int) -> void:
	if not is_targetable() or _graze_cooldown_left > 0.0:
		return
	_graze_cooldown_left = rules.graze_cooldown
	gain_mult(rules.graze_mult, &"graze")
	Events.grazed.emit(slot)


## Distance from a point on the floor plane to the kart's body rectangle, 0 when inside.
func distance_to_body(point: Vector3) -> float:
	var local := to_local(Vector3(point.x, global_position.y, point.z))
	var half := Vector3(stats.width * 0.5, 0.0, stats.length * 0.5)
	var clamped := Vector3(clampf(local.x, -half.x, half.x), 0.0, clampf(local.z, -half.z, half.z))
	return Vector3(local.x, 0.0, local.z).distance_to(clamped)


## Scales the pickup radius, for the Coin Magnet.
func set_pickup_radius_multiplier(multiplier: float) -> void:
	_pickup_shape.radius = rules.pickup_radius * multiplier


## A bullet reached the kart. Returns false when it passes through, for example during spawn
## protection.
func take_hit(bullet: Bullet) -> bool:
	if not is_targetable():
		return false
	die(&"bullet", bullet.owner_slot)
	return true


## Kills the kart. The match decides when and where it respawns.
func die(cause: StringName, killer_slot: int) -> void:
	if not alive:
		return
	alive = false
	falling = false
	collision_layer = 0
	collision_mask = 0
	motor.velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	_body.visible = false
	_smoke.emitting = false
	channel_progress = -1.0
	died.emit(cause, killer_slot)


## Puts the kart back on the floor at [param point], facing [param direction], protected for
## [param protection] seconds.
func respawn(point: Vector3, direction: Vector3, protection: float) -> void:
	alive = true
	falling = false
	global_position = Vector3(point.x, 0.0, point.z)
	scale = Vector3.ONE
	face(direction)
	motor.velocity = Vector3.ZERO
	motor.drifting = false
	motor.drift_time = 0.0
	motor.boost_time_left = 0.0
	motor.turbo_time_left = 0.0
	velocity = Vector3.ZERO
	cannon.cooldown_left = 0.0
	protection_left = protection
	collision_layer = Layers.PROTECTED if protection > 0.0 else Layers.KART
	collision_mask = Layers.WORLD | Layers.KART | Layers.PROTECTED
	_body.visible = true
	_smoke.emitting = true
	respawned.emit()


## Called by a [Pit]: the kart drops out of control for a moment, then dies. The last kart that
## bumped it recently gets the credit.
func start_fall() -> void:
	if not alive or falling:
		return
	falling = true
	_fall_left = rules.pit_fall_time
	collision_layer = 0
	collision_mask = 0


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
	if not alive or falling:
		return
	motor.apply_turbo(direction)
	turbo_taken.emit(direction)


func _fire() -> void:
	var direction := -global_basis.z
	var origin := global_position + direction * cannon_stats.muzzle_offset
	var shots := cannon.fire(bullet_system, slot, origin, direction, Palette.player_color(slot))
	fired.emit(shots)


func _step_protection(delta: float) -> void:
	if protection_left <= 0.0:
		return
	protection_left = maxf(protection_left - delta, 0.0)
	if protection_left <= 0.0:
		collision_layer = Layers.KART
		_body.visible = true
	else:
		_body.visible = fmod(protection_left, BLINK_PERIOD) < BLINK_PERIOD * 0.5


func _step_fall(delta: float) -> void:
	_fall_left -= delta
	position += motor.velocity * 0.3 * delta
	position.y -= FALL_SPEED * delta
	rotation.y += FALL_SPIN * delta
	scale = Vector3.ONE * maxf(_fall_left / rules.pit_fall_time, 0.05)
	if _fall_left <= 0.0:
		var now := Time.get_ticks_msec() * 0.001
		var pusher := (
			last_bump_slot if now - last_bump_time <= rules.bump_attribution_window else -1
		)
		die(&"pit", pusher)


func _resolve_collisions() -> void:
	var pre := motor.velocity
	for i: int in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()
		if absf(normal.y) > 0.7:
			continue
		var other := collision.get_collider() as Kart
		if other != null:
			last_bump_slot = other.slot
			last_bump_time = Time.get_ticks_msec() * 0.001
			if ramming and other.is_targetable():
				other.die(&"ram", slot)
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
	var tint := StandardMaterial3D.new()
	tint.albedo_color = Palette.player_color(slot)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.12, 0.13)
	var white := StandardMaterial3D.new()
	white.albedo_color = Palette.CHIP_WHITE
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	var chassis := _box(Vector3(stats.width * 0.8, 0.3, stats.length), tint)
	chassis.position = Vector3(0.0, 0.32, 0.0)
	_body.add_child(chassis)
	var seat := _box(Vector3(stats.width * 0.5, 0.35, stats.length * 0.35), dark)
	seat.position = Vector3(0.0, 0.62, stats.length * 0.1)
	_body.add_child(seat)
	var nose := _box(Vector3(stats.width * 0.5, 0.12, 0.3), white)
	nose.position = Vector3(0.0, 0.5, -stats.length * 0.45)
	_body.add_child(nose)
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
			_body.add_child(wheel)


func _box(size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	return instance


func _build_pickup_area() -> void:
	_pickup_area = Area3D.new()
	_pickup_area.name = "PickupArea"
	_pickup_area.collision_layer = 0
	_pickup_area.collision_mask = Layers.PICKUP
	var shape := CollisionShape3D.new()
	_pickup_shape = SphereShape3D.new()
	_pickup_shape.radius = rules.pickup_radius
	shape.shape = _pickup_shape
	shape.position = Vector3(0.0, 0.4, 0.0)
	_pickup_area.add_child(shape)
	add_child(_pickup_area)
	_ring = MeshInstance3D.new()
	_ring.name = "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	_ring.mesh = torus
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Palette.NEON_CYAN
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = ring_material
	_ring.position = Vector3(0.0, 0.06, 0.0)
	_ring.visible = false
	add_child(_ring)


## Polled every tick rather than on entry, so a kart that unfreezes or spawns on top of a pickup
## still takes it.
func _collect_overlapping_pickups() -> void:
	for area: Area3D in _pickup_area.get_overlapping_areas():
		var pickup := area as Pickup
		if pickup != null:
			pickup.collect(self)
