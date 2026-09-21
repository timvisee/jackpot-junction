class_name Crowd
extends Node3D
## The people who came to watch, GAME.md 8.1: a band of small figures standing on the table all
## the way round the arena, and a DJ booth along the top edge of it.
##
## They bob along while the room is quiet. Once the excitement meter of 8.4 reaches the top two
## levels they are on their feet, and a kill sets them jumping for a couple of seconds whatever
## the meter says, so the loudest thing in a match is answered by the room rather than only by
## the HUD. The booth's speakers pulse on the beat with them.
##
## There are getting on for a thousand of them, so none of them is a node. The whole crowd is one
## [MultiMesh] of one two-surface figure, drawn in two calls, and the bobbing and leaning happens
## in the vertex shader off a single beat that the whole room shares. Nothing is touched per
## figure per frame, so a fuller house costs a longer instance buffer rather than more work, and
## the crowd never shows up in a frame time. Who stands where, how big they are, which way they
## face, what they are wearing and where in the beat they are is rolled once at build time, since
## a row of identical people evenly spaced reads as a fence rather than as a crowd.
##
## Everything here is scenery: no collision, nothing to drive into, nothing that decides
## anything. A client runs its own crowd off the same events, GAME.md 10.3.

## Metres between two places along a row, between rows, and between the wall and the front row.
const SPACING := 0.62
const ROW_DEPTH := 0.92
const ROWS := 4
const STANDOFF := 1.15
## How far off their spot somebody may stand, and how often a place is taken at all: a gap in a
## crowd is what makes the rest of it look like people rather than like a pattern.
const JITTER := 0.28
const DENSITY := 0.86
## The shortest and the tallest of them, as a share of the usual size.
const SIZE_RANGE := Vector2(0.82, 1.18)
## The stands: how long one stretch of tribune is, how far each row of it is lifted over the row
## in front, how far one keeps off a corner, and how far its steps run past the last person on
## them so that nobody is standing on the edge of one.
const STAND_LENGTH := Vector2(7.0, 13.0)
const TIER := 0.4
const CORNER_CLEARANCE := 2.5
const STAND_MARGIN := 0.7
## How far out into the band the booth stands, in rows, and the patch of table it is given: the
## booth is in the crowd rather than behind it, so people who would be standing where it is go
## somewhere else instead.
const BOOTH_ROW := 1.5
const BOOTH_CLEARANCE := Vector2(7.4, 1.9)
## How many places a stand is allowed to try before it gives up on that side, so a stand never
## ends up built through the booth.
const STAND_TRIES := 8
## Away from the arena, on each of the four sides.
const OUTWARD: Array[Vector3] = [
	Vector3(0.0, 0.0, -1.0),
	Vector3(0.0, 0.0, 1.0),
	Vector3(-1.0, 0.0, 0.0),
	Vector3(1.0, 0.0, 0.0),
]
## The table top, which is where they stand: the felt is a slab of this thickness on top of it.
const TABLE_TOP := -Arena.FLOOR_THICKNESS
const BODY := 0.42
const HEAD := 0.17
## The excitement level at which the room is on its feet, GAME.md 8.4.
const DANCING_LEVEL := 5
## How high a jump goes, how far a dancer leans with it, and how long a kill keeps them at it.
const JUMP := 0.4
const DANCING_LEAN := 0.28
const DANCING_RATE := 7.0
const CHEER := 1.8
## The same three while the room is quiet: a shuffle rather than a dance.
const RESTING_LIFT := 0.045
const RESTING_LEAN := 0.05
const RESTING_RATE := 1.7
## How fast the room takes up a new mood, and the beat's own period, which it is wrapped at so
## that an hour-long match never runs it out of float precision or jumps when it comes round.
## How many frames the house waits before standing up around a new bay: long enough for
## everything that wants one as the room is built to have asked.
const REBUILD_WAIT := 2
const SETTLE := 5.0
const PERIOD := TAU * 2.0
## The colours the crowd comes in: the room's own, plus enough others to look like people.
const SHIRTS: Array[Color] = [
	Color("#E23D3D"),
	Color("#3D6FE2"),
	Color("#F2D23D"),
	Color("#43C463"),
	Color("#9B4FE2"),
	Color("#F28C3D"),
	Color("#3DD9E2"),
	Color("#F26BB8"),
	Color("#E8D8A0"),
]
## The animation, run on the figures themselves rather than on their transforms. Each one carries
## its own place in the beat, its own share of the jump and its own share of the lean, so a
## thousand people on one beat still move like a thousand people.
const FIGURE_VERTEX := """
shader_type spatial;

uniform float beat = 0.0;
uniform float lift = 0.0;
uniform float lean = 0.0;

void vertex() {
	float own = beat + INSTANCE_CUSTOM.x;
	VERTEX.y += abs(sin(own)) * lift * INSTANCE_CUSTOM.y;
	float tip = sin(own * 0.5 + INSTANCE_CUSTOM.w) * lean * INSTANCE_CUSTOM.z;
	float s = sin(tip);
	float c = cos(tip);
	VERTEX.xy = vec2(VERTEX.x * c - VERTEX.y * s, VERTEX.x * s + VERTEX.y * c);
}
"""
## The shirt takes the colour rolled for that figure; the face takes its alpha, which is how dark
## this one is, so both surfaces are told apart by one instance colour. Both are written straight
## to albedo, which is read as light rather than as a colour off a screen, so the values here and
## the ones in the instance buffer are the linear ones: an sRGB colour put in raw comes out of a
## crowd of a thousand as a wash of pastel.
const SHIRT_FRAGMENT := """
void fragment() {
	ALBEDO = COLOR.rgb;
}
"""
const FACE_FRAGMENT := """
void fragment() {
	ALBEDO = vec3(0.890, 0.768, 0.604) * (1.0 - COLOR.a * 0.62);
}
"""

