class_name WorkbenchStyle
extends RoomStyle
## Kit's workshop, the Workbench's style, GAME.md 8.1c: table one as the careful maker who built it
## by hand left it, STORY.md 3.10, before the House printed its copies. Few materials and one of
## each kind of thing: oiled maple, a slate felt chalked with the House's layout in chalk-white and
## cream, cream paint, one brick red and ink, so the player colors are the only strong colors on
## the table.
##
## Every wall is the same maple block with a cream rule inlaid along its top, a tick every eighth
## of a cell and a number at every cell, so a wall measures the table it stands on. A box is a
## maple cube with Kit's mark, a K in a ring, burnt into its top. The Junction is a roulette wheel
## turned from walnut and maple with a brass spindle; a pit is a hole lined in maple with bright
## nails in rows at its bottom; a Jackpot is a maple tray. Round the table, nothing is scattered:
## the lamp and the vice, Kit's plan of the table chalked on a slate on the board behind the bench,
## and a handful of things a maker puts down square, a pencil and a rule, a calculator, jars, a mug
## and a plane.

const GRAIN := preload("res://assets/textures/kit_maple.png")
const RULE := preload("res://assets/textures/kit_rule.png")
const MARK := preload("res://assets/textures/kit_mark.png")
const SLATE := preload("res://assets/textures/kit_chalkboard.png")
const CALCULATOR := preload("res://assets/textures/kit_calculator.png")
const BENCH := "res://scenes/arena/styles/workbench_bench.gd"

const MAPLE := Color("#BC8954")
const WALNUT := Color("#6E4B33")
const CREAM := Color("#EDE3CC")
const INK := Color("#2B2A30")
const RED := Color("#A63F33")
const GREEN := Color("#3D5F48")
const BRASS := Color("#C9A15A")
const STEEL := Color("#D5D8DE")
const BOARD := Color("#5A5F58")
## The layout's inks, GAME.md 8.1b: chalk for the lines and cream for the words, both a step down
## from white so the felt stays the quiet thing under the karts.
const CHALK_LINE := Color("#C9C8C0")
const CHALK_WORD := Color("#DCD2BA")

## How many meters of maple one run of its grain covers, and of wall one run of the rule: eight of
## the table's cells.
const GRAIN_RUN := 1.6
const RULE_RUN := 10.0
## How wide the rule is, how far short of a wall's ends it stops and how far over the top it lies.
const RULE_WIDE := 0.4
const RULE_SHORT := 0.08
const RULE_LIFT := 0.004
## The eased top of a block: how tall it is and how far in from each side, and how far it sinks
## into the block under it, so no two of their faces ever share a plane.
const EASE := 0.12
const EASE_IN := 0.05
const EASE_BITE := 0.02
## The cash-out pad's face, out to the rim that blinks, see [RoomKit]: how many pockets, and the
## height of each turned step over the floor.
const POCKETS := 28
const PAD := 0.05
const LAYER := 0.006

var _materials: Dictionary[String, StandardMaterial3D] = {}


## A maple block the arena's wall was, its top eased, the rule inlaid along it.
func wall(holder: Node3D, size: Vector3, _index: int) -> bool:
	var maple := wood(MAPLE)
	_box(holder, Vector3(size.x, size.y - EASE, size.z), maple, Vector3(0.0, -EASE * 0.5, 0.0))
	var inset := minf(EASE_IN, minf(size.x, size.z) * 0.2)
	var top := Vector3(size.x - inset * 2.0, EASE + EASE_BITE, size.z - inset * 2.0)
	_box(holder, top, maple, Vector3(0.0, (size.y - top.y) * 0.5, 0.0))
	_rule(holder, size)
	return true


