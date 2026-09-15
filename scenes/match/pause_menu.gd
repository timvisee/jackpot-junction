class_name PauseMenu
extends CanvasLayer
## Pausing freezes the whole match in single-player and local play, GAME.md 3.8. Resume,
## Settings, or back to the title.

var _panel: CenterContainer
var _resume: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = CenterContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false
	add_child(_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(shade)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	_panel.add_child(column)
	column.add_child(MenuTheme.title("Paused", 64))
	_resume = MenuTheme.button("Resume")
	_resume.pressed.connect(set_paused.bind(false))
	column.add_child(_resume)
	var settings := MenuTheme.button("Settings")
	settings.pressed.connect(
		func() -> void:
			get_tree().paused = false
			Game.go_to_settings(Game.MATCH_SCENE)
	)
	column.add_child(settings)
	var quit := MenuTheme.button("Back to title")
	quit.pressed.connect(func() -> void: Game.go_to_title())
	column.add_child(quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.PAUSE):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_panel.visible = paused
	if paused:
		_resume.grab_focus()
