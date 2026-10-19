shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, skip_vertex_transform;

#include "res://scenes/fx/looks/look.gdshaderinc"

// Paper cutout: the frame as layers of colored card cut out and stacked, a diorama in a box. Each
// thing is flat card in its own color with the fibers of the paper in it; wherever something
// stands over what is behind it, it throws a soft shadow down and to the right onto the layer
// under it, as card on foam pads does; and its cut edge catches the light, a hair paler, as the
// core of card shows where the blade went through.
uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
// How far a layer's shadow falls, in pixels at 1080 lines.
uniform float shadow_reach : hint_range(2.0, 32.0) = 15.0;
uniform float shadow_depth : hint_range(0.0, 1.0) = 0.8;
uniform float fiber : hint_range(0.0, 0.2) = 0.06;

vec3 shown(vec3 c) {
	vec3 x = max(c, vec3(0.0)) * mat3(vec3(1.074942, 0.638244, 0.086814),
			vec3(0.1368, 1.635012, 0.028188), vec3(0.05112, 0.240894, 1.507986));
	vec3 t = (x * (x + 0.0245786) - 0.000090537) / (x * (0.983729 * x + 0.432951) + 0.238081);
	t = t * mat3(vec3(1.60475, -0.53108, -0.07367), vec3(-0.10208, 1.10813, -0.00605),
			vec3(-0.00327, -0.07276, 1.07602));
	t = clamp(t / 0.977011, 0.0, 1.0);
	return mix(t * 12.92, 1.055 * pow(t, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), t));
}

