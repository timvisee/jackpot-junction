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
## Each player charges their own arc of the ring, in their own color, so that a room with four
## people in it can see which of them the pad has taken and which of them it is waiting for.

## Everybody has been ready for [constant GO_DELAY]: the ring has gone green and the room is
## going. Not the moment the last player readies up, since the room says so before it goes.
signal everybody_ready
## Another block of the ring lit for a player at this screen as they charge, the [param step]th of
## [param of] in their arc. Heard as a soft tick climbing in pitch, see [method _on_charged].
signal charged(seat: int, step: int, of: int)
## Somebody has readied up and the room is still waiting on somebody else. Heard as the ready chime,
## at every machine, see [method _on_readied].
signal readied(seat: int)
## The ring has just gone green all the way round. Heard as the ready chime run up to its octave,
## see [method _on_filled]: the room filling is a bigger moment than one more player in it.
signal filled

## How long a kart has to hold the pad. Leaving it does not fade: the charge is gone and so is the
## ready, on the frame the kart rolls off.
const CHARGE_TIME := 2.5
## A full house turns the whole ring green and holds it, and the room goes a second after it
## filled. Green all the way round is the room saying everybody is in, for as long as that is
## true: somebody rolling off takes the green away with them. The glow carries the color over a
## darker body, since a block lit on both counts on the bright garage floor reads as mint.
const GREEN_GLOW := 1.2
const GREEN_BODY := 0.6
const GO_DELAY := 1.0
## How loud the charging ticks and the ready chime are, both well under the room's other sounds:
## they are for the player on the pad, not a fanfare for the room.
const CHARGE_VOLUME := -17.0
const READY_VOLUME := -9.0
## The run the ring going green is heard as: the chime at the root, the third, the fifth and the
## octave, a note every [constant GREEN_STEP] seconds, the last of them [constant GREEN_LIFT] dB
## over the rest.
const GREEN_RUN: Array[float] = [1.0, 1.26, 1.5, 2.0]
const GREEN_STEP := 0.09
const GREEN_LIFT := 3.0
## The ring that fills: how many blocks it is made of, how far out they sit as a share of the
## pad's radius, and how big each one is. Enough of them for a room of eight to have an arc of six
## each, GAME.md 9.3.
const SEGMENTS := 48
const RING_OUT := 1.14
const SEGMENT_SIZE := Vector2(0.16, 0.34)
## The most ticks a charge is heard in: an arc of more blocks than this lights some of them
## without one, so a player alone on the pad hears it fill no faster than before the ring had so
## many.
const HEARD_STEPS := 24
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
## The ink the joining lines under the count are written in.
const HINT_INK := Color(0.82, 0.83, 0.88)
## How far over the foot of the screen the ways in stand, and the room round the words of the
## ticket at the top, the same on every side.
const WAY_IN_ABOVE := 18.0
## The empty seat: how faint its stock is, and the room on its slanted end.
const SEAT_FILL := Color(HouseTheme.STOCK, 0.64)
const SEAT_INNER := HudBlock.SLANT + 14.0
const TICKET_ROOM := 13.0
## How big the Final Hand's tiny golden ticket beside the next match is drawn.
const TICKET := Vector2(54.0, 24.0)
## What the next match is said after, left to be read under the marker the rest is blacked out
## with at the Final Hand, and how long after the ticket the marker comes down.
const NEXT := "Next: "
const REDACT_AFTER := 0.35
## What the line under the count says once nobody else may sit down, GAME.md 9.6.
const FULL := "Maximum number of players reached"

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
## How many seats the arena has, and how many bots the host last asked for, -1 until it says: the
## bots that come in are as many of those as there are seats left over, see [method bots_joining].
var seats := SeatLimit.SEATS
var bots_asked := -1
## How many players may be in the room, 0 while that is not this machine's to know: once it is
## full, the line saying how to take a seat says there are none left, GAME.md 9.6.
var seat_limit := 0
## Where an online game is played, GAME.md 10.8, stamped beside how friends come in.
var stamp: NetStamp

