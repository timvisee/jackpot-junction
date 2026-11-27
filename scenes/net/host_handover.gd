class_name HostHandover
extends CanvasLayer
## A game handed to a new host as its host goes, GAME.md 10.8 and 9.3, for the others to carry on
## with rather than be sent back to the menus. A game of a dedicated server is not handed over:
## its host is the server, which stays.
##
## A Steam game is handed over through its lobby. Steam makes another player in it its owner by
## itself, or the one a host leaving on purpose handed it to. That player hosts the game afresh
## from the match and door its lobby says, see [constant SteamLobby.PLAN_KEY], and says in the lobby
## once the game is up; everybody else follows them there. The lobby is kept the whole way, see
## [member SteamLobby.handing_over].
##
## A game hosted at a player's machine on the game's own network has no lobby, so its host tells
## every player who hosts after it, in the order they would, at the address it reaches them at, and
## what to host from, see [method HostControls.succession_line]. As the host goes, the first in
## line hosts the game afresh on the same port; everybody else asks at its address until a game
## answers there, see [HostProbe], and follows it in. With nobody answering in [constant STAGE]
## seconds, the next in line takes it on instead, and so on down the line. A host that went quiet
## rather than hanging up is asked after at its own address first: a game still answering there
## means it was this machine's connection that went, see [method NetPing.heard_lately].
##
## Either way, a map being played is carried over, see [MatchResume], and a dialog says so while it
## is handed over, over whatever the room was: whose game it was, who hosts it now, and a bar, with
## Leave, which gives up. A player following the new host into that map passes through the waiting
## room unseen, see [member MatchConfig.into_map], the dialog kept up until the map's own loading
## screen is. Made by [Game] from its path, so nothing it names is compiled with the autoloads, and
## kept across scenes.

## What is being handed over: nothing, a Steam game through its lobby, or a game on the game's own
## network.
enum Kind { NONE, STEAM, LAN }

## Over everything a room puts up, the pause menu and Steam's own questions too.
const LAYER := 96
## The group it is in, for [method Net.hand_over] to find it.
const GROUP := &"host_handover"
## How long a Steam game may take to find a new host before it is given up on, in seconds: Steam
## takes a while to notice a player whose game crashed.
const GIVE_UP_AFTER := 45.0
## Off Steam: how long the one in line has to have their game up before the next in line takes it
## on, in seconds, and how often they are asked whether it is up yet.
const STAGE := 10.0
const ASK_EVERY := 1.0
## At Make host: how long the host stays after telling everybody that its players play on and,
## off Steam, the new order, in seconds, for it to reach them before the connection goes, which
## drops whatever has not.
const TOLD_FOR := 1.0
## Why the game was given up on when it was this machine's connection that went, not the host,
## shown through tr().
const LOST := "The connection to the game was lost"
## The scenes a game is played in, a room or a map, stopped where they stand under the dialog while
## the game is handed over: everything in them holds the session that has gone.
const ROOMS: Array[String] = [
	"res://scenes/waiting/waiting_room.tscn", "res://scenes/match/match_scene.tscn"
]
## What the new host is told, see [method _now_the_host]; how long it is shown once the room is
## up, and how long it fades for; and how long the room is waited for at most, in seconds. Its
## words shown through tr().
const NOW_THE_HOST := "You are now the host"
const SHOWN_FOR := 1.5
const FADE_FOR := 0.4
const TELL_WITHIN := 30.0
## How long the bar takes to ease along, in seconds, and how far it goes.
const EASE_FOR := 8.0
const EASE_REACH := 0.9

## The dialog, its bar and its Leave.
var dialog: FormDialog
var bar: ProgressBar
var leave_button: Button
## Over the room of the game this machine took on, as the dialog goes, see [method _now_the_host]:
## the dialog's look and its title alone, taking nothing.
var banner: Control
## Where the room goes once the game has a new host: there, as host or as a player, unless a test
## says otherwise.
var go_on: Callable = Game.go_to_waiting
## Where the new host goes with a map in play carried over: into it, unless a test says otherwise.
var play_on: Callable = Game.start_match
## And where it goes once given up on, saying why: Play Online, unless a test says otherwise.
var give_up_to: Callable = Game.go_to_play_online

