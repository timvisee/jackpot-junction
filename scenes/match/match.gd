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
@export var joker_catalog: JokerCatalog
@export var offer_size := 3
@export var bot_traits: BotTraitTable
@export var bot_difficulty: BotDifficulty
## Whether the match builds its own HUD. Tests turn it off.
@export var with_hud := true

var state := State.LOBBY
var slots: Array[PlayerSlot] = []
## On a client: a puppet match that renders snapshots from the host.
var puppet := false
## Shown on the lobby panel, for example the host's address and port.
var lobby_hint := ""
## The slot the local player controls in a puppet match, -1 until assigned.
var local_slot := -1
var arena: Arena
var camera_rig: CameraRig
var bullets: BulletSystem
var hud: MatchHud
var nav: ArenaNav
var countdown_left := 0.0
var time_left := 0.0
## The one source of randomness in a match, seeded at start so online play can replicate it.
var rng := RandomNumberGenerator.new()
## Puppet nodes by the host's instance ids, kept up to date by [MatchSnapshot].
var puppet_karts: Dictionary[int, Kart] = {}
var puppet_bullets: Dictionary[int, Bullet] = {}
var puppet_pickups: Dictionary[int, Pickup] = {}
var puppet_turrets: Dictionary[int, Turret] = {}
var puppet_bombs: Dictionary[int, Bomb] = {}

var _inputs: Array[KartInput] = []
var _colors: Array[int] = []
var _seed := 0


func _ready() -> void:
	add_to_group(&"match")
	if rules == null:
		rules = load("res://data/match/default.tres")
	if power_ups == null:
		power_ups = load("res://data/powerups/first_set.tres")
	if joker_catalog == null:
		joker_catalog = load("res://data/jokers/catalog.tres")
	if bot_traits == null:
		bot_traits = load("res://data/ai/traits.tres")
	if bot_difficulty == null:
		bot_difficulty = load("res://data/ai/normal.tres")


## Builds the arena, spawns one kart per input and starts the countdown. A zero seed picks a
## random one; [param colors] gives each slot its colour index, slot order when empty.
func start(inputs: Array[KartInput], seed: int = 0, colors: Array[int] = []) -> void:
	_inputs = inputs
	_colors = colors
	_seed = seed if seed != 0 else randi()
	rng.seed = _seed
	arena = ARENA_SCENE.instantiate()
	arena.name = "Arena"
	add_child(arena)
	arena.start_economy(rules, rng, power_ups)
	nav = ArenaNav.new(arena.grid)
	for i: int in arena.crates.size():
		var cell := arena.grid.crates[i]
		arena.crates[i].destroyed.connect(func(_by: int) -> void: nav.set_cell_blocked(cell, false))
		arena.crates[i].respawned.connect(func() -> void: nav.set_cell_blocked(cell, true))
	arena.junction.bank_started.connect(_on_bank_started)
	arena.junction.bank_tick.connect(_on_bank_tick)
	arena.junction.bank_completed.connect(_on_bank_completed)
	for pad: FlushPad in arena.flush_pads:
		pad.claimed.connect(_on_pad_claimed)
	arena.crate_broken.connect(_on_stat_crate)
	Events.joker_taken.connect(_on_stat_joker)
	Events.life_restored.connect(_on_stat_life)
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
		var slot := PlayerSlot.new(i, inputs[i], colors[i] if i < colors.size() else -1)
		slots.append(slot)
		_spawn_kart(slot, arena.spawn_points[i % arena.spawn_points.size()])
		karts.append(slot.kart)
	camera_rig.targets = karts
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
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
	nav = null
	start(_inputs, 0, _colors)


func _exit_tree() -> void:
	if Events.joker_taken.is_connected(_on_stat_joker):
		Events.joker_taken.disconnect(_on_stat_joker)
	if Events.life_restored.is_connected(_on_stat_life):
		Events.life_restored.disconnect(_on_stat_life)
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.disconnect(_on_joy_connection_changed)


## A human joins on [param device], GAME.md 9.2: they take over a bot kart with its score, pot,
## jokers and item, or spawn fresh in a free slot. Returns null when nobody can join.
func join_human(device: int) -> PlayerSlot:
	for slot: PlayerSlot in slots:
		if slot.is_local_human() and slot.device() == device:
			return null
	_resolve_any_device(device)
	return _join_with_input(PlayerInput.new(device))


