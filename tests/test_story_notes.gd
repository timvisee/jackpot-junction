extends GdUnitTestSuite
## Kit's notes on the table, STORY.md 7.1: when each is due and whether it turns up, where it lies,
## and who can take it, which is this machine's humans and nobody else, with nothing of it on the
## wire.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner
var _profile := Profile.new()
var _was_number := ""
var _was_story := StoryState.new()


func before_test() -> void:
	_profile = Game.settings.profile
	_was_number = _profile.license_number
	_was_story = _profile.story
	_profile.story = StoryState.new()
	_profile.license_number = "JJ-212212"


func after_test() -> void:
	_profile.license_number = _was_number
	_profile.story = _was_story
	NoteDealer.anywhere = false
	Story.note_now = 0


func _profile_at(seconds: float, found: Array[int] = []) -> Profile:
	var profile := Profile.new()
	profile.license_number = "JJ-212212"
	profile.story.seconds = seconds
	profile.story.notes = PackedInt32Array(found)
	return profile


## The first note, the player's own stub, is due on the first map after the license, a quick
## match's or a Grand Prix's; none before the license or with the story off.
func test_the_first_note_is_the_first_maps_after_the_license() -> void:
	var profile := _profile_at(0.0)
	assert_int(StoryNotes.due(profile)).is_equal(1)
	assert_str(String(StoryNotes.key_of(1))).is_equal("stub")
	profile.story.on = false
	assert_int(StoryNotes.due(profile)).is_equal(0)
	profile.story.on = true
	profile.license_number = ""
	assert_int(StoryNotes.due(profile)).is_equal(0)


## A stage's notes are spread across it; after the ending one every ten minutes, the Final Hand's
## first if it was missed there; and never one before the one before it is found.
func test_the_notes_are_spread_across_their_stages_and_come_in_order() -> void:
	var story := StoryState.new()
	assert_float(StoryNotes.due_at(2, story)).is_equal(300.0)
	assert_float(StoryNotes.due_at(5, story)).is_equal(1065.0)
	assert_float(StoryNotes.due_at(6, story)).is_equal(1320.0)
	assert_float(StoryNotes.due_at(10, story)).is_equal_approx(2424.0, 0.01)
	assert_float(StoryNotes.due_at(16, story)).is_equal(4320.0)
	assert_float(StoryNotes.due_at(20, story)).is_equal_approx(5664.0, 0.01)
	# About one a map of five minutes, from the first to the Final Hand's.
	for number: int in range(2, Story.FINAL_HAND_NOTE):
		var gap := StoryNotes.due_at(number, story) - StoryNotes.due_at(number - 1, story)
		if number > 2:
			assert_float(gap).override_failure_message(str(number)).is_between(200.0, 400.0)
	story.final_seconds = 6100.0
	assert_float(StoryNotes.due_at(21, story)).is_equal(6100.0)
	assert_float(StoryNotes.due_at(22, story)).is_equal(6700.0)
	assert_float(StoryNotes.due_at(24, story)).is_equal(7900.0)
	# In order, whatever the clock says.
	assert_int(StoryNotes.due(_profile_at(5000.0, [1, 2]))).is_equal(3)
	assert_int(StoryNotes.due(_profile_at(200.0, [1]))).is_equal(0)
	assert_int(StoryNotes.due(_profile_at(400.0, [1]))).is_equal(2)
	# The Final Hand's only at the Final Hand, then after the ending before the Operator's.
	var all: Array[int] = []
	for number: int in range(1, 21):
		all.append(number)
	var waiting := _profile_at(5900.0, all)
	assert_int(StoryNotes.due(waiting)).is_equal(0)
	waiting.story.final_hand = "2026-10-07"
	waiting.story.final_seconds = 5900.0
	assert_int(StoryNotes.due(waiting)).is_equal(21)
	StoryNotes.file(waiting, 21)
	assert_int(StoryNotes.due(waiting)).is_equal(0)
	waiting.story.seconds = 6500.0
	assert_int(StoryNotes.due(waiting)).is_equal(22)


