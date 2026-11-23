class_name TableState
extends RefCounted
## One profile's table, GAME.md 3.17 and 8.9a: the cards the House has opened for it, the ones it
## turned face down in the match settings, and whether it plays Roulette, kept in a section of its
## own in the profile's file. Nothing in it goes over the wire: a match is told the table it plays,
## see [member MatchRules.table].
##
## The House opens a card a map, [method TableCards.opened_by], counted off the maps the profile has
## played to the whistle; [member early] holds the ones opened before their map. The cards kept are
## the ones turned off rather than on, so a card the House opens comes face up on a table that had
## every other card face up, and stays face down on the Penny table's, which has them all off.

const SECTION := "table"

## The cards opened early, from the match settings, before the House would have, 3.17.
var early := 0
## The cards turned face down in the match settings, of those opened.
var off := 0
## Whether each map deals its own cards, the Roulette preset of GAME.md 9.6.
var roulette := false
## The cards the House has told the profile of: on the payout slip's coupon, 8.9a, or by opening
## them early. A card opened and not yet told is told on the next slip.
var told := TableCards.FIRST
## The cards opened that have not yet been played at a map of this profile's own: shown NEW on the
## loading screen, 8.6, and pointed at once in the match.
var fresh := 0


## The cards opened for a profile that has played [param maps] maps to the whistle.
func opened(maps: float) -> int:
	return TableCards.opened_by(int(maps)) | early


## The table a profile that has played [param maps] maps sets out: every card opened, but the ones
## turned face down.
func table(maps: float) -> int:
	return opened(maps) & ~off


## Opens [param card] before the House would have, from the match settings, 3.17: told already,
## by the asking, and so never on a coupon.
func open_early(card: int) -> void:
	early |= TableCards.bit(card)
	told |= TableCards.bit(card)
	off &= ~TableCards.bit(card)
	fresh |= TableCards.bit(card)


## The cards opened by [param maps] maps that the House has not told of yet, now told, see
## [member told]; and now [member fresh] until played.
func tell(maps: float) -> int:
	var news := opened(maps) & ~told
	told |= news
	fresh |= news
	return news


## A map played at a table of [param table] at this profile's own: its fresh cards played.
func played(table: int) -> void:
	fresh &= ~table


func read(file: ConfigFile) -> void:
	early = int(file.get_value(SECTION, "early", early)) & TableCards.ALL
	off = int(file.get_value(SECTION, "off", off)) & TableCards.ALL
	roulette = bool(file.get_value(SECTION, "roulette", roulette))
	told = int(file.get_value(SECTION, "told", told)) & TableCards.ALL
	fresh = int(file.get_value(SECTION, "fresh", fresh)) & TableCards.ALL


func write(file: ConfigFile) -> void:
	file.set_value(SECTION, "early", early)
	file.set_value(SECTION, "off", off)
	file.set_value(SECTION, "roulette", roulette)
	file.set_value(SECTION, "told", told)
	file.set_value(SECTION, "fresh", fresh)
