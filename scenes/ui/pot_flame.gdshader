shader_type canvas_item;

uniform vec4 heart : source_color = vec4(1.0);
uniform vec4 core : source_color = vec4(1.0);
uniform vec4 body : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform vec4 rim : source_color = vec4(0.7, 0.1, 0.05, 1.0);
// How big the sheet is on the screen, in pixels, for the embers to be round and of a size.
uniform vec2 pixels = vec2(120.0, 72.0);
uniform float seed = 0.0;
uniform float heat = 1.0;
// Seconds the fire has burned, kept small by the node rather than taken from the engine's clock,
// which grows for as long as the game runs.
uniform float clock = 0.0;
// Where the top of the pill is, measured up from the foot of the sheet, for the embers to start;
// how tall the sheet is, in pill heights; how far below its top the fire has gone out, in pill
// heights; and how much of the sheet's width lies either side of the pill, room to sway into.
uniform float lip = 0.36;
uniform float span = 2.65;
uniform float fade = 0.8;
uniform float margin = 0.15;

// A number from 0 to 1 for each point of the noise's grid, worked without a sine: the usual
// sine hash loses its precision as its input grows, and repeats down whole rows of the grid,
// which the fire scrolling upward carried up the screen as lines.
float hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	// Eased in and out to the second degree, so nothing of the grid shows as a crease.
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x);
	float b = mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x);
	return mix(a, b, u.y);
}

// Noise over a few octaves: three, so the shapes it cuts are broad and their bands nest one
// inside another as a flame's do, rather than breaking up into speckle. Each octave is turned
// against the one before, so the rows of their grids never line up into a seam.
float fbm(vec2 p) {
	float sum = 0.0;
	float weight = 0.5;
	mat2 turn = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int octave = 0; octave < 3; octave++) {
		sum += weight * noise(p);
		p = turn * p * 2.0 + vec2(17.3, 9.1);
		weight *= 0.5;
	}
	return sum;
}

// A few embers climbing out of the top of the fire, small round sparks fading as they go: how
// much of one covers this point, and how hot it still is.
vec2 embers(vec2 uv, float t) {
	vec2 lit = vec2(0.0);
	for (int k = 0; k < 5; k++) {
		float fk = float(k);
		float pace = 0.35 + 0.3 * hash(vec2(fk, seed));
		float age = t * pace + hash(vec2(fk + 7.0, seed));
		float life = fract(age);
		float x = 0.2 + 0.6 * hash(vec2(fk + 3.0, floor(age) + seed));
		x += sin(t * 3.0 + fk * 2.0) * 0.04;
		float up = lip + life * (1.0 - lip);
		float along = margin + x * (1.0 - 2.0 * margin);
		float away = length((vec2(along, 1.0 - up) - uv) * pixels);
		float cover = 1.0 - smoothstep(1.2, 2.2, away);
		if (cover > lit.x) {
			lit = vec2(cover, 1.0 - life);
		}
	}
	return lit;
}

void fragment() {
	vec2 uv = UV;
	float t = clock + seed;
	float rise = 1.0 - uv.y;
	// How high up, in pill heights from the foot of the sheet, and where along the pill, 0 at one
	// end and 1 at the other, however much room the sheet has round it.
	float above = rise * span;
	float across = (uv.x - margin) / (1.0 - 2.0 * margin);
	// Pushed side to side the more the higher up, as a flame is and a wall is not.
	float sway = (noise(vec2(rise * 3.0 - t * 1.6, seed)) - 0.5) * 0.3 * rise;
	vec2 p = vec2(across + sway, uv.y);
	// The noise the fire is cut from, rolling upward and folded over itself.
	// Finer across than up, so what it cuts are tall narrow tongues rather than round blobs.
	vec2 rolling = vec2(p.x * 4.8 + seed, p.y * 2.0 + t * 2.8);
	float fold = fbm(rolling * 0.6 + vec2(seed, -t * 0.7));
	float churn = fbm(rolling + vec2(fold * 1.4, 0.0));
	// The churn less a fall-off with height: where it runs high the fire reaches up in a tongue,
	// and where it runs low there is none, so the tongues are the noise's own and rise with it.
	// Crowned, tallest over the middle of the pill, and kept off its ends.
	float crown = 0.85 + 0.15 * sin(PI * clamp(p.x, 0.0, 1.0));
	float fire = (churn - 0.3) * 3.2 * crown - above * 0.45 / max(heat, 0.01) + 0.76;
	fire *= smoothstep(-0.08, 0.12, p.x) * smoothstep(1.08, 0.88, p.x);
	// Thinning to nothing well short of the top of the sheet, so a tongue climbing that high burns
	// out on the way rather than being cut off flat.
	fire -= smoothstep(span - fade, span - 0.1, above) * 1.6;
	// Each band over the one round it, its edge softened over about a pixel so it is clean
	// rather than stepped, however the fire is moving.
	float edge = max(fwidth(fire), 0.001);
	vec4 color = vec4(rim.rgb, smoothstep(0.32 - edge, 0.32 + edge, fire));
	color = mix(color, body, smoothstep(0.52 - edge, 0.52 + edge, fire));
	color = mix(color, core, smoothstep(0.85 - edge, 0.85 + edge, fire));
	color = mix(color, heart, smoothstep(1.15 - edge, 1.15 + edge, fire));
	vec2 ember = embers(uv, t);
	vec4 spark = vec4(mix(body.rgb, core.rgb, step(0.55, ember.y)), ember.x);
	color = mix(spark, color, color.a);
	// And gone before any edge of the sheet whatever the fire does.
	float room = smoothstep(0.0, margin * 0.5, uv.x) * smoothstep(1.0, 1.0 - margin * 0.5, uv.x);
	color.a *= room * (1.0 - smoothstep(span - 0.2, span - 0.02, above));
	COLOR = color;
}
