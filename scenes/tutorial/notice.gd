class_name TutorialNotice
extends PanelContainer
## The tutorial's word at the top of the screen, GAME.md 9.4a: a line or two about the thing in
## front of the player, the two ways to drive, what an item is, what a joker is, what the pot and
## the bank are, where the fight's bar goes, and under that bar while it is up, and the welcome
## at the very start with the game's mark over it. Each lesson says
## its piece by a key of its own and clears only that, so one lesson's word never wipes another's;
## a lesson ending clears whatever is up. Said in words alone, since a panel of them is read where
## a sign floating in the room was noise.

signal changed

const WIDTH := 640.0
const INK := Palette.CHIP_WHITE
const FADE := 0.25
const MARK_SIDE := 110.0
const INFO_SIDE := 22.0

var _label: Label
var _mark: Control
var _title: Label
var _info: Control
var _key := &""


## The information mark in front of a word: a ring with an i in it, so the panel reads as a note
## and not as something to answer.
class Info:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(INFO_SIDE, INFO_SIDE)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var middle := Vector2(INFO_SIDE, INFO_SIDE) * 0.5
		draw_arc(middle, INFO_SIDE * 0.5 - 1.5, 0.0, TAU, 32, Palette.NEON_CYAN, 2.0, true)
		draw_circle(middle + Vector2(0.0, -5.0), 1.6, Palette.NEON_CYAN)
		draw_rect(Rect2(middle + Vector2(-1.4, -2.0), Vector2(2.8, 8.0)), Palette.NEON_CYAN)


static func add_to(layer: CanvasLayer) -> TutorialNotice:
	var notice := TutorialNotice.new()
	notice.name = "Notice"
	layer.add_child(notice)
	return notice


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", HudBlock.scrim())
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(WIDTH, 0.0)
	set_top(TouchControls.below_menu() if TouchInput.enabled else 16.0)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	_mark = CenterContainer.new()
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var logo := LogoArt.new()
	logo.plate = false
	logo.custom_minimum_size = Vector2(MARK_SIDE, MARK_SIDE)
	_mark.add_child(logo)
	_mark.visible = false
	column.add_child(_mark)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	_info = Info.new()
	_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_info)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(WIDTH - 24.0 - INFO_SIDE - 10.0, 0.0)
	Type.text(_label, Type.BODY, INK)
	HudText.shadowed(_label)
	row.add_child(_label)
	# The game's name under the welcome, in the gold the title screen writes it in.
	_title = MenuTheme.title("Jackpot Junction", Type.TITLE)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudText.shadowed(_title, 2)
	_title.visible = false
	column.add_child(_title)
	visible = false


## Says [param text], as [param key], in place of whatever was up, with an information mark in
## front of it; or for [param welcome] with the game's mark over it and the game's name under it,
## and no information mark, since a welcome is not a note.
func say(key: StringName, text: String, welcome := false) -> void:
	_key = key
	_label.text = text
	_mark.visible = welcome
	_title.visible = welcome
	_info.visible = not welcome
	if not visible:
		visible = true
		modulate.a = 0.0
		var fade := create_tween()
		fade.tween_property(self, "modulate:a", 1.0, FADE)
	changed.emit()


## Takes the word down: the one said as [param key], or whatever is up for no key.
func clear(key := &"") -> void:
	if not visible or (key != &"" and key != _key):
		return
	visible = false
	_key = &""
	changed.emit()


func is_saying(key: StringName) -> bool:
	return visible and _key == key


## The words up just now, or nothing.
func said() -> String:
	return _label.text if visible else ""


## Where it hangs from the top of the screen.
func set_top(top: float) -> void:
	offset_top = top
	offset_bottom = top


## Where the screen is clear again under it, from the top, for what else hangs there; where it
## hangs from while it is down.
func below() -> float:
	if not visible:
		return offset_top
	return offset_top + get_combined_minimum_size().y + 10.0
