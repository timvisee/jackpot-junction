class_name MatchHud
extends CanvasLayer
## The match HUD from GAME.md 8.3: timer, standings, one block per human player, a hand of joker
## cards per human along the bottom, countdown and Last Call banners, in-world floating texts for
## grazes and mult, the tally on cash-out, and the results panel. Reads the match; never changes
## it except through the results and lobby buttons.

## What a meter a second reads as on the speedometer. The karts are small and the arena is a
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
## clock it sits, under the Royal Flush tally, and the size past which one is called out as a snap
## rather than a nudge.
const SYNC_TIME := 1.4
const SYNC_DROP := 116.0
## How far under the top the Royal Flush tally hangs: its cards' tops tucked under the clock's
## board, see [FlushTally].
const TALLY_DROP := ClockBoard.TALL - FlushTally.TUCK
const SYNC_SNAP := 1.0

const CALL_DROP := 120.0
## What is called out when a player's next cash-out would win, after their name the way every call
## is, see [MatchPoint].
const WIN_CALL := "MATCH POINT"
## The flag drops in the gantry's own green; Last Call is a bar's neon sign, see [NeonSign].
const GO_INK := Color("#5fe08a")
## The line under each player's block that says what is worth pressing right now, GAME.md 8.3:
## how big the buttons in it are drawn, what color it is, and the word that goes with each one.
## A life, under the name: how big one heart is drawn and the gray a spent one goes.
## How wide a player's corner block is, whatever is in it. A pane that grows when the speed goes
## from 99 to 100 and shrinks again at the next corner is a pane that never stops moving, and the
## eye follows movement.
##
## Wide enough that the line inside it never asks for more: the pot's own cells do grow to fit
## their numbers, since a mult clipped at 24.5 loses the digit that says what the pot is worth,
## and this is the room they grow into rather than out of.
const BLOCK_WIDTH := 352.0
const LIFE_SIZE := 21.0
const LIFE_LOST := Color(0.22, 0.22, 0.26, 0.9)
## How big a heart is when it floats off a kart that has just lost or been given a life, in
## meters. It started at the width of the words it replaced, which as a shape rather than a line
## of text came out wider than the kart is long and buried it.
const LIFE_ICON := 0.65
## The held item's picture: how big it is drawn, how fast the roulette flicks through the others
## while the box is still opening, and the gray it flicks in.
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

## With three or four players here, each hand keeps to its owner's corner, beside the block and
## clear of the clock, see [method _corner_lane]: how much of the top middle the clock keeps, either
## side of the middle, at its widest, and the room kept between a hand and what it stands beside.
const CLOCK_ROOM := 130.0
const LANE_GAP := 16.0

var match_node: Match
## Set once the room is closing, see [method stand_down]. Nothing is drawn or updated after it.
var dismissed := false
## The waiting room of GAME.md 9.6: nothing is being played for, so the HUD says who is there
## rather than who is winning.
var waiting := false
## How far from the top the kill feed hangs at the least, for a screen with something else in the
## top right corner: the tutorial's checklist, GAME.md 9.4a. Zero for the feed's own place.
var feed_drop := 0.0

var _timer: ClockBoard
var _scoreboard: Scoreboard
var _banner: Label
var _last_call: NeonSign
var _light: StartLight
var _call: CallBanner
## Who has just reached match point, to be called out: see [method _update_winning].
var _match_points := MatchPoint.new()
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
var _start_wait: StartWait
var _lobby_start: Button
## Set while the end of a Grand Prix has the screen, see [method stand_aside].
var _aside := false
var _pot_split: PotSplit
var _go_left := 0.0


