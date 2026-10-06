class_name TitleBackground
extends Control
## What is behind the title screen, GAME.md 8.1: a slow carnival sunburst turning behind the
## name, narrow beams of foil light with fine rays engraved between them over a glow round the
## mark, and poker chips drifting up past it.
##
## Drawn rather than modeled. The menu is a flat screen and the game behind it is not running,
## so a scene would be a scene loaded to be looked at once; this is a few polygons a frame and
## nothing to load. Dark on purpose: the point of the screen is the words on it. The wedges are
## light laid over the backdrop rather than two tones of their own, so the engraving of the
## house's stock, GAME.md 8.1a, shows through the whole of the burst rather than being painted out.

## The sunburst, GAME.md 8.1a: beams of foil light, narrow, with the backdrop between them, how
## much of each beam's share of the turn is lit, and how long one full turn takes.
const BEAMS := 48
const BEAM_WIDTH := 0.3
const TURN_SECONDS := 90.0
const LIGHT := Color(Palette.CHIP_GOLD, 0.03)
## The rays engraved between the beams and turning with them: how many, how strong, and how far
## out from the mark they start, in the mark's radii, clear of the seal.
const RAYS := 192
const RAY_INK := Color(Palette.CHIP_GOLD, 0.045)
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
## How many chips drift past, how big they are, and how long one takes to cross the screen.
const CHIPS := 16
const CHIP_RADIUS := Vector2(18.0, 46.0)
const CHIP_SECONDS := Vector2(26.0, 55.0)
const CHIP_ALPHA := 0.13

## What the burst and the seal are centered on, the mark over the name; nothing for the middle
## of [constant CENTER].
var anchor: Control

var _spin := 0.0
var _glow: GradientTexture2D
var _chips: Array[Dictionary] = []
var _seal: Seal
var _sealed_for := 0.0


## The seal's rings, drawn once round its own middle and turned as a whole.
class Seal:
	extends Control

	var _lines: Array[PackedVector2Array] = []
	var _inks: Array[Color] = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Laid out round a mark [param mark] out from its middle.
	func lay(mark: float) -> void:
		var reach := mark * 4.8
		size = Vector2.ONE * reach * 2.0
		pivot_offset = size * 0.5
		_lines.clear()
		_inks.clear()
		for band: Array in TitleBackground.SEAL_BANDS:
			var rings := Engraving.rings(
				size * 0.5,
				mark * float(band[0]),
				mark * float(band[1]),
				band[2],
				band[3],
				int(band[2]) * 9
			)
			_lines.append_array(rings)
			for ring: PackedVector2Array in rings:
				_inks.append(Color(HouseTheme.FOIL, float(band[4])))
		queue_redraw()

	func _draw() -> void:
		for i: int in _lines.size():
			draw_polyline(_lines[i], _inks[i], 0.8, true)


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
	_seal = Seal.new()
	_seal.name = "Seal"
	_seal.visible = false
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
	_place_seal(delta)
	queue_redraw()


## Where the burst and the seal are centered: the mark's middle while it is up, else the middle of
## [constant CENTER].
func focus() -> Vector2:
	if anchor != null and is_instance_valid(anchor) and anchor.is_visible_in_tree():
		return anchor.get_global_rect().get_center() - global_position
	return size * CENTER


## The seal round the mark, turned a little further each frame; gone with the mark on a screen too
## short for it.
func _place_seal(delta: float) -> void:
	var shown := anchor != null and is_instance_valid(anchor) and anchor.is_visible_in_tree()
	_seal.visible = shown
	if not shown:
		return
	var mark := anchor.size.x * 0.5
	if not is_equal_approx(mark, _sealed_for) and mark > 0.0:
		_sealed_for = mark
		_seal.lay(mark)
	_seal.position = focus() - _seal.size * 0.5
	_seal.rotation = fmod(_seal.rotation + TAU * delta / SEAL_TURN, TAU)


func _draw() -> void:
	var center := focus()
	var reach := size.length()
	var glow := reach * GLOW_REACH
	draw_texture_rect(_glow, Rect2(center - Vector2.ONE * glow, Vector2.ONE * glow * 2.0), false)
	for i: int in BEAMS:
		var from := _spin + TAU * i / BEAMS
		var to := from + TAU / BEAMS * BEAM_WIDTH
		draw_colored_polygon(
			PackedVector2Array(
				[
					center,
					center + Vector2(cos(from), sin(from)) * reach,
					center + Vector2(cos(to), sin(to)) * reach
				]
			),
			LIGHT
		)
	# The rays start clear of the seal, where the mark's rings end, and run off the screen.
	var mark := anchor.size.x * 0.5 if anchor != null and is_instance_valid(anchor) else 66.0
	var start := mark * RAY_FROM
	var rays := PackedVector2Array()
	for i: int in RAYS:
		var way := Vector2.from_angle(_spin + TAU * i / RAYS)
		rays.append(center + way * start)
		rays.append(center + way * reach)
	draw_multiline(rays, RAY_INK, 0.6, true)
	for chip: Dictionary in _chips:
		_draw_chip(chip)


## One chip on its way up the screen, turning as it goes.
func _draw_chip(chip: Dictionary) -> void:
	var phase := float(chip["phase"])
	var radius := float(chip["radius"])
	var at := Vector2(
		float(chip["x"]) * size.x, (1.0 - phase) * (size.y + radius * 4.0) - radius * 2.0
	)
	var color: Color = chip["color"]
	var face := Color(color, CHIP_ALPHA)
	draw_circle(at, radius, face)
	draw_arc(at, radius * 0.78, 0.0, TAU, 24, Color(color, CHIP_ALPHA * 1.6), radius * 0.1)
	# The notches round the rim of a poker chip, turning with it.
	var spin := phase * TAU * float(chip["spin"])
	for i: int in 6:
		var angle := spin + TAU * i / 6.0
		var edge := at + Vector2(cos(angle), sin(angle)) * radius * 0.9
		draw_circle(edge, radius * 0.12, Color(color, CHIP_ALPHA * 1.8))
