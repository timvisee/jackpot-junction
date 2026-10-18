shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Halftone: where the light falls the color is flat; in the shade it is printed in dots, as a
// lithograph or a comic shades, the dots growing as the shade deepens.
uniform float cell : hint_range(3.0, 12.0) = 5.0;
uniform float light_level : hint_range(0.02, 1.0) = 0.22;
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float shade = shade_of(c, SCREEN_UV, screen_mip, INV_PROJECTION_MATRIX, px);
	// The screen of dots, turned forty-five degrees as a print's is.
	vec2 p = mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071)) * (SCREEN_UV / px / cell);
	float d = length(fract(p) - 0.5);
	float r = sqrt(shade) * 0.62;
	float aa = fwidth(d) * 1.2;
	float dots = 1.0 - smoothstep(r - aa, r + aa, d);
	// The paper between the dots is the color as the light would have it, the dot its ink.
	vec3 around = textureLod(screen_mip, SCREEN_UV, 4.5).rgb;
	vec3 lit = c * clamp(luma(around) / max(luma(c), 1e-4), 1.0, 2.5) * 0.9;
	vec3 printed = mix(lit, ink_of(c) * 1.4, dots);
	vec3 outv = mix(c, printed, smoothstep(0.05, 0.25, shade));
	ALBEDO = mix(c, outv, amount);
}
