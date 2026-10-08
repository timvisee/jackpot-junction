extends Control
## The title screen from GAME.md 3.8: Play, Play Online, the Driving School, Extras, Settings,
## Quit, Extras putting the Garage practice room and the Catalog of 8.8 in the buttons' place, over
## the turning sunburst of [TitleBackground]; every way in to driving asks for the license of 9.4a
## until it is earned, and the license earned peeks in from the right edge; Kit's notes, once one
## is found, peek in from the left, STORY.md 7.2. The first time it comes up in a run, it opens
## with the mark, see [TitleIntro].

## Room kept under the buttons, clear of the bottom edge of the screen. Who made the music, the
## models and the sounds is said in Settings, About, see [AboutTab], rather than along it.
const BOTTOM_ROOM := 24.0
## The microprint under the name, GAME.md 8.1a, between two rules of foil, and how long they are.
const MICROPRINT := "Dept. of Karts  ·  licensed on every table"
const MICRO_RULE := 150.0
## What is asked before driving without a license, GAME.md 9.4a.
const LICENSE_QUESTION := "Missing license"
const LICENSE_LINE := (
	"Nobody drives the Junction without one. " + "Earn your very own license at the driving school."
)
## The license earned, GAME.md 9.4a, peeking in from the right edge the way a card in a hand
## does: how big, how much of it shows, how far it leans, where it sits over the version line,
## and how far in it comes under the cursor.
const LICENSE_SCALE := 0.78
const LICENSE_PEEK := 0.68
const LICENSE_TILT := -0.14
const LICENSE_TILT_SHOWN := -0.04
const LICENSE_BOTTOM := 72.0
const LICENSE_IN := 28.0
const LICENSE_SLIDE := 0.25
## The license peeking in is dimmed a little, so it does not take the eye from the buttons; slid
## out under the cursor it is as it is.
const LICENSE_DIM := Color(0.74, 0.74, 0.78, 0.86)
## The flyer for the driving school: how far from the button it stands, and from the screen's
## edge at the least.
const AD_GAP := 18.0
const AD_EDGE := 16.0
## The Operator's line along the foot after the ending, STORY.md 8.6: its size and how far up.
const STATUS_SIZE := Type.BODY
## The hints at the license and the folder for keys and pads, see [method _show_peek_hints]: how
## big, and how far over the foot of the screen, in its bottom corners.
const LICENSE_GLYPH_SIZE := 24
const LICENSE_GLYPH_BOTTOM := 44.0
## The opening, GAME.md 8.1a, in seconds from its start, see [TitleIntro]: the backdrop and the glow
## round the mark come up while it flies to its place, then the seal's rings and then the sunburst;
## the words under the mark one after another; the buttons dealt one by one; and last whatever
## peeks in at the edges, the license, Kit's folder, the flyer and the version.
const OPEN_BACKDROP := Vector2(0.65, 1.5)
const OPEN_RINGS := Vector2(1.05, 1.7)
const OPEN_BEAMS := Vector2(1.35, 2.2)
const OPEN_WORDS := 1.25
const OPEN_WORD_STEP := 0.12
const OPEN_BUTTONS := 1.6
const OPEN_BUTTON_STEP := 0.06
const OPEN_RISE := 0.3
const OPEN_EDGES := Vector2(2.0, 2.5)

var play_button: Button
## The shaders compiling, said over the title while they do, or null, see [WarmupPane].
var warming: WarmupPane
## The invitation that brought the player here while it is up, STORY.md 6.1a.
var invitation: OpeningInvitation

