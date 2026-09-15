class_name MatchHud
extends CanvasLayer
## The match HUD from GAME.md 8.3: timer, standings, one block per human player, countdown and
## Last Call banners, in-world floating texts for grazes and mult, the tally on cash-out, and the
## results panel. Reads the match; never changes it except through the results buttons.

const BLOCK_ANCHORS: Array[int] = [
	Control.PRESET_TOP_LEFT,
	Control.PRESET_TOP_RIGHT,
	Control.PRESET_BOTTOM_LEFT,
	Control.PRESET_BOTTOM_RIGHT
]

var match_node: Match

var _timer: Label
var _standings: RichTextLabel
var _banner: Label
var _blocks: Dictionary[int, Dictionary] = {}
var _results: PanelContainer
var _results_rows: VBoxContainer
var _go_left := 0.0


func _ready() -> void:
	layer = 5
	_timer = _label(40, Control.PRESET_CENTER_TOP)
	_timer.offset_top = 10.0
	_standings = RichTextLabel.new()
	_standings.bbcode_enabled = true
	_standings.fit_content = true
	_standings.scroll_active = false
	_standings.autowrap_mode = TextServer.AUTOWRAP_OFF
	_standings.add_theme_font_size_override("normal_font_size", 20)
	_standings.custom_minimum_size = Vector2(600.0, 0.0)
	_standings.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_standings.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_standings.offset_top = 62.0
	add_child(_standings)
	_banner = _label(96, Control.PRESET_CENTER)
	_banner.visible = false
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human():
			_blocks[slot.index] = _make_block(slot)
			ControlHint.attach(slot.kart, slot.device())
	_build_results()
	Events.grazed.connect(_on_grazed)
	Events.mult_gained.connect(_on_mult_gained)
	Events.bank_completed.connect(_on_bank_completed)
	Events.death_banked.connect(_on_death_banked)
	Events.match_state_changed.connect(_on_state_changed)
	Events.kart_killed.connect(_on_kart_killed)


func _on_kart_killed(victim_slot: int, _killer_slot: int, _cause: StringName) -> void:
	_rumble(victim_slot, 1.0, 0.4)


## Vibrates the gamepad of a human slot, when rumble is on.
func _rumble(slot: int, strength: float, seconds: float) -> void:
	if not Game.settings.rumble or slot < 0 or slot >= match_node.slots.size():
		return
	var player := match_node.slots[slot]
	if not player.is_human():
		return
	var device := player.device()
	var devices: Array[int] = []
	if device >= 0:
		devices.append(device)
	elif device == DeviceInput.ANY:
		devices.assign(Input.get_connected_joypads())
	for joypad: int in devices:
		Input.start_joy_vibration(joypad, strength * 0.5, strength, seconds)


func _exit_tree() -> void:
	Events.kart_killed.disconnect(_on_kart_killed)
	Events.grazed.disconnect(_on_grazed)
	Events.mult_gained.disconnect(_on_mult_gained)
	Events.bank_completed.disconnect(_on_bank_completed)
	Events.death_banked.disconnect(_on_death_banked)
	Events.match_state_changed.disconnect(_on_state_changed)


func _process(delta: float) -> void:
	_update_timer()
	_update_standings()
	_update_blocks()
	_update_banner(delta)


func _update_timer() -> void:
	var seconds := ceili(match_node.time_left)
	_timer.text = "%d:%02d" % [seconds / 60, seconds % 60]
	var last_call := match_node.state == Match.State.LAST_CALL
	_timer.add_theme_color_override(
		"font_color", Color(1.0, 0.35, 0.3) if last_call else Color.WHITE
	)


func _update_standings() -> void:
	var parts: PackedStringArray = []
	for slot: PlayerSlot in match_node.standings():
		parts.append(
			(
				"[color=#%s]%s %d[/color]"
				% [slot.color().to_html(false), slot.display_name(), slot.banked]
			)
		)
	_standings.text = "[center]%s[/center]" % "     ".join(parts)


func _update_blocks() -> void:
	for index: int in _blocks:
		var slot := match_node.slots[index]
		var block := _blocks[index]
		var banked: Label = block["banked"]
		var pot: Label = block["pot"]
		var stats: Label = block["stats"]
		banked.text = str(slot.banked)
		var kart := slot.kart
		if kart.alive:
			pot.text = (
				"%d × %s = %d" % [kart.pot.coins, _format_mult(kart.pot.mult), kart.pot.value()]
			)
		else:
			pot.text = "respawning %.1f" % maxf(slot.respawn_left, 0.0)
		stats.text = "K %d  D %d" % [slot.kills, slot.deaths]
		var item: Label = block["item"]
		if kart.held_item == null:
			item.text = ""
		elif kart.item_reveal_left > 0.0:
			item.text = "? ? ?" if fmod(kart.item_reveal_left, 0.12) < 0.06 else "? ?"
		else:
			item.text = "Item: %s" % kart.held_item.display_name
		var jokers: RichTextLabel = block["jokers"]
		jokers.text = _joker_row(kart)
		_update_offer(slot, block)


