shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Chalkboard: the frame drawn in chalk on a dark slate board. Every outline in a stroke of white
// chalk that skips over the board's grain, each thing filled in loosely with the side of a stick
// as light as it is, the karts in colored chalk, and the board itself clouded with the dust of
// what was rubbed out before.
// Its colors are as the screen shows them, after the tone map.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 slate = vec3(0.15, 0.19, 0.17);
uniform vec3 chalk = vec3(0.93, 0.93, 0.88);
// The outline's width, in pixels at 1080 lines.
uniform float outline : hint_range(1.0, 5.0) = 2.6;

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

// How far the pixel at uv lies behind something nearer r away on the screen, as a share of its own
// nearness, and how sharply the surface under it folds f away.
vec2 steps(vec2 uv, vec2 r, vec2 f, mat4 inv_projection) {
	float q = near_at(uv, inv_projection);
	float behind = 0.0;
	float fold = 0.0;
	vec2 d[4] = vec2[](vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(0.7071, 0.7071), vec2(0.7071, -0.7071));
	for (int i = 0; i < 4; i++) {
		float a = near_at(uv + d[i] * r, inv_projection);
		float b = near_at(uv - d[i] * r, inv_projection);
		behind = max(behind, abs(a + b - 2.0 * q) / q);
		float fa = near_at(uv + d[i] * f, inv_projection);
		float fb = near_at(uv - d[i] * f, inv_projection);
		fold = max(fold, abs(fa + fb - 2.0 * q) / q);
	}
	return vec2(behind, fold);
}

// The side of a stick dragged across in one direction: broad, slightly wavering strokes a few
// pixels apart, each broken where the board's grain stood proud of it. q is the place in the room,
// fp a pixel's size there, so the strokes stay on what they were drawn on and keep their size on
// the screen.
float strokes_at(vec2 q, vec2 dir, float gap, float seed) {
	vec2 side = vec2(-dir.y, dir.x);
	float wave = (noise(vec2(dot(q, side) / (gap * 6.0), seed)) - 0.5) * 1.2;
	float s = dot(q, dir) / gap + wave;
	float k = floor(s);
	float along = dot(q, side) / (gap * 7.0) + hash(vec2(k, seed)) * 7.0;
	float j = floor(along);
	float u = fract(along);
	float press = hash(vec2(k + j * 3.1, seed));
	float body = smoothstep(0.0, 0.15, u) * (1.0 - smoothstep(0.6, 0.9 + 0.1 * press, u));
	float across = abs(fract(s) - 0.5) * 2.0;
	return (1.0 - smoothstep(0.3, 0.9, across)) * body * (0.45 + 0.55 * press);
}

