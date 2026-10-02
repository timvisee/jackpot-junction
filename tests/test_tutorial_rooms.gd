extends TutorialSuite
## The tutorial's later rooms, GAME.md 9.4a: items, jokers, the last room's three lessons, the
## gates' care for whoever is in them, and the title asking for the license.


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


## Items: three stations in any order, the hint on the nearest. The Shield has to take the
## guard's shot; the pocket's target counts only off a bounce, behind a wall of light a kart cannot
## pass; the row counts only shot by a turret.
func test_items_three_stations_in_any_order() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(6)
	var lesson := run.current_lesson() as TutorialItems
	var arena := tutorial.match_node.arena
	await _runner.simulate_frames(2, 17)
	assert_bool(lesson.ordered).is_false()
	# Nothing pointed at the item slot yet, and the names are on the floor, not in the air.
	assert_bool(run.reveal.is_pointing()).is_false()
	assert_bool((tutorial.match_node.hud.block_parts(0)["item"] as Control).visible).is_false()
	assert_bool(lesson._signs.is_empty()).is_true()
	# The lesson's own boxes, each holding its item, down from the start of the tutorial.
	var boxes: Array[ItemBox] = []
	for pickup: Node in arena.pickups.get_children():
		if pickup is ItemBox and (pickup as ItemBox).fixed_item != null:
			boxes.append(pickup)
	assert_int(boxes.size()).is_equal(3)
	assert_bool(lesson._guard.alive).is_true()
	assert_bool(lesson._guard.fixture).is_true()
	assert_float(lesson._guard.reach).is_equal(TutorialItems.GUARD_REACH)
	var shot: Bullet = auto_free(Bullet.new())
	assert_bool(lesson._guard.take_hit(shot)).is_true()
	assert_bool(lesson._guard.alive).is_true()
	assert_int(lesson._window.collision_layer).is_equal(Layers.PROTECTED)
	assert_int(lesson._row_window.collision_layer).is_equal(Layers.PROTECTED)
	assert_object(tutorial.match_node.find_child("GuideDots", true, false)).is_not_null()
	var bank := lesson._bank_point()
	var wall := run.cell(Vector2i(TutorialItems.POCKET.x, TutorialItems.POCKET_WALL_ROW)).z
	var face := wall + arena.grid.cell_size * 0.5 + TutorialItems.BULLET_RADIUS
	assert_float(bank.z).is_equal_approx(face, 0.01)
	assert_float(bank.x).is_between(
		run.cell(TutorialItems.SHOOT_FROM).x, run.cell(TutorialItems.POCKET).x
	)
	assert_object(tutorial.match_node.find_child("HazardLine", true, false)).is_not_null()
	assert_object(tutorial.match_node.find_child("HazardBox", true, false)).is_not_null()
	assert_str(lesson._take_shield.hint).is_equal("")
	assert_str(lesson._pop.text).contains("Arm it")
	assert_bool(bool(run.kart().collision_mask & Layers.PROTECTED)).is_true()
	# Nearest the Ricochet box, that station is the one being done; the list shows all seven,
	# with a line between the stations.
	_put(tutorial, TutorialItems.RICOCHET_BOX + Vector2i(-1, 0), Vector3(1.0, 0.0, 0.0))
	await _runner.simulate_frames(2, 17)
	assert_object(lesson.current()).is_same(lesson._take_ricochet)
	assert_int(run.list.task_rows(lesson).size()).is_equal(7)
	var rules := 0
	for row: Node in run.list._rows.get_children():
		rules += 1 if row is MarginContainer else 0
	assert_int(rules).is_equal(2)
	assert_bool(run.notice.is_saying(&"items")).is_true()
	assert_str(run.notice.said()).contains("Drive over a box")
	Events.item_picked.emit(0, &"ricochet_cannon")
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson._take_ricochet.done).is_true()
	# The first item picked up brings the slot in, pointed at until the item has done its piece.
	assert_bool(run.reveal.is_pointing()).is_true()
	assert_str(run.reveal.line()).contains("Your item")
	assert_object(lesson.current()).is_same(lesson._arm)
	Events.item_used.emit(0, &"ricochet_cannon")
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson._arm.done).is_true()
	assert_bool(run.notice.is_saying(&"items")).is_false()
	assert_bool(run.reveal.is_pointing()).is_true()
	assert_object(lesson.current()).is_same(lesson._bounce)
	# The cannon's shots all spent before the pocket: the box is back at once, no wait.
	var gone := lesson._boxes[&"ricochet_cannon"] as ItemBox
	gone.queue_free()
	await _runner.simulate_frames(2, 17)
	var back := lesson._boxes[&"ricochet_cannon"] as ItemBox
	assert_bool(is_instance_valid(back) and back.is_inside_tree()).is_true()
	assert_object(back).is_not_same(gone)
	var pocket := lesson.target_at(TutorialItems.POCKET)
	assert_object(pocket).is_not_null()
	pocket.hit_after_bounce = false
	pocket.struck.emit(pocket, 0)
	assert_bool(lesson._bounce.done).is_false()
	pocket.hit_after_bounce = true
	pocket.struck.emit(pocket, 0)
	assert_bool(lesson._bounce.done).is_true()
	await _runner.simulate_frames(1, 17)
	assert_bool(run.reveal.is_pointing()).is_false()
	# The Shield: picked up, raised, and popped by the guard, the arrow on the guard with no ring.
	Events.item_picked.emit(0, &"shield")
	assert_bool(lesson._take_shield.done).is_true()
	assert_bool(lesson._pop.done).is_false()
	assert_bool(lesson._pop.ringed).is_false()
	assert_vector(lesson._pop.arrow).is_equal(TutorialItems.GUARD)
	Events.shield_popped.emit(0)
	assert_bool(lesson._pop.done).is_true()
	# The guard stands, part of the room, and shoots no more.
	assert_bool(lesson._guard.alive).is_true()
	assert_float(lesson._guard.reach).is_equal(0.0)
	# The row: a shot of the player's own counts for nothing, a turret's does.
	Events.item_picked.emit(0, &"turret")
	for cell: Vector2i in TutorialItems.ROW:
		var target := lesson.target_at(cell)
		target.hit_by_turret = false
		target.struck.emit(target, 0)
	assert_int(lesson._clear.count).is_equal(0)
	# One of the count ticks nothing on the list; only the count complete does.
	var first := lesson.target_at(TutorialItems.ROW[0])
	first.hit_by_turret = true
	first.struck.emit(first, 0)
	await _runner.simulate_frames(1, 17)
	assert_int(lesson._clear.count).is_equal(1)
	var clear_row: Dictionary = run.list.task_rows(lesson)[6]
	assert_bool((clear_row["mark"] as TutorialList.Mark).done).is_false()
	for cell: Vector2i in TutorialItems.ROW.slice(1):
		var target := lesson.target_at(cell)
		target.hit_by_turret = true
		target.struck.emit(target, 0)
	await _runner.simulate_frames(2, 17)
	assert_bool(lesson.is_done()).is_true()
	assert_bool(arena.gate_at(lesson.gate_cell).is_open).is_true()


