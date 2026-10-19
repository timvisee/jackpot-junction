// The House's word, STORY.md 6.1, off the table in a room's own medium: paint, chalk, gilt, a
// stencil, the dots of a display, a sticker or thread. The letters, and the plate a sticker or a
// display has under them, are drawn once into [param picture], its red the letters and its green
// the plate; how the medium wears them, catches the light on them or lights them is worked out
// here, its wear from where on the word it is in meters, so a word wears the same at any size.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

uniform sampler2D picture : hint_default_transparent, filter_linear_mipmap, repeat_disable;
uniform vec4 ink : source_color = vec4(0.92, 0.88, 0.76, 1.0);
uniform vec4 plate : source_color = vec4(0.1, 0.1, 0.1, 1.0);
// The word's size in meters.
uniform vec2 meters = vec2(4.0, 1.0);
// How much of the ink is worn through in patches, how much grain there is in what is left, and
// how much of it is left where it has worn least.
uniform float wear = 0.0;
uniform float grain = 0.0;
uniform float strength = 1.0;
// How far apart a display's dots are, and a satin stitch's threads, in meters: 0 for neither.
uniform float dots = 0.0;
uniform float stitch = 0.0;
// How much metal the letters are, and how much light of their own they carry.
uniform float foil = 0.0;
uniform float glow = 0.0;
uniform float seed = 0.0;

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

// How much of something [param per_meter] times a meter fine still shows at this distance:
// none once it is finer than a pixel, rather than a shimmer.
float fine(vec2 m, float per_meter) {
	float across = max(fwidth(m.x), fwidth(m.y)) * per_meter;
	return 1.0 - smoothstep(0.35, 0.8, across);
}

void fragment() {
	vec2 m = UV * meters + vec2(seed * 17.0, seed * 5.0);
	vec2 at = UV;
	float dot_shape = 1.0;
	if (dots > 0.0) {
		// A display is read a dot at a time: each dot is lit by the letters at its middle.
		vec2 cell = floor(UV * meters / dots);
		at = (cell + 0.5) * dots / meters;
		vec2 inside = fract(UV * meters / dots) - 0.5;
		// Dots too fine to tell apart from here run together into the letters they light.
		float apart = fine(m, 1.4 / dots);
		dot_shape = mix(1.0, 1.0 - smoothstep(0.28, 0.44, length(inside)), apart);
		at = mix(UV, at, apart);
	}
	float letters = texture(picture, at).r;
	float under = texture(picture, UV).g;
	float shade = 1.0;
	float kept = 1.0;
	if (wear > 0.0) {
		float patches = noise(m * 1.1) * 0.6 + noise(m * 2.7) * 0.4;
		float rough = noise(m * 9.0);
		kept = 1.0 - smoothstep(1.0 - wear, 1.16 - wear, patches * 0.7 + rough * 0.3);
	}
	if (grain > 0.0) {
		float speck = noise(m * 40.0);
		kept *= 1.0 - grain * fine(m, 40.0) * smoothstep(0.35, 0.75, speck);
	}
	if (stitch > 0.0) {
		// Satin stitch: threads laid on the slant, each catching the light along its middle.
		float thread = 0.5 + 0.5 * sin((m.x + m.y * 0.55) / stitch * 6.2832);
		shade = mix(1.0, 0.72 + 0.34 * thread, fine(m, 1.0 / stitch));
	}
	float word = letters * kept * dot_shape * strength;
	// The dots nobody lit still show on a display, faintly, as they do on a real one.
	float idle = (1.0 - letters) * dot_shape * step(0.0001, dots) * 0.14;
	float alpha = word + under * (1.0 - word);
	vec3 base = plate.rgb + ink.rgb * idle;
	ALBEDO = mix(base, ink.rgb * shade, word / max(alpha, 0.0001));
	ALPHA = clamp(alpha, 0.0, 1.0);
	METALLIC = foil * word;
	ROUGHNESS = mix(0.85, 0.32, foil * word);
	SPECULAR = 0.2 + 0.3 * foil;
	EMISSION = ink.rgb * glow * (word + idle);
}