func _join_with_input(input: KartInput) -> PlayerSlot:
	for slot: PlayerSlot in slots:
		if not slot.is_human():
			_make_human(slot, input)
			return slot
	if slots.size() >= rules.max_players or arena == null:
		return null
	var slot := PlayerSlot.new(slots.size(), input, _free_color())
	slots.append(slot)
	var enemies: Array[Vector3] = []
	for other: PlayerSlot in slots:
		if other != slot and other.kart != null and other.kart.alive:
			enemies.append(other.kart.global_position)
	_spawn_kart(slot, pick_spawn(arena.spawn_points, enemies))
	slot.kart.frozen = not is_running()
	slot.kart.protection_left = rules.spawn_protection
	slot.kart.collision_layer = Layers.PROTECTED
	camera_rig.targets.append(slot.kart)
	if hud != null:
		hud.add_block(slot)
	Events.player_joined.emit(slot.index)
	return slot


## A human leaves and a bot takes the wheel.
func leave_human(slot: PlayerSlot) -> void:
	if not slot.is_human():
		return
	slot.input = BotInput.new()
	slot.kart.input = slot.input
	slot.kart.rebuild_stats()
	_attach_brain(slot)
	if hud != null:
		hud.remove_block(slot)
	Events.player_left.emit(slot.index)


## An any-device player settles on one device once someone else joins on another.
func _resolve_any_device(joiner: int) -> void:
	for slot: PlayerSlot in slots:
		var player := slot.input as PlayerInput
		if player == null or player.device != DeviceInput.ANY:
			continue
		var chosen := player.last_device
		if chosen == DeviceInput.ANY or chosen == joiner:
			chosen = DeviceInput.KEYBOARD if joiner >= 0 else 0
		player.device = chosen


func _make_human(slot: PlayerSlot, input: KartInput) -> void:
	var brain := slot.kart.get_node_or_null("Brain")
	if brain != null:
		brain.queue_free()
	slot.input = input
	slot.kart.input = slot.input
	slot.bot_trait = null
	slot.kart.rebuild_stats()
	if hud != null:
		hud.add_block(slot)
	Events.player_joined.emit(slot.index)


func _attach_brain(slot: PlayerSlot) -> void:
	var brain := BotBrain.new()
	brain.name = "Brain"
	brain.setup(slot.kart, self, bot_traits.pick(rng), bot_difficulty, rng)
	slot.kart.add_child(brain)
	slot.bot_trait = brain.bot_trait


func _free_color() -> int:
	var taken: Array[int] = []
	for slot: PlayerSlot in slots:
		taken.append(slot.color_index)
	var index := 0
	while index in taken:
		index += 1
	return index


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		return
	for slot: PlayerSlot in slots:
		if slot.is_human() and slot.device() == device:
			leave_human(slot)


func kart_of(slot_index: int) -> Kart:
	return slots[slot_index].kart


## A remote player joins through the network session: like a local join, with a [NetInput].
func join_network(input: NetInput) -> PlayerSlot:
	return _join_with_input(input)


## Builds a client-side match: the arena, camera and HUD without simulation. Slots, karts,
## bullets and pickups appear as snapshots arrive.
func start_puppet() -> void:
	puppet = true
	arena = ARENA_SCENE.instantiate()
	arena.name = "Arena"
	add_child(arena)
	for zone: JackpotZone in arena.jackpot_zones:
		zone.rules = rules
		zone.puppet = true
	arena.junction.puppet = true
	bullets = BulletSystem.new()
	bullets.name = "Bullets"
	bullets.puppet = true
	add_child(bullets)
	camera_rig = CAMERA_SCENE.instantiate()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)
	camera_rig.frame_arena(arena.bounds())
	if with_hud:
		hud = MatchHud.new()
		hud.name = "Hud"
		hud.match_node = self
		add_child(hud)


## Tells a puppet match which slot the local player has.
func set_local_slot(index: int) -> void:
	local_slot = index


## Parks a started match in the lobby, karts frozen and the clock stopped, until the host begins.
func hold_in_lobby() -> void:
	_set_frozen(true)
	_set_state(State.LOBBY)


