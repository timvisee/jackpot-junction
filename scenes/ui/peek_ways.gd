class_name PeekWays
extends RefCounted
## The menu's cursor between the title's buttons and what peeks in at its edges, GAME.md 3.8:
## going sideways off Kit's folder, the license or the bay it comes to the button showing nearest
## the peek's height, rather than to a button fixed beforehand, which the Clubhouse may have hidden
## and the engine then goes on past, out to the far edge.


## The one of [param buttons] showing nearest [param from]'s height, or null with none showing.
static func nearest(buttons: Array[Control], from: Control) -> Control:
	var middle := middle_of(from)
	var found: Control = null
	for button: Control in buttons:
		if not is_instance_valid(button) or not button.is_visible_in_tree():
			continue
		if found == null or absf(middle_of(button) - middle) < absf(middle_of(found) - middle):
			found = button
	return found


## How far down the screen [param control]'s middle is, turned and scaled as it is.
static func middle_of(control: Control) -> float:
	return (control.get_global_transform() * Rect2(Vector2.ZERO, control.size)).get_center().y
