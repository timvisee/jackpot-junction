extends GdUnitTestSuite
## The timeline of Steam's game recording, GAME.md 10.8: every moment drawn as its table says, the
## moments of a map marked for the seats at this machine and nobody else, the match's own stretches
## opened and closed, the bar's color and words for each room, and a Grand Prix one game phase.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const PATH := "user://test_steam_timeline.cfg"
## Steam's own icons, as its client draws them: any of these, a color after it or not.
const STEAM_ICONS: Array[String] = [
	"achievement",
	"attack",
	"bolt",
	"bookmark",
	"bug",
	"cart",
	"caution",
	"chat",
	"checkmark",
	"chest",
	"circle",
	"combat",
	"completed",
	"crown",
	"death",
	"defend",
	"diamond",
	"edit",
	"effect",
	"explosion",
	"fix",
	"flag",
	"gem",
	"group",
	"heart",
	"info",
	"invalid",
	"minus",
	"pair",
	"person",
	"plus",
	"purchase",
	"question",
	"ribbon",
	"screenshot",
	"scroll",
	"square",
	"star",
	"starburst",
	"timer",
	"transfer",
	"triangle",
	"trophy",
	"view",
	"x",
]
const COLORS: Array[String] = [
	"white", "red", "orange", "yellow", "green", "blue", "purple", "brown", "gray"
]

var _steam: FakeSteam
var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_steam = FakeSteam.new()
	Store.steam = SteamStore.new(_steam)
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.player_names[0] = "Ann"


func after_test() -> void:
	Timeline.end_phase()
	Store.steam = null
	TimelineRecord.anywhere = false
	Story.final_hand_on = false
	Game.grand_prix = null
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## Every moment is drawn with one of Steam's own icons, its color after it or not, or one of the
## game's own uploaded to Steamworks; its priority is Steam's 0 to 1000 and its clip one of three.
func test_every_mark_is_drawn_with_an_icon_steam_has() -> void:
	for id: StringName in Timeline.MARKS:
		var drawn: Array = Timeline.MARKS[id]
		var icon: String = drawn[0]
		if icon.begins_with("jj_"):
			assert_array(Timeline.OWN_ICONS).contains([icon])
			continue
		assert_str(icon).starts_with("steam_")
		var parts := icon.trim_prefix("steam_").split("_")
		assert_array(STEAM_ICONS).contains([parts[0]])
		if parts.size() > 1:
			assert_array(COLORS).contains([parts[1]])
		assert_int(int(drawn[1])).is_between(0, 1000)
		assert_array([Timeline.CLIP_NONE, Timeline.CLIP_STANDARD, Timeline.CLIP_FEATURED]).contains(
			[drawn[2]]
		)
	for icon: String in Timeline.OWN_ICONS:
		var used := Timeline.MARKS.values().any(func(drawn: Array) -> bool: return drawn[0] == icon)
		assert_bool(used).override_failure_message("%s is never used" % icon).is_true()


## A moment goes to Steam with its icon, priority and clip; with no Steam it goes nowhere.
func test_a_mark_goes_to_steam_as_drawn() -> void:
	assert_int(Timeline.mark(&"royal_flush", "Royal Flush", "+3 mult")).is_greater(0)
	var marked: Dictionary = _steam.timeline[-1]
	assert_str(marked["title"]).is_equal("Royal Flush")
	assert_str(marked["description"]).is_equal("+3 mult")
	assert_str(marked["icon"]).is_equal("jj_royal_flush")
	assert_int(marked["priority"]).is_equal(850)
	assert_int(marked["clip"]).is_equal(Timeline.CLIP_FEATURED)
	Timeline.mark(&"placed", "Finished 2nd", "", Timeline.place_icon(2))
	assert_str(_steam.timeline[-1]["icon"]).is_equal("steam_2")
	Store.steam = null
	assert_int(Timeline.mark(&"kill", "Took out Bo")).is_equal(0)
	assert_int(_steam.timeline.size()).is_equal(2)


