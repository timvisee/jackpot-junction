class_name Dyno
extends Node3D
## The Garage's rolling road, GAME.md 9.4: a bay against the right wall with a cradle of steel
## rollers set in its floor. A kart driven onto them nose first toward the wall is held there, its
## wheels turning the rollers rather than the kart going anywhere, and whatever speed its motor
## reaches with the throttle held, nitro and jokers and all, is the dyno's, for the test bench's
## dial to show, see [TestBench]. Backing off the rollers lets it go, and it is not taken onto them
## again until it has left the bay.
##
## The kart drives as it always does and is put back on the rollers after it has moved, each
## physics tick, so its motor keeps the speed it would have had on the open floor: the dyno reads
## that rather than working one out of its own.

## Given as a kart is taken onto the rollers, and as it is let go with the best it reached.
signal held_kart(slot: PlayerSlot)
signal let_go(slot: PlayerSlot, best: float)

## How many cells of the room the bay takes, along the wall's normal and along the wall.
const CELLS := Vector2i(3, 2)
## Which way a kart on the rollers faces: into the wall the bay is against.
const FACING := Vector3.RIGHT
## How far from the bay's open end a kart is held, in cells: over the rollers, its nose short of
## the wall.
const HOLD := 1.6
## How square to the wall a kart has to come in to be taken onto the rollers, in radians either
## way, and how fast it may be going, in meters a second: driven on, not flung on.
const SQUARE := 0.9
## Backing off at more than this, in meters a second, lets the kart go.
const BACKING := 0.3
## A kart taken onto the rollers rolls on to where it is held at the speed it came in at, at least
## [constant ROLL_ON] meters a second, braking into place at [constant BRAKE] meters a second each
## second, and squares up to the wall as it goes.
const ROLL_ON := 2.0
const BRAKE := 10.0
## The cradle: two rollers side by side under the kart's back wheels, how thick and how long, and
## how far apart; the bars on each that show it turning.
const ROLLER := 0.2
const ROLLER_LONG := 1.9
const ROLLERS_APART := 0.48
const ROLLER_BARS := 6
## How far behind the kart's middle its back wheels stand, where the cradle is.
const REAR := 0.32
const STEEL := Color(0.42, 0.44, 0.48)
const DARK_STEEL := Color(0.16, 0.17, 0.19)
const PLATE := Color(0.27, 0.28, 0.31)
const WORDS := "DYNO"
const WORDS_TALL := 0.26
const WORDS_SIZE := 96
## The fence down either side of the bay: how tall, its posts' thickness and how far apart at most,
## its rails' and how high up the posts each runs, as a share of their height, and how far outside
## the bay's lines it stands.
const FENCE_TALL := 0.7
const FENCE_POST := 0.08
const FENCE_EVERY := 1.3
const FENCE_RAIL := 0.05
const FENCE_RAILS: Array[float] = [0.45, 0.95]
const FENCE_OUT := 0.14
## The straps that hold a kart down on the rollers once it is in place: where on a kart square to
## the wall each takes hold, from its middle, along it, up and out; how far out along and in from
## the bay's side their ratchets stand on the floor; the band's width and thickness and its orange;
## the ratchets' size. How near its place a kart is taken to be in it, in meters, how long the
## straps take to be let out over it and wound back in, in seconds, and how far each lags the one
## before, as a share of the whole.
const KART_CORNER := Vector3(0.48, 0.3, 0.4)
const STRAP_OUT := Vector2(0.35, 0.18)
const STRAP_WIDE := 0.07
const STRAP_THICK := 0.012
const STRAP_INK := Color(0.96, 0.46, 0.08)
const RATCHET := Vector3(0.16, 0.08, 0.12)
const SETTLED := 0.03
const STRAP_ON := 0.45
const STRAP_OFF := 0.2
const STRAP_STAGGER := 0.15

