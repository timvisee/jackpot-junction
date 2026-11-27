class_name ManagePlayers
extends PanelContainer
## The host's list of everybody in its game, GAME.md 10.3, from its pause menu in place of the menu
## itself: the host's own players first, marked Me, then each other player by the name and color
## of their seat and the plate on their kart, or the learner's L, and each watcher by the name
## the host gave them, with Kick beside every one of those, which asks first, as Make host does,
## see [signal asking], and in a Steam game Profile, their profile in Steam's overlay. The cursor
## starts on Back, so a press too many shows nobody out. Somebody kicked goes back to the title,
## told why, and may join again; in the lobby their seat is emptied, and on a map a bot takes their
## kart on, as for anybody who leaves. The list follows whoever comes and goes while it is up, and
## scrolls between the title and Back where a room of eight and its watchers do not fit on the
## screen, GAME.md 9.3, keeping the row with the cursor in sight, see [FitScroll].
##
## In a Steam game, GAME.md 10.8, everybody has it, called Players for whoever has no say: every
## row has Profile and Mute, which hides that player's emotes on this screen, see [Muted], and only
## the host has Kick. Kicked from a public game, a player cannot come back to it.

## Back: the menu is up again in its place.
signal closed
## Kick or Make host pressed: [param words], the question, the line under it and the button that
## goes ahead, to be asked in place of the list, and [param action] done on yes; no is the list
## again with the cursor on [param from], the button that asked.
signal asking(words: Array[String], action: Callable, from: Button)

## How wide a row is, and its buttons.
## What a player without the host's say is told over the list off Steam, where it has no Profile or
## Mute: only to see who is in the game and who hosts it, GAME.md 10.8. Shown through tr().
const OFF_STEAM_NOTE := "Only the host can kick players or make someone else the host."
const ROW_WIDE := 640.0
const KICK_SIZE := Vector2(110.0, 44.0)
const HAND_SIZE := Vector2(150.0, 44.0)
const PROFILE_SIZE := Vector2(130.0, 44.0)
const MUTE_SIZE := Vector2(130.0, 44.0)
const LICENSE_SIZE := Vector2(130.0, 44.0)
## The room between a row's buttons.
const BUTTON_ROOM := 10.0

var session: NetSession
## The button on the menu that opens the list, which it names: Manage players with the say, and
## Players without.
var button: Button

var _rows: VBoxContainer
var _scroll: FitScroll
var _back: Button
var _note: Label
## Who the rows were drawn for, so they are only made again when somebody comes or goes.
var _drawn := ""


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuTheme.pane_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	column.add_child(MenuTheme.title(tr("Players"), Type.TITLE))
	_note = MenuTheme.subtitle("", Type.LABEL)
	column.add_child(_note)
	column.add_child(MenuTheme.perforation())
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	_scroll = FitScroll.around(_rows, self)
	column.add_child(_scroll.shaded())
	_back = MenuTheme.button(tr("Back"))
	_back.pressed.connect(func() -> void: closed.emit())
	column.add_child(_back)


## Up, drawn afresh, with the cursor on Back: on the first Kick, a press too many showed somebody
## the door.
func open() -> void:
	visible = true
	MenuTheme.deal(self)
	_note.text = tr("Somebody kicked goes back to the title, and can join again.")
	if Store.public_game():
		_note.text = tr("Somebody kicked goes back to the title, and can't join this game again.")
	elif not _says() and Store.steam_game():
		_note.text = tr(
			"Mute hides somebody's emotes on your screen. Report is on their Steam profile."
		)
	elif not _says():
		_note.text = tr(OFF_STEAM_NOTE)
	if _handing():
		_note.text = tr(
			"""Somebody kicked goes back to the server's games, and can join again. Make host hands \
them the host's say."""
		)
	_drawn = ""
	_redraw()
	_back.grab_focus()


func _process(_delta: float) -> void:
	if button != null:
		button.text = tr("Manage players") if _says() else tr("Players")
	if visible:
		_redraw()


## Whether a pause menu offers the list, see [member button]: to whoever has the host's say, and to
## everybody in a game a player hosts, on Steam or off it, GAME.md 10.8, to see who is in it and
## who hosts it; not to a player at a dedicated server's game, whose host is the server.
static func offered(session: NetSession, says: bool) -> bool:
	if session == null:
		return false
	if says or Store.steam_game():
		return true
	var config := Game.pending_config
	return config == null or config.server.is_empty()


## Whether the host's say is here, which kicks.
func _says() -> bool:
	return session != null and session.host_controls.mine()


func _redraw() -> void:
	var guests := session.host_controls.guests() if session != null else []
	if session != null and session.is_host and Store.steam_game():
		# With their Steam accounts, and without the host's own, listed as Me.
		guests = session.host_controls.everybody().filter(
			func(each: Dictionary) -> bool: return not each.get("host", false)
		)
	var mine := _mine()
	var drawn := str(mine) + str(guests) + str(_says()) + Muted.said()
	if drawn == _drawn:
		return
	_drawn = drawn
	var had_focus := get_viewport().gui_get_focus_owner()
	var lost := had_focus != null and _rows.is_ancestor_of(had_focus)
	for row: Node in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	for here: Dictionary in mine:
		_rows.add_child(_row(here))
	if guests.is_empty():
		_rows.add_child(MenuTheme.subtitle(tr("Nobody else is here."), Type.BODY))
	for guest: Dictionary in guests:
		_rows.add_child(_row(guest))
	if lost:
		_back.grab_focus()


