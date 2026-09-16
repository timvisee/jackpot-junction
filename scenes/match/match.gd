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

var _inputs: Array[KartInput] = []
var _colors: Array[int] = []
var _seed := 0
var _puppet_karts: Dictionary[int, Kart] = {}
var _puppet_bullets: Dictionary[int, Bullet] = {}
var _puppet_pickups: Dictionary[int, Pickup] = {}
var _puppet_turrets: Dictionary[int, Turret] = {}
var _all_items: PowerUpTable


func _ready() -> void:
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


## Everything a client needs to render the match this tick.
func build_snapshot() -> Dictionary:
	var slot_data: Array = []
	for slot: PlayerSlot in slots:
		var kart := slot.kart
		var entry := {
			"banked": slot.banked,
			"kills": slot.kills,
			"deaths": slot.deaths,
			"coins": kart.pot.coins,
			"mult": kart.pot.mult,
			"item": String(kart.held_item.id) if kart.held_item != null else "",
			"reveal": kart.item_reveal_left,
			"jokers": kart.jokers.ids(),
			"human": slot.is_human(),
			"trait": String(slot.bot_trait.id) if slot.bot_trait != null else "",
			"color": slot.color_index,
			"respawn": slot.respawn_left,
			"menu": kart.menu_open,
			"menu_index": kart.menu_index,
			"nitro_charge": kart.nitro_charge,
		}
		if slot.offer != null and not slot.offer.is_done():
			var ids: Array = []
			for joker: Joker in slot.offer.choices:
				ids.append(String(joker.id))
			entry["offer"] = {
				"stage": slot.offer.stage,
				"selected": slot.offer.selected,
				"choices": ids,
				"chosen": String(slot.offer.chosen.id) if slot.offer.chosen != null else "",
			}
		slot_data.append(entry)
	var karts: Array = []
	for node: Node in get_children():
		var kart := node as Kart
		if kart == null:
			continue
		(
			karts
			. append(
				{
					"id": kart.get_instance_id(),
					"slot": kart.slot,
					"color": kart.color_index,
					"x": kart.global_position.x,
					"z": kart.global_position.z,
					"h": kart.motor.heading,
					"alive": kart.alive,
					"prot": kart.protection_left > 0.0,
					"shield": kart.shielded,
					"ring": kart.channel_progress,
					"drift": kart.motor.drifting,
					"aim": kart._aim_arrow.visible,
					"nitro": kart.nitro_active,
					"decoy": kart.is_decoy(),
				}
			)
		)
	var bullet_data: Array = []
	for bullet: Bullet in bullets.bullets:
		(
			bullet_data
			. append(
				{
					"id": bullet.get_instance_id(),
					"x": bullet.global_position.x,
					"z": bullet.global_position.z,
					"vx": bullet.velocity.x,
					"vz": bullet.velocity.z,
					"r": bullet.radius,
					"c": bullet.color,
				}
			)
		)
	var pickup_data: Array = []
	for node: Node in arena.pickups.get_children():
		var pickup := node as Pickup
		if pickup == null or pickup.is_queued_for_deletion():
			continue
		var entry := {
			"id": pickup.get_instance_id(),
			"x": pickup.global_position.x,
			"z": pickup.global_position.z
		}
		var chip := pickup as Chip
		var die := pickup as MultDie
		var box := pickup as ItemBox
		var card := pickup as FloorJoker
		if chip != null:
			entry["kind"] = "chip"
			entry["value"] = chip.value
			entry["gold"] = chip.gold
			entry["dropped"] = chip.dropped
		elif die != null:
			entry["kind"] = "die"
		elif box != null:
			entry["kind"] = "item"
			entry["item"] = String(box.fixed_item.id) if box.fixed_item != null else ""
		elif card != null:
			entry["kind"] = "joker"
			entry["joker"] = String(card.joker.id)
		else:
			continue
		pickup_data.append(entry)
	var turret_data: Array = []
	for node: Node in get_tree().get_nodes_in_group(&"turrets"):
		var turret := node as Turret
		if turret != null and turret.alive:
			turret_data.append(
				{
					"id": turret.get_instance_id(),
					"x": turret.global_position.x,
					"z": turret.global_position.z,
					"h": turret.rotation.y,
					"c": turret.color
				}
			)
	var jackpots: Array = []
	for zone: JackpotZone in arena.jackpot_zones:
		jackpots.append({"active": zone.active, "chips": zone.chips})
	var crates: Array = []
	for crate: Crate in arena.crates:
		crates.append(crate.alive)
	return {
		"state": state,
		"time": time_left,
		"countdown": countdown_left,
		"payout": arena.junction.payout_multiplier,
		"slots": slot_data,
		"karts": karts,
		"bullets": bullet_data,
		"pickups": pickup_data,
		"turrets": turret_data,
		"jackpots": jackpots,
		"crates": crates,
	}


