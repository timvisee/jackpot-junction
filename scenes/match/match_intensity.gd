class_name MatchIntensity
extends Node
## How exciting the match feels right now, GAME.md 8.4. A match is run as six levels: it opens
## at level 1 and finishes at level 6, and every level has a written-down effect on the music,
## the lights and the camera.
##
## Underneath the levels is a meter from 0 to 1. Two parts add up to it. Heat comes from things
## that just happened, a kill or a cash-out, and fades over a few seconds. Pressure comes from
## how the match stands: a fat unbanked pot on the loose, karts in each other's faces, a cash-out
## running, a Jackpot about to burst. Pressure alone never quite reaches the top, and one kill on
## its own does not either, so nothing winds up unless several things are going on at once.
##
## The level is deliberately slow. The meter has to ask for a different one for a few seconds
## running before the room follows, it moves one level at a time, and whichever way it went it
## then stands for a good while. A flurry therefore cannot flick the room up and straight back
## down: the evening builds, and the little it loses it loses gradually. Last Call is the one
## exception: it stops asking the meter and walks the room up to the top on its own clock,
## a level every couple of seconds, so the finale arrives as a build rather than as a switch.
##
## A client keeps its own meter: the host relays the same events, and snapshots give it the same
## pots and positions, so both machines wind up together.

## Heat one event adds.
const KILL := 0.30
const WOUND := 0.14
const GRAZE := 0.06
const BANK := 0.10
const FLUSH := 0.22
const BOUNTY := 0.18
const BLAST := 0.14
## Heat lost per second, and the most that can be stored, so a flurry keeps paying out.
const DECAY := 0.3
const HEAT_CAP := 1.4
## How fast the reported value climbs toward its target and how slowly it falls back, per
## second. Excitement arrives suddenly and leaves gradually.
const RISE := 3.0
const FALL := 1.2
## Karts closer than this to each other are reading as a duel.
const DUEL_RANGE := 10.0
## The levels of the evening. One per light on the rig, see GAME.md 8.4 for what each does.
const LEVELS := 6
## What the meter has to read for each level from 2 upward.
const MARKS: Array[float] = [0.12, 0.28, 0.45, 0.62, 0.80]
## How far the meter has to fall back below the mark that won a level before it is given up.
const BAND := 0.06
## Seconds the meter has to keep asking for a different level before the room follows it.
const DWELL := 2.5
## Seconds a level stands once it has changed, whichever way it went.
const HOLD := 6.0
## Seconds Last Call takes to walk the room from the bottom to the top, and so the wait
## between its levels. A room already halfway up gets there sooner.
const LAST_CALL_CLIMB := 10.0
const LAST_CALL_STEP := LAST_CALL_CLIMB / float(LEVELS - 1)

var match_node: Match
## The level the room is running at, 1 to [constant LEVELS]. This is what the music, the lights
## and the camera read.
var level := 1
## The smoothed meter the level is picked from.
var value := 0.0
## The fading part, from what just happened.
var heat := 0.0
## The steady part, from how the match stands.
var pressure := 0.0

## Seconds the meter has been asking for a different level, and seconds the current one still
## stands for.
var _dwell := 0.0
var _hold := 0.0
## Whether the Last Call climb is already under way.
var _finale := false


func _ready() -> void:
	Events.kart_killed.connect(_on_killed)
	Events.kart_wounded.connect(_on_wounded)
	Events.grazed.connect(_on_grazed)
	Events.bank_completed.connect(_on_banked)
	Events.flush_completed.connect(_on_flush)
	Events.bounty_called.connect(_on_bounty)
	Events.bounty_claimed.connect(_on_bounty_claimed)
	Events.bomb_exploded.connect(_on_blast)


func _exit_tree() -> void:
	Events.kart_killed.disconnect(_on_killed)
	Events.kart_wounded.disconnect(_on_wounded)
	Events.grazed.disconnect(_on_grazed)
	Events.bank_completed.disconnect(_on_banked)
	Events.flush_completed.disconnect(_on_flush)
	Events.bounty_called.disconnect(_on_bounty)
	Events.bounty_claimed.disconnect(_on_bounty_claimed)
	Events.bomb_exploded.disconnect(_on_blast)


func add(amount: float) -> void:
	heat = minf(heat + amount, HEAT_CAP)


## Puts the room up a level on the spot, for the things that are worth announcing rather than
## waiting out. It stands for the usual hold afterwards, so one cannot be stacked on another.
func bump() -> void:
	if level < LEVELS:
		_set_level(level + 1)


## Drops the meter at once, for example when everyone on this machine is dead and the room should
## go quiet whatever just happened.
func reset() -> void:
	heat = 0.0
	value = 0.0
	_finale = false
	_set_level(1)


## How far through the levels the room is, 0 at level 1 and 1 at the top. Anything that wants
## to fade with the evening rather than step with it reads this.
func share() -> float:
	return float(level - 1) / float(LEVELS - 1)


