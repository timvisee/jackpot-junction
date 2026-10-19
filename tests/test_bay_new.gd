extends GdUnitTestSuite
## The kart dialog's NEW tags, GAME.md 4.4a: dress won in the loyalty program, or moved up a finish,
## is new until the dialog has shown it, on its place on the rack, its part's hook and the key of
## whose kart it is, Next new at the head going to each in turn, and the ways to the dialog wearing
## NEW while there is any, see [BayNew].

const PATH := "user://test_bay_new.cfg"
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
const HAT := 1
const FLAG := 2
const TRAIL := 3

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.profile.story.on = false
	_holder = Control.new()
	_holder.size = Vector2(1600.0, 900.0)
	add_child(_holder)


func after_test() -> void:
	PlayerInput.typing = false
	TitleIntro.force = false
	TitleIntro.played = false
	ShaderWarmup.force = false
	ShaderWarmup.done = false
	get_tree().paused = false
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open() -> KartDialog:
	var dialog := KartDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


func _close(dialog: KartDialog) -> void:
	dialog.close()
	for frame: int in 120:
		if not is_instance_valid(dialog):
			return
		await get_tree().process_frame


static func _index(part: int, named: String) -> int:
	return KartDialog.choices_of(part).find(named)


static func _bay(dialog: KartDialog) -> BayNew:
	return dialog.get_node("BayNew") as BayNew


static func _landed(dialog: KartDialog) -> bool:
	return dialog.tray.get_children().any(func(child: Node) -> bool: return child is LandingCue)


## A landmark won that pays dress has what it pays new, as its part and index for the kart dialog,
## but never one of everybody's, nor a piece this version does not have; seen, it is not, and
## moved up a finish by an edition, it is new again. Kept in the profile's file.
func test_winning_dress_makes_it_new() -> void:
	var profile := Game.settings.profile
	var state := profile.loyalty
	assert_bool(BayNew.has_new(profile)).is_false()
	state.win(&"slip_road")
	assert_array(Array(state.dress_fresh)).is_empty()
	state.win(&"chip_trail")
	assert_array(Array(state.dress_fresh)).contains_exactly(["trail:Poker chips", "flag:Magnet"])
	assert_bool(BayNew.has_new(profile)).is_true()
	var owner := KartOwner.for_profile(profile)
	assert_array(owner.new_pieces()).contains_exactly_in_any_order(
		[Vector2i(TRAIL, _index(TRAIL, "Poker chips")), Vector2i(FLAG, _index(FLAG, "Magnet"))]
	)
	state.dress_new("hat:Cap")
	state.dress_new("hat:Nothing like it")
	assert_int(owner.new_pieces().size()).is_equal(2)
	assert_bool(state.look_at_dress("trail:Poker chips")).is_true()
	assert_bool(state.look_at_dress("trail:Poker chips")).is_false()
	state.owed = 1
	assert_bool(Loyalty.spend_edition(profile, "trail:Poker chips")).is_true()
	assert_bool("trail:Poker chips" in state.dress_fresh).is_true()
	Game.settings.save_to_disk()
	var kept := Profile.at(Game.settings.profiles_dir(), profile.id)
	assert_bool("trail:Poker chips" in kept.loyalty.dress_fresh).is_true()
	assert_bool("flag:Magnet" in kept.loyalty.dress_fresh).is_true()


## A profile's file from before there was new dress has none, however much it has won: only what
## it wins from now on is new.
func test_an_old_profile_is_not_flooded() -> void:
	var file := ConfigFile.new()
	file.set_value("loyalty", "welcomed", true)
	file.set_value("loyalty", "won", PackedStringArray(["slip_road", "fedora", "chip_trail"]))
	var state := LoyaltyState.new()
	state.read(file)
	assert_bool(state.has_won(&"fedora")).is_true()
	assert_array(Array(state.dress_fresh)).is_empty()
	state.win(&"racing_stripes")
	assert_array(Array(state.dress_fresh)).contains_exactly(["paint:Racing stripes"])
	var written := ConfigFile.new()
	state.write(written)
	var again := LoyaltyState.new()
	again.read(written)
	assert_array(Array(again.dress_fresh)).contains_exactly(["paint:Racing stripes"])


