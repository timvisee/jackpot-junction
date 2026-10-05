class_name PickupWire
extends RefCounted
## What is on the floor, sent as what changed rather than as the whole floor, GAME.md 10.3.
##
## Pickups are the largest part of a snapshot and the least interesting: a chip lies where it fell
## until somebody drives over it, and sending every one of them thirty times a second was most of
## why a snapshot did not fit in a datagram. So a snapshot carries the ones that appeared and the
## ones that went, and now and again the whole floor again.
##
## Unreliable packets go missing, so this does not trust a single telling. Every change is
## repeated for a few snapshots, which costs a handful of numbers and means one lost packet
## changes nothing; and the whole floor goes out every couple of seconds regardless, so a client
## that missed something, or that has only just arrived, is never wrong for long.
##
## One of these belongs to each host session rather than to the match, so two matches sharing a
## process keep their own account of what they have told whom. It keeps that account for the
## parts of a snapshot that hardly ever change too, see [member slow].

## How many snapshots a change is repeated in before it is taken as heard.
const REPEATS := 4
## How far a pickup has to have moved, in meters, to be worth mentioning again. Almost all of them
## never move at all; the ones that do are being pulled in by a Chip Magnet or are still in the
## air from whatever dropped them, and a client that was never told stares at a chip sitting where
## it first saw it and then watches it blink out from there.
const MOVED := 0.02
## Snapshots between one whole floor and the next, about two seconds of them.
const KEYFRAME_EVERY := 60

## The parts of a snapshot sent only now and then, see [SlowParts].
var slow := SlowParts.new()

## The pickups the host believes clients have, and the changes still being repeated.
var _have: Dictionary[int, bool] = {}
var _adds: Dictionary[int, int] = {}
var _gone: Dictionary[int, int] = {}
## Where each one was when it was last described, so the ones that have moved can be picked out.
var _at: Dictionary[int, Vector2] = {}
var _until_keyframe := 0


## The pickups part of the next snapshot: what appeared, what went, and whether this is the whole
## floor rather than the difference.
func section(match_node: Match) -> Dictionary:
	var floor_now := MatchSnapshot.pickups_now(match_node)
	var full := _until_keyframe <= 0
	_until_keyframe = KEYFRAME_EVERY if full else _until_keyframe - 1
	if full:
		_have.clear()
		_adds.clear()
		_gone.clear()
		_at.clear()
		for id: int in floor_now:
			_have[id] = true
			_at[id] = _where(floor_now[id])
		return {"pickups": floor_now.values(), "gone": [], "moved": [], "whole": true}
	for id: int in floor_now:
		if not _have.has(id):
			_have[id] = true
			_adds[id] = REPEATS
	for id: int in _have.keys():
		if not floor_now.has(id):
			_have.erase(id)
			_gone[id] = REPEATS
	var appeared: Array = []
	for id: int in _adds.keys():
		# Only what is still there. A chip that arrived and was taken inside the repeat window
		# has nothing left to describe, and its removal is being repeated anyway.
		if floor_now.has(id):
			appeared.append(floor_now[id])
		_spend(_adds, id)
	var went: Array = []
	for id: int in _gone.keys():
		went.append(id)
		_spend(_gone, id)
		_at.erase(id)
	# The few that are going somewhere, as an id and a place and nothing else: whatever they are
	# was said when they arrived and has not changed.
	var moved: Array = []
	for id: int in floor_now:
		var here := _where(floor_now[id])
		if _at.has(id) and _at[id].distance_to(here) < MOVED:
			continue
		_at[id] = here
		if not _adds.has(id):
			moved.append([id, here.x, here.y])
	return {"pickups": appeared, "gone": went, "moved": moved, "whole": false}


## Sends the whole floor in the next snapshot, and the parts that hardly ever change, for
## somebody who has just arrived and has none of it.
func start_again() -> void:
	_until_keyframe = 0
	slow.start_again()


static func _where(entry: Dictionary) -> Vector2:
	return Vector2(entry["x"], entry["z"])


func _spend(from: Dictionary, id: int) -> void:
	var left: int = from[id] - 1
	if left <= 0:
		from.erase(id)
	else:
		from[id] = left
