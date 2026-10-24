class_name KitArt
extends RefCounted
## The pictures on Kit's cards, STORY.md 6.3: drawn over the House's in pencil, as strokes rather
## than the House's flat shapes, each gone over twice a hair apart, the way a pencil is. Skid marks
## into a stop line for Brake Check, one of the House's cards crossed out for Not Today, a sight
## aimed beside the kart for Blind Spot, chips left lying for Loose Change, and a stack of them
## under a table for Under the Table.

## How far apart the two goes over a stroke are, as a share of the picture.
const AGAIN := 0.012


static func draw_into(on: CanvasItem, box: Rect2, id: StringName, ink: Color) -> void:
	match id:
		&"brake_check":
			for x: float in [0.36, 0.6]:
				_stroke(
					on,
					box,
					[
						Vector2(x, 0.08),
						Vector2(x - 0.03, 0.3),
						Vector2(x + 0.02, 0.5),
						Vector2(x - 0.01, 0.68)
					],
					ink
				)
			_stroke(on, box, [Vector2(0.14, 0.78), Vector2(0.86, 0.76)], ink, 2.4)
		&"not_today":
			_stroke(
				on,
				box,
				[
					Vector2(0.28, 0.14),
					Vector2(0.72, 0.15),
					Vector2(0.71, 0.86),
					Vector2(0.29, 0.85),
					Vector2(0.28, 0.14)
				],
				ink
			)
			_stroke(on, box, [Vector2(0.18, 0.24), Vector2(0.82, 0.78)], ink, 1.6)
			_stroke(on, box, [Vector2(0.8, 0.22), Vector2(0.2, 0.8)], ink, 1.6)
		&"blind_spot":
			_ring(on, box, Vector2(0.34, 0.46), 0.22, ink)
			_stroke(on, box, [Vector2(0.34, 0.16), Vector2(0.34, 0.76)], ink)
			_stroke(on, box, [Vector2(0.04, 0.46), Vector2(0.64, 0.46)], ink)
			IconShapes.disc(on, box, 0.76, 0.64, 0.07, ink)
			_stroke(on, box, [Vector2(0.84, 0.72), Vector2(0.94, 0.86)], ink)
			_stroke(on, box, [Vector2(0.88, 0.64), Vector2(0.97, 0.7)], ink)
		&"loose_change":
			for spot: Vector3 in [
				Vector3(0.28, 0.32, 0.12),
				Vector3(0.62, 0.26, 0.1),
				Vector3(0.48, 0.62, 0.14),
				Vector3(0.78, 0.7, 0.09)
			]:
				_ring(on, box, Vector2(spot.x, spot.y), spot.z, ink)
			_stroke(on, box, [Vector2(0.14, 0.84), Vector2(0.86, 0.88)], ink)
		&"under_the_table":
			_stroke(on, box, [Vector2(0.1, 0.3), Vector2(0.9, 0.28)], ink, 2.2)
			_stroke(on, box, [Vector2(0.18, 0.3), Vector2(0.16, 0.86)], ink)
			_stroke(on, box, [Vector2(0.82, 0.29), Vector2(0.84, 0.86)], ink)
			for y: float in [0.82, 0.72, 0.62, 0.52]:
				_stroke(on, box, [Vector2(0.38, y), Vector2(0.62, y - 0.01)], ink, 1.8)


## A pencil stroke through [param points] of [param box], gone over twice, [param heavy] times
## the usual weight.
static func _stroke(on: CanvasItem, box: Rect2, points: Array, ink: Color, heavy := 1.0) -> void:
	var weight := IconShapes.width(box) * 0.8 * heavy
	for pass_at: int in 2:
		var line := PackedVector2Array()
		var off := Vector2(AGAIN, -AGAIN * 0.6) * float(pass_at)
		for point: Vector2 in points:
			line.append(IconShapes.at(box, point.x + off.x, point.y + off.y))
		# Crisp over a note it is laid on at a closer look, drawn in place elsewhere, see [NoteCharts].
		NoteCharts.stroke(on, line, Color(ink, 0.85 if pass_at == 0 else 0.55), weight)


## A circle in pencil round [param middle], [param radius] out, not quite closed.
static func _ring(on: CanvasItem, box: Rect2, middle: Vector2, radius: float, ink: Color) -> void:
	var points := []
	for i: int in 21:
		var angle := TAU * (0.04 + 1.0 * float(i) / 20.0)
		points.append(middle + Vector2.from_angle(angle) * radius * (1.0 + 0.04 * sin(i * 2.3)))
	_stroke(on, box, points, ink)
