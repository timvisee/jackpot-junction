class_name FinalHandPane
extends CanvasLayer
## The House's own pane, put up in the lobby before the match settings while the Final Hand is
## due, STORY.md 8.1: FINAL HAND, "The House has set a table for you.", with Take your seat in
## foil under the cursor, and Not now. Back is Not now.

## Taken, [param take] true, or put off.
signal answered(take: bool)

var take: Button
var not_now: Button


static func add_to(parent: Node) -> FinalHandPane:
	var pane := FinalHandPane.new()
	pane.name = "FinalHandPane"
	parent.add_child(pane)
	return pane


func _ready() -> void:
	# Over the match settings and under the pause menu, as they are.
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(middle)
	var pane := MenuTheme.pane()
	middle.add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	pane.add_child(column)
	column.add_child(MenuTheme.title(StoryLines.FINAL_HAND, 44))
	column.add_child(MenuTheme.subtitle(StoryLines.PANE_LINE, Type.BODY))
	column.add_child(MenuTheme.perforation())
	take = MenuTheme.primary(MenuTheme.button(StoryLines.TAKE_SEAT))
	take.name = "TakeSeat"
	take.pressed.connect(_answer.bind(true))
	column.add_child(take)
	not_now = MenuTheme.button(StoryLines.NOT_NOW)
	not_now.name = "NotNow"
	not_now.pressed.connect(_answer.bind(false))
	column.add_child(not_now)
	MenuTheme.deal(pane)
	take.grab_focus()


func _answer(taken: bool) -> void:
	if is_queued_for_deletion():
		return
	answered.emit(taken)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)