func _ready() -> void:
	layer = 5
	# The clock hangs from the top edge on a board of its own, GAME.md 8.1a.
	_timer = ClockBoard.new()
	_timer.name = "Clock"
	_timer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_timer)
	_scoreboard = Scoreboard.new()
	_scoreboard.name = "Scoreboard"
	_scoreboard.match_node = match_node
	add_child(_scoreboard)
	_banner = ScreenReader.live(_label(96, Control.PRESET_CENTER), true) as Label
	_banner.visible = false
	Type.ink(_banner, GO_INK)
	_last_call = NeonSign.new()
	_last_call.name = "LastCall"
	_last_call.text = "LAST CALL"
	_last_call.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_last_call.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_last_call.grow_vertical = Control.GROW_DIRECTION_BOTH
	_last_call.visible = false
	add_child(_last_call)
	_light = StartLight.new()
	_light.name = "StartLight"
	# Above the middle of the screen, so the GO that follows it has the center to itself.
	_light.hang(50.0)
	_light.visible = false
	add_child(_light)
	_call = CallBanner.new()
	_call.name = "Call"
	_call.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_call.offset_top += CALL_DROP
	_call.offset_bottom += CALL_DROP
	add_child(_call)
	_sync = _label(19, Control.PRESET_CENTER_TOP)
	_sync.offset_top = SYNC_DROP
	_sync.visible = false
	FlushTally.add_to(self, TALLY_DROP)
	ShowdownHud.add_to(self)
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human():
			add_block(slot)
	_kill_feed = KillFeed.new()
	_kill_feed.name = "KillFeed"
	_kill_feed.match_node = match_node
	add_child(_kill_feed)
	_results = ResultsScreen.create(self, match_node)
	EmoteWheel.add_to(self, match_node)
	WatcherEmotes.add_to(self, match_node)
	if TouchInput.enabled:
		TouchControls.attach(self)
		TouchEmotes.attach(self)
	else:
		MouseJokers.attach(self)
	_build_lobby()
	_start_wait = StartWait.add_to(self, match_node)
	_pot_split = PotSplit.attach(self)
	BankStream.add_to(self)
	ItemTag.add_to(self)
	CannonJamCue.add_to(self, match_node)
	HudCovers.add_to(self)
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