vec3 unshown(vec3 s) {
	s = clamp(s, 0.0, 1.0);
	vec3 l = mix(s / 12.92, pow((s + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), s));
	vec3 t = (l * 0.977011) * mat3(vec3(0.643038, 0.311187, 0.045775),
			vec3(0.059269, 0.931436, 0.009295), vec3(0.005962, 0.063929, 0.930118));
	t = clamp(t, vec3(-0.00038), vec3(0.999));
	vec3 a = t * 0.983729 - 1.0;
	vec3 b = t * 0.432951 - 0.0245786;
	vec3 k = t * 0.238081 + 0.000090537;
	vec3 x = (-b - sqrt(b * b - 4.0 * a * k)) / (2.0 * a);
	return max(x * mat3(vec3(0.980412, -0.375432, -0.049424), vec3(-0.081682, 0.644584, -0.007346),
			vec3(-0.020187, -0.090242, 0.665985)), vec3(0.0));
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Paper's fibers at one size: short strands lying every which way, and the tooth between them.
float fibers(vec2 q) {
	vec2 a = mat2(vec2(0.866, 0.5), vec2(-0.5, 0.866)) * q;
	vec2 b = mat2(vec2(0.342, -0.94), vec2(0.94, 0.342)) * q;
	float f1 = vnoise(a * vec2(0.35, 2.2));
	float f2 = vnoise(b * vec2(0.3, 2.0) + 11.0);
	float tooth = vnoise(q * 0.9 + 5.0);
	return (smoothstep(0.55, 0.9, f1) + smoothstep(0.6, 0.92, f2)) * 0.5 - 0.15 + (tooth - 0.5) * 0.4;
}

void fragment() {
	vec2 px = pixel(VIEWPORT_SIZE);
	float scale = max(1.0, VIEWPORT_SIZE.y / 1080.0);
	vec2 uv0 = SCREEN_UV;
	vec3 c = texture(screen_tex, uv0).rgb;
	vec3 here0 = view_at(uv0, INV_PROJECTION_MATRIX);
	float dist0 = -here0.z;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec2 plane = here0.xy + vec2(dot(cam, INV_VIEW_MATRIX[0].xyz), dot(cam, INV_VIEW_MATRIX[1].xyz));
	float px_per_m = abs(PROJECTION_MATRIX[1][1]) * 0.5 * VIEWPORT_SIZE.y / max(dist0, 0.01) / scale;

	// Cut by hand: every edge wanders a little off the line, the same way each frame.
	vec2 wander = vec2(vnoise(plane * px_per_m * 0.12), vnoise(plane * px_per_m * 0.12 + 7.7)) - 0.5;
	vec2 uv = uv0 + wander * 1.4 * px;
	vec3 s = shown(textureLod(screen_mip, uv, 0.3).rgb);
	float dist = distance_at(uv, INV_PROJECTION_MATRIX);
	float ddx = dFdx(dist0) / scale;
	float ddy = dFdy(dist0) / scale;
	float slope_ok = 1.0 - smoothstep(0.02, 0.06, (abs(ddx) + abs(ddy)) / max(dist, 0.01));

	// Card: matte, a shade softer than paint and a little warm.
	float l = luma(s);
	vec3 card = mix(vec3(l), s, 0.92) * 0.86 + vec3(0.085, 0.08, 0.065);

	// The shadow of whatever stands over this spot: the outline of what is above it, moved up and
	// to the left toward the light and softened, read as how much of a small disk there lies on
	// card nearer than this surface would be at that place.
	vec2 toward = normalize(vec2(-0.75, -1.0));
	vec2 middle = toward * shadow_reach * 0.55;
	float soft = shadow_reach * 0.5;
	float step_m = 0.05 + 0.0025 * dist;
	float over = 0.0;
	for (int i = 0; i < 9; i++) {
		float ang = float(i) * 2.39996 + 0.5;
		float rad = sqrt((float(i) + 0.5) / 9.0) * soft;
		vec2 off = middle + vec2(cos(ang), sin(ang)) * rad;
		float sd = distance_at(uv + off * px, INV_PROJECTION_MATRIX);
		float expect = dist + (ddx * off.x + ddy * off.y) * slope_ok;
		over += smoothstep(step_m, step_m * 2.0, expect - sd);
	}
	float shadow = over / 9.0 * shadow_depth;

	// The cut edge: a pixel on card with something farther just beside it is on the card's rim.
	float rim = 0.0;
	for (int i = 0; i < 4; i++) {
		vec2 dir = vec2(i == 0 ? 1.0 : (i == 1 ? -1.0 : 0.0), i == 2 ? 1.0 : (i == 3 ? -1.0 : 0.0));
		vec2 off = dir * 1.6;
		float sd = distance_at(uv + off * px, INV_PROJECTION_MATRIX);
		float expect = dist + (ddx * off.x + ddy * off.y) * slope_ok;
		float behind = smoothstep(step_m, step_m * 2.0, sd - expect);
		// The edges toward the light catch more of it.
		float facing = 0.55 + 0.45 * clamp(dot(-dir, toward), 0.0, 1.0);
		rim = max(rim, behind * facing);
	}
	vec3 core = mix(card, vec3(0.99, 0.97, 0.93), 0.55);
	vec3 outv = mix(card, core, rim * 0.6);

	// The paper's fibers, laid on the card itself so they stay with it under the camera, at two
	// sizes faded between as the camera comes and goes.
	float octave = log2(max(px_per_m, 1e-3) / 3.0);
	float o0 = floor(octave);
	float fade = fract(octave);
	float fib = 0.0;
	for (int i = 0; i < 2; i++) {
		float sc = exp2(o0 + float(i)) * 3.0 / 4.0;
		fib += (i == 0 ? 1.0 - fade : fade) * fibers(plane * sc);
	}
	outv *= 1.0 + fib * fiber;

	// The shadow, a warm gray under card.
	outv *= mix(vec3(1.0), vec3(0.42, 0.4, 0.47), clamp(shadow, 0.0, 1.0));

	vec3 linear = unshown(outv);
	float near = 1.0 - smoothstep(180.0, 240.0, dist0);
	linear = mix(c, linear, max(near, 0.5));
	float hot = smoothstep(1.6, 2.6, max(c.r, max(c.g, c.b)));
	linear = mix(linear, max(linear, c), hot);
	ALBEDO = mix(c, linear, amount);
}
