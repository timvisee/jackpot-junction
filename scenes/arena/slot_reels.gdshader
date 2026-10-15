// The reels of a slot machine, GAME.md 3.15: three windows side by side on the face of its pad,
// each showing a strip of the six faces turned to where its reel stands. Unshaded, so the reels
// read the same in every room, and one draw for all three.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// The six faces one over another, the first at the top, see SlotPad.Strip.
uniform sampler2D strip : source_color, filter_linear_mipmap, repeat_enable;
// Where each reel stands, in faces from the strip's top: a whole number shows that face square in
// the window, and in between the reel is turning.
uniform vec3 reel_at = vec3(0.0, 1.0, 2.0);
// How fast each reel turns, 0 to 1, for the blur of a reel going round.
uniform vec3 blur = vec3(0.0);
// A win lighting the cabinet up, 0 to 1.
uniform float lit = 0.0;
// The reels that made the win, each 0 to 1: lit up and framed in gold, the rest dimmed.
uniform vec3 won = vec3(0.0);
// A pull made void, 1 to 0: the windows gone dark and red, as a machine that will not pay out.
uniform float voided = 0.0;
uniform vec3 cabinet : source_color = vec3(0.32, 0.05, 0.07);
uniform vec3 trim : source_color = vec3(1.0, 0.76, 0.12);

const float FACES = 6.0;
// How many faces a window shows top to bottom, one whole and a little of each neighbor, so the
// faces stand square in a window about as tall as it is wide.
const float SHOWN = 1.15;
// The cabinet round the windows and between them, as a share of a window's width and of the
// quad's height.
const float SIDE = 0.1;
const float EDGE = 0.13;

vec3 face_at(float x, float y, float at, float smear) {
	float v = (at + 0.5 + (y - 0.5) * SHOWN) / FACES;
	vec3 seen = texture(strip, vec2(x, v)).rgb;
	if (smear > 0.0) {
		float step_v = smear * 0.35 / FACES;
		seen += texture(strip, vec2(x, v - step_v)).rgb;
		seen += texture(strip, vec2(x, v + step_v)).rgb;
		seen /= 3.0;
	}
	return seen;
}

void fragment() {
	float reel_x = UV.x * 3.0;
	int reel = int(clamp(floor(reel_x), 0.0, 2.0));
	float x = fract(reel_x);
	float y = UV.y;
	bool window = abs(x - 0.5) < 0.5 - SIDE * 0.5 && abs(y - 0.5) < 0.5 - EDGE;
	float wins = won[reel];
	float any_won = max(won.x, max(won.y, won.z));
	vec3 color = cabinet;
	if (window) {
		float wx = (x - SIDE * 0.5) / (1.0 - SIDE);
		float wy = (y - EDGE) / (1.0 - EDGE * 2.0);
		color = face_at(wx, wy, reel_at[reel], blur[reel]);
		// The drum curving away at the top and the bottom of the window.
		float round_off = abs(wy - 0.5) * 2.0;
		color *= 1.0 - 0.55 * round_off * round_off;
		color = mix(color, color * 1.25, lit);
		// A reel of the win glows gold in from its edge; the others dim beside it.
		float in_x = min(wx, 1.0 - wx) * 0.74;
		float in_y = min(wy, 1.0 - wy);
		float glow = (1.0 - smoothstep(0.0, 0.14, min(in_x, in_y))) * wins;
		color = mix(color, trim * 1.3, glow * 0.85);
		color = mix(color, color * 0.45, any_won * (1.0 - wins));
		float grey = dot(color, vec3(0.3, 0.59, 0.11));
		color = mix(color, vec3(grey * 0.45, grey * 0.12, grey * 0.1), voided * 0.85);
	} else {
		// A gold line round each window, brighter while the cabinet is lit: how far outside its
		// window, a reel's width being about three quarters of the quad's height.
		float out_x = max(abs(x - 0.5) - (0.5 - SIDE * 0.5), 0.0) * 0.74;
		float out_y = max(abs(y - 0.5) - (0.5 - EDGE), 0.0);
		float line = 1.0 - step(0.025 + 0.035 * wins, length(vec2(out_x, out_y)));
		color = mix(cabinet * (1.0 + lit * 0.8), trim * (1.0 + lit + wins * 0.6), line);
	}
	ALBEDO = color;
}