## A turret shoots the gallery's targets when no kart is in reach: one told to, or any turret
## while the tutorial runs, which is how a dropped one clears the row.
func test_a_turret_can_shoot_targets() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(6)
	await _runner.simulate_frames(2, 17)
	assert_bool(Turret.hunts_targets).is_true()
	var target := (run.current_lesson() as TutorialItems).target_at(TutorialItems.ROW[1])
	var turret := Turret.new()
	turret.owner_slot = 0
	turret.bullet_system = tutorial.match_node.bullets
	tutorial.match_node.add_child(turret)
	turret.global_position = run.cell(TutorialItems.ROW[1] + Vector2i(3, 0))
	_put(tutorial, Vector2i(23, 11), Vector3(-1.0, 0.0, 0.0))
	var struck := false
	for i: int in 240:
		await _runner.simulate_frames(1, 17)
		if not target.alive:
			struck = true
			break
	turret.queue_free()
	assert_bool(struck).override_failure_message("the turret never shot the target").is_true()
	assert_bool(target.hit_by_turret).is_true()
	tutorial.queue_free()
	await await_idle_frame()
	assert_bool(Turret.hunts_targets).is_false()


## Jokers, in any order: the parked karts go down to one hit and drop their cards, the hand is
## read, and two deaths in the pit each bring the joker pick, for four cards in all.
func test_jokers_from_parked_karts_and_the_pit() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(7)
	var lesson := run.current_lesson() as TutorialJokers
	var kart := run.kart()
	var arena := tutorial.match_node.arena
	await _runner.simulate_frames(2, 17)
	assert_bool(tutorial.match_node.rules.offer_jokers).is_true()
	assert_bool(tutorial.match_node.rules.bounties).is_false()
	assert_str(run.notice.said()).contains("A killed kart may drop a joker")
	assert_bool(lesson._signs.is_empty()).is_true()
	assert_str(lesson._read.hint).is_equal("")
	assert_str(lesson._pit.hint).is_equal("")
	assert_str(lesson._pick_up.hint).is_equal("")
	assert_bool(lesson.ordered).is_false()
	assert_int(run.list.task_rows(lesson).size()).is_equal(4)
	assert_object(lesson.tasks[3]).is_same(lesson._read)
	# No hand yet, and nothing pointing at one: the lives alone came in.
	assert_bool(tutorial.match_node.hud.hand_of(0).visible).is_false()
	assert_bool(run.reveal.is_pointing()).is_false()
	assert_int(run.dummies.size()).is_equal(TutorialJokers.DUMMIES)
	for i: int in run.dummies.size():
		var dummy := run.dummies[i].kart
		assert_int(dummy.lives).is_equal(1)
		var spot := run.cell(TutorialJokers.DUMMY_SPOTS[i])
		assert_float(dummy.global_position.distance_to(spot)).is_less(0.5)
	# Nearer the second parked kart, the arrow is on it; with it down, on the other.
	_put(tutorial, TutorialJokers.DUMMY_SPOTS[1] + Vector2i(0, -3), Vector3(0.0, 0.0, 1.0))
	await _runner.simulate_frames(1, 17)
	assert_vector(lesson._shoot.arrow).is_equal(TutorialJokers.DUMMY_SPOTS[1])
	run.dummies[1].kart.die(&"bullet", 0)
	await _runner.simulate_frames(1, 17)
	assert_vector(lesson._shoot.arrow).is_equal(TutorialJokers.DUMMY_SPOTS[0])
	run.dummies[0].kart.die(&"bullet", 0)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson._shoot.done).is_true()
	var cards: Array[FloorJoker] = []
	for pickup: Node in arena.pickups.get_children():
		if pickup is FloorJoker:
			cards.append(pickup)
	assert_int(cards.size()).is_equal(2)
	for card: FloorJoker in cards:
		kart.jokers.add(card.joker)
		Events.joker_taken.emit(0, card.joker.id)
		card.queue_free()
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson._pick_up.done).is_true()
	# The hand came in with the cards, but is pointed at only once the rest is done.
	assert_bool(tutorial.match_node.hud.hand_of(0).visible).is_true()
	assert_bool(run.reveal.is_pointing()).is_false()
	# Reading the hand is every card under the cursor once: half the bar for one of two. The
	# pit's two deaths come first here, so the pointer at the hand is up by now.
	assert_bool(lesson._read.done).is_false()
	var hand := tutorial.match_node.hud.hand_of(0)
	kart.menu_open = true
	kart.menu_index = 0
	lesson.step(DT)
	assert_float(lesson._read.progress).is_equal_approx(0.5, 0.01)
	# The card still to read wears an eye; the one read does not.
	assert_int(hand.unread.size()).is_equal(1)
	await _runner.simulate_frames(1, 17)
	var eyes := 0
	for card: Node in hand.get_children():
		var eye := card.get_node_or_null("Unread") as Control
		eyes += 1 if eye != null and eye.visible else 0
	assert_int(eyes).is_equal(1)
	# The pointer at the hand steps aside while the hand is open.
	assert_bool(run.reveal._pointer.visible).is_false()
	# The kart's own tick shut the hand again meanwhile: open it on the second card.
	kart.menu_open = true
	kart.menu_index = 0
	lesson.step(DT)
	assert_float(lesson._read.progress).is_equal_approx(0.5, 0.01)
	kart.menu_index = 1
	lesson.step(DT)
	assert_bool(lesson._read.done).override_failure_message("the hand was never read").is_true()
	assert_bool(hand.unread.is_empty()).is_true()
	kart.menu_open = false
	var slot := run.slot()
	for death: int in 2:
		kart.die(&"pit", -1)
		# A fresh pick, open: the last one is cleared as the kart comes back.
		for i: int in 60:
			await _runner.simulate_frames(1, 17)
			if slot.offer != null and not slot.offer.is_done():
				break
		(
			assert_object(slot.offer)
			. override_failure_message("no pick on death %d" % death)
			. is_not_null()
		)
		(
			assert_bool(slot.offer.is_done())
			. override_failure_message("death %d: the pick was already answered" % death)
			. is_false()
		)
		# A card not held yet, since a copy of one held stacks on it and adds no card to the hand,
		# or else whichever card the hand can take: a copy at its stack's cap it cannot.
		var pick := -1
		for i: int in slot.offer.choices.size():
			var choice: Joker = slot.offer.choices[i]
			if kart.jokers.can_take(choice) and not kart.jokers.has(choice.id):
				pick = i
				break
		if pick < 0:
			for i: int in slot.offer.choices.size():
				if kart.jokers.can_take(slot.offer.choices[i]):
					pick = i
					break
		slot.offer.take(maxi(pick, 0))
		assert_bool(slot.offer.is_done()).override_failure_message("death %d" % death).is_true()
		for i: int in 200:
			await _runner.simulate_frames(1, 17)
			if kart.alive:
				break
		assert_bool(kart.alive).is_true()
		await _runner.simulate_frames(3, 17)
		assert_float(kart.global_position.distance_to(run.cell(lesson.spawn_cell))).is_less(0.5)
		assert_int(kart.jokers.count()).is_equal(TutorialJokers.DUMMIES + death + 1)
	await _runner.simulate_frames(2, 17)
	assert_int(kart.jokers.count()).is_equal(TutorialJokers.WANTED)
	assert_bool(lesson.is_done()).is_true()
	assert_bool(run.reveal.is_pointing()).is_false()
	# Long past the respawn delay by now, the parked karts are still down.
	for slot_dummy: PlayerSlot in run.dummies:
		assert_bool(slot_dummy.kart.alive).is_false()


