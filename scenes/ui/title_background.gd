class_name TitleBackground
extends Control
## What is behind the title screen, GAME.md 8.1: a slow carnival sunburst turning behind the
## name, and poker chips drifting up past it.
##
## Drawn rather than modeled. The menu is a flat screen and the game behind it is not running,
## so a scene would be a scene loaded to be looked at once; this is a few polygons a frame and
## nothing to load. Dark on purpose: the point of the screen is the words on it.

## Wedges in the sunburst, and how long one full turn takes.
const WEDGES := 18
const TURN_SECONDS := 90.0
const DARK := Color(0.10, 0.10, 0.13)
const LIGHT := Color(0.13, 0.13, 0.17)
## Where the burst is centered, as a share of the screen: behind the title rather than the middle.
const CENTER := Vector2(0.5, 0.34)
## How many chips drift past, how big they are, and how long one takes to cross the screen.
const CHIPS := 16
const CHIP_RADIUS := Vector2(18.0, 46.0)
const CHIP_SECONDS := Vector2(26.0, 55.0)
const CHIP_ALPHA := 0.13

var _spin := 0.0
var _chips: Array[Dictionary] = []
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
	queue_redraw()


func _draw() -> void:
	var center := size * CENTER
	var reach := size.length()
	for i: int in WEDGES:
		var from := _spin + TAU * i / WEDGES
		var to := from + TAU / WEDGES * 0.5
		draw_colored_polygon(
			PackedVector2Array(
				[
					center,
					center + Vector2(cos(from), sin(from)) * reach,
					center + Vector2(cos(to), sin(to)) * reach
				]
			),
			LIGHT if i % 2 == 0 else DARK
		)
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