## The host's own players, at this machine: there is nobody to show them out but themselves.
func _mine() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var match_node := session.match_node if session != null else null
	if match_node == null:
		return found
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human():
			(
				found
				. append(
					{
						"name": slot.display_name(),
						"color": slot.color(),
						"plate": KartVisuals.plate_worn(slot.kart),
						"seat": slot.index,
						"me": true,
					}
				)
			)
	return found


## Somebody in the game, as a seat card, see [SeatCard]: their chip in their color with their seat
## on it, gray for a watcher with no kart; their name over whether they play or watch; the plate
## their kart wears; and Profile, Make host and Kick at the right end. The host's own rows are
## rimmed in foil and say Me, with nothing to press.
func _row(guest: Dictionary) -> SeatCard:
	var plays := guest.has("color")
	var seat: int = guest.get("seat", -1)
	var me: bool = guest.get("me", false)
	var where := tr("Me") if me else (tr("Playing") if plays else tr("Watching"))
	if bool(guest.get("host", false)):
		where = tr("Host")
	var says := with_steam_name(where, _steam_name(guest))
	# The seat in the room, as the corner of the screen says it, for everybody alike: the number of
	# their seat at their own machine is for Kick.
	var mark := str(int(guest.get("slot", seat)) + 1) if plays and seat >= 0 else ""
	var card := SeatCard.make(
		str(guest["name"]), guest.get("color", SeatCard.NO_COLOR), mark, says, me
	)
	# Room for the buttons on every row, so the plates line up over rows with none, and the row
	# wider by Profile's and Mute's, so the names keep theirs.
	var handing := _handing() or _hosting_here()
	var room := (KICK_SIZE.x if _says() else 0.0) + (HAND_SIZE.x + BUTTON_ROOM if handing else 0.0)
	var profiles := _profiles()
	# Room for License on every row, GAME.md 10.8, whoever has one to show.
	var wider := LICENSE_SIZE.x + BUTTON_ROOM
	if profiles:
		wider += PROFILE_SIZE.x + BUTTON_ROOM
	if Store.steam_game():
		wider += MUTE_SIZE.x + BUTTON_ROOM
	room += wider
	card.custom_minimum_size.x = ROW_WIDE + wider
	card.actions.custom_minimum_size.x = room
	# Somebody watching has no kart, and the room a plate would take.
	card.show_plate(str(guest.get("plate", "")))
	if me:
		return card
	var peer: int = guest["peer"]
	# Their driver license, held up to be looked at, GAME.md 10.8; a learner has none.
	var license: Dictionary = guest.get("license", {})
	if not license.is_empty():
		card.actions.add_child(_license_button(license, str(guest["name"])))
	# Their profile on Steam, in Steam's overlay over the game, GAME.md 10.8.
	var account := _account(guest) if profiles else 0
	if account != 0:
		card.actions.add_child(profile_button(account))
	# Their emotes hidden on this screen, or shown again, GAME.md 10.8.
	if Store.steam_game():
		card.actions.add_child(_mute_button(guest))
	# Somebody else playing can be handed the say at a dedicated server, GAME.md 9.3a. A LAN game's
	# host is the machine it runs on, and has nobody to hand it to.
	var named := str(guest["name"])
	if _handing() and plays:
		var hand := MenuTheme.button(tr("Make host"), Type.BODY)
		hand.name = "MakeHost"
		hand.custom_minimum_size = HAND_SIZE
		hand.pressed.connect(
			func() -> void:
				asking.emit(
					hand_words(named), func() -> void: session.host_controls.make_host(peer), hand
				)
		)
		card.actions.add_child(hand)
	elif _hosting_here() and plays and (account != 0 or not Store.steam_game()):
		# The game handed to them, at once in the lobby and on the podium, and at the podium when
		# asked during a map, GAME.md 10.8.
		var giving := MenuTheme.button(tr("Make host"), Type.BODY)
		giving.name = "MakeHost"
		giving.custom_minimum_size = HAND_SIZE
		var to := peer
		giving.pressed.connect(
			func() -> void:
				asking.emit(
					hand_on_words(named), func() -> void: session.host_controls.hand_on(to), giving
				)
		)
		card.actions.add_child(giving)
	if not _says():
		return card
	var kick := MenuTheme.button(tr("Kick"), Type.BODY)
	kick.name = "Kick"
	kick.custom_minimum_size = KICK_SIZE
	var barring := Store.public_game()
	kick.pressed.connect(
		func() -> void:
			asking.emit(
				kick_words(named, _handing(), barring),
				func() -> void: session.host_controls.kick(peer, seat),
				kick
			)
	)
	card.actions.add_child(kick)
	return card


