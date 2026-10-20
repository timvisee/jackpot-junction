class_name ScreenPrint
extends Node
## A print a table wears drawn for the screen, GAME.md 8.1b: as finely as the Texture detail
## setting asks for the screens there are, see [method LayoutPrint.screen_scale], and drawn again
## at once when that is changed, a match on or not, since the setting is there to hand video
## memory back. It stands under whatever wears the print, and goes with it.

const GROUP := &"screen_prints"

## What the print is drawn from, made anew each time it is drawn: a control the drawing goes
## with; its size as it is laid out; what is handed the picture once drawn; and how many times as
## finely as the screen asks it is drawn, for a print laid out coarser than the floor's.
var _make: Callable
var _pixels := Vector2i.ZERO
var _keep: Callable
var _finer := 1.0
## How finely it was last drawn, nothing before the first time.
var _scale := 0.0


## Draws what [param make] makes, laid out at [param pixels], under [param host] for the screen,
## [param finer] times as finely, see [method DrawnTexture.kept], and hands [param keep] the
## picture; and again whenever the setting changes how finely, see [method redraw].
static func lay(
	host: Node, make: Callable, pixels: Vector2i, keep: Callable, finer := 1.0
) -> ScreenPrint:
	var made := ScreenPrint.new()
	made.name = "ScreenPrint"
	made._make = make
	made._pixels = pixels
	made._keep = keep
	made._finer = finer
	host.add_child(made)
	made.draw()
	return made


## Every print in [param tree] drawn again that the setting has it drawn at another size now.
static func redraw(tree: SceneTree) -> void:
	tree.call_group(GROUP, &"draw")


## How many times as many pixels a side it was last drawn at, see [method lay].
func drawn_at() -> float:
	return _scale


## Drawn under its host at the size the setting asks for now, unless that is the size it is.
## Drawn half again as finely or more, two samples a pixel leave it as smooth as four did at its
## own size, see [constant LayoutPrint.SMOOTH_FINER].
func draw() -> void:
	var host := get_parent()
	var wanted := LayoutPrint.screen_scale(_pixels) * _finer
	if host == null or is_equal_approx(wanted, _scale):
		return
	_scale = wanted
	var smooth := LayoutPrint.SMOOTH if wanted < 1.5 else LayoutPrint.SMOOTH_FINER
	DrawnTexture.kept(host, _make.call(), _pixels, _keep, smooth, wanted)


func _ready() -> void:
	add_to_group(GROUP)
