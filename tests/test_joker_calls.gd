extends GdUnitTestSuite
## The jokers that do something by themselves say so, GAME.md 8.3: each raises the word its card
## goes off with in the hand, on the moment it made a difference and on no other, and only where
## the karts are run. In a running match of two karts.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner
## What went off since the test began: "slot joker WORD".
var _said: Array[String] = []


func _heard(slot: int, joker: StringName, word: String) -> void:
	_said.append("%d %s %s" % [slot, joker, word])


func before_test() -> void:
	_said.clear()
	Events.joker_went_off.connect(_heard)


func after_test() -> void:
	Events.joker_went_off.disconnect(_heard)


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.death_joker_drop_chance = 0.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([KartInput.new(), KartInput.new()] as Array[KartInput], 21)
	await _runner.simulate_frames(20, 17)
	return match_node


func _attach(kart: Kart, id: String) -> Joker:
	return kart.jokers.add(load("res://data/jokers/%s.tres" % id))


## Insurance Policy says so on a death with something in the pot to bank, and not on one without.
func test_insurance_policy_says_so_when_it_banks_a_pot() -> void:
	var match_node := await _start_match()
	var kart := match_node.kart_of(0)
	_attach(kart, "insurance_policy")
	kart.die(&"pit", -1)
	assert_array(_said).is_empty()
	await _runner.simulate_frames(int(match_node.rules.respawn_delay * 60.0) + 30, 17)
	kart.pot.add_coins(12)
	kart.die(&"pit", -1)
	assert_array(_said).is_equal(["0 insurance_policy INSURED"] as Array[String])


## Tight Grip says so when a death or a ram would have spilled coins out of the pot.
func test_tight_grip_says_so_when_it_keeps_the_coins_in() -> void:
	var match_node := await _start_match()
	var kart := match_node.kart_of(0)
	_attach(kart, "tight_grip")
	kart.pot.add_coins(20)
	match_node._on_kart_rammed(1, match_node.slots[0])
	assert_int(kart.pot.coins).is_equal(20)
	assert_array(_said).is_equal(["0 tight_grip GRIPPED"] as Array[String])
	kart.die(&"pit", -1)
	assert_int(_said.size()).is_equal(2)


## Pickpocket says so on the killer's card when the kill took coins, and not when the victim's pot
## was held shut by Tight Grip.
func test_pickpocket_says_so_when_a_kill_takes_coins() -> void:
	var match_node := await _start_match()
	var killer := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	_attach(killer, "pickpocket")
	victim.pot.add_coins(10)
	victim.die(&"bullet", 0)
	assert_array(_said).is_equal(["0 pickpocket STOLEN"] as Array[String])
	await _runner.simulate_frames(int(match_node.rules.respawn_delay * 60.0) + 30, 17)
	_said.clear()
	_attach(victim, "tight_grip")
	victim.pot.add_coins(10)
	victim.die(&"bullet", 0)
	assert_bool("0 pickpocket STOLEN" in _said).is_false()


## Toll Booth says so when another kart's cash-out pays it.
func test_toll_booth_says_so_when_it_takes_its_toll() -> void:
	var match_node := await _start_match()
	_attach(match_node.kart_of(0), "toll_booth")
	match_node._on_bank_completed(match_node.kart_of(1), 40, 2.0, 80)
	assert_array(_said).is_equal(["0 toll_booth TOLL"] as Array[String])


## Road Rage says so when a ram landed because of it, and not when nitro would have made it one.
func test_road_rage_says_so_when_its_ram_lands() -> void:
	var match_node := await _start_match()
	var kart := match_node.kart_of(0)
	var other := match_node.kart_of(1)
	_attach(kart, "road_rage")
	other.protection_left = 0.0
	assert_bool(KartCollisions.ram(other, 0)).is_true()
	assert_bool(KartCollisions.ram(other, 0)).override_failure_message("rammed twice").is_false()
	kart.nitro_active = true
	KartCollisions._raged(kart)
	assert_array(_said).is_empty()
	kart.nitro_active = false
	KartCollisions._raged(kart)
	assert_array(_said).override_failure_message("said so at a crawl").is_empty()
	kart.motor.velocity = kart.motor.forward_vector() * kart.motor.stats.top_speed * 0.95
	KartCollisions._raged(kart)
	assert_array(_said).is_equal(["0 road_rage WRECKED"] as Array[String])


## Carbon Copy says so when a death drops a copy of a joker.
func test_carbon_copy_says_so_when_it_copies_a_drop() -> void:
	var match_node := await _start_match()
	match_node.rules.death_joker_drop_chance = 1.0
	var kart := match_node.kart_of(0)
	_attach(kart, "carbon_copy")
	_attach(kart, "big_tank")
	kart.die(&"pit", -1)
	assert_array(_said).is_equal(["0 carbon_copy COPIED"] as Array[String])
	assert_int(kart.jokers.count()).is_equal(2)


## A puppet's jokers do nothing of their own: the host says it, and the client hears it relayed.
func test_a_puppets_jokers_say_nothing_and_the_host_relays_it() -> void:
	var match_node := await _start_match()
	var kart := match_node.kart_of(0)
	var angel := _attach(kart, "guardian_angel")
	kart.puppet = true
	angel.went_off(kart, "GUARDED")
	angel.used_up(kart, "LOST")
	kart.puppet = false
	assert_array(_said).is_empty()
	assert_bool(&"joker_went_off" in NetEvents.RELAYED).is_true()
	assert_bool(&"joker_used_up" in NetEvents.RELAYED).is_true()
