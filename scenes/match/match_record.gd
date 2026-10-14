class_name MatchRecord
extends Node
## Writes what the players at this machine did into their profiles, GAME.md 8.5, see
## [LifetimeStats]: the first seat's, whose profile is the one playing, and those of the seats
## other profiles sit in, 3.8, see [SeatLink]; a guest's go nowhere. A match played to the whistle
## counts as a map, won or not, a moment after the whistle: on a client the last counts of the
## match arrive with the host's word that it is over, and the Grand Prix is scored on that same
## word. Left before it, for the lobby, the title, out of the game or with the line to the host
## gone, what was done in it counts all the same, but no map; and so does a room that is no match,
## the lobby and the driving school, see [member maps], as it is left. Only the room the game is in
## writes, and never headless, so neither a test nor a smoke run writes the player's statistics.

## What [method Game.go_to_title] asks to write itself down, before the seats are guests again.
const GROUP := &"match_record"
## How long after the whistle the match is written down, in seconds.
const AFTER := 0.6

## For a test: a room left is written down wherever it is, headless or not, see [method leave].
static var anywhere := false

var match_node: Match
## Whether it counts as a map played, won or not: the lobby and the driving school are no
## matches, GAME.md 8.5, and count what was done in them alone, written as they are left.
var maps := true
## How many seconds of play went by here: the clock going in a match, any time in a room.
var seconds := 0.0
## Whether it has been written down, which happens once.
var recorded := false

## What each slot was last written down with, or held when somebody sat down in it, by its index:
## a player who got up in the middle of a room, and one who took over a kart that had been going
## before them, are counted from then on only, see [LifetimeStats.share_of].
var _since: Dictionary[int, Dictionary] = {}


static func add_to(in_match: Match) -> MatchRecord:
	var record := MatchRecord.new()
	record.name = "MatchRecord"
	record.match_node = in_match
	in_match.add_child(record)
	return record


func _ready() -> void:
	add_to_group(GROUP)
	Events.match_state_changed.connect(_on_state)


func _exit_tree() -> void:
	if Events.match_state_changed.is_connected(_on_state):
		Events.match_state_changed.disconnect(_on_state)
	leave()


func _process(delta: float) -> void:
	if match_node != null and (match_node.is_running() or not maps):
		seconds += delta


## The room is being left: written down now if it has not been, as a map if its whistle has gone.
## Only the room the game is in, and never headless, see the class.
func leave() -> void:
	if not recorded and _writes():
		record(match_node.state == Match.State.RESULTS)


## Somebody at this machine gets up from [param slot] in the middle of [param in_match], GAME.md
## 8.5: what they did is written into their profile there and then, the one sat in at their seat
## too, since the kart goes on without them. [param player] is who they were, when the slot no
## longer says.
static func seat_leaving(in_match: Match, slot: PlayerSlot, player: PlayerInput = null) -> void:
	var record := _of(in_match)
	if record == null or record.recorded or not record._writes():
		return
	var profile := profile_for(player if player != null else slot.input as PlayerInput)
	if profile == null:
		return
	var since: Dictionary = record._since.get(slot.index, {})
	if record.maps:
		Story.count(profile, slot, record.seconds, since, false, Game.grand_prix == null)
		if record.seconds > 0.0:
			profile.loyalty.end_run()
	LifetimeStats.add_play(profile, slot, record.seconds, since)
	record._since[slot.index] = LifetimeStats.share_of(slot, record.seconds)
	Loyalty.settle(profile)
	Game.settings.save_to_disk()


## Somebody sits down in [param slot] of [param in_match], a kart that may have been going before
## them: what it had done is somebody else's, see [member _since].
static func seat_taken(in_match: Match, slot: PlayerSlot) -> void:
	var record := _of(in_match)
	if record != null and not record.recorded:
		record._since[slot.index] = LifetimeStats.share_of(slot, record.seconds)


## What [param slot] of [param in_match] was last written down with, or held when somebody sat
## down in it, for counting what has been done in it since, see [member _since].
static func since_of(in_match: Match, slot: PlayerSlot) -> Dictionary:
	var record := _of(in_match)
	return record._since.get(slot.index, {}) if record != null else {}


