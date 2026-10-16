extends GdUnitTestSuite
## A screen reader, GAME.md 8.5: the project leaves the engine's support for one on, everything
## that takes the cursor is called something, what the game draws for itself is named from the
## words the screen shows for it, and what comes up without the cursor going to it is said.

const TITLE_SCENE := preload("res://scenes/ui/title.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
const PATH := "user://test_screen_reader.cfg"
## What the project setting is when screen readers are switched off, see
## [code]accessibility/general/accessibility_support[/code].
const DISABLED := 2

var _settings_were: Settings
var _runner: GdUnitSceneRunner


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH


func after_test() -> void:
	Story.override = -1
	PlayerInput.typing = false
	Game.settings = _settings_were
	Settings.remove_files(PATH)


## Everything showing in [param root] that the cursor can be taken to.
static func _cursor_stops(root: Node) -> Array[Control]:
	var stops: Array[Control] = []
	for each: Node in root.find_children("*", "Control", true, false):
		var control := each as Control
		if control.is_visible_in_tree() and control.focus_mode == Control.FOCUS_ALL:
			stops.append(control)
	return stops


## Whatever in [param root] the cursor can be taken to that a screen reader would call nothing.
static func _unnamed(root: Node) -> Array[String]:
	var unnamed: Array[String] = []
	for control: Control in _cursor_stops(root):
		if control is TabBar or control is RichTextLabel or control is LinkButton:
			continue
		if ScreenReader.heard(control).strip_edges().is_empty():
			unnamed.append(str(root.get_path_to(control)))
	return unnamed


## On while a screen reader runs, Auto, and nothing paid for it while none does; and every export
## built on the engine's own templates, which carry its support, rather than a template of our own.
func test_the_project_leaves_screen_readers_on() -> void:
	var support: int = ProjectSettings.get_setting("accessibility/general/accessibility_support")
	assert_int(support).is_not_equal(DISABLED)
	var driver: String = ProjectSettings.get_setting("accessibility/general/accessibility_driver")
	assert_str(driver).is_equal("accesskit")
	var presets := ConfigFile.new()
	assert_int(presets.load("res://export_presets.cfg")).is_equal(OK)
	for section: String in presets.get_sections():
		if section.ends_with(".options"):
			for template: String in ["custom_template/debug", "custom_template/release"]:
				assert_str(str(presets.get_value(section, template, ""))).is_empty()


## The House's capitals are said as a sentence and its middle dots as pauses; a line leaves out
## what is empty and what says the same as the part before it.
func test_the_house_print_is_said_as_words() -> void:
	assert_str(ScreenReader.spoken("THE GARAGE  ·  BAY 1")).is_equal("The garage, bay 1")
	assert_str(ScreenReader.spoken("YOUR KART")).is_equal("Your kart")
	assert_str(ScreenReader.line(["Seat 1", "", "Seat 1", "K  ·  Kart"])).is_equal(
		"Seat 1, K, Kart"
	)
	assert_str(ScreenReader.switched("Detailed", true)).is_equal("Detailed, On")


## A row of settings names what stands beside its label: a slider, the slider in a box with its
## value beside it, a box to pick from; the two ways to drive keep their own names, and a button
## with words of its own its words, each told the row's after them.
func test_a_settings_row_names_what_stands_beside_its_label() -> void:
	var slider := HSlider.new()
	auto_free(MenuTheme.row("Music", slider))
	assert_str(slider.accessibility_name).is_equal("Music")
	var swell := SwellSlider.make(0.4)
	auto_free(MenuTheme.row("Intense music", swell))
	assert_str(swell.slider.accessibility_name).is_equal("Intense music")
	var option := MenuTheme.option(["Off", "Full"], 1)
	auto_free(MenuTheme.row("Crowd", option))
	assert_str(option.accessibility_name).is_equal("Crowd")
	var both := HBoxContainer.new()
	var picker := DrivePicker.make(Settings.DRIVE_SIMPLE)
	both.add_child(picker)
	var help := MenuTheme.button("Help me choose")
	both.add_child(help)
	auto_free(MenuTheme.row("Driving", both))
	var simple := picker.button(Settings.DRIVE_SIMPLE)
	assert_str(simple.accessibility_name).is_equal(DrivePicker.WORDS[Settings.DRIVE_SIMPLE])
	assert_str(simple.accessibility_description).is_equal("Driving")
	assert_str(help.accessibility_name).is_empty()
	assert_str(ScreenReader.heard(help)).is_equal("Help me choose")
	assert_str(help.accessibility_description).is_equal("Driving")


## Every page of the settings has a name for everything on it the cursor goes to: the Audio page's
## sliders by their rows, the Controls page's sockets by their action, column and keys.
func test_every_page_of_the_settings_names_what_the_cursor_goes_to() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	await await_idle_frame()
	for i: int in screen.tabs.get_tab_count():
		screen.tabs.current_tab = i
		await await_idle_frame()
		var page := screen.tabs.get_current_tab_control()
		var unnamed := _unnamed(page)
		var on := "Unnamed on %s: %s" % [screen.tabs.get_tab_title(i), unnamed]
		assert_array(unnamed).override_failure_message(on).is_empty()
	var sliders := screen.find_children("*", "HSlider", true, false)
	var music := func(each: Node) -> bool: return (each as Control).accessibility_name == "Music"
	assert_bool(sliders.any(music)).is_true()
	var socket_named := func(each: Node) -> bool:
		return (each as Control).accessibility_name == "Fire, Keyboard and mouse"
	assert_bool(screen.find_children("*", "Button", true, false).any(socket_named)).is_true()


## The title names what peeks in at its edges from what is drawn on them: the license by its title
## with what its face says, Kit's folder by the words across it and whether a new note sticks out
## of it, and the bay by the kart dialog's name; and everything on it the cursor goes to.
func test_the_title_names_what_peeks_in_at_its_edges() -> void:
	Story.override = Story.Stage.PLAYER
	var settings := Game.settings
	settings.license_number = "JJ-212212"
	settings.license_holder = "Snake Eyes Sam"
	settings.profile.story.notes = PackedInt32Array([1, 2])
	settings.profile.story.notes_read = PackedInt32Array([1])
	var title: Control = auto_free(TITLE_SCENE.instantiate())
	add_child(title)
	await await_idle_frame()
	var license := title.find_child("LicensePeek", true, false) as LicenseCard
	assert_str(license.accessibility_name).is_equal("Driver license")
	assert_str(license.accessibility_description).contains("Snake Eyes Sam").contains("JJ-212212")
	var folder := title.find_child("FolderPeek", true, false) as FolderPeek
	assert_str(folder.accessibility_name).is_equal(ScreenReader.spoken(StoryLines.FOLDER_FRONT))
	assert_str(folder.accessibility_description).contains(FolderPeek.TOLD_NEW)
	folder.corner = 0
	assert_str(folder.accessibility_description).is_equal(FolderPeek.TOLD)
	var bay := title.find_child("BayPeek", true, false) as BayPeek
	assert_str(bay.accessibility_name).is_equal(KartDialog.ENTRY)
	assert_str(bay.accessibility_description).is_equal(LicenseTab.KART_LINE)
	title.call(&"show_clubhouse", true)
	await await_idle_frame()
	assert_array(_unnamed(title)).is_empty()


## The kart dialog names what it draws: each hook by its part with the piece worn on it, the name
## box and the plate by the words painted over them, a can by its color and whose it is, and each
## piece on a part's rack as its tape says, the one worn ON.
func test_the_kart_dialog_names_its_hooks_cans_and_rack() -> void:
	Game.settings.set_seat_style(0, PackedInt32Array([1, 4, 2, 0, 0, 0]))
	Game.settings.set_seat_color(0, 3)
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	var dialog := KartDialog.open(holder)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_str(dialog.hooks[1].accessibility_name).is_equal("Hat")
	assert_str(dialog.hooks[1].accessibility_description).is_equal("Party")
	assert_str(dialog.hooks[BoardArt.SHUFFLE].accessibility_name).is_equal("Shuffle")
	assert_str(dialog.name_box.accessibility_name).is_equal("Name")
	assert_str(dialog.plate_field.accessibility_name).is_equal("Plate")
	assert_str(ScreenReader.heard(dialog.cans[3])).is_equal(Palette.color_name(3))
	assert_str(dialog.cans[3].accessibility_description).is_equal("Yours")
	assert_str(ScreenReader.heard(dialog.die)).is_equal(KartDialog.DIE_TIP)
	assert_array(_unnamed(dialog)).is_empty()
	dialog.open_tray(1)
	await get_tree().process_frame
	var worn := dialog.tray.cell_at(KartStyle.HATS.find("Party"))
	assert_str(worn.accessibility_name).is_equal("Party")
	assert_str(worn.accessibility_description).is_equal("On")
	assert_str(dialog.tray.cell_at(0).accessibility_description).is_empty()
	assert_str(ScreenReader.said(dialog.tray)).starts_with("Hats")
	assert_array(_unnamed(dialog)).is_empty()


## A card of the catalog is named for the card in it, with its suit, rarity, kind and words and
## its NEW tag; one never found says so.
func test_a_catalog_card_is_named_for_its_joker() -> void:
	var joker: Joker = CATALOG.jokers[0]
	var make := func() -> Control: return JokerCard.create(joker)
	var cell: CatalogCell = auto_free(CatalogCell.holding(joker.id, true, make))
	assert_str(cell.accessibility_name).is_equal(joker.display_name)
	var told := cell.accessibility_description
	assert_str(told).contains(JokerSuits.name_of(joker.suit)).contains(joker.describe())
	cell.set_fresh(true)
	assert_str(cell.accessibility_description).is_equal("New, " + told)
	var lost := func() -> Control: return DieLine.new()
	var unknown: CatalogCell = auto_free(CatalogCell.holding(joker.id, false, lost))
	assert_str(unknown.accessibility_name).is_equal(CatalogDialog.NOT_FOUND)


## A joker's card is named for it wherever it is shown, its suit, how rare it is, its kind and its
## words after its name, as its corner, its pips and its pane say.
func test_a_joker_card_is_named_for_its_joker() -> void:
	for joker: Joker in CATALOG.jokers.slice(0, 5):
		var card: JokerCard = auto_free(JokerCard.create(joker))
		assert_str(card.accessibility_name).is_equal(joker.display_name)
		assert_str(card.accessibility_description).is_equal(JokerCard.told(joker))
		var told := JokerCard.told(joker)
		assert_str(told).contains(JokerCard.rarity_name(joker)).contains(joker.describe())


## The respawn pick takes no cursor, so the card under the seat's is said as it comes to it: the
## question, which card of how many, its name and its words; and again only as it moves on.
func test_the_pick_says_the_card_under_the_cursor() -> void:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 21)
	var kart := match_node.kart_of(0)
	var offer := JokerOffer.new(kart, CATALOG.offer(match_node.rng, 3, []))
	var picker: JokerPicker = auto_free(JokerPicker.new())
	add_child(picker)
	await await_idle_frame()
	picker.size = Vector2(1920.0, 1080.0)
	picker.show_offer(offer, kart)
	var first := ScreenReader.said(picker)
	assert_str(first).starts_with("Pick a joker, 1 of %d" % offer.choices.size())
	assert_str(first).contains(offer.choices[0].display_name)
	offer.selected = 1
	picker.show_offer(offer, kart)
	assert_str(ScreenReader.said(picker)).starts_with("2 of %d" % offer.choices.size())
	assert_str(ScreenReader.said(picker)).contains(offer.choices[1].display_name)


