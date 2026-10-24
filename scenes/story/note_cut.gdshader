shader_type canvas_item;
// Turns blending off and writes a clear pixel where it draws, so it replaces the paper with
// transparency rather than painting over it: a hole cut in a note, see [NoteCut].
render_mode blend_disabled;

void fragment() {
	COLOR = vec4(0.0);
}
