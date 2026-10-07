class_name CatalogCell
extends Control
## One place in the catalog's grid, GAME.md 8.8: a card face up, or face down for one never taken,
## which lifts and lights up under the cursor as a card of the respawn pick does, and wears a NEW
## tag on its corner while the profile has not yet looked at it. The card is drawn at its own size
## and scaled to fit the cell, standing on its bottom middle with room over it to lift into. Laid
## out by [CardGrid].

## The cursor has come to it: the pane says what it is, and it is no longer new.
signal looked_at(cell: CatalogCell)

## How far a card lifts under the cursor, a share of its height, and how much it grows; the cell
## is that much taller than its card, so a lifted card stays inside it.
const LIFT := 0.07
const LIFTED := 1.05
## How long the card takes to lift or settle, in seconds.
const SETTLE := 0.12
## The NEW tag: its word, its size on the card, and how far it stands out over the card's corner.
const NEW := "NEW"
const NEW_SIZE := 15
const NEW_OUT := Vector2(10.0, -12.0)

## The joker or the item in this place, by id, and whether it was ever taken.
var id: StringName
var found := false
## The card drawn: a [JokerCard] or [ItemCard] face up, a [CardBack] face down.
var card: Control

var _lift := 0.0
var _tween: Tween
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


## The shape of a cell for a card at its own size: the card and the room over it to lift into.
static func shape() -> Vector2:
	return Vector2(JokerCard.SIZE.x, JokerCard.SIZE.y * (1.0 + LIFT))


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false


func _ready() -> void:
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	mouse_entered.connect(grab_focus)
	resized.connect(_place)
	_place()


## Whether the card wears the NEW tag, see [CatalogState.is_fresh].
func set_fresh(on: bool) -> void:
	if on == (_tag != null):
		return
	if not on:
		card.remove_child(_tag)
		_tag.queue_free()
		_tag = null
		return
	_tag = _new_tag()
	card.add_child(_tag)


func is_fresh() -> bool:
	return _tag != null


## Whether the card is lifted, under the cursor.
func is_lifted() -> bool:
	return has_focus()


func _on_focus(on: bool) -> void:
	z_index = 1 if on else 0
	card.call(&"set_highlighted", on)
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_lift_to, _lift, 1.0 if on else 0.0, SETTLE)
	if on:
		looked_at.emit(self)


func _lift_to(amount: float) -> void:
	_lift = amount
	_place()


## The card scaled to the cell and stood on its bottom middle, lifted as far as it is.
func _place() -> void:
	if card == null:
		return
	var full := JokerCard.SIZE
	var fit := minf(size.x / full.x, size.y / (full.y * (1.0 + LIFT)))
	card.pivot_offset = Vector2(full.x * 0.5, full.y)
	card.scale = Vector2.ONE * fit * lerpf(1.0, LIFTED, _lift)
	card.position = Vector2(size.x * 0.5 - full.x * 0.5, size.y - full.y)
	card.position.y -= full.y * LIFT * fit * _lift


## The NEW tag: the word in the foil's dark ink on a chip of foil, over the card's top right corner.
func _new_tag() -> Control:
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
