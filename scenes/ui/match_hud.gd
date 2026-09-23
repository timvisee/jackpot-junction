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
## Seconds between two knocks felt in the same pair of hands, GAME.md 4.2.
const KNOCK_INTERVAL := 0.3
## The speed the dial is full at: a kart flat out on nitro, so the needle has somewhere to go
## when the bottle is lit.
const SPEED_FULL := 1.9
## The announcer's call: how far under the middle of the screen it sits, how long it holds and
## how much of that is the fade. It shares the middle with the start gantry and the GO, neither
## of which is up while anybody is being killed.
## The sync light, GAME.md 8.3: how long one correction stays on the screen, how far under the
## clock it sits, and the size past which one is called out as a snap rather than a nudge.
const SYNC_TIME := 1.4
const SYNC_DROP := 58.0
const SYNC_SNAP := 1.0

const CALL_DROP := 120.0
const CALL_TIME := 2.2
const CALL_FADE := 0.6
## The line under each player's block that says what is worth pressing right now, GAME.md 8.3:
## how big the buttons in it are drawn, what colour it is, and the word that goes with each one.
## A life, under the name: how big one heart is drawn and the grey a spent one goes.
## How wide a player's corner block is, whatever is in it. A pane that grows when the speed goes
## from 99 to 100 and shrinks again at the next corner is a pane that never stops moving, and the
## eye follows movement. Everything in it is clipped to this rather than measured from its text.
const BLOCK_WIDTH := 316.0
const LIFE_SIZE := 19.0
const LIFE_LOST := Color(0.22, 0.22, 0.26, 0.9)
## How big a heart is when it floats off a kart that has just lost or been given a life, in
## metres. It started at the width of the words it replaced, which as a shape rather than a line
## of text came out wider than the kart is long and buried it.
const LIFE_ICON := 0.65
## The held item's picture: how big it is drawn, how fast the roulette flicks through the others
## while the box is still opening, and the grey it flicks in.
const HINT_SIZE := 17
const HINT_INK := Color(0.82, 0.82, 0.88)
const HINT_WORDS: Dictionary[StringName, String] = {
	InputActions.HANDBRAKE: "drift",
	InputActions.NITRO: "nitro",
	InputActions.USE_ITEM: "item",
}
## How long the whistle is left to itself before the podium comes up, GAME.md 3.8. Long enough
## for the karts to roll to a halt and for the rig to find the winner, which is the end of the
## match; a scoreboard thrown over the top of that takes it away from the people in it.
const PODIUM_DELAY := 2.5

## Which corner the first, second, third and fourth block on this screen take. The order is by
## who is sitting here, not by slot number: online, a lone client may well be slot 2, and its one
## player still wants the corner a lone player always gets rather than the one their seat at the
## table happens to be numbered.
const BLOCK_ANCHORS: Array[int] = [
	Control.PRESET_TOP_LEFT,
	Control.PRESET_TOP_RIGHT,
	Control.PRESET_BOTTOM_LEFT,
	Control.PRESET_BOTTOM_RIGHT
]

var match_node: Match
## Set once the room is closing, see [method stand_down]. Nothing is drawn or updated after it.
var dismissed := false

var _timer: Label
var _scoreboard: Scoreboard
var _banner: Label
var _light: StartLight
var _call: Label
var _call_left := 0.0
## The sync light and what is left of its moment, and how many corrections there have been in all.
var _sync: Label
var _sync_left := 0.0
var _sync_count := 0
var _blocks: Dictionary[int, Dictionary] = {}
## The cash-out tally each slot has in the air, so a run of them climbs one number.
var _tallies: Dictionary[int, FloatingText] = {}
var _hands: Dictionary[int, JokerHand] = {}
## Seconds left of the pause between the whistle and the podium, and whether one is running.
var _podium_wait := 0.0
var _podium_pending := false
## Whether the podium is up. A joker pick is a question about a match still being played, so once
## this one is decided the pickers go and are not offered anything again.
var _podium_up := false
var _pickers: Dictionary[int, JokerPicker] = {}
var _kill_feed: KillFeed
## When each slot last felt a knock, so a scrape along a wall is one nudge rather than a buzz.
var _knocked: Dictionary[int, float] = {}
var _results: ResultsScreen
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
	_sync = _label(19, Control.PRESET_CENTER_TOP)
	_sync.offset_top = SYNC_DROP
	_sync.visible = false
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human():
			add_block(slot)
	_kill_feed = KillFeed.new()
	_kill_feed.name = "KillFeed"
	add_child(_kill_feed)
	_results = ResultsScreen.create(self, match_node)
	_build_lobby()
	Events.kart_corrected.connect(_on_corrected)
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
	Events.kart_respawned.connect(_on_kart_respawned)
	Events.kart_crashed.connect(_on_kart_crashed)
	Events.kart_bumped.connect(_on_kart_bumped)


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
		# A heart coming apart rather than the words "-1 LIFE", GAME.md 3.6: a player reading
		# two words over their own kart is a player not driving it.
		FloatingIcon.spawn(
			match_node,
			kart.global_position,
			Heart.broken_shapes(),
			Color(1.0, 0.4, 0.35),
			LIFE_ICON,
			1.0
		)
	_rumble(slot, 0.6, 0.25)


