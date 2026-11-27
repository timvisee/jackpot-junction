class_name MatchResume
extends RefCounted
## A map in play carried over to a new host, GAME.md 10.8. When a game's host goes during a map,
## the player who hosts it next takes what their own screen last showed of it, read off the puppet
## match it was drawing, see [method capture], and starts the match afresh from that, see
## [method start] and [method restore]: every kart where it stood, every banked score, kill and
## death, pot, held item, joker hand, life and respawn, the clock, the bounty, the Jackpot's pile,
## and the chips, items and jokers lying dropped on the floor. Every slot is where it was, so each
## player coming back is seated in their own kart, see [method HostControls.resume_from].
##
## What a screen never sees starts afresh: the bots' plans, the order of the deck, the counters some
## jokers keep, when the pads restock, the random numbers. Shots, turrets, bombs and oil in flight
## go, and so does an open joker pick, the kart coming back once its wait is out. A showdown and the
## story's Final Hand are not carried over: their new host opens its lobby instead. Nor is the
## waiting room, which plays in a match of its own: its new host opens the lobby afresh.

## The states a map is being played in, which are the ones carried over.
const PLAYING: Array[int] = [
	Match.State.COUNTDOWN, Match.State.PLAYING, Match.State.LAST_CALL, Match.State.OVERTIME
]
## The waiting room's own room, the layout its scene builds its match in, by its path, so a match
## in it is known for the lobby it is without this naming the waiting room's scene.
const WAITING_ROOM := "res://data/maps/waiting_room.tres"


## What a new host takes the game on with, GAME.md 10.8, in words: the match [param config] sets
## up, the [param door], its password only [param with_password], which a Steam game has none of and
## only its players hear off Steam, whether it is a Quick Play game, and [param who] may come in.
static func plan_of(config: MatchConfig, door: NetDoor, who: int, with_password := false) -> String:
	var chosen := MatchOptions.to_wire(config) if config != null else {}
	chosen.erase("house")
	chosen.erase("final_hand")
	var opened := door.to_wire()
	if not with_password:
		opened.erase("password")
	var quick := config != null and config.quick_play
	return JSON.stringify({"match": chosen, "door": opened, "quick": quick, "who": who})


## What [param session], a client of a game whose host has gone, last saw of the map being played,
## to carry it over; empty for anything else: no map in play, the waiting room, whose room is a
## match too, a showdown, the Final Hand.
static func capture(session: NetSession) -> Dictionary:
	var match_node := session.match_node if session != null else null
	if match_node == null or not match_node.puppet or match_node.state not in PLAYING:
		return {}
	var layout := match_node.arena_layout
	if layout != null and layout.resource_path == WAITING_ROOM:
		return {}
	if match_node.rules.showdown() or match_node.rules.final_hand:
		return {}
	var owners := owners_of(session)
	var slots: Array = []
	for slot: PlayerSlot in match_node.slots:
		var entry := {
			"human": slot.is_human(),
			"here": slot.is_local_human(),
			"color": slot.color_index,
			"team": slot.team,
			"name": slot.player_name,
			"style": slot.style.to_array(),
			"trait": String(slot.bot_trait.id) if slot.bot_trait != null else "",
			"banked": slot.banked,
			"kills": slot.kills,
			"deaths": slot.deaths,
			"stats": slot.stats.to_array(),
			"respawn": slot.respawn_left,
		}
		entry.merge(owners.get(slot.index, {}))
		var kart := slot.kart
		if kart != null and is_instance_valid(kart):
			entry.merge(_kart_of(kart))
		slots.append(entry)
	return {
		"rules": match_node.rules.to_wire(),
		"state": match_node.state,
		"time": match_node.time_left,
		"bounty": [match_node.bounty_slot, match_node.bounty_left],
		"jackpots": _jackpots_of(match_node),
		"floor": _floor_of(match_node),
		"slots": slots,
	}


## Where [param kart] stood and what it carried.
static func _kart_of(kart: Kart) -> Dictionary:
	return {
		"x": kart.global_position.x,
		"z": kart.global_position.z,
		"h": kart.motor.heading,
		"alive": kart.alive,
		"lives": kart.lives,
		"coins": kart.pot.coins,
		"mult": kart.pot.mult,
		"partial": kart.pot.partial(),
		"item": String(kart.held_item.id) if kart.held_item != null else "",
		"jokers": kart.jokers.ids(),
	}


