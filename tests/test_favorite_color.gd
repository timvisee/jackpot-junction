extends GdUnitTestSuite
## A player's favorite color, GAME.md 3.8: kept in their profile, a seat each, chosen from their
## switch in the pause menu or on the Players page, given wherever it is free, and the color of the
## kart on their license.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
const PATH := "user://test_favorite_color.cfg"

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH


func after_test() -> void:
	get_tree().paused = false
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## Kept in the profile a seat each, and read back; a seat sat in as another profile has that
## profile's.
func test_a_favorite_is_kept_in_the_profile() -> void:
	var settings := Game.settings
	assert_int(settings.seat_color(0)).is_equal(-1)
	settings.set_seat_color(0, 5)
	settings.set_seat_color(2, 3)
	settings.save_to_disk()
	var read := Settings.new()
	read.path = PATH
	read.load_from_disk()
	assert_array(read.seat_colors()).is_equal([5, -1, 3, -1] as Array[int])
	var bob := settings.new_profile()
	bob.colors[0] = 6
	bob.save_to_disk()
	settings.link_seat(1, bob.id)
	assert_int(settings.seat_color(1)).is_equal(6)
	settings.set_seat_color(1, 7)
	assert_int(settings.seat_profile(1).colors[0]).is_equal(7)
	assert_int(settings.profile.colors[1]).is_equal(-1)


## At the table each player is in their favorite where nobody before them has it, and otherwise in
## the color their place gives them, or the first free.
func test_a_match_seats_players_in_their_favorites() -> void:
	var settings := Game.settings
	settings.set_seat_color(0, 4)
	settings.set_seat_color(1, 4)
	var config := MatchConfig.from_settings(settings)
	config.human_devices = [DeviceInput.KEYBOARD, 0] as Array[int]
	config.bot_count = 2
	var colors := config.colors()
	assert_int(colors[0]).is_equal(4)
	assert_int(colors[1]).is_equal(1)
	assert_bool(colors.slice(2).has(4)).is_false()
	assert_array(MatchConfig.favorite_first(3, 4)).is_equal([3, 0, 1, 2] as Array[int])
	assert_array(MatchConfig.favorite_first(-1, 3)).is_equal([0, 1, 2] as Array[int])


## Sitting down in a room, a player is in their seat's favorite, repainting the bot's kart they
## take over; moving on to another color from their switch makes that their favorite.
func test_joining_and_recoloring_use_and_keep_the_favorite() -> void:
	Game.settings.set_seat_color(1, 6)
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), BotInput.new(), BotInput.new()
	]
	match_node.start(inputs, 3)
	await _runner.simulate_frames(3, 17)
	var joined := match_node.join_human(0)
	assert_object(joined).is_not_null()
	assert_int(joined.color_index).is_equal(6)
	assert_int(joined.kart.color_index).is_equal(6)
	var first := match_node.slots[0]
	SeatIdentity.recolor(match_node, first)
	assert_int(Game.settings.seat_color(0)).is_equal(first.color_index)


## The kart on the license is in the holder's favorite, and the Players page chooses a seat's
## favorite from all of them in a row.
func test_the_license_and_the_players_page_show_the_favorite() -> void:
	Game.settings.set_seat_color(0, 3)
	var card: LicenseCard = auto_free(LicenseCard.from_settings())
	assert_int(card.color_index).is_equal(3)
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	# Every color in a row for each seat, the chosen one ringed; a press on one chooses it.
	var row: HBoxContainer = screen.find_child("Colors1", true, false)
	assert_int(row.get_child_count()).is_equal(Palette.PLAYER_COLORS.size())
	(row.get_child(6) as Button).pressed.emit()
	assert_int(Game.settings.seat_color(1)).is_equal(6)
	var ringed := (row.get_child(6) as Button).get_theme_stylebox("normal") as StyleBoxFlat
	assert_int(ringed.border_width_top).is_greater(0)
	var plain := (row.get_child(2) as Button).get_theme_stylebox("normal") as StyleBoxFlat
	assert_int(plain.border_width_top).is_equal(0)
	var first: HBoxContainer = screen.find_child("Colors0", true, false)
	var three := (first.get_child(3) as Button).get_theme_stylebox("normal") as StyleBoxFlat
	assert_int(three.border_width_top).is_greater(0)


## A palette chosen for color blindness on the Accessibility page draws the Players page's colors
## in it at once.
func test_the_colors_follow_the_palette_chosen() -> void:
	var was := Palette.vision
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	var row: HBoxContainer = screen.find_child("Colors0", true, false)
	var choice: OptionButton = null
	for each: Node in screen.find_children("*", "OptionButton", true, false):
		var option := each as OptionButton
		if option.item_count == Settings.VISIONS.size() and option.get_item_text(0) == "Off":
			choice = option
	var deuteranopia := Settings.VISIONS.find("deuteranopia")
	choice.select(deuteranopia)
	choice.item_selected.emit(deuteranopia)
	var drawn := (row.get_child(1) as Button).get_theme_stylebox("normal") as StyleBoxFlat
	assert_that(drawn.bg_color).is_equal(Palette.VISION_COLORS["deuteranopia"][1])
	Palette.vision = was
