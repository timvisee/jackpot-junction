class_name TutorialTask
extends RefCounted
## One thing to do in a lesson of the tutorial, GAME.md 9.4a: a line on the checklist, a hint over
## the kart while it is the one being done, with the controls for it drawn in, and a bar where it
## is a matter of how far, or a count where it is a matter of how many.

## How long the tick box stays lit after one of a count, in seconds.
const TICKED_FOR := 0.8

var text := ""
## The hint's words, with a gap for each of [member actions]: two actions are the two ends of one
## control, a stick on a pad, and are drawn as one. Simple driving, GAME.md 4.2, has its own words
## where it drives differently, and [member simple_way] puts the push where the actions would go.
var hint := ""
var actions: Array[StringName] = []
var simple_text := ""
var simple_hint := ""
var simple_way := false
## Whether it has a bar, and how far along the bar is, 0 to 1.
var bar := false
var progress := 0.0
## How many times it has been done of how many, where it is a count; 0 of for no count.
var count := 0
var of := 0
## Where it needs the kart to go, by cell, for the arrow on the floor, or none.
var arrow := Vector2i(-1, -1)
var done := false

## When one of the count was last done, in engine seconds, or never.
var _ticked_at := -INF


func complete() -> void:
	done = true
	progress = 1.0


## Another [param by] toward [param total] on the bar, and done once it is full.
func advance(by: float, total: float) -> void:
	progress = clampf(progress + by / maxf(total, 0.001), 0.0, 1.0)
	if progress >= 1.0:
		complete()


## One more of the count, and done once they are all there.
func tally() -> void:
	count += 1
	_ticked_at = Time.get_ticks_msec() * 0.001
	if count >= of:
		complete()


## Whether one of the count was done a moment ago, for the tick box to light up for it.
func just_ticked() -> bool:
	return Time.get_ticks_msec() * 0.001 - _ticked_at < TICKED_FOR


## The line on the checklist, with the count where there is one, and simple driving's own words
## where it has them.
func label(simple: bool) -> String:
	var words := simple_text if simple and not simple_text.is_empty() else text
	return "%s  %d/%d" % [words, count, of] if of > 0 else words


## The hint's words for the way the player drives.
func hint_words(simple: bool) -> String:
	return simple_hint if simple and not simple_hint.is_empty() else hint