## Somebody is back on the floor, GAME.md 3.6. A blinking kart says something to whoever
## happens to be looking at that kart; this says it to the whole room at once.
func _on_kart_respawned(slot: int) -> void:
	var kart := _kart(slot)
	if kart != null:
		SpawnRing.spawn(match_node, kart.global_position, _slot_color(slot))


func _on_life_restored(slot: int) -> void:
	var kart := _kart(slot)
	if kart != null:
		var whole: Array[PackedVector2Array] = [Heart.unit_shape()]
		FloatingIcon.spawn(
			match_node, kart.global_position, whole, Color(0.45, 1.0, 0.55), LIFE_ICON, 1.0
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


## Hitting a wall, GAME.md 4.2: a knock in the hands as well as a noise, as hard as the hit was.
func _on_kart_crashed(slot: int, force: float) -> void:
	_knock(slot, 0.25 + 0.65 * force)


## Running into another kart, or bouncing off a box, which the wall response covers as well.
func _on_kart_bumped(slot: int) -> void:
	_knock(slot, 0.4)


## One nudge for a knock. Grinding along a wall or another kart reports contact on every tick it
## is touching, and a pad buzzing continuously is a pad nobody can feel anything else through.
func _knock(slot: int, strength: float) -> void:
	var now := Time.get_ticks_msec() * 0.001
	if now - float(_knocked.get(slot, -INF)) < KNOCK_INTERVAL:
		return
	_knocked[slot] = now
	_rumble(slot, strength, 0.18)


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
	# Leaving the podium for the title or the lobby: the music comes back up with the screen.
	Audio.duck_music(false)
	Events.kart_corrected.disconnect(_on_corrected)
	Events.kart_killed.disconnect(_on_kart_killed)
	Events.kart_respawned.disconnect(_on_kart_respawned)
	Events.kart_crashed.disconnect(_on_kart_crashed)
	Events.kart_bumped.disconnect(_on_kart_bumped)
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
	_blocks[slot.index] = _make_block(slot, _free_corner())
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
	if match_node.with_kart_hints:
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


## The lowest corner nobody on this screen is using. Somebody leaving frees theirs for the next
## player to join rather than pushing everybody after them along.
func _free_corner() -> int:
	var taken: Array[int] = []
	for index: int in _blocks:
		taken.append(_blocks[index]["corner"])
	for corner: int in BLOCK_ANCHORS.size():
		if not taken.has(corner):
			return corner
	return 0


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


## Takes the whole HUD off the screen and keeps it off. For the moment a match stops being
## something anybody can answer: the host has gone and this room is closing. A joker pick left
## open under the notice would be asking a player to choose a card for a match that is not there
## any more, and the standings would be a scoreboard for a game nobody is playing.
func stand_down() -> void:
	dismissed = true
	# The whole layer goes, rather than each thing on it. Anything that shows itself later from a
	# signal rather than from the frame loop is then already covered, and there is no way for one
	# straggler to appear over the notice.
	visible = false
	# The control hints are not on this layer: they hang off the karts, out in the room. They are
	# telling a player which key drives a kart nobody can drive any more.
	for slot: PlayerSlot in match_node.slots:
		if slot.kart == null:
			continue
		for child: Node in slot.kart.get_children():
			var hint := child as ControlHint
			if hint != null:
				hint.visible = false


## The sync light, GAME.md 8.3. Online a client drives its own kart and the host puts it right
## where the two disagree; this says when that happened and how far it moved the kart, so a
## player can tell a bad connection from a bad kart. Nothing shows it in a match played here,
## because nothing corrects a kart nobody is predicting.
func _on_corrected(metres: float, snapped: bool) -> void:
	_sync_count += 1
	_sync_left = SYNC_TIME
	_sync.text = (
		"RESYNC %.2f m  (%d)" % [metres, _sync_count]
		if snapped or metres >= SYNC_SNAP
		else "sync %.2f m  (%d)" % [metres, _sync_count]
	)
	# A nudge is worth seeing and not worth worrying about; a snap moved the kart somewhere a
	# player was not expecting and is the one they want to know about.
	_sync.add_theme_color_override(
		"font_color", Palette.CHIP_RED if snapped or metres >= SYNC_SNAP else Palette.CHIP_GOLD
	)


func _update_sync(delta: float) -> void:
	_sync_left = maxf(_sync_left - delta, 0.0)
	_sync.visible = _sync_left > 0.0
	if _sync.visible:
		_sync.modulate.a = clampf(_sync_left / (SYNC_TIME * 0.5), 0.0, 1.0)


func _process(delta: float) -> void:
	if dismissed:
		return
	_step_podium(delta)
	_update_sync(delta)
	_update_call(delta)
	_update_timer()
	_update_scoreboard()
	_update_blocks()
	_update_banner(delta)
	_update_lobby()


func _step_podium(delta: float) -> void:
	if not _podium_pending:
		return
	_podium_wait = maxf(_podium_wait - delta, 0.0)
	if _podium_wait <= 0.0:
		_podium_pending = false
		_show_podium()


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
## every player already has their own block and the corners are busy, so it stands down. So does
## it in a room with no clock and no target, GAME.md 9.4: the Garage is a place to try things in
## and there is nothing to be winning, so a table of who is ahead is a table about nothing.
func _update_scoreboard() -> void:
	_scoreboard.visible = match_node.rules.timed and _blocks.size() <= 2


func _update_blocks() -> void:
	var bottom_blocks: Array[Rect2] = []
	var feed_top := 16.0
	for index: int in _blocks:
		var corner: int = _blocks[index]["corner"]
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
		var pot: ScorePills = block["pot"]
		var stats: Label = block["stats"]
		banked.text = str(slot.banked)
		var kart := slot.kart
		if kart.alive:
			pot.show_pot(kart.pot.coins, kart.pot.mult, kart.pot.value())
		else:
			pot.say("respawning %.1f" % maxf(slot.respawn_left, 0.0))
		stats.text = "K %d  D %d" % [slot.kills, slot.deaths]
		var pips: Array = block["lives"]
		for i: int in pips.size():
			var lit := kart.alive and i < kart.lives
			(pips[i] as Heart).color = slot.color() if lit else LIFE_LOST
		var nitro: ProgressBar = block["nitro"]
		nitro.value = kart.nitro_charge * 100.0
		nitro.modulate = Color(1.0, 0.75, 0.3) if kart.nitro_active else Color(0.85, 0.85, 0.9)
		_update_speed(block, kart)
		_update_hints(block, kart, slot.device())
		_update_item(block, kart)
		var hand := _hands[index]
		hand.kart = kart
		hand.avoid = bottom_blocks
		hand.keyboard = DeviceInput.uses_keyboard(slot.device())
		_pickers[index].keyboard = hand.keyboard
		var offer: JokerOffer = null if _podium_up else slot.offer
		_pickers[index].show_offer(offer, kart)


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
	if dismissed:
		return
	if state == Match.State.RESULTS:
		# The whistle is not the podium, GAME.md 3.8. The karts roll to a halt and the rig swings
		# onto the winner, and only then does the screen come up: a scoreboard thrown over the
		# top of a kart still rolling takes the end of the match away from the people in it.
		# A host saying it again while the screen is already up is a repeat, not a second ending.
		if _results.visible:
			_results.fill_in()
		else:
			_podium_pending = true
			_podium_wait = PODIUM_DELAY
		return
	_podium_pending = false
	_results.visible = false
	Audio.duck_music(false)
	for hand: JokerHand in _hands.values():
		hand.visible = true


## The end of the pause: the music steps back and the podium comes up into the room it leaves.
func _show_podium() -> void:
	Audio.duck_music(true)
	_podium_up = true
	_results.fill_in()
	# The hand of cards is for a match being played. Once the podium is up it is a row of jokers
	# lying across the bottom of the standings, for a match that is already decided.
	for hand: JokerHand in _hands.values():
		hand.visible = false
	# And a pick left open over the standings is a question about nothing: the match it was going
	# to matter in is the one that has just finished.
	for picker: JokerPicker in _pickers.values():
		picker.show_offer(null, null)


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
	var holder: Control = block["hints"]
	if not Game.settings.control_hints or not kart.alive:
		holder.visible = false
		return
	var keyboard := DeviceInput.uses_keyboard(device)
	var wanted: Array[StringName] = []
	if kart.motor.speed_fraction() > 0.25:
		wanted.append(InputActions.HANDBRAKE)
	if kart.nitro_charge >= kart.stats.nitro_min_start:
		wanted.append(InputActions.NITRO)
	if kart.held_item != null and kart.item_reveal_left <= 0.0:
		wanted.append(InputActions.USE_ITEM)
	holder.visible = not wanted.is_empty()
	# Rebuilt only when the line actually changes: it is a row of drawn buttons rather than a
	# string, and it is looked at every frame by every player on this screen.
	var stamp := "%s|%s" % [keyboard, ",".join(wanted)]
	if block["hint_stamp"] == stamp:
		return
	block["hint_stamp"] = stamp
	for child: Node in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	if wanted.is_empty():
		return
	var parts: Array = []
	var template := ""
	for action: StringName in wanted:
		parts.append(InputHint.glyph(action, keyboard, HINT_INK, HINT_SIZE))
		template += "%s " + HINT_WORDS[action] + " "
	holder.add_child(InputHint.row(template, parts, HINT_INK, HINT_SIZE))


## The held item: its own picture and its name. While the roulette is still turning the picture
## flicks through the other items rather than showing three question marks, which says the same
## thing and says it in the language the rest of the row is in.
func _update_item(block: Dictionary, kart: Kart) -> void:
	(block["item"] as ItemRow).show_kart(kart)


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


## The scrim behind a player's corner: a dark card with rounded corners and no edge, soft enough
## that it reads as shade rather than as a panel.
func _scrim() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.05, 0.34)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 12.0
	return style


