class_name DemoHost
extends Node
## The demo for a booth as it runs, GAME.md 9.8, under [Game] for as long as the game does, from
## room to room: the first run dealt once the shaders have compiled behind the title, and the next
## after the title has stood between runs for [constant TITLE_SECONDS]; somebody pressing a key or a
## button sat down, see [DemoSeats], and got up again once quiet; and the pause menu put away when
## nobody has touched anything for a while. [Game] makes it from its path, see
## [constant Game.DEMO_HOST], and never names it.

## How long the title stands between runs, in seconds.
const TITLE_SECONDS := 10.0
## How long the mouse pointer stays up after the mouse last moved, in seconds.
const POINTER_REST := 3.0
## How far a stick or a trigger has to go to be somebody touching it rather than its drift.
const PUSHED := 0.3
## What [method device_of] says for something that is no device's: a touch, say.
const NO_DEVICE := -100

var rng := RandomNumberGenerator.new()

## The title being waited on, and how long until the next run is dealt from it.
var _title: Node
var _title_left := 0.0
## Whether no run has been dealt yet: the first comes as soon as the shaders are compiled.
var _first := true
## The line saying how to play, and the hand hearing the presses, in whichever room is up.
var _line: DemoLine
var _hand: DemoHand
## The map last seen, so the bots' karts taken over at the map before are taken over again.
var _match: Match
## How long until the mouse pointer is hidden again.
var _pointer_left := 0.0
## How long since anybody touched anything at all.
var _quiet := 0.0
## The machine's settings as they were when a visitor left for the full game, and the profiles
## kept then, so what the visitor changed and made can be put back and thrown away.
var _kept: ConfigFile
var _profiles_before: Array[String] = []


func _ready() -> void:
	name = "DemoHost"
	# On through the pause menu's pause, which it puts away by itself, GAME.md 9.8.
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _process(delta: float) -> void:
	if not Demo.on:
		return
	_quiet += delta
	var scene := get_tree().current_scene
	if scene == null:
		return
	if _hand == null or not is_instance_valid(_hand) or _hand.get_parent() != scene:
		_hand = DemoHand.add_to(scene, self)
	elif _hand.get_index() != scene.get_child_count() - 1:
		# The last thing in the room is the first to hear.
		scene.move_child(_hand, -1)
	if Demo.away:
		wait_for_the_visitor()
		return
	_rest_the_pointer(delta)
	var match_node := scene.get_node_or_null("Match") as Match
	if match_node != _match and match_node != null and not match_node.slots.is_empty():
		_match = match_node
		DemoSeats.seat_again(match_node)
	DemoSeats.step(match_node, delta)
	_place_the_line(scene)
	if _quiet >= DemoSeats.IDLE and PauseMenu.is_open_in(get_tree()):
		get_tree().call_group(PauseMenu.GROUP, &"set_paused", false)
	if scene.scene_file_path == Game.TITLE_SCENE:
		if title_done(scene, delta):
			deal()
	else:
		_title = null


func _input(event: InputEvent) -> void:
	if Demo.playing() and event is InputEventMouseMotion:
		_pointer_left = POINTER_REST
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## [param event], heard before [param room] hears it, see [DemoHand]: anybody touching anything is
## not quiet, and a key or a button on a device nobody sits at sits somebody down, the first of the
## demo's seats or a bot's kart, or on the title the next run dealt at once with them in it. Escape
## is left to open the pause menu, and nothing sits anybody down while it is open. Whether the press
## was taken as sitting down, which nothing else then hears.
func heard(event: InputEvent, room: Node) -> bool:
	if not Demo.on:
		return false
	var device := device_of(event)
	if device == NO_DEVICE or not touches(event):
		return false
	_quiet = 0.0
	if Demo.away:
		return false
	DemoSeats.heard_from(device)
	var paused := room != null and room.is_inside_tree() and room.get_tree().paused
	if not presses(event) or paused or DemoSeats.sits(device):
		return false
	if event is InputEventKey and event.is_action_pressed(InputActions.PAUSE):
		return false
	return _sit_down(device, room)


