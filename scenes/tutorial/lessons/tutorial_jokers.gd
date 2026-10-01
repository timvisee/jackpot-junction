class_name TutorialJokers
extends TutorialLesson
## Lesson 8, GAME.md 9.4a: jokers, in any order. Two parked karts across the room that never move
## or shoot and go down to one hit, for good, each dropping a card as it goes, and the cards picked
## up off the floor; each card in the hand read, with the joker key held and the steering walking
## the hand on a keyboard or a pad, or a tap on each card on a touch screen; and two deaths in the
## pit, each opening the joker pick, for two more cards. Four cards in the hand is the lesson. The
## arrow and its ring
## are on the nearest parked kart still standing, then the nearest card still on the floor, and on
## the pit only while a fall into it is still wanted. The lives come into the corner with the
## lesson, and the hand with the first card, pointed at until the hand has been read; from here on
## a death opens the pick, as it does in a match.

const DUMMIES := 2
## Where the parked karts stand, by cell, across the room from the way in and facing it, and what
## each drops: both help with the coins straight after.
const DUMMY_SPOTS: Array[Vector2i] = [Vector2i(5, 47), Vector2i(10, 47)]
const CARDS: Array[StringName] = [&"magnet_hubcaps", &"payday"]
const PIT := Vector2i(7, 52)
const PIT_RECT := Rect2i(7, 52, 2, 2)
const WANTED := 4
## What the reading task says: by key, and by touch; and the word at the top for the lesson.
const READ_KEYS := "Hold %s and steer through your cards"
const READ_TOUCH := "Tap each card to read it"
const WORDS := (
	"Jokers are cards that bend the rules in your favor: every one you hold is a perk "
	+ "for the rest of the match. A hand holds five."
)

var _shoot: TutorialTask
var _pick_up: TutorialTask
var _read: TutorialTask
var _pit: TutorialTask
## The cards read so far, by id.
var _viewed: Dictionary[StringName, bool] = {}
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
	_read = add_task("Read each card in your hand", READ_KEYS, [InputActions.JOKER_MENU], true)
	_pit = add_task("Drive into the pit and pick a joker", "%s to take a card", [InputActions.FIRE])
	_pit.of = WANTED - DUMMIES
	_pit.arrow = PIT
	_pit.arrow_rect = PIT_RECT
	stations = [[_shoot, _pick_up], [_read], [_pit]]
	pointer_until = _read


func _begin() -> void:
	# A death opens the joker pick from here on, GAME.md 3.7.
	run.match_node.rules.offer_jokers = true
	run.notice.say(&"jokers", WORDS)
	if TouchInput.enabled:
		_read.hint = READ_TOUCH
		_read.actions = []
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


func step(_delta: float) -> void:
	# The hand comes in with the first card, and is pointed at.
	if not _hand_shown and kart().jokers.count() > 0 and run.reveal != null:
		_hand_shown = true
		run.reveal.show_piece(
			&"hand", "Your jokers, hold %s to read them", [InputActions.JOKER_MENU]
		)
	_aim_at_nearest()
	_read_cards()


## The card under the cursor, with the hand open, is read: the task is every card in the hand.
func _read_cards() -> void:
	if _read.done:
		return
	var ids := kart().jokers.ids()
	if kart().menu_open and kart().menu_index >= 0 and kart().menu_index < ids.size():
		_viewed[ids[kart().menu_index]] = true
	var read := 0
	for id: StringName in ids:
		read += 1 if _viewed.has(id) else 0
	_read.progress = float(read) / maxf(float(ids.size()), 1.0)
	if not ids.is_empty() and read >= ids.size():
		_read.complete()


## The arrow on the nearest parked kart still standing, and the nearest card still on the floor.
func _aim_at_nearest() -> void:
	var here := kart().global_position
	var grid := run.grid()
	var best := INF
	for slot_dummy: PlayerSlot in run.dummies:
		var dummy := slot_dummy.kart
		if dummy == null or not dummy.alive:
			continue
		var distance := here.distance_to(dummy.global_position)
		if distance < best:
			best = distance
			_shoot.arrow = grid.cell_of(dummy.global_position)
	best = INF
	for pickup: Node in arena().pickups.get_children():
		if pickup is FloorJoker and is_instance_valid(pickup):
			var distance := here.distance_to((pickup as Node3D).global_position)
			if distance < best:
				best = distance
				_pick_up.arrow = grid.cell_of((pickup as Node3D).global_position)


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
