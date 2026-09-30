class_name Pickup
extends Area3D
## Something a kart drives over and takes. Sits on the pickup layer; the kart's pickup area
## detects it and calls [method collect]. Subclasses build their look and apply their effect.

signal collected(pickup: Pickup, kart: Kart)

const SPIN_SPEED := 2.0
const BOB_HEIGHT := 0.06
const BOB_SPEED := 3.0
## How long a pickup takes to drop out of sight down a pit, and how fast it sinks.
const FALL_TIME := 0.8
const FALL_SPEED := 2.6
## Being thrown clear of whatever dropped it, GAME.md 8.3: how long it is in the air, how high
## it arcs, and how far above the floor it leaves from. The mirror of being drawn into a kart.
const THROW_TIME := 0.3
const THROW_LIFT := 0.45
const THROW_HEIGHT := 0.7
## How long a client stands by having taken a pickup itself before putting it back for want of
## the host agreeing, GAME.md 10.3. The host's word is a round trip away.
const PREDICTED_HOLD := 1.0
## How big the pickup is to a kart reaching for it, and how high a kart reaches from.
const RADIUS := 0.35
const REACH_HEIGHT := 0.4

## Seconds before the pickup vanishes on its own; 0 keeps it forever.
var lifetime := 0.0
## Set when the pickup landed over a pit: it drops out of sight instead of settling.
var falling := false
## Height the visual hovers at, the center of its bob. Subclasses set it in [method
## _build_visual] so the mesh clears the floor instead of sinking into it.
var hover := 0.35

var _age := 0.0
var _fall := 0.0
## Where it was thrown from and how much of the throw is left, or zero when it was simply put
## down somewhere.
var _thrown_from := Vector3.ZERO
var _thrown_left := 0.0
var _taken := false
## How long this client still stands by having taken it, see [method predict_take].
var _predicted_left := 0.0
var _base_y := 0.3
var _visual: Node3D


func _ready() -> void:
	collision_layer = Layers.PICKUP
	collision_mask = 0
	monitoring = false
	add_to_group(&"pickups")
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	shape.shape = sphere
	add_child(shape)
	_base_y = position.y
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_build_visual(_visual)


func _process(delta: float) -> void:
	if _predicted_left > 0.0:
		_predicted_left = maxf(_predicted_left - delta, 0.0)
		if _predicted_left <= 0.0:
			_put_back()
		return
	if _visual == null:
		return
	if falling:
		_step_fall(delta)
		return
	_age += delta
	if _thrown_left > 0.0:
		_step_throw(delta)
	else:
		_visual.rotation.y += SPIN_SPEED * delta
		_visual.position.y = hover + sin(_age * BOB_SPEED) * BOB_HEIGHT
	if lifetime > 0.0:
		if _age >= lifetime:
			queue_free()
		elif lifetime - _age < 3.0:
			_visual.visible = fmod(_age, 0.3) < 0.2


## Thrown clear of whatever dropped it, GAME.md 8.3: the mirror of being drawn into a kart. It
## has already been put where it lands, so what flies is the look of it, out of [param origin]
## and down onto the spot it is going to lie on.
func throw_from(origin: Vector3) -> void:
	_thrown_from = origin + Vector3(0.0, THROW_HEIGHT, 0.0)
	_thrown_left = THROW_TIME


## The throw in progress, for a client to draw the same one, GAME.md 10.3: where it is flying
## from and how much of the flight is left. Empty once it has landed, which is most of a
## pickup's life, so it costs nothing to carry.
func throw_state() -> Array:
	return [] if _thrown_left <= 0.0 else [_thrown_from, _thrown_left]


## Picks the same throw up part way through on a client. Cosmetic the whole way: the pickup is
## already lying where it lands on both machines, and this is only the look of it getting there.
func resume_throw(from: Vector3, left: float) -> void:
	_thrown_from = from
	_thrown_left = left


