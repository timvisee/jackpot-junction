shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Noir: the frame as a hard-boiled picture shoots it, in black and white through a red filter, so
// the felt goes dark and the lamps burn white; the shadows crushed to black and the highlights
// blooming a little in the lens; a fine grain; the corners lost in the dark. Only the players
// keep their color, their karts and their shots, laid on flat and full the way the comic-book
// pictures lay them, so the karts are the brightest things in town.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform float contrast : hint_range(1.0, 3.0) = 1.6;
// Where the middle gray falls, as the lightness of the frame.
uniform float middle : hint_range(0.2, 0.8) = 0.45;
uniform float grain : hint_range(0.0, 0.2) = 0.06;
uniform float vignette : hint_range(0.0, 1.0) = 0.65;
uniform float kept : hint_range(0.0, 1.0) = 1.0;

// How the color c of the frame comes out on the screen, in linear light: the ACES curve every room
// is tonemapped with, at the white most rooms use.
vec3 shown(vec3 c) {
	const mat3 into = mat3(
			vec3(0.59719, 0.35458, 0.04823) * 1.8,
			vec3(0.07600, 0.90834, 0.01566) * 1.8,
			vec3(0.02840, 0.13383, 0.83777) * 1.8);
	const mat3 out_of = mat3(
			vec3(1.60475, -0.53108, -0.07367),
			vec3(-0.10208, 1.10813, -0.00605),
			vec3(-0.00327, -0.07276, 1.07602));
	c = max(c, vec3(0.0)) * into;
	c = (c * (c + 0.0245786) - 0.000090537) / (c * (0.983729 * c + 0.432951) + 0.238081);
	return clamp(c * out_of / 0.977, 0.0, 1.0);
}

// The light the tonemapper turns into d on the screen: shown() run backward.
vec3 unshown(vec3 d) {
	const mat3 out_of = mat3(
			vec3(0.64303825, 0.31118675, 0.04577546),
			vec3(0.05926869, 0.93143649, 0.00929492),
			vec3(0.0059619, 0.06392902, 0.93011838));
	const mat3 into = mat3(
			vec3(0.98041165, -0.37543204, -0.04942405),
			vec3(-0.08168214, 0.64458417, -0.00734648),
			vec3(-0.02018713, -0.09024246, 0.66598515));
	vec3 y = clamp(max(d, vec3(0.0)) * 0.977 * out_of, 0.0, 0.99);
	vec3 a = 1.0 - y * 0.983729;
	vec3 b = 0.0245786 - y * 0.432951;
	vec3 c = -(0.000090537 + y * 0.238081);
	vec3 x = (-b + sqrt(b * b - 4.0 * a * c)) / (2.0 * a);
	return max(x * into, vec3(0.0));
}

vec3 oklab(vec3 c) {
	vec3 lms = vec3(
			dot(c, vec3(0.4122214708, 0.5363325363, 0.0514459929)),
			dot(c, vec3(0.2119034982, 0.6806995451, 0.1073969566)),
			dot(c, vec3(0.0883024619, 0.2817188376, 0.6299787005)));
	lms = pow(max(lms, vec3(0.0)), vec3(1.0 / 3.0));
	return vec3(
			dot(lms, vec3(0.2104542553, 0.7936177850, -0.0040720468)),
			dot(lms, vec3(1.9779984951, -2.4285922050, 0.4505937099)),
			dot(lms, vec3(0.0259040371, 0.7827717662, -0.8086757660)));
}

float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	float a = fract(sin(i * 127.1) * 43758.5453);
	float b = fract(sin((i + 1.0) * 127.1) * 43758.5453);
	return mix(a, b, f * f * (3.0 - 2.0 * f));
}

