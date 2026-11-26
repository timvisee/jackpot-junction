class_name TableStrip
extends VBoxContainer
## The cards on the table in the match settings, GAME.md 9.6, under the presets: a card for each
## of the table's features, 3.17, face up for on and face down, in the card back the player wears,
## for off. One press turns a card over. A card the House has not opened yet, 8.9a, is sealed,
## grayed under a padlock with the map it opens after, and a press asks to open it early. Suits &
## hands are nothing without Jokers: turning them up turns Jokers up with them, and turning Jokers
## down turns them down. A card opened and not yet played wears NEW. With Roulette the cards face
## up are the deck each map's are dealt from, and the strip says so over them. With keys or a pad in
## hand, the hint under the card the cursor is on says which button turns it over, see
## [method show_bind]. Once the House has opened every card, a die at the row's end deals the table
## at random, see [method roll].

## A card was turned over: [member table] says what is on the table now.
signal changed
## A sealed card was pressed: the player asks to open [param card] early.
signal open_asked(card: int)

## How big a card stands at a UI scale of one, and how far apart they lie.
const CARD := Vector2(94.0, 94.0 * TableCardArt.ASPECT)
## How big a card stands where the pane is narrow, the presets in two rows: a phone's under a big
## UI scale, whose screen is short as well.
const CARD_SMALL := Vector2(70.0, 70.0 * TableCardArt.ASPECT)
const GAP := 10.0
## How long a card takes to turn over, out to its edge and back, and how long after the card
## before it the next one starts when a preset turns several, a wave along the row.
const TURN := 0.22
const WAVE := 0.06
## How far under the card under the mouse or the cursor its hint stands.
const TIP_GAP := 10.0
## The felt the cards lie on, a strip of the table itself, and how much of it shows round them.
const FELT := Color("#1f4434")
const FELT_EDGE := Color("#14301f")
const ROOM := 12.0
## The die at the row's end, the one the kart dialog rolls a name with, [NameDie]: how big it
## stands, a share of a card's width, and what its hint and a screen reader say of it.
const DIE_SIZE := 0.55
const DIE_NAME := "Random table"
const DIE_LINE := "Every card face up or down, as the die falls."
const DIE_WORD := "Roll"

## The cards on the table, or with [member roulette] the deck.
var table := TableCards.ALL
var roulette := false
## The cards the House has opened for the profile choosing, and those not yet played.
var opened := TableCards.ALL
var fresh := 0

## The die that deals the table at random, see [method roll].
var die: NameDie

var _heading: Label
var _note: Label
var _cards: Array[TableCardButton] = []
## What the die deals with.
var _rng := RandomNumberGenerator.new()
var _locked := false
## The hint over the card under the mouse or the cursor, see [TableTag], and the cards it may be
## over: the one the mouse is on, which goes first, and the one the cursor is on, the die counted
## as the card after the last; and what it is under now.
var _tip: TableTag
var _tip_under: Control
var _hovered := -1
var _focused := -1
## Whether keys or a pad are in hand rather than the mouse, and which, see [method show_bind].
var _binds := not Game.last_input_pointer
var _keyboard := Game.last_input_keyboard


static func make() -> TableStrip:
	var strip := TableStrip.new()
	strip.name = "Table"
	strip.add_theme_constant_override("separation", 6)
	strip._build()
	return strip


