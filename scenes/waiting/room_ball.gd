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
## room where there is nobody to shoot. Aim assist leans a shot onto it the way it does onto a kart,
## GAME.md 5.2, so a shot at the ball goes where it was meant to.
##
## Online the host kicks it and says where it is, and a client draws it where it was told, running
## on at the speed it was told between one telling and the next, until its own kart meets it. Then
## it is kicked there and then, on that machine, which runs it from there on and tells the host
## where it is; the host goes by that client's word and passes it on, for as long as the client
## has it: [constant OWN_TIME] after its kart last touched it, or until somebody else kicks it.
## Waiting a round trip for the host to kick it was a kart driving into a ball that stood there and
## then shot off from under it, GAME.md 9.6. A shot is still the host's to land, as every bullet is.

## The ball sends where it is, and how fast it is going, for the host to pass on.
signal moved(state: Array)
## At a client that has the ball: where it is, and which of its kicks it runs on, for the host.
signal claimed(state: Array)
## Something has hit the ball hard enough to hear: a kart, [code]&"kick"[/code], or anything else,
## a wall, a prop or a shot, [code]&"knock"[/code]. [param strength] is how much it changed the
## ball's speed, in m/s. See [method _listen].
signal struck(kind: StringName, strength: float)

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
## A change of speed from one tick to the next of more than this is something hitting the ball,
## and is heard; rolling to a stop on the concrete takes off far less than that a tick. At
## [constant LOUD_JOLT] it is heard at [constant LOUD_DB], and quieter below that.
const HEARD_JOLT := 1.5
const LOUD_JOLT := 14.0
const LOUD_DB := -8.0
const QUIET_DB := -24.0
## Seconds a client runs the ball on its own word after its kart last touched it, and how long
## the host goes without word from the client that has it before taking it back.
const OWN_TIME := 2.0
const OWNER_QUIET := 0.3
## How close a kart has to be for a hit to be a kick rather than a knock off something else.
const KICK_REACH := 1.6
## Seconds after a sound in which the ball makes no other, so a ball a kart has pinned to a wall is
## a knock and not a buzz.
const SOUND_GAP := 0.08
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
## Online: this machine's peer, 1 at the host and on a game on one machine; whose word the ball is
## on, by peer; and which of that client's kicks it is, see [method adopt].
var here := 1
var owner_peer := 1
var owner_kick := 0
## At a client that has the ball: whether the host has said it goes by this machine's word for the
## latest kick, after which word of anybody else's is somebody having kicked it since.
var agreed := false

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
## What the ball was doing last tick, as this machine sees it, to hear it being hit; unset until the
## first look, so a ball already rolling when a client arrives is not heard being hit.
var _was := Vector3.ZERO
var _looked := false
var _quiet_left := 0.0
## At a client: how many times its karts have taken the ball and how long it still has it.
var _kicks := 0
var _own_left := 0.0
## At the host: the last kick it went by from each client, how long since it heard from the one
## that has the ball, and that client's latest word, for the next physics step to put the ball at.
var _kick_of: Dictionary[int, int] = {}
var _owner_quiet := 0.0
var _adopted: Array = []


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
	# A target, the way a box or a kart is, for aim assist to find.
	add_to_group(Bullet.TARGET_GROUP)
	if not simulating:
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		freeze = true


## Always there to aim at: nothing takes the ball off the floor.
func is_targetable() -> bool:
	return true


## A shot has landed on it: kicked on the way the shot was going, and the shot is spent. Only ever
## at the host: a client runs no bullets of its own, even while it has the ball.
func take_hit(bullet: Bullet) -> bool:
	if not simulating or here != 1:
		return false
	var going := Vector3(bullet.velocity.x, 0.0, bullet.velocity.z)
	if going.is_zero_approx():
		return true
	_shot += going.normalized() * SHOT_KICK
	sleeping = false
	return true


## Where the host last said it is: [x, z, velocity x, velocity z], and whose word that is, with
## which of their kicks. While this machine has the ball, what the host says is what it had before
## this machine's word reached it, and is let be; once the host has gone by this machine's latest
## kick, word of anybody else's is somebody having kicked it since, and this machine lets go.
func follow(state: Array) -> void:
	if state.size() < 4:
		return
	if state.size() >= 6:
		var said_owner := int(state[4])
		var said_kick := int(state[5])
		if simulating and here != 1:
			if said_owner == here and said_kick == _kicks:
				agreed = true
			if said_owner == here or not agreed:
				return
			_let_go()
		owner_peer = said_owner
		owner_kick = said_kick
	_told = Vector3(state[0], RADIUS, state[1])
	_told_velocity = Vector3(state[2], 0.0, state[3])


