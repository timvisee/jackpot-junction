class_name Achievements
extends RefCounted
## The rules of the achievements of GAME.md 8.10: the list, earning one, and settling, which earns
## whatever a profile's records already show. Earning is the one place an achievement is earned:
## [AchievementRecord] earns the moments of a map, and settling the rest, wherever the records
## change and as the title comes up.

const LIST_PATH := "res://data/achievements/list.tres"
const JOKERS_PATH := "res://data/jokers/catalog.tres"
const ITEM_SETS: Array[String] = [
	"res://data/powerups/first_set.tres", "res://data/powerups/later_set.tres"
]
## How many endorsements the driving test can stamp on the front of the license, GAME.md 9.4a: as
## many as [constant TutorialFight.ENDORSEMENTS] has, which a test holds this to.
const ENDORSEMENTS := 7
## The parts of the dress, GAME.md 8.10: the six of [constant KartStyle.CHOICES] and the card back.
const DRESS_PARTS := 7
## How many crates broken, over every map a profile has played, are Property Damage, GAME.md 8.10.
const CRATES := 100
## The districts of the loyalty program a district can be known by, GAME.md 8.10, Know Every Street.
const DISTRICTS: Array[LoyaltyLandmark.District] = [
	LoyaltyLandmark.District.STRIP,
	LoyaltyLandmark.District.DEPARTMENT,
	LoyaltyLandmark.District.OFF_THE_BOOKS,
]
## The story's four, which only count with the story on, STORY.md 8.7.
const STORY_FOUR: Array[StringName] = [
	&"off_the_books", &"terms_accepted", &"employee_of_the_month", &"a_fresh_start"
]

## The group the toasts' layer is in, [AchievementToasts], reached by it rather than by its class
## so that nothing here names a scene's class: this is read as the game starts, see
## [method read_arguments].
const TOAST_LAYERS := &"achievement_toast_layers"

## For a debug build: achievements to put up as toasts as soon as the toasts' layer is up, see
## [method read_arguments].
static var toasts_due := PackedStringArray()
static var _list: AchievementList
static var _joker_ids: Array[StringName] = []
static var _item_ids: Array[StringName] = []


## The debug build's arguments for the achievements, GAME.md 8.10: `++ --achievements-all` earns the
## profile playing in [param settings] every one, and `++ --achievement=<ids>` the ones named, a
## comma between them, quietly and each new, kept; `++ --achievements-none` takes every one back and
## has the profile credited again the next time the title comes up, as one from before achievements
## is, kept; `++ --achievement-toast=<ids>` puts each named up as a toast once the title is, as if
## just earned, keeping nothing. Nothing in a released game.
static func read_arguments(args: PackedStringArray, settings: Settings) -> void:
	if not OS.is_debug_build():
		return
	var state := settings.profile.achievements
	var kept := false
	for arg: String in args:
		if arg == "--achievements-none":
			state.earned.clear()
			state.fresh.clear()
			state.credited = false
			kept = true
		elif arg == "--achievements-all":
			for each: Achievement in all():
				state.earn(each.id, int(Time.get_unix_time_from_system()))
			state.credited = true
			kept = true
		elif arg.begins_with("--achievement="):
			for id: String in arg.get_slice("=", 1).split(",", false):
				if find(StringName(id)) != null:
					state.earn(StringName(id), int(Time.get_unix_time_from_system()))
			kept = true
		elif arg.begins_with("--achievement-toast="):
			toasts_due.append_array(arg.get_slice("=", 1).split(",", false))
	if kept:
		settings.save_to_disk()


## Every achievement in the list's order, read once.
static func all() -> Array[Achievement]:
	if _list == null:
		_list = load(LIST_PATH) as AchievementList if ResourceLoader.exists(LIST_PATH) else null
		if _list == null:
			_list = AchievementList.new()
	return _list.achievements


## The achievement [param id], or null for one this version does not have.
static func find(id: StringName) -> Achievement:
	for each: Achievement in all():
		if each.id == id:
			return each
	return null