## A new piece wears NEW on its place on the rack, its part's hook while the rack holds one and the
## key of whose kart it is while it has one, each said to a screen reader; the cursor or the mouse
## on the piece takes its tag off, the hook's and the key's with the last, and it stays off once
## the dialog is put away and opened again.
func test_the_rack_the_hook_and_the_key_wear_new_until_looked_at() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"fedora")
	profile.loyalty.win(&"dealers_visor")
	var dialog := await _open()
	var hook := dialog.hooks[HAT]
	assert_bool(hook.fresh).is_true()
	assert_object(hook.get_node_or_null("New")).is_not_null()
	assert_str(hook.accessibility_description).starts_with(ScreenReader.spoken(CatalogCell.NEW))
	assert_bool(dialog.hooks[0].fresh).is_false()
	assert_object(dialog.hooks[0].get_node_or_null("New")).is_null()
	assert_bool(dialog.keys[0].fresh).is_true()
	assert_str(dialog.keys[0].accessibility_name).ends_with(ScreenReader.spoken(CatalogCell.NEW))
	dialog.open_tray(HAT)
	await get_tree().process_frame
	var fedora := dialog.tray.cell_at(_index(HAT, "Fedora"))
	var visor := dialog.tray.cell_at(_index(HAT, "Dealer's visor"))
	var crown := dialog.tray.cell_at(_index(HAT, "Crown"))
	assert_bool(fedora.fresh).is_true()
	assert_object(fedora.get_node_or_null("New")).is_not_null()
	assert_str(fedora.accessibility_description).contains(ScreenReader.spoken(CatalogCell.NEW))
	assert_bool(crown.fresh).is_false()
	fedora.grab_focus()
	assert_bool(fedora.fresh).is_false()
	assert_bool(hook.fresh).is_true()
	assert_bool(dialog.keys[0].fresh).is_true()
	visor.mouse_entered.emit()
	assert_bool(visor.fresh).is_false()
	assert_bool(hook.fresh).is_false()
	assert_bool(dialog.keys[0].fresh).is_false()
	assert_bool(_bay(dialog).next_new.visible).is_false()
	await _close(dialog)
	var kept := Settings.new()
	kept.path = PATH
	kept.load_from_disk()
	assert_array(Array(kept.profile.loyalty.dress_fresh)).is_empty()
	Game.settings = kept
	var again := await _open()
	assert_bool(again.hooks[HAT].fresh).is_false()
	assert_bool(again.keys[0].fresh).is_false()
	again.open_tray(HAT)
	await get_tree().process_frame
	assert_bool(again.tray.cell_at(_index(HAT, "Fedora")).fresh).is_false()


## Next new, GAME.md 8.8, a plate left of Back saying how many are new: pressed, its rack hung out
## and the cursor on the next new piece, down the left board and then the right, the eye drawn to
## it over the rack, its tag off and one fewer left, until none is and it goes. Its bind, N or a
## pad's View, presses it, but not while a box is typed into.
func test_next_new_goes_to_each_new_piece_in_turn() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"chip_trail")
	profile.loyalty.win(&"fedora")
	var dialog := await _open()
	var next := _bay(dialog).next_new
	assert_bool(next.visible).is_true()
	assert_str(next.count.text).is_equal("3")
	assert_str(next.button.accessibility_name).is_equal(NextNew.WORDS)
	assert_int(next.button.focus_mode).is_equal(Control.FOCUS_NONE)
	assert_float(next.position.x + next.size.x).is_less(BayArt.BACK.position.x)
	assert_float(next.position.y).is_equal(BayArt.BACK.position.y)
	var pieces: Array = [[FLAG, "Magnet"], [HAT, "Fedora"], [TRAIL, "Poker chips"]]
	PlayerInput.typing = true
	dialog.get_viewport().push_input(_pressed(InputActions.MENU_NEXT_NEW))
	assert_int(dialog.open_part).is_equal(-1)
	PlayerInput.typing = false
	for i: int in pieces.size():
		if i == 0:
			dialog.get_viewport().push_input(_pressed(InputActions.MENU_NEXT_NEW))
		else:
			next.button.pressed.emit()
		await get_tree().process_frame
		var part: int = pieces[i][0]
		var cell := dialog.tray.cell_at(_index(part, pieces[i][1]))
		assert_int(dialog.open_part).is_equal(part)
		assert_bool(cell.has_focus()).is_true()
		assert_bool(cell.fresh).is_false()
		assert_bool(dialog.hooks[part].fresh).is_false()
		assert_bool(_landed(dialog)).is_true()
		assert_str(next.count.text).is_equal(str(pieces.size() - 1 - i))
	assert_bool(next.visible).is_false()
	assert_bool(dialog.keys[0].fresh).is_false()


