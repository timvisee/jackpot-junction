extends GdUnitTestSuite
## The moments of a map that are achievements, GAME.md 8.10, as [AchievementRecord] hears them at
## this machine: each earned by its situation and not by one just short of it, the wins as a map is
## written down, and each into the profile of the seat that had it.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const PATH := "user://test_achievement_moments.cfg"

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.player_names[0] = "Ann"
	Game.settings.save_to_disk()


func after_test() -> void:
	AchievementRecord.anywhere = false
	MatchRecord.anywhere = false
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## A room of [param inputs], or a player here and three bots, with a record of the achievements
## in it that keeps them.
func _room(inputs: Array[KartInput] = []) -> Match:
	if inputs.is_empty():
		inputs = [PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new(), BotInput.new()]
		inputs.append(BotInput.new())
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.joker_catalog = JOKERS
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, inputs.size())
	AchievementRecord.add_to(match_node)
	AchievementRecord.anywhere = true
	return match_node


func _has(id: StringName, profile: Profile = null) -> bool:
	return (profile if profile != null else Game.settings.profile).achievements.has(id)


func _record(match_node: Match) -> AchievementRecord:
	return match_node.get_node("AchievementRecord") as AchievementRecord


## One drift held for fifteen seconds is Long Way Round; a crash on the way starts the count again,
## and a kart out of its drift holds none.
func test_long_way_round() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var slot := match_node.slots[0]
	var motor := slot.kart.motor
	var record := _record(match_node)
	motor.drifting = true
	motor.drift_time = AchievementRecord.LONG_DRIFT - 0.1
	record._watch(slot, Game.settings.profile)
	motor.spoil_drift()
	motor.drift_time += AchievementRecord.LONG_DRIFT - 0.1
	record._watch(slot, Game.settings.profile)
	motor.drifting = false
	motor.drift_time = AchievementRecord.LONG_DRIFT
	record._watch(slot, Game.settings.profile)
	assert_bool(_has(&"long_way_round")).is_false()
	motor.drifting = true
	record._watch(slot, Game.settings.profile)
	assert_bool(_has(&"long_way_round")).is_true()


## The hundredth crate broken is Property Damage the moment it breaks, the profile's crates of the
## maps before counting with this one's; a bot's crates are nobody's.
func test_property_damage() -> void:
	var match_node := _room()
	Game.settings.profile.stats[&"crates"] = 98.0
	await _runner.simulate_frames(2, 17)
	for i: int in 3:
		match_node.arena.crate_broken.emit(1)
	match_node.arena.crate_broken.emit(0)
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"property_damage")).is_false()
	match_node.arena.crate_broken.emit(0)
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"property_damage")).is_true()


## Eight karts taken out without dying is Untouchable; a death on the way starts the count again.
func test_untouchable() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	for i: int in 7:
		Events.kart_killed.emit(1 + i % 3, 0, &"bullet")
	Events.kart_killed.emit(0, 1, &"bullet")
	Events.kart_killed.emit(1, 0, &"bullet")
	assert_bool(_has(&"untouchable")).is_false()
	for i: int in 7:
		Events.kart_killed.emit(2, 0, &"ram")
	assert_bool(_has(&"untouchable")).is_true()


## Five bullets of other karts shot down in one life is Parry; a death in between starts again, and
## a kart's own shots meeting are no parry.
func test_parry() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	for i: int in 4:
		Events.bullets_met.emit(1, 0)
	Events.bullets_met.emit(0, 0)
	Events.kart_killed.emit(0, -1, &"pit")
	Events.bullets_met.emit(0, 2)
	assert_bool(_has(&"parry")).is_false()
	for i: int in 4:
		Events.bullets_met.emit(2, 0)
	assert_bool(_has(&"parry")).is_true()


## A kill by a bullet off two walls is a Bank Shot; one wall, or a decoy's bullet, is not.
func test_bank_shot() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	Events.kill_detailed.emit(1, false, 1)
	Events.kart_killed.emit(1, 0, &"bullet")
	Events.kill_detailed.emit(2, true, 2)
	Events.kart_killed.emit(2, 0, &"bullet")
	assert_bool(_has(&"bank_shot")).is_false()
	Events.kill_detailed.emit(3, false, 2)
	Events.kart_killed.emit(3, 0, &"bullet")
	assert_bool(_has(&"bank_shot")).is_true()


