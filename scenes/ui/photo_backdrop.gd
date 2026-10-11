class_name PhotoBackdrop
extends Control
## What the photo finish on the payout slip is taken against, GAME.md 3.8: a stage at night, dark
## at the top and warmer toward the floor, the casino's lights far behind it out of focus, soft
## discs of gold, warm white and red each glowing up and fading slowly in its own time; velvet
## curtains either side, gathered by a twisted gold cord with a tassel, under a pelmet of draped
## swags fringed in gold; and lit as the House's invitation is, STORY.md 6.1a, by two lamps just off
## its top corners, their soft beams crossing onto the winner's step and a pool of their light on
## the floor under it, the light breathing slowly up and down. The beams and the pool are the
## invitation's own, see [method OpeningInvitation.draw_beams], drawn on a stage the invitation's
## width, scaled to the picture. Drawn under the podium's picture, which has no background of its
## own, and kept inside its own edges, the lamps' glare and the pool too.
##
## Drawn once, as the title and the loyalty map are, and again only as it changes size or the
## winner stands somewhere else: what moves is faded rather than drawn again. The stage is one
## polygon; the curtains, the pelmet and all their gold one array of triangles, drawn into a
## picture of their own at the screen's own pixels, smoothed, and shown as one sprite; the far
## lights sprites of the one disc, made once a run, each glowing by its modulate; and the light
## breathing by its layer's.

## The stage: its top and its floor's colors.
const TOP := Color(0.04, 0.04, 0.08)
const FLOOR := Color(0.17, 0.12, 0.21)
## The lamps, on a stage as wide as the invitation's, see [constant OpeningInvitation.STAGE], as
## tall as the picture is for it: just off the top, toward its corners, as far either side of the
## winner as each other, so the beams are a pair however far over the winner stands. Where they
## light until the podium says where its winner stands, as a share of the picture: the middle, a
## little below halfway.
const LAMPS: Array[Vector2] = [Vector2(300.0, -150.0), Vector2(1620.0, -150.0)]
const LIT := Vector2(0.5, 0.68)
## The pool of light on the floor round the winner's step, flattened as a pool on a floor seen from
## the front is: how wide and how tall a share of the invitation's it is.
const POOL_SQUASH := Vector2(0.85, 0.42)
## How the light breathes: from how bright to how bright, against the invitation's, which lights a
## darker room, and how long a breath takes.
const DIMMEST := 0.95
const BRIGHTEST := 1.4
const BREATH_SECONDS := 7.0
## The lights far behind: how many, the same ones every time; where they may be, as shares of the
## picture, between the curtains and above the podium's feet; how big, as shares of its height; in
## what colors and how bright at their brightest; and how slowly each glows up and fades, a whole
## glow taking between the two, in seconds.
const FAR_LIGHTS := 18
const FAR_SEED := 7
const FAR_AREA := Rect2(0.14, 0.14, 0.72, 0.5)
const FAR_SIZE := Vector2(0.025, 0.075)
const FAR_INKS: Array[Color] = [
	Palette.CHIP_GOLD, Palette.CHIP_GOLD, Color(1.0, 0.9, 0.74), Color(0.95, 0.42, 0.38)
]
const FAR_LIGHT := Vector2(0.06, 0.18)
const FAR_SECONDS := Vector2(6.0, 14.0)
## The disc a far light is drawn with, how many pixels across, and how bright its middle is against
## its rim, as a light out of focus is.
const DISC := 64
const DISC_MIDDLE := 0.6
## The curtains: how wide each is, as a share of the picture's width, at the top, where the cord
## gathers it and at the floor; how far down the cord is, and how far it sags; its folds, how many
## and how wide each against the rest, the same every time, and how many shades across each.
const CURTAIN_WIDE := Vector3(0.12, 0.05, 0.09)
const CORD_AT := 0.6
const CORD_SAG := 0.035
const FOLD_WIDTHS: Array[float] = [1.0, 0.75, 1.25, 0.9, 1.1]
const ACROSS_FOLD := 8
## The velvet: in a fold's shadow, across its face, the sheen down its ridge where velvet catches
## the light, and how narrow that is; how much darker under the pelmet; and its shadow on the stage
## beside it, how dark and how far out, as a share of the picture's width.
const VELVET_SHADOW := Color(0.1, 0.012, 0.035)
const VELVET := Color(0.36, 0.05, 0.1)
const VELVET_SHEEN := Color(0.62, 0.16, 0.2)
const SHEEN_TIGHT := 5.0
const UNDER_PELMET := 0.5
const CAST := 0.5
const CAST_OUT := 0.06
## The pelmet across the top: how deep at its swags' lowest, how many swags, and how many pleats
## each is draped in; and its fringe, how long as a share of the picture's height and how many
## threads of it a swag has.
const PELMET_DEEP := 0.12
const SWAGS := 6
const PLEATS := 4
const FRINGE_LONG := 0.035
const THREADS := 34
## The gold of the cords, the fringe and the tassels: lit, in shadow, and bright where it catches
## the light.
const GOLD := Palette.CHIP_GOLD
const GOLD_DARK := Color(0.55, 0.38, 0.1)
const GOLD_BRIGHT := Color(1.0, 0.9, 0.6)
## How many steps down a curtain's edge, along a swag or a cord, and round a knot are drawn in.
const SMOOTH := 28
const ROUND := 14

