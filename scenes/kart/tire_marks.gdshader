// The marks a kart leaves on the floor, GAME.md 4.3, one look for every kart's. Unshaded, both
// faces. Every vertex carries the time it was laid in its first texture coordinate, and in its
// second the alpha of the ordinary mark there, which fades over fade_seconds from the moment it
// is laid, and how far along its run it was laid. Its color's red is which edge of the mark it is
// on, 0 the left and 1 the right, and its green how wide the mark is there, in half meters, for a
// mark drawn across as well as along. A gold one carries a
// nonzero second number in its first coordinate for how long the gold lasts: it holds solid for
// the first part of that and then goes, so the trail behind the kart reads as gold rather than as
// a gold already going, and leaves the ordinary mark under it once it has.
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
// The gold of a mark for a kart one cash-out from winning, GAME.md 3.4, how solid it is, and how
// much brighter than its color it is drawn, so it glows where the bloom is on.
uniform vec3 gilt = vec3(1.0, 0.7608, 0.1216);
uniform float gilt_alpha = 0.92;
uniform float gold_glow = 1.35;
// The marks' finish, GAME.md 8.9, faint as the marks are: none, Foil a warm gold in the ink,
// Holographic a color drifting along the run, Polychrome bands of color along it.
uniform int finish = 0;
uniform float finish_share = 0.32;
// Kit's pencil, GAME.md 8.9: the mark drawn by hand rather than laid, see sketched(), and how much
// darker its strokes are than a mark laid solid, for covering less of it.
uniform bool pencil = false;
uniform float pencil_press = 2.0;

vec3 hue(float h) {
	return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x);
	float b = mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x);
	return mix(a, b, f.y);
}

// How much graphite a pencil mark leaves at [along] meters down its run and [across] it, 0 to 1,
// the mark [wide] meters across: scribbled in, the pencil going back and forth across the mark as
// it goes along, as a hand shades a band in quickly. The hand's rhythm wanders and it does not
// always reach the edges; it presses harder and softer and lifts off now and then; where the kart
// leant on its tires, [heavy], it goes over the band a second time. Over it all the grain of the
// graphite, the tooth of the paper showing through.
float sketched(float along, float across, float wide, float heavy) {
	float drawn = 0.0;
	for (int i = 0; i < 2; i++) {
		float pass = float(i);
		float phase = along / 0.14 + 2.2 * noise(vec2(along * 0.9, 1.0 + pass * 4.0)) + pass * 0.4;
		float low = 0.05 + 0.16 * noise(vec2(along * 3.0, 7.0 + pass * 3.0));
		float high = 0.95 - 0.16 * noise(vec2(along * 3.0, 11.0 + pass * 3.0));
		// The stroke out is quicker than the stroke back, by more or less as the hand goes on.
		float out_share = 0.35 + 0.15 * noise(vec2(along * 1.3, 17.0 + pass));
		float t = fract(phase);
		bool going = t < out_share;
		float reach = going ? t / out_share : (1.0 - t) / (1.0 - out_share);
		float line = mix(low, high, reach);
		// How far from the stroke, in meters: across the band, foreshortened by how steeply the
		// stroke crosses it.
		float run = 0.14 * (going ? out_share : 1.0 - out_share);
		float steep = wide * (high - low) / run;
		float apart = abs(across - line) * wide / sqrt(1.0 + steep * steep);
		float soft = max(fwidth(apart), 0.002);
		float half_width = 0.008 + 0.005 * noise(vec2(along * 6.0, pass * 5.0));
		float stroke = 1.0 - smoothstep(half_width - soft, half_width + soft, apart);
		float press = 0.5 + 0.5 * noise(vec2(along * 0.8 + pass * 13.0, 3.0));
		float lifted = step(0.07, fract(along / (2.1 + pass * 0.8) + pass * 0.45));
		float weight = pass < 0.5 ? 1.0 : 0.7 * heavy;
		drawn = max(drawn, stroke * press * lifted * weight);
	}
	float grain = noise(vec2(along * 80.0, across * 9.0));
	return drawn * mix(0.35, 1.0, grain);
}

void fragment() {
	float age = now - UV.x;
	float on = dash > 0.0 ? step(fract(UV2.y / dash), dash_on) : 1.0;
	if (pencil) {
		float heavy = smoothstep(0.12, 0.35, UV2.x);
		on = min(sketched(UV2.y, COLOR.r, COLOR.g * 0.5, heavy) * pencil_press, 1.0);
	}
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
	ALBEDO = mix(laid, gilt * gold_glow, gold);
	ALPHA = mix(mark, gilt_alpha, gold);
}
