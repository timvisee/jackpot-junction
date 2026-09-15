class_name PlayerSlot
extends RefCounted
## One participant in a match, human or bot. Slots are the identity used for kills, ownership
## and scores, never node paths.

var index := 0
var input: KartInput
var kart: Kart
var respawn_left := 0.0
var kills := 0
var deaths := 0


func _init(slot_index: int, kart_input: KartInput) -> void:
	index = slot_index
	input = kart_input


func color() -> Color:
	return Palette.player_color(index)
