class_name LobbySettings
extends PanelContainer
## The host's settings for its game, GAME.md 9.6, from its pause menu in place of the menu itself:
## what the lists of games call it, its host's game unless it is given a name, see [GameList]; and
## who may come in: how many may play, its own players included, a password to keep the game to
## the people who were told it, whether anybody may come to watch, and whether a watcher has to
## give the password too. Changed at once, the name once its box is left; nobody already in is
## shown out by any of them, they only answer the next knock. The name, the number and the two about
## watchers are kept for next time; the password is not.
##
## In a Steam game, GAME.md 10.8, who may join is a choice of three, anyone, friends or those
## invited, in place of the password, and Invite friends stands before the way on and has the
## cursor as the pane comes up, the first thing a host does there: Steam's invite dialog over the
## game, or with Steam's overlay off, the game's own list of friends online, see [SteamInvites], in
## the pane's place until Back.

## Back: the menu is up again in its place.
signal closed

var session: NetSession
## Up as the first step of opening a hosted room, before the match settings, GAME.md 9.6: its
## button goes on to them rather than back to a menu.
var onward := false

var _title: LineEdit
var _players: OptionButton
var _password: LineEdit
var _watchers: CheckButton
var _watch_free: CheckButton
var _who: OptionButton
var _invite: Button
var _invites: SteamInvites
var _back: Button
## The rows a Steam game has no use for, and the one only it has, GAME.md 10.8.
var _password_row: Control
var _watch_free_row: Control
var _who_row: Control


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuTheme.pane_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	column.add_child(MenuTheme.title(tr("Lobby settings"), Type.TITLE))
	column.add_child(MenuTheme.perforation())
	_title = MenuTheme.field("", "", PlayerNames.TITLE_LENGTH)
	_title.name = "GameName"
	_title.custom_minimum_size = Vector2(300.0, 44.0)
	_title.text_submitted.connect(func(_typed: String) -> void: _keep_title())
	_title.focus_entered.connect(func() -> void: PlayerInput.typing = true)
	_title.focus_exited.connect(
		func() -> void:
			PlayerInput.typing = false
			_keep_title()
	)
	column.add_child(MenuTheme.row(tr("Game name"), _title))
	var counts: Array = []
	for count: int in range(NetDoor.FEWEST_PLAYERS, NetDoor.MOST_PLAYERS + 1):
		counts.append(tr_n("%d player", "%d players", count) % count)
	_players = MenuTheme.option(counts, 0)
	_players.item_selected.connect(_on_players)
	column.add_child(MenuTheme.row(tr("Player limit"), _players))
	_password = MenuTheme.field("", tr("None"), NetDoor.PASSWORD_LENGTH)
	_password.custom_minimum_size = Vector2(300.0, 44.0)
	_password.text_changed.connect(
		func(typed: String) -> void:
			if session != null:
				session.door.password = typed.strip_edges()
				session.host_controls.door_changed()
	)
	# The keys are the box's while it has the cursor: the room goes on under the menu online.
	_password.focus_entered.connect(func() -> void: PlayerInput.typing = true)
	_password.focus_exited.connect(func() -> void: PlayerInput.typing = false)
	_password_row = MenuTheme.row(tr("Password"), _password)
	column.add_child(_password_row)
	_watchers = MenuTheme.toggle(true)
	_watchers.toggled.connect(_on_watchers)
	column.add_child(MenuTheme.row(tr("Allow watchers"), _watchers))
	_watch_free = MenuTheme.toggle(false)
	_watch_free.toggled.connect(_on_watch_free)
	_watch_free_row = MenuTheme.row(tr("Watch without password"), _watch_free)
	column.add_child(_watch_free_row)
	# A Steam game is for anyone, every friend or those invited alone, and has no password.
	var who_names := SteamLobby.WHO_NAMES.map(func(who: String) -> String: return tr(who))
	_who = MenuTheme.option(who_names, Game.settings.lobby_who)
	_who.name = "WhoCanJoin"
	_who.item_selected.connect(_on_who)
	_who_row = MenuTheme.row(tr("Who can join"), _who)
	column.add_child(_who_row)
	var note := MenuTheme.subtitle(
		tr("Who can join changes for the next to come. Nobody already here is shown out."),
		Type.LABEL
	)
	column.add_child(note)
	_invite = MenuTheme.button(tr("Invite friends"))
	_invite.name = "InviteFriends"
	_invite.pressed.connect(_invite_friends)
	column.add_child(_invite)
	_back = MenuTheme.button(tr("Back"))
	_back.pressed.connect(
		func() -> void:
			_keep_title()
			closed.emit()
	)
	column.add_child(_back)


