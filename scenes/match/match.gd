class_name Match
extends Node3D
## Runs one match, GAME.md 3.6 and 3.8: builds the arena, spawns a kart per slot, runs the
## countdown, the timer, Last Call and the results, and applies the death sequence. Zones and
## karts report through signals; the match is the only place that changes banked scores.

enum State { LOBBY, COUNTDOWN, PLAYING, LAST_CALL, OVERTIME, RESULTS }

const ARENA_SCENE := preload("res://scenes/arena/arena.tscn")
const KART_SCENE := preload("res://scenes/kart/kart.tscn")
const CAMERA_SCENE := preload("res://scenes/camera/camera_rig.tscn")
## How hard the top excitement level thumps the camera on the beat, and how much harder on
## the first beat of the bar. This is the only effect that moves what the player is aiming
## through, so it is kept to a thump rather than a shake.
const BEAT_TREMBLE := 2.0
const BEAT_DOWNBEAT := 1.4
## Seconds before looking again when there was nobody worth putting a bounty on.
const BOUNTY_RETRY := 5.0
## Lamps on the start gantry, GAME.md 8.3. The rack and the start tones are one countdown: a
## lamp lights and a tone plays together, so however long the countdown is set to, there are
## this many of both. Three of them over the usual three seconds is a lamp a second, which is
## the pace anyone counting a field down actually counts at.
const COUNTDOWN_LAMPS := 3

@export var rules: MatchRules
@export var power_ups: PowerUpTable
@export var joker_catalog: JokerCatalog
@export var offer_size := 3
@export var bot_traits: BotTraitTable
@export var bot_difficulty: BotDifficulty
## Whether the match builds its own HUD. Tests turn it off.
@export var with_hud := true
## The map to build. The arena scene's own default is used when this is left empty.
@export var arena_layout: ArenaLayout

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
## How hot the match feels, read by the music, the arena lights and the camera.
var intensity: MatchIntensity
## Calls out the kills worth calling out, GAME.md 3.12.
var announcer: Announcer
## What the bots copy from the players, and how hard they are trying.
var bot_mirror := BotMirror.new()
## The slot with a price on its head, -1 for nobody, and how long the bounty still stands.
var bounty_slot := -1
## Whose flush is still paying out and for how much longer, GAME.md 3.9.
var flush_lock_slot := -1
var flush_lock_left := 0.0
## The board's share of a coin, so every pad pays on the same beat however slowly they pay.
var flush_change := 0.0
## Seconds until the table throws another joker onto the floor, GAME.md 3.11.
var wild_joker_left := 0.0
var bounty_left := 0.0
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
var puppet_stains: Dictionary[int, OilStain] = {}

