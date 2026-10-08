class_name Kart
extends CharacterBody3D
## A player's or bot's kart. Movement is planar, gravity-free and driven by a [KartMotor]; the
## [KartInput] decides who is at the wheel; the [Cannon] fires forward. Lives, death, falling
## into pits and spawn protection follow GAME.md 3.6: the first hit wounds, the second kills.

signal died(cause: StringName, killer_slot: int)
signal wounded(cause: StringName, by_slot: int)
signal rammed(by_slot: int)
## Another kart's ram reached this one, whatever came of it, see [method KartCollisions.ram].
signal ram_landed(by_slot: int)
signal respawned
signal fired(bullets: Array[Bullet])
signal turbo_taken(direction: Vector3)
signal coins_collected(amount: int)
signal mult_changed(amount: float, reason: StringName)
signal item_held(item: PowerUp)
signal item_used(item: PowerUp)
signal joker_dropped(joker: Joker)
## A bullet of [param by_slot]'s passed close without hitting, see [method graze].
signal grazed_by(by_slot: int)

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
## Which player color the kart and its bullets use.
@export var color_index := 0
## How this kart is dressed, GAME.md 4.4. Set before the kart enters the tree; the body is built
## from it once.
var style := KartStyle.new()

var input: KartInput = KartInput.new():
	set(value):
		input = value
		# Simple driving works the wheel for the player, GAME.md 4.2, so their controls have to
		# know which kart it is they are turning.
		var player := value as PlayerInput
		if player != null:
			player.kart = self
var motor: KartMotor
var cannon: Cannon
var bullet_system: BulletSystem
var pot := Pot.new()
var jokers: JokerHolder
## Set on decoys: the kart whose pot and credit this one feeds.
var decoy_owner: Kart
## How the last hit that could kill it came, beyond its cause, for the kill feed should it: by a
## decoy, off walls, see [signal Events.kill_detailed]. Told by whatever hits it, read by
## [KartDeath].
var kill_how: Dictionary = {}
## Seconds until a temporary kart such as a decoy expires; 0 means forever.
var lifetime := 0.0
## On a client: driven by snapshots from the host, never simulated.
var puppet := false
## The one kart on a client that its own player drives, GAME.md 10.3. Still a puppet for
## everything the host decides, but it moves itself rather than waiting for a round trip.
var predicted := false
## The shared resources the kart's own stat copies are rebuilt from when jokers change.
var base_stats: KartStats
var base_cannon_stats: CannonStats
## Whether the joker menu is held open, which held joker the cursor is on, and which way the
## wheel was last pushed while it is, read and written by [KartMenu].
var menu_open := false
var menu_index := 0
var menu_steer := 0
## Set by the match so jokers and items can roll dice deterministically.
var rng := RandomNumberGenerator.new()
var alive := true
## Hits left before death; a kart below the rules' count is wounded: darker and slower.
var lives := 2
## Whether a joker that banks of its own accord, Direct Debit, may: the tutorial says no until
## the Junction is in the room, GAME.md 9.4a.
var banks_passively := true
## Seconds a freshly wounded kart cannot be hit again.
var hurt_left := 0.0
var falling := false
## Set by the match during the countdown: no input, no movement.
var frozen := false
## Set while a menu here has the controls, GAME.md 9.6: frozen, unread and quiet, see [KartSound].
var held := false
## Set by the match at the whistle: the driver lets go of the wheel. The kart still rolls, but
## nobody steers it and nothing can touch it any more.
var coasting := false
var protection_left := 0.0
## How much of the aim assist this kart's next shot gets and how long it has been standing
## still, GAME.md 5.2. Worked out by [KartAim].
var assist_share := 1.0
var still_for := 0.0
## Fraction of the pot still to bank while on the Junction, -1 when not banking.
var channel_progress := -1.0
## Set by the Boost power-up: contact with another kart kills it.
var ramming := false
## Nitro tank from 0 to 1, and whether it is burning right now. Burning also kills on contact.
var nitro_charge := 1.0
## How much faster the tank refills than its own rate, set by the match from how hot the room
## is, GAME.md 8.4, and by the Junction while the kart stands on it, GAME.md 3.4. Two sources
## that multiply rather than one that overwrites, since each keeps writing its own every frame.
var nitro_recharge_scale := 1.0
var junction_recharge := 1.0
var nitro_active := false
var shielded := false
var held_item: PowerUp
## Seconds until a freshly taken item is revealed and usable.
var item_reveal_left := 0.0
var effects: Array[KartEffect] = []
## Multiplier on the pickup radius from the Chip Magnet.
var pickup_radius_bonus := 1.0
var last_bump_slot := -1
var last_bump_time := -INF
## Contact state kept for [KartCollisions]: whether the kart was already up against a wall last
## tick, so leaning on one is heard once, and how long until it may be heard hitting one again.
var touching_wall := false
var crash_wait := 0.0
## Seconds before a ram can reach this kart again, see [method KartCollisions.ram].
var ram_wait := 0.0
## The engine and tire voices, only on karts somebody drives on this machine; null otherwise.
var sound: KartSound
## Whether somebody sitting at this machine is driving this kart. Feedback meant for a driver
## rather than for the room follows this, so three bots cannot set it off.
var driven_here := false
## Where the rear wheels actually sit on the model, so the marks are laid under them rather than
## under a guess at the shape of a kart. Measured once: the rear wheels do not steer.
var rear_axle := 0.0
var rear_half_track := 0.0
## What the kart leaves behind it, read by [KartVisuals] when it draws the trails.
var tire_marks: TireMarks
var smoke: ExhaustSmoke

