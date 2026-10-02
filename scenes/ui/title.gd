extends Control
## The title screen from GAME.md 3.8: Play, Play LAN, Play Online, the Tutorial, the Garage
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
## The license shown in full, over a shade, on a click or a tap on the one peeking in, or on
## the button that opens the hand of jokers, drawn in the bottom right corner over the version
## with the word License beside it: how big, and the line under it.
const LICENSE_FULL := 1.15
const LICENSE_AWAY := "Click anywhere, or press %s, to put it away"
const LICENSE_GLYPH_SIZE := 24
const LICENSE_GLYPH_BOTTOM := 44.0
const LICENSE_WORD := "License"

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
var _license_view: Control
## The button that shows the license, drawn beside it for the device in hand, and which that is.
var _license_glyph: Control
var _keyboard := true


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
	var tutorial := MenuTheme.button("Tutorial")
	tutorial.pressed.connect(Game.go_to_tutorial)
	column.add_child(tutorial)
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
	resized.connect(_fit)
	_fit()


## The license earned, tilted and a third off the right edge like a card in a hand, sliding in
## straight under the cursor and back out from under it, and shown in full on a click.
func _peek_license() -> void:
	_license = LicenseCard.from_settings()
	_license.name = "LicensePeek"
	_license.mouse_filter = Control.MOUSE_FILTER_STOP
	_license.scale = Vector2.ONE * LICENSE_SCALE
	_license.rotation = LICENSE_TILT
	add_child(_license)
	_license.mouse_entered.connect(_slide_license.bind(true))
	_license.mouse_exited.connect(_slide_license.bind(false))
	_license.gui_input.connect(_on_license_input)
	resized.connect(_place_license)
	_place_license()
	_show_license_glyph()


## The button that opens the hand of jokers, GAME.md 3.7, drawn in the bottom right corner over
## the version with License beside it, as the button that shows the license, for a keyboard or a
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
	var word := Label.new()
	word.text = LICENSE_WORD
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.text(word, Type.LABEL, Color(0.6, 0.6, 0.65))
	word.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(word)
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
	# A stick has to be pushed to count: a keyboard with a joystick in it, or a pad on the desk,
	# whispers small motions all the time.
	var stick := event as InputEventJoypadMotion
	if event is InputEventJoypadButton or (stick != null and absf(stick.axis_value) > 0.5):
		_keyboard = false
	elif event is InputEventKey or event is InputEventMouseButton:
		_keyboard = true
	if was != _keyboard:
		_show_license_glyph()
	if event.is_action_pressed(InputActions.JOKER_MENU):
		get_viewport().set_input_as_handled()
		if _license_view != null:
			hide_license()
		else:
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


## The license in full, over a shade, the way a joker is shown out of the hand, GAME.md 3.7: a
## click anywhere, a tap, Back or the button under it puts it away.
func show_license() -> void:
	if _license_view != null:
		return
	var view := Control.new()
	view.name = "LicenseView"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(view)
	_license_view = view
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	var holder := Control.new()
	holder.custom_minimum_size = LicenseCard.SIZE * LICENSE_FULL
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := LicenseCard.from_settings()
	card.name = "LicenseFull"
	card.scale = Vector2.ONE * LICENSE_FULL
	card.position = (LicenseCard.SIZE * LICENSE_FULL - LicenseCard.SIZE) * 0.5
	holder.add_child(card)
	column.add_child(holder)
	var away := MenuTheme.button("Put it away", Type.BODY)
	away.name = "Away"
	away.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	away.pressed.connect(hide_license)
	column.add_child(away)
	var binding := InputActions.short_binding_text(&"ui_cancel", true)
	column.add_child(MenuTheme.subtitle(LICENSE_AWAY % binding, Type.LABEL))
	view.gui_input.connect(
		func(event: InputEvent) -> void:
			var click := event as InputEventMouseButton
			var touch := event as InputEventScreenTouch
			if (click != null and click.pressed) or (touch != null and touch.pressed):
				get_viewport().set_input_as_handled()
				hide_license()
	)
	view.modulate.a = 0.0
	var rise := create_tween()
	rise.tween_property(view, "modulate:a", 1.0, 0.2)
	away.grab_focus()
	Audio.play_sfx(&"joker_offer", MenuTheme.MOVE_DB, 0.0)


func hide_license() -> void:
	if _license_view == null:
		return
	_license_view.queue_free()
	_license_view = null
	_slide_license(false)
	if play_button != null:
		play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _license_view != null and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		hide_license()


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
## [param then]. With a license it is straight on.
func offer_license(then: Callable) -> void:
	if not Game.settings.license_number.is_empty():
		then.call()
		return
	var holder := Control.new()
	holder.name = "LicenseQuestion"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(holder)
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
			holder.queue_free()
			if yes:
				Game.go_to_tutorial()
			else:
				then.call()
	)
	pane.ask(LICENSE_QUESTION, LICENSE_LINE, "Earn it now", "Drive anyway")
	# The cursor starts on the school: it is the thing the question is for.
	pane.yes_button().grab_focus()
