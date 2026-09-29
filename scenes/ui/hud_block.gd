class_name HudBlock
extends RefCounted
## A player's corner of the match HUD, GAME.md 8.3: their name, what they have banked, the pot,
## kills and deaths, the item row, the lives, the nitro tank, the speedometer and the hints, on a
## scrim. Built here and kept up to date by [MatchHud], which holds what this hands back.


## The block for [param slot] in [param corner] of [param hud], with a heart for each of the
## [param lives] a kart has, added to it. What is in it, for the HUD to keep up to date.
static func make(hud: CanvasLayer, slot: PlayerSlot, corner: int, lives_each: int) -> Dictionary:
	# A corner of numbers over a table that is felt one moment and a white block the next needs
	# something to sit on, GAME.md 8.3. A scrim rather than a panel: enough to hold the text
	# together, not so much that the arena has a box cut out of it.
	var card := PanelContainer.new()
	card.name = "Block%d" % slot.index
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", scrim())
	card.custom_minimum_size = Vector2(MatchHud.BLOCK_WIDTH, 0.0)
	card.set_anchors_and_offsets_preset(MatchHud.BLOCK_ANCHORS[corner])
	var right := corner % 2 == 1
	var bottom := corner >= 2
	card.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	card.offset_left = -16.0 if right else 16.0
	card.offset_right = -16.0 if right else 16.0
	card.offset_top = -16.0 if bottom else 16.0
	card.offset_bottom = -16.0 if bottom else 16.0
	hud.add_child(card)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	var name_label := Label.new()
	name_label.text = slot.display_name()
	Type.strong(name_label, Type.BODY, slot.color())
	var banked := Label.new()
	# The banked score is the number a player checks mid-corner, so it is set the largest and
	# in the heaviest cut there is, GAME.md 8.3.
	Type.numbers(banked, Type.SCORE)
	var stats := Label.new()
	Type.set_font(stats, Type.numbers_text_font(), Type.LABEL)
	stats.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))
	var lives := HBoxContainer.new()
	lives.add_theme_constant_override("separation", 6)
	lives.alignment = BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	var pips: Array = []
	for i: int in lives_each:
		var pip := Heart.new()
		pip.custom_minimum_size = Vector2(MatchHud.LIFE_SIZE, MatchHud.LIFE_SIZE)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.color = slot.color()
		lives.add_child(pip)
		pips.append(pip)
	# A row rather than a line of text: the buttons in it are drawn, GAME.md 8.3. It fills the
	# block so the pictures line up with the writing above them on either side of the screen.
	var hints := HBoxContainer.new()
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hints.alignment = BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	var nitro := bar(Vector2(180.0, 8.0), slot.color())
	nitro.value = 100.0
	nitro.tooltip_text = "Nitro"
	var speed_dial := bar(Vector2(120.0, 6.0), Color(0.82, 0.82, 0.88))
	speed_dial.tooltip_text = "Speed"
	speed_dial.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var speed := Label.new()
	speed.text = "0 km/h"
	Type.set_font(speed, Type.numbers_text_font(), Type.LABEL)
	# Wide enough for the fastest thing on the table and no wider, so the row holds still. Three
	# digits and the unit: at 76 the h of km/h was half a letter.
	speed.custom_minimum_size = Vector2(96.0, 0.0)
	speed.clip_text = true
	speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	HudText.shadowed(speed, 2)
	# The dial reads left to right whichever corner the block is in, with the number at the
	# outside edge where the rest of the block's text already lines up.
	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	speed_row.alignment = BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	if right:
		speed_row.add_child(speed)
		speed_row.add_child(speed_dial)
	else:
		speed_row.add_child(speed_dial)
		speed_row.add_child(speed)
	# Beside the name, a warning while this player's line to the host is slow, GAME.md 10.3.
	var lag := LagWarning.make(18.0, true)
	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override("separation", 8)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for part: Control in [lag, name_label] if right else [name_label, lag]:
		name_row.add_child(part)
	box.add_child(name_row)
	# What is in hand and what is running, GAME.md 8.3: one thing in one place, see [ItemRow].
	for label: Label in [name_label, banked, stats]:
		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
		)
		# Clipped rather than measured: a label that asks for the width of its own text is what
		# made the block breathe in and out with the speedometer.
		label.clip_text = true
		HudText.shadowed(label)
		if label != name_label:
			box.add_child(label)
	# The pot goes between the banked score and the kill count, GAME.md 8.3.
	var pot := ScorePills.add_to(box, right)
	box.move_child(pot, 2)
	var item := ItemRow.add_to(box, right)
	box.add_child(lives)
	box.add_child(nitro)
	box.add_child(speed_row)
	box.add_child(hints)
	return {
		"box": card,
		"name": name_label,
		"lag": lag,
		"corner": corner,
		"banked": banked,
		"pot": pot,
		"stats": stats,
		"lives": pips,
		"nitro": nitro,
		"speed_dial": speed_dial,
		"speed": speed,
		"item": item,
		"item_art": item.art,
		"item_name": item.label,
		"hints": hints,
		"hint_stamp": "",
		"worn": _worn(slot),
	}


## Keeps [param block] in [param slot]'s name and color, which a player can change in the lobby
## and the Garage, GAME.md 4.4, and a client hears about from the host, and in the palette, which
## the settings over the room can change, 8.5. Only on a change.
static func follow(block: Dictionary, slot: PlayerSlot) -> void:
	var worn := _worn(slot)
	if block["worn"] == worn:
		return
	block["worn"] = worn
	var name_label: Label = block["name"]
	name_label.text = slot.display_name()
	name_label.add_theme_color_override("font_color", slot.color())
	var fill := (block["nitro"] as ProgressBar).get_theme_stylebox("fill") as StyleBoxFlat
	fill.bg_color = slot.color()


## The scrim behind a player's corner: a dark card with rounded corners and no edge, soft enough
## that it reads as shade rather than as a panel.
static func scrim() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.05, 0.34)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 12.0
	return style


## One of the slim bars in a block: the nitro tank and the speedometer. Rounded, thin, and in
## the color of whatever it is measuring.
static func bar(size: Vector2, ink: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size = size
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	back.set_corner_radius_all(int(size.y * 0.5))
	var fill := StyleBoxFlat.new()
	fill.bg_color = ink
	fill.set_corner_radius_all(int(size.y * 0.5))
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


## What a block was drawn for: the name, the color and the palette it is in, GAME.md 8.5.
static func _worn(slot: PlayerSlot) -> String:
	return "%d|%s|%s" % [slot.color_index, Palette.vision, slot.display_name()]
