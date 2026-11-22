class_name FramedKarts
extends RefCounted
## Which karts [CameraRig] keeps in the picture, GAME.md 8.2, as the player chose, see
## [method ViewChoices.follows]: every kart; the karts driven here and the rivals near them; or the
## karts driven here alone. Framing every kart puts the camera wherever the rivals spread to,
## which nobody at this screen chose, and on a small screen makes every kart small. A rival left
## out of the picture is pointed at from the edge of the screen instead, see [OffscreenArrows].

## How near a kart driven here a rival has to come to be kept in the picture, as a share of the
## arena's longer side; and how much further than that it goes again before it is let go, so one
## driving along the edge of that does not come and go.
const NEAR := 0.45
const LET_GO := 1.25

## The rivals near enough now, by instance id.
var _near: Dictionary[int, bool] = {}


## Forgets who was near.
func reset() -> void:
	_near.clear()


## The karts of [param all] to keep in the picture for [param way], one of
## [constant ViewChoices.FOLLOWS] but Auto, with [param here] the karts driven at this screen and
## [param arena] the arena's size on the floor. With nobody driven here, a screen watching, every
## kart.
func pick(all: Array[Node3D], here: Array[Node3D], way: String, arena: Vector2) -> Array[Node3D]:
	if way == ViewChoices.FOLLOW_EVERYONE or here.is_empty():
		_near.clear()
		return all
	var reach := maxf(arena.x, arena.y) * NEAR
	var kept: Array[Node3D] = []
	for kart: Node3D in all:
		if kart in here:
			kept.append(kart)
			continue
		var id := kart.get_instance_id()
		if way != ViewChoices.FOLLOW_NEARBY:
			_near.erase(id)
			continue
		var limit := reach * (LET_GO if _near.has(id) else 1.0)
		if _nearest(kart, here) <= limit:
			_near[id] = true
			kept.append(kart)
		else:
			_near.erase(id)
	return kept


## How far [param kart] is across the floor from the nearest of [param here].
static func _nearest(kart: Node3D, here: Array[Node3D]) -> float:
	var gap := INF
	for mine: Node3D in here:
		var apart := kart.global_position - mine.global_position
		gap = minf(gap, Vector2(apart.x, apart.z).length())
	return gap
