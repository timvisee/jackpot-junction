shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// pencil: still to be written; the frame as it is meanwhile.

void fragment() {
	ALBEDO = texture(screen_tex, SCREEN_UV).rgb;
}
