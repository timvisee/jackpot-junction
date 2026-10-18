class_name JumpIcon
extends Control
## The face of Next new, GAME.md 8.8: an arrow coming down onto a dot, the cursor dropped onto the
## next thing new, in the ink of the button it is on, as that button's words would be in its every
## state, see [NextNew]. Drawn, so it is as sharp at every size and UI scale as the button round it.

## Its size, the shaft's thickness as a share of its height, and the dot's radius.
const SIZE := Vector2(34.0, 28.0)
const LINE := 0.12
const DOT := 0.14

## The button it is the face of, whose state says its ink.
var button: Button


## The icon for [param on], drawn again whenever the button is.
static func on(on_button: Button) -> JumpIcon:
	var icon := JumpIcon.new()
	icon.name = "Jump"
	icon.button = on_button
	icon.custom_minimum_size = SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	on_button.draw.connect(icon.queue_redraw)
	return icon


func _draw() -> void:
	var ink := _ink()
	var w := size.x
	var h := size.y
	var line := h * LINE
	var top := Vector2(w * 0.5, h * 0.02)
	var tip := Vector2(w * 0.5, h * 0.58)
	draw_line(top, tip - Vector2(0.0, line), ink, line, true)
	var back := tip - Vector2(0.0, line * 2.6)
	var head := PackedVector2Array(
		[
			tip + Vector2(0.0, line * 0.6),
			back + Vector2(line * 1.9, 0.0),
			back - Vector2(line * 1.9, 0.0)
		]
	)
	draw_colored_polygon(head, ink)
	draw_circle(Vector2(w * 0.5, h * 0.86), h * DOT, ink, true, -1.0, true)


## The ink the button's words would be in, in the state it is in now.
func _ink() -> Color:
	if button == null:
		return Color.WHITE
	match button.get_draw_mode():
		BaseButton.DRAW_HOVER:
			return button.get_theme_color(&"font_hover_color")
		BaseButton.DRAW_PRESSED:
			return button.get_theme_color(&"font_pressed_color")
		BaseButton.DRAW_HOVER_PRESSED:
			return button.get_theme_color(&"font_hover_pressed_color")
		BaseButton.DRAW_DISABLED:
			return button.get_theme_color(&"font_disabled_color")
	return button.get_theme_color(&"font_color")
