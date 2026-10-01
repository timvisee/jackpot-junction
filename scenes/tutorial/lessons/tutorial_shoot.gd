class_name TutorialShoot
extends TutorialLesson
## Lesson 6, GAME.md 9.4a: hit each of the five targets round the gallery once, each lighting a
## green ring at its foot as it is counted, then shoot through the wall of boxes across the way
## out, which never comes back in here. The loose boxes break but count for nothing.

const TARGETS := 5
## The boxes across the way out, by their cells, and where the sign at the end of the lessons so
## far stands, in the room after.
const WALL := Rect2i(32, 9, 2, 4)
const END_SIGN := Vector2i(19, 7)
const RING := Color(0.45, 1.0, 0.55)

var _hit: TutorialTask
var _boxes: TutorialTask
## The targets counted, by instance, and how many boxes of the wall still stand.
var _struck: Dictionary[int, bool] = {}
var _standing := 0
var _rings: Array[Node] = []


func _init() -> void:
	title = "Shooting"
	gate_cell = Vector2i(26, 9)
	spawn_cell = Vector2i(59, 11)
	facing = Vector3(-1.0, 0.0, 0.0)
	next_cell = Vector2i(24, 10)
	_hit = add_task("Hit the targets", "%s to fire", [InputActions.FIRE])
	_hit.of = TARGETS
	_boxes = add_task("Shoot through the boxes", "%s to fire at the boxes", [InputActions.FIRE])
	_boxes.arrow = Vector2i(32, 10)


func _begin() -> void:
	for target: Target in arena().targets:
		target.struck.connect(_on_struck)
	var grid := run.grid()
	for i: int in arena().crates.size():
		if WALL.has_point(grid.crates[i]):
			_standing += 1
			arena().crates[i].destroyed.connect(_on_box)


func end() -> void:
	for target: Target in arena().targets:
		if target.struck.is_connected(_on_struck):
			target.struck.disconnect(_on_struck)
	var grid := run.grid()
	for i: int in arena().crates.size():
		if WALL.has_point(grid.crates[i]) and arena().crates[i].destroyed.is_connected(_on_box):
			arena().crates[i].destroyed.disconnect(_on_box)
	for ring: Node in _rings:
		if is_instance_valid(ring):
			ring.queue_free()
	_rings.clear()


func step(_delta: float) -> void:
	if current() == _boxes and _standing <= 0:
		_boxes.complete()


func _on_struck(target: Target, by_slot: int) -> void:
	if by_slot != kart().slot or _struck.has(target.get_instance_id()) or current() != _hit:
		return
	_struck[target.get_instance_id()] = true
	_ring(target)
	_hit.tally()


func _on_box(_by_slot: int) -> void:
	_standing -= 1


## A green ring at the foot of a target that has been counted.
func _ring(target: Target) -> void:
	var ring := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.75
	disc.bottom_radius = 0.75
	disc.height = 0.05
	disc.radial_segments = 24
	disc.rings = 1
	ring.mesh = disc
	var material := StandardMaterial3D.new()
	material.albedo_color = RING
	material.emission_enabled = true
	material.emission = RING
	material.emission_energy_multiplier = 0.8
	ring.material_override = material
	ring.position = Vector3(target.position.x, 0.03, target.position.z)
	target.get_parent().add_child(ring)
	_rings.append(ring)
