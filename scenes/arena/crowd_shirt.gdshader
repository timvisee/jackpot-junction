// An onlooker's body, GAME.md 8.1: the shirt takes the color rolled for that figure, written
// straight to albedo, which is read as light rather than as a color off a screen, so the values
// in the instance buffer are the linear ones. See crowd_figure.gdshaderinc for the rest.
shader_type spatial;
// Lit by the room, but without the shadow map or a specular term, GAME.md 10.7: nobody in the
// crowd is in a kart's shadow, nothing a dozen pixels tall shows a highlight, and the crowd is a
// third of the screen, so both are a pass over a third of the screen for nothing.
render_mode shadows_disabled, specular_disabled;

#include "res://scenes/arena/crowd_figure.gdshaderinc"

void fragment() {
	ALBEDO = COLOR.rgb * dim;
	EMISSION = rim_color.rgb * rim_of(NORMAL, VIEW) * rim_strength;
}
