extends Control
## The title screen from GAME.md 3.8: Play, Play LAN, Play Online, the Tutorial, the Garage
## practice room, Settings, Quit, over the turning sunburst of [TitleBackground]; every way in to
## driving asks for the license of 9.4a until it is earned, and the license earned peeks in from
## the right edge.

## Room kept under the buttons for the credits along the bottom of the screen.
const CREDITS_ROOM := 48.0
## What is asked before driving without a license, GAME.md 9.4a.
const LICENSE_QUESTION := "No license yet"
const LICENSE_LINE := (
	"Nobody drives the Junction without one. The driving school takes a few minutes: "
	+ "a little theory, the driving test, and a license with your name on it."
)
## The license earned, GAME.md 9.4a, peeking in from the right edge the way a card in a hand
## does: how big, how much of it shows, how far it leans, where it sits over the version line,
## and how far in it comes under the cursor.
const LICENSE_SCALE := 0.78
const LICENSE_PEEK := 0.42
const LICENSE_TILT := -0.2
const LICENSE_TILT_SHOWN := -0.04
const LICENSE_BOTTOM := 72.0
const LICENSE_IN := 28.0
const LICENSE_SLIDE := 0.25

var play_button: Button

var _column: VBoxContainer
## The mark over the name, which goes on a screen too short for it and the buttons both: a big UI
## scale on a short screen, GAME.md 8.5. The buttons are what the screen is for. And after it, on a
## screen shorter still, the gap over the buttons and the line under the name, in that order.
var _mark: Control
var _spare: Array[Control] = []
## The license peeking in, where there is one, and whether it is out under the cursor.
var _license: LicenseCard
var _license_out := false


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
	garage.pressed.connect(func() -> void: DriveChoice.first(self, Game.go_to_garage))
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


## The license earned, tilted and half off the right edge like a card in a hand, sliding in
## straight under the cursor and back out from under it.
func _peek_license() -> void:
	_license = LicenseCard.from_settings()
	_license.name = "LicensePeek"
	_license.mouse_filter = Control.MOUSE_FILTER_STOP
	_license.scale = Vector2.ONE * LICENSE_SCALE
	_license.rotation = LICENSE_TILT
	add_child(_license)
	_license.mouse_entered.connect(_slide_license.bind(true))
	_license.mouse_exited.connect(_slide_license.bind(false))
	resized.connect(_place_license)
	_place_license()


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
