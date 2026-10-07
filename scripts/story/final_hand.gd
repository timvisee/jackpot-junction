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