## A kart taken out by a bullet from 25 m or more is a Long Shot; nearer, or a turret's, is not.
func test_long_shot() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	match_node.slots[0].kart.global_position = Vector3.ZERO
	match_node.slots[1].kart.global_position = Vector3(20.0, 0.0, 10.0)
	match_node.slots[2].kart.global_position = Vector3(30.0, 0.0, 0.0)
	Events.kart_killed.emit(1, 0, &"bullet")
	Events.kart_killed.emit(2, 0, &"turret")
	assert_bool(_has(&"long_shot")).is_false()
	Events.kart_killed.emit(2, 0, &"bullet")
	assert_bool(_has(&"long_shot")).is_true()


## Taking out whoever took you out within ten seconds of coming back, three times in one map, is
## Payback; too late, or somebody else, does not count.
func test_payback() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var record := _record(match_node)
	var avenged := func(late: bool) -> void:
		Events.kart_killed.emit(0, 1, &"bullet")
		Events.kart_respawned.emit(0, Vector3.ZERO)
		if late:
			record._clock += 11.0
		Events.kart_killed.emit(1, 0, &"bullet")
	avenged.call(false)
	avenged.call(true)
	Events.kart_killed.emit(0, 2, &"bullet")
	Events.kart_respawned.emit(0, Vector3.ZERO)
	Events.kart_killed.emit(1, 0, &"bullet")
	avenged.call(false)
	assert_bool(_has(&"payback")).is_false()
	avenged.call(false)
	assert_bool(_has(&"payback")).is_true()


## Two karts taken out by one bomb is Two Birds; two bombs a second apart are not.
func test_two_birds() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	Events.kart_killed.emit(1, 0, &"bomb")
	await _runner.simulate_frames(60, 17)
	Events.kart_killed.emit(2, 0, &"bomb")
	assert_bool(_has(&"two_birds")).is_false()
	await _runner.simulate_frames(60, 17)
	Events.kart_killed.emit(1, 0, &"bomb")
	Events.kart_killed.emit(3, 0, &"bomb")
	assert_bool(_has(&"two_birds")).is_true()


## Three karts to one turret is Set and Forget; two to it, with another to the turret before it,
## is not.
func test_set_and_forget() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	Events.item_used.emit(0, &"turret")
	Events.kart_killed.emit(1, 0, &"turret")
	Events.item_used.emit(0, &"turret")
	Events.kart_killed.emit(2, 0, &"turret")
	Events.kart_killed.emit(3, 0, &"turret")
	assert_bool(_has(&"set_and_forget")).is_false()
	Events.kart_killed.emit(1, 0, &"turret")
	assert_bool(_has(&"set_and_forget")).is_true()


## Three karts knocked into pits in one map is Push Comes to Shove.
func test_push_comes_to_shove() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	Events.kart_killed.emit(1, 0, &"pit")
	Events.kart_killed.emit(2, 0, &"pit")
	assert_bool(_has(&"push_comes_to_shove")).is_false()
	Events.kart_killed.emit(3, 0, &"pit")
	assert_bool(_has(&"push_comes_to_shove")).is_true()


## Over the edge of a pit with a pot worth a thousand is A Pit. Do Not.; with less it is a pit.
func test_a_pit_do_not() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var pot := match_node.slots[0].kart.pot
	pot.add_coins(99)
	pot.add_mult(9.0)
	await _runner.simulate_frames(2, 17)
	Events.kart_fell.emit(0)
	assert_bool(_has(&"a_pit_do_not")).is_false()
	pot.add_coins(1)
	await _runner.simulate_frames(2, 17)
	Events.kart_fell.emit(0)
	assert_bool(_has(&"a_pit_do_not")).is_true()


