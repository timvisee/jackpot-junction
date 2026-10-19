shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Tape: the frame played back off a worn video cassette. The tape keeps the brightness at a third
// of the screen's sharpness and the color at a tenth of it, so the color smears to the right of
// what it belongs to and sits a little late; the deck sharpens the brightness back up, leaving a
// bright ring to one side of every edge. The colors run hot and the blacks stay deep. The lines
// wobble a little across, a band of tracking noise rolls slowly down the picture, and at the foot
// the heads switch, tearing the last few lines sideways.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
// How far, in screen pixels at 1080 lines, the color lags behind the brightness.
uniform float lag : hint_range(0.0, 12.0) = 5.0;
// How hot the color runs.
uniform float saturation : hint_range(0.5, 2.0) = 1.6;
// How much the tape is worn: the tracking noise, the wobble, the snow.
uniform float wear : hint_range(0.0, 1.0) = 0.6;

const mat3 TO_YIQ = mat3(
		vec3(0.299, 0.596, 0.211),
		vec3(0.587, -0.274, -0.523),
		vec3(0.114, -0.322, 0.312));
const mat3 FROM_YIQ = mat3(
		vec3(1.0, 1.0, 1.0),
		vec3(0.956, -0.272, -1.106),
		vec3(0.621, -0.647, 1.703));

float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	float a = fract(sin(i * 127.1) * 43758.5453);
	float b = fract(sin((i + 1.0) * 127.1) * 43758.5453);
	return mix(a, b, f * f * (3.0 - 2.0 * f));
}

// The picture as the tape holds it, in YIQ, gamma encoded the way video is.
vec3 yiq_at(vec2 uv, float lod) {
	vec3 c = textureLod(screen_mip, uv, lod).rgb;
	c = pow(clamp(c, 0.0, 8.0) / (1.0 + clamp(c, 0.0, 8.0) * 0.15), vec3(1.0 / 2.2));
	return TO_YIQ * c;
}

void fragment() {
	vec3 c0 = texture(screen_tex, SCREEN_UV).rgb;
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	float t = TIME;
	// The line the beam is on, at the tape's own count of lines.
	float line = floor(uv.y * 480.0);
	// The tracking band: a soft stripe that rolls slowly down the picture, out of it at the foot,
	// and in again at the top a while later.
	float band_at = fract(t * 0.035) * 1.6 - 0.3;
	float band = smoothstep(0.06, 0.0, abs(uv.y - band_at)) * wear;
	// The head switch: the last few lines at the foot of the picture are torn to the side.
	float foot = smoothstep(0.975, 0.995, uv.y) * wear;
	float jitter = (noise1(line * 0.7 + t * 37.0) - 0.5) * 2.0;
	float shift = jitter * px.x * (0.6 * wear + 11.0 * band) + foot * px.x * (18.0 + 10.0 * jitter);
	// A slow wobble of the whole picture across, as the tape's speed wavers.
	shift += sin(uv.y * 7.0 + t * 1.3) * px.x * 0.8 * wear + (noise1(t * 2.1) - 0.5) * px.x * 1.2 * wear;
	uv.x += shift;
	// The brightness, soft across: a few taps along the line, and a wider look for the deck's
	// sharpening to push against, which leaves a bright ring trailing each edge.
	float y = 0.0;
	float wide = 0.0;
	for (int i = -2; i <= 2; i++) {
		float w = i == 0 ? 0.36 : (abs(i) == 1 ? 0.22 : 0.1);
		y += yiq_at(uv + vec2(float(i) * px.x * 0.9, 0.0), 0.0).x * w;
	}
	for (int i = -1; i <= 1; i++) {
		wide += yiq_at(uv + vec2(float(i) * px.x * 5.0 - px.x * 1.5, 0.0), 1.5).x / 3.0;
	}
	y += (y - wide) * 0.9;
	// The color, far softer and a little late: taken off the frame shrunk four times, along the line.
	vec2 iq = vec2(0.0);
	for (int i = -2; i <= 2; i++) {
		iq += yiq_at(uv + vec2((float(i) * 3.5 - lag) * px.x, 0.0), 1.8).yz;
	}
	iq /= 5.0;
	// Chroma noise: the color crawls in faint streaks along the lines.
	float streak = noise1(uv.x * 40.0 + line * 13.7 + floor(t * 30.0) * 7.0) - 0.5;
	iq += vec2(streak, -streak * 0.7) * 0.03 * wear;
	iq *= saturation;
	// Snow: fine noise in the brightness, heavier in the tracking band, with white flecks there.
	float snow = hash(floor(SCREEN_UV / px * vec2(0.5, 1.0)) + fract(t * 60.0) * 91.0) - 0.5;
	y += snow * (0.025 + 0.25 * band) * wear;
	// The tracking band's streaks: white runs of uneven length along a line, as the heads lose the
	// track; and now and then a dropout anywhere, where the tape has lost its oxide.
	float frame = floor(t * 30.0);
	float run = noise1(uv.x / px.x * 0.025 + line * 7.31 + frame * 13.7);
	float on_line = step(0.55, hash(vec2(line, frame)));
	float streak_white = smoothstep(0.72, 0.8, run) * on_line * band;
	float dropout = smoothstep(0.9, 0.95, noise1(uv.x / px.x * 0.01 + line * 3.1 + frame * 5.3))
			* step(0.9985, hash(vec2(line * 0.37, frame))) * wear;
	y = mix(y, 0.92, max(streak_white, dropout));
	y = mix(y, y * 0.7 + 0.12, foot);
	vec3 rgb = FROM_YIQ * vec3(y, iq);
	// Back out of the video's encoding to the frame's own light, the highlights let out again.
	rgb = pow(clamp(rgb, 0.0, 1.6), vec3(2.2));
	rgb = rgb / max(1.0 - rgb * 0.15, vec3(0.1));
	// The tape's red runs a touch warm.
	rgb *= vec3(1.03, 1.0, 0.97);
	ALBEDO = mix(c0, rgb, amount);
}
