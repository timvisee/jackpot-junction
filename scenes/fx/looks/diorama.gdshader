shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Diorama: graded like a photograph of a model. The shade cooled toward the room's fill and the
// light warmed, the middle tones richer, and the top and foot of the frame softened as a close
// lens softens what is nearer and further than the table.
uniform vec3 shade_tint : source_color = vec3(0.36, 0.42, 0.62);
uniform vec3 light_tint : source_color = vec3(1.0, 0.93, 0.82);
uniform float blur : hint_range(0.0, 4.0) = 2.5;
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	// The frame's top and foot, softer: a few taps of the frame's own mip chain.
	float band = smoothstep(0.32, 0.5, abs(SCREEN_UV.y - 0.55));
	if (band > 0.0) {
		vec3 soft = textureLod(screen_mip, SCREEN_UV, blur * band).rgb;
		c = mix(c, soft, band);
	}
	float l = luma(c);
	float pl = pow(clamp(l, 0.0, 4.0), 1.0 / 2.2);
	vec3 tint = mix(shade_tint, light_tint, smoothstep(0.15, 0.75, pl));
	vec3 graded = c * mix(vec3(1.0), tint * 1.25, 0.55);
	// Richer middle tones.
	float gl = luma(graded);
	graded = mix(vec3(gl), graded, 1.18);
	ALBEDO = mix(texture(screen_tex, SCREEN_UV).rgb, max(graded, vec3(0.0)), amount);
}
