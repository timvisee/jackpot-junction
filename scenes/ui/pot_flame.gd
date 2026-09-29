class_name PotFlame
extends ColorRect
## The fire off one pill of a pot line that would win the match, GAME.md 3.4 and 8.3: a sheet of
## flames in the pill's own colors, blue off the chips and red off the mult, rising from behind it
## and licking up above it. Drawn by a shader rather than thrown as particles, in four bands of
## color with clean, smooth edges between them: a white heat deep in it, a pale core, a light
## shade of the pill's color and a darker rim.
##
## What makes it read as fire rather than as a jagged wall: each tongue is solid at its foot and
## thins out towards its tip rather than stopping flat; the higher up, the further it sways; the
## noise it is cut from rolls upward and folds over itself, so tongues split, curl and throw off
## scraps that rise on their own and go out; and a few embers climb out of the top and wink out.

## The shader the fire is drawn by, see [code]pot_flame.gdshader[/code] beside this script.
const SHADER: Shader = preload("res://scenes/ui/pot_flame.gdshader")
## How far above a pill the sheet reaches, in pill heights, the fire in it going out smoothly over
## the top [constant FADE] of that, and how much wider than the pill it is either side, as a share
## of the pill's width, for the tongues to sway into without reaching an edge. And after how many
## seconds its clock starts again: long enough that nobody sees it happen, short enough to keep
## the numbers small.
const REACH := 2.3
const FADE := 0.8
const MARGIN := 0.25
const CLOCK_WRAP := 900.0

var _clock := 0.0


## A sheet of fire in [param heart], [param core], [param body] and [param rim], from its hottest
## to its edge, on a beat of its own set by [param seed].
static func make(heart: Color, core: Color, body: Color, rim: Color, seed: float) -> PotFlame:
	var flame := PotFlame.new()
	flame.name = "Flame"
	flame.color = Color.WHITE
	flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look := ShaderMaterial.new()
	look.shader = SHADER
	look.set_shader_parameter(&"heart", heart)
	look.set_shader_parameter(&"core", core)
	look.set_shader_parameter(&"body", body)
	look.set_shader_parameter(&"rim", rim)
	look.set_shader_parameter(&"seed", seed)
	flame.material = look
	return flame


## The fire in the colors of a pill in [param ink], every band of it brighter than the pill so it
## glows against it rather than reading as more of it: nearly white deep in it, pale round that, a
## light shade of the pill's color, and the pill's own color darkened a little at the edge.
static func in_ink(ink: Color, seed: float) -> PotFlame:
	var heart := ink.lerp(Color.WHITE, 0.92)
	var core := ink.lerp(Color.WHITE, 0.68)
	return make(heart, core, ink.lerp(Color.WHITE, 0.32), ink.darkened(0.2), seed)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_clock = fmod(_clock + delta, CLOCK_WRAP)
	(material as ShaderMaterial).set_shader_parameter(&"clock", _clock)


## Lays the fire over [param rect], a pill's, and up above it by [constant REACH] of the pill's
## height, over the banked score above the pill, its foot behind the bottom of the pill so it
## rises out of it rather than off its top.
func cover(rect: Rect2) -> void:
	var side := rect.size.x * MARGIN
	position = rect.position - Vector2(side, rect.size.y * REACH)
	size = Vector2(rect.size.x + side * 2.0, rect.size.y * (REACH + 0.9))
	var look := material as ShaderMaterial
	look.set_shader_parameter(&"pixels", size)
	look.set_shader_parameter(&"span", REACH + 0.9)
	look.set_shader_parameter(&"fade", FADE)
	look.set_shader_parameter(&"margin", side / size.x)
	look.set_shader_parameter(&"lip", 0.9 / (REACH + 0.9))
