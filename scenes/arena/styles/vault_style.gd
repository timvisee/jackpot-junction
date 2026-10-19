class_name VaultStyle
extends RoomStyle
## After Hours as the House's glamour room, the Vault's style, GAME.md 8.1c: Art Deco under one
## lamp, the table the House shows off at, STORY.md 3.9. A floor of midnight lacquer with the
## House's layout on it in gold foil and cream; walls stepped like a skyscraper's crown, a black
## lacquer plinth, a fluted cream body and a cream cap with brass where the tiers meet and a brass
## line inlaid round the top; boxes that are cigarette cases of butterscotch catalin with a black
## lid on brass feet. The Junction is a deco roulette wheel round a ziggurat turret, a Jackpot a
## ziggurat of catalin chips on a stepped tray, never in the coins' blue, and a pit an inverted
## ziggurat going down into the dark, a brass nosing on every step and the room's thin red neon
## round its top. Round the table, brass stanchions and their velvet rope, and on the back wall a
## gilded sunburst, the title's own, rising behind the House's poster.

const FLUTES := preload("res://assets/textures/deco_flutes.png")
const FLUTES_NORMAL := preload("res://assets/textures/deco_flutes_normal.png")
const SUNBURST := preload("res://assets/textures/deco_sunburst.png")
const LOUNGE := "res://scenes/arena/styles/vault_lounge.gd"

const LACQUER := Color("#16141A")
const CREAM := Color("#E2D5B8")
const BRASS := Color("#C89A48")
const CHROME := Color("#C6CBD1")
const CHERRY := Color("#6C1820")
const BUTTERSCOTCH := Color("#B57A35")
const JADE := Color("#245A4A")
## The layout's inks, GAME.md 8.1b: gold foil for the lines and cream for the words, both kept
## satin and a step down so the lacquer stays the quiet thing under the karts.
const FOIL := Color("#C29A4C")
const FOIL_WORD := Color("#D9CBA6")
## The neon round the top of a pit, as the card room has always had it, see [RoomKit].
const PIT_NEON := Color(0.62, 0.12, 0.12)
const PIT_GLOW := 0.35

## A wall's tiers: the plinth's height, how far each tier stands in from the one under it, the
## cap's height, how far a tier sinks into the one under it, and the brass band where two meet.
const PLINTH := 0.16
const STEP_IN := 0.08
const CAP := 0.18
const BITE := 0.02
const BAND := 0.025
## How many meters one run of the flutes covers: eight flutes.
const FLUTE_RUN := 0.8
## The cash-out pad's face, out to the rim that blinks, see [RoomKit].
const POCKETS := 28
const PAD := 0.05
const LAYER := 0.006
## An inverted ziggurat: how many steps go down, and how far each one drops.
const STEPS := 4
const DROP := 0.2

var _materials: Dictionary[String, StandardMaterial3D] = {}


func _init(for_room: RoomLook, for_surfaces: Surfaces) -> void:
	super(for_room, for_surfaces)
	# The room's surfaces hold this style, see [RoomKit], and nothing here asks them for anything:
	# holding them back as well would keep the two of them, and every material either has made,
	# alive for as long as the game runs.
	surfaces = null


## A deco block the arena's wall was: a black lacquer plinth, a fluted cream body a step in, a
## cream cap a step in again, brass where the tiers meet and a brass line inlaid round the top.
## Each tier stands in at the ends as well as the sides, so a run ends stepped like a ziggurat.
func wall(holder: Node3D, size: Vector3, _index: int) -> bool:
	var half := size * 0.5
	_box(holder, Vector3(size.x, PLINTH, size.z), lacquer(), _up(-half.y + PLINTH * 0.5))
	var body := Vector3(
		size.x - STEP_IN * 2.0, size.y - PLINTH - CAP + BITE, size.z - STEP_IN * 2.0
	)
	_box(holder, body, fluted(), _up(-half.y + PLINTH - BITE + body.y * 0.5))
	var cap := Vector3(size.x - STEP_IN * 4.0, CAP + BITE, size.z - STEP_IN * 4.0)
	_box(holder, cap, catalin(CREAM), _up(half.y - cap.y * 0.5))
	var brass := metal(BRASS)
	var over := Vector3(0.012, 0.0, 0.012)
	_box(holder, Vector3(body.x, BAND, body.z) + over, brass, _up(-half.y + PLINTH + BAND * 0.5))
	_box(holder, Vector3(cap.x, BAND, cap.z) + over, brass, _up(half.y - cap.y + BAND * 0.5))
	_frame(holder, Vector2(cap.x, cap.z) - Vector2.ONE * 0.14, half.y + 0.002, 0.03, brass)
	return true


