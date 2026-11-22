class_name SupporterPaint
extends RefCounted
## The supporter pack's paint, GAME.md 10.8, Night sky: the player's color as a night sky, deeper
## shades and lighter wisps of it drifting over the body, never darker than any paint may go,
## [constant KartDress.SHADE], so the color is still the kart's; and small stars glowing in it,
## lit from within rather than by the room, now and then one brightening a little and fading back,
## slowly, hard to spot until it is seen. Laid over the paint every kart has, see
## [method KartDress.paint], so the body's print and a finish lie over it as over any.

## How big the sky is laid on, of the patterns' own measure; how many stars are in a tile of it,
## how big the biggest is in its pixels, and how bright they glow.
const SKY_SCALE := 0.7
const STARS := 46
const STAR_REACH := 2.6
const STAR_GLOW := 2.2
## How big a tile of the sky and of its stars is, in pixels.
const SKY := 128
const STARRY := 256
## The twinkle: how bright a star grows at the top of its beat, of its own light, and the pass it is
## drawn in, see [method twinkle].
const TWINKLE := 0.9
const TWINKLE_SHADER := preload("res://scenes/kart/night_twinkle.gdshader")

## The sky's tones, its stars and their beats, each made once.
static var _sky: ImageTexture
static var _stars: ImageTexture
static var _beats: ImageTexture
## The twinkle's pass handing on to each finish's sheen, made once each, see [method twinkle].
static var _twinkles: Dictionary[int, ShaderMaterial] = {}


## The paint of a kart in [param color] wearing the night sky in [param style], with
## [param body_print] over it: the plain paint every kart has, its finish and print kept, with
## the sky laid on it and its stars glowing.
static func paint(color: Color, style: KartStyle, body_print: Texture2D) -> StandardMaterial3D:
	var plain := style.duplicate_style()
	plain.paint = 0
	var material := KartDress.paint(color, plain, body_print)
	material.albedo_texture = sky()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.uv1_triplanar = true
	material.uv1_triplanar_sharpness = 40.0
	material.uv1_scale = Vector3.ONE * KartDress.PATTERN_SCALE * SKY_SCALE
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_texture = stars()
	material.emission_energy_multiplier = STAR_GLOW
	# The color times the stars, so only the stars glow; added, the color lit the whole body.
	material.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	material.next_pass = twinkle(style.finish(0))
	return material


## The pass over the night sky in which now and then one of its stars brightens a little and fades
## back, see [code]night_twinkle.gdshader[/code], handing on to finish [param level]'s sheen, so an
## edition still lies over it; nothing for a player who asked for fewer flashes, see
## [method SupporterDress.steady].
static func twinkle(level: int) -> ShaderMaterial:
	if not _twinkles.has(level):
		var beating := ShaderMaterial.new()
		beating.shader = TWINKLE_SHADER
		beating.set_shader_parameter("beats", beats())
		beating.set_shader_parameter("scale", Vector3.ONE * KartDress.PATTERN_SCALE * SKY_SCALE)
		beating.set_shader_parameter("strength", TWINKLE)
		beating.next_pass = KartDress.finish_material(level)
		_twinkles[level] = beating
	return SupporterDress.steadied(_twinkles[level])


## The night sky's patch on the kart dialog's rack in [param box] on [param on], in
## [param color]: the sky's tones over the color and its stars over them.
static func patch(on: CanvasItem, box: Rect2, color: Color) -> void:
	var shape := FeltArt.rounded(box, minf(box.size.x, box.size.y) * 0.12)
	var tile := box.size.x * 0.9
	var uvs := PackedVector2Array()
	for point: Vector2 in shape:
		uvs.append((point - box.position) / tile)
	on.draw_colored_polygon(shape, color, uvs, sky())
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var side := minf(box.size.x, box.size.y)
	for i: int in 14:
		var at := (
			box.position
			+ Vector2(rng.randf_range(0.12, 0.88), rng.randf_range(0.12, 0.88)) * box.size
		)
		on.draw_circle(at, side * rng.randf_range(0.008, 0.022), Color(1.0, 0.97, 0.9, 0.9))


## The sky's tones: soft drifts of light and shade, tiling, never under [constant KartDress.SHADE].
static func sky() -> ImageTexture:
	if _sky != null:
		return _sky
	var noise := FastNoiseLite.new()
	noise.seed = 9
	noise.frequency = 0.035
	noise.fractal_octaves = 4
	var drift := noise.get_seamless_image(SKY, SKY)
	var picture := Image.create_empty(SKY, SKY, true, Image.FORMAT_RGB8)
	for y: int in SKY:
		for x: int in SKY:
			var of := drift.get_pixel(x, y).r
			var tone := lerpf(KartDress.SHADE + 0.05, 1.0, smoothstep(0.25, 0.78, of))
			picture.set_pixel(x, y, Color.WHITE * tone)
	picture.generate_mipmaps()
	_sky = ImageTexture.create_from_image(picture)
	return _sky


## The stars: small soft points of light on black, some brighter and bigger than the rest, laid so
## that the tile repeats without a seam.
static func stars() -> ImageTexture:
	if _stars == null:
		_lay_stars()
	return _stars


## The stars' beats, laid as the stars are: each star's light in red and in green a beat of its own,
## the brighter star's where two meet, for the twinkle, see [method twinkle].
static func beats() -> ImageTexture:
	if _beats == null:
		_lay_stars()
	return _beats


static func _lay_stars() -> void:
	var picture := Image.create_empty(STARRY, STARRY, true, Image.FORMAT_RGB8)
	picture.fill(Color.BLACK)
	var beating := Image.create_empty(STARRY, STARRY, true, Image.FORMAT_RGB8)
	beating.fill(Color.BLACK)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i: int in STARS:
		var at := Vector2(rng.randf() * STARRY, rng.randf() * STARRY)
		var reach := STAR_REACH * (1.0 if rng.randf() < 0.2 else 0.55)
		var bright := rng.randf_range(0.55, 1.0)
		var beat := float(i) / STARS
		var span := ceili(reach * 2.0)
		for dy: int in range(-span, span + 1):
			for dx: int in range(-span, span + 1):
				var light := bright * exp(-float(dx * dx + dy * dy) / (reach * reach))
				var x := posmod(int(at.x) + dx, STARRY)
				var y := posmod(int(at.y) + dy, STARRY)
				var under := picture.get_pixel(x, y)
				picture.set_pixel(x, y, Color.WHITE * minf(under.r + light, 1.0))
				if light > beating.get_pixel(x, y).r:
					beating.set_pixel(x, y, Color(light, beat, 0.0))
	picture.generate_mipmaps()
	beating.generate_mipmaps()
	_stars = ImageTexture.create_from_image(picture)
	_beats = ImageTexture.create_from_image(beating)