var match_node: Match
## The bay on the floor, in world X and Z.
var area: Rect2
## The kart on the rollers, its slot, and how fast its motor is turning them, in meters a second.
var held: Kart
var held_slot: PlayerSlot
var speed := 0.0
## The best any kart reached on the rollers this visit, and whose.
var best := 0.0
var best_slot: PlayerSlot
## How far the straps are let out over the kart, 0 wound in and 1 holding it down.
var strapped := 0.0

var _hold := Vector3.ZERO
## Where the kart on the rollers is now and which way it faces, on their way to where it is held
## and square to the wall: where and how it came on, and how fast it is rolling on.
var _at := Vector3.ZERO
var _heading := 0.0
var _came_at := Vector3.ZERO
var _came_heading := 0.0
var _rolling := 0.0
## The karts let go that have not yet left the bay, by slot.
var _leaving: Dictionary[int, bool] = {}
var _rollers: Array[Node3D] = []
var _straps: Array[Node3D] = []
## How far round the rollers have turned, in radians.
var _turned := 0.0


## The rolling road in [param in_match]'s room, the bay's corner cell nearest the room's middle
## and its back [param corner].
static func add_to(in_match: Match, corner: Vector2i) -> Dyno:
	var dyno := Dyno.new()
	dyno.name = "Dyno"
	dyno.match_node = in_match
	in_match.arena.add_child(dyno)
	dyno._build(corner)
	return dyno


func _ready() -> void:
	# After the karts have moved, so a kart on the rollers is put back where it is held.
	process_physics_priority = 10


func _build(corner: Vector2i) -> void:
	var arena := match_node.arena
	var grid := arena.grid
	var cell := grid.cell_size
	var near := grid.cell_center(corner)
	var far := grid.cell_center(corner + CELLS - Vector2i.ONE)
	var middle := (near + far) * 0.5
	var long := cell * CELLS.x
	var wide := cell * CELLS.y
	area = Rect2(middle.x - long * 0.5, middle.z - wide * 0.5, long, wide)
	_hold = Vector3(area.position.x + cell * HOLD, 0.0, middle.z)
	var plate := _box(Vector3(long, 0.02, wide), arena.surfaces.marking(PLATE))
	plate.position = Vector3(middle.x, 0.006, middle.z)
	var lines := arena.surfaces.marking(KartLift.LINE_INK)
	for side: float in [-1.0, 1.0]:
		var line := _box(Vector3(long, 0.02, KartLift.LINE), lines)
		line.position = Vector3(middle.x, 0.012, middle.z + side * wide * 0.5)
		add_child(line)
	var cradle := _hold.x - REAR
	var pit := _box(Vector3(ROLLERS_APART + ROLLER * 2.6, 0.02, ROLLER_LONG + 0.1), null)
	pit.material_override = arena.surfaces.marking(DARK_STEEL)
	pit.position = Vector3(cradle, 0.014, middle.z)
	add_child(pit)
	for side: float in [-1.0, 1.0]:
		_rollers.append(_roller(Vector3(cradle + side * ROLLERS_APART * 0.5, 0.0, middle.z)))
	_words(Vector3(area.position.x + cell * 0.45, 0.03, middle.z))
	add_child(plate)
	_fence()
	_build_straps()


