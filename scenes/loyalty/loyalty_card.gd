class_name LoyaltyCard
extends Control
## The loyalty program's card, GAME.md 8.9 and STORY.md 6.6b: black plastic edged in gold, the
## program's name in foil with the line under it, a gold contact pad, the member number and the
## profile's name embossed. Its back, see [member back], has the magnetic stripe, a signature strip
## with the player's name on it, and the House's microprint under them; once a lap of the
## roundabout is won, the lap is printed on it. Drawn in code at [constant SIZE]; drawn as where it
## shines, see [member shine_only], for the light to catch its foil and nothing else.

const SIZE := Vector2(540.0, 340.0)
const CORNER := 22.0
## The contact pad on the card's face, gold and metal.
const PAD := Rect2(Vector2(44.0, 128.0), Vector2(70.0, 54.0))
## The plastic, a little lighter toward its top left, and its fine lines.
const PLASTIC := Color("#121116")
const PLASTIC_LIGHT := Color("#25232c")
const FINE := Color(1.0, 1.0, 1.0, 0.035)
## The gold edge round it and the line inside that.
const EDGE := 7.0
const EDGE_IN := 15.0
## The embossing: the plastic pressed up in a pale silver, lit from above.
const EMBOSSED := Color("#d8d4cc")
const EMBOSS_DARK := Color(0.0, 0.0, 0.0, 0.7)
const EMBOSS_LIGHT := Color(1.0, 1.0, 1.0, 0.35)
## The back: its stripe, the signature strip and its pattern, the hand that signed it.
const STRIPE := Color("#060508")
const STRIP := Color("#efe6d2")
const STRIP_PATTERN := Color(0.62, 0.52, 0.3, 0.22)
const SIGNED := preload("res://assets/fonts/HomemadeApple-Regular.ttf")
const SIGNED_INK := Color("#1d2a5c")
## What the back says in microprint, STORY.md 6.6b, and over its signature strip.
const MICROPRINT: Array[String] = [
	"THIS CARD REMAINS THE PROPERTY OF THE HOUSE · NOT TRANSFERABLE",
	"ALL PLAY IS RECORDED",
]
const SIGNATURE := "AUTHORIZED SIGNATURE"
const MEMBER := "MEMBER"
const NUMBER := "No."
const LAP := "LAP %d"

## The program's name and its line, by the story's stage.
var program := "Loyalty Program"
var line := ""
## Whose card it is and its number.
var holder := ""
var member := "0000 0000"
## The laps of the roundabout won, printed on the card once there is one, GAME.md 8.9.
var laps := 0
## This card's back rather than its face; and this card drawn as where it shines, white on black.
var back := false
var shine_only := false


func _init() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The card of [param profile], as its screens show the program now.
static func of(profile: Profile) -> LoyaltyCard:
	var card := LoyaltyCard.new()
	card.program = LoyaltyDialog.program_name(profile)
	card.line = LoyaltyDialog.program_line(profile)
	card.holder = holder_of(profile)
	card.member = profile.loyalty.member if not profile.loyalty.member.is_empty() else "0000 0000"
	card.laps = profile.loyalty.laps
	return card


## Whose name the card carries: the profile's first player's, the name on its license, or the
## House's word for a member it has no name for.
static func holder_of(profile: Profile) -> String:
	if not profile.player_names[0].strip_edges().is_empty():
		return profile.player_names[0].strip_edges()
	if not profile.license_holder.strip_edges().is_empty():
		return profile.license_holder.strip_edges()
	return "Valued Member"


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, SIZE)
	if shine_only:
		_rounded(rect, Color.BLACK)
		_draw_foil(Color.WHITE)
		# The contact pad is metal too, and catches the light as the gold does.
		if not back:
			draw_rect(PAD, Color.WHITE)
		return
	_rounded(rect, PLASTIC)
	# Lighter toward the top left, the way a lamp catches plastic, and fine lines across it, both
	# kept inside the card's rounded edge.
	var edge := outline()
	var lamp := PackedVector2Array(
		[Vector2.ZERO, Vector2(SIZE.x * 0.75, 0.0), Vector2(0.0, SIZE.y * 0.9)]
	)
	for lit: PackedVector2Array in Geometry2D.intersect_polygons(lamp, edge):
		var shades := PackedColorArray()
		for point: Vector2 in lit:
			var fade := 1.0 - point.x / (SIZE.x * 0.75) - point.y / (SIZE.y * 0.9)
			shades.append(Color(PLASTIC_LIGHT, 0.9 * clampf(fade, 0.0, 1.0)))
		draw_polygon(lit, shades)
	for i: int in 26:
		var x := -SIZE.y + i * 34.0
		var across := PackedVector2Array([Vector2(x, SIZE.y), Vector2(x + SIZE.y, 0.0)])
		for piece: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(across, edge):
			draw_line(piece[0], piece[-1], FINE, 1.0, true)
	if back:
		_draw_back()
	else:
		_draw_front()


func _draw_front() -> void:
	_draw_foil(HouseTheme.FOIL)
	# The contact pad, gold, its lines.
	var pad := PAD
	draw_rect(pad, HouseTheme.FOIL_LOW)
	draw_rect(pad.grow(-3.0), HouseTheme.FOIL)
	for y: float in [pad.position.y + 18.0, pad.position.y + 36.0]:
		draw_line(
			Vector2(pad.position.x + 3.0, y), Vector2(pad.end.x - 3.0, y), HouseTheme.FOIL_LOW, 1.5
		)
	draw_line(
		Vector2(pad.get_center().x, pad.position.y + 3.0),
		Vector2(pad.get_center().x, pad.end.y - 3.0),
		HouseTheme.FOIL_LOW,
		1.5
	)
	var numbers := Type.numbers_font()
	_embossed(Vector2(44.0, 244.0), "%s %s" % [NUMBER, member], numbers, 34)
	_embossed(Vector2(44.0, 296.0), holder.to_upper(), Type.STRONG, 24)
	var small := Type.micro_font()
	draw_string(
		small,
		Vector2(SIZE.x - 150.0, 296.0),
		MEMBER,
		HORIZONTAL_ALIGNMENT_RIGHT,
		110.0,
		12,
		HouseTheme.FOIL_LOW
	)
	_emblem(Vector2(SIZE.x - 104.0, 196.0), 50.0, HouseTheme.FOIL)


