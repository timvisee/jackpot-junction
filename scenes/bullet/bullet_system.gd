class_name BulletSystem
extends Node3D
## Owns every bullet in a match and resolves bullet against bullet: two bullets whose sweeps
## this tick came closer than their combined radius both vanish. Runs after the bullets moved.

## How big the flash of a bullet stopped on an untouchable kart is, and how many bits it throws.
const DEFLECT_SIZE := 0.35
const DEFLECT_COUNT := 6
## A scrambler's crackle over the kart it jammed, GAME.md 5.3: its spark blue, how many arcs crawl
## over the kart in each wave, and how far over the kart its bolt strikes down from, see
## [method _on_scrambled].
const SCRAMBLE_INK := Color(0.5, 0.8, 1.0)
const SCRAMBLE_ARCS := 7
const SCRAMBLE_STRIKE := 3.6
## How long after the first the second wave of crackle comes, so the kart crawls with sparks a
## moment rather than for a single flicker.
const SCRAMBLE_WAVE := 0.18

var bullets: Array[Bullet] = []
## On a client the system only holds puppets and never cancels them.
var puppet := false

var _dice := RandomNumberGenerator.new()


func _ready() -> void:
	process_physics_priority = 10
	add_to_group(&"bullet_system")
	_dice.randomize()
	Events.bullet_deflected.connect(_on_bullet_deflected)
	Events.burst.connect(_on_burst)
	Events.chain_arc.connect(_on_chain_arc)
	Events.scrambled.connect(_on_scrambled)
	Events.tracer.connect(_on_tracer)


func _exit_tree() -> void:
	if Events.bullet_deflected.is_connected(_on_bullet_deflected):
		Events.bullet_deflected.disconnect(_on_bullet_deflected)
	if Events.burst.is_connected(_on_burst):
		Events.burst.disconnect(_on_burst)
	if Events.chain_arc.is_connected(_on_chain_arc):
		Events.chain_arc.disconnect(_on_chain_arc)
	if Events.scrambled.is_connected(_on_scrambled):
		Events.scrambled.disconnect(_on_scrambled)
	if Events.tracer.is_connected(_on_tracer):
		Events.tracer.disconnect(_on_tracer)


## A bullet stopped on a kart that could not be hurt: a small flash of its color where it stopped,
## on every screen, the host saying so, since a client's bullets never touch anything.
func _on_bullet_deflected(at: Vector3, color: Color) -> void:
	if is_inside_tree() and get_parent() != null:
		Burst.spawn(get_parent(), at, color, DEFLECT_SIZE, DEFLECT_COUNT)


## An explosive shot burst, see [Blast]: the flash and a little shake on every screen, the host
## having dealt the damage, since a client's bullets never touch anything.
func _on_burst(at: Vector3, radius: float, color: Color) -> void:
	if not is_inside_tree() or get_parent() == null:
		return
	Explosion.spawn(get_parent(), at, radius, color)
	var match_node := get_parent() as Match
	if match_node != null and match_node.camera_rig != null:
		match_node.camera_rig.shake(0.5)


## Chain lightning leaping, GAME.md 5.3: a bolt drawn between the mark it struck and the next, on
## every screen, the host having dealt the damage, see [ZapArc].
func _on_chain_arc(at: Vector3, to: Vector3, color: Color) -> void:
	if is_inside_tree() and get_parent() != null:
		ZapArc.spawn(get_parent(), at, to, color)