var _segments: Array[MeshInstance3D] = []
## Seat to how many blocks of its arc were lit last frame, to hear each new one as it lights.
var _lit: Dictionary[int, int] = {}
var _ticks: Dictionary[int, Node3D] = {}
## Seconds the room has been full, or -1 while somebody is still to ready up. Somebody rolling off
## in the second before the room goes puts it back to -1: ready lasts as long as the standing does,
## and that is as true in the last second as in any other.
var _full_for := -1.0
var _board: ReadyStand
var _counter: Label
## The count's two halves as the ticket at the top of the screen sets them: the numbers in foil,
## and what they count in capitals beside them.
var _count_numbers: Label
var _count_words: Label
var _hints: VBoxContainer
## How to take a seat here, which is nothing to somebody only watching, GAME.md 10.3.
var _seat_hint: Control
var _full_hint: Label
## The perforation over the next match's line, and the tag the ways in stand on, put away while
## there is nothing on it.
var _plan_tear: Control
var _way_in: Control
## The empty seat the way to take one is shown on, in the corner a newcomer's block would take,
## its look, the number it says, and which corner it is in, -1 for none.
var _seat: PanelContainer
var _seat_look: StripStyle
var _seat_number: Label
var _seat_corner := -2
## Whether the way to sit down is put away for good, on a machine that is only watching.
var _no_seats_here := false
var _online_hint: Label
## What the next match is, as the host last said it, and beside it a tiny golden ticket while the
## seat at the Final Hand is taken, STORY.md 8.1.
var _plan: Label
var _ticket: Control
## The marker over what the next match is while the seat at the Final Hand is taken, see
## [method show_ticket].
var _plan_redacted: RedactionBar
## The match settings' key under the plan, at the machine that chooses the match, see [method
## offer_settings], and whether it was last drawn for the keyboard.
var _settings_key: Control
var _settings_drawn := -1
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
	room.charged.connect(room._on_charged)
	room.readied.connect(room._on_readied)
	room.filled.connect(room._on_filled)
	Events.match_planned.connect(room._on_match_planned)
	Events.room_planned.connect(room._on_room_planned)
	return room


## Somebody has readied up, or taken it back. On the host this is its own word coming back to it;
## on a client it is the first it has heard of it, and the only thing it has to go on.
func _on_player_ready(slot: int, ready: bool) -> void:
	if ready_slots.get(slot, false) == ready:
		return
	ready_slots[slot] = ready
	charge[slot] = 1.0 if ready else 0.0
	# Whoever fills the room is heard in the ring going green instead: the chime and the run on
	# top of each other would be neither.
	if ready and not (all_ready() and not held):
		readied.emit(slot)


func _on_readied(_seat: int) -> void:
	Audio.play_sfx(&"ready", READY_VOLUME, 0.02)


func _on_filled() -> void:
	for i: int in GREEN_RUN.size():
		var loud := READY_VOLUME + (GREEN_LIFT if i == GREEN_RUN.size() - 1 else 0.0)
		var note := Audio.play_sfx.bind(&"ready", loud, 0.0, GREEN_RUN[i])
		if i == 0:
			note.call()
		else:
			get_tree().create_timer(GREEN_STEP * i).timeout.connect(note)


## A step of a player's own charge, heard. Quiet, and climbing in pitch as the arc fills, so it
## reads as the pad filling up rather than as a clock ticking.
func _on_charged(_seat: int, step: int, of: int) -> void:
	var climb := float(step) / float(maxi(of, 1))
	Audio.play_sfx(&"ready_charge", CHARGE_VOLUME, 0.0, lerpf(0.85, 1.6, climb))


## How many of the players in the room have readied up, and how many there are to ready. Bots are
## not counted either way: nobody is waiting on them and they cannot drive onto a pad to say so.
func ready_count() -> int:
	var done := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human() and ready_slots.get(slot.index, false):
			done += 1
	return done


## How many bots will come into the arena with the players in the room: as many as the host asked
## for that there are seats left for, GAME.md 9.6. -1 while the host has not said, as an older
## one never does.
func bots_joining() -> int:
	if bots_asked < 0:
		return -1
	return clampi(bots_asked, 0, maxi(seats - player_count(), 0))


