class_name SteamJoins
extends CanvasLayer
## A friend's Steam game, joined when Steam asks, GAME.md 10.8: an invite accepted, Join game in
## the friends list, or the game started by Steam for either. At the menus it is joined at once; in
## a room, a match or another online game the player is asked first, "Leave this match to join
## Ann?", over whatever is up. And Steam's overlay opened over a room of this machine's own pauses
## it, as the pause menu does; online nothing pauses. Made by [Game] from its path with Steam on, so
## nothing it names is compiled with the autoloads, and kept across scenes.

## Over everything a room puts up, the pause menu and the toasts too.
const LAYER := 95
## The group it is in, for the screens that join a friend's game through it.
const GROUP := &"steam_joins"

## Where joining waits on Steam, saying what it waits on: Play Online, out of whatever room was
## up, unless a test says otherwise.
var wait_on: Callable = Game.go_to_play_online

var _question: Control
var _pane: ConfirmPane
## The lobby being joined, until Steam has let this machine in or said why not; 0 for none.
var _joining := 0
## Whether the game being joined is to be watched rather than played in.
var _watching := false


func _ready() -> void:
	add_to_group(GROUP)
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not Store.on():
		return
	Store.steam.lobbies.asked.connect(_on_asked)
	Store.steam.lobbies.entered.connect(_on_entered)
	Store.steam.lobbies.failed.connect(_on_failed)
	Store.steam.lobbies.host_left.connect(hang_up)
	if Store.steam.api.has_signal(&"overlay_toggled"):
		Store.steam.api.connect(&"overlay_toggled", _on_overlay)


## The host of the Steam game being played at this machine has left its lobby, GAME.md 10.8: the
## connection is put down at once, and the room or the match says the host has gone, as it does
## when the connection is lost. There is no host to hand the game on to: it is played on the host's
## machine, every kart and every rule of it.
func hang_up() -> void:
	if Net.online() and not Net.hosting():
		var peer := Net.session.multiplayer.multiplayer_peer
		if peer != null:
			peer.close()


## Steam's overlay up over a room of this machine's own: the room paused, its menu up.
func _on_overlay(active: bool, _user_initiated: bool, _app: int) -> void:
	var scene := get_tree().current_scene
	if active and pauses_for_the_overlay(scene, Net.online()):
		PauseMenu.open_in(get_tree())


## Whether Steam's overlay coming up over [param scene] pauses it: a room with karts in it, not
## online, its menu not open already.
static func pauses_for_the_overlay(scene: Node, online: bool) -> bool:
	if online or scene == null or scene.get("match_node") == null:
		return false
	return not PauseMenu.is_open_in(scene.get_tree())


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


## Joins [param lobby], or [param watching] watches it: whatever is being played left for Play
## Online, saying the game is being joined, the lobby entered, and once Steam has let this machine
## in, the waiting room of the game, connecting to its host. Leaving by a change of scene takes the
## room out of the tree at once, rather than leaving it a frame on a connection gone.
func join(lobby: int, watching := false) -> void:
	_put_the_question_away()
	if not Store.on():
		return
	# What was done in the room left goes into the profiles first, and the seats sat in as other
	# profiles are guests again, as on the way to the title, GAME.md 8.5.
	get_tree().call_group(MatchRecord.GROUP, &"leave")
	Game.settings.unlink_all()
	var whose := Store.steam.lobbies.host_of(lobby)
	wait_on.call(
		"Joining %s on Steam..." % ("%s's game" % whose if not whose.is_empty() else "the game")
	)
	_joining = lobby
	_watching = watching
	Store.steam.lobbies.join(lobby)


func _on_entered(lobby: int, host: int) -> void:
	if lobby != _joining:
		return
	_joining = 0
	Game.go_to_waiting(join_config(lobby, host, Store.steam.lobbies.host_of(lobby), _watching))


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


## The configuration for hosting a Steam game, for every friend or [param invite_only], as Lobby
## settings last had it.
static func host_config(invite_only := Game.settings.lobby_invite_only) -> MatchConfig:
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
