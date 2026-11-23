class_name SteamPads
extends Node
## Steam Input's controllers as the game's own pads, GAME.md 10.8 "Steam Input": each controller
## Steam reads for the game is a pad of the game's, by an id of its own past the engine's, and what
## Steam says of its actions every frame is pressed on it, as a pad's own buttons and sticks are.
## So every part of the game that reads a pad reads these the same way: a seat taken with Join, a
## kart driven, the menus walked, the joker pick, the pages turned.
##
## A button action Steam says went down is pressed as the pad's own button bound to that action,
## where one button is bound to just the actions that went down with it on the controller, as on
## the game's own layout; otherwise as a button no pad has standing for just those, see
## [method InputActions.chord]. Actions that go down together on one of the controller's buttons are
## one press, by the button Steam says each is on, so a screen hears them once, as it does a pad's
## own button. The sticks and triggers move the game's own sticks' and triggers' axes, those of
## the actions they are, see [SteamActions].
##
## Steam's controllers reach the game through here alone: Steam keeps a controller it reads for the
## game from the engine, unless its layout binds a button to a pad's own button, which then comes
## as a pad of the engine's too. Started in a Steam build unless the player turned Steam Input off,
## and never in the tests, which hand it a [FakeSteam].

## The id the first of Steam's controllers is a pad by, past every id the engine gives its own, and
## how many Steam reads at most.
const FIRST_DEVICE := 32
const MOST := 16
## Where the action manifest is beside a build, as Steamworks names it too, docs/STEAM.md.
const BUILT_MANIFEST := "steam_input/action_manifest.vdf"
## Whether Steam's sticks say up as more, as Steam's own controller's do: the engine says down.
const UP_IS_MORE := true
## How far a stick or trigger moves before the game hears it again, so a held stick says nothing.
const STIR := 0.002

## The one running, or null; for the settings, to show Steam's own controller settings.
static var running: SteamPads

## GodotSteam's `Steam`, or a stand-in for it.
var api: Object

## Steam's handles of the action set and of each action, once Steam has the manifest; 0 until then.
var _set := 0
var _buttons: Dictionary[StringName, int] = {}
var _sticks: Dictionary[String, int] = {}
var _triggers: Dictionary[String, int] = {}
## Each controller, by Steam's handle, and the pad it is; the handle of each pad.
var _devices: Dictionary[int, int] = {}
var _handles: Dictionary[int, int] = {}
## By pad: the button actions held, the presses sent for them and still down, each the event and the
## actions it stands for, and where each axis was last put.
var _held: Dictionary[int, Dictionary] = {}
var _presses: Dictionary[int, Array] = {}
var _axes: Dictionary[int, Dictionary] = {}
## Whether this frame sent anything, to be handed to the game at once.
var _sent := false
## Whether to print what Steam says, `++ --pads`, and which way each stick was last told pushed.
var _told := false
var _pushed: Dictionary[String, String] = {}


func _init(steam_api: Object) -> void:
	api = steam_api
	name = "SteamPads"
	_told = "--pads" in OS.get_cmdline_user_args()


## The action manifest for Steam to read in place of what Steamworks names, GAME.md 10.8: the
## checkout's from a checkout, `make steam-run`, and the one beside the build in an export, which is
## what Steamworks names as well. Empty where there is none.
static func manifest_path() -> String:
	if OS.has_feature("template"):
		var beside := OS.get_executable_path().get_base_dir().path_join(BUILT_MANIFEST)
		return beside if FileAccess.file_exists(beside) else ""
	var here := SteamActions.FOLDER.path_join(SteamActions.MANIFEST)
	return ProjectSettings.globalize_path(here) if FileAccess.file_exists(here) else ""


func _enter_tree() -> void:
	running = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	var manifest := manifest_path()
	if not manifest.is_empty() and not bool(api.call(&"setInputActionManifestFilePath", manifest)):
		push_warning("Steam did not take the action manifest %s" % manifest)
	for wiring: Array in [
		[&"input_device_connected", _on_connected],
		[&"input_device_disconnected", _on_disconnected],
		[&"input_configuration_loaded", _on_configuration_loaded],
	]:
		if api.has_signal(wiring[0]) and not api.is_connected(wiring[0], wiring[1]):
			api.connect(wiring[0], wiring[1])
	DeviceInput.steam_rumble = rumble
	# Read after Steam's own callbacks, which GodotSteam runs on the same signal, and before any node
	# of the game's is processed, so a press is heard the frame Steam has it.
	get_tree().process_frame.connect(poll)
	# Steam says of every controller there already, then of each that comes.
	api.call(&"enableDeviceCallbacks")


