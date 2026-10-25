class_name Match
extends Node3D
## Runs one match, GAME.md 3.6 and 3.8: builds the arena, spawns a kart per slot, runs the
## countdown, the timer, Last Call and the results, and applies the death sequence. Zones and
## karts report through signals; the match is the only place that changes banked scores.

enum State { LOBBY, COUNTDOWN, PLAYING, LAST_CALL, OVERTIME, RESULTS }

const ARENA_SCENE := preload("res://scenes/arena/arena.tscn")
const KART_SCENE := preload("res://scenes/kart/kart.tscn")
const CAMERA_SCENE := preload("res://scenes/camera/camera_rig.tscn")
## Lamps on the start gantry, GAME.md 8.3: a lamp lights and a tone plays together, this many of
## both however long the countdown is, three over three seconds being the pace anyone counts at.
const COUNTDOWN_LAMPS := 3

@export var rules: MatchRules
@export var power_ups: PowerUpTable
@export var joker_catalog: JokerCatalog
@export var offer_size := 3
@export var bot_traits: BotTraitTable
@export var bot_difficulty: BotDifficulty
## Whether the match builds its own HUD. Tests turn it off.
@export var with_hud := true
## Whether a human's kart gets the drive-and-fire hint beside it at the start, GAME.md 3.8. The
## test track of 9.4a turns it off: that room teaches the controls a sign at a time, and a second
## copy of the same three buttons riding on the kart is the room saying it twice.
@export var with_kart_hints := true
## The map to build. The arena scene's own default is used when this is left empty.
@export var arena_layout: ArenaLayout

var state := State.LOBBY
var slots: Array[PlayerSlot] = []
## Where a slot's kart always comes back to, by slot, rather than the spawn farthest from the
## others, and the way it faces there, its -Z: the Garage's dummies, each parked in its own bay,
## GAME.md 9.4.
var parked: Dictionary[int, Transform3D] = {}
## On a client: a puppet match that renders snapshots from the host.
var puppet := false
## A match point of the room's own for [method would_win], GAME.md 9.4a, or 0 for the rules' target.
var win_at := 0
## On a client, when the host was last heard from, in engine milliseconds, or -1 before it has
## been: a line gone quiet cannot say how slow it is, GAME.md 10.3.
var heard_at := -1
## Shown on the lobby panel, for example the host's address and port.
var lobby_hint := ""
## Whether the next [method start] holds the field on the grid rather than going into the
## countdown: online, while the host waits for everybody to have the room up, GAME.md 10.3. Once:
## a rematch is played by the people who are already here.
var hold_start := false
## How many players have the room up, out of how many are playing, while the lamps are held for
## the rest. Zero while nobody is being waited for.
var loading := Vector2i.ZERO
## The closing party of a Grand Prix while it is on, see [GrandPrixFinale], null otherwise.
var finale: GrandPrixFinale
## The slot the local player controls in a puppet match, -1 until assigned.
var local_slot := -1
## On a client, the input its session is polling and sending to the host: the local player's kart
## is a puppet, but still the one they are steering, so anything drawn from where they are pointing
## reads this. Always a [PlayerInput] or null: a player at this machine is what that type means.
var local_input: PlayerInput
## On a client, every seat played at this machine, by slot, with the input it is played on: the
## first, [member local_slot], and any other player who sat down beside them, GAME.md 10.3.
var local_seats: Dictionary[int, PlayerInput] = {}
var arena: Arena
var camera_rig: CameraRig
## The row of tanks on the table that fill as players bank, GAME.md 8.1.
var score_tanks: ScoreTanks
## The clock on a hoarding over the crowd, GAME.md 8.1.
var led_clock: LedClock
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

## Whether the lobby has been told to begin and is waiting on a joker pick first.
var _starting := false
var _inputs: Array[KartInput] = []
var _colors: Array[int] = []
## What the lobby called each seat, in slot order; an empty entry is handed a funny name.
var _names: Array[String] = []
## How each seat dressed its kart, in slot order, as the four numbers of a [KartStyle].
var _styles: Array = []
## Draws the funny names. Its own generator rather than the match's, so that naming the room
## does not shift every other draw of the match along and turn a seeded match into a different
## one than it was before names existed.
var _names_rng := RandomNumberGenerator.new()
var _seed := 0
## Seconds until the next bounty may be called.
var _bounty_wait := 0.0
## What the match counts off [Events] for the results screen, see [MatchStats.Listener].
var _counting: MatchStats.Listener