## A profile keeps its notes by their keys, STORY.md 5.2, not their places in the story, so a later
## version can add notes anywhere: a note earlier than the last one found and not found itself is
## filed new as the file is read, so a profile whose order moved under it reads what it missed; a
## file from before the keys reads its numbers in the order they had then; and a key this version
## does not know, or no longer has, is kept for the version that does.
func test_the_notes_found_are_kept_by_key_gaps_and_all() -> void:
	assert_int(StoryNotes.KEYS.size()).is_equal(Story.NOTE_COUNT)
	var unique := {}
	for key: StringName in StoryNotes.KEYS:
		unique[key] = true
	assert_int(unique.size()).is_equal(Story.NOTE_COUNT)
	var story := StoryState.new()
	story.notes = PackedInt32Array([1, 2, 3])
	story.notes_read = PackedInt32Array([1])
	var file := ConfigFile.new()
	story.write(file)
	assert_array(Array(file.get_value(StoryState.SECTION, "notes"))).is_equal(
		["stub", "inspection", "table_one"]
	)
	var again := StoryState.new()
	again.read(file)
	assert_array(Array(again.notes)).is_equal([1, 2, 3])
	assert_array(Array(again.notes_read)).is_equal([1])
	assert_int(StoryNotes.next_of(again)).is_equal(4)
	# Found before the story was retold, with gaps the new order made: the gaps are filed, new.
	file.set_value(
		StoryState.SECTION, "notes", PackedStringArray(["opening_night", "rota", "now_enrolling"])
	)
	file.set_value(StoryState.SECTION, "notes_read", PackedStringArray(["opening_night"]))
	again.read(file)
	assert_array(Array(again.notes)).is_equal([4, 5, 1, 2, 3])
	assert_bool(again.is_new(1)).is_true()
	assert_bool(again.is_new(4)).is_false()
	assert_int(StoryNotes.next_of(again)).is_equal(6)
	# A note taken out of the story is kept as it was, for a version that still has it.
	var saved := ConfigFile.new()
	again.write(saved)
	assert_array(Array(saved.get_value(StoryState.SECTION, "notes"))).has_size(6)
	assert_array(Array(saved.get_value(StoryState.SECTION, "notes"))).contains(["now_enrolling"])
	# A file from before the keys: its numbers in the order they had then.
	file.set_value(StoryState.SECTION, "notes", PackedInt32Array([1, 3]))
	again.read(file)
	assert_bool(again.has_note(StoryNotes.number_of(&"opening_night"))).is_true()
	assert_bool(again.has_note(StoryNotes.number_of(&"application"))).is_true()
	assert_int(StoryNotes.next_of(again)).is_equal(StoryNotes.number_of(&"application") + 1)
	# A note from a later version, unknown here, kept as it was.
	file.set_value(StoryState.SECTION, "notes", PackedStringArray(["stub", "a_later_note"]))
	again.read(file)
	assert_array(Array(again.notes)).is_equal([1])
	saved = ConfigFile.new()
	again.write(saved)
	assert_array(Array(saved.get_value(StoryState.SECTION, "notes"))).is_equal(
		["stub", "a_later_note"]
	)


## Before the ending a due note turns up in its first map; after it, it is a coin toss in a map
## until it has missed two, then certain. It turns up between twenty seconds in and a minute before
## the end, or in the middle half of a short map, the first note no later than a minute in.
func test_a_due_note_turns_up_by_chance_then_for_certain_inside_the_clock() -> void:
	var story := StoryState.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in 100:
		assert_bool(StoryNotes.turns_up(story, rng)).is_true()
	story.final_hand = "2026-10-16"
	var up := 0
	for i: int in 1000:
		if StoryNotes.turns_up(story, rng):
			up += 1
	assert_int(up).is_between(430, 570)
	story.note_waits = Story.NOTE_CERTAIN_AFTER
	for i: int in 50:
		assert_bool(StoryNotes.turns_up(story, rng)).is_true()
	for i: int in 200:
		assert_float(StoryNotes.moment(300.0, rng)).is_between(20.0, 240.0)
		assert_float(StoryNotes.moment(60.0, rng)).is_between(15.0, 45.0)
		assert_float(StoryNotes.moment(300.0, rng, true)).is_between(20.0, 60.0)
	# The F3 overlay says which note is next and when.
	assert_str(Story.debug_text()).contains("next note 1 in map 1")
	Game.settings.profile.story.notes = PackedInt32Array([1])
	assert_str(Story.debug_text()).contains("next note 2 at 5 min")
	# Filing it starts the count again.
	var profile := _profile_at(0.0)
	profile.story.note_waits = 2
	StoryNotes.file(profile, 1)
	assert_int(profile.story.note_waits).is_equal(0)
	assert_bool(profile.story.is_new(1)).is_true()