## [param profile] earns [param id], GAME.md 8.10: written into it with the moment, marked new, the
## profile saved there and then outside a headless run, and said on
## [signal Events.achievement_earned] for the toast, with the seat it was earned at, -1 for none,
## unless [param quiet]. True the first time; an achievement is earned once.
static func earn(profile: Profile, id: StringName, slot := -1, quiet := false) -> bool:
	if profile == null or find(id) == null:
		return false
	if not profile.achievements.earn(id, int(Time.get_unix_time_from_system())):
		return false
	if not Game.is_headless():
		profile.save_to_disk()
	if not quiet:
		Events.achievement_earned.emit(profile.id, id, slot)
	return true


## Earns [param profile] every achievement its records already show and it has not earned yet, in
## the list's order, as [method earn] does. Returns those earned.
static func settle(profile: Profile, slot := -1, quiet := false) -> Array[Achievement]:
	var earned: Array[Achievement] = []
	if profile == null:
		return earned
	for each: Achievement in all():
		if not profile.achievements.has(each.id) and met(profile, each):
			if earn(profile, each.id, slot, quiet):
				earned.append(each)
	return earned


## [param profile] settled as it comes to a screen or plays at a seat, [param slot], GAME.md 8.10:
## a profile from before achievements is credited quietly with all its records already hold, and
## one toast says how many, Earned already; any other has what its records show earned as ever.
## Returns what was earned.
static func arrive(profile: Profile, slot := -1) -> Array[Achievement]:
	if profile == null:
		return []
	if profile.achievements.credited:
		return settle(profile, slot)
	var earned := settle(profile, slot, true)
	profile.achievements.credited = true
	if not Game.is_headless():
		profile.save_to_disk()
	var tree := Engine.get_main_loop() as SceneTree
	var layer := tree.get_first_node_in_group(TOAST_LAYERS) if tree != null else null
	if layer != null and not earned.is_empty():
		layer.call(&"credited", profile, earned)
	return earned


## Whether [param profile]'s records show [param achievement] done: the license, the catalog, the
## program, the dress, the story and the crates broken. False for a moment of a map, which only
## [AchievementRecord] hears.
static func met(profile: Profile, achievement: Achievement) -> bool:
	if achievement.id in STORY_FOUR and not profile.story.on:
		return false
	match achievement.id:
		&"street_legal":
			return Story.licensed(profile)
		&"honor_roll":
			return Story.licensed(profile) and profile.license_endorsements.size() >= ENDORSEMENTS
		&"off_the_books":
			return profile.story.story_notes() >= 1
		&"terms_accepted":
			return profile.story.ended()
		&"employee_of_the_month":
			return profile.story.ended() and profile.story.shifts >= 1
		&"a_fresh_start":
			return profile.story.story_notes() >= Story.NOTE_COUNT
	if achievement.bar:
		var come := progress(profile, achievement)
		return come.y > 0 and come.x >= come.y
	return false


## How far [param profile] has come with [param achievement]'s bar, and out of how many: (0, 0) for
## one with no bar. A bar counts what there is in the game, so it grows with the game.
static func progress(profile: Profile, achievement: Achievement) -> Vector2i:
	if not achievement.bar:
		return Vector2i.ZERO
	match achievement.id:
		&"full_deck":
			return Vector2i(profile.catalog.found_of(joker_ids()), joker_ids().size())
		&"toybox":
			return Vector2i(profile.catalog.found_of(item_ids()), item_ids().size())
		&"dressed_to_the_nines":
			return Vector2i(dressed_parts(profile), DRESS_PARTS)
		&"know_every_street":
			return nearest_district(profile)
		&"most_valued_member":
			return _won_of(profile, house_landmarks())
		&"lap_of_luxury":
			return _lap(profile)
		&"property_damage":
			var broken := roundi(LifetimeStats.value_of(profile, &"crates"))
			return Vector2i(mini(broken, CRATES), CRATES)
	return Vector2i.ZERO


