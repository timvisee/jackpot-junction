extends GdUnitTestSuite
## Kit's folder, STORY.md 7.2: the notes in order, a note new until its page has been open for a
## second, the folder opening at the first new one, the corner of the new note's paper on the
## title's folder, and the folder beside the payout slip after a map with a note in it.

const TITLE_SCENE := preload("res://scenes/ui/title.tscn")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _profile: Profile
var _was_story := StoryState.new()
var _was_number := ""
var _was_settings_number := ""


func before_test() -> void:
	_profile = Game.settings.profile
	_was_story = _profile.story
	_was_number = _profile.license_number
	_was_settings_number = Game.settings.license_number
	_profile.story = StoryState.new()
	_profile.license_number = "JJ-212212"
	Game.settings.license_number = "JJ-212212"


func after_test() -> void:
	_profile.story = _was_story
	_profile.license_number = _was_number
	Game.settings.license_number = _was_settings_number
	Story.override = -1


func _holder() -> Control:
	var holder: Control = auto_free(Control.new())
	holder.size = Vector2(1920.0, 1080.0)
	add_child(holder)
	return holder


## The notes in the story's order, whatever order they were found in; the folder opens at the first
## new one, and a page is read once it has been open a second, its mark gone with it.
func test_a_note_is_new_until_its_page_has_been_open_a_second() -> void:
	_profile.story.notes = PackedInt32Array([5, 1, 3])
	_profile.story.notes_read = PackedInt32Array([1])
	assert_array(Array(NotesFolder.in_order(_profile.story))).is_equal([1, 3, 5])
	# After the ending, what the player kept is at the back: the Final Hand's slip and the card.
	_profile.story.final_hand = "2026-10-07"
	assert_array(Array(NotesFolder.in_order(_profile.story))).is_equal(
		[1, 3, 5, StoryNotes.FINAL_SLIP, StoryNotes.TERMS_CARD]
	)
	assert_str(StoryNotes.title_of(StoryNotes.TERMS_CARD)).is_equal("Terms Accepted")
	_profile.story.final_hand = ""
	var folder := NotesFolder.open(_holder(), _profile, true)
	await await_idle_frame()
	assert_int(folder.at).is_equal(1)
	var page: NotePage = folder.find_child("NotePage3", true, false)
	assert_bool(page.new).is_true()
	folder._process(0.5)
	assert_bool(_profile.story.is_new(3)).is_true()
	folder._process(0.6)
	assert_bool(_profile.story.is_new(3)).is_false()
	assert_bool(page.new).is_false()
	assert_bool(_profile.story.is_new(5)).is_true()
	# Turned on to the last, which reads in its turn; nothing past it.
	folder.turn(1)
	assert_bool(folder.is_turning()).is_true()
	await await_millis(int(NotesFolder.TURN * 1000.0) + 200)
	assert_bool(folder.is_turning()).is_false()
	assert_int(folder.at).is_equal(2)
	folder._process(1.1)
	assert_bool(_profile.story.any_new()).is_false()
	folder.turn(1)
	assert_bool(folder.is_turning()).is_false()
	# Back, the way it came, and put away.
	folder.turn(-1)
	await await_millis(int(NotesFolder.TURN * 1000.0) + 200)
	assert_int(folder.at).is_equal(1)
	var put := [false]
	folder.put_away.connect(func() -> void: put[0] = true)
	folder.close()
	assert_bool(put[0]).is_true()


## The title's folder peeks in once a note has been found, with the corner of the first new note's
## paper up while there is one; the cursor reaches it going left from the buttons. None with no
## notes, or with the story off.
func test_the_title_peeks_the_folder_with_its_new_corner() -> void:
	Story.override = Story.Stage.PLAYER
	var bare: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(bare)
	await await_idle_frame()
	assert_object(bare.find_child("FolderPeek", true, false)).is_null()
	_profile.story.notes = PackedInt32Array([1, 2])
	_profile.story.notes_read = PackedInt32Array([1])
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	var peek: FolderPeek = title.find_child("FolderPeek", true, false)
	assert_object(peek).is_not_null()
	assert_int(peek.corner).is_equal(2)
	var play: Button = title.get("play_button")
	assert_object(play.get_node(play.focus_neighbor_left)).is_same(peek)
	# The license is reached going right as the folder is going left, each out under the cursor.
	var license := title.find_child("LicensePeek", true, false) as Control
	assert_object(play.get_node(play.focus_neighbor_right)).is_same(license)
	assert_object(license.get_node(license.focus_neighbor_left)).is_same(play)
	license.grab_focus()
	assert_bool(title.get("_license_out")).is_true()
	assert_bool(peek.out).is_false()
	peek.grab_focus()
	assert_bool(title.get("_license_out")).is_false()
	assert_bool(peek.out).is_true()
	peek.opened.emit()
	await await_idle_frame()
	var folder: NotesFolder = title.find_child("NotesFolder", true, false)
	assert_object(folder).is_not_null()
	folder._process(1.1)
	folder.close()
	await await_idle_frame()
	assert_int(peek.corner).is_equal(0)


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 300.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0), BotInput.new()]
	match_node.start(inputs, 41)
	return match_node


## After a map played here with a note taken in it the folder peeks in beside the slip, up with the
## slip and not before; none at the Final Hand.
func test_the_folder_peeks_in_beside_the_slip() -> void:
	var match_node := _start_match()
	await await_idle_frame()
	var folder := SlipFolder.add_to(match_node)
	assert_object(folder).is_not_null()
	_profile.story.notes = PackedInt32Array([1])
	await await_idle_frame()
	assert_bool(folder.visible).is_false()
	var slip := match_node.hud.get_node("Results") as Control
	slip.visible = true
	await await_idle_frame()
	assert_bool(folder.visible).is_true()
	assert_object(folder.peek).is_not_null()
	assert_int(folder.peek.corner).is_equal(1)
	folder.open()
	await await_idle_frame()
	assert_object(folder.notes).is_not_null()
	folder.notes.close()
	await await_idle_frame()
	assert_object(folder.notes).is_null()
	# Never at the Final Hand.
	var final := _start_match()
	await await_idle_frame()
	final.arena.final_hand = true
	assert_object(SlipFolder.add_to(final)).is_null()