func _ready() -> void:
	add_to_group(&"match")
	Emotes.add_to(self)
	BotEmotes.add_to(self)
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
## random one; [param colors] gives each slot its color index, slot order when empty, and
## [param teams] its team in team play, GAME.md 3.14, the smallest for a slot it leaves out.
func start(
	inputs: Array[KartInput],
	seed: int = 0,
	colors: Array[int] = [],
	names: Array[String] = [],
	styles: Array = [],
	teams: Array[int] = []
) -> void:
	_inputs = inputs
	_colors = colors
	_names = names
	_styles = styles
	_seed = seed if seed != 0 else randi()
	rng.seed = _seed
	_names_rng.seed = _seed + 7919
	arena = prepare_arena()
	arena.start_economy(rules, rng, power_ups, joker_catalog)
	nav = ArenaNav.new(arena.grid)
	for i: int in arena.crates.size():
		var cell := arena.grid.crates[i]
		arena.crates[i].destroyed.connect(func(_by: int) -> void: nav.set_cell_blocked(cell, false))
		arena.crates[i].respawned.connect(func() -> void: nav.set_cell_blocked(cell, true))
	for pad: JunctionPad in arena.junctions:
		pad.bank_started.connect(_on_bank_started)
		pad.bank_tick.connect(_on_bank_tick)
		pad.bank_completed.connect(_on_bank_completed)
	for pad: FlushPad in arena.flush_pads:
		pad.decay = rules.flush_pad_decay
		pad.claimed.connect(FlushBoard.claimed.bind(self))
	# Once, because a rematch runs this again on the same node: the arena and the karts are
	# rebuilt but the match itself is not, and the engine refuses a connection it already has.
	_counting = MatchStats.listen(self, _counting)
	arena.crate_broken.connect(_counting.on_crate)
	arena.target_struck.connect(_on_target_struck)
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
		slot.team = Teams.seat(slots, teams, i, rules.teams)
		slot.player_name = _name_for(i, inputs[i])
		slot.style = _style_for(i, inputs[i])
		slots.append(slot)
		_spawn_kart(slot, arena.spawn_points[i % arena.spawn_points.size()])
		karts.append(slot.kart)
	camera_rig.targets = karts
	rules.team_size = Teams.biggest(slots) if rules.teams > 0 else 1
	Showdown.set_up(self)
	refresh_listener()
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_build_hud()
	time_left = rules.duration
	_bounty_wait = rules.bounty_first_delay
	_set_frozen(true)
	if hold_start:
		hold_start = false
		hold_in_lobby()
	else:
		_begin_countdown()


## Tears everything down and starts again with the same players and a fresh seed. The same
## players means whoever is at the table now, not whoever the lobby started with: a player who
## joined mid-match, took over a bot, or arrived over a wire is still here for the next one, and
## starting again from the lobby's list handed their kart to a bot while they went
## on driving it: online that broke every client at once, since each of them kept steering a kart
## the host had given to a bot.
func rematch() -> void:
	var players: Array[KartInput] = []
	var colors: Array[int] = []
	var names: Array[String] = []
	var styles: Array = []
	var teams: Array[int] = []
	for slot: PlayerSlot in slots:
		players.append(slot.input)
		colors.append(slot.color_index)
		teams.append(slot.team)
		# Whoever is at the table keeps the name they have been playing under, including the one
		# they were handed off the list: being renamed between one match and the next would read
		# as somebody else having sat down.
		names.append(slot.player_name)
		styles.append(slot.style.to_array())
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	slots.clear()
	arena = null
	bullets = null
	camera_rig = null
	hud = null
	nav = null
	start(players, 0, colors, names, styles, teams)


func _exit_tree() -> void:
	if _counting != null:
		_counting.stop()
		_counting = null
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.disconnect(_on_joy_connection_changed)


