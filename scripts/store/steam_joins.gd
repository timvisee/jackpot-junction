class_name SteamJoins
extends CanvasLayer
## A friend's Steam game, joined when Steam asks, GAME.md 10.8: an invite accepted, Join game in
## the friends list, or the game started by Steam for either. At the menus it is joined at once; in
## a room, a match or another online game the player is asked first, "Leave this match to join
## Ann?", over whatever is up. Made by [Game] from its path with Steam on, so nothing it names is
## compiled with the autoloads, and kept across scenes.

## Over everything a room puts up, the pause menu and the toasts too.
const LAYER := 95

var _question: Control
var _pane: ConfirmPane
## The lobby being joined, until Steam has let this machine in or said why not; 0 for none.
var _joining := 0


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not Store.on():
		return
	Store.steam.lobbies.asked.connect(_on_asked)
	Store.steam.lobbies.entered.connect(_on_entered)
	Store.steam.lobbies.failed.connect(_on_failed)


## Steam asked to join [param lobby]: at once at the menus, or once the player says so.
func _on_asked(lobby: int) -> void:
	var leaving := busy_with(Game.get_tree().current_scene, Net.online())
	if leaving.is_empty():
		join(lobby)
		return
	var whose := Store.steam.lobbies.host_of(lobby)
	_ask(
		"Leave this %s to join %s?" % [leaving, whose if not whose.is_empty() else "a friend"],
		lobby
	)


## What the player would leave to join a friend's game, in a word, or nothing at the menus: a
## match, another online game, or a room of this machine's own.
static func busy_with(scene: Node, online: bool) -> String:
	var path := scene.scene_file_path if scene != null else ""
	if path == Game.MATCH_SCENE:
		return "match"
	if online:
		return "game"
	if scene != null and scene.get("match_node") != null:
		return "room"
	return ""


## Joins [param lobby]: whatever is being played left, the lobby entered, and once Steam has let
## this machine in, the waiting room of the game, connecting to its host.
func join(lobby: int) -> void:
	_put_the_question_away()
	if not Store.on():
		return
	Net.close()
	_joining = lobby
	Store.steam.lobbies.join(lobby)


func _on_entered(lobby: int, host: int) -> void:
	if lobby != _joining:
		return
	_joining = 0
	# What was done in the room left goes into the profiles first, and the seats sat in as other
	# profiles are guests again, as on the way to the title, GAME.md 8.5.
	get_tree().call_group(MatchRecord.GROUP, &"leave")
	Game.settings.unlink_all()
	Game.go_to_waiting(join_config(lobby, host, Store.steam.lobbies.host_of(lobby)))


func _on_failed(why: String) -> void:
	if _joining == 0:
		return
	_joining = 0
	Game.go_to_play_online(why)


## The configuration for joining the Steam game [param lobby], hosted by the account [param host]
## called [param host_name], or [param watching] it.
static func join_config(lobby: int, host: int, host_name: String, watching := false) -> MatchConfig:
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "join"
	config.watching = watching
	var named: Array[String] = [PlayerNames.clean(Game.settings.player_names[0])]
	config.human_names = named
	config.steam = true
	config.steam_lobby = lobby
	config.steam_host = host
	config.steam_name = host_name
	return config


## The configuration for hosting a Steam game, for every friend or [param invite_only].
static func host_config(invite_only := false) -> MatchConfig:
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "host"
	var named: Array[String] = [PlayerNames.clean(Game.settings.player_names[0])]
	config.human_names = named
	config.steam = true
	config.invite_only = invite_only
	return config


## Puts [param question] up over everything, joining [param lobby] on Join.
func _ask(question: String, lobby: int) -> void:
	_put_the_question_away()
	_question = Control.new()
	_question.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_question)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_question.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_question.add_child(middle)
	_pane = ConfirmPane.new()
	middle.add_child(_pane)
	_pane.answered.connect(
		func(yes: bool) -> void:
			if yes:
				join(lobby)
			else:
				_put_the_question_away()
	)
	_pane.ask(question, "Steam asked to join their game.", "Join", "Stay", RoadSign.Kind.QUESTION)


## The question up just now, or null.
func question() -> ConfirmPane:
	return _pane if _question != null else null


func _put_the_question_away() -> void:
	if _question != null:
		_question.queue_free()
		_question = null
		_pane = null
