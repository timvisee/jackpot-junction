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
## the license, and where the Final Hand is due, STORY.md 5.1. The pace of the whole story is these
## numbers, kept together to be tuned.
const STAGE_STARTS: Array[float] = [0.0, 600.0, 2400.0, 4500.0, 6600.0]
const FINAL_HAND_AT := 9600.0

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


## The debug build's story arguments, see the static variables. Nothing in a released game.
static func read_arguments(args: PackedStringArray) -> void:
	if not OS.is_debug_build():
		return
	for arg: String in args:
		if arg.begins_with("--story-stage="):
			override = clampi(int(arg.get_slice("=", 1)), Stage.CUSTOMER, Stage.OPERATOR)
		elif arg == "--story-final-hand":
			final_hand_now = true
		elif arg.begins_with("--story-note="):
			note_now = int(arg.get_slice("=", 1))


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
	if final_hand_due(profile):
		line += ", Final Hand due"
	return line


static func _gained(slot: PlayerSlot, since: Dictionary, key: StringName) -> int:
	return maxi(roundi(slot.stats.value(key) - float(since.get(key, 0.0))), 0)
