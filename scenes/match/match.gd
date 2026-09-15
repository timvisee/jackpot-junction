class_name Match
extends Node3D
## Runs one match: builds the arena, spawns a kart per slot, and handles deaths and respawns.
## The states beyond Playing, with the timer, Last Call and results, arrive in M2.

enum State { LOBBY, COUNTDOWN, PLAYING, LAST_CALL, RESULTS }

const ARENA_SCENE := preload("res://scenes/arena/arena.tscn")
const KART_SCENE := preload("res://scenes/kart/kart.tscn")
const CAMERA_SCENE := preload("res://scenes/camera/camera_rig.tscn")

@export var rules: MatchRules

var state := State.LOBBY
var slots: Array[PlayerSlot] = []
var arena: Arena
var camera_rig: CameraRig
var bullets: BulletSystem
## The one source of randomness in a match, seeded at start so online play can replicate it.
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	if rules == null:
		rules = load("res://data/match/default.tres")


## Builds the arena and spawns one kart per input. A zero seed picks a random one.
func start(inputs: Array[KartInput], seed: int = 0) -> void:
	rng.seed = seed if seed != 0 else randi()
	arena = ARENA_SCENE.instantiate()
	arena.name = "Arena"
	add_child(arena)
	bullets = BulletSystem.new()
	bullets.name = "Bullets"
	add_child(bullets)
	camera_rig = CAMERA_SCENE.instantiate()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)
	camera_rig.frame_arena(arena.bounds())
	var karts: Array[Node3D] = []
	for i: int in mini(inputs.size(), rules.max_players):
		var slot := PlayerSlot.new(i, inputs[i])
		slots.append(slot)
		_spawn_kart(slot, arena.spawn_points[i % arena.spawn_points.size()])
		karts.append(slot.kart)
	camera_rig.targets = karts
	_set_state(State.PLAYING)


func kart_of(slot_index: int) -> Kart:
	return slots[slot_index].kart


func _set_state(next: State) -> void:
	state = next
	Events.match_state_changed.emit(state)


func _spawn_kart(slot: PlayerSlot, point: Vector3) -> void:
	var kart: Kart = KART_SCENE.instantiate()
	kart.name = "Kart%d" % slot.index
	kart.slot = slot.index
	kart.input = slot.input
	kart.rules = rules
	kart.bullet_system = bullets
	kart.position = point
	add_child(kart)
	kart.face(arena.junction_position - point)
	kart.died.connect(_on_kart_died.bind(slot))
	slot.kart = kart


func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	for slot: PlayerSlot in slots:
		if slot.kart.alive or slot.respawn_left <= 0.0:
			continue
		slot.respawn_left -= delta
		if slot.respawn_left <= 0.0:
			_respawn(slot)


func _on_kart_died(cause: StringName, killer_slot: int, slot: PlayerSlot) -> void:
	slot.deaths += 1
	if killer_slot >= 0 and killer_slot != slot.index and killer_slot < slots.size():
		slots[killer_slot].kills += 1
	slot.respawn_left = rules.respawn_delay
	Events.kart_killed.emit(slot.index, killer_slot, cause)


func _respawn(slot: PlayerSlot) -> void:
	var enemies: Array[Vector3] = []
	for other: PlayerSlot in slots:
		if other != slot and other.kart.alive:
			enemies.append(other.kart.global_position)
	var point := pick_spawn(arena.spawn_points, enemies)
	slot.kart.respawn(point, arena.junction_position - point, rules.spawn_protection)
	Events.kart_respawned.emit(slot.index)


## The spawn point whose nearest enemy is farthest away. Ties go to the earliest point.
static func pick_spawn(points: Array[Vector3], enemies: Array[Vector3]) -> Vector3:
	var best := points[0]
	var best_score := -INF
	for point: Vector3 in points:
		var score := INF
		for enemy: Vector3 in enemies:
			score = minf(score, point.distance_to(enemy))
		if score > best_score:
			best_score = score
			best = point
	return best
