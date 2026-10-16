class_name AchievementIcons
extends RefCounted
## Each achievement's own picture, GAME.md 8.10: what it is about, on the inlay of its chip or the
## enamel of its pin, so no two of the list look alike. Drawn the way every icon in the game is, see
## [IconShapes]: in a box, every measure a fraction of it, in one ink and the fainter of it, with
## [param paper] for what is cut out of the ink, so a picture serves a chip's cream, a pin's enamel
## and the gray of one not earned yet alike.


## The picture of [param id] into [param box] on [param on], in [param ink] on [param paper].
static func draw_into(on: CanvasItem, box: Rect2, id: StringName, ink: Color, paper: Color) -> void:
	var faint := IconShapes.behind(ink)
	match id:
		&"street_legal":
			_license(on, box, ink, faint)
		&"honor_roll":
			IconShapes.star(on, box, 0.5, 0.62, 0.3, ink)
			for i: int in 7:
				var angle := deg_to_rad(198.0 + i * 24.0)
				var at := Vector2(0.5, 0.64) + Vector2(cos(angle), sin(angle)) * 0.44
				IconShapes.disc(on, box, at.x, at.y, 0.05, ink)
		&"flawless":
			IconShapes.heart(on, box, 0.48, 0.56, 0.3, ink)
			IconShapes.spiked(on, box, 0.8, 0.22, 0.12, 4, 0.3, ink)
			IconShapes.spiked(on, box, 0.18, 0.26, 0.08, 4, 0.3, faint)
		&"beat_the_house":
			_beaten_robot(on, box, ink, paper)
		&"clean_sweep":
			_trophy(on, box, ink, faint)
		&"last_kart_standing":
			_kart(on, box, Vector2(0.24, 0.22), 0.75, 196.0, faint, paper)
			_kart(on, box, Vector2(0.78, 0.24), 0.75, 168.0, faint, paper)
			_kart(on, box, Vector2(0.22, 0.86), 0.75, 182.0, faint, paper)
			_kart(on, box, Vector2(0.54, 0.6), 1.35, 0.0, ink, paper)
		&"all_in":
			_stack(on, box, 0.36, 0.88, 7, ink, paper)
			IconShapes.tri(on, box, 0.72, 0.5, 0.2, 90.0, faint)
			IconShapes.tri(on, box, 0.88, 0.5, 0.2, 90.0, ink)
		&"by_a_nose":
			_finish(on, box, ink, paper)
			_kart(on, box, Vector2(0.56, 0.34), 1.0, 0.0, ink, paper)
			_kart(on, box, Vector2(0.47, 0.74), 1.0, 0.0, faint, paper)
		&"buzzer_beater":
			_stopwatch(on, box, ink, faint)
		&"winner_takes_all":
			# A pair, one of it gone over and the other standing, crowned.
			_card(on, box, Vector2(0.4, 0.84), -66.0, Vector2(0.26, 0.38), paper, faint)
			_card(on, box, Vector2(0.6, 0.84), 4.0, Vector2(0.32, 0.48), paper, ink)
			IconShapes.heart(on, box, 0.59, 0.6, 0.11, ink)
			IconShapes.crown(on, Rect2(IconShapes.at(box, 0.45, 0.06), box.size * 0.28), ink)
		&"partners_in_crime":
			# Two karts side by side on the Junction, seen from the side, cashing out together.
			_ellipse(on, box, Vector2(0.5, 0.72), Vector2(0.5, 0.17), ink)
			_ellipse(on, box, Vector2(0.5, 0.72), Vector2(0.42, 0.12), paper)
			_ellipse(on, box, Vector2(0.5, 0.72), Vector2(0.24, 0.07), faint)
			_kart(on, box, Vector2(0.27, 0.56), 1.05, 0.0, ink, paper)
			_kart(on, box, Vector2(0.75, 0.56), 1.05, 0.0, ink, paper)
		&"push_your_luck":
			_stack(on, box, 0.18, 0.88, 1, faint, paper)
			_stack(on, box, 0.44, 0.88, 3, faint, paper)
			_stack(on, box, 0.7, 0.88, 6, ink, paper)
			IconShapes.tri(on, box, 0.9, 0.18, 0.18, 0.0, ink)
			_line(on, box, [Vector2(0.9, 0.24), Vector2(0.9, 0.5)], ink)
		&"point_of_sale":
			_junction_taped(on, box, ink, faint, paper)
		&"hit_the_jackpot":
			_traffic_light(on, box, ink, faint, paper)
		&"most_wanted":
			_poster(on, box, ink, faint)
		&"snatch_and_grab":
			_ellipse(on, box, Vector2(0.62, 0.9), Vector2(0.34, 0.07), faint)
			_stack(on, box, 0.66, 0.88, 3, ink, paper)
			_claw(on, box, 0.66, 0.5, ink)
			_kart(on, box, Vector2(0.22, 0.74), 0.8, 0.0, faint, paper)
			_cross(on, box, Vector2(0.22, 0.6), 0.08, ink)
		&"full_house":
			for i: int in 3:
				var lean := -22.0 + 22.0 * i
				var foot := Vector2(0.3 + 0.2 * i, 0.9 - (0.04 if i == 1 else 0.0))
				_card(on, box, foot, lean, Vector2(0.32, 0.5), paper, ink)
				var middle := foot + Vector2(0.0, -0.3).rotated(deg_to_rad(lean))
				IconShapes.crown(
					on,
					Rect2(IconShapes.at(box, middle.x - 0.1, middle.y - 0.08), box.size * 0.2),
					ink
				)
		&"bank_shot":
			IconShapes.bar(on, box, 0.06, 0.08, 0.88, 0.07, faint)
			IconShapes.bar(on, box, 0.06, 0.85, 0.88, 0.07, faint)
			_line(
				on,
				box,
				[Vector2(0.08, 0.56), Vector2(0.34, 0.84), Vector2(0.6, 0.16), Vector2(0.82, 0.5)],
				ink
			)
			IconShapes.disc(on, box, 0.84, 0.53, 0.07, ink)
		&"parry":
			IconShapes.spiked(on, box, 0.5, 0.5, 0.24, 8, 0.42, ink)
			IconShapes.disc(on, box, 0.5, 0.5, 0.07, paper)
			for side: float in [-1.0, 1.0]:
				IconShapes.disc(on, box, 0.5 + side * 0.32, 0.5, 0.07, ink)
				_line(
					on,
					box,
					[Vector2(0.5 + side * 0.38, 0.5), Vector2(0.5 + side * 0.48, 0.5)],
					faint
				)
		&"long_shot":
			_kart(on, box, Vector2(0.16, 0.8), 0.75, -24.0, ink, paper)
			for i: int in 5:
				var t := 0.12 + i * 0.16
				var from := Vector2(0.22, 0.7).lerp(Vector2(0.74, 0.34), t)
				var to := Vector2(0.22, 0.7).lerp(Vector2(0.74, 0.34), t + 0.08)
				_line(on, box, [from, to], ink)
			IconShapes.ring(on, box, 0.8, 0.28, 0.15, ink)
			IconShapes.ring(on, box, 0.8, 0.28, 0.07, ink)
			IconShapes.disc(on, box, 0.8, 0.28, 0.025, ink)
		&"payback":
			IconShapes.arc(on, box, 0.5, 0.52, 0.3, 30.0, 300.0, ink)
			var tip := Vector2(0.5, 0.52) + Vector2.from_angle(deg_to_rad(300.0)) * 0.3
			IconShapes.tri(on, box, tip.x + 0.02, tip.y + 0.01, 0.2, 120.0, ink)
			IconShapes.burst(on, box, 0.5, 0.52, 0.12, faint)
		&"untouchable":
			IconShapes.flame(on, box, 0.5, 0.9, 0.78, 0.0, ink)
			IconShapes.flame(on, box, 0.5, 0.86, 0.36, 0.0, paper)
			IconShapes.flame(on, box, 0.22, 0.86, 0.28, -18.0, faint)
			IconShapes.flame(on, box, 0.8, 0.86, 0.28, 18.0, faint)
		&"tough_as_nails":
			_patched_heart(on, box, ink, faint, paper)
		&"two_birds":
			IconShapes.disc(on, box, 0.38, 0.66, 0.24, ink)
			_line(on, box, [Vector2(0.52, 0.46), Vector2(0.62, 0.36)], ink)
			IconShapes.spiked(on, box, 0.64, 0.33, 0.08, 6, 0.4, faint)
			_bird(on, box, Vector2(0.66, 0.16), ink)
			_bird(on, box, Vector2(0.86, 0.3), ink)
		&"set_and_forget":
			IconShapes.bar(on, box, 0.1, 0.62, 0.48, 0.22, faint)
			IconShapes.disc(on, box, 0.34, 0.52, 0.17, ink)
			IconShapes.bar(on, box, 0.29, 0.12, 0.1, 0.34, ink)
			_cross(on, box, Vector2(0.78, 0.3), 0.08, ink)
			_cross(on, box, Vector2(0.78, 0.6), 0.08, ink)
		&"road_hog":
			for y: float in [0.46, 0.58, 0.7]:
				_line(on, box, [Vector2(0.04, y), Vector2(0.18, y)], faint)
			_kart(on, box, Vector2(0.42, 0.6), 1.3, 0.0, ink, paper)
			IconShapes.bolt(on, box, 0.42, 0.24, 0.22, faint)
			_cross(on, box, Vector2(0.84, 0.36), 0.08, ink)
			_cross(on, box, Vector2(0.86, 0.72), 0.08, ink)
		&"slick_operator":
			_ellipse(on, box, Vector2(0.5, 0.7), Vector2(0.44, 0.19), faint)
			_kart(on, box, Vector2(0.26, 0.66), 0.62, 160.0, ink, paper)
			_kart(on, box, Vector2(0.52, 0.52), 0.62, 35.0, ink, paper)
			_kart(on, box, Vector2(0.77, 0.7), 0.62, -110.0, ink, paper)
			_spin(on, box, Vector2(0.5, 0.58), 0.4, ink)
		&"dead_ringer":
			_kart(on, box, Vector2(0.24, 0.74), 0.85, 0.0, ink, paper)
			_kart(on, box, Vector2(0.46, 0.46), 0.85, 0.0, faint, paper)
			for i: int in 3:
				var from := Vector2(0.64, 0.42).lerp(Vector2(0.82, 0.26), i / 3.0)
				_line(on, box, [from, from + Vector2(0.04, -0.035)], ink)
			_cross(on, box, Vector2(0.88, 0.2), 0.07, ink)
		&"long_way_round":
			_drift_loop(on, box, ink, faint, paper)
		&"push_comes_to_shove":
			_ellipse(on, box, Vector2(0.64, 0.84), Vector2(0.3, 0.11), ink)
			_kart(on, box, Vector2(0.56, 0.5), 1.4, 34.0, ink, paper)
			IconShapes.tri(on, box, 0.1, 0.3, 0.16, 110.0, faint)
			IconShapes.tri(on, box, 0.22, 0.34, 0.16, 110.0, ink)
		&"a_pit_do_not":
			_warning(on, box, ink, paper)
			_ellipse(on, box, Vector2(0.5, 0.74), Vector2(0.17, 0.06), ink)
			IconShapes.disc(on, box, 0.46, 0.5, 0.055, ink)
			IconShapes.disc(on, box, 0.56, 0.6, 0.045, ink)
		&"property_damage":
			_broken_crate(on, box, ink, paper)
		&"suit_yourself":
			# A hand fanned under the four suits, every one of them made.
			for i: int in 5:
				var lean := -28.0 + i * 14.0
				var fill := faint if i % 2 == 0 else paper
				_card(on, box, Vector2(0.5, 0.96), lean, Vector2(0.17, 0.5), fill, ink)
			for suit: int in 4:
				var at := IconShapes.at(box, 0.13 + suit * 0.2, 0.06)
				SuitArt.draw_into(on, Rect2(at, box.size * 0.16), suit, ink)
		&"let_it_ride":
			_sevens(on, box, ink, paper)
			IconShapes.tri(on, box, 0.5, 0.16, 0.26, 0.0, ink)
		&"a_real_handful":
			for i: int in 9:
				var lean := -56.0 + i * 14.0
				var fill := faint if i % 2 == 0 else paper
				_card(on, box, Vector2(0.5, 0.94), lean, Vector2(0.11, 0.6), fill, ink)
		&"stacked":
			for x: float in [0.3, 0.7]:
				for i: int in 3:
					var foot := Vector2(x - 0.06 + i * 0.05, 0.86 - i * 0.05)
					_card(on, box, foot, 0.0, Vector2(0.14, 0.56), paper if i == 2 else faint, ink)
		&"asking_for_trouble":
			_card(on, box, Vector2(0.44, 0.9), -8.0, Vector2(0.24, 0.78), faint, ink)
			IconShapes.bolt(on, box, 0.56, 0.48, 0.34, ink)
		&"full_deck":
			_deck_box(on, box, ink, faint, paper)
		&"toybox":
			_toybox(on, box, ink, faint, paper)
		&"plus_one":
			_pad(on, box, Vector2(0.36, 0.4), faint, paper)
			_pad(on, box, Vector2(0.62, 0.64), ink, paper)
		&"long_distance":
			_screen(on, box, Vector2(0.2, 0.66), ink, faint)
			_screen(on, box, Vector2(0.8, 0.34), ink, faint)
			for i: int in 6:
				var t := 0.12 + i * 0.14
				var a := _curve(t)
				var b := _curve(t + 0.07)
				_line(on, box, [a, b], ink)
		&"full_table":
			IconShapes.disc(on, box, 0.5, 0.5, 0.25, faint)
			IconShapes.ring(on, box, 0.5, 0.5, 0.25, ink)
			for i: int in 8:
				var at := Vector2(0.5, 0.5) + Vector2.from_angle(TAU * i / 8.0) * 0.38
				IconShapes.disc(on, box, at.x, at.y, 0.075, ink)
		&"front_row":
			_couch(on, box, ink, faint)
			IconShapes.ring(on, box, 0.74, 0.2, 0.14, ink)
			IconShapes.heart(on, box, 0.74, 0.21, 0.08, ink)
		&"dressed_to_the_nines":
			IconShapes.bar(on, box, 0.16, 0.5, 0.68, 0.08, ink)
			IconShapes.bar(on, box, 0.3, 0.1, 0.4, 0.42, ink)
			IconShapes.bar(on, box, 0.3, 0.4, 0.4, 0.06, paper)
			IconShapes.tri(on, box, 0.4, 0.78, 0.24, 90.0, ink)
			IconShapes.tri(on, box, 0.6, 0.78, 0.24, 270.0, ink)
			IconShapes.disc(on, box, 0.5, 0.78, 0.045, ink)
		&"know_every_street":
			_signpost(on, box, ink, faint)
		&"most_valued_member":
			_member_card(on, box, ink, paper)
		&"lap_of_luxury":
			_roundabout(on, box, ink, faint, paper)
		&"off_the_books":
			_eye_crossed(on, box, ink, paper)
		&"terms_accepted":
			_approved(on, box, ink, paper)
		&"not_this_time":
			_torn_off(on, box, ink, faint)
		&"employee_of_the_month":
			_frame(on, box, ink, faint, paper)
		&"a_fresh_start":
			_calendar(on, box, ink, faint, paper)
		_:
			IconShapes.ring(on, box, 0.5, 0.5, 0.32, ink)


