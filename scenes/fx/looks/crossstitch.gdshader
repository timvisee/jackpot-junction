shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Cross-stitch: the frame worked in floss on aida cloth, a cross in every square of the cloth's
// grid, each in the nearest of a box of stranded cotton's colors. The under leg goes one way and
// the top leg the other in every stitch, as a careful hand does it; the thread is round and
// twisted and shines a little down its middle; and where the picture is as pale as the cloth, the
// cloth is left bare, its holes showing at the corners of the squares.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
// How big a stitch is, in pixels at 1080 lines.
uniform float stitch : hint_range(4.0, 14.0) = 7.0;
uniform vec3 cloth = vec3(0.93, 0.9, 0.82);

// The box of floss, as the colors look on the screen.
const int FLOSS = 30;
const vec3 FLOSS_COLORS[30] = {
	vec3(0.07, 0.07, 0.08), // black
	vec3(0.27, 0.28, 0.3), // pewter
	vec3(0.55, 0.55, 0.57), // steel gray
	vec3(0.82, 0.82, 0.82), // pearl gray
	vec3(0.98, 0.98, 0.97), // white
	vec3(0.78, 0.07, 0.17), // red
	vec3(0.52, 0.04, 0.12), // garnet
	vec3(1.0, 0.45, 0.45), // melon
	vec3(1.0, 0.62, 0.8), // pink
	vec3(0.85, 0.2, 0.55), // cranberry
	vec3(1.0, 0.52, 0.05), // tangerine
	vec3(1.0, 0.84, 0.05), // lemon
	vec3(1.0, 0.94, 0.62), // topaz light
	vec3(0.84, 0.65, 0.33), // old gold
	vec3(0.48, 0.3, 0.17), // brown
	vec3(0.25, 0.15, 0.1), // coffee
	vec3(0.09, 0.42, 0.29), // emerald dark
	vec3(0.06, 0.28, 0.2), // emerald ultra dark
	vec3(0.03, 0.17, 0.06), // pine very dark
	vec3(0.12, 0.56, 0.42), // aquamarine
	vec3(0.3, 0.64, 0.2), // kelly green
	vec3(0.62, 0.82, 0.3), // chartreuse
	vec3(0.05, 0.12, 0.38), // navy
	vec3(0.1, 0.11, 0.2), // navy very dark
	vec3(0.1, 0.3, 0.68), // royal blue
	vec3(0.45, 0.6, 0.85), // delft blue
	vec3(0.1, 0.7, 0.9), // electric blue
	vec3(0.4, 0.15, 0.48), // violet
	vec3(0.87, 0.85, 0.76), // ecru, the cloth's own, left bare
	vec3(0.68, 0.6, 0.45) // khaki
};

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

// How far apart two colors look, weighted the way the eye weighs red, green and blue.
float apart(vec3 a, vec3 b) {
	vec3 d = a - b;
	float r = 0.5 * (a.r + b.r);
	return (2.0 + r) * d.r * d.r + 4.0 * d.g * d.g + (3.0 - r) * d.b * d.b;
}

