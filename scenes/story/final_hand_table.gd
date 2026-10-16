class_name FinalHandTable
extends Node
## The Final Hand's table, STORY.md 8.2 to 8.5, put down in the match by the match scene: the bots
## seated as the House's models of whoever it was dealt for, the House's forecast and what it does
## with it, see [HouseForecast] and [HouseWatch], the house applauding together at the whistle, the
## House's evaluation and stamp on the slip, the last lines after it, and the Final Hand said to be
## over as the match goes. The rig, the
## fireworks and the board at the whistle are [MatchEnd]'s and [LedClock]'s, who ask [FinalHand]
## whose they are. Online one is put down at every screen in the room, each its own player's,
## 8.1: the models seated where the bots are driven, and the rest played at each screen, or an
## ordinary match where the story is off; and each screen through is told [FinalHandRoll].

var match_node: Match
## The House's section on the slip, once the whistle has gone.
var evaluation: HouseEvaluation
## Whom the bots are seated as, see [method FinalHand.dealer].
var house := {}
## Whether this screen plays the Final Hand's own part, its own player the candidate: not where
## the story is off, nor at a dedicated server, where nobody plays at all.
var plays := true
## Whether the ending is for real here, STORY.md 8.1: the Final Hand due for the profile playing
## at this screen, which the stamp writes into; played through with nothing kept otherwise.
var due := false
## The House's forecast, at every screen, and what this screen shows of it, where it plays.
var forecast: HouseForecast
var watch: HouseWatch

var _seated := false
var _applauded := false


## The table in [param in_match], its models [param dealt_for], see [method FinalHand.dealer], or
## the profile playing's where the plan said none.
static func add_to(in_match: Match, dealt_for := {}) -> FinalHandTable:
	var table := FinalHandTable.new()
	table.name = "FinalHandTable"
	table.match_node = in_match
	table.house = dealt_for if not dealt_for.is_empty() else FinalHand.dealer(Game.settings.profile)
	table.plays = Story.final_hand_on and in_match.with_hud
	table.due = table.plays and Story.final_hand_due(Game.settings.profile)
	if Net.hosting():
		Net.session.final_hand.open()
	FinalHand.forget_forecasts()
	table.forecast = HouseForecast.add_to(in_match)
	if table.plays:
		table.watch = HouseWatch.add_to(in_match, table.forecast, table.due)
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
	FinalHand.seat_index = -1
	if is_instance_valid(forecast):
		forecast.queue_free()
	if is_instance_valid(watch):
		watch.queue_free()


func _process(_delta: float) -> void:
	if match_node == null or match_node.slots.is_empty():
		return
	# Where the bots are driven: their names, dress and plates reach a client with the rest.
	if not _seated and not match_node.puppet:
		seat_the_models()
	var candidate := FinalHand.candidate(match_node)
	FinalHand.seat_index = candidate.index if candidate != null else -1


## The models, STORY.md 8.2: every bot named after the player the table was dealt for and its
## seat, `{name} 2` on, in that player's own dress in a color of its own, wearing a plate drawn from
## that name as any bot's is, and driving from the first second on that player's lifetime habits.
func seat_the_models() -> void:
	_seated = true
	var named := str(house.get("name", ""))
	var dress := PackedInt32Array(house.get("dress", []))
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
	var habits := {}
	var read: Dictionary = house.get("habits", {})
	for reading: StringName in FinalHand.HABITS:
		habits[reading] = float(read.get(String(reading), 0.0))
	match_node.bot_mirror.hold_habits(habits)


## The whistle: the whole house applauding the candidate together, STORY.md 8.3, and the House's
## section on the slip, its stamp in place of the ways on, 8.4.
func _on_state(state: int) -> void:
	if state != Match.State.RESULTS or _applauded:
		return
	_applauded = true
	# Everything the House raised sinks and the line goes, 8.3, its forecasts counted as they stand.
	if watch != null:
		watch.finish()
	if match_node.arena != null and match_node.arena.crowd != null:
		# Turned to the candidate, whose kart it has been watching since observation, or from now
		# for a match over before then.
		var candidate := FinalHand.candidate(match_node)
		if candidate != null and candidate.kart != null and plays:
			match_node.arena.crowd.watch(candidate.kart)
		match_node.arena.crowd.applaud()
	if Net.hosting():
		Net.session.final_hand.begin()
	var slip: ResultsScreen = null
	if match_node.hud != null:
		slip = match_node.hud.get_node_or_null("Results") as ResultsScreen
	if plays and slip != null and FinalHand.candidate(match_node) != null:
		evaluation = HouseEvaluation.add_to(slip, match_node)
		evaluation.counts = due
		evaluation.finished.connect(_last_lines)
		# Torn off, this screen is through: no last lines, the House will ask again, 8.4.
		evaluation.torn_off.connect(_through)
		# Kit's folder beside the House's page, Kit's last note in it if it was taken, 7.2.
		if Game.settings.profile.story.story_notes() > 0:
			SlipFolder.add_to(match_node)
	else:
		_through()


## The last lines after the stamp, and online, once the license is put away, through, see
## [FinalHandRoll]: the room back to its lobby once everybody is, rather than this screen to the
## title, 8.6.
func _last_lines() -> void:
	var lines := LastLines.begin(match_node.get_parent(), Net.online())
	lines.finished.connect(_through)


func _through() -> void:
	if is_instance_valid(evaluation) and not evaluation.torn:
		evaluation.wait_for_the_others()
	if Net.online() and Net.session != null:
		Net.session.final_hand.through()
