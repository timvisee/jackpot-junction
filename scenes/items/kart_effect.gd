class_name KartEffect
extends RefCounted
## A timed change to a kart, started by a power-up. The kart steps it every physics tick and ends
## it when the time runs out or when [member finished] is set, for example when a shield pops.

var id: StringName
var time_left := 0.0
var finished := false


func _init(effect_id: StringName, duration: float) -> void:
	id = effect_id
	time_left = duration


func start(_kart: Kart) -> void:
	pass


func step(_kart: Kart, _delta: float) -> void:
	pass


func end(_kart: Kart) -> void:
	pass
