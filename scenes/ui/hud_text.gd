class_name HudText
extends RefCounted
## Text drawn over the arena rather than over a menu's own background. The floor beneath it is
## green felt one moment and a white block the next, so every piece of it carries the same drop
## shadow: without one, a label is legible over half the table and gone over the other half.

const SHADOW := Color(0.0, 0.0, 0.0, 0.8)
## The smallest a number fitted to its label is set, see [method fit].
const FIT_SMALLEST := 16


## Gives [param label] the shadow and hands it back, so it can be built and shadowed in one go.
## Small text takes the one-pixel offset; anything bigger needs the two.
static func shadowed(label: Label, offset: int = 2) -> Label:
	label.add_theme_color_override("font_shadow_color", SHADOW)
	label.add_theme_constant_override("shadow_offset_x", offset)
	label.add_theme_constant_override("shadow_offset_y", offset)
	return label


## [param text] in [param label] at [param full] size, or smaller as far as it takes to fit the
## label's width rather than be clipped by it: a banked score of five figures and more in a
## player's corner, GAME.md 8.3. Worked out again only when the text or the width changes.
## TODO: Godot 4.8's Label.auto_font_size does this; once the game is on 4.8 it can stand in for
## this, see "Resize font to fit option for Label and RichTextLabel" under GUI in
## https://godotengine.org/article/dev-snapshot-godot-4-8-dev-4/
static func fit(label: Label, text: String, full: int) -> void:
	var wide := label.size.x
	if label.text == text and is_equal_approx(float(label.get_meta(&"fit_wide", -1.0)), wide):
		return
	label.text = text
	label.set_meta(&"fit_wide", wide)
	var size := full
	if wide > 0.0:
		var font := label.get_theme_font(&"font")
		var need := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, full).x
		if need > wide:
			size = maxi(floori(full * wide / need), FIT_SMALLEST)
	if label.get_theme_font_size(&"font_size") != size:
		label.add_theme_font_size_override(&"font_size", size)
