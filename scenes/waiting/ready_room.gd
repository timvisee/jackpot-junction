class_name ReadyRoom
extends Node
## Readying up in the waiting room, GAME.md 9.6: the cash-out pad is the ready marker.
##
## A match starts when everybody says they are ready, and the saying is done by driving. Standing
## on the pad charges it, a ring round it fills as it charges, and when it is full a tick floats
## over the kart. A button on a menu would do the same job, but it would not tell the four people
## in the room which of them everybody is waiting for, and it would not put the player who is
## waiting anywhere in particular. The pad does both: a kart parked on the pad is a player who has
## said yes, in the one place everybody is already looking.
##
## Ready lasts exactly as long as the standing does. Roll off the pad and it is taken back at
## once, which is the honest reading of a pad somebody is not on: a room that starts because
## everybody was ready a moment ago starts without them.
##
## Each player charges their own arc of the ring, in their own colour, so that a room with four
## people in it can see which of them the pad has taken and which of them it is waiting for.

## Everybody has been ready for [constant GO_DELAY]: the ring has blinked and the room is
## going. Not the moment the last player readies up, since the room says so before it goes.
signal everybody_ready

## How long a kart has to hold the pad. Leaving it does not fade: the charge is gone and so is the
## ready, on the frame the kart rolls off.
const CHARGE_TIME := 2.5
## A full house blinks the whole ring green once, and the room goes a second after it filled. The
## blink is on at once, holds, and fades over the last part of its time, so it reads as one flash
## rather than as the ring turning green and then changing its mind.
const BLINK_TIME := 0.45
const BLINK_FADE := 0.4
const BLINK_GLOW := 1.2
const BLINK_BODY := 0.6
const GO_DELAY := 1.0
## The ring that fills: how many blocks it is made of, how far out they sit as a share of the
## pad's radius, and how big each one is.
const SEGMENTS := 24
const RING_OUT := 1.14
const SEGMENT_SIZE := Vector2(0.22, 0.34)
## How far over a kart its tick floats, and how big the tick is drawn.
const TICK_HEIGHT := 2.3
const TICK_SCALE := 1.15
## The two strokes of the tick, each as a start and an end in the flat: a short one down into the
## corner and a long one up out of it, which is the shape of a tick from where the camera sits.
const STROKES: Array[Array] = [
	[Vector2(-0.40, 0.00), Vector2(-0.10, 0.30)],
	[Vector2(-0.10, 0.30), Vector2(0.45, -0.45)],
]
const READY_INK := Color(0.26, 0.86, 0.42)
const WAITING_INK := Color(0.16, 0.17, 0.2)
## How far in from the back wall the sign stands. Inside the room rather than behind it: out
## there it competed with the benches and chests along the wall, and here the floor is the
## karts' and nothing else is standing on it.
const BOARD_IN := 1.9
## The ink the joining lines under the count are written in.
const HINT_INK := Color(0.82, 0.83, 0.88)

var match_node: Match
var pad: JunctionPad
## Whether this machine decides who is ready. The host simulates every kart, so it is the one
## that can see who is standing on the pad; a client is told, the same way it is told everything
## else about somebody else's kart, GAME.md 10.3.
var deciding := true

## Whether the room is kept from going: the host is choosing the match, GAME.md 9.6. A room that
## went while its host was halfway through the menu would go to whatever was set before they
## started, and would take the host with it mid-choice.
var held := false

## Slot index to how far that player has charged, 0 to 1, and whether they have finished.
var charge: Dictionary[int, float] = {}
var ready_slots: Dictionary[int, bool] = {}

var _segments: Array[MeshInstance3D] = []
var _ticks: Dictionary[int, Node3D] = {}
## Seconds the room has been full, or -1 while somebody is still to ready up. Somebody rolling off
## in the second before the room goes puts it back to -1: ready lasts as long as the standing does,
## and that is as true in the last second as in any other.
var _full_for := -1.0
var _board: ReadyStand
var _counter: Label
var _hints: VBoxContainer
var _online_hint: Label
## What the next match is, as the host last said it.
var _plan: Label
var _said := ""