## A cash-out of a thousand with a bounty on your head is Most Wanted; one under, or after the
## bounty lapsed, is not.
func test_most_wanted() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	Events.bank_completed.emit(0, 100, 10.0, 1000)
	Events.bounty_called.emit(0)
	Events.bank_completed.emit(0, 100, 9.99, 999)
	Events.bounty_lapsed.emit(0)
	Events.bank_completed.emit(0, 100, 10.0, 1000)
	assert_bool(_has(&"most_wanted")).is_false()
	Events.bounty_called.emit(0)
	Events.bank_completed.emit(0, 100, 10.0, 1000)
	assert_bool(_has(&"most_wanted")).is_true()


## A Jackpot pile of 120, a full one at the hottest table, emptied by one kart alone is Hit the
## Jackpot; one somebody else took some of, or a smaller one, is not.
func test_hit_the_jackpot() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	Events.jackpot_collected.emit(0, 70)
	Events.jackpot_collected.emit(1, 5)
	Events.jackpot_collected.emit(0, 50)
	Events.jackpot_emptied.emit(0)
	Events.jackpot_collected.emit(0, 119)
	Events.jackpot_emptied.emit(1)
	assert_bool(_has(&"hit_the_jackpot")).is_false()
	Events.jackpot_collected.emit(0, 70)
	Events.jackpot_collected.emit(0, 50)
	Events.jackpot_emptied.emit(0)
	assert_bool(_has(&"hit_the_jackpot")).is_true()


## Nine jokers held at once is A Real Handful; two jokers at their full stacks is Stacked.
func test_the_hand() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var kart := match_node.slots[0].kart
	for id: StringName in [&"payday", &"payday", &"payday", &"vulture", &"vulture"]:
		kart.jokers.add(JOKERS.by_id(id))
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"stacked")).is_false()
	kart.jokers.add(JOKERS.by_id(&"vulture"))
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"stacked")).is_true()
	for id: StringName in [&"odometer", &"tailslide"]:
		kart.jokers.add(JOKERS.by_id(id))
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"a_real_handful")).is_false()
	kart.jokers.add(JOKERS.by_id(&"comeback"))
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"a_real_handful")).is_true()


## A pot worth three times the target score the map was set to is Push Your Luck; in a room with
## no target nothing is, nor against a goal a lesson sets itself with none set.
func test_push_your_luck() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var pot := match_node.slots[0].kart.pot
	pot.add_coins(300)
	pot.add_mult(9.0)
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"push_your_luck")).is_false()
	match_node.win_at = 1000
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"push_your_luck")).is_false()
	match_node.win_at = 0
	match_node.rules = RULES.duplicate()
	match_node.rules.target_score = 1001
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"push_your_luck")).is_false()
	match_node.rules.target_score = 1000
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"push_your_luck")).is_true()


## A pot coming to win the map while the kart is cashing it out on the Junction is Point of Sale;
## driving on with a pot that already wins it is not.
func test_point_of_sale() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	match_node.win_at = 1000
	var kart := match_node.slots[0].kart
	var pad := match_node.arena.junctions[0]
	kart.pot.add_coins(200)
	kart.pot.add_mult(4.0)
	kart.global_position = pad.global_position
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"point_of_sale")).is_false()
	kart.global_position = pad.global_position + Vector3(pad.radius + 3.0, 0.0, 0.0)
	await _runner.simulate_frames(2, 17)
	kart.global_position = pad.global_position
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"point_of_sale")).is_false()
	# A kill from the pad: the mult goes up in the middle of the cash-out, and the pot with it.
	kart.pot.coins = 100
	kart.pot.mult = 5.0
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"point_of_sale")).is_false()
	kart.pot.mult = 12.0
	await _runner.simulate_frames(2, 17)
	assert_bool(_has(&"point_of_sale")).is_true()


## The last kart left in sudden death that four began is Last Kart Standing; two are not enough.
func test_last_kart_standing() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	match_node.slots[3].kart.alive = false
	Events.match_state_changed.emit(Match.State.OVERTIME)
	for i: int in [1, 2]:
		match_node.slots[i].kart.alive = false
	Events.match_state_changed.emit(Match.State.RESULTS)
	assert_bool(_has(&"last_kart_standing")).is_false()
	var again := _room()
	await _runner.simulate_frames(2, 17)
	Events.match_state_changed.emit(Match.State.OVERTIME)
	for i: int in [1, 2, 3]:
		again.slots[i].kart.alive = false
	Events.match_state_changed.emit(Match.State.RESULTS)
	assert_bool(_has(&"last_kart_standing")).is_true()


