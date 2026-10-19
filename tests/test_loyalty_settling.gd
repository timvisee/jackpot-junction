extends GdUnitTestSuite
## Settling the loyalty program, GAME.md 8.9: a bet met in a room is known there and then and
## stamped BET WON in the player's corner, a tick in pencil off the books; once the map is written
## down its settling is reported for the payout slip's page, the House's bets on the page and Kit's
## on a scrap taped over the slip; what a reward says by the story's stage; and the endorsements
## stamped on the license's back.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const PATH := "user://test_loyalty_settling.cfg"

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.player_names[0] = "Ann"
	var loyalty := Game.settings.profile.loyalty
	loyalty.welcomed = true
	loyalty.win(&"slip_road")
	Game.settings.save_to_disk()


func after_test() -> void:
	Story.override = -1
	LoyaltyRecord.anywhere = false
	MatchRecord.anywhere = false
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _room(hud := false) -> Match:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new()]
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.joker_catalog = JOKERS
	match_node.with_hud = hud
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, inputs.size())
	LoyaltyRecord.add_to(match_node)
	LoyaltyRecord.anywhere = true
	return match_node


## What a reward says as it is paid by the story's stage, STORY.md 6.6b.
func test_what_a_reward_says_by_stage() -> void:
	var map := Loyalty.map()
	var visor := map.landmark(&"dealers_visor")
	var cards := map.landmark(&"rare_cards")
	var items := map.landmark(&"spread_and_swivel")
	assert_str(Loyalty.reward_words(visor, Story.Stage.CUSTOMER)).is_equal("REWARD ISSUED")
	assert_str(Loyalty.reward_words(visor, Story.Stage.OPERATOR)).is_equal("STAFF ISSUE")
	assert_str(Loyalty.reward_words(cards, Story.Stage.PARTICIPANT)).is_equal(
		"NEW JOKERS IN THE DECK"
	)
	assert_str(Loyalty.reward_words(cards, Story.Stage.CANDIDATE)).contains("NEW TERMS AUTHORIZED")
	assert_str(Loyalty.reward_words(items, Story.Stage.CUSTOMER)).is_equal(
		"NEW POWER-UPS ON YOUR TABLE"
	)


## A statistic as it will be once what a slot has done in the room since it was last written is
## added: counts added, bests the higher.
func test_a_statistic_counted_live() -> void:
	var match_node := _room()
	await _runner.simulate_frames(2, 17)
	var profile := Game.settings.profile
	var slot := match_node.slots[0]
	profile.stats[&"banks"] = 20.0
	profile.stats[&"biggest_bank"] = 300.0
	slot.stats.add(&"banks", 6.0)
	slot.stats.peak(&"biggest_bank", 420.0)
	var since := MatchRecord.since_of(match_node, slot)
	assert_float(LifetimeStats.live_value(profile, slot, &"banks", since)).is_equal(26.0)
	assert_float(LifetimeStats.live_value(profile, slot, &"biggest_bank", since)).is_equal(420.0)
	assert_float(LifetimeStats.live_value(profile, slot, &"maps", since)).is_equal(0.0)


## An open bet whose count the room takes past its bet is BET WON there and then, once, though the
## landmark is won as the room is written down; a closed one is not, nor one of a profile not yet
## welcomed to the program.
func test_a_bet_met_in_a_room_is_known_there_and_then() -> void:
	var match_node := _room()
	var record := match_node.get_node("LoyaltyRecord") as LoyaltyRecord
	var heard: Array[StringName] = []
	record.bet_won.connect(
		func(_slot: int, landmark: LoyaltyLandmark) -> void: heard.append(landmark.id)
	)
	await _runner.simulate_frames(2, 17)
	var profile := Game.settings.profile
	profile.stats[&"banks"] = 24.0
	profile.stats[&"coins"] = 9000.0
	match_node.slots[0].stats.add(&"banks", 1.0)
	await _runner.simulate_frames(20, 17)
	assert_array(heard).contains([&"dealers_visor"])
	# Chip Alley's 5,000 chips are met too, but it is closed until the Cashier's Cage is won.
	assert_array(heard).not_contains([&"chip_trail"])
	assert_bool(profile.loyalty.has_won(&"dealers_visor")).is_false()
	match_node.slots[0].stats.add(&"banks", 1.0)
	await _runner.simulate_frames(20, 17)
	assert_int(heard.count(&"dealers_visor")).is_equal(1)


## The settling reported once the map is written down: the House's bets won, Kit's apart, and the
## open bets come nearer, nearest first; nothing for a profile not welcomed.
func test_the_settling_is_reported() -> void:
	var match_node := _room()
	var record := match_node.get_node("LoyaltyRecord") as LoyaltyRecord
	await _runner.simulate_frames(2, 17)
	var profile := Game.settings.profile
	profile.story.on = true
	profile.story.notes = PackedInt32Array([1, 2, 3])
	record._found(profile)
	profile.stats[&"banks"] = 30.0
	profile.stats[&"driven"] = 1200.0
	Loyalty.settle(profile)
	var reports: Array[Array] = []
	record.reported.connect(func(report: Array[Dictionary]) -> void: reports.append(report))
	LoyaltyRecord.settled(match_node, [profile])
	assert_int(reports.size()).is_equal(1)
	var line: Dictionary = record.report[0]
	assert_str(str(line["name"])).is_equal("Ann")
	assert_array(_ids(line["won"])).contains([&"dealers_visor"])
	assert_array(_ids(line["kit"])).contains([&"pencil_trail"])
	assert_array(_ids(line["won"])).not_contains([&"pencil_trail"])
	assert_array(_ids(line["nearer"])).contains([&"racing_stripes"])
	profile.loyalty.welcomed = false
	LoyaltyRecord.settled(match_node, [profile])
	assert_array(record.report).is_empty()


