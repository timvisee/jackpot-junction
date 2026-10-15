extends GdUnitTestSuite
## The joker system from GAME.md 3.7 and the jokers from 7.3, in a running match.

const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


## Offers are off by default so deaths do not hand out random jokers; offer tests turn them on.
func _start_match(
	inputs: Array[KartInput], offer_size: int = 0, seed: int = 21, with_hud: bool = false
) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	rules.respawn_delay = 0.2
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = with_hud
	match_node.offer_size = offer_size
	_runner = scene_runner(match_node)
	match_node.start(inputs, seed)
	return match_node


func _bots() -> Array[KartInput]:
	return [KartInput.new(), KartInput.new()]


func _attach(kart: Kart, id: String) -> Joker:
	return kart.jokers.add(load("res://data/jokers/%s.tres" % id))


func _chip(dropped := false, gold := false) -> Chip:
	var chip := Chip.new()
	chip.dropped = dropped
	chip.gold = gold
	chip.value = 5 if gold else 1
	return auto_free(chip)


func test_catalog_has_unique_jokers_and_offers_exclude_held_ones() -> void:
	var catalog: JokerCatalog = CATALOG
	assert_int(catalog.jokers.size()).is_equal(47)
	var ids: Array[StringName] = []
	for joker: Joker in catalog.jokers:
		(
			assert_bool(joker.id in ids)
			. override_failure_message("duplicate id %s" % joker.id)
			. is_false()
		)
		ids.append(joker.id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var exclude: Array[StringName] = [&"hair_trigger", &"big_tank"]
	var offered := catalog.offer(rng, 3, exclude)
	assert_int(offered.size()).is_equal(3)
	for joker: Joker in offered:
		assert_bool(joker.id in exclude).is_false()
	assert_bool(offered[0] == offered[1] or offered[1] == offered[2]).is_false()


func test_bullets_do_not_bounce_by_default_and_rubber_bumpers_stack_one_bounce_each() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	assert_int(kart.cannon.stats.bounces).is_equal(0)
	var first := _attach(kart, "rubber_bumpers")
	assert_int(kart.cannon.stats.bounces).is_equal(1)
	var catalog: JokerCatalog = CATALOG
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	# The whole pool, so the draw cannot simply miss it as the catalog grows.
	var offered := catalog.offer(rng, catalog.jokers.size(), kart.jokers.ids())
	var again := false
	for joker: Joker in offered:
		again = again or joker.id == &"rubber_bumpers"
	assert_bool(again).override_failure_message("a stackable joker is offered again").is_true()
	_attach(kart, "rubber_bumpers")
	assert_int(kart.cannon.stats.bounces).is_equal(2)
	kart.cannon.cooldown_left = 0.0
	var shots := kart.cannon.fire(
		match_node.bullets, 0, Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Color.WHITE
	)
	assert_int(shots[0].bounces_left).is_equal(2)
	for bullet: Bullet in shots:
		bullet.destroy()
	kart.jokers.remove(first)
	assert_int(kart.cannon.stats.bounces).is_equal(1)


func test_the_hud_deals_the_jokers_as_cards_and_lifts_the_one_picked_in_the_menu() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, 0, 21, true)
	var kart := match_node.kart_of(0)
	_attach(kart, "hair_trigger")
	_attach(kart, "rubber_bumpers")
	await _runner.simulate_frames(12, 17)
	var hand: JokerHand = match_node.hud._hands[0]
	assert_int(hand.card_count()).is_equal(2)
	assert_int(hand.selected()).is_equal(-1)
	assert_bool(hand._detail.visible).is_false()
	Input.action_press(InputActions.JOKER_MENU)
	Input.action_press(InputActions.JOKER_NEXT)
	await _runner.simulate_frames(3, 17)
	Input.action_release(InputActions.JOKER_NEXT)
	await _runner.simulate_frames(30, 17)
	assert_bool(kart.menu_open).is_true()
	assert_int(hand.selected()).is_equal(1)
	assert_float(hand._cards[1].position.y).is_less(hand._cards[0].position.y - 20.0)
	assert_bool(hand._detail.visible).is_true()
	# Name, kind and what it does are told apart rather than run into one paragraph, GAME.md 8.3.
	assert_str(hand._detail._name.text).is_equal("Rubber Bumpers")
	assert_str(hand._detail._kind.text).is_not_empty()
	assert_str(hand._detail._body.text).is_not_empty()
	# The controls under it are drawn buttons with the words between them, GAME.md 8.3.
	var said: PackedStringArray = []
	for child: Node in hand._detail._hints.get_children():
		var word := child as Label
		if word != null:
			said.append(word.text)
	assert_str(" ".join(said)).contains("drop")
	assert_int(hand._detail._hints.get_child_count()).is_greater(3)
	# The kind's color is the foil round the pane's header, torn from its body by a perforation,
	# GAME.md 8.1a.
	var style: TicketStyle = hand._detail.get_theme_stylebox("panel")
	var kind := JokerCard.kind_color(hand._detail._joker)
	assert_object(style.frame).is_equal(Color(kind, JokerDetail.FRAME))
	assert_int(style.perforations.size()).is_equal(1)
	Input.action_release(InputActions.JOKER_MENU)
	await _runner.simulate_frames(3, 17)
	assert_int(hand.selected()).is_equal(-1)
	_attach(kart, "big_tank")
	await _runner.simulate_frames(2, 17)
	assert_int(hand.card_count()).is_equal(3)


