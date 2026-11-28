class_name Bomb
extends StaticBody3D
## A dropped bomb, GAME.md 7.1. It arms shortly after being dropped, then blows up when a kart
## drives over it, when a bullet hits it or when its fuse runs out. The blast kills karts, breaks
## crates and turrets and sets off other bombs within its radius. Kills credit the owner, who is
## not spared. Bullets see it on the bomb layer; karts drive over it without bumping into it. A
## magnet that is on drags it along the floor as it pulls a kart, see [method drag], stopped by
## anything solid in its way; over a hole, dropped there or taken there, it goes down it without
## going off, see [method fall]. A turbo pad launches it rolling down its arrow, see
## [method launch], and a pop bumper it moves into kicks it back, see [method _off_bumpers].

signal exploded(bomb: Bomb)

const ARM_TIME := 0.6
const RADIUS := 2.6
const BODY_RADIUS := 0.38
## How quickly a puppet glides to where the host last said it is, as a share of the way each second
## gone, see [method glide_to]; and how far off it is put there at once instead, set down anew.
const GLIDE := 18.0
const GLIDE_JUMP := 2.0
## How long it takes to drop out of sight down a hole, and how fast it sinks, as a pickup does.
const FALL_TIME := Pickup.FALL_TIME
const FALL_SPEED := Pickup.FALL_SPEED
## How fast a turbo pad launches it rolling, in meters a second, and how quickly its roll dies away,
## in meters a second each second: some eleven meters down a lane at the most, see [method launch].
const LAUNCH_SPEED := 9.0
const ROLL_DRAG := 3.6
## How near a pop bumper's side it is kicked, in meters, how fast, and how long before a bumper
## kicks it again, see [method _off_bumpers].
const KICK_REACH := 0.1
const KICK_SPEED := 7.0
const KICK_AGAIN := 0.25

var owner_slot := -1
## Its owner's team, GAME.md 3.14: with friendly fire off a teammate neither sets it off nor is
## hurt by it.
var team := -1
var fuse := 30.0
var color := Color.WHITE
var alive := true
var puppet := false
var armed := false
## Whether it is on its way down a hole, see [method fall].
var falling := false
## How fast it is rolling along the floor, flat, launched by a turbo pad, see [method launch].
var rolling := Vector3.ZERO

var _age := 0.0
var _trigger: Area3D
var _fuse_light: MeshInstance3D
## Where a puppet glides to, see [method glide_to], and whether it has been told one.
var _glide := Vector3.ZERO
var _gliding := false
var _fallen := 0.0
var _kick_left := 0.0


func _ready() -> void:
	collision_layer = Layers.BOMB
	collision_mask = 0
	add_to_group(&"bombs")
	# Worth bending a shot toward, GAME.md 5.1: setting one off from across the room is a shot
	# that did far more than a bullet normally does.
	add_to_group(Bullet.TARGET_GROUP)
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
	if falling:
		_sink(delta)
	elif puppet:
		_glide_on(delta)
	else:
		_run(delta)


## A client's copy for [param delta] seconds: on toward where the host last said it is, see
## [method glide_to].
func _glide_on(delta: float) -> void:
	if _gliding:
		var off := _glide - global_position
		var share := 1.0 if off.length() > GLIDE_JUMP else 1.0 - exp(-GLIDE * delta)
		global_position += off * share


## The host's bomb for [param delta] seconds: armed after a moment, gone off at the end of its
## fuse, dragged, down a hole it is over, and set off by a kart it is armed for.
func _run(delta: float) -> void:
	armed = _age >= ARM_TIME
	if _age >= fuse:
		explode()
		return
	drag(delta)
	if LooseThings.over_pit(self, global_position):
		fall()
		return
	if not armed:
		return
	for body: Node3D in _trigger.get_overlapping_bodies():
		var kart := body as Kart
		if kart != null and kart.is_targetable() and not Teams.spares(owner_slot, team, kart):
			explode()
			return


## Dragged along the floor for [param delta] seconds by whatever drags loose things, a magnet that
## is on or a belt, see [LooseThings], the way it pulls a kart, and rolled on by a launch, slowing;
## stopped short of anything solid in the way, a wall, a crate or the magnet itself, as a kart
## sliding is, which ends its roll.
func drag(delta: float) -> void:
	_kick_left = maxf(_kick_left - delta, 0.0)
	var pull := LooseThings.pull_at(self)
	if pull.length_squared() < 0.0001 and rolling == Vector3.ZERO:
		return
	_off_bumpers(pull + rolling)
	var motion := (pull + rolling) * delta
	var to := LooseThings.slid(self, BODY_RADIUS, motion)
	if rolling != Vector3.ZERO and to.distance_to(global_position) < motion.length() * 0.5:
		rolling = Vector3.ZERO
	global_position = to
	rolling = rolling.move_toward(Vector3.ZERO, ROLL_DRAG * delta)


