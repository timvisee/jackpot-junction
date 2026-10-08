extends GdUnitTestSuite
## The catalog of GAME.md 8.8: what a profile keeps of every joker and power-up it took, and who
## writes it, see [CatalogState] and [CatalogRecord].

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const POWER_UPS: PowerUpTable = preload("res://data/powerups/all.tres")
const PATH := "user://test_catalog.cfg"

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
	CatalogRecord.anywhere = false
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## A joker or an item taken is counted every time, and the first time it is fresh until the catalog
## has looked at it.
func test_a_take_is_counted_and_fresh_until_looked_at() -> void:
	var catalog := CatalogState.new()
	assert_bool(catalog.found(&"payday")).is_false()
	assert_bool(catalog.take_joker(&"payday")).is_true()
	assert_bool(catalog.take_joker(&"payday")).is_false()
	assert_bool(catalog.use_item(&"bomb")).is_true()
	assert_int(catalog.times(&"payday")).is_equal(2)
	assert_int(catalog.times(&"bomb")).is_equal(1)
	assert_bool(catalog.is_fresh(&"payday")).is_true()
	assert_bool(catalog.look_at(&"payday")).is_true()
	assert_bool(catalog.look_at(&"payday")).is_false()
	assert_bool(catalog.is_fresh(&"payday")).is_false()
	assert_bool(catalog.is_fresh(&"bomb")).is_true()
	# Taken again after being looked at, it is not new any more.
	catalog.take_joker(&"payday")
	assert_bool(catalog.is_fresh(&"payday")).is_false()
	assert_bool(catalog.take_joker(&"")).is_false()
	assert_bool(catalog.found(&"")).is_false()


## What a profile keeps reads back as it was written, and ids this version does not know are kept
## for one that does, though never counted among the ones it has.
func test_the_section_reads_back_and_keeps_unknown_ids() -> void:
	var file := ConfigFile.new()
	var catalog := CatalogState.new()
	catalog.take_joker(&"payday")
	catalog.take_joker(&"payday")
	catalog.take_joker(&"from_the_future")
	catalog.use_item(&"shield")
	catalog.look_at(&"shield")
	catalog.write(file)
	var read := CatalogState.new()
	read.read(file)
	assert_int(read.times(&"payday")).is_equal(2)
	assert_int(read.times(&"from_the_future")).is_equal(1)
	assert_int(read.times(&"shield")).is_equal(1)
	assert_bool(read.is_fresh(&"payday")).is_true()
	assert_bool(read.is_fresh(&"shield")).is_false()
	var ids: Array[StringName] = [&"payday", &"vulture"]
	assert_int(read.found_of(ids)).is_equal(1)
	# Whatever else a file holds is not a count.
	file.set_value(
		CatalogState.SECTION, "jokers", {"payday": "lots", "vulture": -2, 3: 1, "aimbot": 4}
	)
	file.set_value(CatalogState.SECTION, "fresh", 7)
	read.read(file)
	assert_bool(read.found(&"payday")).is_false()
	assert_bool(read.found(&"vulture")).is_false()
	assert_int(read.times(&"aimbot")).is_equal(4)
	assert_int(read.fresh.size()).is_zero()


## 0.14.1 counted power-ups as they were picked up; those counts are left behind, since only a
## power-up used counts, and none of them is new.
func test_power_ups_picked_up_in_0_14_1_are_left_behind() -> void:
	var file := ConfigFile.new()
	file.set_value(CatalogState.SECTION, "jokers", {"payday": 1})
	file.set_value(CatalogState.SECTION, "items", {"bomb": 2})
	file.set_value(CatalogState.SECTION, "fresh", PackedStringArray(["bomb", "payday"]))
	var read := CatalogState.new()
	read.read(file)
	assert_bool(read.found(&"bomb")).is_false()
	assert_bool(read.is_fresh(&"bomb")).is_false()
	assert_bool(read.is_fresh(&"payday")).is_true()
	var written := ConfigFile.new()
	read.write(written)
	assert_bool(written.has_section_key(CatalogState.SECTION, "items")).is_false()


## The biggest stack held of a joker is kept, from the hand at the seat, however late the card
## comes into it after the word it was taken, as a client's does; one taken alone is a stack of one.
func test_the_biggest_stack_held_is_kept() -> void:
	var catalog := CatalogState.new()
	assert_int(catalog.best_stack(&"payday")).is_zero()
	catalog.take_joker(&"payday")
	assert_int(catalog.best_stack(&"payday")).is_equal(1)
	assert_bool(catalog.hold(&"payday", 2)).is_true()
	assert_bool(catalog.hold(&"payday", 1)).is_false()
	assert_int(catalog.best_stack(&"payday")).is_equal(2)
	var file := ConfigFile.new()
	catalog.write(file)
	var read := CatalogState.new()
	read.read(file)
	assert_int(read.best_stack(&"payday")).is_equal(2)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0)]
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 4)
	CatalogRecord.add_to(match_node)
	CatalogRecord.anywhere = true
	await _runner.simulate_frames(2, 17)
	var hand := match_node.slots[0].kart.jokers
	var payday: Joker = JOKERS.by_id(&"payday")
	hand.add(payday)
	Events.joker_taken.emit(0, &"payday")
	var mine := Game.settings.profile.catalog
	assert_int(mine.best_stack(&"payday")).is_equal(1)
	# The second copy comes into the hand after the word, as a client's does off the floor.
	Events.joker_taken.emit(0, &"payday")
	hand.add(payday)
	assert_int(mine.best_stack(&"payday")).is_equal(2)


