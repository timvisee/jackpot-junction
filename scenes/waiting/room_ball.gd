class_name RoomBall
extends RigidBody3D
## A football in the waiting room, GAME.md 9.6: something to knock about while the last player
## finds their seat.
##
## It rolls on the floor and nowhere else. It cannot go up: its height is locked, so no kick lifts
## it over a wall and the only way out of the room is through a wall, which it bounces off like
## the drum and the wheels do. It is not solid to karts. A kart that meets it is not stopped by it
## the way a wall would stop it; the ball is kicked out of the kart's way instead, off the side of
## the kart it met, with however fast that side was coming at it. That is a football: the kart is
## the heavy thing.
##
## A shot kicks it too, the way the shot was going, and is spent on it: something to aim at in a
## room where there is nobody to shoot.
##
## Online the host kicks it and says where it is; a client draws it where it was told, running on
## at the speed it was told between one telling and the next.

## The ball sends where it is, and how fast it is going, for the host to pass on.
signal moved(state: Array)

const RADIUS := 0.5
## The kart as the ball meets it: a box, half as wide and half as long as the kart's own.
const KART_HALF := Vector2(0.5, 0.8)
## How much of a kart's run at it the ball bounces off with, and the most it ever goes.
const RESTITUTION := 0.55
const MAX_SPEED := 16.0
## A kart on nitro kicks twice as hard, and the ball may go twice as fast for it.
const NITRO_KICK := 2.0
## How much speed a shot puts on it, the way the shot was going.
const SHOT_KICK := 9.0
## How fast it rolls to a stop on the concrete, and how hard walls and props throw it back.
const ROLLING_DAMP := 0.6
const BOUNCE := 0.7
## Physics ticks between tellings of where it is, a third of the snapshot rate's worth of words.
const SHARE_EVERY := 3
## How far a client closes on where it was told each tick: most of the way, not all, so a telling
## that arrives late is walked to rather than jumped to.
const FOLLOW := 0.35
## The black patches of a football, one at every corner of an icosahedron.
const PATCH := 0.34
const WHITE := Color(0.94, 0.94, 0.92)
const BLACK := Color(0.08, 0.08, 0.09)

var match_node: Match
## Whether this machine kicks it. The host and a game on one machine do; a client is told.
var simulating := true
## Where it starts, and where it goes back to if it is ever found outside the room.
var home := Vector3.ZERO

var _tick := 0
## The fastest the ball may go just now: [constant MAX_SPEED], or more straight after a kick on
## nitro, coming back down as it slows.
var _cap := MAX_SPEED
## On a client: where it was last told the ball is, and how fast it was going then.
var _told := Vector3.ZERO
var _told_velocity := Vector3.ZERO
## The part that turns as it rolls. The body itself never turns: its rotation is locked with its
## height, and the roll is drawn.
var _look: Node3D
## Speed from shots that landed since the last physics step, put on in the next one.
var _shot := Vector3.ZERO


## Puts a ball on [param in_match]'s floor at [param at], kicked here when [param kicked_here]
## and told about otherwise.
static func add_to(in_match: Match, at: Vector3, kicked_here := true) -> RoomBall:
	var ball := RoomBall.new()
	ball.name = "Ball"
	ball.match_node = in_match
	ball.simulating = kicked_here
	ball.home = Vector3(at.x, RADIUS, at.z)
	ball._told = ball.home
	# Where it is before it is in the tree: its height is locked where it enters, and a ball that
	# entered on the floor and was lifted after would be held half sunk into it.
	ball.position = ball.home
	in_match.arena.add_child(ball)
	return ball


func _ready() -> void:
	gravity_scale = 0.0
	axis_lock_linear_y = true
	lock_rotation = true
	continuous_cd = true
	mass = 0.45
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = ROLLING_DAMP
	# Walls and props, and nothing else: not a kart, not a trigger, so it never stands anybody on
	# the pad and never gets in a kart's way. Bullets see it on a layer of its own.
	collision_layer = Layers.BALL
	collision_mask = Layers.WORLD
	var surface := PhysicsMaterial.new()
	surface.bounce = BOUNCE
	surface.friction = 0.0
	physics_material_override = surface
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	shape.shape = sphere
	add_child(shape)
	_build_look()
	if not simulating:
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		freeze = true


## A shot has landed on it: kicked on the way the shot was going, and the shot is spent. A client
## runs no bullets of its own, and its ball goes where the host says.
func take_hit(bullet: Bullet) -> bool:
	if not simulating:
		return false
	var going := Vector3(bullet.velocity.x, 0.0, bullet.velocity.z)
	if going.is_zero_approx():
		return true
	_shot += going.normalized() * SHOT_KICK
	sleeping = false
	return true