## A line through [param points] of [param box], [param thick] strokes wide.
static func _line(on: CanvasItem, box: Rect2, points: Array, ink: Color, thick := 1.0) -> void:
	var line := PackedVector2Array()
	for point: Vector2 in points:
		line.append(IconShapes.at(box, point.x, point.y))
	on.draw_polyline(line, ink, IconShapes.width(box) * thick, true)


## A stopwatch, the last seconds before the top shaded in and its hand on them, for a cash-out
## made as the clock runs out.
static func _stopwatch(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	var middle := Vector2(0.5, 0.58)
	var wedge := [middle]
	for i: int in 7:
		wedge.append(middle + Vector2.from_angle(deg_to_rad(-120.0 + i * 5.0)) * 0.27)
	_poly(on, box, wedge, faint)
	IconShapes.ring(on, box, middle.x, middle.y, 0.32, ink)
	IconShapes.bar(on, box, 0.42, 0.1, 0.16, 0.07, ink)
	IconShapes.bar(on, box, 0.48, 0.16, 0.04, 0.1, ink)
	_line(on, box, [middle, middle + Vector2.from_angle(deg_to_rad(-104.0)) * 0.24], ink, 1.3)
	IconShapes.disc(on, box, middle.x, middle.y, 0.04, ink)


## A claw machine's claw, open over what it is about to take, hung from its line.
static func _claw(on: CanvasItem, box: Rect2, x: float, y: float, ink: Color) -> void:
	_line(on, box, [Vector2(x, 0.0), Vector2(x, y - 0.12)], ink)
	IconShapes.bar(on, box, x - 0.08, y - 0.14, 0.16, 0.06, ink)
	_line(
		on,
		box,
		[Vector2(x - 0.06, y - 0.09), Vector2(x - 0.17, y + 0.02), Vector2(x - 0.11, y + 0.1)],
		ink
	)
	_line(
		on,
		box,
		[Vector2(x + 0.06, y - 0.09), Vector2(x + 0.17, y + 0.02), Vector2(x + 0.11, y + 0.1)],
		ink
	)


## A spin as a round arrow over the top of [param middle], [param radius] out, sweeping clockwise.
static func _spin(on: CanvasItem, box: Rect2, middle: Vector2, radius: float, ink: Color) -> void:
	IconShapes.arc(on, box, middle.x, middle.y, radius, 200.0, 322.0, ink)
	var end := deg_to_rad(330.0)
	var tip := middle + Vector2.from_angle(end) * radius
	var heading := Vector2(-sin(end), cos(end))
	IconShapes.tri(on, box, tip.x, tip.y, 0.17, rad_to_deg(atan2(heading.x, -heading.y)), ink)


## A shape of [param points] of [param box], filled.
static func _poly(on: CanvasItem, box: Rect2, points: Array, ink: Color) -> void:
	var shape := PackedVector2Array()
	for point: Vector2 in points:
		shape.append(IconShapes.at(box, point.x, point.y))
	on.draw_colored_polygon(shape, ink)


## [param rect] of [param box] filled in [param fill] and edged in [param ink].
static func _rect(on: CanvasItem, box: Rect2, rect: Rect2, fill: Color, ink: Color) -> void:
	var corners := [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]
	if fill.a > 0.0:
		_poly(on, box, corners, fill)
	corners.append(rect.position)
	_line(on, box, corners, ink)


## A rectangle [param half] out each way from [param middle], turned [param turn] degrees, filled.
static func _quad(
	on: CanvasItem, box: Rect2, middle: Vector2, half: Vector2, turn: float, ink: Color
) -> void:
	var corners := []
	for corner: Vector2 in [
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)
	]:
		corners.append(middle + corner.rotated(deg_to_rad(turn)))
	_poly(on, box, corners, ink)


