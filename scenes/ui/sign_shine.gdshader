// The shine across a hand's sign as its name is stamped in, GAME.md 7.3, see SuitedSign: a soft
// slanted band of light, fading out to either side, lighting only what the sign draws that is
// light enough to catch it, its cream cards and gold word, so no box of it shows round them.
shader_type canvas_item;

// The band's middle across the sign, in its own units at its top, how wide it is to either side,
// how far it leans, and how strongly it shows, 0 to 1.
uniform float at = -100.0;
uniform float reach = 16.0;
uniform float lean = 0.4;
uniform float strength = 0.0;
// The sign's own space from the canvas's, the inverse of its place on it.
uniform vec2 inv_x = vec2(1.0, 0.0);
uniform vec2 inv_y = vec2(0.0, 1.0);
uniform vec2 inv_origin = vec2(0.0);

varying vec2 on_sign;

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	on_sign = inv_x * world.x + inv_y * world.y + inv_origin;
}

void fragment() {
	float across = abs(on_sign.x + on_sign.y * lean - at);
	float band = 1.0 - smoothstep(0.0, reach, across);
	band *= band;
	float light = max(COLOR.r, max(COLOR.g, COLOR.b));
	float catches = smoothstep(0.15, 0.5, light);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.97, 0.86), band * strength * catches * 0.85);
}
