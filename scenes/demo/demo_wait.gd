class_name DemoWait
extends Label
## How long the title of the demo for a booth stands before the next run, GAME.md 9.8, said under
## the tagline where the menu would be, so the title standing still between runs, or as the demo
## takes over again from the full game, reads as a wait and not as the game stuck: "The next Grand
## Prix starts in 7 seconds", or after the full game "The demo starts in 7 seconds". Kept up to
## date by [DemoHost].

const NEXT_RUN := "The next Grand Prix starts in %s"
const BACK := "The demo starts in %s"


## A wait on [param title], over its Play, which the demo hides, or the one it has already; or null
## for a title without one.
static func on(title: Node) -> DemoWait:
	var kept := title.find_child("DemoWait", true, false) as DemoWait
	if kept != null:
		return kept
	var play := title.get(&"play_button") as Control
	if play == null or play.get_parent() == null:
		return null
	var wait := DemoWait.new()
	wait.name = "DemoWait"
	wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.strong(wait, Type.LARGE, HouseTheme.FOIL)
	wait.visible = false
	play.get_parent().add_child(wait)
	play.get_parent().move_child(wait, play.get_index())
	return wait


## Says [param left] seconds to go, after the full game when [param back], whole seconds rounded
## up, so it never says nothing is left while something is.
func say(left: float, back: bool) -> void:
	var seconds := maxi(ceili(left), 1)
	var counted := "1 second" if seconds == 1 else "%d seconds" % seconds
	text = (BACK if back else NEXT_RUN) % counted
	visible = true