## Whether the free-aim arrow is showing. A snapshot carries it, so a watching client draws the
## same kart the driver sees, and the Swivel Cannon turns it on and off.
var aim_arrow_visible: bool:
	get:
		return _aim_arrow.visible
	set(value):
		_aim_arrow.visible = value

var _body: Node3D
var _tint: StandardMaterial3D
var _wheels: Array[MeshInstance3D] = []
var _ring: MeshInstance3D
var _pickup_area: Area3D
var _pickup_shape: SphereShape3D
var _shield_visual: MeshInstance3D
var _aim_arrow: MeshInstance3D
var _flame: NitroFlame
var _sparks: DriftSparks
var _crown: Node3D
var _nitro_recharge_wait := 0.0
var _puppet_target := Vector3.ZERO
var _puppet_heading := 0.0
var _puppet_velocity := Vector3.ZERO
var _puppet_has_target := false
var _aim_guide: AimGuide
var _fall_left := 0.0
var _graze_cooldown_left := 0.0
## Whether the kart was drifting last tick and whether that drift had earned its boost, so
## the moment one ends having earned it can be caught.
var _was_drifting := false
var _was_charged := false


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
	var axle := KartVisuals.rear_axle(self, _wheels)
	rear_axle = axle.y
	rear_half_track = axle.x
	tire_marks = TireMarks.new()
	tire_marks.name = "TireMarks"
	tire_marks.marks = style.marks
	add_child(tire_marks)
	smoke = ExhaustSmoke.new()
	smoke.name = "Smoke"
	smoke.position = Vector3(0.0, 0.35, stats.length * 0.5)
	smoke.dress(Palette.player_color(color_index), style.trail)
	add_child(smoke)
	var attached := KartVisuals.build_attachments(self)
	_pickup_area = attached["pickup_area"]
	_pickup_shape = attached["pickup_shape"]
	_ring = attached["ring"]
	_shield_visual = attached["shield"]
	_aim_arrow = attached["aim_arrow"]
	_crown = attached["crown"]
	_flame = attached["flame"]
	_sparks = attached["sparks"]
	rebuild_stats()


