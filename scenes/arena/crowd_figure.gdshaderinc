// What every onlooker in the crowd shares, GAME.md 8.1: the animation, run on the figures
// themselves rather than on their transforms, and the light of the room on them. Included by
// crowd_shirt.gdshader and crowd_face.gdshader, which differ only in what they paint.
//
// Each figure carries its own place in the beat, its own share of the jump and its own share of
// the lean in its instance custom data, so a thousand people on one beat still move like a
// thousand people.
uniform float beat = 0.0;
uniform float lift = 0.0;
uniform float lean = 0.0;

// A crowd is lit by its room rather than by itself: dim is how brightly it is lit against the
// table, and the rim is the light along the edges of everybody, which is what makes a band of
// dark figures read as people rather than as a wall. In a lit room the rim is nothing and this
// costs a multiply.
uniform vec4 rim_color : source_color = vec4(1.0);
uniform float rim_strength = 0.0;
uniform float dim = 1.0;

void vertex() {
	float own = beat + INSTANCE_CUSTOM.x;
	VERTEX.y += abs(sin(own)) * lift * INSTANCE_CUSTOM.y;
	float tip = sin(own * 0.5 + INSTANCE_CUSTOM.w) * lean * INSTANCE_CUSTOM.z;
	float s = sin(tip);
	float c = cos(tip);
	VERTEX.xy = vec2(VERTEX.x * c - VERTEX.y * s, VERTEX.x * s + VERTEX.y * c);
}

float rim_of(vec3 normal, vec3 view) {
	return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), 2.5);
}