static func _of(in_match: Match) -> MatchRecord:
	return in_match.get_node_or_null("MatchRecord") as MatchRecord if in_match != null else null


## Whether this room writes into the profiles: the room the game is in, never headless.
func _writes() -> bool:
	if not is_instance_valid(match_node) or not is_inside_tree():
		return false
	var scene := get_tree().current_scene
	var here := scene != null and scene.is_ancestor_of(self) and not Game.is_headless()
	return here or anywhere


func _on_state(state: int) -> void:
	if state == Match.State.RESULTS and maps and not recorded:
		get_tree().create_timer(AFTER).timeout.connect(record)


## Writes the match down for every seat at this machine that has a profile, and saves: as a map
## played when [param whistled] and it is a match, and otherwise what was done in it alone.
func record(whistled := true) -> void:
	if recorded or not is_instance_valid(match_node):
		return
	recorded = true
	var ranked := match_node.standings()
	var run := Game.grand_prix
	# A run that ends level is counted at its showdown rather than its last map, GAME.md 9.7a, since
	# only then is it known who won it; and the showdown is no map of the run.
	var showdown := match_node.rules.showdown()
	var last := run != null and run.is_last() and not run.needs_showdown()
	var standing: Array[PlayerSlot] = []
	if last:
		standing = run.standings(match_node.slots)
	var written: Array[Profile] = []
	for slot: PlayerSlot in match_node.slots:
		var profile := profile_of(slot)
		if profile == null:
			continue
		if profile not in written:
			written.append(profile)
		if showdown:
			if last and whistled:
				var champion := _first(standing[0], slot)
				LifetimeStats.add_grand_prix(profile, champion)
				if champion and run.showdown.has(slot.index):
					AchievementRecord.showdown_won(match_node, slot, profile)
			continue
		var since: Dictionary = _since.get(slot.index, {})
		# The story's clock runs on maps alone, STORY.md 5.1: never the lobby or the school.
		if maps:
			Story.count(profile, slot, seconds, since, whistled, run == null)
		if not maps or not whistled:
			# A map walked out of with its clock going is no map won, GAME.md 8.9.
			if maps and seconds > 0.0:
				profile.loyalty.end_run()
			LifetimeStats.add_play(profile, slot, seconds, since)
			continue
		# A map won in teams is won by every kart of the winning team, GAME.md 8.10.
		var won := not ranked.is_empty() and _first(ranked[0], slot)
		var share := seconds - float(since.get(LifetimeStats.SHARE_SECONDS, 0.0))
		LoyaltyRecord.map_played(match_node, slot, profile, share, since, won)
		AchievementRecord.map_played(match_node, slot, profile, won)
		LifetimeStats.add_map(profile, slot, won, seconds, since)
		if last:
			LifetimeStats.add_grand_prix(
				profile, not standing.is_empty() and _first(standing[0], slot)
			)
	# What the statistics now hold may win bets of the loyalty program, GAME.md 8.9, which the
	# payout slip's page of it reports, see [LoyaltyRecord].
	for profile: Profile in written:
		Loyalty.settle(profile)
	LoyaltyRecord.settled(match_node, written)
	AchievementRecord.settled(match_node, written)
	if not written.is_empty():
		Game.settings.save_to_disk()
		Loyalty.tell_host()


## Whether [param slot] came first where [param first] did: it is, or it is on its team, GAME.md
## 3.14.
static func _first(first: PlayerSlot, slot: PlayerSlot) -> bool:
	return first == slot or Teams.teammates(first, slot)


## Whose statistics [param slot]'s match goes into: the profile playing for the first seat at this
## machine, the one sat in at another seat here, and nobody's for a guest or a player elsewhere.
static func profile_of(slot: PlayerSlot) -> Profile:
	return profile_for(slot.input as PlayerInput)


## Whose statistics [param player]'s go into, by their seat, see [method profile_of].
static func profile_for(player: PlayerInput) -> Profile:
	if player == null or player.seat < 0:
		return null
	return Game.settings.profile if player.seat == 0 else Game.settings.seat_profile(player.seat)
