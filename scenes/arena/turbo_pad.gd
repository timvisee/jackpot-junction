class_name TurboPad
extends Area3D
## A directional speed boost pad. A kart driving over it is launched along [member direction].

signal triggered(body: Node3D)

@export var direction := Vector3.FORWARD


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.KART | Layers.PROTECTED
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("apply_turbo"):
		body.call("apply_turbo", direction)
		triggered.emit(body)