## A maple cube inside the box's own, its top eased and Kit's mark burnt into it.
func crate(holder: Node3D, size: Vector3) -> bool:
	var maple := wood(MAPLE)
	var body := Vector3(size.x * 0.92, size.y * 0.88, size.z * 0.92)
	_box(holder, body, maple, Vector3(0.0, (body.y - size.y) * 0.5, 0.0))
	var lid := Vector3(size.x * 0.86, size.y * 0.14, size.z * 0.86)
	_box(holder, lid, maple, Vector3(0.0, (size.y - lid.y) * 0.5 - 0.004, 0.0))
	var mark := PlaneMesh.new()
	mark.size = Vector2(size.x * 0.84, size.z * 0.84)
	_flat(_put(holder, mark, burn(), Vector3(0.0, size.y * 0.5 - 0.002, 0.0)))
	holder.rotation.y = rng.randf_range(-0.04, 0.04)
	return true


## A hole lined in maple with bright nails standing in rows at the bottom of it, GAME.md 8.1: the
## lining goes a hand's width down the shaft and a frame of it lies flush round the top.
func pit(into: Node3D, size: Vector2) -> bool:
	var maple := wood(MAPLE)
	var lining := 0.08
	var frame := 0.12
	for side: int in 4:
		var along := side % 2 == 0
		var facing := 1.0 if side < 2 else -1.0
		var across := (size.y if along else size.x) * 0.5
		var run := size.x if along else size.y - lining * 2.0
		var wide := size.x + frame * 2.0 if along else size.y
		var inner := Vector3(run, 0.34, lining) if along else Vector3(lining, 0.34, run)
		var outer := Vector3(wide, 0.012, frame) if along else Vector3(frame, 0.012, wide)
		var down := (across - lining * 0.5) * facing
		var out := (across + frame * 0.5) * facing
		_box(
			into, inner, maple, Vector3(0.0, -0.166, down) if along else Vector3(down, -0.166, 0.0)
		)
		_box(into, outer, maple, Vector3(0.0, 0.006, out) if along else Vector3(out, 0.006, 0.0))
	var nail := metal(STEEL)
	var rows := maxi(int(size.y / 0.5), 3)
	var columns := maxi(int(size.x / 0.5), 3)
	for row: int in rows:
		for column: int in columns:
			var at := Vector3(
				(float(column) - float(columns - 1) * 0.5) * size.x / float(columns),
				-Arena.PIT_DEPTH,
				(float(row) - float(rows - 1) * 0.5) * size.y / float(rows)
			)
			_cylinder(into, 0.07, 0.03, nail, at + Vector3(0.0, 0.015, 0.0))
			_cylinder(into, 0.03, 0.5, nail, at + Vector3(0.0, 0.28, 0.0))
			_cone(into, 0.03, 0.12, nail, at + Vector3(0.0, 0.59, 0.0))
	return true


## A roulette wheel turned from walnut and maple, GAME.md 8.1: a walnut bowl, a maple ball track,
## pockets in Kit's red and ink with a green zero between maple frets, a turned maple cone stepping
## up to the middle and a brass spindle with its cross on top.
func junction(into: Node3D, radius: float) -> bool:
	var walnut := wood(WALNUT)
	var maple := wood(MAPLE)
	var face := radius - RoomKit.RIM
	_disc(into, radius, walnut, PAD * 0.5, PAD)
	_disc(into, face, maple, PAD + LAYER * 0.5)
	var outside := face * 0.9
	var inside := face * 0.58
	var deep := outside - inside
	var middle := (outside + inside) * 0.5
	var red := paint(RED)
	var ink := paint(INK)
	var fret := paint(CREAM)
	for i: int in POCKETS:
		var turn := TAU * float(i) / float(POCKETS)
		var skin := paint(GREEN) if i == 0 else (red if i % 2 == 1 else ink)
		var lift := PAD + LAYER * 1.5 + (LAYER * 0.25 if i % 2 == 1 else 0.0)
		var wide := TAU * middle / float(POCKETS) * 1.1
		var at := Vector3(sin(turn), 0.0, cos(turn)) * middle
		var pocket := _box(into, Vector3(wide, 0.01, deep), skin, at + _up(lift))
		pocket.rotation.y = turn
		var edge := turn + PI / float(POCKETS)
		var bar := Vector3(sin(edge), 0.0, cos(edge)) * middle
		var between := _box(into, Vector3(0.035, 0.012, deep), fret, bar + _up(lift + LAYER))
		between.rotation.y = edge
	# The cone, turned: a step for every ring of it, walnut and maple by turns.
	var steps: Array[float] = [0.6, 0.52, 0.4, 0.3, 0.2]
	for i: int in steps.size():
		var skin := walnut if i % 2 == 0 else maple
		_disc(into, face * steps[i], skin, PAD + LAYER * 3.0 + 0.025 * float(i), 0.03)
	# The spindle, low enough to drive over: a brass post, its cross and a knob on top.
	var brass := metal(BRASS)
	_cylinder(into, 0.09, 0.2, brass, _up(0.27))
	for i: int in 4:
		var turn := PI * 0.25 + PI * 0.5 * float(i)
		var out := Vector3(sin(turn), 0.0, cos(turn))
		var arm := _box(into, Vector3(0.05, 0.05, 0.4), brass, _up(0.33) + out * 0.2)
		arm.rotation.y = turn
		_ball(into, 0.05, brass, _up(0.33) + out * 0.41)
	_ball(into, 0.07, brass, _up(0.4))
	return true


