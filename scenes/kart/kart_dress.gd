class_name KartDress
extends RefCounted
## What a [KartStyle] looks like, GAME.md 4.4. Kept apart from [KartVisuals] the way that is kept
## apart from [Kart]: one is what every kart is made of, this is what one player made of theirs.
##
## The paint patterns are tiny generated textures laid on by triplanar mapping, so the model needs
## no seams or unwrapping for them and the pattern sits on the kart rather than on the world. The
## player's colour multiplies through them, so a striped red kart is still unmistakably the red
## one.

## Side of a pattern texture, in pixels. Small on purpose: these are painted toys.
const PATTERN := 16
## The darker of the two tones a pattern is made of. The lighter one is the colour itself.
const SHADE := 0.55
## How many times a pattern wraps around the kart.
const PATTERN_SCALE := 1.6
## Where the driver's head is, in kart space, measured off the model rather than guessed: the
## character mesh tops out at 1.72 and a hat sits down on it rather than over it: a brim level
## with the crown reads as a hat hovering above somebody's head. The driver wears a round helmet
## the size of their shoulders, so a hat cut to fit a head looks like a badge on a ball: these
## are cut to the helmet.
const HEAD := Vector3(0.0, 1.63, -0.06)
const HEAD_RADIUS := 0.42
## How far above the head each hat reaches, so the roof marker can be lifted clear of it.
const HAT_LIFT: Array[float] = [0.0, 0.21, 0.46, 0.51, 0.59]
## Where a flag stands and how long its pole is. Clear of the bodywork, which is 1 m tall at the
## back, so the flag flies where it can be seen rather than inside the engine.
const FLAG := Vector3(0.0, 0.95, 0.5)
const POLE := 1.0

static var _patterns: Dictionary[int, Texture2D] = {}
## The chequered flag's squares, built once and shared by everybody flying one.
static var _chequers: Texture2D


## The tint a kart's body wears: its colour, with the pattern its owner picked laid over it.
static func paint(color: Color, style: KartStyle) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	var pattern := pattern_texture(style.paint)
	if pattern != null:
		material.albedo_texture = pattern
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.uv1_triplanar = true
		material.uv1_scale = Vector3.ONE * PATTERN_SCALE
	return material


## The pattern for a paint choice, built once and shared by every kart wearing it. Null for the
## plain one, which is a kart with nothing painted on it.
static func pattern_texture(paint_index: int) -> Texture2D:
	if paint_index <= 0:
		return null
	if _patterns.has(paint_index):
		return _patterns[paint_index]
	var image := Image.create_empty(PATTERN, PATTERN, false, Image.FORMAT_RGB8)
	for y: int in PATTERN:
		for x: int in PATTERN:
			image.set_pixel(x, y, Color.WHITE if _lit(paint_index, x, y) else _shade())
	var texture := ImageTexture.create_from_image(image)
	_patterns[paint_index] = texture
	return texture


## Whether one pixel of a pattern is the light tone: diagonal bands, a chequerboard, or a dot in
## the middle of every quarter.
static func _lit(paint_index: int, x: int, y: int) -> bool:
	var quarter := PATTERN / 4
	match paint_index:
		1:
			return ((x + y) / quarter) % 2 == 0
		2:
			return ((x / quarter) + (y / quarter)) % 2 == 0
	var half := PATTERN / 2
	var inside := Vector2(x % half, y % half) - Vector2.ONE * (half * 0.5 - 0.5)
	return inside.length() > half * 0.28


static func _shade() -> Color:
	return Color(SHADE, SHADE, SHADE)