## The gold on the card's face, or where it shines: the edge, the program's name and its line, and
## the lap once there is one.
func _draw_foil(gold: Color) -> void:
	var edge := Rect2(Vector2.ONE * EDGE, SIZE - Vector2.ONE * EDGE * 2.0)
	_rounded_line(edge, gold, 2.6, CORNER - EDGE)
	_rounded_line(edge.grow(-(EDGE_IN - EDGE)), Color(gold, 0.55), 1.0, CORNER - EDGE_IN)
	if back:
		return
	var display := Type.display_font()
	draw_string(
		display,
		Vector2(44.0, 84.0),
		program.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT,
		SIZE.x - 88.0,
		40,
		gold
	)
	draw_string(
		Type.micro_font(),
		Vector2(46.0, 106.0),
		line,
		HORIZONTAL_ALIGNMENT_LEFT,
		SIZE.x - 90.0,
		11,
		Color(gold, 0.85)
	)
	if laps > 0:
		draw_string(
			display, Vector2(136.0, 170.0), LAP % laps, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, gold
		)
	if shine_only:
		_emblem(Vector2(SIZE.x - 104.0, 196.0), 50.0, gold)


## The House's chip, its emblem, [param radius] round [param at]: a gold chip, its edge notched,
## a star in its middle.
func _emblem(at: Vector2, radius: float, gold: Color) -> void:
	draw_circle(at, radius, Color(gold, 0.18))
	draw_arc(at, radius, 0.0, TAU, 48, gold, 2.4, true)
	for i: int in 8:
		var angle := TAU * i / 8.0
		draw_line(
			at + Vector2.from_angle(angle) * radius * 0.78,
			at + Vector2.from_angle(angle) * radius,
			gold,
			radius * 0.2,
			true
		)
	draw_arc(at, radius * 0.62, 0.0, TAU, 40, Color(gold, 0.8), 1.4, true)
	var star := PackedVector2Array()
	for i: int in 10:
		var reach := radius * (0.44 if i % 2 == 0 else 0.19)
		star.append(at + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * reach)
	draw_colored_polygon(star, gold)


func _draw_back() -> void:
	draw_rect(Rect2(0.0, 34.0, SIZE.x, 62.0), STRIPE)
	var strip := Rect2(Vector2(40.0, 132.0), Vector2(330.0, 56.0))
	draw_rect(strip, STRIP)
	for i: int in 22:
		var x := strip.position.x + i * 16.0
		draw_line(Vector2(x, strip.end.y), Vector2(x + 12.0, strip.position.y), STRIP_PATTERN, 4.0)
	draw_string(
		Type.micro_font(),
		strip.position + Vector2(0.0, -8.0),
		SIGNATURE,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color(EMBOSSED, 0.6)
	)
	draw_string(
		SIGNED,
		strip.position + Vector2(14.0, 40.0),
		holder,
		HORIZONTAL_ALIGNMENT_LEFT,
		strip.size.x - 20.0,
		22,
		SIGNED_INK
	)
	# The card's number again, small, and the House's mark beside the strip.
	draw_string(
		Type.numbers_font(),
		Vector2(390.0, 170.0),
		member,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color(EMBOSSED, 0.8)
	)
	draw_string(
		Type.micro_font(),
		Vector2(40.0, 236.0),
		program.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		HouseTheme.FOIL_LOW
	)
	for i: int in MICROPRINT.size():
		var at := Vector2(40.0, 282.0 + i * 14.0)
		draw_string(
			Type.micro_font(),
			at,
			MICROPRINT[i],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			9,
			Color(EMBOSSED, 0.55)
		)
	_draw_foil(HouseTheme.FOIL_LOW)


## [param text] pressed up out of the plastic at [param at]: a shadow under it, a light over it,
## the silver between.
func _embossed(at: Vector2, text: String, font: Font, size_of: int) -> void:
	draw_string(
		font, at + Vector2(1.5, 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_of, EMBOSS_DARK
	)
	draw_string(
		font, at + Vector2(-1.0, -1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_of, EMBOSS_LIGHT
	)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_of, EMBOSSED)


## The card's edge as a polygon, its corners rounded as [method _rounded] draws them.
static func outline() -> PackedVector2Array:
	var points := PackedVector2Array()
	var centers: Array[Vector2] = [
		Vector2(SIZE.x - CORNER, CORNER),
		Vector2(SIZE.x - CORNER, SIZE.y - CORNER),
		Vector2(CORNER, SIZE.y - CORNER),
		Vector2(CORNER, CORNER),
	]
	for i: int in centers.size():
		for step: int in 9:
			var angle := -PI * 0.5 + (i + step / 8.0) * PI * 0.5
			points.append(centers[i] + Vector2.from_angle(angle) * CORNER)
	return points


func _rounded(rect: Rect2, fill: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(int(CORNER))
	style.anti_aliasing = true
	draw_style_box(style, rect)


func _rounded_line(rect: Rect2, ink: Color, width: float, corner: float) -> void:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = ink
	style.set_border_width_all(int(ceilf(width)))
	style.set_corner_radius_all(int(maxf(corner, 0.0)))
	style.anti_aliasing = true
	draw_style_box(style, rect)
