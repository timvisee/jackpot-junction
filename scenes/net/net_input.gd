class_name NetInput
extends KartInput
## Control state received from a remote player, GAME.md 10.3.

## Each packet the client sends is one of its physics ticks, numbered, and the host plays them
## back one a tick. That matters more than it sounds: the client has already driven that tick
## itself and kept the answer, so a host that ran the same controls twice, or skipped one because
## two packets arrived together, would end up somewhere the client never predicted and correct it
## for a mistake neither of them made. One packet, one tick, in order.
##
## Packets arrive when the network feels like it, so a few are held back to smooth that out, and
## one-tick presses are merged rather than dropped when a packet has to be let go.

const FIELDS := 13
## Packets held waiting for their tick. Deep enough to ride out ordinary jitter, shallow enough
## that the queue is not itself a delay: past this the oldest are spent early to catch up, since
## a client that is running ahead should be met rather than followed.
const QUEUE_MAX := 6
## How many packets to have in hand before playing them out again after running dry. A tick with
## nothing to play is the one thing that costs a client its prediction: the kart moves on an
## input the client never numbered, so the two machines end up in places neither is wrong about
## and the client is corrected for it. Two ticks of slack is a thirtieth of a second of delay
## for everyone watching, and nothing at all for the player driving, who is not waiting on this.
const QUEUE_REFILL := 2
## How far a client's kart may be from where the host had it and still be believed, in meters. A
## tick of driving is a fifth of this at top speed, so anything past it is not a difference of
## opinion about physics: it is a kart somewhere else, and the host drives it itself instead.
const CLAIM_REACH := 2.0
## Seconds the host keeps the wheel after something it has to settle, GAME.md 10.3. Long enough
## for the client to be told and to stop arguing, short enough not to be felt as a lurch.
const CLAIM_DENIED := 0.4

## The newest packet number that has arrived, and the number the kart last actually drove. The
## second is what goes back to the client: a packet sitting in the queue has not moved anything
## yet, and a client replaying from it would replay from a tick that never ran.
var last_seq := 0
var applied_seq := 0
## Where the client says its kart ended the tick being played back, and how long the host is
## driving this kart itself whatever the client says.
var claim: Array = []
var denied_left := 0.0

var _queue: Array[Array] = []
## Set when the queue ran dry, cleared once there is enough in hand to run smoothly again.
var _starved := true
var _pending_fire_pressed := false
var _pending_use := false
var _pending_prev := false
var _pending_next := false
var _pending_select := -1
var _pending_drop := false
var _pending_destroy := false
var _pending_emote := -1


## What the far end says it did with this tick, for the host to follow rather than second-guess.
## Empty while the host holds the wheel, so the kart is simulated here instead.
func claimed_state() -> Array:
	return [] if denied_left > 0.0 else claim


func deny_claim(seconds: float) -> void:
	denied_left = maxf(denied_left, seconds)
	claim = []


## Packs a local input for the wire.
static func encode(source: KartInput) -> Array:
	return [
		source.steer,
		source.throttle,
		source.brake,
		source.handbrake,
		source.fire,
		source.fire_pressed,
		source.use_item_pressed,
		source.joker_menu,
		source.joker_prev_pressed,
		source.joker_next_pressed,
		source.joker_select,
		source.joker_drop_pressed,
		source.joker_destroy_pressed,
		source.aim,
		source.nitro,
		source.joker_inspect,
		source.cursor,
		source.emote,
	]


## Takes a packet from the client and puts it in the queue. Packets travel unreliably, so one
## that turns up out of order is older news than what is already here and is dropped.
func receive(state: Array, seq: int = 0, claimed: Array = []) -> void:
	if state.size() < FIELDS or seq <= last_seq:
		return
	last_seq = seq
	_queue.append([seq, state, claimed])
	while _queue.size() > QUEUE_MAX:
		# Too far behind to be worth playing out one at a time. The oldest is spent for its
		# presses, which are the part nobody can afford to lose, and its steering is skipped.
		_merge_presses(_queue.pop_front()[1])


## Plays back one tick of the client's controls. An empty queue means nothing has arrived for
## this tick, and the kart holds what it had: a player whose packet is late is still holding the
## throttle down, and letting go on their behalf would be worse than being a tick out of date.
func poll(delta: float) -> void:
	denied_left = maxf(denied_left - delta, 0.0)
	claim = []
	if _starved and _queue.size() >= QUEUE_REFILL:
		_starved = false
	if _queue.is_empty():
		_starved = true
	elif not _starved:
		var packet: Array = _queue.pop_front()
		applied_seq = packet[0]
		_apply(packet[1])
		claim = packet[2] if packet.size() > 2 else []
	fire_pressed = _pending_fire_pressed
	use_item_pressed = _pending_use
	joker_prev_pressed = _pending_prev
	joker_next_pressed = _pending_next
	joker_select = _pending_select
	joker_drop_pressed = _pending_drop
	joker_destroy_pressed = _pending_destroy
	emote = _pending_emote
	_pending_fire_pressed = false
	_pending_use = false
	_pending_prev = false
	_pending_next = false
	_pending_select = -1
	_pending_drop = false
	_pending_destroy = false
	_pending_emote = -1


## How many ticks of the client's driving are waiting. The host reports it so a client can see
## whether it is running ahead of the host or behind it.
func queued() -> int:
	return _queue.size()


func _apply(state: Array) -> void:
	steer = clampf(float(state[0]), -1.0, 1.0)
	throttle = clampf(float(state[1]), 0.0, 1.0)
	brake = clampf(float(state[2]), 0.0, 1.0)
	handbrake = bool(state[3])
	fire = bool(state[4])
	joker_menu = bool(state[7])
	if state.size() > FIELDS:
		aim = state[FIELDS]
	if state.size() > FIELDS + 1:
		nitro = bool(state[FIELDS + 1])
	# A card a finger rests on, GAME.md 4.2, which a client from before touch never sends.
	joker_inspect = int(state[FIELDS + 2]) if state.size() > FIELDS + 2 else -1
	# The push that walks the joker cursor, GAME.md 4.2, which a client from before simple driving
	# never sends: for it, the push was the wheel.
	cursor = clampf(float(state[FIELDS + 3]), -1.0, 1.0) if state.size() > FIELDS + 3 else steer
	_merge_presses(state)


## The one-tick presses, which are queued rather than read so the kart sees each exactly once
## however the packets arrive.
func _merge_presses(state: Array) -> void:
	_pending_fire_pressed = _pending_fire_pressed or bool(state[5])
	_pending_use = _pending_use or bool(state[6])
	_pending_prev = _pending_prev or bool(state[8])
	_pending_next = _pending_next or bool(state[9])
	if int(state[10]) >= 0:
		_pending_select = int(state[10])
	_pending_drop = _pending_drop or bool(state[11])
	_pending_destroy = _pending_destroy or bool(state[12])
	# An emote, GAME.md 3.8, which a client from before them never sends.
	if state.size() > FIELDS + 4 and int(state[FIELDS + 4]) >= 0:
		_pending_emote = int(state[FIELDS + 4])
