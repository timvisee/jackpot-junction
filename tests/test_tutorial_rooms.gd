extends TutorialSuite
## The tutorial's later lessons, GAME.md 9.4a: the jokers and the trench, the chips, the final exam
## and the license it ends on, a full hand explained, and the title asking for the license.


## A map may hold more than one Junction: each is given the rules and wired to bank, and a bot
## heads for the nearest.
func test_two_junctions_each_bank_and_the_nearest_is_a_bots() -> void:
	var layout := ArenaLayout.new()
	layout.grid = "##########\n#JJ.S..JJ#\n#JJ....JJ#\n##########"
	layout.room = ROOM
	var arena: Arena = auto_free(ARENA_SCENE.instantiate())
	arena.layout = layout
	arena.bake_scenery = false
	add_child(arena)
	assert_int(arena.junctions.size()).is_equal(2)
	assert_object(arena.junction).is_same(arena.junctions[0])
	var rules := MatchRules.new()
	arena.start_economy(rules, RandomNumberGenerator.new(), load("res://data/powerups/all.tres"))
	for pad: JunctionPad in arena.junctions:
		assert_object(pad.rules).is_same(rules)
	var grid := arena.grid
	var west := grid.rect_center(grid.junctions[0])
	var east := grid.rect_center(grid.junctions[1])
	assert_vector(arena.junction_near(grid.cell_center(Vector2i(3, 1)))).is_equal(west)
	assert_vector(arena.junction_near(grid.cell_center(Vector2i(6, 1)))).is_equal(east)


## Jokers: the parked kart comes up, one hit takes it down for good with a card dropped where it
## stood; picked up, the hand comes into the corner. Then the trench opens wall to wall: a kart in
## it comes back across it, the pick opens, and the card taken is the task; the hand is read card by
## card; and the trench shuts again once the lesson is done.
func test_jokers_from_the_parked_kart_and_the_trench() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var kart := run.kart()
	var slot := run.slot()
	var arena := tutorial.match_node.arena
	for i: int in 3:
		run.skip()
		await _runner.simulate_frames(2, 17)
	var lesson := run.current_lesson() as TutorialJokers
	assert_str(lesson.title).is_equal("Jokers")
	assert_bool(tutorial.match_node.rules.offer_jokers).is_true()
	assert_int(run.dummies.size()).is_equal(TutorialJokers.DUMMIES)
	var dummy := run.dummies[0].kart
	await await_millis(int((RisingPiece.MARK + RisingPiece.RISE) * 1000.0) + 400)
	assert_bool(RisingPiece.is_up(dummy)).is_true()
	assert_float(dummy.global_position.distance_to(run.cell(TestGround.PARKED))).is_less(0.5)
	assert_bool(run.reveal.shown[&"lives"]).is_true()
	assert_str(run.list.said()).contains("Joker cards bend rules")
	_put(tutorial, TestGround.ITEM_BOX, TestGround.EAST)
	dummy.die(&"bullet", 0)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson._shoot.done).is_true()
	var cards: Array[FloorJoker] = []
	for pickup: Node in arena.pickups.get_children():
		if pickup is FloorJoker:
			cards.append(pickup)
	assert_int(cards.size()).is_equal(1)
	assert_str(cards[0].joker.id).is_equal(TutorialJokers.CARD)
	kart.jokers.add(cards[0].joker)
	Events.joker_taken.emit(0, cards[0].joker.id)
	cards[0].queue_free()
	await _runner.simulate_frames(2, 17)
	assert_bool(lesson._pick_up.done).is_true()
	assert_bool(tutorial.match_node.hud.hand_of(0).visible).is_true()
	# The trench opens: a pit to a kart and to the bots' map, a death coming back across it.
	assert_bool(run.trench.is_open()).is_true()
	await await_millis(int((Trench.MARK + Trench.MOVE) * 1000.0) + 300)
	assert_array(arena.grid.pits).is_equal([TestGround.TRENCH] as Array[Rect2i])
	assert_bool(tutorial.match_node.nav.is_blocked(TestGround.TRENCH.position)).is_true()
	assert_vector(lesson.spawn_cell).is_equal(TestGround.ACROSS)
	assert_object(lesson.current()).is_same(lesson._dive)
	kart.die(&"pit", -1)
	for i: int in 120:
		await _runner.simulate_frames(1, 17)
		if slot.offer != null and not slot.offer.is_done():
			break
	assert_object(slot.offer).override_failure_message("no pick after the fall").is_not_null()
	slot.offer.take(0)
	for i: int in 120:
		await _runner.simulate_frames(1, 17)
		if kart.alive:
			break
	assert_bool(lesson._dive.done).is_true()
	assert_float(kart.global_position.distance_to(run.cell(TestGround.ACROSS))).is_less(0.6)
	assert_int(kart.jokers.count()).is_equal(2)
	# Read, card by card, with the hand open; then the trench shuts and the next lesson starts.
	assert_object(lesson.current()).is_same(lesson._read)
	kart.menu_open = true
	for i: int in kart.jokers.count():
		kart.menu_index = i
		lesson.step(DT)
	kart.menu_open = false
	assert_bool(lesson._read.done).is_true()
	await _runner.simulate_frames(2, 17)
	assert_int(run.index).is_equal(4)
	assert_bool(run.trench.is_open()).is_false()
	await await_millis(int(Trench.MOVE * 1000.0) + 300)
	assert_bool(arena.grid.pits.is_empty()).is_true()
	assert_bool(tutorial.match_node.nav.is_blocked(TestGround.TRENCH.position)).is_false()


