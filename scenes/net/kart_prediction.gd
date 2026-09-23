class_name KartPrediction
extends RefCounted
## A client driving its own kart ahead of the host, GAME.md 10.3. Kept apart from [Kart] so that
## file stays about what a kart is, the same way [KartCollisions] keeps contact response out of
## it and [KartAim] keeps the cannon's aim out.
##
## The client steps its own kart the moment the stick moves, numbers the tick, and keeps what it
## did. The host later says what it made of that same numbered tick. Where the two agree, which
## is nearly always, nothing happens at all. Where they differ, the kart is put back on the
## host's answer and every tick since is run again, so the correction lands in the present
## instead of dragging the kart back into the past.
##
## Only movement is predicted. Whether a coin was collected, a shot counted or a life was lost
## is the host's to say and arrives on its own.

## Ticks of history kept, a little over two seconds at 60 Hz. A correction older than the buffer
## cannot be replayed, so the kart takes the host's word for it and snaps.
const HISTORY := 140
## Disagreements below this, in meters, are not worth replaying a second of driving over. Ten
## centimeters is a tenth of a kart and nobody can see it, and the host decides everything that
## would actually turn on it anyway: what was collected, who was hit, what it was worth. Being
## relaxed here is the difference between correcting constantly and correcting when it matters.
const IGNORE := 0.10
## The same allowance for the heading, in radians: about a degree and a half.
const HEADING_IGNORE := 0.025
## How much of a correction still outstanding is taken each tick. A fifth walks an error off over
## about a fifth of a second, which is slow enough not to be seen and quick enough not to leave
## the picture behind the kart it is drawn from.
const EASE_RATE := 0.2
## The most the picture is ever allowed to lag the simulation by. Past this the kart on screen
## would be somewhere the kart is not, which is worse than the correction it is hiding.
const EASE_MAX := 1.2
## How many times an offset is halved looking for room to draw the kart in before giving up.
const EASE_TRIES := 4
## Past this, in meters, nothing is being hidden: the kart is simply put where the host says. A
## disagreement this size is a respawn, a death, a blast or a pit, not a difference of opinion
## about driving, and easing it in would send the kart gliding across the room.
const SNAP := 6.0

var kart: Kart
## The number of the last tick this client simulated. The numbering belongs to the session, not
## to this: every packet a client sends is numbered whether or not the kart is being driven, so a
## player who is dead and picking a joker is still heard.
var seq := 0
## How far the last correction moved the kart, for the debug overlay and the tests.
var last_correction := 0.0
## How many ticks the last correction had to replay.
var last_replay := 0
## How many corrections there have been in all, and how many of those were too big to hide.
var corrections := 0
var snaps := 0
## How many times the host simply took this machine's word for a tick, which is what most of a
## match should look like.
var accepted := 0
## How many of this kart's bullets the host last said were in the air. The cap on those is a rule
## worth keeping honest, GAME.md 5.1, and this machine cannot count them itself: it has no
## bullets of its own.
var host_live := 0
## How many times this machine has pulled the trigger for itself, for the tests and the overlay.
var pulls := 0
## How far the kart on screen actually moved because of the last correction, and how far it
## turned, which is the only part of any of this a player can see. Walking a correction in rather
## than applying it is meant to keep both at nothing; a snap is meant to show.
var last_jump := 0.0
var last_turn := 0.0
## The worst either of those has been all match, for the overlay.
var worst_jump := 0.0

## One entry per predicted tick: its number, the controls used, and the state it left the kart in.
var _history: Array[Dictionary] = []
## The ticks on which this machine pulled the trigger and the host has not answered for yet.
## Counted against the bullet cap alongside what the host last said was in the air.
var _shots: Array[int] = []

## What is left of a correction being eased in: where the picture still is relative to where the
## simulation says the kart is, and the same for which way it is pointing. Corrections add to
## these rather than replacing them, so the picture never jumps, it only ever stops lagging.
var _ease := Vector3.ZERO
var _ease_heading := 0.0


func _init(for_kart: Kart) -> void:
	kart = for_kart
	kart.predicted = true
	take_the_wheel()


