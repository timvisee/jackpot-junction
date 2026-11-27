extends GdUnitTestSuite
## The title screen's foot, GAME.md 3.8: the supporter pack's line in its corner, 10.8, which a
## click or a tap holds the thank-you card up again from, and which the cursor never goes to.

const PATH := "user://test_title_foot.cfg"
const TITLE := preload("res://scenes/ui/title.tscn")

var _settings_were: Settings


func before_test() -> void:
	Supporter.dry = true
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()


func after_test() -> void:
	TitleCards.from_the_menus = false
	Supporter.dry = false
	Supporter.start(PackedStringArray(), false, false)
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## A click or a tap on the line holds the thank-you card up again, once, the card alone with Close;
## put away, the cursor is back on the title's button. The cursor never goes to the line: a pad has
## the settings' Me page for the card.
func test_a_tap_on_the_supporter_line_holds_the_card_up() -> void:
	Supporter.start(PackedStringArray(["--supporter"]), false, false)
	Game.settings.supporter_thanked = true
	var title: Control = auto_free(TITLE.instantiate())
	add_child(title)
	await await_idle_frame()
	var foot := title.get_node("Foot") as TitleFoot
	assert_bool(foot.supporter.visible).is_true()
	assert_int(foot.supporter.focus_mode).is_equal(Control.FOCUS_NONE)
	var had := get_viewport().gui_get_focus_owner()
	assert_object(had).is_not_null()
	# A tap as a phone gives it: the mouse it makes of the touch first, then the touch itself.
	var at := foot.supporter.get_global_rect().get_center()
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		click.position = at
		click.global_position = at
		get_viewport().push_input(click, true)
	for down: bool in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.pressed = down
		touch.position = at
		get_viewport().push_input(touch, true)
	await get_tree().process_frame
	var held := title.find_children("SupporterThanks", "SupporterThanks", false, false)
	assert_int(held.size()).is_equal(1)
	var thanks := held[0] as SupporterThanks
	assert_bool(thanks.again).is_true()
	assert_object(foot.thanks).is_same(thanks)
	thanks.come_on_now()
	thanks._close(false)
	await await_signal_on(thanks, "put_away", [], 3000)
	assert_object(foot.thanks).is_null()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(had)
	remove_child(title)


## Without the pack there is no line to press, and a press where it would be holds nothing up.
func test_without_the_pack_nothing_is_held_up() -> void:
	Supporter.start(PackedStringArray(), false, true)
	var title: Control = auto_free(TITLE.instantiate())
	add_child(title)
	await await_idle_frame()
	var foot := title.get_node("Foot") as TitleFoot
	assert_bool(foot.supporter.visible).is_false()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = foot.supporter.get_global_rect().get_center()
	click.global_position = click.position
	get_viewport().push_input(click, true)
	await get_tree().process_frame
	assert_array(title.find_children("SupporterThanks", "SupporterThanks", false, false)).is_empty()
	assert_object(foot.thanks).is_null()
	remove_child(title)
