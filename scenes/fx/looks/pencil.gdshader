shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Pencil: the frame drawn in colored pencil and graphite on cream paper. A light layer of each
// thing's color, hatched over in its own pencil the darker it is, one direction, then two, then
// graphite across both; the outlines drawn in graphite; the paper's tooth showing through it all.
// Its colors are as the screen shows them, after the tone map.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 paper = vec3(0.92, 0.87, 0.74);
uniform vec3 graphite = vec3(0.06, 0.06, 0.07);
// How far apart the hatched lines are, in pixels at 1080 lines.
uniform float spacing : hint_range(3.0, 12.0) = 6.5;

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

// The paper's tooth, high where it stands up: fine, a pixel or two across.
float tooth(vec2 p) {
	return noise(p / 1.6) * 0.5 + noise(p / 3.5 + 11.0) * 0.3 + noise(p / 9.0 + 4.0) * 0.2;
}

// One layer of hatching: lines across dir every gap meters of the room, broken into strokes of a
// few dozen pixels that taper at their ends, each pressed a little harder or softer. fp is a
// pixel's size in meters there, so the lines keep their width in pixels.
float strokes(vec2 q, vec2 dir, float gap, float fp, float width, float seed) {
	float s = dot(q, dir) / gap;
	float k = round(s);
	float off = abs(s - k) * gap / fp;
	float along = dot(q, vec2(-dir.y, dir.x)) / (gap * 11.0) + hash(vec2(k, seed)) * 5.0;
	float j = floor(along);
	float u = fract(along);
	float press = hash(vec2(k * 1.3 + j, seed + j * 0.7));
	float end = 0.8 + 0.17 * hash(vec2(j, k + seed));
	float taper = smoothstep(0.0, 0.18, u) * (1.0 - smoothstep(end - 0.12, end, u));
	float w = width * (0.7 + 0.6 * press) * taper;
	return (1.0 - smoothstep(w * 0.5 - 0.5, w * 0.5 + 0.6, off)) * (0.7 + 0.3 * press);
}

// A layer of hatching that keeps its spacing on the screen at any distance: the next sparser set
// of lines fades in as the nearer one grows too dense, every other line of it one of the first's.
float hatch(vec2 q, vec2 dir, float fp, float width, float seed) {
	float level = log2(spacing * fp / 0.01);
	float base = floor(level);
	float gap = 0.01 * exp2(base);
	float fine = strokes(q, dir, gap, fp, width, seed);
	float coarse = strokes(q, dir, gap * 2.0, fp, width, seed);
	return mix(fine, coarse, level - base);
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	vec3 raw = texture(screen_tex, uv).rgb;
	vec2 p = uv / px;
	vec3 v = view_at(uv, INV_PROJECTION_MATRIX);
	// Where on the room the pixel is, in the camera's axes, so the hatching stays on the things.
	vec2 q = v.xy - VIEW_MATRIX[3].xy;
	// A 1080-line pixel's size in meters at that distance.
	float fp = -v.z * 2.0 / (abs(PROJECTION_MATRIX[1][1]) * 1080.0);
	vec3 c = to_screen(textureLod(screen_mip, uv, 0.7).rgb);
	float l = luma(c);
	float top = max(c.r, max(c.g, c.b));
	float sat = (top - min(c.r, min(c.g, c.b))) / max(top, 0.06);
	// The pencil each thing is colored in: its own hue at a pencil's strength however dark the
	// room has it, a deep green felt in a dark room drawn in green, only harder.
	float colored = smoothstep(0.15, 0.45, sat) * smoothstep(0.03, 0.1, top - min(c.r, min(c.g, c.b)));
	vec3 hue = c / max(top, 0.06);
	float deep = mix(0.5, 0.85, smoothstep(0.08, 0.5, top));
	vec3 pencil = mix(vec3(0.62), mix(vec3(1.0), hue, 0.85) * deep, colored);
	// How dark it is to be drawn: a drawing is lighter than the room, its darks hatched, not filled.
	float tone = smoothstep(0.15, 1.0, 1.0 - l) * 0.88;
	// Laid toward the edge of the sheet with a lighter hand, the way a sketch trails off.
	vec2 mid = abs(uv - 0.5) * 2.0;
	tone *= 1.0 - 0.3 * smoothstep(0.55, 1.0, max(mid.x * 0.8, mid.y));
	float h = tooth(p);
	float grain = smoothstep(0.2, 0.7, h + 0.15);
	// The color laid first on the tooth's peaks, harder the more there is of it; a strong color,
	// the karts' among them, pressed in until little paper shows.
	float height = (INV_VIEW_MATRIX * vec4(v, 1.0)).y;
	float standing = smoothstep(0.08, 0.2, height) * (1.0 - smoothstep(2.0, 3.0, height));
	float strong = smoothstep(0.5, 0.75, sat) * smoothstep(0.2, 0.45, top) * standing;
	float laid = colored * (0.25 + 0.35 * smoothstep(0.1, 0.8, 1.0 - l) + 0.4 * strong);
	vec3 outv = mix(paper, paper * pencil, min(laid, 1.0) * mix(grain, 1.0, 0.5 * strong));
	// A strong color is drawn in its color more than in shade.
	tone *= 1.0 - 0.4 * strong;
	// Hatched over it in its own pencil, then across in a darker one, then in graphite.
	float a = hatch(q, normalize(vec2(0.87, 0.5)), fp, 0.6 + 1.6 * smoothstep(0.25, 0.6, tone), 1.0)
			* smoothstep(0.2, 0.35, tone);
	float b = hatch(q, normalize(vec2(-0.6, 0.8)), fp, 0.6 + 1.4 * smoothstep(0.55, 0.85, tone), 2.0)
			* smoothstep(0.48, 0.62, tone);
	float g = hatch(q, normalize(vec2(0.15, -0.99)), fp, 0.6 + 1.2 * smoothstep(0.75, 1.0, tone), 3.0)
			* smoothstep(0.72, 0.86, tone);
	outv *= mix(vec3(1.0), pencil * 0.8, a * grain * 0.8);
	outv *= mix(vec3(1.0), mix(pencil * 0.55, graphite * 2.0, 0.4), b * grain * 0.75);
	outv = mix(outv, graphite, g * grain * 0.55);
	// Graphite outlines, pressed unevenly along their length.
	float e = line_at(uv, px, INV_PROJECTION_MATRIX);
	vec2 dx = vec2(px.x, 0.0);
	vec2 dy = vec2(0.0, px.y);
	float gl = abs(screen_luma(texture(screen_tex, uv + dx).rgb) - screen_luma(texture(screen_tex, uv - dx).rgb))
			+ abs(screen_luma(texture(screen_tex, uv + dy).rgb) - screen_luma(texture(screen_tex, uv - dy).rgb));
	float line = max(e, smoothstep(0.12, 0.35, gl) * 0.7);
	line *= 0.6 + 0.4 * noise(p / 14.0);
	outv = mix(outv, graphite, line * smoothstep(0.1, 0.6, h + 0.3) * 0.85);
	vec3 result = from_screen(outv);
	// A bullet keeps its glow.
	result = mix(result, raw, smoothstep(1.1, 1.8, luma(raw)));
	ALBEDO = mix(raw, result, amount);
}
