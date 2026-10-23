shader_type spatial;
// A force field round the kart, GAME.md 6.1: clear in the middle and bright at its rim, where the
// sphere turns away from the eye, with a band sweeping up it and a slow pulse, so it reads as a
// live shield rather than a tinted marble. Unshaded and glowing, so the bloom carries the rim; it
// writes no depth and casts no shadow, as a bubble should not.
render_mode blend_mix, cull_disabled, unshaded, shadows_disabled, depth_draw_never;

uniform vec4 color : source_color = vec4(0.32, 0.8, 1.0, 0.9);
// How sharply the glow gathers at the rim, how fast it pulses, and how fast the band sweeps up.
uniform float rim : hint_range(0.5, 6.0) = 2.2;
uniform float pulse_speed = 2.4;
uniform float band_speed = 5.0;

void fragment() {
	// Bright where the surface grazes the eye, near-clear where it faces it.
	float edge = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), rim);
	// A ring of light sweeping up the bubble, and the whole thing breathing.
	float band = 0.5 + 0.5 * sin(UV.y * 34.0 - TIME * band_speed);
	float pulse = 0.78 + 0.22 * sin(TIME * pulse_speed);
	float lit = edge * pulse + band * (0.07 + 0.18 * edge);
	ALBEDO = color.rgb;
	EMISSION = color.rgb * (edge * 1.7 + band * 0.25) * pulse;
	ALPHA = clamp(lit, 0.0, 1.0) * color.a;
}