## A human joins on [param device], GAME.md 9.2: they take over a bot kart with its score, pot,
## jokers and item, or spawn fresh in a free slot. Returns null when nobody can join.
func join_human(device: int) -> PlayerSlot:
	for slot: PlayerSlot in slots:
		if slot.plays_on(device):
			return null
	_resolve_any_device(device)
	var seat := _free_seat()
	return _join_with_input(PlayerInput.new(device, seat), Game.settings.seat_color(seat))


func _join_with_input(input: KartInput, wanted_color := -1) -> PlayerSlot:
	var seat := PlayerSlot.bot_seat(slots, wanted_color)
	if seat != null:
		_make_human(seat, input)
		SeatIdentity.paint(self, seat, wanted_color)
		return seat
	if slots.size() >= rules.max_players or arena == null:
		return null
	var slot := _seat_new(input, wanted_color)
	refresh_listener()
	if hud != null:
		hud.add_block(slot)
	Events.player_joined.emit(slot.index)
	return slot


## A bot seated in the middle of a match in a kart of its own, dealt as any bot is, GAME.md 9.1,
## whatever the room's seats, up to a kart a color: the House seating more of its models at the
## Final Hand, STORY.md 8.2. Null where every color is taken, or at a client, which is told.
func seat_bot() -> PlayerSlot:
	if puppet or arena == null or slots.size() >= Palette.PLAYER_COLORS.size():
		return null
	return _seat_new(BotInput.new())


## A seat of its own for [param input], in a fresh kart spawned away from everybody, protected a
## moment as any kart coming in is.
func _seat_new(input: KartInput, wanted_color := -1) -> PlayerSlot:
	var slot := PlayerSlot.new(slots.size(), input, _free_color(wanted_color))
	slot.team = Teams.smallest(slots, rules.teams)
	if not input is BotInput:
		slot.player_name = _name_for(slot.index, input)
		slot.style = _style_for(slot.index, input)
	slots.append(slot)
	var enemies: Array[Vector3] = []
	for other: PlayerSlot in slots:
		var enemy := other != slot and not Teams.teammates(slot, other)
		if enemy and other.kart != null and other.kart.alive:
			enemies.append(other.kart.global_position)
	_spawn_kart(slot, pick_spawn(arena.spawns_for(slots.size()), enemies))
	Showdown.seat_joined(self, slot)
	slot.kart.frozen = not is_running()
	slot.kart.protection_left = rules.spawn_protection
	slot.kart.collision_layer = Layers.PROTECTED
	camera_rig.targets.append(slot.kart)
	return slot


## A human leaves and a bot takes the wheel.
func leave_human(slot: PlayerSlot) -> void:
	if not slot.is_human():
		return
	MatchRecord.seat_leaving(self, slot)
	slot.input = BotInput.new()
	slot.kart.input = slot.input
	slot.kart.rebuild_stats()
	slot.kart.enable_sound(true, true)
	# In the dress of whoever got up: a bot taking a kart over drives it as it was left.
	_attach_brain(slot)
	refresh_listener()
	if hud != null:
		hud.remove_block(slot)
	Events.player_left.emit(slot.index)


## The first local seat nobody here is sitting in, for somebody joining, so they drive the way that
## seat drives, GAME.md 4.2.
func _free_seat() -> int:
	var taken: Array[int] = []
	for slot: PlayerSlot in slots:
		var player := slot.input as PlayerInput
		if player != null:
			taken.append(player.seat)
	var seat := 0
	while seat in taken:
		seat += 1
	return seat


## An any-device player settles on one device once someone else joins on another.
func _resolve_any_device(joiner: int) -> void:
	for slot: PlayerSlot in slots:
		var player := slot.input as PlayerInput
		if player != null and player.device == DeviceInput.ANY:
			player.device = player.settled_beside(joiner)


