extends Node3D
## Development harness: a match on Lucky Crossing with a player kart and a scripted dummy, plus
## the debug overlay (F3) and the tuning panel (F4).
##
## User arguments after "++":
##   --players=2          keyboard drives slot 0 and the first gamepad slot 1
##   --bots=3             number of bot karts added after the humans (default 1)
##   --difficulty=hard    bot difficulty: easy, normal or hard
##   --jokers=3           deal the player this many random jokers at the start
##   --menu=1             hold the player's joker menu open on this card, for screenshots
##   --explosion=0.2      a bomb blast next to the player, this many seconds in, for screenshots
## The Game autoload handles --screenshot=<png> and --frames=<n> for any scene. Press J or Start
## on an unused device to join mid-match; F6 deals the player a random joker.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var match_node: Match

var _players := 1
var _bots := 1
var _difficulty := "normal"
var _jokers := 0
var _menu := -1
var _explosion := -1.0


func _ready() -> void:
	_parse_user_args()
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.bot_difficulty = load("res://data/ai/%s.tres" % _difficulty)
	add_child(match_node)
	var inputs: Array[KartInput] = []
	if _players >= 2:
		inputs.append(PlayerInput.new(DeviceInput.KEYBOARD))
		for joypad: int in range(0, _players - 1):
			inputs.append(PlayerInput.new(joypad))
	else:
		inputs.append(PlayerInput.new())
	for i: int in _bots:
		inputs.append(BotInput.new())
	match_node.start(inputs)
	var player := match_node.kart_of(0)
	for i: int in _jokers:
		_deal_joker(player)
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
	overlay.arena_width = match_node.arena.world_size().x
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