## The one disc every far light is drawn with, made the first time it is asked for.
static var _disc: ImageTexture

## The podium the photo is of, whose winner the lamps are aimed at, see [method
## ResultsPodium.winner_at]; none, the middle.
var podium: ResultsPodium

## The picture the curtains are drawn into once, smoothed, and the sprite it is shown on.
var _sheet: SubViewport
var _curtains: Node2D
var _shown: Sprite2D
var _lights: Node2D
var _far: Array[Sprite2D] = []
var _time := 0.0
## The far lights, each where it is as a share of the picture, its radius as a share of its height,
## its color, and its glow's pace and where in it it starts, made once from [constant FAR_SEED].
var _far_lights: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The lamps' glare and the pool reach past the picture's edges; the picture stops at them.
	clip_contents = true
	_far_lights = far_lights()
	for far: Dictionary in _far_lights:
		var light := Sprite2D.new()
		light.texture = disc()
		light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(light)
		_far.append(light)
	_sheet = SubViewport.new()
	_sheet.name = "CurtainSheet"
	_sheet.transparent_bg = true
	_sheet.msaa_2d = Viewport.MSAA_4X
	_sheet.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_sheet)
	_curtains = Node2D.new()
	_curtains.name = "Curtains"
	_curtains.draw.connect(_draw_curtains)
	_sheet.add_child(_curtains)
	_shown = Sprite2D.new()
	_shown.name = "Curtains"
	_shown.centered = false
	_shown.texture = _sheet.get_texture()
	# Drawn onto nothing, its smoothed edges are already as faint as they are dark.
	var premultiplied := CanvasItemMaterial.new()
	premultiplied.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	_shown.material = premultiplied
	add_child(_shown)
	_lights = Node2D.new()
	_lights.name = "Lights"
	_lights.draw.connect(_draw_lights)
	_lights.modulate.a = DIMMEST
	add_child(_lights)
	resized.connect(_on_resized)
	if podium != null:
		podium.stood.connect(_lights.queue_redraw)
		podium.item_rect_changed.connect(_lights.queue_redraw)
	_on_resized()


func _on_resized() -> void:
	queue_redraw()
	_lights.queue_redraw()
	if size.x >= 1.0 and size.y >= 1.0:
		var pixels := _pixels()
		_sheet.size = Vector2i((size * pixels).ceil())
		_curtains.scale = Vector2.ONE * pixels
		_shown.scale = Vector2.ONE / pixels
		_curtains.queue_redraw()
		_sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
	for i: int in _far.size():
		var far := _far_lights[i]
		_far[i].position = size * (far["at"] as Vector2)
		_far[i].scale = Vector2.ONE * size.y * float(far["radius"]) * 2.0 / float(DISC)
	_glow()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	var breath := 0.5 - 0.5 * cos(_time * TAU / BREATH_SECONDS)
	_lights.modulate.a = lerpf(DIMMEST, BRIGHTEST, breath)
	_glow()


## How many of the screen's pixels each of this one's units is, so the curtains' picture is drawn
## as sharp as the screen shows it: more than one on a phone's dense screen.
func _pixels() -> float:
	var shown := get_viewport().get_final_transform() * get_global_transform_with_canvas()
	return clampf(shown.get_scale().x, 1.0, 3.0)


