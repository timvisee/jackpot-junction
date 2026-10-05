class_name HouseTheme
extends RefCounted
## The house's look for every control the engine draws, GAME.md 8.1a: made once and laid over the
## engine's own default theme at start, so every button, box, list, tab, slider, field and scroll
## bar in the game is cut from the house's stock without each screen dressing its own. Over the
## default rather than on the root window, since a theme on a window stops at the first canvas
## layer, and the pause menu, the HUD and every pane over a room live in one. A screen that wants
## something else says so on the control, as the HUD's own bars do.
##
## What is here is the stock, the foil and the shapes they are cut to, see [TicketStyle],
## [TabStyle], [LaneStyle] and the pictures of [HouseArt]. Sizes of type stay with whoever sets
## them, through [Type].

## The stock, GAME.md 8.1a: the dark card everything driven past or clicked through is printed on,
## raised a step for a control, lit a step under the cursor and pressed a step darker.
const STOCK := Color("#131218")
const STOCK_RAISED := Color("#1b1a22")
const STOCK_LIT := Color("#27252f")
const STOCK_DOWN := Color("#0e0d12")
## The paper, for documents and nothing else, and the ink printed on it.
const PAPER := Color("#f2ead6")
const INK := Color("#211f24")
## The foil: the house's gold, with the highlight and the low it runs between where it is laid on
## as a fill rather than a line.
const FOIL := Palette.CHIP_GOLD
const FOIL_HIGH := Color("#ffe39a")
const FOIL_LOW := Color("#c38d2b")
## The ink of the words on a foil button.
const ON_FOIL := Color("#22190a")
## Words on stock, and the quieter words beside them.
const WORDS := Color(0.92, 0.91, 0.94)
const QUIET := Color(0.66, 0.65, 0.71)
## How strongly the foil hairline inside a control's edge shows, at rest, lit, and held down.
const RIM := 0.13
const RIM_LIT := 0.55
const RIM_DOWN := 0.4
## The type variation of a button that moves things on, GAME.md 8.1a: Done, Rematch, Resume.
const PRIMARY := &"PrimaryButton"

static var _theme: Theme


## The house's theme, made the first time it is asked for.
static func theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


## Lays the house's theme over the engine's default, once, before any control is made.
static func install() -> void:
	ThemeDB.get_default_theme().merge_with(theme())


static func _build() -> Theme:
	var made := Theme.new()
	made.default_font = Type.TEXT
	_buttons(made)
	_primary(made)
	_options(made)
	_switches(made)
	_fields(made)
	_lists(made)
	_tabs(made)
	_sliders(made)
	_scroll_bars(made)
	_bars(made)
	_tooltips(made)
	made.set_font(&"bold_font", &"RichTextLabel", Type.STRONG)
	return made


## The four looks of a button: a ticket of stock with a foil hairline inside its edge at rest; lit,
## rimmed in gold and with the lane chevron at its left end under the cursor, which is the same
## look as having the focus, since a menu driven with a stick has to say where the cursor is; held
## down, darker, and its words a little lower, the way a stamp goes down.
static func button_looks(
	across := 22.0, down := 12.0, notch := 9.0
) -> Dictionary[StringName, StyleBox]:
	var normal := TicketStyle.cut(Color(STOCK_RAISED, 0.96), notch, across, down)
	normal.frame = Color(FOIL, RIM)
	var lit := TicketStyle.cut(STOCK_LIT, notch, across, down)
	lit.frame = Color(FOIL, RIM_LIT)
	lit.border = FOIL
	lit.chevron = FOIL
	var held := TicketStyle.cut(STOCK_DOWN, notch, across, down)
	held.frame = Color(FOIL, RIM_DOWN)
	held.border = FOIL
	held.chevron = FOIL
	held.content_margin_top = down + 2.0
	held.content_margin_bottom = down - 2.0
	var off := TicketStyle.cut(Color(STOCK_RAISED, 0.5), notch, across, down)
	off.frame = Color(FOIL, RIM * 0.4)
	return {
		&"normal": normal,
		&"hover": lit,
		&"focus": lit,
		&"pressed": held,
		&"hover_pressed": held,
		&"disabled": off,
	}


