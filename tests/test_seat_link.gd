extends GdUnitTestSuite
## Another profile sat in at a seat past the first, GAME.md 3.8: picked from that player's switch in
## the pause menu, it brings its name, its kart, its plate and how it drives, its maps go into its
## statistics, and at the title every seat is a guest again.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const PATH := "user://test_seat_link.cfg"
const BOB_STYLE: Array[int] = [2, 1, 0, 3]
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.player_names[0] = "Ann"
	Game.settings.player_names[1] = "Guest"
	Game.settings.save_to_disk()


func after_test() -> void:
	get_tree().paused = false
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## A second profile, Bob, licensed, in a kart of his own, who drives the simple way.
func _bob() -> Profile:
	var bob := Game.settings.new_profile()
	bob.player_names[0] = "Bob"
	bob.kart_styles[0] = PackedInt32Array(BOB_STYLE)
	bob.license_number = "0042"
	bob.license_plate = "BOB-1"
	bob.drive_modes[0] = Settings.DRIVE_SIMPLE
	bob.save_to_disk()
	return bob


func _room(inputs: Array[KartInput]) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 3)
	return match_node


## Only seats past the first, never the profile playing, and a profile at one seat at a time; a
## linked seat reads and writes its profile, a guest the profile playing, and the title lets go.
func test_a_seat_plays_as_the_profile_linked_to_it() -> void:
	var settings := Game.settings
	var bob := _bob()
	assert_bool(settings.link_seat(0, bob.id)).is_false()
	assert_bool(settings.link_seat(1, settings.profile.id)).is_false()
	assert_int(settings.linkable(1).size()).is_equal(1)
	assert_bool(settings.link_seat(1, bob.id)).is_true()
	assert_bool(settings.link_seat(2, bob.id)).is_false()
	assert_int(settings.linkable(2).size()).is_equal(0)
	assert_str(settings.seat_name(1)).is_equal("Bob")
	assert_str(settings.seat_name(2)).is_equal("")
	assert_that(settings.seat_style(1)).is_equal(PackedInt32Array(BOB_STYLE))
	assert_str(settings.seat_plate(1)).is_equal("BOB-1")
	# A guest wears the plate of the profile playing, which has no license yet.
	assert_str(settings.seat_plate(2)).is_equal("L")
	assert_str(settings.drive_mode(1)).is_equal(Settings.DRIVE_SIMPLE)
	assert_that(settings.seat_names().slice(0, 2)).is_equal(["Ann", "Bob"])
	# What the seat changes is Bob's, kept in his file; the guest's own entry is left alone.
	settings.set_seat_name(1, "Bobby")
	settings.set_drive_mode(1, Settings.DRIVE_ADVANCED)
	assert_str(settings.player_names[1]).is_equal("Guest")
	assert_bool(settings.delete_profile(bob.id)).is_false()
	settings.unlink_all()
	assert_str(settings.seat_name(1)).is_equal("Guest")
	var kept := Profile.at(settings.profiles_dir(), bob.id)
	assert_str(kept.player_names[0]).is_equal("Bobby")
	assert_str(kept.drive_modes[0]).is_equal(Settings.DRIVE_ADVANCED)
	# Never saved as linked: the next start has guests.
	assert_bool(ConfigFile.new().load(PATH) == OK).is_true()
	var read := Settings.new()
	read.path = PATH
	read.load_from_disk()
	assert_str(read.seat_name(1)).is_equal("Guest")