## A cigarette case standing in for the box, inside its cube: butterscotch catalin with black lines
## round it, a black lacquer lid a hair wider with two brass chevrons and a cream roundel inlaid in
## it, on four brass ball feet.
func crate(holder: Node3D, size: Vector3) -> bool:
	var half := size * 0.5
	var feet := 0.08
	var lid := 0.16
	var body := Vector3(size.x * 0.86, size.y - feet - lid + BITE, size.z * 0.86)
	var bottom := -half.y + feet
	_box(holder, body, catalin(BUTTERSCOTCH), _up(bottom + body.y * 0.5))
	var black := lacquer()
	for k: int in 3:
		var line := Vector3(body.x + 0.008, 0.02, body.z + 0.008)
		_box(holder, line, black, _up(bottom + body.y * (0.3 + 0.14 * float(k))))
	var cover := Vector3(size.x * 0.9, lid, size.z * 0.9)
	var top := half.y - 0.004
	_box(holder, cover, black, _up(top - lid * 0.5))
	var brass := metal(BRASS)
	for row: int in 2:
		var tip := Vector3(0.0, top + 0.001, -0.02 + 0.16 * float(row))
		for side: float in [-1.0, 1.0]:
			var arm := _box(holder, Vector3(0.36, 0.006, 0.035), brass, tip)
			arm.rotation.y = side * 0.6
			arm.position += Vector3(side * 0.15, 0.0, -0.1)
	_cylinder(holder, 0.06, 0.006, catalin(CREAM), Vector3(0.0, top + 0.001, -0.3), 16)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var foot := Vector3(corner.x * body.x * 0.4, -half.y + feet * 0.5, corner.y * body.z * 0.4)
		_ball(holder, feet * 0.5, brass, foot)
	holder.rotation.y = rng.randf_range(-0.05, 0.05)
	return true


## An inverted ziggurat, GAME.md 8.1: black lacquer steps going down into the dark, a brass nosing
## along every one, and the card room's thin red neon round the top, an edge to find in a dark
## room rather than a sign. Every step is below the floor.
func pit(into: Node3D, size: Vector2) -> bool:
	var black := lacquer()
	var brass := metal(BRASS)
	var tread := minf(size.x, size.y) * 0.08
	var bottom := -Arena.PIT_DEPTH + 0.02
	for k: int in STEPS:
		var outer := size - Vector2.ONE * tread * 2.0 * float(k)
		var inner := outer - Vector2.ONE * tread * 2.0
		var top := -0.04 - DROP * float(k)
		var tall := top - bottom
		for side: int in 4:
			var along := side % 2 == 0
			var facing := 1.0 if side < 2 else -1.0
			var run := Vector3(outer.x, tall, tread) if along else Vector3(tread, tall, inner.y)
			var out := ((outer.y if along else outer.x) - tread) * 0.5 * facing
			var middle := top - tall * 0.5
			_box(
				into, run, black, Vector3(0.0, middle, out) if along else Vector3(out, middle, 0.0)
			)
		_frame(into, inner + Vector2.ONE * 0.03, top - 0.012, 0.03, brass)
	_neon_edge(into, size)
	return true


