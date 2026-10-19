shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Technicolor: the frame as a still from a nineteen-fifties three-strip picture. The camera's three
// negatives, one for each primary, are each purified against the other two and printed in their
// own dye on a steep curve, with a faint black key under them: the primaries deep and pure, the
// reds a rich crimson, the felt an emerald running to teal, the skin and the cream warm, the
// blacks inky. Over it the old lens and the print: the whites glowing softly into what is round
// them, the lights and the shots haloed red-orange where the light scatters back through the
// film, a fine grain dancing at twenty-four frames a second, the frame weaving a hair in the gate,
// and the corners falling off into shadow.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
// How far each primary is purified against the others, in stops.
uniform float separation : hint_range(0.0, 1.0) = 0.4;
// The steepness of each dye's curve.
uniform float density : hint_range(0.5, 1.5) = 0.9;
// How much fuller the colors come out than they went in.
uniform float richness : hint_range(0.0, 1.5) = 0.6;
uniform float glow : hint_range(0.0, 1.0) = 0.45;
uniform float halation : hint_range(0.0, 1.0) = 0.7;
uniform float grain : hint_range(0.0, 0.3) = 0.15;
uniform float weave : hint_range(0.0, 2.0) = 0.7;
uniform float vignette : hint_range(0.0, 1.0) = 0.6;

// The densest a dye is laid, and the light the clear film lets through.
const float DMAX = 2.2;
const float WHITE = 1.6;

vec3 oklab(vec3 c) {
	vec3 lms = vec3(
			dot(c, vec3(0.4122214708, 0.5363325363, 0.0514459929)),
			dot(c, vec3(0.2119034982, 0.6806995451, 0.1073969566)),
			dot(c, vec3(0.0883024619, 0.2817188376, 0.6299787005)));
	lms = pow(max(lms, vec3(0.0)), vec3(1.0 / 3.0));
	return vec3(
			dot(lms, vec3(0.2104542553, 0.7936177850, -0.0040720468)),
			dot(lms, vec3(1.9779984951, -2.4285922050, 0.4505937099)),
			dot(lms, vec3(0.0259040371, 0.7827717662, -0.8086757660)));
}

vec3 linear_of(vec3 lab) {
	vec3 lms = vec3(
			lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z,
			lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z,
			lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z);
	lms = lms * lms * lms;
	return vec3(
			dot(lms, vec3(4.0767416621, -3.3077115913, 0.2309699292)),
			dot(lms, vec3(-1.2684380046, 2.6097574011, -0.3413193965)),
			dot(lms, vec3(-0.0041960863, -0.7034186147, 1.7076147010)));
}

// How near the hue at deg is to the one at center, 1 there and 0 past width either side.
float bell(float deg, float center, float width) {
	float d = abs(mod(deg - center + 180.0, 360.0) - 180.0);
	return 1.0 - smoothstep(0.0, width, d);
}

float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	float a = fract(sin(i * 127.1) * 43758.5453);
	float b = fract(sin((i + 1.0) * 127.1) * 43758.5453);
	return mix(a, b, f * f * (3.0 - 2.0 * f));
}

