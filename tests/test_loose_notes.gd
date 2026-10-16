extends GdUnitTestSuite
## The loose notes of STORY.md 7.3, which the loyalty program's roads off the books pay, GAME.md
## 8.9: kept by keys of their own and never the story's next note, due once their bet is won, dealt
## only in a map with no note of the story due, filed in the folder's back pocket after the story's
## notes in the order found, and not counted among the notes the program's bets ask for.

var _profile: Profile


func before_test() -> void:
	_profile = Profile.new()
	_profile.story.on = true
	_profile.license_number = "JJ-123456"
	_profile.loyalty.welcomed = true


## Each loose note has a key of its own, outside the story's, and none is ever the next note.
func test_their_own_keys() -> void:
	for i: int in StoryNotes.LOOSE_KEYS.size():
		var number := StoryNotes.LOOSE_FROM + i
		assert_bool(StoryNotes.is_loose(number)).is_true()
		assert_str(String(StoryNotes.key_of(number))).is_equal(String(StoryNotes.LOOSE_KEYS[i]))
		assert_int(StoryNotes.number_of(StoryNotes.LOOSE_KEYS[i])).is_equal(number)
		assert_bool(StoryNotes.KEYS.has(StoryNotes.LOOSE_KEYS[i])).is_false()
		assert_str(StoryNotes.title_of(number)).is_not_empty()
	assert_bool(StoryNotes.is_loose(1)).is_false()
	for number: int in StoryNotes.LOOSE_FROM + 3:
		_profile.story.notes.append(number + 1)
	assert_bool(StoryNotes.is_loose(StoryNotes.next_of(_profile.story))).is_false()


## Due once the bet off the books that pays it is won, in the order won, until found; never with
## the story off.
func test_due_once_its_bet_is_won() -> void:
	assert_int(StoryNotes.loose_due(_profile)).is_equal(0)
	_profile.loyalty.win(&"walk_away")
	_profile.loyalty.win(&"torn_up")
	var program := StoryNotes.number_of(&"program_design")
	assert_int(StoryNotes.loose_due(_profile)).is_equal(program)
	StoryNotes.file(_profile, program)
	assert_int(StoryNotes.loose_due(_profile)).is_equal(StoryNotes.number_of(&"member_no"))
	_profile.story.on = false
	assert_int(StoryNotes.loose_due(_profile)).is_equal(0)


## Dealt only in a map with no note of the story due, never in its place.
func test_never_in_the_storys_place() -> void:
	_profile.loyalty.win(&"torn_up")
	var loose := StoryNotes.number_of(&"member_no")
	# The first note is due on the first map; the second only some minutes on.
	assert_int(StoryNotes.to_deal(_profile)).is_equal(1)
	StoryNotes.file(_profile, 1)
	assert_int(StoryNotes.to_deal(_profile)).is_equal(loose)
	_profile.story.seconds = StoryNotes.due_at(2, _profile.story)
	assert_int(StoryNotes.to_deal(_profile)).is_equal(2)


## In the folder after the story's notes, in the order found, and kept by its key in the profile.
func test_in_the_back_pocket() -> void:
	var back := StoryNotes.number_of(&"back_roads")
	var member := StoryNotes.number_of(&"member_no")
	for number: int in [3, back, 1, member, 2]:
		StoryNotes.file(_profile, number)
	assert_array(Array(NotesFolder.in_order(_profile.story))).is_equal([1, 2, 3, back, member])
	var file := ConfigFile.new()
	_profile.story.write(file)
	var read := StoryState.new()
	read.read(file)
	assert_bool(read.has_note(back)).is_true()
	assert_bool(read.has_note(member)).is_true()


## The program's bets of notes found count the story's notes only.
func test_not_counted_as_the_storys() -> void:
	StoryNotes.file(_profile, 1)
	StoryNotes.file(_profile, StoryNotes.number_of(&"member_no"))
	assert_int(_profile.story.story_notes()).is_equal(1)
	var pencils := Loyalty.map().landmark(&"pencil_trail")
	assert_object(Loyalty.progress(_profile, pencils)).is_equal(Vector2(1.0, 3.0))
