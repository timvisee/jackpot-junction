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
		assert_str(said).contains(model.replace(" ", "\u00a0"))
	for thing: Dictionary in Credits.in_this_build():
		assert_str(said).contains(thing["what"])
	# The links that go somewhere: the game's pages and its source. The one that opens the
	# licenses opens them on the page.
	var uris: Array[String] = []
	for link: Node in about.find_children("*", "LinkButton", true, false):
		if not (link as LinkButton).uri.is_empty():
			uris.append((link as LinkButton).uri)
	assert_int(uris.size()).is_equal(3)
	assert_bool(uris.has(Credits.STEAM)).is_true()
	assert_bool(uris.has(Credits.ITCH)).is_true()
	assert_bool(uris.has(Credits.REPOSITORY)).is_true()
	assert_str(Credits.REPOSITORY).contains("github.com/timvisee/jackpot-junction")
	assert_str(Credits.STEAM).contains("store.steampowered.com/app/5652730")
	assert_str(Credits.ITCH).contains("timvisee.itch.io/jackpot-junction")


## The licenses close the page: Godot's own, then under a link every other notice the build
## carries, see [Licenses], built only once the link is pressed, the page being built each time
## the settings open; pressed again they fold away, and back, the same ones.
func test_the_licenses_open_under_their_link() -> void:
	var about: AboutTab = auto_free(AboutTab.new())
	add_child(about)
	var said := about.said()
	assert_str(said).contains(Engine.get_license_text())
	assert_str(said).contains(AboutTab.SHOW_LICENSES)
	assert_object(about.notices).is_null()
	assert_str(said).not_contains("The FreeType Project")
	assert_int(about.licenses_link.focus_mode).is_equal(Control.FOCUS_ALL)
	about.licenses_link.pressed.emit()
	assert_object(about.notices).is_not_null()
	assert_str(about.licenses_link.text).is_equal(AboutTab.HIDE_LICENSES)
	# They come in a little a frame, the first of them at once.
	assert_int(about.notices.get_child_count()).is_greater(0)
	assert_bool(about.filling()).is_true()
	for frame: int in 120:
		if not about.filling():
			break
		await get_tree().process_frame
	assert_bool(about.filling()).is_false()
	said = about.said()
	var things := Credits.in_this_build()
	var of := Licenses.pieces()
	for piece: Dictionary in of:
		assert_str(said).contains(piece["name"])
	for line: String in _copyright_of("The FreeType Project"):
		assert_str(said).contains(line)
	for thing: Dictionary in things:
		if thing.has("license"):
			assert_str(said).contains(thing["what"])
			for line: String in Licenses.copyright(thing.get("copyright", [])):
				assert_str(said).contains(line)
	var texts := Engine.get_license_info()
	for key: String in Licenses.keys(things, of):
		assert_str(said).contains(Licenses.title(key))
		for piece: String in AboutTab._pieces(texts[key]):
			assert_str(said).contains(piece)
	var opened := about.notices
	about.licenses_link.pressed.emit()
	assert_bool(opened.visible).is_false()
	assert_str(about.licenses_link.text).is_equal(AboutTab.SHOW_LICENSES)
	about.licenses_link.pressed.emit()
	assert_bool(opened.visible).is_true()
	assert_object(about.notices).is_same(opened)


## The pad reaches the licenses' link, down from the last of the page's links, the source's.
func test_the_pad_reaches_the_licenses() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	var about: AboutTab = screen.tabs.get_node("About")
	screen.tabs.current_tab = about.get_index()
	for frame: int in 3:
		await get_tree().process_frame
	var source: LinkButton
	for link: Node in about.find_children("*", "LinkButton", true, false):
		if (link as LinkButton).uri == Credits.REPOSITORY:
			source = link
	assert_object(source.find_valid_focus_neighbor(SIDE_BOTTOM)).is_same(about.licenses_link)


## A license's text is cut at its paragraphs into pieces that each go in in a frame, all of it kept.
func test_a_license_comes_in_pieces() -> void:
	var text: String = Engine.get_license_info()["MPL-2.0"]
	var pieces := AboutTab._pieces(text)
	assert_int(pieces.size()).is_greater(4)
	for piece: String in pieces:
		assert_int(piece.length()).is_less_equal(AboutTab.NOTICE_PIECE * 2)
	assert_str("\n\n".join(pieces)).is_equal(text.strip_edges())


## Closed before the notices are all in, the page takes the rest with it.
func test_the_notices_not_yet_in_go_with_the_page() -> void:
	var about: AboutTab = AboutTab.new()
	add_child(about)
	about.toggle_licenses()
	assert_bool(about.filling()).is_true()
	about.free()


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


## The copyright lines of the piece of Godot named [param name], as the notices write them.
func _copyright_of(name: String) -> PackedStringArray:
	var lines := PackedStringArray()
	for piece: Dictionary in Licenses.pieces():
		if piece["name"] == name:
			for part: Dictionary in piece["parts"]:
				lines.append_array(Licenses.copyright(part["copyright"]))
	assert_bool(lines.is_empty()).is_false()
	return lines


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


## The models read as a sentence, each name held together so no line breaks inside one; and a link
## on the page breaks after none of its slashes.
func test_the_models_read_as_a_sentence() -> void:
	var said := Credits.models_in_words()
	assert_str(said.replace("\u00a0", " ")).is_equal(
		"Claude Fable 5.1, Claude Opus 5 and Claude Opus 5.5"
	)
	assert_str(said).contains("Claude\u00a0Fable\u00a05.1")
	assert_str(AboutTab.whole("github.com/jpt/barlow")).is_equal(
		"github.com/\u2060jpt/\u2060barlow"
	)


## The Chinese partner fonts are credited where a build has them and not on a dedicated server's
## page, GAME.md 10.9: the server's exports leave their folder out, and every row crediting them
## credits files in it alone, so none is listed by a build without it.
func test_the_chinese_fonts_are_credited_only_where_a_build_has_them() -> void:
	var folder := "res://assets/fonts/chinese/"
	var theirs: Array[Dictionary] = []
	for thing: Dictionary in Credits.THINGS:
		var files: Array = thing.get("files", [])
		if files.any(func(file: String) -> bool: return file.begins_with(folder)):
			(
				assert_bool(files.all(func(file: String) -> bool: return file.begins_with(folder)))
				. is_true()
			)
			theirs.append(thing)
	assert_int(theirs.size()).is_equal(7)
	assert_int(Credits.in_this_build(theirs).size()).is_equal(7)
	# The same rows in a build without the folder, as a dedicated server's is.
	var elsewhere: Array[Dictionary] = []
	for thing: Dictionary in theirs:
		var moved := thing.duplicate()
		moved["files"] = (thing["files"] as Array).map(
			func(file: String) -> String: return file.replace(folder, "res://not/in/this/build/")
		)
		elsewhere.append(moved)
	assert_array(Credits.in_this_build(elsewhere)).is_empty()
	var presets := ConfigFile.new()
	assert_int(presets.load("res://export_presets.cfg")).is_equal(OK)
	var servers := 0
	for section: String in presets.get_sections():
		if (
			section.ends_with(".options")
			or not presets.get_value(section, "dedicated_server", false)
		):
			continue
		servers += 1
		var left_out := str(presets.get_value(section, "exclude_filter", ""))
		assert_str(left_out).contains(folder.trim_prefix("res://") + "*")
	assert_int(servers).is_greater(0)
