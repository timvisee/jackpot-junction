// What every look shares, see RenderLook: the quad over the whole of a camera's frame, the frame
// under it, the depth under it and what can be read off the two, GAME.md 8.1b.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
// How strongly the look is laid over the frame, 0 to 1.
uniform float amount : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	// Over the frame of the camera it hangs a meter in front of, and no other: a world another
	// camera also looks into, a bay's feed say, would otherwise have it laid over it twice.
	float hung = distance(NODE_POSITION_WORLD, CAMERA_POSITION_WORLD);
	POSITION = abs(hung - 1.0) < 0.05 ? vec4(VERTEX.xy, 1.0, 1.0) : vec4(2.0, 2.0, 2.0, 1.0);
}

// The point under the pixel at uv, in the camera's space.
vec3 view_at(vec2 uv, mat4 inv_projection) {
	float depth = texture(depth_tex, uv).x;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
	return view.xyz / view.w;
}

float distance_at(vec2 uv, mat4 inv_projection) {
	return -view_at(uv, inv_projection).z;
}

float luma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// One pixel, in uv, at a size that is the same share of the screen at any resolution: 1080 lines
// are the reference, so a line drawn a pixel wide there is two wide at 2160.
vec2 pixel(vec2 viewport) {
	return vec2(1.0) / viewport * max(1.0, viewport.y / 1080.0);
}

// The ink a keyline is drawn in: the color under it, darkened and pulled toward the house's ink,
// so a red kart is edged in deep red rather than in black.
vec3 ink_of(vec3 c) {
	return mix(c * 0.28, vec3(0.025, 0.022, 0.03), 0.35);
}

// How much of an edge there is at uv: a step in distance across the pixel, as a share of the
// distance, and a turn in the surface, read off the depth of the pixels round it.
float edge_at(vec2 uv, vec2 px, mat4 inv_projection) {
	vec3 c = view_at(uv, inv_projection);
	vec3 l = view_at(uv - vec2(px.x, 0.0), inv_projection);
	vec3 r = view_at(uv + vec2(px.x, 0.0), inv_projection);
	vec3 d = view_at(uv - vec2(0.0, px.y), inv_projection);
	vec3 u = view_at(uv + vec2(0.0, px.y), inv_projection);
	float dist = -c.z;
	// A step in depth: an object's outline against what is behind it.
	float step_x = abs((-l.z) + (-r.z) - 2.0 * dist);
	float step_y = abs((-d.z) + (-u.z) - 2.0 * dist);
	float silhouette = smoothstep(0.003, 0.009, max(step_x, step_y) / dist);
	// A crease: the surface's normal turning sharply, as at the top edge of a wall.
	vec3 n = normalize(cross(r - l, u - d));
	vec3 nx = normalize(cross(r - c, u - c));
	vec3 ny = normalize(cross(c - l, c - d));
	float crease = smoothstep(0.25, 0.6, 1.0 - min(dot(n, nx), dot(n, ny)));
	// Nothing past the room: the sky is not an edge.
	float near = 1.0 - smoothstep(180.0, 240.0, dist);
	return max(silhouette, crease * 0.8) * near;
}

// A cheap hash for grain, steady per pixel.
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// How far the pixel at uv lies in shade: darker than the frame round it, as a cast shadow is, or
// turned from the light, as the far side of a wall is. The frame alone cannot tell a dark thing in
// the light from a light thing in the dark, so a dark felt is not shade just for being dark.
float shade_of(vec3 c, vec2 uv, sampler2D mip, mat4 inv_projection, vec2 px) {
	float l = luma(c);
	float around = luma(textureLod(mip, uv, 4.5).rgb);
	float darker = smoothstep(0.12, 0.55, 1.0 - l / max(around, 1e-4));
	vec3 p = view_at(uv, inv_projection);
	vec3 r = view_at(uv + vec2(px.x, 0.0), inv_projection);
	vec3 u = view_at(uv + vec2(0.0, px.y), inv_projection);
	vec3 n = normalize(cross(r - p, u - p));
	// Screen y runs down, so the cross can come out facing away: a surface the camera sees faces it.
	n = n.z < 0.0 ? -n : n;
	// The key comes from above and to the left of the camera in every room, near enough.
	float facing = dot(n, normalize(vec3(-0.45, 0.75, 0.5)));
	float turned = smoothstep(0.25, -0.35, facing);
	float near = 1.0 - smoothstep(150.0, 220.0, -p.z);
	return max(darker, turned * 0.85) * near;
}
