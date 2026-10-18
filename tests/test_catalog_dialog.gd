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
	CatalogDialog.stack = CatalogDialog.WHOLE_STACK
	CatalogDialog.suit_shown = SuitFilter.ALL
	CatalogDialog.by_suit = false
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


## A page with nothing found on it yet has no count on its tab and no cards, only how to unlock it,
## in the middle of the well, and no pane; the cursor goes to Back. Once one is found it is the
## page it always is.
func test_a_page_with_nothing_found_says_how_to_begin_it() -> void:
	Game.settings.profile.catalog.use_item(&"bomb")
	var dialog := await _open()
	assert_str(dialog.tabs.get_tab_title(0)).is_equal(CatalogDialog.JOKERS)
	assert_bool(dialog.is_empty(0)).is_true()
	assert_bool(dialog.joker_grid.is_visible_in_tree()).is_false()
	assert_bool(dialog.joker_pane.is_visible_in_tree()).is_false()
	var empty := dialog.tabs.get_child(0).find_child("Empty", true, false) as Label
	assert_bool(empty.is_visible_in_tree()).is_true()
	assert_str(empty.text).is_equal(CatalogDialog.NO_JOKERS)
	assert_bool(dialog.back.has_focus()).is_true()
	assert_bool(dialog.switch_hint.visible).is_false()
	assert_str(dialog.tabs.get_tab_title(1)).is_equal(
		"%s  1 / %d" % [CatalogDialog.ITEMS, CatalogDialog.items_in_order().size()]
	)
	assert_bool(dialog.is_empty(1)).is_false()
	dialog.switch_tab(1)
	assert_bool(dialog.item_grid.is_visible_in_tree()).is_true()
	assert_bool(dialog.cell_of(&"boost").has_focus()).is_true()
	dialog.switch_tab(1)
	assert_bool(dialog.back.has_focus()).is_true()


## Jokers by rarity, then kind, then name; every joker and every item there, once.
func test_the_order() -> void:
	var jokers := CatalogDialog.jokers_in_order()
	assert_int(jokers.size()).is_equal(CatalogDialog.CATALOG.printed().size())
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


## The tab under the cursor is ruled round in gold, as a slip's box turns under it, so a pad's
## cursor on the row of tabs can be seen there.
func test_the_tab_under_the_cursor_is_ruled_in_gold() -> void:
	var dialog := await _open()
	var focus := dialog.tab_bar.get_theme_stylebox(&"tab_focus") as ProofStyle
	assert_object(focus).is_not_null()
	assert_int(focus.shape).is_equal(ProofStyle.Shape.TAB_FOCUS)
	dialog.tab_bar.grab_focus()
	await get_tree().process_frame
	assert_bool(dialog.tab_bar.has_focus()).is_true()


## Each tab says how many of how many were found, with the gold tick once all were.
func test_the_tabs_count_what_was_found() -> void:
	var catalog := Game.settings.profile.catalog
	catalog.take_joker(&"payday")
	catalog.take_joker(&"vulture")
	for item: PowerUp in CatalogDialog.items_in_order():
		catalog.use_item(item.id)
	var dialog := await _open()
	var jokers := CatalogDialog.CATALOG.printed().size()
	var items := CatalogDialog.items_in_order().size()
	assert_str(dialog.tabs.get_tab_title(0)).is_equal("Jokers  2 / %d" % jokers)
	assert_str(dialog.tabs.get_tab_title(1)).is_equal("Power-ups  %d / %d" % [items, items])
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
	assert_bool(dialog.tab_hint.visible).is_equal(not dialog._binds_for.is_empty())
	# With keys in hand the row says the switch's and the field's keys; with the mouse alone, a
	# gamepad's buttons while one is plugged in, and nothing otherwise.
	var key := InputEventKey.new()
	key.keycode = KEY_K
	key.pressed = true
	dialog._input(key)
	assert_bool(dialog.switch_hint.visible).is_true()
	var said := ""
	for glyph: Node in dialog.switch_hint.find_children("*", "InputGlyph", true, false):
		said += (glyph as InputGlyph).caption + " "
	assert_str(said).contains("Tab").contains("F")
	# And the page keys at the row's end, Q and E, for keys as for a pad.
	assert_bool(dialog.tab_hint.visible).is_true()
	said = ""
	for glyph: Node in dialog.tab_hint.find_children("*", "InputGlyph", true, false):
		said += (glyph as InputGlyph).caption + " "
	assert_str(said).contains("Q").contains("E")
	# Right after the tabs, as the loyalty program has them, rather than at the row's far end.
	await get_tree().process_frame
	var last := dialog.tab_bar.tab_count - 1
	var tabs_end := dialog.tab_bar.position.x + dialog.tab_bar.get_tab_rect(last).end.x
	assert_float(dialog.tab_hint.position.x).is_between(tabs_end, tabs_end + 40.0)
	assert_float(dialog.switch_hint.position.x).is_greater(dialog.tab_hint.position.x + 100.0)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	dialog._input(click)
	assert_bool(dialog.switch_hint.visible).is_equal(SettingsScreen.pad_plugged_in())
	# The pane's foot swapped for the card come back to goes a frame on.
	await get_tree().process_frame


