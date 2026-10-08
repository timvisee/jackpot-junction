class_name Loyalty
extends RefCounted
## The rules of the loyalty program, GAME.md 8.9: when a landmark of its map is open, when its bet
## is met, and settling, which wins whatever is both. Everything counts all along, from a profile's
## first map, so a bet met while its landmark is closed is won the moment a road opens it. Settling
## is the one place anything is won: after a profile's statistics are written, as the program opens
## and as its card is activated.

## The program's map, GAME.md 8.9, The first map.
const MAP_PATH := "res://data/loyalty/map.tres"

static var _map: LoyaltyMap


## The program's map, read once.
static func map() -> LoyaltyMap:
	if _map == null:
		_map = load(MAP_PATH) as LoyaltyMap if ResourceLoader.exists(MAP_PATH) else null
		if _map == null:
			_map = LoyaltyMap.new()
	return _map


## Wins every landmark of [param profile]'s program that is open and whose bet is met, on [param on]
## or the program's map, again and again while one won opens another already met. Returns those won,
## in the order they were.
static func settle(profile: Profile, on: LoyaltyMap = null) -> Array[LoyaltyLandmark]:
	var drawn := on if on != null else map()
	var won: Array[LoyaltyLandmark] = []
	var more := true
	while more:
		more = false
		for each: LoyaltyLandmark in drawn.landmarks:
			if profile.loyalty.has_won(each.id):
				continue
			if is_open(profile, each, drawn) and is_met(profile, each):
				profile.loyalty.win(each.id)
				won.append(each)
				more = true
	return won


## Whether [param district] is on [param profile]'s map: off the books only with the story on and
## a note of it found, STORY.md 6.6b; the rest always.
static func district_open(profile: Profile, district: LoyaltyLandmark.District) -> bool:
	if district == LoyaltyLandmark.District.OFF_THE_BOOKS:
		return profile.story.on and not profile.story.notes.is_empty()
	return true


## Whether [param landmark] is open on [param profile]'s map [param drawn]: its district open, and
## either open from the start of it or a road into it won, every road for a keystone. A road from a
## district that is not on the map opens nothing and holds no keystone shut.
static func is_open(profile: Profile, landmark: LoyaltyLandmark, drawn: LoyaltyMap) -> bool:
	if not district_open(profile, landmark.district):
		return false
	if landmark.entry:
		return true
	var through := false
	for id: StringName in drawn.roads_of(landmark.id):
		var other := drawn.landmark(id)
		if other == null or not district_open(profile, other.district):
			continue
		if profile.loyalty.has_won(id):
			through = true
		elif landmark.keystone:
			return false
	return through


## Whether [param profile] has done what [param landmark]'s bet asks, open or not.
static func is_met(profile: Profile, landmark: LoyaltyLandmark) -> bool:
	var state := profile.loyalty
	match landmark.kind:
		LoyaltyLandmark.Kind.CARD:
			return state.welcomed
		LoyaltyLandmark.Kind.STAT:
			return LifetimeStats.value_of(profile, landmark.stat) >= landmark.count
		LoyaltyLandmark.Kind.FEAT:
			return state.has_feat(landmark.stat)
		LoyaltyLandmark.Kind.FIND:
			return state.has_found(landmark.id)
		LoyaltyLandmark.Kind.NOTES:
			return profile.story.on and profile.story.notes.size() >= int(landmark.count)
	return false