func _build() -> void:
	var felt := PanelContainer.new()
	var look := StyleBoxFlat.new()
	look.bg_color = FELT
	look.border_color = FELT_EDGE
	look.set_border_width_all(2)
	look.set_corner_radius_all(8)
	look.set_content_margin_all(ROOM)
	felt.add_theme_stylebox_override(&"panel", look)
	add_child(felt)
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 8)
	felt.add_child(inside)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	inside.add_child(head)
	_heading = Label.new()
	_heading.text = "ON THE TABLE"
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Type.display(_heading, Type.LABEL, HouseTheme.FOIL)
	head.add_child(_heading)
	_note = Label.new()
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Type.text(_note, Type.SMALL, HouseTheme.QUIET)
	head.add_child(_note)
	var row := HBoxContainer.new()
	row.name = "Cards"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(GAP))
	inside.add_child(row)
	for card: int in TableCards.Card.size():
		var button := TableCardButton.new()
		button.card = card
		button.name = TableCards.NAMES[card].replace(" ", "").replace("&", "And")
		button.custom_minimum_size = CARD
		button.pressed.connect(_on_pressed.bind(card))
		button.mouse_entered.connect(func() -> void: _point(card, true, true))
		button.mouse_exited.connect(func() -> void: _point(card, true, false))
		button.focus_entered.connect(func() -> void: _point(card, false, true))
		button.focus_entered.connect(_cursor_sound)
		button.focus_exited.connect(func() -> void: _point(card, false, false))
		row.add_child(button)
		_cards.append(button)
	_rng.randomize()
	die = NameDie.new()
	die.name = "Die"
	die.custom_minimum_size = Vector2.ONE * CARD.x * DIE_SIZE
	die.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	die.tooltip_text = DIE_LINE
	die.pressed.connect(roll)
	var after := _cards.size()
	die.mouse_entered.connect(func() -> void: _point(after, true, true))
	die.mouse_exited.connect(func() -> void: _point(after, true, false))
	die.focus_entered.connect(func() -> void: _point(after, false, true))
	die.focus_entered.connect(_cursor_sound)
	die.focus_exited.connect(func() -> void: _point(after, false, false))
	row.add_child(die)
	# Across the row and no further: past either end the cursor stays on the card or the die,
	# where it would drop to whatever lies that way under the strip, a column's head.
	_cards[0].focus_neighbor_left = NodePath(".")
	die.focus_neighbor_left = die.get_path_to(_cards[-1])
	die.focus_neighbor_right = NodePath(".")
	# Its own place over everything, so the rows' scroll does not cut it off at the pane's top.
	_tip = TableTag.make()
	_tip.name = "Hint"
	_tip.top_level = true
	_tip.visible = false
	_tip.z_index = 10
	add_child(_tip)
	_show()


## Sets out [param table_in], the deck of a Roulette with [param roulette_in], for a profile with
## [param opened_in] opened and [param fresh_in] not yet played. With [param turning] the cards it
## turns over turn as a press turns one, one after another along the row, a preset's wave.
func set_table(
	table_in: int, roulette_in: bool, opened_in: int, fresh_in := 0, turning := false
) -> void:
	var was: Array[bool] = []
	for each: TableCardButton in _cards:
		was.append(each.up and not each.sealed)
	table = table_in & opened_in
	roulette = roulette_in
	opened = opened_in
	fresh = fresh_in
	_show()
	if not turning:
		return
	var turned := 0
	for i: int in _cards.size():
		var each := _cards[i]
		if not each.sealed and each.up != was[i]:
			each.turn(WAVE * float(turned))
			turned += 1


## The cards at their small size where [param on], for a narrow pane, see [constant CARD_SMALL].
func set_compact(on: bool) -> void:
	for each: TableCardButton in _cards:
		each.custom_minimum_size = CARD_SMALL if on else CARD
	die.custom_minimum_size = Vector2.ONE * (CARD_SMALL if on else CARD).x * DIE_SIZE
	_note.visible = not on


## Every card, in order.
func buttons() -> Array[Button]:
	var all: Array[Button] = []
	all.assign(_cards)
	return all


func button(card: int) -> TableCardButton:
	return _cards[card]


## Every card shown and none to be turned, for a table the House has set: no hint over them either,
## which would say what the House keeps to itself.
func lock() -> void:
	_locked = true
	_tip.visible = false
	for each: TableCardButton in _cards:
		each.disabled = true
	_show()


