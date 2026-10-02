extends Control
## The title screen from GAME.md 3.8: Play, Play LAN, Play Online, the Driving School, the Garage
## practice room, Settings, Quit, over the turning sunburst of [TitleBackground]; every way in to
## driving asks for the license of 9.4a until it is earned, and the license earned peeks in from
## the right edge.

## Room kept under the buttons for the credits along the bottom of the screen.
const CREDITS_ROOM := 48.0
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
## The button that shows the license in full, see [LicenseView], the one that opens the hand of
## jokers, drawn alone in the bottom right corner over the version.
const LICENSE_GLYPH_SIZE := 24
const LICENSE_GLYPH_BOTTOM := 44.0

var play_button: Button

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
## The button that shows the license, drawn beside it for the device in hand, and which that is,
## picked up from whatever was last touched anywhere in the game.
var _license_glyph: Control
var _keyboard := true
## The question whether to earn the license, while it is up, and what had the cursor before it.
var _license_question: Control
var _question_from: Control
## The Driving School button, and the flyer pointing at it while there is no license yet.
var _school_button: Button
var _ad: SchoolAd


func _ready() -> void:
	var column := MenuTheme.screen(self, 18)
	TitleBackground.add_to(self)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	# The mark over the name, GAME.md 8.1: the same one the window wears, without the plate it
	# needs on a desktop.
	var mark := LogoArt.new()
	mark.plate = false
	mark.custom_minimum_size = Vector2(132.0, 132.0)
	var centered := CenterContainer.new()
	centered.add_child(mark)
	column.add_child(centered)
	_column = column
	_mark = centered
	column.add_child(MenuTheme.title("Jackpot Junction", Type.HERO))
	var line := MenuTheme.subtitle("Collect chips. Build your mult. Cash out before they get you.")
	column.add_child(line)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 32.0)
	column.add_child(spacer)
	_spare = [centered, spacer, line]
	play_button = MenuTheme.button("Play")
	# One way in to playing. Whether it is a Grand Prix or a quick match is the lobby's first
	# question, GAME.md 9.7, asked with the rest rather than a screen early.
	# Asked first, the first time, how to drive, GAME.md 4.2, whichever way in to driving it is,
	# and before that, every time until it is earned, whether to earn the license, 9.4a.
	play_button.pressed.connect(
		func() -> void: offer_license(func() -> void: DriveChoice.first(self, Game.go_to_lobby))
	)
	column.add_child(play_button)
	var online := MenuTheme.button("Play LAN")
	online.pressed.connect(
		func() -> void: offer_license(func() -> void: DriveChoice.first(self, Game.go_to_online))
	)
	column.add_child(online)
	# The games on a dedicated server, GAME.md 9.3a, for playing over the internet.
	var server := MenuTheme.button("Play Online")
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
	var garage := MenuTheme.button("Garage")
	garage.name = "Garage"
	garage.pressed.connect(
		func() -> void: offer_license(func() -> void: DriveChoice.first(self, Game.go_to_garage))
	)
	column.add_child(garage)
	var settings := MenuTheme.button("Settings")
	settings.pressed.connect(func() -> void: Game.go_to_settings(Game.TITLE_SCENE))
	column.add_child(settings)
	var quit := MenuTheme.button("Quit")
	quit.pressed.connect(func() -> void: Game.quit())
	column.add_child(quit)
	var credits := Label.new()
	credits.text = (
		"Music: Ovani Sound (ovanisound.com)" + "   |   Models and sounds: Kenney (kenney.nl), CC0"
	)
	credits.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	credits.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	credits.grow_vertical = Control.GROW_DIRECTION_BEGIN
	credits.offset_left = 16.0
	credits.offset_bottom = -12.0
	add_child(credits)
	var version := Label.new()
	version.text = "v%s" % Game.version()
	version.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_right = -16.0
	version.offset_bottom = -12.0
	add_child(version)
	play_button.grab_focus()
	# The shaders compile behind the title, once a run, GAME.md 10.7: a bar above the credits says
	# how far along it is, and the menu answers throughout.
	var warmup := ShaderWarmup.add_to(self)
	if warmup != null:
		add_child(ShaderWarmup.strip(warmup))
	if not Game.settings.license_number.is_empty():
		_peek_license()
	else:
		_advertise_school()
	resized.connect(_fit)
	_fit()


