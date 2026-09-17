class_name PickupFlight
extends Node3D
## Whatever a kart just took, flowing into it, GAME.md 8.3. A pickup that blinks out of
## existence says nothing about where it went or who got it; the same chip, die, card or crate
## being sucked off the floor and into a kart says both without a word. The pickup hands over
## its own visual on the way out, so everything flies as itself.

## Long enough to be seen, short enough that the floor is clear again before it matters.
const DURATION := 0.3
## How far it rises on the way in, and how fast it spins while it goes.
const LIFT := 0.45
const SPIN := 11.0
## Where on the kart things disappear into: the middle of it rather than the floor under it.
const KART_HEIGHT := 0.7

var _kart: Kart
var _from := Vector3.ZERO
var _age := 0.0
var _visual: Node3D


## Takes the visual off [param pickup] and flies it into [param kart]. Safe on a pickup that is
## about to be freed: the visual belongs to the flight by then. Null when there is nothing to
## fly or nowhere to fly it.
static func take(pickup: Pickup, kart: Kart) -> PickupFlight:
	var parent := pickup.get_parent()
	if kart == null or parent == null:
		return null
	var from := pickup.visual_center()
	var visual := pickup.detach_visual()
	if visual == null:
		return null
	return spawn(parent, visual, from, kart)


static func spawn(parent: Node, visual: Node3D, from: Vector3, kart: Kart) -> PickupFlight:
	var flight := PickupFlight.new()
	flight.name = "PickupFlight"
	flight._kart = kart
	flight._from = from
	flight._visual = visual
	parent.add_child(flight)
	flight.global_position = from
	flight.add_child(visual)
	visual.position = Vector3.ZERO
	return flight


func _ready() -> void:
	add_to_group(&"pickup_flights")


func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / DURATION, 0.0, 1.0)
	var target := _from
	if is_instance_valid(_kart):
		target = _kart.global_position + Vector3(0.0, KART_HEIGHT, 0.0)
	# Sucked in rather than lobbed across: it leaves the floor slowly and arrives quickly, and
	# shrinks to nothing as it does, so it reads as going into the kart rather than landing on it.
	var pull := t * t
	global_position = _from.lerp(target, pull) + Vector3(0.0, sin(t * PI) * LIFT, 0.0)
	scale = Vector3.ONE * maxf(1.0 - pull, 0.02)
	_visual.rotation.y += SPIN * delta
	if t >= 1.0:
		queue_free()
