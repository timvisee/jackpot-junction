shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Neon: the room as a grid world of light. Everything goes dark; every outline and crease, and
// every line printed on the felt, is drawn as a tube of light in the color of what it edges, the
// room's own surfaces in magenta where they are warm and cyan where they are cool; a fine grid is
// ruled on the floor; and the karts and their shots, in their players' colors, burn from within
// and glow into the dark round them.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
uniform vec3 warm : source_color = vec3(1.0, 0.16, 0.72);
uniform vec3 cool : source_color = vec3(0.12, 0.86, 1.0);
uniform float glow : hint_range(0.0, 2.0) = 1.0;
// How brightly the grid on the floor is ruled, and how far apart its lines are, in meters.
uniform float grid : hint_range(0.0, 1.0) = 0.35;
uniform float spacing : hint_range(0.5, 8.0) = 2.0;

// The light the tonemapper turns into d on the screen, d in linear light: the ACES curve every
// room is tonemapped with, at the white most rooms use, run backward.
vec3 unshown(vec3 d) {
	const mat3 out_of = mat3(
			vec3(0.64303825, 0.31118675, 0.04577546),
			vec3(0.05926869, 0.93143649, 0.00929492),
			vec3(0.0059619, 0.06392902, 0.93011838));
	const mat3 into = mat3(
			vec3(0.98041165, -0.37543204, -0.04942405),
			vec3(-0.08168214, 0.64458417, -0.00734648),
			vec3(-0.02018713, -0.09024246, 0.66598515));
	vec3 y = clamp(max(d, vec3(0.0)) * 0.977 * out_of, 0.0, 0.99);
	vec3 a = 1.0 - y * 0.983729;
	vec3 b = 0.0245786 - y * 0.432951;
	vec3 c = -(0.000090537 + y * 0.238081);
	vec3 x = (-b + sqrt(b * b - 4.0 * a * c)) / (2.0 * a);
	return max(x * into, vec3(0.0));
}

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

// The tube of light a surface of color c is edged in: its own hue at full strength when it is a
// strong color, the room's magenta or cyan when it is not.
vec3 tube_of(vec3 c, out float vivid) {
	vec3 lab = oklab(c);
	float chroma = length(lab.yz);
	vivid = smoothstep(0.11, 0.16, chroma);
	float top = max(max(c.r, c.g), c.b);
	vec3 hue = c / max(top, 1e-4);
	hue = mix(vec3(dot(hue, vec3(0.3, 0.55, 0.15))), hue, 1.3);
	float warmth = smoothstep(-0.02, 0.06, lab.y + lab.z * 0.6);
	vec3 room = mix(cool, warm, warmth);
	return mix(room, clamp(hue, 0.0, 1.0), vivid);
}

void fragment() {
	vec3 c0 = texture(screen_tex, SCREEN_UV).rgb;
	vec2 px = pixel(VIEWPORT_SIZE);
	vec2 uv = SCREEN_UV;
	float vivid;
	vec3 tube = tube_of(c0, vivid);
	// The tubes: the outlines and creases of the room, and the lines printed on it, as a step in
	// the brightness of its color across a pixel.
	float shape = edge_at(uv, px, INV_PROJECTION_MATRIX);
	float l = luma(c0);
	float lx = luma(texture(screen_tex, uv + vec2(px.x, 0.0)).rgb) - luma(texture(screen_tex, uv - vec2(px.x, 0.0)).rgb);
	float ly = luma(texture(screen_tex, uv + vec2(0.0, px.y)).rgb) - luma(texture(screen_tex, uv - vec2(0.0, px.y)).rgb);
	float printed = smoothstep(0.05, 0.2, length(vec2(lx, ly)) / max(l + 0.08, 0.1));
	// What is printed is drawn on the felt only, where it is the table's markings; elsewhere a step
	// in brightness is a face against a shirt in the stands, and the outlines are enough.
	vec3 view = view_at(uv, INV_PROJECTION_MATRIX);
	vec3 world = (INV_VIEW_MATRIX * vec4(view, 1.0)).xyz;
	float on_felt = 1.0 - smoothstep(0.05, 0.15, abs(world.y));
	float line = max(shape, printed * 0.75 * on_felt);
	// The halo round each tube: the same outlines found again across a wider step, fainter.
	float halo = edge_at(uv, px * 3.0, INV_PROJECTION_MATRIX) * 0.3 + edge_at(uv, px * 7.0, INV_PROJECTION_MATRIX) * 0.12;
	// The floor's grid, ruled in the world so it lies still on the table as the camera moves, and
	// faded out where its lines would come closer together than the pixels can draw.
	vec2 cell = world.xz / spacing;
	vec2 width = fwidth(cell);
	vec2 off = abs(fract(cell + 0.5) - 0.5) / max(width, vec2(1e-5));
	float ruled = 1.0 - min(min(off.x, off.y), 1.0);
	ruled *= 1.0 - smoothstep(0.08, 0.25, max(width.x, width.y));
	ruled *= on_felt;
	// The dark: the room's own color a whisper over a deep violet black; the strong colors, the
	// karts and their shots, lit from within.
	vec3 dark = c0 * 0.04 + vec3(0.006, 0.002, 0.016);
	vec3 lit = mix(dark, tube * (0.45 + 0.5 * luma(c0)), vivid);
	// The glow of the strong colors into the dark round them.
	vec3 near = textureLod(screen_mip, uv, 2.5).rgb;
	vec3 far = textureLod(screen_mip, uv, 4.0).rgb;
	float vn;
	float vf;
	vec3 tn = tube_of(near, vn);
	vec3 tf = tube_of(far, vf);
	vec3 aura = tn * vn * luma(near) * 0.9 + tf * vf * luma(far) * 0.6;
	// The room's tubes burn a little lower than the players' colors, so the karts are the brightest
	// things on the table.
	float strength = mix(0.7, 1.25, vivid);
	vec3 outv = lit + tube * (line * 1.1 + halo) * glow * strength + aura * glow + cool * ruled * grid * 0.5;
	outv = mix(outv, vec3(1.0), smoothstep(0.9, 1.6, line * 1.1 + halo) * 0.35);
	ALBEDO = mix(c0, unshown(clamp(outv, 0.0, 1.0)), amount);
}