## Each far light as bright as it is in its glow now.
func _glow() -> void:
	for i: int in _far.size():
		var far := _far_lights[i]
		var glow := 0.5 + 0.5 * sin(_time * float(far["pace"]) + float(far["from"]))
		_far[i].modulate = Color(far["ink"], float(far["light"]) * lerpf(0.3, 1.0, glow))


## Where the lamps are aimed, as a share of the picture: on the podium's winner, wherever the podium
## stands beside this, or the middle.
func aim() -> Vector2:
	if podium == null or not podium.visible or size.x <= 0.0 or size.y <= 0.0:
		return LIT
	var at := podium.position + podium.size * podium.winner_at() - position
	return at / size


## The lights far behind the stage, the same every time, see [member _far_lights].
static func far_lights() -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = FAR_SEED
	var made: Array[Dictionary] = []
	for i: int in FAR_LIGHTS:
		var at := FAR_AREA.position + FAR_AREA.size * Vector2(rng.randf(), rng.randf())
		(
			made
			. append(
				{
					"at": at,
					"radius": rng.randf_range(FAR_SIZE.x, FAR_SIZE.y),
					"ink": FAR_INKS[rng.randi_range(0, FAR_INKS.size() - 1)],
					"light": rng.randf_range(FAR_LIGHT.x, FAR_LIGHT.y),
					"pace": TAU / rng.randf_range(FAR_SECONDS.x, FAR_SECONDS.y),
					"from": rng.randf_range(0.0, TAU),
				}
			)
		)
	# The biggest first, so the small ones sit over them.
	made.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["radius"] > b["radius"])
	return made


## The disc of a light out of focus, white, brighter at its rim than in its middle and smoothed at
## its edge, with mipmaps for drawing it small.
static func disc() -> ImageTexture:
	if _disc != null:
		return _disc
	var image := Image.create_empty(DISC, DISC, false, Image.FORMAT_RGBA8)
	var middle := float(DISC) * 0.5
	for y: int in DISC:
		for x: int in DISC:
			var out := Vector2(float(x) + 0.5 - middle, float(y) + 0.5 - middle).length() / middle
			var light := lerpf(DISC_MIDDLE, 1.0, smoothstep(0.7, 0.92, out))
			light *= 1.0 - smoothstep(0.93, 1.0, out)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, light))
	image.generate_mipmaps()
	_disc = ImageTexture.create_from_image(image)
	return _disc


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	# The stage, darker overhead.
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]),
		PackedColorArray([TOP, TOP, FLOOR, FLOOR])
	)


## The curtains either side, the pelmet over them and all their gold, as one array of triangles.
func _draw_curtains() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var cloth := Cloth.new()
	for side: float in [0.0, 1.0]:
		_curtain(cloth, side)
	_pelmet(cloth)
	RenderingServer.canvas_item_add_triangle_array(
		_curtains.get_canvas_item(), cloth.indices, cloth.points, cloth.colors
	)


## How far in a curtain comes at [param down], a share of the way to the floor: widest at the top,
## gathered in at the cord, and spreading a little again to the floor.
func _curtain_wide(down: float) -> float:
	var wide := CURTAIN_WIDE * size.x
	if down < CORD_AT:
		return lerpf(wide.x, wide.y, smoothstep(0.0, CORD_AT, down))
	return lerpf(wide.y, wide.z, smoothstep(CORD_AT, 1.0, down))