## A low fence down either side of the bay, from the wall to its open end, so the one way onto the
## rollers is nose first from the room: steel posts with two yellow rails between them, and a body
## a kart runs into the way it runs into a wall.
func _fence() -> void:
	var arena := match_node.arena
	var fence := Node3D.new()
	fence.name = "FenceLook"
	add_child(fence)
	var posts := arena.surfaces.metal(DARK_STEEL)
	var rails := arena.surfaces.painted(KartLift.LINE_INK)
	var body := StaticBody3D.new()
	body.name = "Fence"
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	add_child(body)
	var long := area.size.x
	var count := maxi(2, ceili(long / FENCE_EVERY) + 1)
	for side: float in [-1.0, 1.0]:
		var z := area.get_center().y + side * (area.size.y * 0.5 + FENCE_OUT)
		for i: int in count:
			var x := area.position.x + long * float(i) / (count - 1)
			var post := _box(Vector3(FENCE_POST, FENCE_TALL, FENCE_POST), posts)
			post.position = Vector3(x, FENCE_TALL * 0.5, z)
			fence.add_child(post)
		for high: float in FENCE_RAILS:
			var rail := _box(Vector3(long, FENCE_RAIL, FENCE_RAIL), rails)
			rail.position = Vector3(area.get_center().x, FENCE_TALL * high, z)
			fence.add_child(rail)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(long, FENCE_TALL, FENCE_POST * 2.0)
		shape.shape = box
		shape.position = Vector3(area.get_center().x, FENCE_TALL * 0.5, z)
		body.add_child(shape)
	if arena.bake_scenery:
		Bake.merge(fence)


## A roller lying across the bay, sunk to its axle with its top showing, and the bars along it
## that show it going round.
func _roller(at: Vector3) -> Node3D:
	var arena := match_node.arena
	var axle := Node3D.new()
	axle.position = at
	add_child(axle)
	var drum := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = ROLLER
	mesh.bottom_radius = ROLLER
	mesh.height = ROLLER_LONG
	mesh.radial_segments = 16
	mesh.rings = 1
	drum.mesh = mesh
	drum.material_override = arena.surfaces.metal(STEEL)
	drum.rotation.x = PI * 0.5
	axle.add_child(drum)
	var bars := arena.surfaces.metal(DARK_STEEL)
	for i: int in ROLLER_BARS:
		var turn := TAU * float(i) / ROLLER_BARS
		var bar := _box(Vector3(0.05, 0.03, ROLLER_LONG * 0.98), bars)
		bar.position = Vector3(sin(turn), cos(turn), 0.0) * ROLLER
		bar.rotation.z = -turn
		axle.add_child(bar)
	return axle


func _words(at: Vector3) -> void:
	var label := Label3D.new()
	label.name = "Painted"
	label.text = WORDS
	label.font = Type.mark_font()
	label.font_size = WORDS_SIZE
	label.outline_size = 0
	label.pixel_size = WORDS_TALL / (WORDS_SIZE * Type.CAP_HEIGHT)
	label.modulate = Color(KartLift.LINE_INK, 0.9)
	# Read from the camera's side of it, as the lift's are.
	label.rotation.x = -PI * 0.5
	label.position = at
	add_child(label)


func _physics_process(delta: float) -> void:
	if held != null:
		_keep(delta)
	else:
		speed = move_toward(speed, 0.0, delta * 12.0)
		_take()
	for slot: int in _leaving.keys():
		var kart := match_node.kart_of(slot)
		if kart == null or not holds(kart):
			_leaving.erase(slot)
	_turned = fmod(_turned + speed / ROLLER * delta, TAU)
	for roller: Node3D in _rollers:
		roller.rotation.z = -_turned
	_step_straps(delta)


## The straps let out over the kart once it has rolled into place on the rollers, and wound back
## in as it is let go, one after the next.
func _step_straps(delta: float) -> void:
	var settled := held != null and _at.distance_to(_hold) < SETTLED
	var was := strapped
	var time := STRAP_ON if settled else STRAP_OFF
	strapped = move_toward(strapped, 1.0 if settled else 0.0, delta / time)
	if strapped == was:
		return
	for i: int in _straps.size():
		var reach := clampf(strapped * (1.0 + STRAP_STAGGER * 3.0) - STRAP_STAGGER * i, 0.0, 1.0)
		var strap: Node3D = _straps[i]
		strap.visible = reach > 0.0
		strap.scale = Vector3(1.0, 1.0, maxf(reach, 0.001))


