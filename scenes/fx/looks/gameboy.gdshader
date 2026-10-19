shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Four greens: the frame on a pocket console's screen. A grid of about two hundred lines, each dot
// one of four shades of green, the tones between laid in an ordered dither; everything that stands
// out from what is behind it edged in the darkest green, as a sprite is; and the saturated colors
// keeping a hint of their hue, the way the later consoles colored the old cartridges' sprites, so
// four karts are four karts. The dots sit in a fine grid of gaps, and each throws a faint shadow
// down and to the right onto the screen's backing. The grid is laid from the middle of the table,
// so it slides with the room as the camera pans.
uniform float lines : hint_range(120.0, 360.0) = 216.0;
// How much of a saturated color's hue a dot keeps.
uniform float hint : hint_range(0.0, 1.0) = 1.0;
uniform float outline : hint_range(0.0, 1.0) = 1.0;
// How strongly the gaps between the dots and their shadows show.
uniform float screen : hint_range(0.0, 1.0) = 1.0;

// The four greens, darkest first, in OKLab.
const vec3 GREENS[4] = {
	vec3(0.3015, -0.0653, 0.0488),
	vec3(0.4478, -0.0771, 0.0565),
	vec3(0.6478, -0.0804, 0.1272),
	vec3(0.7973, -0.0665, 0.1219)
};

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

vec3 linear_of(vec3 lab) {
	vec3 lms = vec3(
			lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z,
			lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z,
			lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z);
	lms = lms * lms * lms;
	return vec3(
			dot(lms, vec3(4.0767416621, -3.3077115913, 0.2309699292)),
			dot(lms, vec3(-1.2684380046, 2.6097574011, -0.3413193965)),
			dot(lms, vec3(-0.0041960863, -0.7034186147, 1.7076147010)));
}

// The ordered dither's threshold for the dot at p, 0 to 1, from a four by four Bayer matrix.
float bayer(vec2 p) {
	vec2 a = mod(p, 2.0);
	vec2 b = mod(floor(p * 0.5), 2.0);
	float outer = a.x * 2.0 + a.y * 3.0 - 4.0 * a.x * a.y;
	float inner = b.x * 2.0 + b.y * 3.0 - 4.0 * b.x * b.y;
	return (outer * 4.0 + inner + 0.5) / 16.0;
}

// The frame at the dot centered on uv, what most of its square shows.
vec3 dot_at(vec2 uv, vec2 q) {
	return (texture(screen_tex, uv - q).rgb + texture(screen_tex, uv + q).rgb
			+ texture(screen_tex, uv + vec2(q.x, -q.y)).rgb + texture(screen_tex, uv + vec2(-q.x, q.y)).rgb) * 0.25;
}

// Which of the four greens the color s, as shown, falls to at the dot of dither threshold t, and
// how far toward the next it was, as a fraction.
float tone_of(vec3 lab) {
	// The blues and the reds a step darker than their lightness alone, so a blue kart and a red one
	// do not come out the shade of the felt or of each other.
	float blue = smoothstep(0.05, 0.16, -lab.z) * 0.12;
	float red = smoothstep(0.08, 0.16, lab.y) * 0.04;
	return clamp((lab.x - blue - red - 0.24) / 0.62, 0.0, 1.0) * 3.0;
}

void fragment() {
	vec3 c0 = texture(screen_tex, SCREEN_UV).rgb;
	vec2 size = VIEWPORT_SIZE;
	float block = max(2.0, floor(size.y / lines + 0.5));
	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	vec2 anchor = (clip.xy / clip.w * 0.5 + 0.5) * size;
	vec2 inside = (SCREEN_UV * size - anchor) / block;
	vec2 cell = floor(inside);
	vec2 uv = (anchor + (cell + 0.5) * block) / size;
	vec2 b = vec2(block) / size;
	vec2 q = b * 0.25;
	vec3 lab = oklab(shown(dot_at(uv, q)));
	// Flat shades, dithered only across the narrow step from one to the next, as a sprite artist
	// would lay them.
	int level = int(clamp(floor(tone_of(lab) + 0.5 + (bayer(cell) - 0.5) * 0.55), 0.0, 3.0));
	// The sprite's edge: a dot with something much nearer than itself beside it.
	vec3 view = view_at(uv, INV_PROJECTION_MATRIX);
	float d = -view.z;
	float least = min(
			min(distance_at(uv + vec2(b.x, 0.0), INV_PROJECTION_MATRIX), distance_at(uv - vec2(b.x, 0.0), INV_PROJECTION_MATRIX)),
			min(distance_at(uv + vec2(0.0, b.y), INV_PROJECTION_MATRIX), distance_at(uv - vec2(0.0, b.y), INV_PROJECTION_MATRIX)));
	if ((d - least) / d > 0.006 && least < 400.0 && outline > 0.5) {
		level = 0;
	}
	vec3 green = GREENS[level];
	// The hue a saturated color keeps, laid onto the green of its shade.
	float chroma = length(lab.yz);
	// Only what stands up off the table keeps it: the karts, their shots, the blocks. What is printed
	// on the felt is drawn in the greens alone.
	vec3 world = (INV_VIEW_MATRIX * vec4(view, 1.0)).xyz;
	float standing = smoothstep(0.08, 0.2, world.y);
	float keep = smoothstep(0.08, 0.14, chroma) * standing * hint;
	green = mix(green, vec3(mix(green.x, lab.x, 0.35), lab.yz * 1.1), keep);
	vec3 lit = linear_of(green);
	// The screen: a faint gap round each dot where the backing shows, and the dot's shadow on it,
	// thrown down and to the right from the dot before.
	float dot_px = max(1.0, floor(size.y / 1080.0 + 0.5));
	vec2 f = (inside - cell) * block;
	float gap = max(step(block - dot_px, f.x), step(block - dot_px, f.y));
	vec3 backing = linear_of(GREENS[3]);
	vec3 before = oklab(shown(texture(screen_tex, uv - b).rgb));
	float shadow = smoothstep(0.0, 1.5, tone_of(lab) - tone_of(before)) * 0.12;
	lit = mix(lit, backing, gap * 0.1 * screen);
	lit *= 1.0 - shadow * screen;
	ALBEDO = mix(c0, unshown(lit), amount);
}
