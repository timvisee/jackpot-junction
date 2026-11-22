class_name TitleFoot
extends Control
## The title screen's foot, GAME.md 3.8, over the whole screen and taking no clicks: the version in
## the bottom right corner, and for a player who owns the Steam supporter pack, 10.8, a quiet line
## in the bottom left, the pack's star and its name in the version's gray, shown the moment it is
## owned. Faded in with what peeks in at the edges at the end of the title's opening.

const INK := Color(0.6, 0.6, 0.65)
## How far in from the screen's sides and its foot the two stand, and the supporter pack's line:
## its words and how big its star is.
const SIDE := 16.0
const FOOT := 12.0
const SUPPORTER := "Supporter Pack"
const PIN := 24.0

## The supporter pack's line, shown while the pack is owned.
var supporter: HBoxContainer


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
	foot.add_child(foot.supporter)
	title.add_child(foot)
	return foot


## The pack's star and its name, in the bottom left corner.
static func _supporter_line() -> HBoxContainer:
	var line := HBoxContainer.new()
	line.name = "Supporter"
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	words.text = SUPPORTER
	words.add_theme_color_override("font_color", INK)
	line.add_child(words)
	line.visible = Supporter.owned()
	return line


## Owned or no longer, the supporter pack's line shown or not, as the pack is.
func _process(_delta: float) -> void:
	if supporter != null and supporter.visible != Supporter.owned():
		supporter.visible = Supporter.owned()