## Up, showing what the door is set to now, with the cursor on the number of players.
func open() -> void:
	visible = true
	MenuTheme.deal(self)
	_back.text = tr("Next") if onward else tr("Back")
	# Next is the way on, in foil, GAME.md 8.1a; Back is only the way out.
	_back.theme_type_variation = HouseTheme.PRIMARY if onward else &""
	var door := session.door if session != null else NetDoor.new()
	var count := clampi(door.max_players, NetDoor.FEWEST_PLAYERS, NetDoor.MOST_PLAYERS)
	_title.text = door.title
	_title.placeholder_text = GameList.default_title(_host_name())
	_players.select(count - NetDoor.FEWEST_PLAYERS)
	_password.text = door.password
	_watchers.set_pressed_no_signal(door.watchers_allowed)
	_watch_free.set_pressed_no_signal(not door.watchers_need_password)
	# What the game is open to now: a Quick Play game is anybody's, whatever was last picked.
	var lobby := Store.steam.lobbies if Store.on() else null
	_who.select(lobby.who if lobby != null and lobby.hosting else Game.settings.lobby_who)
	var steam := Store.steam_game()
	_password_row.visible = not steam
	_watch_free_row.visible = not steam
	_who_row.visible = steam
	_invite.visible = steam
	_show_watching()
	(_invite if steam else _players).grab_focus()


## The game's name as it was typed, onto the door and kept for next time, if it changed: once the
## box is left rather than at every letter, since at a dedicated server each change goes over the
## wire and into the server's log.
func _keep_title() -> void:
	var title := PlayerNames.clean(_title.text, PlayerNames.TITLE_LENGTH)
	var door := session.door if session != null else null
	if door != null and door.title != title:
		door.title = title
		session.host_controls.door_changed()
	if Game.settings.lobby_title != title:
		Game.settings.lobby_title = title
		Game.settings.save_to_disk()


## Whose game it is, for the name it has with none given: the first player here, as the room has
## them, or as the settings do before they are seated.
func _host_name() -> String:
	var match_node := session.match_node if session != null else null
	if match_node != null:
		for slot: PlayerSlot in match_node.slots:
			if slot.is_local_human():
				return slot.display_name()
	return PlayerNames.clean(Game.settings.player_names[0])


func _on_players(index: int) -> void:
	var count := index + NetDoor.FEWEST_PLAYERS
	if session != null:
		session.door.max_players = count
		session.host_controls.door_changed()
	Game.settings.lobby_players = count
	Game.settings.save_to_disk()


func _on_watchers(on: bool) -> void:
	if session != null:
		session.door.watchers_allowed = on
		session.host_controls.door_changed()
	Game.settings.lobby_watchers = on
	Game.settings.save_to_disk()
	_show_watching()


func _on_watch_free(on: bool) -> void:
	if session != null:
		session.door.watchers_need_password = not on
		session.host_controls.door_changed()
	Game.settings.lobby_watch_free = on
	Game.settings.save_to_disk()


## Steam's invite dialog over the game, or with Steam's overlay off the game's own list, in this
## pane's place until its Back, GAME.md 10.8.
func _invite_friends() -> void:
	if Store.on() and Store.steam.lobbies.invite():
		return
	if _invites == null:
		_invites = SteamInvites.new()
		_invites.visible = false
		_invites.closed.connect(_back_from_invites)
		get_parent().add_child(_invites)
	visible = false
	_invites.open()


func _back_from_invites() -> void:
	_invites.visible = false
	visible = true
	_invite.grab_focus()


## The game opened to [param who], a [enum SteamLobby.Who], at once and for next time, GAME.md 10.8:
## nobody already in is shown out.
func _on_who(who: int) -> void:
	if Store.on():
		Store.steam.lobbies.set_who(who)
	Game.settings.lobby_who = who
	Game.settings.save_to_disk()


## Watching without the password is only a question while anybody may watch at all.
func _show_watching() -> void:
	_watch_free.disabled = not _watchers.button_pressed


func _exit_tree() -> void:
	PlayerInput.typing = false
