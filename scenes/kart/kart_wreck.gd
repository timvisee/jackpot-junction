class_name KartWreck
extends Node3D
## A kart springing apart, GAME.md 8.1b, whichever body it is built in: when a kart is wrecked its
## shell and the long pieces of its trim let go, a bumper, a wooden frame or a molded base, the
## wheels roll off, the driver pops out of the cockpit and the small trim flies, the tin's key off
## its tail. Every piece is the kart's own mesh in its own paint as it flies, so the burst is the
## kart it was rather than chunks of its color; and as each lands it goes to ash, a gray laid over
## it, and shrinks to most of its size, so what lies on the felt is a wreck at a glance, never a
## kart or a pickup, and it is swept away a while before the kart comes back, the key turning till
## it goes. The gray is one plain lit glaze on both sides, the score tanks' glass's shader, so
## nothing new is compiled.
##
## Looks only: nothing here collides, and nothing of the match waits on it. A client builds its own
## when a puppet dies, as it pops its own [Burst].

## How long the pieces lie there, a second short of the wait before a kart comes back, GAME.md 3.6,
## and the last part of that over which they shrink away.
const LIFETIME := 2.0
const FADE := 0.4
## The ash a piece goes to once it lands: the gray laid over it and how much of the piece it hides,
## how long it takes to come over it, and how much of its size the piece is left with.
const ASH := Color(0.42, 0.41, 0.4)
const ASH_COVER := 0.86
const ASH_TIME := 0.35
const ASH_SIZE := 0.72
const GRAVITY := 22.0
## How much of its fall a piece keeps when it lands, and of its slide along the felt.
const BOUNCE := 0.32
const FRICTION := 0.55
## How fast the key turns while it lies there, in turns a second: winding back up.
const KEY_TURNS := 1.2
## How long a piece of trim is, along the kart or across it, in meters, for it to hop and tip with
## the shell rather than fly: a bumper the length of the kart, a woodie's frame, a microcar's base.
const HEAVY_LONG := 1.0

var _pieces: Array[Dictionary] = []
var _age := 0.0
var _rng := RandomNumberGenerator.new()


## The kart whose body is [param body] sprung apart where it stands, under [param parent]; null
## for a body with nothing to spring apart.
static func spawn(parent: Node, body: Node3D) -> KartWreck:
	if parent == null or body == null or not body.is_inside_tree():
		return null
	var model := body.get_node_or_null("Model") as Node3D
	if model == null:
		return null
	var wreck := KartWreck.new()
	wreck.name = "KartWreck"
	parent.add_child(wreck)
	wreck._rng.randomize()
	wreck._take(body, model)
	return wreck


func _take(body: Node3D, model: Node3D) -> void:
	var middle := body.global_position
	var hops: Array[Node3D] = []
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if not part.is_visible_in_tree():
			continue
		hops.append(_copy(part))
	for worn: String in ["Hat", "Flag", "Plate"]:
		var piece := body.get_node_or_null(worn) as Node3D
		if piece != null and piece.visible:
			var copied := piece.duplicate() as Node3D
			add_child(copied)
			copied.global_transform = piece.global_transform
			hops.append(copied)
	for piece: Node3D in hops:
		var lower := piece.name.to_lower()
		var out := piece.global_position - middle
		out.y = 0.0
		if out.length() < 0.05:
			out = Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0))
		out = out.normalized()
		var speed := _rng.randf_range(1.6, 3.2)
		var up := _rng.randf_range(4.0, 6.5)
		var spin := Vector3(
			_rng.randf_range(-8.0, 8.0), _rng.randf_range(-6.0, 6.0), _rng.randf_range(-8.0, 8.0)
		)
		if lower.begins_with("body") or _long(piece):
			# The shell and its long trim hop and tip rather than fly: they are the heaviest of it.
			speed *= 0.3
			up *= 0.7
			spin *= 0.25
		elif lower.begins_with("wheel"):
			# A wheel rolls off the way it faces, upright for as long as it keeps rolling.
			speed *= 1.3
			up *= 0.45
			spin = Vector3(_rng.randf_range(10.0, 16.0), 0.0, 0.0)
		elif lower.begins_with("character") or lower == "cap":
			up *= 1.25
		var key := lower.begins_with("trim-key")
		if key:
			up *= 1.4
		(
			_pieces
			. append(
				{
					"node": piece,
					"velocity": out * speed + Vector3.UP * up,
					"spin": spin,
					"rest": piece.global_position.y,
					"key": key,
					"scale": piece.scale,
					"landed": false,
					"ash": 0.0,
					"glaze": _glaze(piece),
					"signs": _signs(piece),
				}
			)
		)


