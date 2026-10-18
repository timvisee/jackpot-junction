// An onlooker's head, GAME.md 8.1: the face takes the instance color's alpha, which is how dark
// this one is, so both surfaces are told apart by one instance color. See
// crowd_figure.gdshaderinc for the rest.
shader_type spatial;
// Lit by the room, but without the shadow map or a specular term, GAME.md 10.7: nobody in the
// crowd is in a kart's shadow, nothing a dozen pixels tall shows a highlight, and the crowd is a
// third of the screen, so both are a pass over a third of the screen for nothing.
render_mode shadows_disabled, specular_disabled, cull_disabled;

#include "res://scenes/arena/crowd_figure.gdshaderinc"

void fragment() {
	// The face in its own shade, a printed cap of hair over it, or the cream card round it.
	vec3 skin = vec3(0.890, 0.768, 0.604) * (1.0 - COLOR.a * 0.62);
	vec3 hair = vec3(0.16, 0.12, 0.1) + COLOR.rgb * 0.12;
	vec3 printed = doll.y > 0.605 + 0.02 * sin(doll.x * 40.0) ? hair : skin;
	ALBEDO = mix(printed, vec3(0.86, 0.82, 0.72), UV.x) * dim;
	EMISSION = rim_color.rgb * rim_of(NORMAL, VIEW) * rim_strength;
}
