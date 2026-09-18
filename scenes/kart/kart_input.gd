class_name KartInput
extends RefCounted
## Control state for one kart for one physics tick. Subclasses fill it in [method poll]: a player
## reads the input map, a bot its brain, a network peer its replicated inputs.

## -1 is full left, 1 is full right.
var steer := 0.0
## 0 to 1.
var throttle := 0.0
## 0 to 1. Brakes while moving forward, reverses once stopped.
var brake := 0.0
var handbrake := false
## Held to burn nitro.
var nitro := false
## Free-aim direction on the floor plane from a stick, zero when idle.
var aim := Vector2.ZERO
var fire := false
## True only on the tick fire went down.
var fire_pressed := false
## True only on the tick the item button went down.
var use_item_pressed := false
## Joker menu: held open, cursor moves, direct slot picks (-1 for none), drop and destroy.
var joker_menu := false
var joker_prev_pressed := false
var joker_next_pressed := false
var joker_select := -1
var joker_drop_pressed := false
var joker_destroy_pressed := false


func poll(_delta: float) -> void:
	pass


## Where the machine at the other end says its kart ended this tick, GAME.md 10.3. Empty for
## anything driven here, which is everything except a remote player: a bot and a player at this
## keyboard are simulated on this machine and have nothing to claim.
func claimed_state() -> Array:
	return []


## Takes the wheel back off the far end for [param seconds], for the things it does not get to
## decide on its own: running into somebody, being hit, going down a hole, coming back.
func deny_claim(_seconds: float) -> void:
	pass


func clear() -> void:
	steer = 0.0
	throttle = 0.0
	brake = 0.0
	handbrake = false
	nitro = false
	aim = Vector2.ZERO
	fire = false
	fire_pressed = false
	use_item_pressed = false
	joker_menu = false
	joker_prev_pressed = false
	joker_next_pressed = false
	joker_select = -1
	joker_drop_pressed = false
	joker_destroy_pressed = false