static func _buttons(made: Theme) -> void:
	var looks := button_looks()
	for state: StringName in looks:
		made.set_stylebox(state, &"Button", looks[state])
	made.set_font(&"font", &"Button", Type.STRONG)
	made.set_color(&"font_color", &"Button", WORDS)
	for state: StringName in [&"font_hover_color", &"font_focus_color", &"font_pressed_color"]:
		made.set_color(state, &"Button", Color.WHITE)
	made.set_color(&"font_hover_pressed_color", &"Button", Color.WHITE)
	made.set_color(&"font_disabled_color", &"Button", Color(QUIET, 0.6))
	made.set_color(&"icon_normal_color", &"Button", Color.WHITE)
	made.set_color(&"icon_hover_color", &"Button", Color.WHITE)
	made.set_color(&"icon_pressed_color", &"Button", Color.WHITE)
	made.set_color(&"icon_focus_color", &"Button", Color.WHITE)


## The button that moves things on, GAME.md 8.1a, is gold foil all the time, its words in the dark
## ink foil is printed with, and under the cursor it is lit brighter and wears the chevron in ink.
static func _primary(made: Theme) -> void:
	made.set_type_variation(PRIMARY, &"Button")
	var looks := button_looks()
	var foil := looks[&"normal"].duplicate() as TicketStyle
	foil.fill = FOIL_HIGH
	foil.fill_low = FOIL_LOW
	foil.frame = Color(ON_FOIL, 0.35)
	var lit := looks[&"hover"].duplicate() as TicketStyle
	lit.fill = Color(1.0, 0.93, 0.72)
	lit.fill_low = FOIL
	lit.frame = Color(ON_FOIL, 0.45)
	lit.border = FOIL_HIGH
	lit.chevron = ON_FOIL
	var held := looks[&"pressed"].duplicate() as TicketStyle
	held.fill = FOIL
	held.fill_low = FOIL_LOW.darkened(0.15)
	held.frame = Color(ON_FOIL, 0.45)
	held.border = FOIL_HIGH
	held.chevron = ON_FOIL
	var off := looks[&"disabled"].duplicate() as TicketStyle
	off.fill = Color(FOIL, 0.35)
	off.fill_low = Color(FOIL_LOW, 0.35)
	for pair: Array in [
		[&"normal", foil],
		[&"hover", lit],
		[&"focus", lit],
		[&"pressed", held],
		[&"hover_pressed", held],
		[&"disabled", off]
	]:
		made.set_stylebox(pair[0], PRIMARY, pair[1])
	for state: StringName in [
		&"font_color",
		&"font_hover_color",
		&"font_focus_color",
		&"font_pressed_color",
		&"font_hover_pressed_color"
	]:
		made.set_color(state, PRIMARY, ON_FOIL)
	made.set_color(&"font_disabled_color", PRIMARY, Color(ON_FOIL, 0.6))


## A box that opens a list: a button, its words starting clear of the chevron so the focus never
## lands on them, with the foil arrow at its far end.
static func _options(made: Theme) -> void:
	var looks := button_looks(22.0, 10.0, 7.0)
	for state: StringName in looks:
		var look := looks[state] as TicketStyle
		look.content_margin_left = 38.0
		made.set_stylebox(state, &"OptionButton", look)
	made.set_font(&"font", &"OptionButton", Type.STRONG)
	made.set_icon(&"arrow", &"OptionButton", HouseArt.arrow())
	made.set_constant(&"arrow_margin", &"OptionButton", 16)
	made.set_color(&"font_color", &"OptionButton", Color.WHITE)
	for state: StringName in [&"font_hover_color", &"font_focus_color", &"font_pressed_color"]:
		made.set_color(state, &"OptionButton", Color.WHITE)
	made.set_color(&"font_disabled_color", &"OptionButton", Color(QUIET, 0.6))


## A switch, see [method HouseArt.switch]: nothing round it at rest, and under the cursor a lit
## ticket with the chevron, so the switch with the focus can be found down a column of them.
static func _switches(made: Theme) -> void:
	var rest := StyleBoxEmpty.new()
	var lit := TicketStyle.cut(Color(STOCK_LIT, 0.8), 6.0, 0.0, 6.0)
	lit.border = Color(FOIL, 0.9)
	lit.border_width = 1.5
	lit.chevron = FOIL
	for look: StyleBox in [rest, lit]:
		look.content_margin_left = 34.0
		look.content_margin_right = 8.0
		look.content_margin_top = 6.0
		look.content_margin_bottom = 6.0
	# Pressed, for a switch, is on: the lit look is for the cursor alone.
	for state: StringName in [&"normal", &"pressed", &"disabled"]:
		made.set_stylebox(state, &"CheckButton", rest)
	for state: StringName in [&"hover", &"focus", &"hover_pressed"]:
		made.set_stylebox(state, &"CheckButton", lit)
	for state: StringName in [
		&"unchecked", &"unchecked_mirrored", &"unchecked_disabled", &"unchecked_disabled_mirrored"
	]:
		made.set_icon(state, &"CheckButton", HouseArt.switch(false))
	for state: StringName in [
		&"checked", &"checked_mirrored", &"checked_disabled", &"checked_disabled_mirrored"
	]:
		made.set_icon(state, &"CheckButton", HouseArt.switch(true))
	made.set_constant(&"icon_max_width", &"CheckButton", HouseArt.SWITCH.x)
	for state: StringName in [
		&"icon_normal_color",
		&"icon_pressed_color",
		&"icon_hover_color",
		&"icon_hover_pressed_color",
		&"icon_focus_color"
	]:
		made.set_color(state, &"CheckButton", Color.WHITE)