## Deals the table at random, GAME.md 9.6, as the die is thrown: each card face up or down as a coin
## falls, Suits & hands bringing Jokers up with them as a press does, never every card face down and
## never the table it was; the cards it turns over turn one after another along the row, as a
## preset turns them. Only with every card opened, and the table not the House's.
func roll() -> void:
	if _locked or opened != TableCards.ALL:
		return
	var dealt := table
	while dealt == table or dealt == 0:
		dealt = _rng.randi() & TableCards.ALL
		if TableCards.has(dealt, TableCards.Card.SUITS):
			dealt = TableCards.with(dealt, TableCards.Card.JOKERS, true)
	set_table(dealt, roulette, opened, fresh, true)
	changed.emit()


## The bind that turns the card under the cursor over, drawn in its hint for a keyboard or a pad as
## [param keyboard] says, or none while [param shown] is false, with the mouse in hand, whose
## press is said over the cards.
func show_bind(keyboard: bool, shown: bool) -> void:
	if keyboard == _keyboard and shown == _binds:
		return
	_keyboard = keyboard
	_binds = shown
	_show_tip()


## The mouse, with [param mouse], or the cursor come onto [param card], [param on], or gone off it:
## the hint over whichever card it is now, the mouse's before the cursor's, GAME.md 9.6.
func _point(card: int, mouse: bool, on: bool) -> void:
	if mouse:
		_hovered = card if on else (-1 if _hovered == card else _hovered)
	else:
		_focused = card if on else (-1 if _focused == card else _focused)
	_show_tip()


## The hint over the card the mouse is on, or else the one the cursor is on, or none; under the
## cursor, what turns the card over, see [method show_bind], or for a sealed card, what asks to
## open it early.
func _show_tip() -> void:
	var over := _hovered if _hovered >= 0 else _focused
	if over < 0 or _locked:
		_tip.visible = false
		return
	var bound := _binds and over == _focused and _hovered < 0 and not TouchInput.enabled
	if over >= _cards.size():
		_tip_under = die
		_tip.show_words(DIE_NAME, DIE_LINE)
		_tip.show_bind(_keyboard, DIE_WORD if bound else "")
		_tip.visible = true
		_place_tip.call_deferred()
		return
	var each := _cards[over]
	_tip_under = each
	var chip := TableTag.Chip.NONE
	if each.sealed:
		chip = TableTag.Chip.SEALED
	elif each.fresh:
		chip = TableTag.Chip.NEW
	_tip.show_card(over, chip)
	_tip.show_bind(_keyboard, ("Open early" if each.sealed else "Turn over") if bound else "")
	_tip.visible = true
	_place_tip.call_deferred()


## The hint under its card or the die, in the middle of it and clear of its foot, where it leaves
## the presets over the strip to be reached, or over it where the screen has no room below; kept on
## the screen, and as big as the card is shown, the pane being shrunk to fit a small screen, see
## [HostSettings].
func _place_tip() -> void:
	if not _tip.visible or _tip_under == null:
		return
	var each := _tip_under
	# Under the row as a card's is, the die being shorter than a card.
	var row := _cards[0].get_global_rect()
	var shown := each.get_global_rect()
	shown = Rect2(shown.position.x, row.position.y, shown.size.x, row.size.y)
	var grown := each.get_global_transform().get_scale().y
	_tip.scale = Vector2.ONE * grown
	_tip.reset_size()
	var wide := _tip.size * grown
	var at := Vector2(shown.get_center().x - wide.x * 0.5, shown.end.y + TIP_GAP * grown)
	var screen := get_viewport_rect().size
	at.x = clampf(at.x, 4.0, maxf(screen.x - wide.x - 4.0, 4.0))
	if at.y + wide.y > screen.y - 4.0:
		at.y = shown.position.y - wide.y - TIP_GAP * grown
	_tip.global_position = at


