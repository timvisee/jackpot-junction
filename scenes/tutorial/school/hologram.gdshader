shader_type canvas_item;
// The hologram on the back of the license, GAME.md 9.4a: a disc of silvered foil whose colors run
// round and through as the card is tilted, since the color a foil throws back hangs on the angle
// it is seen at, fine rings engraved under them that glitter as the view slides over, the game's
// mark raised in the middle in a foil of its own, and a glint where the light catches the disc,
// which moves over it only as the card moves. Lying still, the colors drift, slowly.

// Where the card is turned toward, -1 to 1 either way, see TiltedCard.
uniform vec2 tilt = vec2(0.0, 0.0);
// The game's mark, on clear, and how much of the disc's width it takes.
uniform sampler2D mark : filter_linear, repeat_disable;
uniform float mark_share = 0.42;
// Turns of the colors a second while the card lies still.
uniform float drift = 0.02;

// The modulate, taken before the texture is read into COLOR.
varying vec4 tint;

vec3 foil(float phase) {
	return 0.5 + 0.5 * cos(6.28318 * (phase + vec3(0.0, 0.333, 0.667)));
}

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 p = UV - 0.5;
	float r = length(p) * 2.0;
	float disc = 1.0 - smoothstep(0.97, 1.0, r);
	float view = tilt.x * 1.1 - tilt.y * 0.7 + TIME * drift;
	float angle = atan(p.y, p.x);
	// Broad bands running outward, crossed by a slow weave, every phase sliding with the view.
	float weave = sin(p.x * 17.0 + view * 4.0) * sin(p.y * 17.0 - view * 3.0);
	float phase = r * 1.3 - view * 1.5 + 0.1 * sin(angle * 5.0 + view * 2.0) + 0.12 * weave;
	vec3 color = foil(phase);
	// Silvered: pale, as foil is, the colors a sheen over it rather than paint.
	vec3 silver = vec3(0.84, 0.86, 0.9);
	color = mix(color, silver, 0.5);
	// The engraving: fine rings, glittering as the view slides over them.
	float rings = 0.5 + 0.5 * sin(r * 150.0 + view * 30.0);
	color += (rings * rings - 0.3) * 0.1;
	// The mark, raised in a brighter foil half a turn on, its own light and shade in it.
	vec2 m = p / mark_share + 0.5;
	float in_mark = step(abs(m.x - 0.5), 0.5) * step(abs(m.y - 0.5), 0.5);
	vec4 emblem = texture(mark, clamp(m, 0.0, 1.0)) * in_mark;
	float lum = dot(emblem.rgb, vec3(0.3, 0.59, 0.11));
	vec3 raised = mix(foil(phase + 0.5 + lum * 0.3), vec3(1.0), 0.5) * (0.55 + 0.8 * lum);
	color = mix(color, raised, emblem.a);
	// The glint, where the light catches the disc for this turn of the card.
	vec2 light = vec2(-0.18, -0.22) - tilt * 0.26;
	float glint = exp(-dot(p - light, p - light) * 24.0);
	color += glint * 0.25;
	// The rim, a shade darker, so the disc sits in the paper.
	color = mix(color, vec3(0.3, 0.3, 0.34), smoothstep(0.9, 1.0, r) * 0.4);
	COLOR = vec4(color, disc * 0.94) * tint;
}
