class_name LicenseTab
extends ScrollContainer
## The License tab of the settings, GAME.md 8.5: while the driving school or its test is under way,
## only that, see [method _underway]; otherwise the driver license earned at the driving school,
## 9.4a, which the cursor reaches as it does a button, wearing its mark round it, see [FocusMark],
## to look at in full on accept, a click or a tap, see [LicenseView], and beside it Kit's folder
## once the story has a note in it, opened the same way, STORY.md 7.2, though not while a note
## taken in the map under way waits for the map to be over; with the plate on the back of
## the kart to change under them, 4.4, and a button to retake the test; or, before one is earned,
## a word on where to get one, the button that goes there, and the learner's L the kart wears
## meanwhile. At its foot, whichever it is, the way to the kart dialog of 4.4a, but over a room, and
## the way to the catalog of GAME.md 8.8, which a match's pause menu reaches through here, having
## no room of its own for it.

const NONE_YET := "Missing license."
const HOW := "Pass the driving school's test to earn one. It takes a few minutes."
const EARN := "Earn it now"
const MEANWHILE := "Until then, your kart wears this."
const PLATE_LINE := "Up to %d letters, digits, spaces and dashes, on the back of your kart."
const RETAKE := "Retake the driving test"
const UNDERWAY := "License in progress"
const UNDERWAY_HOW := "You're taking the driving test right now. Finish it to earn your license."
const UNDERWAY_KEPT := "Your current license stays until you pass."
## The story's switch, STORY.md 5.4: on to start with, for the profile playing.
const STORY := "Story Progression"
const STORY_LINE := "The small print, the notes, and where they lead."
## Asked before the story goes off, STORY.md 5.4.
const STORY_OFF := "Turn off Story Progression?"
const STORY_OFF_LINE := (
	"The tables go back to how they were when you started: no notes turn up and nothing moves on."
	+ " Your progress is kept, and you can turn it back on at any time to pick up where you left"
	+ " off."
)
const STORY_OFF_YES := "Turn off"
const STORY_OFF_NO := "Keep on"
## The way to the kart dialog, GAME.md 4.4a, and the line under it.
const KART := "Your kart"
const KART_BUTTON := KartDialog.ENTRY
const KART_LINE := "Its parts, its color, its name and its plate."
## The way to the catalog, GAME.md 8.8, and the lines under it.
const CATALOG := "Catalog"
const CATALOG_BUTTON := "Open the catalog"
const CATALOG_LINE := "Every joker and power-up you have found."
const FOUND := "%d of %d found"
## The way to the achievements, GAME.md 8.10, and the lines under it.
const ACHIEVEMENTS := "Achievements"
const ACHIEVEMENTS_BUTTON := "Open the achievements"
const ACHIEVEMENTS_LINE := "Everything you have set out to do and done."
const EARNED := "%d of %d earned"
## The way to the loyalty program's map, GAME.md 8.9, and the lines over it.
const PROGRAM_LINE := "The House's map of bets, and what each one pays."
const PROGRAM_BUTTON := "Open the map"
const WON := "%d of %d landmarks won"
## The page's heading over the cards, and the line under it: whose it is, its number and its day,
## as the Statistics page says whose record it is.
const TITLE := "License"
const HOLDER := "%s  ·  %s  ·  issued %s"
## The page's tab in the settings, named for what the House calls the player at the story's stage,
## STORY.md 5.1, see [enum Story.Stage]: Me before the story starts, or with it off, which says it
## is the player's own page plainer than anything the House would call them.
const TAB_WORDS: Array[String] = ["Me", "Player", "Participant", "Number", "Candidate", "Operator"]
## The sections under the cards, a grid of them as the Statistics page's groups are: their titles,
## how wide each is, and the air between them.
const PLATE := "Plate"
const SCHOOL := "Driving school"
const PASSED := "Passed on %s."
const STORY_SECTION := "Story"
const SECTION_WIDE := 420.0
const SECTION_GAP := Vector2(72.0, 30.0)
const CARD_SCALE := 0.7
## The folder beside it, as tall as the card, and the room between them.
const FOLDER_SCALE := LicenseCard.SIZE.y * CARD_SCALE / FolderPeek.SIZE.y
const BESIDE := 28.0
## The loyalty card beside the license once the House has welcomed the profile, GAME.md 8.9, as
## tall as it is; under it where the screen has no room across for it as well as the license and
## the folder, the room the settings leave round the page and its scroll bar taken off.
const LOYALTY_SCALE := LicenseCard.SIZE.y * CARD_SCALE / LoyaltyCard.SIZE.y
const PAGE_ROOM := 180.0
## Room kept round whatever has the cursor as the page scrolls to it, and round the page itself,
## so the cursor's mark, which stands out past the license, is never cut off at the page's edge.
const MARK_ROOM := 16
## Under the folder while a note taken in the map under way waits for it to be over.
const WAITING := "Read the new note once the map is over."

