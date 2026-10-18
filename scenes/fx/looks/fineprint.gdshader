shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Fine print: the subtle one. The frame stays as it is, laid on the house's paper: a fine tooth of
// grain, the ink spreading a hair at every edge, the corners a little darker, as a print is.
uniform float grain : hint_range(0.0, 0.2) = 0.06;
uniform float spread : hint_range(0.0, 1.0) = 0.45;
uniform float corners : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float e = edge_at(SCREEN_UV, px, INV_PROJECTION_MATRIX);
	vec3 outv = mix(c, ink_of(c), e * spread);
	// Paper tooth at two scales that never line up.
	float t = hash(floor(SCREEN_UV / px)) * 0.6 + hash(floor(SCREEN_UV / px * 0.37) + 3.1) * 0.4;
	outv *= 1.0 - grain * (t - 0.5) * 2.0;
	vec2 v = SCREEN_UV - 0.5;
	outv *= 1.0 - corners * smoothstep(0.25, 0.75, dot(v, v) * 2.2);
	ALBEDO = mix(c, outv, amount);
}
