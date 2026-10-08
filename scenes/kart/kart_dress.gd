class_name KartDress
extends RefCounted
## What a [KartStyle] looks like, GAME.md 4.4. Kept apart from [KartVisuals] the way that is kept
## apart from [Kart]: one is what every kart is made of, this is what one player made of theirs.
##
## The paint patterns are tiny generated textures laid on by triplanar mapping, so the model needs
## no seams or unwrapping for them and the pattern sits on the kart rather than on the world. The
## player's color multiplies through them, so a striped red kart is still unmistakably the red
## one.

## Side of a pattern texture, in pixels. Big enough that a stripe has a clean edge rather than a
## staircase: the kart is a hand's width on screen but the camera comes right down to it on the
## podium, and a sixteen-pixel pattern looked like a sixteen-pixel pattern there.
const PATTERN := 128
## The darker of the two tones a pattern is made of. The lighter one is the color itself. Dark
## enough for a pattern to read on a kart, light enough that the color is the color under it.
const SHADE := 0.4
## The card suits' ink, near black, as a deck's spades are: in the shade they were dark color on
## color and did not read as suits at all. The one pattern darker than the shade, and only a
## third of it, so the color is still the color.
const SUIT_INK := 0.12
## How many times a pattern wraps around the kart, and for each paint how much of that: a pair of
## racing stripes is as wide as the kart, and a suit as small as a part of it, since a suit bigger
## than the part it is printed on is no suit at all.
const PATTERN_SCALE := 1.6
const PAINT_SCALES: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.5, 0.42, 0.8, 0.85]
## Where the driver's head is, in kart space, measured off the model rather than guessed: the
## character mesh tops out at 1.72 and a hat sits down on it rather than over it: a brim level
## with the crown reads as a hat hovering above somebody's head. The driver wears a round helmet
## the size of their shoulders, so a hat cut to fit a head looks like a badge on a ball: these
## are cut to the helmet.
const HEAD := Vector3(0.0, 1.63, -0.06)
const HEAD_RADIUS := 0.42
## How far above the head each hat reaches, so the roof marker can be lifted clear of it.
const HAT_LIFT: Array[float] = [
	0.0, 0.21, 0.46, 0.51, 0.59, 0.5, 0.16, 0.36, 0.42, 0.26, 0.4, 0.62, 0.3, 0.14, 0.3
]
## The learner's block, GAME.md 9.4a: a white cube the driving school's L is painted on, worn
## square on the helmet, and how big.
const LEARNER_SIDE := 0.44
const LEARNER_WHITE := Color(0.95, 0.95, 0.93)
## Where a flag stands and how long its pole is. Clear of the bodywork, which is 1 m tall at the
## back, so the flag flies where it can be seen rather than inside the engine.
const FLAG := Vector3(0.0, 0.95, 0.5)
const POLE := 1.0

## The colors of the things that are what they are whatever the player's color: a dealer's green
## visor, a felt hat, a fin, bone, a traffic cone, a hard hat, brass, newspaper, a measuring tape
## and an oily rag.
const VISOR_GREEN := Color(0.09, 0.42, 0.27)
const FELT := Color(0.2, 0.17, 0.15)
const FIN_GRAY := Color(0.47, 0.52, 0.58)
const BONE := Color(0.93, 0.89, 0.8)
const CONE_ORANGE := Color(1.0, 0.42, 0.06)
const HARD_HAT_YELLOW := Color(1.0, 0.78, 0.08)
const LEATHER := Color(0.25, 0.17, 0.1)
const BRASS := Color(0.72, 0.56, 0.24)
const SMOKED_GLASS := Color(0.08, 0.12, 0.1)
const NEWSPAPER := Color(0.9, 0.88, 0.82)
const TAPE_YELLOW := Color(1.0, 0.82, 0.12)
const RAG := Color(0.45, 0.4, 0.33)
## How big a fuzzy die is.
const DIE := 0.21

static var _patterns: Dictionary[int, Texture2D] = {}
## The checkered flag's squares, built once and shared by everybody flying one.
static var _checkers: Texture2D
## The ace of spades' face, a die's six faces for each player color, and newsprint, each made
## once.
static var _ace_face: Texture2D
static var _dice: Dictionary[Color, Texture2D] = {}
static var _newsprint: Texture2D


