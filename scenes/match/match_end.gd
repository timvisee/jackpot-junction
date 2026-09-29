class_name MatchEnd
extends RefCounted
## How a match ends, GAME.md 3.13: sudden death once the clock runs out, the last kart standing
## taking what it carries, and the winner's lap of honor at the whistle. Kept out of [Match] the
## way [KartDeath] is, so that file stays about running a match.

## How long the fireworks go up for once a match is won, GAME.md 8.3: the pause the podium waits
## out and a while under the standings after it.
const CELEBRATION := 8.0


## Sudden death, GAME.md 3.13. Nobody respawns, so the field only shrinks; the last one left
## banks the lot and the whistle goes. Returns whether the match ended on this tick.
static func step_overtime(match_node: Match) -> bool:
	var standing := alive_slots(match_node)
	if standing.size() > 1:
		return false
	if standing.size() == 1:
		var winner := standing[0]
		var kart := winner.kart
		var won := Scoring.pot_value(kart.pot.coins, kart.pot.mult)
		if won > 0:
			winner.banked += won
			Events.death_banked.emit(winner.index, won)
		kart.pot.reset()
	match_node._finish()
	return true


## Every slot whose kart is still in play. A kart on its way down a pit is already gone.
static func alive_slots(match_node: Match) -> Array[PlayerSlot]:
	var standing: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null and slot.kart.alive and not slot.kart.falling:
			standing.append(slot)
	return standing


## GAME.md 8.1: at the whistle every head leaves its sweep and swings onto whoever won, so the
## winner takes their lap of honor in the spotlight. Whoever that is: a bot that has out-driven
## the room gets the rig the same as a player, and a leader lying in a pit at the whistle is
## still where the beams go, since what the rig follows is the top of the standings rather than
## whoever happens to be on their wheels. A client reaches the whistle by being told about it
## rather than by running one, and the lap of honor is for everybody, so it does this too.
static func spotlight(match_node: Match) -> void:
	var winner := match_node.standings()[0]
	if winner.kart != null:
		match_node.arena.disco.focus(winner.kart)
	# And the room throws fireworks in their color, GAME.md 8.3. For whoever won rather than
	# for the kart, which may well be lying in a pit at the whistle.
	Fireworks.celebrate(match_node, match_node.arena.bounds(), winner.color(), CELEBRATION)
	# And the camera lets the room back in, GAME.md 8.2, over the same pause the podium waits out
	# in 3.8: the karts have stopped being the subject, so the last thing the match does is open
	# out to the table it was played on.
	if match_node.camera_rig != null:
		match_node.camera_rig.show_the_room(MatchHud.PODIUM_DELAY)
