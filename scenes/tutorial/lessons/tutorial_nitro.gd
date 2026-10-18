class_name TutorialNitro
extends TutorialLesson
## Lesson 2, GAME.md 9.4a: speed. The long run along the north of the lot, a ring of cones rising at
## its east end. Burn a full tank of nitro, the tank filled as the lesson starts and coming back in
## seconds, since the bottle is the lesson and not the wait for it; the nitro tank and the
## speedometer come into the corner with it. An extra: drift round the cones, one drift held long
## enough for a turbo, which the lesson does not wait for.

## What the clipboard says the lesson is about.
const WORDS := "Use {nitro} to boost your speed. It refills over time."

var _burn: TutorialTask
var _drift: TutorialTask


func _init() -> void:
	title = "Speed"
	spawn_cell = TestGround.RUN_FROM
	facing = TestGround.EAST
	reveals = [[&"nitro", "Your {nitro}", [InputActions.NITRO]]]
	_burn = add_task("Burn a full tank of {nitro}", "", [InputActions.NITRO], true)
	_burn.arrow = TestGround.DRIFT_RING
	_burn.ringed = false
	_drift = add_task("Drift round the cones for a turbo", "", [InputActions.HANDBRAKE])
	_drift.extra = true


func _prepare() -> void:
	var at := run.cell(TestGround.DRIFT_RING)
	var points := TestGround.ring(TestGround.RING_CONES, TestGround.RING_RADIUS)
	for i: int in points.size():
		var spot := at + Vector3(points[i].x, 0.0, points[i].y)
		keep_back(SchoolCone.stand(arena(), spot, "DriftRing%d" % i), SchoolCone.ACROSS)


func _begin() -> void:
	kart().refill_nitro(1.0)
	run.list.say(&"nitro", WORDS)
	bring_up(piece_nodes(), 0.08)
	Events.drift_boosted.connect(_on_boost)


func end() -> void:
	if Events.drift_boosted.is_connected(_on_boost):
		Events.drift_boosted.disconnect(_on_boost)
	super()


func step(_delta: float) -> void:
	var charge := kart().nitro_charge
	_burn.progress = clampf(1.0 - charge, 0.0, 1.0)
	if charge <= 0.001:
		_burn.complete()


func _on_boost(slot_index: int) -> void:
	if slot_index == kart().slot:
		_drift.complete()
