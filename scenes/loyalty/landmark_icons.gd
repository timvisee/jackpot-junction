class_name LandmarkIcons
extends RefCounted
## Each landmark's own picture, GAME.md 8.9: what the place is, on its sign on the map and on its
## row of the list, so no two of the map's signs look alike. The pane says what it pays with the
## picture of that, see [method LoyaltyArt.draw_reward].
##
## Drawn the way every icon in the game is, see [IconShapes]: in a box, every measure a fraction
## of it, in one ink and the fainter of it, so a picture serves a sign's gold, white or pencil as
## it serves the list's.


## The picture of [param landmark] into [param box] on [param on] in [param ink]; what it pays for
## a landmark with no picture of its own.
static func draw_into(on: CanvasItem, box: Rect2, landmark: LoyaltyLandmark, ink: Color) -> void:
	var faint := IconShapes.behind(ink)
	match landmark.id:
		&"slip_road":
			_merge(on, box, ink)
		&"dealers_visor":
			_cage(on, box, ink, faint)
		&"rare_cards":
			for i: int in 3:
				_card(on, box, Vector2(0.5, 0.86), -24.0 + i * 24.0, ink if i == 2 else faint, ink)
			IconShapes.disc(on, box, 0.62, 0.36, 0.06, ink)
		&"chip_trail":
			for chip: Vector3 in [
				Vector3(0.24, 0.76, 0.17), Vector3(0.5, 0.5, 0.14), Vector3(0.74, 0.27, 0.11)
			]:
				_chip(on, box, chip, ink, faint)
		&"card_suits":
			_diamond(on, box, ink, faint)
		&"ace_of_spades":
			for i: int in 5:
				var card := Rect2(0.1 + i * 0.12, 0.42 - i * 0.07, 0.3, 0.44)
				_box(on, box, card, faint if i < 4 else ink, ink)
			IconShapes.tri(on, box, 0.73, 0.3, 0.16, 0.0, ink)
		&"cursed_cards":
			_glass(on, box, ink, faint)
		&"spread_and_swivel":
			_gift(on, box, ink, faint)
		&"fedora":
			_slots(on, box, ink, faint)
		&"decoy_and_wipe":
			_poster(on, box, ink, faint)
		&"gilt_back":
			_bell(on, box, ink, faint)
		&"more_rare_cards":
			_card(on, box, Vector2(0.38, 0.84), -28.0, faint, ink)
			_card(on, box, Vector2(0.62, 0.84), 28.0, ink, ink)
			IconShapes.arc(on, box, 0.5, 0.5, 0.42, 200.0, 340.0, ink)
			IconShapes.tri(on, box, 0.86, 0.38, 0.14, 150.0, ink)
		&"high_stakes":
			_bag(on, box, ink, faint)
		&"wages":
			_laurel(on, box, ink)
		&"services":
			IconShapes.ring(on, box, 0.5, 0.3, 0.15, ink)
			IconShapes.ring(on, box, 0.5, 0.66, 0.2, ink)
			_line(on, box, [Vector2(0.38, 0.47), Vector2(0.62, 0.47)], faint)
		&"card_shark":
			_chandelier(on, box, ink, faint)
		&"racing_stripes":
			_milestone(on, box, ink, faint)
		&"chalk_marks":
			for side: float in [-0.07, 0.07]:
				var swirl := PackedVector2Array()
				for i: int in 30:
					var turn := i * 0.24
					var reach := 0.42 - i * 0.011 + side
					swirl.append(Vector2(0.5, 0.5) + Vector2.from_angle(turn + 2.4) * reach)
				_line(on, box, Array(swirl), ink)
		&"flames":
			_bend(on, box, ink, faint)
		&"windsock":
			for i: int in 3:
				var x := 0.18 + i * 0.22
				_line(
					on,
					box,
					[Vector2(x, 0.2), Vector2(x + 0.2, 0.5), Vector2(x, 0.8)],
					ink if i == 2 else faint,
					2.0
				)
		&"afterburn":
			_pump(on, box, ink, faint)
		&"clean_record":
			_box(on, box, Rect2(0.2, 0.08, 0.6, 0.86), faint, ink)
			for y: float in [0.36, 0.64]:
				_line(on, box, [Vector2(0.2, y), Vector2(0.8, y)], ink)
			for y: float in [0.22, 0.5, 0.78]:
				_line(on, box, [Vector2(0.42, y), Vector2(0.58, y)], ink, 1.6)
		&"marksman":
			IconShapes.ring(on, box, 0.5, 0.5, 0.42, ink)
			IconShapes.ring(on, box, 0.5, 0.5, 0.28, faint)
			IconShapes.ring(on, box, 0.5, 0.5, 0.15, ink)
			IconShapes.disc(on, box, 0.5, 0.5, 0.06, ink)
		&"horns":
			_wrench(on, box, ink, faint)
		&"lost_cone":
			_poly(
				on,
				box,
				[Vector2(0.3, 0.8), Vector2(0.45, 0.14), Vector2(0.55, 0.14), Vector2(0.7, 0.8)],
				ink
			)
			_line(on, box, [Vector2(0.35, 0.56), Vector2(0.65, 0.56)], faint, 2.2)
			IconShapes.bar(on, box, 0.18, 0.8, 0.64, 0.1, ink)
		&"lost_hard_hat":
			var dome := [Vector2(0.18, 0.66)]
			for i: int in 13:
				dome.append(
					Vector2(0.5, 0.66) + Vector2.from_angle(PI + PI * i / 12.0) * Vector2(0.32, 0.4)
				)
			_poly(on, box, dome, ink)
			IconShapes.bar(on, box, 0.08, 0.64, 0.84, 0.12, ink)
			_line(on, box, [Vector2(0.5, 0.3), Vector2(0.5, 0.62)], faint, 2.0)
		&"lost_tape":
			_box(on, box, Rect2(0.12, 0.2, 0.52, 0.52), faint, ink)
			IconShapes.ring(on, box, 0.38, 0.46, 0.1, ink)
			IconShapes.bar(on, box, 0.56, 0.62, 0.36, 0.1, ink)
			for x: float in [0.68, 0.78, 0.88]:
				_line(on, box, [Vector2(x, 0.62), Vector2(x, 0.56)], ink, 1.0)
		&"lost_dice":
			_box(on, box, Rect2(0.16, 0.16, 0.68, 0.68), faint, ink)
			for pip: Vector2 in [
				Vector2(0.33, 0.33),
				Vector2(0.5, 0.5),
				Vector2(0.67, 0.67),
				Vector2(0.67, 0.33),
				Vector2(0.33, 0.67)
			]:
				IconShapes.disc(on, box, pip.x, pip.y, 0.065, ink)
		&"dashed_marks":
			_line(on, box, [Vector2(0.1, 0.9), Vector2(0.44, 0.12)], ink)
			_line(on, box, [Vector2(0.9, 0.9), Vector2(0.56, 0.12)], ink)
			for dash: Vector3 in [
				Vector3(0.84, 0.66, 0.12), Vector3(0.56, 0.42, 0.08), Vector3(0.34, 0.26, 0.05)
			]:
				_line(on, box, [Vector2(0.5, dash.x), Vector2(0.5, dash.x - dash.z)], ink)
			_line(on, box, [Vector2(0.3, 0.12), Vector2(0.7, 0.12)], faint)
		&"showroom":
			LoyaltyArt.roller_door(on, box, ink)
		&"pencil_trail":
			_pencil(on, box, ink, faint)
		&"patchwork":
			_line(on, box, [Vector2(0.26, 0.2), Vector2(0.74, 0.2), Vector2(0.42, 0.86)], ink, 2.0)
			_line(on, box, [Vector2(0.38, 0.52), Vector2(0.66, 0.52)], ink)
			IconShapes.ring(on, box, 0.5, 0.52, 0.45, faint)
		&"kits_rag":
			_box(on, box, Rect2(0.24, 0.12, 0.52, 0.76), Color(ink, 0.0), ink)
			_line(on, box, [Vector2(0.12, 0.22), Vector2(0.88, 0.8)], ink, 1.6)
			_line(on, box, [Vector2(0.88, 0.22), Vector2(0.12, 0.8)], ink, 1.6)
		&"torn_up":
			_torn(on, box, ink, faint)
		&"welding_goggles":
			_line(
				on,
				box,
				[Vector2(0.2, 0.42), Vector2(0.2, 0.86), Vector2(0.8, 0.86), Vector2(0.8, 0.42)],
				ink
			)
			_line(on, box, [Vector2(0.2, 0.42), Vector2(0.06, 0.24)], ink)
			_line(on, box, [Vector2(0.8, 0.42), Vector2(0.94, 0.24)], ink)
			_line(on, box, [Vector2(0.2, 0.42), Vector2(0.8, 0.42)], faint)
		&"paper_hat":
			_moon(on, box, ink, faint)
		&"walk_away":
			_step(on, box, Vector2(0.34, 0.64), -0.2, ink)
			_step(on, box, Vector2(0.64, 0.38), 0.15, ink)
		&"left_on_the_floor":
			_card(on, box, Vector2(0.5, 0.72), 68.0, faint, ink)
			_line(on, box, [Vector2(0.06, 0.78), Vector2(0.94, 0.78)], ink)
			for x: float in [0.16, 0.36, 0.56, 0.76]:
				_line(on, box, [Vector2(x, 0.8), Vector2(x - 0.08, 0.92)], faint, 1.0)
		&"no_strings":
			_scissors(on, box, ink, faint)
		&"house_money":
			IconShapes.ring(on, box, 0.5, 0.5, 0.42, ink)
			_poly(on, box, [Vector2(0.3, 0.5), Vector2(0.5, 0.28), Vector2(0.7, 0.5)], ink)
			IconShapes.bar(on, box, 0.36, 0.5, 0.28, 0.22, ink)
		&"back_roads":
			for side: float in [-0.08, 0.08]:
				var road := PackedVector2Array()
				for i: int in 21:
					var t := i / 20.0
					road.append(Vector2(0.5 + sin(t * TAU * 1.1) * 0.26 + side, 0.92 - t * 0.84))
				_line(on, box, Array(road), ink)
		_:
			LoyaltyArt.draw_reward(on, box, landmark, ink)


