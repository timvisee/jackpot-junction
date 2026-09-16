class_name Kart
extends CharacterBody3D
## A player's or bot's kart. Movement is planar, gravity-free and driven by a [KartMotor]; the
## [KartInput] decides who is at the wheel; the [Cannon] fires forward. Lives, death, falling
## into pits and spawn protection follow GAME.md 3.6: the first hit wounds, the second kills.

signal died(cause: StringName, killer_slot: int)
signal wounded(cause: StringName, by_slot: int)
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
const FALL_SPEED := 2.5
const FALL_SPIN := 7.0
const BLINK_PERIOD := 0.25
## A quicker flicker for the moment of immunity after losing a life, so it reads as brief.
const HURT_BLINK_PERIOD := 0.12
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
## Hits left before death; a kart below the rules' count is wounded: darker and slower.
var lives := 2
## Seconds a freshly wounded kart cannot be hit again.
var hurt_left := 0.0
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
var _tint: StandardMaterial3D
var _wheels: Array[MeshInstance3D] = []
var _ring: MeshInstance3D
var _pickup_area: Area3D
var _tire_marks: TireMarks
var _smoke: ExhaustSmoke
var _pickup_shape: SphereShape3D
var _shield_visual: MeshInstance3D
var _aim_arrow: MeshInstance3D
var _flame: NitroFlame
var _crown: Node3D
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
	lives = rules.lives
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
	var parts := KartVisuals.build_body(self)
	_body = parts["body"]
	_tint = parts["tint"]
	_wheels.assign(parts["wheels"])
	_tire_marks = TireMarks.new()
	_tire_marks.name = "TireMarks"
	add_child(_tire_marks)
	_smoke = ExhaustSmoke.new()
	_smoke.name = "Smoke"
	_smoke.position = Vector3(0.0, 0.35, stats.length * 0.5)
	add_child(_smoke)
	var attached := KartVisuals.build_attachments(self)
	_pickup_area = attached["pickup_area"]
	_pickup_shape = attached["pickup_shape"]
	_ring = attached["ring"]
	_shield_visual = attached["shield"]
	_aim_arrow = attached["aim_arrow"]
	_crown = attached["crown"]
	_flame = attached["flame"]
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
	_step_crown(delta)
	_update_trails(delta, heading_before)


## True while bullets may hit and aim assist may pick this kart.
func is_targetable() -> bool:
	return alive and not falling and protection_left <= 0.0 and hurt_left <= 0.0


func is_wounded() -> bool:
	return lives < rules.lives


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
	if was_alive and not alive:
		Burst.spawn(get_parent(), global_position, Palette.player_color(color_index), 1.0, 20)
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
	_flame.set_active(state.get("nitro", false))
	var new_lives: int = state.get("lives", rules.lives)
	if new_lives != lives:
		lives = new_lives
		_apply_wounds()


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


func _step_crown(delta: float) -> void:
	if not _crown.visible:
		return
	_crown.rotate_y(2.2 * delta)
	_crown.position.y = KartVisuals.CROWN_HEIGHT + sin(Time.get_ticks_msec() * 0.004) * 0.08


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
	if input is PlayerInput:
		# The accessibility setting scales the built-in assist. Jokers come after it, so Curve
		# Ball still curves for a player who turned the assist off.
		var strength := clampf(Game.settings.aim_assist, 0.0, 1.0)
		cannon_stats.aim_assist_cone_deg *= strength
		cannon_stats.aim_assist_turn_rate_deg *= strength
		cannon_stats.aim_assist = cannon_stats.aim_assist and strength > 0.0
	for joker: Joker in jokers.jokers:
		joker.modify_kart_stats(stats)
		joker.modify_cannon_stats(cannon_stats)
	if is_wounded():
		stats.top_speed *= rules.wounded_speed
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


## Nitro, GAME.md 4.1: hold to burn a limited tank for extra speed and ramming kills. It refills
## very slowly after a short pause; kills top it up, respawning does not.
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


## Adds a fraction of a tank, for example the half tank a kill hands out.
func refill_nitro(fraction: float) -> void:
	var before := nitro_charge
	nitro_charge = minf(nitro_charge + fraction, 1.0)
	if nitro_charge > before:
		Events.nitro_gained.emit(slot)


func _set_nitro_active(on: bool) -> void:
	if on and not nitro_active:
		Events.nitro_started.emit(slot)
	nitro_active = on
	motor.nitro_bonus = stats.nitro_speed_multiplier if on else 1.0
	_flame.set_active(on)


func _step_effects(delta: float) -> void:
	for effect: KartEffect in effects.duplicate():
		effect.time_left -= delta
		effect.step(self, delta)
		if effect.finished or effect.time_left <= 0.0:
			effect.end(self)
			effects.erase(effect)


## A bullet reached the kart. Returns false when it passes through, for example during spawn
## protection. A shield absorbs the hit and pops; otherwise the hit costs a life.
func take_hit(bullet: Bullet) -> bool:
	if not is_targetable():
		return false
	if shielded:
		pop_shield()
		return true
	_take_lethal(&"bullet", bullet.owner_slot)
	return true


