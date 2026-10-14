class_name DialogBinds
extends RefCounted
## What the large dialogs share of their binds, GAME.md 8.5, so the loyalty program, the catalog and
## the achievements answer the same keys the same way, see [constant InputActions.MENU_VIEW]: WASD
## moving the cursor as the arrows do, and the page keys drawn in their row.


## The way [param event] presses one of WASD, or none, held down as well as pressed, as the arrows
## repeat.
static func way_of(event: InputEvent) -> Vector2i:
	for action: StringName in InputActions.MENU_MOVES:
		if event.is_action_pressed(action, true):
			return InputActions.MENU_MOVES[action]
	return Vector2i.ZERO


## Moves the cursor of [param viewport] the way one of WASD in [param event] says, to the control
## that way of the one it is on, as the arrows do. True if it was one of them.
static func moved_focus(event: InputEvent, viewport: Viewport) -> bool:
	var way := way_of(event)
	if way == Vector2i.ZERO:
		return false
	var on := viewport.gui_get_focus_owner()
	if on == null:
		return true
	var side := SIDE_TOP
	match way:
		Vector2i.DOWN:
			side = SIDE_BOTTOM
		Vector2i.LEFT:
			side = SIDE_LEFT
		Vector2i.RIGHT:
			side = SIDE_RIGHT
	var next := on.find_valid_focus_neighbor(side)
	if next != null and next != on:
		next.grab_focus()
	return true


## The page before and after, drawn for [param keys] or a pad, without words: beside the tabs they
## say what they do.
static func pages(keys: bool, ink: Color, size: int) -> Control:
	var parts: Array = [
		InputGlyph.of_action(InputActions.MENU_PAGE_PREV, keys, ink, size),
		InputGlyph.of_action(InputActions.MENU_PAGE_NEXT, keys, ink, size),
	]
	return InputHint.row("%s %s", parts, ink, size)
