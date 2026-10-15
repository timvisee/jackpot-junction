class_name CatalogPage
extends RefCounted
## The pages of the catalog, GAME.md 8.8: a page of cards, the jokers' or the power-ups', with its
## column beside the sheet, and the page of the hands the jokers make, a pay table printed on the
## sheet, see [HandsSheet].


## A page called [param named]: [param grid] in the well, scrolling down it where the cards are more
## than it has room for, and in the column beside it, with room round them, [param preview] over
## [param pane], the one taking whatever room the column has left. With none of its cards found
## yet, [param none] in the middle of the well in place of them, and no column, there being nothing
## to describe.
static func build(
	named: String, grid: CardGrid, pane: Control, preview: CardPreview, none: String
) -> HBoxContainer:
	var page := HBoxContainer.new()
	page.name = named
	page.add_theme_constant_override("separation", int(CatalogDialog.PANE_GAP))
	var well := ListBox.Well.new()
	well.name = "Well"
	# The sheet is drawn under it, see [ProofCover].
	well.bare = true
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(well)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	well.add_child(scroll)
	# On a touch screen a swipe scrolls the cards and only a tap picks one.
	TouchScroll.attach(scroll)
	grid.name = "Grid"
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	var found := false
	for cell: Node in grid.get_children():
		found = found or (cell as CatalogCell).found
	var empty := Label.new()
	empty.name = "Empty"
	empty.text = none
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Type.text(empty, Type.BODY, HouseTheme.INK_FAINT)
	empty.visible = not found
	well.add_child(empty)
	scroll.visible = found
	var side := MarginContainer.new()
	side.name = "Side"
	side.custom_minimum_size.x = CatalogDialog.PANE_ROOM
	for edge: String in ["left", "right", "top", "bottom"]:
		side.add_theme_constant_override("margin_%s" % edge, CatalogDialog.PANE_AROUND)
	page.add_child(side)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", CatalogDialog.SWITCHES_UNDER)
	side.add_child(column)
	preview.name = "Preview"
	column.add_child(preview)
	pane.name = "Pane"
	column.add_child(pane)
	side.visible = found
	var sizing := size_preview.bind(column, preview, pane)
	column.resized.connect(sizing)
	pane.resized.connect(sizing)
	return page


## The large picture's room in [param column]: whatever the column has over [param pane] and what
## is under it, the pane counted as at least [constant CatalogDialog.PANE_KEPT] tall, so the
## picture's size does not move with what the pane says, nor its top with anything; and no more
## than the picture takes, so the pane stands right under it.
static func size_preview(column: VBoxContainer, preview: CardPreview, pane: Control) -> void:
	var gap := float(column.get_theme_constant(&"separation"))
	var rest := 0.0
	for child: Node in column.get_children():
		var control := child as Control
		if control == null or control == preview or not control.visible:
			continue
		var tall := control.size.y
		if control == pane:
			tall = maxf(tall, CatalogDialog.PANE_KEPT)
		rest += tall + gap
	var room := clampf(floorf(column.size.y - rest), 0.0, CardPreview.MOST)
	# Too little to show it in, the pane has it all, rather than a gap over it.
	room = room if room >= CardPreview.LEAST else 0.0
	if not is_equal_approx(preview.custom_minimum_size.y, room):
		preview.custom_minimum_size.y = room


## The page of the hands, GAME.md 7.3 and 8.8: the pay table on the sheet, every hand with its
## cards, what it is, what it pays and how often [param profile] has made it; a sheet of its own,
## so it scrolls where the screen is short, and no column, there being no card to describe.
static func hands(profile: Profile) -> HBoxContainer:
	var page := HBoxContainer.new()
	page.name = CatalogDialog.HANDS
	var well := ListBox.Well.new()
	well.name = "Well"
	well.bare = true
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(well)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	well.add_child(scroll)
	TouchScroll.attach(scroll)
	var sheet := HandsSheet.new()
	sheet.name = "Hands"
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for hand: int in JokerHands.Hand.size():
		var field := PlayerStats.hand_field(hand)
		sheet.made.append(roundi(LifetimeStats.value_of(profile, field)))
	scroll.add_child(sheet)
	# Never empty: every hand is in the table from the start.
	var empty := Label.new()
	empty.name = "Empty"
	empty.visible = false
	well.add_child(empty)
	return page