## A kart seen from the side at [param middle], [param scale] times its usual size, its nose to
## the right, turned [param turn] degrees: upside down at 180, its wheels in the air. Its low body
## with a wedge of a nose, the driver's helmet over the seat, and two fat wheels with their hubs
## cut out; from the side a kart reads at a size its outline from above does not.
static func _kart(
	on: CanvasItem, box: Rect2, middle: Vector2, scale: float, turn: float, ink: Color, paper: Color
) -> void:
	var turned := deg_to_rad(turn)
	var body := []
	for corner: Vector2 in [
		Vector2(-0.21, -0.05),
		Vector2(-0.12, -0.06),
		Vector2(0.02, -0.05),
		Vector2(0.23, 0.0),
		Vector2(0.23, 0.04),
		Vector2(-0.21, 0.04),
	]:
		body.append(middle + (corner * scale).rotated(turned))
	_poly(on, box, body, ink)
	var helmet := middle + (Vector2(-0.07, -0.11) * scale).rotated(turned)
	IconShapes.disc(on, box, helmet.x, helmet.y, 0.055 * scale, ink)
	var visor := middle + (Vector2(-0.04, -0.115) * scale).rotated(turned)
	IconShapes.disc(on, box, visor.x, visor.y, 0.022 * scale, paper)
	for wheel: Vector2 in [Vector2(-0.13, 0.06), Vector2(0.14, 0.065)]:
		var at := middle + (wheel * scale).rotated(turned)
		IconShapes.disc(on, box, at.x, at.y, 0.068 * scale, ink)
		IconShapes.disc(on, box, at.x, at.y, 0.025 * scale, paper)


