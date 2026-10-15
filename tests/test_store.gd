extends GdUnitTestSuite
## The store layer and Steam's start, GAME.md 10.8: when Steam is wanted, how it starts, and what
## the game hears when it does not. Steam here is always [FakeSteam].

const APP := "user://test_store_app.cfg"


func after_test() -> void:
	Store.steam = null
	Store.missing = ""
	Store.restarting = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(APP))


## A Steam build or `--steam`; never with `--no-steam`, on a server or in the demo; and a GitHub
## build, a test or a tool with neither, never.
func test_steam_is_wanted_only_where_asked_for() -> void:
	var none := PackedStringArray()
	var asked := PackedStringArray(["--steam"])
	var refused := PackedStringArray(["--steam", "--no-steam"])
	assert_bool(Store.wanted(none, false, false, false)).is_false()
	assert_bool(Store.wanted(none, true, false, false)).is_true()
	assert_bool(Store.wanted(asked, false, false, false)).is_true()
	assert_bool(Store.wanted(refused, true, false, false)).is_false()
	assert_bool(Store.wanted(asked, true, true, false)).is_false()
	assert_bool(Store.wanted(asked, true, false, true)).is_false()


## The tests run as neither, so starting here starts nothing and says nothing is missing.
func test_a_test_run_starts_no_steam() -> void:
	Store.start(OS.get_cmdline_user_args(), false)
	assert_bool(Store.on()).is_false()
	assert_str(Store.missing).is_empty()


## Started as the app named, Steam running the callbacks, and the account known.
func test_steam_starts_as_the_app_named() -> void:
	var fake := FakeSteam.new()
	var store := SteamStore.new(fake)
	assert_str(store.start(480)).is_empty()
	assert_array(fake.calls).contains(["steamInitEx 480 true"])
	assert_int(store.app).is_equal(480)
	assert_int(store.account).is_equal(fake.account)
	assert_str(store.persona()).is_equal("Ann")


## No Steam client, or an old one: no account, and a word for the screens.
func test_steam_missing_says_why() -> void:
	var fake := FakeSteam.new()
	fake.status = SteamStore.NO_CLIENT
	var store := SteamStore.new(fake)
	assert_str(store.start(480)).is_equal("Steam isn't running")
	assert_int(store.account).is_equal(0)
	fake.status = SteamStore.OLD_CLIENT
	assert_str(SteamStore.new(fake).start(480)).is_equal("Steam needs updating")


## Steam asked whether it would rather start the game itself.
func test_steam_may_start_the_game_itself() -> void:
	var fake := FakeSteam.new()
	assert_bool(SteamStore.new(fake).restart_through_steam(1234)).is_false()
	fake.restarts = true
	assert_bool(SteamStore.new(fake).restart_through_steam(1234)).is_true()
	assert_array(fake.calls).contains(["restartAppIfNecessary 1234"])


## The app a Steam build is, written into it at export, and Spacewar with nothing written.
func test_the_app_id_is_read_from_the_build() -> void:
	assert_int(Store.app_id("user://test_store_nothing.cfg")).is_equal(Store.SPACEWAR)
	var file := ConfigFile.new()
	file.set_value("steam", "app_id", 3141590)
	file.save(APP)
	assert_int(Store.app_id(APP)).is_equal(3141590)


## The supporter pack is Steam's word on the DLC the build names: never with no Steam or no DLC.
func test_the_supporter_pack_is_steams_word() -> void:
	var file := ConfigFile.new()
	file.set_value("steam", "app_id", 3141590)
	file.set_value("steam", "supporter_dlc", 0)
	file.save(APP)
	assert_bool(Store.owns_supporter_pack(APP)).is_false()
	var fake := FakeSteam.new()
	fake.dlcs.append(3141600)
	Store.steam = SteamStore.new(fake)
	Store.steam.start(3141590)
	assert_bool(Store.owns_supporter_pack(APP)).is_false()
	file.set_value("steam", "supporter_dlc", 3141600)
	file.save(APP)
	assert_bool(Store.owns_supporter_pack(APP)).is_true()
	fake.dlcs.clear()
	assert_bool(Store.owns_supporter_pack(APP)).is_false()
