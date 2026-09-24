extends Control
## The title screen from GAME.md 3.8: Play, the Garage practice room, Settings, Quit, over the
## turning sunburst of [TitleBackground].

## Room kept under the buttons for the credits along the bottom of the screen.
const CREDITS_ROOM := 48.0

var play_button: Button

var _column: VBoxContainer
## The mark over the name, which goes on a screen too short for it and the buttons both: a big UI
## scale on a short screen, GAME.md 8.5. The buttons are what the screen is for.
var _mark: Control


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
	column.add_child(
		MenuTheme.subtitle("Collect chips. Build your mult. Cash out before they get you.")
	)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 32.0)
	column.add_child(spacer)
	play_button = MenuTheme.button("Play")
	# One way in to playing. Whether it is a Grand Prix or a quick match is the lobby's first
	# question, GAME.md 9.7, asked with the rest rather than a screen early.
	play_button.pressed.connect(func() -> void: Game.go_to_lobby())
	column.add_child(play_button)
	var online := MenuTheme.button("Play LAN")
	online.pressed.connect(func() -> void: Game.go_to_online())
	column.add_child(online)
	var garage := MenuTheme.button("Garage")
	garage.pressed.connect(func() -> void: Game.enter_garage())
	column.add_child(garage)
	var settings := MenuTheme.button("Settings")
	settings.pressed.connect(func() -> void: Game.go_to_settings(Game.TITLE_SCENE))
	column.add_child(settings)
	var quit := MenuTheme.button("Quit")
	quit.pressed.connect(func() -> void: get_tree().quit())
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
	resized.connect(_fit)
	_fit()


func _fit() -> void:
	if _mark == null:
		return
	var tall := _column.get_combined_minimum_size().y
	var mark := _mark.get_combined_minimum_size().y + _column.get_theme_constant("separation")
	if not _mark.visible:
		tall += mark
	_mark.visible = tall + CREDITS_ROOM <= size.y
