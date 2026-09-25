class_name MusicSwell
extends RefCounted
## How much louder the music gets at the hottest the room gets, GAME.md 8.4 and 8.5: the Intense
## music setting. Off keeps the music at the level it plays at on a quiet table whatever the heat;
## anything above that is how much louder it gets at the top, as a share of how loud it sounds
## there rather than of the signal, so +50% sounds half as loud again. A doubling of loudness is
## ten decibels, and that is the whole of the conversion.

## The top of the slider, and its marks: off, a gentle swell, the one the game always had, which
## is the setting to start from, and a strong one at the top. Normal is the 9 dB it swelled by
## before there was a setting, as a share of loudness: two to the power of 0.9, less one.
const MOST := 1.5
const OFF := 0.0
const GENTLE := 0.4
const NORMAL := 0.866066
const STRONG := MOST
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