## A stack of [param count] chips seen from the side, standing on [param foot] at [param x].
static func _stack(
	on: CanvasItem, box: Rect2, x: float, foot: float, count: int, ink: Color, paper: Color
) -> void:
	for i: int in count:
		var top := foot - (i + 1) * 0.1
		IconShapes.bar(on, box, x - 0.13, top, 0.26, 0.085, ink)
		for edge: float in [-0.07, 0.0, 0.07]:
			IconShapes.bar(on, box, x + edge - 0.012, top + 0.02, 0.024, 0.045, paper)


## A playing card standing on [param foot] of [param box], [param size] across and up, leant
## [param lean] degrees.
static func _card(
	on: CanvasItem, box: Rect2, foot: Vector2, lean: float, size: Vector2, fill: Color, ink: Color
) -> void:
	var corners := []
	for corner: Vector2 in [
		Vector2(-size.x * 0.5, 0.0),
		Vector2(-size.x * 0.5, -size.y),
		Vector2(size.x * 0.5, -size.y),
		Vector2(size.x * 0.5, 0.0)
	]:
		corners.append(foot + corner.rotated(deg_to_rad(lean)))
	_poly(on, box, corners, fill)
	corners.append(corners[0])
	_line(on, box, corners, ink, 0.8)


static func _ellipse(
	on: CanvasItem, box: Rect2, middle: Vector2, half: Vector2, ink: Color
) -> void:
	var points := []
	for i: int in 32:
		var angle := TAU * i / 32.0
		points.append(middle + Vector2(cos(angle) * half.x, sin(angle) * half.y))
	_poly(on, box, points, ink)


static func _cross(on: CanvasItem, box: Rect2, middle: Vector2, half: float, ink: Color) -> void:
	_line(on, box, [middle - Vector2(half, half), middle + Vector2(half, half)], ink, 1.2)
	_line(on, box, [middle + Vector2(-half, half), middle + Vector2(half, -half)], ink, 1.2)


## A bird flying, as a child draws one: two wings in a shallow V.
static func _bird(on: CanvasItem, box: Rect2, middle: Vector2, ink: Color) -> void:
	_line(
		on,
		box,
		[
			middle + Vector2(-0.09, -0.04),
			middle + Vector2(-0.04, -0.01),
			middle,
			middle + Vector2(0.04, -0.01),
			middle + Vector2(0.09, -0.04),
		],
		ink,
		1.1
	)


