class_name TutorialJokers
extends TutorialLesson
## Lesson 8, GAME.md 9.4a: jokers. Two parked karts that never move or shoot and go down to one
## hit, each dropping a card as it goes; then hold the joker key to read the hand; then drive into
## the pit twice, each death opening the joker pick, for the third and fourth cards. Holding four
## is the lesson. The hand and the lives come into the corner with it, and from here on a death
## opens the pick, as it does in a match.

const DUMMIES := 2
## Where the parked karts stand, by cell, and what each drops: both help with the coins straight
## after.
const DUMMY_SPOTS: Array[Vector2i] = [Vector2i(5, 42), Vector2i(10, 42)]
const CARDS: Array[StringName] = [&"magnet_hubcaps", &"payday"]
const PIT := Vector2i(7, 50)
const WANTED := 4
## How long the hand has to be held open to have been read, in seconds.
const READ_FOR := 1.0

var _shoot: TutorialTask
var _pick_up: TutorialTask
var _read: TutorialTask
var _pit: TutorialTask
var _read_time := 0.0


func _init() -> void:
	title = "Jokers"
	gate_cell = Vector2i(6, 57)
	spawn_cell = Vector2i(4, 40)
	facing = Vector3(0.0, 0.0, 1.0)
	next_cell = Vector2i(24, 54)
	reveals = [
		[&"hand", "Your jokers, hold %s to read them", [InputActions.JOKER_MENU]],
		[&"lives", "", []],
	]
	_shoot = add_task("Shoot the two parked karts", "%s to fire", [InputActions.FIRE])
	_shoot.of = DUMMIES
	_shoot.arrow = DUMMY_SPOTS[0]
	_pick_up = add_task("Pick up the cards they dropped", "Drive over a card")
	_pick_up.of = DUMMIES
	_read = add_task(
		"Hold the joker key to read your hand",
		"Hold %s to read your hand",
		[InputActions.JOKER_MENU],
		true
	)
	_pit = add_task("Drive into the pit and pick a joker", "%s to take a card", [InputActions.FIRE])
	_pit.of = WANTED - DUMMIES
	_pit.arrow = PIT


func _begin() -> void:
	# A death opens the joker pick from here on, GAME.md 3.7.
	run.match_node.rules.offer_jokers = true
	Events.kart_killed.connect(_on_killed)
	Events.joker_taken.connect(_on_taken)
	put_sign("PARKED KARTS\nshoot one and it drops a joker", Vector2i(7, 41), Palette.NEON_MAGENTA)
	put_sign("PIT\ndrive in: a death opens the joker pick", PIT, Palette.NEON_MAGENTA)


func end() -> void:
	if Events.kart_killed.is_connected(_on_killed):
		Events.kart_killed.disconnect(_on_killed)
	if Events.joker_taken.is_connected(_on_taken):
		Events.joker_taken.disconnect(_on_taken)
	super()


func step(delta: float) -> void:
	var task := current()
	if task == _read:
		if kart().menu_open:
			_read_time += delta
		_read.progress = clampf(_read_time / READ_FOR, 0.0, 1.0)
		if _read.progress >= 1.0:
			_read.complete()
	elif task == _pit:
		_pit.count = clampi(kart().jokers.count() - DUMMIES, 0, _pit.of)
		if _pit.count >= _pit.of:
			_pit.complete()


## A parked kart shot: its card goes on the floor beside it.
func _on_killed(victim: int, _killer: int, _cause: StringName) -> void:
	var which := -1
	for i: int in run.dummies.size():
		if run.dummies[i].index == victim:
			which = i
	if which < 0 or _shoot.done:
		return
	var card := run.match_node.joker_catalog.by_id(CARDS[which % CARDS.size()])
	if card != null:
		arena().spawn_floor_joker(run.dummies[which].kart.global_position, card, 0.0)
	_shoot.tally()


func _on_taken(slot_index: int, _joker: StringName) -> void:
	if slot_index == kart().slot and current() == _pick_up:
		_pick_up.tally()
