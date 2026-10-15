class_name BenchView
extends CloseLook
## The close look at the Garage's test bench, GAME.md 9.4, see [TestBench]: the board filmed from
## in front of it, the camera easing in on it, at the left of the screen, away from the rolling road
## on the right, see [CloseLook]. Up while a kart is on the rolling road and for a few seconds after
## a time is set on it or through the speed trap, titled for which of the two it was, the board
## having its own name on it, with what was timed in the line under it.

const PIXELS := Vector2i(520, 330)
const SHOWN := Vector2(560.0, 470.0)
## Where the camera stands: how far out in front of the board's face, how much of that it eases in
## over [constant EASE_IN] seconds, how far up and along from the face's middle, and how wide it
## sees, no further than the board and what is round it.
const BACK := 2.8
const IN := 0.55
const UP := 0.12
const ALONG := 0.35
const FOV := 34.0
const FAR := 12.0
const EASE_IN := 3.0

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
	var out := face.global_basis.z
	var across := face.global_basis.x
	var moved := ease(clampf(_time / EASE_IN, 0.0, 1.0), -1.6)
	var from := (
		middle + out * (BACK - IN * moved) + Vector3.UP * UP + across * ALONG * (1.0 - moved)
	)
	camera.fov = FOV
	camera.look_at_from_position(from, middle, Vector3.UP)
