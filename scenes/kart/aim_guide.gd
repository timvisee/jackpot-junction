class_name AimGuide
extends Node3D
## Faint dots ahead of the cannon showing where a shot will go, for local players. Lives in world
## space and follows the kart's aim every drawn frame, from where the kart is drawn rather than
## from where its last physics tick left it: the kart is smoothed between ticks, and dots placed
## off the tick jumped back and forth against it wherever the screen draws faster than the
## physics runs, which on a phone at 90 Hz was every frame. So the engine does not smooth the
## dots again, see [method attach].

const DOTS := 4
const SPACING := 1.5
const RADIUS := 0.08
const ALPHA := 0.45
## How far a player may set it, GAME.md 8.5: from a short guide of fewer dots to a long one, from
## dots half the size to dots two and a half times it, and from barely there to solid; and the
## colors it may be drawn in: the player's own, white, or a yellow that stands off any felt.
const FEWEST := 2
const MOST := 8
const SMALLEST := 0.5
const BIGGEST := 2.5
const FAINTEST := 0.15
const STYLES: Array[String] = ["Player color", "White", "Yellow"]
const YELLOW := Color(1.0, 0.86, 0.18)

var _dots: Array[MeshInstance3D] = []
## The player's color, and what the dots were last built for, see [method _wanted].
var _color := Color.WHITE
var _built := []


static func attach(kart: Kart, color: Color) -> AimGuide:
	var guide := AimGuide.new()
	guide.name = "AimGuide"
	guide.top_level = true
	# Placed every drawn frame from the drawn kart: smoothing it again would put it a tick behind.
	guide.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	kart.add_child(guide)
	guide._build(color)
	return guide


func _build(color: Color) -> void:
	_color = color
	for dot: MeshInstance3D in _dots:
		dot.queue_free()
	_built = wanted()
	_dots = make_dots(color)
	for dot: MeshInstance3D in _dots:
		add_child(dot)


## The dots the settings ask for, for a player of [param color], not yet placed or in the tree: as
## many as the guide runs out to, as big and in the ink [method ink_of] gives. The Accessibility
## page's preview of them is made of these too, see [AimGuidePreview].
static func make_dots(color: Color) -> Array[MeshInstance3D]:
	var settings := Game.settings
	var material := StandardMaterial3D.new()
	material.albedo_color = ink_of(color, settings)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var radius := RADIUS * (settings.aim_guide_size if settings != null else 1.0)
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	# A dot a few pixels across: eight segments round it, GAME.md 10.7.
	mesh.radial_segments = 8
	mesh.rings = 4
	var dots: Array[MeshInstance3D] = []
	for i: int in settings.aim_guide_length if settings != null else DOTS:
		var dot := MeshInstance3D.new()
		dot.mesh = mesh
		dot.material_override = material
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dots.append(dot)
	return dots


## The dots in [param color] instead, for a player who has picked another one.
func paint(color: Color) -> void:
	_color = color
	if not _dots.is_empty():
		var material := _dots[0].material_override as StandardMaterial3D
		material.albedo_color = ink_of(color, Game.settings)


## What the dots are drawn in for a player of [param color], as [param settings] say: its color,
## white or yellow, as solid as they are set.
static func ink_of(color: Color, settings: Settings) -> Color:
	var style := settings.aim_guide_style if settings != null else 0
	var opacity := settings.aim_guide_opacity if settings != null else ALPHA
	var ink := color
	if style == 1:
		ink = Color.WHITE
	elif style == 2:
		ink = YELLOW
	return Color(ink, opacity)


## What the settings ask of the dots now: built again when it changes, as a player changes them
## over a room, see [method update_line].
static func wanted() -> Array:
	var settings := Game.settings
	if settings == null:
		return []
	return [
		settings.aim_guide_length,
		settings.aim_guide_size,
		settings.aim_guide_opacity,
		settings.aim_guide_style
	]


## Places the dots along the aim from the muzzle.
func update_line(muzzle: Vector3, direction: Vector3) -> void:
	if wanted() != _built:
		_build(_color)
	place(_dots, muzzle, direction)


## Places [param dots] along [param direction] from [param muzzle], [constant SPACING] apart at the
## height a shot flies.
static func place(dots: Array[MeshInstance3D], muzzle: Vector3, direction: Vector3) -> void:
	for i: int in dots.size():
		dots[i].global_position = muzzle + direction * (SPACING * (i + 1))
		dots[i].global_position.y = Bullet.HEIGHT
