class_name NoteMark
extends Control
## A note of Kit's lying somewhere in this map, STORY.md 7.1, said beside the clock: a small scrap
## of the notes' paper hung off the right of the clock's board, its corner folded and lines of
## pencil on it, for as long as the note lies on the floor, and a magnifying glass over it in ink,
## a note still to be found. Once a kart here takes the note the glass goes and it is ticked off in
## red pen, as the driving test's checklist is, and stays so until the map is over.
## This machine's alone, as the note is, see [NoteDealer].

## How big the scrap is, how far right of the board it hangs, and how far it leans.
const SIZE := Vector2(24.0, 30.0)
const GAP := 10.0
const LEAN := 0.12
## How much of its width the folded corner takes.
const FOLD := 0.32
## How long it takes to drop in as the note turns up, from how much bigger.
const DROP := 0.32
const FROM := 1.7
const PAPER := NoteCollected.PAPER
const PENCIL := NoteCollected.PENCIL
const SHADOW := Color(0.0, 0.0, 0.0, 0.45)
## The tick of a note taken: red pen, how thick, and how long it takes to be drawn on.
const TICK_INK := HouseTheme.STAMP_RED
const TICK_WIDTH := 3.2
const TICK := 0.3
## The tick's three points against the scrap's size, its long stroke running out past its edge.
const TICK_POINTS: Array[Vector2] = [Vector2(0.12, 0.55), Vector2(0.42, 0.86), Vector2(1.22, 0.02)]
## The magnifying glass of a note still to be found: its ink, the glass's tint, where its lens sits
## against the scrap's size and how big it is against its width, where its handle ends, running out
## past the scrap's corner as the tick's long stroke does, how thick the rim and the handle are, and
## the paper's halo round both, so what runs off the scrap reads on the dark board beside it too.
const GLASS_INK := HouseTheme.INK
const GLASS_TINT := Color(0.66, 0.84, 0.96, 0.45)
const GLASS_AT := Vector2(0.52, 0.5)
const GLASS_RADIUS := 0.32
const HANDLE_TO := Vector2(1.12, 1.08)
const RIM := 2.4
const HANDLE := 3.6
const HALO := 2.0

## Whether the note was taken here, and how much of its tick is drawn, 0 to 1.
var collected := false
var _ticked := 0.0


## The scrap hung beside [param clock], the HUD's clock board, see [ClockBoard].
static func hang_on(clock: Control) -> NoteMark:
	var mark := NoteMark.new()
	mark.name = "NoteMark"
	mark.size = SIZE
	mark.pivot_offset = SIZE * 0.5
	mark.position = Vector2(ClockBoard.TOP + GAP, (ClockBoard.TALL - SIZE.y) * 0.5)
	mark.rotation = LEAN
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock.add_child(mark)
	return mark


func _ready() -> void:
	# Dropped in, since a note turning up is news.
	scale = Vector2.ONE * FROM
	modulate.a = 0.0
	var drop := create_tween().set_parallel()
	drop.tween_property(self, "scale", Vector2.ONE, DROP).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	drop.tween_property(self, "modulate:a", 1.0, DROP * 0.5)


## The note taken: ticked off, the tick drawn on over [constant TICK].
func collect() -> void:
	if collected:
		return
	collected = true
	var drawing := create_tween()
	drawing.tween_method(
		func(done: float) -> void:
			_ticked = done
			queue_redraw(),
		0.0,
		1.0,
		TICK
	)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var fold := w * FOLD
	var sheet := PackedVector2Array(
		[
			Vector2(0.0, 0.0),
			Vector2(w - fold, 0.0),
			Vector2(w, fold),
			Vector2(w, h),
			Vector2(0.0, h)
		]
	)
	var under := PackedVector2Array()
	for point: Vector2 in sheet:
		under.append(point + Vector2(1.5, 2.0))
	draw_colored_polygon(under, SHADOW)
	draw_colored_polygon(sheet, PAPER)
	draw_colored_polygon(
		PackedVector2Array([Vector2(w - fold, 0.0), Vector2(w - fold, fold), Vector2(w, fold)]),
		PAPER.darkened(0.2)
	)
	for i: int in 4:
		var y := h * (0.36 + i * 0.16)
		var end := w * (0.8 if i < 3 else 0.52)
		draw_line(Vector2(w * 0.18, y), Vector2(end, y), Color(PENCIL, 0.8), 1.5, true)
	# The glass fades as the tick is drawn on, and is gone once it is.
	if _ticked < 1.0:
		_draw_glass(1.0 - _ticked)
	if collected:
		_draw_tick()


## The magnifying glass at [param shown] of its strength: its handle, its tinted lens and its rim,
## each over a halo of the paper, and a glint on the glass.
func _draw_glass(shown: float) -> void:
	var middle := GLASS_AT * size
	var radius := GLASS_RADIUS * size.x
	var end := HANDLE_TO * size
	var start := middle + (end - middle).normalized() * radius
	var halo := Color(PAPER, shown)
	var ink := Color(GLASS_INK, shown)
	draw_line(start, end, halo, HANDLE + HALO * 2.0, true)
	draw_circle(end, (HANDLE + HALO * 2.0) * 0.5, halo)
	draw_arc(middle, radius, 0.0, TAU, 28, halo, RIM + HALO * 2.0, true)
	draw_line(start, end, ink, HANDLE, true)
	draw_circle(end, HANDLE * 0.5, ink)
	draw_circle(middle, radius - RIM * 0.5, Color(GLASS_TINT, GLASS_TINT.a * shown))
	draw_arc(middle, radius, 0.0, TAU, 28, ink, RIM, true)
	draw_arc(
		middle, radius * 0.55, PI * 1.05, PI * 1.45, 8, Color(1.0, 1.0, 1.0, 0.8 * shown), 1.4, true
	)


## As much of the tick as has been drawn: down the short stroke, then up the long one.
func _draw_tick() -> void:
	var points: Array[Vector2] = []
	for point: Vector2 in TICK_POINTS:
		points.append(point * size)
	var short := points[0].distance_to(points[1])
	var reach := (short + points[1].distance_to(points[2])) * _ticked
	var line := PackedVector2Array([points[0]])
	if reach <= short:
		line.append(points[0].lerp(points[1], reach / maxf(short, 0.001)))
	else:
		line.append(points[1])
		var long := points[1].distance_to(points[2])
		line.append(points[1].lerp(points[2], (reach - short) / maxf(long, 0.001)))
	draw_polyline(line, TICK_INK, TICK_WIDTH, true)
