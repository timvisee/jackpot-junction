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
	if recorded or not is_instance_valid(match_node) or not is_inside_tree():
		return
	var scene := get_tree().current_scene
	var here := scene != null and scene.is_ancestor_of(self) and not Game.is_headless()
	if here or anywhere:
		record(match_node.state == Match.State.RESULTS)


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
	var last := run != null and run.is_last()
	var standing: Array[PlayerSlot] = []
	if last:
		standing = run.standings(match_node.slots)
	var any := false
	for slot: PlayerSlot in match_node.slots:
		var profile := profile_of(slot)
		if profile == null:
			continue
		any = true
		if not maps or not whistled:
			LifetimeStats.add_play(profile, slot, seconds)
			continue
		LifetimeStats.add_map(profile, slot, not ranked.is_empty() and ranked[0] == slot, seconds)
		if last:
			LifetimeStats.add_grand_prix(profile, not standing.is_empty() and standing[0] == slot)
	if any:
		Game.settings.save_to_disk()


## Whose statistics [param slot]'s match goes into: the profile playing for the first seat at this
## machine, the one sat in at another seat here, and nobody's for a guest or a player elsewhere.
static func profile_of(slot: PlayerSlot) -> Profile:
	var here := slot.input as PlayerInput
	if here == null or here.seat < 0:
		return null
	return Game.settings.profile if here.seat == 0 else Game.settings.seat_profile(here.seat)