var field: PlateField
## The way to the driving school: Earn it now on a tab with no license to show, and Retake the
## driving test under a license.
var earn: Button
var retake: Button
## Whether the story is on for the profile playing, under the license or the word on getting one.
var story_switch: CheckButton
## The question up before the story goes off, or null.
var question: ConfirmPane
## The license in full while it is up.
var view: LicenseView
## The way to the catalog, and the catalog while it is up over the settings; and the same for the
## loyalty program.
var catalog: Button
var catalog_dialog: CatalogDialog
var program: Button
var program_dialog: LoyaltyDialog
var achievements: Button
var achievements_dialog: AchievementsDialog
## The way to the kart dialog, and the dialog while it is up over the settings; none over a room.
var kart: Button
var kart_dialog: KartDialog

## Kit's folder beside the license, once the story has a note in it, and the notes open over the
## settings while they are up, STORY.md 7.2.
var folder: FolderPeek
var notes: NotesFolder
## The loyalty card, and its full view while it is up.
var loyalty_card: Control
var loyalty_view: LoyaltyCardView

var _settings: Settings
## Laid over a room rather than a screen of its own, see [member SettingsScreen.overlay].
var _over_room := false
## The license, which the cursor reaches as it does a button, and what had the cursor before the
## license or the notes came up in full.
var _card: LicenseCard
var _was_focused: Control


## What the page's tab says at the story's [param stage].
static func tab_word(stage: int) -> String:
	return TAB_WORDS[clampi(stage, 0, TAB_WORDS.size() - 1)]


static func make(settings: Settings, over_room := false) -> LicenseTab:
	var tab := LicenseTab.new()
	tab.name = "License"
	tab._settings = settings
	tab._over_room = over_room
	return tab


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Followed here rather than by the container, which shows the control and not its mark.
	follow_focus = false
	get_viewport().gui_focus_changed.connect(_follow)
	var room := MarginContainer.new()
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side: String in ["top", "bottom"]:
		room.add_theme_constant_override("margin_%s" % side, MARK_ROOM)
	add_child(room)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	if DrivingSchool.underway:
		_underway(column)
	elif _settings.license_number.is_empty():
		_none_yet(column)
	else:
		_license(column)
	var grid := _sections(column)
	if not _over_room:
		_kart(grid)
	if _settings.profile.loyalty.welcomed:
		_program(grid)
	_catalog(grid)
	_achievements(grid)
	if not DrivingSchool.underway:
		_story(grid)
	_link_focus(grid)


## The cursor's ways round the page: a row at a time, along it to the left and right and no further,
## and up and down to the one in the same place across the row over or under it, the cards along
## the top, the button to earn a license, then the sections' a grid row at a time; rather than to
## whatever the engine finds nearest that way, which from a section's button low in its box was the
## one beside it. Up from the top row is left to the tabs over the page.
func _link_focus(grid: GridContainer) -> void:
	var rows: Array[Array] = []
	var kept: Array = [_card]
	if loyalty_card != null and loyalty_card.get_parent() == _card_row():
		kept.append(loyalty_card)
	kept.append(folder)
	rows.append(kept)
	if loyalty_card != null and loyalty_card not in kept:
		rows.append([loyalty_card])
	rows.append([earn])
	var sections: Array = []
	for section: Node in grid.get_children():
		sections.append(_taker(section))
	for at: int in range(0, sections.size(), grid.columns):
		rows.append(sections.slice(at, at + grid.columns))
	var ways: Array[Array] = []
	for row: Array in rows:
		var takers := row.filter(
			func(each: Control) -> bool:
				return each != null and each.visible and each.focus_mode != Control.FOCUS_NONE
		)
		if not takers.is_empty():
			ways.append(takers)
	for r: int in ways.size():
		var row: Array = ways[r]
		for c: int in row.size():
			var each: Control = row[c]
			each.focus_neighbor_left = each.get_path_to(row[maxi(c - 1, 0)])
			each.focus_neighbor_right = each.get_path_to(row[mini(c + 1, row.size() - 1)])
			if r > 0:
				each.focus_neighbor_top = each.get_path_to(_across(row, c, ways[r - 1]))
			var under: Control = _across(row, c, ways[r + 1]) if r + 1 < ways.size() else each
			each.focus_neighbor_bottom = each.get_path_to(under)