func _exit_tree() -> void:
	for handle: int in _devices.keys():
		_on_disconnected(handle)
	_flush()
	if get_tree().process_frame.is_connected(poll):
		get_tree().process_frame.disconnect(poll)
	for wiring: Array in [
		[&"input_device_connected", _on_connected],
		[&"input_device_disconnected", _on_disconnected],
		[&"input_configuration_loaded", _on_configuration_loaded],
	]:
		if api.has_signal(wiring[0]) and api.is_connected(wiring[0], wiring[1]):
			api.disconnect(wiring[0], wiring[1])
	if DeviceInput.steam_rumble == rumble:
		DeviceInput.steam_rumble = Callable()
	InputActions.forget_chords()
	if running == self:
		running = null


## What every controller of Steam's has done since the last frame, pressed on its pad.
func poll() -> void:
	if _devices.is_empty() or not _ready_handles():
		return
	for handle: int in _devices:
		api.call(&"activateActionSet", handle, _set)
		_read_buttons(handle, _devices[handle])
		_read_sticks(handle, _devices[handle])
	_flush()


## Steam's own settings for the layout of the controller [param device] is, GAME.md 10.8, or of the
## one touched last, or any; says whether Steam put them up, which it does not with its overlay off.
func show_layout(device := DeviceInput.ANY) -> bool:
	var pad := device if _handles.has(device) else -1
	if pad < 0:
		for touched: int in DeviceInput.recent:
			if _handles.has(touched):
				pad = touched
				break
	if pad < 0 and not _handles.is_empty():
		pad = _handles.keys()[0]
	if pad < 0:
		return false
	return bool(api.call(&"showBindingPanel", _handles[pad]))


## Whether any controller of Steam's is here.
func any() -> bool:
	return not _devices.is_empty()


## Knocks the pad [param device], see [method DeviceInput.rumble]: Steam's left motor is the heavy
## one, and Steam stops it only when told, after [param seconds].
func rumble(device: int, weak: float, strong: float, seconds: float) -> void:
	if not _handles.has(device):
		return
	var handle := _handles[device]
	api.call(&"triggerVibration", handle, _speed(strong), _speed(weak))
	var stop := func() -> void:
		if _devices.has(handle):
			api.call(&"triggerVibration", handle, 0, 0)
	get_tree().create_timer(seconds, true, false, true).timeout.connect(stop)


static func _speed(strength: float) -> int:
	return clampi(roundi(clampf(strength, 0.0, 1.0) * 65535.0), 0, 65535)


## Asks Steam for the handles of the set and the actions until it has the set's, which it has once
## it has read the manifest. Says whether it has. An action Steam has no handle for, from a
## manifest older than the game, is left unread.
func _ready_handles() -> bool:
	if _set != 0:
		return true
	_set = int(api.call(&"getActionSetHandle", SteamActions.SET))
	for action: StringName in SteamActions.BUTTONS:
		_buttons[action] = int(api.call(&"getDigitalActionHandle", String(action)))
	for stick: String in SteamActions.STICKS:
		_sticks[stick] = int(api.call(&"getAnalogActionHandle", stick))
	for trigger: String in SteamActions.TRIGGERS:
		_triggers[trigger] = int(api.call(&"getAnalogActionHandle", trigger))
	return _set != 0


func _on_connected(handle: int) -> void:
	if _devices.has(handle):
		return
	var device := FIRST_DEVICE
	while _handles.has(device):
		device += 1
	if device >= FIRST_DEVICE + MOST:
		return
	_devices[handle] = device
	_handles[device] = handle
	_held[device] = {}
	_presses[device] = []
	_axes[device] = {}
	var type := int(api.call(&"getInputTypeForHandle", handle))
	DeviceInput.steam_pads[device] = PadFamily.STEAM_TYPES.get(type, PadFamily.Family.GENERIC)
	if _told:
		print("Steam Input: controller %d of type %d is pad %d" % [handle, type, device])
	Input.joy_connection_changed.emit(device, true)


