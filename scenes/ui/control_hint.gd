class_name ControlHint
extends Node3D
## The drive and fire hint shown next to a human's kart at match start, GAME.md 3.8: once for each
## seat at this machine, in the first room it plays in, the lobby's as a rule, and at the start of
## every map only with Always show drive hints on, 8.5; shown every map, it was a nag. Goes away
## once the player has both driven and fired, or after ten seconds. A player who is not pinned
## to one device sees whichever scheme they last touched, and it swaps over as they switch.
##
## The buttons are drawn rather than written, GAME.md 8.3, so the line is the same shape on both
## schemes: the throttle, the steering and the fire button, whatever they happen to be bound to.
## It hangs over the kart as a [ScreenHint], the same size on the screen wherever the camera is.
## In simple driving, GAME.md 4.2, the way to go is all there is to driving, and it says so; with
## Auto throttle off, the stick steers and the gas is said too.

const MAX_SECONDS := 10.0
## How often the line is checked against what it should say: a rebinding or a pad picked up
## shows within a quarter of a second, and the check is a string of every binding built.
const RECHECK := 0.25
const INK := Palette.CHIP_WHITE

## The seats at this machine shown the hint since the game was started, see [method due].
static var shown_to: Dictionary[int, bool] = {}

var kart: Kart
var device := DeviceInput.ANY

var _driven := false
var _fired := false
var _age := 0.0
var _recheck := 0.0
## Which scheme is currently drawn, so the picture is only rebuilt when the player switches.
var _shown := ""
var _row: ScreenHint


## Whether the seat [param seat] at this machine is to be shown the hint now, and so has been: the
## first time it asks, and every time with Always show drive hints on.
static func due(seat: int) -> bool:
	var always := Game.settings != null and Game.settings.always_drive_hints
	if shown_to.has(seat) and not always:
		return false
	shown_to[seat] = true
	return true


## The seat at this machine [param slot] of [param in_match] is played from: its player's own, or on
## a client the one this machine is; the slot itself for want of either.
static func seat_of(in_match: Match, slot: PlayerSlot) -> int:
	var player := slot.input as PlayerInput
	if player == null and in_match.puppet:
		if in_match.local_seats.has(slot.index):
			player = in_match.local_seats[slot.index]
		elif slot.index == in_match.local_slot:
			player = in_match.local_input
	return player.seat if player != null else slot.index


static func attach(target: Kart, for_device: int) -> ControlHint:
	var hint := ControlHint.new()
	hint.name = "ControlHint"
	hint.kart = target
	hint.device = for_device
	target.add_child(hint)
	# A method connection, not a lambda: it is dropped automatically when the hint is freed.
	target.fired.connect(hint._on_fired)
	hint._rebuild()
	return hint


## The hint for one device, as a keyboard line or a gamepad line but never both: a player reading
## this has one set of controls in their hands. [param simple] is simple driving's line, and with
## [param pedals] the player's own, see [method PlayerInput.works_the_pedals], the stick steers and
## the gas is theirs to press.
static func hint_row(
	for_device: int, size := ScreenHint.FONT_SIZE, simple := false, pedals := false
) -> HBoxContainer:
	var keyboard := DeviceInput.uses_keyboard(for_device)
	if simple and pedals:
		var steering: Array = [
			InputHint.way(keyboard, INK, size),
			InputHint.glyph(InputActions.THROTTLE, keyboard, INK, size),
			InputHint.glyph(InputActions.FIRE, keyboard, INK, size)
		]
		return InputHint.row("%s steer   %s gas   %s fire", steering, INK, size)
	if simple:
		var ways: Array = [
			InputHint.way(keyboard, INK, size),
			InputHint.glyph(InputActions.FIRE, keyboard, INK, size)
		]
		return InputHint.row("%s drive   %s fire", ways, INK, size)
	var parts: Array = [
		InputHint.glyph(InputActions.THROTTLE, keyboard, INK, size),
		InputHint.pair(InputActions.STEER_LEFT, InputActions.STEER_RIGHT, keyboard, INK, size),
		InputHint.glyph(InputActions.FIRE, keyboard, INK, size),
	]
	return InputHint.row("%s drive   %s steer   %s fire", parts, INK, size)


## What the drawn line depends on, so a rebuild happens when the player picks up a pad and not on
## every frame of the ten seconds this is up for.
static func stamp(for_device: int, simple := false, pedals := false) -> String:
	var keyboard := DeviceInput.uses_keyboard(for_device)
	var named: Array[String] = []
	var actions: Array[StringName] = [
		InputActions.THROTTLE, InputActions.STEER_LEFT, InputActions.DRIVE_UP, InputActions.FIRE
	]
	for action: StringName in actions:
		named.append(InputActions.short_binding_text(action, keyboard))
	return "%s|%s|%s|%s" % [keyboard, simple, pedals, "/".join(named)]


## Whether the player this hint is for drives the simple way, and with the pedals their own.
func _simple() -> bool:
	var player := kart.input as PlayerInput if kart != null and is_instance_valid(kart) else null
	return player != null and player.simple()


func _pedals() -> bool:
	var player := kart.input as PlayerInput if kart != null and is_instance_valid(kart) else null
	return player != null and player.works_the_pedals()


func _exit_tree() -> void:
	if kart != null and is_instance_valid(kart) and kart.fired.is_connected(_on_fired):
		kart.fired.disconnect(_on_fired)


func _on_fired(_bullets: Array[Bullet]) -> void:
	_fired = true


## How big the hint is drawn, see [method ScreenHint.drawn_size].
func drawn_size() -> int:
	return ScreenHint.drawn_size(get_tree() if is_inside_tree() else null)


func _rebuild() -> void:
	var size := drawn_size()
	var simple := _simple()
	var pedals := _pedals()
	var wanted := "%s|%d" % [stamp(device, simple, pedals), size]
	if wanted == _shown:
		return
	_shown = wanted
	if _row != null:
		_row.queue_free()
	_row = ScreenHint.hang(self, hint_row(device, size, simple, pedals), "Row")


func _process(delta: float) -> void:
	_age += delta
	_recheck -= delta
	if _recheck <= 0.0:
		_recheck = RECHECK
		_rebuild()
	if kart != null and kart.motor.speed() > 2.0:
		_driven = true
	if (_driven and _fired) or _age >= MAX_SECONDS:
		queue_free()
