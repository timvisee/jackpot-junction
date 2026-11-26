class_name CursorHold
extends RefCounted
## The menu's cursor held by a view up over a screen that has nothing of its own to take it: the
## license held up, GAME.md 9.4a, a loyalty card, 8.9, Kit's folder and a note out of it, STORY.md
## 7.2. Let go instead, the engine hands it to whatever on the screen under lies the way of the next
## arrow pressed, and it walks about behind the view; held, every way off the view leads back onto
## it, it draws nothing, and the right stick scrolls nothing under it, see [StickScroll]. Put away,
## the screen under gives the cursor back where it was.


## [param view] takes the cursor and keeps it while it is up.
static func take(view: Control) -> void:
	view.focus_mode = Control.FOCUS_ALL
	var own := view.get_path_to(view)
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		view.set_focus_neighbor(side, own)
	view.focus_next = own
	view.focus_previous = own
	view.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	StickScroll.leave_to(view)
	view.grab_focus()
