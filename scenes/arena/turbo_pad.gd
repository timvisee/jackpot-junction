class_name TurboPad
extends Area3D
## A directional speed boost pad. A kart is launched along [member direction] once its center is
## well onto the pad, not the moment its bumper touches the edge, so the shove reads as coming
## from the pad itself. A kart that leaves and comes back is launched again.

signal triggered(body: Node3D)

## The kart's center must be within this fraction of the pad's half width, on both axes.
const INNER_FRACTION := 0.8

@export var direction := Vector3.FORWARD
## Half the width of the pad's plate.
@export var half_size := 0.625

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
	var reach := half_size * INNER_FRACTION
	for body: Node3D in _pending.duplicate():
		if not is_instance_valid(body):
			_pending.erase(body)
			continue
		var offset := body.global_position - global_position
		if absf(offset.x) <= reach and absf(offset.z) <= reach:
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