## The one of [param other] in the same place across it as [param row]'s [param at] is across that:
## the first, from a row of one or to one.
static func _across(row: Array, at: int, other: Array) -> Control:
	if row.size() < 2 or other.size() < 2:
		return other[0]
	return other[roundi(float(at) / float(row.size() - 1) * float(other.size() - 1))]


## The row the license stands in, with the folder and the loyalty card beside it.
func _card_row() -> Node:
	return find_child("Kept", true, false)


## What in [param section] takes the cursor: the plate's field, or its one button or switch.
func _taker(section: Node) -> Control:
	for each: Control in [field, retake, kart, program, catalog, achievements, story_switch]:
		if each != null and section.is_ancestor_of(each):
			return each
	return null


## The grid of sections under what heads the page, see [method _section], made the first time it
## is asked for.
func _sections(column: VBoxContainer) -> GridContainer:
	var grid := column.get_node_or_null("Sections") as GridContainer
	if grid != null:
		return grid
	grid = GridContainer.new()
	grid.name = "Sections"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", roundi(SECTION_GAP.x))
	grid.add_theme_constant_override("v_separation", roundi(SECTION_GAP.y))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 8.0)
	column.add_child(gap)
	column.add_child(grid)
	return grid


## A section of the page named [param named], headed [param title] in gold as the Statistics
## page's groups are, what is in it under the title down its left.
static func _section(named: String, title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = named
	box.custom_minimum_size.x = SECTION_WIDE
	box.add_theme_constant_override("separation", 10)
	var heading := Label.new()
	heading.text = title
	Type.strong(heading, Type.BODY, StatsTab.GROUP_INK)
	box.add_child(heading)
	return box


## A quiet line in a section, wrapped to its width.
static func _section_line(words: String) -> Label:
	var line := Label.new()
	line.text = words
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size.x = SECTION_WIDE
	Type.text(line, Type.LABEL, StatsTab.NAME_INK)
	return line


## The way to the kart dialog, GAME.md 4.4a, over the screen the settings are on, as the catalog's
## is: what it changes, and the button that opens it. Not over a room: its menu has its own way in
## where a kart can be changed, see [method PauseMenu.offer_kart].
func _kart(grid: GridContainer) -> void:
	var section := _section("KartSection", KART)
	section.add_child(_section_line(KART_LINE))
	kart = MenuTheme.button(KART_BUTTON, Type.BODY)
	kart.name = "Kart"
	kart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	kart.pressed.connect(open_kart)
	section.add_child(kart)
	grid.add_child(section)


## The kart dialog over the whole screen the settings are on; put away, the cursor goes back where
## it was, and the license's photo shows the kart as it now is.
func open_kart() -> void:
	if kart_dialog != null:
		return
	kart_dialog = KartDialog.open(_over())
	kart_dialog.put_away.connect(
		func() -> void:
			kart_dialog = null
			if _card != null:
				_card.dress_from_settings()
	)


## The way to the catalog, GAME.md 8.8, over the screen the settings are on: from a room's pause
## menu too, which has no room of its own for it; with how much of it has been found.
func _catalog(grid: GridContainer) -> void:
	var section := _section("CatalogSection", CATALOG)
	var ids := CatalogDialog.page_ids()
	var found := 0
	var every := 0
	for page: Array in ids:
		var listed: Array[StringName] = []
		listed.assign(page)
		found += _settings.profile.catalog.found_of(listed)
		every += page.size()
	section.add_child(_section_line(CATALOG_LINE))
	var count := _section_line(FOUND % [found, every])
	count.name = "Found"
	count.add_theme_color_override("font_color", StatsTab.VALUE_INK)
	section.add_child(count)
	catalog = MenuTheme.button(CATALOG_BUTTON, Type.BODY)
	catalog.name = "Catalog"
	catalog.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	catalog.pressed.connect(open_catalog)
	section.add_child(catalog)
	grid.add_child(section)


## The way to the loyalty program's map, GAME.md 8.9, for a profile the House has welcomed to it,
## as the catalog's is: what it is, how many of its landmarks are won, and the button that opens it.
func _program(grid: GridContainer) -> void:
	var profile := _settings.profile
	var section := _section("ProgramSection", LoyaltyDialog.program_name(profile))
	section.add_child(_section_line(PROGRAM_LINE))
	var won := 0
	var every := 0
	for landmark: LoyaltyLandmark in Loyalty.map().landmarks:
		if Loyalty.is_drawn(profile, landmark):
			every += 1
			won += 1 if profile.loyalty.has_won(landmark.id) else 0
	var count := _section_line(WON % [won, every])
	count.name = "Won"
	count.add_theme_color_override("font_color", StatsTab.VALUE_INK)
	section.add_child(count)
	program = MenuTheme.button(PROGRAM_BUTTON, Type.BODY)
	program.name = "Program"
	program.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	program.pressed.connect(open_program)
	section.add_child(program)
	grid.add_child(section)


## The loyalty program over the whole screen the settings are on, at its map; put away, the cursor
## goes back where it was.
func open_program() -> void:
	if program_dialog != null:
		return
	program_dialog = LoyaltyDialog.open(_over())
	program_dialog.put_away.connect(func() -> void: program_dialog = null)


## The way to the achievements, GAME.md 8.10, as the catalog's is: what they are, how many are
## earned of how many, and the button that opens them over the screen the settings are on.
func _achievements(grid: GridContainer) -> void:
	var section := _section("AchievementsSection", ACHIEVEMENTS)
	section.add_child(_section_line(ACHIEVEMENTS_LINE))
	var profile := _settings.profile
	var earned := _section_line(
		EARNED % [Achievements.earned_count(profile), Achievements.all().size()]
	)
	earned.name = "Earned"
	earned.add_theme_color_override("font_color", StatsTab.VALUE_INK)
	section.add_child(earned)
	achievements = MenuTheme.button(ACHIEVEMENTS_BUTTON, Type.BODY)
	achievements.name = "Achievements"
	achievements.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	achievements.pressed.connect(open_achievements)
	section.add_child(achievements)
	grid.add_child(section)


## The achievements over the whole screen the settings are on; put away, the cursor goes back where
## it was.
func open_achievements() -> void:
	if achievements_dialog != null:
		return
	achievements_dialog = AchievementsDialog.open(_over())
	achievements_dialog.put_away.connect(func() -> void: achievements_dialog = null)


## The catalog over the whole screen the settings are on; put away, the cursor goes back where it
## was.
func open_catalog() -> void:
	if catalog_dialog != null:
		return
	catalog_dialog = CatalogDialog.open(_over())
	catalog_dialog.put_away.connect(func() -> void: catalog_dialog = null)


## In the school or its test: what is under way, and no way to the school, which would leave the
## test for the start of another. A license already held stays until the new one is earned.
func _underway(column: VBoxContainer) -> void:
	column.add_child(MenuTheme.title(UNDERWAY, Type.HEADING))
	column.add_child(MenuTheme.subtitle(UNDERWAY_HOW, Type.BODY))
	if not _settings.license_number.is_empty():
		column.add_child(MenuTheme.subtitle(UNDERWAY_KEPT, Type.LABEL))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 8.0)
	column.add_child(gap)
	var learner := SchoolFigure.of(SchoolFigure.Kind.LEARNER, 96.0)
	learner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(learner)


