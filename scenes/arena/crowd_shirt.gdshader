// An onlooker's body, GAME.md 8.1: the shirt takes the color rolled for that figure, written
// straight to albedo, which is read as light rather than as a color off a screen, so the values
// in the instance buffer are the linear ones. See crowd_figure.gdshaderinc for the rest.
shader_type spatial;

#include "res://scenes/arena/crowd_figure.gdshaderinc"

void fragment() {
	ALBEDO = COLOR.rgb * dim;
	EMISSION = rim_color.rgb * rim_of(NORMAL, VIEW) * rim_strength;
}
