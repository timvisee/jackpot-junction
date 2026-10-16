// Where the House expects the candidate's kart a second and a half from now, STORY.md 8.2, thrown
// onto the floor as its forecast is, see [ForecastLine]: a kart's outline seen from above, its body
// and wheels, a chevron off its nose the way it is going, lines of the projector's scan across it,
// flickering, and stuttering for a moment as the forecast is thrown again.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 ink : source_color = vec4(0.96, 0.76, 0.3, 1.0);
// How big the floor it lies on is, in meters, across and along; how bright; how much it stutters.
uniform vec2 extent = vec2(1.6, 2.4);
uniform float strength = 1.0;
uniform float glitch = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float round_box(vec2 p, vec2 half_size, float corner) {
	vec2 q = abs(p) - half_size + corner;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - corner;
}

void fragment() {
	// Meters from its middle, the nose toward +y.
	vec2 p = (UV - 0.5) * extent;
	float body = round_box(p, vec2(0.42, 0.72), 0.2);
	float wheels = 1e3;
	for (int i = 0; i < 4; i++) {
		vec2 at = vec2(i % 2 == 0 ? -0.5 : 0.5, i < 2 ? -0.45 : 0.45);
		wheels = min(wheels, round_box(p - at, vec2(0.09, 0.17), 0.05));
	}
	float outline = exp(-pow(body / 0.035, 2.0)) + exp(-pow(wheels / 0.03, 2.0)) * 0.8;
	float fill = (1.0 - smoothstep(-0.25, 0.02, body)) * 0.18;
	// A chevron off the nose.
	vec2 c = p - vec2(0.0, 0.98);
	float chevron = abs(c.y + abs(c.x) * 0.7);
	float arrow = exp(-pow(chevron / 0.035, 2.0)) * step(abs(c.x), 0.3);
	float scan = 0.65 + 0.35 * sin(p.y * 22.0 - TIME * 7.0);
	float flicker = 0.88 + 0.12 * sin(TIME * 53.0) * sin(TIME * 7.0);
	float stutter = 1.0 - glitch * step(0.4, hash(vec2(floor(TIME * 30.0), floor(p.y * 4.0))));
	ALBEDO = ink.rgb;
	ALPHA = clamp((outline + fill + arrow) * scan * flicker * stutter * strength, 0.0, 1.0);
}