## The cursor come onto a card or the die heard as it is on any button, see [method
## MenuTheme.button].
static func _cursor_sound() -> void:
	Audio.play_sfx(&"ui_move", MenuTheme.MOVE_DB, 0.0)


func _on_pressed(card: int) -> void:
	if _locked:
		return
	if not TableCards.has(opened, card):
		# A question rather than a turn: clicked as a button is.
		Audio.play_sfx(&"ui_click", MenuTheme.CLICK_DB, 0.0)
		open_asked.emit(card)
		return
	var on := not TableCards.has(table, card)
	table = TableCards.with(table, card, on)
	_cards[card].turn()
	# Suits & hands are nothing without Jokers, GAME.md 3.17: up, they bring Jokers up with them;
	# Jokers down take them down.
	var jokers := TableCards.Card.JOKERS
	var suits := TableCards.Card.SUITS
	if card == suits and on and not TableCards.has(table, jokers):
		table = TableCards.with(table, jokers, true)
		_cards[jokers].turn()
	elif card == jokers and not on and TableCards.has(table, suits):
		table = TableCards.with(table, suits, false)
		_cards[suits].turn()
	_show()
	changed.emit()


func _show() -> void:
	if _note == null:
		return
	_heading.text = "IN THE DECK" if roulette else "ON THE TABLE"
	_note.text = (
		"Power-ups and %d of the rest, dealt each map" % TableCards.DEAL
		if roulette
		else "Press a card to turn it over"
	)
	for each: TableCardButton in _cards:
		var card := each.card
		each.sealed = not TableCards.has(opened, card)
		each.up = TableCards.has(table, card)
		each.fresh = TableCards.has(fresh, card) and not each.sealed
		each.queue_redraw()
		ScreenReader.name(each, TableCards.NAMES[card], _said(each))
	# The die once the House has opened every card, and never on a table the House has set; the
	# cursor goes on to it from the last card while it is there.
	die.visible = opened == TableCards.ALL and not _locked
	var last := _cards[-1]
	last.focus_neighbor_right = last.get_path_to(die) if die.visible else NodePath(".")
	ScreenReader.name(die, DIE_NAME, DIE_LINE)


func _said(each: TableCardButton) -> String:
	if each.sealed:
		return (
			"Not open yet: it opens after map %d. Press to open it early."
			% (TableCards.opens_after(each.card))
		)
	var state := "In the deck" if roulette and each.up else ("On" if each.up else "Off")
	return "%s. %s" % [state, TableCards.LINES[each.card]]


