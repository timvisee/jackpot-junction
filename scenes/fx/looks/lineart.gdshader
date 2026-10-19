shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Line art: ligne claire, as Hergé and Moebius drew. One clean, even black line round everything
// that stands against what is behind it, a finer one on every fold and wherever one flat color
// meets another, and inside the lines flat, clean color on a soft paper, every face a single tone.
// Its colors are as the screen shows them, after the tone map.
uniform vec3 paper = vec3(0.97, 0.95, 0.9);
uniform vec3 line_ink = vec3(0.035, 0.03, 0.04);
// The outline's width and the inner lines', in pixels at 1080 lines.
uniform float outline : hint_range(1.0, 4.0) = 3.0;
uniform float inline : hint_range(0.5, 2.0) = 1.3;
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform float fold_from = 0.002;

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

// A linear color as the screen shows it, with no tone mapping: a flat-lit thing's own color.
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

// The surface's facing at uv, from the room's depth.
vec3 normal_at(vec2 uv, vec2 px, mat4 inv_projection) {
	vec3 c = view_at(uv, inv_projection);
	vec3 r = view_at(uv + vec2(px.x, 0.0), inv_projection);
	vec3 u = view_at(uv + vec2(0.0, px.y), inv_projection);
	vec3 n = normalize(cross(r - c, u - c));
	return n.z < 0.0 ? -n : n;
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	vec3 raw = texture(screen_tex, uv).rgb;
	float dist = -view_at(uv, INV_PROJECTION_MATRIX).z;
	// Nothing past the room is lined: the dark beyond the stands is not an edge.
	float room = 1.0 - smoothstep(160.0, 220.0, dist);

	// The outline is drawn on what is behind, so the thing in front keeps all of its color, and a
	// finer line where the surface folds with no step, as along a block's top edge. Both judged four
	// times a pixel, a quarter pixel apart, so their edges are smooth.
	float k = 0.012;
	vec2 r = px * outline;
	vec2 pi = px * inline;
	float sil = 0.0;
	float fold = 0.0;
	vec2 sub[4] = vec2[](vec2(0.125, 0.375), vec2(-0.375, 0.125), vec2(-0.125, -0.375), vec2(0.375, -0.125));
	for (int i = 0; i < 4; i++) {
		vec2 st = steps(uv + sub[i] / VIEWPORT_SIZE, r, pi, INV_PROJECTION_MATRIX);
		sil += smoothstep(k, k * 1.6, st.x);
		fold += smoothstep(fold_from, fold_from * 2.0, st.y) * (1.0 - smoothstep(k * 0.6, k, st.y));
	}
	// Once more at half the width, so a thing thinner than the line is not stepped over.
	float thin = steps(uv, r * 0.5, pi, INV_PROJECTION_MATRIX).x;
	sil = max(sil * 0.25, smoothstep(k, k * 1.6, thin));
	fold *= 0.25;
	vec3 n = normal_at(uv, pi, INV_PROJECTION_MATRIX);

	// Where one flat color meets another: the color's change across a pixel, read between pixels so
	// the line is as soft at its sides as the color's own edge.
	vec2 h = px * 0.6;
	vec3 gx = srgb(textureLod(screen_mip, uv + vec2(h.x, 0.0), 0.6).rgb) - srgb(textureLod(screen_mip, uv - vec2(h.x, 0.0), 0.6).rgb);
	vec3 gy = srgb(textureLod(screen_mip, uv + vec2(0.0, h.y), 0.6).rgb) - srgb(textureLod(screen_mip, uv - vec2(0.0, h.y), 0.6).rgb);
	float meet = sqrt(dot(gx, gx) + dot(gy, gy));
	float seam = smoothstep(0.3, 0.55, meet);

	float line = max(sil, max(fold, seam) * 0.9) * room;

	// The color: each thing's own, as it was made, flat and clean and kept light, the darks lifted
	// so that black is left to the lines; on a soft paper tone.
	vec3 made = srgb(raw);
	float l = luma(made);
	float lifted = 1.0 - (1.0 - l) * 0.78;
	vec3 flat_c = mix(made * lifted / max(l, 0.02), 1.0 - (1.0 - made) * 0.78, 0.35);
	flat_c = clamp(mix(vec3(luma(flat_c)), flat_c, 1.12), 0.0, 1.0);
	flat_c *= mix(vec3(1.0), paper, 0.35);
	// Lightly shaded: a face turned from the light a single step darker, never a gradient.
	float facing = dot(n, normalize(vec3(-0.45, 0.75, 0.5)));
	flat_c *= mix(1.0, 0.85, smoothstep(0.15, 0.0, facing) * room);
	vec3 outv = mix(flat_c, line_ink, line);
	vec3 result = from_screen(outv);
	// A bullet keeps its glow.
	result = mix(result, raw, smoothstep(1.1, 1.8, luma(raw)));
	ALBEDO = mix(raw, result, amount);
}
