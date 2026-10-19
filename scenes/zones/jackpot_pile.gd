class_name JackpotPile
extends Node3D
## The chips a room piles on a Jackpot, GAME.md 3.5 and 8.1c, showing what the Jackpot holds: no
## chips while it holds none, a few low stacks once it holds a little, and the stacks growing a step
## at a time to the whole pile the room built once it is full. The steps go with the zone's traffic
## light, so the two say the same thing: a few chips of it while it is red, not half of it and then
## more than two thirds through the amber, and all of it on green. A chip that comes drops onto its
## stack and one that goes lifts off it and shrinks away, the bottom of a step first as it fills and
## the top first as it is collected, a chip after the other, so a step is seen happening rather than
## popping.
##
## A room's hook builds its chips under [method stack] as it built them on the tile, a stack at a
## time and its chips bottom first, and [method lay] turns them into one [MultiMesh] for each mesh
## and look they are made in, GAME.md 10.7, each chip's ink on its instance: a pile in five colors
## of one chip is one draw, fewer than the chips took baked into the tile, and nothing is rebuilt as
## it grows, a chip off the pile being one shrunk to nothing. A chip of several pieces, a felt chip
## and the thread round it, is a [Node3D] holding them. The draws hang under the pile, so a Jackpot
## held back out of sight or dropped onto the lot, GAME.md 9.4a, takes its pile with it.
##
## The pile is read off its zone's chips, which a client is sent with the rest of the zone, so every
## screen shows the same pile. A zone with no match on it, a room seen behind a menu or warmed up
## behind the title, shows the whole pile, as it was built, which is how the warm-up compiles the
## looks the piles are drawn in.

## How much of the pile shows at each step, the first of them none at all, see [method step_of].
const SHOWN: Array[float] = [0.0, 0.15, 0.4, 0.7, 1.0]
## How far one stack's chips come after another's, in a share of a stack's height, the stacks taken
## by turns along the golden ratio: a step leaves some stacks short and others not yet begun, which
## is what a few low stacks look like, where every stack one chip high looked like a pattern.
const SPREAD := 0.8
const GOLDEN := 0.618034
## How long a chip takes to land on its stack and how far above it it drops from; how long one takes
## to go and how far it lifts on its way; and how long after the one before it each starts, no more
## than lets a whole step be under way inside [constant STAGGER_ALL].
const LAND := 0.3
const DROP := 0.45
const LEAVE := 0.22
const LIFT := 0.3
const STAGGER := 0.05
const STAGGER_ALL := 0.5

var _stacks: Array[Node3D] = []
var _late: Array[bool] = []
## Every chip in the order the pile fills, each a list of its pieces as [MultiMesh, instance, where
## it lies], with the point it grows from, how far it is there (0 gone, 1 on the pile), whether it
## is coming or going, and how long it waits before it moves.
var _chips: Array[Array] = []
var _centers := PackedVector3Array()
var _presence := PackedFloat32Array()
var _coming: Array[bool] = []
var _wait := PackedFloat32Array()
## How many chips the pile shows or is on its way to showing, always the first that many.
var _shown := 0
## The rules the pile was last worked out against: a match starting puts the pile where it should
## be at once rather than throwing it off the tile in front of everybody.
var _rules: MatchRules
var _moving := false


## The pile on the Jackpot [param zone], made the first time a room's hook asks for it.
static func on(zone: Node3D) -> JackpotPile:
	var pile := zone.get_node_or_null(^"Pile") as JackpotPile
	if pile == null:
		pile = JackpotPile.new()
		pile.name = "Pile"
		zone.add_child(pile)
	return pile


## A new stack on the pile, to build its chips under, bottom first, where they lie in the zone: each
## child a chip. A [param late] stack, a stack tipped over, comes after every upright one has.
func stack(late := false) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Stack%d" % _stacks.size()
	add_child(holder)
	_stacks.append(holder)
	_late.append(late)
	return holder


