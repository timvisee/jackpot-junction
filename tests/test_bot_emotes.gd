extends GdUnitTestSuite
## The bots' emotes, GAME.md 3.8 and 9.1, see [BotEmotes]: on the moments a player would put one
## up, a chance each, after a moment's thought, and then quiet for a while. Every chance taken here,
## so each moment is seen to be one.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner
var _said: Array[Vector2i] = []


func _count(slot: int, emote: int) -> void:
	_said.append(Vector2i(slot, emote))


func before_test() -> void:
	_said.clear()
	Events.emoted.connect(_count)


func after_test() -> void:
	Events.emoted.disconnect(_count)


## A match of a player in slot 0 and bots in 1 and 2, whose bots always take their chance.
func _start() -> BotEmotes:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new(), BotInput.new()
	]
	match_node.start(inputs, 7)
	var emotes: BotEmotes = match_node.get_node("BotEmotes")
	# Sure of it, whatever a bot's chattiness, which is weighed in with the chance.
	emotes.chance = 100.0
	return emotes


## Long enough for any bot to have thought it over.
func _think() -> void:
	await _runner.simulate_frames(int(BotEmotes.DELAY_MAX * 60.0) + 10, 17)


func test_a_bot_shoving_another_down_a_hole_is_pleased_and_the_other_is_cross() -> void:
	var emotes := await _start()
	await _runner.simulate_frames(10, 17)
	Events.kart_killed.emit(2, 1, &"pit")
	assert_array(_said).is_empty()
	await _think()
	assert_bool(Vector2i(1, BotEmotes.HAPPY) in _said).is_true()
	assert_bool(Vector2i(2, BotEmotes.ANGRY) in _said).is_true()
	# And then quiet for a while, whatever happens.
	_said.clear()
	Events.kart_killed.emit(2, 1, &"pit")
	await _think()
	assert_array(_said).is_empty()
	emotes._next.clear()
	# Shot at three times by the same player, the bot is cross.
	for i: int in BotEmotes.HOUNDED:
		Events.kart_shot.emit(1, 0)
	await _think()
	assert_bool(Vector2i(1, BotEmotes.ANGRY) in _said).is_true()


func test_a_bot_killed_the_moment_it_came_back_is_cross() -> void:
	var emotes := await _start()
	await _runner.simulate_frames(10, 17)
	Events.kart_respawned.emit(2, Vector3.ZERO)
	Events.kart_killed.emit(2, 0, &"bullet")
	await _think()
	assert_array(_said).is_equal([Vector2i(2, BotEmotes.ANGRY)] as Array[Vector2i])
	# Killed long after coming back is nothing to say.
	_said.clear()
	emotes._next.clear()
	Events.kart_respawned.emit(1, Vector3.ZERO)
	await _runner.simulate_frames(int(BotEmotes.SPAWN_KILL * 60.0) + 20, 17)
	Events.kart_killed.emit(1, 0, &"bullet")
	await _think()
	assert_array(_said).is_empty()


## Only bots: a player's moments are theirs to say something about.
func test_a_player_is_never_emoted_for() -> void:
	await _start()
	await _runner.simulate_frames(10, 17)
	Events.kart_killed.emit(0, 1, &"pit")
	await _think()
	assert_bool(Vector2i(0, BotEmotes.ANGRY) in _said).is_false()
	assert_bool(Vector2i(1, BotEmotes.HAPPY) in _said).is_true()


## A chance is a chance: at none, a bot never says anything.
func test_a_bot_that_never_takes_its_chance_says_nothing() -> void:
	var emotes := await _start()
	emotes.chance = 0.0
	await _runner.simulate_frames(10, 17)
	Events.kart_killed.emit(2, 1, &"pit")
	await _think()
	assert_array(_said).is_empty()


## A double kill or better pleases a bot, and near misses count as being shot at as much as hits.
func test_a_double_kill_pleases_and_near_misses_count() -> void:
	var emotes := await _start()
	await _runner.simulate_frames(10, 17)
	Events.announced.emit(1, "DOUBLE KILL")
	Events.announced.emit(2, "FIRST BLOOD")
	await _think()
	assert_array(_said).is_equal([Vector2i(1, BotEmotes.HAPPY)] as Array[Vector2i])
	_said.clear()
	emotes._next.clear()
	var hounded: Kart = emotes.match_node.kart_of(2)
	hounded.protection_left = 0.0
	for i: int in BotEmotes.HOUNDED:
		hounded._graze_cooldown_left = 0.0
		hounded.graze(0)
	await _think()
	assert_array(_said).is_equal([Vector2i(2, BotEmotes.ANGRY)] as Array[Vector2i])


## The winner says gg, and a beaten bot now and then does too, a fifth as often.
func test_the_winner_says_gg_and_the_beaten_now_and_then() -> void:
	var emotes := await _start()
	await _runner.simulate_frames(10, 17)
	var slots := emotes.match_node.slots
	slots[2].banked = 500
	emotes._on_state(Match.State.RESULTS)
	await _think()
	# Every chance taken: both bots say it, and the player is left to say their own.
	var both: Array[Vector2i] = [Vector2i(2, BotEmotes.GG), Vector2i(1, BotEmotes.GG)]
	assert_array(_said).contains_exactly_in_any_order(both)
	# At the real chance, with the two as chatty as each other, the beaten one says it far less.
	emotes.chance = BotEmotes.CHANCE
	emotes.rng.seed = 11
	for slot: PlayerSlot in [slots[1], slots[2]]:
		slot.bot_trait = slot.bot_trait.duplicate()
		slot.bot_trait.chattiness = 1.0
	var said := {1: 0, 2: 0}
	for i: int in 1000:
		emotes._next.clear()
		emotes._waiting.clear()
		emotes._on_state(Match.State.RESULTS)
		for waiting: Array in emotes._waiting:
			said[waiting[1]] += 1
	emotes._waiting.clear()
	assert_int(said[2]).is_between(300, 400)
	assert_int(said[1]).is_between(40, 100)


## On a slot machine a bot is pleased with a pull that paid more than it bet and cross at one that
## paid nothing or went void; a pair, its bet back, is nothing to say.
func test_a_bot_reacts_to_its_slot_machine_pulls() -> void:
	var emotes := await _start()
	await _runner.simulate_frames(10, 17)
	var faces := PackedByteArray([0, 1, 2])
	# Pad 99, which no machine is, so only the bots hear of these pulls.
	Events.slot_spun.emit(1, 99, 10, faces)
	Events.slot_paid.emit(1, 99, 30)
	Events.slot_spun.emit(2, 99, 10, faces)
	Events.slot_paid.emit(2, 99, 10)
	await _think()
	assert_array(_said).is_equal([Vector2i(1, BotEmotes.HAPPY)] as Array[Vector2i])
	_said.clear()
	emotes._next.clear()
	Events.slot_spun.emit(2, 99, 10, faces)
	Events.slot_paid.emit(2, 99, 0)
	Events.slot_spun.emit(1, 99, 10, faces)
	Events.slot_voided.emit(1, 99)
	await _think()
	assert_bool(Vector2i(2, BotEmotes.ANGRY) in _said).is_true()
	assert_bool(Vector2i(1, BotEmotes.ANGRY) in _said).is_true()
