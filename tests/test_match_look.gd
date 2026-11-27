extends GdUnitTestSuite
## The match settings for everybody else in an online game, GAME.md 9.6: the same pane, every row
## locked, showing the match as whoever chooses it has it, as they choose it, and who they are; and
## the host's room saying all of it as it is chosen.

const FreePorts := preload("res://tests/free_ports.gd")
const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")

var port := 0
var _runner: GdUnitSceneRunner
## The player's own settings, put aside: closing the host's choices saves them.
var _settings_were: Settings
## Every plan said, as [signal Events.match_planned] carries it.
var _said: Array[Array] = []


func before_test() -> void:
	port = FreePorts.take()
	Game.pending_config = MatchConfig.new()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_match_look.cfg"
	_said.clear()
	Events.match_planned.connect(_on_planned)


func after_test() -> void:
	Events.match_planned.disconnect(_on_planned)
	Game.pending_config = null
	get_tree().paused = false
	Net.close()
	Settings.remove_files(Game.settings.path)
	Game.settings = _settings_were


func _on_planned(summary: String, choosing: bool, house: bool) -> void:
	_said.append([summary, choosing, house, ReadyRoom.whole_plan(summary)])


## A room hosted here by Kit, its match settings up on the match's own rows.
func _host() -> Node3D:
	Game.pending_config.online = "host"
	Game.pending_config.port = port
	Game.pending_config.human_names = ["Kit"] as Array[String]
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	_runner = scene_runner(room)
	await _runner.simulate_frames(45, 17)
	if room.ready_room.everybody_ready.is_connected(room._begin):
		room.ready_room.everybody_ready.disconnect(room._begin)
	var pane: HostSettings = room.host_settings
	if pane.on_lobby():
		pane._lobby._back.pressed.emit()
	return room


## A plan as the host says it, for [param by], on [param map] for eight minutes to 5000.
func _a_plan(by: String, map: StringName) -> Dictionary:
	var chosen := MatchConfig.new()
	chosen.rounds = 0
	chosen.map = map
	chosen.duration = 480.0
	chosen.target_score = 5000
	var plan := MatchOptions.to_wire(chosen)
	plan.erase("house")
	plan["by"] = by
	return plan


## [param plan] as the summary of [signal Events.match_planned] carries it, see [method
## ReadyRoom.planned].
func _said_of(plan: Dictionary) -> String:
	return ReadyRoom.planned(MatchConfig.new(), [], plan)


## The host's room says the whole of the match, and who chooses it, as the rows change while it is
## chosen, a few times a second, and again once it has been; never the House's dealer models. The
## board still says it from the summary, which a game of 0.25.0 reads as ever.
func test_the_host_says_the_match_as_it_is_chosen() -> void:
	var room := await _host()
	var pane: HostSettings = room.host_settings
	assert_bool(pane.is_open()).is_true()
	pane.options.choose(false)
	pane.options.map_option.selected = 2
	pane.options.minutes_option.selected = MatchOptions.match_lengths().find(480)
	await _runner.simulate_frames(30, 17)
	assert_array(_said).is_not_empty()
	var live: Array = _said[-1]
	assert_bool(live[1]).is_true()
	var plan: Dictionary = live[3]
	assert_str(str(plan["map"])).is_equal(String(pane.options._map_id()))
	assert_int(int(plan["duration"])).is_equal(480)
	assert_str(str(plan["by"])).is_equal("Kit")
	assert_bool(plan.has("house")).is_false()
	# Nothing changing, nothing said again.
	var count := _said.size()
	await _runner.simulate_frames(30, 17)
	assert_int(_said.size()).is_equal(count)
	pane.close()
	await _runner.simulate_frames(2, 17)
	assert_bool(_said[-1][1]).is_false()
	assert_str(str(_said[-1][3]["map"])).is_equal(String(room.config.map))
	var named := ArenaMaps.NAMES[ArenaMaps.index_of(room.config.map)]
	assert_str(ReadyRoom.said_plan(_said[-1][0])).contains(named)