## No license: where to get one, and the L worn until then.
func _none_yet(column: VBoxContainer) -> void:
	column.add_child(MenuTheme.title(NONE_YET, Type.HEADING))
	column.add_child(MenuTheme.subtitle(HOW, Type.BODY))
	earn = MenuTheme.button(EARN)
	earn.name = "Earn"
	earn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	earn.pressed.connect(_to_the_school)
	column.add_child(earn)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 8.0)
	column.add_child(gap)
	var learner := SchoolFigure.of(SchoolFigure.Kind.LEARNER, 96.0)
	learner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(learner)
	column.add_child(MenuTheme.subtitle(MEANWHILE, Type.LABEL))


## The license, stamped as it was, Kit's folder beside it while the story has a note in it, under
## the page's heading saying whose it is; and under them the sections: the plate, the school, the
## story and the catalog.
func _license(column: VBoxContainer) -> void:
	var profile := _settings.profile
	column.add_child(MenuTheme.title(TITLE, Type.HEADING))
	var holder := (
		HOLDER
		% [
			(
				profile.license_holder
				if not profile.license_holder.is_empty()
				else profile.display_name()
			),
			profile.license_number,
			profile.license_date
		]
	)
	column.add_child(MenuTheme.subtitle(holder, Type.LABEL))
	var row := HBoxContainer.new()
	row.name = "Kept"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", roundi(BESIDE))
	column.add_child(row)
	_card = LicenseCard.from_settings()
	_card.name = "LicenseCard"
	row.add_child(_held(_card, LicenseCard.SIZE, CARD_SCALE))
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.focus_mode = Control.FOCUS_ALL
	_card.gui_input.connect(_on_card_input)
	# Under the mouse it takes the cursor, mark and all, as the catalog's cards do, to say it can be
	# clicked.
	if not TouchInput.enabled:
		_card.mouse_entered.connect(_card.grab_focus)
	# The cursor's mark round it, as round any button, see [FocusMark].
	var mark := Control.new()
	mark.name = "FocusMark"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.size = LicenseCard.SIZE
	mark.draw.connect(
		func() -> void:
			if _card.has_focus():
				var whole := Rect2(Vector2.ZERO, LicenseCard.SIZE)
				FocusMark.draw_on(mark, whole, LicenseCard.RADIUS, SIDE_LEFT, CARD_SCALE)
	)
	_card.add_child(mark)
	_card.focus_entered.connect(mark.queue_redraw)
	_card.focus_exited.connect(mark.queue_redraw)
	var found := not profile.story.notes.is_empty() or profile.story.ended()
	if Story.on_here() and found:
		folder = FolderPeek.new()
		folder.name = "Folder"
		folder.standing = true
		folder.waiting = NoteDealer.taken_here(get_tree())
		folder.corner = FolderPeek.first_new(profile.story)
		folder.opened.connect(show_notes)
		var side := VBoxContainer.new()
		side.name = "FolderSide"
		side.add_theme_constant_override("separation", 8)
		side.add_child(_held(folder, FolderPeek.SIZE, FOLDER_SCALE))
		if folder.waiting:
			folder.tooltip_text = WAITING
			var line := MenuTheme.subtitle(WAITING, Type.LABEL)
			line.name = "Waiting"
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.custom_minimum_size.x = FolderPeek.SIZE.x * FOLDER_SCALE
			side.add_child(line)
		row.add_child(side)
	if profile.loyalty.welcomed:
		loyalty_card = LoyaltyCardView.corner(profile, LOYALTY_SCALE, show_loyalty_card)
		loyalty_card.name = "LoyaltyCard"
		var across := LicenseCard.SIZE.x * CARD_SCALE + BESIDE + LoyaltyCard.SIZE.x * LOYALTY_SCALE
		if folder != null:
			across += BESIDE + FolderPeek.SIZE.x * FOLDER_SCALE
		if across <= get_viewport_rect().size.x - PAGE_ROOM:
			# Next to the license, in the wallet's order: the school's, the House's, then Kit's.
			row.add_child(loyalty_card)
			row.move_child(loyalty_card, 1)
		else:
			column.add_child(loyalty_card)
	var grid := _sections(column)
	var plate := _section("PlateSection", PLATE)
	field = PlateField.make(_settings.license_plate)
	field.plate_changed.connect(_on_plate_typed)
	var typed := HBoxContainer.new()
	typed.add_theme_constant_override("separation", 16)
	typed.add_child(field)
	var how := PlateField.hint(StatsTab.NAME_INK, Type.LABEL)
	how.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	typed.add_child(how)
	plate.add_child(typed)
	plate.add_child(_section_line(PLATE_LINE % LicensePlate.MOST))
	grid.add_child(plate)
	var school := _section("SchoolSection", SCHOOL)
	school.add_child(_section_line(PASSED % profile.license_date))
	retake = MenuTheme.button(RETAKE, Type.BODY)
	retake.name = "Retake"
	retake.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	retake.pressed.connect(_to_the_school)
	school.add_child(retake)
	grid.add_child(school)