## Renders a host snapshot on a puppet match.
func apply_snapshot(data: Dictionary) -> void:
	if not puppet or arena == null:
		return
	var previous_state := state
	state = data["state"]
	time_left = data["time"]
	countdown_left = data["countdown"]
	arena.junction.payout_multiplier = data["payout"]
	if state != previous_state and hud != null:
		hud.call("_on_state_changed", state)
	_ensure_slots((data["slots"] as Array).size())
	_apply_karts(data["karts"])
	_apply_slots(data["slots"])
	_apply_bullets(data["bullets"])
	_apply_pickups(data["pickups"])
	_apply_turrets(data["turrets"])
	var jackpots: Array = data["jackpots"]
	for i: int in mini(jackpots.size(), arena.jackpot_zones.size()):
		arena.jackpot_zones[i].apply_puppet_state(jackpots[i]["active"], jackpots[i]["chips"])
	var crates: Array = data["crates"]
	for i: int in mini(crates.size(), arena.crates.size()):
		arena.crates[i].visible = crates[i]
		arena.crates[i].alive = crates[i]


func _ensure_slots(count: int) -> void:
	while slots.size() < count:
		var index := slots.size()
		var input: KartInput = PlayerInput.new() if index == local_slot else KartInput.new()
		slots.append(PlayerSlot.new(index, input))


func _apply_slots(entries: Array) -> void:
	for i: int in entries.size():
		var entry: Dictionary = entries[i]
		var slot := slots[i]
		if i == local_slot and not slot.is_local_human():
			slot.input = PlayerInput.new()
		slot.banked = entry["banked"]
		slot.kills = entry["kills"]
		slot.deaths = entry["deaths"]
		slot.color_index = entry["color"]
		slot.respawn_left = entry["respawn"]
		slot.bot_trait = (
			bot_traits.by_id(StringName(entry["trait"])) if entry["trait"] != "" else null
		)
		if slot.kart != null:
			slot.kart.pot.coins = entry["coins"]
			slot.kart.pot.mult = entry["mult"]
			slot.kart.held_item = _item_by_id(entry["item"])
			slot.kart.item_reveal_left = entry["reveal"]
			slot.kart.menu_open = entry["menu"]
			slot.kart.menu_index = entry["menu_index"]
			slot.kart.nitro_charge = entry.get("nitro_charge", 1.0)
			var jokers: Array[Joker] = []
			for id: String in entry["jokers"]:
				var joker := joker_catalog.by_id(StringName(id))
				if joker != null:
					jokers.append(joker)
			slot.kart.jokers.jokers = jokers
		if entry.has("offer"):
			var offer_data: Dictionary = entry["offer"]
			var choices: Array[Joker] = []
			for id: String in offer_data["choices"]:
				var joker := joker_catalog.by_id(StringName(id))
				if joker != null:
					choices.append(joker)
			if slot.offer == null or slot.offer.is_done():
				slot.offer = JokerOffer.new(slot.kart, choices)
			slot.offer.choices = choices
			slot.offer.stage = offer_data["stage"]
			slot.offer.selected = offer_data["selected"]
			slot.offer.chosen = (
				joker_catalog.by_id(StringName(offer_data["chosen"]))
				if offer_data["chosen"] != ""
				else null
			)
		else:
			slot.offer = null


func _item_by_id(id: String) -> PowerUp:
	if id == "":
		return null
	if _all_items == null:
		_all_items = load("res://data/powerups/all.tres")
	for item: PowerUp in _all_items.entries:
		if item.id == StringName(id):
			return item
	return null


