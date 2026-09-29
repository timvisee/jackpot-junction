// An onlooker's head, GAME.md 8.1: the face takes the instance color's alpha, which is how dark
// this one is, so both surfaces are told apart by one instance color. See
// crowd_figure.gdshaderinc for the rest.
shader_type spatial;

#include "res://scenes/arena/crowd_figure.gdshaderinc"

void fragment() {
	ALBEDO = vec3(0.890, 0.768, 0.604) * (1.0 - COLOR.a * 0.62) * dim;
	EMISSION = rim_color.rgb * rim_of(NORMAL, VIEW) * rim_strength;
}
