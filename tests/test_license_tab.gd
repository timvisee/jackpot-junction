extends GdUnitTestSuite
## The License page of the settings, GAME.md 8.5, as the cursor goes round it. See [LicenseTab].

const PATH := "user://test_license_tab.cfg"

var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()


func after_test() -> void:
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## The cursor walks the License page a row at a time, GAME.md 8.5: along the cards on top, down to
## the sections' grid under them a row of it at a time, the same column down as it was, and never
## off a row's end or the page's foot to wherever the engine finds nearest.
func test_the_cursor_walks_the_license_page_a_row_at_a_time() -> void:
	Game.settings.license_number = "JJ-224123"
	Game.settings.license_date = "2026-10-02"
	Game.settings.profile.loyalty.welcomed = true
	Game.settings.profile.story.on = false
	var room: Control = auto_free(Control.new())
	room.size = Vector2(1600.0, 900.0)
	add_child(room)
	var tab := LicenseTab.make(Game.settings)
	room.add_child(tab)
	await await_idle_frame()
	var card: Control = tab.find_child("LicenseCard", true, false)
	# The sections two across: Plate and Driving school, Your kart and the program, Catalog and
	# Achievements, and Story on its own.
	var steps := {
		"right":
		[
			[card, tab.loyalty_card],
			[tab.loyalty_card, tab.loyalty_card],
			[tab.kart, tab.program],
			[tab.catalog, tab.achievements],
			[tab.achievements, tab.achievements],
			[tab.story_switch, tab.story_switch]
		],
		"left":
		[
			[tab.loyalty_card, card],
			[tab.program, tab.kart],
			[tab.achievements, tab.catalog],
			[tab.story_switch, tab.story_switch],
			[card, card]
		],
		"down":
		[
			[card, tab.field],
			[tab.loyalty_card, tab.retake],
			[tab.field, tab.kart],
			[tab.retake, tab.program],
			[tab.kart, tab.catalog],
			[tab.program, tab.achievements],
			[tab.achievements, tab.story_switch],
			[tab.story_switch, tab.story_switch]
		],
		"up":
		[
			[tab.field, card],
			[tab.retake, tab.loyalty_card],
			[tab.kart, tab.field],
			[tab.achievements, tab.program],
			[tab.story_switch, tab.catalog]
		],
	}
	for way: String in steps:
		for step: Array in steps[way]:
			var from: Control = step[0]
			var path: NodePath = from.get(
				(
					"focus_neighbor_%s"
					% ("top" if way == "up" else ("bottom" if way == "down" else way))
				)
			)
			(
				assert_object(from.get_node(path))
				. override_failure_message("%s from %s" % [way, from.name])
				. is_same(step[1])
			)
	tab.queue_free()
