extends GdUnitTestSuite
## The About page of the settings, GAME.md 8.5: what the game is, that AI made it and which models,
## and everybody else whose work is in it.

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")


func after_test() -> void:
	Audio.music_dir = Audio.MUSIC_DIR


func test_the_about_page_says_what_it_is_and_who_made_it() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	var about: AboutTab = screen.tabs.get_node("About")
	var said := about.said()
	assert_str(said).contains("Jackpot Junction")
	assert_str(said).contains(Game.version())
	assert_str(said).contains("experiment")
	for model: String in Credits.MODELS:
		assert_str(said).contains(model)
	for thing: Dictionary in Credits.in_this_build():
		assert_str(said).contains(thing["what"])
	var links := about.find_children("*", "LinkButton", true, false)
	assert_int(links.size()).is_equal(3)
	var uris: Array[String] = []
	for link: Node in links:
		uris.append((link as LinkButton).uri)
	assert_bool(uris.has(Credits.STEAM)).is_true()
	assert_bool(uris.has(Credits.ITCH)).is_true()
	assert_bool(uris.has(Credits.REPOSITORY)).is_true()
	assert_str(Credits.REPOSITORY).contains("github.com/timvisee/jackpot-junction")
	assert_str(Credits.STEAM).contains("store.steampowered.com/app/5652730")
	assert_str(Credits.ITCH).contains("timvisee.itch.io/jackpot-junction")


## Everybody THIRD_PARTY.md says has work in the repository is credited on the page, so the two
## cannot drift apart.
func test_everybody_in_the_third_party_list_is_credited() -> void:
	var authors := _third_party_authors()
	assert_int(authors.size()).is_greater(5)
	var who := ""
	for thing: Dictionary in Credits.THINGS:
		who += " " + String(thing["who"])
	for author: String in authors:
		assert_str(who).override_failure_message("%s is not credited" % author).contains(author)


## And the other way: everybody the page credits has a row in THIRD_PARTY.md, with the files and the
## terms, but Godot, which is the engine rather than anything in the repository.
func test_everybody_credited_is_in_the_third_party_list() -> void:
	var authors := _third_party_authors()
	for thing: Dictionary in Credits.THINGS:
		if thing["what"] == "Godot Engine":
			continue
		var who := String(thing["who"])
		var listed := authors.any(func(author: String) -> bool: return who.contains(author))
		(
			assert_bool(listed)
			. override_failure_message("%s has no row in THIRD_PARTY.md" % who)
			. is_true()
		)


## Who made each row of THIRD_PARTY.md's table, its second column.
func _third_party_authors() -> Array[String]:
	var text := FileAccess.get_file_as_string("res://THIRD_PARTY.md")
	var authors: Array[String] = []
	for line: String in text.split("\n"):
		var cells := line.split("|")
		if (
			cells.size() < 4
			or line.begins_with("|--")
			or cells[1].strip_edges() == "Asset or library"
		):
			continue
		authors.append(cells[2].strip_edges())
	return authors


## What only a Steam build has in it, GAME.md 10.8, is credited only where it is.
func test_steam_is_credited_where_it_is_in_the_build() -> void:
	var steam := Engine.has_singleton(Store.SINGLETON)
	var godotsteam := Credits.in_this_build().any(
		func(thing: Dictionary) -> bool: return thing["what"].begins_with("GodotSteam")
	)
	assert_bool(godotsteam).is_equal(steam)


## Music is credited only where it is in the build: the licensed tracks live in a private
## repository, see tools/private_assets, and a build from the public one alone has none.
func test_music_is_credited_only_where_it_is_in_the_build() -> void:
	var ovani := func() -> bool:
		return Credits.in_this_build().any(
			func(thing: Dictionary) -> bool: return thing["who"] == "Ovani Sound"
		)
	assert_bool(ovani.call()).is_equal(not Audio.tracks_here().is_empty())
	Audio.music_dir = "res://tests/no_music_here/"
	assert_bool(ovani.call()).is_false()
	Audio.music_dir = Audio.MUSIC_DIR
	# Everything else stays.
	var cascadia := Credits.in_this_build().any(
		func(thing: Dictionary) -> bool: return thing["who"] == "Cascadia Games"
	)
	assert_bool(cascadia).is_true()


## The name Credits knows GodotSteam by is Store's, named again so the hall need not load Store.
func test_the_steam_singleton_is_stores() -> void:
	assert_str(String(Credits.STEAM_SINGLETON)).is_equal(String(Store.SINGLETON))


## Every file a credit names is in the project, so a file renamed or taken out cannot quietly take
## its credit out of every build.
func test_every_file_credited_is_here() -> void:
	for thing: Dictionary in Credits.THINGS:
		for path: String in thing.get("files", []):
			(
				assert_bool(Credits.holds(path))
				. override_failure_message("%s is not here" % path)
				. is_true()
			)


## A credit whose files a build does not hold is left out of it, the way the server, built without
## its sound, leaves the sounds out; one with any of them, or with no files named, stays.
func test_a_credit_is_left_out_of_a_build_without_its_files() -> void:
	var missing := "res://assets/audio/sfx/not_here.ogg"
	var gone := {"what": "Gone", "files": [missing]}
	var here := {"what": "Here", "files": [missing, "res://assets/fonts/Inter-Regular.ttf"]}
	var always := {"what": "Always"}
	var things: Array[Dictionary] = [gone, here, always]
	assert_array(Credits.in_this_build(things)).contains_exactly([here, always])


## The terms a credit names a text for are in the engine's table, which the notices print from, and
## a credit with a text says whose it is, but where its terms waive that: CC0's.
func test_every_license_credited_has_its_text() -> void:
	var texts := Engine.get_license_info()
	for thing: Dictionary in Credits.THINGS:
		if not thing.has("license"):
			continue
		var key: String = thing["license"]
		assert_bool(texts.has(key)).override_failure_message("%s has no text" % key).is_true()
		if key != "CC0-1.0":
			(
				assert_bool(thing.has("copyright"))
				. override_failure_message("%s says nothing of whose it is" % thing["what"])
				. is_true()
			)


func test_the_models_read_as_a_sentence() -> void:
	assert_str(Credits.models_in_words()).is_equal(
		"Claude Fable 5.1, Claude Opus 5 and Claude Opus 5.5"
	)