## A deco roulette wheel inside the neon ring: a black lacquer bezel ringed in brass, cherry and
## black pockets with a jade zero between brass frets, a cone of jade and black rays, and a
## ziggurat turret of black, brass and chrome with four stepped fins, low enough to drive over.
func junction(into: Node3D, radius: float) -> bool:
	var black := lacquer()
	var brass := metal(BRASS)
	var face := radius - RoomKit.RIM
	_disc(into, radius, black, PAD * 0.5, PAD)
	_disc(into, face, brass, PAD + LAYER * 0.5)
	_disc(into, face * 0.95, black, PAD + LAYER)
	var outside := face * 0.9
	var inside := face * 0.6
	var deep := outside - inside
	var middle := (outside + inside) * 0.5
	var cherry := catalin(CHERRY)
	for i: int in POCKETS:
		var turn := TAU * float(i) / float(POCKETS)
		var skin := catalin(JADE) if i == 0 else (cherry if i % 2 == 1 else black)
		var lift := PAD + LAYER * 2.0 + (LAYER * 0.25 if i % 2 == 1 else 0.0)
		var wide := TAU * middle / float(POCKETS) * 1.1
		var at := Vector3(sin(turn), 0.0, cos(turn)) * middle
		var pocket := _box(into, Vector3(wide, 0.01, deep), skin, at + _up(lift))
		pocket.rotation.y = turn
		var edge := turn + PI / float(POCKETS)
		var bar := Vector3(sin(edge), 0.0, cos(edge)) * middle
		var fret := _box(into, Vector3(0.03, 0.012, deep), brass, bar + _up(lift + LAYER))
		fret.rotation.y = edge
	_disc(into, inside, brass, PAD + LAYER * 3.0)
	_disc(into, inside - 0.06, black, PAD + LAYER * 4.0)
	# The cone, a sunburst of jade rays on the black.
	var jade := catalin(JADE)
	var rays := 16
	for i: int in rays:
		var turn := TAU * float(i) / float(rays)
		var reach := (inside - 0.06) * 0.62
		var at := Vector3(sin(turn), 0.0, cos(turn)) * (reach * 0.5 + 0.28)
		var ray := _box(into, Vector3(0.11, 0.01, reach), jade, at + _up(PAD + LAYER * 5.0))
		ray.rotation.y = turn
	# The turret: tiers stepping up, black and brass by turns, chrome at the top, and a spire.
	var tiers: Array[Vector2] = [
		Vector2(0.46, 0.05), Vector2(0.36, 0.05), Vector2(0.26, 0.06), Vector2(0.17, 0.06)
	]
	var floor_at := PAD + LAYER * 5.0
	for i: int in tiers.size():
		var tier := tiers[i]
		_cylinder(
			into, tier.x, tier.y, black if i % 2 == 0 else brass, _up(floor_at + tier.y * 0.5)
		)
		floor_at += tier.y
	var chrome := metal(CHROME)
	_cylinder(into, 0.1, 0.05, chrome, _up(floor_at + 0.025), 16)
	_cone(into, 0.05, 0.12, chrome, _up(floor_at + 0.11))
	for i: int in 4:
		var turn := PI * 0.25 + PI * 0.5 * float(i)
		var out := Vector3(sin(turn), 0.0, cos(turn))
		var low := _box(into, Vector3(0.03, 0.06, 0.4), brass, _up(PAD + 0.06) + out * 0.42)
		low.rotation.y = turn
		var high := _box(into, Vector3(0.03, 0.16, 0.16), brass, _up(PAD + 0.11) + out * 0.3)
		high.rotation.y = turn
	return true


## A ziggurat of catalin chips on a stepped black tray, GAME.md 3.5: cherry stacks highest along
## the back, butterscotch and cream down the sides, low jade and black ones along the front, so
## the count painted on the tile stands clear in the middle and in front of the pile. None of
## them is the coins' blue.
func jackpot(into: Node3D, size: Vector2) -> bool:
	var black := lacquer()
	_box(into, Vector3(size.x * 0.94, 0.02, size.y * 0.94), black, _up(0.06))
	_box(into, Vector3(size.x * 0.84, 0.04, size.y * 0.84), black, _up(0.07))
	var brass := metal(BRASS)
	_frame(into, Vector2(size.x, size.y) * 0.84, 0.09, 0.025, brass)
	var spacing := size.x * 0.84 * 0.25
	for i: int in 4:
		for j: int in 4:
			if i in [1, 2] and j in [1, 2]:
				continue
			var at := Vector3((float(i) - 1.5) * spacing, 0.0, (float(j) - 1.5) * spacing)
			var high := 6 if j == 0 else (2 if j == 3 else 4)
			var ink := CHERRY if j == 0 else (JADE if j == 3 else BUTTERSCOTCH)
			if j in [1, 2] and (i + j) % 2 == 0:
				ink = CREAM
			if j == 3 and i % 2 == 1:
				ink = LACQUER
			for k: int in high:
				_cylinder(into, 0.17, 0.046, chip(ink), at + _up(0.115 + 0.05 * float(k)), 16)
	return true


