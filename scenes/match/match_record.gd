class_name MatchRecord
extends Node
## Writes a match played to the whistle into the profiles of the players at this machine, GAME.md
## 8.5, see [LifetimeStats]: the first seat's, whose profile is the one playing, and those of the
## seats other profiles sit in, 3.8, see [SeatLink]; a guest's go nowhere. Put up by
## [MatchScene] alone, so the driving school, the Garage and the lobby, which are rooms rather than
## matches, are never counted; and only at the whistle, so a match left before it counts for
## nothing. A moment after it rather than on it: on a client the last counts of the match arrive
## with the host's word that it is over, and the Grand Prix is scored on that same word.

## How long after the whistle the match is written down, in seconds.
const AFTER := 0.6

var match_node: Match
## How many seconds the match has run, clock going, while this machine watched it.
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
	Events.match_state_changed.connect(_on_state)


func _exit_tree() -> void:
	if Events.match_state_changed.is_connected(_on_state):
		Events.match_state_changed.disconnect(_on_state)


func _process(delta: float) -> void:
	if match_node != null and match_node.is_running():
		seconds += delta


func _on_state(state: int) -> void:
	if state == Match.State.RESULTS and not recorded:
		get_tree().create_timer(AFTER).timeout.connect(record)


## Writes the match down for every seat at this machine that has a profile, and saves.
func record() -> void:
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