var _inputs: Array[KartInput] = []
var _colors: Array[int] = []
var _seed := 0
## Seconds until the next bounty may be called.
var _bounty_wait := 0.0


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
	arena = _build_arena()
	arena.start_economy(rules, rng, power_ups, joker_catalog)
	nav = ArenaNav.new(arena.grid)
	for i: int in arena.crates.size():
		var cell := arena.grid.crates[i]
		arena.crates[i].destroyed.connect(func(_by: int) -> void: nav.set_cell_blocked(cell, false))
		arena.crates[i].respawned.connect(func() -> void: nav.set_cell_blocked(cell, true))
	arena.junction.bank_started.connect(_on_bank_started)
	arena.junction.bank_tick.connect(_on_bank_tick)
	arena.junction.bank_completed.connect(_on_bank_completed)
	for pad: FlushPad in arena.flush_pads:
		pad.decay = rules.flush_pad_decay
		pad.claimed.connect(_on_pad_claimed)
	arena.crate_broken.connect(_on_stat_crate)
	arena.target_struck.connect(_on_target_struck)
	# Guarded, because a rematch runs this again on the same node: the arena and the karts are
	# rebuilt but the match itself is not, and the engine refuses a connection it already has.
	if not Events.joker_taken.is_connected(_on_stat_joker):
		Events.joker_taken.connect(_on_stat_joker)
	if not Events.life_restored.is_connected(_on_stat_life):
		Events.life_restored.connect(_on_stat_life)
	if not Events.jackpot_collected.is_connected(_on_stat_jackpot):
		Events.jackpot_collected.connect(_on_stat_jackpot)
	if not Events.drift_boosted.is_connected(_on_stat_drift_boost):
		Events.drift_boosted.connect(_on_stat_drift_boost)
	if not Events.oil_hit.is_connected(_on_stat_oil):
		Events.oil_hit.connect(_on_stat_oil)
	for zone: JackpotZone in arena.jackpot_zones:
		zone.filled.connect(
			func(filled: JackpotZone) -> void: Events.jackpot_full.emit(filled.index)
		)
		zone.collected.connect(
			func(kart: Kart, chips: int) -> void: Events.jackpot_collected.emit(kart.slot, chips)
		)
	_build_systems(false)
	var karts: Array[Node3D] = []
	for i: int in mini(inputs.size(), rules.max_players):
		var slot := PlayerSlot.new(i, inputs[i], colors[i] if i < colors.size() else -1)
		slots.append(slot)
		_spawn_kart(slot, arena.spawn_points[i % arena.spawn_points.size()])
		karts.append(slot.kart)
	camera_rig.targets = karts
	_refresh_listener()
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_build_hud()
	time_left = rules.duration
	_bounty_wait = rules.bounty_first_delay
	_set_frozen(true)
	_begin_countdown()


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
	if Events.jackpot_collected.is_connected(_on_stat_jackpot):
		Events.jackpot_collected.disconnect(_on_stat_jackpot)
	if Events.drift_boosted.is_connected(_on_stat_drift_boost):
		Events.drift_boosted.disconnect(_on_stat_drift_boost)
	if Events.oil_hit.is_connected(_on_stat_oil):
		Events.oil_hit.disconnect(_on_stat_oil)
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
	_refresh_listener()
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
	slot.kart.enable_sound(true, true)
	_attach_brain(slot)
	_refresh_listener()
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
	slot.kart.enable_sound(true, not slot.is_local_human())
	_refresh_listener()
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


## What a host and a client both have around the arena: the bullets, the excitement meter and
## the camera framing the floor. The only difference is whether the bullets are driven here or
## replayed from snapshots, so everything else stays one description rather than two that have
## to be kept in step by hand.
func _build_systems(from_snapshots: bool) -> void:
	bullets = BulletSystem.new()
	bullets.name = "Bullets"
	bullets.puppet = from_snapshots
	add_child(bullets)
	_add_intensity()
	camera_rig = CAMERA_SCENE.instantiate()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)
	camera_rig.frame_arena(arena.bounds())


## The HUD, when this build wants one. It reads the slots as it is built, so a host adds it once
## the karts are in and a client adds it empty and lets the snapshots fill it.
func _build_hud() -> void:
	if not with_hud:
		return
	hud = MatchHud.new()
	hud.name = "Hud"
	hud.match_node = self
	add_child(hud)


## The excitement meter, on the host and on a client alike: both see the same events and the
## same snapshot, so the music and the lights wind up together.
func _add_intensity() -> void:
	intensity = MatchIntensity.new()
	intensity.name = "Intensity"
	intensity.match_node = self
	add_child(intensity)
	announcer = Announcer.new()
	announcer.name = "Announcer"
	add_child(announcer)


## Instantiates the arena on the chosen map. The layout has to be in place before the node
## enters the tree, because that is when it builds itself.
func _build_arena() -> Arena:
	var built: Arena = ARENA_SCENE.instantiate()
	built.name = "Arena"
	if arena_layout != null:
		built.layout = arena_layout
	add_child(built)
	return built


func kart_of(slot_index: int) -> Kart:
	return slots[slot_index].kart


## A remote player joins through the network session: like a local join, with a [NetInput].
func join_network(input: NetInput) -> PlayerSlot:
	return _join_with_input(input)


## Builds a client-side match: the arena, camera and HUD without simulation. Slots, karts,
## bullets and pickups appear as snapshots arrive.
func start_puppet() -> void:
	puppet = true
	arena = _build_arena()
	for zone: JackpotZone in arena.jackpot_zones:
		zone.rules = rules
		zone.puppet = true
	arena.junction.puppet = true
	for crate: Crate in arena.crates:
		crate.puppet = true
	_build_systems(true)
	_build_hud()


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
	_begin_countdown()