## A card never taken is only its die line, not printed yet, and its pane says only that it was not
## found; one taken is the card as the hand draws it, its pane the match's, and how often it was
## taken.
func test_face_down_says_nothing_and_face_up_says_it_all() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	var hidden := dialog.cell_of(&"aimbot")
	assert_object(hidden.card).is_instanceof(DieLine)
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


## The jokers' page shows the cards of one suit alone, by its chips or the suit key stepping on, the
## cursor going to the first of them when its card went; laid out by suit they run Spades to Clubs
## and then the wild cards, and both are kept for the next time the catalog opens in the run.
func test_the_jokers_are_shown_by_suit() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	dialog.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	assert_str(dialog.cover.stamp_words()).is_empty()
	(dialog.switches.suits.get_node("Clubs") as Button).emit_signal(&"pressed")
	assert_int(CatalogDialog.suit_shown).is_equal(Joker.Suit.CLUBS)
	assert_str(dialog.cover.stamp_words()).is_equal("CLUBS ONLY  ·  12 OF 47")
	var shown := dialog.joker_grid.cells()
	assert_int(shown.size()).is_equal(12)
	for cell: Control in shown:
		var joker: Joker = CatalogDialog.CATALOG.by_id(StringName(cell.name))
		assert_int(joker.suit).is_equal(Joker.Suit.CLUBS)
	assert_bool(dialog.cell_of(&"payday").visible).is_false()
	assert_object(dialog._joker_at).is_same(shown[0])
	dialog._input(_pressed(CatalogDialog.SUIT_ACTION))
	assert_int(CatalogDialog.suit_shown).is_equal(Joker.Suit.WILD)
	assert_int(dialog.switches.suits.shown()).is_equal(Joker.Suit.WILD)
	dialog._input(_pressed(CatalogDialog.SUIT_ACTION))
	assert_int(dialog.joker_grid.cells().size()).is_equal(CatalogDialog.CATALOG.printed().size())
	dialog._input(_pressed(CatalogDialog.BY_SUIT_ACTION))
	assert_bool(dialog.switches.by_suit_switch.button_pressed).is_true()
	var last := -1
	for cell: Control in dialog.joker_grid.cells():
		var suit := CatalogDialog.CATALOG.by_id(StringName(cell.name)).suit
		assert_int(suit).is_greater_equal(last)
		last = suit
	dialog.show_suit(Joker.Suit.HEARTS)
	dialog.free()
	var again := await _open()
	assert_int(again.switches.suits.shown()).is_equal(Joker.Suit.HEARTS)
	assert_bool(again.switches.by_suit_switch.button_pressed).is_true()
	assert_int(again.joker_grid.cells().size()).is_equal(8)


## The card under the cursor stays where it is, the size it was, and wears the cursor's frame,
## which the glide slides to as it does to a button.
func test_the_cursor_frames_a_card_without_moving_it() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
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
	# Every joker at its whole stack to start with.
	assert_str(dialog.stepper.shown()).is_equal("×3")
	dialog.cell_of(&"wild_card").grab_focus()
	await get_tree().process_frame
	assert_str(dialog.stepper.shown()).is_equal("×2")
	dialog.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	dialog.set_stack(1)
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


