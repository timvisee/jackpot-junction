class_name CardPreview
extends Control
## The picture of the card under the catalog's cursor, large, over the pane that describes it,
## GAME.md 8.8: the card's own picture and the engraved ring round it, in the card's color, rather
## than the whole card, which took twice the room to say nothing more; a joker's of 8.3a, an
## item's, or the question mark of a card face down. At most [constant MOST] across, at the top of
## the room the column leaves it and across the middle of it, so it stays where it is; smaller
## where the room is short, and left out where it would be under [constant LEAST], a phone's short
## screen.

enum Kind { NONE, JOKER, ITEM, UNKNOWN }

## The biggest and the smallest the picture is shown, across.
const MOST := 200.0
const LEAST := 96.0
## The ring round the picture, as the card has it round its own, see [JokerCard]: how far out it
## is, a share of the side, how deep it swings, a share of how far out, and how strongly it shows;
## and how big the picture is inside it, a share of the side.
const RING := 0.44
const RING_DEPTH := 0.1
const RING_LOBES := 14
const RING_LINES := 8
const ENGRAVED := 0.32
const PICTURE := 0.62
## How big the question mark is, a share of the side.
const MARK := 0.46

## What is shown: a joker's or an item's picture, a card face down's question mark, or nothing.
var kind := Kind.NONE
var id: StringName
var ink := Color.WHITE

## The ring as last worked out, and for which side.
var _lines: Array[PackedVector2Array] = []
var _lines_side := -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO


## Shows [param joker]'s picture, in its kind's color.
func show_joker(joker: Joker) -> void:
	_show(Kind.JOKER, joker.id, JokerCard.kind_color(joker))


## Shows [param item]'s picture, in its color.
func show_item(item: PowerUp) -> void:
	_show(Kind.ITEM, item.id, PowerUp.ink_of(item))


## Shows the question mark of a card face down.
func show_unknown() -> void:
	_show(Kind.UNKNOWN, &"", CardBack.INK)


## Whether there is a picture to show and room enough to show it.
func is_shown() -> bool:
	return kind != Kind.NONE and side() >= LEAST


## How big the picture is shown, across.
func side() -> float:
	return minf(minf(size.x, size.y), MOST)


func _show(what: Kind, named: StringName, color: Color) -> void:
	if what == kind and named == id and color == ink:
		return
	kind = what
	id = named
	ink = color
	queue_redraw()


func _draw() -> void:
	if not is_shown():
		return
	var across := side()
	var box := Rect2(Vector2(floorf((size.x - across) * 0.5), 0.0), Vector2(across, across))
	var middle := box.get_center()
	if not is_equal_approx(_lines_side, across):
		_lines_side = across
		var out := across * RING
		_lines = Engraving.rings(Vector2.ZERO, out, out * RING_DEPTH, RING_LOBES, RING_LINES, 240)
	draw_set_transform(middle)
	Engraving.draw_on(self, _lines, Color(ink, ENGRAVED), 1.0)
	draw_set_transform(Vector2.ZERO)
	var inside := Vector2.ONE * across * PICTURE
	var picture := Rect2(middle - inside * 0.5, inside)
	match kind:
		Kind.JOKER:
			JokerArt.draw_into(self, picture, id, ink)
		Kind.ITEM:
			PowerUpArt.draw_into(self, picture, id, ink)
		Kind.UNKNOWN:
			CardBack.draw_mark(self, middle, roundi(across * MARK), ink)
