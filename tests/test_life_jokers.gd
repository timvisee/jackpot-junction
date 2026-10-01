extends GdUnitTestSuite
## The jokers about lives, GAME.md 3.6 and 7.3: Spare Tire, one more that the death takes with it,
## Scar Tissue, one more that nothing heals, and Guardian Angel, which spends a protection item on a
## hit that would take one. In a running match with the rules' two lives.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const SHIELD := preload("res://data/powerups/shield.tres")
const WIPE := preload("res://data/powerups/bullet_wipe.tres")

var _runner: GdUnitSceneRunner


## A match of two karts, the first driven by [param first] when given, and the HUD up with
## [param hud].
func _start_match(first: KartInput = null, hud := false) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 2
	rules.duration = 60.0
	rules.respawn_delay = 0.2
	rules.death_joker_drop_chance = 1.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = hud
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [first if first != null else KartInput.new(), KartInput.new()]
	match_node.start(inputs, 21)
	return match_node


func _attach(kart: Kart, id: String) -> Joker:
	return kart.jokers.add(load("res://data/jokers/%s.tres" % id))


## A lethal hit on [param kart] from the other kart.
func _hit(kart: Kart) -> void:
	kart.hurt_left = 0.0
	kart.protection_left = 0.0
	kart._take_lethal(&"bullet", 1)


## Spare Tire is one more life, there the moment it is picked up rather than a wound, and healing
## fills it; the death that takes the last life takes the tire too, and it is never dropped.
func test_spare_tire_is_one_more_life_lost_with_the_kart() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	_attach(kart, "spare_tire")
	assert_int(KartLives.most(kart)).is_equal(3)
	assert_int(kart.lives).is_equal(3)
	assert_bool(kart.is_wounded()).is_false()
	_hit(kart)
	assert_int(kart.lives).is_equal(2)
	kart.restore_life()
	assert_int(kart.lives).is_equal(3)
	_hit(kart)
	_hit(kart)
	assert_bool(kart.alive).is_true()
	var floor_before := _floor_jokers(match_node)
	_hit(kart)
	assert_bool(kart.alive).is_false()
	assert_bool(kart.jokers.has(&"spare_tire")).is_false()
	assert_int(_floor_jokers(match_node)).override_failure_message("the tire was dropped").is_equal(
		floor_before
	)
	await _runner.simulate_frames(30, 17)
	assert_bool(kart.alive).is_true()
	assert_int(kart.lives).is_equal(2)


## Scar Tissue is one more life that nothing heals while it lives, neither the Junction nor a
## kill; coming back brings them all back. Held with Spare Tire, the two stack, and nothing heals.
func test_scar_tissue_is_one_more_life_that_only_coming_back_heals() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	_attach(kart, "scar_tissue")
	assert_int(kart.lives).is_equal(3)
	_hit(kart)
	assert_int(kart.lives).is_equal(2)
	kart.restore_life()
	assert_int(kart.lives).override_failure_message("Scar Tissue healed").is_equal(2)
	_attach(kart, "spare_tire")
	assert_int(KartLives.most(kart)).is_equal(4)
	assert_int(kart.lives).is_equal(3)
	kart.restore_life()
	assert_int(kart.lives).is_equal(3)
	match_node.rules.death_joker_drop_chance = 0.0
	kart.die(&"pit", -1)
	await _runner.simulate_frames(30, 17)
	assert_bool(kart.alive).is_true()
	# The tire went with that death; the scar stays, and the life that comes back with it is full.
	assert_int(kart.lives).is_equal(3)
	# Dropped from the hand while alive, the life it brought goes with it, never the last one.
	kart.jokers.remove(kart.jokers.jokers[0])
	assert_int(kart.lives).is_equal(2)


func _floor_jokers(match_node: Match) -> int:
	var count := 0
	for node: Node in match_node.arena.pickups.get_children():
		if node is FloorJoker:
			count += 1
	return count


## Guardian Angel spends the Shield or Bullet Wipe the kart holds on a hit about to cost it a life:
## a Shield on anything, a Bullet Wipe on a shot only, and nothing still being rolled for.
func test_guardian_angel_spends_the_protection_held() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	_attach(kart, "guardian_angel")
	kart.protection_left = 0.0
	kart.hurt_left = 0.0
	kart.hold_item(SHIELD, 0.0)
	kart.take_ram(1)
	assert_int(kart.lives).override_failure_message("the shield never went up").is_equal(2)
	assert_object(kart.held_item).is_null()
	assert_bool(kart.shielded).is_false()
	# A Bullet Wipe takes a shot, and wipes it with the rest near the kart.
	kart.hold_item(WIPE, 0.0)
	var shot: Bullet = auto_free(Bullet.new())
	shot.owner_slot = 1
	kart.take_hit(shot)
	assert_int(kart.lives).is_equal(2)
	assert_object(kart.held_item).is_null()
	# But not a ram, which it cannot wipe away.
	kart.hold_item(WIPE, 0.0)
	kart.take_ram(1)
	assert_int(kart.lives).is_equal(1)
	assert_object(kart.held_item).is_not_null()
	# Nor does anything off a pad that is still being rolled for.
	kart.hurt_left = 0.0
	kart.restore_life()
	kart.hold_item(SHIELD, 0.5)
	kart.take_ram(1)
	assert_int(kart.lives).is_equal(1)


