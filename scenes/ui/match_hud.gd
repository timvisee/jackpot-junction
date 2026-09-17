class_name MatchHud
extends CanvasLayer
## The match HUD from GAME.md 8.3: timer, standings, one block per human player, a hand of joker
## cards per human along the bottom, countdown and Last Call banners, in-world floating texts for
## grazes and mult, the tally on cash-out, and the results panel. Reads the match; never changes
## it except through the results and lobby buttons.

## What a metre a second reads as on the speedometer. The karts are small and the arena is a
## table, so the honest number is a single figure and says nothing; scaled like this a kart
## tops out around 210 and nitro takes it to 400, which is what the driving feels like.
const SPEED_SCALE := 20.0
## The speed the dial is full at: a kart flat out on nitro, so the needle has somewhere to go
## when the bottle is lit.
const SPEED_FULL := 1.9
## The announcer's call: how far under the middle of the screen it sits, how long it holds and
## how much of that is the fade. It shares the middle with the start gantry and the GO, neither
## of which is up while anybody is being killed.
const CALL_DROP := 120.0
const CALL_TIME := 2.2
const CALL_FADE := 0.6

const BLOCK_ANCHORS: Array[int] = [
	Control.PRESET_TOP_LEFT,
	Control.PRESET_TOP_RIGHT,
	Control.PRESET_BOTTOM_LEFT,
	Control.PRESET_BOTTOM_RIGHT
]

var match_node: Match

var _timer: Label
var _scoreboard: Scoreboard
var _banner: Label
var _light: StartLight
var _call: Label
var _call_left := 0.0
var _blocks: Dictionary[int, Dictionary] = {}
## The cash-out tally each slot has in the air, so a run of them climbs one number.
var _tallies: Dictionary[int, FloatingText] = {}
var _hands: Dictionary[int, JokerHand] = {}
var _pickers: Dictionary[int, JokerPicker] = {}
var _kill_feed: KillFeed
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
	_scoreboard = Scoreboard.new()
	_scoreboard.name = "Scoreboard"
	_scoreboard.match_node = match_node
	add_child(_scoreboard)
	_banner = _label(96, Control.PRESET_CENTER)
	_banner.visible = false
	_light = StartLight.new()
	_light.name = "StartLight"
	# Above the middle of the screen, so the GO that follows it has the centre to itself.
	_light.hang(50.0)
	_light.visible = false
	add_child(_light)
	_call = _label(64, Control.PRESET_CENTER)
	_call.offset_top += CALL_DROP
	_call.visible = false
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human():
			add_block(slot)
	_kill_feed = KillFeed.new()
	_kill_feed.name = "KillFeed"
	add_child(_kill_feed)
	_build_results()
	_build_lobby()
	Events.grazed.connect(_on_grazed)
	Events.mult_gained.connect(_on_mult_gained)
	Events.bank_completed.connect(_on_bank_completed)
	Events.death_banked.connect(_on_death_banked)
	Events.match_state_changed.connect(_on_state_changed)
	Events.kart_killed.connect(_on_kart_killed)
	Events.nitro_gained.connect(_on_nitro_gained)
	Events.flush_completed.connect(_on_flush_completed)
	Events.bounty_called.connect(_on_bounty_called)
	Events.bounty_claimed.connect(_on_bounty_claimed)
	Events.kart_wounded.connect(_on_kart_wounded)
	Events.life_restored.connect(_on_life_restored)
	Events.announced.connect(_on_announced)


func _on_bounty_called(slot: int) -> void:
	var kart := _kart(slot)
	if kart != null:
		FloatingText.spawn(match_node, kart.global_position, "BOUNTY", Palette.CHIP_GOLD, 56, 1.6)
	_kill_feed.add_line("a bounty on %s" % _slot_name(slot), Palette.CHIP_GOLD)


func _on_bounty_claimed(killer_slot: int, victim_slot: int, amount: int) -> void:
	var kart := _kart(killer_slot)
	if kart != null:
		FloatingText.spawn(
			match_node, kart.global_position, "+%d BOUNTY" % amount, Palette.CHIP_GOLD, 48, 1.4
		)
	_kill_feed.add_line(
		"%s collected %d on %s" % [_slot_name(killer_slot), amount, _slot_name(victim_slot)],
		Palette.CHIP_GOLD
	)


func _on_kart_wounded(slot: int, _by_slot: int, _cause: StringName) -> void:
	var kart := _kart(slot)
	if kart != null:
		FloatingText.spawn(
			match_node, kart.global_position, "-1 LIFE", Color(1.0, 0.4, 0.35), 40, 1.0
		)
	_rumble(slot, 0.6, 0.25)


