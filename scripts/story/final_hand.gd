class_name FinalHand
extends RefCounted
## The story's ending, STORY.md 8: when the House offers it, the table it sets, and who at that
## table it is watching. Dealt for one player, the House talking to them, and online played at
## every screen in the room, each for its own player, 8.1: the table goes over the wire with the
## rules, and the House's models with the plan of whoever has the say at a dedicated server.

## The Final Hand's match, STORY.md 8.2: House Rules for five minutes, all items and three bots.
const MAP := &"house_rules"
const SECONDS := 300.0
const ITEMS := "all"
const BOTS := 3
## The least each reading of [method deviation] is measured against, so a habit the models never
## had is not a division by nothing: an item a minute, a hundredth of the match on nitro, a
## hundredth of the distance drifted, a cash-out every two minutes.
const READING_FLOOR: Array[float] = [1.0, 0.01, 0.01, 0.5]
## The lifetime readings the models drive on, see [method BotMirror.hold_habits], and the longest
## name and the most parts of a dress a plan may carry for them.
const HABITS: Array[StringName] = [&"seconds", &"items", &"nitro", &"driven", &"drifted"]
const NAME_MOST := 32
## How many decisions the House puts out in a day, its own statements' rate, STORY.md 8.5: about
## forty-eight thousand a second, from the stamp on in the player's name.
const APPROVALS_A_DAY := 4118920113

## The slot of this screen's own player at the Final Hand, the candidate here, see
## [method candidate], or -1: kept by the [FinalHandTable] for whatever prints a name.
static var seat_index := -1
## What the House's forecasts of this screen's candidate came to at the Final Hand, STORY.md 8.4,
## see [HouseWatch]: the racks raised at them and the ones they got past, and how far off the
## forecasts were all told, each as a share of how far it had them going, and how many there were.
static var raised := 0
static var beaten := 0
static var off_by := 0.0
static var forecasts := 0


## Whether Play offers the Final Hand now, at a lobby on this machine alone: due for the profile
## playing and the story on there. Not now puts it off for that lobby alone, STORY.md 8.1: the
## next one Play opens asks again.
static func offered(profile: Profile) -> bool:
	return Story.on_here() and Story.final_hand_due(profile)


## The operator asks to re-sit the Final Hand, STORY.md 8.7: dealt again at the next lobby though
## the stamp is down, so its page can be torn off for Not This Time with their operator status kept.
static func resit(profile: Profile) -> void:
	profile.story.resit = true
	if not Game.is_headless():
		Game.settings.save_to_disk()


## [param config] set as the House sets the table: its match, the profile's last bot difficulty,
## and every other setting as GAME.md 3.8 starts it. Kept on this machine, see
## [member MatchConfig.final_hand].
static func set_table(config: MatchConfig, difficulty: String) -> void:
	var usual := MatchConfig.new()
	config.final_hand = true
	config.house = dealer(Game.settings.profile)
	config.map = MAP
	config.rounds = 0
	config.duration = SECONDS
	config.target_score = usual.target_score
	config.difficulty = difficulty
	config.item_set = ITEMS
	config.bot_count = BOTS
	config.own_bullets_hurt = usual.own_bullets_hurt
	config.overtime = usual.overtime
	config.teams = usual.teams
	config.friendly_fire = usual.friendly_fire
	config.joker_slots = usual.joker_slots
	config.small_maps = usual.small_maps


## [param config] set back as the match settings have it, as a lobby comes back from the Final
## Hand online, STORY.md 8.6: the House's table played, the next match is the room's own again.
static func clear_table(config: MatchConfig) -> void:
	var usual := MatchConfig.from_settings(Game.settings)
	config.final_hand = false
	config.house = {}
	for field: StringName in [&"map", &"rounds", &"duration", &"target_score", &"difficulty"]:
		config.set(field, usual.get(field))
	for field: StringName in [&"item_set", &"bot_count", &"own_bullets_hurt", &"overtime"]:
		config.set(field, usual.get(field))
	for field: StringName in [&"teams", &"friendly_fire", &"joker_slots", &"small_maps"]:
		config.set(field, usual.get(field))


## Whom the House seats the bots as, STORY.md 8.2, the player [param profile] is: the name it
## writes, the dress of the first seat and the lifetime readings the models drive on.
static func dealer(profile: Profile) -> Dictionary:
	var habits := {}
	for reading: StringName in HABITS:
		habits[String(reading)] = float(profile.stats.get(reading, 0.0))
	return {
		"name": StoryFill.written_name(profile),
		"dress": Array(Game.settings.seat_style(0)),
		"habits": habits,
	}


## [param said], a [method dealer] off the wire, as far as it is one: a name cut short, a dress of
## numbers and readings of numbers; nothing else kept.
static func clean_dealer(said: Variant) -> Dictionary:
	var given := said as Dictionary if said is Dictionary else {}
	var dress: Array[int] = []
	var worn: Variant = given.get("dress", [])
	if worn is Array:
		for part: Variant in (worn as Array).slice(0, KartStyle.CHOICES.size()):
			dress.append(int(part) if part is int or part is float else 0)
	var habits := {}
	var read: Variant = given.get("habits", {})
	var readings := read as Dictionary if read is Dictionary else {}
	for reading: StringName in HABITS:
		var value: Variant = readings.get(String(reading), 0.0)
		habits[String(reading)] = maxf(float(value), 0.0) if value is int or value is float else 0.0
	return {
		"name": PlayerNames.clean(str(given.get("name", "")), NAME_MOST),
		"dress": dress,
		"habits": habits,
	}


