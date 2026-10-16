// The beam the House throws its forecast down along, STORY.md 8.2, see [ForecastLine]: a cone of
// faint light out of the dark over the racks onto where it expects the candidate's kart, soft at
// its edges and brightest near the floor, dust drifting through it. Drawn on a cone a meter tall,
// stretched to the length of the beam.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 ink : source_color = vec4(1.0, 0.86, 0.5, 1.0);
uniform float strength = 0.2;
uniform float glitch = 0.0;

varying float up;
varying vec3 world_at;

void vertex() {
	up = VERTEX.y + 0.5;
	world_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float facing = abs(dot(NORMAL, VIEW));
	float soft = pow(facing, 2.2);
	float fade = (1.0 - smoothstep(0.2, 0.75, up)) * (1.0 - up);
	float dust = 0.75 + 0.25 * sin(world_at.y * 3.0 + world_at.x * 1.7 - TIME * 1.3);
	float stutter = 1.0 - glitch * 0.7 * step(0.5, fract(TIME * 23.0));
	ALBEDO = ink.rgb;
	ALPHA = clamp(soft * fade * dust * stutter * strength, 0.0, 1.0);
}
