class_name TitleBackground
extends Control
## What is behind the title screen, GAME.md 8.1: a slow carnival sunburst turning behind the
## name, narrow beams of foil light with fine rays engraved between them over a glow round the
## mark, fading out well before the screen's sides and foot, and poker chips and a few cards face
## down, wearing the card back the player has chosen, drifting up past it, out at the edges and
## gone near the mark.
##
## Drawn rather than modeled. The menu is a flat screen and the game behind it is not running,
## so a scene would be a scene loaded to be looked at once; this is drawn once and only moved a
## frame, in a handful of draws, with nothing to load. Dark on purpose: the point of the screen is
## the words on it. The wedges are light laid over the backdrop rather than two tones of their own,
## so the engraving of the house's stock, GAME.md 8.1a, shows through the whole of the burst rather
## than being painted out.

## The sunburst, GAME.md 8.1a: beams of foil light, narrow, with the backdrop between them, how
## much of each beam's share of the turn is lit, how long one full turn takes, and how strong the
## light is at the mark, from where it fades.
const BEAMS := 48
const BEAM_WIDTH := 0.3
const TURN_SECONDS := 200.0
const LIGHT := Color(Palette.CHIP_GOLD, 0.04)
## How far the burst reaches, as a share of the way from the mark to the nearest of the screen's
## left side, right side and foot, so it never touches one; how far out of that it is still at its
## full light; and how many steps the fade is drawn in.
const REACH := 0.88
const SOLID := 0.15
const FADE_STEPS := 10
## The rays engraved between the beams and turning with them: how many, how strong, and how far
## out from the mark they start, in the mark's radii, clear of the seal; fading out with the beams.
const RAYS := 192
const RAY_INK := Color(Palette.CHIP_GOLD, 0.05)
const RAY_FROM := 5.3
## How far either side of its line a ray's ink fades out to nothing, in pixels: the ray's own soft
## edge, drawn in the beams' one array of triangles rather than as a smoothed line of its own, and
## how strong its middle is against the thin smoothed line it stands in for.
const RAY_SOFT := 0.9
const RAY_MIDDLE := 0.7
## The glow behind the mark: the stock lit a step round it, falling off to the backdrop's own
## dark well before the edges, as far out as this share of the screen's diagonal.
const GLOW := Color(0.16, 0.14, 0.19, 0.85)
const GLOW_REACH := 0.62
## Where the burst is centered, as a share of the screen: behind the title rather than the middle.
const CENTER := Vector2(0.5, 0.34)
## The seal behind the mark, GAME.md 8.1a: three bands of guilloché rings round it, each as
## [radius, depth, lobes, lines, ink] against the mark's own radius, and how long it takes to turn
## once. Drawn once and turned whole, so turning it costs nothing a frame.
const SEAL_BANDS := [
	[2.15, 0.13, 28, 12, 0.15], [3.2, 0.19, 40, 16, 0.09], [4.55, 0.23, 54, 20, 0.055]
]
const SEAL_TURN := 240.0
## How many chips drift past, how big they are, how long one takes to cross the screen, and how
## strong one is out at the edges. They are the chips of the house's print, GAME.md 8.1a, the
## seat cards' own, and fade the other way to the beams: clear within the first of these shares of
## the burst's reach from the mark, and all there past the second.
const CHIPS := 14
const CHIP_RADIUS := Vector2(16.0, 40.0)
const CHIP_SECONDS := Vector2(40.0, 80.0)
## How far a chip turns on its way up, in whole turns, the least and the most; every other one the
## other way, so they turn both ways.
const CHIP_SPIN := Vector2(0.4, 1.0)
const CHIP_ALPHA := 0.18
const CHIP_CLEAR := Vector2(0.45, 1.05)
## The cards drifting up among them face down, in the back the profile playing wears, GAME.md 8.9:
## how many, how big against a [JokerCard], how long one takes to cross the screen, how far it
## turns on its way, both ways as the chips do, and how strong one is out at the edges, a little
## more than a chip so the back is seen.
const CARDS := 6
const CARD_SCALE := Vector2(0.4, 0.7)
const CARD_SECONDS := Vector2(55.0, 95.0)
const CARD_SPIN := Vector2(0.3, 0.7)
const CARD_ALPHA := 0.4
## How many times a card's own size its back is drawn at, once, see [method _paint_back], so the
## biggest card drawn on a big screen is a smaller copy of it rather than a stretched one.
const BACK_PIXELS := 2
## How many pixels across each chip's face is drawn, once, see [method _paint_faces], and how many
## frames it waits at most for them to be drawn.
const CHIP_CELL := 128
const FACE_TRIES := 4

