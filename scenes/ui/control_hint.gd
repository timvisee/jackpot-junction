class_name ControlHint
extends Node3D
## The drive and fire hint shown next to a human's kart at match start, GAME.md 3.8. Goes away
## once the player has both driven and fired, or after ten seconds. A player who is not pinned
## to one device sees whichever scheme they last touched, and it swaps over as they switch.
##
## The buttons are drawn rather than written, GAME.md 8.3, so the line is the same shape on both
## schemes: the throttle, the steering and the fire button, whatever they happen to be bound to.

const MAX_SECONDS := 10.0
## How big the buttons are drawn and how big that picture is in the world. Together these are
## about the size the line of text they replaced was, at a UI scale of 100%: it is drawn bigger with
## the rest of the UI, GAME.md 8.5, and drawn bigger rather than stretched, so it stays sharp.
const FONT_SIZE := 26
const PIXEL_SIZE := 0.010
const INK := Palette.CHIP_WHITE

var kart: Kart
var device := DeviceInput.ANY

var _driven := false
var _fired := false
var _age := 0.0
## Which scheme is currently drawn, so the picture is only rebuilt when the player switches.
var _shown := ""
var _row: Node3D


static func attach(target: Kart, for_device: int) -> ControlHint:
	var hint := ControlHint.new()
	hint.name = "ControlHint"
	hint.kart = target
	hint.device = for_device
	hint.position = Vector3(0.0, 2.2, 0.0)
	target.add_child(hint)
	# A method connection, not a lambda: it is dropped automatically when the hint is freed.
	target.fired.connect(hint._on_fired)
	hint._rebuild()
	return hint


## The hint for one device, as a keyboard line or a gamepad line but never both: a player reading
## this has one set of controls in their hands.
static func hint_row(for_device: int, size := FONT_SIZE) -> HBoxContainer:
	var keyboard := DeviceInput.uses_keyboard(for_device)
	var parts: Array = [
		InputHint.glyph(InputActions.THROTTLE, keyboard, INK, size),
		InputHint.pair(InputActions.STEER_LEFT, InputActions.STEER_RIGHT, keyboard, INK, size),
		InputHint.glyph(InputActions.FIRE, keyboard, INK, size),
	]
	return InputHint.row("%s drive   %s steer   %s fire", parts, INK, size)


## What the drawn line depends on, so a rebuild happens when the player picks up a pad and not on
## every frame of the ten seconds this is up for.
static func stamp(for_device: int) -> String:
	var keyboard := DeviceInput.uses_keyboard(for_device)
	var named: Array[String] = []
	for action: StringName in [InputActions.THROTTLE, InputActions.STEER_LEFT, InputActions.FIRE]:
		named.append(InputActions.short_binding_text(action, keyboard))
	return "%s|%s" % [keyboard, "/".join(named)]


func _exit_tree() -> void:
	if kart != null and is_instance_valid(kart) and kart.fired.is_connected(_on_fired):
		kart.fired.disconnect(_on_fired)


func _on_fired(_bullets: Array[Bullet]) -> void:
	_fired = true


## How big the hint is drawn: [constant FONT_SIZE] at the UI scale the screen has now.
func drawn_size() -> int:
	var scale := get_tree().root.content_scale_factor if is_inside_tree() else 1.0
	return roundi(FONT_SIZE * scale)


func _rebuild() -> void:
	var size := drawn_size()
	var wanted := "%s|%d" % [stamp(device), size]
	if wanted == _shown:
		return
	_shown = wanted
	if _row != null:
		_row.queue_free()
	_row = InputHint.billboard(InputHint.card(hint_row(device, size)), PIXEL_SIZE)
	add_child(_row)


func _process(delta: float) -> void:
	_age += delta
	_rebuild()
	if kart != null and kart.motor.speed() > 2.0:
		_driven = true
	if (_driven and _fired) or _age >= MAX_SECONDS:
		queue_free()