## From the second player's switch in the lobby: Link profile, Bob, and the kart is his at once;
## Unlink and it is a guest's again. The first player has no such button.
func test_linking_from_the_pause_menu_puts_the_profile_on_the_kart() -> void:
	_bob()
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(0, 1)]
	var match_node := _room(inputs)
	await _runner.simulate_frames(3, 17)
	var slot := match_node.slots[1]
	var menu := PauseMenu.add_to(match_node)
	menu.names_and_colors = true
	menu.set_paused(true)
	await await_idle_frame()
	var switches := menu._switches
	assert_bool(_switch_of(switches, 0).has("link")).is_false()
	var link: Button = _switch_of(switches, 1)["link"]
	assert_str(link.text).is_equal(DriveSwitches.LINK)
	link.pressed.emit()
	await await_idle_frame()
	var listed: Array = _switch_of(switches, 1)["buttons"]
	(
		assert_that(listed.map(func(each: Button) -> String: return each.text))
		. is_equal(["Bob", DriveSwitches.BACK])
	)
	(listed[0] as Button).pressed.emit()
	await await_idle_frame()
	assert_str(slot.player_name).is_equal("Bob")
	assert_that(slot.style.to_array()).is_equal(PackedInt32Array(BOB_STYLE))
	assert_that(slot.kart.style.to_array()).is_equal(PackedInt32Array(BOB_STYLE))
	assert_str(slot.kart.get_node("Body/Plate").get_meta(&"plate")).is_equal("BOB-1")
	assert_bool((slot.input as PlayerInput).simple()).is_true()
	# The switch says whose profile the seat is, its plate beside it, and the button changes it.
	var linked: Node = (_switch_of(switches, 1)["pane"] as Node).find_child("Linked", true, false)
	assert_object(linked).is_not_null()
	assert_str((linked.get_child(1) as Label).text).is_equal("Bob's profile")
	assert_object(linked.find_child("Plate", true, false)).is_not_null()
	assert_str((_switch_of(switches, 1)["link"] as Button).text).is_equal(DriveSwitches.CHANGE)
	# And so does the Players page of the settings.
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var note: Label = screen.find_child("Linked1", true, false)
	assert_str(note.text).is_equal("Linked to Bob")
	assert_object(screen.find_child("Linked0", true, false)).is_null()
	screen.queue_free()
	# Back on the switch, which has Change profile; the list now has Unlink as well.
	(_switch_of(switches, 1)["link"] as Button).pressed.emit()
	await await_idle_frame()
	listed = _switch_of(switches, 1)["buttons"]
	assert_bool((listed[0] as Button).disabled).is_true()
	assert_str((listed[1] as Button).text).is_equal(DriveSwitches.UNLINK)
	(listed[1] as Button).pressed.emit()
	await await_idle_frame()
	assert_str(slot.player_name).is_equal("Guest")
	assert_str(slot.kart.get_node("Body/Plate").get_meta(&"plate")).is_equal("L")
	(
		assert_object((_switch_of(switches, 1)["pane"] as Node).find_child("Linked", true, false))
		. is_null()
	)
	assert_str((_switch_of(switches, 1)["link"] as Button).text).is_equal(DriveSwitches.LINK)
	assert_bool((slot.input as PlayerInput).simple()).is_false()
	menu.set_paused(false)


## With no other profile kept there is nothing to link, so no button.
func test_no_button_without_another_profile() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(0, 1)]
	var match_node := _room(inputs)
	await _runner.simulate_frames(3, 17)
	var menu := PauseMenu.add_to(match_node)
	menu.set_paused(true)
	await await_idle_frame()
	assert_bool(_switch_of(menu._switches, 1).has("link")).is_false()
	menu.set_paused(false)


## A linked seat's map goes into its profile, the first seat's into the one playing, and a guest's
## into nobody's.
func test_a_linked_seats_match_goes_into_its_profile() -> void:
	var bob := _bob()
	Game.settings.link_seat(1, bob.id)
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0),
		PlayerInput.new(0, 1),
		PlayerInput.new(1, 2),
	]
	match_node.start(inputs, 3)
	await _runner.simulate_frames(2, 17)
	assert_object(MatchRecord.profile_of(match_node.slots[1])).is_same(
		Game.settings.seat_profile(1)
	)
	assert_object(MatchRecord.profile_of(match_node.slots[2])).is_null()
	match_node.slots[1].kills = 2
	var record := MatchRecord.add_to(match_node)
	record.record()
	var kept := Profile.at(Game.settings.profiles_dir(), bob.id)
	assert_float(LifetimeStats.value_of(kept, &"maps")).is_equal(1.0)
	assert_float(LifetimeStats.value_of(kept, &"kills")).is_equal(2.0)
	assert_float(LifetimeStats.value_of(Game.settings.profile, &"maps")).is_equal(1.0)


static func _switch_of(switches: DriveSwitches, seat: int) -> Dictionary:
	for each: Dictionary in switches._up:
		if (each["player"] as PlayerInput).seat == seat:
			return each
	return {}
