// What every onlooker in the crowd shares, GAME.md 8.1: the animation, run on the figures
// themselves rather than on their transforms, and the light of the room on them. Included by
// crowd_shirt.gdshader and crowd_face.gdshader, which differ only in what they paint.
//
// Each figure carries its own place in the beat, its own share of the jump and its own share of
// the lean in its instance custom data, so a thousand people on one beat still move like a
// thousand people. Spread is how much of that they keep, 1 for all of it and 0 for a house
// moving as one, STORY.md 6.9.
uniform float beat = 0.0;
uniform float lift = 0.0;
uniform float lean = 0.0;
uniform float spread = 1.0;
// Everybody leaning in toward one point on the table, by this much a meter up, STORY.md 6.9: the
// figures are round, so a lean is how a house turns to look at something.
uniform vec3 watch_point = vec3(0.0);
uniform float watch = 0.0;

// A crowd is lit by its room rather than by itself: dim is how brightly it is lit against the
// table, and the rim is the light along the edges of everybody, which is what makes a band of
// dark figures read as people rather than as a wall. In a lit room the rim is nothing and this
// costs a multiply.
uniform vec4 rim_color : source_color = vec4(1.0);
uniform float rim_strength = 0.0;
uniform float dim = 1.0;

void vertex() {
	float own = beat + INSTANCE_CUSTOM.x * spread;
	VERTEX.y += abs(sin(own)) * lift * mix(1.0, INSTANCE_CUSTOM.y, spread);
	float sway = mix(1.0, INSTANCE_CUSTOM.z, spread);
	float tip = sin(own * 0.5 + INSTANCE_CUSTOM.w * spread) * lean * sway;
	float s = sin(tip);
	float c = cos(tip);
	VERTEX.xy = vec2(VERTEX.x * c - VERTEX.y * s, VERTEX.x * s + VERTEX.y * c);
	if (watch > 0.0) {
		// The way to the point in the figure's own frame: its turn undone, its size normalized
		// away.
		vec3 toward = watch_point - MODEL_MATRIX[3].xyz;
		vec3 mine = transpose(mat3(MODEL_MATRIX)) * vec3(toward.x, 0.0, toward.z);
		VERTEX.xz += normalize(mine.xz + vec2(0.0001, 0.0)) * VERTEX.y * watch;
	}
}

float rim_of(vec3 normal, vec3 view) {
	return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), 2.5);
}