## One tick of movement and nothing else. Firing, items, pickups, scoring and damage are all left
## out: none is this machine's to decide, and a replay would do each of them again.
##
## [param live] is the tick as it happens rather than one being replayed. A replayed tick lays no
## tire marks and turns no wheels, because that already happened the first time round.
static func step(on: Kart, with: KartInput, delta: float, live: bool = true) -> void:
	var heading_before := on.motor.heading
	# The kart reads its own controls in a few places rather than being handed them, so a replay
	# lends it the tick's controls for the length of the tick. Live, this is the same object.
	var held := on.input
	on.input = with
	if on.falling:
		# Down a hole. The drop is run here so it starts the moment the kart goes over the edge
		# rather than a round trip later, and stops there: the kart does not die of it on this
		# machine, it waits to be told.
		on._step_fall(delta)
		on.input = held
		return
	# Nitro is predicted, and has to be: it is the button with the most immediate effect in the
	# game, it changes how fast the kart is about to go, and it decides whether the kart goes
	# through a crate or bounces off it. A client that waited a round trip for it would spend
	# that round trip driving at the wrong speed and being corrected for it.
	on._step_nitro(delta)
	on.motor.step(with, delta)
	on.velocity = on.motor.velocity
	on.move_and_slide()
	KartCollisions.resolve(on, on.motor.velocity, true)
	on.motor.velocity = Vector3(on.velocity.x, 0.0, on.velocity.z)
	on.position.y = 0.0
	on.rotation = Vector3(0.0, on.motor.heading, 0.0)
	if live:
		on._spin_wheels(delta)
		KartVisuals.update_trails(on, delta, heading_before)
	on.input = held


## A kart driven from another machine ends the tick where that machine says it did, GAME.md 10.3.
## The host has just simulated it anyway, which is what settles anything it ran into and what
## catches a claim that is nonsense, but the answer a player sees on their own screen is the one
## that stands. Anything the host has to arbitrate takes the wheel back for a moment.
static func follow_claim(on: Kart) -> void:
	var claim := on.input.claimed_state()
	if claim.is_empty():
		return
	if on.global_position.distance_to(Vector3(claim[0], 0.0, claim[1])) > NetInput.CLAIM_REACH:
		# Not a difference of opinion about physics: a kart somewhere else entirely. The host
		# keeps this one, and says so, and the client puts itself right.
		on.input.deny_claim(NetInput.CLAIM_DENIED)
		return
	restore(on, claim)


## Where a kart is, what its motor is doing and what is in its nitro tank, as one value. The
## tank is in here rather than left to the snapshot because the client spends it as it goes: a
## figure a round trip out of date would have the gauge jumping back up every time one arrived.
static func capture(on: Kart) -> Array:
	return (
		[on.global_position.x, on.global_position.z]
		+ on.motor.capture()
		+ [on.nitro_charge, on.nitro_active]
	)


static func restore(on: Kart, state: Array) -> void:
	var motor_end := 2 + KartMotor.STATE_FIELDS.size()
	if state.size() < motor_end:
		return
	on.global_position = Vector3(state[0], 0.0, state[1])
	on.motor.restore(state.slice(2, motor_end))
	on.rotation = Vector3(0.0, on.motor.heading, 0.0)
	on.velocity = on.motor.velocity
	if state.size() > motor_end + 1:
		on.nitro_charge = state[motor_end]
		on._set_nitro_active(state[motor_end + 1])


## Runs tick [param at] on the kart and remembers it, under the number the session is about to
## send it with.
##
## A correction still being eased in sits between where the kart is simulated and where it is
## drawn, so it comes off before the tick and goes back on after it: the simulation always runs
## from its own answer, and only the picture lags behind by the part of the error left to walk off.
func predict(with: KartInput, delta: float, at: int) -> void:
	seq = at
	# A kart being driven here is solid, every tick, by asking rather than by remembering. Going
	# down a hole takes a kart's collisions away, and between losing them and being driven again
	# it has been dead, stood down and brought back by three different pieces of code; the one
	# time that was left to trust, a kart came back able to drive through walls for the rest of
	# the match. It is one comparison a tick to never have to reason about that again.
	if not kart.falling and kart.collision_mask == 0:
		take_the_wheel()
	kart.global_position -= _ease
	step(kart, with, delta)
	_history.append({"seq": seq, "input": NetInput.encode(with), "state": capture(kart)})
	if _history.size() > HISTORY:
		_history = _history.slice(_history.size() - HISTORY)
	_pull_trigger(with, delta, at)
	_wear_off()


