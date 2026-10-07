extends GdUnitTestSuite
## The catalog's dialog, GAME.md 8.8: a page each of jokers and power-ups in their order, what was
## taken face up and the rest face down, the count on each tab, the panes, Full stack and the NEW
## tags.

const PATH := "user://test_catalog_dialog.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	_holder = auto_free(Control.new())
	add_child(_holder)


func after_test() -> void:
	Story.override = -1
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open() -> CatalogDialog:
	var dialog := CatalogDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


## Jokers by rarity, then kind, then name; every joker and every item there, once.
func test_the_order() -> void:
	var jokers := CatalogDialog.jokers_in_order()
	assert_int(jokers.size()).is_equal(CatalogDialog.CATALOG.jokers.size())
	for i: int in range(1, jokers.size()):
		var a := jokers[i - 1]
		var b := jokers[i]
		assert_bool(a.rarity < b.rarity or (a.rarity == b.rarity and a.kind <= b.kind)).is_true()
		if a.rarity == b.rarity and a.kind == b.kind:
			assert_int(a.display_name.naturalnocasecmp_to(b.display_name)).is_less(0)
	var items := CatalogDialog.items_in_order()
	var all: PowerUpTable = load("res://data/powerups/all.tres")
	assert_int(items.size()).is_equal(all.entries.size())
	assert_str(String(items[0].id)).is_equal(String(CatalogDialog.FIRST.entries[0].id))
	assert_str(String(items[-1].id)).is_equal(String(CatalogDialog.LATER.entries[-1].id))


## Each tab says how many of how many were found, with the gold tick once all were.
func test_the_tabs_count_what_was_found() -> void:
	var catalog := Game.settings.profile.catalog
	catalog.take_joker(&"payday")
	catalog.take_joker(&"vulture")
	for item: PowerUp in CatalogDialog.items_in_order():
		catalog.take_item(item.id)
	var dialog := await _open()
	var jokers := CatalogDialog.CATALOG.jokers.size()
	var items := CatalogDialog.items_in_order().size()
	assert_str(dialog.tabs.get_tab_title(0)).is_equal("Jokers  2/%d" % jokers)
	assert_str(dialog.tabs.get_tab_title(1)).is_equal("Power-ups  %d/%d" % [items, items])
	assert_object(dialog.tabs.get_tab_icon(0)).is_null()
	assert_object(dialog.tabs.get_tab_icon(1)).is_not_null()


## A card never taken lies face down, and its pane says only that it was not found; one taken is
## the card as the hand draws it, its pane the match's with the details, and how often it was taken.
func test_face_down_says_nothing_and_face_up_says_it_all() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	var hidden := dialog.cell_of(&"aimbot")
	assert_object(hidden.card).is_instanceof(CardBack)
	hidden.grab_focus()
	await get_tree().process_frame
	var said := _words_in(dialog.joker_pane)
	assert_str(said).contains(CatalogDialog.NOT_FOUND)
	assert_str(said).not_contains("Aimbot")
	assert_str(said).not_contains("RARE")
	var shown := dialog.cell_of(&"payday")
	assert_object(shown.card).is_instanceof(JokerCard)
	shown.grab_focus()
	await get_tree().process_frame
	said = _words_in(dialog.joker_pane)
	assert_str(said).contains("Payday")
	assert_str(said).contains("Stacks up to ×3.")
	assert_str(said).contains("Taken 2 times")
	assert_str(said).not_contains("×3 ")


## Full stack shows a joker that stacks as its whole stack, its key or its switch, and back.
func test_full_stack_shows_the_whole_stack() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	dialog.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	var one := _words_in(dialog.joker_pane)
	dialog.set_stacked(true)
	assert_bool(dialog.full_stack.button_pressed).is_true()
	var whole := _words_in(dialog.joker_pane)
	assert_str(whole).contains("×3")
	assert_str(whole).is_not_equal(one)
	dialog.full_stack.button_pressed = false
	assert_bool(dialog.stacked).is_false()
	assert_str(_words_in(dialog.joker_pane)).is_equal(one)


## An item's pane says what it does, its numbers and the set it comes in.
func test_an_items_pane_has_its_facts_and_set() -> void:
	Game.settings.profile.catalog.take_item(&"decoy_kart")
	var dialog := await _open()
	dialog.switch_tab(1)
	dialog.cell_of(&"decoy_kart").grab_focus()
	await get_tree().process_frame
	var item: PowerUp = load("res://data/powerups/decoy_kart.tres")
	assert_str(dialog.item_pane.title()).is_equal(item.display_name)
	var facts := dialog.item_pane.facts_shown()
	assert_array(facts[-1]).contains_exactly([CatalogDialog.SET, CatalogDialog.LATER_SET])
	assert_array(facts[0]).contains_exactly(item.facts()[0])
	dialog.cell_of(&"shield").grab_focus()
	await get_tree().process_frame
	assert_str(dialog.item_pane.title()).is_equal(CatalogDialog.NOT_FOUND)


