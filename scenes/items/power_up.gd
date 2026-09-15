class_name PowerUp
extends Resource
## A held item, GAME.md 7.1. Karts hold one and use it with a button; [method activate] applies
## the effect, usually by adding a [KartEffect] or spawning something.

@export var id: StringName
@export var display_name := ""
@export var description := ""
## Relative chance of coming out of a power-up pad.
@export var weight := 1.0
@export var color := Color.WHITE


func activate(_kart: Kart) -> void:
	pass
