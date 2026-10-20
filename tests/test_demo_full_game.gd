extends GdUnitTestSuite
## Leaving the demo for a booth for the full game, GAME.md 9.8: a profile of the visitor's own with
## a head start on the loyalty program, and the demo back after a minute with nothing pressed, the
## visitor's profiles thrown away and the machine's settings as they were.

const PATH := "user://test_demo_full_game.cfg"


## A host that goes nowhere, which would leave the test's scene.
class StayingHost:
	extends DemoHost
	var titles := 0

	func go_to_title() -> void:
		titles += 1


var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Demo.on = true
	Demo.set_up(Game.settings, false)


func after_test() -> void:
	Demo.on = false
	Demo.away = false
	DemoSeats.clear()
	Game.settings = _settings_were
	Settings.remove_files(PATH)


## The head start is the landmarks nearest the slip road on the House's side, about a third of the
## program, with no keystone and nothing off the books.
func test_the_head_start_is_the_nearest_third() -> void:
	var drawn := Loyalty.map()
	var near := DemoGuest.nearest(drawn)
	assert_array(near).contains([&"slip_road", &"dealers_visor", &"racing_stripes", &"rare_cards"])
	assert_int(near.size()).is_between(drawn.landmarks.size() / 4, drawn.landmarks.size() / 2)
	for id: StringName in near:
		var landmark := drawn.landmark(id)
		assert_bool(landmark.keystone).is_false()
		assert_bool(landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS).is_false()
	var profile := Profile.new()
	DemoGuest.head_start(profile)
	assert_bool(profile.loyalty.welcomed).is_true()
	for id: StringName in near:
		assert_bool(profile.loyalty.has_won(id)).is_true()
	# The deck has cards of the program's, and the stalls its dress, but not all of it.
	var unlocks := Loyalty.unlocks_of(profile)
	assert_array(unlocks["jokers"]).contains(["lucky_seven"])
	assert_array(unlocks["dress"]).contains(["hat:Dealer's visor"])
	assert_bool(profile.loyalty.has_won(&"card_shark")).is_false()
	# Everything else about it is a new player's.
	assert_bool(profile.story.on).is_true()
	assert_bool(profile.tutorial_done).is_false()


## Play the full game: the visitor's own profile with its head start, kept, and nobody left sitting
## at the demo's seats.
func test_leaving_for_the_full_game() -> void:
	var host: StayingHost = auto_free(StayingHost.new())
	DemoSeats.held = {0: 0}
	host.leave()
	assert_bool(Demo.away).is_true()
	assert_bool(Demo.playing()).is_false()
	assert_int(host.titles).is_equal(1)
	assert_bool(DemoSeats.held.is_empty()).is_true()
	var guest := Game.settings.profile
	assert_bool(guest.transient).is_false()
	assert_bool(guest.id.is_valid_int()).is_true()
	assert_bool(SafeFile.exists(guest.path)).is_true()
	assert_bool(guest.loyalty.has_won(&"dealers_visor")).is_true()


