shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Woodblock: the frame printed as an ukiyo-e is, from a key block and a block for each ink. The key
// block's black line round every shape; under it a few flat water-based inks, each a little out of
// register with the line and showing the grain of its block; the shade and the top of the sheet
// wiped in a bokashi, a gradient rubbed into the block by hand; all of it on fibrous washi.
// Its colors are as the screen shows them, after the tone map.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 washi = vec3(0.93, 0.88, 0.77);
uniform vec3 sumi = vec3(0.1, 0.09, 0.09);
uniform vec3 bero = vec3(0.15, 0.25, 0.43);
// How far the inks sit off the key block's line, in pixels at 1080 lines.
uniform vec2 register = vec2(1.8, -1.2);
uniform float line_width : hint_range(1.0, 5.0) = 3.6;

// The room's tone map (ACES, white 6) with its contrast and saturation, near enough, and its
// inverse: the look is drawn in the colors the screen will show, then handed back to the tone map.
const mat3 TO_RRT = mat3(vec3(1.074942, 0.638244, 0.086814), vec3(0.1368, 1.635012, 0.028188),
		vec3(0.05112, 0.240894, 1.507986));
const mat3 TO_RGB = mat3(vec3(1.60475, -0.53108, -0.07367), vec3(-0.10208, 1.10813, -0.00605),
		vec3(-0.00327, -0.07276, 1.07602));
const mat3 FROM_RRT = mat3(vec3(0.980412, -0.375432, -0.049424), vec3(-0.081682, 0.644584,
		-0.007346), vec3(-0.020187, -0.090242, 0.665985));
const mat3 FROM_RGB = mat3(vec3(0.643038, 0.311187, 0.045775), vec3(0.059269, 0.931436,
		0.009295), vec3(0.005962, 0.063929, 0.930118));

vec3 to_screen(vec3 c) {
	vec3 x = max(c, 0.0) * TO_RRT;
	vec3 t = clamp((x * (x + 0.0245786) - 0.000090537) / (x * (0.983729 * x + 0.432951) + 0.238081)
			* TO_RGB / 0.977, 0.0, 1.0);
	vec3 s = mix(t * 12.92, 1.055 * pow(t, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, t));
	s = mix(vec3(0.5), s, 1.06);
	return clamp(mix(vec3((s.r + s.g + s.b) / 3.0), s, 1.06), 0.0, 1.0);
}

vec3 from_screen(vec3 s) {
	s = clamp(s, 0.0, 1.0);
	s = mix(vec3((s.r + s.g + s.b) / 3.0), s, 1.0 / 1.06);
	s = clamp((s - 0.5) / 1.06 + 0.5, 0.0, 1.0);
	vec3 t = mix(s / 12.92, pow((s + 0.055) / 1.055, vec3(2.4)), step(0.04045, s));
	vec3 y = clamp(t * 0.977 * FROM_RGB, 0.0, 1.0);
	vec3 a = 1.0 - 0.983729 * y;
	vec3 b = 0.0245786 - 0.432951 * y;
	vec3 k = 0.000090537 + 0.238081 * y;
	vec3 x = (-b + sqrt(b * b + 4.0 * a * k)) / (2.0 * a);
	return max(x * FROM_RRT, 0.0);
}

// Two steady random numbers per lattice point, with no trigonometry (Dave Hoskins' hash).
vec2 hash2(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

// Gradient noise, 0 to 1 about a middle of a half: smooth, without value noise's grid.
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float na = dot(hash2(i) * 2.0 - 1.0, f);
	float nb = dot(hash2(i + vec2(1.0, 0.0)) * 2.0 - 1.0, f - vec2(1.0, 0.0));
	float nc = dot(hash2(i + vec2(0.0, 1.0)) * 2.0 - 1.0, f - vec2(0.0, 1.0));
	float nd = dot(hash2(i + vec2(1.0, 1.0)) * 2.0 - 1.0, f - vec2(1.0, 1.0));
	return 0.5 + 0.9 * mix(mix(na, nb, u.x), mix(nc, nd, u.x), u.y);
}

// Where the ray through uv meets the table's floor: a place in the room that stays put however the
// camera moves, and runs on without a break over everything that stands on the floor.
vec2 floor_at(vec2 uv, mat4 inv_projection, mat4 inv_view) {
	vec4 far = inv_projection * vec4(uv * 2.0 - 1.0, 0.5, 1.0);
	vec3 dir = (inv_view * vec4(far.xyz / far.w, 0.0)).xyz;
	vec3 eye = inv_view[3].xyz;
	return (eye + dir * (-eye.y / min(dir.y, -1e-3))).xz;
}

// How light a linear color shows on the screen, near enough to to_screen's and a good deal
// cheaper: the tone curve on its luma alone.
float screen_luma(vec3 c) {
	float x = luma(max(c, 0.0)) * 1.8;
	float t = clamp((x * (x + 0.0245786) - 0.000090537) / (x * (0.983729 * x + 0.432951) + 0.238081) / 0.977, 0.0, 1.0);
	return t < 0.0031308 ? t * 12.92 : 1.055 * pow(t, 1.0 / 2.4) - 0.055;
}

