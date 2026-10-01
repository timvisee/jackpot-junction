class_name TutorialBossBar
extends PanelContainer
## The bar across the top of the screen for the tutorial's last lesson, GAME.md 9.4a: how much
## of the points to bank has been banked, the way a boss's health would be shown, so the end of
## the tutorial is one thing to reach rather than a line on the checklist.

const WIDTH := 520.0
const INK := Palette.CHIP_GOLD

var need := 400

var _bar: ProgressBar
var _count: Label


static func add_to(layer: CanvasLayer, points: int) -> TutorialBossBar:
	var bar := TutorialBossBar.new()
	bar.name = "BossBar"
	bar.need = points
	layer.add_child(bar)
	return bar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", HudBlock.scrim())
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	var top := TouchControls.below_menu() if TouchInput.enabled else 16.0
	offset_top = top
	offset_bottom = top
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var title := Label.new()
	title.text = "BANK %d TO FINISH" % need
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.strong(title, Type.LARGE, INK)
	HudText.shadowed(title)
	column.add_child(title)
	_bar = HudBlock.bar(Vector2(WIDTH, 16.0), INK)
	_bar.value = 0.0
	column.add_child(_bar)
	_count = Label.new()
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.numbers(_count, Type.BODY, Palette.CHIP_WHITE)
	HudText.shadowed(_count)
	column.add_child(_count)
	show_banked(0)


func show_banked(banked: int) -> void:
	_bar.value = clampf(float(banked) / maxf(float(need), 1.0), 0.0, 1.0) * 100.0
	_count.text = "%d / %d" % [mini(banked, need), need]