func _physics_process(delta: float) -> void:
	if puppet:
		# The one kart on a client its own player drives moves itself, GAME.md 10.3, and its
		# session steps it rather than this. Gliding it toward the host's last word as well
		# would be two hands on the same wheel.
		if not predicted:
			_step_puppet(delta)
		else:
			_step_sound(delta)
		return
	if not alive:
		# Dead is not gone. The hand is still yours to read through, GAME.md 3.7, and a player
		# waiting to come back is exactly the player with time to read it. Dropping and burning
		# are not: there is no kart to drop a card from, and the respawn pick is already asking
		# what to keep. The controls are polled for the whole slot by the match while it waits.
		KartMenu.step(self, false)
		_step_sound(delta)
		return
	if frozen or held:
		# Waiting on the grid nothing moves, but the throttle still revs the engine, GAME.md 8.4;
		# held under a menu the controls are the menu's, and are not read at all.
		if not held:
			input.poll(delta)
		_step_sound(delta)
		return
	if falling:
		_step_fall(delta)
		_step_sound(delta)
		return
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			die(&"expired", -1)
			return
	_step_protection(delta)
	_step_assist(delta)
	_graze_cooldown_left = maxf(_graze_cooldown_left - delta, 0.0)
	crash_wait = maxf(crash_wait - delta, 0.0)
	ram_wait = maxf(ram_wait - delta, 0.0)
	_step_effects(delta)
	input.poll(delta)
	_step_nitro(delta)
	cannon.step(delta)
	if input.fire and protection_left <= 0.0 and cannon.can_fire() and bullet_system != null:
		_fire()
	item_reveal_left = maxf(item_reveal_left - delta, 0.0)
	KartMenu.step(self)
	if not menu_open and input.use_item_pressed and held_item != null and item_reveal_left <= 0.0:
		use_item()
	var heading_before := motor.heading
	var from := global_position
	motor.step(input, delta)
	velocity = motor.velocity
	move_and_slide()
	KartCollisions.resolve(self, motor.velocity)
	motor.velocity = Vector3(velocity.x, 0.0, velocity.z)
	position.y = 0.0
	rotation = Vector3(0.0, motor.heading, 0.0)
	KartPrediction.follow_claim(self, from)
	_collect_overlapping_pickups()
	_spin_wheels(delta)
	_step_crown(delta)
	KartVisuals.update_trails(self, delta, heading_before)
	_step_sound(delta)


## Whether the kart is in play: alive, on the floor and with somebody at the wheel. Zones,
## hazards and the stats all sit this one out, so nothing scores or trips a kart that is only
## rolling out the end of the match or waiting for the countdown.
func is_active() -> bool:
	return alive and not falling and not frozen and not held and not coasting


## True while bullets may hit and aim assist may pick this kart. A kart on the line for the
## countdown is still fair game once the flag drops; one rolling out the finish never is.
func is_targetable() -> bool:
	if coasting:
		return false
	return alive and not falling and protection_left <= 0.0 and hurt_left <= 0.0


func is_wounded() -> bool:
	return lives < KartLives.most(self)


## The match is over, GAME.md 2. The kart is handed a blank set of controls rather than being
## stopped dead, so it rolls out of whatever it was in the middle of and comes to a halt on its
## own. Nobody can drive it, hurt it or drop it down a pit while it does.
func coast() -> void:
	coasting = true
	input = KartInput.new()
	menu_open = false


## Gives the kart its own engine and tires, or takes them away again, GAME.md 8.4. A kart
## nobody here is driving takes the lean version: one engine, one squeal, a little quieter and
## detuned off the others. A puppet counts as driven by somebody, just not here.
func enable_sound(on: bool, lean: bool = false) -> void:
	driven_here = on and not lean
	if sound != null and (not on or sound.lean != lean):
		sound.queue_free()
		sound = null
	if not on or sound != null:
		return
	sound = KartSound.new()
	sound.name = "Sound"
	sound.setup(self, load("res://data/kart/sound.tres"), lean)
	add_child(sound)


