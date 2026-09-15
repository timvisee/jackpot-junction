extends Node
## Sound and music playback. Autoloaded as `Audio`.
##
## Phase 0 stub: the bus layout and the API exist so gameplay can call it; playback lands in M4.

const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"


## Plays a one-shot sound effect by name. No-op until the audio pass.
func play_sfx(_name: StringName, _position: Vector3 = Vector3.ZERO) -> void:
	pass