## A maple tray let in over a Jackpot's tile, low enough that the count painted on the tile stands
## clear of it, with a walnut edge round it and a short stack of Kit's chips in each corner.
func jackpot(into: Node3D, size: Vector2) -> bool:
	var tray := Vector3(size.x * 0.86, 0.04, size.y * 0.86)
	_box(into, tray, wood(MAPLE), Vector3(0.0, 0.07, 0.0))
	var walnut := wood(WALNUT)
	var band := 0.1
	for side: int in 4:
		var along := side % 2 == 0
		var facing := 1.0 if side < 2 else -1.0
		var run := (
			Vector3(tray.x, 0.05, band) if along else Vector3(band, 0.05, tray.z - band * 2.0)
		)
		var out := ((tray.z if along else tray.x) - band) * 0.5 * facing
		_box(into, run, walnut, Vector3(0.0, 0.07, out) if along else Vector3(out, 0.07, 0.0))
	# Kit's own chips, a short stack squared into each corner, none of them the coins' blue.
	var chips: Array[Color] = [RED, CREAM, INK, CREAM]
	var high: Array[int] = [4, 2, 3, 5]
	var corner := tray.x * 0.5 - 0.34
	for i: int in 4:
		var at := Vector3(
			corner * (1.0 if i % 2 == 0 else -1.0), 0.0, corner * (1.0 if i < 2 else -1.0)
		)
		for k: int in high[i]:
			_cylinder(into, 0.19, 0.046, paint(chips[i]), at + _up(0.115 + 0.05 * k), 16)
	return true


## The layout in chalk and cream, GAME.md 8.1b, as Kit would have chalked the House's terms.
func layout_inks() -> Array[Color]:
	return [CHALK_LINE, CHALK_WORD]


## The workshop round the table, GAME.md 8.1, built by [WorkbenchBench]: the bench's edge and legs,
## the board behind it with the calendar and Kit's slate, and the few things a careful maker leaves
## out, each put down square where it belongs rather than dealt.
##
## The bench is asked for by its path as the room goes up rather than named here. Naming it, and
## the room's parts it builds with, would have this script wait on them as it compiles, and they on
## the settings screen, whose aim guide preview preloads the Workbench, which names this script:
## the preview's room came out a bare resource.
func room_round(props: RoomProps) -> bool:
	load(BENCH).new(self, props).lay()
	return true