## Draws the stacks the room's hook handed in as the pile they make, one [MultiMesh] for each mesh
## and look across them, and frees the nodes they were built of; [method RoomKit.jackpot] calls it
## once the hook is done. How many draws it made.
func lay() -> int:
	var groups: Dictionary[String, Array] = {}
	_take(groups)
	var made := 0
	for key: String in groups:
		var group: Array = groups[key]
		var pieces: Array = group[3]
		var many := MultiMesh.new()
		many.transform_format = MultiMesh.TRANSFORM_3D
		# Before the count, which the engine asks of a MultiMesh that takes colors.
		many.use_colors = true
		many.mesh = group[0]
		many.instance_count = pieces.size()
		var drawn := MultiMeshInstance3D.new()
		drawn.name = "Chips%d" % made
		drawn.multimesh = many
		drawn.material_override = group[1]
		drawn.cast_shadow = group[2]
		# Moved in frame time rather than by the physics, so not smoothed between its steps.
		drawn.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(drawn)
		for i: int in pieces.size():
			var piece: Array = pieces[i]
			_chips[piece[0]].append([many, i, piece[1]])
			many.set_instance_transform(i, piece[1])
			many.set_instance_color(i, piece[2])
		made += 1
	return made


## The step [param zone]'s pile is at, from 0, no chips, to 4, all of them: none while the zone
## holds no whole chip, then a step more at each edge of the traffic light, amber, halfway on from
## amber to the rules' cap, and the cap. The cap is the rules' own rather than the heat's, which a
## client does not keep, so a hot table's pile past it is a full pile still, and the same on every
## screen. A zone with no match on it is all of it.
static func step_of(zone: JackpotZone) -> int:
	if zone == null or zone.rules == null:
		return SHOWN.size() - 1
	var count := zone.whole_chips()
	if count <= 0:
		return 0
	var amber := zone.rules.jackpot_amber
	var full := zone.rules.jackpot_cap
	var step := 1
	for edge: int in [amber, (amber + full) / 2, full]:
		if count >= edge:
			step += 1
	return step


## How many chips there are on the pile in all.
func chips() -> int:
	return _chips.size()


## How many chips the pile is showing, or on its way to showing once the step under way is done.
func shown() -> int:
	return _shown


## Whether every chip has landed or gone.
func is_settled() -> bool:
	return not _moving


## How many chips are on the tile to be seen right now, the ones on their way included.
func visible_chips() -> int:
	var count := 0
	for presence: float in _presence:
		if presence > 0.0:
			count += 1
	return count


func _process(delta: float) -> void:
	if _chips.is_empty():
		return
	var zone := get_parent() as JackpotZone
	var want := roundi(SHOWN[step_of(zone)] * float(_chips.size()))
	var rules := zone.rules if zone != null else null
	if rules != _rules:
		_rules = rules
		_head_for(want, true)
	elif want != _shown:
		_head_for(want, false)
	if _moving:
		_move(delta)


## Sends the chips toward the first [param want] of them showing, the bottom of the chips coming
## first and the top of the chips going first, or puts them there at once if [param at_once].
func _head_for(want: int, at_once: bool) -> void:
	var low := mini(want, _shown)
	var high := maxi(want, _shown)
	var gap := minf(STAGGER, STAGGER_ALL / float(maxi(high - low, 1)))
	for i: int in _chips.size():
		var coming := i < want
		if at_once:
			_coming[i] = coming
			_presence[i] = 1.0 if coming else 0.0
			_wait[i] = 0.0
			_place(i)
			continue
		if coming == _coming[i]:
			continue
		_coming[i] = coming
		_wait[i] = gap * float(i - low if coming else high - 1 - i)
		_moving = true
	_shown = want


func _move(delta: float) -> void:
	_moving = false
	for i: int in _chips.size():
		var target := 1.0 if _coming[i] else 0.0
		if _presence[i] == target:
			continue
		_moving = true
		if _wait[i] > 0.0:
			_wait[i] -= delta
			continue
		_presence[i] = move_toward(_presence[i], target, delta / (LAND if _coming[i] else LEAVE))
		_place(i)


## Puts chip [param i]'s pieces where its presence has it: dropping onto its place and growing to
## its size as it comes, rising off it and shrinking as it goes, about the point it grows from.
func _place(i: int) -> void:
	var now := _presence[i]
	var size := now
	var rise := LIFT * (1.0 - now)
	if _coming[i]:
		size = smoothstep(0.0, 0.35, now)
		rise = DROP * (1.0 - now) * (1.0 - now)
	var center := _centers[i]
	for piece: Array in _chips[i]:
		var base: Transform3D = piece[2]
		var at := center + (base.origin - center) * size + Vector3.UP * rise
		(piece[0] as MultiMesh).set_instance_transform(piece[1], Transform3D(base.basis * size, at))


