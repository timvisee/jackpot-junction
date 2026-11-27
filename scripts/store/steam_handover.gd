class_name SteamHandover
extends CanvasLayer
## A Steam game handed to a new host as its host goes, GAME.md 10.8, for the others to carry on with
## rather than be sent back to Play Online. Steam makes another player in the lobby its owner by
## itself, or the one a host leaving on purpose handed it to. That player hosts the game afresh from
## the match and door its lobby says, see [constant SteamLobby.PLAN_KEY], into a waiting room, and
## says in the lobby once the game is up; everybody else follows them there. The lobby is kept the
## whole way, see [member SteamLobby.handing_over].
##
## While it is handed over a dialog says so, over whatever the room was: whose game it was, who
## hosts it now, and a bar, with Leave, which gives up and goes to Play Online. With nobody taking
## it on in [constant GIVE_UP_AFTER] seconds, it gives up by itself. Made by [Game] from its path
## with Steam on, so nothing it names is compiled with the autoloads, and kept across scenes.

## Over everything a room puts up, the pause menu and Steam's own questions too.
const LAYER := 96
## The group it is in, for [method Store.hand_over] to find it.
const GROUP := &"steam_handover"
## How long the game may take to find a new host before it is given up on, in seconds: Steam takes
## a while to notice a player whose game crashed.
const GIVE_UP_AFTER := 45.0
## How long the bar takes to ease along, in seconds, and how far it goes.
const EASE_FOR := 8.0
const EASE_REACH := 0.9

## The dialog, its bar and its Leave.
var dialog: FormDialog
var bar: ProgressBar
var leave_button: Button
## Where the room goes once the game has a new host: there, as host or as a player, unless a test
## says otherwise.
var go_on: Callable = Game.go_to_waiting
## Where the new host goes with a map in play carried over: into it, unless a test says otherwise.
var play_on: Callable = Game.start_match
## And where it goes once given up on, saying why: Play Online, unless a test says otherwise.
var give_up_to: Callable = Game.go_to_play_online

## The lobby being handed over, 0 while none is; the host who went, and their name; whether this
## machine was watching; how long it has waited.
var _lobby := 0
var _old_host := 0
var _left_name := ""
var _heading := ""
var _watching := false
var _waited := 0.0
## What this machine last saw of the map being played as the host went, see [MatchResume].
var _resume := {}
var _easing: Tween


func _ready() -> void:
	add_to_group(GROUP)
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	var screen := Control.new()
	screen.name = "Screen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	dialog = FormDialog.add_to(screen, "", "")
	dialog.name = "Handover"
	bar = dialog.add_bar()
	leave_button = dialog.add_button("Leave")
	leave_button.pressed.connect(give_up)


## Whether the game is being handed over now.
func is_handing_over() -> bool:
	return _lobby != 0


## The connection to the host of the Steam game [param session] plays in has gone, GAME.md 10.8:
## the game handed to its next host, the session closed with the lobby kept, and the dialog up.
## Says whether it took it on, which it does in a Steam game's lobby at a client.
func take(session: NetSession) -> bool:
	if not Store.on() or session == null or session.is_host:
		return false
	var lobbies := Store.steam.lobbies
	if lobbies.id == 0 or lobbies.hosting or _lobby != 0:
		return false
	_lobby = lobbies.id
	_old_host = lobbies.host_account
	_watching = session.watching
	# Taken before the session closes and the room with it, in case this machine hosts next.
	_resume = MatchResume.capture(session)
	var config := Game.pending_config
	_left_name = config.steam_name if config != null and not config.steam_name.is_empty() else ""
	if _left_name.is_empty():
		_left_name = "The host"
	_waited = 0.0
	_heading = "%s left" % _left_name
	dialog.set_title(_heading, "Migrating host...")
	bar.value = 0.0
	if _easing != null:
		_easing.kill()
	_easing = create_tween()
	_easing.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_easing.tween_property(bar, "value", EASE_REACH, EASE_FOR)
	dialog.open(leave_button)
	# Closed after the call that brought the word, which is the session's own: the lobby kept.
	lobbies.handing_over = true
	Net.close.call_deferred()
	return true


