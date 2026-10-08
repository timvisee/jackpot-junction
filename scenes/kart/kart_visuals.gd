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
## The plate on the back of the kart, GAME.md 4.4: where it hangs, on the rear bumper under the
## flag, how big the learner's L is, and how big a license plate is.
const PLATE_AT := Vector3(0.0, 0.49, 0.69)
const LEARNER_SIDE := 0.52
const LICENSE_PLATE := Vector2(0.74, 0.21)


## The body: the model tinted in the player's color, the wheels picked out so they can be spun,
## and the roof marker. Returns the body node, the shared tint and the wheels.
static func build_body(kart: Kart) -> Dictionary:
	var body := Node3D.new()
	body.name = "Body"
	kart.add_child(body)
	var model := _model()
	body.add_child(model)
	var color := Palette.player_color(kart.color_index)
	var tint := KartDress.paint(color, kart.style)
	var wheels: Array[MeshInstance3D] = []
	paint(model, tint, wheels)
	body.set_meta(&"frame", kart.style.frame)
	var marker := roof_marker(kart.color_index)
	# A hat stands where the marker floated, so the marker moves up over it rather than through.
	marker.position.y += KartDress.HAT_LIFT[kart.style.hat]
	body.add_child(marker)
	var hat := KartDress.hat(kart.style.hat, color)
	if hat != null:
		body.add_child(hat)
	var flag := KartDress.flag(kart.style.flag, color)
	if flag != null:
		body.add_child(flag)
	return {"body": body, "tint": tint, "wheels": wheels}


## The learner's L on the back of [param kart], GAME.md 4.4: for a kart of this machine's while it
## has no license yet, and for the whole of the driving test. In place of any plate it wore.
static func learner_plate(kart: Kart) -> Node3D:
	return plate_like(_body_of(kart), "L")


## The license plate on the back of [param kart], reading [param text], GAME.md 4.4: for a kart of
## this machine's once it has its license. In place of any plate it wore.
static func license_plate(kart: Kart, text: String) -> Node3D:
	return plate_like(_body_of(kart), text)


## The plate a kart of this machine's wears, by the settings: the learner's L until the license
## is earned, and the plate chosen after.
static func plate_for_here(kart: Kart) -> Node3D:
	return plate_for_here_on(_body_of(kart))


## The plate of the seat at this machine whose kart [param kart] is, GAME.md 3.8: its linked
## profile's, or the profile playing's.
static func plate_for_seat(kart: Kart) -> Node3D:
	var player := kart.input as PlayerInput
	var seat := player.seat if player != null else 0
	return plate_like(_body_of(kart), Game.settings.seat_plate(seat))


## The same, as the word the wire carries, GAME.md 10.3: "L" or the plate's text, which a client
## says to the host for its seats, see [method NetSession._claim_plate].
static func plate_here() -> String:
	if Game.settings.license_number.is_empty():
		return "L"
	return Game.settings.license_plate


## The same plate on [param body], a kart's body or a model of one standing for display, the
## podium's say, GAME.md 3.8.
static func plate_for_here_on(body: Node3D) -> Node3D:
	return plate_like(body, plate_here())


## What [param kart] wears on its back, GAME.md 4.4: "L" for the learner's plate, the words of a
## license plate, or nothing for a kart with none.
static func plate_worn(kart: Kart) -> String:
	if kart == null or not is_instance_valid(kart):
		return ""
	return _worn_on(_body_of(kart))