func _step_sound(delta: float) -> void:
	if sound != null:
		sound.step(delta)


## Turns the kart into a client-side puppet: no physics of its own, visuals from snapshots. It
## keeps a layer of its own so the one kart this client drives has the others to bump into, and
## no mask, because nothing may push a puppet off where the host put it.
func make_puppet() -> void:
	puppet = true
	collision_layer = Layers.PUPPET
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
		# A dead kart is not in the way. The host takes a kart's collisions off it when it dies,
		# and a puppet is never killed here, so until now nobody had: a kart somebody had just
		# shot went invisible and stayed solid, and the spot it died on could not be driven
		# through until it came back.
		collision_layer = 0
		collision_mask = 0
	if alive and not was_alive:
		# Back on the floor, which is the host's to place. A respawn is a teleport rather than
		# driving, so it is one of the few things a kart driven here still takes from the
		# snapshot: without it a kart that went down a hole would come back still standing in
		# the hole, and fall down it again, for ever.
		scale = Vector3.ONE
		global_position = target
		motor.heading = state["h"]
		rotation = Vector3(0.0, motor.heading, 0.0)
		motor.velocity = Vector3.ZERO
		motor.forward_speed = 0.0
		# Moved before it is made solid again, and in that order. A kart that fell down a hole is
		# still standing in one until it is put back, and a hole notices a kart the moment the
		# kart is something it can notice: made solid where it died, it would be dropped down the
		# same hole again on the frame it came back from it.
		falling = false
		collision_layer = Layers.PUPPET
	# A kart this client is driving takes its pose from its own driving and its corrections from
	# the message addressed to it, GAME.md 10.3. The broadcast snapshot is a third of a second of
	# round trip out of date for this one kart, and putting it here would undo the prediction
	# thirty times a second. Everything below is the host's either way.
	if not predicted:
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
		motor.drift_time = state.get("drift_time", 0.0)
	protection_left = 1.0 if state["prot"] else 0.0
	var blink := fmod(Time.get_ticks_msec() * 0.001, BLINK_PERIOD) < BLINK_PERIOD * 0.5
	_body.visible = alive and (protection_left <= 0.0 or blink)
	smoke.emitting = alive
	set_shielded(state["shield"])
	channel_progress = state["ring"]
	_aim_arrow.visible = state["aim"]
	if not predicted:
		# A kart driven here burns its own nitro and lights its own flame, GAME.md 10.3. The
		# host's word for it is a round trip old, and laying that over the top is what made
		# nitro flicker on a client: lit here, put out by the next snapshot, lit again.
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
		_step_sound(delta)
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
	KartVisuals.update_trails(self, delta, heading_before)
	_step_sound(delta)


func _step_crown(delta: float) -> void:
	if not _crown.visible:
		return
	_crown.rotate_y(2.2 * delta)
	_crown.position.y = KartVisuals.CROWN_HEIGHT + sin(Time.get_ticks_msec() * 0.004) * 0.08


func is_decoy() -> bool:
	return decoy_owner != null


## Where the cannon points: forward, or the free-aim direction while a swivel cannon is active.
## Where this kart is pointing its cannon, see [KartAim].
func aim_direction() -> Vector3:
	return KartAim.direction(self)


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
func graze(by_slot: int) -> void:
	if not is_targetable() or _graze_cooldown_left > 0.0:
		return
	grazed_by.emit(by_slot)
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
		var burned := jokers.remove_at(index)
		Events.joker_destroyed.emit(slot, burned.id if burned != null else &"")


