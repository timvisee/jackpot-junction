class_name MatchPoint
extends RefCounted
## Who has just reached match point, GAME.md 3.4: a player whose next cash-out would win the match,
## the moment they get there. Called out on every screen, see [MatchHud], and counted on the host
## for the results, 3.8, each off one of these, so the count is the calls a player saw. Once, and
## not again for the same player for [constant AGAIN] seconds, so a pot that hovers on the line is
## one match point rather than a flicker of them.

const AGAIN := 10.0

## Who was at match point last tick, and when, on this one's own clock, each was last called.
var _could: Dictionary[int, bool] = {}
var _called: Dictionary[int, float] = {}
var _clock := 0.0


## One tick of [param match_node]: the slots that have reached match point in it.
func step(match_node: Match, delta: float) -> Array[int]:
	_clock += delta
	var reached: Array[int] = []
	if not match_node.is_running():
		_could.clear()
		return reached
	for slot: PlayerSlot in match_node.slots:
		# Nobody is told of a score off the standings, Under the Table's, STORY.md 6.3.
		var can := match_node.would_win(slot) and not KitCards.off_the_board(match_node, slot)
		# A team's is called once for the team, GAME.md 3.14, whichever of its karts gets there.
		var whose := slot.index if slot.team < 0 else -1 - slot.team
		if can and not _could.get(slot.index, false):
			var last: float = _called.get(whose, -AGAIN)
			if _clock - last >= AGAIN:
				_called[whose] = _clock
				reached.append(slot.index)
		_could[slot.index] = can
	return reached