func _on_bounty_claimed(killer_slot: int, _victim_slot: int, amount: int) -> void:
	var kart := _kart(killer_slot)
	if kart != null:
		FloatingText.spawn(
			match_node, kart.global_position, "+%d BOUNTY" % amount, Palette.CHIP_GOLD, 48, 1.4
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
## happens to be looking at that kart; this says it to the whole room at once. Where the host put
## them rather than where their kart is: on a client this arrives before the snapshot that moves
## the kart there, and the ring used to open over the spot they had died on.
func _on_kart_respawned(slot: int, at: Vector3) -> void:
	if _kart(slot) != null:
		SpawnRing.spawn(match_node, at, _slot_color(slot))


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


## A death felt at this screen; the feed says who and how itself, see [KillFeed].
func _on_kart_killed(victim_slot: int, _killer_slot: int, _cause: StringName) -> void:
	_rumble(victim_slot, 1.0, 0.4)
	# Somebody at this screen going down is heard as the music going under, GAME.md 8.4. Only
	# here: a client hears its own player's death that way, nobody else's.
	if _blocks.has(victim_slot):
		Audio.muffle_music()


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


## Vibrates the gamepad a human slot drives with, when rumble is on, see
## [method PlayerSlot.knocked_pad].
func _rumble(slot: int, strength: float, seconds: float) -> void:
	if not Game.settings.rumble or slot < 0 or slot >= match_node.slots.size():
		return
	var player := match_node.slots[slot]
	var pad := player.knocked_pad() if player.is_local_human() else -1
	if pad >= 0:
		Input.start_joy_vibration(pad, strength * 0.5, strength, seconds)


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
	_blocks[slot.index] = HudBlock.make(self, slot, _free_corner(), match_node.rules.lives)
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
	var seat := ControlHint.seat_of(match_node, slot)
	var hinted := match_node.with_kart_hints and not DemoInput.bot_drives(slot.input)
	if hinted and not TouchInput.enabled and ControlHint.due(seat):
		ControlHint.attach(slot.kart, slot.device())


func remove_block(slot: PlayerSlot) -> void:
	if not _blocks.has(slot.index):
		return
	var block: Dictionary = _blocks[slot.index]
	# Renamed out of the way as they go, so a corner made again in the same frame, as the demo's
	# is for whoever sits down, GAME.md 9.8, has its own names to be found by.
	for gone: Node in [block["box"], _hands[slot.index], _pickers[slot.index]]:
		gone.name = "Gone"
		gone.queue_free()
	_blocks.erase(slot.index)
	_hands.erase(slot.index)
	_pickers.erase(slot.index)
	_layout_hands()


## The lowest corner nobody on this screen is using. Somebody leaving frees theirs for the next
## player to join rather than pushing everybody after them along.
func _free_corner() -> int:
	return maxi(next_corner(), 0)


## The corner the next player to join at this screen would take, or -1 with all four taken.
func next_corner() -> int:
	var taken: Array[int] = []
	for index: int in _blocks:
		taken.append(_blocks[index]["corner"])
	for corner: int in BLOCK_ANCHORS.size():
		if not taken.has(corner):
			return corner
	return -1


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
## The end of a Grand Prix, GAME.md 9.7: everything but the results screen goes, and stays gone,
## so the podium in the room has the screen to itself until the run's standings come up over it.
func stand_aside() -> void:
	_aside = true
	for child: Node in get_children():
		var shown := child as CanvasItem
		if shown != null and child != _results:
			shown.visible = false


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
func _on_corrected(meters: float, snapped: bool) -> void:
	_sync_count += 1
	_sync_left = SYNC_TIME
	_sync.text = (
		"RESYNC %.2f m  (%d)" % [meters, _sync_count]
		if snapped or meters >= SYNC_SNAP
		else "sync %.2f m  (%d)" % [meters, _sync_count]
	)
	# A nudge is worth seeing and not worth worrying about; a snap moved the kart somewhere a
	# player was not expecting and is the one they want to know about.
	_sync.add_theme_color_override(
		"font_color", Palette.CHIP_RED if snapped or meters >= SYNC_SNAP else Palette.CHIP_GOLD
	)


func _update_sync(delta: float) -> void:
	_sync_left = maxf(_sync_left - delta, 0.0)
	_sync.visible = _sync_left > 0.0
	if _sync.visible:
		_sync.modulate.a = clampf(_sync_left / (SYNC_TIME * 0.5), 0.0, 1.0)


func _process(delta: float) -> void:
	if dismissed or _aside:
		return
	_step_podium(delta)
	_update_sync(delta)
	_update_winning(delta)
	_timer.show_time(match_node)
	_update_scoreboard()
	_update_blocks()
	_update_banner(delta)
	_update_lobby()


## A podium that was already up when this screen arrived at it, GAME.md 10.3: there is no whistle
## to wait out, and the host may press on at any moment.
func skip_the_whistle() -> void:
	_podium_wait = 0.0


func _step_podium(delta: float) -> void:
	if not _podium_pending:
		return
	_podium_wait = maxf(_podium_wait - delta, 0.0)
	if _podium_wait <= 0.0:
		_podium_pending = false
		_show_podium()


## The running order is for the player watching this screen. In a four-corner shared-screen game
## every player already has their own block and the corners are busy, so it stands down. So does
## it in a room with no clock and no target, GAME.md 9.4: the Garage is a place to try things in
## and there is nothing to be winning, so a table of who is ahead is a table about nothing. The
## waiting room keeps it, as the list of who is there, GAME.md 9.6.
func _update_scoreboard() -> void:
	_scoreboard.roster = waiting
	_scoreboard.visible = waiting or (match_node.rules.timed and _blocks.size() <= 2)


func _update_blocks() -> void:
	var bottom_blocks: Array[Rect2] = []
	var all_blocks: Array[Rect2] = []
	var feed_top := TouchControls.feed_top(_scoreboard) if TouchInput.enabled else 16.0
	for index: int in _blocks:
		var corner: int = _blocks[index]["corner"]
		var rect := (_blocks[index]["box"] as Control).get_global_rect()
		all_blocks.append(rect)
		if corner >= 2:
			bottom_blocks.append(rect)
		elif corner == 1:
			# A player's block owns the top right corner; the feed lines up under it and its hints.
			feed_top = maxf(feed_top, HudBlock.foot(_blocks[index]) + 12.0)
	_kill_feed.offset_top = maxf(feed_top, feed_drop)
	for index: int in _blocks:
		var slot := match_node.slots[index]
		var block := _blocks[index]
		var banked: Label = block["banked"]
		var pot: ScorePills = block["pot"]
		var stats: Label = block["stats"]
		# The waiting room scores nothing, so a block there says nothing about scoring: no banked
		# chips, no pot, no mult, no kills and deaths. The name, lives, nitro and speed stay, since
		# driving round in there is still driving.
		var kart := slot.kart
		for scoring: Control in [banked, pot, stats]:
			scoring.visible = not waiting
		# Nor a showdown, with no money in its room, GAME.md 9.7a: the pot only to say who is out.
		if match_node.rules.showdown():
			banked.visible = false
			pot.visible = not waiting and not kart.alive
		HudBlock.show_bank(block, slot, match_node.slots)
		if kart.alive:
			pot.show_pot(kart.pot.coins, kart.pot.mult, kart.pot.value())
		elif match_node.rules.showdown():
			pot.say(Showdown.corner_words(slot))
		elif match_node.state == Match.State.OVERTIME:
			# Nobody comes back in sudden death, GAME.md 3.13, so a count would be a count to
			# nothing: it stood still at whatever it had reached when the clock ran out.
			pot.say("waiting on players")
		else:
			pot.say("respawning %.1f" % maxf(slot.respawn_left, 0.0))
		(block["lag"] as LagWarning).show_trip(_round_trip(slot))
		# A pot that would win the match on the next cash-out burns, GAME.md 3.4.
		pot.set_burning(match_node.is_running() and match_node.would_win(slot))
		stats.text = "K %d · D %d" % [slot.kills, slot.deaths]
		var pips := HudBlock.fit_lives(block, slot, KartLives.most(kart))
		for i: int in pips.size():
			var lit := kart.alive and i < kart.lives
			(pips[i] as Heart).color = slot.color() if lit else LIFE_LOST
		var nitro: NitroCells = block["nitro"]
		nitro.value = kart.nitro_charge * 100.0
		nitro.modulate = Color(1.0, 0.75, 0.3) if kart.nitro_active else Color(0.85, 0.85, 0.9)
		HudBlock.follow(block, slot)
		HudBlock.place_bot(block, slot)
		_update_speed(block, kart)
		_update_hints(block, kart, slot.device())
		_update_item(block, kart)
		var hand := _hands[index]
		hand.kart = kart
		hand.avoid = bottom_blocks
		# A touch screen's hand keeps to the lane between the stick and the buttons, GAME.md 4.2.
		if not hand.tucked:
			var cornered := _blocks.size() > 2
			hand.corner = block["corner"] if cornered else -1
			hand.lane = _corner_lane(block, hand.size.x) if cornered else Vector2.ZERO
			if cornered:
				# A lane too narrow for the hand, at a big UI scale, leaves it off every block
				# rather than over its own: under a top one, over a bottom one.
				hand.avoid = all_blocks
			_pickers[index].corner = hand.corner
			_pickers[index].lane = hand.lane
			_pickers[index].ceiling_y = hand.reach() + LANE_GAP
		hand.keyboard = DeviceInput.uses_keyboard(slot.device())
		hand.details = DeviceInput.pressed(InputActions.DETAILS, slot.device())
		_pickers[index].keyboard = hand.keyboard
		_pickers[index].details = hand.details
		var offer: JokerOffer = null if _podium_up else slot.offer
		_pickers[index].show_offer(offer, kart)
		_pickers[index].share_with(hand, _podium_up)


## The stretch of its edge a cornered hand keeps to, from and to: from its owner's block to the
## middle, or at the top to the clock.
func _corner_lane(block: Dictionary, width: float) -> Vector2:
	var corner: int = block["corner"]
	var rect := (block["box"] as Control).get_global_rect()
	var middle := width * 0.5
	var inner := CLOCK_ROOM if corner < 2 else 0.0
	if corner % 2 == 0:
		return Vector2(rect.end.x + LANE_GAP, middle - inner - LANE_GAP)
	return Vector2(middle + inner + LANE_GAP, rect.position.x - LANE_GAP)


## The announcer's call, GAME.md 3.12: the player's name and what they just did, in their own
## color, under the middle of the screen where the eye already is. It holds and then goes.
func _on_announced(slot: int, call: String) -> void:
	var who := _slot_name(slot)
	if call == WIN_CALL and slot < match_node.slots.size() and match_node.slots[slot].team >= 0:
		who = Teams.name_of(match_node.slots[slot].team)
	_call.show_call(who, call, _slot_color(slot), call == WIN_CALL)


## A player getting to where their next cash-out wins the match, GAME.md 3.4, called out on every
## screen, their own, their rivals' and a watcher's: the one moment worth everybody looking up
## for. Seen by each machine from the pots and the banked scores it has, so nothing more is sent.
## Once, and not again for the same player for a while, see [MatchPoint], which the host's count of
## them for the results goes by too.
func _update_winning(delta: float) -> void:
	for index: int in _match_points.step(match_node, delta):
		_on_announced(index, WIN_CALL)


func _update_banner(delta: float) -> void:
	# The gantry is up for the countdown and the moment after it, whatever the match goes on to:
	# a map whose Last Call starts as the flag drops goes straight past playing, and the lamps
	# were only ever put away from there.
	if match_node.state != Match.State.COUNTDOWN:
		_go_left -= delta
		_light.visible = _go_left > 0.0
		_light.set_go()
	match match_node.state:
		Match.State.COUNTDOWN:
			# A room with no countdown, like the Garage, holds nobody on a grid and gets no
			# gantry and no flag: it is a place to drive around in, not a race being started.
			_banner.visible = false
			_last_call.visible = false
			_light.visible = match_node.rules.countdown > 0.0
			_light.set_countdown(match_node.countdown_lamps())
			_go_left = 0.8 if match_node.rules.countdown > 0.0 else 0.0
		Match.State.PLAYING:
			_banner.visible = _go_left > 0.0
			_banner.text = "GO"
			_last_call.visible = false
		Match.State.LAST_CALL:
			# The sign flickers on by itself, and steady for anybody who asked for fewer flashes.
			_banner.visible = false
			_last_call.visible = match_node.time_left > match_node.rules.last_call_duration - 3.0
		_:
			_banner.visible = false
			_last_call.visible = false


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


## A pot split at a death or at the whistle, GAME.md 3.6: shown going where it went, see
## [PotSplit].
func _on_death_banked(slot: int, amount: int, lost: int) -> void:
	_pot_split.play(slot, amount, lost)


## Where [param slot]'s banked score is on this screen, GAME.md 8.3, in its player's corner or on
## its row of the standings, and where a number said about it goes: beside it in the corner, and
## off the side of the standings over the arena, clear of the names. Empty when it is on neither.
func score_spot(slot: int) -> PackedVector2Array:
	if _blocks.has(slot):
		var banked: Label = _blocks[slot]["banked"]
		if banked.is_visible_in_tree():
			# The number as it is about to be written, which the label catches up with on its next
			# frame, rather than the label round it, which runs the width of the corner; and
			# through the corner's own scale, which a rect leaves out.
			var font := banked.get_theme_font(&"font")
			var size := banked.get_theme_font_size(&"font_size")
			var written := str(match_node.slots[slot].banked)
			var run := font.get_string_size(written, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			var place := banked.get_global_transform()
			var middle := place * Vector2(run * 0.5, banked.size.y * 0.5)
			var beside := place * Vector2(run, banked.size.y * 0.5) + Vector2(48.0, 0.0)
			return PackedVector2Array([middle, beside])
	var score := _scoreboard.score_label(slot)
	if score != null and score.is_visible_in_tree():
		var panel := _scoreboard.row_panel(slot)
		var off := panel.get_global_transform() * Vector2(0.0, panel.size.y * 0.5)
		return PackedVector2Array(
			[score.get_global_transform() * (score.size * 0.5), off - Vector2(44.0, 0.0)]
		)
	return PackedVector2Array()


## The reminder row under a player's block, GAME.md 8.3: which button drifts, which burns
## The speedometer, GAME.md 8.3: the needle and the number both read whatever the kart is
## actually doing, and both turn the nitro color while the bottle is lit. A dead kart reads
## zero rather than keeping the speed it died at.
## How slow [param slot]'s line to the host is, in milliseconds, GAME.md 10.3: what the host last
## timed, or on a client, how long it has heard nothing from the host if that is longer, since a
## line gone quiet cannot say how slow it is. Only while the match is running and nobody has
## stopped it, when the host is always talking.
func _round_trip(slot: PlayerSlot) -> float:
	var trip := slot.round_trip
	var talking := match_node.is_running() and not get_tree().paused
	if match_node.puppet and match_node.heard_at >= 0 and talking:
		trip = maxf(trip, Time.get_ticks_msec() - match_node.heard_at)
	return trip


func _update_speed(block: Dictionary, kart: Kart) -> void:
	var dial: SpeedDial = block["speed_dial"]
	var readout: Label = block["speed"]
	var speed := kart.motor.speed() if kart.alive else 0.0
	dial.value = clampf(speed / (kart.stats.top_speed * SPEED_FULL), 0.0, 1.0) * 100.0
	# The unit is the dial's own, written in the gap at its foot, km/h or mph as the settings say.
	var unit := Game.settings.speed_unit()
	dial.unit = SpeedUnits.word(unit)
	readout.text = "%d" % roundi(SpeedUnits.from_kmh(speed * SPEED_SCALE, unit))
	var lit := Color(1.0, 0.75, 0.3) if kart.nitro_active else Color(0.85, 0.85, 0.9)
	dial.modulate = lit
	Type.ink(readout, lit)


## nitro and which plays the item they are holding. Each one only appears while it is worth
## pressing, and they are named for whichever scheme that player last used.
func _update_hints(block: Dictionary, kart: Kart, device: int) -> void:
	var holder: Control = block["hints"]
	# A touch screen's buttons say what they are on them, GAME.md 4.2; keys would be no help.
	if not Game.settings.control_hints or not kart.alive or TouchInput.enabled:
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
		template += "%s " + HINT_WORDS[action] + "   "
	holder.add_child(InputHint.row(template, parts, HINT_INK, HINT_SIZE))


## The held item: its own picture and its name. While the roulette is still turning the picture
## flicks through the other items rather than showing three question marks, which says the same
## thing and says it in the language the rest of the row is in.
func _update_item(block: Dictionary, kart: Kart) -> void:
	(block["item"] as ItemRow).show_kart(kart)


## The pieces of the HUD that the touch controls and the mouse work with, see [TouchControls]
## and [MouseJokers]: kept from when each is made, where they used to find them by name every
## frame, GAME.md 10.7. Null for a slot with none, and for one on its way out.
## The hands of cards at this screen.
func hands() -> Array[JokerHand]:
	var all: Array[JokerHand] = []
	all.assign(_hands.values())
	return all


func hand_of(index: int) -> JokerHand:
	var hand: Variant = _hands.get(index)
	return hand as JokerHand if is_instance_valid(hand) else null


func picker_of(index: int) -> JokerPicker:
	var picker: Variant = _pickers.get(index)
	return picker as JokerPicker if is_instance_valid(picker) else null


## [param index]'s corner of the screen, see [HudBlock].
func block_of(index: int) -> Control:
	var box: Variant = (_blocks.get(index, {}) as Dictionary).get("box")
	return box as Control if is_instance_valid(box) else null


## The pieces of [param index]'s corner block by name, see [method HudBlock.make], or empty.
func block_parts(index: int) -> Dictionary:
	return _blocks.get(index, {})


func scoreboard() -> Scoreboard:
	return _scoreboard


func kill_feed() -> KillFeed:
	return _kill_feed


func _slot_name(slot: int) -> String:
	if slot < 0 or slot >= match_node.slots.size():
		return ""
	return FinalHand.name_of(match_node.slots[slot])


func _slot_color(slot: int) -> Color:
	if slot < 0 or slot >= match_node.slots.size():
		return KillFeed.NEUTRAL
	return match_node.slots[slot].color()


func _kart(slot: int) -> Kart:
	if slot < 0 or slot >= match_node.slots.size():
		return null
	return match_node.slots[slot].kart


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
	# Held on the grid for somebody still building the room, or still choosing which joker to
	# keep, is not the lobby, GAME.md 9.7 and 10.3: there is nothing to start, and [StartWait] and
	# the pick say what is being waited for.
	var held := match_node.loading.y > 0 or JokerKeep.pending(match_node)
	# And the waiting room is a room of its own rather than a match held in its lobby, GAME.md 9.6.
	var in_lobby := match_node.state == Match.State.LOBBY and not held and not waiting
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
