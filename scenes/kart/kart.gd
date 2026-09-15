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
signal item_held(item: PowerUp)
signal item_used(item: PowerUp)
signal joker_dropped(joker: Joker)

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
var jokers: JokerHolder
## The shared resources the kart's own stat copies are rebuilt from when jokers change.
var base_stats: KartStats
var base_cannon_stats: CannonStats
## Whether the joker menu is held open, and which held joker the cursor is on.
var menu_open := false
var menu_index := 0
## Set by the match so jokers and items can roll dice deterministically.
var rng := RandomNumberGenerator.new()
var alive := true
var falling := false
## Set by the match during the countdown and the results: no input, no movement.
var frozen := false
var protection_left := 0.0
## Fraction of the pot still to bank while on the Junction, -1 when not banking.
var channel_progress := -1.0
## Set by the Boost power-up: contact with another kart kills it.
var ramming := false
var shielded := false
var held_item: PowerUp
## Seconds until a freshly taken item is revealed and usable.
var item_reveal_left := 0.0
var effects: Array[KartEffect] = []
## Multiplier on the pickup radius from the Coin Magnet.
var pickup_radius_bonus := 1.0
var last_bump_slot := -1
var last_bump_time := -INF

var _body: Node3D
var _ring: MeshInstance3D
var _pickup_area: Area3D
var _tire_marks: TireMarks
var _smoke: ExhaustSmoke
var _pickup_shape: SphereShape3D
var _shield_visual: MeshInstance3D
var _fall_left := 0.0
var _graze_cooldown_left := 0.0


func _ready() -> void:
	if stats == null:
		stats = load("res://data/kart/default.tres")
	if cannon_stats == null:
		cannon_stats = load("res://data/cannons/default.tres")
	if rules == null:
		rules = load("res://data/match/default.tres")
	base_stats = stats
	base_cannon_stats = cannon_stats
	stats = base_stats.duplicate()
	cannon_stats = base_cannon_stats.duplicate()
	jokers = JokerHolder.new(self)
	jokers.changed.connect(rebuild_stats)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = Layers.KART
	collision_mask = Layers.WORLD | Layers.KART | Layers.PROTECTED | Layers.TURRET
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
	rebuild_stats()


func _physics_process(delta: float) -> void:
	if not alive or frozen:
		return
	if falling:
		_step_fall(delta)
		return
	_step_protection(delta)
	_graze_cooldown_left = maxf(_graze_cooldown_left - delta, 0.0)
	_step_effects(delta)
	input.poll(delta)
	cannon.step(delta)
	if input.fire and protection_left <= 0.0 and cannon.can_fire() and bullet_system != null:
		_fire()
	item_reveal_left = maxf(item_reveal_left - delta, 0.0)
	_step_menu()
	if not menu_open and input.use_item_pressed and held_item != null and item_reveal_left <= 0.0:
		use_item()
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


## Rebuilds the kart's own stat copies from the shared bases and the held jokers.
func rebuild_stats() -> void:
	stats = base_stats.duplicate()
	cannon_stats = base_cannon_stats.duplicate()
	for joker: Joker in jokers.jokers:
		joker.modify_kart_stats(stats)
		joker.modify_cannon_stats(cannon_stats)
	if input is PlayerInput:
		var strength := clampf(Game.settings.aim_assist, 0.0, 1.0)
		cannon_stats.aim_assist_cone_deg *= strength
		cannon_stats.aim_assist_turn_rate_deg *= strength
		cannon_stats.aim_assist = cannon_stats.aim_assist and strength > 0.0
	motor.stats = stats
	cannon.stats = cannon_stats
	refresh_pickup_radius()


## Coins picked up from chips, crates or the Jackpot. Jokers may change what a chip is worth.
func collect_coins(amount: int, source: Pickup) -> void:
	var chip := source as Chip
	if chip != null:
		for joker: Joker in jokers.jokers:
			amount = joker.modify_coin_value(self, chip, amount)
	if amount > 0:
		pot.add_coins(amount)
		coins_collected.emit(amount)
		Events.coin_collected.emit(slot, amount)
	if chip != null:
		for joker: Joker in jokers.jokers:
			joker.on_chip_collected(self, chip)


func gain_mult(amount: float, reason: StringName) -> void:
	for joker: Joker in jokers.jokers:
		amount = joker.modify_mult_gain(self, amount, reason)
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
	var amount := rules.graze_mult
	for joker: Joker in jokers.jokers:
		amount = joker.modify_graze_mult(self, amount)
	if amount > 0.0:
		gain_mult(amount, &"graze")
	Events.grazed.emit(slot)


## Seconds in which the Junction drain doubles for this kart.
func bank_doubling() -> float:
	var doubling := rules.bank_rate_doubling
	for joker: Joker in jokers.jokers:
		doubling = joker.modify_bank_doubling(self, doubling)
	return doubling


## Multiplier on this kart's Junction payouts from jokers.
func bank_payout() -> float:
	var multiplier := 1.0
	for joker: Joker in jokers.jokers:
		multiplier = joker.modify_bank_payout(self, multiplier)
	return multiplier


## Whether contact kills other karts right now: Boost, or a joker such as Road Rage.
func ram_kills() -> bool:
	if ramming:
		return true
	for joker: Joker in jokers.jokers:
		if joker.ram_kills(self):
			return true
	return false


## How many jokers a respawn offers this kart.
func offer_count(base: int) -> int:
	var count := base
	for joker: Joker in jokers.jokers:
		count = joker.modify_offer_count(count)
	return count


## Drops a held joker on the floor for anyone to take.
func drop_joker(index: int) -> void:
	if index < 0 or index >= jokers.count():
		return
	var joker := jokers.remove_at(index)
	joker_dropped.emit(joker)