func _on_room_planned(bots: int, most: int) -> void:
	bots_asked = bots
	seat_limit = most
	seats = SeatLimit.seats_for(most)


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
	# Every machine charges the ring off the karts it can see, so the arcs fill on a client's
	# screen as they do on the host's. Only the host says who is ready, see 10.3: a client's arc
	# stops one block short of full until it is told, and its tick waits for the word too.
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
		# Said, and taken in from the saying like any other machine does, see
		# [method _on_player_ready]. Written down here first it was news to nobody, and the machine
		# that decided it was the one that never heard the chime.
		if deciding and (now >= 1.0) != already:
			Events.player_ready.emit(index, now >= 1.0)
		_show_tick(slot)
	_count_down(delta)
	_paint_ring()
	_say_the_count()
	_show_the_way_in()
	_show_the_settings_key()


## The second between the room filling and the room going. A client runs it as well, off what it
## has been told, so the ring goes green on every screen and not only on the host's; only the
## host's going is acted on, and a client follows when told to, see 10.3.
func _count_down(delta: float) -> void:
	if held or not all_ready():
		_full_for = -1.0
		return
	var was := _full_for
	_full_for = maxf(_full_for, 0.0) + (delta if was >= 0.0 else 0.0)
	if was < 0.0:
		filled.emit()
	if was < GO_DELAY and _full_for >= GO_DELAY:
		everybody_ready.emit()


## Whether the ring is green all the way round: the room is full and nothing is holding it.
func all_green() -> bool:
	return _full_for >= 0.0


## How many are ready, said twice: once at the top of the screen for the player at this machine,
## and once on a board in the room for everybody looking at it, and how many bots are coming in
## with them, so nobody expecting a match of two finds four karts on the grid. Both are rewritten
## only when the count changes -- a board refits its lettering to the words, which is not work for
## every frame of a room where nothing is happening.
func _say_the_count() -> void:
	var counted := "PLAYERS READY" + bot_words()
	var words := "%d / %d %s" % [ready_count(), player_count(), counted]
	if words == _said:
		return
	_said = words
	if _counter != null:
		_counter.text = words
		_count_numbers.text = "%d / %d" % [ready_count(), player_count()]
		_count_words.text = counted
	if _board != null:
		_board.say("%d / %d" % [ready_count(), player_count()], counted)


## The way in, or that there is none left: once as many are playing as may, the line saying how
## to take a seat gives way to one saying the room is full, and once this machine has as many as
## one may, GAME.md 9.6, to one saying so.
func _show_the_way_in() -> void:
	if _no_seats_here or _seat_hint == null:
		return
	var full := seat_limit > 0 and player_count() >= seat_limit
	var here := not full and SeatLimit.full_here(match_node, Net.session)
	_seat_hint.visible = not full and not here
	_full_hint.visible = full or here
	_full_hint.text = SeatLimit.HERE_FULL.trim_suffix(".") if here else FULL
	_place_the_seat()
	_fit_the_way_in()


## The empty seat in the corner the next player at this screen would take, GAME.md 9.6: cut as a
## corner block is, off the edge, but faint and empty, so it says where a newcomer will be as well
## as how to get there. None with every corner taken.
func _place_the_seat() -> void:
	if _seat == null:
		return
	var hud := match_node.hud if match_node != null else null
	var corner := hud.next_corner() if hud != null else 0
	_seat_number.text = "SEAT %d" % (player_count() + 1)
	if corner == _seat_corner:
		return
	_seat_corner = corner
	if corner < 0:
		return
	var right := corner % 2 == 1
	var bottom := corner >= 2
	_seat_look.off_right = right
	_seat_look.wide_at_bottom = bottom
	_seat_look.content_margin_left = SEAT_INNER if right else HudBlock.OUTER
	_seat_look.content_margin_right = HudBlock.OUTER if right else SEAT_INNER
	_seat.set_anchors_and_offsets_preset(MatchHud.BLOCK_ANCHORS[corner])
	_seat.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
	_seat.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	var line_up := HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	_seat_number.horizontal_alignment = line_up
	_seat_hint.alignment = BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN


## The tag at the foot of the screen, up while anything is on it, and the empty seat while there
## is a seat to take and a corner to take it in.
func _fit_the_way_in() -> void:
	if _way_in == null:
		return
	var online := _online_hint.visible and not _online_hint.text.is_empty()
	_way_in.visible = _full_hint.visible or online or stamp.visible
	if _seat != null:
		_seat.visible = _seat_hint.visible and _seat_corner >= 0