func _make_human(slot: PlayerSlot, input: KartInput) -> void:
	MatchRecord.seat_taken(self, slot)
	if slot.input is VacantSeat:
		VacantSeat.fill(self, slot)
	var brain := slot.kart.get_node_or_null("Brain")
	if brain != null:
		brain.queue_free()
	slot.input = input
	slot.kart.input = slot.input
	# Somebody sitting down where a bot was goes by their own name, not the bot's.
	if slot.player_name.is_empty() or slot.bot_trait != null:
		slot.player_name = _name_for(slot.index, input)
	slot.bot_trait = null
	# In their own dress rather than the one the seat was left in, GAME.md 4.4: a bot drives the
	# kart as it comes, and whoever left the seat took theirs with them.
	StyleStalls.dress(slot, _style_for(slot.index, input).to_array())
	slot.kart.rebuild_stats()
	slot.kart.enable_sound(true, not slot.is_local_human())
	plate_kart(slot)
	refresh_listener()
	if hud != null:
		hud.add_block(slot)
	Events.player_joined.emit(slot.index)


## A bot at the wheel of [param slot], in the way of driving it was dealt, or one drawn now for a
## bot taking over from somebody who got up.
func _attach_brain(slot: PlayerSlot) -> void:
	var brain := BotBrain.new()
	brain.name = "Brain"
	var chosen := slot.bot_trait if slot.bot_trait != null else bot_traits.pick(rng)
	brain.setup(slot.kart, self, chosen, bot_difficulty, rng)
	slot.kart.add_child(brain)
	slot.bot_trait = brain.bot_trait


## Who the bot in [param slot] is, before its kart is built, GAME.md 3.8, 4.4 and 9.7: its way of
## driving, the dress that goes with it, so the kart comes out dressed, and a robot's name, the two
## drawn off the names' generator and a seed of their own, so they move nothing a seed decides.
func _deal_bot(slot: PlayerSlot) -> void:
	slot.bot_trait = bot_traits.pick(rng, PlayerSlot.traits_in(slots))
	slot.style = bot_traits.dress(_names_rng)
	var taken := PlayerSlot.names_in(slots)
	slot.player_name = bot_traits.bot_name(_seed + 104729 * (slot.index + 1), taken)


## What a slot goes by, GAME.md 3.8: the name the lobby was given for that seat, or one off the
## funny list that nobody in the room is already using. Bots are named as they are dealt, see
## [method _deal_bot]; practice dummies are left nameless and named after what they are instead.
func _name_for(index: int, input: KartInput) -> String:
	var seat := _seat_for(index, input)
	var given := PlayerNames.clean(_names[seat] if seat >= 0 and seat < _names.size() else "")
	if not given.is_empty():
		return given
	if not (input is PlayerInput or input is NetInput):
		return ""
	var taken: Array[String] = []
	for slot: PlayerSlot in slots:
		taken.append(slot.player_name)
	return PlayerNames.pick(_names_rng, taken)


## How a seat dressed its kart, GAME.md 4.4, or the plain kart for a seat that said nothing.
func _style_for(index: int, input: KartInput) -> KartStyle:
	var seat := _seat_for(index, input)
	return KartStyle.from_array(_styles[seat] if seat >= 0 and seat < _styles.size() else null)


## Which seat's name and dress [param input] in [param index] takes, GAME.md 3.8 and 4.4: a player
## here the seat they sat down in, one at another machine none, and anything else its slot.
static func _seat_for(index: int, input: KartInput) -> int:
	if input is NetInput:
		return -1
	var player := input as PlayerInput
	if player != null and player.seat >= 0:
		return player.seat
	return index


func _free_color(wanted := -1) -> int:
	var taken: Array[int] = []
	for slot: PlayerSlot in slots:
		taken.append(slot.color_index)
	return wanted if wanted >= 0 and wanted not in taken else MatchConfig.first_free(taken)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		return
	for slot: PlayerSlot in slots:
		if slot.is_human() and slot.device() == device:
			leave_human(slot)


## What a host and a client both have around the arena: the bullets, the excitement meter and
## the camera framing the floor, the one difference being whether the bullets are driven here or
## replayed from snapshots.
func _build_systems(from_snapshots: bool) -> void:
	bullets = BulletSystem.new()
	bullets.name = "Bullets"
	bullets.puppet = from_snapshots
	add_child(bullets)
	_add_intensity()
	# The camera, the room's light, the tanks, the clock and the record, GAME.md 8.1.
	MatchStage.build(self, CAMERA_SCENE)


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


