class_name Bomb
extends StaticBody3D
## A dropped bomb, GAME.md 7.1. It arms shortly after being dropped, then blows up when a kart
## drives over it, when a bullet hits it or when its fuse runs out. The blast kills karts, breaks
## crates and turrets and sets off other bombs within its radius. Kills credit the owner, who is
## not spared. Bullets see it on the bomb layer; karts drive over it without bumping into it.

signal exploded(bomb: Bomb)

const ARM_TIME := 0.6
const RADIUS := 2.6
const BODY_RADIUS := 0.38

var owner_slot := -1
var fuse := 30.0
var color := Color.WHITE
var alive := true
var puppet := false
var armed := false

var _age := 0.0
var _trigger: Area3D
var _fuse_light: MeshInstance3D


func _ready() -> void:
	collision_layer = Layers.BOMB
	collision_mask = 0
	add_to_group(&"bombs")
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = BODY_RADIUS
	shape.shape = sphere
	shape.position = Vector3(0.0, BODY_RADIUS, 0.0)
	add_child(shape)
	_trigger = Area3D.new()
	_trigger.name = "Trigger"
	_trigger.collision_layer = Layers.TRIGGER
	_trigger.collision_mask = Layers.KART | Layers.PROTECTED
	var trigger_shape := CollisionShape3D.new()
	var trigger_sphere := SphereShape3D.new()
	trigger_sphere.radius = 0.7
	trigger_shape.shape = trigger_sphere
	trigger_shape.position = Vector3(0.0, 0.4, 0.0)
	_trigger.add_child(trigger_shape)
	add_child(_trigger)
	_build_visuals()


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_age += delta
	_blink()
	if puppet:
		return
	armed = _age >= ARM_TIME
	if _age >= fuse:
		explode()
		return
	if not armed:
		return
	for body: Node3D in _trigger.get_overlapping_bodies():
		var kart := body as Kart
		if kart != null and kart.is_targetable():
			explode()
			return


## A bullet sets the bomb off, armed or not.
func take_hit(_bullet: Bullet) -> bool:
	if not alive:
		return false
	explode()
	return true


func explode() -> void:
	if not alive:
		return
	alive = false
	exploded.emit(self)
	Events.bomb_exploded.emit(owner_slot)
	if not puppet:
		_blast()
	Explosion.spawn(get_parent(), global_position, RADIUS, color)
	queue_free()


## Everything within the radius takes the blast: karts, crates, turrets and other bombs. Asked
## of this bomb's own match rather than of the whole tree: a host and a puppet match can share
## one, in tests and in a future split screen, and a blast that swept the tree would kill the
## other match's karts and free its puppets from under it.
func _blast() -> void:
	var match_node := _match()
	if match_node == null:
		return
	for node: Node in MatchSnapshot.own_nodes(match_node, &"karts"):
		var kart := node as Kart
		if kart != null and _within(kart.global_position, 0.5):
			kart.take_blast(owner_slot)
	for node: Node in MatchSnapshot.own_nodes(match_node, &"crates"):
		var crate := node as Crate
		if crate != null and crate.alive and _within(crate.global_position, 0.5):
			crate.hit(owner_slot)
	for node: Node in MatchSnapshot.own_nodes(match_node, &"turrets"):
		var turret := node as Turret
		if turret != null and turret.alive and _within(turret.global_position, 0.4):
			turret.destroy()
	for node: Node in MatchSnapshot.own_nodes(match_node, &"bombs"):
		var other := node as Bomb
		if other != null and other != self and other.alive and _within(other.global_position, 0.0):
			other.explode()
	if match_node.camera_rig != null:
		match_node.camera_rig.shake(0.7)


## The match this bomb was dropped in, found by walking up rather than by asking the tree for
## the first one it has.
func _match() -> Match:
	var at: Node = self
	while at != null:
		var found := at as Match
		if found != null:
			return found
		at = at.get_parent()
	return null


func _within(point: Vector3, margin: float) -> bool:
	var flat := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	return flat.length() <= RADIUS + margin


## The fuse light blinks, faster in the last seconds and while still arming.
func _blink() -> void:
	var period := 0.8
	if _age < ARM_TIME:
		period = 0.12
	elif fuse - _age < 5.0:
		period = 0.25
	_fuse_light.visible = fmod(_age, period) < period * 0.5


func _build_visuals() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.12, 0.14)
	dark.metallic = 0.3
	dark.roughness = 0.4
	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = BODY_RADIUS
	sphere.height = BODY_RADIUS * 2.0
	body.mesh = sphere
	body.material_override = dark
	body.position = Vector3(0.0, BODY_RADIUS, 0.0)
	add_child(body)
	var band := MeshInstance3D.new()
	var band_mesh := TorusMesh.new()
	band_mesh.inner_radius = BODY_RADIUS - 0.02
	band_mesh.outer_radius = BODY_RADIUS + 0.03
	band.mesh = band_mesh
	var tint := StandardMaterial3D.new()
	tint.albedo_color = color
	tint.emission_enabled = true
	tint.emission = color
	tint.emission_energy_multiplier = 0.6
	band.material_override = tint
	band.position = Vector3(0.0, BODY_RADIUS, 0.0)
	add_child(band)
	var cap := MeshInstance3D.new()
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.09
	cap_mesh.bottom_radius = 0.09
	cap_mesh.height = 0.12
	cap.mesh = cap_mesh
	cap.material_override = dark
	cap.position = Vector3(0.0, BODY_RADIUS * 2.0, 0.0)
	add_child(cap)
	_fuse_light = MeshInstance3D.new()
	var light_mesh := SphereMesh.new()
	light_mesh.radius = 0.07
	light_mesh.height = 0.14
	_fuse_light.mesh = light_mesh
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.25, 0.2)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.25, 0.2)
	glow.emission_energy_multiplier = 3.0
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fuse_light.material_override = glow
	_fuse_light.position = Vector3(0.0, BODY_RADIUS * 2.0 + 0.12, 0.0)
	add_child(_fuse_light)
