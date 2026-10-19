// Black outlines, GAME.md 8.1b: what the outline looks share, after look.gdshaderinc.
//
// A silhouette is drawn across an object's edge, half on the object and half on what is behind it,
// as a pen draws it: on a dark floor it is the half on the object that shows. A pixel is by an edge
// when something much nearer or much farther than itself lies close by, judged against the slope
// of its own surface, so a plane seen at a slant is never mistaken for an edge. Creases, a wall's top edge or a kart's seam, are drawn
// thinner and lighter on the object itself. Width is in pixels at 1080 lines, a little heavier near
// the camera and lighter far off, as a pen draws what is near with more weight.

// How far from the camera an outline is drawn at its full width.
const float OUTLINE_REFERENCE = 34.0;

// How strongly [uv] lies just outside a silhouette, and just on a crease, 0 to 1 each, for
// outlines [width] pixels wide.
vec2 outline_at(vec2 uv, vec2 px, float width, mat4 inv_projection) {
	vec3 c = view_at(uv, inv_projection);
	float d = -c.z;
	float scale = clamp(OUTLINE_REFERENCE / max(d, 1.0), 0.6, 1.6);
	float w = width * scale;
	float silhouette = 0.0;
	// Four directions, each tested both ways: is something much nearer on one side than the
	// surface here would be if it carried on?
	vec2 dirs[4] = vec2[](vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(0.7071, 0.7071), vec2(0.7071, -0.7071));
	for (int i = 0; i < 4; i++) {
		vec2 o = dirs[i] * px * w;
		float a = -view_at(uv + o, inv_projection).z;
		float b = -view_at(uv - o, inv_projection).z;
		float bend = abs(a - b) * 0.5;
		// Outside the edge, something much nearer close by; inside it, something much farther.
		// Both, so the line straddles the edge: on a dark floor the half on the object is the
		// half that shows.
		float nearer = (d - min(a, b)) - bend;
		float farther = (max(a, b) - d) - bend;
		silhouette = max(silhouette, smoothstep(0.004, 0.011, max(nearer, farther) / d));
	}
	// Creases: the surface turning sharply within half the width, on the object.
	vec2 h = px * max(w * 0.5, 1.0);
	vec3 r = view_at(uv + vec2(h.x, 0.0), inv_projection);
	vec3 l = view_at(uv - vec2(h.x, 0.0), inv_projection);
	vec3 u = view_at(uv + vec2(0.0, h.y), inv_projection);
	vec3 dn = view_at(uv - vec2(0.0, h.y), inv_projection);
	vec3 n = normalize(cross(r - l, u - dn));
	vec3 nr = normalize(cross(r - c, u - c));
	vec3 nl = normalize(cross(c - l, c - dn));
	float turn = 1.0 - min(abs(dot(n, nr)), abs(dot(n, nl)));
	float crease = smoothstep(0.3, 0.65, turn);
	// Nothing past the room: the dark beyond it is not an edge.
	float near = 1.0 - smoothstep(170.0, 230.0, d);
	return vec2(silhouette, crease) * near;
}