## Watches [param in_match]'s pad and puts the ring round it. Returns nothing useful; the room
## keeps the handle so it can ask who is ready.
static func add_to(in_match: Match) -> ReadyRoom:
	var room := ReadyRoom.new()
	room.name = "ReadyRoom"
	room.match_node = in_match
	in_match.add_child(room)
	room.deciding = not in_match.puppet
	room._build()
	Events.player_ready.connect(room._on_player_ready)
	Events.match_planned.connect(room._on_match_planned)
	return room


## Somebody has readied up, or taken it back. On the host this is its own word coming back to it;
## on a client it is the first it has heard of it, and the only thing it has to go on.
func _on_player_ready(slot: int, ready: bool) -> void:
	if ready_slots.get(slot, false) == ready:
		return
	ready_slots[slot] = ready
	charge[slot] = 1.0 if ready else 0.0
	if ready:
		Audio.play_sfx(&"pad_claim", -4.0)


## How many of the players in the room have readied up, and how many there are to ready. Bots are
## not counted either way: nobody is waiting on them and they cannot drive onto a pad to say so.
func ready_count() -> int:
	var done := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human() and ready_slots.get(slot.index, false):
			done += 1
	return done


func player_count() -> int:
	var seats := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human():
			seats += 1
	return seats


## Whether the room is waiting on anybody. An empty room is not ready: a match with nobody in it
## has nothing to start.
func all_ready() -> bool:
	return player_count() > 0 and ready_count() == player_count()


func _process(delta: float) -> void:
	if pad == null:
		return
	if not deciding:
		for slot: PlayerSlot in match_node.slots:
			if slot.kart != null:
				_show_tick(slot)
		_count_down(delta)
		_paint_ring()
		_say_the_count()
		return
	var standing := _karts_on_the_pad()
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_human() or slot.kart == null:
			continue
		var index := slot.index
		var on_it := standing.has(index)
		var was: float = charge.get(index, 0.0)
		var now := clampf(was + delta / CHARGE_TIME, 0.0, 1.0) if on_it else 0.0
		charge[index] = now
		var already: bool = ready_slots.get(index, false)
		if (now >= 1.0) != already:
			ready_slots[index] = now >= 1.0
			Events.player_ready.emit(index, now >= 1.0)
		_show_tick(slot)
	_count_down(delta)
	_paint_ring()
	_say_the_count()


## The second between the room filling and the room going. A client runs it as well, off what it
## has been told, so the ring blinks on every screen and not only on the host's; only the host's
## going is acted on, and a client follows when told to, see 10.3.
func _count_down(delta: float) -> void:
	if held or not all_ready():
		_full_for = -1.0
		return
	var was := _full_for
	_full_for = maxf(_full_for, 0.0) + (delta if was >= 0.0 else 0.0)
	if was < GO_DELAY and _full_for >= GO_DELAY:
		everybody_ready.emit()


## How far through the blink the ring is: 1 while it is lit, falling to 0 over the fade, and 0 the
## rest of the time.
func blink() -> float:
	if _full_for < 0.0:
		return 0.0
	return clampf((BLINK_TIME - _full_for) / (BLINK_TIME * BLINK_FADE), 0.0, 1.0)


## How many are ready, said twice: once at the top of the screen for the player at this machine,
## and once on a board in the room for everybody looking at it. Both are rewritten only when the
## count changes -- a board refits its lettering to the words, which is not work for every frame
## of a room where nothing is happening.
func _say_the_count() -> void:
	var words := "%d / %d PLAYERS READY" % [ready_count(), player_count()]
	if words == _said:
		return
	_said = words
	if _counter != null:
		_counter.text = words
	if _board != null:
		_board.say(words)