## The excitement level of the match, 0 to 6. The match keeps it up to date.
var level := 0
## Scenery can be switched off: the Garage in 9.4 is not a party, GAME.md 8.1.
var enabled := true

## Where everybody is standing, kept after the build because it is the record of the house.
var _spots: Array[Transform3D] = []
## The footprints of the tribunes, flat on the table: inside one, a row stands a step higher.
var _footprints: Array[Rect2] = []
## Patches of table nobody stands in and no stand is built over: the booth's, and whatever else
## has been put out there since, such as the score tanks of GAME.md 8.1.
var _clear: Array[Rect2] = []
## The size of the arena this house was raised around, so it can be raised again.
var _size := Vector2.ZERO
var _stands: Node3D
var _shirts: PackedColorArray = []
var _traits: PackedColorArray = []
var _onlookers: MultiMeshInstance3D
var _skins: Array[ShaderMaterial] = []
var _speakers: Array[Node3D] = []
## Whoever is behind the decks, who dances in the booth's own space rather than on the table.
var _dj: Node3D
var _cheer := 0.0
## Frames left until the house goes up again, 0 when it is standing as it should be.
var _rebuild_wait := 0
var _beat := 0.0
var _rate := RESTING_RATE
var _lift := RESTING_LIFT
var _lean := RESTING_LEAN
var _rng := RandomNumberGenerator.new()


## Fills the table around an arena of [param size] metres with onlookers.
static func add_to(parent: Node3D, size: Vector2) -> Crowd:
	var crowd := Crowd.new()
	crowd.name = "Crowd"
	parent.add_child(crowd)
	crowd._build(size)
	return crowd


func _ready() -> void:
	Events.kart_killed.connect(_on_kart_killed)


func _exit_tree() -> void:
	if Events.kart_killed.is_connected(_on_kart_killed):
		Events.kart_killed.disconnect(_on_kart_killed)


## How many people came.
func count() -> int:
	return _spots.size()


func _process(delta: float) -> void:
	if _rebuild_wait > 0:
		_rebuild_wait -= 1
		if _rebuild_wait == 0:
			_build(_size)
	visible = enabled
	if not enabled:
		return
	# A player who would rather have the table to themselves keeps the booth and loses the house,
	# GAME.md 8.5. Hidden rather than never built, since the setting can be changed mid-match.
	var watching := Game.settings.crowd
	_onlookers.visible = watching
	if _stands != null:
		_stands.visible = watching
	_cheer = maxf(_cheer - delta, 0.0)
	var dancing := level >= DANCING_LEVEL or _cheer > 0.0
	var blend := 1.0 - exp(-delta * SETTLE)
	_rate = lerpf(_rate, DANCING_RATE if dancing else RESTING_RATE, blend)
	_lift = lerpf(_lift, JUMP if dancing else RESTING_LIFT, blend)
	_lean = lerpf(_lean, DANCING_LEAN if dancing else RESTING_LEAN, blend)
	_beat = fmod(_beat + delta * _rate, PERIOD)
	if watching:
		for skin: ShaderMaterial in _skins:
			skin.set_shader_parameter(&"beat", _beat)
			skin.set_shader_parameter(&"lift", _lift)
			skin.set_shader_parameter(&"lean", _lean)
	_step_booth()


