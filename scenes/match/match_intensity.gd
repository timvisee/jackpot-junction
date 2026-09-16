class_name MatchIntensity
extends Node
## How exciting the match feels right now, from 0 for a quiet lap to 1 for chaos, GAME.md 8.4.
##
## Two parts add up. Heat comes from things that just happened, a kill or a cash-out, and fades
## over a few seconds. Pressure comes from how the match stands: a fat unbanked pot on the loose,
## karts in each other's faces, a cash-out running, a Jackpot about to burst. Pressure alone
## never quite reaches the top, and one kill on its own does not either, so the music, the arena
## lights and the camera only wind up when several things are going on at once. Last Call pins it
## to the top until the match ends.
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

var match_node: Match
## The smoothed value everything else reads.
var value := 0.0
## The fading part, from what just happened.
var heat := 0.0
## The steady part, from how the match stands.
var pressure := 0.0


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


## Drops the meter at once, for example when everyone on this machine is dead and the room should
## go quiet whatever just happened.
func reset() -> void:
	heat = 0.0
	value = 0.0


## One line for the debug overlay.
func debug_text() -> String:
	return "intensity %.2f (heat %.2f  hold %.2f)" % [value, heat, pressure]


func _physics_process(delta: float) -> void:
	heat = maxf(heat - DECAY * delta, 0.0)
	pressure = _pressure()
	var target := clampf(heat + pressure, 0.0, 1.0)
	if match_node != null and match_node.state == Match.State.LAST_CALL:
		target = 1.0
	value = move_toward(value, target, (RISE if target > value else FALL) * delta)
	Audio.set_intensity(value)


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
		if zone.active and zone.chips >= rules.jackpot_cap * 0.9:
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
	if _everyone_down():
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


func _on_bounty(_slot: int) -> void:
	add(BOUNTY)


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
