class_name TutorialJokers
extends TutorialLesson
## Lesson 8, GAME.md 9.4a: jokers, in any order. Two parked karts across the room that never move
## or shoot and go down to one hit, for good, each dropping a card as it goes, and the cards picked
## up off the floor; the
## joker key held to read the hand; and two deaths in the pit, each opening the joker pick, for
## two more cards. Four cards in the hand is the lesson. The lives come into the corner with it,
## and the hand with the first card, pointed at until the hand has been read; from here on a death
## opens the pick, as it does in a match.

const DUMMIES := 2
## Where the parked karts stand, by cell, across the room from the way in and facing it, and what
## each drops: both help with the coins straight after.
const DUMMY_SPOTS: Array[Vector2i] = [Vector2i(5, 47), Vector2i(10, 47)]
const CARDS: Array[StringName] = [&"magnet_hubcaps", &"payday"]
const PIT := Vector2i(7, 50)
const PIT_RECT := Rect2i(7, 50, 2, 2)
const WANTED := 4
## How long the hand has to be held open to have been read, in seconds.
const READ_FOR := 1.0

var _shoot: TutorialTask
var _pick_up: TutorialTask
var _read: TutorialTask
var _pit: TutorialTask
var _read_time := 0.0
var _hand_shown := false


func _init() -> void:
	title = "Jokers"
	ordered = false
	gate_cell = Vector2i(22, 55)
	spawn_cell = Vector2i(4, 40)
	facing = Vector3(0.0, 0.0, 1.0)
	next_cell = Vector2i(23, 53)
	reveals = [[&"lives", "", []]]
	_shoot = add_task("Shoot the two parked karts", "%s to fire", [InputActions.FIRE])
	_shoot.of = DUMMIES
	_shoot.arrow = DUMMY_SPOTS[0]
	_pick_up = add_task("Pick up the cards they dropped", "Drive over a card")
	_pick_up.of = DUMMIES
	_pick_up.arrow = DUMMY_SPOTS[1]
	_read = add_task(
		"Hold the joker key to read your hand",
		"Hold %s to read your hand",
		[InputActions.JOKER_MENU],
		true
	)
	_pit = add_task("Drive into the pit and pick a joker", "%s to take a card", [InputActions.FIRE])
	_pit.of = WANTED - DUMMIES
	_pit.arrow = PIT
	_pit.arrow_rect = PIT_RECT
	stations = [[_shoot, _pick_up], [_read], [_pit]]
	pointer_until = _read


func _begin() -> void:
	# A death opens the joker pick from here on, GAME.md 3.7.
	run.match_node.rules.offer_jokers = true
	Events.kart_killed.connect(_on_killed)
	Events.joker_taken.connect(_on_taken)
	put_sign("PARKED KARTS\nshoot one and it drops a joker", Vector2i(7, 46), Palette.NEON_MAGENTA)
	put_sign("PIT\ndrive in: a death opens the joker pick", PIT, Palette.NEON_MAGENTA)


func end() -> void:
	if Events.kart_killed.is_connected(_on_killed):
		Events.kart_killed.disconnect(_on_killed)
	if Events.joker_taken.is_connected(_on_taken):
		Events.joker_taken.disconnect(_on_taken)
	super()


func step(delta: float) -> void:
	# The hand comes in with the first card, and is pointed at.
	if not _hand_shown and kart().jokers.count() > 0 and run.reveal != null:
		_hand_shown = true
		run.reveal.show_piece(
			&"hand", "Your jokers, hold %s to read them", [InputActions.JOKER_MENU]
		)
	if _read.done:
		return
	if kart().menu_open:
		_read_time += delta
	_read.progress = clampf(_read_time / READ_FOR, 0.0, 1.0)
	if _read.progress >= 1.0:
		_read.complete()


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


## A card taken: off the floor while alive, out of the pick while dead.
func _on_taken(slot_index: int, _joker: StringName) -> void:
	if slot_index != kart().slot:
		return
	if kart().alive:
		if not _pick_up.done:
			_pick_up.tally()
	elif not _pit.done:
		_pit.tally()
