class_name DemoSlip
extends Node
## The payout slip of the demo for a booth going on by itself, GAME.md 9.8, since nobody has to be
## there to press on through it: the map's podium for [constant PODIUM] seconds, then the run's
## standings under it for [constant STANDINGS] and on to the next map; after the last map its podium
## for [constant PODIUM] and on to the party, or to the showdown that settles a level run, and the
## final standings for [constant FINAL] and back to the title. A watcher's bar, 9.3, fills along
## the foot of what it is about to press: the arrow down while it is to turn the page, and the way
## on after. Somebody who sat down can press on sooner.

const PODIUM := 8.0
const STANDINGS := 8.0
const FINAL := 12.0

var screen: ResultsScreen

var _fill: CountdownFill
## What it is waiting to do, the screen's page and way on it waits beside, so a page turned or a way
## changed starts the wait afresh; and how long the wait is and how much of it is left.
var _waiting_on := ""
var _whole := 0.0
var _left := 0.0


static func add_to(results: ResultsScreen) -> DemoSlip:
	var slip := DemoSlip.new()
	slip.name = "DemoSlip"
	slip.screen = results
	results.add_child(slip)
	return slip


func _ready() -> void:
	_fill = CountdownFill.new()
	_fill.name = "DemoFill"
	_fill.visible = false


func _exit_tree() -> void:
	if _fill != null and is_instance_valid(_fill) and _fill.get_parent() == null:
		_fill.free()


func _process(delta: float) -> void:
	var way := screen.way_on() if screen.visible else null
	if way == null:
		_waiting_on = ""
		_fill.visible = false
		return
	var mid_run := screen.match_node.rules.round < screen.match_node.rules.rounds
	var turning := mid_run and screen.bill.aim() == 0 and screen.bill.page_count() > 1
	var waiting_on := "%s/%d/%d" % [way.name, screen.bill.aim(), int(turning)]
	if waiting_on != _waiting_on:
		_waiting_on = waiting_on
		_whole = PODIUM
		if screen.run_shown():
			_whole = FINAL
		elif mid_run and not turning:
			_whole = STANDINGS
		_left = _whole
		_fill.move_onto(screen.pager_on() if turning else way)
		_fill.visible = true
	_left -= delta
	_fill.value = 1.0 - _left / _whole
	if _left > 0.0:
		return
	_waiting_on = ""
	_fill.visible = false
	if turning:
		screen.turn_to(1)
	else:
		way.pressed.emit()
