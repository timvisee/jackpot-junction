class_name KitCards
extends RefCounted
## Kit's cards, STORY.md 6.3 and GAME.md 3.7: five cards in the House's deck that the House did not
## print, each one of its cards painted over in Kit's pencil. In every machine's catalog, so any
## machine can read one, but never dealt by a deck, never on the floor and of no suit. The host
## deals one in place of one of the House's in a pick, for a seat whose profile has found its first
## note with the story on: one pick in five, at most once a map, the five in order the first time
## and then any of them, one pick in three after the ending; never at the Final Hand and never to a
## bot. What a seat may be dealt reaches the host as one flag a seat, as the loyalty program's
## unlocks do, see [method flag_of].

## The five, in the order they are first dealt.
const IDS: Array[StringName] = [
	&"brake_check", &"not_today", &"blind_spot", &"loose_change", &"under_the_table"
]
## Where each is kept in the folder's pocket the first time it is taken, STORY.md 7.2: a page of
## the back's, numbered from this one down in [constant IDS]' order, see [FolderBack].
const FIRST_PAGE := -21
## How long the hoardings show the House's own green screen when one is taken, in seconds, and its
## green.
const FLASH := 1.0
const FLASH_GREEN := Color(0.18, 0.62, 0.3)
## One pick in this many holds one of Kit's, before the ending and after it.
const ONE_IN := 5
const ONE_IN_AFTER := 3
## What the flag says of a profile after the ending, beside how many of the five it has taken.
const ENDED := "ended"
## Kit's pencil: on a card's painted-over face, and light enough to read on the HUD's dark.
const PENCIL := Color(0.29, 0.29, 0.31)
const PENCIL_LIGHT := Color(0.8, 0.79, 0.76)
## The paint a card of the House's was painted over with, and its graph paper's squares.
const PAINTED := Color(0.86, 0.85, 0.81)
const SQUARES := Color(0.55, 0.62, 0.68, 0.35)


## What [param profile] tells a host of Kit's cards, STORY.md 5.3: nothing where it may not have
## them, and otherwise how many of the five it has taken and whether its story has ended.
static func flag_of(profile: Profile) -> PackedStringArray:
	if profile == null or not profile.story.on or profile.story.story_notes() <= 0:
		return PackedStringArray()
	var flag := PackedStringArray([str(clampi(profile.story.kit_cards.size(), 0, IDS.size()))])
	if profile.story.ended():
		flag.append(ENDED)
	return flag


## What [param slot]'s owner may be dealt, as [method flag_of] says it: a seat here its profile's,
## and at a host a client's seat what that client told it; nothing for a bot or anybody else.
static func flag_for(slot: PlayerSlot) -> PackedStringArray:
	if slot == null or slot.input is BotInput or slot.bot_trait != null:
		return PackedStringArray()
	var player := slot.input as PlayerInput
	if player != null and player.seat >= 0:
		var profile := MatchRecord.profile_of(slot)
		return flag_of(profile if profile != null else Game.settings.profile)
	var session := Net.session
	if session == null or not session.is_host or session.door == null:
		return PackedStringArray()
	var told: Dictionary = session.door.unlocks.get(session._peer_slots.peer_at(slot.index), {})
	var said: Variant = told.get("kit", PackedStringArray())
	return PackedStringArray(said) if said is PackedStringArray or said is Array else []


## The card of Kit's to deal [param slot] in a pick at [param match_node], or null: the host's to
## say, a seat that may have them, never at the Final Hand, at most once a map, by the odds.
static func deal_for(match_node: Match, slot: PlayerSlot) -> Joker:
	if match_node.puppet or match_node.rules.final_hand or Story.final_hand_on:
		return null
	var flag := flag_for(slot)
	if flag.is_empty():
		return null
	var dealt: Dictionary = match_node.get_meta(&"kit_dealt", {})
	if dealt.has(slot.index):
		return null
	var one_in := ONE_IN_AFTER if ENDED in flag else ONE_IN
	if match_node.rng.randi_range(1, one_in) != 1:
		return null
	var taken := clampi(int(flag[0]), 0, IDS.size())
	var id := IDS[taken] if taken < IDS.size() else IDS[match_node.rng.randi_range(0, 4)]
	if slot.kart != null and slot.kart.jokers.has(id):
		return null
	var card := match_node.joker_catalog.by_id(id)
	if card == null:
		return null
	dealt[slot.index] = true
	match_node.set_meta(&"kit_dealt", dealt)
	return card


