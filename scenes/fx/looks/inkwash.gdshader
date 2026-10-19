shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Ink wash: the frame painted in sumi ink on rice paper. The room in three or four tones of one
// gray ink, each wash bleeding out along the paper's fibers and dried darker at its edge; every
// outline laid in a dry brush that breaks up along its stroke. The karts and the bullets alone keep
// their color, as the one red seal on a scroll does, so the game reads at a glance.
// Its colors are as the screen shows them, after the tone map.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 paper = vec3(0.9, 0.85, 0.74);
uniform vec3 ink = vec3(0.03, 0.03, 0.035);
uniform float tones : hint_range(2.0, 6.0) = 4.0;

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

// Rice paper: a soft mottle with long fibers laid every way through it, high where they lie.
float fibers(vec2 p) {
	float f = 0.0;
	for (int i = 0; i < 3; i++) {
		float a = float(i) * 2.1 + 0.4;
		mat2 turn = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a)));
		vec2 q = turn * p;
		// Long along one axis and thin across it: a fiber.
		f += smoothstep(0.62, 0.9, noise(q * vec2(0.035, 0.45) + float(i) * 7.0));
	}
	return f;
}

// How much ink a pixel of lightness l takes, stepped into the few tones a painter mixes, the step
// between two tones softened by w and moved about by the paper's fibers.
float washes(float l, float w) {
	float t = (1.0 - l) * tones;
	float k = floor(t);
	return (k + smoothstep(0.5 - w, 0.5 + w, t - k)) / tones;
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	vec3 raw = texture(screen_tex, uv).rgb;
	vec2 p = uv / px;
	vec2 w = floor_at(uv, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	vec3 view = view_at(uv, INV_PROJECTION_MATRIX);
	vec3 world = (INV_VIEW_MATRIX * vec4(view, 1.0)).xyz;
	float fib = fibers(p);
	// The ink spreads out from where it was laid along the paper's fibers, so a wash is the room a
	// little softened, its edge feathered.
	vec2 spread = (vec2(noise(w * 0.8), noise(w * 0.8 + 17.0)) - 0.5) * px * 3.0;
	vec3 c = to_screen(textureLod(screen_mip, uv + spread, 1.4).rgb);
	// Judged against the frame as a whole, so a dark room is painted in the same few tones as a
	// light one: the table, which is most of the frame, in a pale wash; what is darker than it in
	// deeper ones; what is lighter left as the paper.
	float key = screen_luma(textureLod(screen_mip, vec2(0.5, 0.55), 8.0).rgb);
	float rel = luma(c) / max(key, 0.04);
	float jitter = fib * 0.06 + (noise(w * 0.5 + 3.0) - 0.5) * 0.12;
	float tone = smoothstep(1.35, 0.15, rel + jitter);
	float d = washes(1.0 - tone, 0.16);
	// Each wash dried darker where it ends: the ink runs out to its rim.
	float rel_soft = screen_luma(textureLod(screen_mip, uv + spread, 3.0).rgb) / max(key, 0.04);
	float rim = abs(washes(1.0 - smoothstep(1.35, 0.15, rel_soft + jitter), 0.25) - d);
	d = clamp(d + rim * 0.4, 0.0, 1.0);
	// Ink is never quite even: a wash is paler and darker in soft patches, and the fibers drink it.
	d *= 0.88 + 0.24 * noise(w * 0.25 + 9.0);
	d = clamp(d + fib * 0.05 * d, 0.0, 1.0);
	vec3 painted = mix(paper, ink, pow(d, 1.35) * 0.9);
	// The outlines in a dry brush: dark where the hairs held ink, broken where they ran dry, the
	// break running along the stroke.
	float e = line_at(uv, px * 1.2, INV_PROJECTION_MATRIX);
	vec2 gx = vec2(px.x * 1.5, 0.0);
	vec2 gy = vec2(0.0, px.y * 1.5);
	float lx = screen_luma(texture(screen_tex, uv + gx).rgb) - screen_luma(texture(screen_tex, uv - gx).rgb);
	float ly = screen_luma(texture(screen_tex, uv + gy).rgb) - screen_luma(texture(screen_tex, uv - gy).rgb);
	float line = max(e, smoothstep(0.18, 0.4, length(vec2(lx, ly))) * 0.6);
	vec2 across = normalize(vec2(lx, ly) + 1e-5);
	vec2 along = vec2(-across.y, across.x);
	// Streaks in the room's own place, so they stay on the line as the camera moves.
	float streak = noise(vec2(dot(w, along) * 0.6, dot(w, across) * 18.0));
	float pressure = noise(w * 0.35 + 5.0);
	float dry = smoothstep(0.3, 0.6, streak + pressure * 0.5 - 0.1);
	painted = mix(painted, ink, line * dry * 0.9);
	// The spot color: the karts and what they fire keep theirs, laid in a clean wash of it. A kart
	// is a strong color standing up off the table, big enough to be more than a speck of the crowd.
	float standing = smoothstep(0.08, 0.2, world.y) * (1.0 - smoothstep(2.2, 3.0, world.y));
	if (standing > 0.0) {
		vec3 sharp = to_screen(raw);
		float top = max(sharp.r, max(sharp.g, sharp.b));
		float sat = (top - min(sharp.r, min(sharp.g, sharp.b))) / max(top, 0.05);
		vec3 near = to_screen(textureLod(screen_mip, uv, 3.0).rgb);
		float near_top = max(near.r, max(near.g, near.b));
		float near_sat = (near_top - min(near.r, min(near.g, near.b))) / max(near_top, 0.05);
		float spot = smoothstep(0.45, 0.62, sat) * smoothstep(0.22, 0.4, near_sat)
				* smoothstep(0.25, 0.45, top) * standing;
		// Laid a little stronger than the room had it, as a seal's red is.
		vec3 colored = clamp(mix(vec3(luma(sharp)), sharp, 1.25), 0.0, 1.0) * paper;
		colored = mix(colored, ink, line * dry * 0.6);
		painted = mix(painted, colored, spot);
	}
	vec3 result = from_screen(painted);
	// A bullet keeps its glow.
	result = mix(result, raw, smoothstep(1.0, 1.6, luma(raw)));
	ALBEDO = mix(raw, result, amount);
}
