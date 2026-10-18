shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Gouache: the frame painted in flat strokes. A Kuwahara filter keeps each pixel's calmest
// neighbourhood, which flattens texture into patches of paint while keeping the edges.
uniform int radius : hint_range(1, 6) = 3;

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec3 mean[4];
	vec3 sq[4];
	for (int k = 0; k < 4; k++) {
		mean[k] = vec3(0.0);
		sq[k] = vec3(0.0);
	}
	for (int j = -radius; j <= radius; j++) {
		for (int i = -radius; i <= radius; i++) {
			vec3 s = texture(screen_tex, SCREEN_UV + vec2(float(i), float(j)) * px).rgb;
			s = pow(clamp(s, 0.0, 4.0), vec3(1.0 / 2.2));
			vec3 s2 = s * s;
			if (i <= 0 && j <= 0) { mean[0] += s; sq[0] += s2; }
			if (i >= 0 && j <= 0) { mean[1] += s; sq[1] += s2; }
			if (i <= 0 && j >= 0) { mean[2] += s; sq[2] += s2; }
			if (i >= 0 && j >= 0) { mean[3] += s; sq[3] += s2; }
		}
	}
	float count = float((radius + 1) * (radius + 1));
	float best = 1e9;
	vec3 pick = vec3(0.0);
	for (int k = 0; k < 4; k++) {
		vec3 m = mean[k] / count;
		vec3 v = abs(sq[k] / count - m * m);
		float sigma = v.r + v.g + v.b;
		if (sigma < best) {
			best = sigma;
			pick = m;
		}
	}
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	ALBEDO = mix(c, pow(pick, vec3(2.2)), amount);
}