func _apply_karts(entries: Array) -> void:
	var seen: Dictionary[int, bool] = {}
	var delta := float(NetSession.SNAPSHOT_EVERY_TICKS) / Engine.physics_ticks_per_second
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		seen[id] = true
		var kart: Kart = _puppet_karts.get(id)
		if kart == null:
			kart = KART_SCENE.instantiate()
			kart.name = "Puppet%d" % id
			kart.slot = entry["slot"]
			kart.color_index = entry["color"]
			kart.rules = rules
			if entry["decoy"]:
				kart.decoy_owner = kart
			add_child(kart)
			kart.make_puppet()
			kart.global_position = Vector3(entry["x"], 0.0, entry["z"])
			_puppet_karts[id] = kart
			if not entry["decoy"] and entry["slot"] < slots.size():
				slots[entry["slot"]].kart = kart
				camera_rig.targets.append(kart)
				if hud != null and entry["slot"] == local_slot:
					hud.add_block(slots[entry["slot"]])
		kart.apply_puppet_state(entry, delta)
	for id: int in _puppet_karts.keys():
		if not seen.has(id):
			var kart: Kart = _puppet_karts[id]
			_puppet_karts.erase(id)
			camera_rig.targets.erase(kart)
			kart.queue_free()


func _apply_bullets(entries: Array) -> void:
	var seen: Dictionary[int, bool] = {}
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		seen[id] = true
		var bullet: Bullet = _puppet_bullets.get(id)
		var velocity := Vector3(entry["vx"], 0.0, entry["vz"])
		if bullet == null:
			bullet = Bullet.new()
			bullet.setup_puppet(
				Vector3(entry["x"], 0.0, entry["z"]), velocity, entry["r"], entry["c"]
			)
			bullets.add_child(bullet)
			_puppet_bullets[id] = bullet
		else:
			bullet.global_position = Vector3(entry["x"], Bullet.HEIGHT, entry["z"])
			bullet.velocity = velocity
	for id: int in _puppet_bullets.keys():
		if not seen.has(id):
			var bullet: Bullet = _puppet_bullets[id]
			_puppet_bullets.erase(id)
			bullet.queue_free()


func _apply_pickups(entries: Array) -> void:
	var seen: Dictionary[int, bool] = {}
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		seen[id] = true
		if _puppet_pickups.has(id):
			continue
		var pickup: Pickup = null
		match String(entry["kind"]):
			"chip":
				var chip := Chip.new()
				chip.value = entry["value"]
				chip.gold = entry["gold"]
				chip.dropped = entry["dropped"]
				pickup = chip
			"die":
				pickup = MultDie.new()
			"item":
				var box := ItemBox.new()
				box.fixed_item = _item_by_id(entry["item"])
				pickup = box
			"joker":
				var card := FloorJoker.new()
				card.joker = joker_catalog.by_id(StringName(entry["joker"]))
				pickup = card
		if pickup == null:
			continue
		pickup.position = Vector3(entry["x"], 0.0, entry["z"])
		pickup.monitorable = false
		arena.pickups.add_child(pickup)
		_puppet_pickups[id] = pickup
	for id: int in _puppet_pickups.keys():
		if not seen.has(id):
			var pickup: Pickup = _puppet_pickups[id]
			_puppet_pickups.erase(id)
			pickup.queue_free()


func _apply_turrets(entries: Array) -> void:
	var seen: Dictionary[int, bool] = {}
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		seen[id] = true
		var turret: Turret = _puppet_turrets.get(id)
		if turret == null:
			turret = Turret.new()
			turret.puppet = true
			turret.color = entry["c"]
			add_child(turret)
			turret.collision_layer = 0
			_puppet_turrets[id] = turret
		turret.global_position = Vector3(entry["x"], 0.0, entry["z"])
		turret.rotation.y = entry["h"]
	for id: int in _puppet_turrets.keys():
		if not seen.has(id):
			var turret: Turret = _puppet_turrets[id]
			_puppet_turrets.erase(id)
			turret.queue_free()


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
		if killer.kart.alive:
			killer.kart.gain_mult(rules.kill_mult, &"kill")
	kart.pot.reset()
	slot.deaths += 1
	slot.respawn_left = rules.respawn_delay
	slot.offer = _make_offer(slot)
	Events.kart_killed.emit(slot.index, killer_slot, cause)
	_check_target()


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
