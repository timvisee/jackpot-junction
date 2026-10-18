shader_type canvas_item;
// The dark over the loyalty program while the House shows a member round it, GAME.md 8.9 "The
// first look": all of it dark but for soft pools of light, each round the thing it lights, its
// middle and how far it reaches either way in the rect's own pixels, see LoyaltyTour: a rectangle
// with its corners rounded as far as its shorter side lets them be, so a sign's is nearly round
// and a slip's hugs the slip.

uniform vec2 room = vec2(1920.0, 1080.0);
uniform vec4 spots[4];
uniform int count = 0;
uniform float dark = 0.66;
uniform float soft = 34.0;
uniform vec3 ink = vec3(0.02, 0.025, 0.04);

void fragment() {
	vec2 at = UV * room;
	float lit = 0.0;
	for (int i = 0; i < 4; i++) {
		if (i >= count) {
			break;
		}
		vec2 reach = max(spots[i].zw, vec2(1.0));
		float corner = min(reach.x, reach.y) * 0.9;
		// How far outside the rounded rectangle, negative inside it.
		vec2 past = abs(at - spots[i].xy) - (reach - vec2(corner));
		float away = length(max(past, vec2(0.0))) + min(max(past.x, past.y), 0.0) - corner;
		lit = max(lit, 1.0 - smoothstep(-soft, soft, away));
	}
	COLOR = vec4(ink, dark * (1.0 - lit));
}
