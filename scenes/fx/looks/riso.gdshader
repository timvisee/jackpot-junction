shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Riso: printed on a risograph in spot inks, each laid a little out of register, with the paper's
// grain under it and the tones stepped as a stencil steps them.
uniform float offset : hint_range(0.0, 4.0) = 0.8;
uniform float levels : hint_range(3.0, 16.0) = 10.0;
uniform float grain : hint_range(0.0, 0.3) = 0.035;

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 o = px * offset;
	// Each ink off register by its own small step.
	float r = texture(screen_tex, SCREEN_UV + vec2(o.x, 0.3 * o.y)).r;
	float g = texture(screen_tex, SCREEN_UV - vec2(0.4 * o.x, o.y)).g;
	float b = texture(screen_tex, SCREEN_UV + vec2(-o.x, 0.6 * o.y)).b;
	vec3 c = vec3(r, g, b);
	vec3 base = texture(screen_tex, SCREEN_UV).rgb;
	// Stepped in a perceptual space, with a little dither so the steps are not bands.
	vec3 p = pow(clamp(c, 0.0, 4.0), vec3(1.0 / 2.2));
	float n = hash(floor(SCREEN_UV / px));
	p = floor(p * levels + 0.5) / levels;
	vec3 stepped = pow(p, vec3(2.2));
	// The paper: warm and a little uneven.
	float paper = 1.0 - grain * (hash(floor(SCREEN_UV / px * 0.5) + 7.0) - 0.5);
	vec3 outv = stepped * paper * vec3(1.02, 1.0, 0.95);
	ALBEDO = mix(base, outv, amount);
}