## A death after the trench opens with the pick skipped still has the trench done.
func test_a_fall_with_the_pick_skipped_does_the_trench_too() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var kart := run.kart()
	var slot := run.slot()
	for i: int in 3:
		run.skip()
		await _runner.simulate_frames(2, 17)
	var lesson := run.current_lesson() as TutorialJokers
	lesson._shoot.complete()
	lesson._pick_up.complete()
	await _runner.simulate_frames(2, 17)
	assert_bool(run.trench.is_open()).is_true()
	kart.die(&"pit", -1)
	for i: int in 120:
		await _runner.simulate_frames(1, 17)
		if slot.offer != null and not slot.offer.is_done():
			break
	slot.offer.skip()
	for i: int in 120:
		await _runner.simulate_frames(1, 17)
		if kart.alive:
			break
	await _runner.simulate_frames(2, 17)
	assert_bool(lesson._dive.done).is_true()


## Chips: the four Royal Flush pads turn over out of the floor in the corners, the pot pointed at;
## the flush brings the Jackpot up, full; drained, the Junction comes up in the middle with the bank
## and the pot both pointed at, a padlock each; the pot banked is the lesson.
func test_chips_the_flush_then_the_jackpot_then_the_junction() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var kart := run.kart()
	var arena := tutorial.match_node.arena
	for i: int in 4:
		run.skip()
		await _runner.simulate_frames(2, 17)
	var lesson := run.current_lesson() as TutorialChips
	assert_str(lesson.title).is_equal("Chips")
	assert_bool(run.reveal.shown[&"pot"]).is_true()
	assert_str(run.list.said()).contains("Royal Flush")
	await await_millis(int((RisingPiece.MARK + RisingPiece.FLIP) * 1000.0) + 1200)
	for pad: FlushPad in arena.flush_pads:
		assert_bool(RisingPiece.is_up(pad)).is_true()
	assert_bool(lesson._zone.visible).is_false()
	assert_bool(arena.junction.visible).is_false()
	Events.flush_completed.emit(kart.slot)
	assert_bool(lesson._flush.done).is_true()
	assert_str(run.list.said()).contains("Stand on a Jackpot")
	await await_millis(int((RisingPiece.MARK + RisingPiece.FLIP) * 1000.0) + 300)
	assert_bool(RisingPiece.is_up(lesson._zone)).is_true()
	assert_bool(lesson._zone.active).is_true()
	assert_float(lesson._zone.chips).is_greater(0.0)
	Events.jackpot_emptied.emit(lesson._zone.index)
	assert_bool(lesson._drain.done).is_true()
	assert_bool(kart.banks_passively).is_true()
	assert_str(run.list.said()).contains("Only banked points are safe.")
	assert_bool(run.reveal.has_card()).is_true()
	assert_bool(run.reveal._also_frame.visible).is_true()
	await await_millis(int((RisingPiece.MARK + RisingPiece.FLIP) * 1000.0) + 300)
	assert_bool(RisingPiece.is_up(arena.junction)).is_true()
	assert_object(lesson.current()).is_same(lesson._bank)
	# An empty pot sends the player back to the Jackpot.
	kart.pot.reset()
	lesson.step(DT)
	assert_vector(lesson._bank.arrow).is_equal(TestGround.JACKPOT)
	kart.pot.add_coins(20)
	lesson.step(DT)
	assert_vector(lesson._bank.arrow).is_equal(TestGround.JUNCTION)
	Events.bank_completed.emit(kart.slot, 20, 1.0, 20)
	assert_bool(lesson._bank.done).is_true()
	await _runner.simulate_frames(2, 17)
	assert_int(run.index).is_equal(5)


