extends GdUnitTestSuite
## What a table deals under the loyalty program of GAME.md 8.9: the twenty jokers every deck
## starts with and the cards and later items the program adds, the profile playing's at a machine,
## the host's say's at a dedicated server, and what a machine says of its own at the door, see
## [Loyalty].

const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const ALL_ITEMS: PowerUpTable = preload("res://data/powerups/all.tres")
const FIRST_SET: PowerUpTable = preload("res://data/powerups/first_set.tres")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const PATH := "user://test_loyalty_table.cfg"

var _settings_were: Settings
var _session_was: NetSession


func before_test() -> void:
	_settings_were = Game.settings
	_session_was = Net.session
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()


func after_test() -> void:
	Net.session = _session_was
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _ids(items: PowerUpTable) -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: PowerUp in items.entries:
		ids.append(entry.id)
	return ids


## A profile that has won [param landmarks].
func _winning(landmarks: Array[StringName]) -> Profile:
	var profile := Profile.new()
	for id: StringName in landmarks:
		profile.loyalty.win(id)
	return profile


## Twenty jokers are in every deck, and every other joker is added by one landmark of the map.
func test_every_joker_is_in_the_starting_deck_or_added_once() -> void:
	var starting := 0
	for joker: Joker in JOKERS.printed():
		var adder := Loyalty.adder_of(joker.id)
		if joker.starting_deck:
			starting += 1
			assert_object(adder).override_failure_message(String(joker.id)).is_null()
		else:
			assert_object(adder).override_failure_message(String(joker.id)).is_not_null()
	assert_int(starting).is_equal(27)


## A fresh profile's table is dealt the twenty and the first set, and never anything else, however
## often it is dealt; the floor's draws keep to the deck too.
func test_a_fresh_profile_is_dealt_the_starting_deck() -> void:
	var fresh := Loyalty.unlocks_of(Profile.new())
	assert_array(Array(fresh["jokers"])).is_empty()
	var deck := Loyalty.deck_from(fresh, JOKERS)
	assert_int(deck.size()).is_equal(27)
	var dealt := JOKERS.dealing(deck)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in 200:
		for joker: Joker in dealt.offer(rng, 3, []):
			assert_bool(joker.starting_deck).override_failure_message(String(joker.id)).is_true()
		var thrown := dealt.quality(rng, Joker.Rarity.UNCOMMON)
		assert_bool(thrown.starting_deck).is_true()
		assert_int(thrown.rarity).is_greater_equal(Joker.Rarity.UNCOMMON)
	# No rare is in the starting deck, so none is ever thrown that way.
	assert_object(dealt.quality(rng, Joker.Rarity.RARE)).is_null()
	# Every joker is still known by its name, for a hand dealt by a host with more.
	assert_object(dealt.by_id(&"wild_card")).is_not_null()
	assert_array(_ids(Loyalty.items_from(fresh, ALL_ITEMS))).is_equal(_ids(FIRST_SET))


## The cards and items a landmark won adds are dealt from then on.
func test_won_landmarks_add_to_the_deck_and_the_items() -> void:
	var profile := _winning([&"rare_cards", &"spread_and_swivel"])
	var unlocks := Loyalty.unlocks_of(profile)
	var deck := Loyalty.deck_from(unlocks, JOKERS)
	assert_int(deck.size()).is_equal(31)
	for id: StringName in [&"lucky_seven", &"hot_streak", &"aimbot"]:
		assert_bool(id in deck).is_true()
		assert_bool(Loyalty.in_deck(profile, JOKERS.by_id(id))).is_true()
	assert_bool(Loyalty.in_deck(profile, JOKERS.by_id(&"wild_card"))).is_false()
	var items := _ids(Loyalty.items_from(unlocks, ALL_ITEMS))
	# The Prize Counter adds its seven: Spread and Swivel, and the Rocket, Grenade, Railgun, Flak
	# Cannon and Proximity Mine of 5.3.
	assert_int(items.size()).is_equal(FIRST_SET.entries.size() + 7)
	assert_bool(&"spread_cannon" in items).is_true()
	assert_bool(&"flak_cannon" in items).is_true()
	assert_bool(&"decoy_kart" in items).is_false()
	# A table of the first set alone stays the first set, whatever was added.
	assert_array(_ids(Loyalty.items_from(unlocks, FIRST_SET))).is_equal(_ids(FIRST_SET))


## A room dealt by this machine deals the profile playing's deck and items.
func test_a_room_deals_the_profile_playings_table() -> void:
	Game.settings.profile.loyalty.win(&"more_rare_cards")
	Game.settings.profile.loyalty.win(&"decoy_and_wipe")
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	Loyalty.deal_table(match_node, ALL_ITEMS, false)
	assert_int(match_node.joker_catalog.deck.size()).is_equal(33)
	assert_bool(&"wild_card" in match_node.joker_catalog.deck).is_true()
	assert_bool(&"aimbot" in match_node.joker_catalog.deck).is_false()
	assert_bool(&"bullet_wipe" in _ids(match_node.power_ups)).is_true()
	assert_bool(&"swivel_cannon" in _ids(match_node.power_ups)).is_false()