var _kind := Kind.NONE
## The Steam game's lobby, and the account of the host who went.
var _lobby := 0
var _old_host := 0
## Off Steam: who hosts next, in order, each by the peer they were, the address the host reached
## them at and their name; the port to find them on; what to host from; the peer this machine was;
## the password the game had; which of the line is being waited on, for how much longer, and the
## asking at their address.
var _line: Array = []
var _port := 0
var _plan := ""
var _me := 0
## The secret this machine was given to prove it is [member _me] at the new host.
var _token := ""
var _password := ""
var _stage := 0
var _stage_left := STAGE
var _probe: HostProbe
var _ask_left := 0.0
## Off Steam, the host gone quiet rather than hanging up: the address and port it was reached at,
## asked first, see [method _ask_old_host].
var _old_address := ""
var _old_port := 0
var _asking_old := false
## The host who went, by name, the dialog's title, whether this machine was watching, how long it
## has waited, and what it last saw of the map being played, see [MatchResume].
var _left_name := ""
var _heading := ""
var _watching := false
var _waited := 0.0
var _resume := {}
## Whether a map was being played here as the host went, for this machine to follow the new host
## straight into it, see [method _follow]; and whether the dialog is held up over the waiting room
## passed through on the way, with what is behind it covered, for how much longer at most, and over
## which scene it was first held, by its instance.
var _into_map := false
var _held := false
var _held_left := 0.0
var _held_over := 0
var _cover: Control
var _easing: Tween
## How much longer the new host's room is waited for, see [method _now_the_host], whether it is
## up, how much longer the word is shown since, and its fading.
var _tell_left := 0.0
var _up := false
var _shown_left := 0.0
var _fading: Tween


func _ready() -> void:
	add_to_group(GROUP)
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	var screen := Control.new()
	screen.name = "Screen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	# Behind the dialog held over the waiting room passed through, the stock every menu stands on, as
	# the map's loading screen after it does, see [method _hold].
	_cover = Backdrop.new()
	_cover.name = "Cover"
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.visible = false
	screen.add_child(_cover)
	dialog = FormDialog.add_to(screen, "", "")
	dialog.name = "Handover"
	bar = dialog.add_bar()
	leave_button = dialog.add_button(tr("Leave"))
	leave_button.pressed.connect(give_up)
	banner = _banner()
	screen.add_child(banner)


## The new host's word: a pane the dialog's own, saying [constant NOW_THE_HOST] and nothing else,
## with no bar, no button and no shade, which takes no click, key or cursor, so the room goes on
## under it.
func _banner() -> Control:
	var middle := CenterContainer.new()
	middle.name = "NowTheHost"
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.visible = false
	var pane := MenuTheme.pane()
	pane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pane.add_child(column)
	var title := MenuTheme.title(tr(NOW_THE_HOST), 44)
	title.name = "Title"
	column.add_child(title)
	return middle


## Whether this machine is being told it hosts the game now, see [method _now_the_host]: a map
## carried over holds its countdown until it has been, see [method HostControls.being_told].
func telling() -> bool:
	return banner.visible


## Whether the game is being handed over now.
func is_handing_over() -> bool:
	return _kind != Kind.NONE


