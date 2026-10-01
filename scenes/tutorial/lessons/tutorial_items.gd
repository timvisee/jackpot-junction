class_name TutorialItems
extends TutorialLesson
## Lesson 7, GAME.md 9.4a: items, three stations round one room, done in any order, each box
## holding its own item with no roulette. Along the top, the run a turret guards: pick the Shield
## up at the east end, out of the turret's reach, raise it and take the turret's shot on it, which
## is what a Shield is for. In the south-east, the pocket shut off by a hologram a shot passes and
## a kart does not, with a thin pillar in the middle and the target past it, where only a shot
## bounced off the pocket's north or south wall reaches: pick the Ricochet Cannon up and bounce a
## shot onto it. Along the west wall, a row of three targets: pick the Turret up, drop it
## by them and let it clear them, which only it can, a shot of the player's counting for nothing.
## A box taken with its station not done and the item gone comes back a moment later.

const SHIELD: PowerUp = preload("res://data/powerups/shield.tres")
const RICOCHET: PowerUp = preload("res://data/powerups/ricochet_cannon.tres")
const TURRET: PowerUp = preload("res://data/powerups/turret.tres")
## Where everything stands, by cell: the boxes, the guard and the way in to it, the window and the
## pocket's target, and the row.
const SHIELD_BOX := Vector2i(24, 3)
const GUARD := Vector2i(13, 3)
const RUN_IN := Vector2i(23, 5)
const RICOCHET_BOX := Vector2i(16, 15)
const WINDOW := Vector2i(19, 15)
const WINDOW_TALL := 2
const POCKET := Vector2i(25, 15)
const TURRET_BOX := Vector2i(9, 11)
const ROW: Array[Vector2i] = [Vector2i(3, 9), Vector2i(3, 11), Vector2i(3, 13)]
## How far the guard shoots, in meters, and how long a taken box takes to come back, in seconds.
const GUARD_REACH := 7.0
const RETURN_WAIT := 3.0
const GUARD_INK := Color("#FF3B30")

var _take_shield: TutorialTask
var _pop: TutorialTask
var _take_ricochet: TutorialTask
var _bounce: TutorialTask
var _take_turret: TutorialTask
var _clear: TutorialTask
## Each station's box on the floor, by the item, and how long since it was taken.
var _boxes: Dictionary[StringName, ItemBox] = {}
var _waits: Dictionary[StringName, float] = {}
var _guard: Turret
var _window: Hologram
var _row_hit: Dictionary[int, bool] = {}


func _init() -> void:
	title = "Items"
	ordered = false
	gate_cell = Vector2i(2, 18)
	spawn_cell = Vector2i(24, 10)
	facing = Vector3(-1.0, 0.0, 0.0)
	next_cell = Vector2i(3, 20)
	reveals = [[&"item", "Your item, %s to use it", [InputActions.USE_ITEM]]]
	_take_shield = add_task("Pick up the Shield", "Drive over the box")
	_take_shield.arrow = SHIELD_BOX
	_pop = add_task(
		"Raise it and take the turret's shot", "%s to raise the shield", [InputActions.USE_ITEM]
	)
	_pop.arrow = RUN_IN
	_take_ricochet = add_task("Pick up the Ricochet Cannon", "Drive over the box")
	_take_ricochet.arrow = RICOCHET_BOX
	_bounce = add_task(
		"Bounce a shot onto the hidden target",
		"%s to fire at a wall past the pillar",
		[InputActions.FIRE]
	)
	_bounce.arrow = Vector2i(17, 15)
	_take_turret = add_task("Pick up the Turret", "Drive over the box")
	_take_turret.arrow = TURRET_BOX
	_clear = add_task(
		"Drop it and let it clear the three targets",
		"%s to drop the turret",
		[InputActions.USE_ITEM]
	)
	_clear.arrow = Vector2i(6, 11)
	_clear.of = ROW.size()
	stations = [[_take_shield, _pop], [_take_ricochet, _bounce], [_take_turret, _clear]]


