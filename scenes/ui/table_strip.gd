class_name TableStrip
extends VBoxContainer
## The cards on the table in the match settings, GAME.md 9.6, under the presets: a card for each
## of the table's features, 3.17, face up for on and face down, in the card back the player wears,
## for off. One press turns a card over. A card the House has not opened yet, 8.9a, is sealed,
## grayed under a padlock with the map it opens after, and a press asks to open it early. Suits &
## hands are nothing without Jokers: turning them up turns Jokers up with them, and turning Jokers
## down turns them down. A card opened and not yet played wears NEW. With Roulette the cards face
## up are the deck each map's are dealt from, and the strip says so over them.

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
## How long a card takes to turn over, out to its edge and back.
const TURN := 0.22
## The felt the cards lie on, a strip of the table itself, and how much of it shows round them.
const FELT := Color("#1f4434")
const FELT_EDGE := Color("#14301f")
const ROOM := 12.0

## The cards on the table, or with [member roulette] the deck.
var table := TableCards.ALL
var roulette := false
## The cards the House has opened for the profile choosing, and those not yet played.
var opened := TableCards.ALL
var fresh := 0

var _heading: Label
var _note: Label
var _cards: Array[TableCardButton] = []
var _locked := false


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
		row.add_child(button)
		_cards.append(button)
	_show()


## Sets out [param table_in], the deck of a Roulette with [param roulette_in], for a profile with
## [param opened_in] opened and [param fresh_in] not yet played.
func set_table(table_in: int, roulette_in: bool, opened_in: int, fresh_in := 0) -> void:
	table = table_in & opened_in
	roulette = roulette_in
	opened = opened_in
	fresh = fresh_in
	_show()


## The cards at their small size where [param on], for a narrow pane, see [constant CARD_SMALL].
func set_compact(on: bool) -> void:
	for each: TableCardButton in _cards:
		each.custom_minimum_size = CARD_SMALL if on else CARD
	_note.visible = not on


## Every card, in order.
func buttons() -> Array[Button]:
	var all: Array[Button] = []
	all.assign(_cards)
	return all


func button(card: int) -> TableCardButton:
	return _cards[card]


## Every card shown and none to be turned, for a table the House has set.
func lock() -> void:
	_locked = true
	for each: TableCardButton in _cards:
		each.disabled = true


func _on_pressed(card: int) -> void:
	if _locked:
		return
	if not TableCards.has(opened, card):
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
	## Who is told a face is drawn, see [KeptPictures].
	const GROUP := &"table_cards"

	var card := 0
	var up := true
	var sealed := false
	var fresh := false
	var _back: Texture2D
	var _turning := 0.0

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
		resized.connect(func() -> void: pivot_offset = size * 0.5)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	## Turns it over: narrowed to its edge, and the other side shown as it widens again.
	func turn() -> void:
		_turning = 1.0
		set_process(true)

	func _process(delta: float) -> void:
		_turning = maxf(_turning - delta / TableStrip.TURN, 0.0)
		scale.x = absf(_turning * 2.0 - 1.0) if _turning > 0.0 else 1.0
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
