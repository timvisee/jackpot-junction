class_name ScreenReader
extends RefCounted
## What the menus tell a screen reader, GAME.md 8.5. The engine hands it everything through
## AccessKit while one is running, the project's accessibility support left on Auto so a player
## without one pays nothing for it, and it reads by itself a button's words, a label's, a switch's
## state, a slider's value and the entry a box to pick from shows. What the game draws for itself
## has no words for it to find: the license peeking in, Kit's folder, the catalog's cards, the kart
## dialog's hooks and cans. Each of those is named here from the words the screen shows for it, so
## the two say the same thing and follow the story's words as they change, and what is drawn to
## be pressed says it is a button. What comes up without the cursor going to it, a notice, a
## question, the lamps of the start and who won, is said as it comes; nothing that changes every
## frame is, since a reader reading the HUD's numbers would never get a word in.

## What a [Voice] is called among its parent's children, see [method say].
const VOICE := &"ScreenReaderVoice"
## What stands between the parts of something said as one line, the House's middle dot read as a
## pause rather than as its name.
const PAUSE := ", "
## How a switch flipped away from the cursor is said to be, see [method switched].
const ON := "On"
const OFF := "Off"


## Words said for something drawn rather than written, see [method say]: a line of text to a
## screen reader, its words its name, and nothing at all on the screen, laid out by nothing.
class Voice:
	extends Control

	func _init() -> void:
		name = VOICE
		top_level = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE

	func _notification(what: int) -> void:
		if what != NOTIFICATION_ACCESSIBILITY_UPDATE:
			return
		var element := get_accessibility_element()
		if element.is_valid():
			AccessibilityServer.update_set_role(element, AccessibilityServer.ROLE_STATIC_TEXT)
			AccessibilityServer.update_set_value(element, accessibility_name)


## A control drawn by whoever makes it, pressed as a button is, that a screen reader is told is a
## button, see [method drawn].
class Pressable:
	extends Control

	func _notification(what: int) -> void:
		ScreenReader.drawn(self, what)


## Names [param control] [param words] for a screen reader, with [param more] read after them,
## and gives it back. Either is set only when it changes, since every change is told to the reader.
static func name(control: Control, words: String, more := "") -> Control:
	if control.accessibility_name != words:
		control.accessibility_name = words
	if control.accessibility_description != more:
		control.accessibility_description = more
	return control


## Names what stands beside a row's label for [param words], see [method MenuTheme.row]:
## [param control] itself where it takes the cursor, and otherwise whatever in it does, a slider in
## a box with its value beside it, say. One with a name or words of its own, the two ways to drive
## or Help me choose, keeps them and is told the row's after them. Nothing for no words.
static func label(control: Control, words: String) -> void:
	if words.is_empty():
		return
	var named: Array[Node] = [control]
	if control.focus_mode == Control.FOCUS_NONE:
		named = control.find_children("*", "Control", true, false)
	for each: Node in named:
		var part := each as Control
		if part.focus_mode == Control.FOCUS_NONE:
			continue
		var button := part as Button
		var worded := button != null and not button.text.is_empty() and part is not OptionButton
		if part.accessibility_name.is_empty() and not worded:
			part.accessibility_name = words
		elif part.accessibility_description.is_empty():
			part.accessibility_description = words


## Has a screen reader read [param control] out whenever what it says changes, and as it comes up:
## after whatever the reader is saying, or at once for [param urgent]. Gives it back.
static func live(control: Control, urgent := false) -> Control:
	control.accessibility_live = (
		AccessibilityServer.LIVE_ASSERTIVE if urgent else AccessibilityServer.LIVE_POLITE
	)
	return control


## Hides [param content] while [param layer] is hidden, as the screen does: the engine leaves
## what is in a hidden layer for a screen reader to read, stale, and says nothing of it as it comes
## back, so what a layer says is read only while it is up, and again each time it comes up.
static func with_layer(layer: CanvasLayer, content: CanvasItem) -> void:
	content.visible = layer.visible
	layer.visibility_changed.connect(func() -> void: content.visible = layer.visible)


## Says [param words] for [param on], something drawn rather than written, as a screen reader
## comes to it: after whatever it is saying, or at once for [param urgent]. The words are a [Voice]
## of its own, made the first time, and said again only once they change. Nothing for no words.
static func say(on: Node, words: String, urgent := false) -> void:
	var voice := on.get_node_or_null(NodePath(VOICE)) as Voice
	if voice == null:
		if words.is_empty():
			return
		voice = Voice.new()
		on.add_child(voice)
	live(voice, urgent)
	name(voice, words)


