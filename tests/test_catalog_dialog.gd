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
	_holder = Control.new()
	add_child(_holder)


func after_test() -> void:
	Story.override = -1
	CatalogDialog.detailed = false
	CatalogDialog.stack = 1
	# Gone before the scratch files are: a dialog going keeps the NEW tags it cleared, which would
	# write them again for the next test to read.
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
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
		catalog.use_item(item.id)
	var dialog := await _open()
	var jokers := CatalogDialog.CATALOG.jokers.size()
	var items := CatalogDialog.items_in_order().size()
	assert_str(dialog.tabs.get_tab_title(0)).is_equal("Jokers  2/%d" % jokers)
	assert_str(dialog.tabs.get_tab_title(1)).is_equal("Power-ups  %d/%d" % [items, items])
	assert_object(dialog.tabs.get_tab_icon(0)).is_null()
	assert_object(dialog.tabs.get_tab_icon(1)).is_not_null()
	# The row the tabs are drawn in says the same.
	assert_str(dialog.tab_bar.get_tab_title(0)).is_equal(dialog.tabs.get_tab_title(0))
	assert_object(dialog.tab_bar.get_tab_icon(1)).is_not_null()
	dialog.tab_bar.current_tab = 1
	assert_int(dialog.tabs.current_tab).is_equal(1)
	# The switches' binds in the row are the jokers' page's alone, and only for a gamepad.
	assert_bool(dialog.switch_hint.visible).is_false()
	dialog.switch_tab(-1)
	assert_bool(dialog.tab_hint.visible).is_equal(SettingsScreen.pad_plugged_in())
	# With keys in hand the row says the switch's and the field's keys; with the mouse alone, a
	# gamepad's buttons while one is plugged in, and nothing otherwise.
	var key := InputEventKey.new()
	key.keycode = KEY_A
	key.pressed = true
	dialog._input(key)
	assert_bool(dialog.switch_hint.visible).is_true()
	var said := ""
	for glyph: Node in dialog.switch_hint.find_children("*", "InputGlyph", true, false):
		said += (glyph as InputGlyph).caption + " "
	assert_str(said).contains("Alt").contains("Tab")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	dialog._input(click)
	assert_bool(dialog.switch_hint.visible).is_equal(SettingsScreen.pad_plugged_in())
	# The pane's foot swapped for the card come back to goes a frame on.
	await get_tree().process_frame


## A card never taken lies face down, and its pane says only that it was not found; one taken is
## the card as the hand draws it, its pane the match's, and how often it was taken.
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
	assert_str(said).not_contains("Stacks up to")
	assert_str(said).contains("Taken 2 times")
	assert_str(said).not_contains("×3 ")


## Detailed has the pane say what the hand says only for the details key held, its switch or that
## key, on the jokers' page alone; it is kept for the next time the catalog opens in the run.
func test_detailed_says_how_far_a_card_stacks() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	dialog.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	assert_str(_words_in(dialog.joker_pane)).not_contains("Stacks up to ×3.")
	dialog.detailed_switch.button_pressed = true
	assert_bool(CatalogDialog.detailed).is_true()
	assert_str(_words_in(dialog.joker_pane)).contains("Stacks up to ×3.")
	dialog._input(_pressed(CatalogDialog.DETAILED_ACTION))
	assert_bool(CatalogDialog.detailed).is_false()
	assert_bool(dialog.detailed_switch.button_pressed).is_false()
	dialog.set_detailed(true)
	dialog.switch_tab(1)
	dialog._input(_pressed(CatalogDialog.DETAILED_ACTION))
	assert_bool(CatalogDialog.detailed).is_true()
	dialog.free()
	var again := await _open()
	assert_bool(again.detailed_switch.button_pressed).is_true()


