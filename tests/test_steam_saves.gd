extends GdUnitTestSuite
## A Steam account's saves, GAME.md 10.8: a folder of its own, the profiles beside its settings,
## the GitHub build's copied in once, and a new profile named after the account. Played on folders
## of the tests' own, shaped like the player's, never the player's.

const ACCOUNT := 76561197960287930
## A GitHub build's saves and an account's, as the real ones are laid out: settings.cfg with a
## profiles folder beside it.
const GITHUB := "user://test_steam_saves_github/settings.cfg"
const STEAM := "user://test_steam_saves_account/settings.cfg"
const OTHER := "user://test_steam_saves_other.cfg"


func after_test() -> void:
	Store.steam = null
	for at: String in [GITHUB, STEAM]:
		var folder := at.get_base_dir()
		_empty(folder.path_join("profiles"))
		_empty(folder)
	Settings.remove_files(OTHER)


## Every account in a folder of its own, its profiles beside its settings as the player's own are
## beside theirs; anything else keeps its profiles in a folder named after it, as ever.
func test_an_account_keeps_its_saves_in_a_folder_of_its_own() -> void:
	var path := SteamSaves.settings_path(ACCOUNT)
	assert_str(path).is_equal("user://steam/%d/settings.cfg" % ACCOUNT)
	var settings := Settings.new()
	settings.path = path
	assert_str(settings.profiles_dir()).is_equal("user://steam/%d/profiles" % ACCOUNT)
	settings.path = Settings.DEFAULT_PATH
	assert_str(settings.profiles_dir()).is_equal("user://profiles")
	settings.path = OTHER
	assert_str(settings.profiles_dir()).is_equal("user://test_steam_saves_other.profiles")


## The first time, the GitHub build's settings and profiles are copied in, and left where they were.
func test_the_github_saves_are_copied_in_once() -> void:
	var github := _saved(GITHUB, "Dee")
	assert_bool(SteamSaves.bring_over(STEAM, GITHUB)).is_true()
	var steam := Settings.new()
	steam.path = STEAM
	steam.load_from_disk()
	assert_str(steam.profile.player_names[0]).is_equal("Dee")
	assert_bool(FileAccess.file_exists(github.profiles_dir().path_join("1.cfg"))).is_true()
	# Played on, the account's own are never written over again.
	steam.profile.player_names[0] = "Ann"
	steam.save_to_disk()
	assert_bool(SteamSaves.bring_over(STEAM, GITHUB)).is_false()
	steam.load_from_disk()
	assert_str(steam.profile.player_names[0]).is_equal("Ann")


## Profiles Steam's cloud brought down, with no settings on this machine yet, are the account's:
## nothing is copied over them.
func test_profiles_from_the_cloud_are_kept() -> void:
	_saved(GITHUB, "Dee")
	var cloud := Profile.at(STEAM.get_base_dir().path_join("profiles"), "1")
	cloud.player_names[0] = "Ann"
	cloud.save_to_disk()
	assert_bool(SteamSaves.bring_over(STEAM, GITHUB)).is_false()
	assert_bool(FileAccess.file_exists(STEAM)).is_false()


## With no GitHub build here there is nothing to copy, and nothing is made.
func test_nothing_to_copy_makes_nothing() -> void:
	assert_bool(SteamSaves.bring_over(STEAM, GITHUB)).is_false()
	assert_bool(DirAccess.dir_exists_absolute(STEAM.get_base_dir())).is_false()


## A profile made in a Steam build is named after the account; with no Steam, nameless as ever.
func test_a_new_profile_is_named_after_the_account() -> void:
	var settings := Settings.new()
	settings.path = OTHER
	settings.save_to_disk()
	assert_str(settings.new_profile().player_names[0]).is_empty()
	var fake := FakeSteam.new()
	fake.persona = "Ann the Great of Steam"
	Store.steam = SteamStore.new(fake)
	Store.steam.start(Store.SPACEWAR)
	assert_str(settings.new_profile().player_names[0]).is_equal(PlayerNames.clean(fake.persona))


## A test never takes a player's settings away, the GitHub build's or an account's.
func test_a_players_saves_are_never_a_tests_to_remove() -> void:
	assert_bool(Settings._players_own(Settings.DEFAULT_PATH)).is_true()
	assert_bool(Settings._players_own(SteamSaves.settings_path(ACCOUNT))).is_true()
	assert_bool(Settings._players_own(OTHER)).is_false()


func _saved(at: String, named: String) -> Settings:
	var settings := Settings.new()
	settings.path = at
	settings.profile.player_names[0] = named
	settings.save_to_disk()
	return settings


func _empty(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for file: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