func test_steering_walks_the_joker_cursor_one_card_per_push() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, 0, 21, true)
	var kart := match_node.kart_of(0)
	for id: String in ["hair_trigger", "rubber_bumpers", "big_tank"]:
		_attach(kart, id)
	await _runner.simulate_frames(12, 17)
	Input.action_press(InputActions.JOKER_MENU)
	Input.action_press(InputActions.STEER_RIGHT)
	# Held down, not tapped: the cursor moves once and then waits for a fresh push.
	await _runner.simulate_frames(20, 17)
	assert_int(kart.menu_index).is_equal(1)
	Input.action_release(InputActions.STEER_RIGHT)
	Input.action_press(InputActions.STEER_LEFT)
	await _runner.simulate_frames(20, 17)
	assert_int(kart.menu_index).is_equal(0)
	Input.action_release(InputActions.STEER_LEFT)
	Input.action_release(InputActions.JOKER_MENU)
	await _runner.simulate_frames(3, 17)


func test_curve_ball_bends_bullets_hard_and_after_a_bounce() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	var plain := kart.cannon.stats.aim_assist_turn_rate_deg
	assert_bool(kart.cannon.stats.assist_after_bounce).is_false()
	_attach(kart, "curve_ball")
	var curved := kart.cannon.stats
	assert_bool(curved.aim_assist).is_true()
	assert_float(curved.aim_assist_turn_rate_deg).is_greater(plain * 2.0)
	assert_float(curved.aim_assist_cone_deg).is_greater(50.0)
	assert_bool(curved.assist_after_bounce).is_true()
	# A bullet fired 20° wide of an enemy, into the open, curves onto it instead of sailing past.
	var enemy := match_node.kart_of(1)
	enemy.global_position = Vector3(6.0, 0.0, -9.375)
	kart.global_position = Vector3(-6.0, 0.0, -9.375)
	kart.face(Vector3(1.0, 0.0, 0.0))
	await _runner.simulate_frames(2, 17)
	kart.cannon.cooldown_left = 0.0
	var shots := kart.cannon.fire(
		match_node.bullets,
		0,
		kart.global_position + Vector3(1.2, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0).rotated(Vector3.UP, deg_to_rad(-20.0)),
		Color.WHITE
	)
	var bullet: Bullet = shots[0]
	assert_bool(bullet.assist_after_bounce).is_true()
	var start := bullet.global_position.distance_to(enemy.global_position)
	await _runner.simulate_frames(40, 17)
	(
		assert_int(match_node.slots[1].deaths)
		. override_failure_message("the curved bullet missed; it started %.1f m away" % start)
		. is_equal(1)
	)
	assert_int(match_node.slots[0].kills).is_equal(1)


func test_aimbot_turns_the_shot_toward_the_nearest_enemy() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	var enemy := match_node.kart_of(1)
	assert_float(kart.cannon.stats.auto_aim_deg).is_equal(0.0)
	kart.global_position = Vector3(-6.0, 0.0, 4.0)
	kart.face(Vector3(1.0, 0.0, 0.0))
	enemy.global_position = Vector3(0.0, 0.0, 2.0)
	await _runner.simulate_frames(2, 17)
	# Without the joker the shot goes exactly where the kart points.
	var straight := KartAim.steered(kart, Vector3(1.0, 0.0, 0.0))
	assert_vector(straight).is_equal_approx(Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.001)
	_attach(kart, "aimbot")
	assert_float(kart.cannon.stats.auto_aim_deg).is_equal_approx(14.0, 0.001)
	var aimed := KartAim.steered(kart, Vector3(1.0, 0.0, 0.0))
	var toward := (enemy.global_position - kart.global_position).normalized()
	assert_float(rad_to_deg(aimed.angle_to(Vector3(1.0, 0.0, 0.0)))).is_equal_approx(14.0, 0.5)
	assert_float(aimed.angle_to(toward)).is_less(Vector3(1.0, 0.0, 0.0).angle_to(toward))
	# Nothing in range leaves the shot alone. The reach is pulled right in for it, because the
	# boxes on the floor are things a shot may be bent toward now as well, GAME.md 5.1.
	enemy.global_position = Vector3(18.0, 0.0, 18.0)
	kart.cannon.stats.auto_aim_range = 1.0
	await _runner.simulate_frames(2, 17)
	assert_vector(KartAim.steered(kart, Vector3(1.0, 0.0, 0.0))).is_equal_approx(
		Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.001
	)


## GAME.md 3.7: the card about to be thrown away is crossed out, so it can never be read as the
## one being claimed.
func test_the_destroy_step_crosses_the_card_out() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	for id: String in ["hair_trigger", "big_tank", "comeback", "toll_booth", "road_rage"]:
		_attach(kart, id)
	assert_bool(kart.jokers.is_full()).is_true()
	var offer := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, kart.jokers.ids()))
	var picker: JokerPicker = auto_free(JokerPicker.new())
	add_child(picker)
	await await_idle_frame()
	# Choosing one to claim: gold, no cross.
	picker.show_offer(offer, kart)
	assert_int(picker.card_count()).is_equal(3)
	assert_bool(picker._cross.visible).is_false()
	# A full hand turns the same row into a choice of what to throw away.
	offer.take(0)
	assert_int(offer.stage).is_equal(JokerOffer.Stage.REPLACING)
	picker.show_offer(offer, kart)
	assert_int(picker.card_count()).is_equal(JokerHolder.MAX_JOKERS)
	assert_bool(picker._cross.visible).is_true()
	assert_str(picker._title.text).contains("Destroy")
	# The cross sits exactly over the card under the cursor, whatever its scale.
	var doomed := picker._cards[offer.selected]
	assert_vector(picker._cross.position).is_equal(doomed.position)
	assert_vector(picker._cross.scale).is_equal(doomed.scale)
	# Backing out puts the claim colors back.
	offer.cancel_replace()
	picker.show_offer(offer, kart)
	assert_bool(picker._cross.visible).is_false()