## A stretch marked whole ends now, begun as long ago as it lasted; one left open is closed by its
## handle.
func test_stretches_are_marked_whole_or_left_open() -> void:
	Timeline.span(&"winning_cash_out", "Cashed out 1,240 for the win", "", 2.5)
	var whole: Dictionary = _steam.timeline[-1]
	assert_float(whole["offset"]).is_equal(-2.5)
	assert_float(whole["lasting"]).is_equal(2.5)
	var handle := Timeline.open(&"last_call", "Last Call")
	assert_bool(_steam.timeline[-1]["open"]).is_true()
	Timeline.close(handle)
	assert_bool(_steam.timeline[-1]["open"]).is_false()
	Timeline.close(0)
	assert_int(_steam.calls.count("endRangeTimelineEvent %d 0.0" % handle)).is_equal(1)


## The bar's color and the words along it are told to Steam only when they change.
func test_mode_and_tooltip_are_told_once() -> void:
	Store.steam.timeline_mode(Timeline.PLAYING)
	Store.steam.timeline_mode(Timeline.PLAYING)
	Store.steam.timeline_tooltip("The Vault")
	Store.steam.timeline_tooltip("The Vault")
	Store.steam.timeline_tooltip("")
	assert_int(_steam.timeline_mode).is_equal(Timeline.PLAYING)
	assert_int(_steam.calls.count("setTimelineGameMode 1")).is_equal(1)
	assert_int(_steam.calls.count("setTimelineTooltip The Vault")).is_equal(1)
	assert_int(_steam.calls.count("clearTimelineTooltip")).is_equal(1)


## GAME.md 10.8's colors: a room going up is loading, a pause at this machine alone the menus, a
## match's lobby and podium and the waiting room waiting, the maps, the Garage and the school
## playing, and anywhere else the menus.
func test_each_room_colors_the_bar() -> void:
	var playing := Match.State.PLAYING
	assert_int(SteamTimeline.mode_for(Game.MATCH_SCENE, playing, true, false)).is_equal(
		Timeline.LOADING
	)
	assert_int(SteamTimeline.mode_for(Game.MATCH_SCENE, playing, false, true)).is_equal(
		Timeline.MENUS
	)
	for state: int in [Match.State.COUNTDOWN, playing, Match.State.OVERTIME]:
		assert_int(SteamTimeline.mode_for(Game.MATCH_SCENE, state, false, false)).is_equal(
			Timeline.PLAYING
		)
	for state: int in [Match.State.LOBBY, Match.State.RESULTS]:
		assert_int(SteamTimeline.mode_for(Game.MATCH_SCENE, state, false, false)).is_equal(
			Timeline.STAGING
		)
	assert_int(SteamTimeline.mode_for(Game.WAITING_SCENE, -1, false, false)).is_equal(
		Timeline.STAGING
	)
	for scene: String in [Game.GARAGE_SCENE, Game.TUTORIAL_SCENE, Game.DRIVING_SCHOOL_SCENE]:
		assert_int(SteamTimeline.mode_for(scene, -1, false, false)).is_equal(Timeline.PLAYING)
	assert_int(SteamTimeline.mode_for(Game.TITLE_SCENE, -1, false, false)).is_equal(Timeline.MENUS)


## The words along the timeline: the map and a Grand Prix's leg, the showdown by itself, the rooms
## between by name, and nothing in the menus.
func test_the_tooltip_says_the_map_and_leg() -> void:
	var leg := {"scene": Game.MATCH_SCENE, "map": &"vault", "leg": 2, "legs": 3}
	assert_str(SteamTimeline.tooltip_for(leg)).is_equal("The Vault · leg 2 of 3")
	var alone := {"scene": Game.MATCH_SCENE, "map": &"vault", "leg": 0, "legs": 0}
	assert_str(SteamTimeline.tooltip_for(alone)).is_equal("The Vault")
	var showdown := {"scene": Game.MATCH_SCENE, "map": ArenaMaps.SHOWDOWN, "leg": 3, "legs": 3}
	assert_str(SteamTimeline.tooltip_for(showdown)).is_equal(
		TimelineRecord.map_name(ArenaMaps.SHOWDOWN)
	)
	assert_str(SteamTimeline.tooltip_for({"scene": Game.WAITING_SCENE})).is_equal("Waiting room")
	assert_str(SteamTimeline.tooltip_for({"scene": Game.GARAGE_SCENE})).is_equal("Garage")
	assert_str(SteamTimeline.tooltip_for({"scene": Game.TITLE_SCENE})).is_empty()