## A drift held all the way round: the two marks of the rear wheels nearly a circle, and the kart
## at their end still hanging out, its nose turned into the turn and smoke off its rear wheel.
static func _drift_loop(on: CanvasItem, box: Rect2, ink: Color, faint: Color, paper: Color) -> void:
	for radius: float in [0.36, 0.27]:
		IconShapes.arc(on, box, 0.5, 0.48, radius, 125.0, 415.0, faint)
	IconShapes.disc(on, box, 0.2, 0.76, 0.05, faint)
	IconShapes.disc(on, box, 0.12, 0.7, 0.035, faint)
	_kart(on, box, Vector2(0.52, 0.8), 0.95, -20.0, ink, paper)


## A crate broken in two, its halves falling apart along the split, each with its frame and its
## brace, and its splinters flying.
static func _broken_crate(on: CanvasItem, box: Rect2, ink: Color, paper: Color) -> void:
	var split := [Vector2(0.5, 0.85), Vector2(0.45, 0.68), Vector2(0.53, 0.55), Vector2(0.46, 0.42)]
	for side: float in [-1.0, 1.0]:
		var pivot := Vector2(0.5 + side * 0.25, 0.85)
		var turned := func(point: Vector2) -> Vector2:
			return (
				pivot + (point - pivot).rotated(deg_to_rad(side * 10.0)) + Vector2(side * 0.05, 0)
			)
		var shape := [turned.call(pivot)]
		for point: Vector2 in split + [Vector2(0.5, 0.3), Vector2(0.5 + side * 0.25, 0.3)]:
			shape.append(turned.call(point))
		_poly(on, box, shape, ink)
		# Its frame, open along the split, and the brace across it, cut out of the ink.
		var outer := 0.5 + side * 0.17
		var inner := 0.44 if side < 0.0 else 0.51
		var points := []
		for point: Vector2 in [
			Vector2(inner, 0.38), Vector2(outer, 0.38), Vector2(outer, 0.77), Vector2(inner, 0.77)
		]:
			points.append(turned.call(point))
		_line(on, box, points, paper, 0.55)
		var brace: Array = [
			turned.call(Vector2(outer, 0.77)), turned.call(Vector2(0.5 + side * 0.06, 0.4))
		]
		_line(on, box, brace, paper, 0.55)
	_quad(on, box, Vector2(0.5, 0.19), Vector2(0.065, 0.02), 60.0, ink)
	_quad(on, box, Vector2(0.32, 0.15), Vector2(0.05, 0.018), -30.0, ink)
	_quad(on, box, Vector2(0.69, 0.14), Vector2(0.055, 0.018), 20.0, ink)