func destroy_joker(index: int) -> void:
	if index >= 0 and index < jokers.count():
		jokers.remove_at(index)


## Distance from a point on the floor plane to the kart's body rectangle, 0 when inside.
func distance_to_body(point: Vector3) -> float:
	var local := to_local(Vector3(point.x, global_position.y, point.z))
	var half := Vector3(stats.width * 0.5, 0.0, stats.length * 0.5)
	var clamped := Vector3(clampf(local.x, -half.x, half.x), 0.0, clampf(local.z, -half.z, half.z))
	return Vector3(local.x, 0.0, local.z).distance_to(clamped)


## The joker menu, GAME.md 3.7: held open while driving; cycle, pick, drop or destroy.
func _step_menu() -> void:
	menu_open = input.joker_menu and jokers.count() > 0
	if not menu_open:
		menu_index = 0
		return
	var count := jokers.count()
	if input.joker_next_pressed:
		menu_index = (menu_index + 1) % count
	if input.joker_prev_pressed:
		menu_index = posmod(menu_index - 1, count)
	if input.joker_select >= 0 and input.joker_select < count:
		menu_index = input.joker_select
	if input.joker_drop_pressed:
		drop_joker(menu_index)
	elif input.joker_destroy_pressed:
		destroy_joker(menu_index)
	menu_index = clampi(menu_index, 0, maxi(jokers.count() - 1, 0))


func _step_effects(delta: float) -> void:
	for effect: KartEffect in effects.duplicate():
		effect.time_left -= delta
		effect.step(self, delta)
		if effect.finished or effect.time_left <= 0.0:
			effect.end(self)
			effects.erase(effect)


## A bullet reached the kart. Returns false when it passes through, for example during spawn
## protection. A shield absorbs the hit and pops.
func take_hit(bullet: Bullet) -> bool:
	if not is_targetable():
		return false
	if shielded:
		pop_shield()
		return true
	die(&"bullet", bullet.owner_slot)
	return true


## A ramming kart reached this one: the shield pops or the kart dies.
func take_ram(rammer_slot: int) -> void:
	if not is_targetable():
		return
	if shielded:
		pop_shield()
		return
	die(&"ram", rammer_slot)


## Starts a timed effect, replacing one with the same id.
func add_effect(effect: KartEffect) -> void:
	end_effect(effect.id)
	effects.append(effect)
	effect.start(self)


## Ends an effect early, for example a shield that just popped. Silently ignores unknown ids.
func end_effect(id: StringName) -> void:
	for effect: KartEffect in effects.duplicate():
		if effect.id == id:
			effect.end(self)
			effects.erase(effect)


func has_effect(id: StringName) -> bool:
	for effect: KartEffect in effects:
		if effect.id == id:
			return true
	return false


func set_shielded(on: bool) -> void:
	shielded = on
	_shield_visual.visible = on


func pop_shield() -> void:
	end_effect(&"shield")
	set_shielded(false)


## Takes a power-up from a pad or the floor. The item is unusable until it is revealed.
func hold_item(item: PowerUp, reveal_time: float) -> void:
	held_item = item
	item_reveal_left = reveal_time
	item_held.emit(item)
	Events.item_picked.emit(slot, item.id)


func use_item() -> void:
	if held_item == null:
		return
	var item := held_item
	held_item = null
	item.activate(self)
	item_used.emit(item)
	Events.item_used.emit(slot, item.id)


## Pickups currently inside the pickup radius.
func overlapping_pickups() -> Array[Pickup]:
	var result: Array[Pickup] = []
	for area: Area3D in _pickup_area.get_overlapping_areas():
		var pickup := area as Pickup
		if pickup != null:
			result.append(pickup)
	return result


## Recomputes the pickup radius from the rules, the jokers and the Coin Magnet.
func refresh_pickup_radius() -> void:
	var radius := rules.pickup_radius
	for joker: Joker in jokers.jokers:
		radius = joker.modify_pickup_radius(radius)
	_pickup_shape.radius = radius * pickup_radius_bonus


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
	for effect: KartEffect in effects:
		effect.end(self)
	effects.clear()
	set_shielded(false)
	ramming = false
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
	collision_mask = Layers.WORLD | Layers.KART | Layers.PROTECTED | Layers.TURRET
	_body.visible = true
	_smoke.emitting = true
	for joker: Joker in jokers.jokers:
		joker.on_respawn(self)
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
	for joker: Joker in jokers.jokers:
		joker.on_turbo_pad(self)
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
		var collider := collision.get_collider()
		var other := collider as Kart
		var turret := collider as Turret
		if other != null:
			last_bump_slot = other.slot
			last_bump_time = Time.get_ticks_msec() * 0.001
			if ram_kills():
				other.take_ram(slot)
			motor.apply_bump(normal)
			velocity = motor.velocity
		elif turret != null and ramming:
			turret.destroy()
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
	_shield_visual = MeshInstance3D.new()
	_shield_visual.name = "Shield"
	var bubble := SphereMesh.new()
	bubble.radius = 1.25
	bubble.height = 2.5
	_shield_visual.mesh = bubble
	var bubble_material := StandardMaterial3D.new()
	bubble_material.albedo_color = Color(0.2, 0.8, 1.0, 0.3)
	bubble_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shield_visual.material_override = bubble_material
	_shield_visual.position = Vector3(0.0, 0.5, 0.0)
	_shield_visual.visible = false
	_shield_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shield_visual)


## Polled every tick rather than on entry, so a kart that unfreezes or spawns on top of a pickup
## still takes it.
func _collect_overlapping_pickups() -> void:
	for pickup: Pickup in overlapping_pickups():
		pickup.collect(self)
