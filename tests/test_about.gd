extends GdUnitTestSuite
## The About page of the settings, GAME.md 8.5: what the game is, that AI made it and which models,
## and everybody else whose work is in it.

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")


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
	for thing: Dictionary in Credits.THINGS:
		assert_str(said).contains(thing["what"])
	var links := about.find_children("*", "LinkButton", true, false)
	assert_int(links.size()).is_equal(1)
	assert_str((links[0] as LinkButton).uri).is_equal(Credits.REPOSITORY)
	assert_str(Credits.REPOSITORY).contains("github.com/timvisee/jackpot-junction")


## Everybody THIRD_PARTY.md says has work in the repository is credited on the page, so the two
## cannot drift apart.
func test_everybody_in_the_third_party_list_is_credited() -> void:
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
	assert_int(authors.size()).is_greater(5)
	var who := ""
	for thing: Dictionary in Credits.THINGS:
		who += " " + String(thing["who"])
	for author: String in authors:
		assert_str(who).override_failure_message("%s is not credited" % author).contains(author)


func test_the_models_read_as_a_sentence() -> void:
	assert_str(Credits.models_in_words()).is_equal(
		"Claude Fable 5.1, Claude Opus 5 and Claude Opus 5.5"
	)
