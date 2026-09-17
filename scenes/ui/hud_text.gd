class_name HudText
extends RefCounted
## Text drawn over the arena rather than over a menu's own background. The floor beneath it is
## green felt one moment and a white block the next, so every piece of it carries the same drop
## shadow: without one, a label is legible over half the table and gone over the other half.

const SHADOW := Color(0.0, 0.0, 0.0, 0.8)


## Gives [param label] the shadow and hands it back, so it can be built and shadowed in one go.
## Small text takes the one-pixel offset; anything bigger needs the two.
static func shadowed(label: Label, offset: int = 2) -> Label:
	label.add_theme_color_override("font_shadow_color", SHADOW)
	label.add_theme_constant_override("shadow_offset_x", offset)
	label.add_theme_constant_override("shadow_offset_y", offset)
	return label