## On every map a note lies on bare floor a kart can reach, with nothing it is sent to or falls down
## beside it and no pit within two cells.
func test_a_note_lies_on_open_floor_on_every_map() -> void:
	var rng := RandomNumberGenerator.new()
	for id: StringName in ArenaMaps.IDS:
		var grid: ArenaGrid = ArenaMaps.layout(id).parse()
		var home := grid.region_of(grid.spawns[0])
		for seed: int in 40:
			rng.seed = seed
			var cell := NoteDealer.spot_on(grid, rng)
			assert_int(cell.x).override_failure_message(String(id)).is_greater_equal(0)
			assert_str(grid.glyph(cell)).is_equal(ArenaGrid.FLOOR)
			assert_int(grid.region_of(cell)).is_equal(home)
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					var glyph := grid.glyph(cell + Vector2i(dx, dy))
					assert_str(glyph).override_failure_message(String(id)).is_not_equal(
						ArenaGrid.PIT
					)
					if absi(dx) <= 1 and absi(dy) <= 1:
						assert_bool(glyph in NoteDealer.AVOID).is_false()


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 300.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0), BotInput.new()]
	match_node.start(inputs, 41)
	return match_node


## A bot driving over a note leaves it; the player's kart takes it, which files it for the profile
## playing and puts the pencil scrap up in that player's corner. The note was never a pickup and
## the floor the host sends never mentions it.
func test_only_this_machines_humans_take_a_note() -> void:
	NoteDealer.anywhere = true
	Story.note_now = 3
	var match_node := _start_match()
	var dealer := NoteDealer.add_to(match_node)
	for i: int in 200:
		await _runner.simulate_frames(1, 17)
		if dealer.note != null:
			break
	var note := dealer.note
	assert_object(note).is_not_null()
	assert_int(note.number).is_equal(3)
	# While it lies there, a scrap of its paper hangs beside the clock.
	var mark := dealer.mark
	assert_object(mark).is_not_null()
	assert_object(mark.get_parent()).is_same(match_node.hud.get_node("Clock"))
	assert_float(mark.position.x).is_greater(ClockBoard.TOP)
	assert_object(note.get_parent()).is_not_same(match_node.arena.pickups)
	assert_str(str(PickupWire.new().section(match_node)).to_lower()).not_contains("note")
	var bot := match_node.slots[1].kart
	bot.global_position = note.global_position
	await _runner.simulate_frames(3, 17)
	assert_bool(dealer.taken).is_false()
	assert_object(dealer.note).is_not_null()
	var player := match_node.slots[0].kart
	player.global_position = note.global_position
	await _runner.simulate_frames(3, 17)
	assert_bool(dealer.taken).is_true()
	assert_int(dealer.taken_by).is_equal(0)
	assert_bool(Game.settings.profile.story.has_note(3)).is_true()
	assert_object(match_node.hud.find_child("NoteCollected", true, false)).is_not_null()
	# Taken, the scrap stays beside the clock, ticked off, until the map is over.
	assert_object(dealer.mark).is_same(mark)
	assert_bool(mark.collected).is_true()
	assert_bool(mark.is_queued_for_deletion()).is_false()
	dealer._on_state(Match.State.RESULTS)
	assert_object(dealer.mark).is_null()
	assert_bool(mark.is_queued_for_deletion()).is_true()