## One line for the debug overlay.
func debug_text() -> String:
	return (
		"level %d/%d  meter %.2f (heat %.2f  hold %.2f  next %.0fs)"
		% [level, LEVELS, value, heat, pressure, maxf(_hold, DWELL - _dwell)]
	)


func _physics_process(delta: float) -> void:
	heat = maxf(heat - DECAY * delta, 0.0)
	pressure = _pressure()
	var target := clampf(heat + pressure, 0.0, 1.0)
	if _last_call():
		target = 1.0
	value = move_toward(value, target, (RISE if target > value else FALL) * delta)
	_step_level(delta)
	Audio.set_excitement(level, share())


## Walks the level toward what the meter is asking for: one step at a time, only once the meter
## has kept asking for a while, and never within [constant HOLD] of the last change. Last Call
## skips the queue and takes the room straight to the top.
func _step_level(delta: float) -> void:
	if _last_call():
		_step_finale(delta)
		return
	_finale = false
	_hold = maxf(_hold - delta, 0.0)
	var wanted := _wanted_level()
	if wanted == level:
		_dwell = 0.0
		return
	_dwell += delta
	if _hold > 0.0 or _dwell < DWELL:
		return
	_set_level(level + (1 if wanted > level else -1))


## Last Call, GAME.md 8.4: the room stops listening to the meter and simply climbs, one level
## every [constant LAST_CALL_STEP] until it is at the top. The usual hold does not apply; this
## is the one climb nothing is allowed to slow down.
func _step_finale(delta: float) -> void:
	if not _finale:
		_finale = true
		_dwell = 0.0
	if level >= LEVELS:
		return
	_dwell += delta
	if _dwell >= LAST_CALL_STEP:
		_set_level(level + 1)


## The level the meter is asking for. Holding on to a level takes a little less than reaching it
## did, so a meter sitting right on a mark does not walk up and down over it.
func _wanted_level() -> int:
	var wanted := 1
	for i: int in MARKS.size():
		var mark := MARKS[i] - (BAND if i + 2 <= level else 0.0)
		if value >= mark:
			wanted = i + 2
	return wanted


func _set_level(to: int) -> void:
	if to == level:
		return
	level = clampi(to, 1, LEVELS)
	_dwell = 0.0
	_hold = HOLD


func _last_call() -> bool:
	return match_node != null and match_node.state == Match.State.LAST_CALL


## The part that does not fade.
func _pressure() -> float:
	if match_node == null or match_node.arena == null:
		return 0.0
	var alive: Array[Kart] = []
	var pot := 0.0
	var banking := false
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or not kart.alive:
			continue
		alive.append(kart)
		pot = maxf(pot, kart.pot.exact_value())
		banking = banking or kart.channel_progress >= 0.0
	var rules := match_node.rules
	var total := 0.25 * clampf(pot / maxf(rules.junction_hint_full, 1.0), 0.0, 1.0)
	total += 0.25 * _closeness(alive)
	if banking:
		total += 0.2
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		if zone.active and zone.chips >= zone.cap() * 0.9:
			total += 0.12
			break
	return clampf(total, 0.0, 1.0)


## How close the nearest two karts are, 1 when they are touching and 0 beyond [constant
## DUEL_RANGE]. Two karts circling each other is the most reliable sign that something is about
## to happen.
func _closeness(karts: Array[Kart]) -> float:
	var nearest := DUEL_RANGE
	for i: int in karts.size():
		for j: int in range(i + 1, karts.size()):
			nearest = minf(nearest, karts[i].global_position.distance_to(karts[j].global_position))
	return 1.0 - nearest / DUEL_RANGE


func _on_killed(_victim: int, _killer: int, _cause: StringName) -> void:
	add(KILL)
	# Everybody watching this screen is dead, so the room goes quiet for them. Not during Last
	# Call: the finale is the finale whoever is lying in the pit for the last few seconds of it.
	if _everyone_down() and not _last_call():
		reset()
		Audio.mark_all_players_down()


func _on_wounded(_victim: int, _by: int, _cause: StringName) -> void:
	add(WOUND)


func _on_grazed(_slot: int) -> void:
	add(GRAZE)


func _on_banked(_slot: int, _coins: int, _mult: float, _total: int) -> void:
	add(BANK)


func _on_flush(_slot: int) -> void:
	add(FLUSH)


func _on_blast(_slot: int) -> void:
	add(BLAST)


## A price going on the leader's head is an announcement, not a rumour: the room goes up a
## level for it whatever the meter thinks, and the usual hold keeps it there.
func _on_bounty(_slot: int) -> void:
	add(BOUNTY)
	bump()


func _on_bounty_claimed(_killer: int, _victim: int, _amount: int) -> void:
	add(BOUNTY)


## True when every human in this match is dead, players and remote players alike.
func _everyone_down() -> bool:
	if match_node == null:
		return false
	var humans := 0
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_human():
			continue
		humans += 1
		if slot.kart != null and slot.kart.alive:
			return false
	return humans > 0
