class_name CannonJam
extends RefCounted
## A cannon held back by the limit on bullets in the air, GAME.md 5.1: the shot is refused, and a
## player at this machine hears a dry click and sees a puff of smoke at the muzzle, once a
## cooldown for as long as the trigger is held, so a full sky reads as the limit rather than as a
## cannon that has jammed or a press that was missed. A bot holding its trigger says nothing.

## The puff: its smoke, how big against a kart's pop, and how many wisps.
const SMOKE := Color(0.62, 0.62, 0.66)
const PUFF := 0.22
const WISPS := 5
## The phone's buzz on a held-back shot, GAME.md 4.2: longer and softer than a shot's firm tap, see
## [constant Kart.SHOT_RUMBLE_MS], so a full sky is felt as the limit, not a fired shot.
const RUMBLE_MS := 65
const RUMBLE_STRENGTH := 0.35


## Whether [param kart]'s cannon has a shot for its trigger now; held back by the limit on bullets
## in the air, it says so first, see [method say].
static func has_shot(kart: Kart) -> bool:
	if kart.cannon.can_fire():
		return true
	if kart.cannon.is_full() and kart.cannon.jam_due() and kart.input is PlayerInput:
		say(kart)
	return false


## The click and the puff of [param kart]'s cannon held back: on this machine's own kart as it is
## refused, and on a client's as the host says it was, see [method KartPrediction.hear].
static func say(kart: Kart) -> void:
	var direction := KartAim.steered(kart, kart.aim_direction())
	var muzzle := kart.global_position + direction * kart.cannon_stats.muzzle_offset
	Burst.spawn(kart.get_parent(), muzzle, SMOKE, PUFF, WISPS)
	Events.cannon_jammed.emit(kart.slot)
	# The phone feels a held-back shot as well, longer and softer than a fired one, see [method
	# Kart._fire]; only this machine's own touch player, as the shot buzz is.
	if TouchInput.enabled and Game.settings.rumble:
		Input.vibrate_handheld(RUMBLE_MS, RUMBLE_STRENGTH)