## How many of the profile's achievements are earned, of those this version has.
static func earned_count(profile: Profile) -> int:
	var count := 0
	for each: Achievement in all():
		if profile.achievements.has(each.id):
			count += 1
	return count


## Whether any achievement [param profile] has earned is still new, GAME.md 8.10.
static func has_fresh(profile: Profile) -> bool:
	for each: Achievement in all():
		if profile.achievements.is_fresh(each.id):
			return true
	return false


## Every joker in the game, by id.
static func joker_ids() -> Array[StringName]:
	if _joker_ids.is_empty():
		var catalog := load(JOKERS_PATH) as JokerCatalog
		if catalog != null:
			for joker: Joker in catalog.jokers:
				if joker.id not in _joker_ids:
					_joker_ids.append(joker.id)
	return _joker_ids


## Every power-up in the game, the first set and the later, by id.
static func item_ids() -> Array[StringName]:
	if _item_ids.is_empty():
		for path: String in ITEM_SETS:
			var table := load(path) as PowerUpTable
			if table == null:
				continue
			for item: PowerUp in table.entries:
				if item.id not in _item_ids:
					_item_ids.append(item.id)
	return _item_ids


## How many parts of the dress [param profile] wears as something other than the plain choice and
## other than None, GAME.md 8.10: its own kart's, which a seat it sits in wears, and its card back.
static func dressed_parts(profile: Profile) -> int:
	var style := KartStyle.from_array(profile.kart_styles[0]).to_array()
	var count := 0
	for part: int in KartStyle.CHOICES.size():
		var index := style[part] if part < style.size() else 0
		if index > 0 and KartStyle.CHOICES[part][index] != "None":
			count += 1
	if profile.loyalty.card_back > 0:
		count += 1
	return count


## The district of the loyalty program [param profile] is nearest to having won every landmark
## of, GAME.md 8.10: how many of it are won, and of how many; Kit's only with the story on.
static func nearest_district(profile: Profile) -> Vector2i:
	var best := Vector2i.ZERO
	var best_share := -1.0
	for district: LoyaltyLandmark.District in DISTRICTS:
		if district == LoyaltyLandmark.District.OFF_THE_BOOKS and not profile.story.on:
			continue
		var come := _won_of(profile, landmarks_of([district]))
		if come.y == 0:
			continue
		var share := float(come.x) / float(come.y)
		if share > best_share:
			best_share = share
			best = come
	return best


## The House's map, GAME.md 8.10, Most Valued Member: the slip road and both districts of the
## House's, not Kit's.
static func house_landmarks() -> Array[LoyaltyLandmark]:
	return landmarks_of(
		[
			LoyaltyLandmark.District.SLIP,
			LoyaltyLandmark.District.STRIP,
			LoyaltyLandmark.District.DEPARTMENT,
		]
	)


## The landmarks of the program's map in any of [param districts].
static func landmarks_of(districts: Array) -> Array[LoyaltyLandmark]:
	var found: Array[LoyaltyLandmark] = []
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		if each.district in districts:
			found.append(each)
	return found


static func _won_of(profile: Profile, landmarks: Array[LoyaltyLandmark]) -> Vector2i:
	var won := 0
	for each: LoyaltyLandmark in landmarks:
		if profile.loyalty.has_won(each.id):
			won += 1
	return Vector2i(won, landmarks.size())


## The roundabout's lap, GAME.md 8.9: every bet once a lap is driven, and until then how many of the
## ring's bets are met, none before the roundabout opens.
static func _lap(profile: Profile) -> Vector2i:
	if profile.loyalty.laps >= 1:
		return Vector2i(Loyalty.RING_BETS, Loyalty.RING_BETS)
	var met := 0
	for bet: Dictionary in profile.loyalty.ring:
		var come := Loyalty.ring_progress(profile, bet)
		if come.x >= come.y:
			met += 1
	return Vector2i(met, Loyalty.RING_BETS)
