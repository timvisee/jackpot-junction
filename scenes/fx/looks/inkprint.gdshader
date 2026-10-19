shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"
#include "res://scenes/fx/looks/outline.gdshaderinc"

// Ink and print: the black outline over the house print at a whisper, the shade laid in a fine
// screen of dots in the ink of what it falls on, and the paper's tooth under it all.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform float width : hint_range(0.5, 5.0) = 1.8;
uniform float crease : hint_range(0.0, 1.0) = 0.45;
uniform float dots : hint_range(0.0, 1.0) = 0.45;
uniform float cell : hint_range(3.0, 10.0) = 4.0;
uniform float grain : hint_range(0.0, 0.2) = 0.035;
uniform vec3 ink : source_color = vec3(0.04, 0.035, 0.045);

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float shade = shade_of(c, SCREEN_UV, screen_mip, INV_PROJECTION_MATRIX, px);
	vec2 q = mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071)) * (SCREEN_UV / px / cell);
	float d = length(fract(q) - 0.5);
	float r = sqrt(shade) * 0.5;
	float aa = fwidth(d) * 1.2;
	float printed_dot = (1.0 - smoothstep(r - aa, r + aa, d)) * smoothstep(0.1, 0.35, shade);
	vec3 printed = mix(c, ink_of(c) * 1.6, printed_dot * dots);
	float t = hash(floor(SCREEN_UV / px)) * 0.6 + hash(floor(SCREEN_UV / px * 0.37) + 3.1) * 0.4;
	printed *= 1.0 - grain * (t - 0.5) * 2.0;
	vec2 line = outline_at(SCREEN_UV, px, width, INV_PROJECTION_MATRIX);
	printed = mix(printed, ink, max(line.x, line.y * crease));
	ALBEDO = mix(c, printed, amount);
}