## Whose each slot of [param session]'s room is, by its index: the Steam account and the number of
## the seat at their machine of everybody playing, this machine's own players marked here.
static func owners_of(session: NetSession) -> Dictionary:
	var owners := {}
	for guest: Dictionary in session.host_controls.guests():
		if guest.has("slot"):
			var account := int(guest.get("account", 0))
			var owner := {"account": account, "peer": int(guest.get("peer", 0))}
			owner["seat"] = int(guest.get("seat", 0))
			owners[int(guest["slot"])] = owner
	var own := Store.steam.account if Store.on() else 0
	for each: ClientSeat in session.seats:
		if each.slot >= 0:
			var player := each.input as PlayerInput
			var device := player.device if player != null else DeviceInput.ANY
			owners[each.slot] = {"account": own, "seat": each.seat, "device": device}
	return owners


static func _jackpots_of(match_node: Match) -> Array:
	var piles: Array = []
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		piles.append(zone.chips)
	return piles


## What lies dropped on the floor: chips out of a pot, items and jokers off a kart. What the pads
## put out they put out again.
static func _floor_of(match_node: Match) -> Array:
	var found: Array = []
	for pickup: Pickup in match_node.puppet_pickups.values():
		if pickup == null or not is_instance_valid(pickup) or pickup.is_queued_for_deletion():
			continue
		var at := pickup.global_position
		var chip := pickup as Chip
		var box := pickup as ItemBox
		var card := pickup as FloorJoker
		if chip != null and chip.dropped:
			found.append(
				{"kind": "chip", "x": at.x, "z": at.z, "gold": chip.gold, "value": chip.value}
			)
		elif box != null and box.fixed_item != null:
			found.append({"kind": "item", "x": at.x, "z": at.z, "item": String(box.fixed_item.id)})
		elif card != null and card.joker != null:
			found.append({"kind": "joker", "x": at.x, "z": at.z, "joker": String(card.joker.id)})
	return found


## Every slot's player at the new host, [param resume] says: this machine's own on its devices, and
## a bot at the wheel of everybody else's, a player coming back taking theirs over, see
## [method HostControls.resume_from].
static func inputs(resume: Dictionary) -> Array[KartInput]:
	var made: Array[KartInput] = []
	for entry: Dictionary in resume.get("slots", []):
		if bool(entry.get("here", false)):
			var device := int(entry.get("device", DeviceInput.ANY))
			made.append(PlayerInput.new(device, int(entry.get("seat", 0))))
		else:
			made.append(BotInput.new())
	return made


## Starts [param match_node] as [param resume] says, slot for slot as it was, held on the grid
## until the players coming back are in, see [method HostControls.resume_from].
static func start(match_node: Match, resume: Dictionary) -> void:
	var colors: Array[int] = []
	var names: Array[String] = []
	var styles: Array = []
	var teams: Array[int] = []
	for entry: Dictionary in resume.get("slots", []):
		colors.append(int(entry.get("color", -1)))
		names.append(str(entry.get("name", "")))
		styles.append(entry.get("style", null))
		teams.append(int(entry.get("team", -1)))
	match_node.hold_start = true
	match_node.start(inputs(resume), 0, colors, names, styles, teams)
	restore(match_node, resume)


## [param resume] put back on [param match_node], started from it: every slot and kart, the clock,
## the bounty, the Jackpot's pile and the floor.
static func restore(match_node: Match, resume: Dictionary) -> void:
	var entries: Array = resume.get("slots", [])
	for i: int in mini(entries.size(), match_node.slots.size()):
		_restore_slot(match_node, match_node.slots[i], entries[i])
	match_node.time_left = float(resume.get("time", match_node.time_left))
	var bounty: Array = resume.get("bounty", [-1, 0.0])
	var crowned := int(bounty[0]) if bounty.size() > 0 else -1
	if crowned >= 0 and crowned < match_node.slots.size():
		match_node.bounty_slot = crowned
		match_node.bounty_left = float(bounty[1]) if bounty.size() > 1 else 0.0
		var kart := match_node.slots[crowned].kart
		if kart != null and kart.alive:
			kart.set_bounty(true)
	var piles: Array = resume.get("jackpots", [])
	for i: int in mini(piles.size(), match_node.arena.jackpot_zones.size()):
		match_node.arena.jackpot_zones[i].chips = float(piles[i])
	for left: Dictionary in resume.get("floor", []):
		_restore_floor(match_node, left)


