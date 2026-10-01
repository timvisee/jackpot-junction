class_name TutorialItems
extends TutorialLesson
## Lesson 7, GAME.md 9.4a: items, three set pieces in a row, each box holding its own item with no
## roulette. A Shield to raise and drive past the turret guarding the corridor; a Ricochet Cannon
## to hit the target in the pocket behind the stub of wall; a Turret to drop by the row of three
## targets and let it clear them. A box taken and the item gone before its piece is done comes back
## a moment later, and the guard falls silent once the kart is past it.

const SHIELD: PowerUp = preload("res://data/powerups/shield.tres")
const RICOCHET: PowerUp = preload("res://data/powerups/ricochet_cannon.tres")
const TURRET: PowerUp = preload("res://data/powerups/turret.tres")
## Where everything stands, by cell: the boxes, the guard, the line past it, the pocket target and
## the row.
const SHIELD_BOX := Vector2i(24, 10)
const GUARD := Vector2i(19, 11)
const PAST := Vector2i(13, 10)
const RICOCHET_BOX := Vector2i(12, 4)
const POCKET := Vector2i(3, 4)
const TURRET_BOX := Vector2i(12, 14)
const ROW: Array[Vector2i] = [Vector2i(4, 16), Vector2i(7, 16), Vector2i(10, 16)]
## How far the guard shoots, in meters, and how long a taken box takes to come back, in seconds.
const GUARD_REACH := 7.0
const RETURN_WAIT := 3.0
const GUARD_INK := Color("#FF3B30")

var _take_shield: TutorialTask
var _past: TutorialTask
var _take_ricochet: TutorialTask
var _bounce: TutorialTask
var _take_turret: TutorialTask
var _clear: TutorialTask
## Each station's box on the floor, by the item, and how long since it was taken.
var _boxes: Dictionary[StringName, ItemBox] = {}
var _waits: Dictionary[StringName, float] = {}
var _guard: Turret
var _row_hit: Dictionary[int, bool] = {}


func _init() -> void:
	title = "Items"
	gate_cell = Vector2i(2, 18)
	spawn_cell = Vector2i(23, 11)
	facing = Vector3(-1.0, 0.0, 0.0)
	next_cell = Vector2i(3, 20)
	reveals = [[&"item", "Your item, %s to use it", [InputActions.USE_ITEM]]]
	_take_shield = add_task("Pick up the Shield", "Drive over the box")
	_take_shield.arrow = SHIELD_BOX
	_past = add_task(
		"Raise it and drive past the turret", "%s to raise the shield", [InputActions.USE_ITEM]
	)
	_past.arrow = PAST
	_take_ricochet = add_task("Pick up the Ricochet Cannon", "Drive over the box")
	_take_ricochet.arrow = RICOCHET_BOX
	_bounce = add_task(
		"Hit the target behind the wall", "%s to fire, the shots bounce", [InputActions.FIRE]
	)
	_bounce.arrow = POCKET
	_take_turret = add_task("Pick up the Turret", "Drive over the box")
	_take_turret.arrow = TURRET_BOX
	_clear = add_task(
		"Drop it by the targets and let it work", "%s to drop the turret", [InputActions.USE_ITEM]
	)
	_clear.arrow = ROW[1]
	_clear.of = ROW.size()


func _begin() -> void:
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
	for target: Target in arena().targets:
		target.struck.connect(_on_struck)
	Events.item_picked.connect(_on_picked)
	put_sign("ITEMS\nan item works once: pick one up, use it", Vector2i(24, 9), Palette.NEON_CYAN)
	put_sign("TURRET\nshield up, drive past", GUARD, GUARD_INK)
	put_sign("RICOCHET\nbounce a shot into the pocket", Vector2i(4, 8), Palette.NEON_CYAN)
	put_sign("TURRET\ndrop it here, it shoots the targets", Vector2i(7, 14), Palette.NEON_CYAN)


func end() -> void:
	for target: Target in arena().targets:
		if target.struck.is_connected(_on_struck):
			target.struck.disconnect(_on_struck)
	if Events.item_picked.is_connected(_on_picked):
		Events.item_picked.disconnect(_on_picked)
	_silence()
	for box: ItemBox in _boxes.values():
		if is_instance_valid(box):
			box.queue_free()
	_boxes.clear()
	super()


func step(delta: float) -> void:
	var task := current()
	if task == _past and kart().alive and kart().global_position.x < run.cell(PAST).x:
		_past.complete()
		_silence()
	for id: StringName in _boxes.keys():
		_return(id, delta)


## A box taken and its piece not done, the item gone, comes back after a moment: a Shield burnt on
## the way to the turret, a Ricochet worn off before the pocket, a Turret dropped short.
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
			return _past
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


func _on_struck(target: Target, by_slot: int) -> void:
	if by_slot != kart().slot:
		return
	if target == target_at(POCKET):
		_bounce.complete()
		return
	for cell: Vector2i in ROW:
		if target == target_at(cell) and not _row_hit.has(target.get_instance_id()):
			_row_hit[target.get_instance_id()] = true
			_clear.count = _row_hit.size()
			if _clear.count >= _clear.of:
				_clear.complete()
