extends Node3D
## The playable match: environment, a [Match] built from the pending [MatchConfig], and the
## pause menu. Falls back to one human against three bots when started directly.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var match_node: Match
var config: MatchConfig


func _ready() -> void:
	config = Game.pending_config if Game.pending_config != null else MatchConfig.new()
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.rules = config.rules(
		match_node.rules if match_node.rules != null else load("res://data/match/default.tres")
	)
	match_node.bot_difficulty = load("res://data/ai/%s.tres" % config.difficulty)
	add_child(match_node)
	match_node.start(config.inputs())
	var pause := PauseMenu.new()
	pause.name = "PauseMenu"
	add_child(pause)
