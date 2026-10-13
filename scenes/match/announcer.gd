class_name Announcer
extends Node
## The voice of the room, GAME.md 3.12. It watches the kills go by and calls out the ones worth
## calling out: two or three in quick succession, two players taking each other out at the same
## moment, and a player nobody can put down. One call per kill, the biggest thing that just
## happened, so a run of kills reads as a story rather than as a wall of text.
##
## It says nothing itself. It works out what was worth saying and emits [signal
## Events.announced]; the HUD decides how that looks.

## Seconds within which kills count as one run, and within which two kills count as a trade.
const COMBO_WINDOW := 4.0
const TRADE_WINDOW := 2.5
## What a run of kills inside the window is called, from two upward. Anything longer than the
## list keeps the last name.
const COMBOS: Array[String] = ["DOUBLE KILL", "TRIPLE KILL", "QUAD KILL", "KILLING SPREE"]
## Kills without dying, and what each is called. Read in order; the last one reached wins.
const STREAKS: Dictionary[int, String] = {3: "HOT STREAK", 5: "ON FIRE", 8: "UNTOUCHABLE"}
## A showdown's calls, GAME.md 9.7a: every kart that goes out of it, and whoever is left at the
## whistle, the tie broken in a Grand Prix's and the showdown won in a quick match's.
const OUT_CALL := "OUT"
const TIE_BROKEN := "BREAKS THE TIE"
const SHOWDOWN_WON := "WINS THE SHOWDOWN"

## Kills each slot has made since its last death, and since the start of its current run.
var streaks: Dictionary[int, int] = {}
var runs: Dictionary[int, int] = {}

var _last_kill_at: Dictionary[int, float] = {}
## Who each slot was killed by last, and when, so a kill straight back reads as a trade.
var _died_to: Dictionary[int, int] = {}
var _died_at: Dictionary[int, float] = {}
var _now := 0.0


func _ready() -> void:
	Events.kart_killed.connect(_on_kart_killed)
	Events.match_state_changed.connect(_on_state_changed)


## Forgets the match just played, GAME.md 3.12. Kill streaks and killing sprees belong to one
## match; carrying them into the next would announce a spree somebody earned in a game that is
## over. A client resets its own when the host starts another, since it keeps its own count.
func forget_the_match() -> void:
	streaks.clear()
	runs.clear()
	_last_kill_at.clear()
	_died_to.clear()
	_died_at.clear()


func _physics_process(delta: float) -> void:
	_now += delta


## A kill happened. Works out what it was worth saying about it, and says the biggest of them.
func _on_kart_killed(victim_slot: int, killer_slot: int, _cause: StringName) -> void:
	streaks[victim_slot] = 0
	runs[victim_slot] = 0
	# In a showdown going out is the whole story of a kill, GAME.md 9.7a: it outranks anything the
	# kill was worth to whoever made it.
	if _showdown() != null:
		_note_death(victim_slot, killer_slot)
		Events.announced.emit(victim_slot, OUT_CALL)
		return
	if killer_slot < 0 or killer_slot == victim_slot:
		# Nobody to credit: a pit, a bomb of their own or the wall. Worth no announcement.
		_note_death(victim_slot, killer_slot)
		return
	var run := 1
	if _now - float(_last_kill_at.get(killer_slot, -INF)) <= COMBO_WINDOW:
		run = int(runs.get(killer_slot, 0)) + 1
	runs[killer_slot] = run
	_last_kill_at[killer_slot] = _now
	var streak := int(streaks.get(killer_slot, 0)) + 1
	streaks[killer_slot] = streak
	var call := _call_for(killer_slot, victim_slot, run, streak)
	_note_death(victim_slot, killer_slot)
	if not call.is_empty():
		Events.announced.emit(killer_slot, call)


## The one thing worth saying about this kill, or nothing. A run of kills outranks a streak,
## which outranks a trade: the rarer the thing, the louder it is.
func _call_for(killer_slot: int, victim_slot: int, run: int, streak: int) -> String:
	if run >= 2:
		return COMBOS[mini(run - 2, COMBOS.size() - 1)]
	if STREAKS.has(streak):
		return STREAKS[streak]
	if _traded(killer_slot, victim_slot):
		return "TRADE KILL"
	return ""


## Whether this kill pays back one the killer took from the same player a moment ago, which is
## the two of them going down together however many frames apart it actually was.
func _traded(killer_slot: int, victim_slot: int) -> bool:
	return (
		int(_died_to.get(killer_slot, -1)) == victim_slot
		and _now - float(_died_at.get(killer_slot, -INF)) <= TRADE_WINDOW
	)


## The whistle of a showdown, GAME.md 9.7a: whoever is left says so in their color.
func _on_state_changed(state: int) -> void:
	var showdown := _showdown()
	if state != Match.State.RESULTS or showdown == null or showdown.slots.is_empty():
		return
	var winner := showdown.standings()[0]
	if winner.benched:
		return
	Events.announced.emit(winner.index, TIE_BROKEN if showdown.rules.rounds > 0 else SHOWDOWN_WON)


## The match this voice is the room of, when it is a showdown; otherwise null.
func _showdown() -> Match:
	var match_node := get_parent() as Match
	return match_node if match_node != null and match_node.rules.showdown() else null


func _note_death(victim_slot: int, killer_slot: int) -> void:
	_died_to[victim_slot] = killer_slot
	_died_at[victim_slot] = _now
