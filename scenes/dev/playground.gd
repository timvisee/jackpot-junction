extends Node3D
## Development harness: a match on Lucky Crossing with a player kart and a scripted dummy, plus
## the debug overlay (F3) and the tuning panel (F4).
##
## User arguments after "++":
##   --players=2          keyboard drives slot 0 and the first gamepad slot 1
##   --seats=2            this many players at this screen, the ones past the first on pads that
##                        are not there, sitting still: for screenshots of a shared screen
##   --bots=3             number of bot karts added after the humans (default 1, up to 7)
##   --difficulty=hard    bot difficulty: easy, normal or hard
##   --jokers=3           deal the player this many random jokers at the start
##   --menu=1             hold the player's joker menu open on this card, for screenshots
##   --explosion=0.2      a bomb blast next to the player, this many seconds in, for screenshots
##   --flame=1            show the player's nitro flame, for screenshots
##   --oil=1              drop an oil stain next to the player, for screenshots
##   --burst=1            pop a destruction burst next to the player, for screenshots
##   --feed=1             put a few made-up kills in the kill feed, for screenshots
##   --offer=1            open the respawn joker pick, for screenshots
##   --destroy=1          open the pick with a full hand, on the destroy step
##   --disco=4            hold the excitement level here, 1 to 6, for the lights and the music
##   --clean=1            hide the debug overlay, for screenshots of the game itself
##   --bounty=1           put a bounty on the second slot, for screenshots
##   --banked=1           spread some banked score across the field, for the score tanks
##   --results=1          end the match at once with made-up stats, to see the results screen
##   --fireworks=1        the winner's fireworks over the open-out camera, for screenshots
##   --loading=1          hold the lamps as if two players were still building the room
##   --finale=1           end a made-up two-map Grand Prix and stage its finale
##   --wide=1             hold the camera on the whole room, so two shots can be compared
##   --back=200           hold the camera that many meters back, to look at the room itself
##   --map=vault          which map to play, by id (default lucky_crossing)
## The Game autoload handles --screenshot=<png> and --frames=<n> for any scene. Press J or Start
## on an unused device to join mid-match; F6 deals the player a random joker.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## The first of the pads the players of `--seats` sit at: past any real pad, so none of them is
## ever unplugged under them and handed to a bot.
const NO_PAD := 16

var match_node: Match

var _players := 1
var _seats := 1
var _bots := 1
var _difficulty := "normal"
var _jokers := 0
var _menu := -1
var _explosion := -1.0
var _flame := false
var _oil := false
var _burst := false
var _feed := false
var _offer := false
var _destroy := false
var _disco := 0
var _clean := false
var _bounty := false
var _banked := false
var _results := false
var _fireworks := false
var _loading := false
var _finale := false
var _wide := false
var _back := 0.0
var _map := &"lucky_crossing"


