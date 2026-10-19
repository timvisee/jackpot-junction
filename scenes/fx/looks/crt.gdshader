shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Arcade screen: the frame on an arcade cabinet's tube. The picture is drawn line by line by the
// beam, about two hundred and fifty lines down the screen with dark between them and the bright
// lines swelling into the dark; through an aperture grille of red, green and blue stripes; on glass
// bowed a little, so the corners round off into the dark of the bezel; the three guns a little out
// of convergence toward the sides; and the phosphor glowing into the glass round the bright parts.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
// How far the glass bows, at the corners.
uniform float bow : hint_range(0.0, 0.15) = 0.045;
// How strongly the grille's stripes show.
uniform float grille : hint_range(0.0, 1.0) = 0.45;
// How dark the gap between two lines goes, 0 for none.
uniform float gaps : hint_range(0.0, 1.0) = 0.7;
uniform float glow : hint_range(0.0, 1.0) = 0.3;

// The picture as the beam draws it along line y, at x: softened across, as the signal's bandwidth
// softens it, and the three guns each landing a little apart.
vec3 line_at(float x, float y, vec2 px, float spread) {
	vec2 h = vec2(px.x * 0.9, 0.0);
	vec2 at = vec2(x, y);
	vec2 split = vec2(px.x * spread, 0.0);
	float r = texture(screen_tex, at + split).r * 0.5
		+ texture(screen_tex, at + split - h).r * 0.25 + texture(screen_tex, at + split + h).r * 0.25;
	float g = texture(screen_tex, at).g * 0.5
		+ texture(screen_tex, at - h).g * 0.25 + texture(screen_tex, at + h).g * 0.25;
	float b = texture(screen_tex, at - split).b * 0.5
		+ texture(screen_tex, at - split - h).b * 0.25 + texture(screen_tex, at - split + h).b * 0.25;
	return vec3(r, g, b);
}

// How much light a line at distance d, in lines, puts on the point: the beam's spot is a soft
// round, wider for a brighter line, as a hotter beam blooms.
vec3 beam(float d, vec3 c) {
	vec3 bright = clamp(pow(clamp(c, 0.0, 4.0), vec3(0.5)), 0.0, 1.2);
	vec3 width = mix(vec3(0.24), vec3(0.42), bright / 1.2);
	vec3 w = d / width;
	return exp2(-w * w) / (0.6 + 0.4 * width / 0.42);
}

void fragment() {
	vec3 c0 = texture(screen_tex, SCREEN_UV).rgb;
	vec2 px = pixel(VIEWPORT_SIZE);
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	// The bowed glass: each point of the screen looks onto the picture a little further out than
	// it stands, more so toward the corners.
	vec2 q = SCREEN_UV * 2.0 - 1.0;
	vec2 bend = vec2(bow, bow * aspect * 0.6);
	q *= 1.0 + bend * q.yx * q.yx;
	vec2 uv = q * 0.5 + 0.5;
	// The lines: a whole number of screen pixels each, so they never beat against the pixels.
	float pitch = max(3.0, floor(VIEWPORT_SIZE.y / 256.0 + 0.5));
	float pitch_uv = pitch / VIEWPORT_SIZE.y;
	float y_line = uv.y / pitch_uv - 0.5;
	float n = floor(y_line);
	float f = y_line - n;
	float spread = 0.35 + 1.3 * abs(q.x);
	vec3 a = line_at(uv.x, (n + 0.5) * pitch_uv, px, spread);
	vec3 b = line_at(uv.x, (n + 1.5) * pitch_uv, px, spread);
	vec3 lit = a * beam(f, a) + b * beam(1.0 - f, b);
	lit = mix(mix(a, b, f), lit, gaps);
	// The aperture grille: stripes of red, green and blue phosphor a screen pixel wide each.
	float stripe = floor(SCREEN_UV.x * VIEWPORT_SIZE.x / max(1.0, floor(VIEWPORT_SIZE.y / 1080.0 + 0.5)));
	int which = int(mod(stripe, 3.0));
	vec3 mask = vec3(1.0 - grille * 0.55);
	mask[which] = 1.0 + grille * 0.55;
	lit *= mask;
	// The phosphor's glow into the glass, round what is bright.
	vec3 halo = textureLod(screen_mip, uv, 3.5).rgb * 0.6 + textureLod(screen_mip, uv, 5.0).rgb * 0.4;
	lit += halo * halo * glow;
	// A tube is brighter in the middle than at its edges, and the lines and grille take some of its
	// light: driven a little hotter to make up for it.
	float fall = 1.0 - 0.22 * dot(q * vec2(0.8, 1.0), q * vec2(0.8, 1.0));
	lit *= 1.45 * fall;
	// The bezel: the tube's corners are round, and past its edge is the cabinet's dark.
	vec2 edge = abs(q) - vec2(1.0) + vec2(0.06);
	float corner = length(max(edge, vec2(0.0))) + min(max(edge.x, edge.y), 0.0) - 0.06;
	float inside = 1.0 - smoothstep(-0.004, 0.004, corner);
	// The glass catches a dim, blurred sight of the picture just past its edge.
	vec3 shine = textureLod(screen_mip, clamp(uv, 0.0, 1.0), 6.0).rgb * 0.05;
	vec3 bezel = vec3(0.012, 0.011, 0.014) + shine * smoothstep(0.08, 0.0, corner);
	vec3 outv = mix(bezel, lit, inside);
	ALBEDO = mix(c0, outv, amount);
}