## A joker's suit is shown in the side column, GAME.md 8.8: as a little card under the loupe while
## there is room for the large card, and before the name where there is not, the room the large
## card would have had going to the pane rather than a gap over it.
func test_the_suit_is_under_the_loupe_or_before_the_name() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	var dialog := await _open()
	dialog.cell_of(&"payday").grab_focus()
	for i: int in 3:
		await get_tree().process_frame
	var pane := dialog.joker_pane
	assert_bool(dialog.joker_preview.is_shown()).is_true()
	assert_int(pane.title_suit()).is_equal(-1)
	var column := dialog.joker_preview.get_parent() as VBoxContainer
	CatalogPage.size_preview(column, dialog.joker_preview, pane)
	var room := dialog.joker_preview.custom_minimum_size.y
	assert_float(room).is_greater_equal(CardPreview.LEAST)
	dialog.joker_preview.size = Vector2.ONE * CardPreview.LEAST * 0.5
	dialog.cover.queue_redraw()
	for i: int in 3:
		await get_tree().process_frame
	assert_int(pane.title_suit()).is_equal(Joker.Suit.DIAMONDS)
	assert_bool(pane._title_mark.visible).is_true()
	# Too little room for the large card leaves it none.
	dialog.joker_preview.custom_minimum_size.y = 0.0
	column.size.y = column.get_combined_minimum_size().y + CardPreview.LEAST * 0.5
	CatalogPage.size_preview(column, dialog.joker_preview, pane)
	assert_float(dialog.joker_preview.custom_minimum_size.y).is_equal(0.0)


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


## A tab wears NEW while a card found on its page has not been looked at, over its own top right
## corner, and not once the last of them has; the other tab, with nothing new, never does.
func test_a_tab_wears_new_while_its_page_has_a_new_card() -> void:
	var catalog := Game.settings.profile.catalog
	catalog.take_joker(&"payday")
	var dialog := await _open()
	await get_tree().process_frame
	var tag := dialog.tab_tags.of(0)
	assert_object(tag).is_not_null()
	assert_object(dialog.tab_tags.of(1)).is_null()
	assert_object(tag.get_parent()).is_same(dialog.tab_bar)
	var tab := dialog.tab_bar.get_tab_rect(0)
	assert_float(tag.get_rect().end.x).is_equal_approx(tab.end.x + CatalogCell.NEW_OUT.x, 1.0)
	assert_float(tag.position.y).is_less(tab.position.y)
	dialog.cell_of(&"payday").grab_focus()
	await get_tree().process_frame
	assert_object(dialog.tab_tags.of(0)).is_null()


## Every card on either page is the one size; the rows reach across the well from one side to the
## other, and the grid is as tall as its rows, for the well to scroll.
func test_the_cards_are_one_size_across_the_well() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	Game.settings.profile.catalog.use_item(&"bomb")
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
## The loyalty program, the catalog and the achievements answer the same keys the same way,
## GAME.md 8.5, see [DialogBinds]: the view key changes the view, the option key is the second
## switch, and the page keys turn the pages; fixed, and none of them a row of the controls a
## player may rebind for driving.
func test_the_dialogs_share_their_binds() -> void:
	assert_str(String(LoyaltyDialog.LIST_ACTION)).is_equal(InputActions.MENU_VIEW)
	assert_str(String(CatalogDialog.DETAILED_ACTION)).is_equal(InputActions.MENU_VIEW)
	assert_str(String(AchievementsDialog.SORT_ACTION)).is_equal(InputActions.MENU_VIEW)
	assert_str(String(LoyaltyDialog.CARD_ACTION)).is_equal(InputActions.MENU_OPTION)
	assert_str(String(CatalogDialog.STACK_ACTION)).is_equal(InputActions.MENU_OPTION)
	assert_str(String(AchievementsDialog.HIDE_ACTION)).is_equal(InputActions.MENU_OPTION)
	assert_str(String(LoyaltyDialog.SHEET_BACK)).is_equal(InputActions.MENU_PAGE_PREV)
	assert_str(String(LoyaltyDialog.SHEET_ON)).is_equal(InputActions.MENU_PAGE_NEXT)
	for action: StringName in InputActions.MENU:
		assert_bool(action in SettingsScreen.REBINDABLE).is_false()
		assert_bool(InputMap.has_action(action)).is_true()
	var keys := {
		InputActions.MENU_PAGE_PREV: [KEY_Q, JOY_BUTTON_LEFT_SHOULDER],
		InputActions.MENU_PAGE_NEXT: [KEY_E, JOY_BUTTON_RIGHT_SHOULDER],
		InputActions.MENU_VIEW: [KEY_TAB, JOY_BUTTON_Y],
		InputActions.MENU_OPTION: [KEY_F, JOY_BUTTON_X],
		InputActions.MENU_FILTER: [KEY_R, -1],
		InputActions.MENU_SORT: [KEY_T, -1],
		InputActions.MENU_NEXT_NEW: [KEY_N, JOY_BUTTON_BACK],
	}
	for action: StringName in keys:
		var key := InputEventKey.new()
		key.physical_keycode = keys[action][0]
		key.keycode = keys[action][0]
		key.pressed = true
		assert_bool(key.is_action_pressed(action)).override_failure_message(action).is_true()
		if keys[action][1] < 0:
			continue
		var button := InputEventJoypadButton.new()
		button.button_index = keys[action][1]
		button.pressed = true
		assert_bool(button.is_action_pressed(action)).override_failure_message(action).is_true()
	# The catalog's suit and order are the pad's triggers.
	for action: StringName in [InputActions.MENU_FILTER, InputActions.MENU_SORT]:
		var trigger := InputEventJoypadMotion.new()
		trigger.axis = (
			JOY_AXIS_TRIGGER_RIGHT if action == InputActions.MENU_FILTER else JOY_AXIS_TRIGGER_LEFT
		)
		trigger.axis_value = 1.0
		assert_bool(trigger.is_action_pressed(action)).override_failure_message(action).is_true()


