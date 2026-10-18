class_name TutorialItems
extends TutorialLesson
## Lesson 7, GAME.md 9.4a: items, three stations round one room, done in any order, each box
## holding its own item with no roulette. Along the top, a dead-end run with a turret at the far
## end that is part of the room, on a hazard plinth, never destroyed: pick the Shield up at the
## open end, out of the turret's reach, arm it, cross the hazard line where the reach begins and
## take the turret's shot on it, which is what a Shield is for. In the south-east, the pocket shut
## off by a hologram a shot passes and a kart does not, with a thin pillar in the middle and the
## target past it, where only a shot bounced off the pocket's north wall reaches, and the path of
## that shot dotted on the floor from the spot to stand on: pick the Ricochet Cannon up, arm it,
## line up with the dots and fire. Along the west wall, three targets behind a hologram of their
## own and a hazard box on the floor where to drop the Turret: pick it up, drop it there and let it
## clear them, which only it can, a shot of the player's counting for nothing. A box taken with
## its station not done and the item gone comes back. The item slot comes into the corner with
## the first item picked up, pointed at until that item has done its piece.

const SHIELD: PowerUp = preload("res://data/powerups/shield.tres")
const RICOCHET: PowerUp = preload("res://data/powerups/ricochet_cannon.tres")
const TURRET: PowerUp = preload("res://data/powerups/turret.tres")
## Where everything stands, by cell: the boxes, the guard and the run it covers, the window and
## the pocket's target, the spot to shoot from and where the shot banks, the row and its own
## window, and where to drop the Turret for it.
const SHIELD_BOX := Vector2i(24, 3)
const GUARD := Vector2i(3, 3)
const RUN_ROWS := Vector2i(1, 5)
const RICOCHET_BOX := Vector2i(16, 15)
const WINDOW := Vector2i(19, 15)
const WINDOW_TALL := 2
const POCKET := Vector2i(25, 15)
const SHOOT_FROM := Vector2i(17, 15)
## The pocket's north wall, by the row of cells it is, and how far from a wall a shot turns:
## the bullet's own radius, see [Bullet].
const POCKET_WALL_ROW := 13
const BULLET_RADIUS := 0.15
const TURRET_BOX := Vector2i(9, 11)
const ROW: Array[Vector2i] = [Vector2i(3, 9), Vector2i(3, 11), Vector2i(3, 13)]
const ROW_WINDOW := Vector2i(4, 9)
const ROW_WINDOW_TALL := 5
const DROP_AT := Vector2i(6, 11)
const DROP_BOX_CELLS := 3
## How far the guard shoots, in meters, and how long a taken box takes to come back, in seconds.
const GUARD_REACH := 7.0
const RETURN_WAIT := 3.0
const GUARD_INK := Color(0.6, 0.62, 0.66)
## The word at the top until an item has been used, with the item key named in it.
const WORDS := "Drive over a box to pick up an item, then use it."

var _take_shield: TutorialTask
var _pop: TutorialTask
var _take_ricochet: TutorialTask
var _arm: TutorialTask
var _bounce: TutorialTask
var _take_turret: TutorialTask
var _clear: TutorialTask
## Each station's box on the floor, by the item, and how long since it was taken.
var _boxes: Dictionary[StringName, ItemBox] = {}
var _waits: Dictionary[StringName, float] = {}
var _guard: Turret
var _window: Hologram
var _row_window: Hologram
var _row_hit: Dictionary[int, bool] = {}
var _slot_shown := false


func _init() -> void:
	title = "Items"
	ensures = [&"item"]
	ordered = false
	gate_cell = Vector2i(2, 18)
	spawn_cell = Vector2i(24, 10)
	facing = Vector3(-1.0, 0.0, 0.0)
	next_cell = Vector2i(3, 20)
	_take_shield = add_task("Pick up the Shield", "")
	_take_shield.arrow = SHIELD_BOX
	_pop = add_task(
		"Arm it and take the turret's shot",
		"%s to arm it, then across the hazard line",
		[InputActions.USE_ITEM]
	)
	_pop.arrow = GUARD
	_pop.ringed = false
	_take_ricochet = add_task("Pick up the Ricochet Cannon", "")
	_take_ricochet.arrow = RICOCHET_BOX
	_arm = add_task("Arm it", "%s to arm the cannon", [InputActions.USE_ITEM])
	_bounce = add_task(
		"Bank a shot onto the hidden target",
		"Line up with the dots, %s to fire",
		[InputActions.FIRE]
	)
	_bounce.arrow = SHOOT_FROM
	_take_turret = add_task("Pick up the Turret", "")
	_take_turret.arrow = TURRET_BOX
	_clear = add_task(
		"Drop it in the box and let it clear the targets",
		"%s to drop the turret",
		[InputActions.USE_ITEM]
	)
	_clear.arrow = DROP_AT
	_clear.of = ROW.size()
	stations = [[_take_shield, _pop], [_take_ricochet, _arm, _bounce], [_take_turret, _clear]]