## Looked at, the match is shown as it was said, every row locked, saying who chooses it and
## whether they are still at it; Close puts it away and keeps nothing as this player's choice.
func test_a_look_at_the_match_changes_nothing() -> void:
	var room := await _host()
	var pane: HostSettings = room.host_settings
	pane.options.choose(false)
	pane.options.map_option.selected = 1
	pane.close()
	var kept := Game.settings.map
	var look := HostSettings.for_looking(room, null)
	look.look_at(_a_plan("Bo", ArenaMaps.IDS[3]), false)
	look.open()
	await _runner.simulate_frames(2, 17)
	var shown := MatchConfig.new()
	look.options.apply_to(shown)
	assert_str(String(shown.map)).is_equal(String(ArenaMaps.IDS[3]))
	assert_float(shown.duration).is_equal(480.0)
	assert_int(shown.target_score).is_equal(5000)
	for row: OptionButton in [
		look.options.map_option,
		look.options.minutes_option,
		look.options.target_option,
		look.options.bots_option,
		look.options.teams_option,
	]:
		assert_bool(row.disabled).override_failure_message(row.name).is_true()
	assert_bool(look.options.mode_picker.locked).is_true()
	assert_bool(look.options.small_maps_toggle.disabled).is_true()
	# The kind of game chosen still drawn as chosen, and nothing on the table says to press it.
	var quick := look.options.mode_picker.button(false)
	assert_object(quick.get_theme_stylebox(&"disabled")).is_same(
		quick.get_theme_stylebox(&"pressed")
	)
	var grand := look.options.mode_picker.button(true)
	assert_object(grand.get_theme_stylebox(&"disabled")).is_not_same(
		grand.get_theme_stylebox(&"pressed")
	)
	assert_str(look.options.table_strip._note.text).is_empty()
	assert_str(look._line.text).is_equal("Bo chooses the match.")
	assert_str(look._done.text).is_equal("Close")
	# Nothing to set: the cursor on Close.
	assert_object(get_viewport().gui_get_focus_owner()).is_same(look._done)
	look.look_at(_a_plan("Bo", ArenaMaps.IDS[3]), true)
	assert_str(look._line.text).is_equal("Bo is choosing the match.")
	look.look_at(_a_plan("", ArenaMaps.IDS[3]), false)
	assert_str(look._line.text).is_equal("The host chooses the match.")
	look.close()
	assert_bool(look.is_open()).is_false()
	assert_str(Game.settings.map).is_equal(kept)


## The room's look follows what it hears while it is up; the karts here held while it is up, as
## under any menu.
func test_the_look_follows_the_plan_heard() -> void:
	var room := await _host()
	room.host_settings.close()
	room._on_match_planned(_said_of(_a_plan("Bo", ArenaMaps.IDS[2])), false, false)
	room._look()
	var look: HostSettings = room.looking
	assert_bool(look.is_open()).is_true()
	assert_bool(room._menu_up()).is_true()
	assert_str(String(look.options._map_id())).is_equal(String(ArenaMaps.IDS[2]))
	room._on_match_planned(_said_of(_a_plan("Bo", ArenaMaps.IDS[4])), true, false)
	assert_object(room.looking).is_same(look)
	assert_str(String(look.options._map_id())).is_equal(String(ArenaMaps.IDS[4]))
	assert_str(look._line.text).is_equal("Bo is choosing the match.")
	look.close()
	await _runner.simulate_frames(2, 17)
	assert_bool(room._menu_up()).is_false()


## From a game that says only the summary, 0.25.0's, a look shows as much as the summary says, and
## the host as choosing it; nothing at all for no summary.
func test_a_summary_alone_is_looked_at_as_far_as_it_goes() -> void:
	var chosen := MatchConfig.new()
	chosen.map = ArenaMaps.IDS[3]
	chosen.duration = 480.0
	chosen.target_score = 5000
	var whole := ReadyRoom.whole_plan(ReadyRoom.planned(chosen))
	var shown := MatchConfig.new()
	MatchOptions.from_wire(shown, whole)
	assert_str(String(shown.map)).is_equal(String(ArenaMaps.IDS[3]))
	assert_float(shown.duration).is_equal(480.0)
	assert_int(shown.target_score).is_equal(5000)
	assert_bool(whole.has("by")).is_false()
	assert_dict(ReadyRoom.whole_plan("")).is_empty()
	assert_dict(ReadyRoom.whole_plan("Vault · 5 min")).is_empty()
