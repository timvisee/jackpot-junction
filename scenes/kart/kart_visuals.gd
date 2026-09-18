class_name KartVisuals
extends RefCounted
## Everything a [Kart] is made of on screen: the tinted model with its roof marker, the pickup
## ring, the shield bubble, the free-aim arrow, the bounty crown and the nitro flame. Kept apart
## from the kart itself so that file stays about rules rather than geometry. Each builder hangs
## its nodes off the kart it is given and hands back the parts the kart keeps a reference to.

const MODEL := preload("res://assets/models/car-kit/kart-oobi.glb")
const MODEL_SCALE := 1.12
const MODEL_LIFT := 0.235
## How high above the kart the roof marker and the bounty crown ride.
const MARKER_HEIGHT := 1.75
const CROWN_HEIGHT := MARKER_HEIGHT + 0.42


## The body: the model tinted in the player's colour, the wheels picked out so they can be spun,
## and the roof marker. Returns the body node, the shared tint and the wheels.
static func build_body(kart: Kart) -> Dictionary:
	var body := Node3D.new()
	body.name = "Body"
	kart.add_child(body)
	var model: Node3D = MODEL.instantiate()
	model.name = "Model"
	# The model drives toward its +Z; Godot's forward is -Z.
	model.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	model.scale = Vector3.ONE * MODEL_SCALE
	model.position = Vector3(0.0, MODEL_LIFT, 0.0)
	body.add_child(model)
	var tint := StandardMaterial3D.new()
	tint.albedo_color = Palette.player_color(kart.color_index)
	var wheels: Array[MeshInstance3D] = []
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var lower := mesh.name.to_lower()
		if lower.begins_with("wheel"):
			wheels.append(mesh)
		elif not lower.contains("character"):
			mesh.material_override = tint
	body.add_child(roof_marker(kart.slot, kart.color_index))
	return {"body": body, "tint": tint, "wheels": wheels}


## Where the rear wheels sit on the model, as (half track, distance behind the middle). The tire
## marks are laid here rather than at a fraction of the kart's length that was nearly right: the
## marks were coming down a quarter of a metre behind the wheels meant to be making them. The
## rear wheels do not steer, so one measurement stands for the whole match.
##
## Measured from the middle of the tyre itself rather than from the point the model hangs it
## from. On this model the wheel's own origin sits at its inner face, a tyre's width inboard of
## where the rubber actually meets the floor, which laid the marks between the wheels.
static func rear_axle(kart: Kart, wheels: Array[MeshInstance3D]) -> Vector2:
	var found := Vector2.ZERO
	var count := 0
	for wheel: MeshInstance3D in wheels:
		if not wheel.name.to_lower().contains("back"):
			continue
		var to_kart := kart.global_transform.affine_inverse() * wheel.global_transform
		var at := (to_kart * wheel.get_aabb()).get_center()
		found += Vector2(absf(at.x), at.z)
		count += 1
	if count == 0:
		return Vector2(kart.stats.width * 0.43, kart.stats.length * 0.25)
	return found / float(count)


## Everything that hangs off the kart rather than being part of it: the pickup area with its
## progress ring, the shield bubble, the free-aim arrow, the bounty crown and the nitro flame.
static func build_attachments(kart: Kart) -> Dictionary:
	var pickup_area := Area3D.new()
	pickup_area.name = "PickupArea"
	pickup_area.collision_layer = 0
	pickup_area.collision_mask = Layers.PICKUP
	var shape := CollisionShape3D.new()
	var pickup_shape := SphereShape3D.new()
	pickup_shape.radius = kart.rules.pickup_radius
	shape.shape = pickup_shape
	shape.position = Vector3(0.0, 0.4, 0.0)
	pickup_area.add_child(shape)
	kart.add_child(pickup_area)
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	ring.mesh = torus
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Palette.NEON_CYAN
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = ring_material
	ring.position = Vector3(0.0, 0.06, 0.0)
	ring.visible = false
	kart.add_child(ring)
	var shield := MeshInstance3D.new()
	shield.name = "Shield"
	var bubble := SphereMesh.new()
	bubble.radius = 1.25
	bubble.height = 2.5
	shield.mesh = bubble
	var bubble_material := StandardMaterial3D.new()
	bubble_material.albedo_color = Color(0.2, 0.8, 1.0, 0.3)
	bubble_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shield.material_override = bubble_material
	shield.position = Vector3(0.0, 0.5, 0.0)
	shield.visible = false
	shield.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	kart.add_child(shield)
	var aim_arrow := MeshInstance3D.new()
	aim_arrow.name = "AimArrow"
	var arrow := PrismMesh.new()
	arrow.size = Vector3(0.35, 0.5, 0.08)
	aim_arrow.mesh = arrow
	var arrow_material := StandardMaterial3D.new()
	arrow_material.albedo_color = Palette.NEON_CYAN
	arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aim_arrow.material_override = arrow_material
	aim_arrow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	aim_arrow.top_level = true
	aim_arrow.visible = false
	kart.add_child(aim_arrow)
	var crown := bounty_crown()
	kart.add_child(crown)
	var flame := NitroFlame.new()
	flame.name = "Flame"
	flame.position = Vector3(0.0, 0.4, kart.stats.length * 0.5 - 0.05)
	kart.add_child(flame)
	var sparks := DriftSparks.new()
	sparks.name = "DriftSparks"
	kart.add_child(sparks)
	return {
		"pickup_area": pickup_area,
		"pickup_shape": pickup_shape,
		"ring": ring,
		"shield": shield,
		"aim_arrow": aim_arrow,
		"crown": crown,
		"flame": flame,
		"sparks": sparks,
	}