## GAME.md 8.3: the card under the cursor rises and grows and does nothing else. It grows about
## its own bottom center, so scaling that offset again slid it left by half of what it had grown
## by, on a row that is otherwise dead straight.
func test_the_picked_card_rises_without_sliding_sideways() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	var offer := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, []))
	var picker: JokerPicker = auto_free(JokerPicker.new())
	add_child(picker)
	await await_idle_frame()
	offer.selected = 0
	picker.show_offer(offer, kart)
	# Where the second card stands while somebody else is picked, settling the scale first.
	for i: int in 20:
		picker.show_offer(offer, kart)
	var card := picker._cards[1]
	var resting := card.position + card.pivot_offset
	offer.selected = 1
	for i: int in 20:
		picker.show_offer(offer, kart)
	var lifted := card.position + card.pivot_offset
	assert_float(lifted.x).is_equal_approx(resting.x, 0.01)
	assert_float(lifted.y).is_less(resting.y - 10.0)
	# And it has grown, which is the thing that used to drag it sideways.
	assert_float(card.scale.x).is_greater(1.0)


## GAME.md 8.3: every joker has a picture of its own, and no picture is left behind for a joker
## that no longer exists. The two lists are written out separately, so this is what keeps them in
## step when a joker is added.
func test_every_joker_has_a_picture_and_every_picture_has_a_joker() -> void:
	var drawn := JokerArt.known()
	var ids: Array[StringName] = []
	for file: String in DirAccess.get_files_at("res://data/jokers/"):
		if file == "catalog.tres" or not file.ends_with(".tres"):
			continue
		var joker: Joker = load("res://data/jokers/" + file)
		ids.append(joker.id)
		(
			assert_bool(drawn.has(joker.id))
			. override_failure_message("%s has no picture" % joker.id)
			. is_true()
		)
	assert_int(ids.size()).is_greater(20)
	for id: StringName in drawn:
		(
			assert_bool(ids.has(id))
			. override_failure_message("there is a picture for %s, which is not a joker" % id)
			. is_true()
		)


## GAME.md 8.3a: and every power-up has one too, held to its list the same way.
func test_every_power_up_has_a_picture_and_every_picture_has_a_power_up() -> void:
	var drawn := PowerUpArt.known()
	var ids: Array[StringName] = []
	for file: String in DirAccess.get_files_at("res://data/powerups/"):
		if file in ["all.tres", "first_set.tres", "later_set.tres"] or not file.ends_with(".tres"):
			continue
		var item: PowerUp = load("res://data/powerups/" + file)
		ids.append(item.id)
		(
			assert_bool(drawn.has(item.id))
			. override_failure_message("%s has no picture" % item.id)
			. is_true()
		)
	assert_int(ids.size()).is_greater(8)
	for id: StringName in drawn:
		(
			assert_bool(ids.has(id))
			. override_failure_message("there is a picture for %s, which is not an item" % id)
			. is_true()
		)


## And the card puts it on: one picture node in the middle of every card, drawn in the kind's
## color, rather than the initials that used to be there.
func test_a_card_carries_its_joker_s_picture() -> void:
	var joker: Joker = load("res://data/jokers/aimbot.tres")
	var card: JokerCard = auto_free(JokerCard.create(joker))
	add_child(card)
	await await_idle_frame()
	var found: JokerArt.Picture = null
	for child: Node in card.find_children("*", "Control", true, false):
		if child is JokerArt.Picture:
			found = child
	assert_object(found).is_not_null()
	assert_str(String(found.id)).is_equal("aimbot")
	assert_object(found.ink).is_equal(JokerCard.kind_color(joker))


## The row is only rebuilt when what it shows changes, not on every frame.
func test_the_picker_keeps_its_cards_between_frames() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	var offer := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, []))
	var picker: JokerPicker = auto_free(JokerPicker.new())
	add_child(picker)
	await await_idle_frame()
	picker.show_offer(offer, kart)
	var first := picker._cards[0]
	picker.show_offer(offer, kart)
	picker.show_offer(offer, kart)
	assert_object(picker._cards[0]).is_same(first)


## GAME.md 4.4: an offer still open at the whistle is dropped. Nobody respawns out of the
## results, so the pick has nothing left to be for and it would sit over the standings unusable.
func test_the_whistle_takes_an_open_joker_pick_off_the_screen() -> void:
	var match_node := _start_match(_bots(), 3)
	# The whistle this is about is the real one, so no sudden death in the way of it.
	match_node.rules.overtime = false
	var kart := match_node.kart_of(0)
	var slot := match_node.slots[0]
	slot.offer = JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, []))
	assert_bool(slot.offer.is_done()).is_false()
	match_node.time_left = 0.0
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_object(slot.offer).is_null()