## The connection to the host of the game [param session] plays in has gone, GAME.md 10.8: the
## game handed to its next host, the session closed, a Steam game's lobby kept, and the dialog up.
## Says whether it took it on: at a client of a Steam game's lobby, or of a game hosted at a
## player's machine that said who hosts after it.
func take(session: NetSession) -> bool:
	if session == null or session.is_host or _kind != Kind.NONE:
		return false
	var config := Game.pending_config
	if Store.on() and Store.steam.lobbies.id != 0 and not Store.steam.lobbies.hosting:
		_take_steam(session, config)
	elif not session.host_controls.succession.is_empty():
		if config != null and not config.server.is_empty():
			return false
		_take_line(session, config)
	else:
		return false
	_watching = session.watching
	# Taken before the session closes and the room with it, in case this machine hosts next.
	_resume = MatchResume.capture(session)
	_into_map = not _resume.is_empty()
	_open(tr("%s left") % _left_name)
	Net.close.call_deferred()
	return true


func _take_steam(session: NetSession, config: MatchConfig) -> void:
	var lobbies := Store.steam.lobbies
	_kind = Kind.STEAM
	_lobby = lobbies.id
	_old_host = lobbies.host_account
	_left_name = config.steam_name if config != null and not config.steam_name.is_empty() else ""
	if _left_name.is_empty():
		_left_name = _host_name_in(session)
	# Closed after the call that brought the word, which is the session's own: the lobby kept.
	lobbies.handing_over = true


func _take_line(session: NetSession, config: MatchConfig) -> void:
	var controls := session.host_controls
	_kind = Kind.LAN
	_line = controls.succession.duplicate(true)
	_port = controls.succession_port
	_plan = controls.succession_plan
	_me = controls.succession_me
	_token = controls.rejoin_token
	_password = config.password if config != null else ""
	_old_address = config.address if config != null else ""
	_old_port = config.port if config != null else _port
	_asking_old = not _old_address.is_empty() and not session.ping.heard_lately()
	_left_name = controls.succession_host
	if _left_name.is_empty():
		_left_name = _host_name_in(session)
	_stage = 0
	_stage_left = STAGE
	_probe = null


## What the host of [param session]'s game was called, as everybody else was told, or "The host"
## in the language spoken.
static func _host_name_in(session: NetSession) -> String:
	for guest: Dictionary in session.host_controls.guests():
		if bool(guest.get("host", false)) and not str(guest.get("name", "")).is_empty():
			return str(guest["name"])
	return Lang.t("The host")


## Hands the Steam game hosted here to the player at the account [param account], GAME.md 10.8:
## the lobby theirs, the session closed with the lobby kept, and this machine following them as
## the others do. Make host from Manage players.
func hand_to(account: int) -> void:
	if not Store.on() or not Net.hosting() or _kind != Kind.NONE:
		return
	var lobbies := Store.steam.lobbies
	_kind = Kind.STEAM
	_lobby = lobbies.id
	_old_host = Store.steam.account
	_watching = false
	_resume = {}
	_into_map = MatchResume.carried(Net.session.match_node)
	_left_name = Store.persona()
	lobbies.hand_to(account)
	lobbies.hosting = false
	lobbies.handing_over = true
	_open(tr("Handing over"))
	_close_soon()


## Hands the game hosted here on the game's own network to the first of [param line], GAME.md 10.8:
## the session closed a moment later, once everybody has heard the new order, everybody following
## them, and this machine with them, on [param port], the new host taking it on from [param plan].
## Make host from Manage players.
func hand_down(line: Array, port: int, plan: String) -> void:
	if not Net.hosting() or _kind != Kind.NONE or line.is_empty():
		return
	_kind = Kind.LAN
	_line = line.duplicate(true)
	_port = port
	_plan = plan
	_me = 1
	_token = Net.session.host_controls.rejoin_token
	_password = Net.session.door.password
	_asking_old = false
	_watching = false
	_resume = {}
	_into_map = MatchResume.carried(Net.session.match_node)
	# This machine's own, see [method give_up].
	_left_name = ""
	_stage = 0
	_stage_left = STAGE
	_probe = null
	_open(tr("Handing over"))
	_close_soon()


## The game hosted here closed once everybody has heard what it said last, see [constant TOLD_FOR]:
## who is first in line now, and that this machine's players play on in it.
func _close_soon() -> void:
	var going := Net.session
	var closing := func() -> void:
		if Net.session == going:
			Net.close()
	get_tree().create_timer(TOLD_FOR, true).timeout.connect(closing)