## The bots coming in, as the count says them after the players: " + 2 BOTS", or nothing when
## none are, or while the host has not said.
func bot_words() -> String:
	var bots := bots_joining()
	if bots <= 0:
		return ""
	return " + %d BOT%s" % [bots, "" if bots == 1 else "S"]


## A tiny golden ticket beside the next match while the seat at the Final Hand is taken, STORY.md
## 8.1: a drawing of one, see [method GoldenTicket.draw_icon], the ticket itself being far too small
## to read up there. What the match is, the House's choice, is blacked out as its settings are.
func show_ticket() -> void:
	if _plan == null or _ticket != null:
		return
	var row := _plan.get_parent()
	_ticket = Control.new()
	_ticket.name = "Ticket"
	_ticket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticket.custom_minimum_size = TICKET
	_ticket.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ticket.draw.connect(
		func() -> void: GoldenTicket.draw_icon(_ticket, Rect2(Vector2.ZERO, _ticket.size))
	)
	row.add_child(_ticket)
	row.move_child(_ticket, 0)
	_plan_redacted = RedactionBar.over(_plan, REDACT_AFTER)
	_redact_plan()


## The marker over the plan without the ticket, at every screen but the one the House dealt the
## Final Hand at, which has it with the ticket, see [method show_ticket]; or taken off again.
func black_out_the_plan(on: bool) -> void:
	if _ticket != null:
		return
	if on and _plan_redacted == null and _plan != null:
		_plan_redacted = RedactionBar.over(_plan, REDACT_AFTER)
	elif not on and _plan_redacted != null:
		_plan_redacted.queue_free()
		_plan_redacted = null
	_redact_plan()


## The marker over all of the plan but [constant NEXT], or put away while it says something else.
func _redact_plan() -> void:
	if _plan_redacted == null:
		return
	_plan_redacted.visible = _plan.visible and _plan.text.begins_with(NEXT)
	var font := _plan.get_theme_font(&"font")
	var points := _plan.get_theme_font_size(&"font_size")
	var said := font.get_string_size(NEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, points).x
	_plan_redacted.offset_left = said - RedactionBar.OVER.x


## The match settings' key, E or a pad's View, drawn in front of the plan on the board at the
## machine that chooses the match, GAME.md 9.6, "[E] Next: ...": the room's own way to them,
## besides its pause menu's. A touch screen has a button beside its menu button for them instead,
## see [TouchSettings].
func offer_settings() -> void:
	_settings_drawn = -1
	if _plan == null or _settings_key != null or TouchInput.enabled:
		return
	_settings_key = HBoxContainer.new()
	_settings_key.name = "SettingsKey"
	_settings_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := _plan.get_parent()
	row.add_child(_settings_key)
	row.move_child(_settings_key, _plan.get_index())


## The key drawn for the keyboard or a pad, whichever was last in hand, and up with the plan.
func _show_the_settings_key() -> void:
	if _settings_key == null:
		return
	_settings_key.visible = _plan.visible
	var keyboard := int(Game.last_input_keyboard)
	if keyboard == _settings_drawn:
		return
	_settings_drawn = keyboard
	for child: Node in _settings_key.get_children():
		child.queue_free()
	var key := InputHint.glyph(InputActions.MATCH_SETTINGS, keyboard == 1, HINT_INK, Type.LABEL)
	if key != null:
		_settings_key.add_child(key)


## The host has said what the next match is, or that they are still choosing. Either way it goes
## under the count, because what is about to be played is the other thing a room of people
## waiting to play it wants to know.
func _on_match_planned(summary: String, choosing: bool, by_the_house := false) -> void:
	held = choosing
	black_out_the_plan(by_the_house)
	var who := "The host is" if Net.online() else "Still"
	_plan.text = "%s choosing the match" % who if choosing else NEXT + summary
	_plan.visible = true
	_plan_tear.visible = true
	_redact_plan()


## What to say about getting more people into the room: how somebody at this machine takes a
## seat, and, when there is a host to join, how somebody at another machine does.
##
## The room is the place both of those questions get asked, so it is the place they are answered.
## Anywhere else and a player has to leave the room to find out how to let their friend in.
## The line that says how to take a seat, put away for a machine that is only watching, where
## there is no seat to take, GAME.md 10.3.
func hide_how_to_sit_down() -> void:
	_no_seats_here = true
	if _seat_hint != null:
		_seat_hint.visible = false
	if _full_hint != null:
		_full_hint.visible = false
	_fit_the_way_in()


