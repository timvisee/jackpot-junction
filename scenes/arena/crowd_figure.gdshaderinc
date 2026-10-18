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
// The few who have stopped to watch the player's kart before the Final Hand, STORY.md 6.9: every
// figure carries a rank in the fraction of its lean's phase, those most in view first, and those
// ranked under watchers stop dancing and lean in toward watcher_point. The one ranked 0 is the
// one who never falls into step with the rest.
uniform float watchers = 0.0;
uniform vec3 watcher_point = vec3(0.0);
uniform float watcher_lean = 0.3;

// A crowd is lit by its room rather than by itself: dim is how brightly it is lit against the
// table, and the rim is the light along the edges of everybody, which is what makes a band of
// dark figures read as people rather than as a wall. In a lit room the rim is nothing and this
// costs a multiply.
uniform vec4 rim_color : source_color = vec4(1.0);
uniform float rim_strength = 0.0;
uniform float dim = 1.0;

// A paper doll turned to the camera about its own up, GAME.md 8.1b: flat, it would be edge on to
// anybody looking along the flanks. This much of the way round, 1 for all of it.
uniform float face_camera = 1.0;
// How far back a doll leans on its easel: twenty-five degrees.
const float EASEL_SIN = 0.4226;
const float EASEL_COS = 0.9063;
// Where on the doll a point is, for the face's printed hair.
varying vec2 doll;

void vertex() {
	doll = VERTEX.xy;
	// Leant back on its easel a little, so the camera over the table sees more of it, and lit as
	// a card lying under the lamp is rather than as one standing edge on to it.
	VERTEX.z -= VERTEX.y * EASEL_SIN;
	VERTEX.y *= EASEL_COS;
	NORMAL = normalize(vec3(0.0, 0.8, 0.6));
	vec3 front = (MODEL_MATRIX * vec4(0.0, 0.0, 1.0, 0.0)).xyz;
	vec3 to_camera = CAMERA_POSITION_WORLD - MODEL_MATRIX[3].xyz;
	float turn = atan(to_camera.x, to_camera.z) - atan(front.x, front.z);
	turn = mod(turn + PI, TAU) - PI;
	turn *= face_camera;
	float ts = sin(turn);
	float tc = cos(turn);
	VERTEX.xz = vec2(VERTEX.x * tc + VERTEX.z * ts, -VERTEX.x * ts + VERTEX.z * tc);
	NORMAL.xz = vec2(NORMAL.x * tc + NORMAL.z * ts, -NORMAL.x * ts + NORMAL.z * tc);
	float rank = fract(INSTANCE_CUSTOM.w);
	float phase = floor(INSTANCE_CUSTOM.w) / 64.0;
	bool odd_one = rank < 0.001;
	bool watcher = !odd_one && rank < watchers;
	float keep = odd_one ? 1.0 : spread;
	float own = beat + INSTANCE_CUSTOM.x * keep;
	float jump = watcher ? 0.0 : lift;
	float swing = watcher ? 0.0 : lean;
	VERTEX.y += abs(sin(own)) * jump * mix(1.0, INSTANCE_CUSTOM.y, keep);
	float sway = mix(1.0, INSTANCE_CUSTOM.z, keep);
	float tip = sin(own * 0.5 + phase * keep) * swing * sway;
	float s = sin(tip);
	float c = cos(tip);
	VERTEX.xy = vec2(VERTEX.x * c - VERTEX.y * s, VERTEX.x * s + VERTEX.y * c);
	float leaning = watch;
	vec3 point = watch_point;
	if (watch <= 0.0 && watcher) {
		leaning = watcher_lean;
		point = watcher_point;
	}
	if (leaning > 0.0) {
		// The way to the point in the figure's own frame: its turn undone, its size normalized
		// away.
		vec3 toward = point - MODEL_MATRIX[3].xyz;
		vec3 mine = transpose(mat3(MODEL_MATRIX)) * vec3(toward.x, 0.0, toward.z);
		VERTEX.xz += normalize(mine.xz + vec2(0.0001, 0.0)) * VERTEX.y * leaning;
	}
}

float rim_of(vec3 normal, vec3 view) {
	return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), 2.5);
}
