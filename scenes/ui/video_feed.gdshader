// What a close look's picture is drawn through, GAME.md 8.9 and 9.4, see VideoFeed: a feed off a
// camera on the floor rather than a window onto the room. Faint scanlines rolling slowly down it,
// a little grain, the corners darker, red and blue pulled a hair apart toward its edges, and now
// and then a tear, a band of it knocked sideways and jittering for a moment, the colors pulled
// further apart while it lasts; a cut tears it the same way.
shader_type canvas_item;

// How dark a scanline is at its darkest, and how many there are down the picture.
uniform float scanlines = 0.09;
uniform float lines = 210.0;
// How strong the grain is.
uniform float grain = 0.045;
// How far red and blue are pulled apart at the edges, as a share of the picture.
uniform float fringe = 0.004;
// How much darker the corners are.
uniform float vignette = 0.38;
// The tear: how strong it is now, 0 for none, where its band is, 0 the top and 1 the foot, and
// how tall.
uniform float tear = 0.0;
uniform float tear_at = 0.5;
uniform float tear_tall = 0.07;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	// The tear's band knocked sideways, each line of it its own way, changing thirty times a second.
	float band = 1.0 - smoothstep(0.0, tear_tall, abs(uv.y - tear_at));
	float jitter = hash(vec2(floor(uv.y * 90.0), floor(TIME * 30.0))) - 0.5;
	uv.x += tear * band * jitter * 0.12;
	vec2 apart = (uv - vec2(0.5)) * fringe * (1.0 + tear * 8.0);
	vec4 seen = texture(TEXTURE, uv);
	vec3 col = vec3(texture(TEXTURE, uv + apart).r, seen.g, texture(TEXTURE, uv - apart).b);
	float line = 0.5 + 0.5 * sin((uv.y * lines + TIME * 3.0) * 3.14159);
	col *= 1.0 - scanlines * line;
	col += (hash(uv * 640.0 + vec2(fract(TIME * 7.0) * 31.0)) - 0.5) * grain;
	float out_to = length((uv - vec2(0.5)) * vec2(1.0, 0.85));
	col *= 1.0 - vignette * smoothstep(0.3, 0.78, out_to);
	COLOR = vec4(col, 1.0);
}
