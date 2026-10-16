class_name Story
extends RefCounted
## The story under the casino, STORY.md: how far a profile is through it and what every screen at
## this machine should show of it. A profile moves through it by playing maps once it has a license,
## on a clock of its own, STORY.md 5.1; the words it prints are in [StoryLines], and what the
## profile keeps of it in [StoryState]. Nothing here changes a rule, STORY.md 2.

## The stages, each named for what the House calls the player in it, STORY.md 5.1.
enum Stage { CUSTOMER, PLAYER, PARTICIPANT, NUMBER, CANDIDATE, OPERATOR }

const NAMES: Array[String] = [
	"Customer", "Player", "Participant", "Number", "Candidate", "Operator"
]
## Where each stage up to the Candidate begins on the story's clock, in seconds of maps played since
## the license, and where the Final Hand is due, STORY.md 5.1: about two hours at the tables, the
## lobby, the picks and the slips counted. The pace of the whole story is these numbers, kept
## together to be tuned.
const STAGE_STARTS: Array[float] = [0.0, 300.0, 1320.0, 2700.0, 4320.0]
const FINAL_HAND_AT := 6000.0
## How many notes there are, STORY.md 7.3, the last of them the calendar's next page.
const NOTE_COUNT := 24
## The notes' pace, STORY.md 7.1, beside the stages' it keeps step with: each stage's first and last
## note, the first the Customer's own, the Final Hand's between the Candidate's and the Operator's;
## the map after the license the first is due in; how far apart the Operator's are on the clock; the
## chance a due note turns up in a map after the ending, and after how many maps without it turns up
## for certain, every due note before the ending turning up in its first map; and the part of a
## match it may turn up in, seconds after the flag and seconds before the clock runs out, the first
## note no later than a minute in.
const STAGE_NOTES: Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(2, 5),
	Vector2i(6, 10),
	Vector2i(11, 15),
	Vector2i(16, 20),
	Vector2i(22, 24),
]
const FINAL_HAND_NOTE := 21
const FIRST_NOTE_MAP := 1
const NOTE_EVERY_AFTER := 600.0
const NOTE_CHANCE := 0.5
const NOTE_CERTAIN_AFTER := 2
const NOTE_FROM := 20.0
const NOTE_BEFORE_END := 60.0
const FIRST_NOTE_BY := 60.0

## A stage shown whatever the profile has reached, for a test or `++ --story-stage=N` in a debug
## build, and -1 for none.
static var override := -1
## Whether the match being played at this machine is the Final Hand, STORY.md 8: set by the match
## for as long as it is, so what the House prints in it can say so.
static var final_hand_on := false
## For a debug build: `++ --story-final-hand` deals the Final Hand on the next Play, and
## `++ --story-note=N` lies note N on the next map's floor at once, see [method read_arguments].
static var final_hand_now := false
static var note_now := 0
## For a debug build: `++ --story-clock=SECONDS` reads the story's clock as that, for what moves
## with it rather than with the stage, and -1 for the profile's own.
static var clock_override := -1.0


## The stage [param profile] has reached, whether or not its story is on: the Customer until it has
## a license, the Operator once the stamp has come down, and otherwise by its clock.
static func stage_of(profile: Profile) -> int:
	if profile == null or not licensed(profile):
		return Stage.CUSTOMER
	if profile.story.ended():
		return Stage.OPERATOR
	var reached := Stage.CUSTOMER
	for stage: int in STAGE_STARTS.size():
		if profile.story.seconds >= STAGE_STARTS[stage]:
			reached = stage
	return reached


## The stage [param profile]'s screens show: the first with its story off, STORY.md 5.4.
static func shown_of(profile: Profile) -> int:
	if profile == null or not profile.story.on:
		return Stage.CUSTOMER
	return stage_of(profile)


## The stage every screen at this machine shows: the profile playing's, STORY.md 5.2, or the first
## when nothing is drawn, so no test and no server ever sees anything else unless it asks.
static func stage_here() -> int:
	if override >= 0:
		return clampi(override, Stage.CUSTOMER, Stage.OPERATOR)
	if Game.is_headless():
		return Stage.CUSTOMER
	return shown_of(Game.settings.profile)


## The story's clock at this machine, in seconds: the profile playing's.
static func clock_here() -> float:
	if clock_override >= 0.0:
		return clock_override
	return Game.settings.profile.story.seconds


## How much of their own place in the beat the crowd keeps at [param stage] with [param seconds] on
## the clock, STORY.md 6.9: all of it until the Candidate, then less with every map, none by the
## Final Hand, and none after it.
static func crowd_spread(stage: int, seconds: float) -> float:
	if stage < Stage.CANDIDATE:
		return 1.0
	if stage == Stage.OPERATOR:
		return 0.0
	var start := STAGE_STARTS[Stage.CANDIDATE]
	return clampf(1.0 - (seconds - start) / (FINAL_HAND_AT - start), 0.0, 1.0)


## Whether the story's marks before the license are shown at this machine, STORY.md 6.7: the quiz's
## fourth question and the license's scratches and fine print, for the profile playing while its
## story is on, licensed or not; never headless unless a test or a debug build asks.
static func told_here() -> bool:
	if override >= 0:
		return true
	if Game.is_headless():
		return false
	return Game.settings.profile.story.on