## Out of the kart fast and settling slowly, growing from nothing as it goes, which is the way
## a taken pickup leaves the floor slowly and arrives fast, run backwards.
func _step_throw(delta: float) -> void:
	_thrown_left = maxf(_thrown_left - delta, 0.0)
	var t := clampf(1.0 - _thrown_left / THROW_TIME, 0.0, 1.0)
	var settle := 1.0 - (1.0 - t) * (1.0 - t)
	var landed := global_position + Vector3(0.0, hover, 0.0)
	_visual.global_position = (
		_thrown_from.lerp(landed, settle) + Vector3(0.0, sin(t * PI) * THROW_LIFT, 0.0)
	)
	_visual.scale = Vector3.ONE * maxf(settle, 0.02)
	_visual.rotation.y += SPIN_SPEED * 3.0 * delta
	if _thrown_left <= 0.0:
		_visual.scale = Vector3.ONE


## Sent down a pit, GAME.md 3.6: it drops out of sight, shrinking, and is gone. Nobody can
## take it on the way down.
func fall_into_pit() -> void:
	falling = true


## Whether this kart may take the pickup right now. Subclasses add their own rule on top of
## this one, which refuses anything already on its way down a pit.
func can_collect(_kart: Kart) -> bool:
	return not falling


## Whether [param kart], its simulation at [param where], is near enough to take it: the reach of
## its pickup area, GAME.md 3.3, against the pickup's own size, the same test the host's physics
## makes of the two.
func within_reach(kart: Kart, where: Vector3) -> bool:
	var from := where + Vector3(0.0, REACH_HEIGHT, 0.0)
	return from.distance_to(global_position) < kart.pickup_reach() + RADIUS


## Taken by this client's own kart on its own word, GAME.md 10.3: into [param kart] the tick it
## got there rather than a round trip later, which is how every pickup feels on the machine
## driving. What it was worth is the host's, and so is saying it is gone, which then finds nothing
## left to fly. Should the host not say so within [constant PREDICTED_HOLD], it is back.
func predict_take(kart: Kart) -> void:
	if _taken or predicted_take():
		return
	_predicted_left = PREDICTED_HOLD
	PickupFlight.take(self, kart)


func predicted_take() -> bool:
	return _predicted_left > 0.0


## The event the host raises when [param kart] takes this, and what with, for a client that took
## it itself to hear it now, see [method Audio.ahead]. Empty for a pickup that says nothing.
func heard_as(_kart: Kart) -> Array:
	return []


## The host never agreed: it was somebody else's, or never there. On the floor again, as it was.
func _put_back() -> void:
	if _visual != null:
		return
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_build_visual(_visual)


func collect(kart: Kart) -> void:
	if _taken or not can_collect(kart):
		return
	_taken = true
	_apply(kart)
	collected.emit(self, kart)
	# It flows into the kart rather than blinking out, GAME.md 8.3, so it is plain who got it.
	PickupFlight.take(self, kart)
	queue_free()


## Sinking into the hole: down, spinning and shrinking, then gone.
func _step_fall(delta: float) -> void:
	_fall += delta
	position.y -= FALL_SPEED * delta
	_visual.rotation.y += SPIN_SPEED * 2.0 * delta
	_visual.scale = Vector3.ONE * maxf(1.0 - _fall / FALL_TIME, 0.05)
	if _fall >= FALL_TIME:
		queue_free()


## Where the pickup is actually being drawn, which is above the floor it sits on and moving
## with its bob. What flies into a kart leaves from here rather than from the floor.
func visual_center() -> Vector3:
	return _visual.global_position if _visual != null else global_position


## Hands the visual over to whatever is going to animate it, leaving the pickup with nothing
## left to draw. Used by [PickupFlight] on the way out.
func detach_visual() -> Node3D:
	if _visual == null:
		return null
	var visual := _visual
	_visual = null
	remove_child(visual)
	return visual


func _build_visual(_parent: Node3D) -> void:
	pass


func _apply(_kart: Kart) -> void:
	pass


## What a thing lying on the floor is made of, GAME.md 8.1: molded plastic, or metal for the
## gold ones. A little of the room's light comes back off the edge of it, which is what keeps a
## chip readable on a dark felt without it having to glow like a lamp.
static func _paint(color: Color, metal := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.metallic_specular = 0.6
	material.roughness = 0.28 if metal > 0.0 else 0.46
	material.rim_enabled = true
	material.rim = 0.4
	material.rim_tint = 0.3
	return material
