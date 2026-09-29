class_name ItemTag
extends Control
## The item a player on this screen has just picked up, shown beside their kart, GAME.md 8.3: a
## small picture that turns through the items the way the roulette in their corner does while the
## box is opening, settles on the one they got, and fades slowly, since the corner keeps saying
## what they hold. Once it can be used, the button that uses it sits on the chip's corner, drawn
## for the keys or the pad the player is on. Used, it goes at once. The eyes are on the kart when
## it drives through a box, not on the corner of the screen.

## How big the picture is, the chip it sits on, how far to the side of the kart it hangs, level with
## it and clear of the hints over it, how long it stays once settled and how long it takes to fade.
const ICON := 30.0
const PAD := 5.0
const OFFSET := Vector2(50.0, 6.0)
const HOLD := 0.8
const FADE := 1.2
## How long after the pickup a kart holding nothing still has its tag waiting for the item: on a
## client the word of the pickup can come a tick ahead of the snapshot that puts it in the kart.
const GRACE := 0.4
const CHIP := Color(0.04, 0.04, 0.06, 0.75)
## The button that uses the item, on the chip's lower corner: its size and ink.
const BUTTON_SIZE := 13
const BUTTON_INK := Color(0.92, 0.92, 0.95)

var match_node: Match

## Slot to its tag: how long since the pickup, and how long the item has been settled.
var _tags: Dictionary[int, Dictionary] = {}


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
		if kart.held_item != null and kart.item_reveal_left <= 0.0:
			tag["settled"] += delta
			if tag["settled"] >= HOLD + FADE:
				_drop(slot)
				continue
		_place_button(slot, kart)
	queue_redraw()


## The button that uses the item, on the chip's lower corner once the item is usable: made for the
## keys or the pad the player is on, again should they change, and faded with the chip.
func _place_button(slot: int, kart: Kart) -> void:
	var tag := _tags[slot]
	var usable := kart.held_item != null and kart.item_reveal_left <= 0.0
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
	var fade := 1.0 - clampf((float(tag["settled"]) - HOLD) / FADE, 0.0, 1.0)
	button.size = button.get_combined_minimum_size()
	button.position = box.grow(PAD).end - button.size * 0.6
	button.modulate.a = fade


## Where the chip's picture goes for [param kart] on this screen, or an empty rect when the kart
## is out of sight.
func _box(kart: Kart) -> Rect2:
	var camera := get_viewport().get_camera_3d()
	# Where the kart is drawn, between physics ticks, rather than where the last tick left it:
	# followed tick by tick, the tag stepped along beside a kart that glides.
	var above := kart.get_global_transform_interpolated().origin + Vector3(0.0, 0.6, 0.0)
	if camera == null or camera.is_position_behind(above):
		return Rect2()
	var at := camera.unproject_position(above) + OFFSET
	return Rect2(at - Vector2.ONE * ICON * 0.5, Vector2.ONE * ICON)


func _draw() -> void:
	for slot: int in _tags:
		var kart := match_node.slots[slot].kart
		var box := _box(kart)
		if kart.held_item == null or not box.has_area():
			continue
		var fade := 1.0 - clampf((float(_tags[slot]["settled"]) - HOLD) / FADE, 0.0, 1.0)
		var chip := StyleBoxFlat.new()
		chip.bg_color = Color(CHIP, CHIP.a * fade)
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