## Next new's bind, N and a pad's View, is no other action's, the kart's and the hand's or the
## dialogs': free in all three dialogs, whatever else they hear. The pad's button is called View, as
## today's pads print it, not Back, which a dialog's own Back is.
func test_next_new_has_a_bind_of_its_own() -> void:
	for table: Dictionary[StringName, Array] in [InputActions.DEFAULTS, InputActions.MENU]:
		for action: StringName in table:
			if action == NextNew.ACTION:
				continue
			for descriptor: Dictionary in table[action]:
				var used: Array = [descriptor.get("key"), descriptor.get("button")]
				assert_bool(KEY_N in used).override_failure_message(action).is_false()
				assert_bool(JOY_BUTTON_BACK in used).override_failure_message(action).is_false()
	for action: StringName in InputActions.UI_EXTRAS:
		for descriptor: Dictionary in InputActions.UI_EXTRAS[action]:
			assert_bool(descriptor.get("button") == JOY_BUTTON_BACK).is_false()
	var view := InputEventJoypadButton.new()
	view.button_index = JOY_BUTTON_BACK
	assert_str(InputActions.event_text(view)).is_equal("View")
	var press := InputEventKey.new()
	press.physical_keycode = KEY_N
	for action: StringName in [&"ui_accept", &"ui_cancel", &"ui_focus_next", &"ui_page_down"]:
		assert_bool(press.is_action(action)).override_failure_message(action).is_false()


## The page keys stand right after the last tab, GAME.md 8.5, see [method DialogBinds.beside_tabs],
## however wide the bar is laid out; while the tabs do not all fit and the bar scrolls them, at the
## row's end.
func test_the_page_keys_stand_beside_the_tabs() -> void:
	var row := HBoxContainer.new()
	row.size = Vector2(1000.0, 40.0)
	var bar := TabBar.new()
	bar.clip_tabs = true
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_tab("One")
	bar.add_tab("Two")
	row.add_child(bar)
	var hint := Control.new()
	hint.name = "Hint"
	hint.custom_minimum_size = Vector2(60.0, 20.0)
	row.add_child(hint)
	DialogBinds.beside_tabs(row, bar, hint.name, 20.0)
	add_child(row)
	await get_tree().process_frame
	var end := bar.get_tab_rect(1).end.x
	assert_float(end).is_less(500.0)
	assert_float(hint.position.x).is_equal_approx(end + 20.0, 0.5)
	for i: int in 30:
		bar.add_tab("A tab with a long name %d" % i)
	row.size = Vector2(400.0, 40.0)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(bar.get_offset_buttons_visible()).is_true()
	assert_float(hint.position.x).is_equal_approx(400.0 - 60.0, 0.5)
	row.queue_free()
	await get_tree().process_frame


