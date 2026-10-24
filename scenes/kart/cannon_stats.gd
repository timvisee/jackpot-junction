class_name CannonStats
extends Resource
## Cannon and bullet numbers from GAME.md 5.1 and 5.2. Cannon power-ups swap this resource.

@export_group("Firing")
@export var fire_cooldown := 0.4
@export var max_live_bullets := 3
@export var muzzle_offset := 1.0
@export var spread_count := 1
@export var spread_angle_deg := 0.0
@export var free_aim := false

@export_group("Bullet")
@export var bullet_speed := 17.0
@export var bullet_radius := 0.15
## Wall bounces before a bullet dies. Zero by default: jokers and the Ricochet Cannon add some.
@export var bounces := 0
@export var lifetime := 3.0

@export_group("Projectile")
## What a shot is, for how it strikes and how it is drawn, GAME.md 5.3: [code]ball[/code] the plain
## bullet, or rocket, grenade, railgun, lightning or boomerang. The cannon power-ups set it.
@export var kind := &"ball"
## Life it takes from a kart on a direct hit, GAME.md 5.3: one for the plain bullet, two for the
## rocket, which kills a kart at full life outright.
@export var hits := 1
## If above zero, the shot bursts over this radius where it lands and over its fuse, catching karts,
## crates, turrets and bombs as a bomb's blast does, see [Blast]. The burst takes one life each.
@export var blast_radius := 0.0
## Whether the shot bursts when its lifetime runs out rather than simply dying: a grenade's fuse.
@export var explode_on_expire := false
## How many karts or crates the shot passes through before it stops: a railgun pierces.
@export var pierce := 0
## How many more targets the shot leaps to after a hit, each nearer than the last: chain lightning.
@export var chain := 0
## Whether the shot flies out and curves back to the kart that fired it: a boomerang.
@export var returns := false

@export_group("Aim assist")
@export var aim_assist := true
@export var aim_assist_cone_deg := 15.0
@export var aim_assist_range := 15.0
@export var aim_assist_turn_rate_deg := 50.0
## Whether bullets keep bending after their first bounce, which Curve Ball turns on.
@export var assist_after_bounce := false
## The assist is for a shot taken on the move, GAME.md 5.2. A kart under this share of its top
## speed is standing still as far as the cannon is concerned; after this long parked the assist
## fades over this long, down to this share of itself. Picking up speed hands it straight back:
## a kart that is moving is a kart with a harder shot to take.
@export var assist_moving_fraction := 0.22
@export var assist_still_grace := 1.2
@export var assist_still_fade := 1.5
@export var assist_still_floor := 0.25
## Degrees a shot is turned toward the nearest enemy as it leaves the barrel, for Aimbot.
@export var auto_aim_deg := 0.0
## How far Aimbot looks for that enemy.
@export var auto_aim_range := 20.0