## The booth is four nodes rather than a thousand, so it is animated the ordinary way.
func _step_booth() -> void:
	if _dj != null:
		_dj.position.y = absf(sin(_beat)) * _lift
		_dj.rotation.z = sin(_beat * 0.5) * _lean
	var thump := 1.0 + (_lean * 0.8) * (1.0 - Audio.music_beat())
	for speaker: Node3D in _speakers:
		speaker.scale = Vector3(thump, thump, thump)


## Somebody went down, GAME.md 3.6. Worth getting up for whatever the meter says.
func _on_kart_killed(_victim: int, _killer: int, _cause: StringName) -> void:
	_cheer = CHEER


## Keeps a patch of table free and stands the house up again around it. For whatever else ends
## up out here: a crowd standing in front of a thing put there to be looked at is worse than a
## slightly smaller crowd.
func keep_clear(area: Rect2) -> void:
	_clear.append(area)
	# Stood up again a couple of frames later rather than here and now, and once however many
	# bays are asked for: the tanks, the hoardings and the clock board each want one as the room
	# is built, and a house rebuilt per asker is a thousand people put down and picked up again
	# four times over, which is long enough to be felt.
	_rebuild_wait = REBUILD_WAIT if _size != Vector2.ZERO else 0


## Whether [param at] falls in a patch that is being kept clear, grown by [param slack].
func _blocked(at: Vector2, slack: float) -> bool:
	for area: Rect2 in _clear:
		if area.grow(slack).has_point(at):
			return true
	return false


## Whether [param box] runs into a patch that is being kept clear, grown by [param slack].
func _overlaps(box: Rect2, slack: float) -> bool:
	for area: Rect2 in _clear:
		if box.intersects(area.grow(slack)):
			return true
	return false


func _build(size: Vector2) -> void:
	_rng.seed = hash(size)
	_size = size
	# A rebuild starts from an empty table: the booth puts its own patch back as it goes down.
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_spots.clear()
	_shirts.clear()
	_traits.clear()
	_footprints.clear()
	_skins.clear()
	_speakers.clear()
	_onlookers = null
	_stands = null
	_dj = null
	var kept := _clear.duplicate()
	_clear.clear()
	var half := size * 0.5
	var outer := half + Vector2.ONE * (STANDOFF + (ROWS - 1) * ROW_DEPTH)
	# The booth goes down first because everything else is placed around it: it stands a couple
	# of rows into the crowd, with people in front of it and people behind it, rather than out on
	# its own behind the back row where it read as a thing parked next to the party.
	_booth(Vector3(0.0, TABLE_TOP, -(half.y + STANDOFF + BOOTH_ROW * ROW_DEPTH)))
	for area: Rect2 in kept:
		if not _clear.has(area):
			_clear.append(area)
	_raise_stands(half)
	for row: int in ROWS:
		_ring(half + Vector2.ONE * (STANDOFF + row * ROW_DEPTH), row)
	_raise_house(outer)


## One row of onlookers, walked round the four edges of a rectangle. Each edge leaves its far
## corner to the edge after it, so nobody is standing inside anybody.
func _ring(half: Vector2, row: int) -> void:
	var corners: Array[Vector3] = [
		Vector3(-half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, half.y),
		Vector3(-half.x, 0.0, half.y),
	]
	for i: int in 4:
		_line(corners[i], corners[(i + 1) % 4], row)


func _line(from: Vector3, to: Vector3, row: int) -> void:
	var steps := maxi(int(from.distance_to(to) / SPACING), 1)
	for i: int in steps:
		_stand(from.lerp(to, float(i) / float(steps)), row)


## Rolls one onlooker onto a spot, or leaves the spot empty.
func _stand(at: Vector3, row: int) -> void:
	# Grown by the jitter, since the spot is rolled off this point and could wander in.
	if _blocked(Vector2(at.x, at.z), JITTER):
		return
	if _rng.randf() > DENSITY:
		return
	var spot := Vector3(
		at.x + _rng.randf_range(-JITTER, JITTER),
		TABLE_TOP + _tier_at(at, row),
		at.z + _rng.randf_range(-JITTER, JITTER)
	)
	var turned := Basis.from_euler(Vector3(0.0, _rng.randf_range(0.0, TAU), 0.0))
	var size := _rng.randf_range(SIZE_RANGE.x, SIZE_RANGE.y)
	_spots.append(Transform3D(turned.scaled(Vector3.ONE * size), spot))
	var shirt := SHIRTS[_rng.randi_range(0, SHIRTS.size() - 1)].srgb_to_linear()
	# The alpha is not transparency: it is how dark this one's face is, carried along with the
	# shirt so that one instance colour dresses both surfaces.
	shirt.a = _rng.randf_range(0.0, 1.0)
	_shirts.append(shirt)
	_traits.append(
		Color(
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(0.7, 1.3),
			_rng.randf_range(0.5, 1.5),
			_rng.randf_range(0.0, TAU)
		)
	)


