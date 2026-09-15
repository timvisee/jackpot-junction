class_name Match
extends Node3D
## Runs one match, GAME.md 3.6 and 3.8: builds the arena, spawns a kart per slot, runs the
## countdown, the timer, Last Call and the results, and applies the death sequence. Zones and
## karts report through signals; the match is the only place that changes banked scores.

enum State { LOBBY, COUNTDOWN, PLAYING, LAST_CALL, RESULTS }

const ARENA_SCENE := preload("res://scenes/arena/arena.tscn")
const KART_SCENE := preload("res://scenes/kart/kart.tscn")
const CAMERA_SCENE := preload("res://scenes/camera/camera_rig.tscn")

@export var rules: MatchRules
@export var power_ups: PowerUpTable
## Whether the match builds its own HUD. Tests turn it off.
@export var with_hud := true

var state := State.LOBBY
var slots: Array[PlayerSlot] = []
var arena: Arena
var camera_rig: CameraRig
var bullets: BulletSystem
var hud: MatchHud
var countdown_left := 0.0
var time_left := 0.0
## The one source of randomness in a match, seeded at start so online play can replicate it.
var rng := RandomNumberGenerator.new()

var _inputs: Array[KartInput] = []
var _seed := 0


func _ready() -> void:
	if rules == null:
		rules = load("res://data/match/default.tres")
	if power_ups == null:
		power_ups = load("res://data/powerups/first_set.tres")


## Builds the arena, spawns one kart per input and starts the countdown. A zero seed picks a
## random one.
func start(inputs: Array[KartInput], seed: int = 0) -> void:
	_inputs = inputs
	_seed = seed if seed != 0 else randi()
	rng.seed = _seed
	arena = ARENA_SCENE.instantiate()
	arena.name = "Arena"
	add_child(arena)
	arena.start_economy(rules, rng, power_ups)
	arena.junction.bank_started.connect(_on_bank_started)
	arena.junction.bank_tick.connect(_on_bank_tick)
	arena.junction.bank_completed.connect(_on_bank_completed)
	for zone: JackpotZone in arena.jackpot_zones:
		zone.filled.connect(
			func(filled: JackpotZone) -> void: Events.jackpot_full.emit(filled.index)
		)
		zone.collected.connect(
			func(kart: Kart, chips: int) -> void: Events.jackpot_collected.emit(kart.slot, chips)
		)
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
	if with_hud:
		hud = MatchHud.new()
		hud.name = "Hud"
		hud.match_node = self
		add_child(hud)
	time_left = rules.duration
	countdown_left = rules.countdown
	_set_frozen(true)
	_set_state(State.COUNTDOWN)


## Tears everything down and starts again with the same players and a fresh seed.
func rematch() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	slots.clear()
	arena = null
	bullets = null
	camera_rig = null
	hud = null
	start(_inputs, 0)


func kart_of(slot_index: int) -> Kart:
	return slots[slot_index].kart


func is_running() -> bool:
	return state == State.PLAYING or state == State.LAST_CALL


## Slots ranked by banked score, then kills, then fewest deaths.
func standings() -> Array[PlayerSlot]:
	var ranked := slots.duplicate()
	ranked.sort_custom(
		func(a: PlayerSlot, b: PlayerSlot) -> bool:
			if a.banked != b.banked:
				return a.banked > b.banked
			if a.kills != b.kills:
				return a.kills > b.kills
			return a.deaths < b.deaths
	)
	return ranked


func _set_state(next: State) -> void:
	state = next
	Events.match_state_changed.emit(state)


func _set_frozen(frozen: bool) -> void:
	for slot: PlayerSlot in slots:
		slot.kart.frozen = frozen


func _spawn_kart(slot: PlayerSlot, point: Vector3) -> void:
	var kart: Kart = KART_SCENE.instantiate()
	kart.name = "Kart%d" % slot.index
	kart.slot = slot.index
	kart.input = slot.input
	kart.rules = rules
	kart.rng = rng
	kart.bullet_system = bullets
	kart.position = point
	add_child(kart)
	kart.face(arena.junction_position - point)
	kart.died.connect(_on_kart_died.bind(slot))
	slot.kart = kart


