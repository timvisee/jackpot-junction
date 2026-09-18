class_name MatchSnapshot
extends RefCounted
## Snapshots for online play, GAME.md 10.3. The host describes the whole match as a dictionary
## thirty times a second with [method build]; a puppet match renders it with [method apply],
## creating and removing puppet karts, bullets, pickups, turrets and bombs by the host's
## instance ids. Kept out of [Match] so both stay readable.
##
## A puppet this is holding may already have been freed by the time the snapshot that drops it
## arrives, so every removal asks before it looks. Naming a freed object at all is the error in
## GDScript, not using it, which is why each one goes through a [Variant] first.

## Every item in the game, for looking up held and dropped items by id.
static var _all_items: PowerUpTable


## Everything a client needs to render the match this tick. One section per kind of thing on
## the table, each of which is its own question and answers it on its own.
static func build(match_node: Match) -> Dictionary:
	return {
		"state": match_node.state,
		"time": match_node.time_left,
		"countdown": match_node.countdown_left,
		"payout": match_node.arena.junction.payout_multiplier,
		"slots": _slots(match_node),
		"karts": _karts(match_node),
		"bullets": _bullets(match_node),
		"pickups": _pickups(match_node),
		"turrets": _turrets(match_node),
		"bombs": _bombs(match_node),
		"stains": _stains(match_node),
		"jackpots": _jackpots(match_node),
		"crates": _crates(match_node),
		"targets": _targets(match_node),
		"flush": _flush(match_node),
		"bounty": match_node.bounty_slot,
		"bounty_left": match_node.bounty_left,
	}


## The players themselves: what they have scored and are carrying, and the joker pick in front
## of them if one is open.
static func _slots(match_node: Match) -> Array:
	var data: Array = []
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		var entry := {
			"banked": slot.banked,
			"kills": slot.kills,
			"deaths": slot.deaths,
			"coins": kart.pot.coins,
			"mult": kart.pot.mult,
			"partial": kart.pot.partial(),
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
			"stats": slot.stats.to_array(),
		}
		if slot.offer != null and not slot.offer.is_done():
			entry["offer"] = _offer(slot.offer)
		data.append(entry)
	return data


static func _offer(offer: JokerOffer) -> Dictionary:
	var ids: Array = []
	for joker: Joker in offer.choices:
		ids.append(String(joker.id))
	return {
		"stage": offer.stage,
		"selected": offer.selected,
		"choices": ids,
		"chosen": String(offer.chosen.id) if offer.chosen != null else "",
	}


## Where every kart is and what it is doing, which is most of what a client draws.
static func _karts(match_node: Match) -> Array:
	var data: Array = []
	for node: Node in match_node.get_children():
		var kart := node as Kart
		if kart == null:
			continue
		(
			data
			. append(
				{
					"id": kart.get_instance_id(),
					"slot": kart.slot,
					"color": kart.color_index,
					"x": kart.global_position.x,
					"z": kart.global_position.z,
					"h": kart.motor.heading,
					"vx": kart.motor.velocity.x,
					"vz": kart.motor.velocity.z,
					"alive": kart.alive,
					"prot": kart.protection_left > 0.0,
					"shield": kart.shielded,
					"ring": kart.channel_progress,
					"drift": kart.motor.drifting,
					# How long the slide has run, so a watching client can see the drift sparks earn
					# their boost and flash when it is taken, the same as the driver does.
					"drift_time": kart.motor.drift_time,
					"aim": kart.aim_arrow_visible,
					"nitro": kart.nitro_active,
					"lives": kart.lives,
					"decoy": kart.is_decoy(),
				}
			)
		)
	return data


