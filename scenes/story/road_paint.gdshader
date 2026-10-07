// The House's word painted on the road in its box, STORY.md 6.1: old road paint, flush with the
// floor, thin where the karts run over it and chipped away in patches. The box and the letters are
// drawn once into [param paint]; the wear is worked out here from where on the floor it lies, so no
// two boxes wear alike.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

uniform sampler2D paint : filter_linear, repeat_disable;
uniform vec4 ink : source_color = vec4(0.92, 0.88, 0.76, 1.0);
// How much of the paint is left where it has worn least.
uniform float strength = 0.68;

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	float shape = texture(paint, UV).a;
	vec2 p = world.xz;
	// Patches worn through, the grain of the floor showing in what is left, and two tracks where
	// the wheels go along the lane.
	float patches = noise(p * 1.1) * 0.6 + noise(p * 2.7) * 0.4;
	float grain = noise(p * 18.0);
	float wheels = exp(-pow((UV.y - 0.36) / 0.09, 2.0)) + exp(-pow((UV.y - 0.64) / 0.09, 2.0));
	float wear = patches * 0.7 + grain * 0.3 + wheels * 0.14;
	float kept = 1.0 - smoothstep(0.58, 0.74, wear);
	ALBEDO = ink.rgb;
	ALPHA = shape * kept * strength * (0.7 + 0.3 * grain);
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
