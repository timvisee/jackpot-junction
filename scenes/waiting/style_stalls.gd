class_name StyleStalls
extends Node3D
## Where a player dresses their kart, GAME.md 4.4 and 9.6: a pad on the floor for each of the four
## things a kart wears, its paint, its hat, its flag and its trail, with its picture on it. On one,
## the fire button puts the next of that thing on the kart rather than a shot out of the cannon, so
## a player goes through them at their own pace and stops on the one they want. The pad lights in
## the color of whoever is on it, and a card over their kart says what it wears there, large, and
## under it, smaller, the button and what it puts on next: one card that changes as they go
## through, rather than names rising over the kart that ran into each other pressed quickly.
##
## The host decides, as it decides who is on the ready pad, GAME.md 10.3: it can see every kart,
## and says so with [signal Events.kart_dressed], which every machine answers. What a player
## picks is theirs to keep. A player at this machine has it written to their seat in the
## settings; a client keeps its own, and says it again when it is seated in the next room.

## The parts, in [constant KartStyle.CHOICES] order, and the card back last, and what each is
## called. The plate, the tire marks and the card back are the loyalty program's, GAME.md
## 8.9: until one of a kind is won, its pad has only the plain one.
const WORDS: Array[String] = ["PAINT", "HAT", "FLAG", "TRAIL", "PLATE", "TIRE MARKS", "CARD BACK"]
## The card back's pad: this machine's own, never the host's to step, since it dresses the cards
## this machine draws rather than a kart.
const CARD_BACK := 6
## How much of a pad its picture takes, and how many pixels the picture is drawn at.
const PICTURE := 0.62
const PICTURE_PIXELS := 256
## How big a pad is, in cells of the room's grid, and how far in from the cell edges it stops.
const CELLS := 2
const INSET := 0.15
const PAD_INK := Color(0.2, 0.21, 0.24)
const WORD_INK := Color(0.93, 0.93, 0.95)
## How much larger than the line under it the name of what a kart wears is set on its card, and
## how far the card swells for a moment when it changes, and for how long, so a press is seen.
const NAME_SCALE := 1.5
const POP := 1.12
const POP_TIME := 0.14
## What the card says under the name on a pad with nothing else to put on yet, and what it calls
## a part's choice of nothing, which the choices call None.
const ONLY_ONE := "The only one so far"
const NOTHING: Array[String] = ["", "No hat", "No flag", "No trail", "Plain plate", ""]
## How long the cannon is held for, in seconds, each tick a kart is on a pad: past the next tick.
const HOLD := 0.1

## Every set of stalls in a room right now, kept as they come and go, for [method part_under]: the
## touch controls ask it every frame they draw the fire button.
static var _in_rooms: Array[StyleStalls] = []

var match_node: Match
## Whether this machine decides who is on a pad: the host, or a machine playing alone.
var deciding := true

## Each pad's floor, as a rectangle on the floor plane, and its slab, lit while somebody is on it.
var _areas: Array[Rect2] = []
var _slabs: Array[MeshInstance3D] = []
## Slot to the card hanging over its kart, and what the card was drawn for.
var _hints: Dictionary[int, ScreenHint] = {}
var _drawn: Dictionary[int, String] = {}


## One of the four drawn for a pad to wear, in the pad's light ink, see [method DressArt.draw_into].
class Picture:
	extends Control

	var part := 0

	func _draw() -> void:
		DressArt.draw_into(self, Rect2(Vector2.ZERO, size), part, WORD_INK)


## Four pads in [param in_match]'s room, the first of them with its top left corner in [param
## first], the next ones along to the right with a cell between each.
static func add_to(in_match: Match, first: Vector2i) -> StyleStalls:
	var stalls := StyleStalls.new()
	stalls.name = "StyleStalls"
	stalls.match_node = in_match
	stalls.deciding = not in_match.puppet
	in_match.arena.add_child(stalls)
	for i: int in WORDS.size():
		stalls._build(i, first + Vector2i(i * (CELLS + 1), 0))
	Events.kart_dressed.connect(stalls._on_kart_dressed)
	return stalls


func _enter_tree() -> void:
	_in_rooms.append(self)