## The chips' faces, one in each player color side by side, drawn once a run with smaller copies of
## themselves for the chips drawn small, see [method _paint_faces]; null until they have been.
static var _faces: Texture2D
## The card backs drawn so far this run, by the back, see [method _paint_back].
static var _drawn_backs: Dictionary[int, Texture2D] = {}

## What the burst and the seal are centered on, the mark over the name; nothing for the middle
## of [constant CENTER].
var anchor: Control
## How much of each part is up, from 0 to 1, for the title's opening to bring them in one after
## another, see [TitleIntro]: the glow, the seal's rings, band by band out from the mark, and the
## burst, sweeping out from the mark, with the chips.
var glow := 1.0:
	set(value):
		glow = value
		queue_redraw()
var rings := 1.0:
	set(value):
		rings = value
		if _seal != null:
			_seal.shown = value
var beams := 1.0

var _spin := 0.0
var _glow: GradientTexture2D
## Where the glow was last drawn and how strong, so it is drawn again only when either changes.
var _glowed := Rect2()
var _chips: Array[Dictionary] = []
var _sprites: Array[Sprite2D] = []
var _cards: Array[Dictionary] = []
## The cards, each a picture of the back worn moved, turned and faded a frame, as the chips are,
## rather than its engraving drawn again every frame, see [method _paint_back].
var _backs: Array[Sprite2D] = []
var _back_tries := 0
var _back_sheet: Node
var _face_tries := 0
var _seal: Seal
var _sealed_for := 0.0
var _burst: Sunburst


## The seal's rings, drawn once round its own middle and turned as a whole; each band comes up out
## of the mark in its turn as [member shown] goes from 0 to 1. A [Node2D] rather than a control,
## which is drawn again whenever it is turned: this is turned every frame and drawn once.
class Seal:
	extends Node2D

	var shown := 1.0:
		set(value):
			shown = value
			queue_redraw()

	var _lines: Array[PackedVector2Array] = []
	var _inks: Array[Color] = []
	var _bands: PackedInt32Array = []

	## Laid out round a mark [param mark] out from its middle.
	func lay(mark: float) -> void:
		_lines.clear()
		_inks.clear()
		_bands.clear()
		for band: int in TitleBackground.SEAL_BANDS.size():
			var made: Array = TitleBackground.SEAL_BANDS[band]
			var rings := Engraving.rings(
				Vector2.ZERO,
				mark * float(made[0]),
				mark * float(made[1]),
				made[2],
				made[3],
				int(made[2]) * 9
			)
			_lines.append_array(rings)
			for ring: PackedVector2Array in rings:
				_inks.append(Color(HouseTheme.FOIL, float(made[4])))
				_bands.append(band)
		queue_redraw()

	## How far up band [param band] of three is, the inner one first, as the seal is [member shown].
	func band_shown(band: int) -> float:
		return clampf((shown - float(band) * 0.25) / 0.5, 0.0, 1.0)

	func _draw() -> void:
		for i: int in _lines.size():
			var up := band_shown(_bands[i])
			if up <= 0.0:
				continue
			# Each band grows out to its place as it comes up, rather than just being there.
			var grown := lerpf(0.72, 1.0, ease(up, 0.4))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * grown)
			draw_polyline(_lines[i], Color(_inks[i], _inks[i].a * up), 0.8, true)
		draw_set_transform(Vector2.ZERO)


