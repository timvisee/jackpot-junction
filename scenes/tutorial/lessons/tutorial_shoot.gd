class_name TutorialShoot
extends TutorialLesson
## Lesson 3, GAME.md 9.4a: shooting and an item. Three targets rise against the east wall, a lamp on
## a pole beside each, dark until the target is hit and green after: hit each once. Then a box rises
## in the middle holding a Turret, with no roulette: pick it up, which brings the item slot into the
## corner, and drop it; the lamps go dark again, and the Turret hits the targets, which every turret
## does while the tutorial runs, see [member Turret.hunts_targets], a shot of the player's own
## counting for nothing then; once it has hit all three it is taken down, its piece done, so it
## shoots nothing that comes up after. A box taken with the Turret gone and the targets not all
## hit comes back after a moment.

const TURRET: PowerUp = preload("res://data/powerups/turret.tres")
## Where a target's lamp stands, from the target: beside it along the wall.
const LIGHT_AT := Vector3(0.0, 0.0, -1.1)
## How long a box taken takes to come back, in seconds.
const RETURN_WAIT := 3.0
## What the clipboard says the lesson is about.
const WORDS := "Targets drop {chips} when they are hit."

var _hit: TutorialTask
var _take: TutorialTask
var _drop: TutorialTask
## The targets, their lamps, and which are counted for the task under way, by instance.
var _targets: Array[Target] = []
var _lights: Dictionary[int, TrafficLight] = {}
var _counted: Dictionary[int, bool] = {}
var _box: ItemBox
var _wait := 0.0


func _init() -> void:
	title = "Shooting"
	spawn_cell = TestGround.ITEM_BOX
	facing = TestGround.EAST
	_hit = add_task("Hit the targets", "", [InputActions.FIRE])
	_hit.of = TestGround.TARGETS.size()
	_take = add_task("Pick up the box", "")
	_take.arrow = TestGround.ITEM_BOX
	_drop = add_task("Drop the Turret and let it hit them", "", [InputActions.USE_ITEM])
	_drop.of = TestGround.TARGETS.size()


## The targets and their lamps, held back.
func _prepare() -> void:
	for cell: Vector2i in TestGround.TARGETS:
		var target := target_at(cell)
		if target == null:
			continue
		_targets.append(target)
		keep_back(target, Vector2.ONE * cell_size())
		var light := TrafficLight.add_to(target.get_parent(), target.position + LIGHT_AT)
		_lights[target.get_instance_id()] = light
		keep_back(light, Vector2.ONE * 0.5)


func _begin() -> void:
	run.list.say(&"shoot", WORDS)
	bring_up(piece_nodes(), 0.1)
	for target: Target in _targets:
		target.struck.connect(_on_struck)
	Events.item_picked.connect(_on_picked)


func end() -> void:
	_take_down_turrets()
	for target: Target in _targets:
		if target.struck.is_connected(_on_struck):
			target.struck.disconnect(_on_struck)
	if Events.item_picked.is_connected(_on_picked):
		Events.item_picked.disconnect(_on_picked)
	super()


func step(delta: float) -> void:
	if current() == _hit:
		_aim_at_target()
	# A box taken with the Turret gone and the targets not all hit comes back.
	if _take.done and not _drop.done:
		var gone := _box == null or not is_instance_valid(_box) or not _box.is_inside_tree()
		var in_hand := kart().held_item != null
		var turret_up := not run.get_tree().get_nodes_in_group(&"turrets").is_empty()
		if gone and not in_hand and not turret_up:
			_wait += delta
			if _wait >= RETURN_WAIT:
				_wait = 0.0
				_place_box(false)
		else:
			_wait = 0.0


func _settle() -> void:
	for light: TrafficLight in _lights.values():
		light.set_green()


## The lamps, for asking what they say.
func lights() -> Array[TrafficLight]:
	var all: Array[TrafficLight] = []
	all.assign(_lights.values())
	return all


## The arrow and its ring on the nearest target not yet counted.
func _aim_at_target() -> void:
	var here := kart().global_position
	var best := INF
	for target: Target in _targets:
		if _counted.has(target.get_instance_id()):
			continue
		var distance := here.distance_to(target.global_position)
		if distance < best:
			best = distance
			_hit.arrow = run.grid().cell_of(target.global_position)


## The box with the Turret in it, coming up in the middle, or put straight down where it came
## back after being taken.
func _place_box(rising: bool) -> void:
	_box = ItemBox.new()
	_box.fixed_item = TURRET
	_box.lifetime = 0.0
	arena().place_drop(_box, run.cell(TestGround.ITEM_BOX))
	if rising:
		RisingPiece.hold(_box)
		RisingPiece.bring(_box, Vector2.ONE * cell_size(), RisingPiece.Way.RISE, 0.3)


func _on_struck(target: Target, by_slot: int) -> void:
	if by_slot != kart().slot or _counted.has(target.get_instance_id()):
		return
	var task := current()
	if task == _hit and not target.hit_by_turret:
		_count(target, _hit)
		if _hit.done:
			# The targets to hit over, by the Turret this time.
			_counted.clear()
			for light: TrafficLight in _lights.values():
				light.set_dark()
			_place_box(true)
	elif task == _drop and target.hit_by_turret:
		_count(target, _drop)
		if _drop.done:
			_take_down_turrets()


## The player's turrets taken down: the targets are hit, and the parked kart that comes up next is
## no turret's to shoot.
func _take_down_turrets() -> void:
	for node: Node in run.get_tree().get_nodes_in_group(&"turrets"):
		var turret := node as Turret
		if turret != null and turret.alive and turret.owner_slot == kart().slot:
			turret.destroy()


func _count(target: Target, task: TutorialTask) -> void:
	_counted[target.get_instance_id()] = true
	var light: TrafficLight = _lights.get(target.get_instance_id())
	if light != null:
		light.set_green()
	task.tally()


## The Turret picked up: the item slot comes into the corner, pointed at until it has done its
## piece.
func _on_picked(slot_index: int, id: StringName) -> void:
	if slot_index != kart().slot or id != &"turret":
		return
	_take.complete()
	if run.reveal != null and not run.reveal.shown.get(&"item", false):
		pointer_until = _drop
		run.reveal.show_piece(&"item", "Your item", [InputActions.USE_ITEM])
