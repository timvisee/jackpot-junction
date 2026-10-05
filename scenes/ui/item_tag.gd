class_name ItemTag
extends Control
## The item a player on this screen has just picked up, shown beside their kart, GAME.md 8.3: a
## small picture that turns through the items the way the roulette in their corner does while the
## box is opening, settles on the one they got, and fades slowly, since the corner keeps saying
## what they hold. Once it can be used, the button that uses it sits on the chip's corner, drawn
## for the keys or the pad the player is on. Used, it goes at once. The eyes are on the kart when
## it drives through a box, not on the corner of the screen.
##
## And again while a player holding one drives up to another box: a box they cannot take, since
## the slot is full, which they drove straight through wondering why. The item they hold comes up
## beside the kart the nearer they get, and goes again as they leave the box behind. One taken
## with another box already underneath the kart just stays up until they drive away from it.

## How big the picture is, the chip it sits on, the kart's top right corner that the chip's lower
## left one sits on, in meters up and to the right as the camera sees it, how long it stays once
## settled and how long it takes to fade.
const ICON := 30.0
const PAD := 5.0
const CORNER := Vector2(0.7, 1.0)
const HOLD := 0.8
const FADE := 1.2
## How long after the pickup a kart holding nothing still has its tag waiting for the item: on a
## client the word of the pickup can come a tick ahead of the snapshot that puts it in the kart.
const GRACE := 0.4
## How near another box the item held comes up, in meters, from nothing at the first to all of it
## at the second, and how fast it comes and goes, a share a second.
const FAR := 6.0
const NEAR := 2.0
const EASE := 2.5
const CHIP := Color(HouseTheme.STOCK, 0.82)
## The foil rim round the chip, GAME.md 8.1a, the way a key cap's is.
const RIM := Color(HouseTheme.FOIL, 0.7)
## The button that uses the item, on the chip's lower corner: its size and ink.
const BUTTON_SIZE := 13
const BUTTON_INK := Color(0.92, 0.92, 0.95)

var match_node: Match

## Slot to its tag: how long since the pickup, and how long the item has been settled.
var _tags: Dictionary[int, Dictionary] = {}
## Where the boxes on the floor are, found once a frame for every player here, and the frame.
var _boxes: Array[Vector3] = []
var _boxes_frame := -1


static func add_to(hud: MatchHud) -> ItemTag:
	var tag := ItemTag.new()
	tag.name = "ItemTag"
	tag.match_node = hud.match_node
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Under the corners and the standings, like everything else hung on a kart.
	tag.z_index = -1
	# After the camera has moved for the frame, so the tag is put where the kart is drawn now
	# rather than where the camera saw it a frame ago.
	tag.process_priority = 100
	hud.add_child(tag)
	return tag


func _ready() -> void:
	Events.item_picked.connect(_on_picked)
	Events.item_used.connect(_on_used)


func _exit_tree() -> void:
	Events.item_picked.disconnect(_on_picked)
	Events.item_used.disconnect(_on_used)


func _on_picked(slot: int, _item: StringName) -> void:
	if slot < match_node.slots.size() and match_node.slots[slot].is_local_human():
		# A fresh pickup takes over from whatever was up, button and all.
		_drop(slot)
		_tags[slot] = {"age": 0.0, "settled": 0.0}


func _on_used(slot: int, _item: StringName) -> void:
	_drop(slot)


## Takes [param slot]'s tag down, button and all.
func _drop(slot: int) -> void:
	if not _tags.has(slot):
		return
	var button: Control = _tags[slot].get("button")
	if button != null:
		button.queue_free()
	_tags.erase(slot)


func _process(delta: float) -> void:
	for slot: int in _tags.keys():
		var tag := _tags[slot]
		tag["age"] += delta
		var kart := match_node.slots[slot].kart if slot < match_node.slots.size() else null
		if kart == null or (kart.held_item == null and tag["age"] > GRACE):
			_drop(slot)
			continue
		if tag.has("near"):
			var wanted := _nearness(kart) if kart.held_item != null else 0.0
			tag["near"] = move_toward(float(tag["near"]), wanted, EASE * delta)
			if tag["near"] <= 0.0 and wanted <= 0.0:
				_drop(slot)
				continue
		elif kart.held_item != null and kart.item_reveal_left <= 0.0:
			if _nearness(kart) > 0.0:
				# Taken with another box underneath, as off a pad that puts its next one straight
				# out: it stays up for that box as it is, rather than fading and coming back.
				tag["near"] = _fade(tag)
			else:
				tag["settled"] += delta
				if tag["settled"] >= HOLD + FADE:
					_drop(slot)
					continue
		_place_button(slot, kart)
	_remind()
	queue_redraw()