func _ready() -> void:
	_parse_user_args()
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.bot_difficulty = load("res://data/ai/%s.tres" % _difficulty)
	match_node.arena_layout = ArenaMaps.layout(_map)
	add_child(match_node)
	var inputs: Array[KartInput] = []
	if _seats >= 2:
		inputs.append(PlayerInput.new(DeviceInput.KEYBOARD, 0))
		for seat: int in range(1, _seats):
			inputs.append(PlayerInput.new(NO_PAD + seat, seat))
	elif _players >= 2:
		inputs.append(PlayerInput.new(DeviceInput.KEYBOARD, 0))
		for joypad: int in range(0, _players - 1):
			inputs.append(PlayerInput.new(joypad, joypad + 1))
	else:
		inputs.append(PlayerInput.new(DeviceInput.ANY, 0))
	for i: int in _bots:
		inputs.append(BotInput.new())
	# Dressed as the settings say, GAME.md 4.4, so a screenshot of this room shows what a player
	# actually drives rather than the kart as it comes.
	var styles: Array = [Game.settings.kart_styles[0]]
	# As many karts as were asked for, up to a room of eight, GAME.md 9.3.
	match_node.rules = match_node.rules.duplicate()
	match_node.rules.max_players = maxi(match_node.rules.max_players, inputs.size())
	# A showdown on its map, GAME.md 9.7a, as a debug build's quick match on it is.
	match_node.rules.map = _map
	Showdown.dress(match_node)
	match_node.hold_start = _loading
	match_node.start(inputs, 0, [], [], styles)
	# Kit's notes, as a map has them, so `++ --story-note=N` can lay one down here, STORY.md 7.1.
	NoteDealer.add_to(match_node)
	# What is pinned in the loyalty program by the clock, as a map has it, GAME.md 8.9: nothing
	# without a pin, which `++ --loyalty-pin=<id>` puts there.
	PinnedStrip.add_to(match_node)
	if _loading:
		# What the host shows while it holds the lamps, GAME.md 10.3, without a network.
		match_node.loading = Vector2i(2, 4)
	var player := match_node.kart_of(0)
	for i: int in _jokers:
		_deal_joker(player)
	if _banked:
		# A field part way through a match, so the tanks of GAME.md 8.1 have something in them.
		var spread: Array[int] = [820, 1750, 2450, 400]
		for i: int in match_node.slots.size():
			match_node.slots[i].banked = spread[i % spread.size()]
	if _bounty:
		# Straight on, without waiting for the countdown and the leader check.
		match_node.slots[1].banked = 900
		match_node.bounty_slot = 1
		match_node.bounty_left = 999.0
		match_node.kart_of(1).set_bounty(true)
	if _destroy:
		var full := match_node.slots[0]
		for id: String in ["hair_trigger", "big_tank", "comeback", "toll_booth", "road_rage"]:
			full.kart.jokers.add(load("res://data/jokers/%s.tres" % id))
		var pick := match_node.joker_catalog.offer(match_node.rng, 3, [])
		full.offer = JokerOffer.new(full.kart, pick)
		full.offer.take(1)
		full.offer.selected = 2
	if _offer:
		var slot := match_node.slots[0]
		var choices := match_node.joker_catalog.offer(match_node.rng, 3, [])
		slot.offer = JokerOffer.new(slot.kart, choices)
		slot.offer.selected = 1
	if _feed:
		var made_up: Array[Array] = [
			[1, 0, &"bullet"], [2, 1, &"ram"], [3, -1, &"pit"], [0, 3, &"bomb"], [1, 2, &"turret"]
		]
		for pair: Array in made_up:
			Events.kart_killed.emit(pair[0], pair[1], pair[2])
	if _burst:
		Burst.spawn(
			match_node, player.global_position + Vector3(3.0, 0.0, 0.5), Palette.player_color(0)
		)
		Burst.spawn(
			match_node, player.global_position + Vector3(6.0, 0.0, 2.5), Palette.BLOCK, 0.9, 18
		)
	if _oil:
		var stain := OilStain.new()
		match_node.add_child(stain)
		stain.global_position = player.global_position + Vector3(2.5, 0.0, 1.5)
	if _fireworks:
		# The whistle's own view, GAME.md 8.3: the camera open on the room and the show over it.
		Fireworks.celebrate(match_node, match_node.arena.bounds(), Palette.player_color(0), 30.0)
		match_node.camera_rig.show_the_room(30.0)
	if _back > 0.0:
		# Further out than the game ever goes, which is the only way to see whether the room the
		# table stands in holds up from the side as well as from above.
		match_node.camera_rig.follow_close(_back)
	if _wide:
		# The whole room, held: two screenshots of the same room are only worth holding against
		# each other if the camera was in the same place for both.
		match_node.camera_rig.show_the_room(120.0)
	if _results:
		var counter := 0
		for slot: PlayerSlot in match_node.slots:
			for field: StringName in PlayerStats.FIELDS:
				slot.stats.add(field, float((counter * 7 + slot.index * 13) % 40))
				counter += 1
			slot.banked = 900 - slot.index * 250
			slot.kills = 3 - slot.index
		match_node._finish()
	if _finale:
		_stage_the_finale()
	if _explosion >= 0.0:
		var blast := Explosion.spawn(
			match_node, player.global_position + Vector3(3.0, 0.0, 2.0), Bomb.RADIUS, Color.WHITE
		)
		blast._age = _explosion
		blast.frozen = true
		var bomb := Bomb.new()
		bomb.color = Palette.player_color(0)
		match_node.add_child(bomb)
		bomb.global_position = player.global_position + Vector3(3.0, 0.0, -1.5)
	var overlay := DebugOverlay.new()
	overlay.kart = player
	overlay.match_node = match_node
	overlay.arena_width = match_node.arena.world_size().x
	# Screenshots of the game want the game, not the instruments.
	overlay.visible = not _clean
	add_child(overlay)
	var tuning := TuningPanel.new()
	tuning.stats = player.base_stats
	tuning.cannon_stats = player.base_cannon_stats
	tuning.on_change = _rebuild_all_karts
	add_child(tuning)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.physical_keycode != KEY_F6:
		return
	_deal_joker(match_node.kart_of(0))
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _disco > 0:
		var share := float(_disco - 1) / float(MatchIntensity.LEVELS - 1)
		match_node.intensity.level = _disco
		match_node.intensity.value = share
		var lights := match_node.arena.disco
		lights.level = _disco
		# Settled at once: a screenshot cannot wait out the rig easing between levels.
		lights._smooth = share
		Audio.set_excitement(_disco, share)
	if _flame:
		match_node.kart_of(0)._flame.set_active(true)
	if _menu < 0:
		return
	var player := match_node.kart_of(0)
	player.menu_open = player.jokers.count() > 0
	player.menu_index = clampi(_menu, 0, maxi(player.jokers.count() - 1, 0))


