shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Comic: the strongest of them. Cel bands, a keyline round everything and the shade in halftone
// dots, the way a printed comic of the match would draw it.
uniform float cell : hint_range(3.0, 12.0) = 5.0;
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = max(luma(c), 1e-4);
	float p = pow(clamp(l, 0.0, 4.0), 1.0 / 2.2) * 3.0;
	float stepped = floor(p) + smoothstep(0.42, 0.58, fract(p));
	float lq = pow(max(stepped, 0.45) / 3.0, 2.2);
	vec3 banded = c * (lq / l);
	float shade = shade_of(c, SCREEN_UV, screen_mip, INV_PROJECTION_MATRIX, px);
	vec2 q = mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071)) * (SCREEN_UV / px / cell);
	float d = length(fract(q) - 0.5);
	float r = sqrt(shade) * 0.6;
	float aa = fwidth(d) * 1.2;
	float dots = 1.0 - smoothstep(r - aa, r + aa, d);
	vec3 printed = mix(banded, ink_of(banded) * 1.5, dots * smoothstep(0.05, 0.25, shade));
	float e = edge_at(SCREEN_UV, px * 1.3, INV_PROJECTION_MATRIX);
	vec3 outv = mix(printed, ink_of(banded), e);
	ALBEDO = mix(c, outv, amount);
}