## The tint a kart's body wears: its color, with the pattern its owner picked laid over it.
static func paint(color: Color, style: KartStyle) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	# Painted and lacquered, GAME.md 8.1: a kart is a toy off a shelf rather than a block of
	# color, and the coat is what catches the room's lamp as it turns.
	material.roughness = 0.34
	material.metallic_specular = 0.6
	material.clearcoat_enabled = true
	material.clearcoat = 0.55
	material.clearcoat_roughness = 0.15
	# And a little of the light wraps round the edge of it, so a kart reads against a dark felt.
	material.rim_enabled = true
	material.rim = 0.45
	material.rim_tint = 0.35
	var pattern := pattern_texture(style.paint)
	if pattern != null:
		material.albedo_texture = pattern
		# Smoothed and mip-mapped rather than snapped to the pixel: a kart is a painted toy, not
		# a sprite, and a hard-edged pattern shimmers as it drives away.
		# Seen at a slant from the camera over the table, so filtered for that.
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		material.uv1_triplanar = true
		# Each face takes the pattern laid on from the side it faces rather than a blend of three,
		# which on a curved part is the pattern three times over, out of step and blurred.
		material.uv1_triplanar_sharpness = 40.0
		material.uv1_scale = Vector3.ONE * PATTERN_SCALE * PAINT_SCALES[style.paint]
	return material


## The pattern for a paint choice, built once and shared by every kart wearing it. Null for the
## plain one, which is a kart with nothing painted on it. Each pixel is the tone of four points in
## it, so an edge is clean rather than a staircase.
static func pattern_texture(paint_index: int) -> Texture2D:
	if paint_index <= 0:
		return null
	if _patterns.has(paint_index):
		return _patterns[paint_index]
	var image := Image.create_empty(PATTERN, PATTERN, true, Image.FORMAT_RGB8)
	var points: Array[Vector2] = [
		Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)
	]
	for y: int in PATTERN:
		for x: int in PATTERN:
			var tone := 0.0
			for point: Vector2 in points:
				tone += _tone(paint_index, (Vector2(x, y) + point) / float(PATTERN))
			image.set_pixel(x, y, Color.WHITE * (tone * 0.25))
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_patterns[paint_index] = texture
	return texture


## How light a pattern is at [param at], across and down it from 0 to 1, as a share of the color,
## never darker than [constant SHADE], so the color is the color whatever is painted over it: the
## light tone or the shade for the two-tone patterns, and a patch's own tone for the patchwork.
static func _tone(paint_index: int, at: Vector2) -> float:
	var lit := true
	match paint_index:
		1:
			# Diagonal bands.
			lit = int(floorf((at.x + at.y) * 4.0)) % 2 == 0
		2:
			# A checkerboard.
			lit = (int(floorf(at.x * 4.0)) + int(floorf(at.y * 4.0))) % 2 == 0
		3:
			# A big round spot in the middle of every quarter.
			lit = (_quarter(at) * 2.0).length() > 0.34 * 2.0
		4:
			return SUIT_INK if _suit_at(at) else 1.0
		5:
			lit = not _stripe_at(at)
		6:
			lit = not _flame_at(at)
		7:
			return _patch_at(at)
	return 1.0 if lit else SHADE


## Where [param at] is in its quarter of the pattern, from its middle, each way from -0.5 to 0.5.
static func _quarter(at: Vector2) -> Vector2:
	return Vector2(fposmod(at.x * 2.0, 1.0), fposmod(at.y * 2.0, 1.0)) - Vector2.ONE * 0.5


## Card suits: one big in each quarter of the pattern, a heart, a diamond, a club and a spade, in
## the shade on the color.
static func _suit_at(at: Vector2) -> bool:
	var which := int(floorf(at.x * 2.0)) % 2 + 2 * (int(floorf(at.y * 2.0)) % 2)
	var suit := _quarter(at) * 2.05
	match which:
		0:
			return _heart(suit)
		1:
			return absf(suit.x) / 0.72 + absf(suit.y) / 1.05 <= 1.0
		2:
			return _club(suit)
	return _spade(suit)


