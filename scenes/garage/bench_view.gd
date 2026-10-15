class_name BenchView
extends CloseLook
## The close look at the Garage's test bench, GAME.md 9.4, see [TestBench]: the board filmed from
## in front of it, the camera easing in on it, at the left of the screen, away from the rolling road
## on the right, see [CloseLook]. Up while a kart is on the rolling road and for a few seconds after
## a time is set on it or through the speed trap, titled for which of the two it was, the board
## having its own name on it, with what was timed in the line under it.

const PIXELS := Vector2i(520, 330)
const SHOWN := Vector2(560.0, 470.0)
## How the camera sees the board: straight on from in front of the middle of its face, as wide as
## [constant FOV], from far enough off that the whole board in its frame fills the picture but for
## [constant MARGIN] round it, easing in over [constant EASE_IN] seconds from [constant WIDER] as
## far again; and no further than the board and what is round it.
const FOV := 34.0
const MARGIN := 0.08
const WIDER := 0.15
const EASE_IN := 3.0
const FAR := 14.0

var bench: TestBench
var _time := 0.0
var _title := ""
var _line := ""


## The look at [param on_bench], titled [param title] and saying [param line] under it.
static func of(on_bench: TestBench, title: String, line: String) -> BenchView:
	var view := BenchView.new()
	view.name = "BenchView"
	view.bench = on_bench
	view._title = title
	view._line = line
	return view


func _ready() -> void:
	_build(_title, _line, PIXELS, SHOWN, true, FAR)
	_frame()


## Titles the look [param title] and says [param line] under the picture, about the time just set.
func say(title: String, line: String) -> void:
	_title = title
	_line = line
	if heading != null:
		heading.text = title
		under.text = line


func _process(delta: float) -> void:
	_time += delta
	_frame()


## The camera in front of the board's face, so far into easing in, looking at its middle.
func _frame() -> void:
	if camera == null or bench == null or bench.face == null:
		return
	var face := bench.face
	var middle := face.global_position
	var moved := ease(clampf(_time / EASE_IN, 0.0, 1.0), -1.6)
	var off := fit() * (1.0 + WIDER * (1.0 - moved))
	camera.fov = FOV
	camera.look_at_from_position(middle + face.global_basis.z * off, middle, Vector3.UP)


## How far in front of the board the camera stands to have all of it in the picture, its frame
## and [constant MARGIN] round it, whichever of its width and its height needs it further off.
static func fit() -> float:
	var board := TestBench.FACE + Vector2.ONE * TestBench.FRAME * 2.0
	var high := tan(deg_to_rad(FOV) * 0.5)
	var wide := high * float(PIXELS.x) / float(PIXELS.y)
	var for_height := board.y * (1.0 + MARGIN) * 0.5 / high
	var for_width := board.x * (1.0 + MARGIN) * 0.5 / wide
	return maxf(for_height, for_width)
