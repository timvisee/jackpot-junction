extends GdUnitTestSuite
## The Count Room and House Rules, STORY.md 3.9 and GAME.md 6.3: the map on the end of the list,
## in no Grand Prix's deal and in a quick match's list only after the Final Hand; the room's
## racks, drives, processor, lifted tiles, memory and vents; its crowd in exact rows with nobody at
## the console; its rig in green; its monitor; and its shaders warmed with the rest.

var _was_story := StoryState.new()
var _was_number := ""


func before_test() -> void:
	_was_story = Game.settings.profile.story
	_was_number = Game.settings.profile.license_number


func after_test() -> void:
	Game.settings.profile.story = _was_story
	Game.settings.profile.license_number = _was_number
	Story.override = -1


## House Rules is on every machine's list, on its end, in the Count Room; no Grand Prix ever deals
## it; and a quick match's list has it only for a profile that has played the Final Hand with its
## story on.
func test_house_rules_is_opened_by_the_final_hand_alone() -> void:
	assert_str(String(ArenaMaps.IDS[-1])).is_equal("house_rules")
	assert_str(ArenaMaps.NAMES[-1]).is_equal("House Rules")
	assert_str(String(ArenaMaps.layout(&"house_rules").room.id)).is_equal("count_room")
	for normal: bool in [true, false]:
		for xl: bool in [true, false]:
			assert_bool(&"house_rules" in ArenaMaps.pool(normal, xl)).is_false()
	var rng := RandomNumberGenerator.new()
	for seed: int in 60:
		rng.seed = seed
		assert_bool(&"house_rules" in GrandPrix.deal(8, rng)).is_false()
	var profile := Profile.new()
	profile.license_number = "JJ-212212"
	assert_int(ArenaMaps.offered(profile)).is_equal(ArenaMaps.IDS.size() - 1)
	profile.story.final_hand = "2026-10-07"
	assert_int(ArenaMaps.offered(profile)).is_equal(ArenaMaps.IDS.size())
	profile.story.on = false
	assert_int(ArenaMaps.offered(profile)).is_equal(ArenaMaps.IDS.size() - 1)
	# The lobby's list, as the profile playing has it.
	Game.settings.profile.license_number = "JJ-212212"
	Game.settings.profile.story = StoryState.new()
	var before: HostSettings = auto_free(HostSettings.add_to(self, true))
	assert_int(before.options.map_option.item_count).is_equal(ArenaMaps.IDS.size() - 1)
	Game.settings.profile.story.final_hand = "2026-10-07"
	var after: HostSettings = auto_free(HostSettings.add_to(self, true))
	assert_int(after.options.map_option.item_count).is_equal(ArenaMaps.IDS.size())
	after.options.map_option.selected = ArenaMaps.IDS.size() - 1
	var config := MatchConfig.new()
	after.options.apply_to(config)
	assert_str(String(config.map)).is_equal("house_rules")


## The room as it is built: the walls racks with lit faces, red patch cables over some, the boxes
## drives, the Junction a processor, the pits lifted tiles with no spikes and their cables each
## their own, nothing on the floor, a hall of racks with monitors round it, the rig in green, and
## the monitor on the back rack.
func test_the_count_room_is_built_as_the_house_would() -> void:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = ArenaMaps.layout(&"house_rules")
	arena.bake_scenery = false
	add_child(arena)
	var rack: MeshInstance3D = arena.get_node("Walls/Wall0/Wall").get_child(0)
	assert_object((rack.material_override as ShaderMaterial).shader).is_same(CountKit.LEDS)
	assert_int(arena.get_node("Litter").get_child_count()).is_equal(0)
	var pit := arena.pits[0]
	for part: Node in pit.find_children("*", "MeshInstance3D", true, false):
		var mesh := (part as MeshInstance3D).mesh as CylinderMesh
		if mesh != null:
			# Cables lying down, not spikes standing up.
			assert_float(mesh.top_radius).is_greater(0.0)
	# No two pits' cables alike.
	var runs: Array = []
	for each: Node3D in arena.pits.slice(0, 2):
		var thick: Array[float] = []
		for part: Node in each.find_children("*", "MeshInstance3D", true, false):
			var cable := (part as MeshInstance3D).mesh as CylinderMesh
			if cable != null:
				thick.append(cable.top_radius)
		runs.append(thick)
	assert_bool(runs[0] == runs[1]).is_false()
	# Red patch cables looped over some of the racks.
	var patches := arena.get_node("Walls").find_children("*", "MeshInstance3D", true, false).filter(
		func(part: Node) -> bool:
			var piece := (part as MeshInstance3D).mesh as CylinderMesh
			return piece != null and is_equal_approx(piece.top_radius, CountKit.PATCH_THICK)
	)
	assert_bool(patches.is_empty()).is_false()
	var hall: CountRoom = arena.get_node("CountRoom")
	assert_bool(hall.back_racks.is_empty()).is_false()
	var monitors := hall.find_children("Monitor*", "MeshInstance3D", false, false)
	assert_bool(monitors.is_empty()).is_false()
	var palette := arena.disco._colors
	for color: Color in palette:
		assert_float(color.g).is_greater(color.r)
	var dressing: StoryDressing = arena.get_node("Story")
	var words: Label3D = dressing.poster.get_node("Big")
	assert_str(words.text).is_equal("HUMAN OVERSIGHT: 0")
	assert_object(dressing.poster.get_node("Cursor")).is_not_null()


## The crowd stands in exact rows, every figure the usual size, facing the table, in the one gray;
## no tribune is built and nobody is at the console.
func test_the_count_rooms_crowd_stands_in_exact_rows() -> void:
	var holder: Node3D = auto_free(Node3D.new())
	add_child(holder)
	var room: RoomLook = load("res://data/rooms/count_room.tres")
	var crowd := Crowd.add_to(holder, Vector2(40.0, 22.5), room)
	assert_int(crowd.count()).is_greater(100)
	assert_object(crowd._stands).is_null()
	assert_object(crowd._dj).is_null()
	var first := crowd._shirts[0]
	for i: int in crowd.count():
		assert_float(crowd._spots[i].basis.get_scale().x).is_equal_approx(1.0, 0.001)
		assert_bool(crowd._shirts[i].is_equal_approx(first)).is_true()
		assert_float(crowd._spots[i].origin.y).is_equal_approx(Crowd.TABLE_TOP, 0.001)


## The room's racks and monitors are warmed with the rest, GAME.md 10.7.
func test_the_count_room_is_warmed_up() -> void:
	assert_bool("count_room" in ShaderWarmup.ROOMS).is_true()
	assert_bool(&"_story_rooms" in ShaderWarmup.EFFECTS).is_true()
