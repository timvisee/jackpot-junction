class_name TutorialDrift
extends TutorialLesson
## Lesson 5, GAME.md 9.4a: tap the handbrake while turning, once, then hold a drift long enough
## for a turbo, three times, each drift's bar filling toward the turbo point of 4.1.

const TURBOS := 3
## What the turbo task says over the kart: while the drift is charging, and once it has its turbo
## and straightening up lets it go.
const KEEP := "Keep the drift going for a turbo"
const READY := "Turbo ready: straighten up to launch it"

var _tap: TutorialTask
var _turbo: TutorialTask


func _init() -> void:
	title = "Drifting"
	gate_cell = Vector2i(61, 10)
	spawn_cell = Vector2i(81, 20)
	next_cell = Vector2i(59, 11)
	_tap = add_task(
		"Tap the handbrake while turning", "Tap %s while turning", [InputActions.HANDBRAKE]
	)
	_turbo = add_task("Hold a drift until it turbos", KEEP, [], true)
	_turbo.of = TURBOS


func _begin() -> void:
	Events.drift_boosted.connect(_on_boost)


func end() -> void:
	if Events.drift_boosted.is_connected(_on_boost):
		Events.drift_boosted.disconnect(_on_boost)
	super()


func _on_boost(slot_index: int) -> void:
	if slot_index == kart().slot and current() == _turbo:
		_turbo.tally()


func step(_delta: float) -> void:
	var motor := kart().motor
	var task := current()
	if task == _tap and motor.drifting:
		_tap.complete()
	elif task == _turbo:
		var charge := motor.drift_time / maxf(kart().stats.drift_min_duration, 0.001)
		_turbo.progress = clampf(charge, 0.0, 1.0) if motor.drifting else 0.0
		# Once the drift has earned its turbo, straightening up is what lets it go.
		_turbo.hint = READY if motor.drifting and motor.boost_earned() else KEEP