## The sunburst's beams and the rays between them, drawn once round its own middle, fading out to
## nothing at its edge, and turned as a whole, a [Node2D] for the same reason as the [Seal].
class Sunburst:
	extends Node2D

	## How far out the beams go, and where the rays start.
	var reach := 0.0
	var rays_from := 0.0

	func lay(out: float, from: float) -> void:
		reach = out
		rays_from = from
		queue_redraw()

	## How strong the light is [param out] from the middle, as a share of its strength there.
	static func light_at(out: float, reach_of: float) -> float:
		if reach_of <= 0.0:
			return 0.0
		return 1.0 - smoothstep(TitleBackground.SOLID, 1.0, out / reach_of)

	## The beams and the rays as one array of triangles, a single draw rather than one for every
	## piece of every beam and every ray, laid once and turned whole.
	func _draw() -> void:
		if reach <= 0.0:
			return
		var points := PackedVector2Array()
		var inks := PackedColorArray()
		var corners := PackedInt32Array()
		_lay_beams(points, inks, corners)
		# The rays start clear of the seal, where the mark's rings end, and fade out with the beams.
		if rays_from < reach:
			_lay_rays(points, inks, corners)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), corners, points, inks)

	## Each beam a strip of quads out from the middle, each step out fainter, see [method light_at].
	func _lay_beams(
		points: PackedVector2Array, inks: PackedColorArray, corners: PackedInt32Array
	) -> void:
		var middle := Vector2.ZERO
		var steps := TitleBackground.FADE_STEPS
		var light := TitleBackground.LIGHT
		for i: int in TitleBackground.BEAMS:
			var from := Vector2.from_angle(TAU * i / TitleBackground.BEAMS)
			var to := Vector2.from_angle(
				TAU * (i + TitleBackground.BEAM_WIDTH) / TitleBackground.BEAMS
			)
			var first := points.size()
			for step: int in steps + 1:
				var out := reach * float(step) / float(steps)
				var ink := Color(light, light.a * light_at(out, reach))
				points.append_array([middle + from * out, middle + to * out])
				inks.append_array([ink, ink])
			for step: int in steps:
				var at := first + step * 2
				corners.append_array([at, at + 2, at + 3, at, at + 3, at + 1])

	## Each ray a line of ink down its middle fading to nothing [constant RAY_SOFT] either side, so
	## it is soft at the edges as a smoothed line is, without being one.
	func _lay_rays(
		points: PackedVector2Array, inks: PackedColorArray, corners: PackedInt32Array
	) -> void:
		var middle := Vector2.ZERO
		var steps := TitleBackground.FADE_STEPS
		var ink := TitleBackground.RAY_INK
		var clear := Color(ink, 0.0)
		for i: int in TitleBackground.RAYS:
			var way := Vector2.from_angle(TAU * i / TitleBackground.RAYS)
			var side := way.orthogonal() * TitleBackground.RAY_SOFT
			var first := points.size()
			for step: int in steps + 1:
				var out := lerpf(rays_from, reach, float(step) / float(steps))
				var on := middle + way * out
				var strong := ink.a * TitleBackground.RAY_MIDDLE * light_at(out, reach)
				points.append_array([on + side, on, on - side])
				inks.append_array([clear, Color(ink, strong), clear])
			for step: int in steps:
				var at := first + step * 3
				corners.append_array(
					[
						at,
						at + 1,
						at + 4,
						at,
						at + 4,
						at + 3,
						at + 1,
						at + 2,
						at + 5,
						at + 1,
						at + 5,
						at + 4
					]
				)


var _rng := RandomNumberGenerator.new()