## Q and E turn the catalog's pages, as the shoulders do on a pad, and WASD walks the cards as the
## arrows do.
func test_the_page_keys_and_wasd() -> void:
	var catalog := Game.settings.profile.catalog
	for joker: Joker in CatalogDialog.jokers_in_order().slice(0, 4):
		catalog.take_joker(joker.id)
	catalog.use_item(&"bomb")
	var dialog := await _open()
	assert_int(dialog.tabs.current_tab).is_equal(0)
	dialog._input(_pressed(InputActions.MENU_PAGE_NEXT))
	assert_int(dialog.tabs.current_tab).is_equal(1)
	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_LEFT_SHOULDER
	shoulder.pressed = true
	dialog._input(shoulder)
	assert_int(dialog.tabs.current_tab).is_equal(0)
	await get_tree().process_frame
	var first := get_viewport().gui_get_focus_owner()
	assert_object(first).is_instanceof(CatalogCell)
	dialog._input(_pressed(InputActions.MENU_RIGHT))
	var next := get_viewport().gui_get_focus_owner()
	assert_object(next).is_not_same(first)
	assert_object(next).is_same(first.find_valid_focus_neighbor(SIDE_RIGHT))
	dialog._input(_pressed(InputActions.MENU_LEFT))
	assert_object(get_viewport().gui_get_focus_owner()).is_same(first)
	# The pane's foot swapped for each card the cursor came to goes a frame on.
	await get_tree().process_frame


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


## Short of room, as a phone's screen is at its UI scale, a dialog fills the screen, its corners
## square and less room inside its edge, a well's cards nearer its edge and the column nearer the
## well, a flush well's still at its very edge; with the room, the shade shows round it again.
func test_a_dialog_fills_a_short_screen() -> void:
	var pane: PanelContainer = auto_free(MenuTheme.pane())
	var around: MarginContainer = auto_free(MarginContainer.new())
	var row := HBoxContainer.new()
	pane.add_child(row)
	var well := ListBox.Well.new()
	row.add_child(well)
	var flush := ListBox.Well.new()
	flush.flush = true
	row.add_child(flush)
	var look := pane.get_theme_stylebox(&"panel") as TicketStyle
	var squares: Array[bool] = []
	for room: Vector2 in [Vector2(1600.0, 720.0), Vector2(1920.0, 1080.0)]:
		var full := room.y < CatalogDialog.SHORT
		CatalogDialog.fill_screen(pane, around, room)
		var margin := 0 if full else int(room.y * CatalogDialog.AROUND)
		assert_int(around.get_theme_constant(&"margin_left")).is_equal(margin)
		assert_int(around.get_theme_constant(&"margin_top")).is_equal(margin)
		for notched: bool in [look.notch_top, look.notch_left, look.notch_right, look.notch_bottom]:
			squares.append(notched == full)
		var inside := (
			CatalogDialog.FULL_INSIDE if full else MenuTheme.PANE_INSET + MenuTheme.PANE_GAP
		)
		assert_float(look.get_margin(SIDE_LEFT)).is_equal(inside)
		var inset := CatalogDialog.FULL_WELL_INSET if full else ListBox.INSET
		assert_int(well.get_theme_constant(&"margin_left")).is_equal(inset)
		assert_int(flush.get_theme_constant(&"margin_left")).is_equal(0)
		var gap := CatalogDialog.FULL_GAP if full else CatalogDialog.PANE_GAP
		assert_int(row.get_theme_constant(&"separation")).is_equal(int(gap))
	assert_array(squares).not_contains([true])


## Short of room the head is the settings', GAME.md 8.8: the title at its left, the story's line
## beside it and Back at its right, with no foot; with the room, the title over the middle, the line
## under it and Back at the right of the foot. The cursor stays on Back as it moves.
func test_the_head_short_of_room() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	Story.override = Story.Stage.PARTICIPANT
	var dialog := await _open()
	var head := dialog.find_child("Head", true, false) as HBoxContainer
	var foot := dialog.find_child("Foot", true, false) as HBoxContainer
	var line := dialog.find_child("Kept", true, false) as Label
	var short := dialog.get_viewport().get_visible_rect().size.y < CatalogDialog.SHORT
	assert_bool(dialog.back.get_parent() == head).is_equal(short)
	dialog.back.grab_focus()
	dialog._lay_head(true)
	assert_object(dialog.back.get_parent()).is_same(head)
	assert_int(dialog.back.get_index()).is_equal(head.get_child_count() - 1)
	assert_object(line.get_parent()).is_same(head)
	assert_bool(foot.visible).is_false()
	assert_bool(dialog.back.has_focus()).is_true()
	dialog._lay_head(false)
	assert_object(dialog.back.get_parent()).is_same(foot)
	assert_object(line.get_parent()).is_same(head.get_parent())
	assert_int(line.get_index()).is_equal(head.get_index() + 1)
	assert_bool(foot.visible).is_true()
	assert_bool(dialog.back.has_focus()).is_true()


