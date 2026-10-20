class_name SpotFraming
extends Node
## The driving test's camera frames the spot the arrow on the floor points at along with the kart,
## see [GuideArrow], once the kart is within [constant REACH] of it, GAME.md 9.4a: a target, the
## parked kart or a pad comes into the shot as the kart nears it, rather than only the arrow saying
## where it is. The spot glides into the framing as a kart new to the shot does, see
## [FramedSpots], and out again once the kart is well away from it.

## How near the kart has to come to the spot, in meters, for the spot to come into the shot, and
## how far it has to go again for it to leave: apart, so a kart on the edge does not pump the
## camera in and out.
const REACH := 15.0
const LET_GO := 17.0

## Whether the spot is framed at all: off only where the camera is wanted on the kart alone, which
## is the tutorial's suites.
static var on := true

var run: TutorialRun
## The spot as the camera frames it, a point on the floor, and whether it is in the shot.
var spot: Node3D
var framed := false


## Puts it on [param for_run]'s camera.
static func add_to(for_run: TutorialRun) -> SpotFraming:
	var framing := SpotFraming.new()
	framing.name = "SpotFraming"
	framing.run = for_run
	for_run.add_child(framing)
	return framing


func _ready() -> void:
	spot = Node3D.new()
	spot.name = "FramedSpot"
	run.match_node.add_child(spot)


func _exit_tree() -> void:
	if is_instance_valid(spot):
		spot.queue_free()


func _physics_process(_delta: float) -> void:
	var rig := run.match_node.camera_rig
	if rig == null:
		return
	var at := run.arrow.target if run.arrow != null else Vector3.INF
	var near := false
	if on and not run.is_over() and at.is_finite():
		var here := run.kart().global_position
		var gap := Vector2(at.x - here.x, at.z - here.z).length()
		near = gap <= (LET_GO if framed else REACH)
	if near:
		spot.global_position = Vector3(at.x, 0.0, at.z)
	if near == framed:
		return
	framed = near
	if near:
		rig.targets.append(spot)
	else:
		rig.targets.erase(spot)
