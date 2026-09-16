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
## Smoothing rate for puppets, per second: how fast they close in on the latest snapshot.
const PUPPET_SMOOTHING := 18.0
## Beyond this distance a puppet snaps instead of gliding, for example after a respawn.
const PUPPET_SNAP_DISTANCE := 4.0
const KART_MODEL := preload("res://assets/models/car-kit/kart-oobi.glb")
const MODEL_SCALE := 1.12
const MODEL_LIFT := 0.235
const MARKER_HEIGHT := 1.75
const FALL_SPEED := 2.5
const FALL_SPIN := 7.0
const BLINK_PERIOD := 0.25
const RING_RADIUS_EMPTY := 0.6
const RING_RADIUS_FULL := 1.4

@export var stats: KartStats
@export var cannon_stats: CannonStats
@export var rules: MatchRules
## Player slot, 0 to 3, decides who gets the credit.
@export var slot := 0
## Which player colour the kart and its bullets use.
@export var color_index := 0

var input: KartInput = KartInput.new()
var motor: KartMotor
var cannon: Cannon
var bullet_system: BulletSystem
var pot := Pot.new()
var jokers: JokerHolder
## Set on decoys: the kart whose pot and credit this one feeds.
var decoy_owner: Kart
## Seconds until a temporary kart such as a decoy expires; 0 means forever.
var lifetime := 0.0
## On a client: driven by snapshots from the host, never simulated.
var puppet := false
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
## Nitro tank from 0 to 1, and whether it is burning right now. Burning also kills on contact.
var nitro_charge := 1.0
var nitro_active := false
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
var _wheels: Array[MeshInstance3D] = []
var _ring: MeshInstance3D
var _pickup_area: Area3D
var _tire_marks: TireMarks
var _smoke: ExhaustSmoke
var _pickup_shape: SphereShape3D
var _shield_visual: MeshInstance3D
var _aim_arrow: MeshInstance3D
var _flame: MeshInstance3D
var _nitro_recharge_wait := 0.0
var _puppet_target := Vector3.ZERO
var _puppet_heading := 0.0
var _puppet_velocity := Vector3.ZERO
var _puppet_has_target := false
var _aim_guide: AimGuide
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
	if puppet:
		_step_puppet(delta)
		return
	if not alive or frozen:
		return
	if falling:
		_step_fall(delta)
		return
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			die(&"expired", -1)
			return
	_step_protection(delta)
	_graze_cooldown_left = maxf(_graze_cooldown_left - delta, 0.0)
	_step_effects(delta)
	input.poll(delta)
	_step_nitro(delta)
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
	_spin_wheels(delta)
	_update_trails(delta, heading_before)


## True while bullets may hit and aim assist may pick this kart.
func is_targetable() -> bool:
	return alive and not falling and protection_left <= 0.0


## Turns the kart into a client-side puppet: no physics, no collisions, visuals from snapshots.
func make_puppet() -> void:
	puppet = true
	collision_layer = 0
	collision_mask = 0
	remove_from_group(Bullet.TARGET_GROUP)


## Records one snapshot entry for a puppet: the pose becomes a target the physics step glides
## toward, while life state and effect visuals apply at once.
func apply_puppet_state(state: Dictionary, _delta: float) -> void:
	var target := Vector3(state["x"], 0.0, state["z"])
	var was_alive := alive
	alive = state["alive"]
	var far := global_position.distance_to(target) > PUPPET_SNAP_DISTANCE
	if not _puppet_has_target or not alive or not was_alive or far:
		global_position = target
		motor.heading = state["h"]
		rotation = Vector3(0.0, motor.heading, 0.0)
	_puppet_target = target
	_puppet_heading = state["h"]
	_puppet_velocity = Vector3(state.get("vx", 0.0), 0.0, state.get("vz", 0.0))
	_puppet_has_target = true
	motor.drifting = state["drift"]
	protection_left = 1.0 if state["prot"] else 0.0
	var blink := fmod(Time.get_ticks_msec() * 0.001, BLINK_PERIOD) < BLINK_PERIOD * 0.5
	_body.visible = alive and (protection_left <= 0.0 or blink)
	_smoke.emitting = alive
	set_shielded(state["shield"])
	channel_progress = state["ring"]
	_aim_arrow.visible = state["aim"]
	_flame.visible = state.get("nitro", false)


## Glides a puppet toward its extrapolated snapshot target every physics tick, so movement stays
## smooth between the host's 30 Hz snapshots and rendering interpolation has a steady source.
func _step_puppet(delta: float) -> void:
	if not _puppet_has_target or not alive:
		motor.velocity = Vector3.ZERO
		return
	_puppet_target += _puppet_velocity * delta
	var blend := 1.0 - exp(-PUPPET_SMOOTHING * delta)
	var heading_before := motor.heading
	var previous := global_position
	global_position = previous.lerp(_puppet_target, blend)
	motor.heading = lerp_angle(motor.heading, _puppet_heading, blend)
	rotation = Vector3(0.0, motor.heading, 0.0)
	motor.velocity = (global_position - previous) / maxf(delta, 0.0001)
	motor.forward_speed = motor.velocity.dot(motor.forward_vector())
	_spin_wheels(delta)
	_update_trails(delta, heading_before)


