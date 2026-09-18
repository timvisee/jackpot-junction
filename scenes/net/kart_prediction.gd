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
## Disagreements below this, in metres, are two machines rounding differently rather than
## disagreeing, and moving the kart for them would be a twitch in place of an error.
const IGNORE := 0.03
## Up to this far apart the kart is walked back into place over a few ticks rather than moved:
## about a kart's length, which is as far as a scrape along a wall or a bump ever puts it out.
const EASE := 2.0
## How much of what is left of an eased correction is taken each tick.
const EASE_RATE := 0.25
## The same allowance for the heading, in radians: about a third of a degree.
const HEADING_IGNORE := 0.006
## Past [constant EASE] the kart is simply put where the host says. That far apart is a respawn,
## a death, a blast or a pit, none of which is a difference of opinion about driving.

var kart: Kart
## The number of the last tick this client simulated and sent.
var seq := 0
## How far the last correction moved the kart, for the debug overlay and the tests.
var last_correction := 0.0
## How many ticks the last correction had to replay.
var last_replay := 0

## One entry per predicted tick: its number, the controls used, and the state it left the kart in.
var _history: Array[Dictionary] = []
## What is left of a correction being eased in, in world space.
var _ease := Vector3.ZERO


func _init(for_kart: Kart) -> void:
	kart = for_kart
	kart.predicted = true
	# The walls and the crates, and nothing that moves. Those are the same on both machines and
	# always there, so predicting against them is predicting against what the host will say.
	#
	# Other karts are deliberately left out. A client has only puppets of them, put where the
	# host last said rather than where they are now, so a predicted bump would be a guess at a
	# guess; and two karts each predicting their own side of the same contact would each shove
	# the other and neither would be right. A bump is the host's to settle and arrives as a
	# correction, which is what corrections are for.
	kart.collision_mask = Layers.WORLD


## One tick of movement and nothing else. Firing, items, pickups, scoring and damage are all left
## out: none is this machine's to decide, and a replay would do each of them again.
##
## [param live] is the tick as it happens rather than one being replayed. A replayed tick lays no
## tire marks and turns no wheels, because that already happened the first time round.
static func step(on: Kart, with: KartInput, delta: float, live: bool = true) -> void:
	var heading_before := on.motor.heading
	on.motor.step(with, delta)
	on.velocity = on.motor.velocity
	on.move_and_slide()
	KartCollisions.resolve(on, on.motor.velocity, true)
	on.motor.velocity = Vector3(on.velocity.x, 0.0, on.velocity.z)
	on.position.y = 0.0
	on.rotation = Vector3(0.0, on.motor.heading, 0.0)
	if live:
		on._spin_wheels(delta)
		on._update_trails(delta, heading_before)


## Where a kart is and what its motor is doing, as one value.
static func capture(on: Kart) -> Array:
	return [on.global_position.x, on.global_position.z] + on.motor.capture()


static func restore(on: Kart, state: Array) -> void:
	if state.size() < 3:
		return
	on.global_position = Vector3(state[0], 0.0, state[1])
	on.motor.restore(state.slice(2))
	on.rotation = Vector3(0.0, on.motor.heading, 0.0)
	on.velocity = on.motor.velocity


## Runs this tick on the kart and remembers it. Returns the tick's number, which goes on the wire
## with the controls so the host can say what it made of it.
##
## A correction still being eased in sits between where the kart is simulated and where it is
## drawn, so it comes off before the tick and goes back on after it: the simulation always runs
## from its own answer, and only the picture lags behind by the part of the error left to walk off.
func predict(with: KartInput, delta: float) -> int:
	seq += 1
	kart.global_position -= _ease
	step(kart, with, delta)
	_history.append({"seq": seq, "input": NetInput.encode(with), "state": capture(kart)})
	if _history.size() > HISTORY:
		_history = _history.slice(_history.size() - HISTORY)
	_ease *= 1.0 - EASE_RATE
	if _ease.length() <= IGNORE:
		_ease = Vector3.ZERO
	kart.global_position += _ease
	return seq


## The host's answer for tick [param ack]. Anything this client did after that tick is run again
## on top of it, so the kart ends up where its own controls say it should be by now rather than
## where it was a round trip ago.
func reconcile(ack: int, state: Array, delta: float) -> void:
	last_correction = 0.0
	last_replay = 0
	kart.global_position -= _ease
	var mine := _state_at(ack)
	_forget_through(ack)
	if not mine.is_empty() and _matches(mine, state):
		# The two machines drove the same tick the same way, which is the ordinary case and the
		# one worth being cheap about: nothing to replay, nothing to move, nothing to see.
		kart.global_position += _ease
		return
	var before := kart.global_position
	restore(kart, state)
	var replayed := KartInput.new()
	for entry: Dictionary in _history:
		_apply(replayed, entry["input"])
		step(kart, replayed, delta, false)
		entry["state"] = capture(kart)
		last_replay += 1
	var moved := before - kart.global_position
	last_correction = moved.length()
	# Under a few centimetres is two machines rounding differently rather than disagreeing, and
	# the kart keeps what it had. Past a kart's length it is a respawn, a blast or a pit, and the
	# kart simply goes where it is told. Between the two it walks back over the next few ticks.
	if last_correction <= IGNORE:
		kart.global_position = before
	elif last_correction <= EASE:
		_ease = moved
	else:
		_ease = Vector3.ZERO
	kart.global_position += _ease


## One line for the debug overlay: how far ahead of the host this machine is running, and what
## the last correction cost. Corrections at nought are the two machines agreeing, which is what
## this should read for most of a match on a decent wire.
func debug_text() -> String:
	if not kart.predicted:
		return "prediction off"
	return (
		"prediction %d ticks ahead  last correction %.3f m over %d ticks"
		% [_history.size(), last_correction, last_replay]
	)


## Stops driving and forgets what it was holding, for a kart that has died, been frozen on the
## grid or sent rolling out the end of the match. None of those is a state a player steers out
## of, and the ticks in the buffer are about to become history nobody will ask about.
func suspend() -> void:
	kart.predicted = false
	_history.clear()
	_ease = Vector3.ZERO
	last_correction = 0.0
	last_replay = 0


## Starts driving again, on whatever the host last said. Any tick numbered before now is one the
## host answered while nobody here was driving, so the count starts again above all of them.
func resume() -> void:
	kart.predicted = true
	_history.clear()
	_ease = Vector3.ZERO


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
