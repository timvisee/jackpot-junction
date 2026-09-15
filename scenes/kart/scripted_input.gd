class_name ScriptedInput
extends KartInput
## Drives a lazy weaving loop with the occasional handbrake and a shot every few seconds, for
## smoke runs and dummy opponents.

var _time := 0.0


func poll(delta: float) -> void:
	_time += delta
	throttle = 1.0
	brake = 0.0
	steer = sin(_time * 0.7)
	handbrake = fmod(_time, 6.0) > 5.2
	var firing := fmod(_time, 2.5) < 0.05
	fire_pressed = firing and not fire
	fire = firing
