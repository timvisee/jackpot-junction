class_name ItemCard
extends Panel
## A power-up drawn as a card for the catalog of GAME.md 8.8, so the items sit in a grid the way the
## jokers beside them do: the size, the round corners and the engraving of a [JokerCard], framed
## and engraved in the item's own color, with its picture of 8.3a in the middle and its name under
## it. No pips: an item has no rarity.

const KIND := "Item"

var item: PowerUp

var _normal: StyleBoxFlat
var _chosen: StyleBoxFlat


static func create(for_item: PowerUp) -> ItemCard:
	var card := ItemCard.new()
	card.item = for_item
	card._build()
	ScreenReader.name(card, for_item.display_name, for_item.description)
	return card


## Lights the card up as the one under the cursor, as [method JokerCard.set_highlighted] does.
func set_highlighted(on: bool) -> void:
	add_theme_stylebox_override("panel", _chosen if on else _normal)


func _build() -> void:
	size = JokerCard.SIZE
	pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, JokerCard.SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_normal = StyleBoxFlat.new()
	_normal.bg_color = Color(0.11, 0.11, 0.14, 0.96)
	_normal.set_corner_radius_all(10)
	_normal.set_border_width_all(3)
	var ink := PowerUp.ink_of(item)
	_normal.border_color = ink
	_normal.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	_normal.shadow_size = 6
	_chosen = _normal.duplicate()
	_chosen.bg_color = Color(0.22, 0.18, 0.08, 1.0)
	_chosen.set_border_width_all(5)
	_chosen.border_color = Palette.CHIP_WHITE
	_chosen.shadow_color = Color(Palette.CHIP_GOLD, 0.75)
	_chosen.shadow_size = 18
	add_theme_stylebox_override("panel", _normal)
	var face := JokerCard.Face.new()
	face.name = "Face"
	face.ink = ink
	add_child(face)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var kind := Label.new()
	kind.text = KIND.to_upper()
	kind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(kind, Type.STRONG, 13)
	kind.add_theme_color_override("font_color", ink)
	var room := StyleBoxEmpty.new()
	room.content_margin_left = JokerCard.KIND_ROOM
	kind.add_theme_stylebox_override("normal", room)
	stack.add_child(kind)
	var art := PowerUpArt.picture(item.id, ink)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(art)
	var title := Label.new()
	title.text = item.display_name
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(title, Type.STRONG, 15)
	title.add_theme_color_override("font_color", Palette.CHIP_WHITE)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	# Where a joker's pips go, the same room, so the names line up across the two pages.
	var foot := Control.new()
	foot.custom_minimum_size = Vector2(0.0, JokerCard.PIP)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(foot)