## The story's switch, STORY.md 5.4, for the profile playing: off, its clock stops and the game is
## the casino of the first stage throughout; on again, everything is where it was. Kept with the
## rest of the settings as they are left.
func _story(grid: GridContainer) -> void:
	var section := _section("StorySection", STORY_SECTION)
	story_switch = MenuTheme.toggle(_settings.profile.story.on)
	story_switch.name = "Story"
	story_switch.toggled.connect(_on_story_toggled)
	var line := MenuTheme.row(STORY, story_switch)
	line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	section.add_child(line)
	section.add_child(_section_line(STORY_LINE))
	grid.add_child(section)


## On at once; off only once asked, the switch staying on until the answer is yes.
func _on_story_toggled(on: bool) -> void:
	if on:
		_settings.profile.story.on = true
		return
	story_switch.set_pressed_no_signal(true)
	if question == null:
		_ask_story_off()


## Asks over the screen whether the story is to go off, saying it can come on again at any time;
## the cursor back on the switch either way.
func _ask_story_off() -> void:
	var holder := Control.new()
	holder.name = "StoryOff"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	_over().add_child(holder)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(middle)
	question = ConfirmPane.new()
	middle.add_child(question)
	question.answered.connect(
		func(yes: bool) -> void:
			holder.queue_free()
			question = null
			if yes:
				_settings.profile.story.on = false
				story_switch.set_pressed_no_signal(false)
			if is_instance_valid(story_switch) and story_switch.is_inside_tree():
				story_switch.grab_focus()
	)
	question.ask(STORY_OFF, STORY_OFF_LINE, STORY_OFF_YES, STORY_OFF_NO, RoadSign.Kind.QUESTION)