## `++ --catalog-all` in a debug build has the profile playing take everything once more.
func test_the_debug_argument_fills_the_catalog() -> void:
	CatalogDialog.read_arguments(PackedStringArray(["--other"]), Game.settings)
	assert_int(Game.settings.profile.catalog.jokers.size()).is_zero()
	CatalogDialog.read_arguments(PackedStringArray(["--catalog-all"]), Game.settings)
	var catalog := Game.settings.profile.catalog
	var jokers := CatalogDialog.ids_of(CatalogDialog.CATALOG.printed())
	var items := CatalogDialog.ids_of(CatalogDialog.items_in_order())
	assert_int(catalog.found_of(jokers)).is_equal(jokers.size())
	assert_int(catalog.found_of(items)).is_equal(items.size())
	# Every stack held at its biggest, so the stack's field goes as far as the joker does.
	for joker: Joker in CatalogDialog.CATALOG.printed():
		var most := maxi(joker.most, 1) if joker.stackable else 1
		assert_int(catalog.best_stack(joker.id)).is_equal(most)
	var kept := Profile.at(Game.settings.profiles_dir(), Game.settings.profile.id)
	assert_int(kept.catalog.found_of(jokers)).is_equal(jokers.size())
	assert_int(kept.catalog.best_stack(&"payday")).is_equal(3)


## A finger at [param at] on the screen, as a phone sends it: the mouse it makes of it first, then
## the finger itself; down, or up.
func _finger(at: Vector2, down: bool) -> void:
	var click := InputEventMouseButton.new()
	click.device = InputEvent.DEVICE_ID_EMULATION
	click.button_index = MOUSE_BUTTON_LEFT
	click.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	click.pressed = down
	click.position = at
	click.global_position = at
	get_viewport().push_input(click, true)
	var touch := InputEventScreenTouch.new()
	touch.pressed = down
	touch.position = at
	get_viewport().push_input(touch, true)


## On a touch screen a swipe begun on a card scrolls rather than picking it, and only a tap, a
## finger let go where it was put down, picks the card under it.
func test_on_a_touch_screen_only_a_tap_picks_a_card() -> void:
	Game.settings.profile.catalog.take_joker(&"payday")
	Game.settings.profile.catalog.take_joker(&"odometer")
	var was_touch := TouchInput.enabled
	TouchInput.enabled = true
	var dialog := await _open()
	var first := dialog.cell_of(&"payday")
	var other := dialog.cell_of(&"odometer")
	first.grab_focus()
	await get_tree().process_frame
	var at := other.get_global_transform_with_canvas() * (other.size * 0.5)
	_finger(at, true)
	var drag := InputEventScreenDrag.new()
	drag.position = at + Vector2(0.0, -60.0)
	drag.relative = Vector2(0.0, -60.0)
	get_viewport().push_input(drag, true)
	_finger(at + Vector2(0.0, -60.0), false)
	await get_tree().process_frame
	assert_object(get_viewport().gui_get_focus_owner()).is_same(first)
	_finger(at, true)
	_finger(at, false)
	await get_tree().process_frame
	assert_object(get_viewport().gui_get_focus_owner()).is_same(other)
	TouchInput.enabled = was_touch


## A pad held right over the cards walks on along them, GAME.md 4.2: the push itself one card, then
## after a moment a card every so often for as long as it is held.
func test_a_pad_held_over_walks_on_along_the_cards() -> void:
	for joker: Joker in CatalogDialog.CATALOG.printed():
		Game.settings.profile.catalog.take_joker(joker.id)
	var dialog := await _open()
	var first := dialog.joker_grid.get_child(0) as Control
	first.grab_focus()
	var repeat: PadRepeat = auto_free(PadRepeat.new())
	repeat.set_process(false)
	add_child(repeat)
	var held: Array[StringName] = [&"ui_right"]
	repeat.hold(0, held, PadRepeat.DELAY * 0.9)
	assert_bool(first.has_focus()).is_true()
	repeat.hold(0, held, PadRepeat.DELAY * 0.1 + 0.001)
	for i: int in 2:
		repeat.hold(0, held, PadRepeat.EVERY + 0.001)
	assert_object(get_viewport().gui_get_focus_owner()).is_same(dialog.joker_grid.get_child(3))
	# The pane's earlier cards go at the end of the frame.
	await get_tree().process_frame
	await get_tree().process_frame


