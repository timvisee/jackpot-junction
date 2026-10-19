shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Crayon: the frame colored in wax crayon on drawing paper, as a child does it. Each thing
// scribbled back and forth in its own bright crayon, pressed harder where it is darker, the wax
// catching only the tops of the paper's tooth so white flecks show all through it, and running a
// little past the lines, which are gone over again in a darker crayon.
// Its colors are as the screen shows them, after the tone map.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 paper = vec3(0.97, 0.95, 0.9);
// How far the scribble runs past the lines, in pixels at 1080 lines.
uniform float overrun : hint_range(0.0, 8.0) = 3.5;

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

// The paper's tooth, high where it stands up: a fine, even drawing paper.
float tooth(vec2 p) {
	return noise(p / 1.4) * 0.45 + noise(p / 3.2 + 9.0) * 0.35 + noise(p / 8.0 + 2.0) * 0.2;
}

// A scribble: the crayon dragged back and forth across dir in strokes a few pixels apart, each
// pressed a little differently and wavering. q is the place in the room and fp a pixel's size
// there, so the scribble stays on the thing it colors and keeps its size on the screen.
float scribble_at(vec2 q, vec2 dir, float gap, float seed) {
	vec2 side = vec2(-dir.y, dir.x);
	float wave = (noise(vec2(dot(q, side) / (gap * 8.0), seed)) - 0.5) * 1.6;
	float s = dot(q, dir) / gap + wave;
	float k = floor(s);
	float press = hash(vec2(k, seed));
	float across = abs(fract(s) - 0.5) * 2.0;
	return (1.0 - smoothstep(0.55, 1.0, across)) * (0.6 + 0.4 * press);
}

// The scribble at a spacing of about five pixels whatever the distance: stepped in octaves of the
// room's size, the next fading in as the one before grows too dense, so it never swims.
float scribble(vec2 q, vec2 dir, float fp, float seed) {
	float level = log2(5.0 * fp / 0.01);
	float base = floor(level);
	float gap = 0.01 * exp2(base);
	return mix(scribble_at(q, dir, gap, seed), scribble_at(q, dir, gap * 2.0, seed + 0.5), level - base);
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	vec3 raw = texture(screen_tex, uv).rgb;
	vec2 p = uv / px;
	vec3 view = view_at(uv, INV_PROJECTION_MATRIX);
	float room = 1.0 - smoothstep(160.0, 220.0, -view.z);
	vec2 q = view.xy - VIEW_MATRIX[3].xy;
	float fp = -view.z * 2.0 / (abs(PROJECTION_MATRIX[1][1]) * 1080.0);

	// The color runs past the lines: read from a little way off, the way wobbling in the room, and
	// spread so a bright thing's color reaches over its edge.
	vec2 wob = vec2(noise(q / (fp * 30.0)), noise(q / (fp * 30.0) + 17.0)) - 0.5;
	vec2 at = uv + wob * px * overrun * 2.0;
	// A dark room drawn as brightly as a light one: a child does not color in the dark.
	float key = luma(textureLod(screen_mip, vec2(0.5), 10.0).rgb);
	float gain = clamp(0.2 / max(key, 0.01), 1.0, 3.5);
	vec3 lin = textureLod(screen_mip, at, 1.0).rgb;
	vec3 c = srgb(lin * gain / (1.0 + lin * (gain - 1.0)));
	// Each thing's crayon: its color, brighter and cleaner, as a crayon box has it; a dark thing
	// in a dark crayon, brown or navy or black, never a bright one.
	float l = luma(c);
	float top = max(c.r, max(c.g, c.b));
	float sat = (top - min(c.r, min(c.g, c.b))) / max(top, 0.04);
	vec3 crayon = clamp(mix(vec3(l), c, 1.3), 0.0, 1.0);
	crayon = pow(crayon, vec3(0.72));
	// How hard it is pressed: harder where it is darker, softer on what is light.
	float press = mix(0.4, 0.85, smoothstep(0.85, 0.15, l));
	// Scribbled one way, and on the darker parts once more across it.
	float a = scribble(q, normalize(vec2(0.82, 0.57)), fp, 1.0);
	float b = 0.0;
	if (l < 0.5) {
		b = scribble(q, normalize(vec2(-0.4, 0.92)), fp, 2.0) * smoothstep(0.5, 0.25, l);
	}
	float strokes = max(a, b);
	// The wax only takes on the tooth's high points: lightly pressed, only the highest.
	float h = tooth(p);
	float cover = smoothstep(1.05 - press * 0.9, 1.2 - press * 0.7, h * 0.85 + strokes * 0.5);
	// A white thing is left as the paper, lightly gone over.
	float white = smoothstep(0.8, 0.95, l) * (1.0 - smoothstep(0.1, 0.25, sat));
	cover *= 1.0 - white * 0.75;
	// Wax lies thicker in the darks, a little glossy, and darker still where two layers overlap.
	vec3 waxed = crayon * (1.0 - 0.18 * b);
	vec3 outv = mix(paper, waxed, cover * room + (1.0 - room) * 0.9);

	// The lines gone over in a darker crayon of the color beside them, wobbling.
	float e = line_at(uv + wob * px * 1.5, px * 1.4, INV_PROJECTION_MATRIX);
	// The color's change, read in a square root of the light, near enough the screen's own curve.
	vec3 gx = sqrt(textureLod(screen_mip, uv + vec2(px.x, 0.0), 0.8).rgb) - sqrt(textureLod(screen_mip, uv - vec2(px.x, 0.0), 0.8).rgb);
	vec3 gy = sqrt(textureLod(screen_mip, uv + vec2(0.0, px.y), 0.8).rgb) - sqrt(textureLod(screen_mip, uv - vec2(0.0, px.y), 0.8).rgb);
	float seam = smoothstep(0.35, 0.65, sqrt(dot(gx, gx) + dot(gy, gy)));
	float line = max(e, seam * 0.5) * room;
	float line_cover = smoothstep(0.25, 0.55, h + 0.25);
	vec3 dark = mix(crayon * 0.35, vec3(0.12, 0.1, 0.12), 0.4);
	outv = mix(outv, dark, line * line_cover * 0.9);
	vec3 result = from_screen(outv);
	// A bullet keeps its glow.
	result = mix(result, raw, smoothstep(1.0, 1.6, luma(raw)));
	ALBEDO = mix(raw, result, amount);
}
