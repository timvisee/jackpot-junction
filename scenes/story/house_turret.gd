class_name HouseTurret
extends Turret
## The House's turret at the Final Hand, STORY.md 8.2: gold, owned by nobody, rising out of the
## floor in a rack's place and seen coming as a rack is, by its tile outlined in gold. Once up it
## fires a burst of three at where the House forecasts its kart will be when the shot gets there,
## not at the kart, which misses anybody who is not where it expected, and it sinks again. The
## House's furniture: nothing of it breaks, rule 6, so rammed or blown up it only sinks the sooner.
## The host's, as every turret is; a client's puppet rises and sinks by the age the snapshot gives.

const SHOTS := 3
const SHOT_EVERY := 0.2
## How long it waits once up before the first shot, and after the last before it sinks.
const SETTLE := 0.3
const AFTER := 0.5
## How far under the floor it waits.
const DEPTH := 1.1

## The slot whose forecast it fires at, and what forecasts it.
var target := -1
var forecast: HouseForecast
var age := 0.0

var _shot := 0
var _outline: MeshInstance3D
var _gold: StandardMaterial3D


func _init() -> void:
	fixture = true
	owner_slot = -1
	color = HouseTheme.FOIL
	lifetime = 1.0e9


func _ready() -> void:
	super._ready()
	add_to_group(HouseRack.GROUP + &"_turrets")
	_gold = StandardMaterial3D.new()
	_gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_gold.albedo_color = HouseTheme.FOIL
	_gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_outline = MeshInstance3D.new()
	_outline.name = "Outline"
	_outline.mesh = HouseRack.outline_mesh(Vector2.ONE * 1.25, HouseRack.OUTLINE)
	_outline.material_override = _gold
	_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Flat on the floor where it rises, not turning with it as it aims.
	_outline.top_level = true
	add_child(_outline)
	lay()


## How long it lasts, outline to sunk.
static func life() -> float:
	return _sinks_at() + HouseRack.SINK


## When it starts to sink.
static func _sinks_at() -> float:
	return HouseRack.MARK + HouseRack.RISE + SETTLE + SHOTS * SHOT_EVERY + AFTER


## How far up it stands at [param at] seconds of age, 0 under the floor to 1 up.
static func height_at(at: float) -> float:
	if at < HouseRack.MARK:
		return 0.0
	if at < HouseRack.MARK + HouseRack.RISE:
		return ease((at - HouseRack.MARK) / HouseRack.RISE, 0.4)
	if at < _sinks_at():
		return 1.0
	return clampf(1.0 - (at - _sinks_at()) / HouseRack.SINK, 0.0, 1.0)


func is_targetable() -> bool:
	return alive and height_at(age) >= 1.0


func take_hit(_bullet: Bullet) -> bool:
	return alive and height_at(age) > 0.5


func destroy() -> void:
	age = maxf(age, _sinks_at())


func _physics_process(delta: float) -> void:
	if puppet:
		lay()
		return
	age += delta
	if age >= life():
		alive = false
		destroyed.emit(self)
		queue_free()
		return
	lay()
	var aim := _aim_point()
	if not aim.is_finite():
		return
	var to_aim := aim - global_position
	var wanted := atan2(-to_aim.x, -to_aim.z)
	var up := height_at(age)
	rotation.y = rotate_toward(rotation.y, wanted, TURN_RATE * 2.0 * delta) if up > 0.0 else wanted
	var first := HouseRack.MARK + HouseRack.RISE + SETTLE
	if _shot >= SHOTS or age < first + _shot * SHOT_EVERY or bullet_system == null:
		return
	_shot += 1
	var direction := Vector3(to_aim.x, 0.0, to_aim.z).normalized()
	if direction.is_zero_approx():
		direction = -global_basis.z
	var muzzle := Vector3(global_position.x, 0.0, global_position.z) + direction * 0.9
	var shot := bullet_system.spawn(-1, muzzle, direction, cannon_stats, color, global_position)
	shot.from_turret = true


## Where to fire: where the House forecasts its kart will be when a shot from here would get
## there, or nowhere when the kart is not there to forecast.
func _aim_point() -> Vector3:
	if forecast == null:
		return Vector3.INF
	var kart := forecast.match_node.kart_of(target)
	if kart == null or not kart.is_active():
		return Vector3.INF
	var speed := maxf(cannon_stats.bullet_speed if cannon_stats != null else 17.0, 1.0)
	var flight := global_position.distance_to(kart.global_position) / speed
	return forecast.ahead_of(kart, minf(flight, HouseForecast.AHEAD))


## Where it stands at its age: risen out of the floor, its tile outlined until it is up.
func lay() -> void:
	position.y = (height_at(age) - 1.0) * DEPTH
	if _outline == null:
		return
	_outline.global_position = Vector3(global_position.x, 0.025, global_position.z)
	_outline.global_rotation = Vector3.ZERO
	var marked := 1.0 - clampf((age - HouseRack.MARK) / HouseRack.RISE, 0.0, 1.0)
	_gold.albedo_color.a = marked * (0.6 + 0.4 * sin(age * 16.0))
	_outline.visible = marked > 0.0
