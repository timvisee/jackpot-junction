shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Screenprint: the frame pulled as a silkscreen poster, at a light hand. Each thing is printed in
// flat steps of an ink from a short row of tins, its own color pulled toward the tin's; a dark key
// goes over it in a fine halftone for the dark tones and a thin line round the outlines; the
// screens are a hair out of register with each other, so a sliver of paper or of overprint shows
// along the edges; and the ink lies a little unevenly, as a squeegee leaves it.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 paper = vec3(0.95, 0.925, 0.86);
uniform vec3 key_ink = vec3(0.11, 0.1, 0.15);
// How far the screens are out of register, in pixels at 1080 lines.
uniform float misregister : hint_range(0.0, 4.0) = 0.8;
// The halftone's cell, in pixels at 1080 lines.
uniform float cell : hint_range(3.0, 12.0) = 4.0;
// How many flat steps of each ink there are, from the paper to the full ink.
uniform float levels : hint_range(3.0, 12.0) = 6.0;

const int INKS = 9;
const vec3 INK_COLORS[9] = {
	vec3(0.9, 0.17, 0.2), // warm red
	vec3(0.97, 0.5, 0.13), // orange
	vec3(0.98, 0.8, 0.12), // yellow
	vec3(0.2, 0.66, 0.3), // green
	vec3(0.02, 0.5, 0.44), // teal
	vec3(0.15, 0.33, 0.78), // ultramarine
	vec3(0.5, 0.25, 0.65), // violet
	vec3(0.96, 0.38, 0.62), // pink
	vec3(0.6, 0.57, 0.52) // warm gray
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

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

float apart(vec3 a, vec3 b) {
	vec3 d = a - b;
	float r = 0.5 * (a.r + b.r);
	return (2.0 + r) * d.r * d.r + 4.0 * d.g * d.g + (3.0 - r) * d.b * d.b;
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	float scale = max(1.0, VIEWPORT_SIZE.y / 1080.0);
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;

	// The color screen: the picture's color pulled toward the tin it would be printed from, chosen
	// by its hue, and its depth set to one of a few flat steps.
	vec2 color_uv = uv + vec2(1.0, 0.6) * misregister * px;
	vec3 s = shown(textureLod(screen_mip, color_uv, 0.8 + log2(scale)).rgb);
	float mx = max(s.r, max(s.g, s.b));
	float chroma = mx - min(s.r, min(s.g, s.b));
	vec3 hue = s / max(mx, 1e-3);
	int pick = 8;
	float best = 1e9;
	for (int i = 0; i < INKS - 1; i++) {
		vec3 ink = INK_COLORS[i];
		float d = apart(hue, ink / max(ink.r, max(ink.g, ink.b)));
		if (d < best) {
			best = d;
			pick = i;
		}
	}
	// Grays and the near-grays print from the warm gray.
	float sat = chroma / max(mx, 0.05);
	float colorful = smoothstep(0.1, 0.2, sat);
	pick = colorful > 0.5 ? pick : 8;
	vec3 ink = INK_COLORS[pick];
	vec3 ink_hue = ink / max(ink.r, max(ink.g, ink.b));
	vec3 pulled = mix(hue, ink_hue, 0.45 * colorful);
	float f = pow(mx, 0.85) * levels;
	float stepped = (floor(f) + smoothstep(0.4, 0.6, fract(f))) / levels;
	stepped = max(stepped, 0.5 / levels);
	vec3 color_plate = pulled * stepped;
	// The palest parts are the paper itself.
	color_plate = mix(color_plate, paper, smoothstep(0.82, 0.95, stepped) * (1.0 - smoothstep(0.15, 0.35, sat)));
	float inked = 1.0 - smoothstep(0.85, 0.95, stepped) * (1.0 - smoothstep(0.15, 0.35, sat));

	// The key screen, out of register the other way: a fine halftone for the dark tones, solid only
	// in the deepest, and a thin line along the outlines.
	vec2 key_uv = uv - vec2(0.7, 0.4) * misregister * px;
	vec3 ks = shown(textureLod(screen_mip, key_uv, 0.5 + log2(scale)).rgb);
	float kl = luma(ks);
	float dark = 1.0 - smoothstep(0.05, 0.3, kl);
	vec2 q = mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071)) * (uv / px / cell);
	float d = length(fract(q) - 0.5);
	float r = sqrt(dark) * 0.62;
	float aa = fwidth(d) * 1.0;
	float dots = (1.0 - smoothstep(r - aa, r + aa, d)) * smoothstep(0.02, 0.1, r);
	dots = max(dots, smoothstep(0.88, 0.98, dark));
	float e = edge_at(key_uv, px * 1.2, INV_PROJECTION_MATRIX);
	float key = max(dots * 0.85, smoothstep(0.35, 0.8, e) * 0.7);

	// The ink lies a little unevenly: thinner in streaks the squeegee pulled, in the paper.
	float uneven = vnoise(uv / px * vec2(0.02, 0.12)) * 0.6 + vnoise(uv / px * 0.09) * 0.4;
	color_plate = mix(color_plate, paper, (uneven - 0.4) * 0.08 * inked);
	// Inks overprint: the key over the color is darker still.
	vec3 printed = color_plate * mix(vec3(1.0), key_ink / paper, key);
	float tooth = hash12(floor(uv / px)) * 0.6 + hash12(floor(uv / px * 0.5) + 3.0) * 0.4;
	printed *= 1.0 - 0.035 * (tooth - 0.5) * 2.0;

	vec3 linear = unshown(printed);
	float hot = smoothstep(1.6, 2.6, max(c.r, max(c.g, c.b)));
	linear = mix(linear, max(linear, c), hot);
	ALBEDO = mix(c, linear, amount);
}