## GAME.md 8.3: the count beside the hand says how many of the five slots are taken.
func test_the_hand_shows_how_full_it_is() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, 0, 21, true)
	var kart := match_node.kart_of(0)
	await _runner.simulate_frames(12, 17)
	var hand: JokerHand = match_node.hud._hands[0]
	assert_bool(hand._count_label.visible).is_false()
	_attach(kart, "hair_trigger")
	_attach(kart, "big_tank")
	await _runner.simulate_frames(4, 17)
	assert_bool(hand._count_label.visible).is_true()
	assert_str(hand._count_label.text).is_equal("2 / %d" % JokerHolder.MAX_JOKERS)
	assert_object(hand._count_label.get_theme_color("font_color")).is_not_equal(Palette.CHIP_GOLD)
	# A full hand says so in gold, because the next joker costs one of these.
	for id: String in ["comeback", "toll_booth", "road_rage"]:
		_attach(kart, id)
	await _runner.simulate_frames(4, 17)
	assert_str(hand._count_label.text).is_equal(
		"%d / %d" % [JokerHolder.MAX_JOKERS, JokerHolder.MAX_JOKERS]
	)
	assert_object(hand._count_label.get_theme_color("font_color")).is_equal(Palette.CHIP_GOLD)


## GAME.md 8.3: a hand of three or more fans out, and the card picked in the menu straightens.
func test_a_full_hand_fans_out_and_the_picked_card_rises_straight_up() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs, 0, 21, true)
	var kart := match_node.kart_of(0)
	for id: String in ["hair_trigger", "big_tank", "curve_ball", "comeback", "toll_booth"]:
		_attach(kart, id)
	await _runner.simulate_frames(40, 17)
	var hand: JokerHand = match_node.hud._hands[0]
	assert_int(hand.card_count()).is_equal(5)
	var cards := hand._cards
	# The ends tip away from the middle, which itself stays upright and rides highest.
	assert_float(cards[0].rotation).is_less(-0.01)
	assert_float(cards[4].rotation).is_greater(0.01)
	assert_float(absf(cards[2].rotation)).is_less(0.005)
	assert_float(cards[2].position.y).is_less(cards[0].position.y)
	assert_float(cards[2].position.y).is_less(cards[4].position.y)
	# Picking one lifts it and does nothing else: it keeps its tilt and its place along the hand,
	# since the cards turn about their bottom corner and straightening one swings it sideways.
	var tilt := cards[0].rotation
	var along := cards[0].position.x
	Input.action_press(InputActions.JOKER_MENU)
	await _runner.simulate_frames(40, 17)
	Input.action_release(InputActions.JOKER_MENU)
	assert_int(hand.selected()).is_equal(0)
	assert_float(cards[0].rotation).is_equal_approx(tilt, 0.01)
	assert_float(cards[0].position.x).is_equal_approx(along, 0.01)
	assert_float(cards[0].position.y).is_less(cards[2].position.y)


## Presses and releases one action, polling the offer through both, the way a held key would be
## seen by the match over two frames.
func _tap(offer: JokerOffer, action: StringName) -> void:
	Input.action_press(action)
	offer.poll(DeviceInput.ANY)
	Input.action_release(action)
	offer.poll(DeviceInput.ANY)


## GAME.md 3.7: the respawn offer is a row of cards, and steering moves the cursor along it.
func test_the_offer_is_a_row_of_cards_that_steering_walks_along() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	var choices := CATALOG.offer(match_node.rng, 3, [])
	var offer := JokerOffer.new(kart, choices)
	var picker: JokerPicker = auto_free(JokerPicker.new())
	add_child(picker)
	await await_idle_frame()
	picker.show_offer(offer, kart)
	assert_bool(picker.visible).is_true()
	assert_int(picker.card_count()).is_equal(3)
	var cards := picker._cards
	assert_float(cards[0].scale.x).is_greater(cards[1].scale.x)
	assert_str(picker._title.text).is_equal("Pick a joker")
	assert_str(picker._detail._name.text).is_equal(choices[0].display_name)
	# Steering right walks the cursor along, and holding it over does not keep walking.
	_tap(offer, InputActions.STEER_RIGHT)
	assert_int(offer.selected).is_equal(1)
	picker.show_offer(offer, kart)
	await await_idle_frame()
	assert_float(cards[1].scale.x).is_greater(cards[0].scale.x)
	assert_str(picker._detail._name.text).is_equal(choices[1].display_name)
	Input.action_press(InputActions.STEER_RIGHT)
	offer.poll(DeviceInput.ANY)
	offer.poll(DeviceInput.ANY)
	offer.poll(DeviceInput.ANY)
	Input.action_release(InputActions.STEER_RIGHT)
	offer.poll(DeviceInput.ANY)
	assert_int(offer.selected).is_equal(2)
	# Steering left walks back, and the row wraps around its ends.
	_tap(offer, InputActions.STEER_RIGHT)
	assert_int(offer.selected).is_equal(0)
	_tap(offer, InputActions.STEER_LEFT)
	assert_int(offer.selected).is_equal(choices.size() - 1)
	offer.skip()
	picker.show_offer(offer, kart)
	assert_bool(picker.visible).is_false()
	assert_int(picker.card_count()).is_equal(0)


## A remote player's push arrives as an axis, so the picker turns it back into single steps.
func test_a_remote_players_stick_steps_the_cursor_once_per_push() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	var offer := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, []))
	var input := KartInput.new()
	input.cursor = 1.0
	offer.poll_input(input)
	assert_int(offer.selected).is_equal(1)
	offer.poll_input(input)
	assert_int(offer.selected).is_equal(1)
	input.cursor = 0.0
	offer.poll_input(input)
	input.cursor = 1.0
	offer.poll_input(input)
	assert_int(offer.selected).is_equal(2)
	input.cursor = -1.0
	offer.poll_input(input)
	assert_int(offer.selected).is_equal(1)