## From a hook, Next new goes to the first new piece of its rack or after it; from a piece on a
## rack, to the next new one after it on the same rack, without hanging it out again.
func test_next_new_goes_on_from_where_the_cursor_is() -> void:
	var profile := Game.settings.profile
	for id: StringName in [&"dealers_visor", &"fedora", &"card_shark", &"chip_trail"]:
		profile.loyalty.win(id)
	var dialog := await _open()
	var bay := _bay(dialog)
	dialog.hooks[HAT].grab_focus()
	bay.jump()
	await get_tree().process_frame
	assert_int(dialog.open_part).is_equal(HAT)
	var visor := dialog.tray.cell_at(_index(HAT, "Dealer's visor"))
	assert_bool(visor.has_focus()).is_true()
	bay.jump()
	await get_tree().process_frame
	assert_bool(dialog.tray.cell_at(_index(HAT, "Fedora")).has_focus()).is_true()
	assert_bool(dialog.tray.is_out()).is_true()
	bay.jump()
	await get_tree().process_frame
	assert_bool(dialog.tray.cell_at(_index(HAT, "Shark fin")).has_focus()).is_true()
	# On down the left board to the trail under the hat.
	bay.jump()
	await get_tree().process_frame
	assert_int(dialog.open_part).is_equal(TRAIL)
	assert_bool(dialog.tray.cell_at(_index(TRAIL, "Poker chips")).has_focus()).is_true()


## Next new turns to another tab for a profile with dress new, its key wearing NEW until then and
## the tab up's hooks none; what was seen there is kept in that profile's own file.
func test_next_new_turns_to_the_tab_with_dress_new() -> void:
	var other := Game.settings.new_profile()
	other.loyalty.win(&"flames")
	other.save_to_disk()
	var dialog := await _open()
	assert_int(dialog.owners.size()).is_equal(2)
	assert_bool(dialog.keys[0].fresh).is_false()
	assert_bool(dialog.keys[1].fresh).is_true()
	assert_bool(dialog.hooks[0].fresh).is_false()
	assert_str(_bay(dialog).next_new.count.text).is_equal("1")
	_bay(dialog).jump()
	await get_tree().process_frame
	assert_int(dialog.current).is_equal(1)
	assert_int(dialog.open_part).is_equal(0)
	assert_bool(dialog.tray.cell_at(_index(0, "Flames")).has_focus()).is_true()
	assert_bool(dialog.keys[1].fresh).is_false()
	assert_bool(_bay(dialog).next_new.visible).is_false()
	await _close(dialog)
	var kept := Profile.at(Game.settings.profiles_dir(), other.id)
	assert_array(Array(kept.loyalty.dress_fresh)).is_empty()


## A guest's tab, whose kart wears the profile playing's dress, has the profile playing's new
## pieces but its card back, having none of its own to choose.
func test_a_guest_has_no_new_card_back() -> void:
	Game.settings.profile.loyalty.win(&"gilt_back")
	Game.settings.profile.loyalty.win(&"fedora")
	var guest := KartOwner.for_seat(1)
	assert_bool(guest.is_guest()).is_true()
	assert_array(guest.new_pieces()).contains_exactly([Vector2i(HAT, _index(HAT, "Fedora"))])
	var own := KartOwner.for_seat(0)
	assert_int(own.new_pieces().size()).is_equal(2)


## The ways to the dialog wear NEW while the profile playing has dress the dialog has not shown it:
## the pause menu's Customize kart where a room offers it, and its Clubhouse with it, but not in a
## room with no way to the dialog; the Me tab's Customize kart; and the title's bay and Clubhouse,
## until the dialog has shown it.
func test_the_ways_in_wear_new() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"fedora")
	# Only the dress new, not the landmark that paid it.
	profile.loyalty.fresh = PackedStringArray()
	var menu := PauseMenu.add_to(_holder)
	await get_tree().process_frame
	var clubhouse := menu.find_child("ClubhouseButton", true, false) as Button
	assert_object(clubhouse.get_node_or_null("New")).is_null()
	var kart := menu.offer_kart(null)
	assert_object(kart.get_node_or_null("New")).is_not_null()
	assert_object(clubhouse.get_node_or_null("New")).is_not_null()
	menu.free()
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var tab := screen.find_child("License", true, false) as LicenseTab
	assert_object(tab.kart.get_node_or_null("New")).is_not_null()
	remove_child(screen)
	Game.settings.license_number = "JJ-212212"
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	# Only the dress new, not what the profile was credited with as the title came up.
	profile.achievements.fresh = PackedStringArray()
	title.call("_tag_fresh")
	var bay := title.find_child("BayPeek", true, false) as BayPeek
	assert_object(bay.get_node_or_null("New")).is_not_null()
	var title_club := title.get("_clubhouse_button") as Button
	assert_object(title_club.get_node_or_null("New")).is_not_null()
	title.call("show_kart")
	var dialog := title.find_child("KartDialog", true, false) as KartDialog
	await get_tree().process_frame
	dialog.open_tray(HAT)
	await get_tree().process_frame
	dialog.tray.cell_at(_index(HAT, "Fedora")).grab_focus()
	await _close(dialog)
	assert_object(bay.get_node_or_null("New")).is_null()
	assert_object(title_club.get_node_or_null("New")).is_null()


func _pressed(action: StringName) -> InputEventAction:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	return press
