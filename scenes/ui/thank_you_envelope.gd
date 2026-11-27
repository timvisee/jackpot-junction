class_name ThankYouEnvelope
extends Control
## What the supporter pack's thank-you card comes in, GAME.md 10.8: not the House's bulk mail but a
## kraft envelope addressed by hand, "TO: YOU", as the House's invitation is, a real stamp in its
## corner with a lighthouse on it, and a round postmark across the stamp. Drawn in code at
## [constant SIZE].

const SIZE := Vector2(720.0, 480.0)
const KRAFT := Color(0.76, 0.62, 0.44)
const KRAFT_DARK := Color(0.62, 0.49, 0.33)
const INK := Color(0.16, 0.18, 0.3)
const STAMP_PAPER := Color(0.97, 0.95, 0.9)
const STAMP_FIELD := Color(0.22, 0.32, 0.55)
const POSTMARK := Color(0.2, 0.2, 0.25, 0.65)
## The address written on it, and the postmark's words, shown through tr().
const TO := "TO: YOU"
const WHERE := "Jackpot Junction, table one"
const STAMP := Rect2(560.0, 36.0, 120.0, 144.0)
const POSTMARK_AT := Vector2(548.0, 150.0)
const POSTMARK_WORDS := "THANK YOU"
## The address: the foot of its first line, under the flap's point, and how far down the second's
## is; how big each is written; and how far the rule under the first runs past the longer of them.
const ADDRESS_FOOT := 318.0
const WHERE_DOWN := 54.0
const TO_SIZE := 54
const WHERE_SIZE := 34
const RULE_PAST := 24.0


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var paper := StyleBoxFlat.new()
	paper.bg_color = KRAFT
	paper.set_corner_radius_all(6)
	paper.anti_aliasing = true
	paper.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	paper.shadow_size = 18
	paper.shadow_offset = Vector2(0.0, 10.0)
	draw_style_box(paper, Rect2(Vector2.ZERO, SIZE))
	# The flap's edges, folded in from the back.
	for line: PackedVector2Array in [
		PackedVector2Array([Vector2(0.0, 0.0), Vector2(SIZE.x * 0.5, SIZE.y * 0.46)]),
		PackedVector2Array([Vector2(SIZE.x, 0.0), Vector2(SIZE.x * 0.5, SIZE.y * 0.46)]),
	]:
		draw_polyline(line, KRAFT_DARK, 2.0, true)
	_draw_address()
	_draw_stamp()
	_draw_postmark()


## Who it is for and where, written by hand in the middle of the envelope under the flap's point,
## a rule under the first line as long as the longer of the two and a little past.
func _draw_address() -> void:
	var hand := BayArt.hand_font()
	var middle := SIZE.x * 0.5
	var to := tr(TO)
	var where := tr(WHERE)
	var to_wide := hand.get_string_size(to, HORIZONTAL_ALIGNMENT_LEFT, -1, TO_SIZE).x
	var where_wide := hand.get_string_size(where, HORIZONTAL_ALIGNMENT_LEFT, -1, WHERE_SIZE).x
	var at := Vector2(middle - to_wide * 0.5, ADDRESS_FOOT)
	draw_string(hand, at, to, HORIZONTAL_ALIGNMENT_LEFT, -1, TO_SIZE, INK)
	var under := Vector2(middle - where_wide * 0.5, ADDRESS_FOOT + WHERE_DOWN)
	draw_string(hand, under, where, HORIZONTAL_ALIGNMENT_LEFT, -1, WHERE_SIZE, INK)
	var half := maxf(to_wide, where_wide) * 0.5 + RULE_PAST
	var rule := ADDRESS_FOOT + 12.0
	draw_line(
		Vector2(middle - half, rule), Vector2(middle + half, rule + 4.0), Color(INK, 0.4), 1.5, true
	)


## The stamp: white paper with a toothed edge round a blue field, a lighthouse on it in cream.
func _draw_stamp() -> void:
	draw_rect(STAMP, STAMP_PAPER)
	var teeth := 10
	for i: int in teeth + 1:
		var along := float(i) / float(teeth)
		for at: Vector2 in [
			Vector2(STAMP.position.x + STAMP.size.x * along, STAMP.position.y),
			Vector2(STAMP.position.x + STAMP.size.x * along, STAMP.end.y),
		]:
			draw_circle(at, 4.0, KRAFT)
		var down := STAMP.position.y + STAMP.size.y * along
		draw_circle(Vector2(STAMP.position.x, down), 4.0, KRAFT)
		draw_circle(Vector2(STAMP.end.x, down), 4.0, KRAFT)
	var field := STAMP.grow(-12.0)
	draw_rect(field, STAMP_FIELD)
	var foot := field.get_center() + Vector2(0.0, 30.0)
	var cream := Color(0.96, 0.92, 0.82)
	draw_colored_polygon(
		PackedVector2Array(
			[
				foot + Vector2(-12.0, 0.0),
				foot + Vector2(-8.0, -56.0),
				foot + Vector2(8.0, -56.0),
				foot + Vector2(12.0, 0.0),
			]
		),
		cream
	)
	draw_rect(Rect2(foot + Vector2(-7.0, -68.0), Vector2(14.0, 12.0)), Color(1.0, 0.88, 0.6))
	draw_colored_polygon(
		PackedVector2Array(
			[foot + Vector2(-17.0, -2.0), foot + Vector2(17.0, -2.0), foot + Vector2(0.0, 8.0)]
		),
		cream.darkened(0.3)
	)


## A round postmark half over the stamp, THANK YOU round its rim and wavy lines off its side.
func _draw_postmark() -> void:
	draw_arc(POSTMARK_AT, 46.0, 0.0, TAU, 48, POSTMARK, 2.5, true)
	draw_arc(POSTMARK_AT, 34.0, 0.0, TAU, 48, POSTMARK, 1.5, true)
	var font := Type.STRONG
	draw_string(
		font,
		POSTMARK_AT + Vector2(-34.0, 5.0),
		tr(POSTMARK_WORDS),
		HORIZONTAL_ALIGNMENT_CENTER,
		68.0,
		12,
		POSTMARK
	)
	for i: int in 4:
		var y := POSTMARK_AT.y - 18.0 + float(i) * 12.0
		var wave := PackedVector2Array()
		for k: int in 18:
			var x := POSTMARK_AT.x - 70.0 - float(k) * 12.0
			wave.append(Vector2(x, y + sin(float(k) * 0.9) * 3.0))
		draw_polyline(wave, POSTMARK, 2.0, true)