## The room, built, its layout in place before it enters the tree, which is when it builds
## itself. A loader that means to show a progress bar asks for it with [param stepped], runs
## [method Arena.build_steps] itself and then starts the match, GAME.md 8.6; everything else lets
## this build it in one go when the match starts.
func prepare_arena(stepped := false) -> Arena:
	if arena == null:
		arena = _build_arena(stepped)
	return arena


func _build_arena(stepped := false) -> Arena:
	var built: Arena = ARENA_SCENE.instantiate()
	built.name = "Arena"
	built.deferred_build = stepped
	if arena_layout != null:
		built.layout = arena_layout
	add_child(built)
	return built


func kart_of(slot_index: int) -> Kart:
	return slots[slot_index].kart


## A remote player joins through the network session: like a local join, with a [NetInput], in
## the color and on the team [param kept] says they had in the room before, GAME.md 3.14 and 9.6.
func join_network(input: NetInput, kept: Dictionary = {}) -> PlayerSlot:
	var slot := _join_with_input(input, int(kept.get("color", -1)))
	var team := int(kept.get("team", -1))
	if slot != null and team >= 0 and team < rules.teams:
		SeatIdentity.join_team(slot, team)
	return slot


## Builds a client-side match: the arena, camera and HUD without simulation. Slots, karts,
## bullets and pickups appear as snapshots arrive.
func start_puppet() -> void:
	puppet = true
	arena = prepare_arena()
	for zone: JackpotZone in arena.jackpot_zones:
		zone.rules = rules
		zone.puppet = true
	for pad: JunctionPad in arena.junctions:
		pad.puppet = true
		# Banking stays the host's, but the pad's faster nitro tank is worked out here too,
		# GAME.md 3.4, and for that it needs the numbers. They are the same numbers: a client's
		# copy is the one the host's lobby settings are written into, and the rest is in the file.
		pad.rules = rules
	for crate: Crate in arena.crates:
		crate.puppet = true
	_build_systems(true)
	_build_hud()


## Tells a puppet match which slot the local player has.
func set_local_slot(index: int, input: KartInput = null) -> void:
	local_slot = index
	var player := input as PlayerInput
	if player != null:
		local_input = player
		local_seats[index] = player


## Another player at this client, in [param index] on [param input], or one of them gone again.
func add_local_seat(index: int, input: PlayerInput) -> void:
	local_seats[index] = input
	for slot: PlayerSlot in slots:
		if slot.index == index:
			plate_kart(slot)


## The plate on [param slot]'s kart, GAME.md 4.4: a player's here by the settings, a bot's by skill.
func plate_kart(slot: PlayerSlot) -> void:
	if slot.kart == null:
		return
	if slot.is_local_human() or is_local_seat(slot.index):
		KartVisuals.plate_for_seat(slot.kart)
	elif slot.input is BotInput:
		KartVisuals.plate_for_bot(slot.kart, slot.kart.get_node_or_null("Brain") as BotBrain, rng)


func drop_local_seat(index: int) -> void:
	local_seats.erase(index)


func is_local_seat(index: int) -> bool:
	return index >= 0 and (index == local_slot or local_seats.has(index))


## Parks a started match in the lobby, karts frozen and the clock stopped, until the host begins.
func hold_in_lobby() -> void:
	_set_frozen(true)
	_set_state(State.LOBBY)


## Leaves the lobby into the countdown, once nobody is still choosing which joker to keep: the
## lamps wait for them, GAME.md 9.7, see [JokerKeep].
func begin_from_lobby() -> void:
	if state != State.LOBBY or puppet:
		return
	_starting = JokerKeep.pending(self)
	if not _starting:
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


## The host's description of the whole match for online clients, see [MatchSnapshot]. Given a
## [PickupWire] the floor goes out as what changed rather than as all of it; without one, which
## is how anything but a live session asks, the snapshot stands on its own.
func build_snapshot(wire: PickupWire = null) -> Dictionary:
	return MatchSnapshot.build(self, wire)


## Renders a host snapshot on a puppet match, see [MatchSnapshot].
func apply_snapshot(data: Dictionary) -> void:
	MatchSnapshot.apply(self, data)


## The end of the match, whether that is the clock running down or the sudden death after it.
## Both mean the same thing to anyone watching: there is no lap after this one.
func in_the_finale() -> bool:
	return state in [State.LAST_CALL, State.OVERTIME] or (rules.showdown() and is_running())


