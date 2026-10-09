class_name ClientSeat
extends RefCounted
## One seat played at a client, GAME.md 10.3: its controls, the slot the host gave it, and the kart
## it drives there ahead of the host, corrected by what the host made of it. A client with two
## players at it has two of these, each asked for, driven, sent and corrected on its own; the first
## is the one [member NetSession.local_slot] names.

## Which of this machine's players it is: their number here, and their seat of the settings, the
## Seats tab's name and the stalls' dress among it.
var seat := 0
var input: KartInput
## The slot the host gave it in the room it is in, -1 until it has.
var slot := -1
## What its player calls themselves and how they dressed their kart, GAME.md 3.8 and 4.4, said to
## the host once the seat is theirs. Empty leaves the host's own.
var player_name := ""
var style := PackedInt32Array()
var prediction: KartPrediction
## What its kart takes off the table, seen here first, see [TakePrediction].
var takes := TakePrediction.new()
## What its player chose of their jokers since the last tick, for the host by name, see
## [JokerWire]: an answered pick, [code][&"answer", taken, replaced][/code], or a card out of the
## hand, [code][&"drop", id][/code] or [code][&"destroy", id][/code].
var said: Array[Array] = []
## The host's latest word on this seat's kart, waiting for the physics step to act on it, see
## [method NetSession._receive_authority]: [ack, state, whether the host drove it].
var authority: Array = []
## The number put on the next set of controls sent, see [method step].
var seq := 0
## Whether its player's controls are working a menu rather than the kart: any menu up at this
## screen in the waiting room, the host's match settings at a dedicated server among them, GAME.md
## 9.3a and 9.6. The kart is sent nothing to drive on, and waits.
var held := false
## The pick whose answer has gone to the host, so it is said once.
var _told: JokerOffer


static func make(
	number: int, controls: KartInput, named := "", dressed := PackedInt32Array()
) -> ClientSeat:
	var made := ClientSeat.new()
	made.seat = number
	made.input = controls
	made.player_name = named
	made.style = dressed
	return made


## Its seat given up, for the next room: the slot and the kart belong to the room that has gone.
func forget_room() -> void:
	slot = -1
	prediction = null
	authority = []
	takes = TakePrediction.new()


## Takes over the driving of this seat's kart once the snapshot has built it. Asked every tick
## rather than once, the way the kart's voice is: which slot is ours arrives in a message of its
## own, and the karts may well have been built before it did.
func adopt(match_node: Match) -> void:
	if match_node == null or slot < 0 or slot >= match_node.slots.size():
		return
	var kart := match_node.slots[slot].kart
	if kart == null:
		return
	if prediction != null and is_instance_valid(prediction.kart) and prediction.kart == kart:
		return
	prediction = KartPrediction.new(kart)


## Whether this seat is driving its own kart rather than watching it, GAME.md 10.3. A kart the host
## has frozen on the grid, killed or sent rolling out the end of the match is none of this
## machine's business to move, so it goes back to following the snapshot until it is again.
func drivable(match_node: Match) -> bool:
	if prediction == null or not is_instance_valid(prediction.kart):
		return false
	return prediction.kart.alive and match_node.is_running()


## One tick of this seat: its controls read, its joker pick answered, and its kart driven here
## first, GAME.md 10.3. Returns what goes to the host: the controls, the tick's number and what
## this machine made of the tick, which the host follows rather than second-guesses.
func step(match_node: Match, delta: float) -> Array:
	input.poll(delta)
	if held:
		input.clear()
	_step_offer(match_node)
	_step_hand(match_node)
	seq += 1
	var claim: Array = []
	var own := prediction != null and is_instance_valid(prediction.kart)
	if own:
		var driving := drivable(match_node)
		if driving != prediction.kart.predicted:
			# Killed, frozen on the grid or handed back: stop driving and forget the ticks in
			# hand, since nobody will be asking about them. Or the other way round.
			if driving:
				prediction.resume()
			else:
				prediction.suspend()
		if driving:
			prediction.predict(input, delta, seq)
			claim = KartPrediction.capture(prediction.kart)
			takes.step(match_node, prediction, delta)
	var packet := NetInput.encode(input)
	if own:
		# The aim goes out as a direction rather than as whatever the stick happened to read,
		# because a mouse reads nothing at all: the pointer is on this screen and the host has one
		# of its own, GAME.md 10.3.
		packet[NetInput.FIELDS] = KartAim.pointed_flat(prediction.kart)
	return [packet, seq, claim]


