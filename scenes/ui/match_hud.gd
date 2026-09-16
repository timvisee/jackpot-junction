class_name MatchHud
extends CanvasLayer
## The match HUD from GAME.md 8.3: timer, standings, one block per human player, a hand of joker
## cards per human along the bottom, countdown and Last Call banners, in-world floating texts for
## grazes and mult, the tally on cash-out, and the results panel. Reads the match; never changes
## it except through the results and lobby buttons.

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
var _hands: Dictionary[int, JokerHand] = {}
var _results: PanelContainer
var _results_rows: VBoxContainer
var _lobby: PanelContainer
var _lobby_rows: RichTextLabel
var _lobby_hint: Label
var _lobby_start: Button
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
		if slot.is_local_human():
			add_block(slot)
	_build_results()
	_build_lobby()
	Events.grazed.connect(_on_grazed)
	Events.mult_gained.connect(_on_mult_gained)
	Events.bank_completed.connect(_on_bank_completed)
	Events.death_banked.connect(_on_death_banked)
	Events.match_state_changed.connect(_on_state_changed)
	Events.kart_killed.connect(_on_kart_killed)
	Events.nitro_gained.connect(_on_nitro_gained)


func _on_nitro_gained(slot: int) -> void:
	var kart := _kart(slot)
	if kart != null:
		FloatingText.spawn(
			match_node, kart.global_position, "+NITRO", Color(1.0, 0.75, 0.3), 36, 0.9
		)


func _on_kart_killed(victim_slot: int, _killer_slot: int, _cause: StringName) -> void:
	_rumble(victim_slot, 1.0, 0.4)


## Vibrates the gamepad of a human slot, when rumble is on.
func _rumble(slot: int, strength: float, seconds: float) -> void:
	if not Game.settings.rumble or slot < 0 or slot >= match_node.slots.size():
		return
	var player := match_node.slots[slot]
	if not player.is_local_human():
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
	Events.nitro_gained.disconnect(_on_nitro_gained)


## Shows a HUD block and the control hint for a human slot.
func add_block(slot: PlayerSlot) -> void:
	if _blocks.has(slot.index):
		return
	_blocks[slot.index] = _make_block(slot)
	var hand := JokerHand.new()
	hand.name = "Hand%d" % slot.index
	hand.kart = slot.kart
	hand.keyboard = slot.device() in [DeviceInput.KEYBOARD, DeviceInput.ANY]
	add_child(hand)
	_hands[slot.index] = hand
	_layout_hands()
	ControlHint.attach(slot.kart, slot.device())


func remove_block(slot: PlayerSlot) -> void:
	if not _blocks.has(slot.index):
		return
	var block: Dictionary = _blocks[slot.index]
	(block["box"] as Control).queue_free()
	_blocks.erase(slot.index)
	_hands[slot.index].queue_free()
	_hands.erase(slot.index)
	_layout_hands()


## Hands share the bottom edge in slot order.
func _layout_hands() -> void:
	var indices := _hands.keys()
	indices.sort()
	for i: int in indices.size():
		var hand := _hands[indices[i]]
		hand.column = i
		hand.columns = indices.size()