func _on_disconnected(handle: int) -> void:
	if not _devices.has(handle):
		return
	var device := _devices[handle]
	for press: Array in _presses[device]:
		_send(_let_go(press[0]))
	for axis: int in _axes[device]:
		if not is_zero_approx(_axes[device][axis]):
			_send(_motion(device, axis, 0.0))
	_flush()
	_devices.erase(handle)
	_handles.erase(device)
	_held.erase(device)
	_presses.erase(device)
	_axes.erase(device)
	DeviceInput.steam_pads.erase(device)
	if _told:
		print("Steam Input: controller %d, pad %d, gone" % [handle, device])
	Input.joy_connection_changed.emit(device, false)


## A controller's layout was loaded again, as when the player changed it in Steam: the handles are
## asked for again.
func _on_configuration_loaded(_app: int, _handle: int, _data: Dictionary = {}) -> void:
	_set = 0


## The button actions held on [param handle], pressed and let go on its pad [param device].
func _read_buttons(handle: int, device: int) -> void:
	var was: Dictionary = _held[device]
	var now := {}
	for action: StringName in _buttons:
		if _buttons[action] == 0:
			continue
		var data: Dictionary = api.call(&"getDigitalActionData", handle, _buttons[action])
		if bool(data.get("state", false)):
			now[action] = true
	_held[device] = now
	var went: Array[StringName] = []
	var came: Array[StringName] = []
	for action: StringName in was:
		if not now.has(action):
			went.append(action)
	for action: StringName in now:
		if not was.has(action):
			came.append(action)
	if went.is_empty() and came.is_empty():
		return
	if _told:
		print("Steam Input: pad %d, down %s, up %s" % [device, came, went])
	# A press goes up with the first of its actions let go; the others still held are pressed again,
	# on their own, which only a layout pressing some of a button's actions in another way does.
	for press: Array in _presses[device].duplicate():
		var stands_for: Array[StringName] = press[1]
		if stands_for.any(func(action: StringName) -> bool: return action in went):
			_send(_let_go(press[0]))
			_presses[device].erase(press)
			for action: StringName in stands_for:
				if now.has(action) and action not in came:
					came.append(action)
	for together: Array[StringName] in _together(handle, came):
		var press := _press(together, device)
		_send(press)
		_presses[device].append([press, together])


## [param actions], which went down on [param handle] in one frame, in the presses they are: those
## on a button of the controller's together, as Steam says which each is on, and each other alone.
func _together(handle: int, actions: Array[StringName]) -> Array[Array]:
	var origins: Dictionary[StringName, Array] = {}
	for action: StringName in actions:
		origins[action] = api.call(&"getDigitalActionOrigins", handle, _set, _buttons[action])
	var presses: Array[Array] = []
	for action: StringName in actions:
		var joined: Array[StringName] = [action]
		for press: Array[StringName] in presses.duplicate():
			if press.any(func(other: StringName) -> bool: return _shared(origins, action, other)):
				joined.append_array(press)
				presses.erase(press)
		presses.append(joined)
	return presses


static func _shared(
	origins: Dictionary[StringName, Array], one: StringName, other: StringName
) -> bool:
	for origin: int in origins[one]:
		if origin in origins[other]:
			return true
	return false


## The press of [param actions] on the pad [param device]: the pad's own button bound to just those
## of the actions Steam knows, or the chord standing for them, see [method InputActions.chord].
func _press(actions: Array[StringName], device: int) -> InputEvent:
	for event: InputEvent in InputMap.action_get_events(actions[0]):
		var button := event as InputEventJoypadButton
		if button == null or InputActions.is_chord(button):
			continue
		var press := _button(device, button.button_index, true)
		if _hears(press) == _sorted(actions):
			return press
	var chord := InputActions.chord(actions)
	if chord >= 0:
		return _button(device, chord, true)
	# Every chord handed out, which no layout comes near: the first action alone.
	var action := InputEventAction.new()
	action.action = actions[0]
	action.pressed = true
	action.strength = 1.0
	action.device = device
	return action