## The plate [param worn], as [method plate_worn] has it, on [param body]: a kart's body, a model
## standing for a kart, the podium's say, GAME.md 3.8, or a puppet's body on a client, 10.3. The
## learner's L for "L", a license plate reading anything else, none for nothing; whatever was worn
## comes off, and a body wearing [param worn] already keeps the plate it has.
static func plate_like(body: Node3D, worn: String) -> Node3D:
	if body == null:
		return null
	var old := body.get_node_or_null("Plate") as Node3D
	if old != null:
		if _worn_on(body) == worn:
			return old
		# Out of the name's way and out of sight, but in the tree until the frame ends, so that its
		# parts are no stray nodes meanwhile, which a test would count.
		old.name = "PlateGone"
		old.visible = false
		old.queue_free()
	if worn.is_empty():
		return null
	var plate := Node3D.new()
	plate.name = "Plate"
	plate.position = PLATE_AT
	plate.set_meta(&"plate", worn)
	var drawn: ViewportTexture
	var size: Vector2
	if worn == "L":
		var figure := SchoolFigure.of(SchoolFigure.Kind.LEARNER, 128.0)
		drawn = DrawnTexture.of(plate, figure, Vector2i(128, 128))
		size = Vector2(LEARNER_SIDE, LEARNER_SIDE)
	else:
		var golden := int(body.get_meta(&"frame", 0)) > 0
		var drawing := LicensePlate.of(worn, LicensePlate.SIZE.x, false, golden)
		drawn = DrawnTexture.of(plate, drawing, Vector2i(448, 128))
		size = LICENSE_PLATE
	plate.add_child(DrawnTexture.face(size, DrawnTexture.decal(drawn)))
	body.add_child(plate)
	return plate


## Puts the plate [param frame] of [constant KartStyle.FRAMES] on [param body], GAME.md 8.9, now and
## for any plate it wears later: the plain plate, or the gold one. The learner's L is a sign rather
## than a plate, and stays as it is.
static func frame_plate(body: Node3D, frame: int) -> void:
	if body == null:
		return
	var was := int(body.get_meta(&"frame", 0))
	body.set_meta(&"frame", frame)
	var worn := _worn_on(body)
	if was == frame or worn.is_empty() or worn == "L":
		return
	var old := body.get_node_or_null("Plate") as Node3D
	if old != null:
		old.name = "PlateGone"
		old.visible = false
		old.queue_free()
	plate_like(body, worn)


## The plate a bot wears, GAME.md 4.4, by [param brain]: the easiest bots are learners, with the
## L, and the rest hold a license, with a plate drawn from their name and [param rng], the
## match's, so a seed decides it. A bot with no brain yet is a learner.
static func plate_for_bot(kart: Kart, brain: BotBrain, rng: RandomNumberGenerator) -> Node3D:
	var difficulty := brain.difficulty if brain != null else null
	if difficulty == null or difficulty.id == &"easy":
		return learner_plate(kart)
	var trait_name := brain.bot_trait.display_name if brain.bot_trait != null else ""
	return license_plate(kart, LicensePlate.for_bot(trait_name, rng))


## The body of [param kart] its plate hangs under, or nothing for a kart without one.
static func _body_of(kart: Kart) -> Node3D:
	if kart == null:
		return null
	return kart.get_node_or_null("Body") as Node3D


## What [param body] wears, as [method plate_worn] has it.
static func _worn_on(body: Node3D) -> String:
	if body == null:
		return ""
	var plate := body.get_node_or_null("Plate")
	if plate == null or not plate.has_meta(&"plate"):
		return ""
	return str(plate.get_meta(&"plate"))


## Dresses [param kart] again in its [member Kart.style], which has just been changed from [param
## was]: the lobby's stalls, GAME.md 9.6, do it to a kart already built. The body keeps its tint,
## darker on a wounded kart, and takes the new pattern; the hat, the flag and the trail are made
## again, and the roof marker moves to stand over the new hat.
static func redress(kart: Kart, was: KartStyle) -> void:
	var body := kart.get_node_or_null("Body") as Node3D
	if body == null:
		return
	var color := Palette.player_color(kart.color_index)
	var fresh := KartDress.paint(color, kart.style)
	var tint: StandardMaterial3D = kart._tint
	if tint != null:
		tint.albedo_texture = fresh.albedo_texture
		tint.texture_filter = fresh.texture_filter
		tint.uv1_triplanar = fresh.uv1_triplanar
		tint.uv1_scale = fresh.uv1_scale
	for part: String in ["Hat", "Flag"]:
		var old := body.get_node_or_null(part)
		if old != null:
			# Left in the tree until it goes, under another name so the new one can take its own:
			# taken out first, it was a node belonging to nothing until the end of the frame.
			old.name = "%sWorn" % part
			old.visible = false
			old.queue_free()
	for worn: Node3D in [
		KartDress.hat(kart.style.hat, color), KartDress.flag(kart.style.flag, color)
	]:
		if worn != null:
			body.add_child(worn)
	var marker := body.get_node_or_null("RoofMarker") as Node3D
	if marker != null:
		marker.position.y += KartDress.HAT_LIFT[kart.style.hat] - KartDress.HAT_LIFT[was.hat]
	if kart.smoke != null:
		kart.smoke.dress(color, kart.style.trail)
	if kart.tire_marks != null:
		kart.tire_marks.marks = kart.style.marks
	frame_plate(body, kart.style.frame)


