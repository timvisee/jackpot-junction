class_name MatchRecord
extends Node
## Writes a match played to the whistle into the profile of the player at this machine, GAME.md
## 8.5, see [LifetimeStats]: the first seat's, whose profile is the one playing. Put up by
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


## Writes the match down for the first seat at this machine, if there is one, and saves.
func record() -> void:
	if recorded or not is_instance_valid(match_node):
		return
	recorded = true
	var slot := first_seat(match_node)
	if slot == null:
		return
	var profile := Game.settings.profile
	var ranked := match_node.standings()
	LifetimeStats.add_map(profile, slot, not ranked.is_empty() and ranked[0] == slot, seconds)
	var run := Game.grand_prix
	if run != null and run.is_last():
		var standing := run.standings(match_node.slots)
		LifetimeStats.add_grand_prix(profile, not standing.is_empty() and standing[0] == slot)
	Game.settings.save_to_disk()


## The slot of the first seat at this machine: whoever plays the profile playing.
static func first_seat(in_match: Match) -> PlayerSlot:
	for slot: PlayerSlot in in_match.slots:
		var here := slot.input as PlayerInput
		if here != null and here.seat == 0:
			return slot
	return null