## The exam: the rest of a table comes up out of the floor, chips and dice over it; a bot comes up
## on a lift at once and another at 250 held; bank 500, on the goal's bar on the clipboard, and the
## tutorial is done, the bots gone in a poof; a moment later the license, numbered once, with the
## endorsements earned on their own lit and the stamp to press.
func test_the_exam_brings_the_bots_up_in_turn_and_ends_the_tutorial() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var arena := tutorial.match_node.arena
	assert_int(run.bots.size()).is_equal(TutorialFight.BOTS)
	for slot: PlayerSlot in run.bots:
		assert_bool(slot.kart.visible).is_false()
	for i: int in 5:
		run.skip()
		await _runner.simulate_frames(2, 17)
	var lesson := run.current_lesson() as TutorialFight
	assert_str(lesson.title).is_equal("Final exam")
	await await_millis(int((RisingPiece.MARK + RisingPiece.RISE) * 1000.0) + 1500)
	for pad: PowerUpPad in arena.power_pads:
		assert_bool(RisingPiece.is_up(pad)).is_true()
	for pad: CoinPad in arena.coin_pads:
		assert_bool(RisingPiece.is_up(pad)).is_true()
	# In play: a bot already up may have shot one to pieces meanwhile.
	for crate: Crate in arena.crates:
		assert_int(crate.process_mode).is_not_equal(Node.PROCESS_MODE_DISABLED)
		assert_bool(crate.has_meta(&"rising")).is_false()
	var chips := 0
	for pickup: Node in arena.pickups.get_children():
		chips += 1 if pickup is Chip else 0
	assert_int(chips).is_greater_equal(TutorialFight.CHIPS_AT.size() * TutorialFight.CHIPS_EACH)
	# The goal, then the hints under a rule, all of them listed from the start.
	assert_int(run.list.task_rows(lesson).size()).is_equal(lesson.tasks.size())
	assert_int(lesson.tasks.size()).is_equal(8)
	assert_int(tutorial.match_node.win_at).is_equal(run.slot().banked + TutorialFight.NEED)
	# The first bot up on its lift and let go; the second still under the floor.
	assert_int(lesson.released()).is_equal(1)
	assert_bool(RisingPiece.is_up(run.bots[0].kart)).is_true()
	assert_bool(run.bots[0].kart.frozen).is_false()
	assert_bool(run.bots[1].kart.visible).is_false()
	Events.item_used.emit(0, &"shield")
	assert_bool(lesson._use.done).is_true()
	Events.kart_killed.emit(run.bots[0].index, 0, &"bullet")
	assert_bool(lesson._kill.done).is_true()
	# The goal's bar on the clipboard, a death's banking on it too.
	Events.death_banked.emit(0, 40, 60)
	assert_int(lesson._bank.count).is_equal(40)
	assert_str(lesson._bank.label(false)).ends_with("40/%d" % TutorialFight.NEED)
	# A full hand is three jokers.
	var deck := tutorial.match_node.joker_catalog.jokers
	for joker: Joker in deck.slice(0, TutorialFight.HAND):
		run.kart().jokers.add(joker)
	lesson.step(DT)
	assert_bool(lesson._hand.done).is_true()
	# The exam is not skipped.
	assert_bool(lesson.skippable).is_false()
	run.skip()
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_done()).is_false()
	# The second comes up at 250 held, the pot counted with the bank.
	var pot := lesson.kart().pot
	pot.reset()
	pot.add_coins(TutorialFight.RELEASE_AT[1] - 41)
	await _runner.simulate_frames(1, 17)
	assert_int(lesson.released()).is_equal(1)
	pot.add_coins(1)
	await _runner.simulate_frames(1, 17)
	assert_int(lesson.released()).is_equal(2)
	pot.reset()
	await await_millis(int((RisingPiece.MARK + RisingPiece.RISE) * 1000.0) + 300)
	assert_bool(RisingPiece.is_up(run.bots[1].kart)).is_true()
	assert_bool(run.penned.is_empty()).is_true()
	for each: PlayerSlot in run.bots:
		var brain := each.kart.get_node("Brain") as BotBrain
		assert_object(brain.difficulty).is_same(tutorial.match_node.bot_difficulty)
	Game.settings.tutorial_done = false
	Game.settings.license_number = ""
	Game.settings.license_date = ""
	Game.settings.license_plate = ""
	Events.bank_tick.emit(0, TutorialFight.NEED - 40)
	await _runner.simulate_frames(2, 17)
	assert_bool(run.is_over()).is_true()
	for task: TutorialTask in lesson.tasks:
		assert_bool(task.done).is_true()
	assert_int(tutorial.match_node.win_at).is_equal(0)
	assert_bool(Game.settings.tutorial_done).is_true()
	var number := Game.settings.license_number
	assert_bool(number.begins_with("JJ-")).is_true()
	assert_bool("KO" in Game.settings.license_endorsements).is_true()
	assert_bool("ITEMS" in Game.settings.license_endorsements).is_true()
	assert_bool("FULL HAND" in Game.settings.license_endorsements).is_true()
	assert_bool("ROYAL FLUSH" in Game.settings.license_endorsements).is_false()
	for slot_bot: PlayerSlot in run.bots:
		assert_bool(slot_bot.kart.alive).is_false()
		assert_bool(slot_bot.kart.visible).is_false()
		assert_bool(slot_bot in run.gone).is_true()
	assert_object(tutorial.match_node.find_child("Fireworks", true, false)).is_not_null()
	# A moment after the bang, the license: the kart held, the clipboard and the menu gone.
	await await_millis(int(Tutorial.LICENSE_AFTER * 1000.0) + 400)
	await _runner.simulate_frames(2, 17)
	var license := tutorial.license
	assert_object(license).is_not_null()
	assert_bool(run.kart().frozen).is_true()
	assert_bool(run.list.visible).is_false()
	assert_object(tutorial.menu).is_null()
	assert_str(license.card.number).is_equal(number)
	var earned := license.card.endorsements
	assert_bool(earned["KO"]).is_true()
	assert_bool(earned["FULL HAND"]).is_true()
	assert_bool(earned["ROYAL FLUSH"]).is_false()
	assert_bool(license.offering()).is_false()
	license.stamp.pressed.emit()
	await await_millis(int((RubberStamp.LIFT + RubberStamp.DROP) * 1000.0) + 150)
	assert_bool(license.card.stamped).is_true()
	# Done again, the license keeps its number, what this exam earned replaces what it had, and
	# it carries the name enrolled under this time.
	Game.settings.license_endorsements = PackedStringArray(["JACKPOT"])
	Game.settings.license_holder = "Somebody Before"
	tutorial._on_finished()
	assert_str(Game.settings.license_number).is_equal(number)
	assert_bool("JACKPOT" in Game.settings.license_endorsements).is_false()
	assert_str(Game.settings.license_holder).is_equal(run.slot().display_name())