## Stamps where the game [param config] plays is played, GAME.md 10.8, or nothing on this machine.
func stamp_network(config: MatchConfig) -> void:
	stamp.show_for(config)
	_fit_the_way_in()


func say_how_to_join(online: String) -> void:
	_online_hint.text = online
	_online_hint.visible = not online.is_empty()
	_fit_the_way_in()


## Which players are standing on the pad this frame.
func _karts_on_the_pad() -> Dictionary[int, bool]:
	var standing: Dictionary[int, bool] = {}
	for body: Node3D in pad.get_overlapping_bodies():
		var kart := body as Kart
		if kart != null and kart.alive and kart.rules == match_node.rules:
			standing[kart.slot] = true
	return standing


## The ring, split between whoever is in the room: an arc each, in their own color, filling as
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
		var index := seats[s].index
		var ready: bool = ready_slots.get(index, false)
		var shown: float = 1.0 if ready else charge.get(index, 0.0)
		var full := int(round(shown * float(span)))
		if not ready:
			full = mini(full, span - 1)
		for k: int in span:
			if from + k < inks.size() and k < full:
				inks[from + k] = seats[s].color()
		# A block more than last frame, for a player at this screen, is a step of their own
		# charge: the player on the pad hears it filling. Anybody else's is seen, not heard.
		var steps := mini(span, HEARD_STEPS)
		var heard := full * steps / span
		var was: int = _lit.get(index, 0) * steps / span
		if seats[s].is_local_human() and heard > was and not ready:
			charged.emit(index, heard, steps)
		_lit[index] = full
	var green := all_green()
	for i: int in _segments.size():
		var skin := _segments[i].material_override as StandardMaterial3D
		var on := inks[i] != WAITING_INK
		skin.albedo_color = READY_INK.darkened(GREEN_BODY) if green else inks[i]
		skin.emission = READY_INK if green else inks[i]
		skin.emission_energy_multiplier = GREEN_GLOW if green else (1.4 if on else 0.0)


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


## The sign on top of the back wall, over the middle of it. A room that has a clock hangs it on a
## hoarding over the crowd; there is no crowd in here and the camera is holding the whole room,
## so the count stands on the wall instead, inside the shot and off the karts' floor.
func _build_board() -> void:
	var layout := match_node.arena.layout
	var half := match_node.arena.world_size() * 0.5
	var at := Vector3(0.0, layout.wall_height, -(half.y - layout.cell_size * 0.5))
	_board = ReadyStand.add_to(match_node.arena, at, Vector3.ZERO, match_node.arena.room)