func is_decoy() -> bool:
	return decoy_owner != null


## Where the cannon points: forward, or the free-aim direction while a swivel cannon is active.
func aim_direction() -> Vector3:
	var forward := -global_basis.z
	if not cannon.current_stats().free_aim:
		return forward
	if input.aim.length() > 0.3:
		return Vector3(input.aim.x, 0.0, input.aim.y).normalized()
	var mouse := _mouse_aim_direction()
	return mouse if mouse != Vector3.ZERO else forward


func set_aim_arrow_visible(on: bool) -> void:
	_aim_arrow.visible = on


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
## A decoy hands everything to its owner.
func collect_coins(amount: int, source: Pickup) -> void:
	if is_decoy():
		if is_instance_valid(decoy_owner) and decoy_owner.alive:
			decoy_owner.collect_coins(amount, source)
		return
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
	if is_decoy():
		if is_instance_valid(decoy_owner) and decoy_owner.alive:
			decoy_owner.gain_mult(amount, reason)
		return
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


## Whether contact kills other karts right now: Boost, nitro, or a joker such as Road Rage.
func ram_kills() -> bool:
	if ramming or nitro_active:
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


## The floor point under the mouse, as a direction from the kart, for free aim on keyboard.
func _mouse_aim_direction() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.ZERO
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var normal := camera.project_ray_normal(mouse)
	if absf(normal.y) < 0.0001:
		return Vector3.ZERO
	var t := (Bullet.HEIGHT - from.y) / normal.y
	if t < 0.0:
		return Vector3.ZERO
	var point := from + normal * t
	var direction := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	return direction.normalized() if direction.length() > 0.2 else Vector3.ZERO


func _process(_delta: float) -> void:
	_ring.visible = channel_progress >= 0.0 and alive
	if _ring.visible:
		var radius := lerpf(RING_RADIUS_EMPTY, RING_RADIUS_FULL, channel_progress)
		_ring.scale = Vector3(radius, 1.0, radius)
	if _aim_arrow.visible and alive:
		var direction := aim_direction()
		_aim_arrow.global_position = global_position + Vector3(0.0, 0.9, 0.0) + direction * 0.9
		_aim_arrow.look_at(_aim_arrow.global_position + direction, Vector3.UP)
	_update_aim_guide()


## The aim guide shows for local players when the setting is on.
func _update_aim_guide() -> void:
	var wanted := alive and not puppet and input is PlayerInput and Game.settings.aim_guide
	if wanted and _aim_guide == null:
		_aim_guide = AimGuide.attach(self, Palette.player_color(color_index))
	if _aim_guide == null:
		return
	_aim_guide.visible = wanted
	if wanted:
		var direction := aim_direction()
		_aim_guide.update_line(global_position + direction * cannon_stats.muzzle_offset, direction)


## Nitro, GAME.md 4.1: hold to burn a limited tank for extra speed and ramming kills; it refills
## slowly after a short pause.
func _step_nitro(delta: float) -> void:
	var can_start := nitro_active or nitro_charge >= stats.nitro_min_start
	if input.nitro and can_start and nitro_charge > 0.0 and not falling:
		if not nitro_active:
			_set_nitro_active(true)
		nitro_charge = maxf(nitro_charge - delta / stats.nitro_capacity_seconds, 0.0)
		_nitro_recharge_wait = stats.nitro_recharge_delay
		if nitro_charge <= 0.0:
			_set_nitro_active(false)
		return
	if nitro_active:
		_set_nitro_active(false)
	if input.nitro:
		# Holding the button on an empty tank does not refill it; let go first.
		_nitro_recharge_wait = stats.nitro_recharge_delay
		return
	_nitro_recharge_wait = maxf(_nitro_recharge_wait - delta, 0.0)
	if _nitro_recharge_wait <= 0.0:
		nitro_charge = minf(nitro_charge + delta / stats.nitro_recharge_seconds, 1.0)


func _set_nitro_active(on: bool) -> void:
	if on and not nitro_active:
		Events.nitro_started.emit(slot)
	nitro_active = on
	motor.nitro_bonus = stats.nitro_speed_multiplier if on else 1.0
	_flame.visible = on


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
	Events.shield_popped.emit(slot)


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
	_set_nitro_active(false)
	_body.visible = false
	_smoke.emitting = false
	channel_progress = -1.0
	died.emit(cause, killer_slot)
	if is_decoy():
		queue_free()


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
	nitro_charge = 1.0
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
	Events.turbo_taken.emit(slot)