## A key or a pad held along a row of cards stops at the row's end, rather than going on to the
## tabs over the cards or to the pane beside them; within a row it walks on as ever.
func test_the_cursor_stops_at_the_ends_of_a_row() -> void:
	for joker: Joker in CatalogDialog.CATALOG.printed():
		Game.settings.profile.catalog.take_joker(joker.id)
	var dialog := await _open()
	var grid := dialog.joker_grid
	var cells := grid.cells()
	var columns := grid.columns
	assert_int(columns).is_greater(1)
	assert_int(cells.size()).is_greater(columns * 2)
	var viewport := get_viewport()
	var row_start := cells[columns]
	row_start.grab_focus()
	viewport.push_input(_pressed(&"ui_left"))
	assert_object(viewport.gui_get_focus_owner()).is_same(row_start)
	var row_end := cells[columns * 2 - 1]
	row_end.grab_focus()
	viewport.push_input(_pressed(&"ui_right"))
	assert_object(viewport.gui_get_focus_owner()).is_same(row_end)
	viewport.push_input(_pressed(&"ui_left"))
	assert_object(viewport.gui_get_focus_owner()).is_same(cells[columns * 2 - 2])
	# The last card ends its row too, a short one or not.
	var last := cells[-1]
	last.grab_focus()
	viewport.push_input(_pressed(&"ui_right"))
	assert_object(viewport.gui_get_focus_owner()).is_same(last)
	await get_tree().process_frame
	await get_tree().process_frame


## Next new, GAME.md 8.8: how many cards wear NEW over its corner, and pressed, the cursor at once
## on the next of them after the one it is on, the jokers' in their order and then the power-ups',
## the page turned to it, which takes the tag off, the tabs' too, kept as the dialog goes; gone once
## none is new.
func test_next_new_walks_the_new_cards() -> void:
	var catalog := Game.settings.profile.catalog
	var order := CatalogDialog.jokers_in_order()
	var fresh: Array[StringName] = [order[0].id, order[2].id, order[5].id, &"bomb"]
	for id: StringName in fresh.slice(0, 3):
		catalog.take_joker(id)
	catalog.use_item(&"bomb")
	var dialog := await _open()
	var next := dialog.next_new
	# The first card has the cursor, and is no longer new.
	assert_bool(catalog.is_fresh(fresh[0])).is_false()
	assert_bool(next.visible).is_true()
	assert_str(next.count.text).is_equal("3")
	assert_str(next.button.accessibility_description).is_equal(NextNew.LEFT % 3)
	# Its face the NEW tag with the way on, its words a screen reader's.
	assert_str(next.button.text).is_empty()
	assert_str((next.button.find_child("*", true, false) as Node).name).is_equal("Face")
	assert_str(next.button.accessibility_name).is_equal(NextNew.WORDS)
	assert_int(next.button.focus_mode).is_equal(Control.FOCUS_NONE)
	assert_int(next.button.mouse_default_cursor_shape).is_equal(Control.CURSOR_POINTING_HAND)
	for i: int in range(1, fresh.size()):
		next.button.pressed.emit()
		var cell := dialog.cell_of(fresh[i])
		assert_bool(cell.has_focus()).is_true()
		# A moment bigger, over the cards round it, for the eye.
		assert_bool(cell._pop.is_running()).is_true()
		assert_int(cell.z_index).is_equal(1)
		assert_bool(cell.is_fresh()).is_false()
		assert_bool(catalog.is_fresh(fresh[i])).is_false()
		assert_int(dialog.tabs.current_tab).is_equal(0 if i < 3 else 1)
		assert_str(next.count.text).is_equal(str(fresh.size() - 1 - i))
	assert_object(dialog.tab_tags.of(0)).is_null()
	assert_object(dialog.tab_tags.of(1)).is_null()
	assert_bool(next.visible).is_false()
	dialog.close()
	await get_tree().process_frame
	var kept := Profile.at(Game.settings.profiles_dir(), Game.settings.profile.id)
	for id: StringName in fresh:
		assert_bool(kept.catalog.is_fresh(id)).is_false()