## One of the slim bars in a block: the nitro tank and the speedometer. Rounded, thin, and in
## the colour of whatever it is measuring.
func _bar(size: Vector2, ink: Color) -> ProgressBar:
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


func _format_mult(mult: float) -> String:
	return ScorePills.mult_text(mult)


func _label(size: int, preset: int) -> Label:
	var label := Label.new()
	Type.set_font(label, Type.numbers_font(), size)
	HudText.shadowed(label, 2)
	label.set_anchors_and_offsets_preset(preset)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	return label


func _make_block(slot: PlayerSlot, corner: int) -> Dictionary:
	# A corner of numbers over a table that is felt one moment and a white block the next needs
	# something to sit on, GAME.md 8.3. A scrim rather than a panel: enough to hold the text
	# together, not so much that the arena has a box cut out of it.
	var card := PanelContainer.new()
	card.name = "Block%d" % slot.index
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _scrim())
	card.custom_minimum_size = Vector2(BLOCK_WIDTH, 0.0)
	card.set_anchors_and_offsets_preset(BLOCK_ANCHORS[corner])
	var right := corner % 2 == 1
	var bottom := corner >= 2
	card.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	card.offset_left = -16.0 if right else 16.0
	card.offset_right = -16.0 if right else 16.0
	card.offset_top = -16.0 if bottom else 16.0
	card.offset_bottom = -16.0 if bottom else 16.0
	add_child(card)
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
	for i: int in match_node.rules.lives:
		var pip := Heart.new()
		pip.custom_minimum_size = Vector2(LIFE_SIZE, LIFE_SIZE)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.color = slot.color()
		lives.add_child(pip)
		pips.append(pip)
	# A row rather than a line of text: the buttons in it are drawn, GAME.md 8.3. It fills the
	# block so the pictures line up with the writing above them on either side of the screen.
	var hints := HBoxContainer.new()
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hints.alignment = BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	var nitro := _bar(Vector2(180.0, 8.0), slot.color())
	nitro.value = 100.0
	nitro.tooltip_text = "Nitro"
	var speed_dial := _bar(Vector2(120.0, 6.0), Color(0.82, 0.82, 0.88))
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
	# What is in hand and what is running, GAME.md 8.3: one thing in one place, see [ItemRow].
	for label: Label in [name_label, banked, stats]:
		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
		)
		# Clipped rather than measured: a label that asks for the width of its own text is what
		# made the block breathe in and out with the speedometer.
		label.clip_text = true
		HudText.shadowed(label)
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
	}


## The online lobby, GAME.md 9.3: who is here, how to join, and the host's Start button.
func _build_lobby() -> void:
	_lobby = MenuTheme.pane()
	_lobby.name = "Lobby"
	_lobby.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_lobby.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_lobby.grow_vertical = Control.GROW_DIRECTION_BOTH
	_lobby.custom_minimum_size = Vector2(620.0, 0.0)
	_lobby.visible = false
	add_child(_lobby)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_lobby.add_child(column)
	column.add_child(MenuTheme.title("Online lobby", 44))
	_lobby_hint = Label.new()
	Type.set_font(_lobby_hint, Type.TEXT, Type.LABEL)
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