func _on_life_restored(slot: int) -> void:
	var kart := _kart(slot)
	if kart != null:
		FloatingText.spawn(
			match_node, kart.global_position, "PATCHED UP", Color(0.45, 1.0, 0.55), 40, 1.0
		)


func _on_flush_completed(slot: int) -> void:
	var kart := _kart(slot)
	if kart != null:
		FloatingText.spawn(
			match_node, kart.global_position, "ROYAL FLUSH", Palette.CHIP_GOLD, 64, 1.6
		)


func _on_nitro_gained(slot: int) -> void:
	var kart := _kart(slot)
	if kart != null:
		FloatingText.spawn(
			match_node, kart.global_position, "+NITRO", Color(1.0, 0.75, 0.3), 36, 0.9
		)


func _on_kart_killed(victim_slot: int, killer_slot: int, cause: StringName) -> void:
	_rumble(victim_slot, 1.0, 0.4)
	var victim := _slot_name(victim_slot)
	if victim.is_empty():
		return
	_kill_feed.add_kill(
		victim, _slot_color(victim_slot), _slot_name(killer_slot), _slot_color(killer_slot), cause
	)


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
	Events.flush_completed.disconnect(_on_flush_completed)
	Events.bounty_called.disconnect(_on_bounty_called)
	Events.bounty_claimed.disconnect(_on_bounty_claimed)
	Events.kart_wounded.disconnect(_on_kart_wounded)
	Events.life_restored.disconnect(_on_life_restored)


## Shows a HUD block and the control hint for a human slot. Only for a human at this machine:
## a corner block, a hand of cards and a joker pick are all things somebody here has to be able
## to answer, and a host watching a player on the other end of a wire cannot answer any of them.
func add_block(slot: PlayerSlot) -> void:
	if _blocks.has(slot.index) or not slot.is_local_human():
		return
	_blocks[slot.index] = _make_block(slot)
	var hand := JokerHand.new()
	hand.name = "Hand%d" % slot.index
	hand.kart = slot.kart
	hand.keyboard = slot.device() in [DeviceInput.KEYBOARD, DeviceInput.ANY]
	add_child(hand)
	_hands[slot.index] = hand
	var picker := JokerPicker.new()
	picker.name = "Picker%d" % slot.index
	picker.keyboard = hand.keyboard
	add_child(picker)
	_pickers[slot.index] = picker
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
	_pickers[slot.index].queue_free()
	_pickers.erase(slot.index)
	_layout_hands()


## Hands share the bottom edge in slot order.
func _layout_hands() -> void:
	var indices := _hands.keys()
	indices.sort()
	for i: int in indices.size():
		var hand := _hands[indices[i]]
		hand.column = i
		hand.columns = indices.size()
		var picker := _pickers[indices[i]]
		picker.column = i
		picker.columns = indices.size()


func _process(delta: float) -> void:
	_update_call(delta)
	_update_timer()
	_update_scoreboard()
	_update_blocks()
	_update_banner(delta)
	_update_lobby()


func _update_timer() -> void:
	if not match_node.rules.timed:
		# A room with no clock, such as the Garage: nothing to count down to.
		_timer.visible = false
		return
	var overtime := match_node.state == Match.State.OVERTIME
	if overtime:
		# There is nothing left to count: the clock has run out and the match is still on.
		_timer.text = "OVERTIME"
	else:
		var seconds := ceili(match_node.time_left)
		_timer.text = "%d:%02d" % [seconds / 60, seconds % 60]
	var hot := overtime or match_node.state == Match.State.LAST_CALL
	_timer.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3) if hot else Color.WHITE)


## The running order is for the player watching this screen. In a four-corner shared-screen game
## every player already has their own block and the corners are busy, so it stands down.
func _update_scoreboard() -> void:
	_scoreboard.visible = _blocks.size() <= 2


func _update_blocks() -> void:
	var bottom_blocks: Array[Rect2] = []
	var feed_top := 16.0
	for index: int in _blocks:
		var corner := index % BLOCK_ANCHORS.size()
		var rect := (_blocks[index]["box"] as Control).get_global_rect()
		if corner >= 2:
			bottom_blocks.append(rect)
		elif corner == 1:
			# A player's block owns the top right corner; the feed lines up underneath it.
			feed_top = maxf(feed_top, rect.end.y + 12.0)
	_kill_feed.offset_top = feed_top
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
		var pips: Array = block["lives"]
		for i: int in pips.size():
			var lit := kart.alive and i < kart.lives
			(pips[i] as ColorRect).color = slot.color() if lit else Color(0.22, 0.22, 0.26, 0.9)
		var nitro: ProgressBar = block["nitro"]
		nitro.value = kart.nitro_charge * 100.0
		nitro.modulate = Color(1.0, 0.75, 0.3) if kart.nitro_active else Color(0.85, 0.85, 0.9)
		_update_speed(block, kart)
		_update_hints(block, kart, slot.device())
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
		hand.keyboard = DeviceInput.uses_keyboard(slot.device())
		_pickers[index].keyboard = hand.keyboard
		_pickers[index].show_offer(slot.offer, kart)


