shader_type canvas_item;

// A picture seen through a window with rounded corners: the Accessibility page's preview of the aim
// guide, GAME.md 8.5. Nothing past the corners, their edge smoothed over a pixel; and inside, a
// little darker toward the edge, as the inside of a frame is, so the picture sits in it rather than
// being pasted on.

// How big the window is, in the picture's own units, how round its corners, and how far in from
// its edge the dark reaches and how dark it is at the edge.
uniform vec2 box = vec2(600.0, 170.0);
uniform float radius = 14.0;
uniform float reach = 26.0;
uniform float edge_dark = 0.3;

void fragment() {
	// How far outside the rounded box this point is: negative inside.
	vec2 from_middle = (UV - vec2(0.5)) * box;
	vec2 past = abs(from_middle) - box * 0.5 + vec2(radius);
	float out_by = length(max(past, vec2(0.0))) + min(max(past.x, past.y), 0.0) - radius;
	COLOR.rgb *= 1.0 - edge_dark * (1.0 - smoothstep(0.0, reach, -out_by));
	COLOR.a *= clamp(0.5 - out_by / max(fwidth(out_by), 0.0001), 0.0, 1.0);
}
