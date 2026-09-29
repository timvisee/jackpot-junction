// One segment of the clock board, GAME.md 8.1, drawn as an instance of the board's one
// MultiMesh: every segment of the four digits and the colon is the same bar, placed, sized and
// colored per instance, so the whole display is one thing to draw rather than thirty, GAME.md
// 10.7. The instance color is the color a lit segment shows, and the first custom value says
// whether it is lit: dark segments show the board's own dark faintly, so the display reads as
// a board with segments rather than as bars floating in the air.
shader_type spatial;

uniform vec3 dark : source_color = vec3(0.14, 0.12, 0.1);
// How hard a lit segment glows, from the room's neon level.
uniform float glow = 1.6;

varying float lit;

void vertex() {
	lit = INSTANCE_CUSTOM.x;
}

void fragment() {
	ALBEDO = mix(dark, COLOR.rgb, lit);
	EMISSION = COLOR.rgb * glow * lit;
	ROUGHNESS = 0.6;
}