## The test's time on the license screen's second page, said once and quietly: the time, and the
## best beside it only where an earlier pass was quicker; nothing for a test with no time kept.
func test_the_test_time_is_said_with_the_best_beside_it() -> void:
	var profile := Profile.new()
	assert_str(LicenseScreen.time_words(profile)).is_empty()
	profile.test_time = 192.4
	profile.test_best = 192.4
	assert_str(LicenseScreen.time_words(profile)).is_equal("Test time 3:12")
	profile.test_best = 178.0
	assert_str(LicenseScreen.time_words(profile)).is_equal("Test time 3:12  ·  best 2:58")
	assert_str(LicenseScreen.clock(65.4)).is_equal("1:05")


## The exam's match point is the 500 on top of the bank as it began, with the pot counted in and
## never with an empty pot.
func test_the_exam_counts_its_match_point_from_the_bank_at_its_start() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var match_node := tutorial.match_node
	var kart := run.kart()
	var slot := run.slot()
	slot.banked = 120
	for i: int in 5:
		run.skip()
		await _runner.simulate_frames(2, 17)
	var fight := run.current_lesson() as TutorialFight
	assert_int(fight.bank_at_start()).is_equal(slot.banked)
	assert_int(match_node.win_at).is_equal(slot.banked + TutorialFight.NEED)
	kart.pot.reset()
	while kart.jokers.count() > 0:
		kart.jokers.remove_at(0)
	assert_float(kart.bank_payout()).is_equal(1.0)
	assert_bool(match_node.would_win(slot)).is_false()
	kart.pot.add_coins(TutorialFight.NEED - 1)
	assert_bool(match_node.would_win(slot)).is_false()
	kart.pot.add_coins(1)
	assert_bool(match_node.would_win(slot)).is_true()
	kart.pot.reset()
	slot.banked += TutorialFight.NEED
	assert_bool(match_node.would_win(slot)).is_false()


