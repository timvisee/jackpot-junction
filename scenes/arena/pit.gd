class_name Pit
extends Area3D
## A hole in the floor. Karts that enter fall and die (M1); for now it only reports entries.

signal kart_entered(body: Node3D)


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.KART
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	kart_entered.emit(body)
