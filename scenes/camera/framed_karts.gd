class_name FramedKarts
extends RefCounted
## Which karts [CameraRig] keeps in the picture, GAME.md 8.2, as the player chose, see
## [method ViewChoices.follows]: every kart; the karts driven here and the rivals near them; or the
## karts driven here alone. Framing every kart puts the camera wherever the rivals spread to,
## which nobody at this screen chose, and on a small screen makes every kart small. A rival left
## out of the picture is pointed at from the edge of the screen instead, see [OffscreenArrows].
## And, following the rivals near, where the picture is aimed and how close it may come in: at the
## karts driven here, never at the middle of them and their rivals, and never closer than a share
## of the whole arena, see [method aim_places] and [method least].

## How near a kart driven here a rival has to come to be kept in the picture, as a share of the
## arena's longer side; and how much further than that it goes again before it is let go, so one
## driving along the edge of that does not come and go.
const NEAR := 0.45
const LET_GO := 1.25
## Following the rivals near, the closest the camera comes, as a share of the distance that holds
## the whole arena: about half of it across the screen round the kart, so a kart alone is never
## followed so close that the table round it is lost.
const NEARBY_CLOSEST := 0.5

## The way the karts were last picked for, see [method pick].
var following := ViewChoices.FOLLOW_EVERYONE
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
	following = way if not here.is_empty() else ViewChoices.FOLLOW_EVERYONE
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


## Where the picture is aimed, of [param places], where the karts [param framed] count for the
## framing, one for each: the middle of the box they are all in; following the rivals near, the
## middle of the karts of [param here] alone, so the player's own kart stays in the middle of the
## screen however the rivals near it come and go, GAME.md 8.2.
func aim_places(
	framed: Array[Node3D], places: PackedVector3Array, here: Array[Node3D]
) -> PackedVector3Array:
	if following != ViewChoices.FOLLOW_NEARBY:
		return places
	var mine := PackedVector3Array()
	for i: int in mini(framed.size(), places.size()):
		if framed[i] in here:
			mine.append(places[i])
	return mine if not mine.is_empty() else places


## The closest the camera may come, [param closest] as the rig works it out, held back following
## the rivals near to [constant NEARBY_CLOSEST] of [param arena_far], the distance that holds the
## whole arena.
func least(closest: float, arena_far: float) -> float:
	if following != ViewChoices.FOLLOW_NEARBY:
		return closest
	return minf(maxf(closest, arena_far * NEARBY_CLOSEST), arena_far)


## The box every one of [param places] is inside: where the tracked karts count for the framing.
static func box(places: PackedVector3Array) -> AABB:
	var around := AABB(places[0], Vector3.ZERO)
	for place: Vector3 in places:
		around = around.expand(place)
	return around
