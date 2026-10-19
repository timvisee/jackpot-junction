shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Duotone: the frame printed in the House's two inks on its cream paper, the gold laid down for
// the middle tones and the deep ink over it for the dark ones, as a poster of the House's own
// would be. The players' colors are a third, spot ink, so every kart and every shot stays its own.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 paper = vec3(0.949, 0.918, 0.839);
uniform vec3 gold = vec3(0.925, 0.706, 0.278);
uniform vec3 ink = vec3(0.086, 0.071, 0.110);
// How much of the paper's tooth shows.
uniform float grain : hint_range(0.0, 0.1) = 0.03;

// The room's tonemap as the engine lays it over what the pass writes: ACES as Godot fits it, with
// a white of 6, then the screen's sRGB. shown() is how a color of the frame looks on the screen,
// unshown() what to write for a color to look as given, so an ink is chosen as it prints.
vec3 shown(vec3 c) {
	vec3 x = max(c, vec3(0.0)) * mat3(vec3(1.074942, 0.638244, 0.086814),
			vec3(0.1368, 1.635012, 0.028188), vec3(0.05112, 0.240894, 1.507986));
	vec3 t = (x * (x + 0.0245786) - 0.000090537) / (x * (0.983729 * x + 0.432951) + 0.238081);
	t = t * mat3(vec3(1.60475, -0.53108, -0.07367), vec3(-0.10208, 1.10813, -0.00605),
			vec3(-0.00327, -0.07276, 1.07602));
	t = clamp(t / 0.977011, 0.0, 1.0);
	return mix(t * 12.92, 1.055 * pow(t, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), t));
}

vec3 unshown(vec3 s) {
	s = clamp(s, 0.0, 1.0);
	vec3 l = mix(s / 12.92, pow((s + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), s));
	vec3 t = (l * 0.977011) * mat3(vec3(0.643038, 0.311187, 0.045775),
			vec3(0.059269, 0.931436, 0.009295), vec3(0.005962, 0.063929, 0.930118));
	t = clamp(t, vec3(-0.00038), vec3(0.999));
	vec3 a = t * 0.983729 - 1.0;
	vec3 b = t * 0.432951 - 0.0245786;
	vec3 k = t * 0.238081 + 0.000090537;
	vec3 x = (-b - sqrt(b * b - 4.0 * a * k)) / (2.0 * a);
	return max(x * mat3(vec3(0.980412, -0.375432, -0.049424), vec3(-0.081682, 0.644584, -0.007346),
			vec3(-0.020187, -0.090242, 0.665985)), vec3(0.0));
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// The hue of a color, 0 to 1 round the wheel.
float hue_of(vec3 c) {
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float d = mx - mn + 1e-5;
	float h = mx == c.r ? (c.g - c.b) / d : (mx == c.g ? 2.0 + (c.b - c.r) / d : 4.0 + (c.r - c.g) / d);
	return fract(h / 6.0);
}

// The spot ink for a hue, if it is one of the players' four, red, yellow, green and blue, and how
// near it is to it.
vec4 player_ink(float h) {
	float red = 1.0 - smoothstep(0.035, 0.07, min(h, 1.0 - h));
	float yellow = 1.0 - smoothstep(0.03, 0.06, abs(h - 0.14));
	float green = 1.0 - smoothstep(0.05, 0.09, abs(h - 0.33));
	float blue = 1.0 - smoothstep(0.06, 0.1, abs(h - 0.62));
	vec4 best = vec4(0.9, 0.16, 0.14, red);
	best = yellow > best.w ? vec4(1.0, 0.86, 0.12, yellow) : best;
	best = green > best.w ? vec4(0.22, 0.74, 0.3, green) : best;
	best = blue > best.w ? vec4(0.2, 0.44, 0.96, blue) : best;
	return best;
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec3 s = shown(c);
	float l = luma(s);
	// The plate is made for the room: a dark room is opened up so it prints rather than drowning
	// in ink, gently, so the print does not breathe as the camera moves over a lit room.
	float key = luma(shown(textureLod(screen_mip, vec2(0.5), 9.0).rgb));
	float gain = clamp(sqrt(0.4 / max(key, 0.05)), 1.0, 2.0);
	float tone = clamp(l * gain, 0.0, 1.0);

	// Two inks over the paper, laid as a print lays them: the gold over the whole of the dark half
	// and thinning out through the lights, the deep ink over it the darker it gets, each ink's
	// density adding up the way layers of ink do, so the gold deepens through bronze to the ink.
	float gold_cover = 1.0 - smoothstep(0.62, 0.95, tone);
	float ink_cover = 1.0 - smoothstep(0.1, 0.6, tone);
	vec3 printed = paper * pow(gold / paper, vec3(gold_cover)) * pow(ink / gold, vec3(ink_cover));
	// The spot ink: what is in a player's color is printed in that player's own ink over the two
	// plates, flat and full, shaded only where the picture is shaded.
	float mx = max(s.r, max(s.g, s.b));
	float sat = (mx - min(s.r, min(s.g, s.b))) / max(mx, 1e-4);
	vec4 spot_ink = player_ink(hue_of(s));
	float spot = smoothstep(0.45, 0.65, sat) * smoothstep(0.2, 0.32, mx) * spot_ink.w;
	float spot_shade = smoothstep(0.1, 0.6, mx * gain);
	vec3 spot_printed = spot_ink.rgb * pow(ink / paper, vec3((1.0 - spot_shade) * 0.6));
	vec3 spotted = mix(printed, spot_printed, spot);

	// The paper's tooth, at a whisper.
	vec2 cell = floor(SCREEN_UV / px);
	float tooth = hash12(cell) * 0.6 + hash12(floor(cell * 0.5) + 7.0) * 0.4;
	spotted *= 1.0 - grain * (tooth - 0.5) * 2.0;

	vec3 outv = unshown(spotted);
	// What glows keeps its glow over the ink.
	float hot = smoothstep(1.6, 2.6, max(c.r, max(c.g, c.b)));
	outv = mix(outv, max(outv, c), hot);
	ALBEDO = mix(c, outv, amount);
}