## How many lamps of the start gantry are lit, GAME.md 8.3, first one the moment the field is
## held and the last as the flag drops. The rack and the start tones both read this, so what a
## player sees and what they hear are the same countdown however long it is set to.
func countdown_lamps() -> int:
	if rules == null or rules.countdown <= 0.0:
		return COUNTDOWN_LAMPS
	var run := 1.0 - clampf(countdown_left / rules.countdown, 0.0, 1.0)
	return clampi(floori(run * COUNTDOWN_LAMPS) + 1, 1, COUNTDOWN_LAMPS)


## Holds the field on the grid with the first lamp lit and its tone played.
func _begin_countdown() -> void:
	countdown_left = rules.countdown
	_set_state(State.COUNTDOWN)
	if rules.countdown > 0.0:
		Events.countdown_tick.emit(countdown_lamps())


## The host's description of the whole match for online clients, see [MatchSnapshot].
func build_snapshot() -> Dictionary:
	return MatchSnapshot.build(self)


## Renders a host snapshot on a puppet match, see [MatchSnapshot].
func apply_snapshot(data: Dictionary) -> void:
	MatchSnapshot.apply(self, data)


## The end of the match, whether that is the clock running down or the sudden death after it.
## Both mean the same thing to anyone watching: there is no lap after this one.
func in_the_finale() -> bool:
	return state == State.LAST_CALL or state == State.OVERTIME


func is_running() -> bool:
	return state == State.PLAYING or state == State.LAST_CALL or state == State.OVERTIME


## Slots ranked by banked score, then kills, then fewest deaths.
func standings() -> Array[PlayerSlot]:
	var ranked := slots.duplicate()
	ranked.sort_custom(PlayerSlot.by_banked)
	return ranked


func _set_state(next: State) -> void:
	state = next
	Events.match_state_changed.emit(state)


func _set_frozen(frozen: bool) -> void:
	for slot: PlayerSlot in slots:
		slot.kart.frozen = frozen


## Points the ears at whoever is playing on this machine, GAME.md 8.4.
func _refresh_listener() -> void:
	if camera_rig == null:
		return
	var here: Array[Node3D] = []
	for slot: PlayerSlot in slots:
		if slot.is_local_human() and slot.kart != null:
			here.append(slot.kart)
	camera_rig.listener_targets = here


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
	kart.enable_sound(true, not slot.is_local_human())
	if slot.input is BotInput:
		_attach_brain(slot)


func _physics_process(delta: float) -> void:
	if puppet:
		return
	match state:
		State.COUNTDOWN:
			var before := countdown_lamps()
			countdown_left -= delta
			var now := countdown_lamps()
			if now > before:
				Events.countdown_tick.emit(now)
			if countdown_left <= 0.0:
				_begin_play()
		State.PLAYING, State.LAST_CALL, State.OVERTIME:
			if rules.timed and state != State.OVERTIME:
				time_left -= delta
			if state == State.PLAYING and time_left <= rules.last_call_duration:
				_enter_last_call()
			if state != State.OVERTIME and time_left <= 0.0:
				time_left = 0.0
				if not _enter_overtime():
					return
			if state == State.OVERTIME:
				if _step_overtime():
					return
			else:
				_step_respawns(delta)
			_step_stats(delta)
			bot_mirror.update(self)
			_step_bounty(delta)
			_step_flush_income(delta)
			_step_heat(delta)
			arena.junction.hint = junction_hint()
			arena.junction.winning = junction_wins_it()
			arena.disco.level = intensity.level
			camera_rig.tremble = _beat_tremble()


## The camera's share of the top excitement level, GAME.md 8.4: at level 6 and nowhere else
## the room is felt as well as heard. A thump on every beat and a harder one on the first of
## the bar, each shaped so it has fallen away before the next arrives. The accessibility
## toggle in 8.5 turns all of it off, since this is the one effect that moves the whole view.
func _beat_tremble() -> float:
	if intensity.level < MatchIntensity.LEVELS:
		return 0.0
	var downbeat := BEAT_DOWNBEAT if Audio.music_beat_index() == 0 else 1.0
	return BEAT_TREMBLE * downbeat * pow(1.0 - Audio.music_beat(), 5.0)


## How loudly the Junction should blink: from the biggest pot a local player is carrying,
## GAME.md 3.4. Bots and remote players never make it blink; it is a nudge for whoever is
## watching this screen.
## The kart carrying the bounty, or null when nobody is.
func bounty_kart() -> Kart:
	return kart_of(bounty_slot) if bounty_slot >= 0 else null