static func _restore_slot(match_node: Match, slot: PlayerSlot, entry: Dictionary) -> void:
	slot.banked = int(entry.get("banked", 0))
	slot.kills = int(entry.get("kills", 0))
	slot.deaths = int(entry.get("deaths", 0))
	if entry.has("stats"):
		slot.stats.from_array(entry["stats"])
	var kart := slot.kart
	if kart == null or not entry.has("x"):
		return
	kart.global_position = Vector3(float(entry["x"]), 0.0, float(entry["z"]))
	var heading := float(entry.get("h", 0.0))
	kart.face(Vector3(-sin(heading), 0.0, -cos(heading)))
	kart.pot.coins = int(entry.get("coins", 0))
	kart.pot.mult = float(entry.get("mult", 1.0))
	kart.pot.set_partial(float(entry.get("partial", 0.0)))
	kart.held_item = MatchSnapshot._item_by_id(str(entry.get("item", "")))
	var hand: Array[Joker] = []
	for id: Variant in entry.get("jokers", []):
		var joker := match_node.joker_catalog.by_id(StringName(str(id)))
		if joker != null:
			hand.append(joker)
	kart.jokers.deal(hand)
	kart.lives = int(entry.get("lives", kart.lives))
	if not bool(entry.get("alive", true)):
		_lay_down(kart)
		slot.respawn_left = maxf(float(entry.get("respawn", 0.0)), 0.5)


## [param kart] out, as it was when its host went, with nothing of a death about it: no wreck, no
## pot spilled, no death counted twice. It comes back once its wait is out, as any kart does.
static func _lay_down(kart: Kart) -> void:
	kart.alive = false
	kart.collision_layer = 0
	kart.collision_mask = 0
	kart.velocity = Vector3.ZERO
	kart.motor.velocity = Vector3.ZERO
	var body := kart.get_node_or_null("Body") as Node3D
	if body != null:
		body.visible = false
	kart.smoke.emitting = false


static func _restore_floor(match_node: Match, left: Dictionary) -> void:
	var arena := match_node.arena
	var at := Vector3(float(left.get("x", 0.0)), 0.0, float(left.get("z", 0.0)))
	var lifetime := match_node.rules.dropped_chip_lifetime
	match str(left.get("kind", "")):
		"chip":
			var chip := Chip.new()
			chip.gold = bool(left.get("gold", false))
			chip.value = int(left.get("value", match_node.rules.chip_value))
			chip.dropped = true
			chip.lifetime = lifetime
			arena.place_drop(chip, arena.clamp_to_floor(at))
		"item":
			var item := MatchSnapshot._item_by_id(str(left.get("item", "")))
			if item != null:
				var box := ItemBox.new()
				box.fixed_item = item
				box.lifetime = lifetime
				arena.place_drop(box, arena.clamp_to_floor(at))
		"joker":
			var joker := match_node.joker_catalog.by_id(StringName(str(left.get("joker", ""))))
			if joker != null:
				var card := FloorJoker.new()
				card.joker = joker
				card.lifetime = lifetime
				arena.place_drop(card, arena.clamp_to_floor(at))


## The seats [param resume] keeps for the players coming back, by who they were, see
## [method returning]: the number of each seat at their machine and the slot it is, with its
## color, team and name, see [method PeerSeats.kept_for].
static func seats_kept(resume: Dictionary) -> Dictionary:
	var kept := {}
	var entries: Array = resume.get("slots", [])
	for index: int in entries.size():
		var entry: Dictionary = entries[index]
		var key := returning(int(entry.get("account", 0)), int(entry.get("peer", 0)))
		if not bool(entry.get("human", false)) or bool(entry.get("here", false)) or key.is_empty():
			continue
		var theirs: Dictionary = kept.get(key, {})
		theirs[int(entry.get("seat", 0))] = {
			"slot": index,
			"color": int(entry.get("color", -1)),
			"team": int(entry.get("team", -1)),
			"name": str(entry.get("name", "")),
		}
		kept[key] = theirs
	return kept


## Who a player coming back to a map carried over is: their Steam account, or off Steam the peer
## they were in the old game; empty for nobody known.
static func returning(account: int, was: int) -> String:
	if account != 0:
		return "a%d" % account
	return "p%d" % was if was != 0 else ""