## NOTE COLLECTED waits for a call of the announcer's already up, is written big under the middle
## of the screen, holds, and goes into the corner beside the player's block, STORY.md 7.1.
func test_note_collected_waits_for_a_call_and_goes_to_the_corner() -> void:
	var hud: Control = auto_free(Control.new())
	hud.size = Vector2(1920.0, 1080.0)
	add_child(hud)
	var call := Control.new()
	call.name = "Call"
	hud.add_child(call)
	var block := Control.new()
	block.position = Vector2(20.0, 860.0)
	block.size = Vector2(300.0, 160.0)
	hud.add_child(block)
	var scrap := NoteCollected.show_beside(hud, block)
	scrap._process(0.5)
	assert_int(scrap.phase).is_equal(NoteCollected.Phase.WAITING)
	assert_bool(scrap.visible).is_false()
	call.visible = false
	scrap._process(0.01)
	assert_int(scrap.phase).is_equal(NoteCollected.Phase.WRITING)
	assert_bool(scrap.visible).is_true()
	scrap._process(NoteCollected.WRITE)
	assert_int(scrap.phase).is_equal(NoteCollected.Phase.HOLDING)
	scrap._process(NoteCollected.HOLD)
	assert_int(scrap.phase).is_equal(NoteCollected.Phase.GOING)
	scrap._process(NoteCollected.GO)
	scrap._process(0.01)
	assert_int(scrap.phase).is_equal(NoteCollected.Phase.CORNER)
	assert_float(scrap.position.x).is_equal_approx(320.0 + NoteCollected.GAP, 0.5)
	assert_float(scrap.position.y).is_equal_approx(1020.0 - NoteCollected.SMALL.y, 0.5)


## Every note STORY.md 7.3 has is here, in order: a title, a paper a page knows how to draw, and
## its words; a page draws each one, its placeholders filled in for the profile reading.
func test_every_note_has_its_title_paper_and_words() -> void:
	for number: int in range(1, Story.NOTE_COUNT + 1):
		var note: Dictionary = StoryNotes.NOTES[number]
		assert_str(StoryNotes.title_of(number)).override_failure_message(str(number)).is_not_empty()
		(
			assert_bool(NotePage.PAPERS.has(note["paper"]))
			. override_failure_message(str(number))
			. is_true()
		)
		assert_bool((note["lines"] as Array).is_empty()).is_false()
		for line: Array in note["lines"]:
			(
				assert_bool(NotePage.VOICES.has(line[0]))
				. override_failure_message(str(number))
				. is_true()
			)
	assert_int(StoryNotes.NOTES.size()).is_equal(Story.NOTE_COUNT + StoryNotes.LOOSE_KEYS.size())
	assert_str(str(StoryNotes.NOTES[21]["lines"][0][1])).is_equal(
		"Don't stamp it! Don't accept their terms. Not this time. —K."
	)
	_profile.license_number = "JJ-123456"
	_profile.license_date = "16 OCT 2026"
	_profile.story.invitation = "0001 2048"
	for number: int in [1, 2]:
		for layer: StringName in [&"paper", &"back"]:
			var page: NotePage = auto_free(NotePage.make(number, _profile))
			page.layer = layer
			add_child(page)
			await await_idle_frame()
			assert_object(page).is_not_null()
	# Inspection is dated the day of the player's own test, the stub numbered as their invitation.
	assert_str(StoryFill.fill(str(StoryNotes.NOTES[2]["lines"][1][1]), _profile)).contains(
		"16 OCT 2026"
	)
	assert_str(StoryNotes.read_out(1, _profile)).contains("0001 2048")


## Note 13's memo is the bots' trait table as it is dealt: each trait's share of the weights in
## percent, so a weight tuned in data/ai/traits.tres is a memo to rewrite, STORY.md 7.3.
func test_the_traits_memo_is_the_trait_table() -> void:
	var memo := str(StoryNotes.NOTES[StoryNotes.number_of(&"traits")]["lines"][1][1])
	var table: BotTraitTable = load("res://data/ai/traits.tres")
	var total := 0.0
	for entry: BotTrait in table.entries:
		total += entry.weight
	var said: Array[String] = []
	for entry: BotTrait in table.entries:
		said.append("%s %d" % [entry.display_name.to_upper(), roundi(entry.weight / total * 100.0)])
	assert_str(memo).is_equal(" · ".join(said))