## Play the full game goes dark for a moment first, a beat between the demo and the game: the
## title only once the screen has been dark for a while, nothing pressed through the dark, and the
## dark lifting off the title after.
func test_leaving_goes_dark_for_a_moment_first() -> void:
	# Not the demo's own frame work, which would sit a hand on the test's scene meanwhile.
	Demo.on = false
	var host: StayingHost = auto_free(StayingHost.new())
	add_child(host)
	host.leave()
	host.leave()
	var dark := host.get_node("Dark") as CanvasLayer
	var shade := dark.get_child(0) as ColorRect
	assert_int(shade.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	assert_int(host.titles).is_equal(0)
	assert_bool(Demo.away).is_false()
	# The music fades out with the screen, for the title to let go of as it opens.
	assert_bool(Audio.is_music_held()).is_true()
	await await_millis(int((DemoHost.DARK_IN + DemoHost.DARK_HOLD * 0.5) * 1000.0))
	assert_float(shade.modulate.a).is_equal_approx(1.0, 0.01)
	assert_int(host.titles).is_equal(0)
	await await_millis(int(DemoHost.DARK_HOLD * 0.5 * 1000.0) + 200)
	assert_int(host.titles).is_equal(1)
	assert_bool(Demo.away).is_true()
	await await_millis(int(DemoHost.DARK_OUT * 1000.0) + 300)
	assert_bool(is_instance_valid(dark)).is_false()
	Audio.hold_music(false)


## A minute with nothing pressed and the demo takes over again: every profile made since it was
## left thrown away, the machine's settings and the lobby's choices put back.
func test_the_demo_takes_over_again_after_a_quiet_minute() -> void:
	var host: StayingHost = auto_free(StayingHost.new())
	var volume := Game.settings.master_volume
	host.leave()
	var guest := Game.settings.profile
	var another := Game.settings.new_profile()
	Game.settings.master_volume = 0.05
	Game.settings.match_seconds = 60
	host._quiet = DemoSeats.IDLE - 1.0
	host.wait_for_the_visitor()
	assert_bool(Demo.away).is_true()
	host._quiet = DemoSeats.IDLE
	host.wait_for_the_visitor()
	assert_bool(Demo.away).is_false()
	assert_int(host.titles).is_equal(2)
	assert_str(Game.settings.profile.id).is_equal(Demo.PROFILE_ID)
	assert_bool(Game.settings.profile.transient).is_true()
	assert_bool(SafeFile.exists(guest.path)).is_false()
	assert_bool(SafeFile.exists(another.path)).is_false()
	assert_float(Game.settings.master_volume).is_equal(volume)
	assert_int(Game.settings.match_seconds).is_equal(Settings.new().match_seconds)
	var read := Settings.new()
	read.path = PATH
	read.load_from_disk()
	assert_float(read.master_volume).is_equal(volume)
	# Naming the profile it named before the visitor came, not one thrown away.
	assert_str(read.named).is_equal("1")


## Away in the full game, the title's Quit asks first: quit the game, or back to the demo, which
## the cursor starts on and which takes the demo up again. Back puts the question away. There is no
## button of its own for it.
func test_quit_asks_whether_to_go_back_to_the_demo() -> void:
	var host: StayingHost = StayingHost.new()
	host.name = "DemoHost"
	Game.add_child(host)
	# Away at once rather than through the dark, see the test before.
	host._away()
	var away: Control = auto_free(load("res://scenes/ui/title.tscn").instantiate())
	add_child(away)
	await await_idle_frame()
	var quit: Button = null
	for button: Button in away.find_children("*", "Button", true, false):
		assert_str(button.text).is_not_equal("Back to the demo")
		if button.text == "Quit":
			quit = button
	quit.pressed.emit()
	var pane := away.find_child("DemoQuit", true, false) as ConfirmPane
	assert_object(pane).is_not_null()
	assert_str(pane.yes_button().text).is_equal("Quit the game")
	assert_str(pane.no_button().text).is_equal("Back to the demo")
	assert_bool(pane.no_button().has_focus()).is_true()
	away._put_the_question_away()
	await await_idle_frame()
	assert_object(away.find_child("DemoQuit", true, false)).is_null()
	assert_bool(Demo.away).is_true()
	quit.pressed.emit()
	(away.find_child("DemoQuit", true, false) as ConfirmPane).no_button().pressed.emit()
	assert_bool(Demo.away).is_false()
	assert_int(host.titles).is_equal(2)
	Game.remove_child(host)
	host.free()


## Anybody touching anything in the full game keeps the demo away; nothing they press sits them
## down at a seat of the demo's.
func test_the_full_game_is_the_visitors_while_they_play() -> void:
	var host: StayingHost = auto_free(StayingHost.new())
	host.leave()
	host._quiet = DemoSeats.IDLE - 1.0
	var press := InputEventJoypadButton.new()
	press.device = 0
	press.pressed = true
	var room: Node = auto_free(Node.new())
	assert_bool(host.heard(press, room)).is_false()
	assert_float(host._quiet).is_equal(0.0)
	assert_bool(DemoSeats.held.is_empty()).is_true()
