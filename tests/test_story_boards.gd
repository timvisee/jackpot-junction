extends GdUnitTestSuite
## The House's advertising, STORY.md 6.1: the hoardings draw one board from the newest stage and one
## from every stage reached, the poster on the back wall changes once a stage, and the House says
## its word off the table in every room, in the room's own medium.

## What each room says its word in, where it has a medium of its own, STORY.md 6.1.
const MEDIA := {
	&"workbench": HouseWord.Medium.CHALK,
	&"after_hours": HouseWord.Medium.GILT,
	&"the_yard": HouseWord.Medium.STENCIL,
	&"stitch": HouseWord.Medium.STITCH,
	&"pinball": HouseWord.Medium.DOTS,
	&"playset": HouseWord.Medium.STICKER,
	&"count_room": HouseWord.Medium.PAINT,
	&"garage": HouseWord.Medium.PAINT,
	&"school": HouseWord.Medium.PAINT,
}


func after_test() -> void:
	Story.override = -1


func _arena(map: String) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
	arena.bake_scenery = false
	add_child(arena)
	return arena


func _dressing(arena: Arena) -> StoryDressing:
	return arena.get_node_or_null("Story") as StoryDressing


## The first stage is the sixteen boards there have always been; later ones put one of their own up
## every time, never the same board twice and never two that name the player.
func test_one_board_from_the_newest_stage_and_one_from_them_all() -> void:
	var rng := RandomNumberGenerator.new()
	for seed: int in 200:
		rng.seed = seed
		var first := StoryBoards.pick(Story.Stage.CUSTOMER, false, rng)
		assert_bool(first[0] in Billboard.ADS and first[1] in Billboard.ADS).is_true()
		assert_bool(first[0] == first[1]).is_false()
		for stage: int in range(Story.Stage.PLAYER, Story.Stage.OPERATOR + 1):
			var two := StoryBoards.pick(stage, false, rng)
			assert_bool(two[0] in StoryLines.ADS[stage]).is_true()
			assert_bool(two[1] in StoryBoards.pool(stage)).is_true()
			assert_bool(two[0] == two[1]).is_false()
			var named := 0
			for ad: Array in two:
				if StoryBoards.names_the_player(ad):
					named += 1
			assert_int(named).is_less_equal(1)
	var final := StoryBoards.pick(Story.Stage.CANDIDATE, true, rng)
	assert_str(str(final[0][0])).is_equal("FINAL HAND")
	assert_str(str(final[1][0])).is_equal("NOW HIRING")
	# The old jokes keep coming around: the first stage's boards are in every stage's pool.
	assert_bool(Billboard.ADS[0] in StoryBoards.pool(Story.Stage.OPERATOR)).is_true()


## Every map a match is played on, the XL maps and the story's own included, has the House's word
## off its table, in its room's own medium, facing the camera on the near side, a picture of its
## own no bigger than a word needs, worn by the one shader every room's word is.
func test_the_word_is_said_off_the_table_on_every_map() -> void:
	for id: StringName in ArenaMaps.IDS:
		var arena := _arena(String(id))
		var word: HouseWord = arena.get_node_or_null("HouseWord")
		assert_object(word).override_failure_message(String(id)).is_not_null()
		assert_str(word.text).is_equal("KEEP CLEAR")
		if arena.room.id in MEDIA:
			assert_int(word.medium).override_failure_message(String(id)).is_equal(
				MEDIA[arena.room.id]
			)
		var box := word.transform * word.mesh.get_aabb()
		var half := arena.world_size() * 0.5
		var table := Rect2(-half, half * 2.0)
		var lies := Rect2(Vector2(box.position.x, box.position.z), Vector2(box.size.x, box.size.z))
		assert_bool(table.intersects(lies)).override_failure_message(String(id)).is_false()
		var facing := word.transform.basis.z.normalized()
		(
			assert_float(facing.dot(Vector3(0.0, 0.55, 0.84)))
			. override_failure_message(String(id))
			. is_greater(0.3)
		)
		assert_float(word.transform.basis.y.y).is_greater_equal(-0.01)
		var drawn: SubViewport = word.get_node_or_null("Drawn")
		if drawn != null:
			assert_int(maxi(drawn.size.x, drawn.size.y)).is_less_equal(HouseWord.MOST_PIXELS)
		var skin := word.material_override as ShaderMaterial
		assert_object(skin.shader).is_same(HouseWord.SHADER)


## A word on the near apron keeps clear of whatever lies there, and is kept from what comes after.
func test_a_word_on_the_apron_keeps_clear_of_what_lies_there() -> void:
	for map: String in ["vault", "house_rules"]:
		var arena := _arena(map)
		var word: HouseWord = arena.get_node("HouseWord")
		var props: RoomProps = arena.get_node("Props")
		var at := Vector2(word.position.x, word.position.z)
		var patch := Rect2(at - HouseWord.APRON * 0.5, HouseWord.APRON)
		for laid: Dictionary in props.laid_out:
			(
				assert_bool((laid["box"] as Rect2).intersects(patch))
				. override_failure_message("%s: %s" % [map, laid["kind"]])
				. is_false()
			)
		assert_bool(props._free(patch)).is_false()


## A match's room is dressed for the stage the machine shows, its word with it, the XL maps' rooms
## as well; the Garage and the driving school are not dressed at all, and say the House's first
## word whatever the stage, STORY.md 6.10.
func test_the_rooms_wear_the_stage_they_are_built_at() -> void:
	Story.override = Story.Stage.PARTICIPANT
	for map: String in ["lucky_crossing", "vault", "crossfire"]:
		var dressing := _dressing(_arena(map))
		assert_object(dressing).override_failure_message(map).is_not_null()
		assert_str(dressing.word.text).is_equal("KEEP PLAYING")
		var big: Label3D = dressing.poster.get_node("Big")
		assert_str(big.text).is_equal("BE YOURSELF")
	for map: String in ["lucky_crossing_xl", "vault_xl", "crossfire_xl", "house_rules"]:
		var dressing := _dressing(_arena(map))
		assert_object(dressing).override_failure_message(map).is_not_null()
		assert_str(dressing.word.text).is_equal("KEEP PLAYING")
	Story.override = Story.Stage.OPERATOR
	assert_str(_dressing(_arena("vault_xl")).word.text).is_equal("STAFF ONLY")
	for map: String in ["garage", "waiting_room", "tutorial"]:
		var arena := _arena(map)
		assert_object(_dressing(arena)).override_failure_message(map).is_null()
		var word: HouseWord = arena.get_node("HouseWord")
		assert_str(word.text).is_equal("KEEP CLEAR")
	Story.override = Story.Stage.CUSTOMER
	var first := _dressing(_arena("lucky_crossing"))
	assert_str(first.word.text).is_equal("KEEP CLEAR")
	assert_str((first.poster.get_node("Big") as Label3D).text).is_equal("PLAY RESPONSIBLY")


## The hoardings carry the newest stage's words, filled in.
func test_the_hoardings_carry_the_stage() -> void:
	Story.override = Story.Stage.OPERATOR
	var arena := _arena("vault")
	var said: Array[String] = []
	for label: Label3D in arena.billboards.find_children("*", "Label3D", true, false):
		said.append(label.text)
	var newest: Array[String] = []
	for ad: Array in StoryLines.ADS[Story.Stage.OPERATOR]:
		newest.append(StoryFill.fill(str(ad[0]), Game.settings.profile))
	var found := false
	for line: String in said:
		if line in newest:
			found = true
	assert_bool(found).override_failure_message(str(said)).is_true()
	for line: String in said:
		assert_bool(line.contains("{")).is_false()