## One card of the strip: its face where it is on the table, its back where it is not, sealed where
## it is not opened yet. Drawn rather than built of pieces: a face is a handful of shapes.
class TableCardButton:
	extends Button

	## The tag on a card opened and not yet played.
	const NEW_INK := Color("#ff4fa3")
	## A card turned over heard put down on the felt, as it starts to turn, and how loud: a little
	## over a button's click, the recordings' slap coming as the card comes down flat.
	const FLIP := &"card_flip"
	const FLIP_DB := -24.0
	## Who is told a face is drawn, see [KeptPictures].
	const GROUP := &"table_cards"

	var card := 0
	var up := true
	var sealed := false
	var fresh := false
	var _back: Texture2D
	var _turning := 0.0
	var _wait := 0.0
	## Whether the turn under way has been heard yet, see [constant FLIP].
	var _heard := true

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_STOP
		for state: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())

	func _ready() -> void:
		add_to_group(GROUP)
		CardBack.picture(
			CardBack.worn(),
			self,
			func(drawn: Texture2D) -> void:
				_back = drawn
				queue_redraw()
		)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	## Turns it over: narrowed to its edge, and the other side shown as it widens again, after
	## [param wait] seconds, the side it showed shown till then. Only what is drawn narrows: the
	## card keeps its place and its size, so the cursor going on from it, or onto it, as it turns
	## finds the card beside it rather than the row under the strip, and a click finds it whole.
	func turn(wait := 0.0) -> void:
		_turning = 1.0
		_wait = wait
		_heard = false
		set_process(true)
		queue_redraw()

	func _process(delta: float) -> void:
		if _wait > 0.0:
			_wait -= delta
			return
		if not _heard:
			_heard = true
			Audio.play_sfx(FLIP, FLIP_DB, 0.08)
		_turning = maxf(_turning - delta / TableStrip.TURN, 0.0)
		if _turning <= 0.0:
			set_process(false)
		queue_redraw()

	## Its face as a picture of itself once that is drawn, GAME.md 10.7: a face is a few dozen shapes,
	## a draw call or more each every frame, and a picture is one. Drawn at the screen's own pixels;
	## until it is ready, the face is drawn as itself.
	func _draw_face(box: Rect2) -> void:
		var state := 2 if sealed else 0
		var scale := KeptPictures.scale_of(self)
		var pixels := Vector2i((box.size * scale).ceil())
		var picture: Texture2D = null
		if pixels.x >= 1 and pixels.y >= 1 and _turning <= 0.0:
			var drawn := card
			var size_drawn := box.size
			picture = KeptPictures.of(
				self,
				"table_card|%d|%d" % [card, state],
				pixels,
				func() -> Control: return _Face.new(drawn, state, size_drawn, pixels),
				GROUP
			)
		if picture != null:
			draw_texture_rect(picture, box, false)
		elif sealed:
			TableCardArt.sealed(self, box, card)
		else:
			TableCardArt.face(self, box, card)

	func _draw() -> void:
		# Narrowed about its middle as it turns over, see [method turn].
		var across := absf(_turning * 2.0 - 1.0) if _turning > 0.0 else 1.0
		if across < 1.0:
			draw_set_transform(
				Vector2(size.x * 0.5 * (1.0 - across), 0.0), 0.0, Vector2(across, 1.0)
			)
		var box := Rect2(Vector2.ZERO, size)
		# Lifted a little under the cursor, the way a card is picked up.
		if (has_focus() or is_hovered()) and not disabled:
			box.position.y -= 4.0
		# Halfway through a turn the side that was showing gives way to the one coming up.
		var showing_up := up if _turning < 0.5 else not up
		if sealed or showing_up:
			_draw_face(box)
		elif _back != null:
			draw_texture_rect(_back, box, false)
		else:
			draw_rect(box, HouseTheme.STOCK_LIT)
		if fresh and not sealed:
			var tag := Rect2(Vector2(box.end.x - 34.0, box.position.y - 6.0), Vector2(38.0, 17.0))
			draw_rect(tag, NEW_INK)
			draw_string(
				Type.display_font(),
				tag.position + Vector2(0, 13.5),
				"NEW",
				HORIZONTAL_ALIGNMENT_CENTER,
				tag.size.x,
				13,
				Color.WHITE
			)
		if has_focus():
			var frame := StyleBoxFlat.new()
			frame.draw_center = false
			frame.border_color = HouseTheme.FOIL
			frame.set_border_width_all(3)
			frame.set_corner_radius_all(roundi(box.size.x * TableCardArt.CORNER) + 2)
			frame.anti_aliasing = true
			draw_style_box(frame, box.grow(4.0))


## A card's face drawn once for its picture, see [method TableCardButton._draw_face]: [param state]
## 0 up, 2 sealed, laid out at the card's size and drawn at [param pixels].
class _Face:
	extends Control

	var _card := 0
	var _state := 0
	var _shown := Vector2.ONE

	func _init(card: int, state: int, shown: Vector2, pixels: Vector2i) -> void:
		_card = card
		_state = state
		_shown = shown
		size = Vector2(pixels)

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, size / _shown)
		var box := Rect2(Vector2.ZERO, _shown)
		if _state == 2:
			TableCardArt.sealed(self, box, _card)
		else:
			TableCardArt.face(self, box, _card, _state == 1)