## The hat a player picked, ready to hang off the kart's body, or null for a bare head.
static func hat(index: int, color: Color) -> Node3D:
	if index <= 0 or index >= KartStyle.HATS.size():
		return null
	var worn := Node3D.new()
	worn.name = "Hat"
	worn.position = HEAD
	var dark := Color(0.12, 0.12, 0.15)
	match index:
		1:
			worn.add_child(_disc(HEAD_RADIUS * 0.95, 0.16, color, 0.08))
			var peak := _block(Vector3(HEAD_RADIUS * 1.5, 0.06, HEAD_RADIUS * 1.1), color)
			peak.position = Vector3(0.0, 0.04, -HEAD_RADIUS * 0.85)
			worn.add_child(peak)
		2:
			worn.add_child(_disc(HEAD_RADIUS * 1.25, 0.05, dark, 0.02))
			worn.add_child(_disc(HEAD_RADIUS * 0.8, 0.42, dark, 0.25))
			worn.add_child(_disc(HEAD_RADIUS * 0.83, 0.1, color, 0.13))
		3:
			worn.add_child(_disc(HEAD_RADIUS * 0.9, 0.18, Palette.CHIP_GOLD, 0.09))
			for i: int in 5:
				var angle := TAU * i / 5.0
				var spike := _spike(0.1, 0.3, Palette.CHIP_GOLD)
				spike.position = Vector3(
					cos(angle) * HEAD_RADIUS * 0.7, 0.32, sin(angle) * HEAD_RADIUS * 0.7
				)
				worn.add_child(spike)
		_:
			worn.add_child(_spike(HEAD_RADIUS * 0.85, 0.46, color, 0.23))
			worn.add_child(_disc(0.1, 0.1, Palette.CHIP_WHITE, 0.5))
	return worn


## The flag a player picked, on its pole at the back of the kart, or null for none. All of them
## are the player's colour except the chequered one, which is the colour a chequered flag is.
static func flag(index: int, color: Color) -> Node3D:
	if index <= 0 or index >= KartStyle.FLAGS.size():
		return null
	var flown := Node3D.new()
	flown.name = "Flag"
	flown.position = FLAG
	# Turned a quarter so the flag flies off the back of the kart rather than out of its side,
	# which is where a flag on a kart belongs and which keeps it out of the driver's way.
	flown.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	flown.add_child(_disc(0.03, POLE, Color(0.16, 0.16, 0.18), 0.0))
	if index == 1:
		var pennant := MeshInstance3D.new()
		pennant.mesh = _pennant_mesh()
		pennant.material_override = _flat(color)
		pennant.rotation_degrees = Vector3(0.0, 0.0, -90.0)
		pennant.position = Vector3(0.3, POLE * 0.32, 0.0)
		flown.add_child(pennant)
	else:
		var banner := _block(Vector3(0.52, 0.34, 0.03), color)
		if index == 3:
			banner.material_override = _chequered()
		banner.position = Vector3(0.28, POLE * 0.3, 0.0)
		flown.add_child(banner)
	return flown


## The chequered flag: the one flag in the game that is not the player's colour, because a
## chequered flag that is red and a darker red is not a chequered flag.
static func _chequered() -> StandardMaterial3D:
	var material := _flat(Color.WHITE)
	material.albedo_texture = _chequer_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.uv1_scale = Vector3(3.0, 2.0, 1.0)
	return material


static func _chequer_texture() -> Texture2D:
	if _chequers != null:
		return _chequers
	var image := Image.create_empty(2, 2, false, Image.FORMAT_RGB8)
	for y: int in 2:
		for x: int in 2:
			image.set_pixel(x, y, Color.WHITE if (x + y) % 2 == 0 else Color(0.06, 0.06, 0.07))
	_chequers = ImageTexture.create_from_image(image)
	return _chequers


static func _pennant_mesh() -> PrismMesh:
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.34, 0.52, 0.03)
	mesh.left_to_right = 0.0
	return mesh


static func _disc(radius: float, height: float, color: Color, lift: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.material_override = _flat(color)
	node.position = Vector3(0.0, lift, 0.0)
	return node


static func _block(size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _flat(color)
	return node


static func _spike(radius: float, height: float, color: Color, lift: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.material_override = _flat(color)
	node.position = Vector3(0.0, lift, 0.0)
	return node


static func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