## The joker pick in front of this seat's player, answered here, GAME.md 10.3. The host is running
## the same pick off the same controls and its answer is the one that counts, but waiting a round
## trip to see the cursor move, and another to see a card taken, is the whole of what made picking
## a joker on a client feel broken. The snapshot leaves this one alone while it is open.
func _step_offer(match_node: Match) -> void:
	if slot < 0 or slot >= match_node.slots.size():
		return
	var offer := match_node.slots[slot].offer
	if offer != null and not offer.is_done():
		offer.poll_input(input)
	# Answered: the host is told which card, by name, rather than left to work it out again from
	# the controls, see [JokerWire].
	if offer != null and offer != _told and not offer.answer().is_empty():
		_told = offer
		said.append([&"answer"] + offer.answer())


## The hand of this seat's player, opened and walked here, GAME.md 10.3, for the same reason the
## pick is: a cursor a round trip behind the stick is a cursor on the wrong card. A card dropped or
## destroyed goes out of the hand here at once and to the host by name, and the snapshots made
## before the host heard leave the hand as it is here meanwhile.
func _step_hand(match_node: Match) -> void:
	if slot < 0 or slot >= match_node.slots.size():
		return
	var mine := match_node.slots[slot]
	var kart := mine.kart
	if kart == null or not KartMenu.browse(kart, input) or not kart.alive:
		return
	var what := &"drop" if input.joker_drop_pressed else &""
	if input.joker_destroy_pressed and what.is_empty():
		what = &"destroy"
	if what.is_empty() or kart.menu_index >= kart.jokers.count():
		return
	said.append([what, kart.jokers.ids()[kart.menu_index]])
	var gone := kart.jokers.remove_at(kart.menu_index)
	if gone != null:
		if what == &"destroy":
			Events.joker_destroyed.emit(slot, gone.id)
		else:
			Events.joker_left.emit(slot, gone.id)
	kart.menu_index = clampi(kart.menu_index, 0, maxi(kart.jokers.count() - 1, 0))
	mine.hand_changed_at = Time.get_ticks_msec() * 0.001


## Keeps the host's word on this kart for the physics step, only the newest: an older one describes
## a tick the newer has already answered for.
func hold(ack: int, state: Array, host_drove: bool) -> void:
	if authority.is_empty() or ack >= int(authority[0]):
		authority = [ack, state, host_drove]


## Acts on the host's word, in the physics step where a correction belongs.
func settle(delta: float) -> void:
	if authority.is_empty():
		return
	if prediction != null and is_instance_valid(prediction.kart) and prediction.kart.predicted:
		if bool(authority[2]):
			prediction.reconcile(int(authority[0]), authority[1], delta)
		else:
			# The host followed this machine's own answer for that tick, so there is nothing to put
			# right. The history is trimmed and the kart carries on undisturbed, which is most
			# ticks of most matches and the whole point of claiming at all.
			prediction.accept(int(authority[0]))
	authority = []


## Whether the shot the host says [param shooter] fired is one this seat already fired for itself,
## on the tick its button went down, which would otherwise be the same shot heard twice.
func fired_first(shooter: int) -> bool:
	return (
		shooter == slot
		and prediction != null
		and is_instance_valid(prediction.kart)
		and prediction.kart.predicted
	)


func debug_text() -> String:
	if prediction == null or not is_instance_valid(prediction.kart):
		return ""
	return "%s  %s" % [prediction.debug_text(), takes.debug_text()]
