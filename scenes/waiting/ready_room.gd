class_name ReadyRoom
extends Node
## Readying up in the waiting room, GAME.md 9.6: the cash-out pad is the ready marker.
##
## A match starts when everybody says they are ready, and the saying is done by driving. Standing
## on the pad charges it, a ring round it fills as it charges, and when it is full a tick floats
## over the kart and stays there. A button on a menu would do the same job, but it would not tell
## the four people in the room which of them everybody is waiting for, and it would not put the
## player who is waiting anywhere in particular. The pad does both: a kart parked on the pad is a
## player who has said yes, in the one place everybody is already looking.
##
## Ready is sticky. Rolling off the pad afterwards does not take it back, so the last player in
## does not find the first has drifted off and undone it.

signal everybody_ready

## How long a kart has to hold the pad, and how fast the charge runs back out when it leaves. It
## runs out slower than it goes in, so clipping a corner of the pad and coming straight back does
## not start again from nothing.
const CHARGE_TIME := 2.5
const FADE_RATE := 0.6
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
## How high the count is lettered on the board, and how far behind the room the board stands.
const BOARD_SIZE := 0.9
const BOARD_BACK := 5.0
## The ink the joining lines under the count are written in.
const HINT_INK := Color(0.82, 0.83, 0.88)

var match_node: Match
var pad: JunctionPad

## Slot index to how far that player has charged, 0 to 1, and whether they have finished.
var charge: Dictionary[int, float] = {}
var ready_slots: Dictionary[int, bool] = {}

var _segments: Array[MeshInstance3D] = []
var _ticks: Dictionary[int, Node3D] = {}
var _announced := false
var _board: Billboard
var _board_words: Label3D
var _counter: Label
var _hints: VBoxContainer
var _online_hint: Label
var _said := ""


## Watches [param in_match]'s pad and puts the ring round it. Returns nothing useful; the room
## keeps the handle so it can ask who is ready.
static func add_to(in_match: Match) -> ReadyRoom:
	var room := ReadyRoom.new()
	room.name = "ReadyRoom"
	room.match_node = in_match
	in_match.add_child(room)
	room._build()
	return room


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
	var standing := _karts_on_the_pad()
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_human() or slot.kart == null:
			continue
		var index := slot.index
		var on_it := standing.has(index)
		var was: float = charge.get(index, 0.0)
		var now := clampf(
			was + (delta / CHARGE_TIME if on_it else -delta * FADE_RATE / CHARGE_TIME), 0.0, 1.0
		)
		charge[index] = now
		if now >= 1.0 and not ready_slots.get(index, false):
			ready_slots[index] = true
			Audio.play_sfx(&"pad_claim", -4.0)
		_show_tick(slot)
	_paint_ring()
	_say_the_count()
	if all_ready() and not _announced:
		_announced = true
		everybody_ready.emit()


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
	if _board != null and _board_words != null:
		_board_words.text = words
		_board_words.pixel_size = _board.fitted(words, BOARD_SIZE) / float(Billboard.FONT_SIZE)


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


## The ring: dark all the way round, and lit as far round as the furthest charge has got. It
## reads as one pad filling rather than as four, which is what a player standing on it is asking
## about -- whether the pad has taken them yet.
func _paint_ring() -> void:
	var most := 0.0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human():
			most = maxf(most, charge.get(slot.index, 0.0))
	var lit := int(round(most * float(SEGMENTS)))
	for i: int in _segments.size():
		var on := i < lit
		var skin := _segments[i].material_override as StandardMaterial3D
		skin.albedo_color = READY_INK if on else WAITING_INK
		skin.emission_energy_multiplier = 1.4 if on else 0.0


## The tick over a kart that has readied up, kept over its head as it drives.
func _show_tick(slot: PlayerSlot) -> void:
	var done: bool = ready_slots.get(slot.index, false)
	if not done:
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


## The board at the back of the room, where the clock hangs in a room that has one. A waiting
## room has no clock and this is the one thing anybody in it wants to know.
func _build_board() -> void:
	var half := match_node.arena.world_size() * 0.5
	var at := Vector3(0.0, 0.0, -(half.y + BOARD_BACK))
	_board = Billboard.add_to(match_node.arena, at, Vector3.ZERO, match_node.arena.room)
	_board_words = _board.words("", Vector2(0.0, 0.1), BOARD_SIZE, READY_INK)


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
	var seat := InputHint.row(
		"%s to take a seat",
		[InputHint.glyph(InputActions.JOIN, Game.last_input_keyboard, HINT_INK, Type.LABEL)],
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