## The straps: one from each corner of a kart held on the rollers, square to the wall, out and down
## to a ratchet on the floor beside the bay, each a band pivoted at its ratchet that is let out
## toward the kart, and the ratchets, which stay.
func _build_straps() -> void:
	var arena := match_node.arena
	var band := arena.surfaces.painted(STRAP_INK)
	var ratchets := arena.surfaces.metal(DARK_STEEL)
	var holds_at := Node3D.new()
	holds_at.name = "Ratchets"
	add_child(holds_at)
	for along: float in [1.0, -1.0]:
		for side: float in [-1.0, 1.0]:
			var corner := _hold + FACING * along * KART_CORNER.x
			corner += Vector3(0.0, KART_CORNER.y, side * KART_CORNER.z)
			var anchor := _hold + FACING * along * (KART_CORNER.x + STRAP_OUT.x)
			anchor += Vector3(0.0, 0.02, side * (area.size.y * 0.5 - STRAP_OUT.y))
			var ratchet := _box(RATCHET, ratchets)
			ratchet.position = anchor + Vector3(0.0, RATCHET.y * 0.5, 0.0)
			holds_at.add_child(ratchet)
			var pivot := Node3D.new()
			pivot.name = "Strap"
			pivot.position = anchor
			add_child(pivot)
			pivot.look_at(corner, Vector3.UP)
			var long := anchor.distance_to(corner)
			var strap := _box(Vector3(STRAP_WIDE, STRAP_THICK, long), band)
			strap.position = Vector3(0.0, 0.0, -long * 0.5)
			pivot.add_child(strap)
			pivot.scale = Vector3(1.0, 1.0, 0.001)
			pivot.visible = false
			_straps.append(pivot)
	if arena.bake_scenery:
		Bake.merge(holds_at)


## Puts the kart on the rollers back where it is held and reads its motor, or lets it go once it
## backs off them or is gone. Taken on, it rolls on over the cradle and squares up to the wall
## rather than being put there at once, see [constant BRAKE].
func _keep(delta: float) -> void:
	if not is_instance_valid(held) or not held.alive or held.motor.forward_speed < -BACKING:
		_release()
		return
	var left := _at.distance_to(_hold)
	_rolling = minf(_rolling, sqrt(2.0 * BRAKE * left))
	_at = _at.move_toward(_hold, _rolling * delta)
	var whole := _came_at.distance_to(_hold)
	var through := 1.0 - _at.distance_to(_hold) / whole if whole > 0.001 else 1.0
	_heading = lerp_angle(_came_heading, atan2(-FACING.x, -FACING.z), smoothstep(0.0, 1.0, through))
	held.global_position = Vector3(_at.x, held.global_position.y, _at.z)
	held.motor.heading = _heading
	held.rotation = Vector3(0.0, _heading, 0.0)
	held.motor.velocity = FACING * held.motor.forward_speed
	speed = maxf(held.motor.forward_speed, 0.0)
	if speed > best:
		best = speed
		best_slot = held_slot


## Takes onto the rollers the first kart driven into the bay nose first toward the wall.
func _take() -> void:
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or not kart.alive or slot.is_dummy() or _leaving.has(slot.index):
			continue
		if not holds(kart) or kart.motor.forward_speed <= 0.0:
			continue
		if absf(angle_difference(kart.motor.heading, atan2(-FACING.x, -FACING.z))) > SQUARE:
			continue
		held = kart
		held_slot = slot
		_at = kart.global_position
		_came_at = _at
		_heading = kart.motor.heading
		_came_heading = _heading
		_rolling = maxf(kart.motor.forward_speed, ROLL_ON)
		held_kart.emit(slot)
		return


func _release() -> void:
	var slot := held_slot
	if slot != null:
		_leaving[slot.index] = true
	held = null
	held_slot = null
	if slot != null:
		let_go.emit(slot, best)


## Whether [param kart] is in the bay, where its wheels stand.
func holds(kart: Kart) -> bool:
	return kart != null and area.has_point(Vector2(kart.global_position.x, kart.global_position.z))


static func _box(size: Vector3, skin: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var made := MeshInstance3D.new()
	made.mesh = mesh
	made.material_override = skin
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made
