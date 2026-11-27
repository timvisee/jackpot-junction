class_name LicenseWire
extends RefCounted
## A driver license as it goes over the wire, GAME.md 10.8: each machine's own, the first seat's,
## its profile's, sent to the host, which tells everybody with the rest of who is in the game, for
## their Players and the payout slip to show it, see [method LicenseCard.from_wire]. What the card
## says but the story's marks: the House's stamp, the Operator's class and the scratched stripe
## would tell a player who has not got that far what is to come, so another's card never has them.
## Light, with nothing of the card in it, so a host reads one without building anything.

## The most a license may say, so one sent by anybody stays small: how long its words are, and how
## many endorsements and stamps it carries.
const WORD := 24
const MOST := 16
const MOST_CONES := 99
## The stamp for laps of the roundabout, as [constant LoyaltyCard.LAP] words it: the card's scene
## kept out of here, which a dedicated server loads with the host's controls.
const LAP := "LAP %d"


## This machine's license, the first seat's, as the card says it, see
## [method LicenseCard.from_settings]; empty without one, a learner having none to show.
static func here() -> Dictionary:
	return of_seat(0)


## The license of this machine's seat [param seat], as the card says it: the first seat's the
## profile playing's, and another's the profile linked to it, GAME.md 3.8; empty for a seat with no
## profile of its own, a guest's, and for a learner, who has none to show.
static func of_seat(seat: int) -> Dictionary:
	var settings := Game.settings
	if settings == null:
		return {}
	var profile := settings.profile if seat == 0 else settings.seat_profile(seat)
	if profile == null or not Story.licensed(profile):
		return {}
	var holder := profile.license_holder
	if holder.is_empty():
		holder = settings.seat_name(seat)
	var stamps := Loyalty.endorsements_of(profile)
	if profile.loyalty.laps > 0:
		stamps.append(LAP % profile.loyalty.laps)
	return {
		"name": holder,
		"number": profile.license_number,
		"issued": profile.license_date,
		"color": maxi(settings.seat_color(seat), 0),
		"style": PackedInt32Array(profile.kart_styles[0]),
		"earned": profile.license_endorsements,
		"supporter": settings.supporter_since if seat == 0 and Supporter.owned() else "",
		"stamps": stamps,
		"cones": profile.license_cones,
	}


## [param said], a license somebody sent, as far as one can say it: words cut short, numbers in
## range, lists not too long, anything else dropped; empty for nothing like one.
static func clean(said: Variant) -> Dictionary:
	if not said is Dictionary or str((said as Dictionary).get("number", "")).is_empty():
		return {}
	var given: Dictionary = said
	var style: Variant = given.get("style", [])
	return {
		"name": PlayerNames.clean(str(given.get("name", ""))),
		"number": str(given.get("number", "")).left(WORD),
		"issued": str(given.get("issued", "")).left(WORD),
		"color": clampi(int(given.get("color", 0)), 0, Palette.PLAYER_COLORS.size() - 1),
		"style": PackedInt32Array(style) if style is Array or style is PackedInt32Array else [],
		"earned": _words(given.get("earned", [])),
		"supporter": str(given.get("supporter", "")).left(WORD),
		"stamps": _words(given.get("stamps", [])),
		"cones": clampi(int(given.get("cones", 0)), 0, MOST_CONES),
	}


static func _words(said: Variant) -> PackedStringArray:
	var words := PackedStringArray()
	if said is Array or said is PackedStringArray:
		for each: Variant in said:
			if words.size() < MOST:
				words.append(str(each).left(WORD))
	return words
