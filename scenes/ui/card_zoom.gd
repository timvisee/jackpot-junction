class_name CardZoom
extends Control
## A card of the catalog held up large, GAME.md 8.8, to see its picture and read its words up close:
## A, Enter or Space held on a card face up, or the mouse or a finger held down on it, shows it over
## the dialog as big as the screen has room for, and letting go puts it away. Moving the cursor
## while it is held shows the card it comes to. A card face down has nothing to show; a finger that
## moves before the card comes up is scrolling the cards, and nothing comes up.
##
## Over the whole of the dialog, see [CatalogDialog], taking no clicks itself: the cards under it
## still hear the mouse, the wheel and a finger's drag.

## How long a press is held before the card comes up, in seconds; how far a mouse or a finger may
## move meanwhile and still be holding rather than dragging, in pixels.
const HOLD := 0.25
const DRIFT := 12.0
## How much of the dialog's height and width the card takes at most, the shade behind it, and how
## long it takes to come up, growing a little into its size.
const TALL := 0.82
const WIDE := 0.9
const SHADE := Color(0.0, 0.0, 0.0, 0.62)
const RISE := 0.12
const FROM := 0.92

## Over the pencil's rings round the cards, which stand over the rest of the dialog.
const OVER := 10

## What holds the card: [code]"key"[/code], [code]"mouse"[/code], or nothing.
var holding := ""
## The card held up, a picture of it drawn at the size it is shown at, or null while none is; and
## the card itself, made again from the cell's and drawn into it, see [method _show].
var shown: TextureRect
var card: Control

var _dialog: CatalogDialog
var _cell: CatalogCell
var _held_for := 0.0
var _from := Vector2.ZERO
var _shade: ColorRect


## The zoom over [param dialog]'s cards, on top of everything in it.
static func add_to(dialog: CatalogDialog) -> CardZoom:
	var zoom := CardZoom.new()
	zoom.name = "Zoom"
	zoom._dialog = dialog
	dialog.add_child(zoom)
	return zoom


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = OVER
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = SHADE
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.visible = false
	add_child(_shade)


func _input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		if click.pressed:
			hold(_cell_at(click.position), "mouse", click.position)
		else:
			let_go("mouse")
		return
	var moved := event as InputEventMouseMotion
	if moved != null:
		# Moved before the card came up: a drag scrolling the cards, not a hold.
		if holding == "mouse" and shown == null and moved.position.distance_to(_from) > DRIFT:
			let_go("mouse")
		return
	if event.is_action_pressed(&"ui_accept") and not event.is_echo():
		var focused := get_viewport().gui_get_focus_owner() as CatalogCell
		if focused != null and focused.is_visible_in_tree():
			hold(focused, "key", Vector2.ZERO)
			get_viewport().set_input_as_handled()
	elif event.is_action_released(&"ui_accept"):
		let_go("key")


## [param cell] pressed and held, by [param by], from [param at] for the mouse: its card comes up
## once it has been held for [constant HOLD], if it is face up.
func hold(cell: CatalogCell, by: String, at: Vector2) -> void:
	if cell == null or not cell.found or not holding.is_empty():
		return
	holding = by
	_cell = cell
	_from = at
	_held_for = 0.0


## Let go by [param by]: the card held up goes, as does a press not yet held long enough.
func let_go(by: String) -> void:
	if holding != by:
		return
	holding = ""
	_cell = null
	_put_away()


func _process(delta: float) -> void:
	if holding.is_empty():
		return
	if not is_instance_valid(_cell) or not _cell.is_visible_in_tree():
		let_go(holding)
		return
	# The cursor moved on while A is held: the card it comes to, if it is face up.
	if holding == "key":
		var focused := get_viewport().gui_get_focus_owner() as CatalogCell
		if focused != null and focused != _cell and focused.found:
			_cell = focused
			if shown != null:
				_show(_cell)
	if shown == null:
		_held_for += delta
		if _held_for >= HOLD:
			_show(_cell)


## [param cell]'s card made again and held up in the middle of the dialog, as big as
## [constant TALL] and [constant WIDE] let it, growing into its size over [constant RISE]. Drawn at
## its own size into a picture as many of the screen's pixels as it is shown at, so its words are
## set at that size, sharp, rather than drawn small and blown up, see [method DrawnTexture.of].
func _show(cell: CatalogCell) -> void:
	var first := shown == null
	_put_away()
	var full := JokerCard.SIZE
	var fit := minf(size.y * TALL / full.y, size.x * WIDE / full.x)
	card = cell.make_card()
	card.name = "Card"
	var pixels := fit * KeptPictures.scale_of(self)
	shown = TextureRect.new()
	shown.name = "Shown"
	shown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shown.texture = DrawnTexture.of(self, card, Vector2i(full), Viewport.MSAA_4X, pixels)
	shown.size = full * fit
	shown.pivot_offset = shown.size * 0.5
	shown.position = (size - shown.size) * 0.5
	add_child(shown)
	_shade.visible = true
	if not first:
		return
	Audio.play_sfx(&"card_flip", -12.0, 0.05)
	shown.scale = Vector2.ONE * FROM
	shown.modulate.a = 0.0
	var rise := shown.create_tween().set_parallel()
	rise.tween_property(shown, ^"scale", Vector2.ONE, RISE).set_ease(Tween.EASE_OUT)
	rise.tween_property(shown, ^"modulate:a", 1.0, RISE)


## The card held up gone, the viewport it was drawn in with it.
func _put_away() -> void:
	if shown != null:
		shown.queue_free()
		shown = null
	if card != null:
		card.get_parent().queue_free()
		card = null
	_shade.visible = false


## The card cell under [param point] on the page shown, where the cards' well shows it, or null.
func _cell_at(point: Vector2) -> CatalogCell:
	for grid: CardGrid in [_dialog.joker_grid, _dialog.item_grid]:
		if grid == null or not grid.is_visible_in_tree():
			continue
		var well: Node = grid
		while well != null and not well is ScrollContainer:
			well = well.get_parent()
		if well != null and not (well as Control).get_global_rect().has_point(point):
			continue
		for cell: Control in grid.cells():
			if cell is CatalogCell and cell.get_global_rect().has_point(point):
				return cell as CatalogCell
	return null