## The wins of a whole map: Flawless without a life lost, All In with one cash-out, By a Nose
## within fifty, Asking for Trouble with three cursed cards and Beat the House on Hard; none for a
## map lost.
func test_the_wins() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var slot := match_node.slots[0]
	for id: StringName in [&"snake_eyes", &"road_rage", &"high_roller"]:
		slot.kart.jokers.add(JOKERS.by_id(id))
	Events.bank_started.emit(0)
	slot.banked = 3000
	match_node.slots[1].banked = 2960
	AchievementRecord.map_played(match_node, slot, ann, false)
	assert_int(ann.achievements.earned.size()).is_equal(0)
	match_node.bot_difficulty = load("res://data/ai/hard.tres")
	AchievementRecord.map_played(match_node, slot, ann, true)
	for id: StringName in [
		&"flawless", &"all_in", &"by_a_nose", &"asking_for_trouble", &"beat_the_house"
	]:
		assert_bool(_has(id)).override_failure_message(String(id)).is_true()


## A life lost, a second cash-out or a win by more than fifty earns none of those; a map won
## against two earns Flawless and By a Nose but not All In; and against one, none of them.
func test_the_wins_short_of_it() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var slot := match_node.slots[0]
	Events.kart_wounded.emit(0, 1, &"bullet")
	Events.bank_started.emit(0)
	Events.bank_started.emit(0)
	slot.banked = 3000
	match_node.slots[1].banked = 2900
	AchievementRecord.map_played(match_node, slot, ann, true)
	for id: StringName in [&"flawless", &"all_in", &"by_a_nose", &"beat_the_house"]:
		assert_bool(_has(id)).override_failure_message(String(id)).is_false()
	var two: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new(), BotInput.new()
	]
	var three := _room(two)
	await _runner.simulate_frames(2, 17)
	Events.bank_started.emit(0)
	three.slots[0].banked = 3000
	three.slots[1].banked = 2960
	AchievementRecord.map_played(three, three.slots[0], ann, true)
	assert_bool(_has(&"flawless")).is_true()
	assert_bool(_has(&"by_a_nose")).is_true()
	assert_bool(_has(&"all_in")).is_false()
	ann.achievements.earned.clear()
	var few: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new()]
	var small := _room(few)
	await _runner.simulate_frames(2, 17)
	AchievementRecord.map_played(small, small.slots[0], ann, true)
	assert_bool(_has(&"flawless")).is_false()


## Two people at this screen make Plus One for the one with a profile; a guest earns nothing.
func test_plus_one() -> void:
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(0, 1), BotInput.new()
	]
	var match_node := _room(inputs)
	await _runner.simulate_frames(2, 17)
	AchievementRecord.map_played(match_node, match_node.slots[0], Game.settings.profile, false)
	assert_bool(_has(&"plus_one")).is_true()


## A moment goes into the profile of the seat it was had at, the linked profile's at another seat,
## and a guest's and a bot's nowhere; a test's room keeps nothing.
func test_a_moment_goes_into_the_profile_at_its_seat() -> void:
	var bob := Game.settings.new_profile()
	bob.player_names[0] = "Bob"
	bob.save_to_disk()
	Game.settings.link_seat(1, bob.id)
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0),
		PlayerInput.new(0, 1),
		PlayerInput.new(1, 2),
		BotInput.new(),
	]
	_room(inputs)
	AchievementRecord.anywhere = false
	await _runner.simulate_frames(2, 17)
	for i: int in 3:
		Events.kart_killed.emit(3, 0, &"pit")
	assert_bool(_has(&"push_comes_to_shove")).is_false()
	AchievementRecord.anywhere = true
	for slot: int in [1, 2, 3]:
		for i: int in 3:
			Events.kart_killed.emit(0, slot, &"pit")
	assert_bool(_has(&"push_comes_to_shove")).is_false()
	assert_bool(_has(&"push_comes_to_shove", Game.settings.seat_profile(1))).is_true()