// How near the room is at uv, as one over the distance: flat on any plane across the screen, so a
// step in it is an edge and a slope is not.
float near_at(vec2 uv, mat4 inv_projection) {
	// Only the depth reaches a perspective's z and w, so two rows of the matrix are enough.
	float d = texture(depth_tex, uv).x;
	float z = inv_projection[2][2] * d + inv_projection[3][2];
	float w = inv_projection[2][3] * d + inv_projection[3][3];
	return -w / min(z, -1e-3 * abs(w));
}

// An outline and a fold at uv, cheaply: a step in nearness across r on the screen as a share of
// the nearness, and the surface bending there, from four taps of the depth round it.
float line_at(vec2 uv, vec2 r, mat4 inv_projection) {
	float q = near_at(uv, inv_projection);
	float sx = near_at(uv + vec2(r.x, 0.0), inv_projection) + near_at(uv - vec2(r.x, 0.0), inv_projection) - 2.0 * q;
	float sy = near_at(uv + vec2(0.0, r.y), inv_projection) + near_at(uv - vec2(0.0, r.y), inv_projection) - 2.0 * q;
	float s = max(abs(sx), abs(sy)) / q;
	return max(smoothstep(0.006, 0.014, s), smoothstep(0.0015, 0.004, s) * 0.8);
}

// A linear color as the screen shows it, with no tone mapping: a thing's own color.
vec3 srgb(vec3 c) {
	c = clamp(c, 0.0, 1.0);
	return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c));
}

// A dark room's colors brought up by g, its darks most and its lights hardly at all.
vec3 lift(vec3 c, float g) {
	return c * g / (1.0 + c * (g - 1.0));
}

// How far the pixel at uv lies behind something nearer r away on the screen, as a share of its own
// nearness: the line is cut on what is behind, so the thing in front keeps all of its ink.
float behind(vec2 uv, vec2 r, mat4 inv_projection) {
	float q = near_at(uv, inv_projection);
	float s = 0.0;
	vec2 d[4] = vec2[](vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(0.7071, 0.7071), vec2(0.7071, -0.7071));
	for (int i = 0; i < 4; i++) {
		float a = near_at(uv + d[i] * r, inv_projection);
		float b = near_at(uv - d[i] * r, inv_projection);
		s = max(s, (a + b - 2.0 * q) / q);
	}
	return s;
}

// A screen color in Oklab, and back: lightness and two axes of hue that the eye sees evenly.
vec3 oklab(vec3 c) {
	vec3 lin = pow(clamp(c, 0.0, 1.0), vec3(2.2));
	vec3 lms = mat3(vec3(0.4122214708, 0.2119034982, 0.0883024619),
			vec3(0.5363325363, 0.6806995451, 0.2817188376),
			vec3(0.0514459929, 0.1073969566, 0.6299787005)) * lin;
	lms = pow(max(lms, 0.0), vec3(1.0 / 3.0));
	return mat3(vec3(0.2104542553, 1.9779984951, 0.0259040371),
			vec3(0.7936177850, -2.4285922050, 0.7827717662),
			vec3(-0.0040720468, 0.4505937099, -0.8086757660)) * lms;
}

vec3 from_oklab(vec3 lab) {
	vec3 lms = mat3(vec3(1.0, 1.0, 1.0), vec3(0.3963377774, -0.1055613458, -0.0894841775),
			vec3(0.2158037573, -0.0638541728, -1.2914855480)) * lab;
	lms = lms * lms * lms;
	vec3 lin = mat3(vec3(4.0767416621, -1.2684380046, -0.0041960863),
			vec3(-3.3077115913, 2.6097574011, -0.7034186147),
			vec3(0.2309699292, -0.3413193965, 1.7076147010)) * lms;
	return pow(clamp(lin, 0.0, 1.0), vec3(1.0 / 2.2));
}

// A hue pulled toward the nearest of the printer's pigments: vermilion, gamboge, a leaf green, an
// indigo green, Prussian blue and a purple, as angles round Oklab's hue circle.
float pigment(float h) {
	const float PIG[6] = float[](0.5, 1.55, 2.55, 3.05, -1.7, -0.9);
	float best = h;
	float near = 10.0;
	for (int i = 0; i < 6; i++) {
		float d = mod(h - PIG[i] + 3.14159265, 6.2831853) - 3.14159265;
		if (abs(d) < near) {
			near = abs(d);
			best = PIG[i] + d * 0.45;
		}
	}
	return best;
}