## A Grand Prix is one game phase however many maps it has: begun once, each map tagged once, told
## how it went, and ended for the next one.
func test_a_grand_prix_is_one_phase() -> void:
	Timeline.begin_phase("jj1", ["Grand Prix", "Online"] as Array[String])
	Timeline.begin_phase("jj1", ["Grand Prix"] as Array[String])
	Timeline.phase_map("The Vault")
	Timeline.phase_map("Crossfire")
	Timeline.phase_map("The Vault")
	Timeline.phase_result(1, 4, "18 points")
	assert_int(_steam.phases.size()).is_equal(1)
	var phase: Dictionary = _steam.phases[0]
	assert_str(phase["id"]).starts_with("jj1-")
	(
		assert_array(phase["tags"])
		. is_equal(
			[
				["Mode", "Grand Prix"],
				["Mode", "Online"],
				["Maps", "The Vault"],
				["Maps", "Crossfire"],
				["Result", "Won"],
			]
		)
	)
	assert_str(phase["attributes"]["Score"]).is_equal("18 points · 1st of 4")
	Timeline.begin_phase("jj2", ["Single map"] as Array[String])
	assert_bool(_steam.phases[0]["open"]).is_false()
	assert_bool(_steam.phases[1]["open"]).is_true()
	Timeline.phase_result(3, 4, "900 points")
	assert_array(_steam.phases[1]["tags"]).contains([["Result", "3rd"]])
	Timeline.end_phase()
	Timeline.end_phase()
	assert_int(_steam.calls.count("endGamePhase")).is_equal(2)


## A kill of the seat here is marked, its death too; one between two bots is nobody's moment here.
func test_the_seats_here_have_their_kills_and_deaths_marked() -> void:
	var match_node := await _room()
	var record := _record(match_node)
	var bot := match_node.slots[1].display_name()
	record._on_kart_killed(1, 0, &"bullet")
	assert_str(_titles()[-1]).is_equal("Took out %s" % bot)
	assert_str(_steam.timeline[-1]["icon"]).is_equal("steam_attack")
	record._on_kart_killed(2, 1, &"bullet")
	assert_int(_steam.timeline.size()).is_equal(1)
	record._on_kart_killed(0, 1, &"bullet")
	assert_str(_titles()[-1]).is_equal("Taken out by %s" % bot)
	record._on_kart_killed(0, -1, &"pit")
	assert_str(_titles()[-1]).is_equal("Fell into a pit")


## On a shared screen each title says whose moment it was.
func test_a_shared_screen_names_whose_it_was() -> void:
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(0, 1), BotInput.new()
	]
	var match_node := await _room(inputs)
	var record := _record(match_node)
	record._on_flush_completed(1)
	var second := match_node.slots[1].display_name()
	assert_str(_titles()[-1]).is_equal("%s: Royal Flush" % second)


## The announcer's runs of kills and streaks of a seat here are marked, each its own way.
func test_the_announcers_calls_are_marked() -> void:
	var match_node := await _room()
	var record := _record(match_node)
	record._on_announced(0, "TRIPLE KILL")
	record._on_announced(0, "ON FIRE")
	record._on_announced(1, "DOUBLE KILL")
	assert_array(_titles()).is_equal(["Triple kill", "On fire"])
	assert_str(_steam.timeline[0]["icon"]).is_equal("steam_combat_red")
	assert_str(_steam.timeline[1]["description"]).is_equal("5 kills without dying")
	assert_str(_steam.timeline[1]["icon"]).is_equal("steam_bolt_orange")


