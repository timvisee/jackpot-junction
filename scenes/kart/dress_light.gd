class_name DressLight
extends Node
## The light of a piece of the supporter pack, GAME.md 10.8: what of it shines goes dark when its
## kart dies and warms back up once it is back, never blinking, since blinking says spawn
## protection; and where the piece says, it flares a little while its kart cashes out, but never
## for a player who asked for fewer flashes. Worked out on every screen from what the snapshot
## brings, alive or not and cashing out, the look alone. On a kart only to look at, in the kart
## dialog or on the podium, it shines and nothing else.

## How quickly it goes dark, how long it takes to warm back up, and how long a flare takes to come
## and to go, in seconds.
const DARKEN := 0.25
const WARM := 1.2
const FLARE_EASE := 0.3

## What shines, each given a paint of its own once it is in the tree.
var shining: Array[MeshInstance3D] = []
## How much brighter it shines while its kart cashes out, of its own light; 0 for not at all.
var flare := 0.0
## How lit it is, 0 dark to 1, and how far into a flare.
var light := 1.0
var flared := 0.0
var _kart: Kart
## Each shining mesh's own paint, and its alpha and its glow at full light.
var _paints: Array[StandardMaterial3D] = []
var _alphas := PackedFloat32Array()
var _glows := PackedFloat32Array()


func _ready() -> void:
	var above := get_parent()
	while above != null and not above is Kart:
		above = above.get_parent()
	_kart = above as Kart
	for mesh: MeshInstance3D in shining:
		if mesh == null or mesh.material_override == null:
			continue
		var own := mesh.material_override.duplicate() as StandardMaterial3D
		mesh.material_override = own
		_paints.append(own)
		_alphas.append(own.albedo_color.a)
		_glows.append(own.emission_energy_multiplier)


## Every drawn frame rather than every step, since it is the look alone and moves smoothly.
func _process(delta: float) -> void:
	step(delta, _kart == null or _kart.alive, _kart != null and _kart.channel_progress >= 0.0)


## One frame of [param delta] seconds: lit or going dark as [param lit] says, flaring while
## [param cashing].
func step(delta: float, lit: bool, cashing: bool) -> void:
	var wanted := 1.0 if lit else 0.0
	light = move_toward(light, wanted, delta / (WARM if wanted > light else DARKEN))
	var flaring := cashing and lit and flare > 0.0 and not Game.settings.flash_reduction
	flared = move_toward(flared, 1.0 if flaring else 0.0, delta / FLARE_EASE)
	var level := light * (1.0 + flare * flared)
	for i: int in _paints.size():
		var paint := _paints[i]
		paint.albedo_color.a = clampf(_alphas[i] * level, 0.0, 1.0)
		if paint.emission_enabled:
			paint.emission_energy_multiplier = _glows[i] * level
