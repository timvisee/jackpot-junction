// The toy kart on the loyalty program's map as a paper cut-out lying on it, GAME.md 8.9: its
// colors flattened to a few printed tones, a border of paper round its outline with a thin ink
// edge, a fine grain, and its shadow on the map under it. Over the kart's own sheet, see
// [LoyaltyCursor].
shader_type canvas_item;

// The paper round the kart and the ink round that, in the sheet's pixels; how far the shadow falls
// and how dark it is; the paper's and the ink's colors; and how many tones a color is printed in.
uniform float border = 4.0;
uniform float ink_edge = 1.4;
uniform vec2 shadow_offset = vec2(3.0, 5.0);
uniform float shadow = 0.3;
uniform vec4 paper : source_color = vec4(0.97, 0.95, 0.89, 1.0);
uniform vec4 ink : source_color = vec4(0.14, 0.13, 0.15, 1.0);
uniform float tones = 4.0;

// The most cover of the sheet within [radius] pixels of [uv], round a ring.
float cover_near(sampler2D sheet, vec2 uv, vec2 pixel, float radius) {
	float most = texture(sheet, uv).a;
	for (int i = 0; i < 16; i++) {
		float angle = float(i) * 6.2831853 / 16.0;
		vec2 step_to = vec2(cos(angle), sin(angle)) * radius * pixel;
		most = max(most, texture(sheet, uv + step_to).a);
		most = max(most, texture(sheet, uv + step_to * 0.5).a);
	}
	return most;
}

float grain_at(vec2 cell) {
	return fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 pixel = TEXTURE_PIXEL_SIZE;
	vec4 own = texture(TEXTURE, UV);
	float inside = smoothstep(0.35, 0.65, own.a);
	float cut = max(inside, smoothstep(0.25, 0.6, cover_near(TEXTURE, UV, pixel, border)));
	float outer = smoothstep(0.25, 0.6, cover_near(TEXTURE, UV, pixel, border + ink_edge));
	float edge = clamp(outer - cut, 0.0, 1.0);
	vec2 under = UV - shadow_offset * pixel;
	float fallen = smoothstep(0.25, 0.6, cover_near(TEXTURE, under, pixel, border)) * shadow;
	// Printed in a few tones: the brightness stepped, the hue kept.
	float bright = dot(own.rgb, vec3(0.299, 0.587, 0.114));
	float stepped = (floor(bright * tones) + 0.6) / tones;
	vec3 printed = clamp(own.rgb * (stepped / max(bright, 0.001)), 0.0, 1.0);
	vec3 color = mix(paper.rgb, printed, inside);
	color += (grain_at(floor(UV / pixel)) - 0.5) * 0.05;
	vec4 shown = vec4(0.0, 0.0, 0.0, fallen);
	shown = mix(shown, vec4(color, 1.0), cut);
	shown = mix(shown, vec4(ink.rgb, 1.0), edge * 0.85);
	COLOR = shown;
}
