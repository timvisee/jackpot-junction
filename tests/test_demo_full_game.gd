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


## Away in the full game, the title has Back to the demo over Quit; never in the demo itself.
func test_the_title_has_a_way_back_to_the_demo() -> void:
	var title_scene: PackedScene = load("res://scenes/ui/title.tscn")
	Demo.away = true
	var away: Control = auto_free(title_scene.instantiate())
	add_child(away)
	await await_idle_frame()
	var back := away.find_child("BackToTheDemo", true, false) as Button
	assert_object(back).is_not_null()
	assert_bool(back.is_visible_in_tree()).is_true()
	assert_int(back.get_index()).is_less(back.get_parent().get_child_count() - 1)
	Demo.away = false
	var demo: Control = auto_free(title_scene.instantiate())
	add_child(demo)
	await await_idle_frame()
	assert_object(demo.find_child("BackToTheDemo", true, false)).is_null()


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