func test_stat_jokers_rebuild_the_karts_own_stats_and_removal_restores_them() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	var trigger := _attach(kart, "hair_trigger")
	_attach(kart, "big_tank")
	_attach(kart, "rubber_bumpers")
	_attach(kart, "nitro_habit")
	_attach(kart, "magnet_hubcaps")
	_attach(kart, "jerry_can")
	assert_float(kart.cannon.stats.fire_cooldown).is_equal_approx(0.28, 0.001)
	assert_int(kart.cannon.stats.max_live_bullets).is_equal(5)
	assert_int(kart.cannon.stats.bounces).is_equal(1)
	assert_float(kart.stats.drift_exit_boost_duration).is_equal_approx(2.4, 0.001)
	assert_float(kart.stats.turbo_duration).is_equal_approx(3.0, 0.001)
	assert_float(kart.stats.nitro_recharge_seconds).is_equal_approx(22.5, 0.001)
	assert_float(kart._pickup_shape.radius).is_equal_approx(1.8, 0.001)
	assert_float(kart.base_stats.turbo_duration).is_equal_approx(1.0, 0.001)
	kart.jokers.remove(trigger)
	assert_float(kart.cannon.stats.fire_cooldown).is_equal_approx(0.4, 0.001)
	assert_int(kart.jokers.count()).is_equal(5)


## GAME.md 8.3: a card says how rare its joker is in pips as well as in color, and the pane
## says it in a word. Count as well as color, because color alone is not readable by everybody
## and the card is already spending its color on the joker's kind.
func test_a_card_wears_its_rarity_in_pips_and_the_pane_names_it() -> void:
	var common: Joker = load("res://data/jokers/big_tank.tres")
	var uncommon: Joker = load("res://data/jokers/getaway_driver.tres")
	var rare: Joker = load("res://data/jokers/wild_card.tres")
	assert_int(auto_free(JokerCard.create(common)).rarity_pips()).is_equal(1)
	assert_int(auto_free(JokerCard.create(uncommon)).rarity_pips()).is_equal(2)
	assert_int(auto_free(JokerCard.create(rare)).rarity_pips()).is_equal(3)
	assert_object(JokerCard.rarity_color(common)).is_not_equal(JokerCard.rarity_color(rare))
	var pane: JokerDetail = auto_free(JokerDetail.new())
	pane.show_joker(rare)
	assert_str(pane._rarity.text).is_equal("RARE")
	pane.show_joker(common)
	assert_str(pane._rarity.text).is_equal("COMMON")


## GAME.md 3.7: a player waiting to come back can still read their hand, and is the player with
## time to read it. What they cannot do is throw a card away: there is no kart to drop one from
## and the respawn pick is already asking what to keep.
func test_a_dead_player_can_look_through_their_hand_but_not_throw_any_of_it_away() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	for id: String in ["hair_trigger", "big_tank", "vulture"]:
		_attach(kart, id)
	await _runner.simulate_frames(12, 17)
	kart.die(&"pit", -1)
	assert_bool(kart.alive).is_false()
	var input := inputs[0]
	input.joker_menu = true
	await _runner.simulate_frames(4, 17)
	assert_bool(kart.menu_open).is_true()
	# The cursor walks. How far depends on how many ticks the frame ran for, which is not the
	# point: the point is that a dead player can move it at all.
	input.joker_next_pressed = true
	await _runner.simulate_frames(1, 17)
	input.joker_next_pressed = false
	assert_int(kart.menu_index).is_greater(0)
	# Neither button throws anything away.
	input.joker_drop_pressed = true
	await _runner.simulate_frames(1, 17)
	input.joker_drop_pressed = false
	input.joker_destroy_pressed = true
	await _runner.simulate_frames(1, 17)
	input.joker_destroy_pressed = false
	assert_int(kart.jokers.count()).is_equal(3)
	# Alive again, the same buttons work as they always did.
	await _runner.simulate_frames(120, 17)
	assert_bool(kart.alive).is_true()
	input.joker_destroy_pressed = true
	await _runner.simulate_frames(1, 17)
	input.joker_destroy_pressed = false
	assert_int(kart.jokers.count()).is_less(3)


func test_road_rage_slows_the_kart_and_rams_at_speed() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "road_rage")
	var expected := kart.base_stats.top_speed * 0.9
	assert_float(kart.stats.top_speed).is_equal_approx(expected, 0.001)
	assert_bool(kart.ram_kills()).is_false()
	kart.motor.velocity = kart.motor.forward_vector() * expected * 0.95
	assert_bool(kart.ram_kills()).is_true()


func test_graze_jokers() -> void:
	var match_node := _start_match(_bots())
	var slip := match_node.kart_of(0)
	var snake := match_node.kart_of(1)
	_attach(slip, "slipstream")
	_attach(snake, "snake_eyes")
	slip.graze(1)
	snake.graze(0)
	assert_float(slip.pot.mult).is_equal(2.5)
	assert_float(snake.pot.mult).is_equal(1.0)


func test_high_roller_doubles_mult_gains_and_banks_nothing_on_death() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "high_roller")
	kart.gain_mult(1.0, &"kill")
	assert_float(kart.pot.mult).is_equal(3.0)
	kart.pot.add_coins(10)
	kart.die(&"pit", -1)
	assert_int(match_node.slots[0].banked).is_equal(0)