## Carbon Copy: a joker the death drops goes on the floor as a copy, and the hand keeps its own,
## Carbon Copy among them. Without it the card leaves the hand, as ever.
func test_carbon_copy_keeps_what_the_death_drops() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	_attach(kart, "carbon_copy")
	_attach(kart, "odometer")
	var held := kart.jokers.ids()
	var before := _floor_jokers(match_node)
	kart.die(&"pit", -1)
	assert_int(_floor_jokers(match_node) - before).is_equal(1)
	assert_array(kart.jokers.ids()).is_equal(held)
	# Without it, the card dropped is gone from the hand.
	var other := match_node.kart_of(1)
	_attach(other, "odometer")
	other.die(&"pit", -1)
	assert_bool(other.jokers.has(&"odometer")).is_false()


## Guardian Angel taking a hit says so, GAME.md 7.3 and 8.3: the event goes to every screen, and in
## its player's hand the card pulls out of the fan, grows, lights up and glows round its frame with
## "GUARDED" over it, and goes back.
func test_guardian_angel_taking_a_hit_sets_its_card_off() -> void:
	var match_node := _start_match(PlayerInput.new(DeviceInput.ANY, 0), true)
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	_attach(kart, "spare_tire")
	_attach(kart, "guardian_angel")
	await _runner.simulate_frames(30, 17)
	var hand := match_node.hud.hand_of(0)
	var angel: JokerCard = hand._cards[1]
	var rest := angel.position.y
	var rest_scale := angel.scale.x
	kart.protection_left = 0.0
	kart.hurt_left = 0.0
	kart.hold_item(SHIELD, 0.0)
	var heard: Array[StringName] = []
	var note := func(slot: int, joker: StringName) -> void:
		if slot == 0:
			heard.append(joker)
	Events.kart_spared.connect(note)
	kart.take_ram(1)
	Events.kart_spared.disconnect(note)
	assert_array(heard).is_equal([&"guardian_angel"] as Array[StringName])
	assert_bool(&"kart_spared" in NetEvents.RELAYED).is_true()
	await _runner.simulate_frames(20, 17)
	assert_float(angel.position.y).override_failure_message("it never pulled out").is_less(
		rest - 30.0
	)
	assert_float(angel.scale.x).is_greater(rest_scale * 1.15)
	assert_float(angel.modulate.r).is_greater(1.1)
	assert_object(angel.get_theme_stylebox("panel")).is_same(angel._glowing)
	assert_int(angel.z_index).is_greater(hand._cards[0].z_index)
	# The other card stays where it was, and nothing rises over the kart.
	assert_object(hand._cards[0].get_theme_stylebox("panel")).is_same(hand._cards[0]._normal)
	assert_object(match_node.get_node_or_null("FloatingIcon")).is_null()
	# "GUARDED" over it, clear of its top.
	var word: Label = hand._words.get(&"guardian_angel")
	assert_object(word).override_failure_message("no word over the card").is_not_null()
	assert_str(word.text).is_equal("GUARDED")
	assert_float(word.modulate.a).is_greater(0.9)
	var top := angel.position.y + angel.pivot_offset.y - JokerCard.SIZE.y * angel.scale.y
	assert_float(word.position.y + word.size.y).is_less_equal(top)
	await _runner.simulate_frames(int(JokerHand.FLASH_TIME * 60.0) + 30, 17)
	assert_float(angel.position.y).is_equal_approx(rest, 1.0)
	assert_float(angel.modulate.r).is_less(1.02)
	assert_object(angel.get_theme_stylebox("panel")).is_same(angel._normal)
	assert_bool(hand._words.is_empty()).is_true()
	assert_bool(is_instance_valid(word)).is_false()


## A tucked hand, a touch screen's, comes up while a card of it is out, the way it does for a card
## being read, so the card that went off is seen at its full size rather than half under the edge.
func test_a_tucked_hand_comes_up_while_a_card_is_out() -> void:
	var match_node := _start_match(PlayerInput.new(DeviceInput.ANY, 0), true)
	await _runner.simulate_frames(20, 17)
	_attach(match_node.kart_of(0), "guardian_angel")
	var hand := match_node.hud.hand_of(0)
	hand.tucked = true
	await _runner.simulate_frames(40, 17)
	var tucked := hand._cards[0].scale.x
	hand.flash(&"guardian_angel")
	await _runner.simulate_frames(20, 17)
	assert_float(hand._cards[0].scale.x).is_greater(tucked * 1.6)
