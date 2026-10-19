shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Blueprint: the frame as an engineer's drawing, printed white on cyanotype blue. Every outline
// and fold drawn in an even white line, finer ones where one color meets another, over a faint
// drafting grid; the paper's blue a little uneven, as a print's is. The karts are drawn in their
// own colored pencil and the bullets glow, so the race reads as well as the drawing does.
// Its colors are as the screen shows them, after the tone map.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 blue = vec3(0.07, 0.25, 0.52);
uniform vec3 chalk_white = vec3(0.9, 0.95, 1.0);
// The outline's width and the inner lines', in pixels at 1080 lines.
uniform float outline : hint_range(0.5, 4.0) = 1.8;
uniform float inline : hint_range(0.5, 2.0) = 1.0;
// The drafting grid's squares, in pixels at 1080 lines.
uniform float grid : hint_range(8.0, 80.0) = 24.0;

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
// nearness, and how sharply the surface under it folds f away: the one positive, the other either
// way. Read along four directions, so an edge at any angle is found.
vec2 steps(vec2 uv, vec2 r, vec2 f, mat4 inv_projection) {
	float q = near_at(uv, inv_projection);
	float behind = 0.0;
	float fold = 0.0;
	vec2 d[4] = vec2[](vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(0.7071, 0.7071), vec2(0.7071, -0.7071));
	for (int i = 0; i < 4; i++) {
		float a = near_at(uv + d[i] * r, inv_projection);
		float b = near_at(uv - d[i] * r, inv_projection);
		behind = max(behind, (a + b - 2.0 * q) / q);
		float fa = near_at(uv + d[i] * f, inv_projection);
		float fb = near_at(uv - d[i] * f, inv_projection);
		fold = max(fold, abs(fa + fb - 2.0 * q) / q);
	}
	return vec2(behind, fold);
}

// A line of a grid of squares s pixels across at p, w pixels wide, faded out where it would fall
// finer than a pixel.
float grid_line(vec2 p, float s, float w) {
	vec2 g = abs(fract(p / s + 0.5) - 0.5) * s;
	float d = min(g.x, g.y);
	return 1.0 - smoothstep(w * 0.5 - 0.5, w * 0.5 + 0.5, d);
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	vec3 raw = texture(screen_tex, uv).rgb;
	vec2 p = uv / px;
	vec3 view = view_at(uv, INV_PROJECTION_MATRIX);
	vec3 world = (INV_VIEW_MATRIX * vec4(view, 1.0)).xyz;
	float room = 1.0 - smoothstep(160.0, 220.0, -view.z);

	// The paper: cyanotype blue, deeper and paler in broad soft patches and a fine tooth.
	float mottle = noise(p / 260.0) * 0.6 + noise(p / 70.0 + 3.0) * 0.3 + noise(p / 6.0) * 0.1;
	vec3 paper = blue * (0.86 + 0.28 * mottle);
	// Toward the edges the print is a shade deeper, as an exposure is.
	vec2 mid = abs(uv - 0.5) * 2.0;
	paper *= 1.0 - 0.18 * smoothstep(0.5, 1.4, length(mid * vec2(1.0, 0.8)));
	// The drafting grid, faint, a heavier line every fifth.
	float g = max(grid_line(p, grid, 1.0) * 0.08, grid_line(p, grid * 5.0, 1.4) * 0.14);
	vec3 outv = mix(paper, chalk_white, g);

	// What stands off the table is hatched lightly in white, the way a section is, and its faces
	// turned from the light a little deeper, so its form reads.
	vec3 made = srgb(raw);
	float l = luma(made);
	float standing = smoothstep(0.05, 0.25, world.y) * room;
	vec3 r = view_at(uv + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	vec3 u = view_at(uv + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	vec3 n = normalize(cross(r - view, u - view));
	n = n.z < 0.0 ? -n : n;
	float facing = dot(n, normalize(vec3(-0.45, 0.75, 0.5)));
	float tint = 0.1 + 0.08 * smoothstep(-0.2, 0.6, facing) + 0.08 * l;
	outv = mix(outv, chalk_white, standing * tint);
	// A light thing drawn on the table, a pad or a marking, shows as a pale wash of white.
	outv = mix(outv, chalk_white, (1.0 - standing) * smoothstep(0.45, 0.9, l) * 0.22 * room);

	// The lines: white outlines judged four times a pixel, a quarter pixel apart, so their edges
	// are smooth; finer folds; and the faintest where one color meets another.
	float k = 0.012;
	vec2 ro = px * outline;
	vec2 ri = px * inline;
	float sil = 0.0;
	float fold = 0.0;
	vec2 sub[4] = vec2[](vec2(0.125, 0.375), vec2(-0.375, 0.125), vec2(-0.125, -0.375), vec2(0.375, -0.125));
	for (int i = 0; i < 4; i++) {
		vec2 st = steps(uv + sub[i] / VIEWPORT_SIZE, ro, ri, INV_PROJECTION_MATRIX);
		sil += smoothstep(k, k * 1.6, st.x);
		fold += smoothstep(0.002, 0.004, st.y) * (1.0 - smoothstep(k * 0.6, k, st.y));
	}
	sil *= 0.25;
	fold *= 0.25;
	vec2 h = px * 0.6;
	vec3 gx = srgb(textureLod(screen_mip, uv + vec2(h.x, 0.0), 0.6).rgb) - srgb(textureLod(screen_mip, uv - vec2(h.x, 0.0), 0.6).rgb);
	vec3 gy = srgb(textureLod(screen_mip, uv + vec2(0.0, h.y), 0.6).rgb) - srgb(textureLod(screen_mip, uv - vec2(0.0, h.y), 0.6).rgb);
	float seam = smoothstep(0.25, 0.5, sqrt(dot(gx, gx) + dot(gy, gy)));
	float line = max(sil, max(fold * 0.75, seam * 0.55)) * room;
	// The pen's ink a touch uneven along its length.
	line *= 0.85 + 0.15 * noise(p / 9.0);

	// The karts in their own color: a strong color standing off the table, filled with a wash of
	// it and outlined in it.
	float top = max(made.r, max(made.g, made.b));
	float sat = (top - min(made.r, min(made.g, made.b))) / max(top, 0.05);
	vec3 near = srgb(textureLod(screen_mip, uv, 2.5).rgb);
	float near_top = max(near.r, max(near.g, near.b));
	float near_sat = (near_top - min(near.r, min(near.g, near.b))) / max(near_top, 0.05);
	float kart = smoothstep(0.5, 0.7, sat) * smoothstep(0.3, 0.5, near_sat) * smoothstep(0.12, 0.3, top)
			* smoothstep(0.1, 0.25, world.y) * (1.0 - smoothstep(2.0, 3.0, world.y)) * room;
	vec3 pen = clamp(made / max(top, 0.05) * 1.05, 0.0, 1.0);
	pen = mix(pen, vec3(1.0), 0.15);
	outv = mix(outv, mix(outv, pen, 0.85), kart);
	outv = mix(outv, mix(chalk_white, pen, kart), line);
	vec3 result = from_screen(outv);
	// A bullet keeps its glow.
	result = mix(result, raw, smoothstep(1.0, 1.6, luma(raw)));
	ALBEDO = mix(raw, result, amount);
}