func is_running() -> bool:
	return state == State.PLAYING or state == State.LAST_CALL or state == State.OVERTIME


## Slots ranked by banked score, then kills, then fewest deaths; a showdown's by who lasted; in team
## play, GAME.md 3.14, team by team as the teams rank, and each team's karts in that order.
func standings() -> Array[PlayerSlot]:
	var ranked := slots.duplicate()
	ranked.sort_custom(Showdown.ahead if rules.showdown() else PlayerSlot.by_banked)
	if rules.teams <= 0:
		return ranked
	# A showdown's teams go in the order their karts lasted, GAME.md 9.7a; any other map's by bank.
	return Teams.grouped(ranked) if rules.showdown() else Teams.ranked(ranked)


func _set_state(next: State) -> void:
	state = next
	MatchStage.watch(self, state)
	Events.match_state_changed.emit(state)


func _set_frozen(frozen: bool) -> void:
	for slot: PlayerSlot in slots:
		slot.kart.frozen = frozen


## Points the ears at whoever is playing on this machine, GAME.md 8.4.
func refresh_listener() -> void:
	if camera_rig == null:
		return
	var here: Array[Node3D] = []
	for slot: PlayerSlot in slots:
		if slot.is_local_human() and slot.kart != null:
			here.append(slot.kart)
	camera_rig.listener_targets = here


func _spawn_kart(slot: PlayerSlot, point: Vector3) -> void:
	if slot.input is BotInput and slot.bot_trait == null:
		_deal_bot(slot)
	var kart: Kart = KART_SCENE.instantiate()
	kart.name = "Kart%d" % slot.index
	kart.slot = slot.index
	kart.color_index = slot.paint_index()
	kart.team = slot.team
	kart.marker_index = slot.color_index
	kart.style = slot.style
	kart.input = slot.input
	kart.rules = rules
	kart.rng = rng
	kart.bullet_system = bullets
	kart.position = point
	add_child(kart)
	kart.face(arena.junction_position - point)
	kart.died.connect(_on_kart_died.bind(slot))
	kart.joker_dropped.connect(_on_joker_dropped.bind(slot))
	kart.rammed.connect(_on_kart_rammed.bind(slot))
	kart.ram_landed.connect(func(by_slot: int) -> void: MatchStats.count(self, by_slot, &"rams"))
	kart.fired.connect(func(shots: Array[Bullet]) -> void: slot.stats.add(&"bullets", shots.size()))
	kart.coins_collected.connect(func(amount: int) -> void: slot.stats.add(&"coins", amount))
	kart.item_used.connect(func(_item: PowerUp) -> void: slot.stats.add(&"items"))
	kart.turbo_taken.connect(func(_direction: Vector3) -> void: slot.stats.add(&"turbo_pads"))
	kart.mult_changed.connect(_on_stat_mult.bind(slot))
	slot.kart = kart
	kart.enable_sound(true, not slot.is_local_human())
	if slot.input is BotInput:
		_attach_brain(slot)
	elif slot.input is DemoInput:
		DemoInput.drive(self, slot)
	plate_kart(slot)


func _physics_process(delta: float) -> void:
	# Whoever is one cash-out from winning lays gold tracks, on every machine alike.
	TireMarks.gild(self)
	# What each kart earns from catch up, GAME.md 3.16, read the same way on every machine.
	CatchUp.update(self)
	if puppet:
		MatchHeat.nitro(self)
		MatchStage.step(self)
		return
	match state:
		State.LOBBY:
			if JokerKeep.step(self, delta) and _starting:
				_starting = false
				_begin_countdown()
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
			var sudden := state == State.OVERTIME or rules.showdown()
			_step_respawns(delta, not sudden)
			if sudden and MatchEnd.step_overtime(self):
				return
			_step_stats(delta)
			bot_mirror.update(self, delta)
			Bounty.step(self, delta)
			FlushBoard.step(self, delta)
			JokerTick.step(slots, delta)
			# Every tick rather than only when something banks, for a winner whose cash-out it
			# was waiting on to stop, see [method check_target].
			check_target()
			MatchHeat.step(self, delta)
			for pad: JunctionPad in arena.junctions:
				pad.hint = junction_hint()
				pad.winning = junction_wins_it()
			MatchStage.step(self)


