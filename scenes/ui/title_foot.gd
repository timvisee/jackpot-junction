class_name TitleFoot
extends Control
## The title screen's foot, GAME.md 3.8, over the whole screen and taking no clicks itself: the
## version in the bottom right corner, and for a player who owns the Steam supporter pack, 10.8, a
## quiet line in the bottom left, the pack's star and its name in the version's gray, shown the
## moment it is owned. A click or a tap on that line holds the thank-you card up again, see
## [SupporterThanks]; the cursor never goes to it, as the settings' Me page holds the card up for a
## pad. Faded in with what peeks in at the edges at the end of the title's opening.

const INK := Color(0.6, 0.6, 0.65)
## The supporter pack's line's words under the mouse, lit as something a click acts on.
const INK_LIT := Color(0.88, 0.88, 0.92)
## How far in from the screen's sides and its foot the two stand, and the supporter pack's line:
## its words and how big its star is.
const SIDE := 16.0
const FOOT := 12.0
const SUPPORTER := "Supporter Pack"
const PIN := 24.0

## The supporter pack's line, shown while the pack is owned.
var supporter: HBoxContainer
## The thank-you card while it is held up from the supporter pack's line.
var thanks: SupporterThanks


## The foot on [param title], the version saying [param words].
static func add_to(title: Control, words: String) -> TitleFoot:
	var foot := TitleFoot.new()
	foot.name = "Foot"
	foot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var version := Label.new()
	version.name = "Version"
	version.text = words
	version.add_theme_color_override("font_color", INK)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_right = -SIDE
	version.offset_bottom = -FOOT
	foot.add_child(version)
	foot.supporter = _supporter_line()
	foot.supporter.gui_input.connect(foot._on_supporter_input)
	foot.add_child(foot.supporter)
	title.add_child(foot)
	return foot


## The pack's star and its name, in the bottom left corner.
static func _supporter_line() -> HBoxContainer:
	var line := HBoxContainer.new()
	line.name = "Supporter"
	line.mouse_filter = Control.MOUSE_FILTER_STOP
	line.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	line.add_theme_constant_override("separation", 6)
	line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	line.grow_vertical = Control.GROW_DIRECTION_BEGIN
	line.offset_left = SIDE
	line.offset_bottom = -FOOT
	var pin := Control.new()
	pin.custom_minimum_size = Vector2.ONE * PIN
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pin.draw.connect(func() -> void: PartTray.draw_star(pin, pin.size / 2.0, PIN * 0.42))
	line.add_child(pin)
	var words := Label.new()
	words.name = "Words"
	words.text = SUPPORTER
	words.add_theme_color_override("font_color", INK)
	line.add_child(words)
	for lit: bool in [true, false]:
		(line.mouse_entered if lit else line.mouse_exited).connect(
			words.add_theme_color_override.bind("font_color", INK_LIT if lit else INK)
		)
	line.visible = Supporter.owned()
	return line


## A click or a tap on the supporter pack's line holds the thank-you card up again over the title,
## once the foot has come in; put away, the cursor is back where it was.
func _on_supporter_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	var pressed := (
		(click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
		or (touch != null and touch.pressed)
	)
	if not pressed or thanks != null or modulate.a < 1.0 or Demo.on:
		return
	get_viewport().set_input_as_handled()
	Audio.play_sfx(&"ui_click", MenuTheme.CLICK_DB, 0.0)
	var had := get_viewport().gui_get_focus_owner()
	thanks = SupporterThanks.again_over(get_parent())
	thanks.put_away.connect(
		func() -> void:
			thanks = null
			if is_instance_valid(had) and had.is_visible_in_tree():
				had.grab_focus()
	)


## Owned or no longer, the supporter pack's line shown or not, as the pack is.
func _process(_delta: float) -> void:
	if supporter != null and supporter.visible != Supporter.owned():
		supporter.visible = Supporter.owned()