## The room's furniture, there from the start: the guard, the window and the boxes.
func _prepare() -> void:
	_place(&"shield", SHIELD, SHIELD_BOX)
	_place(&"ricochet_cannon", RICOCHET, RICOCHET_BOX)
	_place(&"turret", TURRET, TURRET_BOX)
	_guard = Turret.new()
	_guard.name = "Guard"
	_guard.owner_slot = -1
	_guard.lifetime = 1.0e9
	_guard.fire_interval = 1.2
	_guard.reach = GUARD_REACH
	_guard.bullet_system = run.match_node.bullets
	_guard.color = GUARD_INK
	run.match_node.bullets.get_parent().add_child(_guard)
	_guard.global_position = run.cell(GUARD)
	_guard.rotation.y = -PI * 0.5
	var size := run.grid().cell_size
	var window_at := run.cell(WINDOW) + Vector3(0.0, 0.0, size * (WINDOW_TALL - 1) * 0.5)
	_window = Hologram.add_to(run.match_node, window_at, Vector3(0.3, 1.0, size * WINDOW_TALL))
	for at: Vector2i in [WINDOW, WINDOW + Vector2i(0, 1)]:
		run.match_node.nav.set_cell_blocked(at, true)


func _begin() -> void:
	for target: Target in arena().targets:
		target.struck.connect(_on_struck)
	Events.item_picked.connect(_on_picked)
	Events.shield_popped.connect(_on_popped)
	put_sign("ITEMS\nan item works once: pick one up, use it", Vector2i(13, 9), Palette.NEON_CYAN)
	put_sign("SHIELD\nup, then into the turret's fire", Vector2i(22, 3), GUARD_INK)
	put_sign(
		"RICOCHET\nthrough the window, off a wall past the pillar",
		Vector2i(15, 13),
		Palette.NEON_CYAN
	)
	put_sign("TURRET\ndrop it here, it shoots the row", Vector2i(7, 11), Palette.NEON_CYAN)


func end() -> void:
	for target: Target in arena().targets:
		if target.struck.is_connected(_on_struck):
			target.struck.disconnect(_on_struck)
	if Events.item_picked.is_connected(_on_picked):
		Events.item_picked.disconnect(_on_picked)
	if Events.shield_popped.is_connected(_on_popped):
		Events.shield_popped.disconnect(_on_popped)
	_silence()
	super()


func step(delta: float) -> void:
	for id: StringName in _boxes.keys():
		_return(id, delta)


## A box taken and its station not done, the item gone, comes back after a moment: a Shield burnt
## elsewhere, a Ricochet worn off before the pocket, a Turret dropped out of reach of the row.
func _return(id: StringName, delta: float) -> void:
	var box: ItemBox = _boxes[id]
	if is_instance_valid(box) and box.is_inside_tree():
		return
	var task: TutorialTask = _station(id)
	if task == null or task.done or kart().held_item != null:
		_waits[id] = 0.0
		return
	_waits[id] = float(_waits.get(id, 0.0)) + delta
	if float(_waits[id]) < RETURN_WAIT:
		return
	_waits[id] = 0.0
	match id:
		&"shield":
			_place(id, SHIELD, SHIELD_BOX)
		&"ricochet_cannon":
			_place(id, RICOCHET, RICOCHET_BOX)
		&"turret":
			_place(id, TURRET, TURRET_BOX)


## The task each box's item is for.
func _station(id: StringName) -> TutorialTask:
	match id:
		&"shield":
			return _pop
		&"ricochet_cannon":
			return _bounce
		&"turret":
			return _clear
	return null


func _place(id: StringName, item: PowerUp, cell: Vector2i) -> void:
	var box := ItemBox.new()
	box.fixed_item = item
	box.lifetime = 0.0
	arena().place_drop(box, run.cell(cell))
	_boxes[id] = box


## The guard has done its piece once the Shield has taken its shot.
func _silence() -> void:
	if _guard != null and is_instance_valid(_guard) and _guard.alive:
		_guard.destroy()


func _on_picked(slot_index: int, id: StringName) -> void:
	if slot_index != kart().slot:
		return
	match id:
		&"shield":
			_take_shield.complete()
		&"ricochet_cannon":
			_take_ricochet.complete()
		&"turret":
			_take_turret.complete()


func _on_popped(slot_index: int) -> void:
	if slot_index == kart().slot and not _pop.done:
		_pop.complete()
		_silence()


func _on_struck(target: Target, by_slot: int) -> void:
	if by_slot != kart().slot:
		return
	if target == target_at(POCKET):
		if target.hit_after_bounce:
			_bounce.complete()
		return
	if not target.hit_by_turret:
		return
	for cell: Vector2i in ROW:
		if target == target_at(cell) and not _row_hit.has(target.get_instance_id()):
			_row_hit[target.get_instance_id()] = true
			_clear.tally()