## The sparks off the rear wheels, GAME.md 4.3: white while the drift is still earning its
## exit boost, gold once it has, and a flash off the back the moment the boost is taken.
##
## The flash is worked out from the drift ending with enough time on it, which is the same
## condition that pays the boost, rather than from the boost itself. A kart being watched
## across the network has the drift and its length from the snapshot but not the boost, and
## a receipt nobody else can see is not much of a receipt.
func step_drift_sparks() -> void:
	var charged := motor.boost_earned()
	_sparks.set_state(motor.drifting, charged)
	if _was_drifting and not motor.drifting and _was_charged:
		_sparks.pop()
		if driven_here:
			Events.drift_boosted.emit(slot)
	_was_drifting = motor.drifting
	_was_charged = charged


func _process(_delta: float) -> void:
	_ring.visible = channel_progress >= 0.0 and alive
	if _ring.visible:
		var radius := lerpf(RING_RADIUS_EMPTY, RING_RADIUS_FULL, channel_progress)
		_ring.scale = Vector3(radius, 1.0, radius)
	_aim_guide = KartAim.draw(self, _aim_arrow, _aim_guide)


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
		var rate := nitro_recharge_scale * junction_recharge / stats.nitro_recharge_seconds
		nitro_charge = minf(nitro_charge + delta * rate, 1.0)


## Adds a fraction of a tank, for example the half tank a kill hands out.
func refill_nitro(fraction: float) -> void:
	var before := nitro_charge
	nitro_charge = minf(nitro_charge + fraction, 1.0)
	if nitro_charge > before:
		Events.nitro_gained.emit(slot)


func _set_nitro_active(on: bool) -> void:
	# A puppet raises nothing. It is told, GAME.md 10.3: a client predicting its own nitro would
	# otherwise announce it here and again when the host's word for the same tank arrives.
	if on and not nitro_active and not puppet:
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


## A bullet reached the kart. Returns true when the bullet is spent on it, which includes a
## kart's own harmless shot and anybody's while it cannot be hurt, see [method
## KartCollisions.shrugs_off], and false when it passes through. A shield absorbs the hit and pops;
## otherwise the hit costs a life.
func take_hit(bullet: Bullet) -> bool:
	if not is_targetable():
		return KartCollisions.shrugs_off(self, bullet)
	if bullet.owner_slot == slot and not rules.own_bullets_hurt:
		# Your own shot stops on you rather than carrying on through: it simply does no harm,
		# and it does not cost a shield either.
		return true
	Events.kart_shot.emit(slot, bullet.owner_slot)
	if shielded:
		pop_shield()
		return true
	var cause := &"turret" if bullet.from_turret else &"bullet"
	if not KartLives.spared(self, cause):
		_take_lethal(cause, bullet.owner_slot)
	return true


## A ramming kart reached this one: the shield pops or the kart dies. See [method
## KartCollisions.ram] for the ram that finds it too freshly hurt for that.
func take_ram(rammer_slot: int) -> void:
	_take_through_shield(&"ram", rammer_slot)


## A bomb went off within reach: the shield pops or the kart dies, credited to the bomb's owner.
func take_blast(owner_slot: int) -> void:
	_take_through_shield(&"bomb", owner_slot)


## A hit the shield is allowed to answer for: it pops instead, and the kart lives.
func _take_through_shield(cause: StringName, by_slot: int) -> void:
	if not is_targetable():
		return
	if shielded:
		pop_shield()
		return
	if not KartLives.spared(self, cause):
		_take_lethal(cause, by_slot)


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


## Patches a wounded kart up to full lives: the Junction does it, and so does a kill, unless a
## joker says nothing may, see [KartLives].
func restore_life() -> void:
	if not alive or not is_wounded() or not KartLives.healable(self):
		return
	lives = KartLives.most(self)
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
	var running := effects.size()
	var loaded := cannon.override_shots_left()
	item.activate(self)
	# Whatever it started is named after it, so the HUD of 8.3 can say what is running on a kart
	# without knowing what any one power-up does. A cannon power-up loads shots rather than
	# starting an effect, so it is named the same way.
	for i: int in range(running, effects.size()):
		effects[i].display_name = item.display_name
		effects[i].color = item.color
		effects[i].item_id = item.id
	if cannon.override_shots_left() > loaded:
		cannon.override_name = item.display_name
		cannon.override_color = item.color
		cannon.override_item = item.id
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