func _physics_process(delta: float) -> void:
	match state:
		State.COUNTDOWN:
			countdown_left -= delta
			if countdown_left <= 0.0:
				_begin_play()
		State.PLAYING, State.LAST_CALL:
			time_left -= delta
			if state == State.PLAYING and time_left <= rules.last_call_duration:
				_enter_last_call()
			if time_left <= 0.0:
				time_left = 0.0
				_finish()
				return
			_step_respawns(delta)


func _begin_play() -> void:
	_set_frozen(false)
	_set_state(State.PLAYING)


func _enter_last_call() -> void:
	arena.junction.payout_multiplier = rules.last_call_payout
	for zone: JackpotZone in arena.jackpot_zones:
		zone.accrual_multiplier = rules.last_call_accrual
	_set_state(State.LAST_CALL)


## Ends the match. Pots still unbanked are lost.
func _finish() -> void:
	if state == State.RESULTS:
		return
	_set_frozen(true)
	bullets.process_mode = Node.PROCESS_MODE_DISABLED
	_set_state(State.RESULTS)


func _step_respawns(delta: float) -> void:
	for slot: PlayerSlot in slots:
		if slot.kart.alive or slot.respawn_left <= 0.0:
			continue
		slot.respawn_left -= delta
		if slot.respawn_left <= 0.0:
			_respawn(slot)


func _check_target() -> void:
	for slot: PlayerSlot in slots:
		if slot.banked >= rules.target_score:
			_finish()
			return


## The death sequence from GAME.md 3.6, in order: bank half, drop coins, credit the killer, reset
## the pot, start the respawn timer.
func _on_kart_died(cause: StringName, killer_slot: int, slot: PlayerSlot) -> void:
	var kart := slot.kart
	var banked := Scoring.death_bank(kart.pot.coins, kart.pot.mult, rules.death_bank_fraction)
	if banked > 0:
		slot.banked += banked
		Events.death_banked.emit(slot.index, banked)
	var drop := Scoring.death_drop(kart.pot.coins, rules.death_drop_fraction, rules.death_drop_max)
	if drop > 0:
		arena.spawn_chips(kart.global_position, drop, rules.dropped_chip_lifetime, 0.0, true)
	if kart.held_item != null:
		if rng.randf() < rules.death_item_drop_chance:
			arena.spawn_floor_item(kart.global_position, kart.held_item, rules.floor_item_lifetime)
		kart.held_item = null
	if killer_slot >= 0 and killer_slot != slot.index and killer_slot < slots.size():
		var killer := slots[killer_slot]
		killer.kills += 1
		if killer.kart.alive:
			killer.kart.gain_mult(rules.kill_mult, &"kill")
	kart.pot.reset()
	slot.deaths += 1
	slot.respawn_left = rules.respawn_delay
	Events.kart_killed.emit(slot.index, killer_slot, cause)
	_check_target()


func _respawn(slot: PlayerSlot) -> void:
	var enemies: Array[Vector3] = []
	for other: PlayerSlot in slots:
		if other != slot and other.kart.alive:
			enemies.append(other.kart.global_position)
	var point := pick_spawn(arena.spawn_points, enemies)
	slot.kart.respawn(point, arena.junction_position - point, rules.spawn_protection)
	Events.kart_respawned.emit(slot.index)


func _on_bank_started(kart: Kart) -> void:
	Events.bank_started.emit(kart.slot)


func _on_bank_tick(kart: Kart, points: int) -> void:
	slots[kart.slot].banked += points
	Events.bank_tick.emit(kart.slot, points)
	_check_target()


func _on_bank_completed(kart: Kart, coins: int, mult: float, total: int) -> void:
	Events.bank_completed.emit(kart.slot, coins, mult, total)


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
