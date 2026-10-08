class_name LicenseTab
extends ScrollContainer
## The License tab of the settings, GAME.md 8.5: while the driving school or its test is under way,
## only that, see [method _underway]; otherwise the driver license earned at the driving school,
## 9.4a, which the cursor reaches as it does a button, wearing its mark round it, see [FocusMark],
## to look at in full on accept, a click or a tap, see [LicenseView], and beside it Kit's folder
## once the story has a note in it, opened the same way, STORY.md 7.2, though not over a room,
## where a map's note would be read before its map was over; with the plate on the back of
## the kart to change under them, 4.4, and a button to retake the test; or, before one is earned,
## a word on where to get one, the button that goes there, and the learner's L the kart wears
## meanwhile. At its foot, whichever it is, the way to the catalog of GAME.md 8.8, which a match's
## pause menu reaches through here, having no room of its own for it.

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
## The way to the catalog, GAME.md 8.8, and the line under it.
const CATALOG := "Catalog"
const CATALOG_LINE := "Every joker and power-up you have found."
const CARD_SCALE := 0.7
## The folder beside it, as tall as the card, and the room between them.
const FOLDER_SCALE := LicenseCard.SIZE.y * CARD_SCALE / FolderPeek.SIZE.y
const BESIDE := 28.0
## Room kept round whatever has the cursor as the page scrolls to it, and round the page itself,
## so the cursor's mark, which stands out past the license, is never cut off at the page's edge.
const MARK_ROOM := 16

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
## The way to the catalog, and the catalog while it is up over the settings.
var catalog: Button
var catalog_dialog: CatalogDialog

## Kit's folder beside the license, once the story has a note in it, and the notes open over the
## settings while they are up, STORY.md 7.2.
var folder: FolderPeek
var notes: NotesFolder

var _settings: Settings
## Laid over a room from its pause menu rather than on the settings' own screen.
var _over_room := false
## The license, which the cursor reaches as it does a button, and what had the cursor before the
## license or the notes came up in full.
var _card: LicenseCard
var _was_focused: Control


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
	_catalog(column)


## The way to the catalog, GAME.md 8.8, over the screen the settings are on: from a room's pause
## menu too, which has no room of its own for it.
func _catalog(column: VBoxContainer) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap)
	catalog = MenuTheme.button(CATALOG, Type.BODY)
	catalog.name = "Catalog"
	catalog.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	catalog.pressed.connect(open_catalog)
	column.add_child(catalog)
	column.add_child(MenuTheme.subtitle(CATALOG_LINE, Type.LABEL))


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
	_story(column)


## The license, stamped as it was, Kit's folder beside it while the story has a note in it, and
## the plate under them.
func _license(column: VBoxContainer) -> void:
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
	var profile := _settings.profile
	var found := not profile.story.notes.is_empty() or profile.story.ended()
	if not _over_room and Story.on_here() and found:
		folder = FolderPeek.new()
		folder.name = "Folder"
		folder.standing = true
		folder.corner = FolderPeek.first_new(profile.story)
		folder.opened.connect(show_notes)
		row.add_child(_held(folder, FolderPeek.SIZE, FOLDER_SCALE))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap)
	field = PlateField.make(_settings.license_plate)
	field.plate_changed.connect(_on_plate_typed)
	column.add_child(PlateField.row("License plate", field))
	column.add_child(MenuTheme.subtitle(PLATE_LINE % LicensePlate.MOST, Type.LABEL))
	var gap_after := Control.new()
	gap_after.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap_after)
	retake = MenuTheme.button(RETAKE, Type.BODY)
	retake.name = "Retake"
	retake.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retake.pressed.connect(_to_the_school)
	column.add_child(retake)
	_story(column)


## The story's switch, STORY.md 5.4, for the profile playing: off, its clock stops and the game is
## the casino of the first stage throughout; on again, everything is where it was. Kept with the
## rest of the settings as they are left.
func _story(column: VBoxContainer) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(gap)
	story_switch = MenuTheme.toggle(_settings.profile.story.on)
	story_switch.name = "Story"
	story_switch.toggled.connect(_on_story_toggled)
	var line := MenuTheme.row(STORY, story_switch)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(line)
	column.add_child(MenuTheme.subtitle(STORY_LINE, Type.LABEL))


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
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
		_was_focused.grab_focus()


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