var _column: VBoxContainer
## The mark over the name, which goes on a screen too short for it and the buttons both: a big UI
## scale on a short screen, GAME.md 8.5. The buttons are what the screen is for. And after it, on a
## screen shorter still, the gap over the buttons and the line under the name, in that order.
var _mark: Control
var _spare: Array[Control] = []
## The license peeking in, where there is one, whether it is out under the cursor, and the view
## of it in full while one is up.
var _license: LicenseCard
var _license_out := false
var _license_view: LicenseView
## What had the cursor when the license was shown in full, for it to go back to.
var _license_from: Control
## The hints at the license and the folder, see [method _show_peek_hints]; which device they are
## drawn for, picked up from whatever was last touched anywhere in the game; and whether the mouse
## is in hand, which has none drawn.
var _license_glyph: Control
var _folder_glyph: Control
var _keyboard := true
var _pointer := false
## The question whether to earn the license, while it is up, and what had the cursor before it.
var _license_question: Control
var _question_from: Control
## The Driving School button, and the flyer pointing at it while there is no license yet, or the
## House's pointing at Play while the Final Hand is due, and the button it points at.
var _school_button: Button
var _ad: SchoolAd
var _ad_button: Button
## Kit's notes peeking in from the left once one has been found, the folder open over the title
## while it is, and what had the cursor before it, STORY.md 7.2.
var _folder: FolderPeek
var _notes: NotesFolder
var _notes_from: Control
## The opening while it plays, see [TitleIntro]; the cursor, the hints and the warm-up wait on it.
var _intro: TitleIntro
## The catalog of every joker and power-up taken, GAME.md 8.8, over the title while it is up.
var _catalog: CatalogDialog
## The loyalty program over the title while it is up, GAME.md 8.9, and the first of Extras' buttons
## that opens it, there once the profile playing has been welcomed to it.
var _loyalty: LoyaltyDialog
var _loyalty_button: Button
## The title's own buttons, the ones Extras puts in their place, GAME.md 3.8, and Extras itself, for
## the cursor to go back to.
var _main: Array[Control] = []
var _extras: Array[Control] = []
var _extras_button: Button
## Under Extras' buttons while they are up, as tall as the title's own they stand in for less their
## own, so the column keeps its height and the mark and the name stay where they are.
var _extras_room: Control


