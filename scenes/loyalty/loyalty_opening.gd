class_name LoyaltyOpening
extends RefCounted
## Where the loyalty program's map opens and what it shows as it does, GAME.md 8.9, see
## [LoyaltyDialog]: the cursor at the landmark it was asked for; at the roundabout while an
## edition is owed; at the slip road for the House's first look, see [LoyaltyTour]; at the first of
## the bets won since it was last shown, which it shows being won, see [LoyaltyReveal]; at what is
## pinned; where the cursor was left; or at the nearest open bet, never the slip road won long ago.

## Whether the map shows bets being won as it opens and the House shows the member round: never
## in a run nobody watches, as the welcome is never shown in one; a test may set it.
static var watched := DisplayServer.get_name() != "headless"

## Where the cursor stands, the bets shown being won, and whether the House's tour comes.
var start := &""
var showing: Array[StringName] = []
var touring := false


## Where [param of]'s map opens: asked for [param asked], none for none, the cursor left at
## [param left] last, [param welcoming] for the welcome opening it.
static func of(
	of_profile: Profile, asked: StringName, left: StringName, welcoming: bool
) -> LoyaltyOpening:
	var opening := LoyaltyOpening.new()
	if asked != &"":
		opening.start = asked
	elif of_profile.loyalty.owed > 0:
		opening.start = Loyalty.ROUNDABOUT
	elif watched and LoyaltyTour.due(of_profile, welcoming):
		opening.touring = true
		opening.showing = LoyaltyTour.showing(of_profile)
		opening.start = Loyalty.SLIP_ROAD
	else:
		var rest := resting(of_profile, left)
		if watched:
			opening.showing = LoyaltyReveal.due(of_profile, LoyaltyMapLayout.sheet_of_id(rest))
		opening.start = opening.showing[0] if not opening.showing.is_empty() else rest
	return opening


## Where [param of]'s map rests with nothing to show: what is pinned, where the cursor was left at
## [param left], the nearest open bet, or the slip road with nothing open at all.
static func resting(of_profile: Profile, left: StringName) -> StringName:
	var pinned := Loyalty.pinned_of(of_profile)
	if pinned != &"":
		return pinned
	var was := Loyalty.map().landmark(left)
	if left == Loyalty.ROUNDABOUT or (was != null and Loyalty.is_drawn(of_profile, was)):
		return left
	var nearest := Loyalty.nearest_open(of_profile)
	return nearest if nearest != &"" else Loyalty.SLIP_ROAD