## Midnight lacquer, the room's own felt color under a satin coat, the lamp lying on it softly.
func floor_top() -> StandardMaterial3D:
	if not _materials.has("floor"):
		var coat := StandardMaterial3D.new()
		coat.albedo_color = room.felt
		coat.roughness = 0.32
		coat.metallic_specular = 0.6
		_materials["floor"] = coat
	return _materials["floor"]


## The table round the arena in black lacquer, the room's own table color.
func surround() -> StandardMaterial3D:
	if not _materials.has("table"):
		var coat := StandardMaterial3D.new()
		coat.albedo_color = room.table
		coat.roughness = 0.38
		coat.metallic_specular = 0.55
		_materials["table"] = coat
	return _materials["table"]


## The layout in gold foil and cream, GAME.md 8.1b, the House's own print at its best.
func layout_inks() -> Array[Color]:
	return [FOIL, FOIL_WORD]


## The room round the table, built by [VaultLounge]: the walls of a dark room with the gilded
## sunburst on the back one, the pictures either side of the House's poster, the table's edge and
## legs, the rope line behind the crowd, and the House's things set out about the table.
##
## The lounge is asked for by its path as the room goes up rather than named here, as the
## Workbench's bench is, see [method WorkbenchStyle.room_round]: naming it and the room's parts it
## builds with would have this script wait on them as it compiles.
func room_round(props: RoomProps) -> bool:
	load(LOUNGE).new(self, props).lay()
	return true


## A chip of cherry catalin, cream notches round its rim and a black face with a brass ziggurat
## stepping up out of it.
func emblem() -> Node3D:
	var holder := Node3D.new()
	holder.name = "DecoChip"
	_cylinder(holder, 0.5, 0.12, catalin(CHERRY), Vector3.ZERO, 32)
	var cream := catalin(CREAM)
	for k: int in 8:
		var turn := TAU * float(k) / 8.0
		var notch := _box(
			holder, Vector3(0.14, 0.124, 0.1), cream, Vector3(sin(turn), 0.0, cos(turn)) * 0.455
		)
		notch.rotation.y = turn
	_cylinder(holder, 0.34, 0.13, lacquer(), Vector3.ZERO, 32)
	var brass := metal(BRASS)
	_cylinder(holder, 0.36, 0.126, brass, Vector3.ZERO, 32)
	var lift := 0.065
	for side: float in [0.24, 0.17, 0.1]:
		_box(holder, Vector3(side, 0.03, side), brass, _up(lift + 0.015))
		lift += 0.03
	return holder


# --- the parts ---------------------------------------------------------------


## A rectangle of thin strips [param size] across lying at [param lift], [param thick] wide: the
## brass inlaid round a cap, a nosing round a step, the edge of a tray.
func _frame(into: Node3D, size: Vector2, lift: float, thick: float, skin: Material) -> void:
	for side: int in 4:
		var along := side % 2 == 0
		var facing := 1.0 if side < 2 else -1.0
		var run := Vector3(size.x, thick, thick) if along else Vector3(thick, thick, size.y - thick)
		var out := ((size.y if along else size.x) - thick) * 0.5 * facing
		_box(into, run, skin, Vector3(0.0, lift, out) if along else Vector3(out, lift, 0.0))


## The red neon round the top of a pit of [param size], lying on the floor: four runs of it.
func _neon_edge(into: Node3D, size: Vector2) -> void:
	var lit := neon(PIT_NEON, PIT_GLOW)
	var band := 0.06
	for side: int in 4:
		var along := side % 2 == 0
		var out := ((size.y if along else size.x) + band) * 0.5 * (1.0 if side < 2 else -1.0)
		var at := Vector3(0.0, 0.008, out) if along else Vector3(out, 0.008, 0.0)
		var run := (
			Vector3(size.x + band * 2.0, 0.012, band) if along else Vector3(band, 0.012, size.y)
		)
		_box(into, run, lit, at)


