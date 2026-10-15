// A clock over a slot machine, GAME.md 3.15: a dark face with a cream rim, and a wedge in the
// waiting kart's color for the rest it still has to wait, emptying clockwise from the top as a
// clock's hand goes. Turned to the camera wherever it stands. See SlotDial.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

// How much of the rest is left, from 1 to 0, and how strongly the dial shows.
uniform float left : hint_range(0.0, 1.0) = 1.0;
uniform float shown : hint_range(0.0, 1.0) = 1.0;
uniform vec4 face_color : source_color = vec4(0.12, 0.11, 0.14, 0.92);
uniform vec4 left_color : source_color = vec4(0.95, 0.75, 0.3, 1.0);
uniform vec4 rim_color : source_color = vec4(0.95, 0.92, 0.84, 1.0);

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]
	);
}

void fragment() {
	vec2 at = UV * 2.0 - 1.0;
	float r = length(at);
	float edge = fwidth(r);
	float turn = fract(atan(at.x, -at.y) / TAU + 1.0);
	float disc = 1.0 - smoothstep(1.0 - edge, 1.0, r);
	float rim = smoothstep(0.8 - edge, 0.8, r);
	float wedge = step(turn, left) * (1.0 - smoothstep(0.68 - edge, 0.68, r));
	vec3 color = mix(face_color.rgb, left_color.rgb, wedge);
	color = mix(color, rim_color.rgb, rim);
	ALBEDO = color;
	ALPHA = disc * shown * max(face_color.a, max(wedge, rim));
}