## All that is left of the pot into the score: the chips a death spills still spill, and the rest
## banks whole rather than halved.
func test_insurance_policy_banks_all_that_is_left_on_death() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "insurance_policy")
	kart.pot.add_coins(10)
	kart.pot.add_mult(1.0)
	var loose := _chips_on_the_floor(match_node)
	kart.die(&"pit", -1)
	# Three of the ten spill, and the seven left bank at 2x.
	assert_int(_chips_on_the_floor(match_node) - loose).is_equal(3)
	assert_int(match_node.slots[0].banked).is_equal(14)


## Tight Grip lets none of the pot go: nothing spills and a killer takes nothing, and the death
## banks its usual share of all of it; with Insurance Policy as well, all of all of it.
func test_tight_grip_lets_none_of_the_pot_go() -> void:
	var three: Array[KartInput] = [KartInput.new(), KartInput.new(), KartInput.new()]
	var match_node := _start_match(three)
	var kart := match_node.kart_of(0)
	var thief := match_node.kart_of(1)
	_attach(kart, "tight_grip")
	_attach(thief, "pickpocket")
	kart.pot.add_coins(10)
	kart.pot.add_mult(1.0)
	var loose := _chips_on_the_floor(match_node)
	kart.die(&"bullet", 1)
	assert_int(_chips_on_the_floor(match_node)).is_equal(loose)
	assert_int(thief.pot.coins).is_equal(0)
	assert_int(match_node.slots[0].banked).is_equal(10)
	var both := match_node.kart_of(2)
	_attach(both, "tight_grip")
	_attach(both, "insurance_policy")
	both.pot.add_coins(10)
	both.pot.add_mult(1.0)
	both.die(&"pit", -1)
	assert_int(match_node.slots[2].banked).is_equal(20)
	assert_int(_chips_on_the_floor(match_node)).is_equal(loose)


func _chips_on_the_floor(match_node: Match) -> int:
	var count := 0
	for node: Node in match_node.arena.pickups.get_children():
		if node is Chip and not node.is_queued_for_deletion():
			count += 1
	return count


func test_coin_value_jokers() -> void:
	var match_node := _start_match(_bots())
	var vulture := match_node.kart_of(0)
	var dice := match_node.kart_of(1)
	_attach(vulture, "vulture")
	_attach(dice, "loaded_dice")
	vulture.collect_coins(1, _chip(true))
	vulture.collect_coins(1, _chip(false))
	assert_int(vulture.pot.coins).is_equal(4)
	for i: int in 300:
		dice.collect_coins(1, _chip())
	assert_int(dice.pot.coins).is_between(510, 690)


func test_lucky_seven_gives_a_mult_every_seventh_chip() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "lucky_seven")
	for i: int in 14:
		kart.collect_coins(1, _chip())
	assert_float(kart.pot.mult).is_equal(3.0)


func test_green_light_rewards_turbo_pads() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "green_light")
	await _runner.simulate_frames(12, 17)
	kart.apply_turbo(Vector3(0.0, 0.0, 1.0))
	assert_float(kart.pot.mult).is_equal(2.0)


func test_pickpocket_steals_half_the_victims_coins_and_the_victim_drops_none() -> void:
	var match_node := _start_match(_bots())
	var killer := match_node.kart_of(1)
	var victim := match_node.kart_of(0)
	_attach(killer, "pickpocket")
	victim.pot.add_coins(10)
	var pickups_before := match_node.arena.pickups.get_child_count()
	victim.die(&"bullet", 1)
	assert_int(killer.pot.coins).is_equal(5)
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(pickups_before)


func test_glass_jackpot_pays_more_and_dies_hard() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	_attach(kart, "glass_jackpot")
	_attach(kart, "hair_trigger")
	_attach(kart, "big_tank")
	await _runner.simulate_frames(12, 17)
	kart.pot.add_coins(20)
	kart.pot.add_mult(1.0)
	kart.global_position = match_node.arena.junction_position
	await _runner.simulate_frames(110, 17)
	assert_int(match_node.slots[0].banked).is_equal(60)
	kart.pot.add_coins(10)
	var pickups_before := match_node.arena.pickups.get_child_count()
	kart.die(&"pit", -1)
	assert_int(kart.jokers.count()).is_equal(1)
	assert_int(match_node.arena.pickups.get_child_count()).is_equal(pickups_before + 12)


func test_getaway_driver_banks_faster_and_toll_booth_skims_others() -> void:
	var match_node := _start_match(_bots())
	var driver := match_node.kart_of(0)
	var booth := match_node.kart_of(1)
	_attach(driver, "getaway_driver")
	_attach(booth, "toll_booth")
	assert_float(driver.bank_doubling()).is_equal_approx(0.25, 0.001)
	await _runner.simulate_frames(12, 17)
	driver.pot.add_coins(20)
	driver.pot.add_mult(1.0)
	driver.global_position = match_node.arena.junction_position
	await _runner.simulate_frames(60, 17)
	assert_int(match_node.slots[0].banked).is_equal(40)
	assert_int(match_node.slots[1].banked).is_equal(6)


func test_comeback_and_snake_eyes_set_the_mult_on_respawn() -> void:
	var match_node := _start_match(_bots())
	var comeback := match_node.kart_of(0)
	var snake := match_node.kart_of(1)
	_attach(comeback, "comeback")
	_attach(snake, "snake_eyes")
	await _runner.simulate_frames(12, 17)
	comeback.pot.add_mult(3.0)
	comeback.die(&"pit", -1)
	snake.die(&"pit", -1)
	await _runner.simulate_frames(30, 17)
	assert_bool(comeback.alive).is_true()
	assert_float(comeback.pot.mult).is_equal(2.0)
	assert_float(snake.pot.mult).is_equal(3.0)


