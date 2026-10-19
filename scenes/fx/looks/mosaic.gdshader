shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Mosaic: the frame laid in tesserae, small square tiles in rows a little out of line with each
// other as a hand sets them, each tile one color with the small differences of cut stone and glass,
// set in grout. Where the picture has an edge in it the tile is cut in four, so outlines and karts
// keep their shape in smaller pieces, the way a mosaicist goes finer round a figure.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
// How big a tile is, in pixels at 1080 lines.
uniform float tile : hint_range(4.0, 16.0) = 8.0;
// How wide the grout is, in pixels.
uniform float grout : hint_range(0.3, 3.0) = 1.1;

vec3 shown(vec3 c) {
	vec3 x = max(c, vec3(0.0)) * mat3(vec3(1.074942, 0.638244, 0.086814),
			vec3(0.1368, 1.635012, 0.028188), vec3(0.05112, 0.240894, 1.507986));
	vec3 t = (x * (x + 0.0245786) - 0.000090537) / (x * (0.983729 * x + 0.432951) + 0.238081);
	t = t * mat3(vec3(1.60475, -0.53108, -0.07367), vec3(-0.10208, 1.10813, -0.00605),
			vec3(-0.00327, -0.07276, 1.07602));
	t = clamp(t / 0.977011, 0.0, 1.0);
	return mix(t * 12.92, 1.055 * pow(t, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), t));
}