func _open(heading: String) -> void:
	release_hold()
	_stop_the_room()
	_heading = heading
	_waited = 0.0
	dialog.set_title(_heading, tr("Migrating host..."))
	bar.value = 0.0
	if _easing != null:
		_easing.kill()
	_easing = create_tween()
	_easing.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_easing.tween_property(bar, "value", EASE_REACH, EASE_FOR)
	dialog.open(leave_button)


## The room or map stops where it stands, GAME.md 10.8, until the next one takes its place: those
## of its nodes that run even while the game is paused, the pause menu among them, as well.
func _stop_the_room() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path not in ROOMS:
		return
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	for node: Node in scene.find_children("*", "", true, false):
		if node.process_mode == Node.PROCESS_MODE_ALWAYS:
			node.process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	if banner.visible:
		_step_banner(delta)
	if _held:
		_step_held(delta)
	if _kind == Kind.STEAM and Store.on():
		_step_steam(delta)
	elif _kind == Kind.LAN:
		_step_line(delta)


func _step_steam(delta: float) -> void:
	_waited += delta
	var api := Store.steam.api
	var owner := int(api.call(&"getLobbyOwner", _lobby))
	if owner == 0 or owner == _old_host:
		if _waited >= GIVE_UP_AFTER:
			give_up()
		return
	var named := Store.steam.persona_of(owner)
	if named.is_empty():
		named = tr("the next host")
	if owner == Store.steam.account:
		var config := rehost_config(api, _lobby)
		Store.steam.lobbies.take_over(config.lobby_who)
		_host_it(config)
		return
	dialog.set_title(_heading, tr("Migrating host to %s...") % named)
	if str(api.call(&"getLobbyData", _lobby, SteamLobby.HOSTED_KEY)) == str(owner):
		Store.steam.lobbies.host_account = owner
		_follow(SteamJoins.join_config(_lobby, owner, named, _watching))
	elif _waited >= GIVE_UP_AFTER:
		give_up()


## Off Steam: the one in line hosts it now if it is this machine; otherwise their address is asked
## until a game answers there, which is followed in, or until the next in line takes it on.
func _step_line(delta: float) -> void:
	_waited += delta
	# Make host: nobody is asked while this machine still hosts, for everybody to hear the new
	# order first, see [constant TOLD_FOR]. On one machine the address asked is its own, where the
	# game it is handing over still answers.
	if Net.hosting():
		return
	if _asking_old:
		_ask_old_host()
		return
	if _stage >= _line.size():
		give_up(tr("Nobody could take the game on, so it is over."))
		return
	var next: Dictionary = _line[_stage]
	if int(next.get("peer", 0)) == _me:
		_host_it(line_config(_plan, _port))
		return
	var named := str(next.get("name", ""))
	if named.is_empty():
		named = tr("the next host")
	dialog.set_title(_heading, tr("Migrating host to %s...") % named)
	_stage_left -= delta
	_ask_left -= delta
	if _probe == null or (_probe.failed and _ask_left <= 0.0):
		_probe = HostProbe.new(str(next.get("address", "")), _port)
		_ask_left = ASK_EVERY
	_probe.poll()
	if _probe.reached:
		var address := str(next.get("address", ""))
		_follow(follow_config(address, _port, _password, _me, _watching, _token))
	elif _stage_left <= 0.0:
		_stage += 1
		_stage_left = STAGE
		_probe = null


## Off Steam, the host gone quiet rather than hanging up, GAME.md 10.8: its own address asked
## first. A game still answering there means it was this machine's connection that went, not the
## host, and this machine is out of it; nobody answering, the game goes down the line.
func _ask_old_host() -> void:
	if _probe == null:
		_probe = HostProbe.new(_old_address, _old_port)
	_probe.poll()
	if _probe.reached:
		give_up(tr(LOST))
	elif _probe.failed:
		_asking_old = false
		_probe = null


