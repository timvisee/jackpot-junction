class_name BulletSystem
extends Node3D
## Owns every bullet in a match and resolves bullet against bullet: two bullets whose sweeps
## this tick came closer than their combined radius both vanish. Runs after the bullets moved.

var bullets: Array[Bullet] = []
## On a client the system only holds puppets and never cancels them.
var puppet := false


func _ready() -> void:
	process_physics_priority = 10
	add_to_group(&"bullet_system")


## [param from] is the shooter's centre; the bullet checks the way from there to the muzzle.
func spawn(
	owner_slot: int,
	origin: Vector3,
	direction: Vector3,
	stats: CannonStats,
	color: Color,
	from: Vector3 = Vector3.INF
) -> Bullet:
	var bullet := Bullet.new()
	bullet.setup(owner_slot, origin, direction, stats, color, from)
	bullet.expired.connect(_on_bullet_expired)
	add_child(bullet)
	bullets.append(bullet)
	return bullet


func live_count() -> int:
	return bullets.size()


func _on_bullet_expired(bullet: Bullet) -> void:
	bullets.erase(bullet)


func _physics_process(_delta: float) -> void:
	if puppet:
		return
	var doomed: Array[Bullet] = []
	for i: int in bullets.size():
		var a := bullets[i]
		for j: int in range(i + 1, bullets.size()):
			var b := bullets[j]
			if a in doomed or b in doomed:
				continue
			# One cannon's own shots pass through each other. A Spread Cannon puts three of them
			# on the same muzzle, and they would otherwise cancel before they had left it.
			if a.owner_slot == b.owner_slot:
				continue
			if sweeps_touch(a, b):
				doomed.append(a)
				doomed.append(b)
	for bullet: Bullet in doomed:
		bullet.destroy()


## True when the movement segments of two bullets this tick passed within their combined radius.
static func sweeps_touch(a: Bullet, b: Bullet) -> bool:
	var points := Geometry3D.get_closest_points_between_segments(
		a.previous_position, a.global_position, b.previous_position, b.global_position
	)
	return points[0].distance_to(points[1]) <= a.radius + b.radius
