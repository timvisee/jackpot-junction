class_name ControlHint
extends Label3D
## The drive and fire hint shown next to a human's kart at match start, GAME.md 3.8. Goes away
## once the player has both driven and fired, or after ten seconds. A player who is not pinned
## to one device sees whichever scheme they last touched, and it swaps over as they switch.

const MAX_SECONDS := 10.0

var kart: Kart
var device := DeviceInput.ANY

var _driven := false
var _fired := false
var _age := 0.0


static func attach(target: Kart, for_device: int) -> ControlHint:
	var hint := ControlHint.new()
	hint.kart = target
	hint.device = for_device
	hint.text = hint_text(for_device)
	hint.font_size = 64
	hint.outline_size = 14
	hint.pixel_size = 0.01
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.no_depth_test = true
	hint.modulate = Palette.CHIP_WHITE
	hint.position = Vector3(0.0, 2.2, 0.0)
	target.add_child(hint)
	# A method connection, not a lambda: it is dropped automatically when the hint is freed.
	target.fired.connect(hint._on_fired)
	return hint


## The hint for one device, as a key line or a gamepad line but never both: a player reading
## this has one set of controls in their hands.
static func hint_text(for_device: int) -> String:
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
	# The fire button comes from the bindings, the same as the keyboard line: naming it here
	# meant it went on saying RB long after firing had moved off the shoulder.
	var gamepad := (
		"Triggers drive   Left stick steer   %s fire"
		% InputActions.binding_text(InputActions.FIRE, false).get_slice(",", 0)
	)
	return keyboard if DeviceInput.uses_keyboard(for_device) else gamepad


func _exit_tree() -> void:
	if kart != null and is_instance_valid(kart) and kart.fired.is_connected(_on_fired):
		kart.fired.disconnect(_on_fired)


func _on_fired(_bullets: Array[Bullet]) -> void:
	_fired = true


func _process(delta: float) -> void:
	_age += delta
	text = hint_text(device)
	if kart != null and kart.motor.speed() > 2.0:
		_driven = true
	if (_driven and _fired) or _age >= MAX_SECONDS:
		queue_free()
