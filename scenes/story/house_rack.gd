class_name HouseRack
extends StaticBody3D
## One of the House's racks at the Final Hand, STORY.md 8.2: raised out of the Count Room's floor
## where the House's forecast of a kart ends, across the road it expects the kart to take, a rack
## of the room's own as its walls are. Its tiles are outlined in gold first, a moment for anybody to
## see it coming; then it rises out of the floor, stands a few seconds as a wall, and sinks again.
## Driven into, it is a wall and never a death. The host raises it, see [HouseForecast], and every
## client puts up a puppet of it from the snapshot, see [MatchSnapshot], so it stands on every
## screen alike, solid for a client's own kart as well.

const GROUP := &"house_racks"
## How long the tiles are outlined before it rises, how long it takes to rise, how long it stands
## and how long it takes to sink again, in seconds.
const MARK := 0.8
const RISE := 0.3
const STAND := 3.0
const SINK := 0.4
const LIFE := MARK + RISE + STAND + SINK
## How much of its tiles it takes, how far up it has to be before it is something to drive into,
## and how wide the outline is.
const SHARE := 0.9
const SOLID_FROM := 0.35
const OUTLINE := 0.09
## How wide the gold rim round its top is.
const RIM := 0.08

## The slot whose forecast it was raised at, and its age, from which everything else follows.
var target := -1
var age := 0.0
var puppet := false
## How much floor it stands on, in meters, and how tall it stands.
var footprint := Vector2(1.25, 1.25)
var tall := 1.0

var _body: Node3D
var _outline: MeshInstance3D
var _gold: StandardMaterial3D
var _shape: CollisionShape3D
var _solid := false
var _rose := false


## A rack for [param slot] over [param floor_size] of floor in the middle at [param at],
## [param height] tall, in [param arena]'s look.
static func raise(
	into: Node, at: Vector3, floor_size: Vector2, slot: int, arena: Arena, height := 1.0
) -> HouseRack:
	var rack := HouseRack.new()
	rack.name = "HouseRack"
	rack.target = slot
	rack.footprint = floor_size
	rack.tall = height
	rack._build(arena.surfaces if arena != null else null, arena.room if arena != null else null)
	into.add_child(rack)
	rack.global_position = Vector3(at.x, 0.0, at.z)
	return rack


func _build(surfaces: Surfaces, room: RoomLook) -> void:
	add_to_group(GROUP)
	collision_layer = Layers.WORLD
	collision_mask = 0
	var size := Vector3(footprint.x * SHARE, tall, footprint.y * SHARE)
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	_shape.shape = box
	_shape.position = Vector3(0.0, tall * 0.5, 0.0)
	_shape.disabled = true
	add_child(_shape)
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	if surfaces != null and room != null:
		CountKit.rack(_body, size, surfaces, room)
		# Its top in the House's gold rather than the room's green, a rim round it and the strip
		# down it: its own, raised on purpose.
		var gold := surfaces.neon(HouseTheme.FOIL, 0.35)
		var rim := MeshInstance3D.new()
		rim.name = "Rim"
		rim.mesh = outline_mesh(Vector2(size.x, size.z), RIM)
		rim.material_override = gold
		rim.position.y = size.y * 0.5 + 0.012
		_body.add_child(rim)
		var strip := MeshInstance3D.new()
		strip.name = "Strip"
		var bar := BoxMesh.new()
		var long_x := size.x >= size.z
		bar.size = (
			Vector3(size.x - RIM * 2.0, 0.03, size.z * 0.22)
			if long_x
			else Vector3(size.x * 0.22, 0.03, size.z - RIM * 2.0)
		)
		strip.mesh = bar
		strip.material_override = gold
		strip.position.y = size.y * 0.5 + 0.01
		_body.add_child(strip)
	_outline = MeshInstance3D.new()
	_outline.name = "Outline"
	_outline.mesh = outline_mesh(footprint, OUTLINE)
	_gold = StandardMaterial3D.new()
	_gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_gold.albedo_color = HouseTheme.FOIL
	_gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_outline.material_override = _gold
	_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_outline.position.y = 0.025
	add_child(_outline)
	_lay()


## A frame round [param across] of floor, [param width] wide, flat on it.
static func outline_mesh(across: Vector2, width: float) -> ArrayMesh:
	var half := across * 0.5
	var inner := half - Vector2.ONE * width
	var points := PackedVector3Array()
	var corners: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for i: int in 4:
		var a := corners[i]
		var b := corners[(i + 1) % 4]
		var outer_a := Vector3(a.x * half.x, 0.0, a.y * half.y)
		var outer_b := Vector3(b.x * half.x, 0.0, b.y * half.y)
		var inner_a := Vector3(a.x * inner.x, 0.0, a.y * inner.y)
		var inner_b := Vector3(b.x * inner.x, 0.0, b.y * inner.y)
		points.append_array([outer_a, outer_b, inner_b, outer_a, inner_b, inner_a])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var up := PackedVector3Array()
	up.resize(points.size())
	up.fill(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = up
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## How far up it stands at [param at] seconds of age, 0 under the floor to 1 standing.
static func height_at(at: float) -> float:
	if at < MARK:
		return 0.0
	if at < MARK + RISE:
		return ease((at - MARK) / RISE, 0.4)
	if at < MARK + RISE + STAND:
		return 1.0
	return clampf(1.0 - (at - MARK - RISE - STAND) / SINK, 0.0, 1.0)


## Whether it is something to drive into now.
func is_solid() -> bool:
	return _solid


## Whether it has risen at all: one taken down before it rose was never there.
func has_risen() -> bool:
	return _rose


## Whether [param point] is up against it, [param reach] past its sides.
func touches(point: Vector3, reach: float) -> bool:
	var half := footprint * SHARE * 0.5 + Vector2.ONE * reach
	var off := point - global_position
	return absf(off.x) <= half.x and absf(off.z) <= half.y


## Straight down into the floor, the whistle gone: what is left of its life is the sinking.
func sink() -> void:
	age = maxf(age, MARK + RISE + STAND) if age >= MARK else LIFE


func _physics_process(delta: float) -> void:
	if not puppet:
		age += delta
		if age >= LIFE:
			queue_free()
			return
	_lay()


## Where it stands at its age: the outline pulsing while the tiles are marked and gone once it has
## risen, its body up out of the floor, and solid once it is far enough up.
func _lay() -> void:
	var up := height_at(age)
	_body.position.y = tall * 0.5 + (up - 1.0) * tall
	_body.visible = up > 0.0
	var marked := 1.0 - clampf((age - MARK) / RISE, 0.0, 1.0)
	_gold.albedo_color.a = marked * (0.6 + 0.4 * sin(age * 16.0))
	_outline.visible = marked > 0.0
	var solid := up >= SOLID_FROM
	if solid:
		_rose = true
	if solid != _solid:
		_solid = solid
		_shape.set_deferred(&"disabled", not solid)