## Where the host last said it is: [x, z, velocity x, velocity z].
func follow(state: Array) -> void:
	if state.size() < 4:
		return
	_told = Vector3(state[0], RADIUS, state[1])
	_told_velocity = Vector3(state[2], 0.0, state[3])


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not simulating or match_node == null:
		return
	var at := state.transform.origin
	var velocity := state.linear_velocity + _shot
	_shot = Vector3.ZERO
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or not kart.alive or kart.falling or not kart.is_inside_tree():
			continue
		var kicked := _kick(at, velocity, kart)
		at = kicked[0]
		velocity = kicked[1]
		if kicked[2]:
			_cap = MAX_SPEED * NITRO_KICK
	velocity.y = 0.0
	if velocity.length() > _cap:
		velocity = velocity.normalized() * _cap
	_cap = maxf(MAX_SPEED, minf(_cap, velocity.length()))
	# A ball found outside the room -- through a gap, or pushed through a wall by a kart pinning it
	# there -- goes back to where it started rather than rolling on under the crowd.
	var half := match_node.arena.world_size() * 0.5
	if absf(at.x) > half.x or absf(at.z) > half.y:
		at = home
		velocity = Vector3.ZERO
	at.y = RADIUS
	state.transform.origin = at
	state.linear_velocity = velocity


## The ball off one kart: if it is inside the kart's box, out to its edge and away, bouncing off
## the side it met with the speed that side was coming at it, twice as hard off a kart on nitro.
## Returns [where, how fast, whether it was a kick on nitro].
func _kick(at: Vector3, velocity: Vector3, kart: Kart) -> Array:
	var center := Vector3(kart.global_position.x, 0.0, kart.global_position.z)
	var flat := Vector3(at.x, 0.0, at.z)
	var basis := kart.global_basis.orthonormalized()
	var local := basis.inverse() * (flat - center)
	var edge := Vector3(
		clampf(local.x, -KART_HALF.x, KART_HALF.x), 0.0, clampf(local.z, -KART_HALF.y, KART_HALF.y)
	)
	var touch := center + basis * edge
	touch.y = 0.0
	var away := flat - touch
	var gap := away.length()
	if gap >= RADIUS:
		return [at, velocity, false]
	# Its middle inside the kart: straight out from the kart's own middle.
	var normal := away / gap if gap > 0.001 else (flat - center).normalized()
	if normal.is_zero_approx():
		normal = Vector3.RIGHT
	var out := touch + normal * RADIUS
	var coming := velocity - Vector3(kart.velocity.x, 0.0, kart.velocity.z)
	var into := coming.dot(normal)
	var hard := kart.nitro_active and into < 0.0
	if into < 0.0:
		velocity -= (1.0 + RESTITUTION) * into * normal * (NITRO_KICK if hard else 1.0)
	return [Vector3(out.x, at.y, out.z), velocity, hard]


func _physics_process(delta: float) -> void:
	if simulating:
		_tick += 1
		if _tick % SHARE_EVERY == 0:
			var at := global_position
			moved.emit([at.x, at.z, linear_velocity.x, linear_velocity.z])
		return
	# Run on at the speed it was told between tellings, and close on it.
	_told += _told_velocity * delta
	_told_velocity *= maxf(1.0 - ROLLING_DAMP * delta, 0.0)
	global_position = global_position.lerp(_told, FOLLOW)


## The roll, drawn: the look turns about the line across its way of travel, as far as it rolled.
func _process(delta: float) -> void:
	var going := linear_velocity if simulating else _told_velocity
	going.y = 0.0
	var speed := going.length()
	if speed < 0.01 or _look == null:
		return
	var axis := Vector3.UP.cross(going / speed)
	_look.global_rotate(axis, speed * delta / RADIUS)


## A white ball with black patches, the patches being what shows it rolling.
func _build_look() -> void:
	_look = Node3D.new()
	_look.name = "Look"
	add_child(_look)
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = RADIUS * 2.0
	sphere.radial_segments = 20
	sphere.rings = 10
	ball.mesh = sphere
	ball.material_override = _paint(WHITE)
	_look.add_child(ball)
	var patch := CylinderMesh.new()
	patch.top_radius = RADIUS * PATCH
	patch.bottom_radius = RADIUS * PATCH
	patch.height = 0.02
	patch.radial_segments = 5
	var ink := _paint(BLACK)
	var phi := (1.0 + sqrt(5.0)) * 0.5
	for corner: Vector3 in [
		Vector3(0, 1, phi),
		Vector3(0, -1, phi),
		Vector3(0, 1, -phi),
		Vector3(0, -1, -phi),
		Vector3(1, phi, 0),
		Vector3(-1, phi, 0),
		Vector3(1, -phi, 0),
		Vector3(-1, -phi, 0),
		Vector3(phi, 0, 1),
		Vector3(-phi, 0, 1),
		Vector3(phi, 0, -1),
		Vector3(-phi, 0, -1),
	]:
		var up := corner.normalized()
		var spot := MeshInstance3D.new()
		spot.mesh = patch
		spot.material_override = ink
		var side := Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD
		var across := up.cross(side).normalized()
		spot.basis = Basis(across, up, across.cross(up))
		spot.position = up * (RADIUS * 0.985)
		_look.add_child(spot)


func _paint(color: Color) -> Material:
	if match_node != null and match_node.arena != null and match_node.arena.surfaces != null:
		return match_node.arena.surfaces.painted(color)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	return paint
