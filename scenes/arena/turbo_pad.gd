class_name TurboPad
extends Area3D
## A directional speed boost pad. A kart is launched along [member direction] once its center is
## well onto the pad, not the moment its bumper touches the edge, so the shove reads as coming
## from the pad itself. A kart that leaves and comes back is launched again.
##
## Pads side by side that point the same way are one pad, a section of them, see
## [method ArenaGrid.turbo_sections]: as two, a kart driven down the line between them had its
## center on the edge of both, well onto neither, and went through without a launch.

signal triggered(body: Node3D)

## How far in from the edge of the pad the kart's center must be, on both axes, as a fraction of
## half the pad's narrower side: a single pad's is a fifth of its half width all round.
const INNER_FRACTION := 0.8

@export var direction := Vector3.FORWARD
## Half the size of the pad, across in x and along in z: a single pad's is half a cell each way,
## and a section's covers every pad in it.
@export var half_extents := Vector2(0.625, 0.625)

## Karts overlapping the pad that have not been launched since they drove on.
var _pending: Array[Node3D] = []


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	# Puppets too, so a client gets its own shove on the tick it drives onto the arrow rather
	# than a round trip later, GAME.md 10.3. A pad is painted on the floor and is in the same
	# place on both machines, which makes it as safe to predict against as a wall.
	collision_mask = Layers.KART | Layers.PROTECTED | Layers.PUPPET
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	var edge := minf(half_extents.x, half_extents.y) * (1.0 - INNER_FRACTION)
	var reach := half_extents - Vector2(edge, edge)
	for body: Node3D in _pending.duplicate():
		if not is_instance_valid(body):
			_pending.erase(body)
			continue
		var offset := body.global_position - global_position
		if absf(offset.x) <= reach.x and absf(offset.z) <= reach.y:
			_pending.erase(body)
			body.call("apply_turbo", direction)
			triggered.emit(body)


func _on_body_entered(body: Node3D) -> void:
	var kart := body as Kart
	# Somebody else's kart, drawn on this screen where the host last said it was. Shoving it
	# would be shoving it on the strength of a position a round trip old.
	if kart != null and kart.puppet and not kart.predicted:
		return
	if body.has_method("apply_turbo") and body not in _pending:
		_pending.append(body)


func _on_body_exited(body: Node3D) -> void:
	_pending.erase(body)
