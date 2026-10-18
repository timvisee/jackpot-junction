shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Keyline: every outline and crease drawn in a thin ink of the color under it, the way a
// printed illustration is keyed.
uniform float width : hint_range(0.5, 3.0) = 1.6;

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE) * width;
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float e = edge_at(SCREEN_UV, px, INV_PROJECTION_MATRIX);
	ALBEDO = mix(c, ink_of(c), min(e * 1.25, 1.0) * amount);
}