## The curtain on [param side], 0 the left and 1 the right, into [param cloth]: its shadow on the
## stage; its folds, each rounded, in shadow at its edges with the sheen down its ridge, narrowing
## as they gather to the cord and darker under the pelmet; its inner edge catching the light; and
## the cord round it.
func _curtain(cloth: Cloth, side: float) -> void:
	var out := 1.0 if side == 0.0 else -1.0
	for step: int in SMOOTH:
		var top := float(step) / float(SMOOTH)
		var bottom := float(step + 1) / float(SMOOTH)
		var edge_top := _in_curtain(side, 1.0, top)
		var edge_bottom := _in_curtain(side, 1.0, bottom)
		var reach := Vector2(size.x * CAST_OUT * out, 0.0)
		var dark := Color(0.0, 0.0, 0.0, CAST)
		var none := Color(0.0, 0.0, 0.0, 0.0)
		cloth.quad(
			[edge_top, edge_top + reach, edge_bottom + reach, edge_bottom], [dark, none, none, dark]
		)
	var total := 0.0
	for wide: float in FOLD_WIDTHS:
		total += wide
	var near := 0.0
	for fold: int in FOLD_WIDTHS.size():
		var far := near + FOLD_WIDTHS[fold] / total
		# Folds further in, toward the stage's lights, a little brighter.
		var lit := lerpf(0.75, 1.1, (near + far) * 0.5)
		for column: int in ACROSS_FOLD:
			var left := float(column) / float(ACROSS_FOLD)
			var right := float(column + 1) / float(ACROSS_FOLD)
			var a := lerpf(near, far, left)
			var b := lerpf(near, far, right)
			for step: int in SMOOTH:
				var top := float(step) / float(SMOOTH)
				var bottom := float(step + 1) / float(SMOOTH)
				cloth.quad(
					[
						_in_curtain(side, a, top),
						_in_curtain(side, b, top),
						_in_curtain(side, b, bottom),
						_in_curtain(side, a, bottom)
					],
					[
						_velvet(left, top, lit),
						_velvet(right, top, lit),
						_velvet(right, bottom, lit),
						_velvet(left, bottom, lit)
					]
				)
		near = far
	var edge := PackedVector2Array()
	for step: int in SMOOTH + 1:
		edge.append(_in_curtain(side, 1.0, float(step) / float(SMOOTH)))
	cloth.ribbon(edge, maxf(size.x * 0.0018, 1.0), Color(VELVET_SHEEN, 0.85))
	_cord(cloth, side)


## The point [param across] the way in from the outer edge of the curtain on [param side], 0 at
## its outer edge and 1 at its inner, [param down] the way to the floor.
func _in_curtain(side: float, across: float, down: float) -> Vector2:
	var x := _curtain_wide(down) * across
	return Vector2(x if side == 0.0 else size.x - x, size.y * down)


## The velvet [param across] a fold, 0 to 1 edge to edge, [param down] the way to the floor, as
## [param lit] as the fold is: in shadow at its edges, its face rounding up to the sheen down its
## ridge, and darker under the pelmet and a little toward the floor.
func _velvet(across: float, down: float, lit: float) -> Color:
	var round := 0.5 - 0.5 * cos(TAU * across)
	var ink := VELVET_SHADOW.lerp(VELVET, round)
	ink = ink.lerp(VELVET_SHEEN, pow(round, SHEEN_TIGHT) * 0.8)
	var shade := 1.0 - UNDER_PELMET * (1.0 - smoothstep(0.0, 0.45, down))
	shade *= 1.0 - 0.2 * smoothstep(0.75, 1.0, down)
	return Color(ink.r * shade * lit, ink.g * shade * lit, ink.b * shade * lit)


## The cord round the curtain on [param side] where it is gathered, into [param cloth]: a rope
## twisted in two golds, sagging a little, a knot at its inner end and a tassel hanging from it,
## its threads in stripes.
func _cord(cloth: Cloth, side: float) -> void:
	var thick := maxf(size.y * 0.02, 2.0)
	var rope := PackedVector2Array()
	for step: int in SMOOTH + 1:
		var across := float(step) / float(SMOOTH)
		var at := _in_curtain(side, minf(across * 1.06, 1.06), CORD_AT)
		at.y += size.y * CORD_SAG * sin(PI * across)
		rope.append(at)
	cloth.band(rope, thick + 1.5, GOLD_DARK)
	# The twist: a stripe of light across it every so often, slanted.
	var half := thick * 0.5
	for i: int in rope.size() - 1:
		var from := rope[i]
		var to := rope[i + 1]
		var lean := (to - from) * 0.45
		cloth.quad(
			[from + Vector2(0.0, -half), to + Vector2(0.0, -half), to + lean, from + lean],
			[GOLD, GOLD_BRIGHT, GOLD, GOLD_DARK]
		)
		cloth.quad(
			[from + lean, to + lean, to + Vector2(0.0, half), from + Vector2(0.0, half)],
			[GOLD_DARK, GOLD, GOLD, GOLD_DARK]
		)
	var knot := rope[rope.size() - 1]
	cloth.disc(knot, thick * 0.85, GOLD_DARK)
	cloth.disc(knot + Vector2(-thick * 0.15, -thick * 0.15), thick * 0.6, GOLD)
	_tassel(cloth, knot + Vector2(0.0, thick * 0.6), thick * 0.75, thick * 3.4)


