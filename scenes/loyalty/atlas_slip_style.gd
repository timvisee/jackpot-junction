class_name AtlasSlipStyle
extends StyleBox
## The slip of the House's cream paper the loyalty program's details are printed on, GAME.md
## 8.9, lying flat on the atlas's cover, bound along its top by a wire coil as a pad's page is,
## see [method AtlasArt.coil], and torn along its foot: a band along its top for the coil's holes,
## a gold hairline inside its edge under that, a dotted line across it at [member tear_at] under
## its header, and only a little shadow under it on the cloth, as paper lying flat has. While what
## it says is still on the plans, a landmark not open yet, it is blueprint paper instead, see
## [member planned].

## The paper, darker toward its foot by this share of the way to its low shade.
const PAPER := HouseTheme.PAPER
const PAPER_LOW := HouseTheme.PAPER_LOW
const DARKER := 0.7
## How wide and deep the teeth of its torn foot are.
const TOOTH := 12.0
const TOOTH_DEEP := 6.0
## How tall the band along its top for the coil's holes is.
const BAND := 16.0
## How far in the hairline runs, under the band at its top, how much further at the foot to clear
## the teeth, and its gold.
const HAIRLINE_IN := 7.0
const HAIRLINE_FOOT := 6.0
const HAIRLINE := Color(0.76, 0.55, 0.17, 0.8)
## The dotted line under its header: how far apart its dots are, how big, how far in from the edges
## they start, and their ink.
const DOT_STEP := 9.0
const DOT := 1.6
const DOT_IN := 15.0
const DOT_INK := Color(0.13, 0.12, 0.14, 0.45)
## The blueprint paper, see [member planned]: the paper, darker toward its foot, its grid, how far
## apart the lines are and how many to a heavier one, its hairline and the dotted line in white;
## and the barrier along its foot, as at roadworks, its height, how far up from the foot it is,
## its stripes' width and lean, and their colors, with the room it takes from what is printed.
const PLAN_PAPER := Color("#2f68ad")
const PLAN_PAPER_LOW := Color("#265892")
const PLAN_GRID := Color(1.0, 1.0, 1.0, 0.09)
const PLAN_GRID_HEAVY := Color(1.0, 1.0, 1.0, 0.18)
const PLAN_GRID_STEP := 16.0
const PLAN_GRID_EVERY := 4
const PLAN_HAIRLINE := Color(1.0, 1.0, 1.0, 0.7)
const PLAN_DOT_INK := Color(1.0, 1.0, 1.0, 0.5)
const BARRIER := 14.0
const BARRIER_UP := 30.0
const BARRIER_STRIPE := 10.0
const BARRIER_LEAN := 14.0
const BARRIER_YELLOW := Color("#e5b52e")
const BARRIER_BLACK := Color("#1d1b1f")
const BARRIER_ROOM := 14.0
## The shadow under it, two steps of it fallen a little down.
const SHADOW: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(1.0, 2.5)]
const SHADOW_INK: Array[float] = [0.28, 0.16]
## The room round what is printed on it, and more at its foot for the teeth.
const ROOM := 22.0
const ROOM_FOOT := 28.0

## Where across it the dotted line under its header runs, from its top; none at nothing.
var tear_at := 0.0
## Whether what it says is still on the plans, a landmark not open yet: blueprint paper, a grid on
## it and its lines in white, and a barrier along its foot, which takes a little more room there.
var planned := false:
	set(on):
		planned = on
		content_margin_bottom = ROOM_FOOT + (BARRIER_ROOM if on else 0.0)


func _init() -> void:
	content_margin_left = ROOM
	content_margin_right = ROOM
	content_margin_top = ROOM + BAND
	content_margin_bottom = ROOM_FOOT