## A line through [param points] of [param box], [param thick] strokes wide.
static func _line(on: CanvasItem, box: Rect2, points: Array, ink: Color, thick := 1.0) -> void:
	var line := PackedVector2Array()
	for point: Vector2 in points:
		line.append(IconShapes.at(box, point.x, point.y))
	on.draw_polyline(line, ink, IconShapes.width(box) * thick, true)


## A shape of [param points] of [param box], filled.
static func _poly(on: CanvasItem, box: Rect2, points: Array, ink: Color) -> void:
	var shape := PackedVector2Array()
	for point: Vector2 in points:
		shape.append(IconShapes.at(box, point.x, point.y))
	on.draw_colored_polygon(shape, ink)


## [param rect] of [param box] filled in [param fill] and edged in [param ink].
static func _box(on: CanvasItem, box: Rect2, rect: Rect2, fill: Color, ink: Color) -> void:
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


## A playing card standing on [param foot] of [param box], leant [param lean] degrees.
static func _card(
	on: CanvasItem, box: Rect2, foot: Vector2, lean: float, fill: Color, ink: Color
) -> void:
	var corners := []
	for corner: Vector2 in [
		Vector2(-0.17, 0.0), Vector2(-0.17, -0.58), Vector2(0.17, -0.58), Vector2(0.17, 0.0)
	]:
		corners.append(foot + corner.rotated(deg_to_rad(lean)))
	_poly(on, box, corners, fill)
	corners.append(corners[0])
	_line(on, box, corners, ink)