## The program's page prints the House's bets won and the nearest, and is no page with nothing of
## the House's; Kit's scrap is taped over a page, over its top, taking no room in it.
func test_the_slip_page_and_kits_scrap() -> void:
	var map := Loyalty.map()
	var profile := Game.settings.profile
	var report: Array[Dictionary] = [
		{
			"profile": profile,
			"name": "Ann",
			"won": [map.landmark(&"dealers_visor")],
			"kit": [map.landmark(&"pencil_trail")],
			"nearer": [map.landmark(&"racing_stripes")],
		}
	]
	var page: LoyaltySlipPage = auto_free(LoyaltySlipPage.create())
	add_child(page)
	assert_bool(page.fill(report)).is_true()
	assert_str(page.heading.text).is_equal("Loyalty Program")
	var won := 0
	for child: Node in page.rows.get_children():
		won += 1 if child is LoyaltySlipPage.WonLine else 0
	assert_int(won).is_equal(1)
	# A bet come nearer can be pinned from the slip, and again unpinned.
	var near: LoyaltySlipPage.NearLine = null
	for child: Node in page.rows.get_children():
		if child is LoyaltySlipPage.NearLine:
			near = child
	assert_object(near).is_not_null()
	await get_tree().process_frame
	assert_bool(near.pin.visible).is_true()
	near.pin.pressed.emit()
	assert_str(String(profile.loyalty.pinned)).is_equal("racing_stripes")
	assert_str(near.pin.tooltip_text).is_equal(LoyaltyPane.PINNED)
	near.pin.pressed.emit()
	assert_str(String(profile.loyalty.pinned)).is_empty()
	# The line says what the bet paid, by name, not only that something was.
	assert_str(LoyaltySlipPage.paid_words(map.landmark(&"dealers_visor"))).contains(
		"Dealer's visor"
	)
	var only_kit: Array[Dictionary] = [
		{
			"profile": profile,
			"name": "Ann",
			"won": [],
			"kit": [map.landmark(&"pencil_trail")],
			"nearer": [],
		}
	]
	assert_bool(page.fill(only_kit)).is_false()
	var lines := LoyaltySlipPage.kit_lines(report)
	assert_array(Array(lines)).is_equal(["pencils"])
	LoyaltySlipPage.tape_onto(page, lines)
	await get_tree().process_frame
	var tape := page.get_node("Tape") as Control
	assert_object(tape).is_not_null()
	assert_float(tape.size.y).is_equal(0.0)
	assert_object(tape.get_node("Scrap")).is_not_null()
	LoyaltySlipPage.tape_onto(page, PackedStringArray())
	assert_object(page.get_node_or_null("Tape")).is_null()
	# At the foot of the program's own page: last, in room of its own, under its heading.
	LoyaltySlipPage.tape_onto(page, lines, true)
	await get_tree().process_frame
	tape = page.get_node("Tape") as Control
	assert_int(tape.get_index()).is_equal(page.get_child_count() - 1)
	var scrap := tape.get_node("Scrap") as LoyaltySlipPage.KitScrap
	assert_float(tape.size.y).is_greater_equal(scrap.tall())
	assert_float(tape.position.y).is_greater(page.heading.position.y + page.heading.size.y)


## The four Department bets that are endorsements stamp the license's back once won, in the map's
## order.
func test_the_endorsements_on_the_license() -> void:
	var profile := Game.settings.profile
	assert_array(Array(Loyalty.endorsements_of(profile))).is_empty()
	profile.loyalty.win(&"marksman")
	profile.loyalty.win(&"chalk_marks")
	assert_array(Array(Loyalty.endorsements_of(profile))).is_equal(["DRIFT", "MARKSMAN"])
	Game.settings.license_number = "JJ-123456"
	var card: LicenseCard = auto_free(LicenseCard.from_settings())
	assert_array(Array(card.program_stamps)).is_equal(["DRIFT", "MARKSMAN"])


## BET WON goes to the player's corner, beside their block; a bet off the books is a tick on a
## scrap; each is gone after its two seconds.
func test_the_stamp_in_the_corner() -> void:
	var hud := Control.new()
	hud.size = Vector2(1920.0, 1080.0)
	add_child(hud)
	var block := Control.new()
	block.name = "Block0"
	block.position = Vector2(20.0, 20.0)
	block.size = Vector2(300.0, 90.0)
	hud.add_child(block)
	var map := Loyalty.map()
	var house := LoyaltyStamp.show_beside(hud, 0, map.landmark(&"dealers_visor"))
	var kit := LoyaltyStamp.show_beside(hud, 0, map.landmark(&"pencil_trail"))
	assert_object(house.size).is_equal(LoyaltyStamp.SIZE)
	assert_object(kit.size).is_equal(LoyaltyStamp.SCRAP)
	for i: int in 3:
		await get_tree().process_frame
	assert_float(house._corner().x).is_greater_equal(block.position.x + block.size.x)
	assert_float(kit._corner().x).is_greater(house._corner().x)
	house._age = LoyaltyStamp.LASTS
	kit._age = LoyaltyStamp.LASTS
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(is_instance_valid(house)).is_false()
	hud.free()


func _ids(landmarks: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for each: LoyaltyLandmark in landmarks:
		ids.append(each.id)
	return ids