## The driver license: the card, its photo, its lines and the PASSED stamp in its corner.
static func _license(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_rect(on, box, Rect2(0.08, 0.22, 0.84, 0.56), faint, ink)
	IconShapes.bar(on, box, 0.16, 0.32, 0.22, 0.32, ink)
	for y: float in [0.36, 0.46, 0.56]:
		_line(on, box, [Vector2(0.46, y), Vector2(0.82, y)], ink, 0.8)
	IconShapes.ring(on, box, 0.74, 0.7, 0.13, ink)
	IconShapes.ring(on, box, 0.74, 0.7, 0.08, ink)


## A bot knocked out: its head with crosses for eyes, and a star going round it.
static func _beaten_robot(on: CanvasItem, box: Rect2, ink: Color, paper: Color) -> void:
	var head := Rect2(box.position + box.size * Vector2(0.08, 0.14), box.size * Vector2(0.76, 0.76))
	IconShapes.robot(on, head, ink, ink)
	for eye: Vector2 in [Vector2(0.36, 0.52), Vector2(0.64, 0.52)]:
		var at := IconShapes.at(head, eye.x, eye.y)
		var reach := IconShapes.span(head, 0.08)
		var width := IconShapes.width(head)
		on.draw_line(at - Vector2(reach, reach), at + Vector2(reach, reach), paper, width, true)
		on.draw_line(at + Vector2(-reach, reach), at + Vector2(reach, -reach), paper, width, true)
	IconShapes.star(on, box, 0.86, 0.16, 0.1, ink)


## A heart that took its hits and lived: a plaster across it, and the bursts of the hits round it.
static func _patched_heart(
	on: CanvasItem, box: Rect2, ink: Color, faint: Color, paper: Color
) -> void:
	for burst: Vector3 in [
		Vector3(0.14, 0.24, 0.09), Vector3(0.86, 0.2, 0.08), Vector3(0.84, 0.82, 0.07)
	]:
		IconShapes.spiked(on, box, burst.x, burst.y, burst.z, 8, 0.45, faint)
	IconShapes.heart(on, box, 0.5, 0.54, 0.34, ink)
	_quad(on, box, Vector2(0.5, 0.5), Vector2(0.3, 0.075), -32.0, paper)
	_quad(on, box, Vector2(0.5, 0.5), Vector2(0.09, 0.075), -32.0, faint)
	for dot: Vector2 in [Vector2(-0.2, 0.0), Vector2(0.2, 0.0)]:
		var at := Vector2(0.5, 0.5) + dot.rotated(deg_to_rad(-32.0))
		IconShapes.disc(on, box, at.x, at.y, 0.018, faint)


## The Grand Prix's trophy, and a star under it for each of its maps.
static func _trophy(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	var bowl := [Vector2(0.26, 0.1)]
	for i: int in 9:
		var angle := PI * i / 8.0
		bowl.append(Vector2(0.5 - cos(angle) * 0.24, 0.1 + sin(angle) * 0.36))
	bowl.append(Vector2(0.74, 0.1))
	_poly(on, box, bowl, ink)
	IconShapes.arc(on, box, 0.24, 0.24, 0.1, 90.0, 270.0, ink)
	IconShapes.arc(on, box, 0.76, 0.24, 0.1, -90.0, 90.0, ink)
	IconShapes.bar(on, box, 0.46, 0.44, 0.08, 0.16, ink)
	IconShapes.bar(on, box, 0.32, 0.6, 0.36, 0.08, ink)
	for x: float in [0.3, 0.5, 0.7]:
		IconShapes.star(on, box, x, 0.84, 0.09, faint)


## The finish line, a strip of checks down the right.
static func _finish(on: CanvasItem, box: Rect2, ink: Color, paper: Color) -> void:
	IconShapes.bar(on, box, 0.72, 0.06, 0.12, 0.88, ink)
	for row: int in 8:
		var x := 0.72 if row % 2 == 0 else 0.78
		_quad(on, box, Vector2(x + 0.03, 0.115 + row * 0.11), Vector2(0.03, 0.055), 0.0, paper)


## The Junction with hazard tape across it: MATCH POINT on the pad.
static func _junction_taped(
	on: CanvasItem, box: Rect2, ink: Color, faint: Color, paper: Color
) -> void:
	IconShapes.disc(on, box, 0.5, 0.54, 0.38, faint)
	IconShapes.ring(on, box, 0.5, 0.54, 0.38, ink)
	IconShapes.ring(on, box, 0.5, 0.54, 0.25, ink)
	IconShapes.disc(on, box, 0.5, 0.54, 0.1, ink)
	# The tape, a band across the pad a little askew, striped as hazard tape is: the band in ink,
	# its stripes cut out of it slanting, each worked out along the band and across it.
	var middle := Vector2(0.5, 0.5)
	var turn := deg_to_rad(-14.0)
	var half := Vector2(0.52, 0.085)
	var along := Vector2.from_angle(turn)
	var across := along.orthogonal()
	var band := []
	for corner: Vector2 in [-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]:
		band.append(middle + along * corner.x + across * corner.y)
	_poly(on, box, band, ink)
	for i: int in range(-4, 5):
		var u := i * 0.13
		var stripe := []
		for corner: Vector2 in [
			Vector2(u - 0.02, -half.y * 0.7),
			Vector2(u + 0.04, -half.y * 0.7),
			Vector2(u + 0.0, half.y * 0.7),
			Vector2(u - 0.06, half.y * 0.7),
		]:
			var x := clampf(corner.x, -half.x + 0.03, half.x - 0.03)
			stripe.append(middle + along * x + across * corner.y)
		_poly(on, box, stripe, paper)


## The Jackpot's traffic light gone green, rays off its last lamp.
static func _traffic_light(
	on: CanvasItem, box: Rect2, ink: Color, faint: Color, paper: Color
) -> void:
	IconShapes.bar(on, box, 0.47, 0.72, 0.06, 0.22, faint)
	IconShapes.bar(on, box, 0.34, 0.08, 0.32, 0.66, ink)
	IconShapes.disc(on, box, 0.5, 0.2, 0.075, Color(paper, 0.35))
	IconShapes.disc(on, box, 0.5, 0.41, 0.075, Color(paper, 0.35))
	IconShapes.disc(on, box, 0.5, 0.62, 0.085, paper)
	for i: int in 5:
		var angle := deg_to_rad(-40.0 + i * 20.0)
		var from := Vector2(0.5, 0.62) + Vector2.from_angle(angle) * 0.24
		var to := Vector2(0.5, 0.62) + Vector2.from_angle(angle) * 0.36
		_line(on, box, [from, to], ink)


## A wanted poster with the bounty's crown on it.
static func _poster(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_rect(on, box, Rect2(0.18, 0.08, 0.64, 0.84), faint, ink)
	var crown := Rect2(box.position + box.size * Vector2(0.28, 0.18), box.size * Vector2(0.44, 0.4))
	IconShapes.crown(on, crown, ink)
	for y: float in [0.68, 0.78]:
		_line(on, box, [Vector2(0.3, y), Vector2(0.7, y)], ink)


## A warning sign, the Highway Code's: a triangle, cut out inside.
static func _warning(on: CanvasItem, box: Rect2, ink: Color, paper: Color) -> void:
	_poly(on, box, [Vector2(0.5, 0.06), Vector2(0.96, 0.9), Vector2(0.04, 0.9)], ink)
	_poly(on, box, [Vector2(0.5, 0.24), Vector2(0.81, 0.82), Vector2(0.19, 0.82)], paper)


## The whole deck squared up, its edges showing down one side and the ace of spades on top.
static func _deck_box(on: CanvasItem, box: Rect2, ink: Color, faint: Color, paper: Color) -> void:
	for i: int in range(5, 0, -1):
		var at := Vector2(0.24 + i * 0.025, 0.1 + i * 0.025)
		_rect(on, box, Rect2(at, Vector2(0.44, 0.66)), paper, faint)
	_rect(on, box, Rect2(0.24, 0.1, 0.44, 0.66), paper, ink)
	_spade(on, box, Vector2(0.46, 0.42), 0.15, ink)


## A spade, the heart turned over on a stem.
static func _spade(on: CanvasItem, box: Rect2, middle: Vector2, span: float, ink: Color) -> void:
	var side := IconShapes.span(box, span) * 2.0
	var corner := IconShapes.at(box, middle.x, middle.y) - Vector2(side, side) * 0.5
	var points := PackedVector2Array()
	for point: Vector2 in Heart.unit_shape():
		points.append(corner + Vector2(point.x, 1.0 - point.y) * side)
	on.draw_colored_polygon(points, ink)
	IconShapes.tri(on, box, middle.x, middle.y + span * 1.05, span * 1.1, 0.0, ink)


## A slot machine's three reels, each on a seven: the pull that won.
static func _sevens(on: CanvasItem, box: Rect2, ink: Color, paper: Color) -> void:
	for i: int in 3:
		var left := 0.08 + i * 0.29
		_rect(on, box, Rect2(left, 0.38, 0.26, 0.42), paper, ink)
		_line(on, box, [Vector2(left + 0.06, 0.48), Vector2(left + 0.2, 0.48)], ink, 1.4)
		_line(on, box, [Vector2(left + 0.2, 0.48), Vector2(left + 0.1, 0.72)], ink, 1.4)


## An open toy box with a shield, a bomb and a star coming out of it.
static func _toybox(on: CanvasItem, box: Rect2, ink: Color, faint: Color, paper: Color) -> void:
	IconShapes.bar(on, box, 0.2, 0.44, 0.6, 0.12, faint)
	IconShapes.shield(on, box, 0.34, 0.34, 0.12, ink)
	IconShapes.disc(on, box, 0.64, 0.36, 0.1, ink)
	_line(on, box, [Vector2(0.7, 0.28), Vector2(0.76, 0.18)], ink)
	IconShapes.star(on, box, 0.5, 0.14, 0.09, ink)
	IconShapes.bar(on, box, 0.14, 0.52, 0.72, 0.38, ink)
	IconShapes.bar(on, box, 0.14, 0.62, 0.72, 0.04, paper)


## A gamepad at [param middle]: its body and grips, a cross and two buttons cut into it.
static func _pad(on: CanvasItem, box: Rect2, middle: Vector2, ink: Color, paper: Color) -> void:
	IconShapes.bar(on, box, middle.x - 0.22, middle.y - 0.09, 0.44, 0.18, ink)
	IconShapes.disc(on, box, middle.x - 0.17, middle.y + 0.07, 0.085, ink)
	IconShapes.disc(on, box, middle.x + 0.17, middle.y + 0.07, 0.085, ink)
	_quad(on, box, middle + Vector2(-0.12, 0.0), Vector2(0.05, 0.016), 0.0, paper)
	_quad(on, box, middle + Vector2(-0.12, 0.0), Vector2(0.016, 0.05), 0.0, paper)
	IconShapes.disc(on, box, middle.x + 0.1, middle.y - 0.02, 0.022, paper)
	IconShapes.disc(on, box, middle.x + 0.15, middle.y + 0.03, 0.022, paper)


## A screen on its stand, at [param middle].
static func _screen(on: CanvasItem, box: Rect2, middle: Vector2, ink: Color, faint: Color) -> void:
	_rect(on, box, Rect2(middle.x - 0.15, middle.y - 0.11, 0.3, 0.2), faint, ink)
	IconShapes.bar(on, box, middle.x - 0.02, middle.y + 0.09, 0.04, 0.06, ink)
	IconShapes.bar(on, box, middle.x - 0.08, middle.y + 0.14, 0.16, 0.03, ink)


## Where along the line from one screen to the other [param t] is, bowed up between them.
static func _curve(t: float) -> Vector2:
	var straight := Vector2(0.3, 0.56).lerp(Vector2(0.7, 0.3), t)
	return straight + Vector2(0.0, -0.22 * sin(t * PI))


## A couch to watch from: its back, seat, arms and feet.
static func _couch(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	IconShapes.bar(on, box, 0.18, 0.42, 0.64, 0.2, ink)
	IconShapes.bar(on, box, 0.14, 0.6, 0.72, 0.16, ink)
	IconShapes.bar(on, box, 0.06, 0.5, 0.14, 0.3, ink)
	IconShapes.bar(on, box, 0.8, 0.5, 0.14, 0.3, ink)
	IconShapes.bar(on, box, 0.16, 0.8, 0.06, 0.08, faint)
	IconShapes.bar(on, box, 0.78, 0.8, 0.06, 0.08, faint)


## A signpost with two arrows, the way to every street.
static func _signpost(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	IconShapes.bar(on, box, 0.46, 0.12, 0.08, 0.8, faint)
	_poly(
		on,
		box,
		[
			Vector2(0.4, 0.16),
			Vector2(0.8, 0.16),
			Vector2(0.92, 0.27),
			Vector2(0.8, 0.38),
			Vector2(0.4, 0.38)
		],
		ink
	)
	_poly(
		on,
		box,
		[
			Vector2(0.6, 0.46),
			Vector2(0.2, 0.46),
			Vector2(0.08, 0.57),
			Vector2(0.2, 0.68),
			Vector2(0.6, 0.68)
		],
		ink
	)
	IconShapes.bar(on, box, 0.34, 0.88, 0.32, 0.06, ink)


## The loyalty program's card, its chip on its face and a star of the best member.
static func _member_card(on: CanvasItem, box: Rect2, ink: Color, paper: Color) -> void:
	IconShapes.bar(on, box, 0.08, 0.22, 0.84, 0.56, ink)
	IconShapes.disc(on, box, 0.3, 0.56, 0.12, paper)
	IconShapes.ring(on, box, 0.3, 0.56, 0.07, ink)
	for i: int in 4:
		IconShapes.bar(on, box, 0.5 + i * 0.09, 0.62, 0.06, 0.04, paper)
	IconShapes.star(on, box, 0.76, 0.36, 0.1, paper)


## The roundabout round its pot: the ring, arrows going round it, and the chip in its middle.
static func _roundabout(on: CanvasItem, box: Rect2, ink: Color, faint: Color, paper: Color) -> void:
	var middle := IconShapes.at(box, 0.5, 0.5)
	# The roads in first, then the ring of road over their ends, a dashed line round its middle and
	# arrows the way it goes, and the pot on its island.
	for i: int in 4:
		var toward := Vector2.from_angle(TAU * i / 4.0 + PI * 0.25)
		var from := Vector2(0.5, 0.5) + toward * 0.3
		_line(on, box, [from, from + toward * 0.2], faint, 2.6)
	on.draw_arc(
		middle, IconShapes.span(box, 0.31), 0.0, TAU, 64, ink, IconShapes.span(box, 0.15), true
	)
	for i: int in 12:
		var from := TAU * i / 12.0
		on.draw_arc(
			middle,
			IconShapes.span(box, 0.31),
			from,
			from + 0.22,
			6,
			paper,
			IconShapes.width(box) * 0.5,
			true
		)
	for i: int in 3:
		var angle := TAU * i / 3.0
		var at := Vector2(0.5, 0.5) + Vector2.from_angle(angle) * 0.31
		IconShapes.tri(on, box, at.x, at.y, 0.1, rad_to_deg(angle) + 180.0, paper)
	IconShapes.disc(on, box, 0.5, 0.5, 0.15, ink)
	IconShapes.ring(on, box, 0.5, 0.5, 0.09, paper)


## The eye drawn on Kit's folder and crossed out.
static func _eye_crossed(on: CanvasItem, box: Rect2, ink: Color, paper: Color) -> void:
	var outline := []
	for i: int in 17:
		var t := i / 16.0
		outline.append(Vector2(0.1 + t * 0.8, 0.5 - sin(t * PI) * 0.24))
	for i: int in 17:
		var t := 1.0 - i / 16.0
		outline.append(Vector2(0.1 + t * 0.8, 0.5 + sin(t * PI) * 0.24))
	_poly(on, box, outline, ink)
	IconShapes.disc(on, box, 0.5, 0.5, 0.15, paper)
	IconShapes.disc(on, box, 0.5, 0.5, 0.08, ink)
	_line(on, box, [Vector2(0.14, 0.86), Vector2(0.86, 0.14)], paper, 2.6)
	_line(on, box, [Vector2(0.14, 0.86), Vector2(0.86, 0.14)], ink, 1.3)


## A page torn off along its perforation: the line of holes it hung from, and the page below it
## leaning away and falling, its blank line where STATUS was never stamped.
static func _torn_off(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	for i: int in 7:
		IconShapes.disc(on, box, 0.14 + 0.12 * float(i), 0.24, 0.025, ink)
	var page := [Vector2(0.2, 0.36), Vector2(0.84, 0.46), Vector2(0.74, 0.9), Vector2(0.12, 0.8)]
	_poly(on, box, page, faint)
	_line(on, box, page + [page[0]], ink)
	_line(on, box, [Vector2(0.3, 0.6), Vector2(0.66, 0.66)], ink, 1.4)
	_line(on, box, [Vector2(0.86, 0.3), Vector2(0.92, 0.38)], ink)


## The House's stamp as it came down on the evaluation: two rings and APPROVED across them.
static func _approved(on: CanvasItem, box: Rect2, ink: Color, paper: Color) -> void:
	IconShapes.ring(on, box, 0.5, 0.5, 0.42, ink)
	IconShapes.ring(on, box, 0.5, 0.5, 0.33, ink)
	IconShapes.bar(on, box, 0.02, 0.4, 0.96, 0.2, ink)
	var font := Type.display_font()
	var size := maxi(roundi(IconShapes.span(box, 0.17)), 6)
	var word := "APPROVED"
	var wide := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var middle := IconShapes.at(box, 0.5, 0.5)
	on.draw_string(
		font,
		Vector2(middle.x - wide * 0.5, middle.y + size * Type.CAP_HEIGHT * 0.5),
		word,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		paper
	)
	IconShapes.star(on, box, 0.5, 0.25, 0.07, ink)
	IconShapes.star(on, box, 0.5, 0.75, 0.07, ink)


## The frame After Hours hangs the Operator's kart in.
static func _frame(on: CanvasItem, box: Rect2, ink: Color, faint: Color, paper: Color) -> void:
	IconShapes.bar(on, box, 0.14, 0.14, 0.72, 0.64, ink)
	IconShapes.bar(on, box, 0.22, 0.22, 0.56, 0.48, paper)
	IconShapes.bar(on, box, 0.22, 0.22, 0.56, 0.48, faint)
	_kart(on, box, Vector2(0.5, 0.5), 1.15, 0.0, ink, paper)
	IconShapes.bar(on, box, 0.32, 0.84, 0.36, 0.08, ink)


## The page of the House's calendar, turned over at last, its first day ringed in pencil.
static func _calendar(on: CanvasItem, box: Rect2, ink: Color, faint: Color, paper: Color) -> void:
	_rect(on, box, Rect2(0.14, 0.2, 0.72, 0.68), faint, ink)
	IconShapes.bar(on, box, 0.14, 0.2, 0.72, 0.16, ink)
	for x: float in [0.32, 0.68]:
		IconShapes.ring(on, box, x, 0.2, 0.06, ink)
		IconShapes.disc(on, box, x, 0.27, 0.025, paper)
	for row: int in 3:
		for column: int in 4:
			var at := Vector2(0.22 + column * 0.16, 0.44 + row * 0.14)
			IconShapes.bar(on, box, at.x, at.y, 0.1, 0.08, faint)
	IconShapes.ring(on, box, 0.27, 0.48, 0.09, ink)


## Every id this knows a picture for, so a test can hold the set to the list.
static func known() -> Array[StringName]:
	var ids: Array[StringName] = [
		&"street_legal",
		&"honor_roll",
		&"flawless",
		&"beat_the_house",
		&"clean_sweep",
		&"last_kart_standing",
		&"all_in",
		&"by_a_nose",
		&"buzzer_beater",
		&"winner_takes_all",
		&"partners_in_crime",
		&"push_your_luck",
		&"point_of_sale",
		&"hit_the_jackpot",
		&"most_wanted",
		&"snatch_and_grab",
		&"full_house",
		&"let_it_ride",
		&"suit_yourself",
		&"bank_shot",
		&"parry",
		&"long_shot",
		&"payback",
		&"untouchable",
		&"tough_as_nails",
		&"two_birds",
		&"set_and_forget",
		&"road_hog",
		&"slick_operator",
		&"dead_ringer",
		&"long_way_round",
		&"push_comes_to_shove",
		&"a_pit_do_not",
		&"property_damage",
		&"a_real_handful",
		&"stacked",
		&"asking_for_trouble",
		&"full_deck",
		&"toybox",
		&"plus_one",
		&"long_distance",
		&"full_table",
		&"front_row",
		&"dressed_to_the_nines",
		&"know_every_street",
		&"most_valued_member",
		&"lap_of_luxury",
		&"off_the_books",
		&"terms_accepted",
		&"not_this_time",
		&"employee_of_the_month",
		&"a_fresh_start",
	]
	return ids
