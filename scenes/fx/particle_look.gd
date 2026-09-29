class_name ParticleLook
extends RefCounted
## How the particles in this game are drawn, GAME.md 8.1. Sparks, smoke and flame all want the
## same three things of their material: no lighting, because a puff of smoke lit by the room's
## lamps reads as a solid object; alpha, because they fade rather than vanish; and the particle's
## own color taken from its vertex colors, which is what carries the color ramp. The chunks a
## [Burst] throws are the exception and are lit, since they are meant to read as solid.
##
## Named here because a particle that misses one of the three does not fail, it simply looks
## wrong, and the three are easy to lose track of one file at a time.


## The shared look. Callers set whatever else that particular effect wants on top.
static func material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	return material


## Particles cast no shadows. A spark or a puff of smoke throwing a shadow is nothing anybody
## sees, and a system of a hundred draws its mesh a hundred times over into every split of the
## shadow map: before this was set, the particles behind four karts were six of the seven
## million triangles in a frame, GAME.md 10.1.
static func no_shadows(particles: GPUParticles3D) -> void:
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A ball for a particle, [param radius] across and [param detail] segments round, in the shared
## look. A SphereMesh comes at sixty-four segments and four thousand triangles, and a spark or a
## puff is a few pixels of one flat color: six segments for a spark and eight for a puff draw
## the same, at a fiftieth of the triangles.
static func ball(radius: float, detail := 8) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = detail
	mesh.rings = maxi(detail >> 1, 2)
	mesh.material = material()
	return mesh


## A ramp from [param from] to [param to], ending transparent however [param to] was written:
## every one of these effects fades out rather than blinking off, so the end alpha is the rule
## rather than something each caller has to remember.
static func fade_out(from: Color, to: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, from)
	gradient.set_color(1, Color(to.r, to.g, to.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	return ramp