## And the same count at the top of the screen, for the player who is looking at their own kart
## rather than at the room: on a ticket hung from the top edge as the clock board is in a match,
## GAME.md 8.1a, the count in foil figures with what it counts in capitals beside it, and the next
## match under a perforation. How to take a seat goes on a tag of its own under the ticket.
func _build_counter() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ReadyCount"
	layer.layer = 12
	match_node.add_child(layer)
	_hints = VBoxContainer.new()
	_hints.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_hints.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hints.alignment = BoxContainer.ALIGNMENT_CENTER
	_hints.add_theme_constant_override("separation", 8)
	layer.add_child(_hints)
	var ticket := PanelContainer.new()
	ticket.name = "Ticket"
	ticket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ticket.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Hung from the top edge, square where it meets it and notched at its foot, and short, so it
	# stays over the count's sign on the back wall rather than in front of it: the same small room
	# on every side, which is what keeps the perforation's gap even, see [Perforation].
	var look := TicketStyle.cut(Color(HouseTheme.STOCK, 0.9), 9.0, TICKET_ROOM, TICKET_ROOM)
	look.notch_top = false
	look.bite = 6.0
	look.frame = Color(HouseTheme.FOIL, 0.32)
	look.frame_body = Color(HouseTheme.FOIL, 0.14)
	look.frame_inset = 5.0
	look.shadow = 8.0
	Surface.wear(look, "pane")
	ticket.add_theme_stylebox_override("panel", look)
	_hints.add_child(ticket)
	var inside := VBoxContainer.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_theme_constant_override("separation", 2)
	ticket.add_child(inside)
	var count := HBoxContainer.new()
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.alignment = BoxContainer.ALIGNMENT_CENTER
	count.add_theme_constant_override("separation", 12)
	inside.add_child(count)
	_count_numbers = Label.new()
	_count_numbers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(_count_numbers, Type.numbers_font(), Type.LARGE)
	_count_numbers.add_theme_color_override("font_color", HouseTheme.FOIL)
	_count_numbers.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.add_child(_count_numbers)
	_count_words = Label.new()
	_count_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.strong(_count_words, Type.LABEL, HouseTheme.WORDS)
	_count_words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.add_child(_count_words)
	# The whole line as one, still kept for what reads it, put away: the ticket says it in two.
	_counter = Label.new()
	_counter.visible = false
	inside.add_child(_counter)
	_plan_tear = MenuTheme.perforation()
	_plan_tear.visible = false
	inside.add_child(_plan_tear)
	var plan_row := HBoxContainer.new()
	plan_row.name = "PlanRow"
	plan_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plan_row.alignment = BoxContainer.ALIGNMENT_CENTER
	plan_row.add_theme_constant_override("separation", 10)
	inside.add_child(plan_row)
	_plan = Label.new()
	_plan.name = "Plan"
	_plan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plan.visible = false
	Type.text(_plan, Type.LABEL, HouseTheme.QUIET)
	plan_row.add_child(_plan)
	# The ways in at the foot of the screen, on a tag of their own, gone while it has nothing on it.
	var tag := PanelContainer.new()
	tag.name = "WayIn"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_stylebox_override("panel", HudBlock.scrim())
	tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tag.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tag.offset_bottom = -WAY_IN_ABOVE
	tag.visible = false
	layer.add_child(tag)
	var ways_in := VBoxContainer.new()
	ways_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ways_in.add_theme_constant_override("separation", 4)
	tag.add_child(ways_in)
	_way_in = tag
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
	_build_the_seat(layer)
	_seat.get_child(0).add_child(seat)
	_seat_hint = seat
	_full_hint = Label.new()
	_full_hint.text = FULL
	_full_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_full_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_hint.visible = false
	Type.text(_full_hint, Type.LABEL, HINT_INK)
	ways_in.add_child(_full_hint)
	# Where an online game is played, stamped beside how friends come in, GAME.md 10.8.
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 12)
	ways_in.add_child(line)
	stamp = NetStamp.new()
	stamp.visible = false
	line.add_child(stamp)
	_online_hint = Label.new()
	_online_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_online_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_online_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_online_hint.visible = false
	Type.text(_online_hint, Type.LABEL, HINT_INK)
	line.add_child(_online_hint)
	_fit_the_way_in()


## The empty seat, built in the top left corner and moved to the corner a newcomer would take, see
## [method _place_the_seat]: a corner block's strip, faint, with the seat's number over the way to
## take it.
func _build_the_seat(layer: CanvasLayer) -> void:
	_seat = PanelContainer.new()
	_seat.name = "EmptySeat"
	_seat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seat.custom_minimum_size = Vector2(MatchHud.BLOCK_WIDTH, 0.0)
	_seat_look = StripStyle.cut(false, HudBlock.SLANT, HudBlock.OUTER, SEAT_INNER, 14.0)
	_seat_look.fill = SEAT_FILL
	_seat_look.edge_top = Color(HouseTheme.FOIL, 0.3)
	_seat_look.edge_bottom = Color(HouseTheme.FOIL, 0.3)
	_seat.add_theme_stylebox_override("panel", _seat_look)
	_seat.visible = false
	layer.add_child(_seat)
	var lines := VBoxContainer.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_theme_constant_override("separation", 6)
	_seat.add_child(lines)
	_seat_number = Label.new()
	_seat_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seat_number.add_theme_font_override("font", Type.micro_font())
	_seat_number.add_theme_font_size_override("font_size", Type.LABEL)
	_seat_number.add_theme_color_override("font_color", Color(HouseTheme.FOIL, 0.75))
	lines.add_child(_seat_number)
