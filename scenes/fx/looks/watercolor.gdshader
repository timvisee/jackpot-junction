shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Watercolor: the frame painted in transparent washes on cold-press paper. Each shape is a wash
// that dried with its pigment pooled in a dark rim at its edge, settled into the valleys of the
// paper's tooth and spread a little past where it was laid; the lightest parts are the paper itself.
// Its colors are as the screen shows them, after the tone map.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 paper = vec3(0.95, 0.93, 0.86);
uniform vec3 glaze = vec3(0.45, 0.5, 0.82);
uniform float pooling : hint_range(0.0, 2.0) = 1.0;
uniform float granulation : hint_range(0.0, 1.0) = 0.6;

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

// The paper's tooth, high where it stands up: cold-press, rounded bumps a few pixels across.
float tooth(vec2 p) {
	mat2 turn = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	return noise(p / 4.0) * 0.6 + noise(turn * p / 2.1 + 17.0) * 0.4;
}

// Pigment laid at density d over a color: thinner than 1 lightens it, thicker darkens it, the way
// a transparent wash does (Bousseau et al.).
vec3 density(vec3 c, float d) {
	return clamp(c - (c - c * c) * (d - 1.0), 0.0, 1.0);
}

// The room as the screen shows it, a dark room brought up by g, its darks most: a watercolor is
// painted light whatever the light was.
vec3 screen_at(vec2 uv, float lod, float g) {
	vec3 c = textureLod(screen_mip, uv, lod).rgb;
	return to_screen(c * g / (1.0 + c * (g - 1.0)));
}

// The same, cheaply: a square root of the light, near enough the screen's own curve to tell where
// the color changes.
vec3 root_at(vec2 uv, float lod, float g) {
	vec3 c = textureLod(screen_mip, uv, lod).rgb;
	return sqrt(c * g / (1.0 + c * (g - 1.0)));
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	vec3 raw = texture(screen_tex, uv).rgb;
	vec2 p = uv / px;
	vec2 w = floor_at(uv, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	// The wash's edge wanders a little from the shape's.
	vec2 wob = vec2(noise(w * 0.6), noise(w * 0.6 + 31.0)) - 0.5;
	vec2 at = uv + wob * px * 4.0;
	float key = luma(textureLod(screen_mip, vec2(0.5), 10.0).rgb);
	float g = clamp(0.2 / max(key, 0.01), 1.0, 2.5);
	vec3 sharp = screen_at(at, 0.0, g);
	vec3 soft = screen_at(at, 1.4, g);
	vec3 c = mix(sharp, soft, 0.5);
	// Pigment pools where the color changes and at every outline.
	// The color's change, read in a square root of the light, near enough the screen's own curve.
	vec3 soft_root = root_at(at, 1.4, g);
	vec3 gx = root_at(at + vec2(px.x * 2.0, 0.0), 1.4, g) - soft_root;
	vec3 gy = root_at(at + vec2(0.0, px.y * 2.0), 1.4, g) - soft_root;
	float grad = length(gx) + length(gy);
	float outline = line_at(at, px, INV_PROJECTION_MATRIX);
	float pool = max(smoothstep(0.08, 0.5, grad), outline * 0.6);
	// The wash is a filter over the paper: lighter than the room, its hue kept.
	float l = luma(c);
	float chroma = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
	vec3 t = max(mix(vec3(l), c, 1.3), 0.0);
	t = 1.0 - (1.0 - t) * 0.64;
	// The lightest parts are left as paper, where they have little color to give.
	t = mix(t, vec3(1.0), smoothstep(0.68, 0.85, l) * (1.0 - smoothstep(0.12, 0.35, chroma)));
	// Shade glazed over in a cool wash, as a painter lays a shadow.
	float s = shade_of(raw, uv, screen_mip, INV_PROJECTION_MATRIX, px);
	t *= mix(vec3(1.0), glaze, s * 0.4);
	// The pigments of a wash part a little as it dries, warmer here and cooler there.
	float part = noise(w * 0.15 + 21.0) - 0.5;
	t *= 1.0 + part * vec3(0.12, 0.02, -0.12);
	// How thick the pigment lies: uneven over the wash, pooled at its edge, in the paper's valleys.
	float h = tooth(p);
	float d = 1.0 + (noise(w * 0.3 + 3.0) - 0.5) * 0.9;
	d += pool * pooling * 0.6;
	// Where water ran back into a drying wash it pushed the pigment out ahead of it: a paler
	// bloom with a hard, dark tide mark round it.
	float run = noise(w * 0.11 + 13.0) + (h - 0.5) * 0.02;
	float into = (run - 0.64) / max(fwidth(run), 1e-4);
	float bloom = smoothstep(-0.7, 0.7, into);
	d += smoothstep(-5.0, 0.0, into) * (1.0 - bloom) * 0.35 - bloom * 0.22;
	d += (0.5 - h) * granulation * (0.4 + (1.0 - luma(t)) * 2.0);
	vec3 painted = density(t, d);
	// Toward the edge of the sheet the wash thins out to bare paper, raggedly.
	vec2 edge = min(p, 1.0 / px - p);
	float border = min(edge.x, edge.y);
	if (border < 32.0) {
		border += (noise(p / 24.0) - 0.5) * 26.0;
		painted = mix(vec3(1.0), painted, smoothstep(0.0, 16.0, border));
	}
	// The paper under it all, lit from the top left across its tooth.
	float lit = (dFdx(h) - dFdy(h)) * 0.8;
	vec3 outv = painted * paper * (1.0 + lit * 0.16);
	vec3 result = from_screen(outv);
	// A bullet keeps its glow.
	result = mix(result, raw, smoothstep(1.1, 1.8, luma(raw)));
	ALBEDO = mix(raw, result, amount);
}
