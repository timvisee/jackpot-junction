class_name FinalHand
extends RefCounted
## The story's ending, STORY.md 8: when the House offers it, the table it sets, and who at that
## table it is watching. The Final Hand is one machine's, the House talking to one player: it is
## never dealt online, and nothing of it goes over the wire.

## The Final Hand's match, STORY.md 8.2: House Rules for five minutes, all items and three bots.
const MAP := &"house_rules"
const SECONDS := 300.0
const ITEMS := "all"
const BOTS := 3
## The least each reading of [method deviation] is measured against, so a habit the models never
## had is not a division by nothing: an item a minute, a hundredth of the match on nitro, a
## hundredth of the distance drifted, a cash-out every two minutes.
const READING_FLOOR: Array[float] = [1.0, 0.01, 0.01, 0.5]

## Not now, for as long as the game runs: the House does not ask again until it is next started,
## STORY.md 8.1. The flyer stays.
static var declined := false


## Whether Play offers the Final Hand now, at a lobby on this machine alone: due for the profile
## playing, the story on there, and not put off this session.
static func offered(profile: Profile) -> bool:
	return not declined and Story.on_here() and Story.final_hand_due(profile)


## [param config] set as the House sets the table: its match, the profile's last bot difficulty,
## and every other setting as GAME.md 3.8 starts it. Kept on this machine, see
## [member MatchConfig.final_hand].
static func set_table(config: MatchConfig, difficulty: String) -> void:
	var usual := MatchConfig.new()
	config.final_hand = true
	config.map = MAP
	config.rounds = 0
	config.duration = SECONDS
	config.target_score = usual.target_score
	config.difficulty = difficulty
	config.item_set = ITEMS
	config.bot_count = BOTS
	config.own_bullets_hurt = usual.own_bullets_hurt
	config.overtime = usual.overtime
	config.joker_slots = usual.joker_slots
	config.small_maps = usual.small_maps


## Whether [param slot] is the candidate's: the seat of the profile playing, the first at this
## machine, at the Final Hand.
static func is_candidate(slot: PlayerSlot) -> bool:
	if not Story.final_hand_on or slot == null:
		return false
	var player := slot.input as PlayerInput
	return player != null and player.seat == 0


## The candidate's slot in [param match_node], or null.
static func candidate(match_node: Match) -> PlayerSlot:
	for slot: PlayerSlot in match_node.slots:
		if is_candidate(slot):
			return slot
	return null


## What the House prints for [param slot] wherever it prints a name, STORY.md 8.2: CANDIDATE for
## the candidate at the Final Hand, the name otherwise.
static func name_of(slot: PlayerSlot) -> String:
	return StoryLines.CANDIDATE if is_candidate(slot) else slot.display_name()


## How far, in percent, [param candidate] drove from the models over the match, STORY.md 8.4: its
## items, nitro, drift and cash-outs set against their average on the same readings, each by how
## far it sat from theirs, never under 1, since nobody drives exactly like their own average.
static func deviation(match_node: Match, candidate: PlayerSlot) -> int:
	var minutes := maxf(match_node.rules.duration - match_node.time_left, 30.0) / 60.0
	var mine := _readings(candidate, minutes)
	var theirs: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var models := 0
	for slot: PlayerSlot in match_node.slots:
		if not slot.input is BotInput:
			continue
		models += 1
		var read := _readings(slot, minutes)
		for i: int in theirs.size():
			theirs[i] += read[i]
	if models == 0:
		return 1
	var apart := 0.0
	for i: int in theirs.size():
		var average := theirs[i] / float(models)
		apart += absf(mine[i] - average) / maxf(average, READING_FLOOR[i])
	return clampi(roundi(apart / float(theirs.size()) * 100.0), 1, 999)


## Items a minute, the share of the match on nitro, the share of the distance drifted, and
## cash-outs a minute.
static func _readings(slot: PlayerSlot, minutes: float) -> Array[float]:
	var stats := slot.stats
	var driven := maxf(stats.value(&"driven"), 1.0)
	return [
		stats.value(&"items") / minutes,
		stats.value(&"nitro") / (minutes * 60.0),
		stats.value(&"drifted") / driven,
		stats.value(&"banks") / minutes,
	]


## The evaluation's lines for [param match_node] at its whistle, filled in, STORY.md 8.4: each its
## label and its value, STATUS blank for the stamp.
static func evaluation(match_node: Match) -> Array[Array]:
	var lit := candidate(match_node)
	var profile := Game.settings.profile
	var table := {}
	if lit != null:
		var seconds := match_node.rules.duration - match_node.time_left
		table["place"] = StoryFill.ordinal(match_node.standings().find(lit) + 1)
		table["deviation"] = str(deviation(match_node, lit))
		table["trait"] = StorySlip.classify(lit.stats, lit.kills, seconds)
	var models := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.input is BotInput:
			models += 1
	table["models"] = str(models)
	var lines: Array[Array] = []
	for line: Array in StoryLines.EVALUATION:
		lines.append([str(line[0]), StoryFill.fill(str(line[1]), profile, table)])
	return lines


## The stamp come down, STORY.md 8.4 and 8.7: the Final Hand played, the day and the clock it was
## played at, and what the evaluation said, kept for the folder, written into [param profile] and
## saved there and then. Terms Accepted.
static func stamp_down(profile: Profile, lines: Array[Array], date: String) -> void:
	profile.story.final_hand = date
	profile.story.final_seconds = profile.story.seconds
	profile.story.evaluation = {"date": date, "lines": lines}
	if not Game.is_headless():
		Game.settings.save_to_disk()