func _fire() -> void:
	var direction := aim_direction()
	var origin := global_position + direction * cannon_stats.muzzle_offset
	var shots := cannon.fire(
		bullet_system, slot, origin, direction, Palette.player_color(color_index)
	)
	fired.emit(shots)
	Events.bullet_fired.emit(slot)


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
			if pre.length() > 3.0:
				Events.kart_bumped.emit(slot)
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
	var slip := absf(motor.slip_angle())
	if motor.drifting or slip > 0.3:
		intensity = clampf(slip / 0.7, 0.5, 1.0)
	elif input.handbrake and speed > 1.5:
		# A straight handbrake stop lays down locked-wheel skid marks.
		intensity = 0.85
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
	var skidding := input.handbrake and speed > 1.5
	var pushing := motor.boosting() or motor.turboing() or nitro_active
	_smoke.update_state(input.throttle, motor.drifting or skidding, pushing)


func _build_visuals() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	var model: Node3D = KART_MODEL.instantiate()
	model.name = "Model"
	# The model drives toward its +Z; Godot's forward is -Z.
	model.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	model.scale = Vector3.ONE * MODEL_SCALE
	model.position = Vector3(0.0, MODEL_LIFT, 0.0)
	_body.add_child(model)
	var tint := StandardMaterial3D.new()
	tint.albedo_color = Palette.player_color(color_index)
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var lower := mesh.name.to_lower()
		if lower.begins_with("wheel"):
			_wheels.append(mesh)
		elif not lower.contains("character"):
			mesh.material_override = tint
	_body.add_child(_roof_marker())


## A distinct shape per slot above the driver, so colours are not the only way to tell karts apart.
func _roof_marker() -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	marker.name = "RoofMarker"
	var shapes: Array[Mesh] = [
		SphereMesh.new(),
		BoxMesh.new(),
		PrismMesh.new(),
		TorusMesh.new(),
		CylinderMesh.new(),
		CapsuleMesh.new()
	]
	var mesh: Mesh = shapes[posmod(slot, shapes.size())]
	if mesh is SphereMesh:
		(mesh as SphereMesh).radius = 0.16
		(mesh as SphereMesh).height = 0.32
	elif mesh is BoxMesh:
		(mesh as BoxMesh).size = Vector3.ONE * 0.28
	elif mesh is PrismMesh:
		(mesh as PrismMesh).size = Vector3(0.32, 0.3, 0.32)
	elif mesh is TorusMesh:
		(mesh as TorusMesh).inner_radius = 0.08
		(mesh as TorusMesh).outer_radius = 0.18
	elif mesh is CylinderMesh:
		(mesh as CylinderMesh).top_radius = 0.14
		(mesh as CylinderMesh).bottom_radius = 0.14
		(mesh as CylinderMesh).height = 0.26
	elif mesh is CapsuleMesh:
		(mesh as CapsuleMesh).radius = 0.11
		(mesh as CapsuleMesh).height = 0.36
	marker.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Palette.player_color(color_index)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = material
	marker.position = Vector3(0.0, MARKER_HEIGHT, 0.0)
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return marker


func _spin_wheels(delta: float) -> void:
	var turn := motor.forward_speed / WHEEL_RADIUS * delta
	for wheel: MeshInstance3D in _wheels:
		wheel.rotation.x += turn
		if wheel.name.to_lower().contains("front"):
			# Steering right is a clockwise turn seen from above, a negative rotation about +Y.
			wheel.rotation.y = -motor.steer * 0.35


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
	_aim_arrow = MeshInstance3D.new()
	_aim_arrow.name = "AimArrow"
	var arrow := PrismMesh.new()
	arrow.size = Vector3(0.35, 0.5, 0.08)
	_aim_arrow.mesh = arrow
	var arrow_material := StandardMaterial3D.new()
	arrow_material.albedo_color = Palette.NEON_CYAN
	arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aim_arrow.material_override = arrow_material
	_aim_arrow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_aim_arrow.top_level = true
	_aim_arrow.visible = false
	add_child(_aim_arrow)
	_flame = MeshInstance3D.new()
	_flame.name = "Flame"
	var flame_mesh := CylinderMesh.new()
	flame_mesh.top_radius = 0.02
	flame_mesh.bottom_radius = 0.22
	flame_mesh.height = 1.1
	_flame.mesh = flame_mesh
	var flame_material := StandardMaterial3D.new()
	flame_material.albedo_color = Color(0.4, 0.75, 1.0, 0.85)
	flame_material.emission_enabled = true
	flame_material.emission = Color(0.4, 0.75, 1.0)
	flame_material.emission_energy_multiplier = 2.5
	flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flame.material_override = flame_material
	# The cylinder's axis is Y; point the tip backward along +Z from the rear of the kart.
	_flame.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_flame.position = Vector3(0.0, 0.4, stats.length * 0.5 + 0.45)
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flame.visible = false
	add_child(_flame)


## Polled every tick rather than on entry, so a kart that unfreezes or spawns on top of a pickup
## still takes it.
func _collect_overlapping_pickups() -> void:
	for pickup: Pickup in overlapping_pickups():
		pickup.collect(self)