## A tassel hanging from [param top] into [param cloth], [param wide] across its skirt and
## [param long]: a little neck, then threads in stripes of two golds, flaring out a little.
func _tassel(cloth: Cloth, top: Vector2, wide: float, long: float) -> void:
	var neck := long * 0.22
	cloth.quad(
		[
			top + Vector2(-wide * 0.35, 0.0),
			top + Vector2(wide * 0.35, 0.0),
			top + Vector2(wide * 0.45, neck),
			top + Vector2(-wide * 0.45, neck)
		],
		[GOLD, GOLD, GOLD_DARK, GOLD_DARK]
	)
	var threads := 7
	for i: int in threads:
		var left := float(i) / float(threads)
		var right := float(i + 1) / float(threads)
		var ink := GOLD if i % 2 == 0 else GOLD_DARK
		var tip := GOLD_DARK.darkened(0.2)
		cloth.quad(
			[
				top + Vector2(lerpf(-wide * 0.45, wide * 0.45, left), neck),
				top + Vector2(lerpf(-wide * 0.45, wide * 0.45, right), neck),
				top + Vector2(lerpf(-wide * 0.6, wide * 0.6, right), long),
				top + Vector2(lerpf(-wide * 0.6, wide * 0.6, left), long)
			],
			[ink, ink, tip, tip]
		)


## The pelmet across the top into [param cloth]: swags hung between knots, each draped in pleats
## that curve as it does, in shadow between them and darker toward where it hangs from; a hem of
## gold along the bottom of it with a fringe of threads hanging from it; and a knot of gold where
## each swag is hung.
func _pelmet(cloth: Cloth) -> void:
	var deep := size.y * PELMET_DEEP
	var steps := SWAGS * SMOOTH
	var hem := PackedVector2Array()
	for step: int in steps + 1:
		var along := float(step) / float(steps)
		hem.append(Vector2(size.x * along, _hem_y(along, deep)))
	# The pleats: bands from the top down to the hem, following its curve more the lower they are,
	# each in shadow at its edges and lit across its middle.
	var rows := PLEATS * 2
	for row: int in rows:
		var upper := float(row) / float(rows)
		var lower := float(row + 1) / float(rows)
		var lit_upper := row % 2 == 1
		for step: int in steps:
			var x0 := hem[step].x
			var x1 := hem[step + 1].x
			cloth.quad(
				[
					Vector2(x0, _pleat_y(hem[step].y, upper, deep)),
					Vector2(x1, _pleat_y(hem[step + 1].y, upper, deep)),
					Vector2(x1, _pleat_y(hem[step + 1].y, lower, deep)),
					Vector2(x0, _pleat_y(hem[step].y, lower, deep))
				],
				[
					_swag_ink(lit_upper, upper),
					_swag_ink(lit_upper, upper),
					_swag_ink(not lit_upper, lower),
					_swag_ink(not lit_upper, lower)
				]
			)
	var fringe := maxf(size.y * 0.012, 1.5)
	var long := size.y * FRINGE_LONG
	# The threads, hanging from the hem, each a little shorter or longer than the next.
	for i: int in SWAGS * THREADS:
		var along := (float(i) + 0.5) / float(SWAGS * THREADS)
		var at := Vector2(size.x * along, _hem_y(along, deep))
		var wide := size.x / float(SWAGS * THREADS) * 0.45
		var hang := long * (0.85 + 0.15 * sin(float(i) * 2.3))
		cloth.quad(
			[
				at + Vector2(-wide, 0.0),
				at + Vector2(wide, 0.0),
				at + Vector2(wide, hang),
				at + Vector2(-wide, hang)
			],
			[GOLD, GOLD, GOLD_DARK, GOLD_DARK]
		)
	cloth.band(hem, fringe + 1.0, GOLD_DARK)
	cloth.band(hem, fringe, GOLD)
	cloth.ribbon(hem, maxf(fringe * 0.3, 0.75), GOLD_BRIGHT, -fringe * 0.25)
	for hung: int in range(1, SWAGS):
		var at := Vector2(size.x * float(hung) / float(SWAGS), _hem_y(0.0, deep))
		cloth.disc(at, fringe * 1.9, GOLD_DARK)
		cloth.disc(at + Vector2(-fringe * 0.3, -fringe * 0.3), fringe * 1.35, GOLD)
		_tassel(cloth, at + Vector2(0.0, fringe * 1.3), fringe * 2.0, long * 1.6)


