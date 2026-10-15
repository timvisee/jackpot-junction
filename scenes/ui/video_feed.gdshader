// What a close look's picture is drawn through, GAME.md 8.9 and 9.4, see VideoFeed: a feed off a
// camera on the floor rather than a window onto the room. Faint scanlines rolling slowly down it,
// a little grain, the corners darker, red and blue pulled a hair apart toward its edges, and now
// and then a tear, a band of it knocked sideways and jittering for a moment, the colors pulled
// further apart while it lasts. Coming on and at a cut it is snow and a flash for a moment, and its
// focus hunts as it comes on. A feed may be tinted, as a security camera's green. Its corners are
// rounded, for the bezel round it to show at them.
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
// Snow over the picture, 0 none and 1 nothing but; a white flash over it; and how far out of focus
// it is, 0 sharp.
uniform float snow = 0.0;
uniform float flash = 0.0;
uniform float blur = 0.0;
// A tint, how much of it, and its color, the picture's own light kept.
uniform float tint = 0.0;
uniform vec3 tint_ink : source_color = vec3(0.86, 1.0, 0.9);
// The picture's size in pixels, and how round its corners are in them.
uniform vec2 pixels = vec2(520.0, 330.0);
uniform float corner = 7.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec3 seen_at(sampler2D picture, vec2 uv, vec2 apart, float spread) {
	// In focus, which is all but the first moment, one look rather than five.
	if (spread <= 0.0) {
		return vec3(
			texture(picture, uv + apart).r, texture(picture, uv).g, texture(picture, uv - apart).b
		);
	}
	vec3 col = vec3(0.0);
	// Out of focus, five looks spread round the point and averaged; in focus they are one.
	for (int i = 0; i < 5; i++) {
		float turn = float(i) * 1.2566;
		vec2 by = i == 0 ? vec2(0.0) : vec2(cos(turn), sin(turn)) * spread;
		col += vec3(
			texture(picture, uv + by + apart).r,
			texture(picture, uv + by).g,
			texture(picture, uv + by - apart).b
		);
	}
	return col / 5.0;
}

void fragment() {
	vec2 uv = UV;
	// The tear's band knocked sideways, each line of it its own way, changing thirty times a second.
	float band = 1.0 - smoothstep(0.0, tear_tall, abs(uv.y - tear_at));
	float jitter = hash(vec2(floor(uv.y * 90.0), floor(TIME * 30.0))) - 0.5;
	uv.x += tear * band * jitter * 0.12;
	vec2 apart = (uv - vec2(0.5)) * fringe * (1.0 + tear * 8.0);
	vec3 col = seen_at(TEXTURE, uv, apart, blur * 0.012);
	float light = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, light * tint_ink, tint);
	float line = 0.5 + 0.5 * sin((uv.y * lines + TIME * 3.0) * 3.14159);
	col *= 1.0 - scanlines * line;
	col += (hash(uv * 640.0 + vec2(fract(TIME * 7.0) * 31.0)) - 0.5) * grain;
	float out_to = length((uv - vec2(0.5)) * vec2(1.0, 0.85));
	col *= 1.0 - vignette * smoothstep(0.3, 0.78, out_to);
	float noise = hash(floor(UV * pixels * 0.5) + vec2(floor(TIME * 40.0) * 17.0, 3.0));
	col = mix(col, vec3(noise * 0.9), snow);
	col += vec3(flash);
	// Rounded corners, the bezel round the picture showing at them.
	vec2 from_middle = abs(UV - vec2(0.5)) * pixels;
	vec2 into = from_middle - (pixels * 0.5 - vec2(corner));
	float outside = length(max(into, vec2(0.0))) - corner;
	float alpha = 1.0 - smoothstep(-1.0, 0.5, outside);
	COLOR = vec4(col, alpha);
}
