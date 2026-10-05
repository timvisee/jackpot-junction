class_name WarmupPane
extends Control
## The shaders compiling behind the title, GAME.md 10.7, said over the title in a pane of its own
## while they do: what is going on and why, a bar with how far along it is, and Skip. The title is
## out of reach under it until it is done or skipped; a small line in a corner was easy to miss,
## and then the first match stuttered. Skipped, or Back, the compiling stops, and whatever was not
## compiled is compiled the old way, on first use, as when the title was left early; it comes up
## again at the next start, since nothing was kept. Done, it fades away by itself.

## Gone, done or skipped.
signal put_away

const TITLE := "Preparing"
const LINE := "Compiling shaders, please wait..."
const SKIP := "Skip"
## How wide the line wraps, and the bar.
const WIDE := 520.0
const BAR_HEIGHT := 12.0
## How long it waits on a full bar before it fades, and how long the fade takes.
const LINGER := 0.4
const FADE := 0.4

var warmup: ShaderWarmup
var bar: ProgressBar
var percent: Label
var skip_button: Button

var _going := false


## Puts the pane up over [param parent], saying how far [param warmup] is.
static func over(parent: Control, compiling: ShaderWarmup) -> WarmupPane:
	var pane := WarmupPane.new()
	pane.name = "WarmupPane"
	pane.warmup = compiling
	parent.add_child(pane)
	return pane


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(middle)
	var pane := PanelContainer.new()
	pane.add_theme_stylebox_override("panel", MenuTheme.pane_style())
	middle.add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	pane.add_child(column)
	column.add_child(MenuTheme.title(TITLE, Type.TITLE))
	var line := MenuTheme.subtitle(LINE, Type.BODY)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(WIDE, 0.0)
	column.add_child(line)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	bar = HudBlock.bar(Vector2(WIDE - 80.0, BAR_HEIGHT), Palette.CHIP_GOLD)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	percent = Label.new()
	percent.custom_minimum_size = Vector2(68.0, 0.0)
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Type.strong(percent, Type.BODY, Palette.CHIP_GOLD)
	row.add_child(percent)
	skip_button = MenuTheme.button(SKIP, Type.BODY)
	skip_button.name = "Skip"
	skip_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip_button.custom_minimum_size.x = 200.0
	skip_button.pressed.connect(skip)
	column.add_child(skip_button)
	# The cursor stays on Skip rather than walking off it onto the title under the pane.
	var here := skip_button.get_path()
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		skip_button.set_focus_neighbor(side, here)
	skip_button.focus_next = here
	skip_button.focus_previous = here
	skip_button.grab_focus.call_deferred()
	if is_instance_valid(warmup):
		warmup.finished.connect(_finished)
	_show(0.0)


func _process(_delta: float) -> void:
	if not _going and is_instance_valid(warmup):
		_show(warmup.progress)


func _show(done: float) -> void:
	bar.value = done * 100.0
	percent.text = "%d%%" % floori(clampf(done, 0.0, 1.0) * 100.0)


## Stops the compiling, see the class, and goes.
func skip() -> void:
	if _going:
		return
	if is_instance_valid(warmup):
		warmup.queue_free()
	_go()


func _finished() -> void:
	if _going:
		return
	_show(1.0)
	_going = true
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, FADE).set_delay(LINGER)
	fade.tween_callback(_go)


func _go() -> void:
	_going = true
	if is_queued_for_deletion():
		return
	queue_free()
	put_away.emit()


## Back skips it; nothing else gets past it to the title under it.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		skip()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