## The profile keeps it in its file, and a profile from before the catalog starts it empty.
func test_the_profile_keeps_its_catalog() -> void:
	var profile := Game.settings.profile
	assert_int(profile.catalog.jokers.size()).is_zero()
	profile.catalog.take_joker(&"wild_card")
	profile.catalog.use_item(&"turret")
	Game.settings.save_to_disk()
	var kept := Profile.at(Game.settings.profiles_dir(), profile.id)
	assert_int(kept.catalog.times(&"wild_card")).is_equal(1)
	assert_int(kept.catalog.times(&"turret")).is_equal(1)


## Jokers and items share the profile's list of fresh ids, so no joker is called what an item is.
func test_no_joker_shares_an_id_with_an_item() -> void:
	for item: PowerUp in POWER_UPS.entries:
		assert_object(JOKERS.by_id(item.id)).is_null()


## A take goes into the profile of the seat it was taken at, the profile playing's at the first, the
## linked profile's at another, and a guest's and a bot's nowhere; a test's room keeps nothing, and
## what a room keeps is written as it is left, before the seats are guests again.
func test_a_take_goes_into_the_profile_at_its_seat() -> void:
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
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 4)
	var record := CatalogRecord.add_to(match_node)
	await _runner.simulate_frames(2, 17)
	Events.joker_taken.emit(0, &"payday")
	assert_bool(Game.settings.profile.catalog.found(&"payday")).is_false()
	CatalogRecord.anywhere = true
	Events.joker_taken.emit(0, &"payday")
	Events.item_used.emit(0, &"bomb")
	Events.joker_taken.emit(1, &"vulture")
	Events.item_used.emit(1, &"shield")
	# Picked up is not used: a power-up counts once it has been.
	Events.item_picked.emit(0, &"turret")
	Events.joker_taken.emit(2, &"aimbot")
	Events.joker_taken.emit(3, &"aimbot")
	Events.joker_taken.emit(9, &"aimbot")
	var ann := Game.settings.profile.catalog
	assert_int(ann.times(&"payday")).is_equal(1)
	assert_int(ann.times(&"bomb")).is_equal(1)
	assert_bool(ann.found(&"turret")).is_false()
	assert_bool(ann.found(&"vulture")).is_false()
	assert_bool(ann.found(&"aimbot")).is_false()
	var linked := Game.settings.seat_profile(1).catalog
	assert_int(linked.times(&"vulture")).is_equal(1)
	assert_int(linked.times(&"shield")).is_equal(1)
	assert_bool(linked.found(&"payday")).is_false()
	get_tree().call_group(MatchRecord.GROUP, &"leave")
	Game.settings.unlink_all()
	assert_int(Profile.at(Game.settings.profiles_dir(), bob.id).catalog.times(&"vulture")).is_equal(
		1
	)
	var mine := Profile.at(Game.settings.profiles_dir(), Game.settings.profile.id)
	assert_int(mine.catalog.times(&"bomb")).is_equal(1)
	# Taken out of the tree, the room hears nothing more.
	match_node.remove_child(record)
	Events.joker_taken.emit(0, &"payday")
	assert_int(ann.times(&"payday")).is_equal(1)
	record.free()


## GAME.md 7.1: every item says what it does in a sentence without numbers, and its numbers are its
## facts, read from the item itself.
func test_every_item_has_a_sentence_and_facts_of_its_own_numbers() -> void:
	var digits := RegEx.create_from_string("[0-9]")
	for item: PowerUp in POWER_UPS.entries:
		assert_str(item.description).is_not_empty()
		assert_object(digits.search(item.description)).is_null()
		assert_bool(item.description.ends_with(".")).is_true()
		assert_int(item.facts().size()).is_greater(0)
		for line: PackedStringArray in item.facts():
			assert_int(line.size()).is_equal(2)
	var boost: BoostPowerUp = load("res://data/powerups/boost.tres").duplicate()
	boost.duration = 4.5
	boost.speed_multiplier = 1.25
	var said := boost.facts()
	assert_array(said[0]).contains_exactly(["Lasts", "4.5 s"])
	assert_array(said[1]).contains_exactly(["Top speed", "+25%"])
	assert_array(said[2]).contains_exactly(["Steering", "-20%"])