func _exit_tree() -> void:
	_in_rooms.erase(self)
	if Events.kart_dressed.is_connected(_on_kart_dressed):
		Events.kart_dressed.disconnect(_on_kart_dressed)


## Which of the four [param kart] is standing on in [param match_node]'s room, or -1: there are no
## stalls anywhere but the lobby and the Garage, and a kart that is down is standing on nothing.
static func part_under(match_node: Match, kart: Kart) -> int:
	if match_node == null or match_node.arena == null or kart == null or not kart.alive:
		return -1
	for stalls: StyleStalls in _in_rooms:
		if stalls.match_node == match_node:
			return stalls.pad_under(kart)
	return -1


## The pad [param kart] is standing on, or -1.
func pad_under(kart: Kart) -> int:
	var at := Vector2(kart.global_position.x, kart.global_position.z)
	for i: int in _areas.size():
		if _areas[i].has_point(at):
			return i
	return -1


func _physics_process(_delta: float) -> void:
	for i: int in _slabs.size():
		(_slabs[i].material_override as StandardMaterial3D).emission_energy_multiplier = 0.0
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		var pad := -1
		if kart != null and kart.alive and slot.is_human():
			pad = pad_under(kart)
		_hint(slot, pad)
		if pad < 0:
			continue
		var skin := _slabs[pad].material_override as StandardMaterial3D
		skin.emission = slot.color()
		skin.emission_energy_multiplier = 0.9
		# The trigger is the pad's while the kart is on it, on every machine, a client's own kart
		# included: nothing comes out of the cannon, and it makes no sound of trying.
		kart.cannon.cooldown_left = maxf(kart.cannon.cooldown_left, HOLD)
		if pad == CARD_BACK:
			var player := _player_here(slot)
			if player != null and player.fire_pressed:
				_turn_back()
				# A card back is the last part of the dress, GAME.md 8.10, earned as it is turned.
				Achievements.arrive(Game.settings.profile, slot.index)
		elif deciding and slot.input != null and slot.input.fire_pressed:
			_step(slot, pad)


## The next of [param part] on [param slot]'s kart that its owner may wear, everybody's or won in
## the loyalty program, GAME.md 8.9, said to every machine.
func _step(slot: PlayerSlot, part: int) -> void:
	var stepped := slot.style.duplicate_style()
	var values := stepped.to_array()
	values[part] = KartStyle.next(part, values[part], Loyalty.dress_of(slot))
	stepped = KartStyle.from_array(values)
	stepped.finishes = slot.style.finishes.duplicate()
	# The piece in the finish its owner has moved it up to, GAME.md 8.9.
	var piece := KartStyle.won_name(part, values[part])
	stepped.finishes[part] = Loyalty.finish_for(slot, piece) if values[part] > 0 else 0
	values = stepped.to_array()
	Events.kart_dressed.emit(slot.index, part, values)


## The next card back the profile playing has won, GAME.md 8.9, on the card back's pad: the cards
## this machine draws wear it, and the card over the kart says so.
func _turn_back() -> void:
	var profile := Game.settings.profile
	profile.loyalty.card_back = next_back(profile)
	Game.settings.save_to_disk()


## Somebody's kart has been dressed, here or on the host: it wears it, and whoever it belongs to
## keeps it. The card over it says so on the next step.
func _on_kart_dressed(index: int, _part: int, values: PackedInt32Array) -> void:
	if index < 0 or index >= match_node.slots.size():
		return
	var slot := match_node.slots[index]
	StyleStalls.dress(slot, values)
	StyleStalls.keep(slot)


## The card back after the one [param profile] has, among those it has won, GAME.md 8.9.
static func next_back(profile: Profile) -> int:
	var dress: PackedStringArray = Loyalty.unlocks_of(profile)["dress"]
	var back := profile.loyalty.card_back
	for i: int in CardBack.STYLES.size():
		back = (back + 1) % CardBack.STYLES.size()
		if back == 0 or "card_back:%s" % CardBack.STYLES[back] in dress:
			break
	return back


