extends Control
## The title screen from GAME.md 3.8: Play, Settings, Quit.

var play_button: Button


func _ready() -> void:
	MenuTheme.background(self)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(column)
	column.add_child(MenuTheme.title("Jackpot Junction", 96))
	column.add_child(
		MenuTheme.subtitle("Collect chips. Build your mult. Cash out before they get you.")
	)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 32.0)
	column.add_child(spacer)
	play_button = MenuTheme.button("Play")
	play_button.pressed.connect(func() -> void: Game.go_to_lobby())
	column.add_child(play_button)
	var settings := MenuTheme.button("Settings")
	settings.pressed.connect(func() -> void: Game.go_to_settings(Game.TITLE_SCENE))
	column.add_child(settings)
	var quit := MenuTheme.button("Quit")
	quit.pressed.connect(func() -> void: get_tree().quit())
	column.add_child(quit)
	var credits := Label.new()
	credits.text = (
		"Music: Bossa Antigua by Kevin MacLeod (incompetech.com), CC BY 4.0"
		+ "   |   Models and sounds: Kenney (kenney.nl), CC0"
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
