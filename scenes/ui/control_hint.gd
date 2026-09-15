class_name ControlHint
extends Label3D
## The drive and fire hint shown next to a human's kart at match start, GAME.md 3.8. Goes away
## once the player has both driven and fired, or after ten seconds.

const MAX_SECONDS := 10.0

var kart: Kart

var _driven := false
var _fired := false
var _age := 0.0


static func attach(target: Kart, device: int) -> ControlHint:
	var hint := ControlHint.new()
	hint.kart = target
	hint.text = hint_text(device)
	hint.font_size = 64
	hint.outline_size = 14
	hint.pixel_size = 0.01
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.no_depth_test = true
	hint.modulate = Palette.CHIP_WHITE
	hint.position = Vector3(0.0, 2.2, 0.0)
	target.add_child(hint)
	target.fired.connect(func(_bullets: Array[Bullet]) -> void: hint._fired = true)
	return hint


static func hint_text(device: int) -> String:
	var keyboard := (
		"%s / %s drive   %s fire"
		% [
			InputActions.binding_text(InputActions.THROTTLE, true).get_slice(",", 0),
			(
				InputActions.binding_text(InputActions.STEER_LEFT, true).get_slice(",", 0)
				+ "-"
				+ InputActions.binding_text(InputActions.STEER_RIGHT, true).get_slice(",", 0)
			),
			InputActions.binding_text(InputActions.FIRE, true).get_slice(",", 0),
		]
	)
	var gamepad := "Triggers drive   Left stick steer   RB fire"
	match device:
		DeviceInput.KEYBOARD:
			return keyboard
		DeviceInput.ANY:
			return keyboard + "\n" + gamepad
	return gamepad


func _process(delta: float) -> void:
	_age += delta
	if kart != null and kart.motor.speed() > 2.0:
		_driven = true
	if (_driven and _fired) or _age >= MAX_SECONDS:
		queue_free()