## Leaves the lobby into the countdown.
func begin_from_lobby() -> void:
	if state != State.LOBBY or puppet:
		return
	countdown_left = rules.countdown
	_set_state(State.COUNTDOWN)


## The host's description of the whole match for online clients, see [MatchSnapshot].
func build_snapshot() -> Dictionary:
	return MatchSnapshot.build(self)


## Renders a host snapshot on a puppet match, see [MatchSnapshot].
func apply_snapshot(data: Dictionary) -> void:
	MatchSnapshot.apply(self, data)


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
	kart.color_index = slot.color_index
	kart.input = slot.input
	kart.rules = rules
	kart.rng = rng
	kart.bullet_system = bullets
	kart.position = point
	add_child(kart)
	kart.face(arena.junction_position - point)
	kart.died.connect(_on_kart_died.bind(slot))
	kart.joker_dropped.connect(_on_joker_dropped.bind(slot))
	kart.fired.connect(func(shots: Array[Bullet]) -> void: slot.stats.add(&"bullets", shots.size()))
	kart.coins_collected.connect(func(amount: int) -> void: slot.stats.add(&"coins", amount))
	kart.item_used.connect(func(_item: PowerUp) -> void: slot.stats.add(&"items"))
	kart.turbo_taken.connect(func(_direction: Vector3) -> void: slot.stats.add(&"turbo_pads"))
	kart.mult_changed.connect(_on_stat_mult.bind(slot))
	slot.kart = kart
	if slot.input is BotInput:
		_attach_brain(slot)


func _physics_process(delta: float) -> void:
	if puppet:
		return
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
			_step_stats(delta)


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
		if slot.kart.alive:
			continue
		if slot.offer != null and not slot.offer.is_done() and slot.is_human():
			slot.input.poll(delta)
			slot.offer.poll_input(slot.input)
		slot.respawn_left = maxf(slot.respawn_left - delta, 0.0)
		if slot.respawn_left <= 0.0 and (slot.offer == null or slot.offer.is_done()):
			slot.offer = null
			_respawn(slot)


func _check_target() -> void:
	for slot: PlayerSlot in slots:
		if slot.banked >= rules.target_score:
			_finish()
			return


## The death sequence from GAME.md 3.6, bent by jokers: bank a share, drop coins and maybe a
## joker or the item, credit the killer, reset the pot, offer jokers, start the respawn timer.
func _on_kart_died(cause: StringName, killer_slot: int, slot: PlayerSlot) -> void:
	var kart := slot.kart
	slot.stats.add(&"deaths")
	slot.stats.add(&"coins_lost", kart.pot.coins)
	if cause == &"pit":
		slot.stats.add(&"pit_deaths")
	if killer_slot == slot.index:
		slot.stats.add(&"self_kills")
	var death := DeathOutcome.from_rules(rules)
	for joker: Joker in kart.jokers.jokers:
		joker.modify_death(kart, death)
		joker.on_death(kart)
	var killer: PlayerSlot = null
	if killer_slot >= 0 and killer_slot != slot.index and killer_slot < slots.size():
		killer = slots[killer_slot]
		for joker: Joker in killer.kart.jokers.jokers:
			joker.on_victim_death(killer.kart, kart, death)
	var banked := Scoring.death_bank(kart.pot.coins, kart.pot.mult, death.bank_fraction)
	if banked > 0:
		slot.banked += banked
		Events.death_banked.emit(slot.index, banked)
	var position := kart.global_position
	var stolen := 0
	if killer != null and death.steal_fraction > 0.0 and killer.kart.alive:
		stolen = floori(kart.pot.coins * death.steal_fraction)
		killer.kart.collect_coins(stolen, null)
	var drop := Scoring.death_drop(kart.pot.coins - stolen, death.drop_fraction, death.drop_max)
	if drop > 0:
		arena.spawn_chips(position, drop, rules.dropped_chip_lifetime, 0.0, true)
	for i: int in death.joker_drop_count:
		if kart.jokers.count() > 0 and rng.randf() < death.joker_drop_chance:
			var dropped := kart.jokers.remove_at(rng.randi_range(0, kart.jokers.count() - 1))
			arena.spawn_floor_joker(position, dropped, rules.floor_item_lifetime)
	if kart.held_item != null:
		if rng.randf() < death.item_drop_chance:
			arena.spawn_floor_item(position, kart.held_item, rules.floor_item_lifetime)
		kart.held_item = null
	if killer != null:
		killer.kills += 1
		if cause == &"bomb":
			killer.stats.add(&"bomb_kills")
		if killer.kart.alive:
			killer.kart.gain_mult(rules.kill_mult, &"kill")
			killer.kart.refill_nitro(killer.kart.stats.nitro_kill_refill)
	kart.pot.reset()
	slot.deaths += 1
	slot.respawn_left = rules.respawn_delay
	slot.offer = _make_offer(slot)
	Events.kart_killed.emit(slot.index, killer_slot, cause)
	_check_target()