## Paints [param kart] over in the player color [param color_index], for a player who has picked
## another in the lobby or the Garage, GAME.md 4.4: the body, darker while it is wounded, the roof
## marker, the hat, the flag, the trail and the aim guide. Its shots are in whatever it is in when
## they are fired.
static func recolor(kart: Kart, color_index: int) -> void:
	kart.color_index = color_index
	var color := Palette.player_color(color_index)
	var tint: StandardMaterial3D = kart._tint
	if tint != null:
		tint.albedo_color = color.darkened(0.5) if kart.is_wounded() else color
	var marker := kart.get_node_or_null("Body/RoofMarker") as MeshInstance3D
	if marker != null:
		marker.mesh = marker_shape(color_index)
		(marker.material_override as StandardMaterial3D).albedo_color = color
	var guide := kart.get_node_or_null("AimGuide") as AimGuide
	if guide != null:
		guide.paint(color)
	redress(kart, kart.style)


## Every kart in [param match_node] painted over in the palette worn now, GAME.md 8.5, for a
## player who has just changed it in the settings over the room: the karts driven, the ones of a
## client's screen and the decoys, each in the color it already was.
static func repaint_all(match_node: Match) -> void:
	for node: Node in match_node.find_children("*", "CharacterBody3D", true, false):
		var kart := node as Kart
		if kart != null:
			recolor(kart, kart.color_index)


## The kart as something to look at rather than to drive: the model in a player's color, with
## nothing hanging off it and no kart under it. The results podium stands one on each step.
## How far round a display model on a turntable starts, turning once every [param spin_seconds],
## so that it comes round to look straight at a camera on its far +Z side [param soon] seconds
## after it is first seen: the kart in the license's photo and on the podium. A model's nose is
## its -Z, so at no turn it shows the camera its back, and it used to start a little past that.
static func facing_soon(spin_seconds: float, soon := 0.5) -> float:
	return PI - TAU * soon / spin_seconds


static func display_model(color_index: int, style: KartStyle = null) -> Node3D:
	# A holder rather than the model itself: the model is turned round and scaled to sit on the
	# floor, and a hat hung off it would be turned round and scaled with it.
	var holder := Node3D.new()
	holder.name = "Kart"
	var model := _model()
	holder.add_child(model)
	var dressed := style if style != null else KartStyle.new()
	holder.set_meta(&"frame", dressed.frame)
	var color := Palette.player_color(color_index)
	var tint := KartDress.paint(color, dressed)
	var wheels: Array[MeshInstance3D] = []
	paint(model, tint, wheels)
	for worn: Node3D in [KartDress.hat(dressed.hat, color), KartDress.flag(dressed.flag, color)]:
		if worn != null:
			holder.add_child(worn)
	return holder


## Paints every part of a model but the driver in one color, and collects the wheels on the way
## past, since those are turned rather than tinted.
static func paint(model: Node3D, tint: StandardMaterial3D, wheels: Array[MeshInstance3D]) -> void:
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var lower := mesh.name.to_lower()
		if lower.begins_with("wheel"):
			wheels.append(mesh)
		elif not lower.contains("character"):
			mesh.material_override = tint


