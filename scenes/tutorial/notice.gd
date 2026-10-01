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
const MARK_SIDE := 72.0

var _label: Label
var _mark: Control
var _key := &""


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
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(WIDTH - 24.0, 0.0)
	Type.text(_label, Type.BODY, INK)
	HudText.shadowed(_label)
	column.add_child(_label)
	visible = false


## Says [param text], as [param key], in place of whatever was up, with the game's mark over it
## for [param with_mark].
func say(key: StringName, text: String, with_mark := false) -> void:
	_key = key
	_label.text = text
	_mark.visible = with_mark
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