## Takes this pile's stacks into [param groups], keyed by what each piece is and is made in, as
## [mesh, look, shadow, [chip, where it lies, its ink]], its chips in the order the pile fills:
## lowest first, a share of each stack's height at a time, a late stack's last.
func _take(groups: Dictionary[String, Array]) -> void:
	var order: Array[Array] = []
	for s: int in _stacks.size():
		var chips_in := _stacks[s].get_children()
		var behind := fposmod(float(s) * GOLDEN, 1.0) * SPREAD + (2.0 if _late[s] else 0.0)
		for k: int in chips_in.size():
			order.append([(float(k) + 0.5) / float(chips_in.size()) + behind, chips_in[k]])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var looks: Dictionary[int, Array] = {}
	for index: int in order.size():
		var chip: Node3D = order[index][1]
		var parts: Array[Node] = [chip]
		parts.append_array(chip.find_children("*", "MeshInstance3D", true, false))
		var center := Vector3.INF
		for node: Node in parts:
			var part := node as MeshInstance3D
			if part == null or part.mesh == null:
				continue
			var skin := part.material_override
			if skin == null:
				skin = part.mesh.surface_get_material(0)
			if skin == null:
				continue
			if not looks.has(skin.get_instance_id()):
				looks[skin.get_instance_id()] = _look(skin, looks)
			var look: Array = looks[skin.get_instance_id()]
			var at := _under(self, part)
			if center == Vector3.INF:
				center = at.origin
			var key := "%s:%s:%d" % [look[2], _shape(part.mesh), part.cast_shadow]
			if not groups.has(key):
				groups[key] = [part.mesh, look[0], part.cast_shadow, []]
			(groups[key][3] as Array).append([index, at, look[1]])
		_chips.append([])
		_centers.append(center if center != Vector3.INF else Vector3.ZERO)
		_presence.append(1.0)
		_coming.append(true)
		_wait.append(0.0)
	_shown = _chips.size()
	for holder: Node3D in _stacks:
		remove_child(holder)
		# Freed on the spot, as [Bake] frees what it merges: nothing holds these.
		holder.free()
	_stacks.clear()


## The look a chip in [param skin] is drawn in, as [look, its ink on the instance, what tells the
## look apart]: the same material in white taking its color off the instance, shared by every chip
## whose material is the same but for its color, as [param looks] has them so far. A material that
## is not a [StandardMaterial3D] is drawn as it is, in white.
static func _look(skin: Material, looks: Dictionary[int, Array]) -> Array:
	var paint := skin as StandardMaterial3D
	if paint == null:
		return [skin, Color.WHITE, str(skin.get_instance_id())]
	var parts := PackedStringArray()
	for property: Dictionary in paint.get_property_list():
		if property["usage"] & PROPERTY_USAGE_STORAGE and property["name"] != "albedo_color":
			parts.append(str(paint.get(property["name"])))
	var same := ",".join(parts)
	# Stored linear, the way a material's own albedo is, since the instance's is taken as it is.
	var ink := Color(paint.albedo_color.srgb_to_linear(), 1.0)
	for seen: Array in looks.values():
		if seen[2] == same:
			return [seen[0], ink, same]
	var look := paint.duplicate() as StandardMaterial3D
	look.albedo_color = Color(1.0, 1.0, 1.0, paint.albedo_color.a)
	look.vertex_color_use_as_albedo = true
	return [look, ink, same]


## What a mesh is told apart from another by, for one drawn many times over: a room's primitives are
## each made afresh, so two the same shape are two meshes alike rather than one.
static func _shape(mesh: Mesh) -> String:
	return "%s%s%d" % [mesh.get_class(), mesh.get_aabb(), mesh.get_faces().size()]


## Where [param node] lies in [param root]'s own space, walked up, as [method Bake._relative] does.
static func _under(root: Node3D, node: Node3D) -> Transform3D:
	var out := node.transform
	var parent := node.get_parent() as Node3D
	while parent != null and parent != root:
		out = parent.transform * out
		parent = parent.get_parent() as Node3D
	return out
