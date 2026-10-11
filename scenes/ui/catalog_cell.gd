class_name CatalogCell
extends Control
## One place in the catalog's grid, GAME.md 8.8: a card face up, or face down for one never found,
## which wears the cursor's frame under the cursor, the gold edge a button wears, a little way out
## round the card, the glide of [FocusGlide] sliding to it from wherever the cursor was; and a NEW
## tag on its corner while the profile has not yet looked at it. The card stays still: a card that
## lifts and grows out of a hand is the hand's, and a page of them doing it is restless. The card is
## drawn scaled to fit the cell, in the middle of it, the frame's room round it. Laid out by
## [CardGrid].

## The cursor has come to it: the pane says what it is, and it is no longer new.
signal looked_at(cell: CatalogCell)

## The room between the card's edge and the frame round it under the cursor.
const FRAME_ROOM := 7.0
## The NEW tag: its word, its size on the card, and how far it stands out over the card's corner.
const NEW := "NEW"
const NEW_SIZE := 15
const NEW_OUT := Vector2(10.0, -12.0)

## The joker or the item in this place, by id, and whether it was ever found.
var id: StringName
var found := false
## The card drawn: a [JokerCard] or [ItemCard] face up, a [CardBack] face down.
var card: Control

var _frame := FocusGlide.look()
var _tag: Control


## A place for [param face], the card for [param what], face up where [param taken].
static func holding(what: StringName, taken: bool, face: Control) -> CatalogCell:
	var cell := CatalogCell.new()
	cell.name = String(what)
	cell.id = what
	cell.found = taken
	cell.card = face
	cell.add_child(face)
	return cell


## The size of a cell for a card drawn at [param scale] of its own: the card and the frame's room.
static func shape(scale_of: float) -> Vector2:
	return JokerCard.SIZE * scale_of + Vector2.ONE * FRAME_ROOM * 2.0


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	# Passed on as well, so the wheel and a finger's drag scroll the cards it stands among.
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_to_group(FocusGlide.GROUP)


func _ready() -> void:
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	mouse_entered.connect(_on_mouse_entered)
	resized.connect(_place)
	_place()


## The mouse over it gives it the cursor, as it does any button; not on a touch screen, where the
## mouse a phone makes of a finger would give it every card a swipe passed over, see [TouchScroll].
func _on_mouse_entered() -> void:
	if not TouchInput.enabled:
		grab_focus()


func _draw() -> void:
	if has_focus():
		draw_style_box(_frame, Rect2(Vector2.ZERO, size))


## Whether the card wears the NEW tag, see [CatalogState.is_fresh].
func set_fresh(on: bool) -> void:
	if on == (_tag != null):
		return
	if not on:
		card.remove_child(_tag)
		_tag.queue_free()
		_tag = null
		return
	_tag = new_tag()
	card.add_child(_tag)


func is_fresh() -> bool:
	return _tag != null


func _on_focus(on: bool) -> void:
	queue_redraw()
	if on:
		looked_at.emit(self)


## The card scaled to fit the cell inside the frame's room, in the middle of it.
func _place() -> void:
	if card == null:
		return
	var full := JokerCard.SIZE
	var room := size - Vector2.ONE * FRAME_ROOM * 2.0
	var fit := maxf(minf(room.x / full.x, room.y / full.y), 0.0)
	card.pivot_offset = Vector2.ZERO
	card.scale = Vector2.ONE * fit
	card.position = (size - full * fit) * 0.5


## Hangs the NEW tag over [param on]'s top right corner, or takes it off: the title's Extras and
## the loyalty program's button wear it while a landmark is new, GAME.md 8.9.
static func tag(on: Control, fresh: bool) -> void:
	var worn := on.get_node_or_null("New")
	if fresh == (worn != null):
		return
	if worn != null:
		# Under another name until it goes, so a new one can take its own.
		worn.name = "NewGone"
		(worn as Control).hide()
		worn.queue_free()
		return
	on.add_child(new_tag())


## The NEW tag: the word in the foil's dark ink on a chip of foil, over the card's top right corner.
static func new_tag() -> Control:
	var tag := PanelContainer.new()
	tag.name = "New"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := TicketStyle.cut(HouseTheme.FOIL, 4.0, 7.0, 2.0)
	style.shadow = 6.0
	tag.add_theme_stylebox_override("panel", style)
	var word := Label.new()
	word.text = NEW
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.strong(word, NEW_SIZE, HouseTheme.ON_FOIL)
	tag.add_child(word)
	# Hung by its top right corner, growing left and down from there, since its words have no size
	# until they are in the tree.
	tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tag.offset_left = NEW_OUT.x
	tag.offset_right = NEW_OUT.x
	tag.offset_top = NEW_OUT.y
	tag.offset_bottom = NEW_OUT.y
	return tag
