class_name CardPreview
extends Control
## The card under the catalog's cursor shown large, GAME.md 8.8, over the pane that describes it:
## as big as the room the pane's column leaves it, up to [constant MOST] of the card's own size, and
## in the middle of that room. Where the room would only hold it smaller than [constant LEAST], a
## phone's short screen, it is not shown at all: the card is in the grid and the pane says it all.

## The biggest and the smallest a card is shown at, a share of its own size.
const MOST := 1.8
const LEAST := 0.95

## The card shown, a [JokerCard], [ItemCard] or [CardBack] of its own, or null.
var card: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(_fit)


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO


## Shows [param face] large, in place of whatever was shown, or nothing for null.
func show_card(face: Control) -> void:
	if card != null:
		card.name = "Gone"
		card.hide()
		card.queue_free()
	card = face
	if card != null:
		card.name = "Card"
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(card)
	_fit()


## Whether the room holds the card big enough to be worth showing.
func is_shown() -> bool:
	return card != null and card.visible


## How big the card is shown, a share of its own size.
func scale_of() -> float:
	var full := JokerCard.SIZE
	return minf(minf(size.x / full.x, size.y / full.y), MOST)


func _fit() -> void:
	if card == null:
		return
	var fit := scale_of()
	card.visible = fit >= LEAST
	card.pivot_offset = Vector2.ZERO
	card.scale = Vector2.ONE * fit
	card.position = ((size - JokerCard.SIZE * fit) * 0.5).floor()