vec3 unshown(vec3 s) {
	s = clamp(s, 0.0, 1.0);
	vec3 l = mix(s / 12.92, pow((s + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), s));
	vec3 t = (l * 0.977011) * mat3(vec3(0.643038, 0.311187, 0.045775),
			vec3(0.059269, 0.931436, 0.009295), vec3(0.005962, 0.063929, 0.930118));
	t = clamp(t, vec3(-0.00038), vec3(0.999));
	vec3 a = t * 0.983729 - 1.0;
	vec3 b = t * 0.432951 - 0.0245786;
	vec3 k = t * 0.238081 + 0.000090537;
	vec3 x = (-b - sqrt(b * b - 4.0 * a * k)) / (2.0 * a);
	return max(x * mat3(vec3(0.980412, -0.375432, -0.049424), vec3(-0.081682, 0.644584, -0.007346),
			vec3(-0.020187, -0.090242, 0.665985)), vec3(0.0));
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

// How far inside a rounded box a point is, in pixels, from the box's middle: 0 at its edge.
float inside(vec2 at, vec2 size, float round_px) {
	vec2 q = abs(at) - (0.5 * size - round_px);
	float outside = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - round_px;
	return -outside;
}

// Where a row's tiles part: each a little along from where an even setting would put it.
float part(float k, float row) {
	return (hash12(vec2(k, row) + 0.71) - 0.5) * 0.36;
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	float scale = max(1.0, VIEWPORT_SIZE.y / 1080.0);
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;

	// The rows run in gentle waves, as a hand lays them across a floor, each set a little along
	// from the one before; in a row the tiles are not all of a width; and their edges are not
	// quite straight, as cut stone is not.
	vec2 p = uv / px;
	vec2 wob = vec2(vnoise(p * 0.35), vnoise(p * 0.35 + 19.3)) - 0.5;
	vec2 q = p + wob * 0.7;
	float wave = (vnoise(vec2(q.x * 0.017, 2.0)) - 0.5) * 6.0;
	float yq = q.y + wave;
	float row = floor(yq / tile);
	float shift = hash12(vec2(row, 3.1)) * tile;
	float xq = (q.x + shift) / tile;
	float k = floor(xq);
	if (xq < k + part(k, row)) {
		k -= 1.0;
	} else if (xq >= k + 1.0 + part(k + 1.0, row)) {
		k += 1.0;
	}
	float x0 = k + part(k, row);
	float x1 = k + 1.0 + part(k + 1.0, row);
	vec2 cell = vec2(k, row);
	vec2 local = vec2((xq - x0) / (x1 - x0), yq / tile - row);
	vec2 size = vec2((x1 - x0) * tile, tile);

	// The four quarters of the tile, read from the frame: if they differ, or one is on something
	// nearer than another, the tile is cut in four.
	float qlod = log2(tile * 0.5 * scale);
	vec3 quarter[4];
	float qd[4];
	vec3 mean = vec3(0.0);
	for (int n = 0; n < 4; n++) {
		vec2 off = vec2(float(n % 2), float(n / 2)) * 0.5 + 0.25;
		float ax = (x0 + (x1 - x0) * off.x) * tile - shift;
		float wave_at = (vnoise(vec2(ax * 0.017, 2.0)) - 0.5) * 6.0;
		vec2 at = vec2(ax, (row + off.y) * tile - wave_at) * px;
		quarter[n] = shown(textureLod(screen_mip, at, qlod).rgb);
		qd[n] = distance_at(at, INV_PROJECTION_MATRIX);
		mean += quarter[n] * 0.25;
	}
	float spread = 0.0;
	float dmin = min(min(qd[0], qd[1]), min(qd[2], qd[3]));
	float dmax = max(max(qd[0], qd[1]), max(qd[2], qd[3]));
	for (int n = 0; n < 4; n++) {
		vec3 d = quarter[n] - mean;
		spread = max(spread, dot(d, d));
	}
	bool split = spread > 0.006 || (dmax - dmin) > 0.25 + 0.02 * dmin;
	vec3 col = mean;
	vec2 id = cell;
	if (split) {
		vec2 half_cell = floor(local * 2.0);
		int n = int(half_cell.x) + int(half_cell.y) * 2;
		col = quarter[n];
		local = fract(local * 2.0);
		size *= 0.5;
		id = cell * 2.0 + half_cell + 0.5;
	}

	// Each tessera a stone or a bit of glass picked for its color, never quite the same as its
	// neighbor's: a little lighter or darker, a little warmer or cooler.
	vec2 h = hash22(id + vec2(13.0, 7.0));
	float l = luma(col);
	vec3 stone = mix(vec3(l), col, 1.15);
	stone *= 1.0 + (h.x - 0.5) * 0.2;
	stone += vec3(0.03, 0.0, -0.03) * (h.y - 0.5);
	stone = clamp(stone, 0.0, 1.0);

	// Cut by hand: each tile a little turned in its place and a little off its middle.
	vec2 h2 = hash22(id + vec2(3.3, 1.9));
	float turn = (h2.x - 0.5) * 0.24;
	vec2 fp = (local - 0.5) * size;
	fp = vec2(fp.x * cos(turn) - fp.y * sin(turn), fp.x * sin(turn) + fp.y * cos(turn));
	fp -= (h2 - 0.5) * 0.5;
	float min_side = min(size.x, size.y);

	// The tile's face: lit from the top left, its edges worn round, a grain in the stone.
	float round_px = min_side * 0.2;
	float in_px = inside(fp, size, round_px) - grout * 0.5;
	vec2 slope = fp / (0.5 * size);
	float edge = 1.0 - smoothstep(0.0, min_side * 0.25, in_px);
	float bevel = -(slope.x + slope.y) * 0.5 * edge;
	float grain_n = vnoise(fp * 0.5 + h * 9.0) - 0.5;
	vec3 face = stone * (1.0 + bevel * 0.28 + grain_n * 0.08);
	// A glint off the glass ones.
	face += vec3(0.07) * smoothstep(0.55, 0.95, 1.0 - length(slope + vec2(0.4)) * 0.9) * step(0.72, h.x);

	// The grout between: a warm gray cement, in the shade of what is round it.
	vec3 cement = mix(vec3(0.5, 0.47, 0.42), mean * 0.55, 0.45) * mix(0.3, 1.0, smoothstep(0.0, 0.5, luma(mean)));
	float aa = 0.6;
	float set = smoothstep(-aa, aa, in_px);
	vec3 outv = mix(cement, face, set);

	vec3 linear = unshown(outv);
	float near = 1.0 - smoothstep(180.0, 240.0, distance_at(uv, INV_PROJECTION_MATRIX));
	linear = mix(c, linear, max(near, 0.6));
	float hot = smoothstep(1.6, 2.6, max(c.r, max(c.g, c.b)));
	linear = mix(linear, max(linear, c), hot);
	ALBEDO = mix(c, linear, amount);
}
