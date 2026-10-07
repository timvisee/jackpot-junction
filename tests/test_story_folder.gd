extends GdUnitTestSuite
## Kit's folder, STORY.md 7.2: the notes in order, a note new until it has been looked at closer,
## the folder turning on to the first new one and taking it out, the pages turned as fast as they
## are pressed, the corner of the new note's paper on the title's folder, and the folder beside the
## payout slip after a map with a note in it.

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


## Until [param folder] has come out and turned on to its first new note, or a few seconds.
func _settled(folder: NotesFolder) -> void:
	for i: int in 80:
		if not folder.is_busy():
			return
		await await_millis(50)


## The notes in the story's order, whatever order they were found in, two to a spread, the back of a
## leaf on the left and the front of the next on the right, each page numbered; the folder comes out
## shut, opens on its first spread, turns on to the first new note and takes it out for a closer
## look; open on its page is not enough to read it, taken out it is read at once.
func test_a_note_is_new_until_it_has_been_looked_at_closer() -> void:
	_profile.story.notes = PackedInt32Array([5, 1, 3])
	_profile.story.notes_read = PackedInt32Array([1])
	assert_array(Array(NotesFolder.in_order(_profile.story))).is_equal([1, 3, 5])
	# After the ending, what the player kept is at the back: the invitation and its ticket, torn,
	# the Final Hand's slip and the card.
	_profile.story.final_hand = "2026-10-07"
	assert_array(Array(NotesFolder.in_order(_profile.story))).is_equal(
		[
			1,
			3,
			5,
			StoryNotes.INVITATION,
			StoryNotes.TICKET,
			StoryNotes.FINAL_SLIP,
			StoryNotes.TERMS_CARD
		]
	)
	assert_str(StoryNotes.title_of(StoryNotes.TERMS_CARD)).is_equal("Terms Accepted")
	var invitation: NotePage = auto_free(NotePage.make(StoryNotes.INVITATION, _profile))
	add_child(invitation)
	assert_bool(invitation.get_node("Kept") is InvitationCard).is_true()
	var kept: NotePage = auto_free(NotePage.make(StoryNotes.TICKET, _profile))
	add_child(kept)
	var ticket: GoldenTicket = kept.get_node("Kept")
	assert_bool(ticket.torn).is_true()
	assert_bool(ticket.stub.visible).is_false()
	assert_object(auto_free(NotePage.make(1, _profile)).get_node_or_null("Kept")).is_null()
	_profile.story.final_hand = ""
	assert_int(NotesFolder.spreads(3)).is_equal(2)
	assert_int(NotesFolder.spread_of(0)).is_equal(0)
	assert_int(NotesFolder.spread_of(1)).is_equal(1)
	assert_int(NotesFolder.spread_of(2)).is_equal(1)
	assert_int(NotesFolder.left_of(0)).is_equal(-1)
	assert_int(NotesFolder.first_new_index(_profile.story)).is_equal(1)
	var folder := NotesFolder.open(_holder(), _profile, true)
	await await_idle_frame()
	assert_bool(folder.is_busy()).is_true()
	assert_int(folder.at).is_equal(0)
	await _settled(folder)
	assert_int(folder.at).is_equal(1)
	var left: NotePage = folder.find_child("Left", true, false).get_child(0)
	var right: NotePage = folder.find_child("Right", true, false).get_child(0)
	assert_int(left.number).is_equal(3)
	assert_int(right.number).is_equal(5)
	assert_int(left.page_number).is_equal(2)
	assert_int(right.page_number).is_equal(3)
	# Laid on its page by hand: askew, under a clip, tape or a staple, the same every time.
	var lying: NotePage = right.get_node("Note")
	var held: NoteOnPage = right.get_node("Held")
	assert_str(String(lying.layer)).is_equal("lying")
	assert_array(NoteOnPage.KINDS).contains([held.kind])
	assert_float(absf(lying.rotation)).is_less_equal(NoteOnPage.ASKEW)
	var again: NotePage = auto_free(NotePage.make(5, _profile))
	add_child(again)
	assert_float(again.get_node("Note").rotation).is_equal(lying.rotation)
	assert_str(String(again.get_node("Held").kind)).is_equal(String(held.kind))
	# Turned on to, the first new note is out for a closer look.
	assert_object(folder.view).is_not_null()
	assert_int(folder.view.index).is_equal(1)
	# Taken out, it is read at once.
	assert_bool(_profile.story.is_new(3)).is_false()
	assert_bool(_profile.story.is_new(5)).is_true()
	assert_bool(left.new).is_false()
	assert_bool(right.new).is_true()
	# The arrow to a new note carries its pencil mark; the one to a read note does not.
	var ahead: Button = folder.view.find_child("Next", true, false)
	var behind: Button = folder.view.find_child("Previous", true, false)
	assert_bool(ahead.get_node("NewMark").visible).is_true()
	assert_object(behind.get_node_or_null("NewMark")).is_null()
	folder.view.close()
	await await_idle_frame()
	# Nothing past the last spread.
	folder.turn(1)
	assert_bool(folder.is_turning()).is_false()
	# Back on the first spread, the arrow on to the next carries the mark: note 5 is new.
	folder._show(0)
	var on: Button = folder.find_child("Next", true, false)
	assert_bool(on.get_node("NewMark").visible).is_true()
	folder._show(1)
	# A pad's shoulder buttons turn the pages.
	var shoulder := InputEventJoypadButton.new()
	shoulder.pressed = true
	shoulder.button_index = JOY_BUTTON_LEFT_SHOULDER
	assert_int(NotesFolder.turn_of(shoulder)).is_equal(-1)
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
	assert_int(NotesFolder.turn_of(shoulder)).is_equal(1)
	# The stick turns a page a push: held over it turns no more, and let go it turns again.
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_X
	assert_int(NotesFolder.turn_of(stick)).is_equal(0)
	for push: Array in [[0.9, 1], [0.95, 0], [1.0, 0], [0.05, 0], [0.9, 1], [-0.9, -1]]:
		stick.axis_value = push[0]
		assert_int(folder._stick_turn(stick)).is_equal(push[1])
	# Back, the way it came, and put away: said at once, gone once it is back where it came from.
	folder.turn(-1)
	assert_bool(folder.is_turning()).is_true()
	await await_millis(int(NotesFolder.TURN * 1000.0) + 200)
	assert_int(folder.at).is_equal(0)
	var put := [false]
	folder.put_away.connect(func() -> void: put[0] = true)
	folder.close()
	assert_bool(put[0]).is_true()
	await await_millis(int((NotesFolder.SWING + NotesFolder.SLIDE) * 1000.0) + 300)
	assert_bool(is_instance_valid(folder)).is_false()