## The host has said what the next match is, or that they are still choosing. Either way it goes
## under the count, because what is about to be played is the other thing a room of people
## waiting to play it wants to know.
func _on_match_planned(summary: String, choosing: bool) -> void:
	held = choosing
	_plan.text = "The host is choosing the match" if choosing else "Next: %s" % summary
	_plan.visible = true


## What to say about getting more people into the room: how somebody at this machine takes a
## seat, and, when there is a host to join, how somebody at another machine does.
##
## The room is the place both of those questions get asked, so it is the place they are answered.
## Anywhere else and a player has to leave the room to find out how to let their friend in.
func say_how_to_join(online: String) -> void:
	_online_hint.text = online
	_online_hint.visible = not online.is_empty()


## Which players are standing on the pad this frame.
func _karts_on_the_pad() -> Dictionary[int, bool]:
	var standing: Dictionary[int, bool] = {}
	for body: Node3D in pad.get_overlapping_bodies():
		var kart := body as Kart
		if kart != null and kart.alive and kart.rules == match_node.rules:
			standing[kart.slot] = true
	return standing


## The ring, split between whoever is in the room: an arc each, in their own colour, filling as
## they hold the pad. One ring showing the furthest anybody had got read as one pad filling, which
## in a room of four says nothing about which of them it has taken.
func _paint_ring() -> void:
	var seats := _seated()
	var inks: Array[Color] = []
	for i: int in _segments.size():
		inks.append(WAITING_INK)
	for s: int in seats.size():
		var from := int(round(float(s) * float(SEGMENTS) / float(seats.size())))
		var to := int(round(float(s + 1) * float(SEGMENTS) / float(seats.size())))
		var span := maxi(to - from, 1)
		var full := int(round(charge.get(seats[s].index, 0.0) * float(span)))
		for k: int in span:
			if from + k < inks.size() and k < full:
				inks[from + k] = seats[s].color()
	var flash := blink()
	for i: int in _segments.size():
		var skin := _segments[i].material_override as StandardMaterial3D
		var on := inks[i] != WAITING_INK
		# The flash is carried by the glow over a darker body. Lit on both counts, a block lying on a
		# bright floor goes past green to mint, and it is green the room is meant to see.
		skin.albedo_color = inks[i].lerp(READY_INK.darkened(BLINK_BODY), flash)
		skin.emission = inks[i].lerp(READY_INK, flash)
		skin.emission_energy_multiplier = lerpf(1.4 if on else 0.0, BLINK_GLOW, flash)


## The players the ring is divided between, in slot order so that an arc stays where it was as
## somebody else readies up.
func _seated() -> Array[PlayerSlot]:
	var seats: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human():
			seats.append(slot)
	return seats


## The tick over a kart that has readied up, kept over its head as it drives, and taken away the
## moment the pad is left.
func _show_tick(slot: PlayerSlot) -> void:
	var done: bool = ready_slots.get(slot.index, false)
	if not done:
		if _ticks.has(slot.index):
			(_ticks[slot.index] as Node3D).queue_free()
			_ticks.erase(slot.index)
		return
	if not _ticks.has(slot.index):
		_ticks[slot.index] = _build_tick()
	var tick: Node3D = _ticks[slot.index]
	tick.global_position = slot.kart.global_position + Vector3(0.0, TICK_HEIGHT, 0.0)


