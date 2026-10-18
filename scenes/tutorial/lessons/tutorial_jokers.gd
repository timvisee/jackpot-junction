class_name TutorialJokers
extends TutorialLesson
## Lesson 4, GAME.md 9.4a: jokers. A parked kart rises facing the kart coming down from the
## targets, which never moves or shoots and goes down to one hit, for good, dropping a card, Magnet
## Hubcaps, since it helps with the chips straight after: shoot it and pick the card up, which
## brings the hand into the corner. Then the trench opens across the lot, wall to wall, with no way
## round: a kart that goes in dies and comes back across it, where the joker pick opens, for a
## second card. Two cards, then read each in the hand, with the hand's key held and the steering
## walking it, or a tap on each card on a touch screen, see 3.7. The lives come into the corner with
## the lesson. The trench closes once the lesson is done, and from here on a death opens the pick,
## as it does in a match.

const DUMMIES := 1
const CARD := &"magnet_hubcaps"
## How much floor the parked kart stands on, for its outline.
const PARKED_ACROSS := Vector2(1.6, 2.2)
## What the clipboard says the lesson is about.
const WORDS := (
	"Joker cards bend rules in your favor. A kart taken out may drop one, and every death "
	+ "offers you a pick."
)

var _shoot: TutorialTask
var _pick_up: TutorialTask
var _dive: TutorialTask
var _read: TutorialTask
## The cards read so far, by id.
var _viewed: Dictionary[StringName, bool] = {}
var _hand_shown := false
## Whether the kart has gone down since the trench opened: back up with the pick done or skipped,
## the trench has done its piece.
var _fell := false


func _init() -> void:
	title = "Jokers"
	ensures = [&"hand"]
	spawn_cell = TestGround.ITEM_BOX
	facing = TestGround.EAST
	reveals = [[&"lives", "", []]]
	_shoot = add_task("Shoot the parked kart", "", [InputActions.FIRE])
	_shoot.arrow = TestGround.PARKED
	_pick_up = add_task("Pick up the card it dropped", "")
	_pick_up.arrow = TestGround.PARKED
	_dive = add_task("Drive into the trench, then pick a joker", "")
	_dive.arrow = TestGround.TRENCH.position + Vector2i(1, TestGround.PARKED.y - 1)
	_dive.ringed = false
	_read = add_task("Read each card in your hand", "", [InputActions.JOKER_MENU], true)
	pointer_until = _read


## The parked kart, held back.
func _prepare() -> void:
	for slot_dummy: PlayerSlot in run.dummies:
		keep_back(slot_dummy.kart, PARKED_ACROSS)


func _begin() -> void:
	# A death opens the joker pick from here on, GAME.md 3.7.
	run.match_node.rules.offer_jokers = true
	run.list.say(&"jokers", WORDS)
	bring_up(piece_nodes())
	Events.kart_killed.connect(_on_killed)
	Events.joker_taken.connect(_on_taken)


func end() -> void:
	var hand := run.match_node.hud.hand_of(kart().slot) if run.match_node.hud != null else null
	if hand != null:
		hand.set_unread([])
	if Events.kart_killed.is_connected(_on_killed):
		Events.kart_killed.disconnect(_on_killed)
	if Events.joker_taken.is_connected(_on_taken):
		Events.joker_taken.disconnect(_on_taken)
	if run.trench != null:
		run.trench.close()
	super()


## Done whichever way: the pick on from here, and the parked kart gone for good, under the floor
## where nothing shoots it and no feed says so.
func _settle() -> void:
	run.match_node.rules.offer_jokers = true
	for slot_dummy: PlayerSlot in run.dummies:
		slot_dummy.respawn_left = INF
		RisingPiece.hold(slot_dummy.kart)


func step(_delta: float) -> void:
	# The hand comes in with the first card, and is pointed at once the rest is done, so the
	# reading is the one thing left to do when the pointer says how.
	if not _hand_shown and kart().jokers.count() > 0 and run.reveal != null:
		run.reveal.show_piece(&"hand", "", [])
		if _dive.done:
			_hand_shown = true
			run.reveal.show_piece(&"hand", "Your jokers", [InputActions.JOKER_MENU])
	_aim_at_card()
	_read_cards()
	# A hand already full takes no card off the floor: the picking up is as good as done.
	if kart().jokers.is_full() and not _pick_up.done:
		_pick_up.complete()
	# The card in hand, the trench opens, and a death comes back across it.
	if _pick_up.done and run.trench != null and not run.trench.is_open() and not _dive.done:
		run.trench.open()
		spawn_cell = TestGround.ACROSS
		facing = TestGround.WEST
	if current() == _dive:
		_dive.arrow = Vector2i(TestGround.TRENCH.end.x - 1, run.grid().cell_of(kart().position).y)
		# Back up across the trench with the pick taken or skipped: the trench has done its piece.
		var picking := run.slot().offer != null and not run.slot().offer.is_done()
		if _fell and kart().alive and not picking:
			_dive.complete()


## The card under the cursor, with the hand open, is read: the task is every card in the hand.
func _read_cards() -> void:
	if _read.done or current() != _read:
		return
	var ids := kart().jokers.ids()
	if kart().menu_open and kart().menu_index >= 0 and kart().menu_index < ids.size():
		_viewed[ids[kart().menu_index]] = true
	var read := 0
	var unread: Array[StringName] = []
	for id: StringName in ids:
		if _viewed.has(id):
			read += 1
		else:
			unread.append(id)
	_read.progress = float(read) / maxf(float(ids.size()), 1.0)
	# The cards still to read wear an eye on the hand itself, which is where the player looks.
	var hand := run.match_node.hud.hand_of(kart().slot) if run.match_node.hud != null else null
	if hand != null:
		hand.set_unread(unread)
	if not ids.is_empty() and read >= ids.size():
		_read.complete()


## The arrow on the card still on the floor.
func _aim_at_card() -> void:
	var here := kart().global_position
	var best := INF
	for pickup: Node in arena().pickups.get_children():
		if pickup is FloorJoker and is_instance_valid(pickup):
			var distance := here.distance_to((pickup as Node3D).global_position)
			if distance < best:
				best = distance
				_pick_up.arrow = run.grid().cell_of((pickup as Node3D).global_position)


## The parked kart shot: its card goes on the floor where it stood.
func _on_killed(victim: int, _killer: int, _cause: StringName) -> void:
	if victim == kart().slot and _pick_up.done:
		_fell = true
		return
	var which := -1
	for i: int in run.dummies.size():
		if run.dummies[i].index == victim:
			which = i
	if which < 0 or _shoot.done:
		return
	var card := run.match_node.joker_catalog.by_id(CARD)
	if card != null:
		arena().spawn_floor_joker(run.dummies[which].kart.global_position, card, 0.0)
	_shoot.complete()


## A card taken: off the floor while alive, out of the pick while dead, which is the trench's.
func _on_taken(slot_index: int, _joker: StringName) -> void:
	if slot_index != kart().slot:
		return
	if kart().alive:
		if _shoot.done and not _pick_up.done:
			_pick_up.complete()
	elif _pick_up.done and not _dive.done:
		_dive.complete()