## The slip road's motorway arrow: the road straight on with its head, and the slip road curving
## up onto it from the side.
static func _merge(on: CanvasItem, box: Rect2, ink: Color) -> void:
	_line(on, box, [Vector2(0.62, 0.92), Vector2(0.62, 0.24)], ink, 2.2)
	IconShapes.tri(on, box, 0.62, 0.2, 0.34, 0.0, ink)
	var slip := []
	for i: int in 9:
		var t := i / 8.0
		slip.append(Vector2(lerpf(0.22, 0.6, t), 0.92 - sin(t * PI * 0.5) * 0.46))
	_line(on, box, slip, ink, 1.6)


## The Cashier's Cage: a teller's window barred, its counter and the slot under the bars.
static func _cage(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_box(on, box, Rect2(0.14, 0.1, 0.72, 0.62), faint, ink)
	for x: float in [0.32, 0.5, 0.68]:
		_line(on, box, [Vector2(x, 0.1), Vector2(x, 0.62)], ink)
	IconShapes.arc(on, box, 0.5, 0.72, 0.12, 180.0, 360.0, ink)
	IconShapes.bar(on, box, 0.04, 0.74, 0.92, 0.12, ink)


## Chip Alley's chip, [param chip] its middle and how far round: a disc with a ring cut in it.
static func _chip(on: CanvasItem, box: Rect2, chip: Vector3, ink: Color, faint: Color) -> void:
	IconShapes.disc(on, box, chip.x, chip.y, chip.z, ink)
	IconShapes.disc(on, box, chip.x, chip.y, chip.z * 0.62, faint)
	IconShapes.ring(on, box, chip.x, chip.y, chip.z * 0.62, ink)


## The High Limit Room's stake: a cut diamond, its table, crown and the facets down to its point.
static func _diamond(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	var gem := [
		Vector2(0.3, 0.16),
		Vector2(0.7, 0.16),
		Vector2(0.92, 0.38),
		Vector2(0.5, 0.9),
		Vector2(0.08, 0.38)
	]
	_poly(on, box, gem, faint)
	gem.append(gem[0])
	_line(on, box, gem, ink)
	_line(on, box, [Vector2(0.08, 0.38), Vector2(0.92, 0.38)], ink)
	_line(on, box, [Vector2(0.3, 0.16), Vector2(0.4, 0.38), Vector2(0.5, 0.9)], ink, 0.8)
	_line(on, box, [Vector2(0.7, 0.16), Vector2(0.6, 0.38), Vector2(0.5, 0.9)], ink, 0.8)
	_line(on, box, [Vector2(0.4, 0.38), Vector2(0.5, 0.16), Vector2(0.6, 0.38)], ink, 0.8)


## The Ten Times Bar's glass: a cocktail glass with an olive in it.
static func _glass(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_poly(on, box, [Vector2(0.14, 0.14), Vector2(0.86, 0.14), Vector2(0.5, 0.52)], faint)
	_line(
		on,
		box,
		[Vector2(0.14, 0.14), Vector2(0.86, 0.14), Vector2(0.5, 0.52), Vector2(0.14, 0.14)],
		ink
	)
	_line(on, box, [Vector2(0.5, 0.52), Vector2(0.5, 0.84)], ink)
	_line(on, box, [Vector2(0.28, 0.86), Vector2(0.72, 0.86)], ink, 1.6)
	IconShapes.disc(on, box, 0.58, 0.24, 0.07, ink)
	_line(on, box, [Vector2(0.58, 0.24), Vector2(0.74, 0.04)], ink)


## The Prize Counter's prize: a box tied with a ribbon and its bow.
static func _gift(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_box(on, box, Rect2(0.18, 0.44, 0.64, 0.46), faint, ink)
	IconShapes.bar(on, box, 0.12, 0.32, 0.76, 0.13, ink)
	_line(on, box, [Vector2(0.5, 0.45), Vector2(0.5, 0.9)], ink, 1.6)
	IconShapes.ring(on, box, 0.38, 0.22, 0.1, ink)
	IconShapes.ring(on, box, 0.62, 0.22, 0.1, ink)


## Jackpot Plaza's slot machine: its cabinet, three reels behind its glass and its lever.
static func _slots(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_box(on, box, Rect2(0.1, 0.14, 0.62, 0.76), faint, ink)
	for x: float in [0.17, 0.33, 0.49]:
		_box(on, box, Rect2(x, 0.3, 0.14, 0.24), ink, ink)
	IconShapes.bar(on, box, 0.16, 0.66, 0.5, 0.08, ink)
	_line(on, box, [Vector2(0.72, 0.62), Vector2(0.86, 0.62), Vector2(0.86, 0.22)], ink)
	IconShapes.disc(on, box, 0.86, 0.18, 0.07, ink)


## The Bounty Board's notice: a poster pinned up, a face on it and the words under it.
static func _poster(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_box(on, box, Rect2(0.2, 0.1, 0.6, 0.82), faint, ink)
	IconShapes.disc(on, box, 0.5, 0.36, 0.12, ink)
	IconShapes.arc(on, box, 0.5, 0.66, 0.2, 200.0, 340.0, ink)
	for y: float in [0.7, 0.8]:
		_line(on, box, [Vector2(0.32, y), Vector2(0.68, y)], ink, 0.8)
	IconShapes.disc(on, box, 0.5, 0.1, 0.06, ink)


## The Last Call Bar's bell, ringing.
static func _bell(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	var bell := [Vector2(0.2, 0.74)]
	for i: int in 9:
		var t := i / 8.0
		bell.append(Vector2(lerpf(0.26, 0.74, t), 0.74 - sin(t * PI) * 0.5 - 0.06))
	bell.append(Vector2(0.8, 0.74))
	_poly(on, box, bell, ink)
	IconShapes.disc(on, box, 0.5, 0.82, 0.07, ink)
	IconShapes.disc(on, box, 0.5, 0.14, 0.05, ink)
	for side: float in [-1.0, 1.0]:
		var x := 0.5 + side * 0.4
		_line(on, box, [Vector2(x, 0.28), Vector2(x + side * 0.06, 0.2)], faint, 1.4)
		_line(on, box, [Vector2(x + side * 0.02, 0.46), Vector2(x + side * 0.1, 0.44)], faint, 1.4)


## The Counting Room's money: a bag tied at its neck and a stack of coins beside it.
static func _bag(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	IconShapes.disc(on, box, 0.4, 0.62, 0.3, ink)
	_poly(
		on,
		box,
		[Vector2(0.3, 0.36), Vector2(0.24, 0.16), Vector2(0.56, 0.16), Vector2(0.5, 0.36)],
		ink
	)
	_line(on, box, [Vector2(0.26, 0.36), Vector2(0.54, 0.36)], faint, 1.4)
	for i: int in 3:
		IconShapes.bar(on, box, 0.68, 0.8 - i * 0.1, 0.26, 0.08, ink if i % 2 == 0 else faint)


## The Winners' Circle's laurels: two boughs of leaves curving up round an open middle.
static func _laurel(on: CanvasItem, box: Rect2, ink: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var stem := []
		for i: int in 9:
			var angle := deg_to_rad(100.0 + i * 15.0)
			var at := Vector2(0.5 + side * cos(angle) * -0.36, 0.52 + sin(angle) * 0.36)
			stem.append(at)
			if i % 2 == 1:
				var leaf := Vector2(side * 0.08, -0.06).rotated(-side * i * 0.18)
				_poly(
					on,
					box,
					[
						at,
						at + leaf + leaf.orthogonal() * 0.4,
						at + leaf * 1.9,
						at + leaf - leaf.orthogonal() * 0.4
					],
					ink
				)
		_line(on, box, stem, ink)
	IconShapes.star(on, box, 0.5, 0.44, 0.16, ink)


## The Grand Salon's chandelier: hung from its chain, its arms curving up with a light on each and
## the drops under them.
static func _chandelier(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_line(on, box, [Vector2(0.5, 0.04), Vector2(0.5, 0.42)], ink)
	IconShapes.arc(on, box, 0.5, 0.3, 0.36, 20.0, 160.0, ink)
	for x: float in [0.16, 0.38, 0.62, 0.84]:
		var top := 0.42 if x in [0.16, 0.84] else 0.62
		IconShapes.bar(on, box, x - 0.04, top - 0.14, 0.08, 0.14, ink)
		IconShapes.disc(on, box, x, top - 0.2, 0.04, faint)
	for x: float in [0.27, 0.5, 0.73]:
		IconShapes.disc(on, box, x, 0.8, 0.05, ink)
	IconShapes.disc(on, box, 0.5, 0.6, 0.08, ink)


## Milestone 10's stone: a slab with a round top and a band across it, its count on it.
static func _milestone(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	var stone := [Vector2(0.24, 0.9), Vector2(0.24, 0.38)]
	for i: int in 9:
		stone.append(Vector2(0.5, 0.38) + Vector2.from_angle(PI + PI * i / 8.0) * 0.26)
	stone.append(Vector2(0.76, 0.9))
	_poly(on, box, stone, faint)
	stone.append(stone[0])
	_line(on, box, stone, ink)
	_line(on, box, [Vector2(0.38, 0.4), Vector2(0.38, 0.64)], ink, 1.6)
	IconShapes.ring(on, box, 0.58, 0.52, 0.09, ink)
	_line(on, box, [Vector2(0.1, 0.9), Vector2(0.9, 0.9)], ink)


## Boost Bend's sign: the road bending away under an arrow, and the rush of air after it.
static func _bend(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	var bend := []
	for i: int in 11:
		var t := i / 10.0
		bend.append(
			Vector2(0.3 + sin(t * PI * 0.5) * 0.36, 0.9 - (1.0 - cos(t * PI * 0.5)) * 0.1 - t * 0.6)
		)
	_line(on, box, bend, ink, 2.2)
	IconShapes.tri(on, box, 0.68, 0.18, 0.3, 20.0, ink)
	for y: float in [0.46, 0.62, 0.78]:
		_line(on, box, [Vector2(0.06, y), Vector2(0.2, y)], faint, 1.4)


## The Nitro Pumps' pump: its body and dial, the hose and the nozzle on its side.
static func _pump(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_box(on, box, Rect2(0.14, 0.12, 0.44, 0.78), faint, ink)
	_box(on, box, Rect2(0.22, 0.22, 0.28, 0.18), ink, ink)
	IconShapes.bar(on, box, 0.08, 0.86, 0.56, 0.08, ink)
	_line(
		on,
		box,
		[Vector2(0.58, 0.3), Vector2(0.78, 0.3), Vector2(0.84, 0.44), Vector2(0.84, 0.72)],
		ink
	)
	_line(on, box, [Vector2(0.8, 0.72), Vector2(0.9, 0.72)], ink, 1.8)


## The Body Shop's wrench, its jaws open at the top and the ring at its foot.
static func _wrench(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_line(on, box, [Vector2(0.26, 0.76), Vector2(0.66, 0.34)], ink, 2.6)
	IconShapes.ring(on, box, 0.24, 0.78, 0.12, ink)
	IconShapes.disc(on, box, 0.72, 0.28, 0.17, ink)
	IconShapes.disc(on, box, 0.8, 0.2, 0.09, faint)
	_line(on, box, [Vector2(0.76, 0.24), Vector2(0.9, 0.1)], ink, 2.0)


## A pencil, lying across: its sharpened point and the eraser at its other end.
static func _pencil(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	_line(on, box, [Vector2(0.28, 0.72), Vector2(0.72, 0.28)], ink, 3.4)
	_poly(on, box, [Vector2(0.18, 0.66), Vector2(0.34, 0.82), Vector2(0.1, 0.9)], ink)
	_line(on, box, [Vector2(0.74, 0.26), Vector2(0.86, 0.14)], faint, 3.4)
	_line(on, box, [Vector2(0.22, 0.86), Vector2(0.06, 0.94)], ink)


## A sheet torn in two, the halves a little apart along the tear.
static func _torn(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	var tear := [
		Vector2(0.5, 0.1),
		Vector2(0.44, 0.26),
		Vector2(0.54, 0.42),
		Vector2(0.44, 0.6),
		Vector2(0.52, 0.76),
		Vector2(0.46, 0.9)
	]
	var left := [Vector2(0.12, 0.1)]
	var right := [Vector2(0.9, 0.12)]
	for point: Vector2 in tear:
		left.append(point - Vector2(0.05, 0.0))
	for point: Vector2 in tear:
		right.append(point + Vector2(0.06, 0.03))
	left.append(Vector2(0.12, 0.9))
	right.append(Vector2(0.9, 0.93))
	_poly(on, box, left, faint)
	_poly(on, box, right, faint)
	left.append(left[0])
	right.append(right[0])
	_line(on, box, left, ink)
	_line(on, box, right, ink)


## Quiet hours: a crescent moon and the z of somebody asleep. The moon is the left of one circle
## with the left of another taken out of it, the two meeting at its horns.
static func _moon(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	var outer := Vector2(0.44, 0.54)
	var reach := 0.36
	var horn := deg_to_rad(60.0)
	var inner := outer + Vector2(0.22, 0.0)
	var top := outer + Vector2.from_angle(-horn) * reach
	var inner_reach := top.distance_to(inner)
	var from := (outer + Vector2.from_angle(horn) * reach - inner).angle()
	var to := (top - inner).angle() + TAU
	var moon := []
	for i: int in 13:
		moon.append(outer + Vector2.from_angle(lerpf(horn, TAU - horn, i / 12.0)) * reach)
	for i: int in 13:
		moon.append(inner + Vector2.from_angle(lerpf(to, from, i / 12.0)) * inner_reach)
	_poly(on, box, moon, ink)
	var z := [Vector2(0.68, 0.1), Vector2(0.88, 0.1), Vector2(0.68, 0.3), Vector2(0.88, 0.3)]
	_line(on, box, z, faint, 1.4)


## A shoe's print at [param at] of [param box], turned [param turn]: its sole and its heel.
static func _step(on: CanvasItem, box: Rect2, at: Vector2, turn: float, ink: Color) -> void:
	var sole := []
	for i: int in 12:
		sole.append(at + (Vector2.from_angle(TAU * i / 12.0) * Vector2(0.1, 0.15)).rotated(turn))
	_poly(on, box, sole, ink)
	var heel := []
	for i: int in 10:
		heel.append(
			(
				at
				+ (
					(Vector2(0.0, 0.26) + Vector2.from_angle(TAU * i / 10.0) * Vector2(0.08, 0.07))
					. rotated(turn)
				)
			)
		)
	_poly(on, box, heel, ink)


## Scissors, open, a string cut short between their blades.
static func _scissors(on: CanvasItem, box: Rect2, ink: Color, faint: Color) -> void:
	IconShapes.ring(on, box, 0.24, 0.72, 0.12, ink)
	IconShapes.ring(on, box, 0.44, 0.84, 0.12, ink)
	_line(on, box, [Vector2(0.3, 0.62), Vector2(0.84, 0.14)], ink, 1.6)
	_line(on, box, [Vector2(0.5, 0.74), Vector2(0.9, 0.3)], ink, 1.6)
	_line(on, box, [Vector2(0.62, 0.04), Vector2(0.7, 0.2)], faint, 1.2)
	_line(on, box, [Vector2(0.94, 0.4), Vector2(0.98, 0.56)], faint, 1.2)
