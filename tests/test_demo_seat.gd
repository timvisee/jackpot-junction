extends GdUnitTestSuite
## A seat of the demo for a booth, GAME.md 9.8: a player's at this machine to the HUD and the picks,
## with a bot at the wheel, and its picks worked where everybody sees them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES := preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _match(with_hud := false, keeping := false) -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = with_hud
	match_node.hold_start = keeping
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [DemoInput.new(0), BotInput.new()]
	match_node.start(inputs, 21)
	return match_node


## Hands [param kart] [param count] jokers off the catalog, from its [param first].
func _deal(match_node: Match, kart: Kart, first: int, count: int) -> Array[StringName]:
	var given: Array[StringName] = []
	var catalog := match_node.joker_catalog.jokers
	for i: int in count:
		var joker: Joker = catalog[(first + i) % catalog.size()]
		kart.jokers.add(joker)
		given.append(joker.id)
	return given


## The seat is a player's at this machine, with no bot's name or way of driving, but its bot
## drives: the kart goes somewhere without anybody touching anything.
func test_a_seat_of_the_demo_is_driven_by_its_bot() -> void:
	var match_node := _match()
	var slot := match_node.slots[0]
	var seat := slot.input as DemoInput
	assert_bool(slot.is_local_human()).is_true()
	assert_object(slot.bot_trait).is_null()
	var kart := match_node.kart_of(0)
	assert_object(kart.input).is_same(seat)
	var brain: BotBrain = kart.get_node("Brain")
	assert_object(brain.input).is_same(seat.bot)
	assert_object(seat.bot_trait).is_not_null()
	var from := kart.global_position
	await _runner.simulate_frames(150, 17)
	assert_float(kart.global_position.distance_to(from)).is_greater(2.0)


## Its corner of the HUD is a player's, but no hint over the kart says how to drive it: nobody is.
func test_its_corner_is_a_players_without_the_drive_hint() -> void:
	ControlHint.shown_to.clear()
	var match_node := _match(true)
	await _runner.simulate_frames(2, 17)
	assert_bool(match_node.hud._blocks.has(0)).is_true()
	assert_object(match_node.kart_of(0).get_node_or_null("ControlHint")).is_null()
	ControlHint.shown_to.clear()


## While its bot drives, the seat wears a robot's head after its name, in the standings and in its
## corner, as a bot's seat does; taken over, it wears none, and handed back, it wears it again.
func test_a_seat_its_bot_drives_wears_a_robots_head() -> void:
	var match_node := _match(true)
	await _runner.simulate_frames(4, 17)
	var slot := match_node.slots[0]
	var seat := slot.input as DemoInput
	var row: Control = match_node.hud._scoreboard._rows[0]["bot"]
	var corner: Control = match_node.hud._blocks[0]["bot"]
	assert_bool(slot.bot_driven()).is_true()
	assert_bool(row.visible).is_true()
	assert_bool(corner.visible).is_true()
	# Just after the end of the name, not over it.
	var name_label: Label = match_node.hud._blocks[0]["name"]
	assert_float(corner.position.x).is_greater(0.0)
	assert_float(corner.position.x + corner.size.x).is_less_equal(name_label.size.x)
	seat.take(0)
	await _runner.simulate_frames(2, 17)
	assert_bool(slot.bot_driven()).is_false()
	assert_bool(row.visible).is_false()
	assert_bool(corner.visible).is_false()
	seat.let_go()
	await _runner.simulate_frames(2, 17)
	assert_bool(row.visible).is_true()
	assert_bool(corner.visible).is_true()


## The respawn pick is worked as a player works it: not answered at once, as a bot's is, the cursor
## stepping, and a card taken within four seconds or so.
func test_the_respawn_pick_is_worked_where_it_is_seen() -> void:
	var match_node := _match()
	await _runner.simulate_frames(20, 17)
	var slot := match_node.slots[0]
	var kart := match_node.kart_of(0)
	kart.die(&"test", 1)
	assert_object(slot.offer).is_not_null()
	assert_bool(slot.offer.is_done()).is_false()
	var offer := slot.offer
	var seen: Dictionary[int, bool] = {offer.selected: true}
	# The game's own clock, its physics ticks, which is the one the pick is worked by: a frame of the
	# test's may hold more than one of them when the machine is busy.
	var started := Engine.get_physics_frames()
	var frames := 0
	while not offer.is_done() and frames < 900:
		await _runner.simulate_frames(1, 17)
		frames += 1
		seen[offer.selected] = true
	var took := float(Engine.get_physics_frames() - started) / Engine.physics_ticks_per_second
	assert_bool(offer.is_done()).is_true()
	assert_object(offer.taken).is_not_null()
	assert_array(kart.jokers.ids()).contains([offer.taken.id])
	# Read for a while first, the cursor seen to move, and done in seven seconds and a bit at most.
	assert_int(seen.size()).is_greater(1)
	assert_float(took).is_greater(2.2)
	assert_float(took).is_less(DemoPicker.LONGEST + 0.5)


## A full hand gives up one of its cards the same way, and keeps the new one.
func test_a_full_hand_gives_one_up_the_same_way() -> void:
	var match_node := _match()
	await _runner.simulate_frames(20, 17)
	var slot := match_node.slots[0]
	var kart := match_node.kart_of(0)
	_deal(match_node, kart, 0, kart.jokers.capacity())
	assert_bool(kart.jokers.is_full()).is_true()
	kart.die(&"test", 1)
	var offer := slot.offer
	assert_object(offer).is_not_null()
	var frames := 0
	while not offer.is_done() and frames < 1000:
		await _runner.simulate_frames(1, 17)
		frames += 1
	assert_bool(offer.is_done()).is_true()
	assert_bool(kart.jokers.is_full()).is_true()
	assert_array(kart.jokers.ids()).contains([offer.chosen.id])


## The pick of a joker to keep on the grid is worked the same way, well before its deadline, and
## the lamps go once it is.
func test_the_keep_pick_is_worked_on_the_grid() -> void:
	var match_node := _match(false, true)
	var kart := match_node.kart_of(0)
	var held := _deal(match_node, kart, 3, 3)
	var options: Array[Joker] = kart.jokers.jokers.duplicate()
	while kart.jokers.count() > 0:
		kart.jokers.remove_at(0)
	JokerKeep.open(match_node.slots[0], options)
	match_node.begin_from_lobby()
	var offer := match_node.slots[0].offer
	assert_bool(offer.keeping).is_true()
	var frames := 0
	while match_node.state == Match.State.LOBBY and frames < 900:
		await _runner.simulate_frames(1, 17)
		frames += 1
	assert_int(match_node.state).is_not_equal(Match.State.LOBBY)
	assert_float(offer.keep_left).is_greater(JokerKeep.DEADLINE - DemoPicker.LONGEST - 0.5)
	assert_int(kart.jokers.count()).is_equal(1)
	assert_bool(held.has(kart.jokers.ids()[0])).is_true()


## The seat's bot has its say as the bots do, GAME.md 3.8.
func test_the_seat_emotes_as_a_bot() -> void:
	var match_node := _match()
	var emotes: BotEmotes = match_node.get_node("BotEmotes")
	assert_bool(emotes._is_bot(0)).is_true()
	assert_bool(emotes._is_bot(1)).is_true()
