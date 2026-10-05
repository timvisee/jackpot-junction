class_name SlowParts
extends RefCounted
## The parts of a snapshot that hardly ever change, GAME.md 10.3: every player's name, way of
## driving and statistics, and every kart's dress and plate. With eight karts they were a fifth of
## every snapshot, sent thirty times a second to say what the last one said, and a snapshot of
## eight came in eight pieces of a datagram, any one of which going missing loses the lot.
##
## So each player's go in every [constant EVERY]th snapshot, twice a second, each player on a beat
## of their own so that no one snapshot carries everybody's, which is how a client that missed one
## is put right; a name, a way of driving, a dress or a plate also goes in the few snapshots after
## it changes, so a dress picked on a stall shows at once and one lost packet changes nothing. The
## statistics change all the time and matter only at the end, so they go at the slow beat alone,
## and in every snapshot while the match is not being played, so the podium is drawn from the last
## word on them. Somebody who has just arrived gets all of it in the next one, see
## [method start_again].
##
## One of these belongs to each host session, with its [PickupWire].

## Snapshots between one player's slow beat and their next: half a second of them.
const EVERY := 15
## How many snapshots a change is repeated in before it is taken as heard.
const REPEATS := 4

var _count := 0
## Whether the snapshot being built carries all of it, and whether the next one is to.
var _everything := true
var _fresh := true
## What each part last said, by its owner and its name, and how many more snapshots a change to it
## is still being repeated in.
var _said: Dictionary[String, Variant] = {}
var _repeats: Dictionary[String, int] = {}


## Starts the next snapshot: all of it while nothing is being played, [param running] false, and
## for somebody who has just arrived.
func next(running: bool) -> void:
	_everything = _fresh or not running
	_fresh = false
	_count += 1


## Whether the owner on [param beat], a player's slot, has its slow beat in the snapshot being
## built, or the snapshot carries all of it anyway.
func due(beat: int) -> bool:
	return _everything or posmod(_count + beat, EVERY) == 0


## Whether [param value], the part called [param key] of the owner on [param beat], goes into the
## snapshot being built.
func wants(key: String, value: Variant, beat: int) -> bool:
	if not _said.has(key) or typeof(_said[key]) != typeof(value) or _said[key] != value:
		_said[key] = value
		_repeats[key] = REPEATS
	var left: int = _repeats.get(key, 0)
	if left > 0:
		_repeats[key] = left - 1
	return due(beat) or left > 0


## Sends all of it in the next snapshot, for somebody who has just arrived and has none of it.
func start_again() -> void:
	_fresh = true
