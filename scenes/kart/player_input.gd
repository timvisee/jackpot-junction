class_name PlayerInput
extends KartInput
## Reads the input map for one device. [constant DeviceInput.ANY] lets every device drive the
## kart, which suits single-player; local multiplayer gives each slot its own device.

## The emote wheel on the right stick, GAME.md 3.8: pushed past [constant WHEEL_PUSH] it comes up
## and stays while the stick is held, pointing at the one the stick points at; pushed to
## [constant FLICK] it is armed; let go, armed, it asks for the one it was last pointing at, and
## unarmed it asks for nothing. A flick is all three in a moment. It used to ask the moment the
## stick passed the flick, so the wheel was up for the tick or two a flick takes, and nobody saw
## what was on it.
const FLICK := 0.8
const WHEEL_PUSH := 0.35
## How long the wheel stays open after the key for it if nothing is picked, GAME.md 3.8.
const WHEEL_TIME := 3.0

## Whether somebody at this machine is typing into a box, their name in the pause menu, GAME.md
## 4.4. The keys are the box's then: a player on the keyboard sits still rather than driving round
## the room with the letters of their name, online, where the room goes on under the menu.
static var typing := false

var device := DeviceInput.ANY
## The emote wheel as this player has it, for [EmoteWheel] to draw, GAME.md 3.8: whether the key
## for it has opened it, when the four ways pick rather than drive, which of the four the right
## stick points at, or -1, and whether the stick has been to the edge, so letting go asks for it.
var wheel_by_keys := false
var wheel_pointing := -1
var wheel_armed := false
## For an any-device player, the device that last produced input; ANY until something moved.
var last_device := DeviceInput.ANY
## The local seat this player sits in, whose way to drive in the settings they follow, GAME.md 4.2,
## or -1 for one that works the wheel and pedals whatever the settings say: a tool, or a test.
var seat := -1
## The kart these controls drive, for simple driving, which has to know which way it points. The
## kart sets it itself when it is handed them.
var kart: Kart

## How long the wheel stays open after its key.
var _wheel_left := 0.0
var _fire_was_down := false
var _use_was_down := false
var _was_down: Dictionary[StringName, bool] = {}
var _simple := SimpleDrive.new()


func _init(input_device: int = DeviceInput.ANY, local_seat := -1) -> void:
	device = input_device
	seat = local_seat


## Whether this player drives the simple way, GAME.md 4.2: a way on the screen to go, rather than a
## wheel and pedals.
func simple() -> bool:
	return seat >= 0 and Game.settings.drive_mode(seat) == Settings.DRIVE_SIMPLE


func poll(delta: float) -> void:
	if typing and device in [DeviceInput.KEYBOARD, DeviceInput.ANY]:
		clear()
		return
	if device == DeviceInput.ANY:
		_detect_device()
	steer = (
		DeviceInput.strength(InputActions.STEER_RIGHT, device)
		- DeviceInput.strength(InputActions.STEER_LEFT, device)
	)
	handbrake = DeviceInput.pressed(InputActions.HANDBRAKE, device)
	nitro = DeviceInput.pressed(InputActions.NITRO, device)
	# A touch screen is one more device, GAME.md 4.2, for the one player at it: the one who reads
	# every device rather than a pad of their own.
	var touch := TouchInput.enabled and device == DeviceInput.ANY
	if touch:
		steer = clampf(steer + TouchInput.steer, -1.0, 1.0)
		handbrake = handbrake or TouchInput.handbrake
		nitro = nitro or TouchInput.nitro
	cursor = steer
	if simple():
		_drive_simply(touch, delta)
	else:
		_simple.wanted = Vector3.ZERO
		throttle = DeviceInput.strength(InputActions.THROTTLE, device)
		brake = DeviceInput.strength(InputActions.BRAKE, device)
		if touch:
			throttle = maxf(throttle, TouchInput.throttle)
			brake = maxf(brake, TouchInput.brake)
	aim = Vector2(
		(
			DeviceInput.strength(InputActions.AIM_RIGHT, device)
			- DeviceInput.strength(InputActions.AIM_LEFT, device)
		),
		(
			DeviceInput.strength(InputActions.AIM_DOWN, device)
			- DeviceInput.strength(InputActions.AIM_UP, device)
		)
	)
	fire = DeviceInput.pressed(InputActions.FIRE, device) or (touch and TouchInput.fire)
	fire_pressed = fire and not _fire_was_down
	_fire_was_down = fire
	var use_down := (
		DeviceInput.pressed(InputActions.USE_ITEM, device) or (touch and TouchInput.use_item)
	)
	use_item_pressed = use_down and not _use_was_down
	_use_was_down = use_down
	joker_menu = DeviceInput.pressed(InputActions.JOKER_MENU, device)
	joker_prev_pressed = _just_pressed(InputActions.JOKER_PREV)
	joker_next_pressed = _just_pressed(InputActions.JOKER_NEXT)
	joker_drop_pressed = _just_pressed(InputActions.JOKER_DROP)
	# The jokers are pointed at by a finger on a touch screen, and by the mouse for the player on
	# the keyboard anywhere else, see [MouseJokers]: the same cards, kept open the same way, and
	# the same button under the pick to skip it.
	var pointer := touch or MouseJokers.player == self
	joker_destroy_pressed = (
		_just_pressed(InputActions.JOKER_DESTROY) or (pointer and TouchInput.take_back())
	)
	_poll_emote(delta, touch)
	# While the wheel is open the four ways are its, not the kart's.
	if wheel_by_keys:
		steer = 0.0
		cursor = 0.0
		throttle = 0.0
		brake = 0.0
	joker_inspect = TouchInput.joker_inspect if pointer else -1
	pick_inspect = TouchInput.pick_inspect if touch else -1
	joker_select = -1
	for i: int in InputActions.JOKER_SELECTS.size():
		if _just_pressed(InputActions.JOKER_SELECTS[i]):
			joker_select = i
	# A card of the respawn pick tapped is the number key for it.
	var tapped := TouchInput.take_tap() if pointer else -1
	if tapped >= 0:
		joker_select = tapped
	# A joker dropped or destroyed from its pane is the key for it, on the card the pane was for.
	var dropped := TouchInput.take_drop() if pointer else -1
	var destroyed := TouchInput.take_destroy() if pointer else -1
	if dropped >= 0:
		joker_inspect = dropped
		joker_drop_pressed = true
	elif destroyed >= 0:
		joker_inspect = destroyed
		joker_destroy_pressed = true


