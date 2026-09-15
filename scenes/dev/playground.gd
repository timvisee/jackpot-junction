extends Node3D
## Development harness: a match on Lucky Crossing with a player kart and a scripted dummy, plus
## the debug overlay (F3) and the tuning panel (F4).
##
## User arguments after "++":
##   --players=2          keyboard drives slot 0 and the first gamepad slot 1
##   --bots=3             number of bot karts added after the humans (default 1)
##   --difficulty=hard    bot difficulty: easy, normal or hard
## The Game autoload handles --screenshot=<png> and --frames=<n> for any scene.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var match_node: Match

var _players := 1
var _bots := 1
var _difficulty := "normal"


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
	var overlay := DebugOverlay.new()
	overlay.kart = player
	overlay.arena_width = match_node.arena.world_size().x
	add_child(overlay)
	var tuning := TuningPanel.new()
	tuning.stats = player.base_stats
	tuning.on_change = player.rebuild_stats
	add_child(tuning)


func _parse_user_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--players="):
			_players = int(arg.get_slice("=", 1))
		elif arg.begins_with("--bots="):
			_bots = int(arg.get_slice("=", 1))
		elif arg.begins_with("--difficulty="):
			_difficulty = arg.get_slice("=", 1)