## What [param on] has last said, see [method say], or nothing.
static func said(on: Node) -> String:
	var voice := on.get_node_or_null(NodePath(VOICE)) as Control
	return voice.accessibility_name if voice != null else ""


## [param words], the name of a switch flipped by its bind rather than under the cursor, said with
## whether it is now [param on], see [method say].
static func switched(words: String, on: bool) -> String:
	return line([words, ON if on else OFF])


## The House's capitals said as a sentence, and its middle dots as pauses: "THE GARAGE  ·  BAY 1"
## is "The garage, bay 1". Some readers spell out a word in capitals, or say so before each letter.
static func spoken(printed: String) -> String:
	var words := line([printed.to_lower()])
	return words.left(1).to_upper() + words.substr(1)


## [param parts] said one after another as a line, those with words and not the same as the one
## before, each a pause from the next, a middle dot or a line break inside one of them a pause too.
static func line(parts: PackedStringArray) -> String:
	var kept := PackedStringArray()
	for part: String in parts:
		var words := part.replace("·", ",").replace("\n", ", ").strip_edges()
		while words.contains("  "):
			words = words.replace("  ", " ")
		words = words.replace(" ,", ",").replace(",,", ",")
		if not words.is_empty() and (kept.is_empty() or kept[-1] != words):
			kept.append(words)
	return PAUSE.join(kept)


## What [param control] says on the screen, as one line, see [method line]: the words of every
## label showing in it, in order, any in the House's capitals said as a sentence; none drawn into a
## picture of its own, a page turning over it, say.
static func words_in(control: Control) -> String:
	var said := PackedStringArray()
	for each: Node in control.find_children("*", "Label", true, false):
		var label := each as Label
		var words := label.text
		if not label.is_visible_in_tree() or label.get_viewport() != control.get_viewport():
			continue
		if words.strip_edges().is_empty():
			continue
		var capitals := words == words.to_upper() and words != words.to_lower()
		said.append(spoken(words) if capitals else words)
	return line(said)


## For [param control]'s _notification, something the game draws itself: while it takes the
## cursor, a button to a screen reader, pressed by the reader as the accept button presses it, or
## [param role], an entry of a list say, for one only looked at; and a picture while it does not.
static func drawn(
	control: Control,
	what: int,
	role: AccessibilityServer.AccessibilityRole = AccessibilityServer.ROLE_BUTTON
) -> void:
	if what != Node.NOTIFICATION_ACCESSIBILITY_UPDATE:
		return
	var element := control.get_accessibility_element()
	if not element.is_valid():
		return
	if control.focus_mode == Control.FOCUS_NONE:
		AccessibilityServer.update_set_role(element, AccessibilityServer.ROLE_IMAGE)
		return
	AccessibilityServer.update_set_role(element, role)
	if role == AccessibilityServer.ROLE_BUTTON:
		AccessibilityServer.update_add_action(
			element, AccessibilityServer.ACTION_CLICK, func(_data: Variant) -> void: press(control)
		)


## For [param control]'s _notification, a pane that asks something or tells it: a dialog to a
## screen reader, read as its name and what more it says as the cursor comes into it.
static func dialog(control: Control, what: int) -> void:
	if what != Node.NOTIFICATION_ACCESSIBILITY_UPDATE:
		return
	var element := control.get_accessibility_element()
	if element.is_valid():
		AccessibilityServer.update_set_role(element, AccessibilityServer.ROLE_DIALOG)


## Presses [param control] the way the accept button does, the cursor going to it first: what a
## screen reader's own press on something drawn to be pressed does, see [method drawn].
static func press(control: Control) -> void:
	if not is_instance_valid(control) or not control.is_visible_in_tree():
		return
	control.grab_focus()
	for down: bool in [true, false]:
		var accept := InputEventAction.new()
		accept.action = &"ui_accept"
		accept.pressed = down
		Input.parse_input_event(accept)


## What a screen reader calls [param control], as the engine puts it together: a label's text, or
## its name, before a button's words where it has both, or else the button's words or its tooltip.
static func heard(control: Control) -> String:
	if control is Label:
		return (control as Label).text
	var button := control as Button
	var words := button.text if button != null else ""
	if not control.accessibility_name.is_empty():
		return control.accessibility_name + (": " + words if not words.is_empty() else "")
	return words if not words.is_empty() else control.tooltip_text
