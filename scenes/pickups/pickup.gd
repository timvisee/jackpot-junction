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

## Seconds before the pickup vanishes on its own; 0 keeps it forever.
var lifetime := 0.0
## Set when the pickup landed over a pit: it drops out of sight instead of settling.
var falling := false
## Height the visual hovers at, the centre of its bob. Subclasses set it in [method
## _build_visual] so the mesh clears the floor instead of sinking into it.
var hover := 0.35

var _age := 0.0
var _fall := 0.0
## Where it was thrown from and how much of the throw is left, or zero when it was simply put
## down somewhere.
var _thrown_from := Vector3.ZERO
var _thrown_left := 0.0
var _taken := false
var _base_y := 0.3
var _visual: Node3D


func _ready() -> void:
	collision_layer = Layers.PICKUP
	collision_mask = 0
	monitoring = false
	add_to_group(&"pickups")
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	shape.shape = sphere
	add_child(shape)
	_base_y = position.y
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_build_visual(_visual)


func _process(delta: float) -> void:
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


static func _unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