func _ready() -> void:
	var column := MenuTheme.screen(self, 18)
	var background := TitleBackground.add_to(self)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	# The mark over the name, GAME.md 8.1: the same one the window wears, without the plate it
	# needs on a desktop.
	# After the story's ending the title is the Operator's, STORY.md 8.6.
	var operator := Story.stage_here() == Story.Stage.OPERATOR
	var mark := LogoArt.new()
	mark.plate = false
	mark.custom_minimum_size = Vector2(132.0, 132.0)
	if operator:
		mark.fine_print = StoryLines.SEAL_AFTER
	var centered := CenterContainer.new()
	centered.add_child(mark)
	column.add_child(centered)
	# The sunburst and the seal's rings turn about the mark, GAME.md 8.1a.
	background.anchor = mark
	_column = column
	_mark = centered
	# The name is a mark rather than a heading: the condensed Black, over a line of microprint.
	var named := MenuTheme.title("Jackpot Junction", Type.HERO)
	Type.set_font(named, Type.mark_font(), Type.HERO)
	column.add_child(named)
	# The microprint under the name moves with the story, STORY.md 6.4.
	var printed := _microprint(
		str(StoryLines.at(StoryLines.MICRO_TITLE, Story.stage_here(), MICROPRINT))
	)
	column.add_child(printed)
	# After the ending the House's green line has the tagline's place, STORY.md 8.6.
	var line: Control = (
		_status_line()
		if operator
		else MenuTheme.subtitle("Collect chips. Build your mult. Cash out before they get you.")
	)
	column.add_child(line)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 32.0)
	column.add_child(spacer)
	_spare = [centered, spacer, printed, line]
	play_button = MenuTheme.button(StoryLines.CLOCK_IN if operator else "Play")
	# One way in to playing. Whether it is a Grand Prix or a quick match is the lobby's first
	# question, GAME.md 9.7, asked with the rest rather than a screen early.
	# Asked first, the first time, how to drive, GAME.md 4.2, whichever way in to driving it is,
	# and before that, every time until it is earned, whether to earn the license, 9.4a.
	play_button.pressed.connect(
		func() -> void: offer_license(func() -> void: DriveChoice.first(self, Game.go_to_lobby))
	)
	column.add_child(play_button)
	# The games on dedicated servers, GAME.md 9.3a, and through them the games on the network, 9.3:
	# one way in to playing with other machines rather than one for each kind of host.
	var server := MenuTheme.button(StoryLines.CLOCK_IN_ONLINE if operator else "Play Online")
	server.pressed.connect(
		func() -> void:
			offer_license(func() -> void: DriveChoice.first(self, Game.go_to_play_online))
	)
	column.add_child(server)
	var tutorial := MenuTheme.button("Driving School")
	tutorial.name = "DrivingSchool"
	tutorial.pressed.connect(Game.go_to_tutorial)
	column.add_child(tutorial)
	_school_button = tutorial
	# What is not a way in to a match goes behind one button, so the column stays short enough
	# for a phone: the Garage and the Catalog, and whatever joins them later.
	_extras_button = MenuTheme.button("Extras")
	_extras_button.name = "Extras"
	_extras_button.pressed.connect(show_extras.bind(true))
	column.add_child(_extras_button)
	var settings := MenuTheme.button("Settings")
	settings.pressed.connect(func() -> void: Game.go_to_settings(Game.TITLE_SCENE))
	column.add_child(settings)
	var quit := MenuTheme.button("Quit")
	quit.pressed.connect(func() -> void: Game.quit())
	column.add_child(quit)
	_main = [play_button, server, tutorial, _extras_button, settings, quit]
	_extras = []
	if Game.settings.profile.loyalty.welcomed:
		_loyalty_button = MenuTheme.button(LoyaltyDialog.program_name(Game.settings.profile))
		_loyalty_button.name = "Loyalty"
		_loyalty_button.pressed.connect(show_loyalty)
		_extras.append(_loyalty_button)
	var garage := MenuTheme.button("Garage")
	garage.name = "Garage"
	garage.pressed.connect(
		func() -> void: offer_license(func() -> void: DriveChoice.first(self, Game.go_to_garage))
	)
	var catalog := MenuTheme.button("Catalog")
	catalog.name = "Catalog"
	catalog.pressed.connect(show_catalog)
	var back := MenuTheme.button("Back")
	back.name = "ExtrasBack"
	back.pressed.connect(show_extras.bind(false))
	_extras.append_array([garage, catalog, back])
	_tag_fresh()
	for each: Control in _extras:
		each.visible = false
		column.add_child(each)
	_extras_room = Control.new()
	_extras_room.name = "ExtrasRoom"
	_extras_room.visible = false
	column.add_child(_extras_room)
	var version := Label.new()
	version.text = "v%s" % Game.version()
	version.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_right = -16.0
	version.offset_bottom = -12.0
	add_child(version)
	if not Game.settings.license_number.is_empty():
		_peek_license()
	else:
		_advertise(SchoolAd.new(), _school_button)
	# The Final Hand, offered rather than sprung, STORY.md 8.1.
	if Story.on_here() and Story.final_hand_due(Game.settings.profile):
		_advertise(HouseAd.new(), play_button)
	_peek_folder()
	resized.connect(_fit)
	_fit()
	if TitleIntro.wanted():
		_open(mark, [named, printed, line], version)
	# The invitation that brought the player here, the first time a profile comes to the title,
	# STORY.md 6.1a: put up now, under the warm-up's pane, so it has drawn everything once by the
	# time it starts, and started once the shaders have compiled.
	if OpeningInvitation.due(Game.settings.profile):
		invitation = OpeningInvitation.over(self, Game.settings.profile)
		invitation.accepted.connect(_open_up)
		# It comes in silence, the music faded out if it was playing, and held off till the title
		# opens.
		Audio.hold_music(true)
	# The shaders compile first, once a version, GAME.md 10.7, said in a pane over all of it, the
	# license too, with Skip; the opening waits for them, since it would only stutter while they
	# compile, and the menu is the player's once both are done.
	var warmup := ShaderWarmup.add_to(self)
	if warmup != null:
		warming = WarmupPane.over(self, warmup)
		warming.put_away.connect(_on_warmed)
	else:
		_on_warmed()


## The shaders compiled, skipped, or none to compile: the invitation that brought the player here
## the first time a profile comes to the title, STORY.md 6.1a, and then the opening plays, or the
## cursor goes on Play.
func _on_warmed() -> void:
	warming = null
	if invitation != null:
		invitation.start()
		return
	_open_up()


func _open_up() -> void:
	invitation = null
	Audio.hold_music(false)
	if _intro != null:
		_intro.start()
	else:
		play_button.grab_focus()