func _draw(item: RID, rect: Rect2) -> void:
	var outline := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y)])
	var teeth := maxi(int(rect.size.x / TOOTH), 1)
	for i: int in teeth + 1:
		var x := rect.end.x - rect.size.x * i / teeth
		outline.append(Vector2(x, rect.end.y - (TOOTH_DEEP if i % 2 == 1 else 0.0)))
	for k: int in SHADOW.size():
		var fallen := PackedVector2Array()
		for point: Vector2 in outline:
			fallen.append(point + SHADOW[k])
		var ink := PackedColorArray([Color(0.0, 0.0, 0.0, SHADOW_INK[k])])
		RenderingServer.canvas_item_add_polygon(item, fallen, ink)
	var colors := PackedColorArray()
	var top := PLAN_PAPER if planned else PAPER
	var foot := PLAN_PAPER_LOW if planned else PAPER_LOW
	for point: Vector2 in outline:
		var down := (point.y - rect.position.y) / maxf(rect.size.y, 1.0)
		colors.append(top.lerp(foot, down * DARKER))
	RenderingServer.canvas_item_add_polygon(item, outline, colors)
	if planned:
		_grid(item, rect)
		_barrier(item, rect)
	var hairline := Rect2(rect.position + Vector2(HAIRLINE_IN, HAIRLINE_IN + BAND), rect.size)
	hairline.size -= Vector2(HAIRLINE_IN * 2.0, HAIRLINE_IN * 2.0 + HAIRLINE_FOOT + BAND)
	var corners := PackedVector2Array(
		[
			hairline.position,
			Vector2(hairline.end.x, hairline.position.y),
			hairline.end,
			Vector2(hairline.position.x, hairline.end.y),
			hairline.position,
		]
	)
	var hair := PLAN_HAIRLINE if planned else HAIRLINE
	var hair_wide := 1.5 if planned else 1.0
	RenderingServer.canvas_item_add_polyline(
		item, corners, PackedColorArray([hair]), hair_wide, true
	)
	if tear_at <= 0.0:
		return
	# The dots as one line of dashes as long as they are thick, in one draw.
	var dots := PackedVector2Array()
	var x := rect.position.x + DOT_IN
	while x <= rect.end.x - DOT_IN:
		var at := Vector2(x, rect.position.y + tear_at)
		dots.append(at - Vector2(DOT * 0.75, 0.0))
		dots.append(at + Vector2(DOT * 0.75, 0.0))
		x += DOT_STEP
	var ink := PLAN_DOT_INK if planned else DOT_INK
	RenderingServer.canvas_item_add_multiline(item, dots, PackedColorArray([ink]), DOT * 1.5)


## The blueprint's grid over [param rect], under the band for the coil, its light lines in one draw
## and its heavier ones in another.
func _grid(item: RID, rect: Rect2) -> void:
	var light := PackedVector2Array()
	var heavy := PackedVector2Array()
	var top := rect.position.y + BAND
	var foot := rect.end.y - TOOTH_DEEP
	var count := 0
	var x := rect.position.x + HAIRLINE_IN
	while x <= rect.end.x:
		var into := heavy if count % PLAN_GRID_EVERY == 0 else light
		into.append_array(PackedVector2Array([Vector2(x, top), Vector2(x, foot)]))
		x += PLAN_GRID_STEP
		count += 1
	count = 0
	var y := top + 4.0
	while y <= foot:
		var into := heavy if count % PLAN_GRID_EVERY == 0 else light
		into.append_array(PackedVector2Array([Vector2(rect.position.x, y), Vector2(rect.end.x, y)]))
		y += PLAN_GRID_STEP
		count += 1
	RenderingServer.canvas_item_add_multiline(item, light, PackedColorArray([PLAN_GRID]), 1.0)
	RenderingServer.canvas_item_add_multiline(item, heavy, PackedColorArray([PLAN_GRID_HEAVY]), 1.0)


## The barrier along the foot of [param rect], inside the hairline: yellow, its black stripes all
## in one draw.
func _barrier(item: RID, rect: Rect2) -> void:
	var strip := Rect2(
		Vector2(rect.position.x + HAIRLINE_IN, rect.end.y - BARRIER_UP),
		Vector2(rect.size.x - HAIRLINE_IN * 2.0, BARRIER)
	)
	RenderingServer.canvas_item_add_rect(item, strip, BARRIER_YELLOW)
	var edge := PackedVector2Array(
		[
			strip.position,
			Vector2(strip.end.x, strip.position.y),
			strip.end,
			Vector2(strip.position.x, strip.end.y)
		]
	)
	var points := PackedVector2Array()
	var indices := PackedInt32Array()
	var x := strip.position.x - BARRIER_LEAN
	while x < strip.end.x:
		var stripe := PackedVector2Array(
			[
				Vector2(x, strip.end.y),
				Vector2(x + BARRIER_LEAN, strip.position.y),
				Vector2(x + BARRIER_LEAN + BARRIER_STRIPE, strip.position.y),
				Vector2(x + BARRIER_STRIPE, strip.end.y),
			]
		)
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(stripe, edge):
			var first := points.size()
			points.append_array(piece)
			for i: int in range(1, piece.size() - 1):
				indices.append_array(PackedInt32Array([first, first + i, first + i + 1]))
		x += BARRIER_STRIPE * 2.0
	var colors := PackedColorArray()
	colors.resize(points.size())
	colors.fill(BARRIER_BLACK)
	RenderingServer.canvas_item_add_triangle_array(item, indices, points, colors)
