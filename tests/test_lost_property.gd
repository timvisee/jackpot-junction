extends GdUnitTestSuite
## Lost Property, GAME.md 8.9: the thing of each room on its floor once its landmark is open, on an
## even chance a map and for certain after two misses, in a spot of its own, taken by this
## machine's human karts only, found for the profile, and the Yard's hard hat gone off the hoarding;
## see [LostProperty].

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const YARD: ArenaLayout = preload("res://data/maps/crossfire.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const PATH := "user://test_lost_property.cfg"

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	var loyalty := Game.settings.profile.loyalty
	loyalty.welcomed = true
	loyalty.win(&"slip_road")


func after_test() -> void:
	LostProperty.anywhere = false
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## Opens the Yard's Lost Property: the roads to it won.
func _open_the_yard() -> void:
	for id: StringName in [&"racing_stripes", &"dashed_marks", &"lost_dice"]:
		Game.settings.profile.loyalty.win(id)


func _yard(inputs: Array[KartInput] = []) -> Match:
	if inputs.is_empty():
		inputs = [PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new()]
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = YARD
	match_node.joker_catalog = JOKERS
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, inputs.size())
	LostProperty.anywhere = true
	return match_node


## Each room's thing by its landmark, the driving school's too; nothing lost in the Garage.
func test_what_was_lost_where() -> void:
	assert_str(String(LostProperty.landmark_for(&"the_yard").id)).is_equal("lost_hard_hat")
	assert_str(String(LostProperty.landmark_for(&"workbench").id)).is_equal("lost_tape")
	assert_str(String(LostProperty.landmark_for(&"after_hours").id)).is_equal("lost_dice")
	assert_str(String(LostProperty.landmark_for(LostProperty.SCHOOL).id)).is_equal("lost_cone")
	assert_object(LostProperty.landmark_for(&"garage")).is_null()


## Lost for a profile once its landmark is open and until it is found; an even chance a map, and
## certain once it has missed two.
func test_lost_once_open_and_certain_after_two_misses() -> void:
	var profile := Game.settings.profile
	var hat := LostProperty.landmark_for(&"the_yard")
	assert_bool(LostProperty.due(profile, hat)).is_false()
	_open_the_yard()
	assert_bool(LostProperty.due(profile, hat)).is_true()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var up := 0
	for i: int in 200:
		up += 1 if LostProperty.turns_up(profile, hat, rng) else 0
	assert_int(up).is_between(70, 130)
	profile.loyalty.lost_waits["lost_hard_hat"] = 2
	for i: int in 20:
		assert_bool(LostProperty.turns_up(profile, hat, rng)).is_true()
	profile.loyalty.find(&"lost_hard_hat")
	assert_bool(LostProperty.due(profile, hat)).is_false()


## Its spot on a map is bare floor clear of everything a kart is sent to, the same every time.
func test_a_spot_of_its_own() -> void:
	var grid := YARD.parse()
	var spot := LostProperty.spot_on(grid, "lost_hard_hatcrossfire")
	assert_int(spot.x).is_greater_equal(0)
	assert_str(grid.glyph(spot)).is_equal(ArenaGrid.FLOOR)
	assert_bool(NoteDealer._clear(grid, spot)).is_true()
	assert_object(LostProperty.spot_on(grid, "lost_hard_hatcrossfire")).is_equal(spot)


## In a map of its room, certain, it lies on the floor; a bot driving over it leaves it; this
## machine's kart takes it, found for the profile, gone from the floor. A map it missed counts.
func test_taken_by_this_machines_kart_only() -> void:
	_open_the_yard()
	var profile := Game.settings.profile
	profile.loyalty.lost_waits["lost_hard_hat"] = LostProperty.CERTAIN_AFTER
	var match_node := _yard()
	var lost := LostProperty.add_to(match_node)
	await _runner.simulate_frames(4, 17)
	match_node.state = Match.State.PLAYING
	await _runner.simulate_frames(3, 17)
	assert_object(lost.thing).is_not_null()
	assert_bool(profile.loyalty.lost_waits.has("lost_hard_hat")).is_false()
	var bot := match_node.slots[1].kart
	bot.global_position = lost.thing.global_position
	await _runner.simulate_frames(2, 17)
	assert_bool(lost.taken).is_false()
	var mine := match_node.slots[0].kart
	mine.global_position = lost.thing.global_position
	await _runner.simulate_frames(2, 17)
	assert_bool(lost.taken).is_true()
	assert_bool(profile.loyalty.has_found(&"lost_hard_hat")).is_true()
	assert_object(lost.thing).is_null()


## A map it could have lain in and did not counts toward its being certain.
func test_a_miss_is_counted() -> void:
	_open_the_yard()
	var profile := Game.settings.profile
	var match_node := _yard()
	var lost := LostProperty.add_to(match_node)
	lost.chance = 0.0
	await _runner.simulate_frames(4, 17)
	match_node.state = Match.State.PLAYING
	await _runner.simulate_frames(3, 17)
	assert_object(lost.thing).is_null()
	assert_int(int(profile.loyalty.lost_waits.get("lost_hard_hat", 0))).is_equal(1)


## Once the Yard's Lost Property is open the hard hat has blown down off the hoarding.
func test_the_hard_hat_blows_down() -> void:
	var profile := Game.settings.profile
	assert_bool(RoomShell.hat_blown_down(profile)).is_false()
	_open_the_yard()
	assert_bool(RoomShell.hat_blown_down(profile)).is_true()
	profile.loyalty.find(&"lost_hard_hat")
	Loyalty.settle(profile)
	assert_bool(RoomShell.hat_blown_down(profile)).is_true()


## Each thing as it lies is built, by the name of its dress.
func test_each_thing_as_it_lies() -> void:
	for dress: String in ["Traffic cone", "Hard hat", "Tape measure", "Fuzzy dice"]:
		var thing: Node3D = auto_free(KartDress.lost(dress))
		assert_int(thing.get_child_count()).is_greater(0)
