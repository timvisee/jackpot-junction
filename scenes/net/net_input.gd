class_name NetInput
extends KartInput
## Control state received from a remote player. The client sends its state every tick; one-tick
## presses are queued so the kart sees each exactly once, however the packets arrive.

const FIELDS := 13

var _pending_fire_pressed := false
var _pending_use := false
var _pending_prev := false
var _pending_next := false
var _pending_select := -1
var _pending_drop := false
var _pending_destroy := false


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
	]


## Applies a packet from the client.
func receive(state: Array) -> void:
	if state.size() < FIELDS:
		return
	steer = clampf(float(state[0]), -1.0, 1.0)
	throttle = clampf(float(state[1]), 0.0, 1.0)
	brake = clampf(float(state[2]), 0.0, 1.0)
	handbrake = bool(state[3])
	fire = bool(state[4])
	_pending_fire_pressed = _pending_fire_pressed or bool(state[5])
	_pending_use = _pending_use or bool(state[6])
	joker_menu = bool(state[7])
	_pending_prev = _pending_prev or bool(state[8])
	_pending_next = _pending_next or bool(state[9])
	if int(state[10]) >= 0:
		_pending_select = int(state[10])
	_pending_drop = _pending_drop or bool(state[11])
	_pending_destroy = _pending_destroy or bool(state[12])
	if state.size() > FIELDS:
		aim = state[FIELDS]
	if state.size() > FIELDS + 1:
		nitro = bool(state[FIELDS + 1])


## Moves queued presses into the one-tick fields and clears the queue.
func poll(_delta: float) -> void:
	fire_pressed = _pending_fire_pressed
	use_item_pressed = _pending_use
	joker_prev_pressed = _pending_prev
	joker_next_pressed = _pending_next
	joker_select = _pending_select
	joker_drop_pressed = _pending_drop
	joker_destroy_pressed = _pending_destroy
	_pending_fire_pressed = false
	_pending_use = false
	_pending_prev = false
	_pending_next = false
	_pending_select = -1
	_pending_drop = false
	_pending_destroy = false
