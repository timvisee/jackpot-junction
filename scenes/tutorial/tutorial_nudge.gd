class_name TutorialNudge
extends RefCounted
## When the tutorial points the player at the clipboard again, GAME.md 9.4a: a learner who has not
## found it, up in its corner, stands about or drives round with nothing done. Standing still a
## while with nothing getting done, or a longer while of nothing getting done however they drive,
## and it is time; and again as long as it stays that way. Getting on with the lesson, or being
## busy with something else, a question or the hand open, starts the wait over. [TutorialRun] asks
## every tick and lands the board when told, see [method TutorialList.nudge].

## How long, in seconds, standing still, and then nothing getting done however the kart drives,
## before the clipboard is pointed at, and again after.
const STILL_FOR := 3.0
const QUIET_FOR := 20.0
## How slow the kart goes, in meters a second, to be standing still.
const STANDING := 0.5
## How far a lesson has to get, in tasks' worth, to be getting on: a bar's fiftieth, so a bar
## creeping forward on nothing is not. Up from wherever it fell back to: the nitro filling again
## is no headway, burning it again is.
const HEADWAY := 0.02

## Whether the tutorial points at the clipboard at all: the tutorial's suites turn it off, as they
## do [member SpotFraming.on], and test it on its own.
static var on := true

## Seconds of nothing getting done, and of standing still, since the last headway or the last time
## the clipboard was pointed at.
var quiet := 0.0
var still := 0.0
## The least the lesson's headway has been since it last got on, for telling getting on from
## falling back and coming again.
var _low := INF


## Starts the wait over, from [param headway], the lesson's as it is: a new lesson, or one got on
## with.
func reset(headway: float) -> void:
	quiet = 0.0
	still = 0.0
	_low = headway


## One tick of [param delta] seconds, the lesson's [param headway] as it is now, see
## [method TutorialLesson.headway], at [param speed]; [param busy] for the player at something
## else just then. Whether to point at the clipboard now.
func step(delta: float, headway: float, speed: float, busy: bool) -> bool:
	if busy or headway >= _low + HEADWAY:
		reset(headway)
		return false
	_low = minf(_low, headway)
	quiet += delta
	still = still + delta if speed < STANDING else 0.0
	if still < STILL_FOR and quiet < QUIET_FOR:
		return false
	quiet = 0.0
	still = 0.0
	return true