## What comes up by itself is said as it comes: a notice, once put away said again the next time;
## the status of a room, read out as it changes; a question, read as a dialog of it; the lamps of
## the start, as each one lights.
func test_what_comes_up_by_itself_is_said() -> void:
	var notice := NoticePane.tell(self, "Host left", "The game is over.")
	auto_free(notice)
	await await_idle_frame()
	assert_str(ScreenReader.said(notice)).is_equal("Host left, The game is over.")
	notice.close()
	assert_str(ScreenReader.said(notice)).is_empty()
	var status := StatusPane.add_to(self)
	auto_free(status)
	var words := status.find_children("*", "Label", true, false)[0] as Label
	assert_int(words.accessibility_live).is_equal(AccessibilityServer.LIVE_POLITE)
	# Hidden with its layer, so what it said last is not left for a reader to come across.
	assert_bool(words.is_visible_in_tree()).is_false()
	status.say("Connecting...")
	assert_bool(words.is_visible_in_tree()).is_true()
	var question: ConfirmPane = auto_free(ConfirmPane.new())
	add_child(question)
	question.ask("Leave the match?", "Your chips stay on the table.", "Leave")
	assert_str(question.accessibility_name).is_equal("Leave the match?")
	assert_str(question.accessibility_description).is_equal("Your chips stay on the table.")
	var light: StartLight = auto_free(StartLight.new())
	add_child(light)
	light.set_countdown(2)
	assert_str(ScreenReader.said(light)).is_equal("2")
	light.set_go()
	assert_str(ScreenReader.said(light)).is_equal("2")