## The room's furniture, there from the start: the guard on its plinth and the hazard line where
## its reach begins, the two windows, the dotted bank shot, the hazard box for the Turret and the
## boxes.
func _prepare() -> void:
	_place(&"shield", SHIELD, SHIELD_BOX)
	_place(&"ricochet_cannon", RICOCHET, RICOCHET_BOX)
	_place(&"turret", TURRET, TURRET_BOX)
	_guard = Turret.new()
	_guard.name = "Guard"
	_guard.owner_slot = -1
	_guard.fixture = true
	_guard.lifetime = 1.0e9
	_guard.fire_interval = 1.2
	_guard.reach = GUARD_REACH
	_guard.bullet_system = run.match_node.bullets
	_guard.color = GUARD_INK
	run.match_node.bullets.get_parent().add_child(_guard)
	_guard.global_position = run.cell(GUARD)
	_guard.rotation.y = PI * 0.5
	var size := run.grid().cell_size
	var holder := run.match_node
	# The hazard ring round the guard, on the floor, where it stays put while the guard turns.
	HazardLine.box(holder, run.cell(GUARD), Vector2(1.7, 1.7))
	# Where the guard's reach begins, across the run.
	var reach_x := run.cell(GUARD).x + GUARD_REACH
	var run_top := run.cell(Vector2i(GUARD.x, RUN_ROWS.x)).z - size * 0.5
	var run_bottom := run.cell(Vector2i(GUARD.x, RUN_ROWS.y)).z + size * 0.5
	HazardLine.lay(holder, Vector3(reach_x, 0.0, run_top), Vector3(reach_x, 0.0, run_bottom))
	# The pocket's window, and the bank shot dotted from the spot to stand on.
	var window_at := run.cell(WINDOW) + Vector3(0.0, 0.0, size * (WINDOW_TALL - 1) * 0.5)
	_window = Hologram.add_to(holder, window_at, Vector3(0.3, 1.0, size * WINDOW_TALL))
	for at: Vector2i in [WINDOW, WINDOW + Vector2i(0, 1)]:
		run.match_node.nav.set_cell_blocked(at, true)
	GuideDots.lay(holder, [run.cell(SHOOT_FROM), _bank_point(), run.cell(POCKET)])
	# The row behind a window of its own, and the box to drop the Turret in.
	var row_at := run.cell(ROW_WINDOW) + Vector3(0.0, 0.0, size * (ROW_WINDOW_TALL - 1) * 0.5)
	_row_window = Hologram.add_to(holder, row_at, Vector3(0.3, 1.0, size * ROW_WINDOW_TALL))
	for i: int in ROW_WINDOW_TALL:
		run.match_node.nav.set_cell_blocked(ROW_WINDOW + Vector2i(0, i), true)
	HazardLine.box(holder, run.cell(DROP_AT), Vector2.ONE * size * DROP_BOX_CELLS)


func _begin() -> void:
	run.list.say(&"items", WORDS)
	for target: Target in arena().targets:
		target.struck.connect(_on_struck)
	Events.item_picked.connect(_on_picked)
	Events.item_used.connect(_on_used)
	Events.shield_popped.connect(_on_popped)


func end() -> void:
	for target: Target in arena().targets:
		if target.struck.is_connected(_on_struck):
			target.struck.disconnect(_on_struck)
	if Events.item_picked.is_connected(_on_picked):
		Events.item_picked.disconnect(_on_picked)
	if Events.item_used.is_connected(_on_used):
		Events.item_used.disconnect(_on_used)
	if Events.shield_popped.is_connected(_on_popped):
		Events.shield_popped.disconnect(_on_popped)
	_silence()
	super()


func step(delta: float) -> void:
	for id: StringName in _boxes.keys():
		_return(id, delta)


## A box taken and its station not done, the item gone, comes back: a Shield burnt elsewhere or
## a Turret dropped out of reach of the row after a moment, a Ricochet's shots all spent before
## the pocket at once, since there is nothing else to wait for.
func _return(id: StringName, delta: float) -> void:
	var box: ItemBox = _boxes[id]
	if is_instance_valid(box) and box.is_inside_tree():
		return
	var task: TutorialTask = _station(id)
	var in_hand := kart().held_item != null or kart().cannon.override_item == id
	if task == null or task.done or in_hand:
		_waits[id] = 0.0
		return
	_waits[id] = float(_waits.get(id, 0.0)) + delta
	var wait := 0.0 if id == &"ricochet_cannon" else RETURN_WAIT
	if float(_waits[id]) < wait:
		return
	_waits[id] = 0.0
	match id:
		&"shield":
			_place(id, SHIELD, SHIELD_BOX)
		&"ricochet_cannon":
			_place(id, RICOCHET, RICOCHET_BOX)
		&"turret":
			_place(id, TURRET, TURRET_BOX)


## The task each box's item is there to do.
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


## Where a shot from the spot to stand on turns off the pocket's north wall to land on the target:
## the target mirrored in the wall's face, a bullet's radius off it, and the straight line to the
## mirror image crossing that face.
func _bank_point() -> Vector3:
	var size := run.grid().cell_size
	var face := run.cell(Vector2i(POCKET.x, POCKET_WALL_ROW)).z + size * 0.5 + BULLET_RADIUS
	var from := run.cell(SHOOT_FROM)
	var target := run.cell(POCKET)
	var image := Vector3(target.x, 0.0, 2.0 * face - target.z)
	var share := (face - from.z) / (image.z - from.z)
	return from.lerp(image, share)


## The guard has done its piece once the Shield has taken its shot: it stops shooting, and
## stands, being part of the room.
func _silence() -> void:
	if _guard != null and is_instance_valid(_guard):
		_guard.reach = 0.0


## An item picked up: the first brings the item slot into the corner, pointed at until that item
## has done its piece.
func _on_picked(slot_index: int, id: StringName) -> void:
	if slot_index != kart().slot:
		return
	if not _slot_shown and run.reveal != null:
		_slot_shown = true
		pointer_until = _station(id)
		run.reveal.show_piece(&"item", "Your item, %s to use it", [InputActions.USE_ITEM])
	match id:
		&"shield":
			_take_shield.complete()
		&"ricochet_cannon":
			_take_ricochet.complete()
		&"turret":
			_take_turret.complete()


func _on_used(slot_index: int, id: StringName) -> void:
	if slot_index != kart().slot:
		return
	run.list.unsay(&"items")
	if id == &"ricochet_cannon":
		_arm.complete()


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
