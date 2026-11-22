class_name KartTravel
extends RefCounted
## The way each kart driven here is traveling, as [CameraRig] looks ahead of it, GAME.md 8.2: eased
## over [constant EASE] seconds rather than taken as it is each frame. A bump, a wall or a spin
## turns a kart round in a frame, and the look-ahead and the floor kept ahead of it used to swing
## round with it, half the screen across and back for a knock that was over before anybody saw it.

## How long a change in the way a kart is traveling takes to come through, in seconds.
const EASE := 0.35

## By the kart's instance id, on the floor, in meters a second.
var _eased: Dictionary[int, Vector3] = {}


## Forgets every kart: the next are taken as they are going.
func reset() -> void:
	_eased.clear()


## Eases on [param delta] seconds for [param karts]; a kart new to it is taken as it is going, and
## one no longer among them is forgotten.
func follow(karts: Array[Node3D], delta: float) -> void:
	var take := 1.0 - exp(-delta / EASE)
	var kept: Dictionary[int, Vector3] = {}
	for kart: Node3D in karts:
		var now := _now(kart)
		var id := kart.get_instance_id()
		kept[id] = _eased[id].lerp(now, take) if _eased.has(id) else now
	_eased = kept


## How [param kart] is traveling, eased; as it is going for one not eased yet.
func of(kart: Node3D) -> Vector3:
	var id := kart.get_instance_id()
	return _eased[id] if _eased.has(id) else _now(kart)


## How [param kart] is going this frame, on the floor.
static func _now(kart: Node3D) -> Vector3:
	var body := kart as CharacterBody3D
	return Vector3(body.velocity.x, 0.0, body.velocity.z) if body != null else Vector3.ZERO