## How high somebody in [param row] stands at [param at]: on the table, unless a tribune has
## been built under that stretch of the band, in which case one step per row behind the front.
func _tier_at(at: Vector3, row: int) -> float:
	if row <= 0:
		return 0.0
	for stand: Rect2 in _footprints:
		if stand.has_point(Vector2(at.x, at.z)):
			return row * TIER
	return 0.0


## Builds a tribune into one stretch of each side of the band, GAME.md 8.1. Somewhere along a
## side rather than the whole of it: a stand that goes all the way round is a bowl, and this is a
## table with people standing at it.
func _raise_stands(half: Vector2) -> void:
	_stands = Node3D.new()
	_stands.name = "Stands"
	add_child(_stands)
	var tread := _paint(Palette.BLOCK)
	var back := _paint(Palette.BLOCK_EDGE)
	for side: int in 4:
		var out := OUTWARD[side]
		var sideways := Vector3(absf(out.z), 0.0, absf(out.x))
		var along := half.x if sideways.x > 0.5 else half.y
		var across := half.y if sideways.x > 0.5 else half.x
		var run := _rng.randf_range(STAND_LENGTH.x, STAND_LENGTH.y)
		var room := along - run * 0.5 - CORNER_CLEARANCE
		if room <= 0.0:
			continue
		var edge := out * (across + STANDOFF - ROW_DEPTH * 0.5)
		var near := edge
		var footprint := Rect2()
		for attempt: int in STAND_TRIES:
			near = edge + sideways * _rng.randf_range(-room, room)
			footprint = _footprint(near, out, sideways, run)
			if not _overlaps(footprint, STAND_MARGIN):
				break
			footprint = Rect2()
		if footprint.get_area() <= 0.0:
			continue
		_footprints.append(footprint)
		_step_up(near, out, run, _stands, tread, back)


## The footprint of one stand, flat on the table, which is what decides who is standing on it.
static func _footprint(near: Vector3, out: Vector3, sideways: Vector3, run: float) -> Rect2:
	var corner := near - sideways * (run * 0.5)
	var far := near + out * (ROWS * ROW_DEPTH) + sideways * (run * 0.5)
	return Rect2(
		Vector2(minf(corner.x, far.x), minf(corner.z, far.z)),
		Vector2(absf(far.x - corner.x), absf(far.z - corner.z))
	)


## The steps themselves: one solid block per lifted row, rising away from the arena, with a wall
## across the back of the top one.
func _step_up(
	near: Vector3, out: Vector3, run: float, parent: Node3D, tread: Material, back: Material
) -> void:
	var wide := run + STAND_MARGIN
	for row: int in range(1, ROWS):
		var high := row * TIER
		var step := MeshInstance3D.new()
		step.mesh = _slab(_spread(out, wide, ROW_DEPTH, high))
		step.material_override = tread
		step.position = (
			near + out * (ROW_DEPTH * (row + 0.5)) + Vector3.UP * (TABLE_TOP + high * 0.5)
		)
		parent.add_child(step)
	var wall := MeshInstance3D.new()
	var high := (ROWS - 1) * TIER + 0.55
	wall.mesh = _slab(_spread(out, wide, 0.3, high))
	wall.material_override = back
	wall.position = near + out * (ROWS * ROW_DEPTH + 0.15) + Vector3.UP * (TABLE_TOP + high * 0.5)
	parent.add_child(wall)


## A box laid out for a stand facing [param out]: [param wide] along the stand, [param deep] away
## from the arena.
static func _spread(out: Vector3, wide: float, deep: float, high: float) -> Vector3:
	if absf(out.z) > 0.5:
		return Vector3(wide, high, deep)
	return Vector3(deep, high, wide)