## The page scrolled to [param control] when it takes the cursor, with [constant MARK_ROOM] round
## it, as far as the page goes.
func _follow(control: Control) -> void:
	if control == null or not is_visible_in_tree() or not is_ancestor_of(control):
		return
	var view := get_global_rect()
	var wanted := control.get_global_rect().grow(MARK_ROOM)
	if wanted.position.y < view.position.y:
		scroll_vertical -= ceili(view.position.y - wanted.position.y)
	elif wanted.end.y > view.end.y:
		scroll_vertical += ceili(wanted.end.y - view.end.y)


## [param shown] drawn at [param scale] in a place of its own in a row, [param size] big there.
static func _held(shown: Control, size: Vector2, scale: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = size * scale
	# Tops in line, the folder as tall as the card, whatever is said under the folder.
	holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shown.scale = Vector2.ONE * scale
	shown.position = (size * scale - size) * 0.5
	holder.add_child(shown)
	return holder


## Accept with the cursor on the card, or a click or a tap on it, shows it in full.
func _on_card_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (
		(click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
		or (touch != null and touch.pressed)
		or event.is_action_pressed(&"ui_accept")
	):
		get_viewport().set_input_as_handled()
		look_closer()


## The license in full over the whole screen the settings are on, growing up off the card and
## going back down onto it as the title shows it; put away, the cursor goes back where it was.
func look_closer() -> void:
	if view != null:
		return
	_was_focused = get_viewport().gui_get_focus_owner()
	view = LicenseView.open(_over(), Game.last_input_keyboard, _card)
	view.put_away.connect(_on_put_away)


func _on_put_away() -> void:
	view = null
	if _was_focused != null and is_instance_valid(_was_focused):
		LicenseView.give_cursor(_was_focused)


## The loyalty card in full over the whole screen the settings are on, growing up off its place
## beside the license as in the program, GAME.md 8.9; put away, the cursor back on it.
func show_loyalty_card() -> void:
	if loyalty_view != null:
		return
	var over := _over() as Control
	var keyboard := Game.last_input_keyboard
	loyalty_view = LoyaltyCardView.open(over, _settings.profile, loyalty_card, keyboard)
	loyalty_view.put_away.connect(
		func() -> void:
			loyalty_view = null
			if is_instance_valid(loyalty_card) and loyalty_card.is_inside_tree():
				loyalty_card.grab_focus()
	)


## Kit's notes open over the whole screen the settings are on, STORY.md 7.2, out of the folder
## beside the license; put away, the cursor goes back where it was, and the folder says what is
## still new.
func show_notes() -> void:
	if notes != null:
		return
	_was_focused = get_viewport().gui_get_focus_owner()
	notes = NotesFolder.open(_over(), _settings.profile, Game.last_input_keyboard, folder)
	notes.put_away.connect(_on_notes_put_away)


func _on_notes_put_away() -> void:
	notes = null
	if folder != null and is_instance_valid(folder):
		folder.corner = FolderPeek.first_new(_settings.profile.story)
		folder.queue_redraw()
	if _was_focused != null and is_instance_valid(_was_focused):
		_was_focused.grab_focus()


## What the license, the notes, the catalog and the question come up over: the whole screen the
## tab is on, or with the tab on its own, whatever holds it.
func _over() -> Node:
	var top: Control = self
	while top.get_parent() is Control:
		top = top.get_parent() as Control
	return top if top != self else get_parent()


## Out of whatever room the settings were opened over, and to the school.
func _to_the_school() -> void:
	Net.close()
	Game.go_to_tutorial()


## The plate as typed, cleaned on the way, see [PlateField].
func _on_plate_typed(cleaned: String) -> void:
	_settings.license_plate = cleaned
