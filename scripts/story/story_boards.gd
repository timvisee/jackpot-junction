class_name StoryBoards
extends RefCounted
## Which two of the House's advertisements a room's hoardings carry, STORY.md 6.1. The set grows
## with the story: of the two a room draws, one comes from the newest stage reached and the other
## from every stage reached, the first stage's sixteen of [constant Billboard.ADS] among them, so
## the newest lines are always seen and the old jokes keep coming around. At most one of the two
## names the player; the Final Hand's are the House's own two.


## Every advertisement up to and including [param stage].
static func pool(stage: int) -> Array[Array]:
	var ads: Array[Array] = []
	ads.append_array(Billboard.ADS)
	for reached: int in range(Story.Stage.PLAYER, stage + 1):
		for ad: Array in StoryLines.ADS.get(reached, []):
			ads.append(ad)
	return ads


## The advertisements [param stage] itself adds, or the first stage's for the first.
static func newest(stage: int) -> Array[Array]:
	var ads: Array[Array] = []
	if stage <= Story.Stage.CUSTOMER or not StoryLines.ADS.has(stage):
		ads.append_array(Billboard.ADS)
	else:
		for ad: Array in StoryLines.ADS[stage]:
			ads.append(ad)
	return ads


## The two a room puts up at [param stage], drawn with [param rng]: the Final Hand's own two when
## [param final_hand], and otherwise one from the newest stage and one from all of them, never the
## same line twice and never two that name the player.
static func pick(stage: int, final_hand: bool, rng: RandomNumberGenerator) -> Array[Array]:
	var two: Array[Array] = []
	if final_hand:
		two.append_array(StoryLines.FINAL_HAND_ADS)
		return two
	var fresh := newest(stage)
	var first: Array = fresh[rng.randi_range(0, fresh.size() - 1)]
	two.append(first)
	var rest: Array[Array] = []
	for ad: Array in pool(stage):
		if ad == first or (names_the_player(first) and names_the_player(ad)):
			continue
		rest.append(ad)
	two.append(rest[rng.randi_range(0, rest.size() - 1)] if not rest.is_empty() else first)
	return two


## Whether [param ad] is the House addressing the player by name.
static func names_the_player(ad: Array) -> bool:
	return str(ad[0]).contains("{name}") or str(ad[1]).contains("{name}")