static func _bullets(match_node: Match) -> Array:
	var data: Array = []
	for bullet: Bullet in match_node.bullets.bullets:
		(
			data
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
	return data


## Everything lying on the floor, each kind carrying what it takes to build the right one back.
static func _pickups(match_node: Match) -> Array:
	var data: Array = []
	for node: Node in match_node.arena.pickups.get_children():
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
		data.append(entry)
	return data


static func _turrets(match_node: Match) -> Array:
	var data: Array = []
	for node: Node in own_nodes(match_node, &"turrets"):
		var turret := node as Turret
		if turret != null and turret.alive:
			(
				data
				. append(
					{
						"id": turret.get_instance_id(),
						"x": turret.global_position.x,
						"z": turret.global_position.z,
						"h": turret.rotation.y,
						"c": turret.color,
					}
				)
			)
	return data


static func _bombs(match_node: Match) -> Array:
	var data: Array = []
	for node: Node in own_nodes(match_node, &"bombs"):
		var bomb := node as Bomb
		if bomb != null and bomb.alive:
			(
				data
				. append(
					{
						"id": bomb.get_instance_id(),
						"x": bomb.global_position.x,
						"z": bomb.global_position.z,
						"c": bomb.color,
						"armed": bomb.armed,
					}
				)
			)
	return data


static func _stains(match_node: Match) -> Array:
	var data: Array = []
	for node: Node in own_nodes(match_node, &"oil_stains"):
		var stain := node as OilStain
		if stain != null and not stain.is_queued_for_deletion():
			(
				data
				. append(
					{
						"id": stain.get_instance_id(),
						"x": stain.global_position.x,
						"z": stain.global_position.z,
					}
				)
			)
	return data


static func _jackpots(match_node: Match) -> Array:
	var data: Array = []
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		data.append({"active": zone.active, "chips": zone.chips})
	return data


static func _crates(match_node: Match) -> Array:
	var data: Array = []
	for crate: Crate in match_node.arena.crates:
		data.append(crate.alive)
	return data


## Which shooting targets are still standing, GAME.md 6.2. Only a bullet knocks one down and a
## client runs no bullets of its own, so without this a client watches a gallery nobody can hit.
static func _targets(match_node: Match) -> Array:
	var data: Array = []
	for target: Target in match_node.arena.targets:
		data.append(target.alive)
	return data


static func _flush(match_node: Match) -> Array:
	var data: Array = []
	for pad: FlushPad in match_node.arena.flush_pads:
		data.append(
			{"owner": pad.owner_slot, "color": pad.owner_color, "disabled": pad.disabled_left}
		)
	return data


## Renders a host snapshot on a match_node.puppet match.
static func apply(match_node: Match, data: Dictionary) -> void:
	if not match_node.puppet or match_node.arena == null:
		return
	var previous_state := match_node.state
	match_node.state = data["state"]
	match_node.time_left = data["time"]
	match_node.countdown_left = data["countdown"]
	match_node.arena.junction.payout_multiplier = data["payout"]
	if match_node.state != previous_state and match_node.hud != null:
		match_node.hud.call("_on_state_changed", match_node.state)
	_ensure_slots(match_node, (data["slots"] as Array).size())
	_apply_karts(match_node, data["karts"])
	_apply_slots(match_node, data["slots"])
	_apply_bullets(match_node, data["bullets"])
	_apply_pickups(match_node, data["pickups"])
	_apply_turrets(match_node, data["turrets"])
	_apply_bombs(match_node, data.get("bombs", []))
	_apply_stains(match_node, data.get("stains", []))
	var jackpots: Array = data["jackpots"]
	for i: int in mini(jackpots.size(), match_node.arena.jackpot_zones.size()):
		match_node.arena.jackpot_zones[i].apply_puppet_state(
			jackpots[i]["active"], jackpots[i]["chips"]
		)
	var crates: Array = data["crates"]
	for i: int in mini(crates.size(), match_node.arena.crates.size()):
		var crate := match_node.arena.crates[i]
		if crate.alive and not crates[i]:
			Burst.spawn(match_node, crate.global_position, Palette.BLOCK, 0.9, 18)
		crate.visible = crates[i]
		crate.alive = crates[i]
	var targets: Array = data.get("targets", [])
	for i: int in mini(targets.size(), match_node.arena.targets.size()):
		match_node.arena.targets[i].apply_puppet_state(targets[i])
	match_node.bounty_slot = data.get("bounty", -1)
	match_node.bounty_left = data.get("bounty_left", 0.0)
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null:
			slot.kart.set_bounty(slot.index == match_node.bounty_slot)
	# Both blinks are about the karts on this screen rather than about anything the host knows,
	# and the snapshot has just said what every pot is worth, so a client works them out itself.
	match_node.arena.junction.hint = match_node.junction_hint()
	match_node.arena.junction.winning = match_node.junction_wins_it()
	match_node.arena.disco.level = match_node.intensity.level
	# The whistle, GAME.md 8.1. A client never runs one, so the rig would keep sweeping while the
	# standings sat on the screen. Asked after the slots are in, since who won is read off them.
	if match_node.state != previous_state:
		if match_node.state == Match.State.RESULTS:
			match_node.spotlight_winner()
		elif previous_state == Match.State.RESULTS:
			match_node.arena.disco.clear_focus()
	var flush: Array = data.get("flush", [])
	for i: int in mini(flush.size(), match_node.arena.flush_pads.size()):
		match_node.arena.flush_pads[i].apply_puppet_state(
			flush[i]["owner"], flush[i]["color"], flush[i]["disabled"]
		)


## Members of a group that belong to this match. A host and a puppet match can share a scene
## tree, in tests and in a future split screen, and must never describe each other's nodes or
## reach into them. Anything that sweeps the tree by group asks this rather than the tree.
static func own_nodes(match_node: Match, group: StringName) -> Array[Node]:
	var result: Array[Node] = []
	for node: Node in match_node.get_tree().get_nodes_in_group(group):
		if match_node.is_ancestor_of(node):
			result.append(node)
	return result


static func _ensure_slots(match_node: Match, count: int) -> void:
	while match_node.slots.size() < count:
		var index := match_node.slots.size()
		var input: KartInput = (
			_local_input(match_node) if index == match_node.local_slot else KartInput.new()
		)
		match_node.slots.append(PlayerSlot.new(index, input))


## The input this machine is polling for its own player. A puppet match whose session never
## handed one over, as a test driving snapshots directly does, gets one of its own: the local
## slot holds a player's input either way, which is what says somebody is here to play.
static func _local_input(match_node: Match) -> PlayerInput:
	if match_node.local_input == null:
		match_node.local_input = PlayerInput.new()
	return match_node.local_input


static func _apply_slots(match_node: Match, entries: Array) -> void:
	for i: int in entries.size():
		var entry: Dictionary = entries[i]
		var slot := match_node.slots[i]
		if i == match_node.local_slot and not slot.is_local_human():
			slot.input = _local_input(match_node)
		slot.banked = entry["banked"]
		slot.kills = entry["kills"]
		slot.deaths = entry["deaths"]
		slot.color_index = entry["color"]
		slot.respawn_left = entry["respawn"]
		if entry.has("stats"):
			slot.stats.from_array(entry["stats"])
		slot.bot_trait = (
			match_node.bot_traits.by_id(StringName(entry["trait"]))
			if entry["trait"] != ""
			else null
		)
		if entry["human"] and not slot.is_human():
			slot.input = NetInput.new()
		elif not entry["human"] and slot.is_human() and i != match_node.local_slot:
			slot.input = KartInput.new()
		if slot.kart != null:
			slot.kart.pot.coins = entry["coins"]
			slot.kart.pot.mult = entry["mult"]
			slot.kart.pot.set_partial(entry.get("partial", 0.0))
			slot.kart.held_item = _item_by_id(entry["item"])
			slot.kart.item_reveal_left = entry["reveal"]
			slot.kart.menu_open = entry["menu"]
			slot.kart.menu_index = entry["menu_index"]
			if not slot.kart.predicted:
				# A kart driven here spends its own tank and is corrected on it by the message
				# addressed to it, GAME.md 10.3. This figure is a round trip old.
				slot.kart.nitro_charge = entry.get("nitro_charge", 1.0)
			var jokers: Array[Joker] = []
			for id: String in entry["jokers"]:
				var joker := match_node.joker_catalog.by_id(StringName(id))
				if joker != null:
					jokers.append(joker)
			slot.kart.jokers.jokers = jokers
		if entry.has("offer"):
			var offer_data: Dictionary = entry["offer"]
			var choices: Array[Joker] = []
			for id: String in offer_data["choices"]:
				var joker := match_node.joker_catalog.by_id(StringName(id))
				if joker != null:
					choices.append(joker)
			if slot.offer == null or slot.offer.is_done():
				slot.offer = JokerOffer.new(slot.kart, choices)
				slot.offer.choices = choices
			elif i != match_node.local_slot:
				# Somebody else's pick, watched rather than made: the host says where their
				# cursor is and what they have taken.
				slot.offer.choices = choices
				slot.offer.stage = offer_data["stage"]
				slot.offer.selected = offer_data["selected"]
				slot.offer.chosen = (
					match_node.joker_catalog.by_id(StringName(offer_data["chosen"]))
					if offer_data["chosen"] != ""
					else null
				)
		else:
			# The host has finished with it: the card is taken, the kart is coming back, and the
			# pick comes off the screen whoever was making it.
			slot.offer = null


static func _item_by_id(id: String) -> PowerUp:
	if id == "":
		return null
	if _all_items == null:
		_all_items = load("res://data/powerups/all.tres")
	for item: PowerUp in _all_items.entries:
		if item.id == StringName(id):
			return item
	return null


static func _apply_karts(match_node: Match, entries: Array) -> void:
	var seen: Dictionary[int, bool] = {}
	var delta := float(NetSession.SNAPSHOT_EVERY_TICKS) / Engine.physics_ticks_per_second
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		seen[id] = true
		var kart: Kart = match_node.puppet_karts.get(id)
		if kart == null:
			kart = match_node.KART_SCENE.instantiate()
			kart.name = "Puppet%d" % id
			kart.slot = entry["slot"]
			kart.color_index = entry["color"]
			kart.rules = match_node.rules
			if entry["decoy"]:
				kart.decoy_owner = kart
			match_node.add_child(kart)
			kart.make_puppet()
			kart.global_position = Vector3(entry["x"], 0.0, entry["z"])
			match_node.puppet_karts[id] = kart
			if not entry["decoy"] and entry["slot"] < match_node.slots.size():
				match_node.slots[entry["slot"]].kart = kart
				match_node.camera_rig.targets.append(kart)
		# The one this player drives sounds like their own; everybody else's sounds like a kart
		# somebody else is driving, which is what a bot sounds like, GAME.md 8.4. Asked every
		# snapshot rather than once at the kart's birth: the host says which slot is ours in a
		# message of its own, which arrives after the first karts have already been built, so a
		# kart that settled its voice on the way in would keep somebody else's all match.
		kart.enable_sound(true, entry["slot"] != match_node.local_slot)
		# The kart this player steers reads the input this machine is polling, even though the
		# host is the one moving it. Everything drawn from where they are pointing — the aim
		# guide, the swivel cannon's arrow — then points where their shot is going to go.
		if entry["slot"] == match_node.local_slot and entry["slot"] < match_node.slots.size():
			kart.input = match_node.slots[entry["slot"]].input
		if (
			match_node.hud != null
			and not entry["decoy"]
			and entry["slot"] == match_node.local_slot
			and entry["slot"] < match_node.slots.size()
		):
			match_node.hud.add_block(match_node.slots[entry["slot"]])
		kart.apply_puppet_state(entry, delta)
	for id: int in match_node.puppet_karts.keys():
		if not seen.has(id):
			var gone: Variant = match_node.puppet_karts[id]
			match_node.puppet_karts.erase(id)
			if not is_instance_valid(gone):
				continue
			var kart := gone as Kart
			match_node.camera_rig.targets.erase(kart)
			kart.queue_free()


static func _apply_bullets(match_node: Match, entries: Array) -> void:
	var seen: Dictionary[int, bool] = {}
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		seen[id] = true
		var bullet: Bullet = match_node.puppet_bullets.get(id)
		var velocity := Vector3(entry["vx"], 0.0, entry["vz"])
		if bullet == null:
			bullet = Bullet.new()
			bullet.setup_puppet(
				Vector3(entry["x"], 0.0, entry["z"]), velocity, entry["r"], entry["c"]
			)
			match_node.bullets.add_child(bullet)
			match_node.puppet_bullets[id] = bullet
		else:
			bullet.correct_puppet(Vector3(entry["x"], 0.0, entry["z"]), velocity)
	for id: int in match_node.puppet_bullets.keys():
		if not seen.has(id):
			var gone: Variant = match_node.puppet_bullets[id]
			match_node.puppet_bullets.erase(id)
			if is_instance_valid(gone):
				(gone as Bullet).queue_free()


static func _apply_pickups(match_node: Match, entries: Array) -> void:
	var seen: Dictionary[int, bool] = {}
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		seen[id] = true
		if match_node.puppet_pickups.has(id):
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
				card.joker = match_node.joker_catalog.by_id(StringName(entry["joker"]))
				pickup = card
		if pickup == null:
			continue
		pickup.position = Vector3(entry["x"], 0.0, entry["z"])
		pickup.monitorable = false
		match_node.arena.pickups.add_child(pickup)
		match_node.puppet_pickups[id] = pickup
	for id: int in match_node.puppet_pickups.keys():
		if not seen.has(id):
			var gone: Variant = match_node.puppet_pickups[id]
			match_node.puppet_pickups.erase(id)
			if not is_instance_valid(gone):
				continue
			var pickup := gone as Pickup
			# The host does not say who took it; the kart on top of it did. Whatever it was
			# flows into that kart here the same as it does for the player who took it.
			var taker := _nearest_puppet_kart(match_node, pickup.global_position, 2.5)
			if taker != null:
				PickupFlight.take(pickup, taker)
			pickup.queue_free()


static func _nearest_puppet_kart(match_node: Match, point: Vector3, max_distance: float) -> Kart:
	var best: Kart = null
	var best_distance := max_distance
	for kart: Kart in match_node.puppet_karts.values():
		if not kart.alive:
			continue
		var distance := kart.global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = kart
	return best


static func _apply_turrets(match_node: Match, entries: Array) -> void:
	var seen: Dictionary[int, bool] = {}
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		seen[id] = true
		var turret: Turret = match_node.puppet_turrets.get(id)
		if turret == null:
			turret = Turret.new()
			turret.puppet = true
			turret.color = entry["c"]
			match_node.add_child(turret)
			turret.collision_layer = 0
			match_node.puppet_turrets[id] = turret
		turret.global_position = Vector3(entry["x"], 0.0, entry["z"])
		turret.rotation.y = entry["h"]
	for id: int in match_node.puppet_turrets.keys():
		if not seen.has(id):
			var gone: Variant = match_node.puppet_turrets[id]
			match_node.puppet_turrets.erase(id)
			if not is_instance_valid(gone):
				continue
			var turret := gone as Turret
			Burst.spawn(match_node, turret.global_position, turret.color, 0.8, 14)
			turret.queue_free()


## Puppet bombs mirror the host's; one that vanishes from the snapshot went off, so its blast
## is shown here too.
## Puppet oil stains mirror the host's; they only ever appear and disappear.
static func _apply_stains(match_node: Match, entries: Array) -> void:
	var seen: Dictionary[int, bool] = {}
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		seen[id] = true
		if match_node.puppet_stains.has(id):
			continue
		var stain := OilStain.new()
		stain.puppet = true
		match_node.add_child(stain)
		stain.collision_layer = 0
		stain.global_position = Vector3(entry["x"], 0.0, entry["z"])
		match_node.puppet_stains[id] = stain
	for id: int in match_node.puppet_stains.keys():
		if not seen.has(id):
			var gone: Variant = match_node.puppet_stains[id]
			match_node.puppet_stains.erase(id)
			if is_instance_valid(gone):
				(gone as OilStain).queue_free()


static func _apply_bombs(match_node: Match, entries: Array) -> void:
	var seen: Dictionary[int, bool] = {}
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		seen[id] = true
		var bomb: Bomb = match_node.puppet_bombs.get(id)
		if bomb == null:
			bomb = Bomb.new()
			bomb.puppet = true
			bomb.color = entry["c"]
			match_node.add_child(bomb)
			bomb.collision_layer = 0
			match_node.puppet_bombs[id] = bomb
		bomb.global_position = Vector3(entry["x"], 0.0, entry["z"])
		bomb.armed = entry["armed"]
	for id: int in match_node.puppet_bombs.keys():
		if not seen.has(id):
			var gone: Variant = match_node.puppet_bombs[id]
			match_node.puppet_bombs.erase(id)
			if not is_instance_valid(gone):
				continue
			var bomb := gone as Bomb
			if bomb.alive:
				bomb.explode()
