// The House's forecast of the candidate at the Final Hand, STORY.md 8.2, as if thrown onto the floor
// by a projector out of the dark over the racks, see [ForecastLine]: soft at its edges and widening
// as it runs ahead, a cone of where the kart may be rather than a line it will keep to; lines of the
// projector's scan running out along it, a flicker and a grain to its light, and the whole of it
// stuttering for a moment when the forecast has to be thrown again.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 ink : source_color = vec4(1.0, 0.88, 0.58, 1.0);
uniform vec4 edge : source_color = vec4(0.96, 0.68, 0.32, 1.0);
// How far the line runs, in meters, its UV.x being meters out from the kart; how bright it is; and
// how much it stutters, 0 to 1.
uniform float reach = 10.0;
uniform float strength = 1.0;
uniform float glitch = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float along = UV.x;
	float share = clamp(along / max(reach, 0.01), 0.0, 1.0);
	float across = abs(UV.y - 0.5) * 2.0;
	// A soft wash of light, with no edge to it and no line down its middle.
	float wash = exp(-pow(across / 0.62, 2.0));
	// The projector's raster: bars across it running out from the kart, crisp in the middle and
	// fraying at the sides.
	float bar = fract(along * 2.6 - TIME * 2.2);
	float bars = smoothstep(0.0, 0.06, bar) * (1.0 - smoothstep(0.1, 0.24, bar));
	bars *= 1.0 - smoothstep(0.55, 1.0, across);
	// Nothing at the kart, firmer as it runs out, and gone again off its far end.
	float lengthwise = smoothstep(0.0, 0.25, share) * (0.45 + 0.55 * share);
	lengthwise *= 1.0 - smoothstep(0.84, 1.0, share);
	float flicker = 0.9 + 0.1 * sin(TIME * 47.0) * sin(TIME * 11.0);
	float grain = 0.75 + 0.5 * hash(floor(UV * vec2(24.0, 12.0)) + floor(TIME * 18.0));
	float stutter = 1.0 - glitch * step(0.45, hash(vec2(floor(TIME * 32.0), floor(along * 2.0))));
	ALBEDO = mix(edge.rgb, ink.rgb, wash);
	float light = wash * 0.22 + bars * 0.55;
	ALPHA = clamp(light * lengthwise * flicker * grain * stutter * strength, 0.0, 1.0);
}
