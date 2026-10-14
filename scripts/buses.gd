class_name Buses
extends RefCounted
## Audio bus names, matching the buses in data/audio/default_bus_layout.tres, the way [Layers]
## matches the physics layers in project.godot.
##
## Named in one place because a bus looked up by a name nothing else agrees with fails silently:
## [method AudioServer.get_bus_index] simply answers -1 and the volume never reaches anything.

const MASTER := &"Master"
const MUSIC := &"Music"
const SFX := &"SFX"
## Everything a kart itself makes, routed through the effects bus, so the slider in GAME.md 8.5
## covers the lot without touching the rest of the mix.
const KART := &"Kart"
