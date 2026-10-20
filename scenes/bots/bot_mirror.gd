class_name BotMirror
extends RefCounted
## How hard the bots try, read off what the players actually do, GAME.md 9.1.
##
## The bots copy the room they are in. A player who never touches an item leaves the bots sitting
## on theirs; a player who burns nitro every lap gets bots that burn it too; a player who never
## drifts faces bots that drive tidily. On top of that the bots ease off while they are ahead
## on score and sharpen up while they are behind, so a match stays close without the bots ever
## turning unbeatable. The score they chase is the live one, banked plus whatever is still in
## the pot, so a player on a hot lap is treated as the leader they are about to become rather
## than the one they were at their last cash-out. Traits still apply over the top: a Bumper is
## a Bumper whatever the players do, it just does its Bumper things at the players' pitch.
##
## Everything is read from the stats the match already collects for the results screen, so
## nothing extra has to be tracked. With nobody to copy, a booth's demo or a room of bots alone,
## they drive as a keen player does, see [constant ALONE].

## What counts as a player who is all-in on each habit: three items a minute, a twentieth of the
## match spent on nitro, a quarter of the distance driven sideways.
const ITEMS_PER_MINUTE := 3.0
const NITRO_SHARE := 0.05
const DRIFT_SHARE := 0.25
## Early on there is not enough driving to judge by, so the first stretch is measured as if it
## lasted this long.
const WARMUP := 45.0
## Points of difference that move the effort by a full step, and how far it may move.
const EFFORT_SPAN := 600.0
const EFFORT_MIN := 0.7
const EFFORT_MAX := 1.3
## The habits bots drive with in a match with no human players at all, a booth's demo or bots on
## their own, GAME.md 9.1 and 9.8: a keen player's, nitro burned, corners drifted and items played,
## so a room of bots shows what the game is rather than four tidy drivers sitting on everything.
const ALONE := 0.6

## How keen the players are on items, nitro and drifting, each 0 to 1.
var items := 0.0
var nitro := 0.0
var drift := 0.0
## Below 1 the bots are ahead and coast; above 1 they are behind and bear down.
var effort := 1.0
## Whether the habits are held where [method hold_habits] put them rather than read off the
## match, as the Final Hand's models drive, STORY.md 8.2. The effort is read off the match either
## way.
var held := false


## Holds the habits at those of a whole profile's [param stats], its lifetime of GAME.md 8.5, from
## the first second rather than after the match has gone on long enough to judge by: how the
## Final Hand's models drive, STORY.md 8.2.
func hold_habits(stats: Dictionary) -> void:
	var seconds := maxf(float(stats.get(&"seconds", 0.0)), WARMUP)
	items = clampf(float(stats.get(&"items", 0.0)) / (seconds / 60.0) / ITEMS_PER_MINUTE, 0.0, 1.0)
	nitro = clampf(float(stats.get(&"nitro", 0.0)) / seconds / NITRO_SHARE, 0.0, 1.0)
	var driven := maxf(float(stats.get(&"driven", 0.0)), 1.0)
	drift = clampf(float(stats.get(&"drifted", 0.0)) / driven / DRIFT_SHARE, 0.0, 1.0)
	held = true


## Reads the players' habits and the score gap. In a match with no human players at all the habits
## are a keen player's, see [constant ALONE], unless they are held.
func update(match_node: Match) -> void:
	var humans := 0
	var used := 0.0
	var burned := 0.0
	var drifted := 0.0
	var driven := 0.0
	var best_human := 0
	var best_bot := 0
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_human():
			best_bot = maxi(best_bot, slot.score())
			continue
		humans += 1
		used += slot.stats.value(&"items")
		burned += slot.stats.value(&"nitro")
		drifted += slot.stats.value(&"drifted")
		driven += slot.stats.value(&"driven")
		best_human = maxi(best_human, slot.score())
	if humans == 0:
		if not held:
			items = ALONE
			nitro = ALONE
			drift = ALONE
		return
	effort = clampf(1.0 + float(best_human - best_bot) / EFFORT_SPAN, EFFORT_MIN, EFFORT_MAX)
	if held:
		return
	var elapsed := maxf(match_node.rules.duration - match_node.time_left, WARMUP)
	items = clampf(used / humans / (elapsed / 60.0) / ITEMS_PER_MINUTE, 0.0, 1.0)
	nitro = clampf(burned / humans / elapsed / NITRO_SHARE, 0.0, 1.0)
	drift = clampf(drifted / maxf(driven, 1.0) / DRIFT_SHARE, 0.0, 1.0)


## How hard a bot should lean on whoever is in front of it. Trailing bots go hunting.
func hunt_urgency() -> float:
	return effort


## How much a bot should want to go out of its way for an item box.
func item_appetite() -> float:
	return lerpf(0.15, 1.6, items)


## Seconds a bot sits on an item before using it just to be rid of it.
func item_patience(base: float) -> float:
	return base * lerpf(6.0, 0.4, items)


## Fraction of tank a bot wants before it will burn any.
func nitro_threshold() -> float:
	return lerpf(1.05, 0.3, nitro)


## Steering angle, in radians, past which a bot yanks the handbrake.
func drift_angle() -> float:
	return lerpf(2.4, 0.9, drift)
