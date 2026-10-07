shader_type canvas_item;
// A picture of a card held up a little turned, GAME.md 3.8. The rect stands in for a window the
// card is seen through: a ray from a camera standing back from it goes through each pixel, meets
// the card turned about its middle, and the picture is read where it lands, so the card is seen in
// perspective, its near side a shade lighter and its far side a shade darker. Turned past edge-on,
// the back is in view and the picture is read mirrored, which is how the back of a card reads
// right once it has come round.

// The turn, in radians: x about the upright axis, bringing the right edge forward when positive,
// and y about the level axis, bringing the bottom edge forward when positive.
uniform vec2 turn = vec2(0.0, 0.0);
// Half the picture's width and height, in widths of the card.
uniform vec2 extent = vec2(0.5, 0.3);
// How far back the camera stands, in widths of the card: the nearer, the stronger the perspective.
uniform float depth = 2.4;
// How much lighter the near side is drawn and the far side darker, per width of the card forward.
uniform float relief = 1.8;
// How bright the light is that the card's face catches where it glances straight back to the eye, a
// soft spot of it going over the card as the card turns, the rest of the face a shade dimmer by
// half as much so that white paper shows it too; none on a card with a light of its own. The light
// is up on the left in front, where the spot sits on a card held flat.
uniform float sheen = 0.0;
uniform vec3 light = vec3(-0.15, -0.2, -1.0);
// How tight the spot is: the higher, the smaller and the glossier; low, the light spreads over
// the card the way it does over paper.
uniform float sheen_tight = 36.0;

// The modulate, taken before the texture is read into COLOR at the untouched UV.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 * extent;
	float cy = cos(turn.x);
	float sy = sin(turn.x);
	float cx = cos(turn.y);
	float sx = sin(turn.y);
	// The card's own axes once turned: across it, down it, and out of its back.
	vec3 across = vec3(cy, 0.0, -sy);
	vec3 down = vec3(-sx * sy, cx, -sx * cy);
	vec3 out_of = vec3(cx * sy, sx, cx * cy);
	// The ray from the camera through this pixel of the window, and where it meets the card.
	vec3 eye = vec3(0.0, 0.0, -depth);
	vec3 ray = vec3(p, depth);
	float toward = dot(out_of, ray);
	vec4 drawn = vec4(0.0);
	if (abs(toward) > 0.0001) {
		float t = -dot(out_of, eye) / toward;
		vec3 hit = eye + ray * t;
		vec2 on_card = vec2(dot(hit, across), dot(hit, down));
		if (t > 0.0 && all(lessThan(abs(on_card), extent))) {
			// The back in view reads mirrored.
			if (out_of.z < 0.0) {
				on_card.x = -on_card.x;
			}
			vec2 uv = on_card / (2.0 * extent) + 0.5;
			vec4 picture = texture(TEXTURE, uv);
			float shade = clamp(1.0 - hit.z * relief, 0.72, 1.18);
			drawn = vec4(picture.rgb * shade, picture.a);
			if (sheen > 0.0) {
				// The face toward the eye, and the eye's ray off it: bright where it meets the light.
				vec3 facing = out_of.z < 0.0 ? out_of : -out_of;
				vec3 bounced = reflect(normalize(ray), facing);
				float glance = max(dot(bounced, normalize(light)), 0.0);
				drawn.rgb = drawn.rgb * (1.0 - sheen * 0.5) + vec3(pow(glance, sheen_tight) * sheen);
			}
		}
	}
	COLOR = drawn * tint;
}
