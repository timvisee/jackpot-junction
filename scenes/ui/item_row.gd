class_name ItemRow
extends VBoxContainer
## What a player is carrying and what is running on them, GAME.md 8.3.
##
## Three lines in one place, because they are one question: an item is picked up, held, played,
## and then it is doing something. The first is the item in hand, with its own picture beside its
## name. Under it is whatever that item started and has still to finish -- an effect counting down
## in seconds, a cannon counting down in shots -- named the same and in the same color. None of
## the lines is there when there is nothing for it to say.

## The picture beside the name, and how fast the picture flicks through the others while the box
## a player just drove into is still opening.
const ICON := 30.0
## The small pictures of items queued behind the held one with Pack Rat, GAME.md 7.3: how big each
## is, and how many are shown before the rest are left off the end of a long hoard.
const QUEUE_ICON := 18.0
const MAX_QUEUE := 4
const SPIN := 0.06
const SPINNING := Color(0.72, 0.72, 0.78)
## The countdown under a running effect.
const BAR := Vector2(112.0, 5.0)

var art: PowerUpArt.Picture
var label: Label
## The first running line's own two pieces, which is what most of a match has at most one of.
var running: Label
var clock: ProgressBar

var _held: HBoxContainer
## The queued items' pictures, Pack Rat's hoard behind the held one, shown small, see
## [method show_kart].
var _queue: HBoxContainer
var _queue_icons: Array[PowerUpArt.Picture] = []
## A line each for what is running: one for whatever a power-up started and one for a cannon
## that is loaded with something. Two is the most a kart can have going at once that is worth
## reading; a third would be a paragraph in the corner of the screen.
var _lines: Array[Dictionary] = []


## Puts the two lines in [param parent], reading outward from the edge of the screen the block is
## on, the way the rest of the block does.
static func add_to(parent: Control, right: bool) -> ItemRow:
	var rows := ItemRow.new()
	rows.name = "ItemRow"
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 3)
	parent.add_child(rows)
	rows._build(right)
	return rows


## What the kart is holding and what it has running, every frame.
func show_kart(kart: Kart) -> void:
	_held.visible = kart.held_item != null
	if _held.visible:
		if kart.item_reveal_left > 0.0:
			var spin := PowerUpArt.known()
			art.id = spin[int(kart.item_reveal_left / SPIN) % spin.size()]
			art.ink = SPINNING
			art.halo = false
			label.text = ""
		else:
			art.id = kart.held_item.id
			art.ink = kart.held_item.color
			art.halo = ItemTag.GUARDIAN.guards(kart)
			label.text = kart.held_item.display_name
			Type.ink(label, kart.held_item.color)
	# The hoard queued behind the held one with Pack Rat, GAME.md 7.3: a small picture each, up to
	# what fits, so what is waiting its turn reads at a glance rather than only as a number.
	for i: int in _queue_icons.size():
		var icon := _queue_icons[i]
		icon.visible = i < kart._item_queue.size()
		if icon.visible:
			var waiting: PowerUp = kart._item_queue[i]
			icon.id = waiting.id
			icon.ink = waiting.color
	var going := going_on(kart)
	for i: int in _lines.size():
		var line: Dictionary = _lines[i]
		var row: HBoxContainer = line["row"]
		row.visible = i < going.size()
		if not row.visible:
			continue
		var what: Dictionary = going[i]
		var name_of_it: Label = line["name"]
		var bar: ProgressBar = line["clock"]
		name_of_it.text = what["name"]
		Type.ink(name_of_it, what["color"])
		bar.modulate = what["color"]
		bar.value = 100.0 * float(what["left"])


## What is going on a kart, in the order it is worth reading: whatever a power-up started and is
## still running, and whatever is loaded in the cannon. A cannon power-up runs out in shots rather
## than in seconds -- the spread and the ricochet are loaded, not timed -- so the bar under it is
## the shots left rather than the time.
static func going_on(kart: Kart) -> Array[Dictionary]:
	var going: Array[Dictionary] = []
	var best: KartEffect = null
	for effect: KartEffect in kart.effects:
		if effect.display_name.is_empty():
			continue
		if best == null or effect.time_left > best.time_left:
			best = effect
	if best != null:
		var timed := {
			"name": best.display_name,
			"id": best.item_id,
			"color": best.color,
			"left": best.time_left / maxf(best.duration, 0.001),
		}
		going.append(timed)
	var shots := kart.cannon.override_shots_left()
	var loaded_name := kart.cannon.override_name
	# Unless the effect above is the thing that loaded it. The Swivel Cannon is free aim for a
	# while, which it does by running an effect and holding the cannon open for as long as that
	# effect lasts; read as two it was two lines saying the same thing, counting down together.
	var already := best != null and best.display_name == loaded_name
	if shots > 0 and not loaded_name.is_empty() and not already:
		var loaded := {
			"name": loaded_name,
			"id": kart.cannon.override_item,
			"color": kart.cannon.override_color,
			"left": float(shots) / maxf(float(kart.cannon.override_total), 1.0),
		}
		going.append(loaded)
	return going


func _build(right: bool) -> void:
	var edge := BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	_held = HBoxContainer.new()
	_held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held.alignment = edge
	_held.add_theme_constant_override("separation", 7)
	art = PowerUpArt.picture(&"", Palette.NEON_MAGENTA)
	art.custom_minimum_size = Vector2(ICON, ICON)
	label = _name(right)
	Type.set_font(label, Type.STRONG, Type.BODY)
	if right:
		_held.add_child(label)
		_held.add_child(art)
	else:
		_held.add_child(art)
		_held.add_child(label)
	add_child(_held)
	# Under the held item, small pictures of whatever is queued behind it with Pack Rat, GAME.md 7.3,
	# read outward from the edge the block is on like the rest, see [method show_kart].
	_queue = HBoxContainer.new()
	_queue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_queue.alignment = edge
	_queue.add_theme_constant_override("separation", 3)
	for i: int in MAX_QUEUE:
		var icon := PowerUpArt.picture(&"", Palette.NEON_MAGENTA)
		icon.custom_minimum_size = Vector2(QUEUE_ICON, QUEUE_ICON)
		icon.visible = false
		_queue.add_child(icon)
		_queue_icons.append(icon)
	add_child(_queue)
	for i: int in 2:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.alignment = edge
		row.add_theme_constant_override("separation", 8)
		var named := _name(right)
		Type.set_font(named, Type.numbers_text_font(), Type.LABEL)
		var bar := _clock()
		if right:
			row.add_child(named)
			row.add_child(bar)
		else:
			row.add_child(bar)
			row.add_child(named)
		add_child(row)
		_lines.append({"row": row, "name": named, "clock": bar})
	running = _lines[0]["name"]
	clock = _lines[0]["clock"]


func _name(right: bool) -> Label:
	var text := Label.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.clip_text = true
	text.custom_minimum_size = Vector2(150.0, 0.0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	HudText.shadowed(text)
	return text


## The time left on it, as a bar rather than as a number: what a player needs off this is whether
## there is a lot of it left or a little.
func _clock() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size = BAR
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.value = 100.0
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.1, 0.13, 0.75)
	back.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 1.0, 1.0)
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	return bar