## A card found since the catalog last showed it wears NEW until the cursor comes to it, and that
## is kept as the dialog goes; the cursor goes back where it was.
func test_new_goes_under_the_cursor_and_is_kept() -> void:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_ALL
	_holder.add_child(button)
	button.grab_focus()
	var catalog := Game.settings.profile.catalog
	catalog.take_joker(&"payday")
	catalog.take_joker(&"vulture")
	catalog.look_at(&"vulture")
	var dialog := await _open()
	assert_bool(dialog.cell_of(&"payday").is_fresh()).is_true()
	assert_bool(dialog.cell_of(&"vulture").is_fresh()).is_false()
	dialog.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	assert_bool(dialog.cell_of(&"payday").is_fresh()).is_false()
	assert_bool(catalog.is_fresh(&"payday")).is_false()
	var gone := [false]
	dialog.put_away.connect(func() -> void: gone[0] = true)
	dialog.close()
	await get_tree().process_frame
	assert_bool(gone[0]).is_true()
	assert_bool(button.has_focus()).is_true()
	var kept := Profile.at(Game.settings.profiles_dir(), Game.settings.profile.id)
	assert_bool(kept.catalog.is_fresh(&"payday")).is_false()
	assert_bool(kept.catalog.found(&"payday")).is_true()


## The cards fill the room they have and never grow past their own size.
func test_the_grid_fits_its_room() -> void:
	var dialog := await _open()
	var grid := dialog.joker_grid
	assert_float(grid.cell_size.x).is_less_equal(CatalogCell.shape().x)
	assert_float(grid.cell_size.x).is_greater(0.0)
	var rows := ceili(float(grid.cells().size()) / float(grid.columns))
	var tall := float(rows) * grid.cell_size.y + float(rows - 1) * grid.gap
	assert_float(tall).is_less_equal(grid.size.y + 0.5)
	var wide := float(grid.columns) * grid.cell_size.x + float(grid.columns - 1) * grid.gap
	assert_float(wide).is_less_equal(grid.size.x + 0.5)


## Every word a pane shows, in one string.
func _words_in(node: Node) -> String:
	var said := ""
	for child: Node in node.find_children("*", "", true, false):
		if child is Label and (child as Label).is_visible_in_tree():
			said += (child as Label).text + "\n"
		elif child is RichTextLabel and (child as RichTextLabel).is_visible_in_tree():
			said += (child as RichTextLabel).get_parsed_text() + "\n"
	return said


## STORY.md 6.6a: from stage 2 a line under the title says whose record it is, and a joker's pane
## carries its term, as in a match; before, neither.
func test_the_story_line_and_the_terms() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	Story.override = Story.Stage.CUSTOMER
	var before := await _open()
	assert_object(before.find_child("Kept", true, false)).is_null()
	before.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	assert_str(_words_in(before.joker_pane)).not_contains(StoryLines.TERMS[&"payday"])
	before.queue_free()
	Story.override = Story.Stage.PARTICIPANT
	var after := await _open()
	var line := after.find_child("Kept", true, false) as Label
	assert_str(line.text).is_equal("All terms are kept on file.")
	after.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	assert_str(_words_in(after.joker_pane)).contains(StoryLines.TERMS[&"payday"])


## `++ --catalog-all` in a debug build has the profile playing take everything once more.
func test_the_debug_argument_fills_the_catalog() -> void:
	CatalogDialog.read_arguments(PackedStringArray(["--other"]), Game.settings)
	assert_int(Game.settings.profile.catalog.jokers.size()).is_zero()
	CatalogDialog.read_arguments(PackedStringArray(["--catalog-all"]), Game.settings)
	var catalog := Game.settings.profile.catalog
	var jokers := CatalogDialog.ids_of(CatalogDialog.CATALOG.jokers)
	var items := CatalogDialog.ids_of(CatalogDialog.items_in_order())
	assert_int(catalog.found_of(jokers)).is_equal(jokers.size())
	assert_int(catalog.found_of(items)).is_equal(items.size())
	var kept := Profile.at(Game.settings.profiles_dir(), Game.settings.profile.id)
	assert_int(kept.catalog.found_of(jokers)).is_equal(jokers.size())
