shader_type canvas_item;

// The shade behind something looked at closer, GAME.md 8.1a: the license, Kit's folder and a note
// held up to the eye. Its own dark eased from clearer round the middle, where what is looked at
// stands, to darker toward the edges and the corners of the screen, the way a lamp over a table
// leaves its corners, rather than one flat gray over everything. The shade's own color and its
// fading in and out, by its modulate, are kept: this only shapes them.

// How much of the shade's dark is left in the middle of the screen, and how much it gathers at the
// corners, over the dark it was given.
uniform float middle = 0.78;
uniform float corners = 1.35;
// How far out from the middle it stays at its clearest, as a share of the way to a corner.
uniform float clear = 0.2;

void fragment() {
	// From the middle of the screen out to its corners, 0 to 1, round on any shape of screen.
	float out_to = length((UV - vec2(0.5)) * 2.0) / sqrt(2.0);
	float dark = mix(middle, corners, smoothstep(clear, 1.0, out_to));
	COLOR.a = clamp(COLOR.a * dark, 0.0, 1.0);
}