## Ten hits taken in one life and lived through, lives lost or shields popped, is Tough as Nails; a
## death on the way starts the count again.
func test_tough_as_nails() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	for i: int in 9:
		Events.kart_wounded.emit(0, 1, &"bullet")
	Events.kart_killed.emit(0, 1, &"bullet")
	assert_bool(_has(&"tough_as_nails")).is_false()
	for i: int in 5:
		Events.kart_wounded.emit(0, 2, &"ram")
	for i: int in 4:
		Events.shield_popped.emit(0)
	assert_bool(_has(&"tough_as_nails")).is_false()
	Events.shield_popped.emit(0)
	assert_bool(_has(&"tough_as_nails")).is_true()


## The dress put on at a stall is earned there and then, the card back with it.
func test_dressed_at_the_stall() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	ann.kart_styles[0] = PackedInt32Array([1, 1, 1, 1, 1, 1])
	ann.loyalty.card_back = 1
	Events.kart_dressed.emit(0, 0, PackedInt32Array([1, 1, 1, 1, 1, 1]))
	await _runner.simulate_frames(1, 17)
	assert_bool(_has(&"dressed_to_the_nines")).is_true()


## A cash-out in the clock's last five seconds that takes the lead, and the map won, is a Buzzer
## Beater; one before then, or one that leaves the kart where it was, ahead already, is not.
func test_buzzer_beater() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var slot := match_node.slots[0]
	match_node.state = Match.State.PLAYING
	match_node.slots[1].banked = 2000
	match_node.time_left = 30.0
	slot.banked = 2100
	Events.bank_completed.emit(0, 100, 2.0, 200)
	match_node.time_left = 4.0
	slot.banked = 2200
	Events.bank_completed.emit(0, 50, 2.0, 100)
	AchievementRecord.map_played(match_node, slot, ann, true)
	assert_bool(_has(&"buzzer_beater")).is_false()
	match_node.slots[1].banked = 2300
	slot.banked = 2400
	Events.bank_completed.emit(0, 100, 2.0, 200)
	AchievementRecord.map_played(match_node, slot, ann, true)
	assert_bool(_has(&"buzzer_beater")).is_true()


## A kart taken out while it collects a Jackpot, and the pile emptied by whoever took it out, is
## Snatch and Grab; the pile emptied by somebody else, or a kart taken out that was not collecting,
## is not.
func test_snatch_and_grab() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	Events.kart_killed.emit(1, 0, &"bullet")
	Events.jackpot_collected.emit(0, 30)
	Events.jackpot_emptied.emit(0)
	assert_bool(_has(&"snatch_and_grab")).is_false()
	Events.jackpot_collected.emit(2, 4)
	Events.kart_killed.emit(2, 0, &"bullet")
	Events.jackpot_collected.emit(3, 10)
	Events.jackpot_emptied.emit(0)
	assert_bool(_has(&"snatch_and_grab")).is_false()
	Events.jackpot_collected.emit(3, 4)
	Events.kart_killed.emit(3, 0, &"bomb")
	Events.jackpot_collected.emit(0, 25)
	Events.jackpot_emptied.emit(0)
	assert_bool(_has(&"snatch_and_grab")).is_true()


## Three Royal Flushes in one map are a Full House.
func test_full_house() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	Events.flush_completed.emit(0)
	Events.flush_completed.emit(1)
	Events.flush_completed.emit(0)
	assert_bool(_has(&"full_house")).is_false()
	Events.flush_completed.emit(0)
	assert_bool(_has(&"full_house")).is_true()


## Two karts rammed out with one Boost are Road Hog; one each with two Boosts, or a ram's kill with
## no Boost going, is not.
func test_road_hog() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	Events.kart_killed.emit(1, 0, &"ram")
	Events.item_used.emit(0, &"boost")
	Events.kart_killed.emit(2, 0, &"ram")
	Events.item_used.emit(0, &"boost")
	Events.kart_killed.emit(3, 0, &"ram")
	assert_bool(_has(&"road_hog")).is_false()
	Events.kart_killed.emit(1, 0, &"ram")
	assert_bool(_has(&"road_hog")).is_true()