## Two strokes lying flat over the kart. Flat rather than turned to the camera: the camera of 8.2
## looks down at a fixed tilt, so a tick drawn on the floor plane reads as a tick from the only
## angle anybody sees it from, and it never swings about as the rig pans.
func _build_tick() -> Node3D:
	var holder := Node3D.new()
	holder.name = "Ready"
	var lit := StandardMaterial3D.new()
	lit.albedo_color = READY_INK
	lit.emission_enabled = true
	lit.emission = READY_INK
	lit.emission_energy_multiplier = 1.6
	for stroke: Array in STROKES:
		var from: Vector2 = stroke[0] * TICK_SCALE
		var to: Vector2 = stroke[1] * TICK_SCALE
		var along := to - from
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(along.length() + 0.16, 0.1, 0.18)
		bar.mesh = mesh
		bar.material_override = lit
		var middle := (from + to) * 0.5
		bar.position = Vector3(middle.x, 0.0, middle.y)
		bar.rotation.y = atan2(-along.y, along.x)
		holder.add_child(bar)
	match_node.add_child(holder)
	return holder


func _build() -> void:
	pad = match_node.arena.junction
	if pad == null:
		return
	var radius := match_node.arena.junction_radius * RING_OUT
	for i: int in SEGMENTS:
		var turn := TAU * float(i) / float(SEGMENTS)
		var skin := StandardMaterial3D.new()
		skin.albedo_color = WAITING_INK
		skin.emission_enabled = true
		skin.emission = READY_INK
		skin.emission_energy_multiplier = 0.0
		var block := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(SEGMENT_SIZE.x, 0.05, SEGMENT_SIZE.y)
		block.mesh = mesh
		block.material_override = skin
		block.position = (
			pad.position + Vector3(sin(turn), 0.06, cos(turn)) * radius + Vector3(0.0, 0.0, 0.0)
		)
		block.rotation.y = turn
		match_node.arena.add_child(block)
		_segments.append(block)
	_build_board()
	_build_counter()


## The sign standing at the top of the room. A room that has a clock hangs it on a hoarding over
## the crowd; there is no crowd in here and the camera is holding the whole floor, so the count
## goes on a pavement sign standing on the concrete instead, inside the shot and out of the way
## against the back wall.
func _build_board() -> void:
	var half := match_node.arena.world_size() * 0.5
	var at := Vector3(0.0, 0.0, -(half.y - BOARD_IN))
	_board = ReadyStand.add_to(match_node.arena, at, Vector3.ZERO, match_node.arena.room)


## And the same count at the top of the screen, for the player who is looking at their own kart
## rather than at the room.
func _build_counter() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ReadyCount"
	layer.layer = 12
	match_node.add_child(layer)
	_counter = Label.new()
	_counter.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_counter.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_counter.offset_top = 18.0
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(_counter, Type.numbers_font(), Type.HEADING)
	HudText.shadowed(_counter)
	_hints = VBoxContainer.new()
	_hints.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_hints.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hints.offset_top = 18.0
	_hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hints.alignment = BoxContainer.ALIGNMENT_CENTER
	_hints.add_theme_constant_override("separation", 6)
	layer.add_child(_hints)
	_hints.add_child(_counter)
	_plan = Label.new()
	_plan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plan.visible = false
	Type.text(_plan, Type.LABEL, READY_INK)
	HudText.shadowed(_plan)
	_hints.add_child(_plan)
	# Both ways in, drawn as the buttons they are, the way the lobby says it. Whoever is about to
	# take a seat has not pressed anything yet, so the device this machine last heard from says
	# which one the player already driving is holding, not which one the newcomer has picked up.
	var ways: Array = []
	for keyboard: bool in [true, false]:
		var button := InputHint.glyph(InputActions.JOIN, keyboard, HINT_INK, Type.LABEL)
		if button != null:
			ways.append(button)
	var seat := InputHint.row(
		"%s or %s to take a seat" if ways.size() > 1 else "%s to take a seat",
		ways,
		HINT_INK,
		Type.LABEL
	)
	seat.alignment = BoxContainer.ALIGNMENT_CENTER
	_hints.add_child(seat)
	_online_hint = Label.new()
	_online_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_online_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_online_hint.visible = false
	Type.text(_online_hint, Type.LABEL, HINT_INK)
	HudText.shadowed(_online_hint)
	_hints.add_child(_online_hint)