## At the host: [param peer]'s word for the ball its kart kicked, [x, z, velocity x, velocity z,
## kick]. A kick newer than the last one heard from it gives it the ball, and word of the kick the
## ball is already on moves it on; anything else is from before somebody else kicked it since.
func adopt(peer: int, state: Array) -> void:
	if state.size() < 5 or not simulating or here != 1:
		return
	var kick := int(state[4])
	var last: int = _kick_of.get(peer, 0)
	if kick > last:
		_kick_of[peer] = kick
		owner_peer = peer
		owner_kick = kick
	elif kick < last or owner_peer != peer:
		return
	_owner_quiet = 0.0
	_adopted = [state[0], state[1], state[2], state[3]]
	sleeping = false


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not simulating or match_node == null:
		return
	var at := state.transform.origin
	var velocity := state.linear_velocity
	if not _adopted.is_empty():
		at = Vector3(_adopted[0], RADIUS, _adopted[1])
		velocity = Vector3(_adopted[2], 0.0, _adopted[3])
		_adopted = []
	var kicked_here := not _shot.is_zero_approx()
	velocity += _shot
	_shot = Vector3.ZERO
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or not kart.alive or kart.falling or not kart.is_inside_tree():
			continue
		# A kart played at a client is kicked with there, and the host told.
		if here == 1 and kart.input is NetInput:
			continue
		var kicked := _kick(at, velocity, kart)
		at = kicked[0]
		velocity = kicked[1]
		if kicked[2]:
			_cap = MAX_SPEED * NITRO_KICK
		kicked_here = kicked_here or (kicked[3] and (here == 1 or kart.predicted))
	if kicked_here:
		_kicked_here()
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
## Returns [where, how fast, whether it was a kick on nitro, whether it touched the kart at all].
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
		return [at, velocity, false, false]
	# Its middle inside the kart: straight out from the kart's own middle.
	var normal := away / gap if gap > 0.001 else (flat - center).normalized()
	if normal.is_zero_approx():
		normal = Vector3.RIGHT
	var out := touch + normal * RADIUS
	# The motor's, which is the kart's own driving and, for somebody else's on a client, the glide
	# toward where the host last put it: a puppet is moved rather than driven.
	var coming := velocity - Vector3(kart.motor.velocity.x, 0.0, kart.motor.velocity.z)
	var into := coming.dot(normal)
	var hard := kart.nitro_active and into < 0.0
	if into < 0.0:
		velocity -= (1.0 + RESTITUTION) * into * normal * (NITRO_KICK if hard else 1.0)
	return [Vector3(out.x, at.y, out.z), velocity, hard, true]


## A kart of this machine's own kicked it, or a shot did at the host: at a client the ball is its
## own for [constant OWN_TIME] more, and at the host it is back on the host's word.
func _kicked_here() -> void:
	if here != 1:
		_own_left = OWN_TIME
	elif owner_peer != 1:
		owner_peer = 1
		owner_kick = 0


func _physics_process(delta: float) -> void:
	if not simulating:
		_follow_on(delta)
		return
	_listen(linear_velocity, delta)
	_tick += 1
	if here != 1:
		_own_left -= delta
		if _own_left <= 0.0:
			_let_go()
		elif _tick % SHARE_EVERY == 0:
			claimed.emit(_state() + [_kicks])
		return
	if owner_peer != 1:
		_owner_quiet += delta
		if _owner_quiet > OWNER_QUIET:
			# Its client has let go of it, or gone.
			owner_peer = 1
			owner_kick = 0
	if _tick % SHARE_EVERY == 0:
		moved.emit(_state() + [owner_peer, owner_kick])


func _state() -> Array:
	var at := global_position
	return [at.x, at.z, linear_velocity.x, linear_velocity.z]


## At a client without the ball: a kart of its own that meets it kicks it, and gives it the ball.
## Otherwise it runs on at the speed it was told between tellings, and closes on it.
func _follow_on(delta: float) -> void:
	if match_node != null:
		for slot: PlayerSlot in match_node.slots:
			var kart := slot.kart
			if kart == null or not kart.predicted or not kart.alive or kart.falling:
				continue
			var kicked := _kick(global_position, _told_velocity, kart)
			if kicked[3]:
				_take(kicked)
				return
	_listen(_told_velocity, delta)
	_told += _told_velocity * delta
	_told_velocity *= maxf(1.0 - ROLLING_DAMP * delta, 0.0)
	global_position = global_position.lerp(_told, FOLLOW)


## This machine's kart has met the ball: kicked here and now, and run here from now on.
func _take(kicked: Array) -> void:
	_kicks += 1
	_own_left = OWN_TIME
	agreed = false
	simulating = true
	freeze = false
	if kicked[2]:
		_cap = MAX_SPEED * NITRO_KICK
	var at: Vector3 = kicked[0]
	global_position = Vector3(at.x, RADIUS, at.z)
	linear_velocity = (kicked[1] as Vector3).limit_length(_cap)
	sleeping = false


## Long enough since this machine's kart last touched it: back to the host's word, from where it is.
func _let_go() -> void:
	simulating = false
	_own_left = 0.0
	_told = global_position
	_told_velocity = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	freeze = true


## Hears the ball being hit, on every machine the same way: from how suddenly its speed changed. A
## client knows nothing of what hit it, only where the host says it is going, so it is that which
## is listened to. A kart close by is a kick; anything else is a knock.
func _listen(going: Vector3, delta: float) -> void:
	_quiet_left = maxf(_quiet_left - delta, 0.0)
	var jolt := (going - _was).length()
	_was = going
	if not _looked:
		_looked = true
		return
	if jolt < HEARD_JOLT or _quiet_left > 0.0:
		return
	_quiet_left = SOUND_GAP
	var kind := &"kick" if _kart_near() else &"knock"
	struck.emit(kind, jolt)
	var loud := lerpf(QUIET_DB, LOUD_DB, clampf(jolt / LOUD_JOLT, 0.0, 1.0))
	Audio.play_sfx(&"ball_kick" if kind == &"kick" else &"ball_knock", loud)


func _kart_near() -> bool:
	if match_node == null:
		return false
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if (
			kart != null
			and kart.alive
			and kart.global_position.distance_to(global_position) < KICK_REACH
		):
			return true
	return false


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
