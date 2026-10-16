class_name StoryFill
extends RefCounted
## Fills in the placeholders of the story's lines, STORY.md 6: what the House knows about the
## player, from their profile, and what it saw at a table, from the match when there is one. Every
## number is printed the way the House prints numbers, with its thousands set apart.

## Every placeholder a line of the story may hold.
const KEYS: Array[String] = [
	"name",
	"license",
	"minutes",
	"maps",
	"hands",
	"accepted",
	"deaths",
	"chips_lost",
	"drifted_km",
	"trait",
	"shifts",
	"place",
	"models",
	"deviation",
	"date",
	"licensed",
	"invitation",
	"declined",
	"offered",
	"beaten",
	"raised",
	"prediction",
	"since",
	"profile",
]
## What a license number reads before there is one.
const LEARNER := "LEARNER"
## The House's profile of the player after the ending, STORY.md 8.6: the most it ever reads, how
## much of what is left each shift closes, and how far back each bet off the books or card of Kit's
## knocks it.
const PROFILE_MOST := 99.9
const SHIFT_CLOSES := 0.04
const KNOCKED_BACK := 1.5


## [param text] with each placeholder filled in for [param profile]; [param table] gives the ones
## only a match knows, the trait, the place, the models and the deviation, and may override any.
static func fill(text: String, profile: Profile, table: Dictionary = {}) -> String:
	if not text.contains("{"):
		return text
	var values := values_for(profile)
	# A line the House prints in capitals has the name in capitals too; one in the game's own case
	# has it as its player wrote it.
	if not _in_capitals(text):
		values["name"] = written_name(profile)
	for key: Variant in table:
		values[str(key)] = str(table[key])
	var filled := text
	for key: String in values:
		filled = filled.replace("{%s}" % key, str(values[key]))
	return filled


## What every placeholder a profile can answer reads for [param profile].
static func values_for(profile: Profile) -> Dictionary:
	var story := profile.story
	return {
		"name": name_of(profile),
		"license": profile.license_number if not profile.license_number.is_empty() else LEARNER,
		"minutes": number(Story.minutes(profile)),
		"maps": number(story.maps),
		"hands": number(story.maps + story.deaths),
		"accepted": number(accepted_of(profile)),
		"declined": number(story.declined),
		"offered": number(accepted_of(profile) + story.declined),
		"deaths": number(roundi(LifetimeStats.value_of(profile, &"deaths"))),
		"chips_lost": number(roundi(LifetimeStats.value_of(profile, &"coins_lost"))),
		"drifted_km": "%.1f" % (LifetimeStats.value_of(profile, &"drifted") / 1000.0),
		"shifts": number(story.shifts),
		"date": LicenseCard.today(),
		"licensed":
		profile.license_date if not profile.license_date.is_empty() else LicenseCard.today(),
		"invitation": story.invitation,
		"since": number(story.since),
		"profile": "%.1f" % profile_share(profile),
	}


## How much of [param profile]'s player the House can predict after the ending, in percent,
## STORY.md 8.6: from 100 less the Final Hand's deviation, each shift closing 4% of what is left,
## each bet won off the books and each of Kit's cards taken knocking it back a point and a half;
## never over 99.9.
static func profile_share(profile: Profile) -> float:
	var story := profile.story
	var deviation := story.deviation
	if deviation <= 0:
		deviation = FinalHand.deviation_kept(story.evaluation)
	var start := clampf(100.0 - float(deviation), 0.0, PROFILE_MOST)
	var share := 100.0 - (100.0 - start) * pow(1.0 - SHIFT_CLOSES, float(story.shifts))
	share -= KNOCKED_BACK * float(off_the_books(profile) + story.kit_cards.size())
	return clampf(share, 0.0, PROFILE_MOST)


## How many bets of the loyalty program's roads off the books [param profile] has won, GAME.md 8.9.
static func off_the_books(profile: Profile) -> int:
	var count := 0
	for id: String in profile.loyalty.won:
		var landmark := Loyalty.map().landmark(StringName(id))
		if landmark != null and landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS:
			count += 1
	return count


## Times [param profile] has accepted the House's terms, STORY.md 6: the invitation and the
## enrollment, then every map's seat, every joker of the House's taken, every coming back, and the
## Final Hand's amendments.
static func accepted_of(profile: Profile) -> int:
	var story := profile.story
	var before := (1 if story.invited else 0) + (0 if profile.license_number.is_empty() else 1)
	return before + story.maps + story.jokers + story.deaths + story.amendments


## The name on the profile's license, or the profile's own name before there is one, in capitals as
## the House prints a name.
static func name_of(profile: Profile) -> String:
	return written_name(profile).to_upper()


## The same name as its player wrote it.
static func written_name(profile: Profile) -> String:
	var name := profile.license_holder
	if name.is_empty():
		name = profile.display_name()
	return name


## Whether [param text], its placeholders aside, is printed in capitals.
static func _in_capitals(text: String) -> bool:
	var bare := text
	while bare.contains("{") and bare.contains("}"):
		var from := bare.find("{")
		var to := bare.find("}", from)
		if to < 0:
			break
		bare = bare.substr(0, from) + bare.substr(to + 1)
	# A line with no letters of its own, a hoarding's headline that is only the name, is the
	# House's and in capitals.
	return bare == bare.to_upper()


## [param value] with its thousands set apart, as the House prints a count: 1,204,388.
static func number(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	while digits.length() > 3:
		grouped = "," + digits.substr(digits.length() - 3) + grouped
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if value < 0 else "") + digits + grouped


## A place as the House prints it: 1ST, 2ND, 3RD, 4TH and on.
static func ordinal(place: int) -> String:
	var tail := "TH"
	if place % 100 < 11 or place % 100 > 13:
		match place % 10:
			1:
				tail = "ST"
			2:
				tail = "ND"
			3:
				tail = "RD"
	return "%d%s" % [place, tail]
