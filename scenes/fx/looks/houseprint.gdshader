shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// House print: the frame printed the way the house prints its tickets. A soft keyline round
// everything, the shadows laid in a fine screen of dots in the ink of what they fall on, and the
// tooth of the paper under the lot, at a whisper.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform float cell : hint_range(3.0, 10.0) = 4.0;
uniform float keyline : hint_range(0.0, 1.0) = 0.6;
uniform float grain : hint_range(0.0, 0.2) = 0.04;

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float shade = shade_of(c, SCREEN_UV, screen_mip, INV_PROJECTION_MATRIX, px);
	vec2 q = mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071)) * (SCREEN_UV / px / cell);
	float d = length(fract(q) - 0.5);
	float r = sqrt(shade) * 0.58;
	float aa = fwidth(d) * 1.2;
	float dots = 1.0 - smoothstep(r - aa, r + aa, d);
	vec3 around = textureLod(screen_mip, SCREEN_UV, 4.5).rgb;
	vec3 lit = c * clamp(luma(around) / max(luma(c), 1e-4), 1.0, 1.8) * 0.92;
	vec3 printed = mix(c, mix(lit, ink_of(c) * 1.5, dots), smoothstep(0.05, 0.3, shade));
	float e = edge_at(SCREEN_UV, px, INV_PROJECTION_MATRIX);
	printed = mix(printed, ink_of(c), e * keyline);
	float t = hash(floor(SCREEN_UV / px)) * 0.6 + hash(floor(SCREEN_UV / px * 0.37) + 3.1) * 0.4;
	printed *= 1.0 - grain * (t - 0.5) * 2.0;
	ALBEDO = mix(c, printed, amount);
}
