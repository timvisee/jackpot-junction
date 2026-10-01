class_name TutorialShoot
extends TutorialLesson
## Lesson 6, GAME.md 9.4a: hit each of the five targets round the gallery once, a traffic light
## beside each going from red to green as it is counted, then shoot through the wall of boxes
## across the way out, which never comes back in here. The loose boxes break but count for nothing.

## How many of the gallery's targets there are: the lesson counts its own, since the rooms after
## have targets of their own.
const TARGETS := 5
const GALLERY := Rect2i(37, 3, 24, 16)
## The boxes across the way out, by their cells.
const WALL := Rect2i(32, 9, 2, 4)
## Where a target's light stands, from the target.
const LIGHT_AT := Vector3(1.1, 0.0, 0.0)

var _hit: TutorialTask
var _boxes: TutorialTask
## The targets counted, by instance, their lights, and how many boxes of the wall still stand.
var _struck: Dictionary[int, bool] = {}
var _lights: Dictionary[int, TrafficLight] = {}
var _standing := 0


func _init() -> void:
	title = "Shooting"
	gate_cell = Vector2i(26, 9)
	spawn_cell = Vector2i(59, 11)
	facing = Vector3(-1.0, 0.0, 0.0)
	next_cell = Vector2i(23, 11)
	_hit = add_task("Hit the targets", "%s to fire", [InputActions.FIRE])
	_hit.of = TARGETS
	_boxes = add_task("Shoot through the boxes", "%s to fire at the boxes", [InputActions.FIRE])
	_boxes.arrow = Vector2i(32, 10)


func _begin() -> void:
	for target: Target in _gallery():
		target.struck.connect(_on_struck)
		var light := TrafficLight.add_to(target.get_parent(), target.position + LIGHT_AT)
		_lights[target.get_instance_id()] = light
	var grid := run.grid()
	for i: int in arena().crates.size():
		if WALL.has_point(grid.crates[i]):
			_standing += 1
			arena().crates[i].destroyed.connect(_on_box)


func end() -> void:
	for target: Target in _gallery():
		if target.struck.is_connected(_on_struck):
			target.struck.disconnect(_on_struck)
	var grid := run.grid()
	for i: int in arena().crates.size():
		if WALL.has_point(grid.crates[i]) and arena().crates[i].destroyed.is_connected(_on_box):
			arena().crates[i].destroyed.disconnect(_on_box)
	super()


## The gallery's own targets.
func _gallery() -> Array[Target]:
	var grid := run.grid()
	var mine: Array[Target] = []
	for i: int in arena().targets.size():
		if GALLERY.has_point(grid.targets[i]):
			mine.append(arena().targets[i])
	return mine


## The lights, for asking what they say.
func lights() -> Array[TrafficLight]:
	var all: Array[TrafficLight] = []
	all.assign(_lights.values())
	return all


func step(_delta: float) -> void:
	if current() == _boxes and _standing <= 0:
		_boxes.complete()


func _on_struck(target: Target, by_slot: int) -> void:
	if by_slot != kart().slot or _struck.has(target.get_instance_id()) or current() != _hit:
		return
	_struck[target.get_instance_id()] = true
	var light: TrafficLight = _lights.get(target.get_instance_id())
	if light != null:
		light.set_green()
	_hit.tally()


func _on_box(_by_slot: int) -> void:
	_standing -= 1