## Pads: the last room starts bare, its pads and Jackpots growing out of the floor with the
## lesson; the flush is every pad of the room, and the Jackpot starts full to be drained.
func test_pads_flush_their_own_room_and_drain_the_jackpot() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var match_node := tutorial.match_node
	var arena := match_node.arena
	var kart := run.kart()
	# Held back until the lesson: unseen, and not driven onto.
	assert_int(arena.flush_pads.size()).is_equal(4)
	for pad: FlushPad in arena.flush_pads:
		assert_bool(pad.visible).is_false()
		assert_int(pad.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	for zone: JackpotZone in arena.jackpot_zones:
		assert_bool(zone.visible).is_false()
		assert_bool(zone.active).is_false()
	for pad: JunctionPad in arena.junctions:
		assert_bool(pad.visible).is_false()
	run._start(8)
	var lesson := run.current_lesson() as TutorialPads
	await _runner.simulate_frames(2, 17)
	# The flush pads first, the Jackpots still held back, and the word about the pads.
	for pad: FlushPad in arena.flush_pads:
		assert_bool(pad.visible).is_true()
		assert_int(pad.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	for zone: JackpotZone in arena.jackpot_zones:
		assert_bool(zone.visible).is_false()
	for pad: JunctionPad in arena.junctions:
		assert_bool(pad.visible).is_false()
	assert_bool(lesson._signs.is_empty()).is_true()
	assert_str(run.notice.said()).contains("Royal Flush pads pay out coins")
	assert_str(lesson._flush.hint).is_equal("")
	for pad: CoinPad in arena.coin_pads:
		assert_bool(pad.visible).is_false()
	var room := arena.grid.region_of(TutorialPads.SPAWN)
	# The arrow is on the nearest pad not yet the player's: with three claimed, on the fourth.
	for pad: FlushPad in arena.flush_pads.slice(0, 3):
		pad.claim(kart.slot, run.slot().color())
	await _runner.simulate_frames(1, 17)
	var fourth := arena.grid.cell_of(arena.flush_pads[3].global_position)
	assert_vector(lesson._flush.arrow).is_equal(fourth)
	for pad: FlushPad in arena.flush_pads:
		assert_int(pad.group).is_equal(room)
		pad.claim(kart.slot, run.slot().color())
	assert_bool(lesson._flush.done).is_false()
	arena.flush_pads[3].claimed.emit(arena.flush_pads[3], kart)
	assert_bool(lesson._flush.done).override_failure_message("no flush").is_true()
	# The flush brings the Jackpots up, one of them full, and the word is about them; the ring
	# goes round the whole of the full one, two cells across.
	await _runner.simulate_frames(1, 17)
	for zone: JackpotZone in arena.jackpot_zones:
		assert_bool(zone.visible).is_true()
	assert_bool(lesson._zone.active).is_true()
	assert_float(lesson._zone.chips).is_equal(float(lesson._zone.cap()))
	assert_str(run.notice.said()).contains("Stand on a Jackpot")
	assert_object(lesson.current()).is_same(lesson._drain)
	assert_bool(run.arrow._ring.visible).is_true()
	assert_float(run.arrow.ring_radius).is_greater(arena.grid.cell_size)
	var ring_at := run.arrow.target
	var zone_at := arena.grid.rect_center(TutorialPads.JACKPOT_RECT)
	assert_float(ring_at.distance_to(zone_at)).is_less(0.1)
	# Drained, the dice come out, the word is about mult and the pointer is on the mult pill.
	Events.jackpot_emptied.emit(lesson._zone.index)
	await _runner.simulate_frames(1, 17)
	assert_object(lesson.current()).is_same(lesson._mult)
	var dice := 0
	for pickup: Node in arena.pickups.get_children():
		dice += 1 if pickup is MultDie else 0
	assert_int(dice).is_equal(TutorialPads.DICE_AT.size())
	assert_str(run.notice.said()).contains("Mult multiplies your pot")
	assert_str(lesson._mult.hint).is_equal("")
	assert_str(lesson._drain.hint).is_equal("")
	assert_bool(run.reveal.is_pointing()).is_true()
	assert_str(run.reveal.line()).contains("Mult will multiply your pot")
	assert_str(lesson.reveals[0][1]).is_equal("Collected coins go to your pot")
	assert_vector(lesson._mult.arrow).is_not_equal(Vector2i(-1, -1))
	for i: int in TutorialPads.DICE:
		Events.mult_gained.emit(0, 1.0, &"die")
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_done()).is_true()
	# No gate: the Junction's lesson starts in the same room, its word up and the pads' gone.
	assert_int(run.index).is_equal(9)
	assert_str(run.notice.said()).contains("Only banked points are safe.")


## The tally over the top counts the pads of the room the player is in, GAME.md 3.9: the last
## room's four from inside it, and none from a room without any.
func test_the_flush_tally_counts_the_room_the_player_is_in() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var tally: FlushTally = tutorial.match_node.hud.find_child("FlushTally", true, false)
	assert_object(tally).is_not_null()
	_put(tutorial, TutorialPads.SPAWN, Vector3(0.0, 0.0, -1.0))
	assert_int(tally._pads_here().size()).is_equal(4)
	_put(tutorial, TutorialJokers.PIT + Vector2i(0, -3), Vector3(0.0, 0.0, -1.0))
	assert_int(tally._pads_here().size()).is_equal(0)
	assert_int(run.index).is_equal(0)


## The Junction grows out of the floor with its lesson, wired to bank: the pot filled, then the
## whole of it banked, an empty pot sent back to the Jackpot, and the fight starts in the same room.
func test_the_junction_banks_the_whole_pot() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var arena := tutorial.match_node.arena
	run._start(9)
	var lesson := run.current_lesson() as TutorialBank
	var kart := run.kart()
	await _runner.simulate_frames(2, 17)
	assert_int(arena.junctions.size()).is_equal(1)
	assert_bool(arena.junctions[0].visible).is_true()
	assert_object(arena.junctions[0].rules).is_same(tutorial.match_node.rules)
	# The pointer is about the pot and the bank both: a frame and a card for each.
	assert_bool(run.reveal.is_pointing()).is_true()
	assert_str(run.reveal.line()).contains("Bank: safe")
	var locks := 0
	for part: Node in run.reveal._line.get_children():
		locks += 1 if part is HudReveal.Lock else 0
	assert_int(locks).is_equal(1)
	assert_bool(run.reveal._also_frame.visible).is_true()
	assert_bool(run.reveal._frame.visible).is_true()
	assert_bool(run.reveal._also_pointer.visible).is_true()
	assert_bool(kart.banks_passively).is_true()
	assert_str(lesson._bank.hint).is_equal("")
	assert_object(lesson.pointer_until).is_same(lesson._bank)
	assert_str(lesson._fill.hint).is_equal("")
	(
		assert_bool(arena.junctions[0].bank_tick.is_connected(tutorial.match_node._on_bank_tick))
		. is_true()
	)
	assert_bool(lesson._fill.done).is_false()
	kart.pot.add_coins(TutorialBank.POT)
	await _runner.simulate_frames(2, 17)
	assert_bool(lesson._fill.done).is_true()
	assert_str(lesson._bank.hint).is_equal(TutorialBank.BANK)
	# Half of it banked is half the bar; a pot emptied otherwise is a trip back to the Jackpot.
	kart.pot.coins = TutorialBank.POT / 2
	await _runner.simulate_frames(1, 17)
	assert_float(lesson._bank.progress).is_equal_approx(0.5, 0.01)
	kart.pot.reset()
	await _runner.simulate_frames(1, 17)
	assert_str(lesson._bank.hint).is_equal(TutorialBank.EMPTY)
	assert_vector(lesson._bank.arrow).is_equal(TutorialBank.JACKPOT)
	kart.pot.add_coins(TutorialBank.POT)
	await _runner.simulate_frames(1, 17)
	assert_str(lesson._bank.hint).is_equal(TutorialBank.BANK)
	assert_bool(lesson.is_done()).is_false()
	# A cash-out of nothing, which a kart parked on the Junction says every tick, is not it.
	Events.bank_completed.emit(0, 0, 1.0, 0)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_done()).is_false()
	Events.bank_completed.emit(0, TutorialBank.POT, 1.0, TutorialBank.POT)
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_done()).is_true()
	assert_int(run.index).is_equal(10)
	# The fight's own "bank your whole pot" is not ticked by that same empty cash-out.
	var fight := run.current_lesson() as TutorialFight
	await _runner.simulate_frames(1, 17)
	Events.bank_completed.emit(0, 0, 1.0, 0)
	assert_bool(fight._cash.done).is_false()