## A ramming kart reached this one: the shield pops or the kart dies.
func take_ram(rammer_slot: int) -> void:
	if not is_targetable():
		return
	if shielded:
		pop_shield()
		return
	_take_lethal(&"ram", rammer_slot)


## A bomb went off within reach: the shield pops or the kart dies, credited to the bomb's owner.
func take_blast(owner_slot: int) -> void:
	if not is_targetable():
		return
	if shielded:
		pop_shield()
		return
	_take_lethal(&"bomb", owner_slot)


## A lethal hit: a kart with a life to spare loses it and limps on, darker, slower and for a
## moment untouchable; otherwise it dies. Pits skip this and kill outright.
func _take_lethal(cause: StringName, by_slot: int) -> void:
	if lives > 1:
		lives -= 1
		hurt_left = rules.hurt_protection
		_apply_wounds()
		wounded.emit(cause, by_slot)
		Events.kart_wounded.emit(slot, by_slot, cause)
		return
	die(cause, by_slot)


## Patches a wounded kart up to full lives: the Junction does it, and so does a kill.
func restore_life() -> void:
	if not alive or not is_wounded():
		return
	lives = rules.lives
	_apply_wounds()
	Events.life_restored.emit(slot)


## The darker body and lower top speed of a wounded kart, or the normal ones when healed.
func _apply_wounds() -> void:
	var color := Palette.player_color(color_index)
	_tint.albedo_color = color.darkened(0.5) if is_wounded() else color
	rebuild_stats()


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
	set_bounty(false)
	_set_nitro_active(false)
	_body.visible = false
	_smoke.emitting = false
	channel_progress = -1.0
	if cause != &"pit":
		# A kart that falls down a pit shrinks away instead; everything else pops.
		Burst.spawn(get_parent(), global_position, Palette.player_color(color_index), 1.0, 20)
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
	lives = rules.lives
	hurt_left = 0.0
	_apply_wounds()
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


## Called by an [OilStain] when the kart crosses it: the tires let go and the kart spins.
func hit_oil(direction: float) -> void:
	if not alive or falling or frozen or motor.spinning():
		return
	motor.apply_spin_out(direction)
	Events.oil_hit.emit(slot)


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
	var direction := _auto_aimed(aim_direction())
	var origin := global_position + direction * cannon_stats.muzzle_offset
	var shots := cannon.fire(
		bullet_system, slot, origin, direction, Palette.player_color(color_index), global_position
	)
	fired.emit(shots)
	Events.bullet_fired.emit(slot)


## Aimbot, GAME.md 7.3: turns the shot part of the way toward the nearest enemy in front, up
## to [member CannonStats.auto_aim_deg]. Without the joker that is zero and the shot goes
## exactly where the kart points.
func _auto_aimed(direction: Vector3) -> Vector3:
	var active := cannon.current_stats()
	if active.auto_aim_deg <= 0.0:
		return direction
	var target := Bullet.nearest_target(get_tree(), global_position, slot, active.auto_aim_range)
	if target == null:
		return direction
	return (
		Bullet
		. steer_toward(
			direction,
			global_position,
			target.global_position,
			deg_to_rad(90.0),
			active.auto_aim_range,
			deg_to_rad(active.auto_aim_deg)
		)
		. normalized()
	)


## Both kinds of invulnerability, GAME.md 3.6: the spawn protection a kart comes back with,
## and the moment after losing a life during which a second bullet cannot finish the job. Both
## blink the body, the second one faster, so the player can see they are safe for a moment.
func _step_protection(delta: float) -> void:
	var was_protected := protection_left > 0.0
	protection_left = maxf(protection_left - delta, 0.0)
	hurt_left = maxf(hurt_left - delta, 0.0)
	if was_protected and protection_left <= 0.0:
		collision_layer = Layers.KART
	if protection_left > 0.0:
		_body.visible = fmod(protection_left, BLINK_PERIOD) < BLINK_PERIOD * 0.5
	elif hurt_left > 0.0:
		_body.visible = fmod(hurt_left, HURT_BLINK_PERIOD) < HURT_BLINK_PERIOD * 0.6
	else:
		_body.visible = true


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
			if not motor.apply_wall_glance(normal, pre):
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
	if motor.spinning():
		intensity = 1.0
	elif motor.drifting or slip > 0.3:
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


## A gold crown over the roof marker while there is a price on this kart's head, GAME.md 3.10.
func set_bounty(on: bool) -> void:
	_crown.visible = on


func has_bounty() -> bool:
	return _crown.visible


func _spin_wheels(delta: float) -> void:
	var turn := motor.forward_speed / WHEEL_RADIUS * delta
	for wheel: MeshInstance3D in _wheels:
		wheel.rotation.x += turn
		if wheel.name.to_lower().contains("front"):
			# Steering right is a clockwise turn seen from above, a negative rotation about +Y.
			wheel.rotation.y = -motor.steer * 0.35


## Polled every tick rather than on entry, so a kart that unfreezes or spawns on top of a pickup
## still takes it.
func _collect_overlapping_pickups() -> void:
	for pickup: Pickup in overlapping_pickups():
		pickup.collect(self)