// Value noise over the plane, for grain that clumps rather than sparkles.
float clump(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// The three-strip print of the light c.
vec3 printed(vec3 c) {
	vec3 lum = vec3(0.2126, 0.7152, 0.0722);
	float y = dot(c, lum);
	// Each negative's exposure in stops from middle gray, a primary that is weaker than the other
	// two pushed weaker still, as the camera's filters kept the records apart.
	vec3 e = log2(max(c, vec3(1e-5)) / 0.18);
	vec3 others = vec3(e.g + e.b, e.r + e.b, e.r + e.g) * 0.5;
	// A near gray, the cream of a wall or a face, is left as it is: only a color already strong is
	// purified.
	float spread = max(max(e.r, e.g), e.b) - min(min(e.r, e.g), e.b);
	e += separation * smoothstep(1.0, 2.5, spread) * min(e - others, vec3(0.0));
	// Each dye laid on its curve, placed so a middle gray prints a middle gray, and the key's black
	// under the shadows.
	float middle = -log(0.18 / WHITE) / log(10.0);
	float e0 = -log(DMAX / middle - 1.0) / density;
	vec3 dye = DMAX / (1.0 + exp(density * (e - e0)));
	float key = 0.4 / (1.0 + exp(1.6 * (log2(max(y, 1e-5) / 0.18) + 3.2)));
	vec3 t = pow(vec3(10.0), -(dye + key)) * WHITE;
	// However inky, the shadows hold what is in them: never darker than half the light they had,
	// so a dark room's table still reads.
	t = max(t, c * 0.5);
	// The dyes' own hues: the reds toward crimson, the greens toward emerald and teal, the yellows
	// toward gold, the blues toward the deep blue of the dye; and the fuller colors fuller still.
	vec3 lab = oklab(t);
	float chroma = length(lab.yz);
	float deg = degrees(atan(lab.z, lab.y));
	float turn = 25.0 * bell(deg, 155.0, 40.0) - 14.0 * bell(deg, 30.0, 26.0)
			- 6.0 * bell(deg, 92.0, 18.0) - 10.0 * bell(deg, 262.0, 35.0);
	float hue = radians(deg + turn);
	chroma *= 1.0 + richness * clamp((chroma - 0.05) / 0.08, 0.0, 1.0);
	lab.yz = chroma * vec2(cos(hue), sin(hue));
	t = max(linear_of(lab), vec3(0.0));
	// The highlights warm, as the print's cream base and the arc lamp make them, and the shadows
	// leaning to the cyan of the dye that lies thickest in them.
	float stops = log2(max(dot(t, lum), 1e-5) / 0.18);
	float high = clamp((stops + 1.0) / 4.0, 0.0, 1.0);
	float low = clamp(-(stops + 1.0) / 4.0, 0.0, 1.0);
	return t * (1.0 + high * vec3(0.04, 0.0, -0.04) + low * vec3(-0.12, 0.0, 0.06));
}

void fragment() {
	vec3 c0 = texture(screen_tex, SCREEN_UV).rgb;
	vec2 px = pixel(VIEWPORT_SIZE);
	float frame = floor(TIME * 24.0);
	// The gate weave: the whole frame drifting a fraction of a pixel, a new place each frame of
	// film, wandering rather than jumping.
	vec2 sway = vec2(noise1(frame * 0.21) - 0.5, noise1(frame * 0.17 + 40.0) - 0.5) * px * weave * 1.6;
	vec2 uv = SCREEN_UV + sway;
	// The old lens and the print a generation or two from the negative: never quite as sharp as the
	// frame, and the whites glowing softly into what is round them.
	vec3 c = mix(texture(screen_tex, uv).rgb, textureLod(screen_mip, uv, 1.0).rgb, 0.35);
	vec3 soft = textureLod(screen_mip, uv, 3.5).rgb;
	c += max(soft - vec3(0.5), vec3(0.0)) * glow;
	c = printed(c);
	// Halation: the lights and the shots haloed red-orange, where their light is scattered back off
	// the film's base through its red layer.
	vec3 lum = vec3(0.3, 0.55, 0.15);
	float tight = max(dot(textureLod(screen_mip, uv, 1.5).rgb, lum) - 0.8, 0.0);
	float near = max(dot(textureLod(screen_mip, uv, 3.0).rgb, lum) - 0.6, 0.0);
	float far = max(dot(textureLod(screen_mip, uv, 4.5).rgb, lum) - 0.5, 0.0);
	c += vec3(1.0, 0.25, 0.06) * (tight * 0.35 + near * 0.5 + far * 0.4) * halation;
	// The grain: clumps of dye, each layer's a little apart, heaviest in the middle tones.
	vec2 gp = SCREEN_UV / px / 1.4 + vec2(frame * 17.31, frame * 7.77);
	float g = clump(gp) - 0.5;
	vec3 dyes = vec3(clump(gp + 3.1), clump(gp + 7.3), clump(gp + 11.9)) - 0.5;
	float tone = pow(clamp(dot(c, vec3(0.2126, 0.7152, 0.0722)), 0.0, 1.0), 1.0 / 2.2);
	float middle_tones = 0.3 + 0.7 * clamp(1.0 - abs(tone - 0.45) * 1.7, 0.0, 1.0);
	c *= 1.0 + (g * 0.8 + dyes * 0.45) * grain * 2.0 * middle_tones;
	// The lens: the corners falling off into shadow, round rather than square.
	vec2 q = (SCREEN_UV - 0.5) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
	c *= 1.0 - vignette * smoothstep(0.3, 1.1, length(q));
	// Dust on the print: now and then a speck or two, each there for one frame only.
	for (int i = 0; i < 3; i++) {
		float k = frame * 3.0 + float(i);
		vec2 at = vec2(hash(vec2(k, 1.7)), hash(vec2(k, 9.2)));
		float size = (1.0 + 2.5 * hash(vec2(k, 4.4))) * px.y;
		float shown_now = step(0.55, hash(vec2(k, 6.1)));
		vec2 d = (SCREEN_UV - at) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
		c *= 1.0 - 0.75 * shown_now * (1.0 - smoothstep(size * 0.5, size, length(d)));
	}
	// The projector's lamp is never quite steady.
	c *= 1.0 + (noise1(frame * 0.9) - 0.5) * 0.03;
	ALBEDO = mix(c0, c, amount);
}
