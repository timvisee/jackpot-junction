class_name KartSoundStats
extends Resource
## Every number the kart's sound uses, GAME.md 8.4. The levels are in dB against the shipped
## files in assets/audio/kart/, which are all peak normalised, so changing one changes only
## that voice's place in the mix.

@export_group("Rev counter")
## Where the needle sits with the engine idling; 1 is the limiter.
@export var idle_rev := 0.13
## How far the engine revs against a slipping clutch with the throttle pinned off the line.
## The clutch then bites over exactly the speed the road needs to reach this same rev, see
## [method KartRev.clutch_fraction], so the needle climbs to it and carries on from there
## instead of flaring and falling back, which is what made pulling away sound harsh.
@export var launch_rev := 0.62
## Extra revs from driven wheels slipping in a drift, at full throttle.
@export var slip_rev_bonus := 0.16
## How much of the speed past the top the needle follows, on nitro or a turbo pad.
@export var over_slope := 0.30
## The needle never passes this, however hard the kart is shoved.
@export var over_max := 1.30
## How fast the needle climbs and falls, per second. Climbing slowly enough that the road can
## keep up with it is what makes pulling away a swell rather than a jump.
@export var rev_rate_up := 4.5
@export var rev_rate_down := 4.5
## Spinning out on oil, the driver is off the pedal: the engine settles to this times the idle.
@export var spin_idle_multiplier := 1.6
## How fast the load follows the pedals, per second. Load is 0 coasting and 1 flat out.
@export var load_rate_up := 9.0
@export var load_rate_down := 5.0

@export_group("Levels")
## Everything the kart itself makes, against the one-shots the whole room hears. The kart sits
## under them on purpose: it is running the whole time, so it is the bed rather than an event.
@export var kart_db := -5.0

@export_group("Engine")
## The rev the engine loop was recorded at: the needle here plays the file at its own pitch.
@export var nominal_rev := 0.55
@export var pitch_min := 0.55
@export var pitch_max := 2.30
## Level flat out. Off the throttle the engine drops by [member off_throttle_db] from it.
@export var engine_db := 0.9
@export var off_throttle_db := -6.5
## How fast the engine fades away when the kart dies or drops down a pit, per second.
@export var engine_fade := 3.0

@export_group("Tires")
## Below the first speed the tires are silent, above the second they are at full voice.
@export var roll_speed_min := 0.8
@export var roll_speed_full := 3.0
## Slip angle in radians at which a drift is as loud as it gets, and the quietest it starts at.
@export var drift_slip_full := 0.7
@export var drift_floor := 0.4
## Slip angles between which a slide outside a drift comes in.
@export var slide_slip_min := 0.22
@export var slide_slip_full := 0.75
## Speeds between which braking hard enough locks the wheels.
@export var lock_speed_min := 2.0
@export var lock_speed_full := 7.0
## How fast a squeal comes in and dies away, per second.
@export var squeal_attack := 14.0
@export var squeal_release := 7.0
## Each squeal's playback speed standing still, and how much of that again it gains at top speed.
@export var drift_pitch := 1.00
@export var drift_pitch_speed := 0.30
@export var drift_db := -6.5
@export var slide_pitch := 0.88
@export var slide_pitch_speed := 0.22
@export var slide_db := -9.9
@export var lock_pitch := 0.72
@export var lock_pitch_speed := 0.16
@export var lock_db := -6.9
## Speed fraction the squeal pitch stops rising at, so a nitro run does not shriek.
@export var squeal_pitch_cap := 1.6

@export_group("Launch chirp")
## A chirp of wheelspin when the throttle goes down at a standstill. Above the second speed
## there is no chirp left to give.
@export var chirp_speed_min := 0.2
@export var chirp_speed_full := 2.2
## How much wheelspin it takes to chirp, and the seconds before it may chirp again.
@export var chirp_threshold := 0.4
@export var chirp_cooldown := 0.6
@export var chirp_pitch := 1.25
@export var chirp_db := -8.0

@export_group("Placement")
## Metres at which a kart plays at exactly the level written above. It has to be the distance
## the ears sit at, [member CameraRig.listener_height], or the attenuation at that distance is
## added to every level here and none of them mean what they say. It also sets the falloff:
## a kart twice this far off is 6 dB down.
@export var unit_size := 2.5
## A ceiling on gain, for a kart closer to the ears than [member unit_size]. It is a guard, not
## the level anything is meant to run at: set at or below the written levels it flattens them
## all to itself and nothing in this resource does anything.
@export var max_db := 3.0
## How hard a kart off to one side is pushed into that speaker, 0 to 1.
@export var panning_strength := 0.6
