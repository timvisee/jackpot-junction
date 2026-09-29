class_name ItemTag
extends Control
## The item a player on this screen has just picked up, shown beside their kart, GAME.md 8.3: a
## small picture that turns through the items the way the roulette in their corner does while the
## box is opening, settles on the one they got, and fades slowly, since the corner keeps saying
## what they hold. Used, it goes at once. The eyes are on the kart when it drives through a box,
## not on the corner of the screen.

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
	_tags.erase(slot)


func _process(delta: float) -> void:
	for slot: int in _tags.keys():
		var tag := _tags[slot]
		tag["age"] += delta
		var kart := match_node.slots[slot].kart if slot < match_node.slots.size() else null
		if kart == null or (kart.held_item == null and tag["age"] > GRACE):
			_tags.erase(slot)
			continue
		if kart.held_item != null and kart.item_reveal_left <= 0.0:
			tag["settled"] += delta
			if tag["settled"] >= HOLD + FADE:
				_tags.erase(slot)
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for slot: int in _tags:
		var kart := match_node.slots[slot].kart
		var above := kart.global_position + Vector3(0.0, 0.6, 0.0)
		if kart.held_item == null or camera.is_position_behind(above):
			continue
		var fade := 1.0 - clampf((float(_tags[slot]["settled"]) - HOLD) / FADE, 0.0, 1.0)
		var at := camera.unproject_position(above) + OFFSET
		var box := Rect2(at - Vector2.ONE * ICON * 0.5, Vector2.ONE * ICON)
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