## The card under the cursor stays where it is, the size it was, and wears the cursor's frame,
## which the glide slides to as it does to a button.
func test_the_cursor_frames_a_card_without_moving_it() -> void:
	var dialog := await _open()
	var cell := dialog.cell_of(&"payday")
	var was := [cell.card.position, cell.card.scale]
	cell.grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_vector(cell.card.position).is_equal(was[0])
	assert_vector(cell.card.scale).is_equal(was[1])
	assert_bool(FocusGlide._glides(cell)).is_true()
	var inside := Rect2(cell.card.position, JokerCard.SIZE * cell.card.scale)
	assert_bool(Rect2(Vector2.ZERO, cell.size).encloses(inside)).is_true()


## The stack's field shows a joker as a stack as big as it stacks to, whatever the profile held of
## it, which is said beside the field and at the pane's foot; its halves and the hand's button step
## it, the latter round to one again.
func test_the_stack_field_goes_as_far_as_the_joker_stacks() -> void:
	var catalog := Game.settings.profile.catalog
	catalog.take_joker(&"payday")
	catalog.hold(&"payday", 2)
	catalog.take_joker(&"wild_card")
	catalog.hold(&"wild_card", 5)
	catalog.take_joker(&"insurance_policy")
	var dialog := await _open()
	dialog.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	var one := _words_in(dialog.joker_pane)
	assert_str(dialog.stepper.shown()).is_equal("×1")
	assert_str(dialog.stack_note.text).is_equal(CatalogDialog.HELD_UP_TO % 2)
	assert_bool(dialog.stepper.can_less()).is_false()
	assert_str(one).contains(CatalogDialog.HELD_UP_TO % 2)
	dialog.stepper.stepped.emit(1)
	assert_str(dialog.stepper.shown()).is_equal("×2")
	var two := _words_in(dialog.joker_pane)
	assert_str(two).contains("×2")
	assert_str(two).is_not_equal(one)
	# Past the biggest stack held, as far as the joker stacks, the held one still said.
	assert_bool(dialog.stepper.can_more()).is_true()
	dialog.stepper.stepped.emit(1)
	assert_str(dialog.stepper.shown()).is_equal("×3")
	assert_bool(dialog.stepper.can_more()).is_false()
	assert_str(_words_in(dialog.joker_pane)).contains("×3").contains(CatalogDialog.HELD_UP_TO % 2)
	assert_str(dialog.stack_note.text).is_equal(CatalogDialog.HELD_UP_TO % 2)
	dialog._input(_pressed(CatalogDialog.STACK_ACTION))
	assert_str(dialog.stepper.shown()).is_equal("×1")
	# Wild Card stacks to two, however many were held.
	dialog.set_stack(9)
	dialog.cell_of(&"wild_card").grab_focus()
	await get_tree().process_frame
	assert_int(dialog.stack_limit((dialog.cell_of(&"wild_card").card as JokerCard).joker)).is_equal(
		2
	)
	assert_str(dialog.stepper.shown()).is_equal("×2")
	# A joker that does not stack says so.
	dialog.cell_of(&"insurance_policy").grab_focus()
	await get_tree().process_frame
	assert_str(dialog.stack_note.text).is_equal(CatalogDialog.NO_STACK)
	assert_bool(dialog.stepper.can_more()).is_false()
	# A click on a half of the field steps it that way, as far as it goes.
	dialog.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	dialog.set_stack(1)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(dialog.stepper.size.x - 4.0, dialog.stepper.size.y * 0.5)
	dialog.stepper._gui_input(click)
	assert_str(dialog.stepper.shown()).is_equal("×2")
	dialog.stepper._gui_input(click)
	dialog.stepper._gui_input(click)
	assert_str(dialog.stepper.shown()).is_equal("×3")
	click.position.x = 4.0
	dialog.stepper._gui_input(click)
	assert_str(dialog.stepper.shown()).is_equal("×2")


