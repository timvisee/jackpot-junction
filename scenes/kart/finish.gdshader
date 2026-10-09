// The finish of a piece of dress, GAME.md 8.9: a sheen laid over it as a second pass, added to
// what is under it so the player's color stays the color, never a color of its own. Foil is a
// band of warm light sweeping across it and a glow at its edges; Holographic colors that turn with
// the angle it is seen at; Polychrome bands of every color drifting over it.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

uniform int finish = 1;
uniform float strength = 0.5;

varying vec3 world_at;

vec3 hue(float h) {
	return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void vertex() {
	world_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float glance = rim * rim;
	vec3 sheen;
	if (finish == 1) {
		float sweep = sin(world_at.x * 1.7 + world_at.z * 1.1 - TIME * 2.2) * 0.5 + 0.5;
		float band = smoothstep(0.82, 1.0, sweep);
		sheen = vec3(1.0, 0.9, 0.62) * (glance * 0.55 + band * 0.5);
	} else if (finish == 2) {
		float turn = rim * 1.6 + dot(NORMAL, vec3(0.3, 0.6, 0.2)) + TIME * 0.05;
		sheen = hue(turn) * (0.12 + glance * 0.45);
	} else {
		float drift = world_at.x * 0.35 + world_at.y * 0.5 + world_at.z * 0.25 + TIME * 0.25;
		sheen = hue(drift) * (0.16 + glance * 0.32);
	}
	ALBEDO = sheen * strength;
}
