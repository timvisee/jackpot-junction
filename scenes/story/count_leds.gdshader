// The Count Room's racks, STORY.md 3.9: metal with rows of small lights winking on its faces, each
// light on and off on a time of its own, all of it one material run off the world position, so a
// thousand lights are no node each and a baked rack winks as it did before. Only the upright faces
// carry lights; the tops are bare. Soft and slow rather than busy, GAME.md 8.1: a light fades on
// and off, and lights too small on screen to draw cleanly settle into the steady glow they average
// to, so a rack seen from far off or past a moving camera glows rather than shimmers.
shader_type spatial;
render_mode shadows_disabled, specular_disabled;

uniform vec4 body : source_color = vec4(0.1, 0.11, 0.11, 1.0);
uniform vec4 light : source_color = vec4(0.25, 1.0, 0.4, 1.0);
// Lights to a meter across, and how hard a lit one glows.
uniform float density = 4.0;
uniform float glow = 1.1;
// How many times a second a light may change, at the slowest and the fastest.
uniform float slowest = 0.15;
uniform float fastest = 0.7;
// How big a light is, as a share of its cell, and how much of a change is a fade.
const float RADIUS = 0.2;
const float FADE = 0.3;

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
	vec2 at = along * scale;
	vec2 cell = floor(at);
	vec2 inside = fract(at) - 0.5;
	// Every third row is a unit's lights; the rows between are its blank front.
	float row = step(0.6, fract(cell.y / 3.0));
	// On or off for a while, fading between the two.
	float rate = mix(slowest, fastest, hash(cell + 7.1));
	float phase = TIME * rate + hash(cell) * 10.0;
	float now = step(0.5, hash(cell + floor(phase)));
	float next = step(0.5, hash(cell + floor(phase) + 1.0));
	float on = mix(now, next, smoothstep(1.0 - FADE, 1.0, fract(phase)));
	// How many cells a pixel spans: the light's edge softened over a pixel, and gone over to its
	// average once a light is a pixel or two across.
	float span = max(length(fwidth(at)), 0.0001);
	float d = length(inside * vec2(1.0, 1.6));
	float edge = max(0.03, span * 0.6);
	float spot = 1.0 - smoothstep(RADIUS - edge, RADIUS + edge, d);
	float sharp = spot * on * row;
	float average = 3.14159 * RADIUS * RADIUS / 1.6 * 0.5 / 3.0;
	float lit = mix(sharp, average, smoothstep(0.2, 0.5, span));
	float upright = 1.0 - step(0.5, abs(world_normal.y));
	lit *= upright;
	ALBEDO = mix(body.rgb, light.rgb, lit);
	EMISSION = light.rgb * lit * glow;
	ROUGHNESS = 0.55;
	METALLIC = 0.3;
}