## The wheel and the pedals worked for the player from the way they push, GAME.md 4.2: left and
## right as they steer, up and down the screen as the two keys or the stick's other half, and the
## touch screen's stick either way.
func _drive_simply(touch: bool, delta: float) -> void:
	var push := Vector2(
		steer,
		(
			DeviceInput.strength(InputActions.DRIVE_DOWN, device)
			- DeviceInput.strength(InputActions.DRIVE_UP, device)
		)
	)
	if touch:
		push.y += TouchInput.stick.y
	var here := kart if kart != null and is_instance_valid(kart) else null
	# A kart that is down comes back somewhere else facing another way, and is not to be turned
	# round to face whichever way its player pushed last before it went.
	if here != null and not here.alive:
		_simple.wanted = Vector3.ZERO
	var camera: Camera3D = null
	if here != null and here.is_inside_tree():
		camera = here.get_viewport().get_camera_3d()
	var motor := here.motor if here != null else null
	_simple.drive(self, push.limit_length(1.0), SimpleDrive.screen_axes(camera), motor, delta)
	# A pad's own gas and brake, the triggers, still work the pedals while either is pressed, over
	# what the push asked for. Only the pad's: on a keyboard the same keys are up and down.
	var pedals := _pad_pedals()
	if pedals != Vector2.ZERO:
		throttle = pedals.x
		brake = pedals.y


## An emote, GAME.md 3.8: a key each, or the right stick flicked up, right, down or left, in
## that order, from the middle. Not while the stick is aiming a cannon that aims freely, which is
## what it is for then.
## An emote from its key, from the wheel's key and then a way, from a flick of the right stick or
## from the touch screen's menu of them; and the wheel for the right stick while it is pushed
## toward one, until it has asked for it.
func _poll_emote(delta: float, touch: bool) -> void:
	emote = -1
	for i: int in InputActions.EMOTES.size():
		if _just_pressed(InputActions.EMOTES[i]):
			emote = i
	# Every tick, whether the wheel is open or not, so a way already held when it opens is not a
	# pick of it.
	var ways: Array[bool] = []
	for way: StringName in InputActions.WHEEL_WAYS:
		ways.append(_just_pressed(way))
	if _just_pressed(InputActions.EMOTE_WHEEL):
		_wheel_left = 0.0 if _wheel_left > 0.0 else WHEEL_TIME
	elif _wheel_left > 0.0:
		_wheel_left -= delta
		if ways.has(true):
			emote = ways.find(true)
			_wheel_left = 0.0
	wheel_by_keys = _wheel_left > 0.0
	var tapped := TouchInput.take_emote() if touch else -1
	if tapped >= 0:
		emote = tapped
	var pushed := aim.length()
	var here := kart if kart != null and is_instance_valid(kart) else null
	# Not while the stick is aiming a cannon that aims freely, which is what it is for then.
	if here != null and KartAim.free_aim(here):
		wheel_pointing = -1
		wheel_armed = false
		return
	if pushed > WHEEL_PUSH:
		wheel_pointing = posmod(roundi(rad_to_deg(atan2(aim.x, -aim.y)) / 90.0), 4)
		wheel_armed = wheel_armed or pushed >= FLICK
		return
	# Let go: the one it was last pointing at, coming back from the edge in a straight line, if it
	# got there, and nothing if it did not.
	if wheel_armed and wheel_pointing >= 0:
		emote = wheel_pointing
	wheel_pointing = -1
	wheel_armed = false


## How far the pad's own gas and brake are down, as x and y: the triggers, unless rebound.
func _pad_pedals() -> Vector2:
	return Vector2(
		DeviceInput.pad_strength(InputActions.THROTTLE, device),
		DeviceInput.pad_strength(InputActions.BRAKE, device)
	)


## Which device is active right now, checked on the driving and firing actions.
func _detect_device() -> void:
	var actions: Array[StringName] = [
		InputActions.THROTTLE,
		InputActions.BRAKE,
		InputActions.STEER_LEFT,
		InputActions.STEER_RIGHT,
		InputActions.DRIVE_UP,
		InputActions.DRIVE_DOWN,
		InputActions.FIRE
	]
	for joypad: int in Input.get_connected_joypads():
		for action: StringName in actions:
			if DeviceInput.strength(action, joypad) > 0.2:
				last_device = joypad
				return
	for action: StringName in actions:
		if DeviceInput.strength(action, DeviceInput.KEYBOARD) > 0.2:
			last_device = DeviceInput.KEYBOARD
			return


func _just_pressed(action: StringName) -> bool:
	var down := DeviceInput.pressed(action, device)
	var was: bool = _was_down.get(action, false)
	_was_down[action] = down
	return down and not was