func _joker_row(kart: Kart) -> String:
	if kart.jokers.count() == 0:
		return ""
	var parts: PackedStringArray = []
	for i: int in kart.jokers.count():
		var joker := kart.jokers.jokers[i]
		var text := "[color=%s]%s[/color]" % [_kind_color(joker), joker.initials()]
		if kart.menu_open and i == kart.menu_index:
			text = "[%s]" % text
		parts.append(text)
	var row := "  ".join(parts)
	if kart.menu_open:
		var current := kart.jokers.jokers[kart.menu_index]
		row += (
			"\n%s: %s\n[ ] cycle   E drop   Q destroy" % [current.display_name, current.description]
		)
	return row


func _update_offer(slot: PlayerSlot, block: Dictionary) -> void:
	var panel: PanelContainer = block["offer"]
	var text: RichTextLabel = block["offer_text"]
	var offer := slot.offer
	if offer == null or offer.is_done():
		panel.visible = false
		return
	panel.visible = true
	var lines: PackedStringArray = []
	if offer.stage == JokerOffer.Stage.CHOOSING:
		lines.append("[b]Pick a joker[/b]")
		for i: int in offer.choices.size():
			var joker := offer.choices[i]
			var marker := "> " if i == offer.selected else "   "
			lines.append(
				(
					"%s%d. [color=%s]%s[/color]  %s"
					% [marker, i + 1, _kind_color(joker), joker.display_name, joker.description]
				)
			)
		lines.append("1-%d pick   E take   Q skip" % offer.choices.size())
	else:
		lines.append("[b]Destroy which joker for %s?[/b]" % offer.chosen.display_name)
		var held := slot.kart.jokers.jokers
		for i: int in held.size():
			var marker := "> " if i == offer.selected else "   "
			lines.append(
				(
					"%s%d. [color=%s]%s[/color]"
					% [marker, i + 1, _kind_color(held[i]), held[i].display_name]
				)
			)
		lines.append("1-5 pick   E confirm   Q back")
	text.text = "\n".join(lines)


func _kind_color(joker: Joker) -> String:
	match joker.kind:
		Joker.Kind.STAT:
			return "#dddddd"
		Joker.Kind.CURSED:
			return "#ff6b6b"
	return "#f2c14e"


func _update_banner(delta: float) -> void:
	match match_node.state:
		Match.State.COUNTDOWN:
			_banner.visible = true
			_banner.text = str(ceili(match_node.countdown_left))
			_go_left = 0.8
		Match.State.PLAYING:
			_go_left -= delta
			_banner.visible = _go_left > 0.0
			_banner.text = "GO"
		Match.State.LAST_CALL:
			var pulse := (
				Game.settings.flash_reduction or fmod(Time.get_ticks_msec() * 0.001, 1.0) < 0.5
			)
			_banner.visible = (
				match_node.time_left > match_node.rules.last_call_duration - 3.0 and pulse
			)
			_banner.text = "LAST CALL"
		_:
			_banner.visible = false


func _on_state_changed(state: int) -> void:
	if state == Match.State.RESULTS:
		_show_results()
	else:
		_results.visible = false


func _on_grazed(slot: int) -> void:
	var kart := _kart(slot)
	if kart != null:
		FloatingText.spawn(
			match_node,
			kart.global_position,
			"+%s" % _format_mult(match_node.rules.graze_mult),
			Palette.NEON_CYAN,
			40,
			0.8
		)


func _on_mult_gained(slot: int, amount: float, reason: StringName) -> void:
	if reason == &"graze":
		return
	var kart := _kart(slot)
	if kart != null:
		FloatingText.spawn(
			match_node,
			kart.global_position,
			"+%s MULT" % _format_mult(amount),
			Palette.CHIP_GOLD,
			48,
			1.0
		)