## Until the license is earned, a flyer stands in its place, GAME.md 3.8, beside the Driving
## School button and pointing at it, fitted to the room there, see [method SchoolAd.fit_into],
## and gone on a screen with none; a click or a tap on it is the button's.
func _advertise_school() -> void:
	_ad = SchoolAd.new()
	add_child(_ad)
	_ad.chosen.connect(func() -> void: _school_button.pressed.emit())
	resized.connect(_place_ad)
	_school_button.item_rect_changed.connect(_place_ad)
	_ad.resized.connect(_place_ad)
	# A column taller than the screen scrolls, GAME.md 8.5, which moves what holds the button rather
	# than the button in it: the flyer goes along with any of them moving.
	var holder := _school_button.get_parent() as Control
	while holder != null and holder != self:
		holder.item_rect_changed.connect(_place_ad)
		holder = holder.get_parent() as Control
	_place_ad.call_deferred()


func _place_ad() -> void:
	if _ad == null or _school_button == null or not is_inside_tree():
		return
	var button := _school_button.get_global_rect()
	button.position -= global_position
	var left := button.end.x + AD_GAP
	var middle := button.get_center().y
	# Gone with the button should the column be scrolled to put it out of sight.
	var in_sight := middle >= 0.0 and middle <= size.y
	_ad.visible = _ad.fit_into(size.x - left - AD_EDGE) and in_sight
	_ad.position = Vector2(left, middle - _ad.size.y * 0.5)


## The license earned, tilted and a third off the right edge like a card in a hand, sliding in
## straight under the cursor and back out from under it, and shown in full on a click.
func _peek_license() -> void:
	_keyboard = Game.last_input_keyboard
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
		_license.mouse_exited.connect(_slide_license.bind(false))
	_license.gui_input.connect(_on_license_input)
	resized.connect(_place_license)
	_place_license()
	_show_license_glyph()


## The button that opens the hand of jokers, GAME.md 3.7, drawn alone in the bottom right corner
## over the version, as the button that shows the license, for a keyboard or a
## pad by what was touched last; a touch screen has the tap, and no glyph.
func _show_license_glyph() -> void:
	if _license_glyph != null:
		_license_glyph.queue_free()
		_license_glyph = null
	if TouchInput.enabled:
		return
	var glyph := InputGlyph.of_action(
		InputActions.JOKER_MENU, _keyboard, Palette.CHIP_WHITE, LICENSE_GLYPH_SIZE
	)
	if glyph == null:
		return
	var row := HBoxContainer.new()
	row.name = "LicenseGlyph"
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(glyph)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_right = -16.0
	row.offset_bottom = -LICENSE_GLYPH_BOTTOM
	add_child(row)
	_license_glyph = row


## The hand's button shows the license and puts it away again, before the focus takes the key
## for walking the buttons; and what was pressed says which glyph to draw.
func _input(event: InputEvent) -> void:
	if _license == null:
		return
	var was := _keyboard
	_keyboard = LicenseView.keyboard_after(event, _keyboard)
	if was != _keyboard:
		_show_license_glyph()
	# Shown, the view takes the button itself, to turn the card over.
	if event.is_action_pressed(InputActions.JOKER_MENU) and _license_view == null:
		get_viewport().set_input_as_handled()
		show_license()


## A click or a tap on the license peeking in shows it in full.
func _on_license_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (
		(click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
		or (touch != null and touch.pressed)
	):
		get_viewport().set_input_as_handled()
		show_license()


## The license in full, see [LicenseView]: put away, it peeks in again, and the cursor goes back
## to Play.
func show_license() -> void:
	if _license_view != null:
		return
	_license_view = LicenseView.open(self, _keyboard)
	_license_view.put_away.connect(_on_license_put_away)


func hide_license() -> void:
	if _license_view != null:
		_license_view.close()


func _on_license_put_away() -> void:
	_license_view = null
	_slide_license(false)
	if play_button != null:
		play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	# Back puts the license away, and puts the question of earning one away unanswered.
	if _license_view != null:
		get_viewport().set_input_as_handled()
		hide_license()
	elif _license_question != null:
		get_viewport().set_input_as_handled()
		Audio.play_sfx(&"ui_back", MenuTheme.CLICK_DB, 0.0)
		_put_the_question_away()


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


## Shows as much of [member _spare] as the screen has room for over the credits, giving it up in
## order until the rest fits.
func _fit() -> void:
	if _spare.is_empty():
		return
	var gap := _column.get_theme_constant("separation")
	var tall := _column.get_combined_minimum_size().y
	for each: Control in _spare:
		if not each.visible:
			tall += each.get_combined_minimum_size().y + gap
	for each: Control in _spare:
		each.visible = tall + CREDITS_ROOM <= size.y
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
	pane.ask(LICENSE_QUESTION, LICENSE_LINE, "Earn it now", "Drive anyway")
	# The cursor starts on the school: it is the thing the question is for.
	pane.yes_button().grab_focus()
