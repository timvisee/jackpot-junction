shader_type canvas_item;
// The dark the store trailer's license is slid into, with a pool of light where the card comes to
// rest: an ellipse [reach] across about [center], its edge [soft], the rest [dark], all of it lit
// by [lit], see scenes/dev/trailer_posed.gd.
uniform vec2 frame = vec2(1920.0, 1080.0);
uniform vec2 center = vec2(960.0, 540.0);
uniform vec2 reach = vec2(640.0, 430.0);
uniform float soft = 0.45;
uniform float dark = 0.93;
uniform float lit = 0.0;

void fragment() {
	float off = length((UV * frame - center) / reach);
	float light = (1.0 - smoothstep(1.0 - soft, 1.0 + soft, off)) * lit;
	COLOR = vec4(0.0, 0.0, 0.0, dark * (1.0 - light));
}