static func _slab(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


## Puts the whole house into one [MultiMesh]. Everything that varies between two people is in the
## instance buffer, which is written once and never touched again.
func _raise_house(outer: Vector2) -> void:
	var mesh := _figure_mesh()
	mesh.surface_set_material(0, _skin(SHIRT_FRAGMENT))
	mesh.surface_set_material(1, _skin(FACE_FRAGMENT))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = _spots.size()
	for i: int in _spots.size():
		multimesh.set_instance_transform(i, _spots[i])
		multimesh.set_instance_color(i, _shirts[i])
		multimesh.set_instance_custom_data(i, _traits[i])
	_onlookers = MultiMeshInstance3D.new()
	_onlookers.name = "Onlookers"
	_onlookers.multimesh = multimesh
	# A crowd this size casting a thousand shadows costs more than the crowd does, and they are
	# standing off the floor where nothing of the match ever reaches them.
	_onlookers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# One cull unit, and the shader lifts people off their spots, so the box has to allow for it.
	_onlookers.custom_aabb = AABB(
		Vector3(-outer.x - 1.0, TABLE_TOP - 0.5, -outer.y - 1.0),
		Vector3(outer.x * 2.0 + 2.0, 4.0, outer.y * 2.0 + 2.0)
	)
	add_child(_onlookers)


## One onlooker as a single mesh with its feet at the origin: a body and a head, coarse enough
## that a thousand of them is a rounding error and fine enough that at this size nobody can tell.
static func _figure_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.15
	capsule.height = BODY
	capsule.radial_segments = 6
	capsule.rings = 2
	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES, _lifted(capsule.get_mesh_arrays(), BODY * 0.5)
	)
	var sphere := SphereMesh.new()
	sphere.radius = HEAD
	sphere.height = HEAD * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES, _lifted(sphere.get_mesh_arrays(), BODY + HEAD * 0.7)
	)
	return mesh


## The same mesh arrays with every vertex moved up, so both surfaces stand on the same feet.
static func _lifted(arrays: Array, by: float) -> Array:
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i: int in points.size():
		points[i] += Vector3(0.0, by, 0.0)
	arrays[Mesh.ARRAY_VERTEX] = points
	return arrays


func _skin(fragment: String) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = FIGURE_VERTEX + fragment
	var material := ShaderMaterial.new()
	material.shader = shader
	_skins.append(material)
	return material


## The booth at the top: a desk, a pair of speakers that pulse on the beat, and somebody behind
## it who never stops dancing.
func _booth(at: Vector3) -> void:
	_clear.append(Rect2(Vector2(at.x, at.z) - BOOTH_CLEARANCE * 0.5, BOOTH_CLEARANCE))
	var booth := Node3D.new()
	booth.name = "DjBooth"
	booth.position = at
	add_child(booth)
	var desk := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.4, 0.9, 1.0)
	desk.mesh = box
	desk.material_override = _paint(Color(0.14, 0.14, 0.18))
	desk.position = Vector3(0.0, 0.45, 0.0)
	booth.add_child(desk)
	var deck := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(2.6, 0.08, 0.7)
	deck.mesh = plate
	deck.material_override = _paint(Palette.NEON_MAGENTA)
	deck.position = Vector3(0.0, 0.94, 0.0)
	booth.add_child(deck)
	for side: int in [-1, 1]:
		var speaker := Node3D.new()
		speaker.position = Vector3(side * 2.6, 0.0, 0.0)
		var cabinet := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(1.0, 1.7, 1.0)
		cabinet.mesh = shape
		cabinet.material_override = _paint(Color(0.1, 0.1, 0.13))
		cabinet.position = Vector3(0.0, 0.85, 0.0)
		speaker.add_child(cabinet)
		var cone := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.3
		disc.bottom_radius = 0.3
		disc.height = 0.08
		cone.mesh = disc
		cone.material_override = _glow(Palette.NEON_CYAN)
		cone.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		cone.position = Vector3(0.0, 1.0, 0.54)
		speaker.add_child(cone)
		booth.add_child(speaker)
		_speakers.append(speaker)
	var dj := Node3D.new()
	dj.position = Vector3(0.0, 0.0, -0.9)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.2
	capsule.height = 0.7
	body.mesh = capsule
	body.material_override = _paint(Palette.CHIP_GOLD)
	body.position = Vector3(0.0, 0.7, 0.0)
	dj.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	head.material_override = _paint(Palette.CHIP_WHITE)
	head.position = Vector3(0.0, 1.25, 0.0)
	dj.add_child(head)
	booth.add_child(dj)
	_dj = dj


func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


func _glow(color: Color) -> StandardMaterial3D:
	var material := _paint(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.4
	return material