func test_a_human_gets_an_offer_on_death_and_respawn_waits_for_the_choice() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), KartInput.new()]
	var match_node := _start_match(inputs, 3)
	var kart := match_node.kart_of(0)
	_attach(kart, "hair_trigger")
	await _runner.simulate_frames(12, 17)
	kart.die(&"pit", -1)
	var slot := match_node.slots[0]
	assert_object(slot.offer).is_not_null()
	assert_int(slot.offer.choices.size()).is_equal(3)
	for joker: Joker in slot.offer.choices:
		assert_bool(joker.id == &"hair_trigger").is_false()
	await _runner.simulate_frames(30, 17)
	assert_bool(kart.alive).is_false()
	slot.offer.take(1)
	var picked := slot.offer.chosen.id
	assert_bool(slot.offer.is_done()).is_true()
	assert_bool(kart.jokers.has(picked)).is_true()
	await _runner.simulate_frames(6, 17)
	assert_bool(kart.alive).is_true()


func test_a_full_hand_must_destroy_a_joker_to_take_a_new_one_and_may_skip() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), KartInput.new()]
	var match_node := _start_match(inputs, 3)
	var kart := match_node.kart_of(0)
	for id: String in ["hair_trigger", "big_tank", "rubber_bumpers", "nitro_habit", "vulture"]:
		_attach(kart, id)
	await _runner.simulate_frames(12, 17)
	kart.die(&"pit", -1)
	var offer := match_node.slots[0].offer
	offer.take(0)
	assert_int(offer.stage).is_equal(JokerOffer.Stage.REPLACING)
	offer.cancel_replace()
	assert_int(offer.stage).is_equal(JokerOffer.Stage.CHOOSING)
	offer.take(0)
	offer.replace(1)
	assert_bool(offer.is_done()).is_true()
	assert_int(kart.jokers.count()).is_equal(5)
	assert_bool(kart.jokers.has(&"big_tank")).is_false()
	assert_bool(kart.jokers.has(offer.chosen.id)).is_true()
	await _runner.simulate_frames(30, 17)
	kart.die(&"pit", -1)
	var second := match_node.slots[0].offer
	second.skip()
	assert_bool(second.is_done()).is_true()
	assert_int(kart.jokers.count()).is_equal(5)


func test_wild_card_offers_five_and_bots_always_take_one() -> void:
	var match_node := _start_match(_bots(), 3)
	var kart := match_node.kart_of(0)
	_attach(kart, "wild_card")
	assert_int(kart.offer_count(3)).is_equal(5)
	await _runner.simulate_frames(12, 17)
	kart.die(&"pit", -1)
	var offer := match_node.slots[0].offer
	assert_int(offer.choices.size()).is_equal(5)
	assert_bool(offer.is_done()).is_true()
	assert_int(kart.jokers.count()).is_equal(2)


func test_dropped_jokers_land_on_the_floor_and_can_be_picked_up() -> void:
	var match_node := _start_match(_bots())
	var rules := match_node.rules
	rules.death_joker_drop_chance = 1.0
	var kart := match_node.kart_of(0)
	var other := match_node.kart_of(1)
	_attach(kart, "hair_trigger")
	await _runner.simulate_frames(12, 17)
	kart.global_position = Vector3(-4.5, 0.0, 1.0)
	kart.die(&"pit", -1)
	var cards: Array[FloorJoker] = []
	for child: Node in match_node.arena.pickups.get_children():
		if child is FloorJoker:
			cards.append(child)
	assert_int(cards.size()).is_equal(1)
	assert_bool(kart.jokers.has(&"hair_trigger")).is_false()
	other.global_position = cards[0].global_position
	await _runner.simulate_frames(10, 17)
	assert_bool(other.jokers.has(&"hair_trigger")).is_true()
	other.drop_joker(0)
	assert_int(other.jokers.count()).is_equal(0)
	var dropped := 0
	for child: Node in match_node.arena.pickups.get_children():
		if child is FloorJoker:
			dropped += 1
	assert_int(dropped).is_equal(1)


## GAME.md 3.7: fire takes the card under the cursor as well as the item button does. A player
## sitting on a respawn pick has a thumb on fire already.
func test_the_fire_button_takes_the_card_under_the_cursor() -> void:
	var match_node := _start_match(_bots(), 3)
	var kart := match_node.kart_of(0)
	var offer := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, []))
	offer.answer_at = 0.0
	offer.selected = 1
	var wanted := offer.choices[1]
	var input := KartInput.new()
	input.fire_pressed = true
	offer.poll_input(input)
	assert_bool(offer.is_done()).is_true()
	assert_array(kart.jokers.ids()).contains([wanted.id])
	# And the item button still does, for anyone who learned it that way.
	var second := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, kart.jokers.ids()))
	second.answer_at = 0.0
	second.selected = 0
	var item := KartInput.new()
	item.use_item_pressed = true
	second.poll_input(item)
	assert_bool(second.is_done()).is_true()