## A note taken off its page for a closer look, by the magnifying glass: turned toward the mouse,
## turned over to its back, looked at closer, the note beside it; put back, the folder opens at the
## last one looked at.
func test_a_note_can_be_looked_at_closer_and_turned_over() -> void:
	_profile.story.notes = PackedInt32Array([1, 2, 3, 4])
	_profile.story.notes_read = PackedInt32Array([1, 2, 3, 4])
	var folder := NotesFolder.open(_holder(), _profile, true)
	await _settled(folder)
	assert_int(folder.at).is_equal(0)
	assert_object(folder.view).is_null()
	assert_str(folder.look.text).is_empty()
	assert_object(folder.look.icon).is_not_null()
	assert_str(folder.look.tooltip_text).is_equal(NotesFolder.LOOK_WORD)
	# The buttons are for the mouse and never take the cursor; with keys or a pad in hand each has
	# its bind drawn on it, gone again with the mouse.
	for button: Node in folder._buttons_row.get_children():
		assert_int((button as Button).focus_mode).is_equal(Control.FOCUS_NONE)
	folder._pointer = false
	folder._show_binds()
	assert_object(folder.look.get_node_or_null("Bind")).is_not_null()
	folder._pointer = true
	folder._show_binds()
	assert_object(folder.look.get_node_or_null("Bind")).is_null()
	# Accept takes the open note out, as it shows the license on the title; a right click puts it
	# back. A and D turn the pages as the arrows do.
	var press_d := InputEventKey.new()
	press_d.physical_keycode = KEY_D
	press_d.pressed = true
	assert_int(NotesFolder.turn_of(press_d)).is_equal(1)
	press_d.physical_keycode = KEY_A
	assert_int(NotesFolder.turn_of(press_d)).is_equal(-1)
	var hand := InputEventAction.new()
	hand.action = &"ui_accept"
	hand.pressed = true
	folder._input(hand)
	assert_object(folder.view).is_not_null()
	await await_millis(int(NoteView.FLY * 1000.0) + 200)
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	folder.view._on_input(right_click)
	assert_object(folder.view).is_null()
	await await_millis(int(NoteView.FLY_BACK * 1000.0) + 150)
	folder.look_closer(0)
	var view := folder.view
	assert_object(view).is_not_null()
	assert_int(view.index).is_equal(0)
	# It grows up off its page, which shows nothing where it lay while it is up.
	var lift := folder.lift_of(0)
	assert_bool(lift.is_empty()).is_false()
	assert_bool((lift["held"] as Control).visible).is_false()
	assert_float(view._fly).is_less(1.0)
	await await_millis(int(NoteView.FLY * 1000.0) + 100)
	assert_float(view._fly).is_equal(1.0)
	# The mouse below and right of it turns its right and bottom edges toward the eye.
	view._mouse = view._card.get_global_rect().end + Vector2(40.0, 40.0)
	view._process(0.5)
	assert_float(view._tilt.x).is_greater(0.0)
	assert_float(view._tilt.y).is_greater(0.0)
	view.turn_over()
	await await_millis(int(NoteView.TURN * 1000.0) + 150)
	assert_bool(view.turned).is_true()
	view.zoom_by(2.0)
	assert_float(view.zoom).is_equal_approx(2.0, 0.001)
	view.zoom_by(10.0)
	assert_float(view.zoom).is_equal(NoteView.CLOSEST)
	view.zoom_by(0.01)
	# A trigger holds it as close as it is pulled, and let go, it goes back to its own size.
	for frame: int in 30:
		view._squeeze(0.5, 0.05)
	assert_float(view.zoom).is_equal_approx(lerpf(1.0, NoteView.CLOSEST, 0.5), 0.05)
	for frame: int in 30:
		view._squeeze(0.0, 0.05)
	assert_float(view.zoom).is_equal(1.0)
	assert_bool(view._squeezed).is_false()
	view.zoom_by(10.0)
	view.step(1)
	assert_int(view.index).is_equal(1)
	assert_bool(view.turned).is_false()
	assert_float(view.zoom).is_equal(1.0)
	view.step(1)
	view.step(1)
	assert_int(view.index).is_equal(3)
	# At the last note there is no arrow on, out of sight but keeping its room.
	var on_arrow: Button = view.find_child("Next", true, false)
	assert_float(on_arrow.modulate.a).is_equal(0.0)
	assert_bool(on_arrow.disabled).is_true()
	assert_float((view.find_child("Previous", true, false) as Button).modulate.a).is_equal(1.0)
	view.close()
	await await_idle_frame()
	assert_object(folder.view).is_null()
	assert_int(folder.at).is_equal(NotesFolder.spread_of(3))
	# Put back, it goes back down onto its page, and the page has it again.
	assert_bool(is_instance_valid(view)).is_true()
	await await_millis(int(NoteView.FLY_BACK * 1000.0) + 150)
	assert_bool(is_instance_valid(view)).is_false()
	assert_bool((folder.lift_of(3)["held"] as Control).visible).is_true()
	# What is kept at the back after the ending is looked at closer and turned over the same way:
	# the invitation face up, and face down on its back.
	folder.close()
	await await_idle_frame()
	_profile.story.final_hand = "2026-10-07"
	folder = NotesFolder.open(_holder(), _profile, true)
	await _settled(folder)
	var at_invitation := Array(folder.pages).find(StoryNotes.INVITATION)
	folder.look_closer(at_invitation)
	view = folder.view
	assert_object(view).is_not_null()
	await await_idle_frame()
	var card: InvitationCard = view.find_child("Kept", true, false)
	assert_bool(card.face_up).is_true()
	view.step(1)
	assert_int(view.index).is_equal(at_invitation + 1)
	var faces: Array = view.find_children("Kept", "", true, false)
	assert_bool(faces.any(func(kept: Node) -> bool: return kept is GoldenTicket)).is_true()
	(
		assert_bool(
			faces.any(func(kept: Node) -> bool: return kept is GoldenTicket and kept.face_down)
		)
		. is_true()
	)
	view.close()
	_profile.story.final_hand = ""
	# Every note's back draws, whatever is on it.
	for number: int in StoryNotes.BACKS:
		var back := NotePage.make(number, _profile)
		back.layer = &"back"
		folder.add_child(back)
	await await_idle_frame()