// One leg of a cross: how far a point is across it and along it, the leg running corner to corner.
vec2 leg(vec2 local, vec2 from, vec2 to) {
	vec2 dir = normalize(to - from);
	vec2 d = local - from;
	return vec2(dot(d, vec2(-dir.y, dir.x)), dot(d, dir) / length(to - from));
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	float scale = max(1.0, VIEWPORT_SIZE.y / 1080.0);
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;

	vec2 p = uv / px / stitch;
	vec2 cell = floor(p);
	vec2 local = fract(p);
	vec2 center = (cell + 0.5) * stitch * px;
	vec3 want = shown(textureLod(screen_mip, center, 1.0 + log2(scale)).rgb);

	// The nearest floss, and the next nearest: a square between two of them takes one or the other
	// by chance, so a slope of color is worked in a scatter of both rather than in bands.
	float d1 = 1e9;
	float d2 = 1e9;
	int i1 = 0;
	int i2 = 0;
	for (int i = 0; i < FLOSS; i++) {
		float d = apart(want, FLOSS_COLORS[i]);
		if (d < d1) {
			d2 = d1;
			i2 = i1;
			d1 = d;
			i1 = i;
		} else if (d < d2) {
			d2 = d;
			i2 = i;
		}
	}
	float chance = smoothstep(0.3, 0.5, d1 / max(d1 + d2, 1e-6)) * 0.5;
	int pick = hash12(cell + 0.37) < chance ? i2 : i1;
	vec3 floss = FLOSS_COLORS[pick];
	// Where a patch of the picture is as pale as the cloth, it is left bare, as a pattern leaves
	// its ground; a single pale square in a figure is stitched in ecru.
	vec3 area = shown(textureLod(screen_mip, center, 3.0 + log2(scale)).rgb);
	bool bare = pick == 28 && apart(area, FLOSS_COLORS[28]) < 0.04;

	// The cloth: aida's woven blocks, a hole at every corner of the grid.
	vec2 corner = abs(local - 0.5) * 2.0;
	float to_hole = length(1.0 - corner) * stitch * 0.5;
	float hole = 1.0 - smoothstep(0.5, 1.1, to_hole);
	vec2 weave = abs(fract(local * 2.0) - 0.5) * 2.0;
	float block = 1.0 - 0.05 * (weave.x + weave.y);
	// The cloth is in the room's light too: a dark room is worked on black aida, so it is not
	// a white sheet showing through every stitch.
	float room = luma(shown(textureLod(screen_mip, uv, 5.0).rgb));
	vec3 ground = mix(vec3(0.1, 0.095, 0.1), cloth, smoothstep(0.1, 0.35, room));
	vec3 fabric = ground * block * (1.0 - hole * 0.55);

	// Backstitch: a single dark thread along the side of a square where what is in it stands
	// over what is in the next, as a pattern outlines its figures.
	float dc = distance_at(center, INV_PROJECTION_MATRIX);
	vec2 step_uv = stitch * px;
	float dl = distance_at(center - vec2(step_uv.x, 0.0), INV_PROJECTION_MATRIX);
	float dr = distance_at(center + vec2(step_uv.x, 0.0), INV_PROJECTION_MATRIX);
	float du = distance_at(center - vec2(0.0, step_uv.y), INV_PROJECTION_MATRIX);
	float dd = distance_at(center + vec2(0.0, step_uv.y), INV_PROJECTION_MATRIX);
	float tol = 0.08 + 0.006 * dc;
	// A side is outlined when the square across it is off the surface this one and the square
	// opposite make: a step, not the floor running away from the camera.
	float out_l = step(tol, abs(dl - (2.0 * dc - dr))) * step(tol, abs(dl - dc));
	float out_r = step(tol, abs(dr - (2.0 * dc - dl))) * step(tol, abs(dr - dc));
	float out_u = step(tol, abs(du - (2.0 * dc - dd))) * step(tol, abs(du - dc));
	float out_d = step(tol, abs(dd - (2.0 * dc - du))) * step(tol, abs(dd - dc));
	float bw = 0.09;
	float baa = 0.6 / stitch;
	float back = 0.0;
	back = max(back, out_l * (1.0 - smoothstep(bw - baa, bw + baa, local.x)));
	back = max(back, out_r * (1.0 - smoothstep(bw - baa, bw + baa, 1.0 - local.x)));
	back = max(back, out_u * (1.0 - smoothstep(bw - baa, bw + baa, local.y)));
	back = max(back, out_d * (1.0 - smoothstep(bw - baa, bw + baa, 1.0 - local.y)));

	// The two legs: under from bottom left to top right, over from top left to bottom right.
	float w = 0.21;
	vec2 under = leg(local, vec2(0.05, 0.95), vec2(0.95, 0.05));
	vec2 over = leg(local, vec2(0.05, 0.05), vec2(0.95, 0.95));
	float aa = 0.6 / stitch;
	// Each leg is fullest in its middle and pinched where it dives into the holes at its ends.
	float pinch_u = sin(clamp(under.y, 0.0, 1.0) * 3.14159);
	float pinch_o = sin(clamp(over.y, 0.0, 1.0) * 3.14159);
	float under_w = w * mix(0.4, 1.0, sqrt(pinch_u));
	float over_w = w * mix(0.4, 1.0, sqrt(pinch_o));
	float in_under = 1.0 - smoothstep(under_w - aa, under_w + aa, abs(under.x));
	float in_over = 1.0 - smoothstep(over_w - aa, over_w + aa, abs(over.x));
	// Round thread, lit from the top left: bright down the middle of a leg, darker at its sides
	// and toward its ends, with the twist of its plies across it.
	float sh_u = clamp(under.x / under_w, -1.0, 1.0);
	float sh_o = clamp(over.x / over_w, -1.0, 1.0);
	float round_u = sqrt(max(1.0 - sh_u * sh_u, 0.0));
	float round_o = sqrt(max(1.0 - sh_o * sh_o, 0.0));
	float twist_u = 0.5 + 0.5 * sin((under.y * 3.0 + sh_u * 0.3) * 6.2832);
	float twist_o = 0.5 + 0.5 * sin((over.y * 3.0 - sh_o * 0.3) * 6.2832);
	float lit_u = (0.42 + 0.55 * round_u - sh_u * 0.1) * mix(0.5, 1.0, pinch_u) * (1.0 - 0.1 * twist_u);
	float lit_o = (0.5 + 0.55 * round_o + sh_o * 0.05) * mix(0.55, 1.05, pinch_o) * (1.0 - 0.1 * twist_o);
	vec3 thread_u = floss * lit_u * 0.9;
	vec3 thread_o = floss * lit_o;
	// The over leg throws a little shade on the under leg beside it, and both on the cloth.
	float shade_o = 1.0 - smoothstep(over_w, over_w + 0.1, abs(over.x));
	thread_u *= 1.0 - shade_o * 0.45;
	float shade_cloth = max(1.0 - smoothstep(under_w, under_w + 0.16, abs(under.x)),
			1.0 - smoothstep(over_w, over_w + 0.16, abs(over.x)));
	vec3 outv = fabric;
	if (!bare) {
		// Under a stitch the cloth hardly shows: the floss fluffs over it, and the holes at the
		// corners, where the thread goes down, are dark.
		outv = mix(fabric, floss * 0.5, 0.55) * (1.0 - shade_cloth * 0.35);
		outv = mix(outv, floss * 0.22, hole);
		outv = mix(outv, thread_u, in_under);
		outv = mix(outv, thread_o, in_over);
		// A sheen on the floss where the light catches it.
		outv += vec3(0.06) * in_over * smoothstep(0.75, 1.0, round_o) * pinch_o * (1.0 - twist_o);
	}

	// The backstitch over all, in a dark brown-black floss.
	vec3 back_thread = mix(vec3(0.09, 0.07, 0.07), floss * 0.3, 0.3);
	outv = mix(outv, back_thread, back);

	vec3 linear = unshown(outv);
	float hot = smoothstep(1.6, 2.6, max(c.r, max(c.g, c.b)));
	linear = mix(linear, max(linear, c), hot);
	ALBEDO = mix(c, linear, amount);
}