## [param choices] with one of the House's cards swapped for [param card] of Kit's, anywhere in it.
static func swap_in(choices: Array[Joker], card: Joker, rng: RandomNumberGenerator) -> void:
	if card == null or choices.is_empty():
		return
	choices[rng.randi_range(0, choices.size() - 1)] = card


## Whether [param kart] holds Kit's card [param id].
static func holds(kart: Kart, id: StringName) -> bool:
	return kart != null and kart.jokers != null and kart.jokers.has(id)


## Whether [param slot]'s banked score is off the standings, Under the Table, until the whistle.
static func off_the_board(match_node: Match, slot: PlayerSlot) -> bool:
	return (
		match_node.state != Match.State.RESULTS
		and slot.kart != null
		and holds(slot.kart, &"under_the_table")
	)


## The folder's page for Kit's card [param id], see [constant FIRST_PAGE].
static func page_of(id: StringName) -> int:
	return FIRST_PAGE - IDS.find(id)


## Whether [param number] is the folder's page for one of Kit's cards.
static func is_page(number: int) -> bool:
	return number <= FIRST_PAGE and number > FIRST_PAGE - IDS.size()


## The card of folder page [param number], see [method page_of], or null.
static func card_of(number: int) -> Joker:
	if not is_page(number):
		return null
	var catalog := load(Achievements.JOKERS_PATH) as JokerCatalog
	return catalog.by_id(IDS[FIRST_PAGE - number]) if catalog != null else null


## Kit's card [param id] taken at [param slot] of [param match_node], heard where it was taken: for
## a player at this machine, the hoardings show the House's own green screen for a second, and the
## first time, the card goes into the folder's pocket and is kept with the profile, STORY.md 6.3.
static func taken(match_node: Match, slot: PlayerSlot, id: StringName) -> void:
	if id not in IDS or not slot.is_local_human():
		return
	var profile := MatchRecord.profile_of(slot)
	if profile == null or not profile.story.on:
		return
	if match_node.arena != null:
		flash(match_node.arena)
	if String(id) in profile.story.kit_cards:
		return
	profile.story.kit_cards.append(String(id))
	Achievements.arrive(profile)
	if not Game.is_headless():
		Game.settings.save_to_disk()
	# A host hears of it, so the next of the five is the one it deals.
	if Net.online() and Net.session != null and not Net.session.is_host:
		Net.session.host_controls.tell_unlocks()


## Both hoardings of [param arena] showing what the House shows itself for a second, the Count
## Room's green screen and HUMAN OVERSIGHT: 0, and then their advertising again.
static func flash(arena: Arena) -> void:
	if arena.billboards == null:
		return
	for node: Node in arena.billboards.get_children():
		var board := node as Billboard
		if board == null or board.face == null:
			continue
		var screen := board.panel(
			Vector2.ZERO, Vector2(Billboard.WIDTH, Billboard.HEIGHT), FLASH_GREEN, true
		)
		screen.position.z = 0.09
		var said := board.words(StoryLines.MONITOR, Vector2.ZERO, 0.5, Color(0.02, 0.06, 0.03))
		said.position.z = 0.12
		var gone := screen.get_tree().create_timer(FLASH, false)
		gone.timeout.connect(
			func() -> void:
				if is_instance_valid(screen):
					screen.queue_free()
				if is_instance_valid(said):
					said.queue_free()
		)