## A box to type into: a small ticket with a quiet rim, rimmed in gold while it has the cursor,
## the caret in gold too. No chevron: it would stand on the first letter.
static func _fields(made: Theme) -> void:
	var rest := TicketStyle.cut(Color(STOCK_RAISED, 0.96), 7.0, 14.0, 10.0)
	rest.frame = Color(FOIL, RIM * 0.8)
	var lit := TicketStyle.cut(Color(0.0, 0.0, 0.0, 0.0), 7.0, 14.0, 10.0)
	lit.border = FOIL
	var read := TicketStyle.cut(Color(STOCK_RAISED, 0.5), 7.0, 14.0, 10.0)
	made.set_stylebox(&"normal", &"LineEdit", rest)
	made.set_stylebox(&"focus", &"LineEdit", lit)
	made.set_stylebox(&"read_only", &"LineEdit", read)
	made.set_font(&"font", &"LineEdit", Type.TEXT)
	made.set_color(&"font_color", &"LineEdit", Color.WHITE)
	made.set_color(&"font_placeholder_color", &"LineEdit", Color(QUIET, 0.75))
	made.set_color(&"font_uneditable_color", &"LineEdit", QUIET)
	made.set_color(&"caret_color", &"LineEdit", FOIL)
	made.set_color(&"selection_color", &"LineEdit", Color(FOIL, 0.35))
	made.set_color(&"font_selected_color", &"LineEdit", Color.WHITE)


## The list a box opens: a solid ticket, solid because what it drops over is the next row of the
## same menu, words and all, with the entry under the cursor lit the way a button is and the one
## picked marked with a gold chip.
static func _lists(made: Theme) -> void:
	var card := TicketStyle.cut(STOCK, 8.0, 8.0, 8.0)
	card.border = Color(1.0, 1.0, 1.0, 0.12)
	card.border_width = 1.0
	card.shadow = 12.0
	made.set_stylebox(&"panel", &"PopupMenu", card)
	var lit := TicketStyle.cut(STOCK_LIT, 6.0, 0.0, 0.0)
	lit.border = FOIL
	lit.border_width = 1.5
	made.set_stylebox(&"hover", &"PopupMenu", lit)
	made.set_font(&"font", &"PopupMenu", Type.TEXT)
	made.set_color(&"font_color", &"PopupMenu", Color(0.86, 0.86, 0.9))
	made.set_color(&"font_hover_color", &"PopupMenu", Color.WHITE)
	made.set_constant(&"v_separation", &"PopupMenu", 18)
	made.set_constant(&"h_separation", &"PopupMenu", 12)
	made.set_constant(&"item_start_padding", &"PopupMenu", 16)
	made.set_constant(&"item_end_padding", &"PopupMenu", 28)
	for state: StringName in [&"radio_checked", &"checked"]:
		made.set_icon(state, &"PopupMenu", HouseArt.mark(true))
	for state: StringName in [&"radio_unchecked", &"unchecked"]:
		made.set_icon(state, &"PopupMenu", HouseArt.mark(false))


## The looks of a row of tabs, GAME.md 8.1a, padded [param down] above and below the words: index
## tabs on a pane cut from the same stock as the tab showing.
static func tab_looks(down: float) -> Dictionary[StringName, StyleBox]:
	var showing := TabStyle.cut(STOCK_RAISED, 24.0, down, 0.0)
	showing.top = FOIL
	showing.edge = Color(1.0, 1.0, 1.0, 0.1)
	var other := TabStyle.cut(STOCK, 24.0, down - 2.0, 4.0)
	var lit := TabStyle.cut(STOCK_LIT, 24.0, down - 1.0, 2.0)
	var off := TabStyle.cut(Color(STOCK, 0.5), 24.0, down - 2.0, 4.0)
	off.edge = Color(1.0, 1.0, 1.0, 0.04)
	var focus := TabStyle.cut(Color(0.0, 0.0, 0.0, 0.0), 24.0, down, 0.0)
	focus.edge = Color(0.0, 0.0, 0.0, 0.0)
	focus.border = FOIL
	return {
		&"tab_selected": showing,
		&"tab_unselected": other,
		&"tab_hovered": lit,
		&"tab_disabled": off,
		&"tab_focus": focus,
	}