## Three karts spun out on one slick are Slick Operator for whoever laid it; the layer's own spin
## and spins on another slick count for none of it.
func test_slick_operator() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var mine := OilStain.new()
	mine.owner_slot = 0
	match_node.add_child(mine)
	mine.global_position = Vector3(20.0, 0.0, 20.0)
	var other := OilStain.new()
	other.owner_slot = 0
	match_node.add_child(other)
	other.global_position = Vector3(-20.0, 0.0, -20.0)
	var spin := func(seat: int, on: OilStain) -> void:
		match_node.slots[seat].kart.global_position = on.global_position
		Events.oil_hit.emit(seat)
	spin.call(0, mine)
	spin.call(1, mine)
	spin.call(2, other)
	spin.call(2, mine)
	assert_bool(_has(&"slick_operator")).is_false()
	spin.call(3, mine)
	assert_bool(_has(&"slick_operator")).is_true()


## A kart taken out by your decoy is Dead Ringer; by your own shot, it is not.
func test_dead_ringer() -> void:
	_room()
	await _runner.simulate_frames(2, 17)
	Events.kill_detailed.emit(1, false, 0)
	Events.kart_killed.emit(1, 0, &"bullet")
	assert_bool(_has(&"dead_ringer")).is_false()
	Events.kill_detailed.emit(2, true, 0)
	Events.kart_killed.emit(2, 0, &"bullet")
	assert_bool(_has(&"dead_ringer")).is_true()


## Every map of a Grand Prix of three won against three or more is a Clean Sweep, the last one
## counted as its whistle goes, before the run has scored it; one map of it lost is not.
func test_clean_sweep() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var was := Game.grand_prix
	var run := GrandPrix.new()
	run.playlist.assign([&"lucky_crossing", &"vault", &"crossfire"])
	run.round = 2
	run.scored_round = 1
	run.places[0] = [1, 2]
	Game.grand_prix = run
	AchievementRecord.map_played(match_node, match_node.slots[0], ann, true)
	assert_bool(_has(&"clean_sweep")).is_false()
	run.places[0] = [1, 1]
	AchievementRecord.map_played(match_node, match_node.slots[0], ann, true)
	Game.grand_prix = was
	assert_bool(_has(&"clean_sweep")).is_true()


## A map played online with somebody at another machine is Long Distance, a bot not counting, and
## one with eight karts at the table, bots counting, is Full Table; off line, neither. Online for
## the moment it is asked, a session of its own standing in for one.
func test_company_online() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0)]
	for i: int in 7:
		inputs.append(BotInput.new())
	var match_node := _room(inputs)
	await _runner.simulate_frames(2, 17)
	var ann := Game.settings.profile
	var slot := match_node.slots[0]
	AchievementRecord.map_played(match_node, slot, ann, false)
	assert_bool(_has(&"full_table")).is_false()
	var was := Net.session
	var online := NetSession.new()
	Net.session = online
	AchievementRecord.map_played(match_node, slot, ann, false)
	Net.session = was
	assert_bool(_has(&"full_table")).is_true()
	assert_bool(_has(&"long_distance")).is_false()
	match_node.slots[1].bot_trait = null
	match_node.slots[1].input = NetInput.new()
	Net.session = online
	AchievementRecord.map_played(match_node, slot, ann, false)
	Net.session = was
	online.free()
	assert_bool(_has(&"long_distance")).is_true()


## Watching an online map from its flag to its whistle with an emote sent is Front Row; with none
## sent, it is not. Watching for the moment the whistle is heard, a session of its own standing in.
func test_front_row() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var record := _record(match_node)
	var was := Net.session
	var watching := NetSession.new()
	watching.watching = true
	Events.countdown_done.emit()
	Net.session = watching
	record._on_state(Match.State.RESULTS)
	Net.session = was
	assert_bool(_has(&"front_row")).is_false()
	Events.watched_emote.emit(1)
	Net.session = watching
	record._on_state(Match.State.RESULTS)
	Net.session = was
	watching.free()
	assert_bool(_has(&"front_row")).is_true()
