class_name MusicSwell
extends RefCounted
## How much louder the music gets at the hottest the room gets, GAME.md 8.4 and 8.5: the Intense
## music setting. Off keeps the music at the level it plays at on a quiet table whatever the heat;
## anything above that is how much louder it gets at the top, as a share of how loud it sounds
## there rather than of the signal, so +50% sounds half as loud again. A doubling of loudness is
## ten decibels, and that is the whole of the conversion.

## The top of the slider, twice as loud, and its marks: off, a gentle swell, the setting to start
## from, and a strong one at the top. Normal is about 5 dB: the 9 dB the music swelled by at first,
## +87%, jumped too far at the top of the heat.
const MOST := 1.0
const OFF := 0.0
const GENTLE := 0.2
const NORMAL := 0.4
const STRONG := MOST
## The Normal of before, two to the power of 0.9, less one: a setting still at it was never moved
## from where it started, and starts from the Normal of now, see [method read].
const WAS_NORMAL := 0.866066
const MARKS: Dictionary[String, float] = {
	"Off": OFF,
	"Gentle": GENTLE,
	"Normal": NORMAL,
	"Strong": STRONG,
}


## How many decibels louder the music is at the top for [param swell].
static func db(swell: float) -> float:
	return 10.0 * log(1.0 + clampf(swell, OFF, MOST)) / log(2.0)


## [param swell] as the slider says it: Off, or how much louder, to the percent.
static func words(swell: float) -> String:
	var percent := roundi(clampf(swell, OFF, MOST) * 100.0)
	return "Off" if percent == 0 else "+%d%%" % percent


## The setting as saved, [param saved], as it is read: on the slider, and the Normal of before,
## which nobody chose, the Normal of now.
static func read(saved: float) -> float:
	if absf(saved - WAS_NORMAL) < 0.0005:
		return NORMAL
	return clampf(saved, OFF, MOST)
