class_name DressMoments
extends Node
## What a piece of the supporter pack watches its kart for, GAME.md 10.8: a death, the respawn after
## it, a cash-out, chips picked up and how big the pot is, by the match's own measure of a pot worth
## banking, [member MatchRules.junction_hint_start], and of a full one,
## [member MatchRules.junction_hint_full]. A piece that answers to them extends this and is told
## each, see [method _died], [method _respawned], [method _cashed] and [method _picked], and steps
## with [method tick]. Worked out on every screen from what the snapshot brings, the pot among it,
## the look alone. On a kart only to look at, in the kart dialog or on the podium, the pot is taken
## for a full one, so the piece is seen at its best.

## The measures of a pot worth banking and of a full one, as the match's rules have them unless it
## says otherwise.
const HINT_START := 250.0
const HINT_FULL := 1200.0

## Whether its kart is alive and cashing out, and its pot's worth, or -1 for a kart only to look
## at; and the two measures of the pot.
var alive := true
var cashing := false
var pot := -1.0
var worth := HINT_START
var full := HINT_FULL
## Seconds it has been stepped, for whatever moves with time.
var clock := 0.0
var _kart: Kart
var _coins := 0
var _pot_at_cash := 0.0


func _ready() -> void:
	var above := get_parent()
	while above != null and not above is Kart:
		above = above.get_parent()
	_kart = above as Kart
	if _kart != null:
		var in_match := _kart.get_parent() as Match
		if in_match != null and in_match.rules != null:
			worth = in_match.rules.junction_hint_start
			full = in_match.rules.junction_hint_full


func _process(delta: float) -> void:
	if _kart == null:
		observe(delta, true, false, -1.0, 0)
	else:
		observe(
			delta,
			_kart.alive,
			_kart.channel_progress >= 0.0,
			_kart.pot.exact_value(),
			_kart.pot.coins
		)


## One frame of [param delta] seconds of a kart [param now_alive] or not, [param now_cashing] out
## or not, with a pot worth [param now_pot], -1 for one only to look at, of [param coins] chips:
## each moment told as it comes, then a step.
func observe(delta: float, now_alive: bool, now_cashing: bool, now_pot: float, coins: int) -> void:
	clock += delta
	if alive and not now_alive:
		_died()
	elif not alive and now_alive:
		_respawned()
	if now_cashing and not cashing:
		_pot_at_cash = now_pot
	if cashing and not now_cashing and now_alive and now_pot < _pot_at_cash - 0.5:
		_cashed()
	if now_alive and coins > _coins and pot >= 0.0:
		_picked(coins - _coins)
	_coins = coins
	alive = now_alive
	cashing = now_cashing
	pot = now_pot
	tick(delta)


## How full the pot is, 0 empty to 1 at the measure of a full one; full for a kart only to look at.
func share() -> float:
	if pot < 0.0:
		return 1.0
	return clampf(pot / maxf(full, 1.0), 0.0, 1.0)


## Its kart has died.
func _died() -> void:
	pass


## Its kart is back after a death.
func _respawned() -> void:
	pass


## Its kart has cashed its pot out, or some of it.
func _cashed() -> void:
	pass


## Its kart has picked up [param count] chips.
func _picked(_count: int) -> void:
	pass


## One frame of [param delta] seconds, after the moments.
func tick(_delta: float) -> void:
	pass