## This machine is the new host: the game hosted afresh from [param config], GAME.md 10.8, into the
## map being played if there was one, as this machine last saw it, or else into a waiting room.
func _host_it(config: MatchConfig) -> void:
	var resume := _resume
	_done()
	_now_the_host()
	_let_go()
	if resume.is_empty():
		go_on.call(config)
		return
	config.resume = resume
	config.map = StringName(str((resume["rules"] as Dictionary).get("map", config.map)))
	play_on.call(config)


## Another player is the new host and its game is up: in after them, as the others do. With a map
## being played here, straight into it: the waiting room the way in is passed through unseen, see
## [member MatchConfig.into_map], under this dialog, held up until the map's loading screen is.
func _follow(config: MatchConfig) -> void:
	var into_map := _into_map
	_done(into_map)
	_let_go()
	if into_map:
		config.into_map = true
		_hold()
	go_on.call(config)


## The dialog kept up on its way to the map being played, over the stock every menu stands on, see
## [method _follow]: whatever room is behind it is only passed through.
func _hold() -> void:
	_held = true
	_held_left = TELL_WITHIN
	var scene := get_tree().current_scene
	_held_over = scene.get_instance_id() if scene != null else 0
	_cover.visible = true


## The dialog held on the way to the map put away once the map's loading screen is up over it, the
## game has gone on to anything but a room, the menus, or it has been up for [constant TELL_WITHIN]
## seconds. The waiting room passed through puts it away as well, should it turn out to be the lobby
## after all, or the game fail to come up, see [method release_hold].
func _step_held(delta: float) -> void:
	_held_left -= delta
	var scene := get_tree().current_scene
	var left := (
		scene != null
		and scene.get_instance_id() != _held_over
		and scene.scene_file_path not in ROOMS
	)
	var loading := not get_tree().get_nodes_in_group(LoadingScreen.GROUP).is_empty()
	if left or loading or _held_left <= 0.0:
		release_hold()


## The dialog held on the way to the map put away, see [method _hold]: up over it, or at the room
## this machine arrived in rather than passed through, the lobby, or a room saying why the game did
## not come up. Asked of the [constant GROUP] by those rooms, which name nothing of this.
func release_hold() -> void:
	if not _held:
		return
	_held = false
	_cover.visible = false
	if _kind == Kind.NONE:
		if _easing != null:
			_easing.kill()
		dialog.visible = false


## This machine took the game on, GAME.md 10.8: as the dialog goes, the same pane says
## [constant NOW_THE_HOST] alone, taking nothing, and stays while the room goes up, under
## its loading screen, and [constant SHOWN_FOR] seconds once it is, then fades. Nothing to close.
func _now_the_host() -> void:
	if _fading != null:
		_fading.kill()
	_fading = null
	banner.modulate.a = 1.0
	banner.visible = true
	_tell_left = TELL_WITHIN
	_up = false


## The new host's word put away a moment after its room is up, the lobby or the map carried on, its
## loading screen gone; or should the game not come up, after [constant TELL_WITHIN] seconds.
func _step_banner(delta: float) -> void:
	if _fading != null:
		return
	_tell_left -= delta
	if not _up and _room_up():
		_up = true
		_shown_left = SHOWN_FOR
	if _up:
		_shown_left -= delta
	if _tell_left > 0.0 and not (_up and _shown_left <= 0.0):
		return
	_fading = create_tween()
	_fading.tween_property(banner, "modulate:a", 0.0, FADE_FOR)
	_fading.tween_callback(
		func() -> void:
			banner.visible = false
			_fading = null
	)


## Whether the room this machine now hosts is up: a room or a map, running, hosted here, with no
## loading screen over it.
func _room_up() -> bool:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path not in ROOMS or not scene.can_process():
		return false
	return Net.hosting() and get_tree().get_nodes_in_group(LoadingScreen.GROUP).is_empty()