static func _heart(at: Vector2) -> bool:
	for side: float in [-1.0, 1.0]:
		if at.distance_to(Vector2(side * 0.48, -0.32)) <= 0.54:
			return true
	return at.y >= -0.32 and at.y <= 1.0 and absf(at.x) <= 1.02 * (1.0 - at.y) / 1.32


static func _club(at: Vector2) -> bool:
	for middle: Vector2 in [Vector2(0.0, -0.5), Vector2(-0.48, 0.12), Vector2(0.48, 0.12)]:
		if at.distance_to(middle) <= 0.42:
			return true
	return _stem(at)


## A spade: a heart upside down, its point at the top, and under its lobes a stem flaring to its
## foot, the whole of it from -1.1 to 1.1 down.
static func _spade(at: Vector2) -> bool:
	if _heart(Vector2(at.x, -at.y - 0.1)):
		return true
	return at.y > 0.45 and at.y < 1.1 and absf(at.x) < 0.07 + (at.y - 0.45) * 0.4


static func _stem(at: Vector2) -> bool:
	return at.y > 0.25 and at.y < 1.0 and absf(at.x) < 0.1 + (at.y - 0.25) * 0.35


## Racing stripes: two bands side by side, one either side of the pattern's edge, which is the
## middle of the kart: the pattern starts where the kart does.
static func _stripe_at(at: Vector2) -> bool:
	var across := fposmod(at.x, 1.0)
	return (across >= 0.03 and across < 0.14) or (across >= 0.86 and across < 0.97)


## Flames: tongues licking up from the foot of the pattern, the tall ones between short ones.
static func _flame_at(at: Vector2) -> bool:
	var wave := absf(sin(at.x * PI * 4.0))
	var tall := 0.23 + 0.31 * wave * wave + 0.06 * sin(at.x * PI * 14.2)
	return at.y > 1.0 - tall


## Patchwork: patches of cloth in tones of the color, stitched together with a dashed seam.
static func _patch_at(at: Vector2) -> float:
	var columns: Array[float] = [0.0, 0.31, 0.69]
	var rows: Array[float] = [0.0, 0.41, 0.75]
	var tones: Array[float] = [1.0, 0.68, 0.48, 0.86, 0.42, 0.62, 0.95, 0.54, 0.78]
	var column := 0
	var row := 0
	for i: int in 3:
		if at.x >= columns[i]:
			column = i
		if at.y >= rows[i]:
			row = i
	var near := at.x - columns[column] < 0.016 or at.y - rows[row] < 0.016
	var seam := near and int(floorf((at.x + at.y) * 32.0)) % 2 == 0
	return SHADE if seam else tones[column + 3 * row]


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
			_crown(worn)
		5:
			worn.add_child(_learner_block())
		6:
			_visor(worn)
		7:
			_fedora(worn, color)
		8:
			var fin := _prism(Vector3(0.72, 0.56, 0.08), 0.85, FIN_GRAY)
			fin.rotation_degrees = Vector3(0.0, -90.0, 0.0)
			fin.position = Vector3(0.0, 0.24, 0.0)
			worn.add_child(fin)
		9:
			_ear_defenders(worn, color)
		10:
			for side: float in [-1.0, 1.0]:
				var horn := _spike(0.09, 0.42, BONE)
				horn.position = Vector3(side * HEAD_RADIUS * 0.62, 0.12, 0.0)
				horn.rotation_degrees = Vector3(0.0, 0.0, -side * 38.0)
				worn.add_child(horn)
		11:
			_traffic_cone(worn)
		12:
			_hard_hat(worn)
		13:
			_welding_goggles(worn)
		14:
			worn.add_child(_paper_hat())
		_:
			worn.add_child(_spike(HEAD_RADIUS * 0.85, 0.46, color, 0.23))
			worn.add_child(_disc(0.1, 0.1, Palette.CHIP_WHITE, 0.5))
	return worn


