shader_type canvas_item;
// A leaf of the theory book turning over, GAME.md 9.4a: lifted off the right page about the spine
// and laid down on the left, seen in perspective from a camera standing in front of the book, so
// the leaf grows a little as it comes up toward it and narrows to an edge as it stands upright.
// Its front is the right page it was, its back the left page it lands as; each face goes a shade
// darker as it turns away from the light in front of the book. The rect covers the open book with
// room over and under it for the leaf to grow into; everything here is in its pixels.

// How far over the leaf has come: 0 flat on the right, PI flat on the left.
uniform float angle = 0.0;
// The rect's size, where the spine runs, how far the page stands off it, the page's width and
// height and where its top is, and how far the camera stands from the book.
uniform vec2 rect_size = vec2(880.0, 650.0);
uniform float hinge = 440.0;
uniform float inner = 11.0;
uniform vec2 page = vec2(400.0, 470.0);
uniform float top = 88.0;
uniform float depth = 2000.0;
// The leaf's faces: the right page it lifts off, and the left page it lands as.
uniform sampler2D front : filter_linear, repeat_disable;
uniform sampler2D back : filter_linear, repeat_disable;

// The modulate, taken before the texture is read into COLOR at the untouched UV.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 px = UV * rect_size;
	float middle = top + page.y * 0.5;
	vec3 eye = vec3(hinge, middle, -depth);
	vec3 ray = vec3(px.x - hinge, px.y - middle, depth);
	float s = sin(angle);
	float c = cos(angle);
	// The plane the leaf lies in: through the spine, turned about it.
	vec3 normal = vec3(s, 0.0, c);
	float toward = dot(normal, ray);
	vec4 drawn = vec4(0.0);
	if (abs(toward) > 0.00001) {
		float t = depth * c / toward;
		if (t > 0.0) {
			vec3 hit = eye + ray * t;
			float along = (hit.x - hinge) * c - hit.z * s - inner;
			float down = hit.y - top;
			if (along >= 0.0 && along <= page.x && down >= 0.0 && down <= page.y) {
				vec4 picture;
				if (c > 0.0) {
					picture = texture(front, vec2(along / page.x, down / page.y));
				} else {
					picture = texture(back, vec2(1.0 - along / page.x, down / page.y));
				}
				float shade = 0.7 + 0.3 * abs(c);
				drawn = vec4(picture.rgb * shade, picture.a);
			}
		}
	}
	COLOR = drawn * tint;
}
