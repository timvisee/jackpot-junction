class_name DriveChoice
extends Control
## The question the first Play asks, GAME.md 4.2: simple driving or advanced, each a big button with
## its picture, what it is in a line, and a word that it can be changed in the settings later. It
## is asked before the first way into driving from the title, whichever of the three it is, and
## only until it has been answered; Back leaves the title as it was and asks again next time. The
## settings ask it again on request, for the first player alone.

## What each way is, in a line under its name.
const WHAT: Dictionary[String, String] = {
	Settings.DRIVE_SIMPLE:
	"Push the way you want to go. The kart steers, speeds up and brakes itself.",
	Settings.DRIVE_ADVANCED:
	"Steer, and work the gas and brake yourself. More to learn, more control.",
}
const PICTURE := 110.0
const CARD := Vector2(380.0, 330.0)
const INK := Color(0.88, 0.88, 0.92)

## What to do once answered.
var then: Callable
## The seat the answer is for, or -1 for the first answer, which is every seat's that has none.
var seat := -1

var _cards: Dictionary[String, Button] = {}
## What had the cursor before the question came up, for Back to give it back to.
var _was_focused: Control


## Asks, over [param parent], unless it has been answered already, and does [param next] once it
## has. Returns the question, or null when there was nothing to ask.
static func first(parent: Control, next: Callable) -> DriveChoice:
	if Game.settings.has_chosen_driving():
		next.call()
		return null
	return ask(parent, next)


## Asks, over [param parent], whatever was answered before, and does [param next] once answered.
## [param for_seat] is the one seat the answer is for; -1 is the first answer, see [method first].
static func ask(parent: Control, next: Callable, for_seat := -1) -> DriveChoice:
	var choice := DriveChoice.new()
	choice.name = "DriveChoice"
	choice.then = next
	choice.seat = for_seat
	parent.add_child(choice)
	return choice


## The card for [param mode], for pressing it.
func card(mode: String) -> Button:
	return _cards.get(mode)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var pane := MenuTheme.pane()
	center.add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	pane.add_child(column)
	column.add_child(MenuTheme.title("How do you want to drive?", Type.TITLE))
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 24)
	column.add_child(cards)
	for mode: String in Settings.DRIVE_MODES:
		cards.add_child(_card(mode))
	# Asked again, it is being asked from the settings, where saying so would be telling the player
	# where they already are.
	if seat < 0:
		column.add_child(MenuTheme.subtitle("You can change this later in Settings.", Type.BODY))
	_confine()
	_was_focused = get_viewport().gui_get_focus_owner()
	# Asked again, the cursor starts on what it says now; the first time, on simple.
	var now := Game.settings.drive_mode(seat) if seat >= 0 else Settings.DRIVE_SIMPLE
	_cards[now].grab_focus()


func _card(mode: String) -> Button:
	var pressable := MenuTheme.button("", Type.LARGE)
	pressable.custom_minimum_size = CARD
	var inside := VBoxContainer.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.alignment = BoxContainer.ALIGNMENT_CENTER
	inside.add_theme_constant_override("separation", 14)
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inside.offset_left = 22.0
	inside.offset_right = -22.0
	var picture := DriveArt.picture(mode, Palette.CHIP_GOLD, PICTURE)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inside.add_child(picture)
	var word := Label.new()
	word.text = DrivePicker.WORDS[mode]
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(word, Type.STRONG, Type.HEADING)
	inside.add_child(word)
	var what := Label.new()
	what.text = WHAT[mode]
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	what.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	what.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.text(what, Type.BODY, INK)
	inside.add_child(what)
	pressable.add_child(inside)
	pressable.pressed.connect(choose.bind(mode))
	_cards[mode] = pressable
	return pressable


## The cursor stays on the two cards while the question is up, rather than walking off them onto
## the title's buttons underneath.
func _confine() -> void:
	var simple := _cards[Settings.DRIVE_SIMPLE]
	var advanced := _cards[Settings.DRIVE_ADVANCED]
	for each: Button in [simple, advanced]:
		var other := advanced if each == simple else simple
		var here := each.get_path()
		each.focus_neighbor_top = here
		each.focus_neighbor_bottom = here
		each.focus_neighbor_left = other.get_path()
		each.focus_neighbor_right = other.get_path()
		each.focus_next = other.get_path()
		each.focus_previous = other.get_path()


## Answers with [param mode], for the seat asked or for every seat that has not said, and goes on.
func choose(mode: String) -> void:
	if seat >= 0:
		Game.settings.set_drive_mode(seat, mode)
	else:
		Game.settings.choose_driving(mode)
	Game.settings.save_to_disk()
	var next := then
	queue_free()
	if next.is_valid():
		next.call()


func _unhandled_input(event: InputEvent) -> void:
	# Back puts the question away unanswered: B on a pad, or Escape, GAME.md 4.2.
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
		if _was_focused != null and is_instance_valid(_was_focused):
			_was_focused.grab_focus()
		else:
			# What had the cursor has gone, a question answered before this one came up: the first
			# button of the screen underneath has it, so a pad is not left with nothing to press.
			var first := SettingsScreen._first_focusable(get_parent())
			if first != null and first != self and not is_ancestor_of(first):
				first.grab_focus()