## The title's opening, GAME.md 8.1a, see [TitleIntro]: [param mark] large in the middle and
## flown into its place, then each part of the screen in its turn, see [constant OPEN_BACKDROP],
## [param words] under the mark and [param version] among them.
func _open(mark: Control, words: Array[Control], version: Control) -> void:
	_intro = TitleIntro.over(self, mark, _column)
	var backdrop := get_node("Backdrop") as CanvasItem
	var background := get_node("Background") as TitleBackground
	var lit := func(by: float) -> void:
		backdrop.modulate.a = by
		background.glow = by
	_intro.add(OPEN_BACKDROP.x, OPEN_BACKDROP.y, lit)
	_intro.add(OPEN_RINGS.x, OPEN_RINGS.y, func(by: float) -> void: background.rings = by)
	_intro.add(OPEN_BEAMS.x, OPEN_BEAMS.y, func(by: float) -> void: background.beams = by)
	var at := OPEN_WORDS
	for word: Control in words:
		_intro.add(at, at + OPEN_RISE, _intro.rise.bind(word))
		at += OPEN_WORD_STEP
	at = OPEN_BUTTONS
	for child: Node in _column.get_children():
		if child is Button:
			_intro.add(at, at + OPEN_RISE, _intro.rise.bind(child))
			at += OPEN_BUTTON_STEP
	_intro.add(OPEN_EDGES.x, OPEN_EDGES.y, _bring_in_edges.bind(version))
	_show_peek_hints()
	_intro.finished.connect(
		func() -> void:
			_intro = null
			_show_peek_hints()
			play_button.grab_focus()
	)


## What peeks in at the screen's edges, brought in [param by], from 0 to 1, at the end of the
## opening: the license in from the right, Kit's folder in from the left, and the flyer and
## [param version] faded up.
func _bring_in_edges(by: float, version: Control) -> void:
	var up := ease(by, 0.4)
	version.modulate.a = up
	if _ad != null:
		_ad.modulate.a = up
	if _license != null:
		_place_license()
		_license.position.x += (1.0 - up) * LicenseCard.SIZE.x * LICENSE_SCALE
	if _folder != null:
		_folder.place()
		_folder.position.x -= (1.0 - up) * FolderPeek.SIZE.x


## After the ending, one line under the name in the Count Room's green, set as a terminal's, in the
## tagline's place, with a block cursor blinking after its end, held still for fewer flashes,
## STORY.md 8.6: the House's own room showing through the menu. The cursor blinks by fading rather
## than by going, so the line never moves.
func _status_line() -> HBoxContainer:
	var green: Color = (load("res://data/rooms/count_room.tres") as RoomLook).trim
	var row := HBoxContainer.new()
	row.name = "StatusLine"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var said := Label.new()
	said.text = StoryFill.fill(StoryLines.STATUS_LINE, Game.settings.profile)
	said.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(said, NotePage.TYPED, STATUS_SIZE)
	said.add_theme_color_override("font_color", green)
	row.add_child(said)
	# The block in a slot the line's height, from just under the top of the letters to a little under
	# their foot, level with the capitals rather than centered on the whole line.
	var font := NotePage.TYPED
	var slot := Control.new()
	slot.name = "Cursor"
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.custom_minimum_size = Vector2(STATUS_SIZE * 0.6, font.get_height(STATUS_SIZE))
	row.add_child(slot)
	var cursor := ColorRect.new()
	cursor.name = "Block"
	cursor.color = green
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor.position = Vector2(0.0, font.get_ascent(STATUS_SIZE) * 0.08)
	cursor.size = Vector2(
		STATUS_SIZE * 0.6,
		font.get_ascent(STATUS_SIZE) * 0.92 + font.get_descent(STATUS_SIZE) * 0.35
	)
	slot.add_child(cursor)
	if not Game.settings.flash_reduction:
		var blink := cursor.create_tween().set_loops()
		(
			blink
			. tween_callback(func() -> void: cursor.self_modulate.a = 1.0 - cursor.self_modulate.a)
			. set_delay(0.53)
		)
	return row


