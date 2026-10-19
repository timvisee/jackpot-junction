shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Stained glass: the frame cut into irregular pieces of jewel-colored glass, each a flat color of
// its own with the ripples and streaks of hand-blown glass in it, held in dark lead that runs
// between the pieces and round every outline. A piece never spans two things: where a kart stands
// over the felt the glass is cut along its edge, so the kart is its own pieces in its own color.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
// How big a piece of glass is, in pixels at 1080 lines.
uniform float piece : hint_range(6.0, 24.0) = 13.0;
// How wide the lead is, in pixels.
uniform float lead : hint_range(0.5, 4.0) = 1.3;

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

// Glass as light comes through it: richer and deeper than paint, the pale colors tinted rather
// than white, the dark ones still letting a little through.
vec3 jewel(vec3 s, float vary, float shift) {
	float l = luma(s);
	// Richer the lighter it is: the deep pieces stay deep rather than turning to bright ruby.
	vec3 rich = clamp(mix(vec3(l), s, mix(1.15, 1.6, smoothstep(0.1, 0.5, l))), 0.0, 1.0);
	// The lights come down a little so they keep a color, the darks up a little so they glow.
	float lifted = mix(0.13, 0.9, pow(smoothstep(0.0, 1.0, l), 0.75));
	rich *= lifted / max(luma(rich), 1e-3);
	// No two pieces from the same sheet: a little lighter or darker, a little off in hue.
	rich = mix(rich, rich.gbr, max(shift, 0.0) * 0.08);
	rich = mix(rich, rich.brg, max(-shift, 0.0) * 0.08);
	return clamp(rich * (1.0 + vary), 0.0, 1.0);
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	float scale = max(1.0, VIEWPORT_SIZE.y / 1080.0);
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;
	vec3 here = view_at(uv, INV_PROJECTION_MATRIX);
	float dist = -here.z;
	// How the distance runs across the screen here, to tell a seed on the same surface from one
	// on something nearer or farther.
	float ddx = dFdx(dist);
	float ddy = dFdy(dist);
	float slope = clamp(abs(ddx) + abs(ddy), 0.0, 0.05 * dist);

	vec2 p = uv / px / piece;
	vec2 base = floor(p);
	vec2 rel = fract(p);
	// The seeds round the pixel, and which of them lie on the same surface as it.
	vec2 rs[9];
	bool same[9];
	float best = 1e9;
	int at = -1;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			int n = (j + 1) * 3 + (i + 1);
			vec2 g = vec2(float(i), float(j));
			vec2 r = g + 0.15 + hash22(base + g) * 0.7 - rel;
			rs[n] = r;
			vec2 seed_uv = uv + r * piece * px;
			float sd = distance_at(seed_uv, INV_PROJECTION_MATRIX);
			// The distance the seed would be at on this pixel's surface, flat as it is here.
			vec2 step_px = r * piece / scale * scale;
			float expect = dist + ddx * step_px.x * scale + ddy * step_px.y * scale;
			same[n] = abs(sd - expect) < 0.12 + 0.012 * dist + slope * 2.0;
			float d = dot(r, r);
			if (same[n] && d < best) {
				best = d;
				at = n;
			}
		}
	}
	// The way to the nearest lead: the nearest bisector between this piece's seed and another's.
	float border = 1e9;
	vec2 mine = vec2(0.0);
	vec2 cellid = base;
	if (at >= 0) {
		mine = rs[at];
		cellid = base + vec2(float(at % 3 - 1), float(at / 3 - 1));
		for (int n = 0; n < 9; n++) {
			if (n != at && same[n]) {
				vec2 r = rs[n];
				border = min(border, dot(0.5 * (mine + r), normalize(r - mine)));
			}
		}
	}
	float border_px = border * piece;

	// The piece's color: the frame over the piece, round its seed, made glass; a pixel that has no
	// piece on its surface near it, a bullet or a thin rail, is glass of its own color.
	float lod = log2(piece * scale * 0.55);
	vec3 col;
	float vary = 0.0;
	vec2 local = rel;
	if (at >= 0) {
		col = textureLod(screen_mip, uv + mine * piece * px, lod).rgb;
		vary = (hash12(cellid + 3.7) - 0.5) * 0.22;
		local = -mine;
	} else {
		col = textureLod(screen_mip, uv, 1.0).rgb;
	}
	vec3 glass = jewel(shown(col), vary, (hash12(cellid + 5.3) - 0.5) * 2.0);
	// Hand-blown glass is never even: a slow streak across each piece and a ripple in it, in the
	// piece's own frame so it stays with the piece.
	float streak_dir = hash12(cellid + 9.1) * 6.2832;
	vec2 sd2 = vec2(cos(streak_dir), sin(streak_dir));
	float streak = dot(local, sd2);
	float ripple = vnoise(local * 2.3 + cellid * 7.0) - 0.5;
	glass *= 1.0 + streak * 0.12 + ripple * 0.1;
	// A little darker toward the lead, where the glass meets the putty.
	glass *= mix(0.82, 1.0, smoothstep(0.0, 4.0, border_px - lead));

	// Paint on the glass: the fine lines of the picture inside a piece, in a brown-black grisaille.
	float glod = 1.0 * log2(scale);
	vec3 a0 = textureLod(screen_mip, uv + vec2(px.x, 0.0), glod).rgb;
	vec3 a1 = textureLod(screen_mip, uv - vec2(px.x, 0.0), glod).rgb;
	vec3 a2 = textureLod(screen_mip, uv + vec2(0.0, px.y), glod).rgb;
	vec3 a3 = textureLod(screen_mip, uv - vec2(0.0, px.y), glod).rgb;
	float lg = length(vec2(luma(sqrt(a0)) - luma(sqrt(a1)), luma(sqrt(a2)) - luma(sqrt(a3))));
	float paint = smoothstep(0.08, 0.25, lg) * 0.55;
	glass = mix(glass, vec3(0.09, 0.06, 0.05), paint);

	// The lead: between the pieces and round every outline, dark, with a dull shine down its
	// rounded middle, and a little of the glass's light spilling over it.
	float e = edge_at(uv, px * 1.2, INV_PROJECTION_MATRIX);
	float aa = 0.75;
	float came = 1.0 - smoothstep(lead - aa, lead + aa, border_px);
	came = max(came, smoothstep(0.25, 0.7, e));
	float profile = at >= 0 ? clamp(1.0 - border_px / max(lead, 0.5), 0.0, 1.0) : 0.5;
	vec3 lead_col = mix(vec3(0.035, 0.035, 0.04), vec3(0.2, 0.2, 0.21), profile * profile * 0.8);
	vec3 halo = jewel(shown(textureLod(screen_mip, uv, lod + 1.0).rgb), 0.0, 0.0);
	lead_col += halo * 0.12;
	vec3 outv = mix(glass, lead_col, came);

	// Light through the glass blooms a little round the brightest pieces.
	vec3 bloom = shown(textureLod(screen_mip, uv, lod + 2.0).rgb);
	outv += max(jewel(bloom, 0.0, 0.0) - 0.65, vec3(0.0)) * 0.35;

	vec3 linear = unshown(outv);
	float near = 1.0 - smoothstep(180.0, 240.0, dist);
	linear = mix(unshown(jewel(shown(c), 0.0, 0.0)), linear, near);
	float hot = smoothstep(1.6, 2.6, max(c.r, max(c.g, c.b)));
	linear = mix(linear, max(linear, c), hot);
	ALBEDO = mix(c, linear, amount);
}
