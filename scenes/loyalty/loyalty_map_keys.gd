class_name LoyaltyMapKeys
extends RefCounted
## The loyalty map's keys and pads, GAME.md 8.9, for [LoyaltyDialog]: an arrow, WASD, the stick or
## the cross driving the cursor along the road that way, minus and plus a notch of zoom a press, a
## pad's triggers zooming for as long as they are pulled and its right stick moving the map.


## Drives the cursor on [param view] the way [param event] pushes, if it is a push. True if it was,
## or if it was the stick still held over, [param pushed] false: a stick drives a landmark a push,
## and on only as [PadRepeat] has it.
static func drive_by(view: LoyaltyMapView, event: InputEvent, pushed: bool) -> bool:
	var ways := {
		&"ui_left": Vector2i.LEFT,
		&"ui_right": Vector2i.RIGHT,
		&"ui_up": Vector2i.UP,
		&"ui_down": Vector2i.DOWN,
	}
	ways.merge(InputActions.MENU_MOVES)
	for action: StringName in ways:
		if event.is_action_pressed(action):
			if pushed:
				view.drive_toward(ways[action])
			return true
	return false


## Whether [param event] is a push: anything but a stick, or a stick just pushed over a way it was
## not before, rather than moving on where it already was, as every move of one held over reads;
## [param ways] the way each axis was last pushed, -1, 1 or 0 in the middle, kept up to date.
static func pushed(event: InputEvent, ways: Dictionary[int, int]) -> bool:
	var stick := event as InputEventJoypadMotion
	if stick == null:
		return true
	var over := absf(stick.axis_value) >= InputMap.action_get_deadzone(&"ui_right")
	var way := int(signf(stick.axis_value)) if over else 0
	var was: int = ways.get(stick.axis, 0)
	ways[stick.axis] = way
	return way != 0 and way != was


## Zooms [param view] in or out a notch for [param event], if it is a zoom key, the cursor kept in
## sight. True if it was, or if it was a trigger, which zooms as it is held, see [method pads].
static func zoom_by(view: LoyaltyMapView, event: InputEvent) -> bool:
	var key := event as InputEventKey
	var pull := event as InputEventJoypadMotion
	if pull != null:
		return pull.axis in [LoyaltyDialog.ZOOM_OUT, LoyaltyDialog.ZOOM_IN]
	var by := 0.0
	if key != null and key.pressed:
		if key.keycode in LoyaltyDialog.ZOOM_KEYS_OUT:
			by = -1.0
		elif key.keycode in LoyaltyDialog.ZOOM_KEYS_IN:
			by = 1.0
	if by == 0.0:
		return false
	view.zoom_to(view.zoom * pow(LoyaltyMapView.ZOOM_STEP, by), view.size * 0.5)
	view.show_point(view.cursor.point, false)
	return true


## How far the pads plugged in are pulling their triggers, in for more than none and out for less,
## and pushing their right sticks, as one: x the zoom, y and z the push.
static func pads() -> Vector3:
	var zooming := 0.0
	var push := Vector2.ZERO
	for pad: int in Input.get_connected_joypads():
		var into := Input.get_joy_axis(pad, LoyaltyDialog.ZOOM_IN)
		var out := Input.get_joy_axis(pad, LoyaltyDialog.ZOOM_OUT)
		var rest := LoyaltyDialog.TRIGGER_REST
		zooming += (into if into > rest else 0.0) - (out if out > rest else 0.0)
		var stick := Vector2(
			Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
		)
		if stick.length() > LoyaltyDialog.STICK_REST:
			push += stick
	return Vector3(zooming, push.x, push.y)


## [param view] zoomed [param zooming] of a trigger's whole pull, in for more than none and out for
## less, about the landmark the cursor is at while it is in view, and moved by the right stick
## pushed [param push] of the way, for [param delta] seconds: pushed right, more of the map to the
## right comes into view.
static func pad_on(view: LoyaltyMapView, zooming: float, push: Vector2, delta: float) -> void:
	if zooming != 0.0:
		var about := view.offset + view.cursor.point * view.zoom
		if not Rect2(Vector2.ZERO, view.size).has_point(about):
			about = view.size * 0.5
		view.zoom_to(view.zoom * pow(2.0, LoyaltyDialog.ZOOM_RATE * zooming * delta), about)
	if push != Vector2.ZERO:
		view.pan_by(-push.limit_length(1.0) * LoyaltyDialog.PAN_RATE * delta)