## GAME.md 3.7: the cards stand there for half a second before they can be answered. A player is
## killed with a thumb on the trigger and the pick opens under that thumb; the card under the
## cursor was being claimed before anybody had read a word of it. Moving the cursor is allowed
## the whole time, because which card you are looking at was never the problem.
func test_the_pick_cannot_be_answered_for_half_a_second() -> void:
	var match_node := _start_match(_bots(), 3)
	var kart := match_node.kart_of(0)
	var offer := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, []))
	assert_bool(offer.is_settled()).is_false()
	var input := KartInput.new()
	input.fire_pressed = true
	offer.poll_input(input)
	assert_bool(offer.is_done()).is_false()
	assert_int(kart.jokers.count()).is_equal(0)
	# Skipping is held back with it: a thumb on the destroy button throws the pick away.
	var skipping := KartInput.new()
	skipping.joker_destroy_pressed = true
	offer.poll_input(skipping)
	assert_bool(offer.is_done()).is_false()
	# The cursor still walks, throughout.
	var steering := KartInput.new()
	steering.cursor = 1.0
	offer.poll_input(steering)
	assert_int(offer.selected).is_equal(1)
	# And once the moment has passed the same press is answered.
	offer.answer_at = 0.0
	offer.poll_input(input)
	assert_bool(offer.is_done()).is_true()
	assert_int(kart.jokers.count()).is_equal(1)


## GAME.md 7.3: Backfire points the cannon out of the back of the kart while the brake is held,
## so a driver being chased can answer without turning round.
func test_backfire_shoots_out_of_the_back_while_the_brake_is_held() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	kart.face(Vector3(1.0, 0.0, 0.0))
	await _runner.simulate_frames(4, 17)
	var nose := KartAim.direction(kart)
	assert_vector(nose).is_equal_approx(Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.01)
	_attach(kart, "backfire")
	# Off the brake it is an ordinary cannon.
	kart.input.brake = 0.0
	assert_vector(KartAim.direction(kart)).is_equal_approx(nose, Vector3.ONE * 0.01)
	# A brush of it while trail braking is not somebody asking to shoot behind themselves.
	kart.input.brake = 0.2
	assert_vector(KartAim.direction(kart)).is_equal_approx(nose, Vector3.ONE * 0.01)
	# Held, and the shot leaves the other way.
	kart.input.brake = 1.0
	assert_vector(KartAim.direction(kart)).is_equal_approx(-nose, Vector3.ONE * 0.01)
	# Free aim overrules it: a hand on the stick has already said where the shot goes.
	kart.cannon.stats.free_aim = true
	kart.input.aim = Vector2(0.0, -1.0)
	assert_vector(KartAim.direction(kart)).is_equal_approx(
		Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.01
	)


## GAME.md 8.3: a pick in the middle of one player's half is a wall across the arena for whoever
## else is on this screen, who is still driving in it. Sharing, it goes down to the foot of its own
## share in the hand's place, smaller, the pane beside the cards, so the whole pick is a strip along
## the bottom edge of its half. Alone, the one watching is the one picking, and it keeps the middle.
func test_a_shared_screen_keeps_the_joker_pick_out_of_the_arena() -> void:
	var match_node := _start_match(_bots())
	var kart := match_node.kart_of(0)
	var offer := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, []))
	var alone: JokerPicker = auto_free(JokerPicker.new())
	add_child(alone)
	var shared: JokerPicker = auto_free(JokerPicker.new())
	shared.columns = 2
	add_child(shared)
	await await_idle_frame()
	alone.size = Vector2(1920.0, 1080.0)
	shared.size = Vector2(1920.0, 1080.0)
	alone.show_offer(offer, kart)
	shared.show_offer(offer, kart)
	# The last card, which is not the one picked out and lifted.
	var card := shared._cards[shared._cards.size() - 1]
	var foot := card.position.y + card.size.y
	# Down at the foot of the screen, where the hand was, and smaller than alone in the middle.
	assert_float(foot).is_greater(1080.0 - JokerPicker.STRIP_FOOT - 1.0)
	assert_float(card.scale.x).is_less(alone._cards[0].scale.x)
	assert_bool(shared.over_hand()).is_true()
	assert_bool(shared.shared()).is_true()
	# The pane beside the cards rather than over them, its foot on their line.
	assert_float(shared._detail.position.x).is_greater(card.position.x)
	assert_float(shared._detail.position.y + shared._detail.size.y).is_equal_approx(foot, 1.0)
	# And it keeps to its own half of the screen.
	assert_float(shared._detail.position.x + shared._detail.size.x).is_less(960.0)
	# Alone it keeps the middle, its pane under its cards, and the hand where it is.
	assert_bool(alone.over_hand()).is_false()
	assert_bool(alone.shared()).is_false()
	assert_float(alone._cards[0].position.y).is_less(card.position.y - 100.0)
	assert_float(alone._detail.position.y).is_greater(alone._cards[0].position.y)


## And a kart that dies after the whistle is offered nothing either, GAME.md 4.4. A bomb already
## in the air or a fall already begun still lands once the match is over, and the pick it made
## sat open over the podium: a question about a match that has already been decided.
func test_a_death_after_the_whistle_offers_no_joker_pick() -> void:
	var seats: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(seats, 3, 21, true)
	match_node.rules.overtime = false
	match_node.time_left = 0.0
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	var slot := match_node.slots[0]
	slot.kart.die(&"pit", -1)
	await _runner.simulate_frames(4, 17)
	assert_object(slot.offer).is_null()
	# And the picker with it: nothing feeds one once the podium is up.
	var picker: JokerPicker = match_node.hud._pickers[0]
	assert_bool(picker.visible).is_false()
