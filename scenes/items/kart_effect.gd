class_name KartEffect
extends RefCounted
## A timed change to a kart, started by a power-up. The kart steps it every physics tick and ends
## it when the time runs out or when [member finished] is set, for example when a shield pops.

var id: StringName
var time_left := 0.0
var finished := false
## What the power-up that started this was called and what colour it is drawn in, so the HUD can
## say what is running without knowing what any of them do, GAME.md 8.3. Filled in by the kart as
## an item is played; an effect nobody asked for has neither and is not shown.
var display_name := ""
var color := Color.WHITE
## How long it started with, for the bar that counts it down.
var duration := 0.0


func _init(effect_id: StringName, run_for: float) -> void:
	id = effect_id
	time_left = run_for
	duration = run_for


func start(_kart: Kart) -> void:
	pass


func step(_kart: Kart, _delta: float) -> void:
	pass


func end(_kart: Kart) -> void:
	pass