// The strokes at a spacing of about eight pixels whatever the distance: stepped in octaves of the
// room's size, the next fading in as the one before grows too dense, so they never swim.
float scumble(vec2 q, vec2 dir, float fp, float seed) {
	float level = log2(8.0 * fp / 0.01);
	float base = floor(level);
	float gap = 0.01 * exp2(base);
	return mix(strokes_at(q, dir, gap, seed), strokes_at(q, dir, gap * 2.0, seed + 0.5), level - base);
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	vec3 raw = texture(screen_tex, uv).rgb;
	vec2 p = uv / px;
	vec3 view = view_at(uv, INV_PROJECTION_MATRIX);
	vec3 world = (INV_VIEW_MATRIX * vec4(view, 1.0)).xyz;
	float room = 1.0 - smoothstep(160.0, 220.0, -view.z);
	// Where on the room the pixel is, in the camera's axes, and a 1080-line pixel's size there.
	vec2 q = view.xy - VIEW_MATRIX[3].xy;
	float fp = -view.z * 2.0 / (abs(PROJECTION_MATRIX[1][1]) * 1080.0);

	// The board: slate, with the grain chalk catches on, and the cloud of old dust where things
	// were rubbed out, in long sweeps of the eraser.
	float grain = noise(p / 1.3) * 0.5 + noise(p / 3.0 + 7.0) * 0.5;
	vec2 sweep = mat2(vec2(0.94, 0.34), vec2(-0.34, 0.94)) * p;
	float dust = smoothstep(0.35, 0.95, noise(sweep / vec2(420.0, 90.0)) * 0.7 + noise(p / 160.0 + 5.0) * 0.5);
	dust *= 0.6 + 0.4 * noise(sweep / vec2(30.0, 3.0));
	vec3 board = slate * (0.92 + 0.12 * grain);
	board = mix(board, chalk, dust * 0.12 + 0.03);
	// Chalk only takes on the high points of the board.
	float tooth = smoothstep(0.25, 0.65, grain + 0.15);

	// The color of each thing, as chalk has it: pale and soft. The strong colors, the karts' among
	// them, as colored sticks.
	vec3 made = srgb(textureLod(screen_mip, uv, 0.5).rgb);
	float l = luma(made);
	float top = max(made.r, max(made.g, made.b));
	float sat = (top - min(made.r, min(made.g, made.b))) / max(top, 0.05);
	float colored = smoothstep(0.35, 0.65, sat) * smoothstep(0.15, 0.35, top);
	vec3 stick = mix(chalk, mix(made / max(top, 0.05), vec3(1.0), 0.3), colored);

	// Filled in loosely with the side of the stick, as hard as the thing is light, in two
	// directions where it is lightest; the table itself is left as the board.
	float standing = smoothstep(0.04, 0.2, world.y);
	float amount_fill = smoothstep(0.15, 0.75, l) * (0.35 + 0.65 * standing) + colored * 0.35;
	float a = scumble(q, normalize(vec2(0.8, 0.6)), fp, 1.0);
	float b = scumble(q, normalize(vec2(-0.5, 0.87)), fp, 2.0);
	float fill = a * smoothstep(0.1, 0.4, amount_fill) + b * smoothstep(0.5, 0.9, amount_fill) * 0.7;
	// Under the strokes, the chalk rubbed in with a finger: a soft haze of it.
	float rubbed = amount_fill * 0.3 * (0.6 + 0.4 * noise(q / (fp * 40.0) + 2.0));
	fill = clamp(max(fill * (0.3 + 0.45 * amount_fill), rubbed), 0.0, 1.0) * tooth * room;
	vec3 outv = mix(board, stick, fill);

	// The outlines, in white chalk, or in the colored stick for a kart, pressed harder in places.
	float k = 0.012;
	float sil = 0.0;
	float fold = 0.0;
	vec2 sub[2] = vec2[](vec2(0.25, 0.25), vec2(-0.25, -0.25));
	for (int i = 0; i < 2; i++) {
		vec2 st = steps(uv + sub[i] / VIEWPORT_SIZE, px * outline * 0.6, px, INV_PROJECTION_MATRIX);
		sil += smoothstep(k, k * 1.6, st.x);
		fold += smoothstep(0.002, 0.004, st.y) * (1.0 - smoothstep(k * 0.6, k, st.y));
	}
	sil *= 0.5;
	fold *= 0.5;
	vec2 h = px;
	vec3 gx = srgb(textureLod(screen_mip, uv + vec2(h.x, 0.0), 0.8).rgb) - srgb(textureLod(screen_mip, uv - vec2(h.x, 0.0), 0.8).rgb);
	vec3 gy = srgb(textureLod(screen_mip, uv + vec2(0.0, h.y), 0.8).rgb) - srgb(textureLod(screen_mip, uv - vec2(0.0, h.y), 0.8).rgb);
	float seam = smoothstep(0.3, 0.6, sqrt(dot(gx, gx) + dot(gy, gy)));
	float line = max(sil, max(fold * 0.6, seam * 0.5)) * room;
	float press = 0.6 + 0.4 * noise(q / (fp * 25.0));
	line *= press * mix(tooth, 1.0, 0.3);
	vec3 line_stick = mix(chalk, stick, colored * 0.8);
	outv = mix(outv, line_stick, clamp(line, 0.0, 1.0));
	// A colored thing keeps a soft wash of its stick under the strokes, so a kart reads at a glance.
	float kart = colored * standing * (1.0 - smoothstep(2.0, 3.0, world.y)) * room;
	outv = mix(outv, stick * mix(0.55, 0.85, tooth), kart * 0.55);
	vec3 result = from_screen(outv);
	// A bullet keeps its glow.
	result = mix(result, raw, smoothstep(1.0, 1.6, luma(raw)));
	ALBEDO = mix(raw, result, amount);
}