## The old game's session closed if it is still open, before the next room opens: one still open
## is taken for the connection the room came back on, and the room is left with nobody in it.
func _let_go() -> void:
	if Net.session != null:
		Net.close()


## Given up, or Leave: a Steam game's lobby left, and back to Play Online saying [param why], or
## else that the game is over. Left on the way to the map at the new host's, see [method _hold],
## nothing is said: the game goes on without this machine.
func give_up(why := "") -> void:
	if _held and _kind == Kind.NONE:
		release_hold()
		give_up_to.call("")
		return
	if _kind == Kind.NONE:
		return
	if why.is_empty() and _left_name.is_empty():
		why = tr("You left, so the game is over.")
	elif why.is_empty():
		why = tr("%s left, so the game is over.") % _left_name
	if _kind == Kind.STEAM and Store.on():
		# The host still in the lobby: it was this machine's connection that went, not the host.
		if Store.steam.lobbies.has_member(_lobby, _old_host):
			why = tr(LOST)
		Store.steam.lobbies.handing_over = false
		Store.steam.lobbies.leave()
	_done()
	give_up_to.call(why)


## Nothing handed over any more, the dialog put away unless it is [param held] up on the way to the
## map, see [method _hold].
func _done(held := false) -> void:
	_kind = Kind.NONE
	_lobby = 0
	_line = []
	_probe = null
	_asking_old = false
	_resume = {}
	_into_map = false
	if held:
		return
	if _easing != null:
		_easing.kill()
	dialog.visible = false


## The game a new host hosts in the Steam lobby [param lobby], as it says through [param api]:
## hosting again, the match and door the old host played by, and open to whoever it was.
static func rehost_config(api: Object, lobby: int) -> MatchConfig:
	var plan := _plan_in(str(api.call(&"getLobbyData", lobby, SteamLobby.PLAN_KEY)))
	var config := SteamJoins.host_config(clampi(int(plan.get("who", 1)), 0, 2))
	return _taken_on(config, plan)


## The game a new host off Steam hosts on [param port], from [param plan], see
## [method HostControls.succession_line]: the match and door the old host played by, its password
## with it.
static func line_config(plan: String, port: int) -> MatchConfig:
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "host"
	config.port = port
	var named: Array[String] = [PlayerNames.clean(Game.settings.player_names[0])]
	config.human_names = named
	_taken_on(config, _plan_in(plan))
	# Hosted with the password the game had, which only its players were told.
	config.password = str(config.door_plan.get("password", ""))
	return config


## Following the new host off Steam: joining the game at [param address] and [param port] with
## [param password], as the player who was [param was] in the old one, proved by [param token], the
## secret the old host gave them alone, so a map carried over seats them in their own kart again, or
## [param watching] it.
static func follow_config(
	address: String, port: int, password: String, was: int, watching: bool, token := ""
) -> MatchConfig:
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "join"
	config.watching = watching
	config.address = address
	config.port = port
	config.password = password
	config.was_peer = was
	config.was_token = token
	var named: Array[String] = [PlayerNames.clean(Game.settings.player_names[0])]
	config.human_names = named
	return config


static func _plan_in(text: String) -> Dictionary:
	var said: Variant = JSON.parse_string(text) if not text.is_empty() else null
	return said if said is Dictionary else {}


## [param config] as the game taken on from [param plan] is: the old host's match and door, a Quick
## Play game still one, and the story's Final Hand, its dealer's, left with them.
static func _taken_on(config: MatchConfig, plan: Dictionary) -> MatchConfig:
	var chosen: Variant = plan.get("match", {})
	if chosen is Dictionary:
		MatchOptions.from_wire(config, chosen)
	var door: Variant = plan.get("door", {})
	config.door_plan = door if door is Dictionary else {}
	config.quick_play = bool(plan.get("quick", false))
	config.final_hand = false
	config.house = {}
	config.rehost = true
	return config
