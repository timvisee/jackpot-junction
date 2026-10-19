shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"
#include "res://scenes/fx/looks/outline.gdshaderinc"

// Black outline: a near-black line round every object, drawn outside its silhouette so it keeps
// its color, and a thinner one along its creases. The looks that use it set how wide and how dark,
// see RenderLook.TABLE.
uniform float width : hint_range(0.5, 5.0) = 2.0;
uniform float crease : hint_range(0.0, 1.0) = 0.5;
uniform vec3 ink : source_color = vec3(0.04, 0.035, 0.045);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec2 line = outline_at(SCREEN_UV, pixel(VIEWPORT_SIZE), width, INV_PROJECTION_MATRIX);
	float k = max(line.x, line.y * crease);
	ALBEDO = mix(c, ink, k * amount);
}
