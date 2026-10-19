shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Tilt-shift: the frame as a photograph of a model through a tilted lens: sharp in a band across
// the middle of the table, soft above and below it, the colors a step richer, the way a real
// street looks like a toy in one.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform float band : hint_range(0.05, 0.4) = 0.16;
uniform float blur : hint_range(0.0, 6.0) = 4.0;

void fragment() {
	vec3 sharp = texture(screen_tex, SCREEN_UV).rgb;
	float off = abs(SCREEN_UV.y - 0.55);
	float soft = smoothstep(band, band + 0.28, off);
	vec3 c = sharp;
	if (soft > 0.001) {
		vec2 px = pixel(VIEWPORT_SIZE);
		float lod = blur * soft;
		vec3 sum = vec3(0.0);
		for (int i = 0; i < 4; i++) {
			vec2 o = vec2(i % 2 == 0 ? -1.0 : 1.0, i < 2 ? -1.0 : 1.0) * px * exp2(lod) * 0.5;
			sum += textureLod(screen_mip, SCREEN_UV + o, lod).rgb;
		}
		c = mix(sharp, sum * 0.25, soft);
	}
	vec3 p = pow(clamp(c, 0.0, 8.0), vec3(1.0 / 2.2));
	p = mix(vec3(luma(p)), p, 1.25);
	p = (p - 0.5) * 1.08 + 0.5;
	ALBEDO = mix(sharp, pow(clamp(p, 0.0, 8.0), vec3(2.2)), amount);
}