## A flush pad changed hands. Holding all four at once is a Royal Flush, GAME.md 3.9: a mult
## bonus and a full nitro tank, and the pads clear and rest for a while.
func _on_pad_claimed(_pad: FlushPad, kart: Kart) -> void:
	Events.pad_claimed.emit(kart.slot)
	for other: FlushPad in arena.flush_pads:
		if other.owner_slot != kart.slot:
			return
	for other: FlushPad in arena.flush_pads:
		other.clear_and_disable(rules.flush_disable_time)
	kart.gain_mult(rules.flush_mult, &"flush")
	kart.refill_nitro(rules.flush_nitro_refill)
	if kart.slot < slots.size():
		slots[kart.slot].stats.add(&"flushes")
	if camera_rig != null:
		camera_rig.shake(0.4)
	Events.flush_completed.emit(kart.slot)


## Distance, drifting, nitro time and peak mult, counted every tick while the match runs.
func _step_stats(delta: float) -> void:
	for slot: PlayerSlot in slots:
		var kart := slot.kart
		if kart == null or not kart.alive or kart.frozen:
			continue
		var distance := kart.motor.speed() * delta
		slot.stats.add(&"driven", distance)
		if kart.motor.drifting:
			slot.stats.add(&"drifted", distance)
		if kart.nitro_active:
			slot.stats.add(&"nitro", delta)
		slot.stats.peak(&"max_mult", kart.pot.mult)


func _on_stat_mult(_amount: float, reason: StringName, slot: PlayerSlot) -> void:
	if reason == &"graze":
		slot.stats.add(&"grazes")


func _on_stat_crate(by_slot: int) -> void:
	if by_slot >= 0 and by_slot < slots.size():
		slots[by_slot].stats.add(&"crates")


func _on_stat_joker(slot: int, _joker: StringName) -> void:
	if not puppet and slot >= 0 and slot < slots.size():
		slots[slot].stats.add(&"jokers")


func _on_stat_life(slot: int) -> void:
	if not puppet and slot >= 0 and slot < slots.size():
		slots[slot].stats.add(&"lives_restored")


## Offers jokers for the respawn. Bots choose at once; humans steer the offer while dead.
func _make_offer(slot: PlayerSlot) -> JokerOffer:
	var kart := slot.kart
	var choices := joker_catalog.offer(rng, kart.offer_count(offer_size), kart.jokers.ids())
	var offer := JokerOffer.new(kart, choices)
	if not offer.is_done():
		Events.joker_offered.emit(slot.index)
	if not slot.is_human() and not offer.is_done():
		offer.take(rng.randi_range(0, choices.size() - 1))
		if offer.stage == JokerOffer.Stage.REPLACING:
			offer.replace(rng.randi_range(0, kart.jokers.count() - 1))
	return offer


func _on_joker_dropped(joker: Joker, slot: PlayerSlot) -> void:
	arena.spawn_floor_joker(slot.kart.global_position, joker, rules.floor_item_lifetime)


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
	if kart.slot < slots.size():
		slots[kart.slot].stats.add(&"banks")
		slots[kart.slot].stats.peak(&"biggest_bank", total)
	Events.bank_completed.emit(kart.slot, coins, mult, total)
	for other: PlayerSlot in slots:
		if other.kart == kart:
			continue
		var bonus := 0
		for joker: Joker in other.kart.jokers.jokers:
			bonus += joker.on_other_bank_completed(other.kart, kart.slot, total)
		if bonus > 0:
			other.banked += bonus
			Events.bank_tick.emit(other.index, bonus)
	_check_target()


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
