shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Vivid: the frame graded punchier, as a toy box's photograph is: richer color, deeper shade, a
// little more contrast in the middle tones, nothing else.
uniform float saturation : hint_range(1.0, 2.0) = 1.35;
uniform float contrast : hint_range(1.0, 1.6) = 1.15;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec3 p = pow(clamp(c, 0.0, 8.0), vec3(1.0 / 2.2));
	float l = luma(p);
	p = mix(vec3(l), p, saturation);
	p = (p - 0.5) * contrast + 0.5;
	vec3 graded = pow(clamp(p, 0.0, 8.0), vec3(2.2));
	ALBEDO = mix(c, graded, amount);
}