## Whether the story is going on at this machine at all: on, licensed and not headless.
static func on_here() -> bool:
	if override >= 0:
		return true
	if Game.is_headless():
		return false
	var profile := Game.settings.profile
	return profile.story.on and licensed(profile)


static func licensed(profile: Profile) -> bool:
	return not profile.license_number.is_empty()


## Whether [param profile]'s Final Hand is waiting to be played, STORY.md 8.1.
static func final_hand_due(profile: Profile) -> bool:
	if profile == null or not licensed(profile) or not profile.story.on or profile.story.ended():
		return false
	return final_hand_now or profile.story.seconds >= FINAL_HAND_AT


## The story's clock in whole minutes, as the House prints it.
static func minutes(profile: Profile) -> int:
	return floori(profile.story.seconds / 60.0)


## Counts a map, or the part of one [param slot] played, into [param profile]'s story: the clock and
## the counts behind the placeholders of STORY.md 6, only once licensed and with the story on, and
## only what came after [param since], as [LifetimeStats.share_of] holds it. [param whistled] for a
## map played to its whistle, and [param quick] for one that was no Grand Prix's.
static func count(
	profile: Profile,
	slot: PlayerSlot,
	seconds: float,
	since: Dictionary,
	whistled: bool,
	quick: bool,
) -> void:
	if profile == null or not licensed(profile) or not profile.story.on:
		return
	var story := profile.story
	story.seconds += maxf(seconds - float(since.get(LifetimeStats.SHARE_SECONDS, 0.0)), 0.0)
	story.deaths += _gained(slot, since, &"deaths")
	story.jokers += _gained(slot, since, &"jokers")
	if not whistled:
		return
	story.maps += 1
	if quick:
		story.quick_matches += 1
	if story.ended():
		story.shifts += 1


## The debug build's story arguments, see the static variables; `++ --story-license` and
## `++ --story-notes`, which license the profile playing in [param settings] and hand it every note
## at once, see [method hand_license] and [method hand_notes]; `++ --story-letter`, which shows the
## House's next letter owed at the title, see [StoryLetters]; and `++ --story-invitation`, which
## shows the invitation at the title again, or `++ --story-invitation=0`, which leaves it out for
## this run alone, see [OpeningInvitation]. Nothing in a released game.
static func read_arguments(args: PackedStringArray, settings: Settings) -> void:
	if not OS.is_debug_build():
		return
	for arg: String in args:
		if arg.begins_with("--story-stage="):
			override = clampi(int(arg.get_slice("=", 1)), Stage.CUSTOMER, Stage.OPERATOR)
		elif arg == "--story-final-hand":
			final_hand_now = true
		elif arg.begins_with("--story-note="):
			note_now = int(arg.get_slice("=", 1))
		elif arg.begins_with("--story-clock="):
			clock_override = maxf(float(arg.get_slice("=", 1)), 0.0)
		elif arg == "--story-license":
			hand_license(settings)
		elif arg == "--story-notes":
			hand_notes(settings)
		elif arg == "--story-letter":
			StoryLetters.again = true
		elif arg == "--story-invitation" or arg == "--story-invitation=1":
			OpeningInvitation.again = true
			OpeningInvitation.held_off = false
		elif arg == "--story-invitation=0":
			OpeningInvitation.held_off = true
			OpeningInvitation.again = false


## The profile playing in [param settings] licensed as passing the driving test would have, GAME.md
## 9.4a: numbered, dated today and in its first seat's name, or in a name picked for it the way the
## school's enrollment form suggests one, and kept, so a new profile's story starts and the other
## arguments have something to show. Nothing for a profile that has its license already.
static func hand_license(settings: Settings) -> void:
	if not settings.license_number.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var holder := settings.seat_name(0)
	if holder.is_empty():
		holder = PlayerNames.pick(rng)
		settings.set_seat_name(0, holder)
	settings.tutorial_done = true
	settings.license_number = LicenseCard.new_number(rng)
	settings.license_date = LicenseCard.today()
	settings.license_holder = holder
	settings.license_plate = LicensePlate.suggest(holder, settings.license_number)
	settings.save_to_disk()


## Every one of Kit's notes filed for the profile playing in [param settings] at once and kept, the
## ones it had not found yet new, so the folder can be read through from the first page to the
## last, STORY.md 7.2. Licensed first if it is not, since no note turns up before the license.
static func hand_notes(settings: Settings) -> void:
	hand_license(settings)
	for number: int in range(1, NOTE_COUNT + 1):
		StoryNotes.file(settings.profile, number)
	settings.save_to_disk()


## The story in a line for the F3 overlay of the profile playing.
static func debug_text() -> String:
	var profile := Game.settings.profile
	var stage := stage_here()
	var line := (
		"story %s (%d) %d min, %d notes"
		% [NAMES[stage], stage, minutes(profile), profile.story.notes.size()]
	)
	if not profile.story.on:
		line += ", off"
	var next := StoryNotes.next_of(profile.story)
	if next == 1:
		line += ", next note 1 in map %d" % FIRST_NOTE_MAP
	elif next > 0:
		var due := StoryNotes.due_at(next, profile.story) / 60.0
		line += ", next note %d at %d min" % [next, floori(due)]
	if final_hand_due(profile):
		line += ", Final Hand due"
	return line


static func _gained(slot: PlayerSlot, since: Dictionary, key: StringName) -> int:
	return maxi(roundi(slot.stats.value(key) - float(since.get(key, 0.0))), 0)
