class_name StyleStalls
extends Node3D
## Where a player dresses their kart, GAME.md 4.4 and 9.6: a pad on the floor for each of the four
## things a kart wears, its paint, its hat, its flag and its trail, with its picture on it. On one,
## the fire button puts the next of that thing on the kart, with its name over the kart, rather
## than a shot out of the cannon, so a player goes through them at their own pace and stops on the
## one they want. The pad lights in the color of whoever is on it, and until a player has changed
## something once, a hint over their kart names the button.
##
## The host decides, as it decides who is on the ready pad, GAME.md 10.3: it can see every kart,
## and says so with [signal Events.kart_dressed], which every machine answers. What a player
## picks is theirs to keep. A player at this machine has it written to their seat in the
## settings; a client keeps its own, and says it again when it is seated in the next room.

## The four, in [constant KartStyle.CHOICES] order, and what each is called in a hint.
const WORDS: Array[String] = ["PAINT", "HAT", "FLAG", "TRAIL"]
## How much of a pad its picture takes, and how many pixels the picture is drawn at.
const PICTURE := 0.62
const PICTURE_PIXELS := 256
## How big a pad is, in cells of the room's grid, and how far in from the cell edges it stops.
const CELLS := 2
const INSET := 0.15
const PAD_INK := Color(0.2, 0.21, 0.24)
const WORD_INK := Color(0.93, 0.93, 0.95)
## How the name of what was just put on is shown over the kart: its size and for how long.
const NAME_SIZE := 64
const NAME_TIME := 1.1
## How long the cannon is held for, in seconds, each tick a kart is on a pad: past the next tick.
const HOLD := 0.1

## The seats at this machine whose players have changed something at a pad since the game was
## started, and need telling no more.
static var learned: Dictionary[int, bool] = {}
## Every set of stalls in a room right now, kept as they come and go, for [method part_under]: the
## touch controls ask it every frame they draw the fire button.
static var _in_rooms: Array[StyleStalls] = []

var match_node: Match
## Whether this machine decides who is on a pad: the host, or a machine playing alone.
var deciding := true

## Each pad's floor, as a rectangle on the floor plane, and its slab, lit while somebody is on it.
var _areas: Array[Rect2] = []
var _slabs: Array[MeshInstance3D] = []
## Slot to the hint hanging over its kart, and what the hint was drawn for.
var _hints: Dictionary[int, Node3D] = {}
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
		if deciding and slot.input != null and slot.input.fire_pressed:
			_step(slot, pad)


## The next of [param part] on [param slot]'s kart that its owner may wear, everybody's or won in
## the loyalty program, GAME.md 8.9, said to every machine.
func _step(slot: PlayerSlot, part: int) -> void:
	var values := slot.style.to_array()
	values[part] = KartStyle.next(part, values[part], Loyalty.dress_of(slot))
	Events.kart_dressed.emit(slot.index, part, values)


## Somebody's kart has been dressed, here or on the host: it wears it, its name floats over it,
## and whoever it belongs to keeps it.
func _on_kart_dressed(index: int, part: int, values: PackedInt32Array) -> void:
	if index < 0 or index >= match_node.slots.size():
		return
	var slot := match_node.slots[index]
	StyleStalls.dress(slot, values)
	var kart := slot.kart
	if kart != null and part >= 0 and part < KartStyle.CHOICES.size():
		var named: String = KartStyle.CHOICES[part][values[part]]
		FloatingText.spawn(
			match_node, kart.global_position, named, slot.color(), NAME_SIZE, NAME_TIME
		)
	var player := _player_here(slot)
	if player != null and part >= 0:
		learned[player.seat] = true
		_hint(slot, -1)
	StyleStalls.keep(slot)


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


## Puts the hint up over [param slot]'s kart for [param pad], or takes it down for -1. It is only
## for a player at this machine who has not changed anything yet, and is drawn for whichever device
## they last touched.
func _hint(slot: PlayerSlot, pad: int) -> void:
	var player := _player_here(slot)
	var wanted := ""
	if pad >= 0 and player != null and not learned.has(player.seat):
		var keyboard := DeviceInput.uses_keyboard(player.device)
		var named := InputActions.short_binding_text(InputActions.FIRE, keyboard)
		if _on_touch(player):
			named = "touch"
		wanted = "%d|%s|%s|%d" % [pad, keyboard, named, _hint_size()]
	if wanted == _drawn.get(slot.index, ""):
		return
	_drawn[slot.index] = wanted
	var old: Node3D = _hints.get(slot.index)
	if old != null and is_instance_valid(old):
		# Out of the kart at once, so the one drawn for the next pad has the name to itself.
		if old.get_parent() != null:
			old.get_parent().remove_child(old)
		old.queue_free()
	_hints.erase(slot.index)
	if wanted.is_empty():
		return
	var kart := slot.kart
	# The drive and fire hint is where this one goes, and this one names the fire button too.
	var other := kart.get_node_or_null("ControlHint")
	if other != null:
		other.queue_free()
	var keyboard := DeviceInput.uses_keyboard(player.device)
	var size := _hint_size()
	var ink := ControlHint.INK
	# On a touch screen the button shows what it changes here, and so does the hint that names it.
	var button: Control = (
		DressArt.button(pad, ink, size)
		if _on_touch(player)
		else InputHint.glyph(InputActions.FIRE, keyboard, ink, size)
	)
	var parts: Array = [button]
	var words := "%%s change %s" % WORDS[pad].to_lower()
	# Where the drive and fire hint hangs, which it replaces, and as big.
	var row := InputHint.row(words, parts, ink, size)
	_hints[slot.index] = ScreenHint.hang(kart, row, "StallHint")


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
