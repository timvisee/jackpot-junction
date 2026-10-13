class_name KartAim
extends RefCounted
## Where a kart's shot goes, GAME.md 5.1 and 7.3. Kept apart from the kart itself so that file
## stays about what a kart is and does, the same way [KartCollisions] keeps contact response out
## of it and [KartVisuals] keeps the geometry out.
##
## Two separate questions: where the player is pointing, which is the nose unless the cannon
## allows free aim and the stick or the mouse says otherwise, and where the shot actually leaves,
## which is that answer bent toward an enemy when the Aimbot joker is held.


## The arrow over a freely aiming kart and the guide ahead of a local player's cannon, placed
## for this drawn frame, and the guide returned, made the first time it is wanted. Both follow
## the kart as it is drawn, between physics ticks, rather than where the last tick left it, see
## [AimGuide].
##
## The aim guide shows for local players when the setting is on. A puppet counts: online the
## kart a player drives is moved by the host, and it is still the one they are steering and the
## only one on their screen whose aim is theirs to see. Holding a [PlayerInput] is what says so,
## since nothing else on either machine is given one.
static func draw(kart: Kart, arrow: MeshInstance3D, guide: AimGuide) -> AimGuide:
	var shown := kart.get_global_transform_interpolated()
	if arrow.visible and kart.alive:
		var toward := shown_direction(kart, shown)
		arrow.global_position = shown.origin + Vector3(0.0, 0.9, 0.0) + toward * 0.9
		arrow.look_at(arrow.global_position + toward, Vector3.UP)
	var wanted := kart.alive and kart.input is PlayerInput and Game.settings.aim_guide
	if wanted and guide == null:
		guide = AimGuide.attach(kart, Palette.player_color(kart.color_index))
	if guide == null:
		return null
	guide.visible = wanted
	if wanted:
		var toward := shown_direction(kart, shown)
		guide.update_line(shown.origin + toward * kart.cannon_stats.muzzle_offset, toward)
	return guide


## Where the aim points with the kart drawn at [param shown]: aimed down the nose, it turns with
## the drawn kart rather than jumping with the physics tick; aimed by a stick or the mouse, it is
## a direction in the room, and the kart's turning has nothing to do with it.
static func shown_direction(kart: Kart, shown: Transform3D) -> Vector3:
	var aim := direction(kart)
	if _free_aim(kart):
		return aim
	return (shown.basis.orthonormalized() * kart.global_basis.orthonormalized().inverse()) * aim


## Where this kart is pointing its cannon, after any joker has had its say about it.
static func direction(kart: Kart) -> Vector3:
	var aim := _pointed(kart)
	for joker: Joker in kart.jokers.jokers:
		aim = joker.modify_aim(kart, aim)
	return aim


## Where the kart itself is pointing: the nose, unless the cannon allows free aim and the stick,
## the mouse or a finger says otherwise. Only a player's own: a bot's swivel is nobody's pointer's.
static func _pointed(kart: Kart) -> Vector3:
	var forward := -kart.global_basis.z
	if not _free_aim(kart):
		return forward
	if kart.input.aim.length() > 0.3:
		return Vector3(kart.input.aim.x, 0.0, kart.input.aim.y).normalized()
	if not kart.input is PlayerInput:
		return forward
	# On a touch screen the mouse is wherever the last finger was, buttons and all, so it is the
	# spot on the floor a finger last pointed at instead, see [TouchControls].
	var on := TouchInput.aim_point
	if not TouchInput.enabled:
		on = floor_point(kart.get_viewport(), kart.get_viewport().get_mouse_position())
	var toward := _toward(kart, on)
	return toward if toward != Vector3.ZERO else forward


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
## Whether [param kart]'s cannon is aimed freely right now, by the right stick or the mouse, which
## is then not free for anything else to use, such as the emotes of GAME.md 3.8.
static func free_aim(kart: Kart) -> bool:
	return _free_aim(kart)


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
		deg_to_rad(90.0),
		kart.get_world_3d().direct_space_state,
		kart.team
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


## How much of the aim assist a shot leaving now gets, after [param still_for] seconds parked,
## GAME.md 5.2. The assist is for a shot taken on the move; a kart sat still with its nose down
## a corridor is not taking a hard shot, and the help there turns it into a turret. It fades
## rather than cutting out, and moving again hands it straight back.
static func assist_share(stats: CannonStats, still_for: float) -> float:
	if stats == null:
		return 1.0
	var over := (still_for - stats.assist_still_grace) / maxf(stats.assist_still_fade, 0.001)
	return lerpf(1.0, clampf(stats.assist_still_floor, 0.0, 1.0), clampf(over, 0.0, 1.0))


## Where [param at], a point of the screen, is on the floor at the height bullets fly, or not
## finite when there is no camera to ask or the point is somewhere the floor is not.
static func floor_point(viewport: Viewport, at: Vector2) -> Vector3:
	var camera := viewport.get_camera_3d()
	if camera == null:
		return Vector3.INF
	var from := camera.project_ray_origin(at)
	var normal := camera.project_ray_normal(at)
	if absf(normal.y) < 0.0001:
		return Vector3.INF
	var t := (Bullet.HEIGHT - from.y) / normal.y
	if t < 0.0:
		return Vector3.INF
	return from + normal * t


## The way from [param kart] to [param point] on the floor, or zero when there is none to go or
## the point is too close to say.
static func _toward(kart: Kart, point: Vector3) -> Vector3:
	if not point.is_finite():
		return Vector3.ZERO
	var direction := Vector3(
		point.x - kart.global_position.x, 0.0, point.z - kart.global_position.z
	)
	return direction.normalized() if direction.length() > 0.2 else Vector3.ZERO