## Puts [param values] on [param slot] and on its kart, if it has one and it is not already
## wearing them.
static func dress(slot: PlayerSlot, values: PackedInt32Array) -> void:
	var style := KartStyle.from_array(values)
	slot.style = style
	var kart := slot.kart
	if kart == null or kart.style.to_array() == style.to_array():
		if kart != null:
			kart.style = style
		return
	var was := kart.style
	kart.style = style
	KartVisuals.redress(kart, was)


## Writes [param slot]'s dress down for whoever at this machine it belongs to: a player here in
## their seat of the settings, and this machine's own player online in the session as well, which
## is what it says when it is seated in the next room.
static func keep(slot: PlayerSlot) -> void:
	var settings := Game.settings
	var player := slot.input as PlayerInput
	var seat := -1
	if player != null and player.seat >= 0:
		seat = player.seat
	var session := Net.session if Net.online() else null
	var mine := session.seat_at(slot.index) if session != null and not session.is_host else null
	if mine != null:
		# Said again as this player is seated in the next room, GAME.md 10.3.
		mine.style = slot.style.to_array()
		if slot.index == session.local_slot:
			session.player_style = mine.style
		seat = mine.seat
	elif session != null and not session.is_host and session.local_slot == slot.index:
		session.player_style = slot.style.to_array()
		seat = 0
	if seat < 0 or seat >= settings.kart_styles.size():
		return
	settings.set_seat_style(seat, slot.style.to_array())
	settings.save_to_disk()


## The player at this machine who drives [param slot], or null: the one in the seat here, or on a
## client the one this machine is.
func _player_here(slot: PlayerSlot) -> PlayerInput:
	if match_node.puppet:
		if match_node.local_seats.has(slot.index):
			return match_node.local_seats[slot.index]
		return match_node.local_input if slot.index == match_node.local_slot else null
	return slot.input as PlayerInput


## Puts the card up over [param slot]'s kart for [param pad], or takes it down for -1, see the
## class description: what the kart wears there, and for a player at this machine the button and
## what it puts on next, drawn for whichever device they last touched. Drawn again only when what
## it says changes, in place, swelling for a moment so a press is seen.
func _hint(slot: PlayerSlot, pad: int) -> void:
	var player := _player_here(slot)
	var kart := slot.kart
	var says := PackedStringArray() if pad < 0 or kart == null else worn_and_next(slot, pad, player)
	var wanted := ""
	if not says.is_empty():
		var keyboard := player != null and DeviceInput.uses_keyboard(player.device)
		var touch := player != null and _on_touch(player)
		wanted = "%d|%s|%s|%s|%s|%d" % [pad, says[0], says[1], keyboard, touch, _hint_size()]
	if wanted == _drawn.get(slot.index, ""):
		return
	_drawn[slot.index] = wanted
	var old: ScreenHint = _hints.get(slot.index)
	if old != null and not is_instance_valid(old):
		old = null
	if wanted.is_empty():
		if old != null:
			# Out of the kart at once, so the one drawn for the next pad has the place to itself.
			if old.get_parent() != null:
				old.get_parent().remove_child(old)
			old.queue_free()
		_hints.erase(slot.index)
		return
	# The drive and fire hint is where this one goes, and this one names the fire button too.
	var other := kart.get_node_or_null("ControlHint")
	if other != null:
		other.queue_free()
	var card := _card(slot, pad, says, player)
	if old != null and old.get_parent() == kart:
		old.replace(card)
		old.scale = Vector3.ONE * POP
		old.create_tween().tween_property(old, "scale", Vector3.ONE, POP_TIME).set_ease(
			Tween.EASE_OUT
		)
		return
	if old != null:
		old.queue_free()
	_hints[slot.index] = ScreenHint.hang(kart, card, "StallHint")