## Mute, hiding [param guest]'s emotes on this screen, or Unmute once it has, GAME.md 10.8.
func _mute_button(guest: Dictionary) -> Button:
	var muted := Muted.is_muted(guest)
	var mute := MenuTheme.button(tr("Unmute") if muted else tr("Mute"), Type.BODY)
	mute.name = "Mute"
	mute.custom_minimum_size = MUTE_SIZE
	mute.pressed.connect(func() -> void: Muted.mute(guest, not Muted.is_muted(guest)))
	return mute


## What is asked before [param named] is kicked: back to the title, or to the server's games when
## [param to_games], at a dedicated server, and free to join again, unless [param barred] from a
## public Steam game, GAME.md 10.8, which is never at a dedicated server.
static func kick_words(named: String, to_games: bool, barred := false) -> Array[String]:
	var line := Lang.t("%s goes back to the title, and can join again.")
	if barred:
		line = Lang.t("%s goes back to the title, and can't join this game again.")
	elif to_games:
		line = Lang.t("%s goes back to the server's games, and can join again.")
	return [Lang.t("Kick %s?") % named, line % named, Lang.t("Kick")]


## What is asked before the host's say is handed to [param named], at a dedicated server, GAME.md
## 9.3a: it is theirs from then on, and not to be taken back.
static func hand_words(named: String) -> Array[String]:
	return [
		Lang.t("Make %s the host?") % named,
		Lang.t("The host's say passes to %s: the match, the lobby and who is in it.") % named,
		Lang.t("Make host")
	]


## What is asked before the game hosted here is handed to [param named], GAME.md 10.8: they host
## it from then on, and the host here plays on in it.
static func hand_on_words(named: String) -> Array[String]:
	return [
		Lang.t("Make %s the host?") % named,
		Lang.t("%s hosts the game from then on, and you play on in it.") % named,
		Lang.t("Make host")
	]


## Whether the game is hosted here, at a player's machine, which can be handed to another player,
## GAME.md 10.8.
func _hosting_here() -> bool:
	return session != null and session.is_host and not session.dedicated


## [param says], with the Steam name [param steam_name] after it in a Steam game, GAME.md 10.8, the
## name the host knows them by on Steam whatever they call their kart.
static func with_steam_name(says: String, steam_name: String) -> String:
	var both := {"says": says, "name": steam_name}
	return says if steam_name.is_empty() else Lang.t("{says} · {name} on Steam").format(both)


## License, holding up [param license], the driver license of the player called [param named] as
## it came over the wire, see [LicenseWire], over everything, GAME.md 10.8; the cursor back on it
## once it is put away.
func _license_button(license: Dictionary, named: String) -> Button:
	var button := MenuTheme.button(tr("License"), Type.BODY)
	button.name = "License"
	button.custom_minimum_size = LICENSE_SIZE
	ScreenReader.label(button, tr("%s's license") % named)
	button.pressed.connect(
		func() -> void:
			var view := LicenseView.open_theirs(self, license, Game.last_input_keyboard)
			view.put_away.connect(func() -> void: LicenseView.give_cursor(button), CONNECT_ONE_SHOT)
	)
	return button


## Profile, opening the Steam profile of the account [param account] in Steam's overlay, GAME.md
## 10.8.
static func profile_button(account: int) -> Button:
	var profile := MenuTheme.button(Lang.t("Profile"), Type.BODY)
	profile.name = "Profile"
	profile.custom_minimum_size = PROFILE_SIZE
	profile.pressed.connect(func() -> void: Store.steam.show_profile(account))
	return profile


## The Steam name of [param guest] in a Steam game, the host's own included, or nothing; somebody
## else's through Steam's filter, GAME.md 10.8.
func _steam_name(guest: Dictionary) -> String:
	if not Store.steam_game():
		return ""
	if guest.get("me", false):
		return Store.persona()
	var account := _account(guest)
	return SteamWords.heard(Store.steam.persona_of(account), account) if account != 0 else ""


## The Steam account of [param guest], somebody else in a Steam game, as the host said it or as the
## connection knows it, or 0.
func _account(guest: Dictionary) -> int:
	if guest.has("account"):
		return int(guest["account"])
	return account_at(session, int(guest["peer"]))


## The Steam account of whoever is at [param peer] of [param session]'s connection, or 0: on any
## other kind, and at a client for anybody but the host.
static func account_at(session: NetSession, peer: int) -> int:
	if session == null or session.multiplayer.multiplayer_peer == null:
		return 0
	var steam := SteamPeer.of(session.multiplayer.multiplayer_peer)
	return steam.account_of(peer) if steam != null else 0


## Whether the rows offer the players' profiles on Steam: in a Steam game, with Steam's overlay to
## show them in.
static func _profiles() -> bool:
	return Store.steam_game() and Store.steam.overlay_on()


## Whether the say here is a client's at a dedicated server, which it can hand to somebody else.
func _handing() -> bool:
	return session != null and not session.is_host and session.host_controls.mine()
