class_name Pit
extends Area3D
## A hole in the floor. A kart that enters starts falling and dies, see GAME.md 3.6.

signal kart_entered(body: Node3D)


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	# Puppets too, so a client sees its own kart go down the hole when it drives into one rather
	# than a round trip later, GAME.md 10.3.
	collision_mask = Layers.KART | Layers.PROTECTED | Layers.PUPPET
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var kart := body as Kart
	# Somebody else's kart, drawn on this screen where the host last said it was. Whether it is
	# over the hole is not a question this machine gets to answer, and dropping it here would be
	# dropping it on the strength of a position a round trip old.
	if kart != null and kart.puppet and not kart.predicted:
		return
	if body.has_method("start_fall"):
		body.call("start_fall")
	kart_entered.emit(body)