## A scrambler's hit, GAME.md 5.3: current crackling over the jammed kart on every screen, so a
## cannon cut off is plain to see, the host having dealt the lock, see [ZapArc].
func _on_scrambled(at: Vector3) -> void:
	if not (is_inside_tree() and get_parent() != null):
		return
	# A bolt strikes down onto the kart and current crawls over it, so a jammed cannon is plain to
	# see: the kart struck and crackling with blue sparks for a moment, see [ZapArc]. The crackle
	# comes in two waves so it lingers rather than flickering once and gone.
	var top := (
		at + Vector3(_dice.randf_range(-0.3, 0.3), SCRAMBLE_STRIKE, _dice.randf_range(-0.3, 0.3))
	)
	ZapArc.spawn(get_parent(), top, at + Vector3(0.0, 0.35, 0.0), SCRAMBLE_INK)
	ZapArc.over(get_parent(), at, SCRAMBLE_INK, _dice, SCRAMBLE_ARCS)
	get_tree().create_timer(SCRAMBLE_WAVE).timeout.connect(_crackle_again.bind(at))


## The scrambler's second wave of crackle over [param at], a short moment after the first, if the
## match is still up, see [method _on_scrambled].
func _crackle_again(at: Vector3) -> void:
	if is_inside_tree() and get_parent() != null:
		ZapArc.over(get_parent(), at, SCRAMBLE_INK, _dice, SCRAMBLE_ARCS)


## A railgun's tracer, GAME.md 5.3: a clean bright beam down the line it fired, on every screen, see
## [ZapArc].
func _on_tracer(at: Vector3, to: Vector3, color: Color) -> void:
	if is_inside_tree() and get_parent() != null:
		ZapArc.beam(get_parent(), at, to, color)


## [param from] is the shooter's center; the bullet checks the way from there to the muzzle.
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
	# Which bullets this tick has already spent, as a flag per bullet rather than a list to
	# search: the pairing is quadratic in the number of bullets, so anything inside it that
	# walks a list of its own answers is quadratic again on top, and a room at its busiest is
	# exactly when that is being paid.
	var spent := PackedByteArray()
	spent.resize(bullets.size())
	var doomed: Array[Bullet] = []
	for i: int in bullets.size():
		if spent[i] == 1:
			continue
		var a := bullets[i]
		for j: int in range(i + 1, bullets.size()):
			if spent[j] == 1:
				continue
			var b := bullets[j]
			# One cannon's own shots pass through each other. A Spread Cannon puts three of them
			# on the same muzzle, and they would otherwise cancel before they had left it.
			if a.owner_slot == b.owner_slot or _friends(a, b):
				continue
			if sweeps_touch(a, b):
				spent[i] = 1
				spent[j] = 1
				doomed.append(a)
				doomed.append(b)
				break
	# Held as their own list rather than walked by index: destroying one takes it out of
	# [member bullets] on the spot, which would shift everything after it under the loop. They were
	# paired as they went in, two by two, so each pair is said once: a shot shot down is an
	# achievement's, GAME.md 8.10, and only this machine saw it.
	for i: int in range(0, doomed.size() - 1, 2):
		Events.bullets_met.emit(doomed[i].owner_slot, doomed[i + 1].owner_slot)
	for bullet: Bullet in doomed:
		bullet.destroy()


## Whether [param a] and [param b] are teammates' shots, which pass each other in the air with
## friendly fire off rather than shooting each other down, GAME.md 3.14.
static func _friends(a: Bullet, b: Bullet) -> bool:
	return a.spares_team and Teams.same(a.owner_team, b.owner_team)


## True when the movement segments of two bullets this tick passed within their combined radius.
## Two sweeps whose middles are further apart than half of each plus both radii cannot have
## touched, and that is nearly every pair in a busy room: the closest points, which allocate,
## are worked out only for the rest, GAME.md 10.7.
static func sweeps_touch(a: Bullet, b: Bullet) -> bool:
	var half_a := (a.global_position - a.previous_position) * 0.5
	var half_b := (b.global_position - b.previous_position) * 0.5
	var reach := half_a.length() + half_b.length() + a.radius + b.radius
	var apart := (a.previous_position + half_a).distance_squared_to(b.previous_position + half_b)
	if apart > reach * reach:
		return false
	var points := Geometry3D.get_closest_points_between_segments(
		a.previous_position, a.global_position, b.previous_position, b.global_position
	)
	return points[0].distance_to(points[1]) <= a.radius + b.radius
