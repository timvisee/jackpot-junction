extends SceneTree
## Puts the title up and the things looked at closer over it one after another, for
## tools/warmup_check to count what they compile that the warm-up behind the title did not, GAME.md
## 10.7: the license, Kit's folder, a note held up to the eye, and the House's invitation to the
## Final Hand, turned over and taken, its golden ticket coming up from behind it; and under them all
## the invitation that brought the player to the tables, up over the title from the start, as it is
## the first time a profile comes to it, accepted last, its stub torn off. A script run with -s is
## compiled before the game's classes can be named, so everything is loaded by its path.
##
##   godot --path . -s tools/closer_looks.gd -- --story-license --story-notes

## The frame each step is taken on, and the frame it quits on, a few seconds apart so each has
## come all the way up and drawn.
const STEPS := {
	40: "_license",
	160: "_folder",
	280: "_note",
	400: "_invitation",
	520: "_taken",
	640: "_accepted"
}
const DONE := 780

var _frames := 0
var _title: Control
var _up: Node


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		# Nothing the machine's own devices do gets past to the title under the steps, and the title
		# is up as it settles rather than opening, which would take the cursor back mid-way.
		root.gui_disable_input = true
		load("res://scenes/ui/title_intro.gd").set("played", true)
		_title = (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
		root.add_child(_title)
	if STEPS.has(_frames):
		call(STEPS[_frames])
	return _frames >= DONE


func _away() -> void:
	if _up != null and is_instance_valid(_up):
		_up.queue_free()
	_up = null


func _license() -> void:
	_up = load("res://scenes/ui/license_view.gd").call("open", _title, true)


func _folder() -> void:
	_away()
	var profile: RefCounted = root.get_node("/root/Game").get("settings").get("profile")
	_up = load("res://scenes/story/notes_folder.gd").call("open", _title, profile, true)


## The first note of the folder held up to the eye.
func _note() -> void:
	load("res://scenes/story/note_view.gd").call("open", _up, 0)


func _invitation() -> void:
	_away()
	_up = load("res://scenes/story/final_hand_pane.gd").call("add_to", _title)


func _taken() -> void:
	_up.call("_take_the_seat")


## The invitation that brought the player here accepted, its stub torn off and falling.
func _accepted() -> void:
	_away()
	var opening: Node = _title.get("invitation")
	if opening != null:
		opening.get("accept").emit_signal("pressed")