## The bounty, GAME.md 3.10: now and then a price goes on the leader's head, and whoever
## takes them out collects it. It lapses on its own if nobody manages it.
func _step_bounty(delta: float) -> void:
	if bounty_slot >= 0:
		bounty_left -= delta
		var kart := kart_of(bounty_slot)
		if bounty_left <= 0.0 or kart == null or not kart.alive:
			_clear_bounty(true)
		return
	_bounty_wait -= delta
	if _bounty_wait > 0.0:
		return
	# Nobody worth calling on yet: look again shortly rather than sitting out a whole interval.
	_bounty_wait = BOUNTY_RETRY
	var ranked := standings()
	if ranked.size() < 2:
		return
	var leader := ranked[0]
	# Only worth calling on a clear leader who is actually out there to be caught.
	if leader.banked - ranked[1].banked < rules.bounty_min_lead:
		return
	if leader.kart == null or not leader.kart.alive:
		return
	_bounty_wait = rng.randf_range(rules.bounty_interval_min, rules.bounty_interval_max)
	bounty_slot = leader.index
	bounty_left = rules.bounty_duration
	leader.kart.set_bounty(true)
	Events.bounty_called.emit(bounty_slot)


func _clear_bounty(lapsed: bool) -> void:
	var was := bounty_slot
	bounty_slot = -1
	bounty_left = 0.0
	var kart := kart_of(was) if was >= 0 else null
	if kart != null:
		kart.set_bounty(false)
	if lapsed and was >= 0:
		Events.bounty_lapsed.emit(was)


## Whether a player on this screen is one cash-out away from taking the match, GAME.md 3.4.
func junction_wins_it() -> bool:
	for slot: PlayerSlot in slots:
		if slot.is_local_human() and slot.would_win(rules.target_score):
			return true
	return false


func junction_hint() -> float:
	var most := 0.0
	for slot: PlayerSlot in slots:
		if slot.is_local_human() and slot.kart != null and slot.kart.alive:
			most = maxf(most, slot.kart.pot.exact_value())
	var span := maxf(rules.junction_hint_full - rules.junction_hint_start, 1.0)
	return clampf((most - rules.junction_hint_start) / span, 0.0, 1.0)


func _begin_play() -> void:
	_set_frozen(false)
	# A rematch in the same room takes the rig off the last winner and hands it back to the levels.
	arena.disco.clear_focus()
	if rules.countdown > 0.0:
		# The flag belongs to the countdown, not to the match starting: a room that holds nobody
		# on a grid drops no flag, so the Garage gets no lights and no tones at all.
		Events.countdown_done.emit()
	_set_state(State.PLAYING)


func _enter_last_call() -> void:
	arena.junction.payout_multiplier = rules.last_call_payout
	_set_state(State.LAST_CALL)


## The clock running out, GAME.md 3.13. With overtime on, the match does not end there: it
## goes to sudden death instead, where nobody comes back and the last kart standing takes
## everything it is carrying. Returns whether overtime was entered; if it was not, the match is
## over and the caller should stop.
func _enter_overtime() -> bool:
	if not rules.overtime or _alive_slots().size() < 2:
		_finish()
		return false
	_set_state(State.OVERTIME)
	return true


## Sudden death, GAME.md 3.13. Nobody respawns, so the field only shrinks; the last one left
## banks the lot and the whistle goes. Returns whether the match ended on this tick.
func _step_overtime() -> bool:
	var standing := _alive_slots()
	if standing.size() > 1:
		return false
	if standing.size() == 1:
		var winner := standing[0]
		var kart := winner.kart
		var won := Scoring.pot_value(kart.pot.coins, kart.pot.mult)
		if won > 0:
			winner.banked += won
			Events.death_banked.emit(winner.index, won)
		kart.pot.reset()
	_finish()
	return true


## Every slot whose kart is still in play. A kart on its way down a pit is already gone.
func _alive_slots() -> Array[PlayerSlot]:
	var standing: Array[PlayerSlot] = []
	for slot: PlayerSlot in slots:
		if slot.kart != null and slot.kart.alive and not slot.kart.falling:
			standing.append(slot)
	return standing


