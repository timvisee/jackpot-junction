shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Pastel: the frame washed soft and light, as a sugared-almond toy is: the color lifted toward
// cream and a little desaturated, the shade lifted, a soft glow off the light parts.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 cream : source_color = vec3(0.98, 0.94, 0.88);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec3 p = pow(clamp(c, 0.0, 8.0), vec3(1.0 / 2.2));
	float l = luma(p);
	p = mix(vec3(l), p, 0.75);
	p = mix(p, cream, 0.28);
	p = p * 0.85 + 0.12;
	vec3 glow = pow(clamp(textureLod(screen_mip, SCREEN_UV, 3.5).rgb, 0.0, 8.0), vec3(1.0 / 2.2));
	p += max(glow - 0.6, vec3(0.0)) * 0.5;
	ALBEDO = mix(c, pow(clamp(p, 0.0, 8.0), vec3(2.2)), amount);
}
