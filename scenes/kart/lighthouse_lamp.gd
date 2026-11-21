class_name LighthouseLamp
extends DressLight
## The lamp of the supporter pack's lighthouse, GAME.md 10.8: it turns, sweeping its one beam round
## the kart, quicker while the kart cashes out, and goes dark and warms back up as all the pack's
## light does, see [DressLight]. For a player who asked for fewer flashes it holds still, pointing
## ahead.

## How many turns a second it makes, and while its kart cashes out.
const TURNS := 0.35
const CASHING_TURNS := 0.9

## What it turns; and its beam, its bulb and the glow round the bulb, which shine.
var head: Node3D
var beam: MeshInstance3D
var bulb: MeshInstance3D
var halo: MeshInstance3D


func _ready() -> void:
	shining = [beam, bulb, halo]
	super()


## One frame of [param delta] seconds: lit or going dark as [param lit] says, turning as quickly as
## [param cashing] says, or held pointing ahead under fewer flashes.
func step(delta: float, lit: bool, cashing: bool) -> void:
	super(delta, lit, cashing)
	if head == null:
		return
	if Game.settings.flash_reduction:
		head.rotation.y = 0.0
	else:
		head.rotation.y = wrapf(
			head.rotation.y + (CASHING_TURNS if cashing else TURNS) * TAU * delta, 0.0, TAU
		)
