class_name FakeSteamInput
extends FakeSteam
## Steam with Steam Input as the tests see it, GAME.md 10.8: [FakeSteam] with controllers the game
## reads through Steam, the action set and its actions, what each controller holds and pushes, and
## the button each action is on, all set by the test; and what the game asked of it.

# gdlint: disable=function-name

signal input_device_connected(input_handle: int)
signal input_device_disconnected(input_handle: int)
signal input_configuration_loaded(app_id: int, device_handle: int, config_data: Dictionary)

## The controllers, by handle, each with Steam's type for it.
var controllers: Dictionary[int, int] = {}
## The handle of the set and of each action Steam knows, by name; none for those it does not.
var action_handles: Dictionary[String, int] = {}
## The button actions each controller holds, by handle; the origins each action is on; and where
## each stick and trigger of each controller is, by handle and the action's name.
var held: Dictionary[int, Array] = {}
var origins: Dictionary[String, Array] = {}
var analog: Dictionary[int, Dictionary] = {}
## The set each controller was last put on, the manifest Steam was given, and every knock: the
## controller and its two motors' speeds.
var active_set: Dictionary[int, int] = {}
var manifest := ""
var knocks: Array[Array] = []
## Whether Steam's overlay puts its controller settings up.
var panel_shows := true
## Each origin as Steam translates it to an Xbox One pad's, which an Xbox pad's own are already;
## Steam's picture of an origin, by the file, and its name for it.
var xbox_of: Dictionary[int, int] = {}
var pictures: Dictionary[int, String] = {}
var words: Dictionary[int, String] = {}


## Knows the game's manifest: a handle for the set and for each of [param names], from 1.
func know_actions(names: Array) -> void:
	action_handles[SteamActions.SET] = 1
	for name: String in names:
		action_handles[name] = action_handles.size() + 1


## A controller of Steam's [param type] plugged in as [param handle], and told of.
func plug(handle: int, type := 1) -> void:
	controllers[handle] = type
	held[handle] = []
	analog[handle] = {}
	input_device_connected.emit(handle)


func unplug(handle: int) -> void:
	controllers.erase(handle)
	input_device_disconnected.emit(handle)


func enableDeviceCallbacks() -> void:
	calls.append("enableDeviceCallbacks")
	for handle: int in controllers:
		input_device_connected.emit(handle)


func setInputActionManifestFilePath(manifest_path: String) -> bool:
	manifest = manifest_path
	return true


func getActionSetHandle(action_set_name: String) -> int:
	return action_handles.get(action_set_name, 0)


func getDigitalActionHandle(action_name: String) -> int:
	return action_handles.get(action_name, 0)


func getAnalogActionHandle(action_name: String) -> int:
	return action_handles.get(action_name, 0)


func activateActionSet(input_handle: int, action_set_handle: int) -> void:
	active_set[input_handle] = action_set_handle


func getInputTypeForHandle(handle: int) -> int:
	return controllers.get(handle, super(handle))


func getDigitalActionData(input_handle: int, digital_action_handle: int) -> Dictionary:
	var down: bool = _named(digital_action_handle) in held.get(input_handle, [])
	return {"state": down, "active": true}


func getAnalogActionData(input_handle: int, analog_action_handle: int) -> Dictionary:
	var at: Vector2 = analog.get(input_handle, {}).get(_named(analog_action_handle), Vector2.ZERO)
	return {"mode": 0, "x": at.x, "y": at.y, "active": true}


func getDigitalActionOrigins(
	_input_handle: int, _action_set_handle: int, digital_action_handle: int
) -> Array:
	return origins.get(_named(digital_action_handle), [])


func getAnalogActionOrigins(
	_input_handle: int, _action_set_handle: int, analog_action_handle: int
) -> Array:
	return origins.get(_named(analog_action_handle), [])


## An origin to an Xbox One pad's, see [member xbox_of], and back to any other controller's: the
## first origin translated to it, or itself.
func translateActionOrigin(destination_input: int, source_origin: int) -> int:
	if destination_input == SteamPads.XBOX_ONE:
		return xbox_of.get(source_origin, source_origin)
	for origin: int in xbox_of:
		if xbox_of[origin] == source_origin:
			return origin
	return source_origin


func getGlyphSVGForActionOrigin(origin: int, _flags: int) -> String:
	return pictures.get(origin, "")


func getStringForActionOrigin(origin: int) -> String:
	return words.get(origin, "")


func showBindingPanel(input_handle: int) -> bool:
	calls.append("showBindingPanel %d" % input_handle)
	return panel_shows


func triggerVibration(input_handle: int, left_speed: int, right_speed: int) -> void:
	knocks.append([input_handle, left_speed, right_speed])


## The name of the action [param action_handle] is the handle of.
func _named(action_handle: int) -> String:
	for name: String in action_handles:
		if action_handles[name] == action_handle:
			return name
	return ""
