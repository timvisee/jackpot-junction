class_name TornPage
extends Control
## The strip torn off the foot of the Final Hand's payout slip, STORY.md 8.4: torn straight across
## the House's page over STATUS, from the tab at its edge, on paper of its own with the tear's
## ragged edge along its top, it leans away from the tab as the tear runs across, and falls off the
## screen, as the invitation's stub fell, 6.1a. Then it is gone, and what was on it with it.

const PAPER := HouseTheme.PAPER
## How long the tear takes to run across, how far the strip leans away meanwhile, how long it takes
## to fall and how far it turns as it does.
const TEAR := 0.45
const LEAN := 0.07
const FALL := 0.9
const TURN := 0.5
## How ragged the torn top is, and how much paper is kept round what was on it.
const RAGGED := 5.0
const ROOM := Vector2(18.0, 14.0)

var _page: Control
var _torn := 0.0
## What it was torn from, which it hangs from until the tear is through however that moves, and
## where it hangs from it; and how long it has been going.
var _from: Control
var _hangs := Vector2.ZERO
var _age := 0.0
var _fell_from := Vector2.ZERO


## [param page], wherever it is on the screen, torn off into [param over] and falling; hanging
## from [param from] until the tear is through, if that is given, wherever it goes meanwhile.
static func off(page: Control, over: Control, from: Control = null) -> TornPage:
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
	torn._from = from
	if from != null:
		torn._hangs = torn.global_position - from.global_position
	page.get_parent().remove_child(page)
	torn.add_child(page)
	page.position = ROOM
	Audio.play_sfx(&"tear", -3.0, 0.08)
	return torn


func _process(delta: float) -> void:
	_age += delta
	if _age < TEAR:
		var share := _age / TEAR
		if _from != null and is_instance_valid(_from):
			global_position = _from.global_position + _hangs
		rotation = LEAN * ease(share, 0.5)
		_torn = share
		_fell_from = position
		queue_redraw()
		return
	var falling := clampf((_age - TEAR) / FALL, 0.0, 1.0)
	var below := get_viewport_rect().size.y + size.y
	position = _fell_from + Vector2(0.0, below * ease(falling, 2.2))
	rotation = lerpf(LEAN, TURN, ease(falling, 2.0))
	modulate.a = 1.0 - clampf((falling - 0.5) * 2.0, 0.0, 1.0)
	_torn = 1.0
	if falling >= 1.0:
		queue_free()


func _draw() -> void:
	var paper := Rect2(Vector2.ZERO, size)
	draw_rect(Rect2(paper.position + Vector2(6.0, 10.0), paper.size), Color(0.0, 0.0, 0.0, 0.28))
	draw_colored_polygon(shape_of(paper), PAPER)
	# The fibers along the tear, where it has run so far from the tab.
	var fibers := _ragged(paper, size.x * (1.0 - _torn))
	if fibers.size() >= 2:
		draw_polyline(fibers, Color(HouseTheme.PAPER_LOW, 0.9), 1.4)


## The paper of [param paper], torn across its top by hand and off the printer along its foot, as
## the strip was torn off and is kept, see [FolderBack].
static func shape_of(paper: Rect2) -> PackedVector2Array:
	var points := _ragged(paper, 0.0)
	var foot := NotePaper.torn(paper, RAGGED, false, true)
	# The torn shape's foot, right to left, after the ragged top left to right.
	for i: int in range(floori(foot.size() * 0.5), foot.size()):
		points.append(foot[i])
	return points


## The top torn by hand from [param from] across to the right edge: uneven, never the same tooth
## twice running.
static func _ragged(paper: Rect2, from: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var x := maxf(from, paper.position.x)
	while x < paper.end.x:
		var bite := RAGGED * (0.5 + 0.5 * sin(x * 0.37) * sin(x * 0.113 + 1.7))
		points.append(Vector2(x, paper.position.y + bite))
		x += 6.0 + 4.0 * absf(sin(x * 0.71))
	points.append(Vector2(paper.end.x, paper.position.y + RAGGED * 0.5))
	return points