## Whether [param piece] is a mesh as long as [constant HEAVY_LONG] or longer, along the kart or
## across it, measured in its own axes, which are the kart's, so the way the kart faces is nothing.
static func _long(piece: Node3D) -> bool:
	var mesh := piece as MeshInstance3D
	if mesh == null or mesh.mesh == null:
		return false
	var size := mesh.get_aabb().size * mesh.global_basis.get_scale()
	return maxf(size.x, size.z) >= HEAVY_LONG


## The ash laid over every mesh of [param piece], clear until the piece lands: a glaze of its own,
## since the pieces land one after another. A plate's text and a sprite take no glaze and are
## grayed instead, see [method _signs].
static func _glaze(piece: Node3D) -> StandardMaterial3D:
	var glaze := StandardMaterial3D.new()
	glaze.albedo_color = Color(ASH, 0.0)
	glaze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Both sides, as the kart's own paint is: a shell seen from under or a cockpit from inside
	# showed its paint through a glaze on its outside alone.
	glaze.cull_mode = BaseMaterial3D.CULL_DISABLED
	glaze.roughness = 0.9
	var parts: Array[Node] = [piece]
	parts.append_array(piece.find_children("*", "GeometryInstance3D", true, false))
	for node: Node in parts:
		var part := node as MeshInstance3D
		if part != null:
			part.material_overlay = glaze
	return glaze


## [param piece]'s text and sprites, which take no glaze and are tinted to the ash instead.
static func _signs(piece: Node3D) -> Array[GeometryInstance3D]:
	var signs: Array[GeometryInstance3D] = []
	for node: Node in piece.find_children("*", "", true, false):
		if node is Label3D or node is SpriteBase3D:
			signs.append(node as GeometryInstance3D)
	return signs


## A copy of [param part] where it stands, in the same mesh and the same paint.
func _copy(part: MeshInstance3D) -> MeshInstance3D:
	var copy := MeshInstance3D.new()
	copy.name = part.name
	copy.mesh = part.mesh
	copy.material_override = part.material_override
	for surface: int in part.get_surface_override_material_count():
		copy.set_surface_override_material(surface, part.get_surface_override_material(surface))
	copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(copy)
	copy.global_transform = part.global_transform
	return copy


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var shrink := clampf((LIFETIME - _age) / FADE, 0.0, 1.0)
	for piece: Dictionary in _pieces:
		var node: Node3D = piece["node"]
		var velocity: Vector3 = piece["velocity"]
		var spin: Vector3 = piece["spin"]
		velocity.y -= GRAVITY * delta
		node.global_position += velocity * delta
		var rest: float = piece["rest"]
		if node.global_position.y < rest:
			node.global_position.y = rest
			piece["landed"] = true
			velocity.y = absf(velocity.y) * BOUNCE
			velocity.x *= FRICTION
			velocity.z *= FRICTION
			spin *= FRICTION
			if velocity.y < 0.6:
				velocity.y = 0.0
		node.rotate_object_local(Vector3.RIGHT, spin.x * delta)
		node.rotate_object_local(Vector3.UP, spin.y * delta)
		node.rotate_object_local(Vector3.FORWARD, spin.z * delta)
		if piece["key"] and velocity.length() < 0.2:
			node.rotate_object_local(Vector3.UP, KEY_TURNS * TAU * delta)
		piece["velocity"] = velocity
		piece["spin"] = spin
		var ash: float = piece["ash"]
		if piece["landed"] and ash < 1.0:
			ash = minf(ash + delta / ASH_TIME, 1.0)
			piece["ash"] = ash
			var settled := smoothstep(0.0, 1.0, ash)
			(piece["glaze"] as StandardMaterial3D).albedo_color.a = ASH_COVER * settled
			var tint := Color.WHITE.lerp(ASH, ASH_COVER * settled)
			for sign: GeometryInstance3D in piece["signs"]:
				sign.set(&"modulate", tint)
		var size: Vector3 = piece["scale"]
		node.scale = size * shrink * lerpf(1.0, ASH_SIZE, smoothstep(0.0, 1.0, ash))
