extends RefCounted
## Development harness: the way the checks walk a kart onto the waiting room's pad, for
## tools/multiplayer_driver.gd and tools/server_driver.gd alike. Each seat parks on a corner of the
## pad of its own, and a kart on the far side of the pad from its corner is walked round the pad,
## outside it, rather than across it through the karts already parked there. Walked through them,
## it was shoved at the host, which took the wheel for every shove, NetInput.CLAIM_DENIED; and since
## a walk is no input, the host's kart stood still while the client's walked on, until the two were
## further apart than the host would believe, and the kart never reached the pad at the host.
##
##   const PadWay := preload("res://tools/pad_way.gd")
##   var to := PadWay.toward(junction, seat, kart.global_position)

## Where on the pad each seat parks: a corner each of its five meters, since four karts in a cross a
## meter from the middle shoved each other, and the last one was forever being pushed back off its
## spot.
const SPOTS: Array[Vector3] = [
	Vector3(-1.3, 0.0, -1.3),
	Vector3(1.3, 0.0, 1.3),
	Vector3(1.3, 0.0, -1.3),
	Vector3(-1.3, 0.0, 1.3)
]
## How far from the middle of the pad a kart is walked round it, clear of the pad's two and a half
## meters and of a kart parked on its rim, and nearer than anything standing on the floor of the
## room. And how far a kart's way in is kept from the other corners: past two meters, two karts of a
## meter by one point six are clear of each other whichever way each is facing.
const RING := 4.5
const BERTH := 2.0
## How far ahead along the ring the next point is, in meters: a few frames' walk.
const LEAD := 0.25


## The corner of the pad round [param middle] that [param seat] parks on.
static func spot(middle: Vector3, seat: int) -> Vector3:
	return middle + SPOTS[seat % SPOTS.size()]


## Where a kart at [param at] is walked next on its way to the corner of [param seat] on the pad
## round [param middle]: straight there while the way is clear of every other corner, and
## otherwise round the pad on the ring outside it until it is, always the same way round, so two
## karts on it never meet head on.
static func toward(middle: Vector3, seat: int, at: Vector3) -> Vector3:
	var to := spot(middle, seat)
	if clear(middle, seat, at, to):
		return to
	var out := Vector3(at.x - middle.x, 0.0, at.z - middle.z)
	if out.length() < 0.01:
		out = SPOTS[seat % SPOTS.size()]
	var angle := atan2(out.z, out.x)
	# Inside the ring and not on its way in: straight out to the ring first.
	if out.length() >= RING - LEAD:
		angle += LEAD / RING
	return middle + Vector3(cos(angle), 0.0, sin(angle)) * RING


## Whether the way from [param from] to [param to] keeps [constant BERTH] from every corner of the
## pad round [param middle] but the one of [param seat].
static func clear(middle: Vector3, seat: int, from: Vector3, to: Vector3) -> bool:
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	for other: int in SPOTS.size():
		if other == seat % SPOTS.size():
			continue
		var corner := spot(middle, other)
		var at := Vector2(corner.x, corner.z)
		if at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)) < BERTH:
			return false
	return true