## The announcer's call, GAME.md 3.12: the player's name and what they just did, in their own
## colour, under the middle of the screen where the eye already is. It holds and then goes.
func _on_announced(slot: int, call: String) -> void:
	var name_of := _slot_name(slot)
	_call.text = call if name_of.is_empty() else "%s  %s" % [name_of, call]
	_call.add_theme_color_override("font_color", _slot_color(slot))
	_call.visible = true
	_call.modulate.a = 1.0
	_call_left = CALL_TIME


## Held at full for most of its life and then faded, so it is read rather than glimpsed.
func _update_call(delta: float) -> void:
	if _call_left <= 0.0:
		return
	_call_left = maxf(_call_left - delta, 0.0)
	_call.modulate.a = clampf(_call_left / CALL_FADE, 0.0, 1.0)
	_call.visible = _call_left > 0.0


func _update_banner(delta: float) -> void:
	match match_node.state:
		Match.State.COUNTDOWN:
			# A room with no countdown, like the Garage, holds nobody on a grid and gets no
			# gantry and no flag: it is a place to drive around in, not a race being started.
			_banner.visible = false
			_light.visible = match_node.rules.countdown > 0.0
			_light.set_countdown(match_node.countdown_lamps())
			_go_left = 0.8 if match_node.rules.countdown > 0.0 else 0.0
		Match.State.PLAYING:
			_go_left -= delta
			_banner.visible = _go_left > 0.0
			_banner.text = "GO"
			_light.visible = _go_left > 0.0
			_light.set_go()
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
			_light.visible = false


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


## The tally this slot still has in the air, or null when it has none. Read out as a plain
## value first and checked before it is given a type: a slot naming a label that has already
## gone is the ordinary case here, and assigning a freed instance to a typed variable is itself
## the error rather than something a later check could catch.
func _running_tally(slot: int) -> FloatingText:
	var previous: Variant = _tallies.get(slot)
	if previous == null or not is_instance_valid(previous):
		return null
	var label: FloatingText = previous
	# Already on its way out: extending it would put the coins on a label nobody will see.
	return null if label.is_queued_for_deletion() else label


## A cash-out finished. A player parked on the Junction while the Royal Flush pads trickle
## finishes one every second or so, each of a single coin, so a run of them is shown as one
## number climbing rather than as a fresh label, a fresh shower of chips and a fresh thump
## for every coin. The tally goes away on its own once the coins stop arriving.
func _on_bank_completed(slot: int, coins: int, mult: float, total: int) -> void:
	var kart := _kart(slot)
	if kart == null:
		return
	var running := _running_tally(slot)
	if running != null:
		running.extend_to(running.total() + total)
		running.global_position = kart.global_position + Vector3(0.0, 1.2, 0.0)
		return
	var prefix := "%d × %s = " % [coins, _format_mult(mult)]
	var big := total >= 500
	var tally := FloatingText.spawn_counting(
		match_node, kart.global_position, prefix, total, Palette.CHIP_GOLD, 96 if big else 72, 1.8
	)
	_tallies[slot] = tally
	# A tally takes itself off the screen when it has had its time, so the slot lets go of it at
	# the same moment rather than holding the name of something that is not there any more.
	tally.tree_exited.connect(func() -> void: _tallies.erase(slot))
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


## The reminder row under a player's block, GAME.md 8.3: which button drifts, which burns
## The speedometer, GAME.md 8.3: the needle and the number both read whatever the kart is
## actually doing, and both turn the nitro colour while the bottle is lit. A dead kart reads
## zero rather than keeping the speed it died at.
func _update_speed(block: Dictionary, kart: Kart) -> void:
	var dial: ProgressBar = block["speed_dial"]
	var readout: Label = block["speed"]
	var speed := kart.motor.speed() if kart.alive else 0.0
	dial.value = clampf(speed / (kart.stats.top_speed * SPEED_FULL), 0.0, 1.0) * 100.0
	readout.text = "%d km/h" % roundi(speed * SPEED_SCALE)
	var lit := Color(1.0, 0.75, 0.3) if kart.nitro_active else Color(0.85, 0.85, 0.9)
	dial.modulate = lit
	readout.add_theme_color_override("font_color", lit)