## Whether [param slot] is the candidate's at this screen: its own player's, the first seat at this
## machine, at the Final Hand.
static func is_candidate(slot: PlayerSlot) -> bool:
	if not Story.final_hand_on or slot == null:
		return false
	if seat_index >= 0:
		return slot.index == seat_index
	var player := slot.input as PlayerInput
	return player != null and player.seat == 0


## The candidate's slot in [param match_node] at this screen, or null: its own player's, the first
## seat here, which at a client is the one the host gave it, see [member Match.local_slot].
static func candidate(match_node: Match) -> PlayerSlot:
	if not Story.final_hand_on:
		return null
	for slot: PlayerSlot in match_node.slots:
		var player := slot.input as PlayerInput
		if match_node.puppet and slot.index == match_node.local_slot and match_node.local_slot >= 0:
			return slot
		if not match_node.puppet and player != null and player.seat == 0:
			return slot
	return null


## What the House prints for [param slot] wherever it prints a name, STORY.md 8.2: CANDIDATE for
## the candidate at the Final Hand, the name otherwise.
static func name_of(slot: PlayerSlot) -> String:
	return StoryLines.CANDIDATE if is_candidate(slot) else slot.display_name()


## The deviation on an evaluation [param kept], in percent, or 0 for none.
static func deviation_kept(kept: Dictionary) -> int:
	for line: Variant in kept.get("lines", []):
		if line is Array and (line as Array).size() >= 2 and str(line[0]) == "DEVIATION FROM MODEL":
			return maxi(int(str(line[1]).get_slice("%", 0)), 0)
	return 0


## How many decisions have gone out in the player's name in [param seconds], at the House's rate.
static func approvals_in(seconds: float) -> int:
	return int(maxf(seconds, 0.0) * float(APPROVALS_A_DAY) / 86400.0)


## The House's count of its forecasts forgotten, for a Final Hand beginning.
static func forget_forecasts() -> void:
	raised = 0
	beaten = 0
	off_by = 0.0
	forecasts = 0


## How far, in percent, [param candidate] drove from the House's forecasts of them, STORY.md 8.4:
## on average how far from where it had them a second and a half on, as a share of how far it had
## them going, see [HouseWatch]. Where it forecast nothing, how far they drove from the models over
## the match: their items, nitro, drift and cash-outs set against the models' average, each by how
## far it sat from theirs. Never under 1, since nobody drives exactly as they are forecast.
static func deviation(match_node: Match, candidate: PlayerSlot) -> int:
	if forecasts > 0:
		return clampi(roundi(off_by / float(forecasts) * 100.0), 1, 999)
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
	table["raised"] = str(raised)
	table["beaten"] = str(beaten)
	table["prediction"] = prediction(profile)
	var lines: Array[Array] = []
	for line: Array in StoryLines.EVALUATION:
		lines.append([str(line[0]), StoryFill.fill(str(line[1]), profile, table)])
	return lines


## The House's forecast of [param profile]'s stamp, STORY.md 8.4: the first time WILL STAMP, as sure
## as the terms accepted are of the terms offered, (accepted + 1) / (offered + 2); once the page has
## been torn off, from the Final Hands alone, WILL NOT STAMP, as sure as the tears are of the times
## the page was answered, (tears + 1) / (answers + 2). In percent to one decimal.
static func prediction(profile: Profile) -> String:
	var story := profile.story
	if story.tears <= 0:
		var accepted := StoryFill.accepted_of(profile)
		var offered := accepted + story.declined
		return StoryLines.PREDICT_STAMP % percent(accepted + 1, offered + 2)
	return StoryLines.PREDICT_NOT % percent(story.tears + 1, story.tears + 2)


## [param part] of [param whole] in percent, to one decimal, never quite 100.
static func percent(part: int, whole: int) -> String:
	var share := float(part) / float(maxi(whole, 1)) * 100.0
	return "%.1f" % minf(share, 99.9)


## The House's verdict on its own forecast as the stamp lands on [param profile]'s page, STORY.md
## 8.4: CORRECT where it forecast the stamp, and INCORRECT, its model updated, where it forecast
## the page torn off again.
static func verdict(profile: Profile) -> String:
	if profile.story.tears <= 0:
		var accepted := StoryFill.accepted_of(profile)
		var offered := accepted + profile.story.declined
		return StoryLines.PREDICTED_RIGHT % percent(accepted + 1, offered + 2)
	return StoryLines.PREDICTED_WRONG


## The page torn off, STORY.md 8.4: noted and counted, one more term declined, kept for the folder
## with its STATUS blank, 7.2, and Not This Time earned, 8.7; the Final Hand still due, and asked
## for again. Written into [param profile] and saved there and then.
static func decline(profile: Profile, lines: Array[Array], date: String) -> void:
	profile.story.tears += 1
	profile.story.declined += 1
	profile.story.torn = {"date": date, "lines": lines}
	profile.story.resit = false
	Achievements.arrive(profile)
	if not Game.is_headless():
		Game.settings.save_to_disk()


## The stamp come down, STORY.md 8.4 and 8.7: the Final Hand played, the day and the clock it was
## played at, and what the evaluation said, kept for the folder, written into [param profile] and
## saved there and then. Terms Accepted.
static func stamp_down(profile: Profile, lines: Array[Array], date: String) -> void:
	profile.story.final_hand = date
	profile.story.final_seconds = profile.story.seconds
	profile.story.evaluation = {"date": date, "lines": lines}
	profile.story.stamped_at = Time.get_unix_time_from_system()
	profile.story.deviation = deviation_kept(profile.story.evaluation)
	profile.story.resit = false
	if not Game.is_headless():
		Game.settings.save_to_disk()