## Three sevens are the sevens' own moment, any other three of a kind a smaller one, a pair none.
func test_slot_pulls_are_marked_by_what_they_show() -> void:
	var match_node := await _room()
	var record := _record(match_node)
	var seven := SlotPad.Face.SEVEN
	var bell := SlotPad.Face.BELL
	record._on_slot_spun(0, 0, 25, PackedByteArray([seven, seven, seven]))
	record._on_slot_paid(0, 0, 250)
	record._on_slot_spun(0, 0, 20, PackedByteArray([bell, bell, bell]))
	record._on_slot_paid(0, 0, 60)
	record._on_slot_spun(0, 0, 20, PackedByteArray([bell, bell, seven]))
	record._on_slot_paid(0, 0, 20)
	assert_array(_titles()).is_equal(["Three sevens · won 250", "Three bells · won 60"])
	assert_str(_steam.timeline[0]["icon"]).is_equal("jj_777")


## Last Call and overtime are stretches of the match for everybody here, closed by the whistle; a
## bounty on a seat here is its own stretch, closed once it is collected.
func test_the_clock_and_a_bounty_are_stretches() -> void:
	var match_node := await _room()
	var record := _record(match_node)
	record._on_bounty_called(0)
	record._on_state(Match.State.LAST_CALL)
	record._on_state(Match.State.OVERTIME)
	var open := _steam.timeline.filter(func(event: Dictionary) -> bool: return event.get("open"))
	(
		assert_array(open.map(func(event: Dictionary) -> String: return event["title"]))
		. is_equal(["Bounty on your head", "Overtime"])
	)
	record._on_bounty_claimed(1, 0, 150)
	match_node.state = Match.State.RESULTS
	record._on_state(Match.State.RESULTS)
	for event: Dictionary in _steam.timeline:
		assert_bool(event.get("open", false)).is_false()


## The whistle marks how the map went for the seat here: its place, by Steam's figure for it.
func test_the_whistle_marks_the_place() -> void:
	var match_node := await _room()
	var record := _record(match_node)
	match_node.slots[0].banked = 100
	match_node.slots[1].banked = 900
	match_node.slots[2].banked = 50
	match_node.slots[3].banked = 20
	record._on_state(Match.State.RESULTS)
	var map := TimelineRecord.map_name(match_node.rules.map)
	assert_str(_titles()[-1]).is_equal("Finished 2nd on %s" % map)
	assert_str(_steam.timeline[-1]["icon"]).is_equal("steam_2")
	match_node.slots[0].banked = 1000
	record._on_state(Match.State.RESULTS)
	assert_str(_titles()[-1]).is_equal("Won %s" % map)
	assert_str(_steam.timeline[-1]["icon"]).is_equal("steam_trophy_yellow")


## A cash-out that reaches the target is marked over its seconds on the Junction; any other as it
## ends.
func test_the_winning_cash_out_is_a_stretch() -> void:
	var match_node := await _room()
	var record := _record(match_node)
	var rules: MatchRules = match_node.rules.duplicate()
	rules.target_score = 3000
	match_node.rules = rules
	record._on_bank_started(0)
	record._clock += 2.0
	match_node.slots[0].banked = 500
	record._on_bank_completed(0, 100, 5.0, 500)
	assert_str(_titles()[-1]).is_equal("Banked 500")
	record._on_bank_started(0)
	record._clock += 3.0
	match_node.slots[0].banked = 3100
	record._on_bank_completed(0, 200, 13.0, 2600)
	assert_str(_titles()[-1]).is_equal("Cashed out 2,600 for the win")
	assert_float(_steam.timeline[-1]["lasting"]).is_equal_approx(3.0, 0.001)


## A room of [param inputs], or a player here and three bots, with a record of its moments for
## Steam's timeline.
func _room(inputs: Array[KartInput] = []) -> Match:
	if inputs.is_empty():
		inputs = [PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new(), BotInput.new()]
		inputs.append(BotInput.new())
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.joker_catalog = JOKERS
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, inputs.size())
	TimelineRecord.anywhere = true
	TimelineRecord.add_to(match_node, false)
	await _runner.simulate_frames(2, 17)
	_steam.timeline.clear()
	return match_node


func _record(match_node: Match) -> TimelineRecord:
	return match_node.get_node("TimelineRecord") as TimelineRecord


func _titles() -> Array:
	return _steam.timeline.map(func(event: Dictionary) -> String: return event["title"])
