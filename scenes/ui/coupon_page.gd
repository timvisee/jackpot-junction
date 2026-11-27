class_name CouponPage
extends VBoxContainer
## The House's coupon on the payout slip, GAME.md 8.9a: a page of its own after the program's when
## the map just played opened a card of the table for the profile playing, headed Compliments of
## the House, a coupon for each card opened, cut out along a dashed red line: the card's face, its
## name, what it does in a line, and that it is good from the next map on. A map that opened none
## has no page.

const INK := HouseTheme.INK
const FAINT := HouseTheme.INK_FAINT
const CUT := Color(0.77, 0.27, 0.24)
## How tall a coupon is, and how big its card stands in it.
const TALL := 210.0
const CARD := Vector2(118.0, 118.0 * TableCardArt.ASPECT)
## The House's rubber stamp across its right end, COMP as a casino comps a regular, how big and how
## askew.
const STAMP := 52.0
const STAMP_TURN := -0.22

var heading: Label
var caption: Label
var rows: VBoxContainer


## One card opened: a coupon cut out of the slip.
class Coupon:
	extends Control

	var card := 0

	func _init() -> void:
		custom_minimum_size.y = CouponPage.TALL
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var box := Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0))
		draw_rect(box, Color(1.0, 0.97, 0.9))
		# The dashed line it is cut out along.
		var corners: Array[Vector2] = [box.position, Vector2(box.end.x, box.position.y), box.end]
		corners.append(Vector2(box.position.x, box.end.y))
		for i: int in 4:
			draw_dashed_line(corners[i], corners[(i + 1) % 4], CouponPage.CUT, 2.0, 8.0)
		var room := (size.y - CouponPage.CARD.y) * 0.5
		var face := Rect2(Vector2(room + 6.0, room), CouponPage.CARD)
		TableCardArt.face(self, face, card)
		var left := face.end.x + 26.0
		var wide := size.x - left - CouponPage.STAMP * 2.0 - 30.0
		draw_string(
			Type.STRONG,
			Vector2(left, room + 22.0),
			tr("NOW OPEN AT YOUR TABLE"),
			HORIZONTAL_ALIGNMENT_LEFT,
			wide,
			16,
			CouponPage.CUT
		)
		draw_string(
			Type.display_font(),
			Vector2(left, room + 74.0),
			tr(TableCards.NAMES[card]).to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT,
			wide,
			52,
			CouponPage.INK
		)
		draw_multiline_string(
			Type.TEXT,
			Vector2(left, room + 108.0),
			tr(TableCards.LINES[card]),
			HORIZONTAL_ALIGNMENT_LEFT,
			wide,
			19,
			2,
			CouponPage.INK
		)
		draw_string(
			Type.micro_font(),
			Vector2(left, face.end.y - 2.0),
			tr("VALID FROM YOUR NEXT MAP"),
			HORIZONTAL_ALIGNMENT_LEFT,
			wide,
			12,
			CouponPage.FAINT
		)
		# Last, the stamp turning the canvas it is put down on.
		# TRANSLATORS: A rubber stamp: COMP, as a casino comps a regular, over THE HOUSE and NO EXPIRY.
		StampArt.stamp(
			self,
			Vector2(size.x - CouponPage.STAMP - 24.0, size.y * 0.5),
			CouponPage.STAMP,
			tr("COMP"),
			tr("THE HOUSE"),
			tr("NO EXPIRY"),
			CouponPage.STAMP_TURN,
			Color(CouponPage.CUT, 0.8)
		)


static func create() -> CouponPage:
	var page := CouponPage.new()
	page._build()
	return page


func _build() -> void:
	name = "CouponPage"
	add_theme_constant_override("separation", 14)
	heading = MenuTheme.title(tr("Compliments of the House"), Type.TITLE)
	heading.name = "Heading"
	heading.add_theme_color_override("font_color", INK)
	heading.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	add_child(heading)
	caption = MenuTheme.subtitle("", Type.LABEL)
	caption.name = "Caption"
	caption.add_theme_color_override("font_color", FAINT)
	add_child(caption)
	var band := ColorRect.new()
	band.color = HouseTheme.FOIL
	band.custom_minimum_size = Vector2(0.0, 3.0)
	add_child(band)
	rows = VBoxContainer.new()
	rows.name = "Rows"
	rows.add_theme_constant_override("separation", 12)
	add_child(rows)


## A coupon for each card of [param opened], a table's bits; false for none, which is no page.
func fill(opened: int) -> bool:
	for child: Node in rows.get_children():
		rows.remove_child(child)
		child.free()
	var cards := TableCards.cards_of(opened)
	caption.text = tr_n(
		"A new feature for your table, as a thank-you for playing",
		"New features for your table, as a thank-you for playing",
		cards.size()
	)
	var said: PackedStringArray = []
	for card: int in cards:
		var coupon := Coupon.new()
		coupon.card = card
		coupon.name = "Coupon%d" % card
		rows.add_child(coupon)
		said.append("%s: %s" % [tr(TableCards.NAMES[card]), tr(TableCards.LINES[card])])
	ScreenReader.name(self, heading.text, " ".join(said))
	return not cards.is_empty()