## What [param slot]'s kart wears at [param pad], by name, and what the fire button puts on next
## there for [param player], the player at this machine who drives it, or nothing for a kart driven
## from elsewhere, nor where there is nothing else to put on. The card back is this machine's own,
## so only its own player's kart says anything on its pad.
static func worn_and_next(slot: PlayerSlot, pad: int, player: PlayerInput) -> PackedStringArray:
	if pad == CARD_BACK:
		if player == null:
			return PackedStringArray()
		var profile := Game.settings.profile
		var back := profile.loyalty.card_back
		var after := next_back(profile)
		return PackedStringArray(
			[CardBack.STYLES[back], CardBack.STYLES[after] if after != back else ""]
		)
	var values := slot.style.to_array()
	var wearing := choice_name(pad, values[pad])
	if player == null:
		return PackedStringArray([wearing, ""])
	var dress := Loyalty.dress_of(slot)
	if dress.is_empty() and not slot.input is PlayerInput:
		# A client's own kart: its unlocks are this machine's profile's, not the host's to tell.
		dress = Loyalty.unlocks_of(Game.settings.profile)["dress"]
	var after := KartStyle.next(pad, values[pad], dress)
	return PackedStringArray([wearing, choice_name(pad, after) if after != values[pad] else ""])


## Choice [param index] of [param part] as the card says it: by its name, or for none, no hat.
static func choice_name(part: int, index: int) -> String:
	var named: String = KartStyle.CHOICES[part][index]
	return NOTHING[part] if named == "None" and not NOTHING[part].is_empty() else named


## The card's words: [param says] from [method worn_and_next], the name large in [param slot]'s
## color, and under it the button, the stall's own on a touch screen, and what it puts on next, or
## that there is nothing else yet; for a kart driven from elsewhere, the name alone.
func _card(slot: PlayerSlot, pad: int, says: PackedStringArray, player: PlayerInput) -> Control:
	var size := _hint_size()
	var ink := ControlHint.INK
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	var name_line := Label.new()
	name_line.text = says[0]
	name_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.strong(name_line, roundi(size * NAME_SCALE), slot.color().lightened(0.15))
	column.add_child(name_line)
	if player == null:
		return column
	if says[1].is_empty():
		# Nothing else to put on here yet: no button to press, and said so.
		var only := Label.new()
		only.text = ONLY_ONE
		only.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Type.text(only, size, Color(ink, 0.7))
		column.add_child(only)
		return column
	var keyboard := DeviceInput.uses_keyboard(player.device)
	# On a touch screen the button shows what it changes here, and so does the line naming it.
	var button: Control = (
		DressArt.button(pad, ink, size)
		if _on_touch(player)
		else InputHint.glyph(InputActions.FIRE, keyboard, ink, size)
	)
	var row := InputHint.row("%%s next: %s" % says[1], [button], ink, size)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	return column


## Whether [param player] plays on the touch screen, whose fire button is on the screen.
static func _on_touch(player: PlayerInput) -> bool:
	return TouchInput.enabled and player.device == DeviceInput.ANY


func _hint_size() -> int:
	return ScreenHint.drawn_size(get_tree())


func _build(index: int, corner: Vector2i) -> void:
	var grid := match_node.arena.grid
	var near := grid.cell_center(corner)
	var far := grid.cell_center(corner + Vector2i(CELLS - 1, CELLS - 1))
	var middle := (near + far) * 0.5
	var side := grid.cell_size * CELLS - INSET * 2.0
	_areas.append(Rect2(middle.x - side * 0.5, middle.z - side * 0.5, side, side))
	var slab := MeshInstance3D.new()
	slab.name = "Stall%d" % index
	var mesh := BoxMesh.new()
	mesh.size = Vector3(side, 0.04, side)
	slab.mesh = mesh
	var skin := StandardMaterial3D.new()
	skin.albedo_color = PAD_INK
	skin.roughness = 0.8
	skin.emission_enabled = true
	skin.emission_energy_multiplier = 0.0
	slab.material_override = skin
	slab.position = Vector3(middle.x, 0.02, middle.z)
	add_child(slab)
	_slabs.append(slab)
	# The picture of what it changes lies on the pad, the roller, the hat, the flag or the trail the
	# touch screen's button shows there, its top away from the camera, which is the way up it reads.
	# A word had to be read, in a language, from a moving kart.
	var drawing := Picture.new()
	drawing.part = index
	var picture := DrawnTexture.face(
		Vector2.ONE * side * PICTURE,
		DrawnTexture.decal(DrawnTexture.of(self, drawing, Vector2i.ONE * PICTURE_PIXELS))
	)
	picture.name = "Picture%d" % index
	picture.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	picture.position = Vector3(middle.x, 0.05, middle.z)
	add_child(picture)
