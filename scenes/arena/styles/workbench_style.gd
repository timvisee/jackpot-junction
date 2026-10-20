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
##
## The lining's top is the frame's, so the two read as one maple border round the hole, and it is
## thicker than the dark rim the arena lays just inside every pit's opening ([constant
## Arena.PIT_RIM], a few millimeters up), which it covers. Thinner and lower, its top lay in the
## same place as that rim, and the edges of the hole flickered between maple and black.
func pit(into: Node3D, size: Vector2) -> bool:
	var maple := wood(MAPLE)
	var lining := Arena.PIT_RIM + 0.01
	var frame := 0.12
	var lip := 0.012
	var deep := 0.336
	for side: int in 4:
		var along := side % 2 == 0
		var facing := 1.0 if side < 2 else -1.0
		var across := (size.y if along else size.x) * 0.5
		var run := size.x if along else size.y - lining * 2.0
		var wide := size.x + frame * 2.0 if along else size.y
		var high := deep + lip
		var inner := Vector3(run, high, lining) if along else Vector3(lining, high, run)
		var outer := Vector3(wide, lip, frame) if along else Vector3(frame, lip, wide)
		var down := (across - lining * 0.5) * facing
		var out := (across + frame * 0.5) * facing
		var middle := lip - high * 0.5
		_box(
			into, inner, maple, Vector3(0.0, middle, down) if along else Vector3(down, middle, 0.0)
		)
		var flat := lip * 0.5
		_box(into, outer, maple, Vector3(0.0, flat, out) if along else Vector3(out, flat, 0.0))
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
## up to the middle and a brass spindle with its cross on top. Its call to attention, 3.4, is a
## wheel of fortune's: the head, its pockets and the cross on the spindle, starts to turn, and the
## bulbs Kit set round the walnut rim light and chase round it, see [method _wheel_head] and
## [method _rim_bulbs].
func junction(into: Node3D, radius: float, cue: JunctionCue) -> bool:
	var walnut := wood(WALNUT)
	var maple := wood(MAPLE)
	var face := radius - RoomKit.RIM
	_disc(into, radius, walnut, PAD * 0.5, PAD)
	_disc(into, face, maple, PAD + LAYER * 0.5)
	_wheel_head(into, face, cue)
	_rim_bulbs(into, radius, cue)
	# The cone, turned: a step for every ring of it, walnut and maple by turns.
	var steps: Array[float] = [0.6, 0.52, 0.4, 0.3, 0.2]
	for i: int in steps.size():
		var skin := walnut if i % 2 == 0 else maple
		_disc(into, face * steps[i], skin, PAD + LAYER * 3.0 + 0.025 * float(i), 0.03)
	# The spindle, low enough to drive over: a brass post and a knob on top, the cross on it
	# turning with the head.
	var brass := metal(BRASS)
	_cylinder(into, 0.09, 0.2, brass, _up(0.27))
	_ball(into, 0.07, brass, _up(0.4))
	return true


## A maple tray let in over a Jackpot's tile, low enough that the count painted on the tile stands
## clear of it, with a walnut edge round it and Kit's chips squared into each corner, a tall stack
## and a shorter one beside it, the pile as much of that as the Jackpot is full, [JackpotPile]: the
## tray as far in from the tile on every side and its edge as wide, a long Jackpot's tray longer.
func jackpot(into: Node3D, size: Vector2) -> bool:
	var inside := RoomKit.tray(size)
	var tray := Vector3(inside.x, 0.04, inside.y)
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
	# Kit's own chips, a stack squared into each corner and a shorter one in from it along the
	# tray, none of them the coins' blue.
	var chips: Array[Color] = [RED, CREAM, INK, CREAM]
	var beside: Array[Color] = [CREAM, INK, RED, RED]
	var high: Array[int] = [8, 6, 7, 8]
	var low: Array[int] = [4, 3, 5, 3]
	var corner := Vector2(tray.x, tray.z) * 0.5 - Vector2.ONE * 0.34
	var pile := JackpotPile.on(into)
	for i: int in 4:
		var facing := Vector3(1.0 if i % 2 == 0 else -1.0, 0.0, 1.0 if i < 2 else -1.0)
		var at := Vector3(corner.x, 0.0, corner.y) * facing
		for pair: int in 2:
			var stack := pile.stack()
			var next := at - Vector3(0.42 * facing.x * pair, 0.0, 0.0)
			var ink := chips[i] if pair == 0 else beside[i]
			for k: int in high[i] if pair == 0 else low[i]:
				_cylinder(stack, 0.19, 0.046, paint(ink), next + _up(0.115 + 0.05 * k), 16)
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


