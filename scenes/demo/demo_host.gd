class_name DemoHost
extends Node
## The demo for a booth as it runs, GAME.md 9.8, under [Game] for as long as the game does, from
## room to room: the first run dealt once the shaders have compiled behind the title, and the next
## after the title has stood between runs for [constant TITLE_SECONDS]. [Game] makes it from its
## path, see [constant Game.DEMO_HOST], and never names it.

## How long the title stands between runs, in seconds.
const TITLE_SECONDS := 10.0
## How long the mouse pointer stays up after the mouse last moved, in seconds.
const POINTER_REST := 3.0

var rng := RandomNumberGenerator.new()

## The title being waited on, and how long until the next run is dealt from it.
var _title: Node
var _title_left := 0.0
## Whether no run has been dealt yet: the first comes as soon as the shaders are compiled.
var _first := true
## The line saying how to play, in whichever room is up.
var _line: DemoLine
## How long until the mouse pointer is hidden again.
var _pointer_left := 0.0


func _ready() -> void:
	name = "DemoHost"
	# On through the pause menu's pause, which it puts away by itself, GAME.md 9.8.
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _process(delta: float) -> void:
	if not Demo.playing():
		return
	_rest_the_pointer(delta)
	var scene := get_tree().current_scene
	if scene == null:
		return
	_place_the_line(scene)
	if scene.scene_file_path == Game.TITLE_SCENE:
		if title_done(scene, delta):
			deal()
	else:
		_title = null


func _input(event: InputEvent) -> void:
	if Demo.playing() and event is InputEventMouseMotion:
		_pointer_left = POINTER_REST
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## The pointer hidden while the demo plays, and up again for a moment whenever the mouse moves.
func _rest_the_pointer(delta: float) -> void:
	if _pointer_left <= 0.0:
		return
	_pointer_left -= delta
	if _pointer_left <= 0.0:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


## The line in [param scene], the title or a match's HUD.
func _place_the_line(scene: Node) -> void:
	var home := line_home(scene)
	if home == null:
		return
	if _line == null or not is_instance_valid(_line) or _line.get_parent() != home:
		_line = DemoLine.add_to(home)


## Where the line goes in [param scene]: the title itself, or a match's HUD, or nowhere.
static func line_home(scene: Node) -> Node:
	if scene.scene_file_path == Game.TITLE_SCENE:
		return scene
	var match_node := scene.get_node_or_null("Match") as Match
	if match_node != null and match_node.hud != null:
		return match_node.hud
	return null


## Whether [param title] has stood long enough, [param delta] seconds on, for the next run to be
## dealt from it: once its shaders are compiled, at once the first time and after
## [constant TITLE_SECONDS] between runs.
func title_done(title: Node, delta: float) -> bool:
	if title != _title:
		_title = title
		_title_left = 0.0 if _first else TITLE_SECONDS
	# The shaders compile behind the title first, GAME.md 10.7.
	if title.get(&"warming") != null:
		return false
	_title_left -= delta
	return _title_left <= 0.0


## Deals a run and goes to its first map.
func deal() -> void:
	_first = false
	_title = null
	Game.start_match(DemoRun.deal(rng))
