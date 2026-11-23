class_name TouchPad
extends RefCounted
## One round button of the touch controls, GAME.md 4.2, see [TouchControls]: what it is, where its
## middle is and how big it is, and how many fingers are on it.

## A finger a little off the edge of a button is still on it: a thumb is not a point.
const REACH := 1.15

var id: StringName
var label := ""
var center := Vector2.ZERO
var radius := 0.0
## How many fingers are on it.
var held := 0


func _init(pad_id: StringName, pad_radius: float, pad_label := "") -> void:
	id = pad_id
	radius = pad_radius
	label = pad_label


func reaches(point: Vector2) -> bool:
	return point.distance_to(center) <= radius * REACH