## GAME.md 8.5: what the player does in the school goes into their statistics as they leave it,
## the distance, the kills and the time, but no map played; and only the school the game is in
## writes it, never one a test started, which would write into the player's own settings.
func test_the_school_counts_into_the_profile_but_no_map() -> void:
	var tutorial := await _start()
	var slot := tutorial.run.slot()
	slot.stats.add(&"driven", 1200.0)
	slot.kills = 2
	tutorial.record.seconds = 90.0
	var real := Game.settings
	var scratch := Settings.new()
	scratch.path = "user://test_school_stats.cfg"
	Game.settings = scratch
	# Left, a test's school is not the game's: nothing is written.
	tutorial.record.leave()
	assert_bool(tutorial.record.recorded).is_false()
	tutorial.record.record()
	var profile := scratch.profile
	assert_float(LifetimeStats.value_of(profile, &"driven")).is_equal(1200.0)
	assert_float(LifetimeStats.value_of(profile, &"kills")).is_equal(2.0)
	assert_float(LifetimeStats.value_of(profile, &"seconds")).is_equal(90.0)
	assert_float(LifetimeStats.value_of(profile, &"maps")).is_zero()
	Settings.remove_files(scratch.path)
	Game.settings = real


## A joker pick with the hand already full is explained on the clipboard for as long as it is
## open, and a card replaced says REPLACED on its way out, the way a card lost says LOST.
func test_a_full_hand_is_explained_and_a_replaced_card_says_so() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var kart := run.kart()
	var slot := run.slot()
	for i: int in 3:
		run.skip()
		await _runner.simulate_frames(2, 17)
	await _runner.simulate_frames(2, 17)
	for joker: Joker in tutorial.match_node.joker_catalog.jokers:
		if kart.jokers.is_full():
			break
		if not kart.jokers.has(joker.id):
			kart.jokers.add(joker)
	assert_bool(kart.jokers.is_full()).is_true()
	assert_bool(run.list.is_saying(&"hand_full")).is_false()
	kart.die(&"pit", -1)
	for i: int in 60:
		await _runner.simulate_frames(1, 17)
		if slot.offer != null and not slot.offer.is_done():
			break
	assert_object(slot.offer).is_not_null()
	await _runner.simulate_frames(1, 17)
	assert_bool(run.list.is_saying(&"hand_full")).is_true()
	assert_str(run.list.said()).contains("Your hand is full")
	var said: Array[String] = []
	var heard := func(_slot: int, _joker: StringName, word: String) -> void: said.append(word)
	Events.joker_used_up.connect(heard)
	slot.offer.take(0)
	slot.offer.replace(0)
	Events.joker_used_up.disconnect(heard)
	assert_array(said).is_equal(["REPLACED"] as Array[String])
	assert_bool(slot.offer.is_done()).is_true()
	await _runner.simulate_frames(1, 17)
	assert_bool(run.list.is_saying(&"hand_full")).is_false()