## The button actions of Steam's that [param press] is, sorted.
static func _hears(press: InputEvent) -> Array[StringName]:
	var hears: Array[StringName] = []
	for action: StringName in SteamActions.BUTTONS:
		if InputMap.has_action(action) and InputMap.event_is_action(press, action, true):
			hears.append(action)
	return _sorted(hears)


static func _sorted(actions: Array[StringName]) -> Array[StringName]:
	var sorted := actions.duplicate()
	sorted.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return sorted


## The sticks and triggers of [param handle], on the axes of its pad [param device].
func _read_sticks(handle: int, device: int) -> void:
	for stick: String in _sticks:
		if _sticks[stick] == 0:
			continue
		var data: Dictionary = api.call(&"getAnalogActionData", handle, _sticks[stick])
		var across := float(data.get("x", 0.0))
		var up := float(data.get("y", 0.0))
		if _told:
			_tell_push(device, stick, Vector2(across, up))
		_move(device, SteamActions.STICKS[stick][1], across)
		_move(device, SteamActions.STICKS[stick][2], up * (-1.0 if UP_IS_MORE else 1.0))
	for trigger: String in _triggers:
		if _triggers[trigger] == 0:
			continue
		var data: Dictionary = api.call(&"getAnalogActionData", handle, _triggers[trigger])
		_move(device, SteamActions.TRIGGERS[trigger][1], float(data.get("x", 0.0)))


## Says which way [param stick] of [param device] is pushed as Steam has it, once each time it is
## pushed all the way another way, for `++ --pads`: whether Steam's up is more,
## [constant UP_IS_MORE].
func _tell_push(device: int, stick: String, push: Vector2) -> void:
	var way := ""
	if push.length() > 0.9:
		way = ("right" if push.x > 0.0 else "left") if absf(push.x) > absf(push.y) else ""
		way = way if not way.is_empty() else ("y more" if push.y > 0.0 else "y less")
	var key := "%d %s" % [device, stick]
	if way != _pushed.get(key, ""):
		_pushed[key] = way
		if not way.is_empty():
			print("Steam Input: pad %d, %s pushed %s: %s" % [device, stick, way, push])


## The axis of the game's [param action] put at [param value] on [param device], [param value]
## being how far toward the action: the axis the action is bound to here, the way it is bound, or
## the one it is bound to as the game starts.
func _move(device: int, action: StringName, value: float) -> void:
	var axis := SteamActions.pad_axis(action)
	var toward := 1.0
	for event: InputEvent in InputMap.action_get_events(action):
		var motion := event as InputEventJoypadMotion
		if motion != null:
			axis = motion.axis
			toward = signf(motion.axis_value)
			break
	if axis < 0:
		return
	var at := clampf(value * toward, -1.0, 1.0)
	var was: float = _axes[device].get(axis, 0.0)
	if absf(at - was) < STIR and not (is_zero_approx(at) and not is_zero_approx(was)):
		return
	_axes[device][axis] = at
	_send(_motion(device, axis, at))


static func _button(device: int, index: int, pressed: bool) -> InputEventJoypadButton:
	var button := InputEventJoypadButton.new()
	button.device = device
	button.button_index = index as JoyButton
	button.pressed = pressed
	button.pressure = 1.0 if pressed else 0.0
	return button


static func _motion(device: int, axis: int, value: float) -> InputEventJoypadMotion:
	var motion := InputEventJoypadMotion.new()
	motion.device = device
	motion.axis = axis as JoyAxis
	motion.axis_value = value
	return motion


## [param press] let go.
static func _let_go(press: InputEvent) -> InputEvent:
	var up: InputEvent = press.duplicate()
	if up is InputEventJoypadButton:
		(up as InputEventJoypadButton).pressed = false
		(up as InputEventJoypadButton).pressure = 0.0
	elif up is InputEventAction:
		(up as InputEventAction).pressed = false
		(up as InputEventAction).strength = 0.0
	return up


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	_sent = true


## Everything sent this frame handed to the game now, before any of it is processed.
func _flush() -> void:
	if _sent:
		_sent = false
		Input.flush_buffered_events()
