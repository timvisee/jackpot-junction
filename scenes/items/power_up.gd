class_name PowerUp
extends Resource
## A held item, GAME.md 7.1. Karts hold one and use it with a button; [method activate] applies
## the effect, usually by adding a [KartEffect] or spawning something.

@export var id: StringName
@export var display_name := ""
## What it does in a sentence, for the catalog of GAME.md 8.8, without numbers: they are its
## [method facts].
@export var description := ""
## Relative chance of coming out of a power-up pad.
@export var weight := 1.0
@export var color := Color.WHITE


func activate(_kart: Kart) -> void:
	pass


## The numbers of what it does that no match shows, for its pane in the catalog of GAME.md 8.8: a
## line each, what it is and how much. Read from the item's own numbers, so the page can never say
## other than the game does.
func facts() -> Array[PackedStringArray]:
	return []


## A line of [method facts].
static func fact(what: String, how_much: String) -> PackedStringArray:
	return PackedStringArray([what, how_much])


## Seconds as the catalog says them: "3 s", "0.6 s".
static func seconds(value: float) -> String:
	return "%s s" % Joker.figure(value)


## Meters as the catalog says them: "8 m", "2.6 m".
static func meters(value: float) -> String:
	return "%s m" % Joker.figure(value)


## A factor as a change in percent: 1.5 is "+50%", 0.8 is "-20%".
static func percent(factor: float) -> String:
	var change := roundi((factor - 1.0) * 100.0)
	return "%s%d%%" % ["+" if change >= 0 else "", change]