## A turn stops the turning on to the first new note where it is, and no closer look opens; then
## the pages turn as fast as they are pressed, every leaf going over in turn, quicker.
func test_a_turn_stops_the_turning_on_and_the_pages_turn_fast() -> void:
	_profile.story.notes = PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8, 9])
	_profile.story.notes_read = PackedInt32Array([1, 2, 3, 4, 5, 6, 7])
	var folder := NotesFolder.open(_holder(), _profile, true)
	await await_millis(int((NotesFolder.SLIDE + NotesFolder.SWING) * 1000.0) + 150)
	assert_bool(folder.is_flipping()).is_true()
	folder.turn(-1)
	assert_bool(folder.is_flipping()).is_false()
	await _settled(folder)
	assert_int(folder.at).is_less(NotesFolder.spread_of(7))
	assert_object(folder.view).is_null()
	var from := folder.at
	folder.turn(1)
	folder.turn(1)
	folder.turn(1)
	# Every spread on the way is landed on, none jumped, and quickly.
	var seen: Array[int] = [from]
	for frame: int in 60:
		await await_millis(16)
		if seen[seen.size() - 1] != folder.at:
			seen.append(folder.at)
	var last := mini(from + 3, NotesFolder.spreads(9) - 1)
	assert_int(folder.at).is_equal(last)
	assert_array(seen).is_equal(range(from, last + 1))


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
	# Back takes the cursor off the license, or the folder, and back to the buttons.
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	title._unhandled_input(back)
	assert_bool(play.has_focus()).is_true()
	peek.grab_focus()
	assert_bool(title.get("_license_out")).is_false()
	assert_bool(peek.out).is_true()
	title._unhandled_input(back)
	assert_bool(play.has_focus()).is_true()
	peek.grab_focus()
	peek.opened.emit()
	await await_idle_frame()
	var folder: NotesFolder = title.find_child("NotesFolder", true, false)
	assert_object(folder).is_not_null()
	await _settled(folder)
	assert_object(folder.view).is_not_null()
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
	# It draws the eye: out from the edge, opening its cover a little and shutting it.
	assert_bool(folder.peek.is_beckoning()).is_true()
	assert_bool(folder.peek.out).is_true()
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
