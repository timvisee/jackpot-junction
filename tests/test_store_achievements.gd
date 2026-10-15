extends GdUnitTestSuite
## The achievements on Steam, GAME.md 8.10 and 10.8: the profile playing's, by their ids in
## capitals, told again at the start and on a switch, never fewer; the bars as statistics; Steam
## told in batches. Steam here is always [FakeSteam].

const OWN_APP := 3141590
const PATH := "user://test_store_achievements.cfg"

var _settings_were: Settings
var _fake: FakeSteam


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = ""
	_fake = FakeSteam.new()
	Store.steam = SteamStore.new(_fake)
	Store.steam.start(OWN_APP)


func after_test() -> void:
	Store.steam = null
	Game.settings = _settings_were
	Settings.remove_files(PATH)


## What the profile playing earns goes to Steam with the next batch, in capitals, and Steam keeps
## it then, once, for its own pop-up; quietly earned, as the Earned already credit is, too.
func test_the_profile_playing_tells_steam() -> void:
	var profile := Game.settings.profile
	Achievements.earn(profile, &"street_legal")
	Achievements.earn(profile, &"flawless", -1, true)
	assert_bool(_fake.achieved.has("STREET_LEGAL")).is_false()
	Store.flush()
	assert_bool(_fake.achieved.has("STREET_LEGAL")).is_true()
	assert_bool(_fake.achieved.has("FLAWLESS")).is_true()
	assert_int(_fake.stores).is_equal(1)
	Store.flush()
	assert_int(_fake.stores).is_equal(1)


## A linked seat's profile, or one that is not playing at all, tells Steam nothing.
func test_a_linked_seat_tells_steam_nothing() -> void:
	var linked := Profile.new()
	linked.id = "2"
	Achievements.earn(linked, &"street_legal")
	Store.tell_all(linked)
	Store.flush()
	assert_bool(_fake.achieved.is_empty()).is_true()
	assert_bool(_fake.stats.is_empty()).is_true()


## Everything the profile has earned, told again, without a pop-up for what Steam already has.
func test_everything_earned_is_told_again() -> void:
	var profile := Game.settings.profile
	for id: StringName in [&"street_legal", &"parry", &"all_in"]:
		profile.achievements.earn(id, 1)
	_fake.achieved["PARRY"] = true
	Store.tell_all(profile)
	Store.flush()
	assert_array(_fake.achieved.keys()).contains_exactly_in_any_order(
		["STREET_LEGAL", "PARRY", "ALL_IN"]
	)
	assert_array(_fake.calls).not_contains(["setAchievement PARRY"])
	assert_int(_fake.stores).is_equal(1)


## The bars go as statistics, never Know Every Street's, and never back: a profile with less
## leaves Steam's count where it is.
func test_the_bars_go_as_statistics_and_never_back() -> void:
	var profile := Game.settings.profile
	profile.stats[&"crates"] = 40.0
	_fake.stats["FULL_DECK_COUNT"] = 10
	Store.tell_all(profile)
	Store.flush()
	assert_int(_fake.stats["PROPERTY_DAMAGE_COUNT"]).is_equal(40)
	assert_int(_fake.stats["FULL_DECK_COUNT"]).is_equal(10)
	assert_bool(_fake.stats.has("KNOW_EVERY_STREET_COUNT")).is_false()
	assert_array(_fake.calls).not_contains(["setStatInt FULL_DECK_COUNT 0"])
	# Settled again with nothing further along, nothing new is due.
	var stores := _fake.stores
	Achievements.settle(profile)
	Store.flush()
	assert_int(_fake.stores).is_equal(stores)


## Steam still reading the account as the game starts takes nothing; the next batches offer it
## again, a few at most.
func test_what_steam_would_not_take_is_offered_again() -> void:
	_fake.busy = true
	Achievements.earn(Game.settings.profile, &"street_legal")
	Store.flush()
	assert_bool(_fake.achieved.has("STREET_LEGAL")).is_false()
	_fake.busy = false
	Store.flush()
	assert_bool(_fake.achieved.has("STREET_LEGAL")).is_true()
	_fake.busy = true
	Achievements.earn(Game.settings.profile, &"parry")
	for _batch: int in SteamStore.TRIES:
		Store.flush()
	_fake.busy = false
	Store.flush()
	assert_bool(_fake.achieved.has("PARRY")).is_false()


## Under Spacewar a debug build gives a few achievements Spacewar's names, and the rest nothing.
func test_spacewar_lends_a_few_names() -> void:
	Store.steam = SteamStore.new(_fake)
	Store.steam.start(Store.SPACEWAR)
	Achievements.earn(Game.settings.profile, &"street_legal")
	Achievements.earn(Game.settings.profile, &"parry")
	Store.tell_all(Game.settings.profile)
	Store.flush()
	if OS.is_debug_build():
		assert_array(_fake.achieved.keys()).contains_exactly(["ACH_WIN_ONE_GAME"])
	assert_bool(_fake.stats.is_empty()).is_true()


## Switched to another profile, Steam hears everything that one has earned.
func test_a_switch_tells_steam_the_other_profile() -> void:
	Game.settings.path = PATH
	Game.settings.save_to_disk()
	var other := Game.settings.new_profile()
	other.achievements.earn(&"honor_roll", 1)
	other.save_to_disk()
	Game.settings.switch_profile(other.id)
	Store.flush()
	assert_bool(_fake.achieved.has("HONOR_ROLL")).is_true()


## Steam's list against the game's, in a debug build with an app of its own: what either lacks is
## said, once.
func test_the_lists_are_compared() -> void:
	for each: Achievement in Achievements.all():
		_fake.known.append(each.store_name())
	_fake.known.erase("PARRY")
	_fake.known.append("SOMETHING_ELSE")
	Achievements.earn(Game.settings.profile, &"street_legal")
	Store.flush()
	assert_bool(_fake.achieved.has("STREET_LEGAL")).is_true()


## Clearing takes everything back on Steam, for a debug build trying it again.
func test_clearing_takes_everything_back() -> void:
	Achievements.earn(Game.settings.profile, &"street_legal")
	Store.flush()
	Store.steam.clear_all()
	assert_bool(_fake.achieved.is_empty()).is_true()
