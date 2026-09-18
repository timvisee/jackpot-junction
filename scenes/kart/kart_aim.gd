class_name KartAim
extends RefCounted
## Where a kart's shot goes, GAME.md 5.1 and 7.3. Kept apart from the kart itself so that file
## stays about what a kart is and does, the same way [KartCollisions] keeps contact response out
## of it and [KartVisuals] keeps the geometry out.
##
## Two separate questions: where the player is pointing, which is the nose unless the cannon
## allows free aim and the stick or the mouse says otherwise, and where the shot actually leaves,
## which is that answer bent toward an enemy when the Aimbot joker is held.


## Where this kart is pointing its cannon, after any joker has had its say about it.
static func direction(kart: Kart) -> Vector3:
	var aim := _pointed(kart)
	for joker: Joker in kart.jokers.jokers:
		aim = joker.modify_aim(kart, aim)
	return aim


## Where the kart itself is pointing: the nose, unless the cannon allows free aim and the stick
## or the mouse says otherwise.
static func _pointed(kart: Kart) -> Vector3:
	var forward := -kart.global_basis.z
	if not _free_aim(kart):
		return forward
	if kart.input.aim.length() > 0.3:
		return Vector3(kart.input.aim.x, 0.0, kart.input.aim.y).normalized()
	var mouse := _from_mouse(kart)
	return mouse if mouse != Vector3.ZERO else forward


## Where this kart's player is pointing, flattened for the wire, GAME.md 10.3. A client resolves
## its own aim before sending it: a stick reading means the same thing on both machines, but a
## mouse does not, and a host handed an empty aim went and asked where its own pointer was and
## fired somebody else's shot at it.
static func pointed_flat(kart: Kart) -> Vector2:
	var pointed := _pointed(kart)
	return Vector2(pointed.x, pointed.z)


## Whether this kart is aiming freely rather than down its nose. A puppet holds no cannon
## override of its own, since the host is the one shooting, but the arrow that shows for exactly
## as long as free aim lasts rides the snapshot, so on a client that is the answer.
static func _free_aim(kart: Kart) -> bool:
	if kart.puppet:
		return kart.aim_arrow_visible
	return kart.cannon.current_stats().free_aim


## Aimbot, GAME.md 7.3: turns the shot part of the way toward the nearest enemy in front, up to
## [member CannonStats.auto_aim_deg]. Without the joker that is zero and the shot goes exactly
## where the kart points.
static func steered(kart: Kart, direction_now: Vector3) -> Vector3:
	var active := kart.cannon.current_stats()
	if active.auto_aim_deg <= 0.0:
		return direction_now
	var target := Bullet.nearest_target(
		kart.get_tree(),
		kart.global_position,
		kart.slot,
		active.auto_aim_range,
		direction_now,
		deg_to_rad(90.0)
	)
	if target == null:
		return direction_now
	return (
		Bullet
		. steer_toward(
			direction_now,
			kart.global_position,
			target.global_position,
			deg_to_rad(90.0),
			active.auto_aim_range,
			deg_to_rad(active.auto_aim_deg)
		)
		. normalized()
	)


## Where the mouse is pointing on the floor, at the height bullets fly, or zero when there is no
## camera to ask or the pointer is somewhere the floor is not.
static func _from_mouse(kart: Kart) -> Vector3:
	var camera := kart.get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.ZERO
	var mouse := kart.get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var normal := camera.project_ray_normal(mouse)
	if absf(normal.y) < 0.0001:
		return Vector3.ZERO
	var t := (Bullet.HEIGHT - from.y) / normal.y
	if t < 0.0:
		return Vector3.ZERO
	var point := from + normal * t
	var direction := Vector3(
		point.x - kart.global_position.x, 0.0, point.z - kart.global_position.z
	)
	return direction.normalized() if direction.length() > 0.2 else Vector3.ZERO