func _on_bank_completed(slot: int, coins: int, mult: float, total: int) -> void:
	var kart := _kart(slot)
	if kart == null:
		return
	var text := "%d × %s = %d" % [coins, _format_mult(mult), total]
	var big := total >= 500
	FloatingText.spawn(
		match_node, kart.global_position, text, Palette.CHIP_GOLD, 96 if big else 72, 1.6
	)
	if big:
		match_node.camera_rig.shake(1.0)
	_rumble(slot, 0.6 if big else 0.3, 0.35)


func _on_death_banked(slot: int, amount: int) -> void:
	var kart := _kart(slot)
	if kart != null:
		FloatingText.spawn(
			match_node, kart.global_position, "½  %d" % amount, Color(0.75, 0.75, 0.75), 56, 1.4
		)


func _kart(slot: int) -> Kart:
	if slot < 0 or slot >= match_node.slots.size():
		return null
	return match_node.slots[slot].kart


func _format_mult(mult: float) -> String:
	if is_equal_approx(mult, roundf(mult)):
		return str(int(roundf(mult)))
	return "%.1f" % mult


func _label(size: int, preset: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.set_anchors_and_offsets_preset(preset)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	return label


func _make_block(slot: PlayerSlot) -> Dictionary:
	var box := VBoxContainer.new()
	box.name = "Block%d" % slot.index
	box.set_anchors_and_offsets_preset(BLOCK_ANCHORS[slot.index % BLOCK_ANCHORS.size()])
	var right := slot.index % 2 == 1
	var bottom := slot.index >= 2
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	box.offset_left = -16.0 if right else 16.0
	box.offset_right = -16.0 if right else 16.0
	box.offset_top = -16.0 if bottom else 16.0
	box.offset_bottom = -16.0 if bottom else 16.0
	add_child(box)
	var name_label := Label.new()
	name_label.text = slot.display_name()
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", slot.color())
	var banked := Label.new()
	banked.add_theme_font_size_override("font_size", 56)
	var pot := Label.new()
	pot.add_theme_font_size_override("font_size", 26)
	var stats := Label.new()
	stats.add_theme_font_size_override("font_size", 18)
	var item := Label.new()
	item.add_theme_font_size_override("font_size", 22)
	item.add_theme_color_override("font_color", Palette.NEON_MAGENTA)
	var jokers := RichTextLabel.new()
	jokers.bbcode_enabled = true
	jokers.fit_content = true
	jokers.scroll_active = false
	jokers.autowrap_mode = TextServer.AUTOWRAP_OFF
	jokers.custom_minimum_size = Vector2(420.0, 0.0)
	jokers.add_theme_font_size_override("normal_font_size", 20)
	var offer := PanelContainer.new()
	offer.visible = false
	offer.custom_minimum_size = Vector2(560.0, 0.0)
	var offer_text := RichTextLabel.new()
	offer_text.bbcode_enabled = true
	offer_text.fit_content = true
	offer_text.scroll_active = false
	offer_text.add_theme_font_size_override("normal_font_size", 20)
	offer.add_child(offer_text)
	for label: Label in [name_label, banked, pot, stats, item]:
		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
		)
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		box.add_child(label)
	box.add_child(jokers)
	box.add_child(offer)
	return {
		"box": box,
		"banked": banked,
		"pot": pot,
		"stats": stats,
		"item": item,
		"jokers": jokers,
		"offer": offer,
		"offer_text": offer_text,
	}


func _build_results() -> void:
	_results = PanelContainer.new()
	_results.name = "Results"
	_results.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_results.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_results.grow_vertical = Control.GROW_DIRECTION_BOTH
	_results.custom_minimum_size = Vector2(520.0, 0.0)
	_results.visible = false
	add_child(_results)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 24)
	_results.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = "Results"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_results_rows = VBoxContainer.new()
	column.add_child(_results_rows)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	column.add_child(buttons)
	var rematch := Button.new()
	rematch.text = "Rematch"
	rematch.pressed.connect(func() -> void: match_node.rematch())
	buttons.add_child(rematch)
	var quit := Button.new()
	quit.text = "Back to title"
	quit.pressed.connect(func() -> void: Game.go_to_title())
	buttons.add_child(quit)


func _show_results() -> void:
	for child: Node in _results_rows.get_children():
		child.queue_free()
	var rank := 1
	for slot: PlayerSlot in match_node.standings():
		var row := Label.new()
		row.text = (
			"%d.  %s    %d    (%d kills, %d deaths)"
			% [rank, slot.display_name(), slot.banked, slot.kills, slot.deaths]
		)
		row.add_theme_font_size_override("font_size", 28)
		row.add_theme_color_override("font_color", slot.color())
		_results_rows.add_child(row)
		rank += 1
	_results.visible = true
