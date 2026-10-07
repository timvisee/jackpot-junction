// The Count Room's racks, STORY.md 3.9: metal with rows of small lights winking on its faces, each
// light on and off on a time of its own, all of it one material run off the world position, so a
// thousand lights are no node each and a baked rack winks as it did before. Only the upright faces
// carry lights; the tops are bare.
shader_type spatial;
render_mode shadows_disabled, specular_disabled;

uniform vec4 body : source_color = vec4(0.1, 0.11, 0.11, 1.0);
uniform vec4 light : source_color = vec4(0.25, 1.0, 0.4, 1.0);
// Lights to a meter across, and how hard a lit one glows.
uniform float density = 7.0;
uniform float glow = 2.6;

varying vec3 world;
varying vec3 world_normal;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 along = abs(world_normal.z) > abs(world_normal.x) ? world.xy : world.zy;
	vec2 scale = vec2(density, density * 1.6);
	vec2 cell = floor(along * scale);
	vec2 inside = fract(along * scale) - 0.5;
	// Every third row is a unit's lights; the rows between are its blank front.
	float row = step(0.6, fract(cell.y / 3.0));
	float rate = 0.6 + hash(cell + 7.1) * 2.4;
	float on = step(0.5, hash(cell + floor(TIME * rate + hash(cell) * 10.0)));
	float spot = 1.0 - smoothstep(0.12, 0.2, length(inside * vec2(1.0, 1.6)));
	float upright = 1.0 - step(0.5, abs(world_normal.y));
	float lit = spot * on * row * upright;
	ALBEDO = mix(body.rgb, light.rgb, lit);
	EMISSION = light.rgb * lit * glow;
	ROUGHNESS = 0.55;
	METALLIC = 0.3;
}
