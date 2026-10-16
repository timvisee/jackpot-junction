shader_type canvas_item;
// The lip of Kit's line scratched into a license's stripe, STORY.md 6.7, catching the light: a
// glint running along the cuts as the card is turned, the way a scratch in a dark finish lights up
// where its walls face the lamp, and a faint gleam everywhere else. See [LicenseCard].

// Where the card is turned toward, -1 to 1 either way, see [member LicenseCard.tilt].
uniform vec2 tilt = vec2(0.0);
// How wide the scratched line runs, in the layer's own pixels, and how bright the glint is at its
// brightest and between.
uniform float width = 480.0;
uniform float bright = 0.95;
uniform float rest = 0.18;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	// A band of light along the line, where it lies moving with the turn: right as the card turns
	// right, and further along as it tips toward the eye.
	float along = local.x / width;
	float at = 0.5 + tilt.x * 0.9 + tilt.y * 0.35;
	float glint = exp(-pow((along - at) * 4.0, 2.0));
	// Steep strokes face the light as the card tips back and forth.
	float tipped = clamp(abs(tilt.y) * 1.4, 0.0, 1.0);
	COLOR.a *= rest + (bright - rest) * max(glint, tipped * 0.5);
}