## The foil of the sunburst: its picture's rays, see tools/make_vault_prints.py, lit a little
## from inside.
func gilt() -> StandardMaterial3D:
	if not _materials.has("gilt"):
		var foil := StandardMaterial3D.new()
		foil.albedo_texture = SUNBURST
		foil.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		foil.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		foil.alpha_scissor_threshold = 0.5
		foil.metallic = 0.6
		foil.roughness = 0.4
		foil.emission_enabled = true
		foil.emission_texture = SUNBURST
		foil.emission = Color(0.62, 0.48, 0.26)
		foil.emission_energy_multiplier = 0.8
		_materials["gilt"] = foil
	return _materials["gilt"]


## Black lacquer: satin, the lamp lying on it softly.
func lacquer() -> StandardMaterial3D:
	return catalin(LACQUER)


## Molded catalin or lacquer in [param color], satin rather than glossy.
func catalin(color: Color) -> StandardMaterial3D:
	var key := "catalin:" + color.to_html(false)
	if not _materials.has(key):
		var molded := StandardMaterial3D.new()
		molded.albedo_color = color
		molded.roughness = 0.4
		molded.metallic_specular = 0.55
		_materials[key] = molded
	return _materials[key]


## A catalin chip in [param color], the notches round its rim printed on it as every chip in the
## game has them, see [Surfaces], since a notched edge is what says chip.
func chip(color: Color) -> StandardMaterial3D:
	var key := "chip:" + color.to_html(false)
	if not _materials.has(key):
		var molded := StandardMaterial3D.new()
		molded.albedo_texture = Surfaces.CHIP_FACE
		molded.albedo_color = color
		molded.roughness = 0.4
		molded.metallic_specular = 0.55
		_materials[key] = molded
	return _materials[key]


## Brass and chrome, satin rather than polished.
func metal(color: Color) -> StandardMaterial3D:
	var key := "metal:" + color.to_html(false)
	if not _materials.has(key):
		var bright := StandardMaterial3D.new()
		bright.albedo_color = color
		bright.metallic = 0.75
		bright.roughness = 0.36
		_materials[key] = bright
	return _materials[key]


## The cream of a wall's body with its flutes running down it, in the world's meters so every wall
## wears them alike.
func fluted() -> StandardMaterial3D:
	if not _materials.has("fluted"):
		var molded := StandardMaterial3D.new()
		molded.albedo_color = CREAM
		molded.albedo_texture = FLUTES
		molded.normal_enabled = true
		molded.normal_texture = FLUTES_NORMAL
		molded.normal_scale = 0.8
		molded.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		molded.uv1_triplanar = true
		molded.uv1_world_triplanar = true
		molded.uv1_triplanar_sharpness = 16.0
		molded.uv1_scale = Vector3.ONE / FLUTE_RUN
		molded.roughness = 0.42
		molded.metallic_specular = 0.5
		_materials["fluted"] = molded
	return _materials["fluted"]


## Lit from inside, as the room's neon is, see [Surfaces].
func neon(color: Color, strength: float) -> StandardMaterial3D:
	var key := "neon:%s:%.2f" % [color.to_html(false), strength]
	if not _materials.has(key):
		var lit := StandardMaterial3D.new()
		lit.albedo_color = color
		lit.emission_enabled = true
		lit.emission = color
		lit.emission_energy_multiplier = strength * room.neon
		lit.roughness = 0.4
		_materials[key] = lit
	return _materials[key]


func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)


func _disc(into: Node3D, radius: float, skin: Material, lift: float, thick := 0.01) -> void:
	_cylinder(into, radius, thick, skin, _up(lift), 48)


func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _put(into, mesh, skin, at)


func _cylinder(
	into: Node3D, radius: float, height: float, skin: Material, at: Vector3, sides := 10
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return _put(into, mesh, skin, at)


func _cone(into: Node3D, radius: float, height: float, skin: Material, at: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1
	_put(into, mesh, skin, at)


func _ball(into: Node3D, radius: float, skin: Material, at: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	_put(into, mesh, skin, at)


func _put(into: Node3D, mesh: Mesh, skin: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node