## A distinct shape per slot above the driver, so colours are not the only way to tell karts apart.
static func roof_marker(slot: int, color_index: int) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	marker.name = "RoofMarker"
	var shapes: Array[Mesh] = [
		SphereMesh.new(),
		BoxMesh.new(),
		PrismMesh.new(),
		TorusMesh.new(),
		CylinderMesh.new(),
		CapsuleMesh.new()
	]
	var mesh: Mesh = shapes[posmod(slot, shapes.size())]
	if mesh is SphereMesh:
		(mesh as SphereMesh).radius = 0.16
		(mesh as SphereMesh).height = 0.32
	elif mesh is BoxMesh:
		(mesh as BoxMesh).size = Vector3.ONE * 0.28
	elif mesh is PrismMesh:
		(mesh as PrismMesh).size = Vector3(0.32, 0.3, 0.32)
	elif mesh is TorusMesh:
		(mesh as TorusMesh).inner_radius = 0.08
		(mesh as TorusMesh).outer_radius = 0.18
	elif mesh is CylinderMesh:
		(mesh as CylinderMesh).top_radius = 0.14
		(mesh as CylinderMesh).bottom_radius = 0.14
		(mesh as CylinderMesh).height = 0.26
	elif mesh is CapsuleMesh:
		(mesh as CapsuleMesh).radius = 0.11
		(mesh as CapsuleMesh).height = 0.36
	marker.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Palette.player_color(color_index)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = material
	marker.position = Vector3(0.0, MARKER_HEIGHT, 0.0)
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return marker


## The gold crown a kart wears while there is a price on its head, GAME.md 3.10. Hidden until the
## match calls a bounty.
static func bounty_crown() -> Node3D:
	var crown := Node3D.new()
	crown.name = "BountyCrown"
	crown.visible = false
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Palette.CHIP_GOLD
	gold.emission_enabled = true
	gold.emission = Palette.CHIP_GOLD
	gold.emission_energy_multiplier = 1.6
	var band := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.26
	torus.outer_radius = 0.38
	band.mesh = torus
	band.material_override = gold
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crown.add_child(band)
	for i: int in 5:
		var spike := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.07
		cone.height = 0.24
		spike.mesh = cone
		spike.material_override = gold
		spike.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var angle := TAU * float(i) / 5.0
		spike.position = Vector3(cos(angle) * 0.32, 0.12, sin(angle) * 0.32)
		crown.add_child(spike)
	crown.position = Vector3(0.0, CROWN_HEIGHT, 0.0)
	return crown


## The marks a kart leaves behind it, GAME.md 4.3: skid marks under the rear wheels and smoke out
## of the exhaust, both shaped by what the kart is doing rather than by how fast it is going. Kept
## here rather than on the kart for the same reason the rest of this file is: it is what a kart
## looks like, not what it is.
static func update_trails(kart: Kart, delta: float, heading_before: float) -> void:
	var motor := kart.motor
	var input := kart.input
	var speed := motor.speed()
	if speed < 0.8:
		kart.smoke.update_state(input.throttle, false, false)
		return
	var turning := absf(wrapf(motor.heading - heading_before, -PI, PI)) / maxf(delta, 0.0001)
	var intensity := 0.06
	var slip := absf(motor.slip_angle())
	if motor.spinning():
		intensity = 1.0
	elif motor.drifting or slip > 0.3:
		intensity = clampf(slip / 0.7, 0.5, 1.0)
	elif input.handbrake and speed > 1.5:
		# A straight handbrake stop lays down locked-wheel skid marks.
		intensity = 0.85
	elif input.brake > 0.3 and motor.forward_speed > 1.0:
		intensity = 0.45
	elif turning > 1.5:
		intensity = 0.2
	var side := kart.global_basis.x
	var rear := kart.global_position + kart.global_basis.z * kart.rear_axle
	var now := Time.get_ticks_msec() * 0.001
	kart.tire_marks.add_sample(0, rear - side * kart.rear_half_track, side, intensity, now)
	kart.tire_marks.add_sample(1, rear + side * kart.rear_half_track, side, intensity, now)
	var skidding := input.handbrake and speed > 1.5
	var pushing := motor.boosting() or motor.turboing() or kart.nitro_active
	kart.smoke.update_state(input.throttle, motor.drifting or skidding, pushing)
	kart.step_drift_sparks()
