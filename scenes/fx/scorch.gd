class_name Scorch
extends MeshInstance3D
## The black mark a kart electrocuted by a live cabinet leaves on the floor where it died, GAME.md
## 6.2: a burn with a ragged edge lying flat, a little longer one way than the other and turned at
## random, so a cabinet that has killed a few times stands in a patch of them. It stays for the
## match; a room keeps the newest [constant MOST], the oldest fading away as another is laid, and
## goes with the arena.
##
## One quad, worn in the look a bullet's mark on a wall is, [BulletMark], so it compiles nothing of
## its own, its shape a blot with a ragged edge drawn once, see [method blot].

## How big it is across, in meters, and how much longer one way than the other at most.
const SIZE := 1.6
const STRETCH := 0.3
## How dark it is at its middle, how long it takes to come up as it is laid, and to go.
const ALPHA := 0.85
const LAY := 0.25
const FADE := 1.5
## How many a room keeps.
const MOST := 6
## How far over the floor it lies: over the floor's print and the road paint on it, see
## [constant HouseWord.ROAD_LIFT], under a kart's tires.
const LIFT := 0.02
## The burn's own black, a touch warm.
const INK := Color(0.05, 0.045, 0.04)

## The blot's picture: how many pixels across, how far out its edge is as a share of the picture's
## half, how ragged it is, and how far in from its edge it is wholly dark.
const PIXELS := 64
const EDGE := 0.8
const RAGGED := 0.16
const SOFT := 0.3

## How many have been laid, so the oldest is known.
static var _laid := 0
static var _blot: ImageTexture

var _age := 0.0
var _born := 0
var _going := -1.0
var _material: StandardMaterial3D


## Lays a scorch under [param parent] at [param at] on the floor, and asks the oldest of those
## already down to go if there are more than [constant MOST].
static func lay(parent: Node, at: Vector3) -> Scorch:
	var mark := Scorch.new()
	mark.name = "Scorch"
	_laid += 1
	mark._born = _laid
	mark._build()
	parent.add_child(mark)
	mark.global_position = Vector3(at.x, LIFT, at.z)
	mark.rotation.y = randf() * TAU
	var long := 1.0 + randf() * STRETCH
	mark.scale = Vector3(long, 1.0, 1.0 / sqrt(long))
	var kept: Array[Scorch] = []
	for node: Node in parent.get_children():
		var other := node as Scorch
		if other != null and other._going < 0.0:
			kept.append(other)
	kept.sort_custom(func(a: Scorch, b: Scorch) -> bool: return a._born < b._born)
	for i: int in kept.size() - MOST:
		kept[i]._going = 0.0
	return mark


## The burn's shape, made once: wholly dark in its middle and fading out to an edge that comes and
## goes round it, in white, the scorch's own black laid over it.
static func blot() -> ImageTexture:
	if _blot != null:
		return _blot
	var dice := RandomNumberGenerator.new()
	dice.seed = 17
	# The edge's reach round the blot, a few waves of it at random, so it is no circle.
	var waves: Array[Vector3] = []
	for i: int in 4:
		waves.append(Vector3(float(i + 2), dice.randf() * TAU, dice.randf_range(0.4, 1.0)))
	var image := Image.create_empty(PIXELS, PIXELS, false, Image.FORMAT_LA8)
	var half := PIXELS * 0.5
	for y: int in PIXELS:
		for x: int in PIXELS:
			var at := Vector2(x + 0.5 - half, y + 0.5 - half) / half
			var turn := at.angle()
			var reach := 0.0
			for wave: Vector3 in waves:
				reach += sin(turn * wave.x + wave.y) * wave.z
			var edge := EDGE * (1.0 + RAGGED * reach / waves.size())
			var dark := clampf((edge - at.length()) / SOFT, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, dark * dark * (3.0 - 2.0 * dark)))
	image.generate_mipmaps()
	_blot = ImageTexture.create_from_image(image)
	return _blot


## Whether it is on its way out, for the tests.
func going() -> bool:
	return _going >= 0.0


func _ready() -> void:
	add_to_group(&"scorches")


func _process(delta: float) -> void:
	_age += delta
	var alpha := ALPHA * minf(_age / LAY, 1.0)
	if _going >= 0.0:
		_going += delta
		if _going >= FADE:
			queue_free()
			return
		alpha *= 1.0 - _going / FADE
	_material.albedo_color.a = alpha


func _build() -> void:
	var quad := PlaneMesh.new()
	quad.size = Vector2(SIZE, SIZE)
	mesh = quad
	_material = StandardMaterial3D.new()
	_material.albedo_texture = blot()
	_material.albedo_color = Color(INK, 0.0)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.emission_enabled = true
	_material.emission = INK
	_material.emission_energy_multiplier = 0.5
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