## [param device] sits down in [param room]; on the title, with the next run dealt at once.
func _sit_down(device: int, room: Node) -> bool:
	if room == null or not DemoSeats.sit(device, room.get_node_or_null("Match") as Match):
		return false
	if room.scene_file_path == Game.TITLE_SCENE:
		deal()
	return true


## Which device [param event] came from: the keyboard and the mouse are one, each pad its own.
static func device_of(event: InputEvent) -> int:
	if event is InputEventKey or event is InputEventMouse:
		return DeviceInput.KEYBOARD
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device
	return NO_DEVICE


## Whether [param event] is somebody touching something: a key, a button, the mouse moved, or a
## stick or a trigger pushed past its drift.
static func touches(event: InputEvent) -> bool:
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return absf(motion.axis_value) > PUSHED
	return event is InputEventKey or event is InputEventMouse or event is InputEventJoypadButton


## Whether [param event] is a key or a button going down: what sits somebody down.
static func presses(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key != null:
		return key.pressed and not key.echo
	var click := event as InputEventMouseButton
	if click != null:
		return click.pressed and click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
	var button := event as InputEventJoypadButton
	return button != null and button.pressed


## The pointer hidden while the demo plays, and up again for a moment whenever the mouse moves.
func _rest_the_pointer(delta: float) -> void:
	if _pointer_left <= 0.0:
		return
	_pointer_left -= delta
	if _pointer_left <= 0.0:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


## The line in [param scene], the title or a match's HUD, for as long as a seat is still a bot's.
func _place_the_line(scene: Node) -> void:
	var home := line_home(scene)
	if home == null:
		return
	if _line == null or not is_instance_valid(_line) or _line.get_parent() != home:
		_line = DemoLine.add_to(home)
	_line.wanted = DemoSeats.any_free()


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


## The demo's host under [Game] in [param tree], or null without the demo.
static func of(tree: SceneTree) -> DemoHost:
	return tree.root.get_node_or_null("Game/DemoHost") as DemoHost


## Leaves the demo for the full game, GAME.md 9.8: the title, for a visitor to play as anybody new
## does, on a profile of their own with a head start, see [DemoGuest]. The machine's settings are
## kept as they are first, to be put back once the demo takes over again.
func leave() -> void:
	_kept = ConfigFile.new()
	Game.settings.write_machine(_kept)
	_profiles_before.clear()
	for each: Profile in Game.settings.profiles():
		_profiles_before.append(each.id)
	DemoSeats.clear()
	Demo.away = true
	_quiet = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Game.settings.profile = DemoGuest.make(Game.settings)
	Game.settings.save_to_disk()
	go_to_title()


## Away in the full game, the demo takes over again once nobody has touched anything for
## [constant DemoSeats.IDLE] seconds, wherever the game is.
func wait_for_the_visitor() -> void:
	if _quiet >= DemoSeats.IDLE:
		come_back()


## The demo again, GAME.md 9.8: the visitor's map, if any, goes into their profile as it goes, and
## then every profile made since the demo was left is thrown away, and the machine's settings and
## the lobby's choices are put back as they were.
func come_back() -> void:
	go_to_title()
	PlayerInput.typing = false
	var settings := Game.settings
	settings.unlink_all()
	settings.profile = Demo.profile()
	if _kept != null:
		settings.load_machine(_kept)
		if is_inside_tree():
			settings.apply(get_tree())
	settings.save_to_disk()
	for each: Profile in settings.profiles():
		if each.id not in _profiles_before:
			settings.delete_profile(each.id)
	_kept = null
	Demo.away = false
	_quiet = 0.0
	_title = null
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


## Back to the title, as any way out of a room goes.
func go_to_title() -> void:
	Game.go_to_title()


## Deals a run and goes to its first map.
func deal() -> void:
	_first = false
	_title = null
	Game.start_match(DemoRun.deal(rng))