static func _tabs(made: Theme) -> void:
	var looks := tab_looks(11.0)
	var page := TicketStyle.cut(Color(STOCK_RAISED, 0.97), 12.0, 16.0, 16.0)
	page.notch_top = false
	page.frame = Color(FOIL, RIM * 0.8)
	page.frame_inset = 6.0
	page.engraving = Color(FOIL, Engraving.ON_STOCK * 0.7)
	page.waves = 90.0
	for type: StringName in [&"TabContainer", &"TabBar"]:
		for state: StringName in looks:
			made.set_stylebox(state, type, looks[state])
		made.set_font(&"font", type, Type.STRONG)
		made.set_color(&"font_unselected_color", type, QUIET)
		made.set_color(&"font_hovered_color", type, Color.WHITE)
		made.set_color(&"font_selected_color", type, Color.WHITE)
		made.set_color(&"font_disabled_color", type, Color(QUIET, 0.5))
		made.set_constant(&"h_separation", type, 4)
	made.set_stylebox(&"panel", &"TabContainer", page)
	made.set_stylebox(&"tabbar_background", &"TabContainer", StyleBoxEmpty.new())


## A slider is a lane painted gold as far as its knob, and its knob is a gold chip.
static func _sliders(made: Theme) -> void:
	made.set_stylebox(&"slider", &"HSlider", LaneStyle.new())
	var paint := StyleBoxFlat.new()
	paint.bg_color = FOIL
	paint.set_corner_radius_all(6)
	paint.anti_aliasing = true
	paint.content_margin_top = 6.0
	paint.content_margin_bottom = 6.0
	var bright := paint.duplicate() as StyleBoxFlat
	bright.bg_color = FOIL_HIGH
	made.set_stylebox(&"grabber_area", &"HSlider", paint)
	made.set_stylebox(&"grabber_area_highlight", &"HSlider", bright)
	made.set_icon(&"grabber", &"HSlider", HouseArt.knob(false))
	made.set_icon(&"grabber_highlight", &"HSlider", HouseArt.knob(true))
	made.set_icon(&"grabber_disabled", &"HSlider", HouseArt.knob(false))
	made.set_constant(&"center_grabber", &"HSlider", 0)
	made.set_constant(&"grabber_offset", &"HSlider", 0)


## A scroll bar is a slim dark lane with a foil grabber, brighter under the cursor.
static func _scroll_bars(made: Theme) -> void:
	for type: StringName in [&"VScrollBar", &"HScrollBar"]:
		var lane := StyleBoxFlat.new()
		lane.bg_color = Color(0.0, 0.0, 0.0, 0.28)
		lane.set_corner_radius_all(4)
		lane.set_content_margin_all(4.0)
		made.set_stylebox(&"scroll", type, lane)
		made.set_stylebox(&"scroll_focus", type, lane)
		for pair: Array in [
			[&"grabber", 0.4], [&"grabber_highlight", 0.7], [&"grabber_pressed", 0.9]
		]:
			var grip := StyleBoxFlat.new()
			grip.bg_color = Color(FOIL, pair[1])
			grip.set_corner_radius_all(4)
			grip.anti_aliasing = true
			made.set_stylebox(pair[0], type, grip)


## A bar that fills, where nothing says otherwise, is a dark lane filling with foil.
static func _bars(made: Theme) -> void:
	var lane := StyleBoxFlat.new()
	lane.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	lane.set_corner_radius_all(6)
	var paint := StyleBoxFlat.new()
	paint.bg_color = FOIL
	paint.set_corner_radius_all(6)
	made.set_stylebox(&"background", &"ProgressBar", lane)
	made.set_stylebox(&"fill", &"ProgressBar", paint)
	made.set_font(&"font", &"ProgressBar", Type.STRONG)


static func _tooltips(made: Theme) -> void:
	var tip := TicketStyle.cut(Color(STOCK, 0.98), 5.0, 12.0, 7.0)
	tip.frame = Color(FOIL, RIM)
	tip.frame_inset = 3.0
	made.set_stylebox(&"panel", &"TooltipPanel", tip)
	made.set_color(&"font_color", &"TooltipLabel", WORDS)
	made.set_font(&"font", &"TooltipLabel", Type.TEXT)