func _process(delta: float) -> void:
	_update_timer()
	_update_standings()
	_update_blocks()
	_update_banner(delta)
	_update_lobby()


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
	var bottom_blocks: Array[Rect2] = []
	for index: int in _blocks:
		if index % BLOCK_ANCHORS.size() >= 2:
			bottom_blocks.append((_blocks[index]["box"] as Control).get_global_rect())
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
		var nitro: ProgressBar = block["nitro"]
		nitro.value = kart.nitro_charge * 100.0
		nitro.modulate = Color(1.0, 0.75, 0.3) if kart.nitro_active else Color(0.85, 0.85, 0.9)
		var item: Label = block["item"]
		if kart.held_item == null:
			item.text = ""
		elif kart.item_reveal_left > 0.0:
			item.text = "? ? ?" if fmod(kart.item_reveal_left, 0.12) < 0.06 else "? ?"
		else:
			item.text = "Item: %s" % kart.held_item.display_name
		var hand := _hands[index]
		hand.kart = kart
		hand.avoid = bottom_blocks
		_update_offer(slot, block)


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
	return "#" + JokerHand.kind_color(joker).to_html(false)


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
	var prefix := "%d × %s = " % [coins, _format_mult(mult)]
	var big := total >= 500
	FloatingText.spawn_counting(
		match_node, kart.global_position, prefix, total, Palette.CHIP_GOLD, 96 if big else 72, 1.8
	)
	ChipBurst.spawn(
		match_node,
		kart.global_position,
		match_node.arena.junction_position,
		mini(coins, 14),
		Palette.CHIP_GOLD
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
	var nitro := ProgressBar.new()
	nitro.min_value = 0.0
	nitro.max_value = 100.0
	nitro.value = 100.0
	nitro.show_percentage = false
	nitro.custom_minimum_size = Vector2(180.0, 10.0)
	nitro.tooltip_text = "Nitro"
	var item := Label.new()
	item.add_theme_font_size_override("font_size", 22)
	item.add_theme_color_override("font_color", Palette.NEON_MAGENTA)
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
	box.add_child(nitro)
	box.add_child(offer)
	return {
		"box": box,
		"banked": banked,
		"pot": pot,
		"stats": stats,
		"nitro": nitro,
		"item": item,
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
	rematch.visible = not match_node.puppet
	buttons.add_child(rematch)
	var quit := Button.new()
	quit.text = "Back to title"
	quit.pressed.connect(func() -> void: Game.go_to_title())
	buttons.add_child(quit)


## The online lobby, GAME.md 9.3: who is here, how to join, and the host's Start button.
func _build_lobby() -> void:
	_lobby = PanelContainer.new()
	_lobby.name = "Lobby"
	_lobby.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_lobby.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_lobby.grow_vertical = Control.GROW_DIRECTION_BOTH
	_lobby.custom_minimum_size = Vector2(620.0, 0.0)
	_lobby.visible = false
	add_child(_lobby)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 24)
	_lobby.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	column.add_child(MenuTheme.title("Online lobby", 44))
	_lobby_hint = Label.new()
	_lobby_hint.add_theme_font_size_override("font_size", 20)
	_lobby_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_lobby_hint)
	_lobby_rows = RichTextLabel.new()
	_lobby_rows.bbcode_enabled = true
	_lobby_rows.fit_content = true
	_lobby_rows.scroll_active = false
	_lobby_rows.add_theme_font_size_override("normal_font_size", 24)
	column.add_child(_lobby_rows)
	_lobby_start = MenuTheme.button("Start match")
	_lobby_start.pressed.connect(func() -> void: match_node.begin_from_lobby())
	_lobby_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_lobby_start)
	var leave := MenuTheme.button("Back to title", 24)
	leave.pressed.connect(func() -> void: Game.go_to_title())
	leave.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(leave)


func _update_lobby() -> void:
	var in_lobby := match_node.state == Match.State.LOBBY
	if _lobby.visible != in_lobby:
		_lobby.visible = in_lobby
		if in_lobby and not match_node.puppet:
			_lobby_start.grab_focus()
	if not in_lobby:
		return
	_lobby_start.visible = not match_node.puppet
	_lobby_hint.text = (
		match_node.lobby_hint
		if not match_node.puppet
		else "Waiting for the host to start the match..."
	)
	var lines: PackedStringArray = []
	for slot: PlayerSlot in match_node.slots:
		var kind := "player" if slot.is_human() else "bot, free for a player to take"
		lines.append(
			(
				"[color=#%s]■[/color]  %s  [color=#9a9aa0]%s[/color]"
				% [slot.color().to_html(false), slot.display_name(), kind]
			)
		)
	_lobby_rows.text = "[center]%s[/center]" % "\n".join(lines)


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
