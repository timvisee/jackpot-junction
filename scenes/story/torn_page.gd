class_name TornPage
extends Control
## The House's page torn off the Final Hand's payout slip, STORY.md 8.4: taken off the bill where it
## hung, on paper of its own with the perforation's torn edge along its top, it leans away from the
## tab as the tear runs along to the other end, and falls off the screen, as the invitation's stub
## fell, 6.1a. Then it is gone, and what was on it with it.

const PAPER := HouseTheme.PAPER
## How long the tear takes to run along the perforation, how far the page leans away meanwhile, how
## long it takes to fall and how far it turns as it does.
const TEAR := 0.45
const LEAN := 0.07
const FALL := 0.9
const TURN := 0.5
## How ragged the torn top is, and how much paper is kept round what was on it.
const RAGGED := 5.0
const ROOM := Vector2(18.0, 14.0)

var _page: Control
var _torn := 0.0


## [param page], wherever it is on the screen, torn off into [param over] and falling.
static func off(page: Control, over: Control) -> TornPage:
	var torn := TornPage.new()
	torn.name = "TornPage"
	torn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var at := page.get_global_rect()
	over.add_child(torn)
	torn.global_position = at.position - ROOM
	torn.size = at.size + ROOM * 2.0
	# Torn from the tab at its right end, it hangs from its left until the tear is through.
	torn.pivot_offset = Vector2(0.0, 0.0)
	torn._page = page
	page.get_parent().remove_child(page)
	torn.add_child(page)
	page.position = ROOM
	torn._fall()
	return torn


func _fall() -> void:
	Audio.play_sfx(&"tear", -3.0, 0.08)
	var going := create_tween()
	going.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	going.tween_method(_tear, 0.0, 1.0, TEAR)
	going.parallel().tween_property(self, ^"rotation", LEAN, TEAR)
	going.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	var below := get_viewport_rect().size.y + size.y
	going.tween_property(self, ^"position:y", position.y + below, FALL)
	going.parallel().tween_property(self, ^"rotation", TURN, FALL)
	going.parallel().tween_property(self, ^"modulate:a", 0.0, FALL).set_delay(FALL * 0.5)
	going.tween_callback(queue_free)


func _tear(amount: float) -> void:
	_torn = amount
	queue_redraw()


func _draw() -> void:
	var paper := Rect2(Vector2.ZERO, size)
	draw_rect(Rect2(paper.position + Vector2(6.0, 10.0), paper.size), Color(0.0, 0.0, 0.0, 0.28))
	draw_colored_polygon(NotePaper.torn(paper, RAGGED, true, true), PAPER)
	# The holes of the perforation along the torn top, half of each still there, and the tear's run
	# showing as the edge comes away from the tab.
	var x := size.x - 10.0
	var reached := size.x * (1.0 - _torn)
	while x > 10.0:
		var ink := Color(HouseTheme.INK_FAINT, 0.5 if x >= reached else 0.25)
		draw_arc(Vector2(x, 0.0), 3.0, 0.0, PI, 8, ink, 1.2, true)
		x -= 12.0
