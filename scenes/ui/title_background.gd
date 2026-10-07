class_name TitleBackground
extends Control
## What is behind the title screen, GAME.md 8.1: a slow carnival sunburst turning behind the
## name, narrow beams of foil light with fine rays engraved between them over a glow round the
## mark, fading out well before the screen's sides and foot, and poker chips drifting up past it,
## out at the edges and gone near the mark.
##
## Drawn rather than modeled. The menu is a flat screen and the game behind it is not running,
## so a scene would be a scene loaded to be looked at once; this is a few polygons a frame and
## nothing to load. Dark on purpose: the point of the screen is the words on it. The wedges are
## light laid over the backdrop rather than two tones of their own, so the engraving of the
## house's stock, GAME.md 8.1a, shows through the whole of the burst rather than being painted out.

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
const CHIP_ALPHA := 0.18
const CHIP_CLEAR := Vector2(0.45, 1.05)

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
var _chips: Array[Dictionary] = []
var _seal: Seal
var _sealed_for := 0.0
var _burst: Sunburst


## The seal's rings, drawn once round its own middle and turned as a whole; each band comes up out
## of the mark in its turn as [member shown] goes from 0 to 1.
class Seal:
	extends Control

	var shown := 1.0:
		set(value):
			shown = value
			queue_redraw()

	var _lines: Array[PackedVector2Array] = []
	var _inks: Array[Color] = []
	var _bands: PackedInt32Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Laid out round a mark [param mark] out from its middle.
	func lay(mark: float) -> void:
		var reach := mark * 4.8
		size = Vector2.ONE * reach * 2.0
		pivot_offset = size * 0.5
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
			draw_set_transform(size * 0.5, 0.0, Vector2.ONE * grown)
			draw_polyline(_lines[i], Color(_inks[i], _inks[i].a * up), 0.8, true)
		draw_set_transform(Vector2.ZERO)


## The sunburst's beams and the rays between them, drawn once round its own middle, fading out to
## nothing at its edge, and turned as a whole.
class Sunburst:
	extends Control

	## How far out the beams go, and where the rays start.
	var reach := 0.0
	var rays_from := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func lay(out: float, from: float) -> void:
		reach = out
		rays_from = from
		size = Vector2.ONE * out * 2.0
		pivot_offset = size * 0.5
		queue_redraw()

	## How strong the light is [param out] from the middle, as a share of its strength there.
	static func light_at(out: float, reach_of: float) -> float:
		if reach_of <= 0.0:
			return 0.0
		return 1.0 - smoothstep(TitleBackground.SOLID, 1.0, out / reach_of)

	func _draw() -> void:
		if reach <= 0.0:
			return
		var middle := size * 0.5
		var steps := TitleBackground.FADE_STEPS
		for i: int in TitleBackground.BEAMS:
			var from := Vector2.from_angle(TAU * i / TitleBackground.BEAMS)
			var to := Vector2.from_angle(
				TAU * (i + TitleBackground.BEAM_WIDTH) / TitleBackground.BEAMS
			)
			for step: int in steps:
				var near := reach * float(step) / float(steps)
				var far := reach * float(step + 1) / float(steps)
				var inner := TitleBackground.LIGHT.a * light_at(near, reach)
				var outer := TitleBackground.LIGHT.a * light_at(far, reach)
				draw_polygon(
					PackedVector2Array(
						[
							middle + from * near,
							middle + from * far,
							middle + to * far,
							middle + to * near
						]
					),
					PackedColorArray(
						[
							Color(TitleBackground.LIGHT, inner),
							Color(TitleBackground.LIGHT, outer),
							Color(TitleBackground.LIGHT, outer),
							Color(TitleBackground.LIGHT, inner)
						]
					)
				)
		# The rays start clear of the seal, where the mark's rings end, and fade out with the beams.
		if rays_from >= reach:
			return
		for i: int in TitleBackground.RAYS:
			var way := Vector2.from_angle(TAU * i / TitleBackground.RAYS)
			var line := PackedVector2Array()
			var inks := PackedColorArray()
			for step: int in steps + 1:
				var out := lerpf(rays_from, reach, float(step) / float(steps))
				line.append(middle + way * out)
				inks.append(
					Color(TitleBackground.RAY_INK, TitleBackground.RAY_INK.a * light_at(out, reach))
				)
			draw_polyline_colors(line, inks, 0.6, true)


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
		(
			_chips
			. append(
				{
					"x": _rng.randf(),
					"phase": _rng.randf(),
					"radius": _rng.randf_range(CHIP_RADIUS.x, CHIP_RADIUS.y),
					"seconds": _rng.randf_range(CHIP_SECONDS.x, CHIP_SECONDS.y),
					"color": Palette.PLAYER_COLORS[i % Palette.PLAYER_COLORS.size()],
					"spin": _rng.randf_range(-0.6, 0.6),
				}
			)
		)


func _process(delta: float) -> void:
	_spin = fmod(_spin + TAU * delta / TURN_SECONDS, TAU)
	for chip: Dictionary in _chips:
		chip["phase"] = fmod(float(chip["phase"]) + delta / float(chip["seconds"]), 1.0)
	_place_burst()
	_place_seal(delta)
	queue_redraw()


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
	_burst.position = focus() - _burst.size * 0.5
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
	_seal.position = focus() - _seal.size * 0.5
	_seal.rotation = fmod(_seal.rotation + TAU * delta / SEAL_TURN, TAU)


## How strong a chip [param at] is, out of [constant CHIP_ALPHA]: none near the mark, all of it out
## at the edges, see [constant CHIP_CLEAR].
func chip_strength(at: Vector2) -> float:
	var out := reach()
	if out <= 0.0:
		return 1.0
	return smoothstep(CHIP_CLEAR.x, CHIP_CLEAR.y, at.distance_to(focus()) / out)


func _draw() -> void:
	if glow > 0.0:
		var center := focus()
		var lit := size.length() * GLOW_REACH
		draw_texture_rect(
			_glow,
			Rect2(center - Vector2.ONE * lit, Vector2.ONE * lit * 2.0),
			false,
			Color(1.0, 1.0, 1.0, glow)
		)
	if beams <= 0.0:
		return
	for chip: Dictionary in _chips:
		_draw_chip(chip)


## One chip on its way up the screen, turning as it goes.
func _draw_chip(chip: Dictionary) -> void:
	var phase := float(chip["phase"])
	var radius := float(chip["radius"])
	var at := Vector2(
		float(chip["x"]) * size.x, (1.0 - phase) * (size.y + radius * 4.0) - radius * 2.0
	)
	var strong := CHIP_ALPHA * chip_strength(at) * clampf(beams, 0.0, 1.0)
	if strong < 0.005:
		return
	var color: Color = chip["color"]
	draw_set_transform(at, phase * TAU * float(chip["spin"]))
	ChipArt.chip(self, Vector2.ZERO, radius, Color(color, strong))
	draw_set_transform(Vector2.ZERO)