## What a machine says it has added is kept as far as it is names, as many as could be; what it
## could not have said is nothing, and a name no card has deals nothing.
func test_unlocks_off_the_wire_are_cleaned() -> void:
	assert_array(Array(Loyalty.clean_unlocks(null)["jokers"])).is_empty()
	assert_array(Array(Loyalty.clean_unlocks({"jokers": "wild_card"})["jokers"])).is_empty()
	var many := []
	for i: int in 500:
		many.append("card_%d" % i)
	many.append(7)
	var cleaned := Loyalty.clean_unlocks({"jokers": many, "items": ["decoy_kart", "decoy_kart"]})
	assert_int(cleaned["jokers"].size()).is_equal(Loyalty.MOST_NAMES)
	assert_array(Array(cleaned["items"])).contains_exactly(["decoy_kart"])
	var deck := Loyalty.deck_from({"jokers": ["no_such_card", "payday"]}, JOKERS)
	assert_int(deck.size()).is_equal(28)


## A host keeps what a client it let in says its profile playing has added, and nothing from
## anybody else, and forgets it as the client goes.
func test_the_host_keeps_what_a_client_said() -> void:
	var session: NetSession = auto_free(NetSession.new())
	session.is_host = true
	var door := session.door
	var version := Game.version()
	var words := NetDoor.knock(version, false, "Ann", "")
	var room := {"no_seat": false, "players": 0, "humans": 1, "watchers": 0, "match": null}
	var answered := door.answer(version, 5, words, room)
	assert_bool(bool(answered["welcome"])).is_true()
	var jokers := PackedStringArray(["wild_card", "wild_card"])
	session.host_controls.keep_unlocks(5, jokers, PackedStringArray(["decoy_kart"]))
	session.host_controls.keep_unlocks(6, jokers, PackedStringArray())
	assert_array(Array(door.unlocks[5]["jokers"])).contains_exactly(["wild_card"])
	assert_array(Array(door.unlocks[5]["items"])).contains_exactly(["decoy_kart"])
	assert_bool(door.unlocks.has(6)).is_false()
	door.forget(5)
	assert_bool(door.unlocks.has(5)).is_false()


## A dedicated server's game deals the deck of whoever has the host's say there, and the next one's
## once the say is handed on; with nobody holding it, the starting deck.
func test_a_dedicated_server_deals_the_says_deck() -> void:
	var session: NetSession = auto_free(NetSession.new())
	Net.session = session
	session.door.unlocks[5] = Loyalty.clean_unlocks({"jokers": ["wild_card"]})
	session.door.unlocks[7] = Loyalty.clean_unlocks({"jokers": ["payday", "aimbot"]})
	session.host_controls.peer = 5
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	Loyalty.deal_table(match_node, ALL_ITEMS, true)
	assert_bool(&"wild_card" in match_node.joker_catalog.deck).is_true()
	assert_int(match_node.joker_catalog.deck.size()).is_equal(28)
	session.host_controls.peer = 7
	Loyalty.deal_table(match_node, ALL_ITEMS, true)
	assert_bool(&"wild_card" in match_node.joker_catalog.deck).is_false()
	assert_int(match_node.joker_catalog.deck.size()).is_equal(29)
	session.host_controls.peer = 0
	Loyalty.deal_table(match_node, ALL_ITEMS, true)
	assert_int(match_node.joker_catalog.deck.size()).is_equal(27)
	assert_array(_ids(match_node.power_ups)).is_equal(_ids(FIRST_SET))


## The lobby offers the later set only once the program has added one of its items.
func test_the_lobby_offers_items_once_added() -> void:
	var column: VBoxContainer = auto_free(VBoxContainer.new())
	Game.settings.item_set = "all"
	var options := MatchOptions.add_to(column, Game.settings)
	assert_bool(options.items_option.get_parent().visible).is_false()
	assert_int(options.items_option.selected).is_zero()
	Game.settings.profile.loyalty.win(&"spread_and_swivel")
	var again: VBoxContainer = auto_free(VBoxContainer.new())
	options = MatchOptions.add_to(again, Game.settings)
	assert_bool(options.items_option.get_parent().visible).is_true()
	assert_int(options.items_option.selected).is_equal(1)


## A bet reads with its count as the map shows it.
func test_a_bet_reads_its_count() -> void:
	var drawn := Loyalty.map()
	var cases := {
		&"racing_stripes": "Drive 2.5 km",
		&"afterburn": "Burn 3 minutes of nitro",
		&"marksman": "Land 60% of 30 shots or more in one map",
		&"chip_trail": "Pick up 5,000 chips",
		&"clean_record": "A map of 3 minutes or more without dying",
		&"cursed_cards": "Cash out at ×10 mult or more",
	}
	for id: StringName in cases:
		var said := Loyalty.bet_of(drawn.landmark(id))
		assert_bool(said == cases[id]).override_failure_message(said).is_true()
	assert_str(Loyalty.thousands(1234567)).is_equal("1,234,567")
	assert_str(Loyalty.thousands(999)).is_equal("999")