## The title asks for the license before every way in to driving until it is earned: Drive
## anyway goes on to play, and the next press asks again; with a license nothing is asked.
func test_the_title_asks_for_the_license_until_it_is_earned() -> void:
	Game.settings.license_number = ""
	var title: Control = auto_free(load("res://scenes/ui/title.tscn").instantiate())
	add_child(title)
	await await_idle_frame()
	var went := [0]
	title.offer_license(func() -> void: went[0] += 1)
	var pane: ConfirmPane = title.find_child("LicenseOffer", true, false)
	assert_object(pane).is_not_null()
	assert_str(pane.said()).contains("Missing license")
	assert_int(went[0]).is_equal(0)
	pane.no_button().pressed.emit()
	assert_int(went[0]).is_equal(1)
	await await_idle_frame()
	assert_object(title.find_child("LicenseOffer", true, false)).is_null()
	title.offer_license(func() -> void: went[0] += 1)
	assert_object(title.find_child("LicenseOffer", true, false)).is_not_null()
	(title.find_child("LicenseOffer", true, false) as ConfirmPane).no_button().pressed.emit()
	await await_idle_frame()
	Game.settings.license_number = "JJ-224123"
	title.offer_license(func() -> void: went[0] += 1)
	assert_int(went[0]).is_equal(3)
	assert_object(title.find_child("LicenseOffer", true, false)).is_null()


## The game's own words in the lessons are drawn in their colors, GAME.md 9.4a: a counter in the
## HUD's, a place in a color of its own, marked in the line with braces and said without them.
func test_the_games_own_words_are_in_their_colors() -> void:
	assert_str(Terms.plain("{Mult} will multiply your {pot}")).is_equal(
		"Mult will multiply your pot"
	)
	var lit := Terms.bbcode("{Mult} multiplies your {pot} at the {Junction}")
	assert_str(lit).contains("[color=#%s]Mult[/color]" % Palette.MULT.to_html(false))
	assert_str(lit).contains("[color=#%s]pot[/color]" % Palette.CHIP_GOLD.to_html(false))
	assert_str(lit).contains("[color=#%s]Junction[/color]" % Terms.PLACE.to_html(false))
	assert_str(Terms.bbcode("{Mult} done", false)).is_equal("Mult done")
	for word: String in [
		"chips", "mult", "pot", "bank", "banked", "nitro", "jackpot", "royal flush"
	]:
		assert_bool(Terms.COLORS.has(word)).override_failure_message(word).is_true()
