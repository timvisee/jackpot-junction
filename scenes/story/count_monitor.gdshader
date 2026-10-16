// A monitor in the Count Room, STORY.md 3.9: rows of figures in the room's green scrolling up the
// screen, nobody reading them. Drawn rather than written: each row a run of blocks the size of a
// digit, a length of its own, the gaps between them where a digit came out as a space. At the Final
// Hand, from observation, 8.2, the figures dim under a plan of the table watching the candidate's
// kart: crosshairs through it, brackets round it, its forecast dotted out ahead to a gold point, and
// a red light blinking in the corner, see [HouseWatch].
shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform vec4 ink : source_color = vec4(0.25, 1.0, 0.4, 1.0);
uniform vec4 gold : source_color = vec4(0.96, 0.76, 0.3, 1.0);
uniform float rows = 12.0;
uniform float digits = 18.0;
uniform float speed = 0.8;
// Each screen starts its scroll somewhere of its own.
uniform float offset = 0.0;
// How much the screen shows the table, 0 none; where on it the candidate's kart is, and its
// forecast, each 0 to 1 across the table's width and depth.
uniform float watching = 0.0;
uniform vec2 mark = vec2(0.5);
uniform vec2 ahead = vec2(0.5);

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

// 1 within [param width] of the segment from a to b, measured with the screen's shape.
float segment(vec2 p, vec2 a, vec2 b, float width) {
	vec2 pa = (p - a) * vec2(1.0, 0.62);
	vec2 ba = (b - a) * vec2(1.0, 0.62);
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
	return step(length(pa - ba * h), width) * step(0.45, fract(h * 5.0));
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
	vec3 color = ink.rgb * (0.06 + glyph * 0.94);
	if (watching > 0.0) {
		vec2 d = abs(UV - mark);
		float grid = max(step(fract(UV.x * 16.0), 0.035), step(fract(UV.y * 9.0), 0.05));
		float cross = max(step(d.x, 0.0025), step(d.y, 0.004)) * step(0.13, max(d.x * 1.6, d.y));
		vec2 box = vec2(0.065, 0.105);
		float sides = step(abs(d.x - box.x), 0.005) * step(d.y, box.y) * step(box.y * 0.45, d.y);
		float tops = step(abs(d.y - box.y), 0.008) * step(d.x, box.x) * step(box.x * 0.45, d.x);
		float point = step(length((UV - ahead) * vec2(1.0, 0.62)), 0.014);
		float dots = segment(UV, mark, ahead, 0.004);
		float rec = step(length((UV - vec2(0.06, 0.1)) * vec2(1.0, 0.62)), 0.018);
		rec *= step(0.5, fract(TIME * 1.1));
		vec3 plan = ink.rgb * (0.03 + glyph * 0.22 + grid * 0.16 + cross * 0.7 + max(sides, tops));
		plan = mix(plan, gold.rgb, max(point, dots));
		plan = mix(plan, vec3(0.95, 0.18, 0.12), rec);
		color = mix(color, plan, watching);
	}
	ALBEDO = color;
}