## The card under the cursor is shown large over the pane where the column has room, its picture in
## its ring, the question mark for one never found, and not at all where the room would only hold it
## small; at the top of its room, whatever room the pane under it leaves.
func test_the_card_is_shown_large_where_there_is_room() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	dialog.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	var preview := dialog.joker_preview
	assert_int(preview.kind).is_equal(CardPreview.Kind.JOKER)
	assert_str(String(preview.id)).is_equal("payday")
	dialog.cell_of(&"aimbot").grab_focus()
	await get_tree().process_frame
	assert_int(preview.kind).is_equal(CardPreview.Kind.UNKNOWN)
	preview.size = Vector2.ONE * CardPreview.MOST * 2.0
	assert_bool(preview.is_shown()).is_true()
	assert_float(preview.side()).is_equal(CardPreview.MOST)
	preview.size = Vector2.ONE * CardPreview.LEAST * 0.5
	assert_bool(preview.is_shown()).is_false()


## The large card stays the one size and in one place whatever the pane under it says: its room is
## reckoned with the pane at its tallest.
func test_the_large_card_stays_put_as_the_pane_changes() -> void:
	var catalog := Game.settings.profile.catalog
	catalog.take_joker(&"payday")
	catalog.take_joker(&"guardian_angel")
	var dialog := await _open()
	var preview := dialog.joker_preview
	dialog.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	var was := [preview.global_position, preview.size]
	dialog.cell_of(&"guardian_angel").grab_focus()
	dialog.set_detailed(true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_vector(preview.global_position).is_equal(was[0])
	assert_vector(preview.size).is_equal(was[1])
	preview.size = JokerCard.SIZE * 0.5
	assert_bool(preview.is_shown()).is_false()


## An item's pane says what it does, its numbers and the set it comes in.
func test_an_items_pane_has_its_facts_and_set() -> void:
	Game.settings.profile.catalog.use_item(&"decoy_kart")
	var dialog := await _open()
	dialog.switch_tab(1)
	dialog.cell_of(&"decoy_kart").grab_focus()
	await get_tree().process_frame
	var item: PowerUp = load("res://data/powerups/decoy_kart.tres")
	assert_str(dialog.item_pane.title()).is_equal(item.display_name)
	var facts := dialog.item_pane.facts_shown()
	assert_array(facts[-1]).contains_exactly([CatalogDialog.SET, CatalogDialog.LATER_SET])
	assert_array(facts[0]).contains_exactly(item.facts()[0])
	assert_str(_words_in(dialog.item_pane)).contains(CatalogDialog.USED_ONCE)
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


## Every card on either page is the one size; the rows reach across the well from one side to the
## other, and the grid is as tall as its rows, for the well to scroll.
func test_the_cards_are_one_size_across_the_well() -> void:
	var dialog := await _open()
	dialog.switch_tab(1)
	await get_tree().process_frame
	var size_of := dialog.joker_grid.cell
	for grid: CardGrid in [dialog.joker_grid, dialog.item_grid]:
		assert_object(grid.get_parent()).is_instanceof(ScrollContainer)
		assert_object(grid.get_parent().get_parent()).is_instanceof(ListBox.Well)
		var cells := grid.cells()
		for cell: Control in cells:
			assert_vector(cell.size).is_equal(size_of)
		var last_across := cells[mini(grid.columns, cells.size()) - 1]
		if cells.size() >= grid.columns:
			var right := last_across.position.x + last_across.size.x
			assert_float(right).is_equal_approx(grid.size.x - CardGrid.ROOM, 1.5)
		var last := cells[-1]
		assert_float(last.position.y + last.size.y).is_less_equal(grid.size.y)
		assert_float(cells[0].position.x).is_equal(CardGrid.ROOM)


## A key or a pad button pressed for [param action].
func _pressed(action: StringName) -> InputEventAction:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	return press


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
	before.free()
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
	# Every stack held at its biggest, so the stack's field goes as far as the joker does.
	for joker: Joker in CatalogDialog.CATALOG.jokers:
		var most := maxi(joker.most, 1) if joker.stackable else 1
		assert_int(catalog.best_stack(joker.id)).is_equal(most)
	var kept := Profile.at(Game.settings.profiles_dir(), Game.settings.profile.id)
	assert_int(kept.catalog.found_of(jokers)).is_equal(jokers.size())
	assert_int(kept.catalog.best_stack(&"payday")).is_equal(3)