// Rice paper: a soft mottle with long fibers laid every way through it.
float fibers(vec2 p) {
	float f = 0.0;
	for (int i = 0; i < 3; i++) {
		float a = float(i) * 2.1 + 0.4;
		mat2 turn = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a)));
		f += smoothstep(0.66, 0.92, noise(turn * p * vec2(0.03, 0.4) + float(i) * 7.0));
	}
	return f;
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	vec3 raw = texture(screen_tex, uv).rgb;
	vec2 p = uv / px;
	float dist = -view_at(uv, INV_PROJECTION_MATRIX).z;
	float room = 1.0 - smoothstep(160.0, 220.0, dist);

	// The color blocks, printed a little off the key block, from the room's own colors judged
	// against the frame as a whole, so a dark room is printed in the same inks as a light one.
	vec2 at = uv + register * px;
	float key = luma(textureLod(screen_mip, vec2(0.5), 10.0).rgb);
	float gain = clamp(0.2 / max(key, 0.01), 1.0, 3.5);
	vec3 c = srgb(lift(textureLod(screen_mip, at, 0.5).rgb, gain));
	vec3 around = srgb(lift(textureLod(screen_mip, at, 4.5).rgb, gain));
	// Each block prints one flat ink: the lightness stepped into a few tones, the hue pulled
	// toward the printer's pigments, the color a little muted as water-based pigment is; the
	// lightest tone is the bare washi.
	vec3 lab = oklab(c);
	float steps_l = 4.0;
	float t = lab.x * steps_l;
	float tk = floor(t);
	float l_step = (tk + smoothstep(0.42, 0.58, t - tk)) / steps_l;
	float chroma = length(lab.yz);
	float hue = pigment(atan(lab.z, lab.y));
	chroma = min(chroma * 1.05, 0.21);
	vec3 ink = from_oklab(vec3(mix(lab.x, l_step, 0.8) * 0.94 + 0.02, chroma * cos(hue), chroma * sin(hue)));
	ink = mix(ink, washi, smoothstep(0.88, 0.95, lab.x) * (1.0 - smoothstep(0.04, 0.1, chroma)));

	// The shade printed from a block of its own in a bokashi: a gray-blue wiped deepest in the
	// middle of the shade and fading out toward its edges.
	float s = smoothstep(0.25, 0.5, 1.0 - luma(c) / max(luma(around), 0.05));
	vec3 c_soft = srgb(lift(textureLod(screen_mip, at, 3.5).rgb, gain));
	float s_soft = smoothstep(0.2, 0.55, 1.0 - luma(c_soft) / max(luma(around), 0.05));
	float shade = s * (0.35 + 0.65 * s_soft);
	// The top of the sheet: the ichimonji bokashi, a band of blue rubbed in from the edge.
	float sky = smoothstep(0.2, 0.0, uv.y + (noise(vec2(p.x / 400.0, 1.0)) - 0.5) * 0.04);

	// The grain of each block shows faintly in its lighter inks, long and nearly straight, and the
	// baren's rubbing leaves the ink a little uneven.
	vec2 g = p / vec2(400.0, 6.0);
	float wave = noise(vec2(g.x, g.y * 0.05)) * 1.5 + noise(p / 300.0) * 1.0;
	float streak = sin((g.y * 0.5 + wave) * 6.2831853) * 0.5 + 0.5;
	float grain = smoothstep(0.6, 1.0, streak) * smoothstep(0.35, 0.75, noise(p / vec2(60.0, 4.0)));
	float rub = noise(p / 70.0 + 4.0);
	float print = 0.92 - 0.14 * grain * smoothstep(0.2, 0.6, luma(ink)) + 0.12 * (rub - 0.5);
	// Where one ink's block stops short of the next's, a sliver of bare paper.
	vec3 next = srgb(lift(textureLod(screen_mip, at + register * px * 1.2, 0.5).rgb, gain));
	float gap = smoothstep(0.15, 0.35, length(next - c)) * 0.45;

	// On the paper: each ink laid over the washi, multiplied, as water-based pigment sits.
	float fib = fibers(p);
	vec3 paper = washi * (0.97 + 0.05 * fib + 0.04 * (noise(p / 7.0) - 0.5));
	vec3 laid = paper * mix(vec3(1.0), ink / washi, clamp(print, 0.0, 1.0) * (1.0 - gap));
	laid *= mix(vec3(1.0), mix(vec3(0.62, 0.66, 0.75), bero / washi, 0.3), shade * 0.85);
	laid *= mix(vec3(1.0), bero / washi * 0.9 + 0.1, sky * 0.75);

	// The key block's line, in sumi, over all of it: cut round each shape where it stands in front
	// of another, on the side of what is behind, so a kart keeps its color inside its line.
	float line = 0.0;
	vec2 sub[2] = vec2[](vec2(0.25, 0.25), vec2(-0.25, -0.25));
	for (int i = 0; i < 2; i++) {
		line += smoothstep(0.012, 0.02, behind(uv + sub[i] / VIEWPORT_SIZE, px * line_width, INV_PROJECTION_MATRIX));
	}
	line = max(line * 0.5, smoothstep(0.012, 0.02, behind(uv, px * line_width * 0.5, INV_PROJECTION_MATRIX)));
	// A finer cut along every fold.
	line = max(line, line_at(uv, px, INV_PROJECTION_MATRIX) * 0.85) * room;
	vec3 outv = mix(laid, sumi * (0.9 + 0.1 * fib), line * 0.95);
	vec3 result = from_screen(outv);
	// A bullet keeps its glow.
	result = mix(result, raw, smoothstep(1.1, 1.8, luma(raw)));
	ALBEDO = mix(raw, result, amount);
}