## Hands the game the host here plays in to the player at the account [param account], GAME.md
## 10.8: the lobby theirs, the session closed with the lobby kept, and this machine following them
## as the others do. Make host from Manage players.
func hand_to(account: int) -> void:
	if not Store.on() or not Net.hosting() or _lobby != 0:
		return
	var lobbies := Store.steam.lobbies
	_lobby = lobbies.id
	_old_host = Store.steam.account
	_watching = false
	_resume = {}
	_left_name = Store.persona()
	lobbies.hand_to(account)
	lobbies.hosting = false
	lobbies.handing_over = true
	_waited = 0.0
	_heading = "Handing over"
	dialog.set_title(_heading, "Migrating host...")
	bar.value = 0.0
	dialog.open(leave_button)
	Net.close.call_deferred()


func _process(delta: float) -> void:
	if _lobby == 0 or not Store.on():
		return
	_waited += delta
	var api := Store.steam.api
	var owner := int(api.call(&"getLobbyOwner", _lobby))
	if owner == 0 or owner == _old_host:
		if _waited >= GIVE_UP_AFTER:
			give_up()
		return
	var named := Store.steam.persona_of(owner)
	if named.is_empty():
		named = "the next host"
	if owner == Store.steam.account:
		_host_it()
		return
	dialog.set_title(_heading, "Migrating host to %s..." % named)
	if str(api.call(&"getLobbyData", _lobby, SteamLobby.HOSTED_KEY)) == str(owner):
		_follow(owner, named)
	elif _waited >= GIVE_UP_AFTER:
		give_up()


## This machine is the new host: the game hosted afresh as the lobby says, GAME.md 10.8.
func _host_it() -> void:
	var lobby := _lobby
	var config := rehost_config(Store.steam.api, lobby)
	Store.steam.lobbies.take_over(config.lobby_who)
	var resume := _resume
	_done()
	if resume.is_empty():
		go_on.call(config)
		return
	# A map was being played: on with it here, GAME.md 10.8, as this machine last saw it.
	config.resume = resume
	config.map = StringName(str((resume["rules"] as Dictionary).get("map", config.map)))
	play_on.call(config)


## Another player is the new host and its game is up: in after them, as the others do.
func _follow(owner: int, named: String) -> void:
	var lobbies := Store.steam.lobbies
	lobbies.host_account = owner
	var config := SteamJoins.join_config(_lobby, owner, named, _watching)
	_done()
	go_on.call(config)


## Given up, or Leave: the lobby left, and back to Play Online saying the game is over.
func give_up() -> void:
	if _lobby == 0:
		return
	var why := "%s left, so the game is over." % _left_name
	# The host still in the lobby: it was this machine's connection that went, not the host.
	if Store.steam.lobbies.has_member(_lobby, _old_host):
		why = "The connection to the game was lost"
	Store.steam.lobbies.handing_over = false
	Store.steam.lobbies.leave()
	_done()
	give_up_to.call(why)


func _done() -> void:
	_lobby = 0
	_resume = {}
	if _easing != null:
		_easing.kill()
	dialog.visible = false


## The game a new host hosts in [param lobby], as its lobby says through [param api]: hosting
## again, the match and door the old host played by, and open to whoever it was.
static func rehost_config(api: Object, lobby: int) -> MatchConfig:
	var text := str(api.call(&"getLobbyData", lobby, SteamLobby.PLAN_KEY))
	var said: Variant = JSON.parse_string(text) if not text.is_empty() else null
	var plan: Dictionary = said if said is Dictionary else {}
	var config := SteamJoins.host_config(clampi(int(plan.get("who", 1)), 0, 2))
	var chosen: Variant = plan.get("match", {})
	if chosen is Dictionary:
		MatchOptions.from_wire(config, chosen)
	var door: Variant = plan.get("door", {})
	config.door_plan = door if door is Dictionary else {}
	config.quick_play = bool(plan.get("quick", false))
	# The story's Final Hand is its dealer's, and goes with them.
	config.final_hand = false
	config.house = {}
	config.rehost = true
	return config
