class_name TestGround
extends RefCounted
## Where everything stands on the driving test's lot, GAME.md 9.4a, by cell of the map in
## data/maps/tutorial.tres: one open lot of a regular map's size, the camera looking north. The
## lessons go round it, the start in the south-west corner, up the west side, along the north, down
## the east side to the trench, and across it into the west again, where the chips are; then the
## exam is played on all of it. What a lesson brings in stands where a map's piece would, so the lot
## reads as a table by the exam rather than as a heap of lessons.

## The start, and the way the kart faces there.
const START := Vector2i(4, 14)
const NORTH := Vector3(0.0, 0.0, -1.0)
const EAST := Vector3(1.0, 0.0, 0.0)
const WEST := Vector3(-1.0, 0.0, 0.0)
## The two pads that switch the way of driving, beside the start, 4.2.
const SIMPLE_PAD := Vector2i(8, 14)
const ADVANCED_PAD := Vector2i(11, 14)
## The lane of cones up the west side, both rows, and the ring of cones at its head to go round.
const LANE: Array[Vector2i] = [
	Vector2i(3, 12),
	Vector2i(5, 12),
	Vector2i(3, 10),
	Vector2i(5, 10),
	Vector2i(3, 8),
	Vector2i(5, 8)
]
const ROUNDABOUT := Vector2i(4, 4)
## The long run along the north, from its west end to the ring of cones at its east end to drift
## round.
const RUN_FROM := Vector2i(7, 3)
const DRIFT_RING := Vector2i(26, 4)
## How far a ring's cones stand from its middle, in meters, and how many there are.
const RING_RADIUS := 1.6
const RING_CONES := 7
## The targets against the east wall, and where the item box comes up.
const TARGETS: Array[Vector2i] = [Vector2i(30, 6), Vector2i(30, 9), Vector2i(30, 12)]
const ITEM_BOX := Vector2i(22, 9)
## The parked kart for the jokers, and which way it faces: at the kart coming down from the
## targets.
const PARKED := Vector2i(26, 14)
## The trench, wall to wall, and where a kart that went in comes back: across it, on the west.
const TRENCH := Rect2i(19, 1, 2, 16)
const ACROSS := Vector2i(16, 12)
## The Royal Flush pads in the corners, the Jackpot that starts full, and the Junction.
const FLUSH_PADS: Array[Vector2i] = [
	Vector2i(1, 1), Vector2i(30, 1), Vector2i(1, 16), Vector2i(30, 16)
]
const JACKPOT := Vector2i(7, 8)
const JACKPOT_RECT := Rect2i(7, 8, 2, 2)
const JUNCTION := Vector2i(13, 8)
const JUNCTION_RECT := Rect2i(12, 7, 4, 4)
## The lifts the exam's bots come up on, at the edges, by the map's extra spawns.
const LIFTS: Array[Vector2i] = [
	Vector2i(10, 1), Vector2i(24, 1), Vector2i(10, 16), Vector2i(24, 16)
]
## The whole lot's floor, for what asks for it.
const LOT := Rect2i(1, 1, 30, 16)


## The cells round [param middle] a ring of [param count] cones stands on, in meters from its
## middle, the first due north.
static func ring(count: int, radius: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i: int in count:
		var angle := TAU * float(i) / float(count)
		points.append(Vector2(sin(angle), -cos(angle)) * radius)
	return points