## Ends the match. Pots still unbanked are lost. The karts are not stopped dead: every driver
## lets go of the wheel at the whistle and rolls to a halt, and the rig swings onto the winner.
func _finish() -> void:
	if state == State.RESULTS:
		return
	for slot: PlayerSlot in slots:
		if slot.kart != null:
			slot.kart.coast()
		# Nobody respawns out of the results, so an open joker pick has nothing left to be
		# for. It comes off the screen rather than sitting over the standings being unusable.
		slot.offer = null
	bullets.process_mode = Node.PROCESS_MODE_DISABLED
	_set_state(State.RESULTS)
	spotlight_winner()


## GAME.md 8.1: at the whistle every head leaves its sweep and swings onto whoever won, so the
## winner takes their lap of honour in the spotlight. A winner who is dead at the whistle has
## nothing to light, so the rig is left as it is. Public because a client reaches the whistle by
## being told about it rather than by running one, and the lap of honour is for everybody.
func spotlight_winner() -> void:
	var winner := standings()[0]
	if winner.kart != null and winner.kart.alive:
		arena.disco.focus(winner.kart)


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
	var collected := 0
	if slot.index == bounty_slot:
		if killer != null:
			collected = rules.bounty_reward
			killer.banked += collected
			killer.stats.add(&"bounties")
			Events.bounty_claimed.emit(killer.index, slot.index, collected)
		_clear_bounty(killer == null)
	if killer != null:
		killer.kills += 1
		if cause == &"bomb":
			killer.stats.add(&"bomb_kills")
		if killer.kart.alive:
			killer.kart.gain_mult(rules.kill_mult, &"kill")
			killer.kart.refill_nitro(killer.kart.stats.nitro_kill_refill)
			# A kill patches the killer up, so a wounded kart can fight its way back rather than
			# having to break off for the Junction.
			killer.kart.restore_life()
	kart.pot.reset()
	slot.deaths += 1
	slot.respawn_left = rules.respawn_delay
	# Nobody comes back out of sudden death, so there is nothing to pick a joker for.
	slot.offer = null if state == State.OVERTIME else _make_offer(slot)
	Events.kart_killed.emit(slot.index, killer_slot, cause)
	if camera_rig != null:
		# A kill in a hot match hits harder than the first one of the round.
		camera_rig.shake(0.2 + 0.5 * intensity.share())
	_check_target()


## GAME.md 3.9: every pad a kart is holding trickles coins into its pot, so the pads are worth
## driving over even when a flush is out of reach. A holder who is dead, falling or rolling out
## the end of the match earns nothing while they are; the pad simply waits for them. The
## trickle runs with the room: at the top excitement level of 8.4 the pads pay three times what
## they pay over a quiet opening lap, so a hot match is worth being out in.
func _step_flush_income(delta: float) -> void:
	var rate := rules.flush_pad_income * lerpf(1.0, rules.flush_pad_income_hot, intensity.share())
	var locked := _step_flush_lock(delta)
	# One clock for the whole board rather than one per pad: the pads pay on the same beat, so
	# two pads across the room from each other throw their rings together and a player holding
	# three of them is paid three coins at once instead of a stutter of singles.
	flush_change += rate * delta
	var coins := floori(flush_change)
	if coins <= 0:
		return
	flush_change -= float(coins)
	for pad: FlushPad in arena.flush_pads:
		var slot := locked if locked >= 0 else pad.owner_slot
		if slot < 0 or slot >= slots.size():
			continue
		if locked < 0 and pad.is_disabled():
			continue
		var kart := slots[slot].kart
		if kart == null or not kart.is_active():
			continue
		kart.collect_coins(coins, null)
		# While a flush is resting the pads wear nobody's colour, so the rings say whose flush
		# is still being paid out.
		pad.pop_halo(slots[slot].color() if locked >= 0 else Color.TRANSPARENT)


