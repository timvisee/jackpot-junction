class_name KeyboardBar
extends CanvasLayer
## A phone's keyboard comes up over the bottom of the screen, and a text box down there goes under
## it: a player types their name blind. So while a box is being typed into and the keyboard covers
## it, this shows what is in it on a bar just above the keyboard, GAME.md 8.3: what the box is for
## and its words, with the caret where it is, as a box of its own. The typing goes into the box
## itself as ever, so everything that listens to the box hears it the way it always has, and the
## bar goes the moment the box lets go or the keyboard does.
##
## Put up by [Game] on a touch screen; on a desktop there is no keyboard on the screen to cover
## anything, and it never shows.

## How far over the keyboard the bar sits, how much room it leaves round its words, and how often
## the caret blinks, in seconds.
const GAP := 8.0
const PAD := 14.0
const BLINK := 0.5
const INK := Color(0.95, 0.95, 0.97)
const HINT_INK := Color(0.66, 0.66, 0.72)

## How tall the keyboard is in the window's pixels, for a test; below zero asks the system.
static var keyboard_for_tests := -1.0

var _panel: PanelContainer
var _named: Label
var _words: Label
var _clock := 0.0


static func add_to(parent: Node) -> KeyboardBar:
	var bar := KeyboardBar.new()
	bar.name = "KeyboardBar"
	parent.add_child(bar)
	return bar


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.name = "Bar"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := MenuTheme.pane_style()
	style.content_margin_top = PAD
	style.content_margin_bottom = PAD
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	add_child(_panel)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 18)
	_panel.add_child(line)
	_named = Label.new()
	Type.text(_named, Type.BODY, HINT_INK)
	line.add_child(_named)
	_words = Label.new()
	_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_words.clip_text = true
	Type.text(_words, Type.BODY, INK)
	line.add_child(_words)


func _process(delta: float) -> void:
	_clock += delta
	var field := covered()
	_panel.visible = field != null
	if field == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var above := screen.y - _keyboard() - GAP
	_named.text = what_for(field)
	_named.visible = not _named.text.is_empty()
	_words.text = shown(field, fmod(_clock, BLINK * 2.0) < BLINK)
	var wide := minf(screen.x - GAP * 2.0, 900.0)
	_panel.size = Vector2(wide, 0.0)
	_panel.position = Vector2((screen.x - wide) * 0.5, above - _panel.get_combined_minimum_size().y)


## The box being typed into, if the keyboard is up and covers it, or null.
func covered() -> LineEdit:
	var keyboard := _keyboard()
	if keyboard <= 0.0:
		return null
	var field := get_viewport().gui_get_focus_owner() as LineEdit
	if field == null or not field.is_visible_in_tree() or not field.editable:
		return null
	var top := get_viewport().get_visible_rect().size.y - keyboard
	return field if field.get_global_rect().end.y > top else null


## How tall the keyboard is, in the viewport's own units.
func _keyboard() -> float:
	var tall := keyboard_for_tests
	if tall < 0.0:
		tall = float(DisplayServer.virtual_keyboard_get_height())
	var window := float(get_window().size.y)
	return tall * get_viewport().get_visible_rect().size.y / window if window > 0.0 else 0.0


## What [param field] is for: the words beside it in its row, or its hint.
static func what_for(field: LineEdit) -> String:
	var parent := field.get_parent()
	if parent is HBoxContainer:
		for sibling: Node in parent.get_children():
			if sibling == field:
				break
			if sibling is Label and not (sibling as Label).text.is_empty():
				return (sibling as Label).text
	return field.placeholder_text


## [param field]'s words as the bar shows them, dots for a secret, with the caret where it is when
## [param caret] says to draw it.
static func shown(field: LineEdit, caret: bool) -> String:
	var words := field.text
	if field.secret:
		words = field.secret_character.repeat(words.length())
	var at := clampi(field.caret_column, 0, words.length())
	return words.left(at) + ("|" if caret else " ") + words.substr(at)