## The trigger, answered here, GAME.md 10.3. The cannon goes on cooldown and the shot is heard on
## the tick the button went down; the bullet comes from the host a round trip later, because
## whether it lives depends on a bullet fired by somebody this machine only sees where they were.
## Everything about pulling a trigger that a player can feel is in the first half.
func _pull_trigger(with: KartInput, delta: float, at: int) -> void:
	kart.cannon.step(delta)
	if not with.fire or kart.protection_left > 0.0 or not _can_fire():
		return
	_shots.append(at)
	pulls += 1
	kart.cannon.pull_dry()
	# The hint that names the fire key comes down, the same as it would for anybody driving here.
	kart.fired.emit([] as Array[Bullet])
	# Heard here rather than waited for. The host's own word for this shot is thrown away on the
	# way in, see NetSession, so it is not heard twice.
	Events.bullet_fired.emit(kart.slot)


## Whether there is a shot to be had: the cannon is ready, and this kart is under the limit on
## bullets in the air once the ones the host has not heard about yet are counted.
func _can_fire() -> bool:
	if kart.cannon.cooldown_left > 0.0:
		return false
	return host_live + _shots.size() < kart.cannon.current_stats().max_live_bullets


## Takes this tick's share off whatever correction is still being walked in, and draws the kart
## where that leaves it. The simulation is always on its own answer; only the picture lags, and
## only by what is left to walk off.
func _wear_off() -> void:
	_ease *= 1.0 - EASE_RATE
	_ease_heading *= 1.0 - EASE_RATE
	if _ease.length() < 0.001:
		_ease = Vector3.ZERO
	if absf(_ease_heading) < 0.0005:
		_ease_heading = 0.0
	kart.global_position += _clear(_ease)
	kart.rotation = Vector3(0.0, kart.motor.heading + _ease_heading, 0.0)


## The part of an offset the kart can actually be drawn along without ending up inside a wall.
## The offset is a picture lagging behind a simulation, not a movement, so nothing tests it for
## collisions; up against a wall that is how a kart comes to be seen halfway through one.
func _clear(offset: Vector3) -> Vector3:
	if offset == Vector3.ZERO or not kart.test_move(kart.global_transform, offset):
		return offset
	# Something is in the way. Half of it, until it fits or there is nothing left worth moving.
	var shrunk := offset
	for i: int in EASE_TRIES:
		shrunk *= 0.5
		if not kart.test_move(kart.global_transform, shrunk):
			return shrunk
	return Vector3.ZERO


## The host's answer for tick [param ack]. Anything this client did after that tick is run again
## on top of it, so the kart ends up where its own controls say it should be by now rather than
## where it was a round trip ago.
func reconcile(ack: int, state: Array, delta: float) -> void:
	last_correction = 0.0
	last_replay = 0
	last_jump = 0.0
	last_turn = 0.0
	if kart.falling:
		# Over the edge and on the way down. The host is still a round trip behind and its answer
		# says the kart is driving along quite happily, which would lift it back out of the hole
		# to drive over it again and fall in a second time when the truth caught up. A fall is
		# not a guess to be talked out of: the kart is in the hole, and the host will say so.
		_history.clear()
		return
	# Where the kart is drawn right now. Whatever else this does, the honest measure of it is how
	# far that moves by the time it returns.
	var drawn := kart.global_position
	var drawn_facing := kart.rotation.y
	kart.global_position -= _ease
	var mine := _state_at(ack)
	_forget_through(ack)
	_forget_shots(ack)
	if not mine.is_empty() and _matches(mine, state):
		# The two machines drove the same tick the same way, which is the ordinary case and the
		# one worth being cheap about: nothing to replay, nothing to move, nothing to see.
		kart.global_position += _ease
		return
	var before := kart.global_position
	var facing := kart.motor.heading
	restore(kart, state)
	var replayed := KartInput.new()
	for entry: Dictionary in _history:
		_apply(replayed, entry["input"])
		step(kart, replayed, delta, false)
		entry["state"] = capture(kart)
		last_replay += 1
	var moved := before - kart.global_position
	last_correction = moved.length()
	corrections += 1
	if last_correction > SNAP:
		# Nothing to hide: the kart is somewhere else entirely, and gliding it across the room
		# would be a stranger thing to watch than arriving.
		snaps += 1
		_ease = Vector3.ZERO
		_ease_heading = 0.0
	else:
		# Added to what is still outstanding rather than replacing it. Replacing it would put
		# the picture back by however much was left, which is a jump, and a jump on every
		# correction is exactly the thing this is for avoiding.
		_ease = (_ease + moved).limit_length(EASE_MAX)
		_ease_heading = clampf(
			_ease_heading + wrapf(facing - kart.motor.heading, -PI, PI), -PI * 0.5, PI * 0.5
		)
	kart.global_position += _ease
	kart.rotation = Vector3(0.0, kart.motor.heading + _ease_heading, 0.0)
	last_jump = kart.global_position.distance_to(drawn)
	last_turn = absf(wrapf(kart.rotation.y - drawn_facing, -PI, PI))
	worst_jump = maxf(worst_jump, last_jump)
	Events.kart_corrected.emit(last_correction, last_correction > SNAP)


