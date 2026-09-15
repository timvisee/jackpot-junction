class_name BotInput
extends KartInput
## Control state written by a [BotBrain]. Polling does nothing; the brain fills the fields before
## the kart reads them.


func poll(_delta: float) -> void:
	pass