## Hands the kart a random joker it does not hold yet, when it has room.
func _deal_joker(kart: Kart) -> void:
	if kart.jokers.is_full():
		return
	var choices := match_node.joker_catalog.offer(match_node.rng, 1, kart.jokers.ids())
	if not choices.is_empty():
		kart.jokers.add(choices[0])


## Live tuning edits the shared resources; every kart re-copies them.
func _rebuild_all_karts() -> void:
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null and slot.kart.alive:
			slot.kart.rebuild_stats()


func _parse_user_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--players="):
			_players = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seats="):
			_seats = clampi(int(arg.get_slice("=", 1)), 1, 4)
		elif arg.begins_with("--bots="):
			_bots = int(arg.get_slice("=", 1))
		elif arg.begins_with("--difficulty="):
			_difficulty = arg.get_slice("=", 1)
		elif arg.begins_with("--jokers="):
			_jokers = int(arg.get_slice("=", 1))
		elif arg.begins_with("--menu="):
			_menu = int(arg.get_slice("=", 1))
		elif arg.begins_with("--explosion="):
			_explosion = float(arg.get_slice("=", 1))
		elif arg.begins_with("--flame="):
			_flame = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--oil="):
			_oil = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--burst="):
			_burst = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--feed="):
			_feed = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--offer="):
			_offer = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--destroy="):
			_destroy = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--clean="):
			_clean = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--disco="):
			_disco = int(arg.get_slice("=", 1))
		elif arg.begins_with("--bounty="):
			_bounty = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--banked="):
			_banked = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--results="):
			_results = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--fireworks="):
			_fireworks = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--loading="):
			_loading = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--finale="):
			_finale = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--wide="):
			_wide = arg.get_slice("=", 1) == "1"
		elif arg.begins_with("--back="):
			_back = float(arg.get_slice("=", 1))
		elif arg.begins_with("--map="):
			_map = StringName(arg.get_slice("=", 1))


## The last map of a made-up Grand Prix of two, scored, whistled and on to its finale the way the
## podium's arrow on to the standings goes there, GAME.md 9.7.
func _stage_the_finale() -> void:
	var run := GrandPrix.start(2, match_node.rng)
	for map: int in 2:
		for slot: PlayerSlot in match_node.slots:
			slot.banked = 300 * (slot.index + 1) if map == 0 else 900 - slot.index * 200
		run.score(match_node.standings())
		if map == 0:
			run.advance()
	Game.grand_prix = run
	match_node.rules.rounds = 2
	match_node.rules.round = 2
	match_node._finish()
	match_node.hud._results._on_standings()
