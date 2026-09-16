class_name MatchSnapshot
extends RefCounted
## Snapshots for online play, GAME.md 10.3. The host describes the whole match as a dictionary
## thirty times a second with [method build]; a puppet match renders it with [method apply],
## creating and removing puppet karts, bullets, pickups, turrets and bombs by the host's
## instance ids. Kept out of [Match] so both stay readable.

## Every item in the game, for looking up held and dropped items by id.
static var _all_items: PowerUpTable


## Everything a client needs to render the match this tick.
static func build(match_node: Match) -> Dictionary:
	var slot_data: Array = []
	for slot: PlayerSlot in match_node.slots:
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
			"stats": slot.stats.to_array(),
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
	for node: Node in match_node.get_children():
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
					"vx": kart.motor.velocity.x,
					"vz": kart.motor.velocity.z,
					"alive": kart.alive,
					"prot": kart.protection_left > 0.0,
					"shield": kart.shielded,
					"ring": kart.channel_progress,
					"drift": kart.motor.drifting,
					"aim": kart._aim_arrow.visible,
					"nitro": kart.nitro_active,
					"lives": kart.lives,
					"decoy": kart.is_decoy(),
				}
			)
		)
	var bullet_data: Array = []
	for bullet: Bullet in match_node.bullets.bullets:
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
		pickup_data.append(entry)
	var turret_data: Array = []
	for node: Node in _own_nodes(match_node, &"turrets"):
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
	var bomb_data: Array = []
	for node: Node in _own_nodes(match_node, &"bombs"):
		var bomb := node as Bomb
		if bomb != null and bomb.alive:
			(
				bomb_data
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
	var stain_data: Array = []
	for node: Node in _own_nodes(match_node, &"oil_stains"):
		var stain := node as OilStain
		if stain != null and not stain.is_queued_for_deletion():
			(
				stain_data
				. append(
					{
						"id": stain.get_instance_id(),
						"x": stain.global_position.x,
						"z": stain.global_position.z,
					}
				)
			)
	var jackpots: Array = []
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		jackpots.append({"active": zone.active, "chips": zone.chips})
	var crates: Array = []
	for crate: Crate in match_node.arena.crates:
		crates.append(crate.alive)
	var flush: Array = []
	for pad: FlushPad in match_node.arena.flush_pads:
		flush.append(
			{"owner": pad.owner_slot, "color": pad.owner_color, "disabled": pad.disabled_left}
		)
	return {
		"state": match_node.state,
		"time": match_node.time_left,
		"countdown": match_node.countdown_left,
		"payout": match_node.arena.junction.payout_multiplier,
		"slots": slot_data,
		"karts": karts,
		"bullets": bullet_data,
		"pickups": pickup_data,
		"turrets": turret_data,
		"bombs": bomb_data,
		"stains": stain_data,
		"jackpots": jackpots,
		"crates": crates,
		"flush": flush,
	}


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
	match_node.arena.junction.hint = match_node.junction_hint()
	var flush: Array = data.get("flush", [])
	for i: int in mini(flush.size(), match_node.arena.flush_pads.size()):
		match_node.arena.flush_pads[i].apply_puppet_state(
			flush[i]["owner"], flush[i]["color"], flush[i]["disabled"]
		)


## Members of a group that belong to this match. A host and a puppet match can share a scene
## tree, in tests and in a future split screen, and must never describe each other's nodes.
static func _own_nodes(match_node: Match, group: StringName) -> Array[Node]:
	var result: Array[Node] = []
	for node: Node in match_node.get_tree().get_nodes_in_group(group):
		if match_node.is_ancestor_of(node):
			result.append(node)
	return result


static func _ensure_slots(match_node: Match, count: int) -> void:
	while match_node.slots.size() < count:
		var index := match_node.slots.size()
		var input: KartInput = (
			PlayerInput.new() if index == match_node.local_slot else KartInput.new()
		)
		match_node.slots.append(PlayerSlot.new(index, input))


static func _apply_slots(match_node: Match, entries: Array) -> void:
	for i: int in entries.size():
		var entry: Dictionary = entries[i]
		var slot := match_node.slots[i]
		if i == match_node.local_slot and not slot.is_local_human():
			slot.input = PlayerInput.new()
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
			slot.kart.held_item = _item_by_id(entry["item"])
			slot.kart.item_reveal_left = entry["reveal"]
			slot.kart.menu_open = entry["menu"]
			slot.kart.menu_index = entry["menu_index"]
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
			slot.offer.stage = offer_data["stage"]
			slot.offer.selected = offer_data["selected"]
			slot.offer.chosen = (
				match_node.joker_catalog.by_id(StringName(offer_data["chosen"]))
				if offer_data["chosen"] != ""
				else null
			)
		else:
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
				if match_node.hud != null and entry["slot"] == match_node.local_slot:
					match_node.hud.add_block(match_node.slots[entry["slot"]])
		kart.apply_puppet_state(entry, delta)
	for id: int in match_node.puppet_karts.keys():
		if not seen.has(id):
			var kart: Kart = match_node.puppet_karts[id]
			match_node.puppet_karts.erase(id)
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
			var bullet: Bullet = match_node.puppet_bullets[id]
			match_node.puppet_bullets.erase(id)
			bullet.queue_free()


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
			var pickup: Pickup = match_node.puppet_pickups[id]
			match_node.puppet_pickups.erase(id)
			var box := pickup as ItemBox
			if box != null:
				# The host does not say who took it; the kart on top of it did.
				var taker := _nearest_puppet_kart(match_node, box.global_position, 2.5)
				if taker != null:
					var color := (
						box.fixed_item.color if box.fixed_item != null else Palette.CHIP_GOLD
					)
					ItemFlight.spawn(match_node.arena.pickups, box.global_position, taker, color)
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
			var turret: Turret = match_node.puppet_turrets[id]
			match_node.puppet_turrets.erase(id)
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
			var stain: OilStain = match_node.puppet_stains[id]
			match_node.puppet_stains.erase(id)
			stain.queue_free()


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
			var bomb: Bomb = match_node.puppet_bombs[id]
			match_node.puppet_bombs.erase(id)
			if bomb.alive:
				bomb.explode()