static func add_to(screen: Control) -> TitleBackground:
	var back := TitleBackground.new()
	back.name = "Background"
	screen.add_child(back)
	# Over the flat color the menu lays down, under everything anybody came here to read.
	screen.move_child(back, 1)
	return back


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The chips under the burst and the seal, each a picture of its face moved, turned and faded a
	# frame, rather than its notches, ring and flecks drawn again every frame.
	var held := Node2D.new()
	held.name = "Chips"
	add_child(held)
	_burst = Sunburst.new()
	_burst.name = "Sunburst"
	add_child(_burst)
	_seal = Seal.new()
	_seal.name = "Seal"
	_seal.visible = false
	_seal.shown = rings
	add_child(_seal)
	var light := Gradient.new()
	light.set_color(0, GLOW)
	light.set_color(1, Color(GLOW, 0.0))
	light.add_point(0.45, Color(GLOW, GLOW.a * 0.35))
	_glow = GradientTexture2D.new()
	_glow.gradient = light
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)
	_glow.width = 256
	_glow.height = 256
	_rng.seed = 20260919
	for i: int in CHIPS:
		var radius := _rng.randf_range(CHIP_RADIUS.x, CHIP_RADIUS.y)
		(
			_chips
			. append(
				{
					"x": _rng.randf(),
					"phase": _rng.randf(),
					"radius": radius,
					"seconds": _rng.randf_range(CHIP_SECONDS.x, CHIP_SECONDS.y),
					"spin": _turns(CHIP_SPIN, i),
				}
			)
		)
		var sprite := Sprite2D.new()
		sprite.region_enabled = true
		var color := i % Palette.PLAYER_COLORS.size()
		sprite.region_rect = Rect2(CHIP_CELL * color, 0.0, CHIP_CELL, CHIP_CELL)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.scale = Vector2.ONE * radius / (CHIP_CELL * 0.5 - 1.0)
		sprite.visible = false
		held.add_child(sprite)
		_sprites.append(sprite)
	for i: int in CARDS:
		var across := _rng.randf_range(CARD_SCALE.x, CARD_SCALE.y)
		(
			_cards
			. append(
				{
					"x": _rng.randf(),
					"phase": _rng.randf(),
					"scale": across,
					"seconds": _rng.randf_range(CARD_SECONDS.x, CARD_SECONDS.y),
					"spin": _turns(CARD_SPIN, i),
				}
			)
		)
		var back := Sprite2D.new()
		back.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		back.scale = Vector2.ONE * across / float(BACK_PIXELS)
		back.visible = false
		held.add_child(back)
		_backs.append(back)
	_paint_faces()
	_paint_back()


## How far the [param index]th chip or card turns on its way up: somewhere in [param turns], one
## way for the even ones and the other for the odd.
func _turns(turns: Vector2, index: int) -> float:
	return _rng.randf_range(turns.x, turns.y) * (1.0 if index % 2 == 0 else -1.0)


func _process(delta: float) -> void:
	_spin = fmod(_spin + TAU * delta / TURN_SECONDS, TAU)
	for chip: Dictionary in _chips + _cards:
		chip["phase"] = fmod(float(chip["phase"]) + delta / float(chip["seconds"]), 1.0)
	_place_burst()
	_place_seal(delta)
	_place_chips()
	var lit := Rect2(focus(), Vector2(size.length() * GLOW_REACH, glow))
	if lit != _glowed:
		_glowed = lit
		queue_redraw()


## The chips' faces, the seat cards' own, see [ChipArt], drawn once a run into a sheet a face a
## player color, and copied out of it with smaller copies of itself the frame it is drawn, so a
## small chip is a smaller copy rather than every few pixels of a big one. Until then, and where
## nothing is drawn, they are shown from the sheet as it is.
func _paint_faces() -> void:
	if _faces != null:
		_wear(_faces)
		return
	var colors := Palette.PLAYER_COLORS
	var sheet := Control.new()
	sheet.draw.connect(
		func() -> void:
			for i: int in colors.size():
				var middle := Vector2((float(i) + 0.5) * CHIP_CELL, CHIP_CELL * 0.5)
				ChipArt.chip(sheet, middle, CHIP_CELL * 0.5 - 1.0, colors[i])
	)
	var drawn := DrawnTexture.of(self, sheet, Vector2i(CHIP_CELL * colors.size(), CHIP_CELL))
	_wear(drawn)
	RenderingServer.frame_post_draw.connect(_keep_faces.bind(drawn), CONNECT_ONE_SHOT)


