// The marks a kart leaves on the floor, GAME.md 4.3, one look for every kart's. Unshaded, both
// faces. Every vertex carries the time it was laid in its first texture coordinate, and in its
// second the alpha of the ordinary mark there, which fades over fade_seconds from the moment it
// is laid. A gold one carries its gold in its color on top of that, and a nonzero second
// coordinate for how long the gold lasts: it holds solid for the first part of that and then
// goes, so the trail behind the kart reads as gold rather than as a gold already going, and
// leaves the ordinary mark under it once it has.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;

uniform float now = 0.0;
uniform vec3 ink = vec3(0.01, 0.0081, 0.0081);
uniform float fade_seconds = 20.0;
// A mark broken into dashes like a lane line, GAME.md 8.9: this many meters from one dash to the
// next, the second coordinate's second number being how far along its run the mark was laid, and
// how much of that a dash is. None for a mark laid unbroken.
uniform float dash = 0.0;
uniform float dash_on = 0.55;
// How much brighter than its color a gold mark is drawn, so it glows where the bloom is on.
uniform float gold_glow = 1.35;
// The marks' finish, GAME.md 8.9, faint as the marks are: none, Foil a warm gold in the ink,
// Holographic a color drifting along the run, Polychrome bands of color along it.
uniform int finish = 0;
uniform float finish_share = 0.32;

vec3 hue(float h) {
	return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void fragment() {
	float age = now - UV.x;
	float on = dash > 0.0 ? step(fract(UV2.y / dash), dash_on) : 1.0;
	float mark = UV2.x * on * clamp(1.0 - age / fade_seconds, 0.0, 1.0);
	float gold = UV.y > 0.0 ? 1.0 - smoothstep(0.45, 1.0, age / UV.y) : 0.0;
	vec3 laid = ink;
	if (finish == 1) {
		laid = mix(ink, vec3(0.62, 0.47, 0.16), finish_share);
	} else if (finish == 2) {
		laid = mix(ink, hue(UV2.y * 0.06 + now * 0.04) * 0.7, finish_share);
	} else if (finish == 3) {
		laid = mix(ink, hue(floor(UV2.y * 0.5) * 0.17) * 0.7, finish_share);
	}
	ALBEDO = mix(laid, COLOR.rgb * gold_glow, gold);
	ALPHA = mix(mark, COLOR.a, gold);
}