## From a card after the last new one, Next new goes round to the first, back on the jokers' page
## from the power-ups' and from the hands'; and its bind, N or a pad's View, presses it.
func test_next_new_goes_round_and_has_its_bind() -> void:
	var catalog := Game.settings.profile.catalog
	var order := CatalogDialog.jokers_in_order()
	for joker: Joker in order.slice(0, 7):
		catalog.take_joker(joker.id)
	for id: StringName in [order[0].id, order[2].id, order[4].id, order[6].id]:
		catalog.look_at(id)
	catalog.use_item(&"bomb")
	catalog.look_at(&"bomb")
	var dialog := await _open()
	dialog.cell_of(order[6].id).grab_focus()
	var press := InputEventKey.new()
	press.physical_keycode = KEY_N
	press.keycode = KEY_N
	press.pressed = true
	dialog._input(press)
	assert_bool(dialog.cell_of(order[1].id).has_focus()).is_true()
	# From the hands' page, which has no cards, from the start.
	dialog.switch_tab(2)
	var view := InputEventJoypadButton.new()
	view.button_index = JOY_BUTTON_BACK
	view.pressed = true
	dialog._input(view)
	assert_int(dialog.tabs.current_tab).is_equal(0)
	assert_bool(dialog.cell_of(order[3].id).has_focus()).is_true()
	# From the power-ups' page, round to the jokers'.
	dialog.switch_tab(1)
	dialog._input(_pressed(InputActions.MENU_NEXT_NEW))
	assert_int(dialog.tabs.current_tab).is_equal(0)
	assert_bool(dialog.cell_of(order[5].id).has_focus()).is_true()
	assert_bool(dialog.next_new.visible).is_false()
	assert_bool(dialog.next_new.heard(press)).is_false()
	await get_tree().process_frame


## A card new among the jokers of a suit the page leaves out: Next new shows every suit, and the
## cursor on it.
func test_next_new_shows_a_suit_left_out() -> void:
	var catalog := Game.settings.profile.catalog
	var joker: Joker = CatalogDialog.jokers_in_order()[1]
	catalog.take_joker(joker.id)
	var dialog := await _open()
	var other := Joker.Suit.SPADES if joker.suit != Joker.Suit.SPADES else Joker.Suit.HEARTS
	dialog.show_suit(other)
	assert_bool(dialog.cell_of(joker.id).visible).is_false()
	dialog.next_new_card()
	assert_int(CatalogDialog.suit_shown).is_equal(SuitFilter.ALL)
	assert_bool(dialog.cell_of(joker.id).visible).is_true()
	assert_bool(dialog.cell_of(joker.id).has_focus()).is_true()
	assert_bool(catalog.is_fresh(joker.id)).is_false()
	await get_tree().process_frame


## Next new stands at the head's right: after the title, which an empty room as wide as it at the
## head's left keeps over the middle, with the room; before Back short of it, with no room kept.
func test_next_new_stands_at_the_heads_right() -> void:
	Game.settings.profile.catalog.take_joker(CatalogDialog.jokers_in_order()[1].id)
	var dialog := await _open()
	var head := dialog.find_child("Head", true, false) as HBoxContainer
	var balance := head.get_node("Balance") as Control
	dialog._lay_head(false)
	dialog._balance_head()
	assert_object(dialog.next_new.get_parent()).is_same(head)
	assert_int(dialog.next_new.get_index()).is_equal(head.get_child_count() - 1)
	assert_bool(balance.visible).is_true()
	assert_float(balance.custom_minimum_size.x).is_equal(
		dialog.next_new.get_combined_minimum_size().x
	)
	dialog._lay_head(true)
	dialog._balance_head()
	assert_int(dialog.next_new.get_index()).is_equal(dialog.back.get_index() - 1)
	assert_bool(balance.visible).is_false()
	dialog._lay_head(false)
	dialog.next_new_card()
	dialog._balance_head()
	assert_bool(dialog.next_new.visible).is_false()
	assert_bool(balance.visible).is_false()
	# The pane's foot swapped for the card the cursor came to goes a frame on.
	await get_tree().process_frame