float clump(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// The black and white of c: panchromatic film through a red filter, which darkens the greens and
// blues and lightens the reds and the skin.
float film_of(vec3 c) {
	return dot(c, vec3(0.5, 0.42, 0.08));
}

void fragment() {
	vec3 c0 = texture(screen_tex, SCREEN_UV).rgb;
	vec2 px = pixel(VIEWPORT_SIZE);
	// Worked as the frame would come out on the screen, so its blacks and whites are the screen's.
	vec3 c = shown(c0);
	float frame = floor(TIME * 24.0);
	// The tone: the frame's lightness, pushed hard apart about its middle and eased into the black
	// and the white at either end.
	float l = pow(max(film_of(c), 0.0), 1.0 / 2.2);
	float t = (l - middle) * contrast + 0.5;
	t = clamp(t, 0.0, 1.0);
	t = mix(t, smoothstep(0.0, 1.0, t), 0.6);
	// The deepest shadows keep a trace of what is in them, so a dark room's table still reads.
	t = max(t, l * 0.22);
	// The bloom: the lamps and the bright walls glowing a little into the dark round them.
	vec3 halo = shown(textureLod(screen_mip, SCREEN_UV, 3.5).rgb);
	float bloom = max(pow(max(film_of(halo), 0.0), 1.0 / 2.2) - 0.7, 0.0) * 0.9;
	float grey = clamp(t + bloom, 0.0, 1.1);
	// The grain: fine and dancing, heavier in the middle tones.
	float g = clump(SCREEN_UV / px / 1.3 + vec2(frame * 17.31, frame * 7.77)) - 0.5;
	grey *= 1.0 + g * grain * 2.0 * (0.4 + 1.2 * grey * (1.0 - grey));
	// The kept colors: what is saturated and stands on the table, no higher than a kart, the karts
	// and their shots, in full color and lifted a step, so it is never lost in a shadow.
	vec3 view = view_at(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 world = (INV_VIEW_MATRIX * vec4(view, 1.0)).xyz;
	float standing = smoothstep(0.06, 0.18, world.y) * (1.0 - smoothstep(1.6, 2.2, world.y));
	float top = max(max(c.r, c.g), c.b);
	float sat = (top - min(min(c.r, c.g), c.b)) / max(top, 1e-4);
	// A kart is a broad patch of one strong color; a fan in the stands wearing it is a speck among
	// faces and others' colors, so the frame round a pixel, blurred, tells the two apart. A shot is
	// small, but it burns.
	vec3 round = shown(textureLod(screen_mip, SCREEN_UV, 3.0).rgb);
	float round_top = max(max(round.r, round.g), round.b);
	float round_sat = (round_top - min(min(round.r, round.g), round.b)) / max(round_top, 1e-4);
	float broad = smoothstep(0.3, 0.5, round_sat);
	float burning = smoothstep(1.2, 2.0, max(max(c0.r, c0.g), c0.b));
	// The players' colors are full, fuller than the brass and gold of a room's walls, which sit
	// between their orange and their yellow: near that hue a color must be fuller to be kept.
	vec3 lab = oklab(c);
	float chroma = length(lab.yz);
	float angle = degrees(atan(lab.z, lab.y));
	float gold = 1.0 - smoothstep(0.0, 18.0, abs(angle - 74.0));
	float full = smoothstep(mix(0.07, 0.13, gold), mix(0.095, 0.15, gold), chroma);
	float keep = full * smoothstep(0.4, 0.6, sat) * standing * max(broad, burning) * kept;
	vec3 hue = c / max(top, 1e-4);
	hue = mix(vec3(dot(hue, vec3(0.3, 0.55, 0.15))), hue, 1.25);
	vec3 colored = clamp(hue, 0.0, 1.0) * (0.3 + 0.75 * top);
	// The lens: the corners fall away into the dark.
	vec2 q = (SCREEN_UV - 0.5) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
	float edge = 1.0 - vignette * smoothstep(0.3, 1.05, length(q));
	vec3 bw = vec3(pow(clamp(grey, 0.0, 1.0), 2.2)) * vec3(1.0, 0.99, 0.97);
	vec3 outv = mix(bw, colored, keep) * edge;
	ALBEDO = mix(c0, unshown(outv), amount);
}
