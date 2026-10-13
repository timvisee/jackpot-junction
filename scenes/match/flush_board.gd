class_name FlushBoard
extends RefCounted
## The Royal Flush pads' side of a match, GAME.md 3.9: what the pads pay their holders, the flush
## still paying after it cleared, and a pad changing hands, which may be a flush. The board's state
## is the match's own, [member Match.flush_lock_slot] and the rest, since the snapshot carries it.


## Every pad a kart is holding trickles coins into its pot, so the pads are worth driving over even
## when a flush is out of reach; a holder dead, falling or rolling out the end of the match earns
## nothing meanwhile. The trickle runs with the room: at the top excitement level of 8.4 the pads
## pay three times what they pay over a quiet opening lap.
static func step(match_node: Match, delta: float) -> void:
	var rules := match_node.rules
	var rate := (
		rules.flush_pad_income
		* lerpf(1.0, rules.flush_pad_income_hot, match_node.intensity.share())
	)
	var locked := _step_lock(match_node, delta)
	# One clock for the whole board rather than one per pad: the pads pay on the same beat, so
	# two pads across the room from each other throw their rings together and a player holding
	# three of them is paid three coins at once instead of a stutter of singles.
	match_node.flush_change += rate * delta
	var coins := floori(match_node.flush_change)
	if coins <= 0:
		return
	match_node.flush_change -= float(coins)
	var slots := match_node.slots
	for pad: FlushPad in match_node.arena.flush_pads:
		var slot := locked if locked >= 0 else pad.owner_slot
		if slot < 0 or slot >= slots.size():
			continue
		if locked < 0 and pad.is_disabled():
			continue
		var kart := slots[slot].kart
		if kart == null or not kart.is_active():
			continue
		kart.collect_coins(coins, null)
		# While a flush is resting the pads wear nobody's color, so the rings say whose flush
		# is still being paid out.
		pad.pop_halo(slots[slot].color() if locked >= 0 else Color.TRANSPARENT)


## Whose flush is still paying, or -1 when none is. A Royal Flush clears the board it was won
## on, so without this the reward for winning one is that the thing paying you stops: the four
## pads keep paying the winner for a while as if they were still held, GAME.md 3.9.
static func _step_lock(match_node: Match, delta: float) -> int:
	if match_node.flush_lock_left <= 0.0:
		return -1
	match_node.flush_lock_left = maxf(match_node.flush_lock_left - delta, 0.0)
	return match_node.flush_lock_slot if match_node.flush_lock_left > 0.0 else -1


## A flush pad changed hands. Holding all four at once is a Royal Flush, GAME.md 3.9: a mult
## bonus and a full nitro tank, and the pads clear and rest for a while. All four being every pad
## of the room the pad is in: a map of rooms, 9.4a, has a flush a room.
static func claimed(pad: FlushPad, kart: Kart, match_node: Match) -> void:
	var slots := match_node.slots
	var rules := match_node.rules
	if kart.slot >= 0 and kart.slot < slots.size():
		slots[kart.slot].stats.add(&"pads_taken")
	Events.pad_claimed.emit(kart.slot)
	var room: Array[FlushPad] = []
	for other: FlushPad in match_node.arena.flush_pads:
		if other.group == pad.group:
			room.append(other)
	for other: FlushPad in room:
		if other.owner_slot != kart.slot:
			return
	for other: FlushPad in room:
		other.clear_and_disable(rules.flush_disable_time)
	match_node.flush_lock_slot = kart.slot
	match_node.flush_lock_left = rules.flush_lock_seconds
	kart.gain_mult(rules.flush_mult, &"flush")
	kart.refill_nitro(rules.flush_nitro_refill)
	if kart.slot < slots.size():
		slots[kart.slot].stats.add(&"flushes")
	if match_node.camera_rig != null:
		match_node.camera_rig.shake(0.4)
	Events.flush_completed.emit(kart.slot)