## The House's word, STORY.md 6.1: chalked in the House's capitals on Kit's slate, over the top
## right of Kit's plan, where the shot a match opens on looks, GAME.md 8.2.
func house_word(word: HouseWord, arena: Arena) -> bool:
	var face := -(arena.world_size().y * 0.5 + RoomBuild.BACK_FAR + RoomBuild.BACK_WALL) + 1.0
	var at := Vector3(5.2, RoomBuild.TOP + 9.7, face + 0.66)
	word.lay(at, Vector2(7.4, 1.5), CHALK_WORD, HouseWord.Medium.CHALK)
	return true


## What Kit leaves on the slate, GAME.md 8.1c: a curl of maple off the plane, a stub of red pencil
## sharpened down to the wood, and a stub of chalk, the few things a maker's floor is never quite
## clear of.
func litter(into: Node3D, which: int, dice: RandomNumberGenerator) -> bool:
	var along := Vector3(0.0, 0.0, PI * 0.5)
	match which % 3:
		0:
			# The curl is a ribbon of maple on its edge, wound in on itself a turn and a bit.
			var turn := dice.randf_range(0.0, TAU)
			var last := Vector3(cos(turn), 0.0, sin(turn)) * 0.11
			for i: int in 10:
				turn += 0.65
				var next := Vector3(cos(turn), 0.0, sin(turn)) * (0.105 - float(i) * 0.0075)
				var run := next - last
				var high := 0.026 + float(i) * 0.001
				var ribbon := RoomStyle.slab(Vector3(run.length() + 0.004, high, 0.004))
				var heading := Vector3(0.0, atan2(-run.z, run.x), 0.0)
				var middle := (last + next) * 0.5 + _up(high * 0.5)
				dropped(into, ribbon, MAPLE.lightened(float(i) * 0.02), middle, heading)
				last = next
		1:
			dropped(into, RoomStyle.rod(0.032, 0.24, 6), RED, Vector3(0.05, 0.032, 0.0), along)
			var cone := RoomStyle.rod(0.032, 0.07, 6, 0.008)
			dropped(into, cone, MAPLE, Vector3(-0.105, 0.032, 0.0), along)
			var lead := RoomStyle.rod(0.008, 0.02, 4, 0.0)
			dropped(into, lead, INK, Vector3(-0.15, 0.032, 0.0), along)
		_:
			var stub := RoomStyle.rod(0.028, 0.13, 8)
			dropped(into, stub, CHALK_LINE, _up(0.028), Vector3(PI * 0.5, 0.0, 0.0))
	return true


## The head of the Workbench's wheel, [param face] across, on a pivot of its own put in
## [param cue] to turn: the pockets, the frets between them and the brass cross on the spindle.
func _wheel_head(into: Node3D, face: float, cue: JunctionCue) -> void:
	cue.spin = 0.32
	var head := Node3D.new()
	head.name = "Head"
	into.add_child(head)
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
		var pocket := _box(head, Vector3(wide, 0.01, deep), skin, at + _up(lift))
		pocket.rotation.y = turn
		var edge := turn + PI / float(POCKETS)
		var bar := Vector3(sin(edge), 0.0, cos(edge)) * middle
		var between := _box(head, Vector3(0.035, 0.012, deep), fret, bar + _up(lift + LAYER))
		between.rotation.y = edge
	var brass := metal(BRASS)
	for i: int in 4:
		var turn := PI * 0.25 + PI * 0.5 * float(i)
		var out := Vector3(sin(turn), 0.0, cos(turn))
		var arm := _box(head, Vector3(0.05, 0.05, 0.4), brass, _up(0.33) + out * 0.2)
		arm.rotation.y = turn
		_ball(head, 0.05, brass, _up(0.33) + out * 0.41)
	cue.turning(head)


## Bulbs set round the walnut rim of the wheel out to [param radius], as round a fair's wheel of
## fortune, each in a brass collar: smoked glass unlit, so the rim is quiet with nothing at stake,
## and lit warm as a filament by [param cue], every other bulb taking turns with its neighbors.
func _rim_bulbs(into: Node3D, radius: float, cue: JunctionCue) -> void:
	var bulbs := 32
	cue.lit = Color("#FF9A30")
	cue.glow = 1.7
	cue.steps = Vector2(1.6, 6.0)
	var glass := cue.chase_lamps(2, Color("#5E4430"))
	var collar := metal(BRASS)
	var round_at := radius - RoomKit.RIM * 0.5
	for i: int in bulbs:
		var turn := TAU * (float(i) + 0.5) / float(bulbs)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * round_at
		_cylinder(into, 0.12, 0.02, collar, at + _up(PAD + 0.01), 12)
		_ball(into, 0.095, glass[i % 2], at + _up(PAD + 0.02))