## How far down the pelmet's hem is [param along] the picture, 0 to 1, [param deep] at a swag's
## lowest: up at the knots, down in an arc between them.
func _hem_y(along: float, deep: float) -> float:
	var swag := fmod(along * float(SWAGS), 1.0)
	return deep * (0.42 + 0.58 * sin(PI * swag))


## How far down a pleat's edge [param share] of the way from the top to the hem runs, where the hem
## is at [param hem]: the top pleats nearly straight, the lower ones curving with the swag.
func _pleat_y(hem: float, share: float, deep: float) -> float:
	var straight := deep * 0.42 * share
	return lerpf(straight, hem, share)


## The swag's velvet in a pleat's shadow or lit across it, [param lit], [param share] of the way
## from the top to the hem: darker toward the top, where it hangs from.
func _swag_ink(lit: bool, share: float) -> Color:
	var ink := VELVET if lit else VELVET_SHADOW
	if lit and share > 0.6:
		ink = ink.lerp(VELVET_SHEEN, 0.35)
	return ink.darkened(0.45 * (1.0 - share))


## The beams, the lamps' glare and the pool, on a stage the invitation's width scaled down to the
## picture's, aimed at the winner.
func _draw_lights() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := size.x / OpeningInvitation.STAGE.x
	var stage := Vector2(OpeningInvitation.STAGE.x, size.y / scale)
	var lit := stage * aim()
	_lights.draw_set_transform(lit * scale, 0.0, POOL_SQUASH * scale)
	OpeningInvitation.draw_pool(_lights)
	_lights.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale)
	var over := Vector2(lit.x - stage.x * 0.5, 0.0)
	var lamps: Array[Vector2] = [LAMPS[0] + over, LAMPS[1] + over]
	OpeningInvitation.draw_beams(_lights, lit, lamps)
	_lights.draw_set_transform_matrix(Transform2D.IDENTITY)


## Triangles laid into one array, to be drawn in one call: quads, bands and ribbons along a line,
## and discs, each point in a color of its own.
class Cloth:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()

	## A four-sided shape of [param corners] in [param inks], in order round it.
	func quad(corners: Array, inks: Array) -> void:
		var first := points.size()
		for i: int in 4:
			points.append(corners[i])
			colors.append(inks[i])
		indices.append_array([first, first + 1, first + 2, first, first + 2, first + 3])

	## A band [param thick] tall down the middle of [param line], in [param ink], [param lower]
	## below it: along a line that runs mostly across, as a cord and a hem do.
	func band(line: PackedVector2Array, thick: float, ink: Color, lower := 0.0) -> void:
		var up := Vector2(0.0, lower - thick * 0.5)
		var down := Vector2(0.0, lower + thick * 0.5)
		for i: int in line.size() - 1:
			quad(
				[line[i] + up, line[i + 1] + up, line[i + 1] + down, line[i] + down],
				[ink, ink, ink, ink]
			)

	## A ribbon [param thick] wide along [param line] whichever way it runs, in [param ink],
	## [param lower] below it.
	func ribbon(line: PackedVector2Array, thick: float, ink: Color, lower := 0.0) -> void:
		for i: int in line.size() - 1:
			var way := (line[i + 1] - line[i]).normalized()
			var side := Vector2(-way.y, way.x) * thick * 0.5
			var down := Vector2(0.0, lower)
			quad(
				[
					line[i] - side + down,
					line[i + 1] - side + down,
					line[i + 1] + side + down,
					line[i] + side + down
				],
				[ink, ink, ink, ink]
			)

	## A disc [param radius] round [param middle] in [param ink].
	func disc(middle: Vector2, radius: float, ink: Color) -> void:
		var first := points.size()
		points.append(middle)
		colors.append(ink)
		for i: int in ROUND:
			points.append(middle + Vector2.from_angle(TAU * float(i) / float(ROUND)) * radius)
			colors.append(ink)
		for i: int in ROUND:
			indices.append_array([first, first + 1 + i, first + 1 + (i + 1) % ROUND])