## nitro and which plays the item they are holding. Each one only appears while it is worth
## pressing, and they are named for whichever scheme that player last used.
func _update_hints(block: Dictionary, kart: Kart, device: int) -> void:
	var hints: Label = block["hints"]
	if not Game.settings.control_hints or not kart.alive:
		hints.visible = false
		return
	var keyboard := DeviceInput.uses_keyboard(device)
	var parts: PackedStringArray = []
	if kart.motor.speed_fraction() > 0.25:
		parts.append("%s drift" % InputActions.short_binding_text(InputActions.HANDBRAKE, keyboard))
	if kart.nitro_charge >= kart.stats.nitro_min_start:
		parts.append("%s nitro" % InputActions.short_binding_text(InputActions.NITRO, keyboard))
	if kart.held_item != null and kart.item_reveal_left <= 0.0:
		parts.append("%s item" % InputActions.short_binding_text(InputActions.USE_ITEM, keyboard))
	hints.visible = not parts.is_empty()
	hints.text = "   ".join(parts)


func _slot_name(slot: int) -> String:
	if slot < 0 or slot >= match_node.slots.size():
		return ""
	return match_node.slots[slot].display_name()


func _slot_color(slot: int) -> Color:
	if slot < 0 or slot >= match_node.slots.size():
		return KillFeed.NEUTRAL
	return match_node.slots[slot].color()


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
	HudText.shadowed(label, 2)
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
	var lives := HBoxContainer.new()
	lives.add_theme_constant_override("separation", 6)
	lives.alignment = BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	var pips: Array = []
	for i: int in match_node.rules.lives:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(18.0, 18.0)
		pip.color = slot.color()
		lives.add_child(pip)
		pips.append(pip)
	var hints := Label.new()
	hints.add_theme_font_size_override("font_size", 17)
	hints.add_theme_color_override("font_color", Color(0.82, 0.82, 0.88))
	HudText.shadowed(hints, 1)
	hints.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	)
	var nitro := ProgressBar.new()
	nitro.min_value = 0.0
	nitro.max_value = 100.0
	nitro.value = 100.0
	nitro.show_percentage = false
	nitro.custom_minimum_size = Vector2(180.0, 10.0)
	nitro.tooltip_text = "Nitro"
	var speed_dial := ProgressBar.new()
	speed_dial.min_value = 0.0
	speed_dial.max_value = 100.0
	speed_dial.value = 0.0
	speed_dial.show_percentage = false
	speed_dial.custom_minimum_size = Vector2(120.0, 10.0)
	speed_dial.tooltip_text = "Speed"
	speed_dial.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var speed := Label.new()
	speed.text = "0 km/h"
	speed.add_theme_font_size_override("font_size", 19)
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
	var item := Label.new()
	item.add_theme_font_size_override("font_size", 22)
	item.add_theme_color_override("font_color", Palette.NEON_MAGENTA)
	for label: Label in [name_label, banked, pot, stats, item]:
		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
		)
		HudText.shadowed(label)
		box.add_child(label)
	box.add_child(lives)
	box.add_child(nitro)
	box.add_child(speed_row)
	box.add_child(hints)
	return {
		"box": box,
		"banked": banked,
		"pot": pot,
		"stats": stats,
		"lives": pips,
		"nitro": nitro,
		"speed_dial": speed_dial,
		"speed": speed,
		"item": item,
		"hints": hints,
	}


func _build_results() -> void:
	_results = PanelContainer.new()
	_results.name = "Results"
	_results.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_results.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_results.grow_vertical = Control.GROW_DIRECTION_BOTH
	_results.custom_minimum_size = Vector2(900.0, 0.0)
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


## Score and kills for everyone, then up to three awards per player: the stats they stand out
## in most, GAME.md 3.8.
func _show_results() -> void:
	for child: Node in _results_rows.get_children():
		child.queue_free()
	var everyone: Array[PlayerStats] = []
	for slot: PlayerSlot in match_node.slots:
		everyone.append(slot.stats)
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
		var parts: PackedStringArray = []
		for award: Array in PlayerStats.awards(slot.stats, everyone):
			parts.append("%s: %s" % [award[0], award[1]])
		if not parts.is_empty():
			var awards := Label.new()
			awards.text = "      " + "   ·   ".join(parts)
			awards.add_theme_font_size_override("font_size", 17)
			awards.add_theme_color_override("font_color", Color(0.72, 0.72, 0.76))
			awards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			awards.custom_minimum_size = Vector2(840.0, 0.0)
			_results_rows.add_child(awards)
		rank += 1
	_results.visible = true