## The item held, brought up for a player on this screen who is nearing a box they cannot take.
func _remind() -> void:
	for slot: PlayerSlot in match_node.slots:
		if _tags.has(slot.index) or not slot.is_local_human() or slot.kart == null:
			continue
		var kart := slot.kart
		if kart.held_item == null or kart.item_reveal_left > 0.0 or _nearness(kart) <= 0.0:
			continue
		_tags[slot.index] = {"age": GRACE, "settled": 0.0, "near": 0.0}


## How near [param kart] is to a box on the floor it cannot take for holding an item already: 0
## out past [constant FAR], 1 within [constant NEAR].
func _nearness(kart: Kart) -> float:
	if match_node.arena == null:
		return 0.0
	var nearest := INF
	for at: Vector3 in _boxes_on_the_floor():
		var gap := at - kart.global_position
		nearest = minf(nearest, Vector2(gap.x, gap.z).length())
	return clampf((FAR - nearest) / (FAR - NEAR), 0.0, 1.0)


## Where the item boxes on the floor are this frame. Asked for each player here up to twice a
## frame, and looking means going through everything on the floor, chips and all.
func _boxes_on_the_floor() -> Array[Vector3]:
	var frame := Engine.get_process_frames()
	if frame == _boxes_frame:
		return _boxes
	_boxes_frame = frame
	_boxes.clear()
	for node: Node in match_node.arena.pickups.get_children():
		var box := node as ItemBox
		if box != null and not box.is_queued_for_deletion() and not box.predicted_take():
			_boxes.append(box.global_position)
	return _boxes


## How much of [param tag] shows: all of it until it has been settled a while and then less and
## less, or as near as the box it is there for.
static func _fade(tag: Dictionary) -> float:
	if tag.has("near"):
		return float(tag["near"])
	return 1.0 - clampf((float(tag["settled"]) - HOLD) / FADE, 0.0, 1.0)


## The button that uses the item, on the chip's lower corner once the item is usable: made for the
## keys or the pad the player is on, again should they change, and faded with the chip. None on a
## touch screen, GAME.md 4.2: the touch controls already put a button with the item's own picture
## under the player's thumb, and a key named over the kart is a key they do not have.
func _place_button(slot: int, kart: Kart) -> void:
	var tag := _tags[slot]
	var usable := kart.held_item != null and kart.item_reveal_left <= 0.0 and not TouchInput.enabled
	var box := _box(kart)
	var keyboard := DeviceInput.uses_keyboard(match_node.slots[slot].device())
	var button: Control = tag.get("button")
	if button != null and (not usable or tag["keyboard"] != keyboard):
		button.queue_free()
		tag.erase("button")
		button = null
	if not usable or not box.has_area():
		return
	if button == null:
		button = InputHint.glyph(InputActions.USE_ITEM, keyboard, BUTTON_INK, BUTTON_SIZE)
		if button == null:
			return
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(button)
		tag["button"] = button
		tag["keyboard"] = keyboard
	var fade := _fade(tag)
	button.size = button.get_combined_minimum_size()
	button.position = box.grow(PAD).end - button.size * 0.6
	button.modulate.a = fade


## Where the chip's picture goes for [param kart] on this screen, or an empty rect when the kart
## is out of sight.
func _box(kart: Kart) -> Rect2:
	var camera := get_viewport().get_camera_3d()
	# Where the kart is drawn, between physics ticks, rather than where the last tick left it:
	# followed tick by tick, the tag stepped along beside a kart that glides.
	var origin := kart.get_global_transform_interpolated().origin
	if camera == null:
		return Rect2()
	# Measured off the kart in the world rather than in pixels, so the chip keeps to the kart's
	# corner however far out the camera has pulled.
	var corner := origin + camera.global_basis.x * CORNER.x + Vector3.UP * CORNER.y
	if camera.is_position_behind(corner):
		return Rect2()
	var at := camera.unproject_position(corner) + Vector2(PAD, -PAD - ICON)
	return Rect2(at, Vector2.ONE * ICON)


func _draw() -> void:
	for slot: int in _tags:
		var kart := match_node.slots[slot].kart
		var box := _box(kart)
		if kart.held_item == null or not box.has_area():
			continue
		var fade := _fade(_tags[slot])
		var chip := StyleBoxFlat.new()
		chip.bg_color = Color(CHIP, CHIP.a * fade)
		chip.border_color = Color(RIM, RIM.a * fade)
		chip.set_border_width_all(1)
		chip.set_corner_radius_all(6)
		draw_style_box(chip, box.grow(PAD))
		var id := kart.held_item.id
		var ink := kart.held_item.color
		if kart.item_reveal_left > 0.0:
			# The same turn through the items as the roulette in the corner, at the same pace.
			var spin := PowerUpArt.known()
			id = spin[int(kart.item_reveal_left / ItemRow.SPIN) % spin.size()]
			ink = ItemRow.SPINNING
		PowerUpArt.draw_into(self, box, id, Color(ink, fade))
