shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Oil paint: the frame painted in strokes that follow what they paint. An anisotropic Kuwahara
// filter reads which way the picture runs at each pixel and keeps the calmest part of a brush's
// ellipse laid along it, which pulls the colors into strokes along the edges; the paint stands up
// off the canvas in dabs that stay on what they were painted on, lit from the top left; and the
// canvas's weave shows through where the paint lies thin.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
// The brush's reach, in pixels at 1080 lines.
uniform float brush : hint_range(2.0, 8.0) = 5.0;
// How far the paint stands up off the canvas.
uniform float impasto : hint_range(0.0, 1.0) = 0.55;
// How much of the canvas's weave shows.
uniform float canvas : hint_range(0.0, 0.2) = 0.06;

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

// The paint at one size of brush: dabs laid on a grid of cells in the world, each a rounded
// ridge of paint along the stroke's way with its bristles' grooves down its length, standing up
// where one is laid over another. Gives how high the paint stands, which dab is on top and the
// way from here to its middle.
vec4 dabs(vec2 q, vec2 along, float sure) {
	// The four cells whose middles are nearest; a dab reaches little past its own cell.
	vec2 base = floor(q - 0.5);
	float top = 0.0;
	float which = 0.5;
	vec2 to = vec2(0.0);
	vec2 across = vec2(-along.y, along.x);
	for (int j = 0; j <= 1; j++) {
		for (int i = 0; i <= 1; i++) {
			vec2 at = base + vec2(float(i), float(j));
			vec2 h = hash22(at);
			vec2 center = at + 0.5 + (h - 0.5) * 0.5;
			// Each dab a little turned from the stroke's way, as a hand lays them, and where the
			// picture gives no way, laid every which way.
			vec2 t = normalize(along + across * ((h.y - 0.5) * mix(3.0, 0.5, sure)));
			vec2 d = q - center;
			vec2 e = vec2(dot(d, t), dot(d, vec2(-t.y, t.x))) / vec2(0.7 + 0.2 * h.x, 0.34 + 0.1 * h.y);
			float r2 = dot(e, e);
			// Rounded across, fuller toward the end the brush came down at, grooved down its length.
			float dome = sqrt(max(1.0 - r2, 0.0)) * (1.0 - 0.3 * smoothstep(-1.0, 1.0, e.x));
			float bristles = 0.8 + 0.2 * sin(e.y * 9.0 + h.x * 6.2832);
			float height = dome * bristles * (0.7 + 0.3 * h.y) + (h.x - 0.5) * 0.15 * step(r2, 1.0);
			if (height > top) {
				top = height;
				which = h.x;
				to = center - q;
			}
		}
	}
	return vec4(top, which, to);
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;
	float scale = max(1.0, VIEWPORT_SIZE.y / 1080.0);

	// Which way the picture runs here: the structure tensor of the colors, read off a softened
	// copy so it follows shapes rather than grain.
	float lod = 1.0 + log2(scale);
	vec2 o = px * 2.0;
	vec3 tl = sqrt(clamp(textureLod(screen_mip, uv + vec2(-o.x, -o.y), lod).rgb, 0.0, 4.0));
	vec3 tr = sqrt(clamp(textureLod(screen_mip, uv + vec2(o.x, -o.y), lod).rgb, 0.0, 4.0));
	vec3 bl = sqrt(clamp(textureLod(screen_mip, uv + vec2(-o.x, o.y), lod).rgb, 0.0, 4.0));
	vec3 br = sqrt(clamp(textureLod(screen_mip, uv + vec2(o.x, o.y), lod).rgb, 0.0, 4.0));
	vec3 gx = (tr + br) - (tl + bl);
	vec3 gy = (bl + br) - (tl + tr);

	// Where the picture is calm the strokes follow a slow drift of their own, laid in the world so
	// it stays put under the camera.
	vec3 view = view_at(uv, INV_PROJECTION_MATRIX);
	float dist = -view.z;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec2 plane = view.xy + vec2(dot(cam, INV_VIEW_MATRIX[0].xyz), dot(cam, INV_VIEW_MATRIX[1].xyz));
	float drift = vnoise(plane * 0.18) * 6.2832 * 1.5;
	vec2 flow = vec2(cos(drift), sin(drift));

	float te = dot(gx, gx) + 0.004 * flow.y * flow.y;
	float tf = dot(gx, gy) - 0.004 * flow.x * flow.y;
	float tg = dot(gy, gy) + 0.004 * flow.x * flow.x;
	float root = sqrt((te - tg) * (te - tg) + 4.0 * tf * tf);
	float l1 = 0.5 * (te + tg + root);
	float l2 = 0.5 * (te + tg - root);
	vec2 t = vec2(l1 - te, -tf);
	t = dot(t, t) > 1e-10 ? normalize(t) : vec2(1.0, 0.0);
	// How sure the way is comes from the picture alone: where it is calm the brush stays round.
	float ie = dot(gx, gx);
	float ig = dot(gy, gy);
	float iff = dot(gx, gy);
	float iroot = sqrt((ie - ig) * (ie - ig) + 4.0 * iff * iff);
	float aniso = iroot / (ie + ig + 0.002);

	// The brush: an ellipse along the stroke, longer the surer the way is.
	float a = brush * (1.0 + aniso);
	float b = brush / (1.0 + aniso);
	vec2 tu = t * a * px;
	vec2 nu = vec2(-t.y, t.x) * b * px;

	// Eight sectors round the ellipse, each taking the sample on its own ray, half of those on its
	// neighbors' and the middle, and weighed by how calm they are: the calmest win, so the colors
	// pull together on either side of an edge rather than across it.
	float klod = 0.9 + log2(scale);
	vec3 mid = sqrt(clamp(textureLod(screen_mip, uv, klod).rgb, 0.0, 4.0));
	vec3 ring[8];
	for (int k = 0; k < 8; k++) {
		float ang = float(k) * 0.785398;
		vec2 off = tu * cos(ang) + nu * sin(ang);
		ring[k] = sqrt(clamp(textureLod(screen_mip, uv + off, klod).rgb, 0.0, 4.0));
	}
	vec3 sum = vec3(0.0);
	float weights = 0.0;
	for (int k = 0; k < 8; k++) {
		vec3 rp = ring[(k + 7) % 8];
		vec3 rn = ring[(k + 1) % 8];
		vec3 m = (mid + ring[k] * 1.5 + 0.5 * (rp + rn)) / 3.5;
		vec3 sq = (mid * mid + ring[k] * ring[k] * 1.5 + 0.5 * (rp * rp + rn * rn)) / 3.5;
		vec3 v = abs(sq - m * m);
		float sigma = (v.r + v.g + v.b) * 60.0;
		float w = 1.0 / (1.0 + sigma * sigma * sigma * sigma);
		sum += m * w;
		weights += w;
	}
	vec3 paint = sum / max(weights, 1e-6);
	paint = paint * paint;

	// Oil's own richness: a touch more color and depth than the room had.
	float pl = luma(paint);
	paint = max(mix(vec3(pl), paint, 1.15), vec3(0.0));

	// The paint standing up off the canvas, in two sizes of brush faded between as the camera comes
	// and goes, so a dab keeps its size on the screen and stays on what it was laid on.
	vec2 along = t;
	along.y = -along.y;
	float px_per_m = abs(PROJECTION_MATRIX[1][1]) * 0.5 * VIEWPORT_SIZE.y / max(dist, 0.01) / scale;
	float octave = log2(max(px_per_m, 1e-3) / 3.0);
	float o0 = floor(octave);
	float fade = fract(octave);
	float sure = smoothstep(0.2, 0.7, aniso);
	vec4 d0 = dabs(plane * (exp2(o0) * 3.0 / 11.0), along, sure);
	vec4 d1 = dabs(plane * (exp2(o0 + 1.0) * 3.0 / 11.0), along, sure);
	float near = 1.0 - smoothstep(150.0, 220.0, dist);
	float h = mix(d0.x, d1.x, fade);
	// Lit from the top left: a slope rising to the right or down faces the lamp.
	float relief = (dFdx(h) + dFdy(h)) * impasto * 1.6 * near;
	relief = clamp(relief, -0.35, 0.35);

	// Each dab is laid in one color, the paint's at its middle, so the strokes show as strokes;
	// not across an outline, where the dab's middle is on something else and the filter's edge
	// is kept.
	vec3 dab_paint = vec3(0.0);
	float dab_weight = 0.0;
	for (int i = 0; i < 2; i++) {
		vec4 d = i == 0 ? d0 : d1;
		float cell = exp2(o0 + float(i)) * 3.0 / 11.0;
		vec2 off = d.zw / cell * px_per_m * px * vec2(1.0, -1.0);
		vec3 at = view_at(uv + off, INV_PROJECTION_MATRIX);
		float same = 1.0 - smoothstep(0.1, 0.3, abs(-at.z - dist) / max(dist * 0.02, 0.05));
		float w = (i == 0 ? 1.0 - fade : fade) * same * step(0.001, d.x);
		dab_paint += sqrt(clamp(textureLod(screen_mip, uv + off, klod).rgb, 0.0, 4.0)) * w;
		dab_weight += w;
	}
	vec3 dab_col = dab_weight > 0.0 ? dab_paint / dab_weight : sqrt(paint);
	dab_col = dab_col * dab_col;
	dab_col = max(mix(vec3(luma(dab_col)), dab_col, 1.15), vec3(0.0));
	paint = mix(paint, dab_col, clamp(dab_weight, 0.0, 1.0) * near * 0.85);
	pl = luma(paint);
	// Broken color: each dab a slightly different mix of the paint.
	float mixv = (mix(d0.y, d1.y, fade) - 0.5) * near;
	paint *= 1.0 + mixv * 0.14;
	paint = mix(paint, paint.gbr * 0.2 + paint * 0.8, max(mixv, 0.0) * 0.16);

	// The canvas's weave, in the canvas: threads two and a half pixels across, over and under.
	vec2 w = uv / px / 2.5;
	vec2 f = fract(w) - 0.5;
	float over = mod(floor(w.x) + floor(w.y), 2.0);
	float weave = mix(1.0 - 4.0 * f.y * f.y, 1.0 - 4.0 * f.x * f.x, over) - 0.5;
	float thin = 1.0 - smoothstep(0.0, 0.35, h);

	vec3 outv = paint * (1.0 + relief) * (1.0 + weave * canvas * (0.4 + thin));
	// A glint on the ridges that face the lamp, as wet oil catches it.
	outv += vec3(smoothstep(0.12, 0.3, relief)) * 0.08 * pl;

	// Bullets and lamps keep their glow; the brush does not smear them out.
	float hot = smoothstep(1.6, 2.6, max(c.r, max(c.g, c.b)));
	outv = mix(outv, c, hot);
	ALBEDO = mix(c, outv, amount);
}
