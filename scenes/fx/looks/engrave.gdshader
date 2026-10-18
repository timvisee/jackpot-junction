shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Engrave: the shade laid in fine lines that thicken as it darkens and cross in deep shadow, as a
// banknote is engraved, over the color the light leaves.
uniform float period : hint_range(3.0, 10.0) = 4.5;
uniform float light_level : hint_range(0.02, 1.0) = 0.25;
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float shade = shade_of(c, SCREEN_UV, screen_mip, INV_PROJECTION_MATRIX, px);
	vec2 q = SCREEN_UV / px;
	float a = fract(dot(q, vec2(0.866, 0.5)) / period);
	float b = fract(dot(q, vec2(-0.5, 0.866)) / period);
	float wa = shade * 0.75;
	float wb = smoothstep(0.55, 1.0, shade) * 0.6;
	float la = 1.0 - smoothstep(wa - 0.1, wa + 0.1, abs(a - 0.5) * 2.0);
	float lb = 1.0 - smoothstep(wb - 0.1, wb + 0.1, abs(b - 0.5) * 2.0);
	float line = max(la * step(0.02, wa), lb * step(0.02, wb));
	vec3 around = textureLod(screen_mip, SCREEN_UV, 4.5).rgb;
	vec3 lit = c * clamp(luma(around) / max(luma(c), 1e-4), 1.0, 2.5) * 0.9;
	vec3 engraved = mix(lit, ink_of(c) * 1.3, line);
	float e = edge_at(SCREEN_UV, px, INV_PROJECTION_MATRIX);
	vec3 outv = mix(mix(c, engraved, smoothstep(0.05, 0.25, shade)), ink_of(c), e * 0.8);
	ALBEDO = mix(c, outv, amount);
}