## One line for the debug overlay: how far ahead of the host this machine is running, and what
## the last correction cost. Corrections at nought are the two machines agreeing, which is what
## this should read for most of a match on a decent wire.
func debug_text() -> String:
	if not kart.predicted:
		return "prediction off"
	return (
		(
			"prediction %d ticks ahead  %d accepted, %d corrections, %d snapped  %d shots\n"
			+ "last %.2f m over %d ticks, moved the kart %.3f m  worst %.3f m"
		)
		% [
			_history.size(),
			accepted,
			corrections,
			snaps,
			pulls,
			last_correction,
			last_replay,
			last_jump,
			worst_jump,
		]
	)


## The host took this machine's word for tick [param ack]. Nothing to replay and nothing to move:
## the ticks up to it are done with, and the kart is already where both machines agree it is.
func accept(ack: int) -> void:
	last_correction = 0.0
	last_replay = 0
	last_jump = 0.0
	last_turn = 0.0
	accepted += 1
	_forget_through(ack)
	_forget_shots(ack)


## Gives the kart the physics of something being driven here: the walls and the crates, which
## are the same on both machines, and the other karts in this room, which are puppets on a layer
## of their own. Driving into somebody used to be the worst of it: the kart carried on through
## where they were standing and was then dragged back by the correction. A predicted bump is a
## guess at where they are, since a puppet is only ever where the host last said, but it is a
## much better guess than no bump at all.
##
## Set here and nowhere else, and checked on every tick that drives the kart. Falling down a hole
## takes a kart's collisions away, and a kart that has been down one has been dead, stood down and
## brought back by the time it is driven again: whatever it was left holding is not to be trusted.
func take_the_wheel() -> void:
	kart.collision_layer = Layers.PUPPET
	kart.collision_mask = Layers.WORLD | Layers.PUPPET


## Stops driving and forgets what it was holding, for a kart that has died, been frozen on the
## grid or sent rolling out the end of the match. None of those is a state a player steers out
## of, and the ticks in the buffer are about to become history nobody will ask about.
func suspend() -> void:
	kart.predicted = false
	_shots.clear()
	_history.clear()
	_ease = Vector3.ZERO
	_ease_heading = 0.0
	last_correction = 0.0
	last_replay = 0


## Starts driving again, on whatever the host last said. Any tick numbered before now is one the
## host answered while nobody here was driving, so the count starts again above all of them.
func resume() -> void:
	kart.predicted = true
	take_the_wheel()
	_history.clear()
	_ease = Vector3.ZERO
	_ease_heading = 0.0


## Shots the host has now answered for: whatever it said is in the air already counts them.
func _forget_shots(ack: int) -> void:
	while not _shots.is_empty() and _shots[0] <= ack:
		_shots.pop_front()


func _state_at(ack: int) -> Array:
	for entry: Dictionary in _history:
		if entry["seq"] == ack:
			return entry["state"]
	return []


func _forget_through(ack: int) -> void:
	while not _history.is_empty() and int(_history[0]["seq"]) <= ack:
		_history.pop_front()


## Whether the host's state and this client's own are the same tick as far as anyone can tell.
func _matches(mine: Array, theirs: Array) -> bool:
	if mine.size() != theirs.size():
		return false
	var apart := Vector2(mine[0] - theirs[0], mine[1] - theirs[1])
	if apart.length() > IGNORE:
		return false
	# A kart pointing somewhere else is as wrong as a kart standing somewhere else, and a heading
	# that is quietly out is what turns a straight into a curve over the next second of driving.
	return absf(wrapf(mine[2] - theirs[2], -PI, PI)) <= HEADING_IGNORE


## Puts a recorded packet back into a set of controls for the replay.
func _apply(into: KartInput, packet: Array) -> void:
	into.steer = packet[0]
	into.throttle = packet[1]
	into.brake = packet[2]
	into.handbrake = packet[3]
	into.fire = packet[4]
	into.aim = packet[13]
	into.nitro = packet[14]
