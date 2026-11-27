class_name BotLicense
extends RefCounted
## A bot's driver license, GAME.md 9.4a: every bot that holds one, the easiest being learners with
## the L, 4.4, shows it on the payout slip behind the robot after its name, 3.8. Made up at each
## screen from what every screen knows of the bot, its name, trait, color and dress, and drawn from
## its name, so a bot shows the same card wherever it is looked at and nothing goes over the wire
## for it; the card itself is [method LicenseCard.for_bot]'s. The story reaches it twice, never
## ahead of the player, STORY.md 3.6: once the note that tells what the bots are has been read, the
## House's MODEL stamp is on its back; and at the Final Hand a model's card is the player's own.

## The note that tells what the bots are, STORY.md 7.3: the mirror.
const MIRROR_NOTE := 14
## How many participants the MODEL stamp says a bot is averaged from, at least and at most.
const AVERAGED_LEAST := 1200
const AVERAGED_MOST := 48000
## The serial number's shape, and the years a bot's card is issued in.
const NUMBER := "B-%04d-%04d"
const FIRST_YEAR := 2019
const LAST_YEAR := 2025


## The card of the bot in [param slot], as [method LicenseCard.for_bot] takes it, or at the Final
## Hand the player's own under a model's name, as [method LicenseCard.from_wire] takes it; empty for
## anybody but a bot, and for a learner, who has none.
static func of(slot: PlayerSlot) -> Dictionary:
	if slot == null or slot.is_human() or slot.is_dummy():
		return {}
	var modeled := _model_of_mine(slot)
	if not modeled.is_empty():
		return modeled
	if KartVisuals.plate_worn(slot.kart) == "L":
		return {}
	var named := slot.display_name()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(named)
	var earned := PackedStringArray()
	if slot.bot_trait != null:
		earned.append(slot.bot_trait.display_name.to_upper())
	var number := NUMBER % [rng.randi_range(0, 9999), rng.randi_range(0, 9999)]
	var year := rng.randi_range(FIRST_YEAR, LAST_YEAR)
	var issued := "%04d-%02d-%02d" % [year, rng.randi_range(1, 12), rng.randi_range(1, 28)]
	var averaged := rng.randi_range(AVERAGED_LEAST, AVERAGED_MOST)
	var stamps := PackedStringArray()
	if mirror_read():
		stamps.append(StoryLines.BOT_MODEL % Loyalty.thousands(averaged))
	return {
		"bot": true,
		"name": named,
		"number": number,
		"issued": issued,
		"color": slot.paint_index(),
		"style": slot.style.to_array(),
		"earned": earned,
		"stamps": stamps,
	}


## Whether the player here has read the mirror's note with the story on, STORY.md 7.3.
static func mirror_read() -> bool:
	if not Story.on_here():
		return false
	var notes := Game.settings.profile.story
	return notes.has_note(MIRROR_NOTE) and not notes.is_new(MIRROR_NOTE)


## At the Final Hand, a model seated as the player here, STORY.md 8.2: its card the player's own,
## the name the model's and the number with its seat after it, the kart in the photo its own; empty
## for any other bot, a model seated as somebody at another screen among them.
static func _model_of_mine(slot: PlayerSlot) -> Dictionary:
	if not Story.final_hand_on:
		return {}
	var mine := LicenseWire.here()
	var written := StoryFill.written_name(Game.settings.profile) + " "
	var named := slot.display_name()
	var seat := named.trim_prefix(written)
	if mine.is_empty() or not named.begins_with(written) or not seat.is_valid_int():
		return {}
	mine["name"] = named
	mine["number"] = "%s-%s" % [mine["number"], seat]
	mine["color"] = slot.paint_index()
	mine["style"] = slot.style.to_array()
	return mine
