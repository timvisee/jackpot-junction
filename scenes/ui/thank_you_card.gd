class_name ThankYouCard
extends Control
## The Steam supporter pack's thank-you card, GAME.md 10.8: a postcard from the maker rather than
## anything of the House's, outside the story. Cream card, a hand-lettered note in ink, the pack's
## star in silver beside a little lighthouse drawn in pencil, and the maker's name signed at its
## foot. Drawn in code at [constant SIZE]; [method shine] draws where its silver catches the light,
## for [HeldCard]. [ThankYouEnvelope] is what it comes in.

const SIZE := Vector2(660.0, 440.0)
const RADIUS := 10
const CARD := Color(0.96, 0.93, 0.85)
const EDGE := Color(0.82, 0.76, 0.64)
const INK := Color(0.16, 0.2, 0.36)
const PENCIL := Color(0.35, 0.34, 0.36, 0.8)
const SILVER := Color(0.56, 0.6, 0.72)
## The words, the maker's own: a draft, to be rewritten in the maker's voice. Shown through tr().
const HEADING := "Thank you!"
const NOTE := """You picked up the Supporter Pack, and that means a lot. Jackpot Junction stays \
free for everyone because people like you chip in. The pieces in the garage are yours now. Wear \
them proudly, and have fun at the tables."""
## The hand the maker signs in, the name signed, and what is written under it, shown through tr().
const SIGNATURE := preload("res://assets/fonts/HomemadeApple-Regular.ttf")
const SIGNED := "timvisee"
const SIGNED_LINE := "made Jackpot Junction"
## Where the note's words go, and how wide, and where the star and the lighthouse stand.
const WORDS_AT := Vector2(44.0, 116.0)
const WORDS_WIDE := 380.0
const STAR_AT := Vector2(548.0, 118.0)
const STAR_REACH := 46.0
const LIGHTHOUSE_AT := Vector2(548.0, 330.0)


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var card := StyleBoxFlat.new()
	card.bg_color = CARD
	card.set_corner_radius_all(RADIUS)
	card.set_border_width_all(2)
	card.border_color = EDGE
	card.anti_aliasing = true
	card.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	card.shadow_size = 16
	card.shadow_offset = Vector2(0.0, 8.0)
	draw_style_box(card, Rect2(Vector2.ZERO, SIZE))
	# A postcard's line down its right, where the address would go, left empty.
	draw_line(Vector2(458.0, 40.0), Vector2(458.0, SIZE.y - 40.0), Color(EDGE, 0.8), 1.5, true)
	var hand := BayArt.hand_font()
	draw_string(hand, Vector2(40.0, 92.0), tr(HEADING), HORIZONTAL_ALIGNMENT_LEFT, -1, 64, INK)
	var note := TextParagraph.new()
	note.width = WORDS_WIDE
	note.add_string(tr(NOTE), hand, 25)
	note.draw(get_canvas_item(), WORDS_AT, INK)
	draw_string(
		SIGNATURE, Vector2(44.0, SIZE.y - 58.0), SIGNED, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, INK
	)
	draw_string(
		hand,
		Vector2(44.0, SIZE.y - 26.0),
		tr(SIGNED_LINE),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color(INK, 0.7)
	)
	_draw_star(self, SILVER)
	_draw_lighthouse()


## Where the card's silver catches the light, white on black, for [HeldCard]: its star.
func shine() -> Control:
	var sheet := ColorRect.new()
	sheet.color = Color.BLACK
	sheet.size = SIZE
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.draw.connect(func() -> void: _draw_star(sheet, Color.WHITE))
	return sheet


## The pack's star at [constant STAR_AT] on [param on] in [param ink]: four points and a ring.
static func _draw_star(on: CanvasItem, ink: Color) -> void:
	var points := PackedVector2Array()
	for i: int in 8:
		var reach := STAR_REACH * (1.0 if i % 2 == 0 else 0.26)
		points.append(STAR_AT + Vector2.UP.rotated(TAU * float(i) / 8.0) * reach)
	on.draw_colored_polygon(points, ink)
	on.draw_arc(STAR_AT, STAR_REACH * 0.62, 0.0, TAU, 48, ink, 2.0, true)


## A little lighthouse in pencil under the star, its beam a few strokes out to the side.
func _draw_lighthouse() -> void:
	var foot := LIGHTHOUSE_AT
	var outline := PackedVector2Array(
		[
			foot + Vector2(-22.0, 40.0),
			foot + Vector2(-13.0, -40.0),
			foot + Vector2(13.0, -40.0),
			foot + Vector2(22.0, 40.0),
			foot + Vector2(-22.0, 40.0),
		]
	)
	draw_polyline(outline, PENCIL, 2.0, true)
	for band: float in [-10.0, 14.0]:
		var wide := lerpf(13.0, 22.0, (band + 40.0) / 80.0)
		draw_line(foot + Vector2(-wide, band), foot + Vector2(wide, band), PENCIL, 2.0, true)
	draw_rect(Rect2(foot + Vector2(-11.0, -58.0), Vector2(22.0, 18.0)), PENCIL, false, 2.0)
	draw_line(foot + Vector2(-14.0, -58.0), foot + Vector2(0.0, -72.0), PENCIL, 2.0, true)
	draw_line(foot + Vector2(14.0, -58.0), foot + Vector2(0.0, -72.0), PENCIL, 2.0, true)
	for ray: float in [-0.25, -0.1, 0.05]:
		var from := foot + Vector2(14.0, -49.0)
		draw_line(from, from + Vector2.RIGHT.rotated(ray) * 46.0, PENCIL, 1.4, true)
	draw_line(foot + Vector2(-46.0, 44.0), foot + Vector2(46.0, 44.0), PENCIL, 2.0, true)
