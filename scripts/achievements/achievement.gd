class_name Achievement
extends Resource
## One achievement, GAME.md 8.10: something worth having done once, earned in any order and at any
## time and paying nothing. What it asks is said in [member objective]; whether it is met is
## either read off what a profile keeps anyway, see [method Achievements.met], or a moment of a map
## heard by [AchievementRecord].

## Which of the list's groups it is in, in the order the list shows them.
enum Group { GETTING_STARTED, WINNING, TABLES, FIGHTING, HAND, COMPANY, CLUBHOUSE, STORY }

## What it is struck on, GAME.md 8.10: a commemorative chip whose color is its denomination, white
## for a first step or for company, red for a moment, green for a feat and black for the hardest and
## the longest; or, for the story's four, an enamel pin, the House's or Kit's.
enum Chip { WHITE, RED, GREEN, BLACK, HOUSE_PIN, KIT_PIN }

## Its name in the profile and, in capitals, on a store, which never changes.
@export var id: StringName
## What it is called in the list and on the toast.
@export var title := ""
## What it asks, in a line.
@export var objective := ""
@export var group := Group.GETTING_STARTED
@export var chip := Chip.WHITE
## Shown as Hidden achievement in the list until it is earned: the story's four alone.
@export var hidden := false
## Whether it has a bar of how far along it is, rather than either happening or not. What the bar
## counts to is the game's to say, see [method Achievements.progress]: every joker there is, every
## part of the dress, so the bar grows with the game.
@export var bar := false


## Whether it is one of the story's enamel pins rather than a chip.
func is_pin() -> bool:
	return chip == Chip.HOUSE_PIN or chip == Chip.KIT_PIN


## Its name on a store, GAME.md 8.10: the id in capitals.
func store_name() -> String:
	return String(id).to_upper()
