extends GdUnitTestSuite
## Dealing a card of the respawn pick again, GAME.md 3.7: once a pick, for 50 banked points, never
## the card it was nor another the pick shows, and never in a keep pick; at a client asked of the
## host by name.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 3
	_runner = scene_runner(match_node)
	# A player's seat: a bot's pick is answered as it is dealt.
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), KartInput.new()]
	match_node.start(inputs, 11)
	return match_node


## A pick dealt to the first seat once the map is under way, [param banked] in the bank.
func _pick(banked := 100) -> JokerOffer:
	var match_node := _start()
	await _runner.simulate_frames(12, 17)
	var slot := match_node.slots[0]
	slot.banked = banked
	var offer := KartDeath._offer(match_node, slot)
	offer.answer_at = 0.0
	return offer


func _ids(offer: JokerOffer) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card: Joker in offer.choices:
		ids.append(card.id)
	return ids


## The card under the cursor is dealt again for 50 banked points: a card the pick did not show,
## once.
func test_a_card_is_dealt_again_once() -> void:
	var offer: JokerOffer = await _pick()
	var before := _ids(offer)
	assert_bool(offer.can_reroll()).is_true()
	assert_bool(offer.reroll(1)).is_true()
	var after := _ids(offer)
	assert_str(String(after[0])).is_equal(String(before[0]))
	assert_str(String(after[2])).is_equal(String(before[2]))
	assert_bool(after[1] in before).is_false()
	assert_int(offer.table.slots[0].banked).is_equal(100 - JokerOffer.REROLL_COST)
	assert_bool(offer.can_reroll()).is_false()
	assert_bool(offer.reroll(0)).is_false()


## Too few points banked, a keep pick, or a pick already answered: no reroll.
func test_no_reroll_without_the_points_or_in_a_keep() -> void:
	var poor: JokerOffer = await _pick(JokerOffer.REROLL_COST - 1)
	assert_bool(poor.can_reroll()).is_false()
	assert_bool(poor.reroll(0)).is_false()
	poor.table.slots[0].banked = 200
	poor.keeping = true
	assert_bool(poor.can_reroll()).is_false()
	poor.keeping = false
	poor.skip()
	assert_bool(poor.can_reroll()).is_false()


## The nitro key deals the card under the cursor again, read as the pick reads its other keys.
func test_the_nitro_key_rerolls_the_card_under_the_cursor() -> void:
	var offer: JokerOffer = await _pick()
	var before := _ids(offer)
	offer.selected = 2
	var input := KartInput.new()
	input.nitro = true
	offer.poll_input(input)
	assert_bool(_ids(offer)[2] in before).is_false()
	assert_int(offer.rerolls_left).is_equal(0)


## At a client the card is named for the host to deal again, and the host's word brings it.
func test_a_client_asks_the_host() -> void:
	var offer: JokerOffer = await _pick()
	var host_side := offer.choices.duplicate()
	offer.table.puppet = true
	assert_bool(offer.reroll(0)).is_true()
	assert_str(String(offer.reroll_asked)).is_equal(String(host_side[0].id))
	assert_int(offer.table.slots[0].banked).is_equal(100)
	offer.table.puppet = false
	offer.rerolls_left = 1
	assert_bool(offer.reroll_card(offer.reroll_asked)).is_true()
	assert_bool(offer.choices[0].id == host_side[0].id).is_false()
