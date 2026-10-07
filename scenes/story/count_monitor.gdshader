// A monitor in the Count Room, STORY.md 3.9: rows of figures in the room's green scrolling up the
// screen, nobody reading them. Drawn rather than written: each row a run of blocks the size of a
// digit, a length of its own, the gaps between them where a digit came out as a space.
shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform vec4 ink : source_color = vec4(0.25, 1.0, 0.4, 1.0);
uniform float rows = 12.0;
uniform float digits = 18.0;
uniform float speed = 0.8;
// Each screen starts its scroll somewhere of its own.
uniform float offset = 0.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	float t = TIME * speed + offset;
	float y = (1.0 - UV.y) * rows - t;
	float row = floor(y);
	float inside = fract(y);
	float column = floor(UV.x * digits);
	float within = fract(UV.x * digits);
	float run = 4.0 + floor(hash(row * 3.7 + offset) * (digits - 5.0));
	float glyph = step(column, run) * step(0.18, within) * step(within, 0.82);
	glyph *= step(0.22, inside) * step(inside, 0.78);
	glyph *= step(0.18, hash(row * 7.0 + column * 1.3 + offset));
	ALBEDO = ink.rgb * (0.06 + glyph * 0.94);
}