## How loudly the Junction should blink: from the biggest pot a local player is carrying,
## GAME.md 3.4, a nudge for whoever is watching this screen and nobody else.
## The kart carrying the bounty, or null when nobody is.
func bounty_kart() -> Kart:
	return kart_of(bounty_slot) if bounty_slot >= 0 else null


## Takes the price off the leader's head, GAME.md 3.10. The rule itself lives in [Bounty].
func clear_bounty(lapsed: bool) -> void:
	Bounty.clear(self, lapsed)


## Whether a player on this screen is one cash-out away from taking the match, GAME.md 3.4.
func junction_wins_it() -> bool:
	for slot: PlayerSlot in slots:
		if slot.is_local_human() and would_win(slot):
			return true
	return false


## Whether [param slot] cashing its pot in would take the match, counting everything a cash-out
## pays: the kart's jokers, and the Junction's own payout, which Last Call doubles.
func would_win(slot: PlayerSlot) -> bool:
	var target := win_at if win_at > 0 else rules.team_target()
	# A room with no target has nothing to win, whatever is in a pot.
	if target <= 0:
		return false
	var payout := arena.junction.payout_multiplier if arena != null and arena.junction else 1.0
	# What its teammates banked counts toward it, GAME.md 3.14.
	return slot.would_win(target - (Teams.score_of(slots, slot) - slot.banked), payout)


## Whether anybody's next cash-out would win the match that is being played, GAME.md 3.4.
func someone_would_win() -> bool:
	if not is_running():
		return false
	for slot: PlayerSlot in slots:
		if would_win(slot):
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
	for pad: JunctionPad in arena.junctions:
		pad.payout_multiplier = rules.last_call_payout
	_set_state(State.LAST_CALL)


## The clock running out, GAME.md 3.13, see [method MatchEnd.clock_out]: the pots banked and the
## whistle, or with overtime on sudden death, where nobody comes back and the last kart standing
## takes everything it is carrying. Returns whether overtime was entered; if it was not, the match
## is over and the caller should stop.
func _enter_overtime() -> bool:
	if not MatchEnd.clock_out(self):
		return false
	_set_state(State.OVERTIME)
	return true


## Ends the match, once whatever is banked at the whistle is in, see [MatchEnd], so the winner
## and every place after it are the final ones. The karts are not stopped dead: every driver lets
## go of the wheel at the whistle and rolls to a halt, and the rig swings onto the winner.
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
	MatchEnd.spotlight(self)


## Whoever is waiting to come back, and in sudden death whoever is not: [param coming_back]
## false polls the controls and stops there, since nobody respawns out of overtime, GAME.md
## 3.13, and a player who is out is exactly the player with time to read their hand in 3.7.
func _step_respawns(delta: float, coming_back := true) -> void:
	for slot: PlayerSlot in slots:
		if slot.kart.alive:
			continue
		# Whoever is waiting to come back still has controls: the pick answers them while it is
		# open, and the hand of cards answers them either way, GAME.md 3.7. Polled once, here,
		# because a second poll in the same tick is a button press nobody sees.
		if slot.is_human():
			slot.input.poll(delta)
			# A client's player answers their pick at the client, and the host is told by name,
			# see [JokerWire].
			var here := not slot.input is NetInput
			if here and slot.offer != null and not slot.offer.is_done():
				slot.offer.poll_input(slot.input)
		if not coming_back:
			continue
		slot.respawn_left = maxf(slot.respawn_left - delta, 0.0)
		if slot.respawn_left <= 0.0 and (slot.offer == null or slot.offer.is_done()):
			slot.offer = null
			_respawn(slot)


## Ends the match once somebody has banked the target, GAME.md 3.4. A cash-out that crossed the
## line is let run to its last coin first, so the player who won it collects all of it rather than
## losing whatever was still in the pot at the moment it went over; the match carries on round
## them meanwhile, and ends the moment that cash-out is done or stops.
func check_target() -> void:
	var reached := false
	for slot: PlayerSlot in slots:
		# A team's bank against a team's target, GAME.md 3.14, and its karts' cash-outs let run.
		if Teams.score_of(slots, slot) < rules.team_target():
			continue
		reached = true
		if slot.kart != null and arena.banking(slot.kart):
			return
	if reached:
		_finish()