## The final exam: the item pads and the crates come in with it, the bots come out of their pens
## one at a time as the player banks, each pen's own gate opening, the last of them normal, and
## 1000 banked is the end: remembered, the bots gone in a poof with their bullets and turrets, and
## a moment later the license up over the room, numbered once, with the endorsements earned on
## their own lit, the stamp to press, and the ways on once it is.
func test_the_fight_lets_the_bots_out_in_turn_and_ends_the_tutorial() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var arena := tutorial.match_node.arena
	assert_int(run.bots.size()).is_equal(TutorialFight.BOTS)
	for slot: PlayerSlot in run.bots:
		assert_bool(slot.kart.frozen).is_true()
	for pad: PowerUpPad in arena.power_pads:
		assert_bool(pad.visible).is_false()
		assert_object(pad.current).is_null()
	run._start(10)
	var lesson := run.current_lesson() as TutorialFight
	await _runner.simulate_frames(2, 17)
	for pad: PowerUpPad in arena.power_pads:
		assert_bool(pad.visible).is_true()
	for pad: CoinPad in arena.coin_pads:
		assert_bool(pad.visible).is_true()
	var chips := 0
	for pickup: Node in arena.pickups.get_children():
		chips += 1 if pickup is Chip else 0
	assert_int(chips).is_greater_equal(TutorialFight.CHIPS_AT.size() * TutorialFight.CHIPS_EACH)
	assert_str(lesson._bank.hint).is_equal("")
	# The goal, then the hints under a rule, all of them listed from the start.
	assert_int(run.list.task_rows(lesson).size()).is_equal(lesson.tasks.size())
	assert_int(lesson.tasks.size()).is_equal(8)
	assert_object(lesson.current()).is_same(lesson._bank)
	assert_int(tutorial.match_node.win_at).is_equal(run.slot().banked + TutorialFight.NEED)
	assert_str(lesson._flush.text).is_equal("Claim a Royal Flush")
	Events.item_used.emit(0, &"shield")
	assert_bool(lesson._use.done).is_true()
	Events.kart_killed.emit(run.bots[0].index, 0, &"bullet")
	assert_bool(lesson._kill.done).is_true()
	assert_bool(lesson._flush.done).is_false()
	assert_int(lesson.released()).is_equal(1)
	assert_bool(run.bots[0].kart.frozen).is_false()
	assert_bool(run.bots[1].kart.frozen).is_true()
	assert_bool(arena.gate_at(TutorialFight.PEN_GATES[0]).is_open).is_true()
	assert_bool(arena.gate_at(TutorialFight.PEN_GATES[1]).is_open).is_false()
	assert_object(tutorial.layer.get_node_or_null("BossBar")).is_not_null()
	assert_str(lesson._bar._title.text).contains("MORE")
	var tally: FlushTally = tutorial.match_node.hud.find_child("FlushTally", true, false)
	assert_float(tally.offset_top).is_greater(MatchHud.TALLY_DROP)
	# The fight is not skipped, and the pause menu's Skip lesson is gone from here on.
	assert_bool(lesson.skippable).is_false()
	run.skip()
	await _runner.simulate_frames(1, 17)
	assert_bool(lesson.is_done()).is_false()
	assert_bool(tutorial._skip_entry.visible).is_false()
	Events.bank_tick.emit(0, TutorialFight.RELEASE_AT[1])
	await _runner.simulate_frames(1, 17)
	assert_int(lesson.released()).is_equal(2)
	assert_bool(arena.gate_at(TutorialFight.PEN_GATES[1]).is_open).is_true()
	Events.bank_tick.emit(0, TutorialFight.RELEASE_AT[2] - TutorialFight.RELEASE_AT[1])
	await _runner.simulate_frames(1, 17)
	assert_int(lesson.released()).is_equal(3)
	var brain := run.bots[2].kart.get_node("Brain") as BotBrain
	assert_object(brain.difficulty).is_same(TutorialFight.NORMAL)
	assert_bool(run.penned.is_empty()).is_true()
	# A bot's turret and a bot's bullet on the floor, and the player's own bullet.
	var bot := run.bots[0]
	var turret := Turret.new()
	turret.owner_slot = bot.index
	turret.bullet_system = tutorial.match_node.bullets
	tutorial.match_node.add_child(turret)
	turret.global_position = run.cell(Vector2i(30, 44))
	var bullets := tutorial.match_node.bullets
	var stats: CannonStats = load("res://data/cannons/default.tres")
	bullets.spawn(bot.index, run.cell(Vector2i(40, 44)), Vector3(1.0, 0.0, 0.0), stats, Color.RED)
	bullets.spawn(0, run.cell(Vector2i(40, 50)), Vector3(1.0, 0.0, 0.0), stats, Color.WHITE)
	Game.settings.tutorial_done = false
	Game.settings.license_number = ""
	Game.settings.license_date = ""
	Game.settings.license_plate = ""
	Events.bank_tick.emit(0, TutorialFight.NEED - TutorialFight.RELEASE_AT[2])
	await _runner.simulate_frames(2, 17)
	assert_bool(run.is_over()).is_true()
	# The goal takes the hints with it, and the arrow has nothing left to point at.
	for task: TutorialTask in lesson.tasks:
		assert_bool(task.done).is_true()
	await _runner.simulate_frames(1, 17)
	assert_bool(run.arrow.target.is_finite()).is_false()
	assert_int(tutorial.match_node.win_at).is_equal(0)
	assert_bool(Game.settings.tutorial_done).is_true()
	# The license is numbered once, for good, and dated today.
	var number := Game.settings.license_number
	assert_bool(number.begins_with("JJ-")).is_true()
	assert_int(number.length()).is_equal(9)
	assert_str(Game.settings.license_date).is_equal(Time.get_date_string_from_system())
	# And the holder, what they earned on their own, and a plate to start from.
	assert_str(Game.settings.license_holder).is_equal(run.slot().display_name())
	assert_bool("KO" in Game.settings.license_endorsements).is_true()
	assert_bool("ROYAL FLUSH" in Game.settings.license_endorsements).is_false()
	assert_str(Game.settings.license_plate).is_equal(
		LicensePlate.suggest(run.slot().display_name(), number)
	)
	assert_object(tutorial.license).is_null()
	assert_object(tutorial.layer.get_node_or_null("License")).is_null()
	# The bots dead and gone with everything of theirs, the player's own shot still flying, and
	# fireworks over the room.
	for slot_bot: PlayerSlot in run.bots:
		assert_bool(slot_bot.kart.alive).is_false()
		assert_bool(slot_bot.kart.visible).is_false()
		assert_int(slot_bot.kart.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
		assert_bool(slot_bot in run.gone).is_true()
	assert_object(tutorial.match_node.find_child("Fireworks", true, false)).is_not_null()
	assert_bool(not is_instance_valid(turret) or not turret.alive).is_true()
	var flying := 0
	for bullet: Bullet in bullets.bullets:
		assert_int(bullet.owner_slot).is_equal(0)
		flying += 1
	assert_int(flying).is_equal(1)
	# A moment after the bang, the license: the kart held, the checklist and the menu gone.
	await await_millis(int(Tutorial.LICENSE_AFTER * 1000.0) + 400)
	await _runner.simulate_frames(2, 17)
	var license := tutorial.license
	assert_object(license).is_not_null()
	assert_object(tutorial.layer.get_node_or_null("License")).is_same(license)
	assert_bool(run.kart().frozen).is_true()
	assert_bool(run.list.visible).is_false()
	assert_object(tutorial.menu).is_null()
	assert_str(license.card.number).is_equal(number)
	assert_str(license.card.holder_name).is_equal(run.slot().display_name())
	# The endorsements: the kill and the item on their own, the rest ticked by the goal.
	var earned := license.card.endorsements
	assert_int(earned.size()).is_equal(TutorialFight.ENDORSEMENTS.size())
	assert_bool(earned["KO"]).is_true()
	assert_bool(earned["ITEMS"]).is_true()
	assert_bool(earned["ROYAL FLUSH"]).is_false()
	assert_bool(earned["FULL HAND"]).is_false()
	# Nothing on until the stamp comes down; stamped, the card wears it and the ways on come up.
	assert_bool(license.offering()).is_false()
	assert_bool(license.card.stamped).is_false()
	var went: Array[StringName] = []
	for way: StringName in license.ways:
		license.ways[way] = func() -> void: went.append(way)
	license.stamp.pressed.emit()
	assert_bool(license.stamp.has_slammed()).is_true()
	await await_millis(int((RubberStamp.LIFT + RubberStamp.DROP) * 1000.0) + 150)
	assert_bool(license.card.stamped).is_true()
	await await_millis(int(LicenseScreen.SETTLE * 1000.0) + 200)
	assert_bool(license.offering()).is_true()
	# The plate to choose, under the congratulations, kept as it is typed.
	assert_object(license.plate_field).is_not_null()
	license.plate_field.text = "go fast!"
	license.plate_field.text_changed.emit(license.plate_field.text)
	assert_str(Game.settings.license_plate).is_equal("GO FAST")
	assert_str(license.plate.text).is_equal("GO FAST")
	license.buttons[&"play"].pressed.emit()
	assert_array(went).contains_exactly([&"play"])
	# Done again, the license keeps its number.
	tutorial._on_finished()
	assert_str(Game.settings.license_number).is_equal(number)


## The item slot is in the corner once the items lesson is over, however it went, and the hand
## once the jokers lesson is: skipped, neither was ever pointed at.
func test_the_pieces_a_lesson_is_about_stay_once_it_is_over() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(6)
	await _runner.simulate_frames(1, 17)
	assert_bool(run.reveal.shown[&"item"]).is_false()
	run.skip()
	await _runner.simulate_frames(1, 17)
	assert_bool(run.reveal.shown[&"item"]).is_true()
	assert_bool(run.reveal.shown[&"hand"]).is_false()
	# The learner blocks about the rooms are boxes: a kart bumps them, a shot breaks them.
	var props := tutorial.match_node.arena.get_node("SchoolProps")
	var blocks := props.find_children("LearnerBlock*", "", false, false)
	assert_int(blocks.size()).is_equal(SchoolProps.BLOCKS.size())
	for block: Node in blocks:
		assert_bool(block is Crate).is_true()
		assert_int((block as Crate).collision_layer).is_equal(Layers.WORLD)
	(blocks[0] as Crate).hit(0)
	assert_bool((blocks[0] as Crate).alive).is_false()
	# And the kart wears the learner's L for the test.
	var plate := run.kart().get_node_or_null("Body/Plate")
	assert_object(plate).is_not_null()
	assert_str(plate.get_meta(&"plate")).is_equal("L")


## A joker pick with the hand already full gets the word at the top for as long as it is open,
## and a card replaced says REPLACED on its way out, the way a card lost says LOST.
func test_a_full_hand_is_explained_and_a_replaced_card_says_so() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	run._start(7)
	var kart := run.kart()
	var slot := run.slot()
	await _runner.simulate_frames(2, 17)
	for joker: Joker in tutorial.match_node.joker_catalog.jokers:
		if kart.jokers.is_full():
			break
		if not kart.jokers.has(joker.id):
			kart.jokers.add(joker)
	assert_bool(kart.jokers.is_full()).is_true()
	assert_bool(run.notice.is_saying(&"hand_full")).is_false()
	# A full hand takes no card off the floor, so the picking up is as good as done.
	await _runner.simulate_frames(1, 17)
	assert_bool((run.current_lesson() as TutorialJokers)._pick_up.done).is_true()
	kart.die(&"pit", -1)
	for i: int in 60:
		await _runner.simulate_frames(1, 17)
		if slot.offer != null and not slot.offer.is_done():
			break
	assert_object(slot.offer).is_not_null()
	await _runner.simulate_frames(1, 17)
	assert_bool(run.notice.is_saying(&"hand_full")).is_true()
	assert_str(run.notice.said()).contains("Your hand is full")
	var said: Array[String] = []
	var heard := func(_slot: int, _joker: StringName, word: String) -> void: said.append(word)
	Events.joker_used_up.connect(heard)
	slot.offer.take(0)
	slot.offer.replace(0)
	Events.joker_used_up.disconnect(heard)
	assert_array(said).is_equal(["REPLACED"] as Array[String])
	assert_bool(slot.offer.is_done()).is_true()
	await _runner.simulate_frames(1, 17)
	assert_bool(run.notice.is_saying(&"hand_full")).is_false()


## The fight's match point is the thousand on top of the bank as the fight began, with the pot
## counted in and never with an empty pot: banked for real at the Junction, so the bank stands
## where the HUD says when the fight takes its baseline.
func test_the_fight_counts_its_match_point_from_the_bank_at_its_start() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var match_node := tutorial.match_node
	var kart := run.kart()
	var slot := run.slot()
	run._start(9)
	await _runner.simulate_frames(2, 17)
	# A pot banked for real, on the Junction, the lesson's own way out.
	kart.pot.add_coins(TutorialBank.POT)
	_put(tutorial, TutorialBank.JUNCTION, Vector3(1.0, 0.0, 0.0))
	for i: int in 900:
		await _runner.simulate_frames(1, 17)
		if run.index == 10:
			break
	assert_int(run.index).override_failure_message("the pot was never banked").is_equal(10)
	var fight := run.current_lesson() as TutorialFight
	assert_int(slot.banked).is_greater(0)
	assert_int(fight.bank_at_start()).is_equal(slot.banked)
	assert_int(match_node.win_at).is_equal(slot.banked + TutorialFight.NEED)
	# No match point on an empty pot, nor on a pot short of the thousand; one that would reach
	# it, yes; and a bank that has reached it still wants a coin in the pot.
	_put(tutorial, TutorialPads.SPAWN, Vector3(0.0, 0.0, -1.0))
	await _runner.simulate_frames(2, 17)
	# Emptied by hand: the fight opens with chips over the floor, and one may have rolled in.
	kart.pot.reset()
	assert_bool(match_node.would_win(slot)).is_false()
	kart.pot.add_coins(TutorialFight.NEED - 1)
	assert_bool(match_node.would_win(slot)).is_false()
	kart.pot.add_coins(1)
	assert_bool(match_node.would_win(slot)).is_true()
	kart.pot.reset()
	slot.banked += TutorialFight.NEED
	assert_bool(match_node.would_win(slot)).is_false()


## A gate never shuts on anybody: told to shut with a kart in it, it waits until the kart is out.
func test_a_gate_waits_to_shut_until_nobody_is_in_it() -> void:
	var tutorial := await _start()
	var run := tutorial.run
	var lesson := run.current_lesson()
	var gate := tutorial.match_node.arena.gate_at(lesson.gate_cell)
	run.open_gate(lesson.gate_cell)
	await _runner.simulate_frames(1, 17)
	assert_bool(gate.is_open).is_true()
	_put(tutorial, lesson.gate_cell + Vector2i(1, 0), Vector3(0.0, 0.0, -1.0))
	run.close_gate(lesson.gate_cell)
	await _runner.simulate_frames(3, 17)
	assert_bool(gate.is_open).is_true()
	_put(tutorial, lesson.spawn_cell, Vector3(0.0, 0.0, -1.0))
	await _runner.simulate_frames(2, 17)
	assert_bool(gate.is_open).is_false()


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
	assert_str(pane.said()).contains("No license yet")
	assert_int(went[0]).is_equal(0)
	pane.no_button().pressed.emit()
	assert_int(went[0]).is_equal(1)
	await await_idle_frame()
	assert_object(title.find_child("LicenseOffer", true, false)).is_null()
	# Asked again the next time.
	title.offer_license(func() -> void: went[0] += 1)
	assert_object(title.find_child("LicenseOffer", true, false)).is_not_null()
	assert_int(went[0]).is_equal(1)
	(title.find_child("LicenseOffer", true, false) as ConfirmPane).no_button().pressed.emit()
	await await_idle_frame()
	# With a license, straight on.
	Game.settings.license_number = "JJ-224123"
	title.offer_license(func() -> void: went[0] += 1)
	assert_int(went[0]).is_equal(3)
	assert_object(title.find_child("LicenseOffer", true, false)).is_null()
