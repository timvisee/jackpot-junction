class_name FinalHandTable
extends Node
## The Final Hand's table, STORY.md 8.2 and 8.3, put down in the match by the match scene: the bots
## seated as the House's models of the player, the house watching the candidate from the first
## second and applauding together at the whistle, and the Final Hand said to be over as the match
## goes. The rig, the fireworks and the board at the whistle are [MatchEnd]'s and [LedClock]'s, who
## ask [FinalHand] whose they are.

var match_node: Match
var _seated := false
var _watching := false
var _applauded := false


static func add_to(in_match: Match) -> FinalHandTable:
	var table := FinalHandTable.new()
	table.name = "FinalHandTable"
	table.match_node = in_match
	in_match.add_child(table)
	return table


## The note the Final Hand lays down whatever the order, note 21, STORY.md 8.2, unless
## [param profile] has it already; 0 for the usual dealing anywhere else.
static func note_for(profile: Profile) -> int:
	if not Story.final_hand_on or profile.story.has_note(Story.FINAL_HAND_NOTE):
		return 0
	return Story.FINAL_HAND_NOTE


func _ready() -> void:
	Events.match_state_changed.connect(_on_state)


func _exit_tree() -> void:
	if Events.match_state_changed.is_connected(_on_state):
		Events.match_state_changed.disconnect(_on_state)
	Story.final_hand_on = false


func _process(_delta: float) -> void:
	if match_node == null or match_node.slots.is_empty():
		return
	if not _seated:
		seat_the_models()
	if not _watching and match_node.arena != null and match_node.arena.crowd != null:
		var candidate := FinalHand.candidate(match_node)
		if candidate != null and candidate.kart != null:
			match_node.arena.crowd.watch(candidate.kart)
			_watching = true


## The models, STORY.md 8.2: every bot named after the player and its seat, `{name} 2` on, in the
## player's own dress in a color of its own, wearing a plate drawn from that name as any bot's is,
## and driving from the first second on the profile's lifetime habits.
func seat_the_models() -> void:
	_seated = true
	var profile := Game.settings.profile
	var named := StoryFill.written_name(profile)
	var dress := Game.settings.seat_style(0)
	var seat := 2
	for slot: PlayerSlot in match_node.slots:
		if not slot.input is BotInput:
			continue
		slot.player_name = StoryLines.MODEL % [named, seat]
		seat += 1
		if not dress.is_empty():
			StyleStalls.dress(slot, dress)
		if slot.kart != null:
			var brain := slot.kart.get_node_or_null("Brain") as BotBrain
			var easy := brain == null or brain.difficulty == null or brain.difficulty.id == &"easy"
			if easy:
				KartVisuals.learner_plate(slot.kart)
			else:
				# Off a generator of its own, so it draws nothing the match's seed decides.
				var draw := RandomNumberGenerator.new()
				draw.seed = hash(slot.player_name)
				KartVisuals.license_plate(slot.kart, LicensePlate.for_bot(slot.player_name, draw))
	match_node.bot_mirror.hold_habits(profile.stats)


## The whistle: the whole house applauding the candidate together, STORY.md 8.3.
func _on_state(state: int) -> void:
	if state != Match.State.RESULTS or _applauded:
		return
	_applauded = true
	if match_node.arena != null and match_node.arena.crowd != null:
		match_node.arena.crowd.applaud()