## The room speeding everything up, GAME.md 8.4. A hot table is not only louder: the Jackpot
## fills faster and holds more, nitro comes back quicker, and past a certain heat the table
## starts throwing good jokers onto the floor. A finale where nobody has anything left to spend
## is a finale where nobody does anything.
func _step_heat(delta: float) -> void:
	var share := intensity.share()
	var last_call := rules.last_call_accrual if state == State.LAST_CALL else 1.0
	for zone: JackpotZone in arena.jackpot_zones:
		zone.accrual_multiplier = lerpf(1.0, rules.jackpot_accrual_hot, share) * last_call
		zone.cap_multiplier = lerpf(1.0, rules.jackpot_cap_hot, share)
	var nitro := lerpf(1.0, rules.nitro_recharge_hot, share)
	for slot: PlayerSlot in slots:
		if slot.kart != null:
			slot.kart.nitro_recharge_scale = nitro
	_step_wild_jokers(delta)


## Good cards turning up on the floor once the room is going, GAME.md 3.11. Nothing common is
## ever thrown out this way: a late match is where the jokers that change how a kart plays come
## from, and they are worth breaking off whatever you were doing for.
func _step_wild_jokers(delta: float) -> void:
	if joker_catalog == null or intensity.level < rules.wild_joker_level:
		wild_joker_left = rules.wild_joker_interval
		return
	wild_joker_left -= delta * (1.0 if intensity.level >= MatchIntensity.LEVELS else 0.5)
	if wild_joker_left > 0.0:
		return
	wild_joker_left = rules.wild_joker_interval
	var joker := joker_catalog.quality(rng, Joker.Rarity.UNCOMMON)
	if joker == null:
		return
	var half := arena.world_size() * 0.5
	var spot := arena.clamp_to_floor(
		Vector3(rng.randf_range(-half.x, half.x), 0.0, rng.randf_range(-half.y, half.y))
	)
	arena.spawn_floor_joker(spot, joker, rules.wild_joker_lifetime)
	Events.wild_joker_dropped.emit(joker.id)


## Whose flush is still paying, or -1 when none is. A Royal Flush clears the board it was won
## on, so without this the reward for winning one is that the thing paying you stops: the four
## pads keep paying the winner for a while as if they were still held, GAME.md 3.9.
func _step_flush_lock(delta: float) -> int:
	if flush_lock_left <= 0.0:
		return -1
	flush_lock_left = maxf(flush_lock_left - delta, 0.0)
	return flush_lock_slot if flush_lock_left > 0.0 else -1


## A flush pad changed hands. Holding all four at once is a Royal Flush, GAME.md 3.9: a mult
## bonus and a full nitro tank, and the pads clear and rest for a while.
func _on_pad_claimed(_pad: FlushPad, kart: Kart) -> void:
	if kart.slot >= 0 and kart.slot < slots.size():
		slots[kart.slot].stats.add(&"pads_taken")
	Events.pad_claimed.emit(kart.slot)
	for other: FlushPad in arena.flush_pads:
		if other.owner_slot != kart.slot:
			return
	for other: FlushPad in arena.flush_pads:
		other.clear_and_disable(rules.flush_disable_time)
	flush_lock_slot = kart.slot
	flush_lock_left = rules.flush_lock_seconds
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
		if kart == null or not kart.is_active():
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


## A shooting target pays the kart that knocked it down, GAME.md 6.2.
func _on_target_struck(by_slot: int, coins: int) -> void:
	if by_slot < 0 or by_slot >= slots.size():
		return
	var slot := slots[by_slot]
	slot.stats.add(&"targets")
	if slot.kart != null and slot.kart.alive:
		slot.kart.collect_coins(coins, null)


func _on_stat_crate(by_slot: int) -> void:
	if by_slot >= 0 and by_slot < slots.size():
		slots[by_slot].stats.add(&"crates")


func _on_stat_joker(slot: int, _joker: StringName) -> void:
	if not puppet and slot >= 0 and slot < slots.size():
		slots[slot].stats.add(&"jokers")


func _on_stat_life(slot: int) -> void:
	if not puppet and slot >= 0 and slot < slots.size():
		slots[slot].stats.add(&"lives_restored")


func _on_stat_jackpot(slot: int, chips: int) -> void:
	if not puppet and slot >= 0 and slot < slots.size():
		slots[slot].stats.add(&"jackpot_chips", chips)


func _on_stat_drift_boost(slot: int) -> void:
	if not puppet and slot >= 0 and slot < slots.size():
		slots[slot].stats.add(&"drift_boosts")


func _on_stat_oil(slot: int) -> void:
	if not puppet and slot >= 0 and slot < slots.size():
		slots[slot].stats.add(&"oil_spins")


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