## The rule inlaid along the top of a wall of [param size]: one strip, its numbers counted from the
## wall's left end, or its far end for a wall that runs toward the camera, and standing upright to
## a player looking down the table.
func _rule(holder: Node3D, size: Vector3) -> void:
	var along_x := size.x >= size.z
	var length := maxf(size.x, size.z) - RULE_SHORT * 2.0
	var half := Vector2(length, minf(RULE_WIDE, minf(size.x, size.z) * 0.5)) * 0.5
	var lift := size.y * 0.5 + RULE_LIFT
	var reach := length / RULE_RUN
	var corners: Array[Vector3] = []
	if along_x:
		corners = [
			Vector3(-half.x, lift, -half.y),
			Vector3(half.x, lift, -half.y),
			Vector3(half.x, lift, half.y),
			Vector3(-half.x, lift, half.y),
		]
	else:
		corners = [
			Vector3(-half.y, lift, -half.x),
			Vector3(-half.y, lift, half.x),
			Vector3(half.y, lift, half.x),
			Vector3(half.y, lift, -half.x),
		]
	var uvs: Array[Vector2] = [
		Vector2(0.0, 0.0), Vector2(reach, 0.0), Vector2(reach, 1.0), Vector2(0.0, 1.0)
	]
	var strip := SurfaceTool.new()
	strip.begin(Mesh.PRIMITIVE_TRIANGLES)
	strip.set_normal(Vector3.UP)
	# Wound the way the engine draws a face it is looking at, clockwise from above.
	var order: Array[int] = [0, 1, 2, 0, 2, 3]
	if not along_x:
		order = [0, 2, 1, 0, 3, 2]
	for i: int in order:
		strip.set_uv(uvs[i])
		strip.add_vertex(corners[i])
	_flat(_put(holder, strip.commit(), printed(RULE), Vector3.ZERO))


## Oiled wood in [param color], its grain laid on in the world's meters.
func wood(color: Color) -> StandardMaterial3D:
	var key := "wood:" + color.to_html(false)
	if not _materials.has(key):
		var oiled := StandardMaterial3D.new()
		oiled.albedo_color = color
		oiled.albedo_texture = GRAIN
		oiled.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		oiled.uv1_triplanar = true
		oiled.uv1_world_triplanar = true
		oiled.uv1_triplanar_sharpness = 8.0
		oiled.uv1_scale = Vector3.ONE / GRAIN_RUN
		oiled.roughness = 0.5
		oiled.metallic_specular = 0.45
		_materials[key] = oiled
	return _materials[key]


## Paint with a satin finish, the way the cream, the red and the ink are put on.
func paint(color: Color) -> StandardMaterial3D:
	var key := "paint:" + color.to_html(false)
	if not _materials.has(key):
		var coat := StandardMaterial3D.new()
		coat.albedo_color = color
		coat.roughness = 0.55
		coat.metallic_specular = 0.4
		_materials[key] = coat
	return _materials[key]


## Bright metal: the nails, the spindle. Half metal and fairly rough, since there is nothing in a
## dim workshop for a mirror to show, and a mirror of nothing is a black bar.
func metal(color: Color) -> StandardMaterial3D:
	var key := "metal:" + color.to_html(false)
	if not _materials.has(key):
		var bright := StandardMaterial3D.new()
		bright.albedo_color = color
		bright.metallic = 0.55
		bright.roughness = 0.38
		_materials[key] = bright
	return _materials[key]


## Kit's mark as the burn it leaves, multiplied over whatever maple it is laid on, so the grain
## runs on under it.
func burn() -> StandardMaterial3D:
	if not _materials.has("burn"):
		var mark := StandardMaterial3D.new()
		mark.albedo_texture = MARK
		mark.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		mark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mark.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		_materials["burn"] = mark
	return _materials["burn"]


## Something carrying its own picture off its own UVs: the rule, the slate, the calculator.
func printed(picture: Texture2D) -> StandardMaterial3D:
	var key := "print:" + picture.resource_path
	if not _materials.has(key):
		var picture_on := StandardMaterial3D.new()
		picture_on.albedo_texture = picture
		picture_on.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		picture_on.roughness = 0.55
		picture_on.metallic_specular = 0.4
		_materials[key] = picture_on
	return _materials[key]


## Casts no shadow: something lying flat on something else, which has nothing to cast one on.
func _flat(node: MeshInstance3D) -> void:
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


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
	mesh.radial_segments = 6
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