## A line of microprint between two short rules of foil, centered under the name.
static func _microprint(words: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in 3:
		if i == 1:
			var said := Label.new()
			said.text = words
			said.uppercase = true
			Type.set_font(said, Type.micro_font(), 13)
			said.add_theme_color_override("font_color", Color(HouseTheme.FOIL, 0.8))
			row.add_child(said)
			continue
		var rule := ColorRect.new()
		rule.color = Color(HouseTheme.FOIL, 0.45)
		rule.custom_minimum_size = Vector2(MICRO_RULE, 1.0)
		rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(rule)
	return row


## A flyer beside [param button] and pointing at it, fitted to the room there, see
## [method SchoolAd.fit_into], and gone on a screen with none; a click or a tap on it is the
## button's. Until the license is earned the school's stands in the license's place, GAME.md 3.8,
## at the Driving School button; while the Final Hand is due the House's is at Play, STORY.md 8.1.
func _advertise(ad: SchoolAd, button: Button) -> void:
	_ad = ad
	_ad_button = button
	add_child(_ad)
	_ad.chosen.connect(func() -> void: button.pressed.emit())
	resized.connect(_place_ad)
	button.item_rect_changed.connect(_place_ad)
	_ad.resized.connect(_place_ad)
	# A column taller than the screen scrolls, GAME.md 8.5, which moves what holds the button rather
	# than the button in it: the flyer goes along with any of them moving.
	var holder := button.get_parent() as Control
	while holder != null and holder != self:
		holder.item_rect_changed.connect(_place_ad)
		holder = holder.get_parent() as Control
	_place_ad.call_deferred()


func _place_ad() -> void:
	if _ad == null or _ad_button == null or not is_inside_tree():
		return
	var button := _ad_button.get_global_rect()
	button.position -= global_position
	var left := button.end.x + AD_GAP
	var middle := button.get_center().y
	# Gone with the button should the column be scrolled to put it out of sight, or Extras put
	# other buttons in its place.
	var in_sight := middle >= 0.0 and middle <= size.y and _ad_button.is_visible_in_tree()
	_ad.visible = _ad.fit_into(size.x - left - AD_EDGE) and in_sight
	_ad.position = Vector2(left, middle - _ad.size.y * 0.5)


## The license earned, tilted and a third off the right edge like a card in a hand, sliding in
## straight under the cursor and back out from under it, and shown in full on a click.
func _peek_license() -> void:
	_keyboard = Game.last_input_keyboard
	_pointer = Game.last_input_pointer
	_license = LicenseCard.from_settings()
	_license.name = "LicensePeek"
	_license.mouse_filter = Control.MOUSE_FILTER_STOP
	_license.scale = Vector2.ONE * LICENSE_SCALE
	_license.rotation = LICENSE_TILT
	_license.modulate = LICENSE_DIM
	add_child(_license)
	# A touch screen has no hover to slide under: the tap shows the card in full on the spot.
	if not TouchInput.enabled:
		_license.mouse_entered.connect(_slide_license.bind(true))
		_license.mouse_exited.connect(func() -> void: _slide_license(_license.has_focus()))
	_license.gui_input.connect(_on_license_input)
	_reach_license()
	resized.connect(_place_license)
	_place_license()
	_license.focus_entered.connect(_show_peek_hints, CONNECT_DEFERRED)
	_license.focus_exited.connect(_show_peek_hints, CONNECT_DEFERRED)
	_show_peek_hints()


## The menu's cursor reaches the license going right from the buttons, as it reaches Kit's folder
## going left, STORY.md 7.2: out under it, with the cursor's mark round it, see [FocusMark], and
## shown in full on the accept button. Going left goes back to Play.
func _reach_license() -> void:
	_license.focus_mode = Control.FOCUS_ALL
	for child: Node in _column.get_children():
		if child is Button:
			(child as Button).focus_neighbor_right = child.get_path_to(_license)
	_license.focus_neighbor_left = _license.get_path_to(play_button)
	for side: int in [SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		_license.set_focus_neighbor(side, _license.get_path())
	var mark := Control.new()
	mark.name = "FocusMark"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.size = LicenseCard.SIZE
	mark.draw.connect(
		func() -> void:
			if _license.has_focus():
				var card := Rect2(Vector2.ZERO, LicenseCard.SIZE)
				FocusMark.draw_on(mark, card, LicenseCard.RADIUS, SIDE_LEFT, LICENSE_SCALE)
	)
	_license.add_child(mark)
	_license.focus_entered.connect(
		func() -> void:
			_slide_license(true)
			mark.queue_redraw()
	)
	_license.focus_exited.connect(
		func() -> void:
			_slide_license(false)
			mark.queue_redraw()
	)


## Kit's notes, once one has been found and while the story is on, in a folder peeking in from the
## left edge, STORY.md 7.2; the menu's cursor reaches it going left from the buttons.
func _peek_folder() -> void:
	var profile := Game.settings.profile
	if not Story.on_here() or (profile.story.notes.is_empty() and not profile.story.ended()):
		return
	var buttons: Array[Control] = []
	for child: Node in _column.get_children():
		if child is Button:
			buttons.append(child)
	_folder = FolderPeek.add_to(self, profile, buttons)
	_folder.opened.connect(show_notes)
	# Deferred, so the cursor leaving as the title goes draws nothing on its way out.
	_folder.focus_entered.connect(_show_peek_hints, CONNECT_DEFERRED)
	_folder.focus_exited.connect(_show_peek_hints, CONNECT_DEFERRED)
	_show_peek_hints()


## The notes' folder open over the title: put away, the cursor goes back where it was.
func show_notes() -> void:
	if _notes != null:
		return
	_notes_from = get_viewport().gui_get_focus_owner()
	_notes = NotesFolder.open(self, Game.settings.profile, Game.last_input_keyboard, _folder)
	_notes.put_away.connect(_on_notes_put_away)


func _on_notes_put_away() -> void:
	_notes = null
	if _folder != null:
		_folder.corner = FolderPeek.first_new(Game.settings.profile.story)
		_folder.queue_redraw()
	if _notes_from != null and is_instance_valid(_notes_from):
		_notes_from.grab_focus()
	elif play_button != null:
		play_button.grab_focus()


## The hints at the license and Kit's folder, peeking in at the screen's edges, STORY.md 7.2, for
## keys or a pad: off one, the way that reaches it from the buttons, right for the license and left
## for the folder; on one, accept, which opens it. Each in its own bottom corner, under it. None
## while the mouse or a finger is in hand, which reach them by pointing, nor while the opening
## plays, see [TitleIntro].
func _show_peek_hints() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	# The old ones out of sight and out of the way of the new ones' names at once, gone at the
	# frame's end.
	for old: Control in [_license_glyph, _folder_glyph]:
		if old != null and is_instance_valid(old):
			old.visible = false
			old.name = "Gone"
			old.queue_free()
	_license_glyph = null
	_folder_glyph = null
	if TouchInput.enabled or _pointer or _intro != null:
		return
	if _license != null:
		var on := _license.has_focus()
		_license_glyph = _peek_hint("LicenseGlyph", &"ui_accept" if on else &"ui_right", false)
	if _folder != null:
		var on := _folder.has_focus()
		_folder_glyph = _peek_hint("FolderGlyph", &"ui_accept" if on else &"ui_left", true)


## A hint named [param named] for [param action], in the bottom left corner if [param left] or the
## bottom right; null for an action with nothing bound to it on the device in hand.
func _peek_hint(named: String, action: StringName, left: bool) -> Control:
	var glyph := InputGlyph.of_action(action, _keyboard, Palette.CHIP_WHITE, LICENSE_GLYPH_SIZE)
	if glyph == null:
		return null
	var row := HBoxContainer.new()
	row.name = named
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(glyph)
	row.set_anchors_and_offsets_preset(
		Control.PRESET_BOTTOM_LEFT if left else Control.PRESET_BOTTOM_RIGHT
	)
	row.grow_horizontal = Control.GROW_DIRECTION_END if left else Control.GROW_DIRECTION_BEGIN
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	if left:
		row.offset_left = 16.0
	else:
		row.offset_right = -16.0
	row.offset_bottom = -LICENSE_GLYPH_BOTTOM
	add_child(row)
	return row


## What was touched says which hints to draw at the license and the folder, and whether to draw any.
func _input(event: InputEvent) -> void:
	if (
		warming != null
		or invitation != null
		or _notes != null
		or _license_view != null
		or _catalog != null
		or _loyalty != null
	):
		return
	var was := _keyboard
	var was_pointer := _pointer
	_keyboard = LicenseView.keyboard_after(event, _keyboard)
	_pointer = ButtonBinds.pointer_after(event, _pointer)
	if was != _keyboard or was_pointer != _pointer:
		_show_peek_hints()
	# A click beside the license or the folder with the cursor on it takes the cursor back to the
	# buttons, as Back does; one on a button takes it there itself.
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		for peek: Control in [_license, _folder]:
			if peek != null and peek.has_focus() and not _is_on(peek, click.global_position):
				play_button.grab_focus()


## Whether [param at], on the screen, is on [param control], turned and scaled as it is.
static func _is_on(control: Control, at: Vector2) -> bool:
	var inside := control.get_global_transform().affine_inverse() * at
	return Rect2(Vector2.ZERO, control.size).has_point(inside)


## A click or a tap on the license peeking in shows it in full, or the accept button with the
## cursor on it.
func _on_license_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (
		(click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
		or (touch != null and touch.pressed)
		or event.is_action_pressed(&"ui_accept")
	):
		get_viewport().set_input_as_handled()
		show_license()


## Extras' buttons in the place of the title's own, the cursor on the first of them, or the title's
## own back, the cursor on Extras, GAME.md 3.8; the column as tall either way, see
## [member _extras_room], so nothing over the buttons moves.
func show_extras(on: bool) -> void:
	var gap := float(_column.get_theme_constant("separation"))
	var room := _tall(_main, gap) - _tall(_extras, gap) - gap
	_extras_room.custom_minimum_size.y = maxf(room, 0.0)
	_extras_room.visible = on and room > 0.0
	for each: Control in _main:
		each.visible = not on
	for each: Control in _extras:
		each.visible = on
	(_extras[0] if on else _extras_button).grab_focus()
	_fit()
	_place_ad.call_deferred()


## How much of the column [param controls] take, each with the gap after it.
static func _tall(controls: Array[Control], gap: float) -> float:
	var tall := 0.0
	for each: Control in controls:
		tall += each.get_combined_minimum_size().y + gap
	return tall


## Whether Extras' buttons are up in the place of the title's own.
func in_extras() -> bool:
	return not _extras.is_empty() and _extras[0].visible


## The catalog over the title, GAME.md 8.8, and the cursor back where it was once it is put away.
func show_catalog() -> void:
	if _catalog != null:
		return
	_catalog = CatalogDialog.open(self)
	_catalog.put_away.connect(func() -> void: _catalog = null)


## The loyalty program over the title, GAME.md 8.9, and the cursor back where it was once it is
## put away, the NEW tags as it left them.
func show_loyalty() -> void:
	if _loyalty != null:
		return
	_loyalty = LoyaltyDialog.open(self)
	_loyalty.put_away.connect(
		func() -> void:
			_loyalty = null
			_tag_fresh()
	)


## Extras and the program's button wear the NEW tag while a landmark won has not been shown under
## the program's cursor, GAME.md 8.9.
func _tag_fresh() -> void:
	var fresh := Loyalty.has_fresh(Game.settings.profile)
	for button: Button in [_extras_button, _loyalty_button]:
		if button != null:
			CatalogCell.tag(button, fresh)


## The license in full, see [LicenseView]: put away, it peeks in again, and the cursor goes back
## where it was, or to Play.
func show_license() -> void:
	if _license_view != null:
		return
	_license_from = get_viewport().gui_get_focus_owner()
	_license_view = LicenseView.open(self, _keyboard, _license)
	_license_view.put_away.connect(_on_license_put_away)


func hide_license() -> void:
	if _license_view != null:
		_license_view.close()


func _on_license_put_away() -> void:
	_license_view = null
	if (
		_license_from != null
		and is_instance_valid(_license_from)
		and _license_from.is_inside_tree()
	):
		LicenseView.give_cursor(_license_from)
		_slide_license(_license_from == _license)
	else:
		_slide_license(false)
		if play_button != null:
			play_button.grab_focus()
	_license_from = null


func _unhandled_input(event: InputEvent) -> void:
	if (
		not event.is_action_pressed(&"ui_cancel")
		or _catalog != null
		or _loyalty != null
		or invitation != null
	):
		return
	# Back puts the license away, puts the question of earning one away unanswered, and takes the
	# cursor off the license or the folder.
	if _license_view != null:
		get_viewport().set_input_as_handled()
		MenuTheme.back_sound()
		hide_license()
	elif _license_question != null:
		get_viewport().set_input_as_handled()
		MenuTheme.back_sound()
		_put_the_question_away()
	elif in_extras():
		get_viewport().set_input_as_handled()
		MenuTheme.back_sound()
		show_extras(false)
	elif (_license != null and _license.has_focus()) or (_folder != null and _folder.has_focus()):
		# Off the license or Kit's folder, peeking in at the edges, and back to the buttons.
		get_viewport().set_input_as_handled()
		MenuTheme.back_sound()
		play_button.grab_focus()


## The question of earning the license taken down, and the cursor back where it was.
func _put_the_question_away() -> void:
	if _license_question == null:
		return
	_license_question.queue_free()
	_license_question = null
	if _question_from != null and is_instance_valid(_question_from):
		_question_from.grab_focus()
	elif play_button != null:
		play_button.grab_focus()


## Where the license's middle is, out under the cursor or peeking in.
func _license_middle(out: bool) -> Vector2:
	var drawn := LicenseCard.SIZE * LICENSE_SCALE
	var y := size.y - drawn.y * 0.5 - LICENSE_BOTTOM
	if out:
		return Vector2(size.x - drawn.x * 0.5 - LICENSE_IN, y)
	return Vector2(size.x - drawn.x * LICENSE_PEEK + drawn.x * 0.5, y)


func _place_license() -> void:
	if _license == null:
		return
	_license.position = _license_middle(_license_out) - LicenseCard.SIZE * 0.5


func _slide_license(out: bool) -> void:
	if _license == null or out == _license_out:
		return
	_license_out = out
	var slide := create_tween()
	slide.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	slide.set_parallel(true)
	slide.tween_property(
		_license, "position", _license_middle(out) - LicenseCard.SIZE * 0.5, LICENSE_SLIDE
	)
	slide.tween_property(
		_license, "rotation", LICENSE_TILT_SHOWN if out else LICENSE_TILT, LICENSE_SLIDE
	)
	slide.tween_property(_license, "modulate", Color.WHITE if out else LICENSE_DIM, LICENSE_SLIDE)
	if out:
		Audio.play_sfx(&"ui_move", MenuTheme.MOVE_DB, 0.0)


## Shows as much of [member _spare] as the screen has room for, giving it up in order until the
## rest fits.
func _fit() -> void:
	if _spare.is_empty():
		return
	var gap := _column.get_theme_constant("separation")
	var tall := _column.get_combined_minimum_size().y
	for each: Control in _spare:
		if not each.visible:
			tall += each.get_combined_minimum_size().y + gap
	for each: Control in _spare:
		each.visible = tall + BOTTOM_ROOM <= size.y
		if not each.visible:
			tall -= each.get_combined_minimum_size().y + gap


## The license asked for before any way in to driving, GAME.md 9.4a, every time, until this
## machine has earned one: Earn it now goes to the driving school, Drive anyway on to
## [param then], and Back puts the question away and goes nowhere. With a license it is straight
## on.
func offer_license(then: Callable) -> void:
	if not Game.settings.license_number.is_empty():
		then.call()
		return
	if _license_question != null:
		return
	_question_from = get_viewport().gui_get_focus_owner()
	var holder := Control.new()
	holder.name = "LicenseQuestion"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(holder)
	_license_question = holder
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(middle)
	var pane := ConfirmPane.new()
	pane.name = "LicenseOffer"
	middle.add_child(pane)
	pane.answered.connect(
		func(yes: bool) -> void:
			# The cursor goes back to the button that asked before anything else comes up, so
			# whatever does, the question of how to drive say, has a button to give it back to.
			_put_the_question_away()
			if yes:
				Game.go_to_tutorial()
			else:
				then.call()
	)
	pane.ask(LICENSE_QUESTION, LICENSE_LINE, "Earn it now", "Drive anyway", RoadSign.Kind.QUESTION)
	# The cursor starts on the school: it is the thing the question is for.
	pane.yes_button().grab_focus()