func _keep_faces(drawn: ViewportTexture) -> void:
	var image := drawn.get_image()
	var middle := Vector2i(CHIP_CELL / 2, CHIP_CELL / 2)
	if image == null or image.is_empty() or image.get_pixelv(middle).a < 0.5:
		_face_tries += 1
		if _face_tries < FACE_TRIES:
			RenderingServer.frame_post_draw.connect(_keep_faces.bind(drawn), CONNECT_ONE_SHOT)
		return
	image.generate_mipmaps()
	_faces = ImageTexture.create_from_image(image)
	_wear(_faces)
	var sheet := get_node_or_null("Drawn")
	if sheet != null:
		sheet.queue_free()


## The back the profile playing wears, see [method CardBack.worn], drawn once a run for each back
## into a picture the cards wear, as the chips' faces are, without the question mark of a card not
## known yet or the shadow of one lying on a screen; until then they are not shown.
func _paint_back() -> void:
	var style := CardBack.worn()
	if _drawn_backs.has(style):
		_wear_back(_drawn_backs[style])
		return
	var pixels := Vector2i(JokerCard.SIZE * BACK_PIXELS)
	var sheet := Control.new()
	var scaled := Node2D.new()
	scaled.scale = Vector2.ONE * BACK_PIXELS
	sheet.add_child(scaled)
	var back := CardBack.new(style, false)
	var look := (back.get_theme_stylebox(&"panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	look.shadow_size = 0
	back.add_theme_stylebox_override(&"panel", look)
	scaled.add_child(back)
	var drawn := DrawnTexture.of(self, sheet, pixels)
	_back_sheet = get_child(get_child_count() - 1)
	RenderingServer.frame_post_draw.connect(_keep_back.bind(drawn, style), CONNECT_ONE_SHOT)


func _keep_back(drawn: ViewportTexture, style: int) -> void:
	if not is_inside_tree():
		return
	var image := drawn.get_image()
	var middle := Vector2i(JokerCard.SIZE * BACK_PIXELS * 0.5)
	if image == null or image.is_empty() or image.get_pixelv(middle).a < 0.5:
		_back_tries += 1
		if _back_tries < FACE_TRIES:
			RenderingServer.frame_post_draw.connect(_keep_back.bind(drawn, style), CONNECT_ONE_SHOT)
		return
	image.generate_mipmaps()
	_drawn_backs[style] = ImageTexture.create_from_image(image)
	_wear_back(_drawn_backs[style])
	if _back_sheet != null:
		_back_sheet.queue_free()
		_back_sheet = null


func _wear_back(back: Texture2D) -> void:
	for sprite: Sprite2D in _backs:
		sprite.texture = back


func _wear(faces: Texture2D) -> void:
	for sprite: Sprite2D in _sprites:
		sprite.texture = faces


## Each chip on its way up the screen, turning as it goes and fading toward the mark, see
## [method chip_strength]; out of sight where it has faded away.
func _place_chips() -> void:
	var center := focus()
	var out := reach()
	var up := clampf(beams, 0.0, 1.0)
	for i: int in _chips.size():
		var chip := _chips[i]
		var sprite := _sprites[i]
		var phase := float(chip["phase"])
		var radius := float(chip["radius"])
		var at := Vector2(
			float(chip["x"]) * size.x, (1.0 - phase) * (size.y + radius * 4.0) - radius * 2.0
		)
		var strong := CHIP_ALPHA * _strength(at, center, out) * up
		sprite.visible = strong >= 0.005
		if not sprite.visible:
			continue
		sprite.position = at
		sprite.rotation = phase * TAU * float(chip["spin"])
		sprite.modulate.a = strong
	for i: int in _cards.size():
		var card := _cards[i]
		var back := _backs[i]
		var phase := float(card["phase"])
		var tall := JokerCard.SIZE.y * float(card["scale"])
		var at := Vector2(float(card["x"]) * size.x, (1.0 - phase) * (size.y + tall * 2.0) - tall)
		var strong := CARD_ALPHA * _strength(at, center, out) * up
		back.visible = strong >= 0.005 and back.texture != null
		if not back.visible:
			continue
		back.position = at
		back.rotation = phase * TAU * float(card["spin"])
		back.modulate.a = strong


## Where the burst and the seal are centered: the mark's middle while it is up, else the middle of
## [constant CENTER].
func focus() -> Vector2:
	if _shows_mark():
		return anchor.get_global_rect().get_center() - global_position
	return size * CENTER


## How far the burst reaches from [method focus]: short of the screen's sides and its foot, see
## [constant REACH]. The top it may run off, since the mark is near it.
func reach() -> float:
	var at := focus()
	return maxf(minf(minf(at.x, size.x - at.x), size.y - at.y), 0.0) * REACH


func _shows_mark() -> bool:
	return anchor != null and is_instance_valid(anchor) and anchor.is_visible_in_tree()


## Half the mark's width, or what it would be, for where the seal and the rays start.
func _mark_radius() -> float:
	if anchor != null and is_instance_valid(anchor) and anchor.size.x > 0.0:
		return anchor.size.x * 0.5
	return 66.0


## The burst round the mark, laid out again whenever how far it reaches changes, turned a little
## further each frame, and swept out from the mark as [member beams] comes up.
func _place_burst() -> void:
	var out := reach()
	var from := _mark_radius() * RAY_FROM
	if not is_equal_approx(out, _burst.reach) or not is_equal_approx(from, _burst.rays_from):
		_burst.lay(out, from)
	_burst.position = focus()
	_burst.rotation = _spin
	var up := ease(clampf(beams, 0.0, 1.0), 0.5)
	_burst.visible = beams > 0.0
	_burst.scale = Vector2.ONE * lerpf(0.2, 1.0, up)
	_burst.modulate.a = clampf(beams * 1.5, 0.0, 1.0)


## The seal round the mark, turned a little further each frame; gone with the mark on a screen too
## short for it.
func _place_seal(delta: float) -> void:
	var shown := _shows_mark()
	_seal.visible = shown and rings > 0.0
	if not shown:
		return
	var mark := anchor.size.x * 0.5
	if not is_equal_approx(mark, _sealed_for) and mark > 0.0:
		_sealed_for = mark
		_seal.lay(mark)
	_seal.position = focus()
	_seal.rotation = fmod(_seal.rotation + TAU * delta / SEAL_TURN, TAU)


## How strong a chip [param at] is, out of [constant CHIP_ALPHA]: none near the mark, all of it out
## at the edges, see [constant CHIP_CLEAR].
func chip_strength(at: Vector2) -> float:
	return _strength(at, focus(), reach())


static func _strength(at: Vector2, center: Vector2, out: float) -> float:
	if out <= 0.0:
		return 1.0
	return smoothstep(CHIP_CLEAR.x, CHIP_CLEAR.y, at.distance_to(center) / out)


## The glow round the mark, drawn again only when it moves or changes, see [method _process].
func _draw() -> void:
	if glow <= 0.0:
		return
	var lit := size.length() * GLOW_REACH
	draw_texture_rect(
		_glow,
		Rect2(focus() - Vector2.ONE * lit, Vector2.ONE * lit * 2.0),
		false,
		Color(1.0, 1.0, 1.0, glow)
	)
