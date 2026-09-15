class_name Pit
extends Area3D
## A hole in the floor. A kart that enters starts falling and dies, see GAME.md 3.6.

signal kart_entered(body: Node3D)


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.KART | Layers.PROTECTED
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("start_fall"):
		body.call("start_fall")
	kart_entered.emit(body)