## Recomputes the pickup radius from the rules, the jokers and the Chip Magnet.
func refresh_pickup_radius() -> void:
	_pickup_shape.radius = pickup_reach()


## How far the kart reaches for a pickup: the rules', bent by the jokers and the Chip Magnet.
func pickup_reach() -> float:
	var radius := rules.pickup_radius
	for joker: Joker in jokers.jokers:
		radius = joker.modify_pickup_radius(radius)
	return radius * pickup_radius_bonus


## Kills the kart. The match decides when and where it respawns.
func die(cause: StringName, killer_slot: int) -> void:
	# A puppet is never killed here; it is told, GAME.md 10.3. A client predicting its own fall
	# down a hole runs the drop and stops there: whether that cost a life, and whose fault it
	# was, is the host's to say and arrives in the snapshot.
	if not alive or puppet:
		return
	input.deny_claim(NetInput.CLAIM_DENIED)
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
	smoke.emitting = false
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
	input.deny_claim(NetInput.CLAIM_DENIED)
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
	lives = KartLives.most(self)
	hurt_left = 0.0
	_apply_wounds()
	protection_left = protection
	collision_layer = Layers.PROTECTED if protection > 0.0 else Layers.KART
	collision_mask = Layers.WORLD | Layers.KART | Layers.PROTECTED | Layers.TURRET
	_body.visible = true
	smoke.emitting = true
	for joker: Joker in jokers.jokers:
		joker.on_respawn(self)
	respawned.emit()


## Called by a [Pit]: the kart drops out of control for a moment, then dies. The last kart that
## bumped it recently gets the credit.
func start_fall() -> void:
	if not alive or falling or coasting:
		return
	input.deny_claim(NetInput.CLAIM_DENIED)
	falling = true
	_fall_left = rules.pit_fall_time
	if not puppet:
		# A puppet raises nothing; the host relays the sound for the fall it decides on.
		Events.kart_fell.emit(slot)
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
	if not alive or falling or frozen or held or motor.spinning():
		return
	# Losing the tires is something that happens to a driver rather than something they did, and
	# no client can see it coming: the stain is the host's and so is the direction it throws the
	# kart. So the host keeps the wheel while it plays out, GAME.md 10.3.
	input.deny_claim(NetInput.CLAIM_DENIED)
	motor.apply_spin_out(direction)
	Events.oil_hit.emit(slot)


## Called by a [TurboPad] when the kart drives over it.
func apply_turbo(direction: Vector3) -> void:
	if not alive or falling:
		return
	motor.apply_turbo(direction)
	if puppet:
		# Predicted here: the shove is movement and movement is this machine's to work out. What
		# the pad was worth, what the jokers make of it and the sound of it are the host's, and
		# the host is driving over the same pad a moment later.
		return
	for joker: Joker in jokers.jokers:
		joker.on_turbo_pad(self)
	turbo_taken.emit(direction)
	Events.turbo_taken.emit(slot)


func _fire() -> void:
	var direction := KartAim.steered(self, aim_direction())
	var origin := global_position + direction * cannon_stats.muzzle_offset
	var shots := cannon.fire(
		bullet_system, slot, origin, direction, Palette.player_color(color_index), global_position
	)
	for bullet: Bullet in shots:
		bullet.apply_assist_share(assist_share)
		bullet.from_decoy = is_decoy()
	fired.emit(shots)
	Events.bullet_fired.emit(slot)


## How long the kart has been standing still and how much of the aim assist that leaves it,
## GAME.md 5.2.
func _step_assist(delta: float) -> void:
	var moving := (
		cannon_stats != null and motor.speed_fraction() >= cannon_stats.assist_moving_fraction
	)
	still_for = 0.0 if moving else still_for + delta
	assist_share = KartAim.assist_share(cannon_stats, still_for)


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