static func _model() -> Node3D:
	var model: Node3D = MODEL.instantiate()
	model.name = "Model"
	# The model drives toward its +Z; Godot's forward is -Z.
	model.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	model.scale = Vector3.ONE * MODEL_SCALE
	model.position = Vector3(0.0, MODEL_LIFT, 0.0)
	return model


## Where the rear wheels sit on the model, as (half track, distance behind the middle). The tire
## marks are laid here rather than at a fraction of the kart's length that was nearly right: the
## marks were coming down a quarter of a meter behind the wheels meant to be making them. The
## rear wheels do not steer, so one measurement stands for the whole match.
##
## Measured from the middle of the tire itself rather than from the point the model hangs it
## from. On this model the wheel's own origin sits at its inner face, a tire's width inboard of
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
	# Thin rings and small trinkets are cut coarse, GAME.md 10.7: a torus comes with four
	# thousand triangles and a ring the width of a finger shows none of them.
	torus.rings = 32
	torus.ring_segments = 6
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
	bubble.radial_segments = 16
	bubble.rings = 8
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
	# Placed every drawn frame from the drawn kart, like the aim guide: see [AimGuide].
	aim_arrow.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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


## A shape of its own over the driver for each player color, GAME.md 4.4, so a color is not the
## only way to tell karts apart: as many shapes as colors, eight, for a room of eight.
static func roof_marker(color_index: int) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	marker.name = "RoofMarker"
	marker.mesh = marker_shape(color_index)
	var material := StandardMaterial3D.new()
	material.albedo_color = Palette.player_color(color_index)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = material
	marker.position = Vector3(0.0, MARKER_HEIGHT, 0.0)
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return marker


## The roof marker's shape for the player color [param color_index]: a ball, a box, a wedge, a
## ring, a drum, a pill, a cone and a diamond, in the order of the colors.
static func marker_shape(color_index: int) -> Mesh:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	# Four sides and a point at each end: a diamond, where a dozen made the ball.
	var diamond := SphereMesh.new()
	diamond.radial_segments = 4
	diamond.rings = 1
	var shapes: Array[Mesh] = [
		SphereMesh.new(),
		BoxMesh.new(),
		PrismMesh.new(),
		TorusMesh.new(),
		CylinderMesh.new(),
		CapsuleMesh.new(),
		cone,
		diamond,
	]
	var mesh: Mesh = shapes[posmod(color_index, shapes.size())]
	# Each a hand's width across, seen from the far end of the room: a dozen segments round.
	if mesh == cone:
		cone.bottom_radius = 0.17
		cone.height = 0.32
		cone.radial_segments = 16
		cone.rings = 1
	elif mesh == diamond:
		diamond.radius = 0.17
		diamond.height = 0.4
	elif mesh is SphereMesh:
		(mesh as SphereMesh).radius = 0.16
		(mesh as SphereMesh).height = 0.32
		(mesh as SphereMesh).radial_segments = 12
		(mesh as SphereMesh).rings = 6
	elif mesh is BoxMesh:
		(mesh as BoxMesh).size = Vector3.ONE * 0.28
	elif mesh is PrismMesh:
		(mesh as PrismMesh).size = Vector3(0.32, 0.3, 0.32)
	elif mesh is TorusMesh:
		(mesh as TorusMesh).inner_radius = 0.08
		(mesh as TorusMesh).outer_radius = 0.18
		(mesh as TorusMesh).rings = 16
		(mesh as TorusMesh).ring_segments = 8
	elif mesh is CylinderMesh:
		(mesh as CylinderMesh).top_radius = 0.14
		(mesh as CylinderMesh).bottom_radius = 0.14
		(mesh as CylinderMesh).height = 0.26
		(mesh as CylinderMesh).radial_segments = 16
		(mesh as CylinderMesh).rings = 1
	elif mesh is CapsuleMesh:
		(mesh as CapsuleMesh).radius = 0.11
		(mesh as CapsuleMesh).height = 0.36
		(mesh as CapsuleMesh).radial_segments = 8
		(mesh as CapsuleMesh).rings = 4
	return mesh


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
	torus.rings = 16
	torus.ring_segments = 6
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
		cone.radial_segments = 6
		cone.rings = 1
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
