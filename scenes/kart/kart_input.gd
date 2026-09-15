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
var fire := false
## True only on the tick fire went down.
var fire_pressed := false
## True only on the tick the item button went down.
var use_item_pressed := false


func poll(_delta: float) -> void:
	pass


func clear() -> void:
	steer = 0.0
	throttle = 0.0
	brake = 0.0
	handbrake = false
	fire = false
	fire_pressed = false
	use_item_pressed = false
