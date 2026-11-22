class_name SupporterTrails
extends RefCounted
## The supporter pack's trails, GAME.md 10.8, beside the rest of what a kart leaves behind it, see
## [ExhaustSmoke]: Stardust's twinkles on the exhaust's particles, the Prism being a ribbon of its
## own, see [PrismRibbon]; and the pictures of both on the kart dialog's rack.

## Stardust: how big a twinkle is, how far above the exhaust they hang and how widely they are
## scattered round it, their pale starlight, how long each hangs and how many there are at most.
const TWINKLE := 0.3
const TWINKLE_RISE := 0.35
const TWINKLE_SCATTER := Vector3(0.3, 0.25, 0.3)
const STARLIGHT := Color(0.92, 0.88, 1.0, 0.55)
const TWINKLE_LIFE := 1.6
const TWINKLES := 56

## A four-pointed twinkle's picture, made once.
static var _star: ImageTexture


## Stardust, the pack's trail, on [param process] and [param smoke]: four-pointed twinkles in pale
## starlight that hang where the kart has been and go out one by one, larger and fainter ones
## among them, never flying, since sparks that fly from the wheels say a drift boost is ready,
## GAME.md 4.3. They twinkle as they hang, but hold for a player who asked for fewer flashes. The
## twinkle a particle draws is handed back.
static func stardust(process: ParticleProcessMaterial, smoke: GPUParticles3D) -> Mesh:
	smoke.lifetime = TWINKLE_LIFE
	smoke.amount = TWINKLES
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = TWINKLE_SCATTER
	process.emission_shape_offset = Vector3(0.0, TWINKLE_RISE, 0.0)
	process.spread = 180.0
	process.initial_velocity_min = 0.0
	process.initial_velocity_max = 0.12
	process.gravity = Vector3(0.0, -0.05, 0.0)
	process.scale_min = 0.5
	process.scale_max = 1.15
	process.scale_curve = _twinkling(Game.settings.flash_reduction)
	process.color = STARLIGHT
	var quad := QuadMesh.new()
	quad.size = Vector2(TWINKLE, TWINKLE)
	var look := SupporterDress.added(Color.WHITE)
	look.albedo_texture = star_texture()
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = look
	return quad


## How big a twinkle of stardust is over its life: up quickly, then twinkling down and up again as
## it hangs and gone at the end; or for [param held], up, held and gone.
static func _twinkling(held: bool) -> CurveTexture:
	var curve := Curve.new()
	var points: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.1, 1.0)]
	if held:
		points.append(Vector2(0.8, 0.85))
	else:
		points.append_array(
			[Vector2(0.3, 0.55), Vector2(0.5, 1.0), Vector2(0.68, 0.5), Vector2(0.85, 0.8)]
		)
	points.append(Vector2(1.0, 0.0))
	for point: Vector2 in points:
		curve.add_point(point)
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


## A four-pointed twinkle, white on nothing: a bright core, four thin rays and a faint halo.
static func star_texture() -> ImageTexture:
	if _star != null:
		return _star
	var side := 64
	var picture := Image.create(side, side, false, Image.FORMAT_RGBA8)
	for y: int in side:
		for x: int in side:
			var at := Vector2(x, y) / float(side - 1) * 2.0 - Vector2.ONE
			var core := exp(-at.length_squared() * 30.0)
			var rays := (
				exp(-absf(at.x) * 40.0) * maxf(0.0, 1.0 - absf(at.y))
				+ exp(-absf(at.y) * 40.0) * maxf(0.0, 1.0 - absf(at.x))
			)
			var glow_of := exp(-at.length_squared() * 5.0) * 0.25
			picture.set_pixel(
				x, y, Color(1.0, 1.0, 1.0, clampf(core + rays * 0.9 + glow_of, 0.0, 1.0))
			)
	_star = ImageTexture.create_from_image(picture)
	return _star


## The picture of the pack's trail called [param named] in [param box] on [param on], for the kart
## dialog: the prism a band of the spectrum swept round in an arc, stardust a scatter of
## twinkles.
static func trail_icon(on: CanvasItem, box: Rect2, named: String) -> void:
	var middle := box.get_center()
	var side := minf(box.size.x, box.size.y)
	match named:
		"Prism":
			var bands := PrismRibbon.BANDS
			for band: int in bands.size():
				var reach := side * (0.42 - 0.035 * float(band))
				on.draw_arc(
					middle + Vector2(0.0, side * 0.3),
					reach,
					PI * 1.08,
					PI * 1.92,
					32,
					Color(bands[band], 0.9),
					side * 0.036,
					true
				)
		"Stardust":
			var rng := RandomNumberGenerator.new()
			rng.seed = 11
			for i: int in 9:
				var at := (
					middle
					+ Vector2(rng.randf_range(-0.38, 0.38), rng.randf_range(-0.3, 0.3)) * side
				)
				var reach := side * rng.randf_range(0.04, 0.11)
				var ink := Color(STARLIGHT, rng.randf_range(0.6, 1.0))
				var points := PackedVector2Array()
				for k: int in 8:
					var out := reach * (1.0 if k % 2 == 0 else 0.22)
					points.append(at + Vector2.UP.rotated(TAU * k / 8.0) * out)
				on.draw_colored_polygon(points, ink)
