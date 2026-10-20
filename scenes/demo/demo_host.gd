class_name DemoHost
extends Node
## The demo for a booth as it runs, GAME.md 9.8, under [Game] for as long as the game does, from
## room to room: the first run dealt once the shaders have compiled behind the title, and the next
## after the title has stood between runs for [constant TITLE_SECONDS]; somebody pressing keys or
## a pad's buttons sat down, see [DemoPresses] and [DemoSeats], and got up again once quiet; and the
## pause menu put away when nobody has touched anything for a while. [Game] makes it from its path,
## see [constant Game.DEMO_HOST], and never names it.

## How long the title stands between runs, in seconds, and how long once the demo has taken over
## again from the full game, when the booth has stood idle for a minute already.
const TITLE_SECONDS := 10.0
const BACK_SECONDS := 5.0
## How long the mouse pointer stays up after the mouse last moved, in seconds.
const POINTER_REST := 3.0
## How far a stick or a trigger has to go to be somebody touching it rather than its drift.
const PUSHED := 0.3
## What [method device_of] says for something that is no seat's device: the mouse, or a touch.
const NO_DEVICE := -100
## What the title's Quit asks away from the demo in the full game, see [method ask_to_quit].
const QUIT_QUESTION := "Quit the game?"
## Leaving the demo for the full game, GAME.md 9.8, a beat between the two: how long the screen
## takes to go dark, how long it stays dark before the full game's title, and how long the dark
## takes to lift off it and the invitation coming up there.
const DARK_IN := 0.5
const DARK_HOLD := 2.0
const DARK_OUT := 0.6
const QUIT_LINE := (
	"Or go back to the demo, which plays on by itself until somebody picks up a pad. "
	+ "This profile goes either way."
)

var rng := RandomNumberGenerator.new()
## Which presses sit somebody down.
var presses := DemoPresses.new()

## The title being waited on, how long until the next run is dealt from it, and the words on it
## counting that down.
var _title: Node
var _title_left := 0.0
var _wait: DemoWait
## Whether no run has been dealt yet: the first comes as soon as the shaders are compiled.
var _first := true
## Whether the demo has just taken over again from the full game, which its title says.
var _back := false
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
var _named_before := ""
## The dark over everything while the demo is left for the full game, see [method leave].
var _dark: CanvasLayer


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
## not quiet, and a key the game plays with or a pad's button or stick on a device nobody sits at
## counts toward somebody sitting down, see [DemoPresses]: at the first of the demo's seats or a
## bot's kart, or on the title with the next run dealt at once. Such a press is theirs, heard by
## nothing else, so a pad's Start is neither a pause nor a join. Escape is left to the pause menu,
## and nothing sits anybody down while it is open or while the window is not in front. Whether the
## press was taken.
func heard(event: InputEvent, room: Node) -> bool:
	if not Demo.on:
		return false
	if touches(event):
		_quiet = 0.0
	if Demo.away or not presses.deliberate(event):
		return false
	var device := device_of(event)
	DemoSeats.heard_from(device)
	var paused := room != null and room.is_inside_tree() and room.get_tree().paused
	if paused or DemoSeats.sits(device) or not _in_front():
		return false
	if not presses.count(device, Time.get_ticks_msec() * 0.001):
		return true
	return _sit_down(device, room)


## Whether the game's window is the one in front, where whatever is pressed is pressed at it.
static func _in_front() -> bool:
	return Game.is_headless() or DisplayServer.window_is_focused()


## [param device] sits down in [param room]; on the title, with the next run dealt at once.
func _sit_down(device: int, room: Node) -> bool:
	if room == null or not DemoSeats.sit(device, room.get_node_or_null("Match") as Match):
		return false
	if room.scene_file_path == Game.TITLE_SCENE:
		deal()
	return true


## Which seat's device [param event] came from: the keyboard, or a pad. The mouse is none, see
## [DemoPresses].
static func device_of(event: InputEvent) -> int:
	if event is InputEventKey:
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
		_title_left = 0.0 if _first else (BACK_SECONDS if _back else TITLE_SECONDS)
		_wait = null if _first else DemoWait.on(title)
	# The shaders compile behind the title first, GAME.md 10.7.
	if title.get(&"warming") != null:
		return false
	_title_left -= delta
	if _wait != null and is_instance_valid(_wait):
		_wait.say(_title_left, _back)
	return _title_left <= 0.0


## The demo's host under [Game] in [param tree], or null without the demo.
static func of(tree: SceneTree) -> DemoHost:
	return tree.root.get_node_or_null("Game/DemoHost") as DemoHost


## The title's Quit away from the demo in the full game, GAME.md 9.8: a question first, put up by
## [param ask], the title's way of asking, whether to quit the game or go back to the demo, which
## the cursor starts on. Whether it asked, which it does only away from the demo in [param tree].
static func ask_to_quit(tree: SceneTree, ask: Callable) -> bool:
	if not (Demo.on and Demo.away):
		return false
	var answered := func(yes: bool) -> void:
		var host := of(tree)
		if yes or host == null:
			Game.quit()
		else:
			host.come_back()
	var pane := ask.call("DemoQuit", answered) as ConfirmPane
	if pane != null:
		pane.ask(QUIT_QUESTION, QUIT_LINE, "Quit the game", "Back to the demo")
	return true


## Leaves the demo for the full game, GAME.md 9.8: the screen goes dark for a moment and the music
## fades out with it, a beat between the two, and comes up on the title, for a visitor to play as
## anybody new does, on a profile of their own with a head start, see [DemoGuest]. Nothing is
## pressed meanwhile. Out of the tree, with no screen to darken, it is the title at once.
func leave() -> void:
	if _dark != null:
		return
	if not is_inside_tree():
		_away()
		return
	_dark = CanvasLayer.new()
	_dark.name = "Dark"
	_dark.layer = 128
	var shade := ColorRect.new()
	shade.color = Color.BLACK
	shade.modulate.a = 0.0
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dark.add_child(shade)
	add_child(_dark)
	# Held off through the dark; the title lets it go as it opens, after the invitation, which comes
	# in silence anyway, STORY.md 6.1a.
	Audio.hold_music(true)
	var fade := _dark.create_tween()
	fade.tween_property(shade, "modulate:a", 1.0, DARK_IN)
	fade.tween_interval(DARK_HOLD)
	fade.tween_callback(_away)
	fade.tween_property(shade, "modulate:a", 0.0, DARK_OUT)
	fade.tween_callback(
		func() -> void:
			_dark.queue_free()
			_dark = null
	)


## The full game's title, in the dark, see [method leave]: the machine's settings kept as they are
## first, to be put back once the demo takes over again.
func _away() -> void:
	_kept = ConfigFile.new()
	Game.settings.write_machine(_kept)
	_named_before = Game.settings.named
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
		settings.named = _named_before
		if is_inside_tree():
			settings.apply(get_tree())
	settings.save_to_disk()
	for each: Profile in settings.profiles():
		if each.id not in _profiles_before:
			settings.delete_profile(each.id)
	_kept = null
	Demo.away = false
	_back = true
	_quiet = 0.0
	_title = null
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


## Back to the title, as any way out of a room goes.
func go_to_title() -> void:
	Game.go_to_title()


## Deals a run and goes to its first map.
func deal() -> void:
	_first = false
	_back = false
	_title = null
	Game.start_match(DemoRun.deal(rng))
