class_name LoyaltyMap
extends Resource
## The loyalty program's map, GAME.md 8.9: its landmarks and the roads between them. Two landmarks
## joined by a road open each other: winning either opens the other, see [Loyalty].

## Every landmark on the map.
@export var landmarks: Array[LoyaltyLandmark] = []

## The landmarks by id, and each one's roads, the ids it is joined to, worked out once.
var _by_id: Dictionary[StringName, LoyaltyLandmark] = {}
var _roads: Dictionary[StringName, Array] = {}


## The landmark [param id], or null for one this map does not have.
func landmark(id: StringName) -> LoyaltyLandmark:
	_index()
	return _by_id.get(id)


## The ids of the landmarks [param id] has a road to.
func roads_of(id: StringName) -> Array[StringName]:
	var joined: Array[StringName] = []
	joined.assign(_roads.get(id, []))
	return joined


## A road between [param a] and [param b], which open each other.
func join(a: StringName, b: StringName) -> void:
	if a == b:
		return
	for pair: Array in [[a, b], [b, a]]:
		var roads: Array = _roads.get(pair[0], [])
		if pair[1] not in roads:
			roads.append(pair[1])
		_roads[pair[0]] = roads


func _index() -> void:
	if _by_id.size() == landmarks.size():
		return
	_by_id.clear()
	for each: LoyaltyLandmark in landmarks:
		_by_id[each.id] = each