## A crown with nothing pointed on it: a gold band, a red velvet cap rising inside it, a gold
## ball on its rim at every eighth of the way round and a red jewel at the front.
static func _crown(worn: Node3D) -> void:
	var band := _disc(HEAD_RADIUS * 0.86, 0.2, Palette.CHIP_GOLD, 0.1)
	var tube := band.mesh as CylinderMesh
	tube.cap_top = false
	(band.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	worn.add_child(band)
	var cap := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = HEAD_RADIUS * 0.8
	dome.height = HEAD_RADIUS * 0.8
	dome.is_hemisphere = true
	cap.mesh = dome
	cap.material_override = _flat(Color(0.62, 0.08, 0.12))
	cap.position = Vector3(0.0, 0.06, 0.0)
	worn.add_child(cap)
	for i: int in 8:
		var angle := TAU * i / 8.0
		var ball := MeshInstance3D.new()
		var round_mesh := SphereMesh.new()
		round_mesh.radius = 0.05
		round_mesh.height = 0.1
		ball.mesh = round_mesh
		ball.material_override = _flat(Palette.CHIP_GOLD)
		ball.position = Vector3(cos(angle), 0.0, sin(angle)) * HEAD_RADIUS * 0.86
		ball.position.y = 0.22
		worn.add_child(ball)
	var jewel := _disc(0.05, 0.03, Color(0.86, 0.1, 0.16), 0.0)
	jewel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	jewel.position = Vector3(0.0, 0.1, -HEAD_RADIUS * 0.87)
	worn.add_child(jewel)


## A dealer's eyeshade: a green band round the helmet and a green peak out over the eyes.
static func _visor(worn: Node3D) -> void:
	var band := _torus(HEAD_RADIUS * 0.84, HEAD_RADIUS * 0.94, VISOR_GREEN.darkened(0.3))
	band.position = Vector3(0.0, -0.1, 0.0)
	worn.add_child(band)
	var brim := _block(Vector3(HEAD_RADIUS * 1.5, 0.025, HEAD_RADIUS * 0.95), VISOR_GREEN)
	brim.position = Vector3(0.0, -0.08, -HEAD_RADIUS * 1.15)
	brim.rotation_degrees = Vector3(-14.0, 0.0, 0.0)
	worn.add_child(brim)


## A fedora: a felt crown with a dent along its top, a wide brim, and a band in the player's color.
static func _fedora(worn: Node3D, color: Color) -> void:
	worn.add_child(_disc(HEAD_RADIUS * 1.35, 0.04, FELT, 0.02))
	var crown := _disc(HEAD_RADIUS * 0.72, 0.3, FELT, 0.19)
	(crown.mesh as CylinderMesh).bottom_radius = HEAD_RADIUS * 0.82
	worn.add_child(crown)
	worn.add_child(_disc(HEAD_RADIUS * 0.84, 0.07, color, 0.08))
	var dent := _block(Vector3(0.08, 0.06, HEAD_RADIUS * 1.0), FELT.darkened(0.25))
	dent.position = Vector3(0.0, 0.33, 0.0)
	worn.add_child(dent)


## Ear defenders, the shooting range's: a band over the top of the helmet and a cup in the
## player's color over each side.
static func _ear_defenders(worn: Node3D, color: Color) -> void:
	var band := _torus(HEAD_RADIUS * 1.0, HEAD_RADIUS * 1.1, Color(0.14, 0.14, 0.17))
	band.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	band.position = Vector3(0.0, -0.32, 0.0)
	worn.add_child(band)
	for side: float in [-1.0, 1.0]:
		var cup := _disc(0.17, 0.13, color, 0.0)
		cup.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		cup.position = Vector3(side * HEAD_RADIUS * 1.08, -0.32, 0.0)
		worn.add_child(cup)


## The driving school's traffic cone, lost: orange, on a square foot, with a white band round it.
static func _traffic_cone(worn: Node3D) -> void:
	var foot := _block(Vector3(0.62, 0.05, 0.62), CONE_ORANGE.darkened(0.2))
	foot.position = Vector3(0.0, 0.025, 0.0)
	worn.add_child(foot)
	worn.add_child(_spike(0.27, 0.62, CONE_ORANGE, 0.36))
	var band := _disc(0.0, 0.09, Palette.CHIP_WHITE, 0.335)
	var mesh := band.mesh as CylinderMesh
	mesh.bottom_radius = 0.27 * (1.0 - 0.24 / 0.62) * 1.04
	mesh.top_radius = 0.27 * (1.0 - 0.33 / 0.62) * 1.04
	worn.add_child(band)


## The Yard's hard hat, the one nobody came back for: a yellow dome with a ridge down it and a brim.
static func _hard_hat(worn: Node3D) -> void:
	worn.add_child(_disc(HEAD_RADIUS * 1.18, 0.035, HARD_HAT_YELLOW, 0.0))
	var dome := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	# A hemisphere is a regular one only as tall as it is round.
	sphere.radius = 0.43
	sphere.height = 0.43
	sphere.is_hemisphere = true
	dome.mesh = sphere
	dome.material_override = _flat(HARD_HAT_YELLOW)
	dome.position = Vector3(0.0, -0.13, 0.0)
	worn.add_child(dome)
	var ridge := _block(Vector3(0.08, 0.06, HEAD_RADIUS * 1.4), HARD_HAT_YELLOW.darkened(0.1))
	ridge.position = Vector3(0.0, 0.25, 0.0)
	worn.add_child(ridge)


## Welding goggles pushed up on the helmet: a leather strap round it and two smoked lenses in
## brass rims at the front.
static func _welding_goggles(worn: Node3D) -> void:
	var strap := _torus(HEAD_RADIUS * 0.82, HEAD_RADIUS * 0.9, LEATHER)
	strap.position = Vector3(0.0, -0.14, 0.0)
	worn.add_child(strap)
	for side: float in [-1.0, 1.0]:
		var rim := _disc(0.11, 0.07, BRASS, 0.0)
		rim.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		rim.position = Vector3(side * 0.14, -0.13, -HEAD_RADIUS * 0.86)
		worn.add_child(rim)
		var glass := _disc(0.085, 0.075, SMOKED_GLASS, 0.0)
		glass.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		glass.position = Vector3(side * 0.14, -0.13, -HEAD_RADIUS * 0.88)
		worn.add_child(glass)


## The learner's block: the driving school's white cube with the L on its four sides and its top,
## the top being what the camera sees most of, sitting square on the helmet, facing the way the
## kart does, the same for every player since the L is the L whoever wears it.
static func _learner_block() -> Node3D:
	var block := Node3D.new()
	block.name = "LearnerBlock"
	block.position = Vector3(0.0, LEARNER_SIDE * 0.5, 0.0)
	block.add_child(_block(Vector3.ONE * LEARNER_SIDE, LEARNER_WHITE))
	var drawn := DrawnTexture.of(
		block, SchoolFigure.of(SchoolFigure.Kind.LEARNER, 128.0), Vector2i(128, 128)
	)
	var decal := DrawnTexture.decal(drawn)
	var side := Vector2.ONE * LEARNER_SIDE * 0.84
	var out := LEARNER_SIDE * 0.5 + 0.005
	for i: int in 4:
		var turn := PI * 0.5 * float(i)
		var face := DrawnTexture.face(side, decal)
		face.position = Vector3(sin(turn), 0.0, cos(turn)) * out
		face.rotation.y = turn
		block.add_child(face)
	var top := DrawnTexture.face(side, decal)
	top.position = Vector3(0.0, out, 0.0)
	top.rotation.x = -PI * 0.5
	block.add_child(top)
	return block


## The flag a player picked, on its pole at the back of the kart, or null for none. All of them
## are the player's color except the checkered one, which is the color a checkered flag is.
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
	# What flies is hung off a pivot where it meets the pole, for [DressSway] to move.
	var sway := DressSway.new()
	sway.name = "Sway"
	match index:
		1:
			var cloth := _pivot(flown, Vector3(0.0, POLE * 0.32, 0.0))
			var pennant := MeshInstance3D.new()
			pennant.mesh = _pennant_mesh()
			pennant.material_override = _flat(color)
			pennant.rotation_degrees = Vector3(0.0, 0.0, -90.0)
			pennant.position = Vector3(0.3, 0.0, 0.0)
			cloth.add_child(pennant)
			sway.pivots = [cloth]
		4:
			var cloth := _pivot(flown, Vector3(0.0, POLE * 0.3, 0.0))
			cloth.add_child(_ace())
			sway.pivots = [cloth]
		5:
			sway.kind = DressSway.Kind.SOCK
			sway.pivots = [_windsock(flown, color)]
		6:
			sway.pivots = [_tape_measure(flown)]
		7:
			sway.kind = DressSway.Kind.DICE
			sway.pivots = _fuzzy_dice(flown, color)
		8:
			var cloth := _pivot(flown, Vector3(0.0, POLE * 0.3, 0.0))
			var rag := _block(Vector3(0.46, 0.3, 0.025), RAG)
			rag.position = Vector3(0.26, 0.0, 0.0)
			rag.rotation_degrees = Vector3(0.0, 0.0, -6.0)
			cloth.add_child(rag)
			var stain := _block(Vector3(0.2, 0.12, 0.03), RAG.darkened(0.35))
			stain.position = Vector3(0.32, -0.03, 0.0)
			cloth.add_child(stain)
			var torn := _block(Vector3(0.14, 0.12, 0.025), RAG.lightened(0.08))
			torn.position = Vector3(0.42, -0.13, 0.0)
			torn.rotation_degrees = Vector3(0.0, 0.0, 12.0)
			cloth.add_child(torn)
			sway.pivots = [cloth]
		_:
			var cloth := _pivot(flown, Vector3(0.0, POLE * 0.3, 0.0))
			var banner := _block(Vector3(0.52, 0.34, 0.03), color)
			if index == 3:
				banner.material_override = _checkered()
			banner.position = Vector3(0.28, 0.0, 0.0)
			cloth.add_child(banner)
			sway.pivots = [cloth]
	flown.add_child(sway)
	return flown


## A pivot on [param flown] at [param at], what flies from the pole there hung off it.
static func _pivot(flown: Node3D, at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "Cloth"
	pivot.position = at
	flown.add_child(pivot)
	return pivot


## The ace of spades on its pivot: a white card, its face printed on either side, since a box
## spreads one picture over its six, and its spade black whatever the player's color, which on a
## yellow kart would be no spade at all.
static func _ace() -> Node3D:
	var card := _block(Vector3(0.34, 0.48, 0.02), Color(0.97, 0.96, 0.93))
	card.position = Vector3(0.22, 0.0, 0.0)
	var face := _flat(Color.WHITE)
	face.albedo_texture = _ace_texture()
	for side: float in [-1.0, 1.0]:
		var printed := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.33, 0.47)
		printed.mesh = quad
		printed.material_override = face
		printed.position = Vector3(0.0, 0.0, side * 0.0105)
		printed.rotation_degrees = Vector3(0.0, 0.0 if side > 0.0 else 180.0, 0.0)
		card.add_child(printed)
	return card


## A windsock off the top of the pole, in bands of the player's color and white, narrowing away,
## on a pivot at the pole.
static func _windsock(flown: Node3D, color: Color) -> Node3D:
	var sock := _pivot(flown, Vector3(0.03, POLE * 0.42, 0.0))
	var ring := _torus(0.13, 0.155, Color(0.16, 0.16, 0.18))
	ring.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	ring.position = Vector3(0.0, 0.0, 0.0)
	sock.add_child(ring)
	for i: int in 3:
		var band := _disc(0.0, 0.2, color if i % 2 == 0 else Palette.CHIP_WHITE, 0.0)
		var mesh := band.mesh as CylinderMesh
		mesh.bottom_radius = 0.15 - 0.03 * float(i)
		mesh.top_radius = 0.15 - 0.03 * float(i + 1)
		band.rotation_degrees = Vector3(0.0, 0.0, -90.0)
		band.position = Vector3(0.1 + 0.2 * float(i), 0.0, 0.0)
		sock.add_child(band)
	return sock


## The Workbench's tape measure, lost: its case on the pole and its yellow tape run out from it,
## the tape on a pivot at the case.
static func _tape_measure(flown: Node3D) -> Node3D:
	var case := _disc(0.11, 0.07, TAPE_YELLOW.darkened(0.15), 0.0)
	case.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	case.position = Vector3(0.0, POLE * 0.44, 0.0)
	flown.add_child(case)
	var tape := _pivot(flown, Vector3(0.0, POLE * 0.4, 0.0))
	var strip := _block(Vector3(0.8, 0.045, 0.006), TAPE_YELLOW)
	strip.position = Vector3(0.42, 0.0, 0.0)
	strip.rotation_degrees = Vector3(0.0, 0.0, -8.0)
	tape.add_child(strip)
	return tape


## After Hours' fuzzy dice, lost: a crossbar off the top of the pole and two dice in the player's
## color hanging from it on strings, pips on every face. Each die and its string on a pivot where
## the string is tied, for [DressSway] to swing.
static func _fuzzy_dice(flown: Node3D, color: Color) -> Array[Node3D]:
	var top := POLE * 0.5
	var bar := _block(Vector3(0.36, 0.025, 0.025), Color(0.16, 0.16, 0.18))
	bar.position = Vector3(0.17, top - 0.02, 0.0)
	flown.add_child(bar)
	var die_skin := _flat(Color.WHITE)
	die_skin.albedo_texture = _dice_texture(color)
	var pivots: Array[Node3D] = []
	for i: int in 2:
		var tied := Node3D.new()
		tied.name = "Die%d" % i
		tied.position = Vector3(0.12 + 0.18 * float(i), top - 0.03, 0.0)
		flown.add_child(tied)
		var drop := 0.14 + 0.06 * float(i)
		var cord := _disc(0.008, drop, Color(0.9, 0.9, 0.92), 0.0)
		cord.position = Vector3(0.0, -drop * 0.5, 0.0)
		tied.add_child(cord)
		var die := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * DIE
		die.mesh = box
		die.material_override = die_skin
		die.position = Vector3(0.0, -drop - DIE * 0.5, 0.0)
		# The second turned onto another face, so the two show different faces the same way.
		die.rotation_degrees = Vector3(90.0 * float(i), 20.0 + 35.0 * float(i), 90.0 * float(i))
		tied.add_child(die)
		pivots.append(tied)
	return pivots


## The face of the ace of spades: a white card, a big black spade in the middle and a small one in
## two corners, made once.
static func _ace_texture() -> Texture2D:
	if _ace_face != null:
		return _ace_face
	var wide := 128
	var tall := 180
	var image := Image.create_empty(wide, tall, true, Image.FORMAT_RGB8)
	var card := Color(0.97, 0.96, 0.93)
	var spade := Color(0.06, 0.06, 0.08)
	for y: int in tall:
		for x: int in wide:
			var big := (Vector2(x, y) - Vector2(wide * 0.5, tall * 0.5)) / 34.0
			var small := (Vector2(x, y) - Vector2(20.0, 24.0)) / 10.0
			var other := (Vector2(x, y) - Vector2(wide - 22.0, tall - 26.0)) / 10.0
			var inked := false
			for at: Vector2 in [big, small, other]:
				inked = inked or _spade(at)
			image.set_pixel(x, y, spade if inked else card)
	image.generate_mipmaps()
	_ace_face = ImageTexture.create_from_image(image)
	return _ace_face


## A die's six faces for [param color], laid out as a box lays a picture over its faces, three
## across and two down: white pips on the color, one to six, made once for each color.
static func _dice_texture(color: Color) -> Texture2D:
	if _dice.has(color):
		return _dice[color]
	var cell := 32
	var image := Image.create_empty(cell * 3, cell * 2, true, Image.FORMAT_RGB8)
	var pips: Array[Array] = [
		[Vector2(0.5, 0.5)],
		[Vector2(0.27, 0.27), Vector2(0.73, 0.73)],
		[Vector2(0.27, 0.27), Vector2(0.5, 0.5), Vector2(0.73, 0.73)],
		[Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
		[
			Vector2(0.27, 0.27),
			Vector2(0.73, 0.27),
			Vector2(0.5, 0.5),
			Vector2(0.27, 0.73),
			Vector2(0.73, 0.73)
		],
		[
			Vector2(0.27, 0.25),
			Vector2(0.73, 0.25),
			Vector2(0.27, 0.5),
			Vector2(0.73, 0.5),
			Vector2(0.27, 0.75),
			Vector2(0.73, 0.75)
		],
	]
	var pip := Color(0.97, 0.97, 0.95)
	for face: int in 6:
		var corner := Vector2i((face % 3) * cell, (face / 3) * cell)
		for y: int in cell:
			for x: int in cell:
				var at := Vector2(x + 0.5, y + 0.5) / float(cell)
				var white := false
				for dot: Vector2 in pips[face]:
					white = white or at.distance_to(dot) < 0.1
				image.set_pixel(corner.x + x, corner.y + y, pip if white else color)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_dice[color] = texture
	return texture


## The paper hat folded out of a newspaper: a triangle across the head from the front, and from
## the side a narrower one opened out round the head, on the band folded up round its foot, both
## printed with columns of type.
static func _paper_hat() -> Node3D:
	var hat := Node3D.new()
	var print_skin := _flat(Color.WHITE)
	print_skin.albedo_texture = _newsprint_texture()
	print_skin.cull_mode = BaseMaterial3D.CULL_DISABLED
	var wide := 0.44
	var deep := 0.12
	var tall := 0.38
	var apex := Vector3(0.0, tall, 0.0)
	var corners: Array[Vector3] = [
		Vector3(-wide, 0.0, -deep),
		Vector3(wide, 0.0, -deep),
		Vector3(wide, 0.0, deep),
		Vector3(-wide, 0.0, deep),
	]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in 4:
		var a := corners[i]
		var b := corners[(i + 1) % 4]
		var normal := (apex - a).cross(b - a).normalized()
		for corner: Array in [
			[a, Vector2(0.0, 1.0)], [b, Vector2(1.0, 1.0)], [apex, Vector2(0.5, 0.0)]
		]:
			tool.set_normal(normal)
			tool.set_uv(corner[1])
			tool.add_vertex(corner[0])
	var folded := MeshInstance3D.new()
	folded.mesh = tool.commit()
	folded.material_override = print_skin
	folded.position = Vector3(0.0, -0.03, 0.0)
	hat.add_child(folded)
	var band := _block(Vector3(wide * 2.0 + 0.02, 0.09, deep * 2.0 + 0.04), NEWSPAPER)
	band.material_override = print_skin
	band.position = Vector3(0.0, -0.035, 0.0)
	hat.add_child(band)
	return hat


## Newsprint: off-white paper and gray columns of type, a headline across the top, made once.
static func _newsprint_texture() -> Texture2D:
	if _newsprint != null:
		return _newsprint
	var side := 128
	var image := Image.create_empty(side, side, true, Image.FORMAT_RGB8)
	var paper := NEWSPAPER
	var type_ink := Color(0.74, 0.73, 0.7)
	var headline := Color(0.45, 0.44, 0.42)
	for y: int in side:
		for x: int in side:
			var ink := paper
			if y >= 10 and y < 18 and x >= 12 and x < side - 12:
				ink = headline
			elif y >= 26 and (y - 26) % 6 == 0:
				var column := x % 42
				var line := (y - 26) / 6
				if column >= 4 and column < 38 - (line * 11) % 13:
					ink = type_ink
			image.set_pixel(x, y, ink)
	image.generate_mipmaps()
	_newsprint = ImageTexture.create_from_image(image)
	return _newsprint


## The checkered flag: the one flag in the game that is not the player's color, because a
## checkered flag that is red and a darker red is not a checkered flag.
static func _checkered() -> StandardMaterial3D:
	var material := _flat(Color.WHITE)
	material.albedo_texture = _checker_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.uv1_scale = Vector3(3.0, 2.0, 1.0)
	return material


static func _checker_texture() -> Texture2D:
	if _checkers != null:
		return _checkers
	var image := Image.create_empty(2, 2, false, Image.FORMAT_RGB8)
	for y: int in 2:
		for x: int in 2:
			image.set_pixel(x, y, Color.WHITE if (x + y) % 2 == 0 else Color(0.06, 0.06, 0.07))
	_checkers = ImageTexture.create_from_image(image)
	return _checkers


static func _pennant_mesh() -> PrismMesh:
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.34, 0.52, 0.03)
	mesh.left_to_right = 0.0
	return mesh


## A prism [param size], its ridge [param apex] of the way across its width, in [param color].
static func _prism(size: Vector3, apex: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = size
	mesh.left_to_right = apex
	node.mesh = mesh
	node.material_override = _flat(color)
	return node


## A ring lying flat round [param inner] to [param outer], in [param color].
static func _torus(inner: float, outer: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 24
	mesh.ring_segments = 8
	node.mesh = mesh
	node.material_override = _flat(color)
	return node


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
	material.roughness = 0.62
	material.rim_enabled = true
	material.rim = 0.3
	return material
