// The supporter pack's night sky, GAME.md 10.8: now and then one of its stars brightens a little
// and fades back, slowly, each to a beat of its own so never two together, hard to spot until it
// is seen. A pass of its own between the paint and its finish, its stars found as the paint finds
// them, laid on in three directions, and its light added so the color stays the color. Nothing at
// all where it is told to be steady, for a player who asked for fewer flashes.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

// Each star's light in red and its own beat in green, see SupporterPaint.beats().
uniform sampler2D beats : filter_linear_mipmap, repeat_enable;
uniform vec3 scale = vec3(1.0);
uniform float sharpness = 40.0;
uniform float strength = 0.9;
uniform bool steady = false;

varying vec3 laid;
varying vec3 weights;

void vertex() {
	// As the paint's own triplanar mapping has it, so the light falls on its stars.
	weights = pow(abs(NORMAL), vec3(sharpness));
	weights /= dot(weights, vec3(1.0));
	laid = VERTEX * scale * vec3(1.0, -1.0, 1.0);
}

// How much a star at [uv] is brightened now: mostly not at all, then a slow rise and fall.
float brightened(vec2 uv) {
	vec2 star = texture(beats, uv).rg;
	float beat = 0.5 + 0.5 * sin(TIME * (0.45 + star.y * 0.5) + star.y * 43.98);
	return star.x * pow(beat, 10.0);
}

void fragment() {
	float lit = 0.0;
	if (!steady) {
		lit += brightened(laid.xy) * weights.z;
		lit += brightened(laid.xz) * weights.y;
		lit += brightened(laid.zy * vec2(-1.0, 1.0)) * weights.x;
	}
	ALBEDO = vec3(1.0, 0.97, 0.9) * lit * strength;
}
