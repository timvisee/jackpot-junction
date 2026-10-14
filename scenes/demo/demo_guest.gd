class_name DemoGuest
extends RefCounted
## The profile a visitor plays the full game on, leaving the demo for a booth, GAME.md 9.8: a new
## player's in everything a new player is shown, but with a head start on the loyalty program, so a
## machine nobody has played on does not show them an empty one either. Its card is activated, and
## the landmarks nearest the slip road on the Strip and in the Department are won, about a third of
## the program and no keystone: the stalls have dress of the program's to offer, and the deck cards
## of its own. Thrown away when the demo takes over again.

## How many roads from the slip road the head start reaches.
const ROADS := 4


## A new profile among [param settings]' with the head start, kept; or one kept nowhere, should
## there be no room for another.
static func make(settings: Settings) -> Profile:
	var made := settings.new_profile()
	if made == null:
		made = Profile.new()
		made.transient = true
	head_start(made)
	made.save_to_disk()
	return made


## [param profile] welcomed to the program and the landmarks of [method nearest] won.
static func head_start(profile: Profile) -> void:
	profile.loyalty.welcomed = true
	for id: StringName in nearest(Loyalty.map()):
		profile.loyalty.win(id)
	Loyalty.settle(profile)


## The landmarks of [param drawn] within [constant ROADS] roads of the slip road, on the slip road,
## the Strip and in the Department, keystones left out.
static func nearest(drawn: LoyaltyMap) -> Array[StringName]:
	var hops: Dictionary[StringName, int] = {}
	var queue: Array[StringName] = []
	for each: LoyaltyLandmark in drawn.landmarks:
		if each.district == LoyaltyLandmark.District.SLIP:
			hops[each.id] = 0
			queue.append(each.id)
	while not queue.is_empty():
		var id: StringName = queue.pop_front()
		if hops[id] >= ROADS:
			continue
		for next: StringName in drawn.roads_of(id):
			if not hops.has(next):
				hops[next] = hops[id] + 1
				queue.append(next)
	var near: Array[StringName] = []
	var houses := [
		LoyaltyLandmark.District.SLIP,
		LoyaltyLandmark.District.STRIP,
		LoyaltyLandmark.District.DEPARTMENT,
	]
	for each: LoyaltyLandmark in drawn.landmarks:
		if hops.has(each.id) and each.district in houses and not each.keystone:
			near.append(each.id)
	return near