## Kicked back off a pop bumper it is moving into at [param moving], GAME.md 6.2: straight away from
## the bumper's middle at [constant KICK_SPEED], as a pinball is, the bumper lit and heard on every
## machine, see [method Bumper.fire]; one lying still against a bumper is left be.
func _off_bumpers(moving: Vector3) -> void:
	if _kick_left > 0.0 or moving.length_squared() < 0.0001:
		return
	var mine := _match()
	for node: Node in FrameGroups.of(get_tree(), &"bumpers"):
		var bumper := node as Bumper if is_instance_valid(node) else null
		if bumper == null or (mine != null and not mine.is_ancestor_of(bumper)):
			continue
		var away := global_position - bumper.global_position
		away.y = 0.0
		var reach := Bumper.RADIUS + BODY_RADIUS + KICK_REACH
		if away.length() > reach or away.length() < 0.01 or moving.dot(away) >= 0.0:
			continue
		rolling = away.normalized() * KICK_SPEED
		_kick_left = KICK_AGAIN
		bumper.fire(-1)
		return


## Launched rolling the way [param way] points, flat, by a turbo pad it lies on, see [TurboPad]:
## off down the lane at [constant LAUNCH_SPEED], slowing, as a pinball is fired, and going off
## against the first kart it is armed for. The host's; a client's copy glides after it.
func launch(way: Vector3) -> void:
	var flat := Vector3(way.x, 0.0, way.z)
	if flat.length_squared() > 0.0001:
		rolling = flat.normalized() * LAUNCH_SPEED


## Down a hole, GAME.md 3.6: it drops out of sight, shrinking, and is gone without going off, and
## nothing sets it off on the way. A client's copy is told so, see [MatchSnapshot], and goes down
## with it.
func fall() -> void:
	if falling or not alive:
		return
	falling = true
	collision_layer = 0
	remove_from_group(Bullet.TARGET_GROUP)
	_trigger.set_deferred(&"monitoring", false)


## Sinking down its hole, smaller the further it goes; gone once out of sight. A client's copy is
## only put out of sight, for the host's word that it is gone to take away.
func _sink(delta: float) -> void:
	_fallen += delta
	global_position.y -= FALL_SPEED * delta
	var left := maxf(1.0 - _fallen / FALL_TIME, 0.05)
	for child: Node in get_children():
		var look := child as MeshInstance3D
		if look != null:
			look.scale = Vector3.ONE * left
	if _fallen < FALL_TIME:
		return
	if puppet:
		visible = false
	else:
		alive = false
		queue_free()


## A puppet glides to [param at], where the host says it is: put there at once the first time and
## when it is far off, see [constant GLIDE_JUMP], and slid the rest, so one a magnet drags moves
## smoothly between the host's words.
func glide_to(at: Vector3) -> void:
	if not _gliding:
		global_position = at
	_glide = at
	_gliding = true


## A bullet sets the bomb off, armed or not.
## Whether a shot may be aimed at this bomb, GAME.md 5.1.
func is_targetable() -> bool:
	return alive and not falling


func take_hit(_bullet: Bullet) -> bool:
	if not alive:
		return false
	explode()
	return true


func explode() -> void:
	if not alive or falling:
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
			if not Teams.spares(owner_slot, team, kart):
				kart.take_blast(owner_slot)
	for node: Node in MatchSnapshot.own_nodes(match_node, &"crates"):
		var crate := node as Crate
		if crate != null and crate.alive and _within(crate.global_position, 0.5):
			crate.hit(owner_slot)
	for node: Node in MatchSnapshot.own_nodes(match_node, &"turrets"):
		var turret := node as Turret
		if turret != null and turret.alive and _within(turret.global_position, 0.4):
			var friendly := turret.spares_team and turret.owner_slot != owner_slot
			if not (friendly and Teams.same(team, turret.team)):
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
	# A ball the size of a hand, cut at sixteen segments rather than sixty-four, GAME.md 10.7.
	sphere.radial_segments = 16
	sphere.rings = 8
	body.mesh = sphere
	body.material_override = dark
	body.position = Vector3(0.0, BODY_RADIUS, 0.0)
	add_child(body)
	var band := MeshInstance3D.new()
	var band_mesh := TorusMesh.new()
	band_mesh.inner_radius = BODY_RADIUS - 0.02
	band_mesh.outer_radius = BODY_RADIUS + 0.03
	band_mesh.rings = 24
	band_mesh.ring_segments = 6
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
	cap_mesh.radial_segments = 12
	cap_mesh.rings = 1
	cap.mesh = cap_mesh
	cap.material_override = dark
	cap.position = Vector3(0.0, BODY_RADIUS * 2.0, 0.0)
	add_child(cap)
	_fuse_light = MeshInstance3D.new()
	var light_mesh := SphereMesh.new()
	light_mesh.radius = 0.07
	light_mesh.height = 0.14
	light_mesh.radial_segments = 8
	light_mesh.rings = 4
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