## The death sequence, GAME.md 3.6. All of it lives in [KartDeath]: it is the longest single
## thing that happens in a match and none of it is about running one.
func _on_kart_died(cause: StringName, killer_slot: int, slot: PlayerSlot) -> void:
	KartDeath.resolve(self, cause, killer_slot, slot)


## Distance, drifting, the longest drift, nitro time, peak mult, the biggest pot and match points,
## counted every tick while the match runs.
func _step_stats(delta: float) -> void:
	_counting.step(delta)


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


## A ram somebody lived through, GAME.md 4.1: it knocks a quarter of their coins out onto the
## floor, whether it cost them a life or found them too freshly hurt to lose one. A ram that kills
## scatters coins through the death sequence already, so this is only for the one that does not,
## which would otherwise cost a full pot nothing at all.
func _on_kart_rammed(_by_slot: int, slot: PlayerSlot) -> void:
	var kart := slot.kart
	if puppet or kart == null or kart.pot.coins <= 0:
		return
	var fraction := rules.ram_coin_fraction
	for joker: Joker in kart.jokers.in_play:
		fraction = joker.modify_ram_knock(kart, fraction)
	if fraction <= 0.0:
		return
	var knocked := clampi(roundi(kart.pot.coins * fraction), 1, rules.ram_coin_max)
	knocked = mini(knocked, kart.pot.coins)
	kart.pot.add_coins(-knocked)
	slot.stats.add(&"coins_lost", knocked)
	slot.stats.add(&"coins_dropped", knocked)
	# Loose Change's never fade back to the House, STORY.md 6.3.
	var lifetime := 0.0 if KitCards.holds(kart, &"loose_change") else rules.dropped_chip_lifetime
	arena.spawn_chips(kart.global_position, knocked, lifetime, 0.0, true, slot.team)


func _on_joker_dropped(joker: Joker, slot: PlayerSlot) -> void:
	# One of Kit's cards let go is gone rather than on the floor, STORY.md 6.3.
	if not joker.contraband:
		arena.spawn_floor_joker(slot.kart.global_position, joker, rules.floor_item_lifetime)
	Events.joker_left.emit(slot.index, joker.id)


func _respawn(slot: PlayerSlot) -> void:
	var point := arena.junction_position
	var facing := Vector3.FORWARD
	if parked.has(slot.index):
		point = parked[slot.index].origin
		facing = -parked[slot.index].basis.z
	else:
		var enemies: Array[Vector3] = []
		for other: PlayerSlot in slots:
			# Away from the other teams, not from everybody: a teammate is not who to fear, 3.14.
			if other != slot and not Teams.teammates(slot, other) and other.kart.alive:
				enemies.append(other.kart.global_position)
		point = pick_spawn(arena.spawns_for(slots.size()), enemies)
		facing = arena.junction_position - point
	slot.kart.respawn(point, facing, rules.spawn_protection)
	Events.kart_respawned.emit(slot.index, point)


func _on_bank_started(kart: Kart) -> void:
	Events.bank_started.emit(kart.slot)


func _on_bank_tick(kart: Kart, points: int) -> void:
	slots[kart.slot].banked += points
	Events.bank_tick.emit(kart.slot, points)
	check_target()


func _on_bank_completed(kart: Kart, coins: int, mult: float, total: int) -> void:
	if kart.slot < slots.size():
		slots[kart.slot].stats.add(&"banks")
		slots[kart.slot].stats.peak(&"biggest_bank", total)
	Events.bank_completed.emit(kart.slot, coins, mult, total)
	for other: PlayerSlot in slots:
		# Toll Booth takes from the other teams' cash-outs only, GAME.md 3.14.
		if other.kart == kart or Teams.same(other.team, kart.team):
			continue
		var bonus := 0
		for joker: Joker in other.kart.jokers.in_play:
			bonus += joker.on_other_bank_completed(other.kart, kart.slot, total)
		if bonus > 0:
			other.banked += bonus
			Events.bank_tick.emit(other.index, bonus)
	check_target()


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
