class_name PauseMenu
extends CanvasLayer
## Pausing freezes the whole match in single-player and local play, GAME.md 3.8. Online it takes
## the whole room: the menu opens straight away, and the match stops once everybody has opened
## theirs. Resume, Settings, or back to the title, and over each local player's corner of the HUD
## a switch for how they drive, and in the lobby and the Garage for their name and color too, see
## [DriveSwitches]. A map adds a way back to the lobby for whoever
## decides where the room goes: the one machine offline, the host online. Both ways out that end
## something for other people, or a Grand Prix, ask first, see [ConfirmPane].
##
## Settings opens over the room, and Back from it comes back here. It used to change scene, and
## coming back built the room again from scratch: a match in progress was thrown away for a new
## one, and online the room came back re-seating a match nobody else was in.

## The menu put away, by Resume, Back or the pause button, rather than left for somewhere else.
signal resumed

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
## Every room's menu is in this group, so something with no way to press Escape, such as the menu
## button on a touch screen, GAME.md 4.2, can open it.
const GROUP := &"pause_menu"
## Kit's folders open, see [constant NotesFolder.GROUP].
const FOLDERS := &"notes_folders"
## Over the room, its HUD and the host's match settings, and over what the room is saying while
## it connects, see [StatusPane], so a player kept waiting can open it and leave.
const LAYER := 20
## The achievements dialog, opened over the menu by its path, see [method open_achievements].
const ACHIEVEMENTS := "res://scenes/achievements/achievements_dialog.gd"
## What skipping the driving school asks, in the school and its test alike, GAME.md 9.4a.
const SKIP_SCHOOL: Array[String] = [
	"Skip the driving school?",
	"Earn your license any time from the title's Driving School button.",
	"Skip",
	"Stay",
]
## The air between the menu's parts, and its heading's size.
const SEPARATION := 16
const HEADING := 48
## How big the stamp of where the game is played is drawn, and how much of it hangs off the menu's
## top corner, GAME.md 10.8.
const STAMP_RADIUS := 50.0
const STAMP_OFF := Vector2(0.55, 0.4)

## Every menu in a tree, kept as they come and go, for [method is_open_in]: the touch controls,
## the emotes and the mouse each ask it every frame, and asking the tree walks the group.
static var _in_tree: Array[PauseMenu] = []
##
## Built on the pane every panel in the game is cut from, GAME.md 8.3, over a shade of the arena
## it is holding up.

## The session to ask online, null in a room where this machine is the only one.
var session: NetSession
## Whether the players here can change their names and colors from their switches: in the lobby
## and the Garage, GAME.md 4.4, and not in the middle of a map.
var names_and_colors := false:
	set(value):
		names_and_colors = value
		if _switches != null:
			_switches.names_and_colors = value

## The menu's heading, Paused or Menu, see [method heading].
var _heading: Label
## The buttons' list, scrolling where the screen is short, see [FitScroll].
var _list: FitScroll
## The fine print at the foot of the buttons in a Grand Prix, see [method run_words], and the
## dotted rule over it with it.
var _run_foot: VBoxContainer
var _run_line: Label
var _panel: Control
## The shade behind the menu, which fades out with it, and whether the menu is on its way out,
## which is not open: the room is the player's again from the moment they close it.
var _shade: ColorRect
var _leaving := false
var _resume: Button
var _quit: Button
## Online, on the host: stopping the match for everybody now rather than waiting for them all to
## ask. On a client: the line saying the host has done that, for a player with no menu open.
var _force: Button
var _held: Control
var _switches: DriveSwitches
## The menu's own pane, and the question that takes its place while it is being asked.
var _main: PanelContainer
var _confirm: ConfirmPane
## What the question is asked before, the button that asked it, for the cursor to go back to, and
## what it stands in place of: the menu, or what is up in its place, see [member _aside].
var _on_yes: Callable
var _asked_by: Button
var _asked_over: Control
## The settings while they are open over the room, null otherwise.
var _settings: SettingsScreen
## The achievements dialog open over the menu, by its path: it names this menu's group, and a
## script naming the other back is a cycle among the rooms', see [method open_achievements].
var _achievements: CanvasLayer
## Online, on the host: who else is in the game, with a way to show any of them out, and the
## button that opens it. Up in place of the menu while it is open, as a question is.
var _players: ManagePlayers
var _manage: Button
## And who may come in: how many may play, and the password, GAME.md 9.6.
var _door: LobbySettings
var _door_button: Button
## In a Steam game, friends invited, and where the game is played, stamped, GAME.md 10.8.
var _invites: SteamInvites
var _invite: Button
var _stamp: NetStamp
## Back to the lobby from a map, for whoever has the say, see [method offer_the_lobby].
var _to_lobby: Button
## Whatever is up in place of the menu just now, and the button that put it there.
var _aside: Control
var _aside_from: Button
## The Clubhouse's buttons, put up in place of the menu's own, see [method show_clubhouse]; the
## button that does, and those of its that wear the NEW tag, see [method _tag_fresh].
var _club: VBoxContainer
var _clubhouse_button: Button
var _loyalty_button: Button
var _catalog_button: Button
var _achievements_button: Button
## The catalog over the menu while it is up, GAME.md 8.8.
var _catalog: CatalogDialog
## The kart dialog over the menu while it is up, GAME.md 4.4, in a room that offers it, and its
## button.
var _kart: KartDialog
var _kart_button: Button
## The loyalty program over the menu while it is up, GAME.md 8.9, opened by its button in the
## Clubhouse once the profile playing has been welcomed to it.
var _loyalty: LoyaltyDialog
## What is pinned in the loyalty program, on a scrap of its own under the menu's pane.
var _pinned_note: PinnedNote


## Hangs one over a room. An online room passes its session, which is what decides whether the
## whole room has asked to stop, see GAME.md 3.8.
static func add_to(parent: Node, net: NetSession = null) -> PauseMenu:
	var menu := PauseMenu.new()
	menu.name = "PauseMenu"
	menu.session = net
	parent.add_child(menu)
	return menu


func _enter_tree() -> void:
	_in_tree.append(self)


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	if session != null:
		session.pause_agreed.connect(_freeze)
	# The menu and the switches over the corners share one root, since a pad's cursor only looks for
	# the next button inside the tree it is in, and they are to be one screen to it.
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel = Control.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	root.add_child(_panel)
	# The shade beside the pane rather than in with it: a container centering the pane would
	# center the shade too, at the nothing it asks for, and the room would never go dark.
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(shade)
	_shade = shade
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(middle)
	var pane := MenuTheme.pane()
	middle.add_child(pane)
	_main = pane
	_confirm = ConfirmPane.new()
	_confirm.visible = false
	_confirm.answered.connect(_answered)
	middle.add_child(_confirm)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", SEPARATION)
	pane.add_child(column)
	_heading = MenuTheme.title(heading(session != null, false), HEADING)
	column.add_child(_heading)
	column.add_child(MenuTheme.perforation())
	# The buttons under the heading, scrolling where the screen is too short for all of them, a
	# phone's under a big UI scale with a host's eight, rather than made smaller, which only made
	# them harder to press: the heading stays, the cursor is followed down them, and on a touch
	# screen a swipe scrolls them and a tap presses one, see [TouchScroll].
	var buttons := VBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", SEPARATION)
	# The Clubhouse's buttons in their place while it is up, see [method show_clubhouse].
	_club = VBoxContainer.new()
	_club.name = "Clubhouse"
	_club.add_theme_constant_override("separation", SEPARATION)
	_club.visible = false
	var lists := VBoxContainer.new()
	lists.add_child(buttons)
	lists.add_child(_club)
	_list = FitScroll.around(lists, pane)
	column.add_child(_list.shaded())
	# Out to the perforation over it and the pane's lines under and beside it, so the NEW tag hung
	# off a button's corner is not cut off by the edge of the scroll, GAME.md 3.8.
	_list.reach(SEPARATION, MenuTheme.PANE_GAP, MenuTheme.PANE_GAP)
	TouchScroll.attach(_list)
	# Back to driving is the way on from here, GAME.md 8.1a, in foil.
	_resume = MenuTheme.primary(MenuTheme.button("Resume"))
	_resume.pressed.connect(set_paused.bind(false))
	buttons.add_child(_resume)
	_force = MenuTheme.button("Pause game")
	_force.pressed.connect(_force_pause)
	_force.visible = false
	# The tick on the far end of the words, and no bigger than they are.
	_force.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_force.expand_icon = false
	buttons.add_child(_force)
	_door = LobbySettings.new()
	_door.session = session
	_door.visible = false
	_door.closed.connect(_put_away_aside)
	middle.add_child(_door)
	_door_button = MenuTheme.button("Lobby settings")
	_door_button.pressed.connect(func() -> void: _open_aside(_door, _door_button))
	_door_button.visible = false
	buttons.add_child(_door_button)
	# Anybody in a Steam game invites friends to it, GAME.md 10.8, over Manage players: through
	# Steam's own dialog, or from a list of the game's own with Steam's overlay off.
	_invites = SteamInvites.new()
	_invites.visible = false
	_invites.closed.connect(_put_away_aside)
	middle.add_child(_invites)
	_invite = MenuTheme.button("Invite friends")
	_invite.name = "InviteFriends"
	_invite.pressed.connect(_invite_friends)
	_invite.visible = false
	buttons.add_child(_invite)
	_players = ManagePlayers.new()
	_players.session = session
	_players.visible = false
	_players.closed.connect(_put_away_aside)
	_players.asking.connect(ask)
	middle.add_child(_players)
	_manage = MenuTheme.button("Manage players")
	_manage.pressed.connect(func() -> void: _open_aside(_players, _manage))
	_manage.visible = false
	buttons.add_child(_manage)
	# What of the title's Clubhouse can be had in a room, GAME.md 3.8, behind one button as there:
	# the loyalty program, the catalog and the achievements, and not the Garage or the Driving
	# School, which are rooms of their own. The Operator's is the staff's, STORY.md 8.6.
	var operator := Story.stage_here() == Story.Stage.OPERATOR
	_clubhouse_button = MenuTheme.button(StoryLines.STAFF_ROOM if operator else "Clubhouse")
	_clubhouse_button.name = "ClubhouseButton"
	_clubhouse_button.pressed.connect(show_clubhouse.bind(true))
	buttons.add_child(_clubhouse_button)
	_fill_clubhouse()
	if Game.settings.profile.loyalty.welcomed:
		# What is pinned in it, apart from the pane, GAME.md 8.9.
		_pinned_note = PinnedNote.new(pane)
		_pinned_note.opened.connect(open_loyalty)
		_panel.add_child(_pinned_note)
	var settings := MenuTheme.button("Settings")
	settings.pressed.connect(open_settings)
	buttons.add_child(settings)
	_quit = MenuTheme.button("Back to title")
	_quit.pressed.connect(_back_to_title)
	buttons.add_child(_quit)
	# In a Grand Prix, where the run has got and what it is played to, see [method run_words]: the
	# fine print at the foot of the ticket, under the buttons rather than the heading, which it made
	# too big a thing; in the list, so a short screen scrolls to it rather than giving it room.
	_run_foot = VBoxContainer.new()
	_run_foot.name = "Run"
	_run_foot.add_theme_constant_override("separation", SEPARATION)
	_run_foot.visible = false
	_run_foot.add_child(_dotted_rule())
	_run_line = MenuTheme.subtitle("", Type.LABEL)
	_run_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_run_line.custom_minimum_size.x = MenuTheme.button_size().x
	_run_foot.add_child(_run_line)
	buttons.add_child(_run_foot)
	_switches = DriveSwitches.new()
	_switches.names_and_colors = names_and_colors
	_switches.visible = false
	root.add_child(_switches)
	# Where the game is played, stamped on the menu's top corner, GAME.md 10.8.
	_stamp = NetStamp.new(STAMP_RADIUS)
	_stamp.name = "NetStamp"
	_stamp.size = _stamp.custom_minimum_size
	_stamp.show_for(Game.pending_config if session != null else null)
	_panel.add_child(_stamp)
	# In the middle of the screen, on a pane of its own: a client that has not opened its menu is
	# looking at the room, and a line of text over the arena is a line nobody reads.
	var held := CenterContainer.new()
	held.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	held.visible = false
	root.add_child(held)
	var held_pane := MenuTheme.pane()
	held.add_child(held_pane)
	var words := Label.new()
	words.text = "The host paused the game"
	Type.strong(words, Type.HEADING, Palette.CHIP_WHITE)
	held_pane.add_child(words)
	_held = held


## Another thing the menu can do in this room, put under Resume, and under Pause game where the
## host has that, or under [param under], an entry added before. The waiting room of GAME.md 9.6
## adds the host's match settings, which are only a thing in there and only for the host.
func add_entry(text: String, action: Callable, under: Control = null) -> Button:
	var button := MenuTheme.button(text)
	button.pressed.connect(
		func() -> void:
			set_paused(false)
			action.call()
	)
	# Under Pause game rather than over it: stopping everybody is the host's first thing to reach for
	# in a room that is still running, and the match settings are a second thing to do in it.
	if under != null:
		under.add_sibling(button)
	else:
		_force.add_sibling(button)
	return button


## The kart dialog's button, GAME.md 4.4, in the Clubhouse over its Back, as the title's way to it
## is: in the lobby and the Garage, for the players here to dress their karts in [param room],
## which wear it at once. The dialog is put up over the menu, which waits under it, as the
## catalog's is.
func offer_kart(room: Match) -> Button:
	_kart_button = MenuTheme.button(KartDialog.ENTRY)
	_kart_button.name = "YourKart"
	_kart_button.pressed.connect(open_kart.bind(room))
	# Kept in the list as the Clubhouse's others are, see [method _fill_clubhouse].
	_kart_button.focus_neighbor_left = NodePath(".")
	_kart_button.focus_neighbor_right = NodePath(".")
	var back := _club.get_node("ClubhouseBack")
	back.add_sibling(_kart_button)
	_club.move_child(_kart_button, back.get_index())
	_tag_fresh()
	return _kart_button


## The kart dialog over the menu for [param room]'s players here; put away, the cursor goes back to
## its button, and the players' switches say their names and colors as they now are.
func open_kart(room: Match) -> void:
	if _kart != null:
		return
	_kart = KartDialog.open(self, room)
	_kart.put_away.connect(
		func() -> void:
			_kart = null
			_tag_fresh()
			if _panel.visible and _main.visible and not in_clubhouse():
				_switches.put_up(_buttons())
	)


## The menu of the driving school and its test, GAME.md 9.4a: Resume, Settings, which a player
## new to the game may need before anything else, and Skip driving school in place of Back to
## title, which asks first and then does [param skip]; nothing of the Clubhouse's.
func for_the_school(skip: Callable) -> void:
	_clubhouse_button.visible = false
	if _pinned_note != null:
		_pinned_note.queue_free()
		_pinned_note = null
	_quit.text = "Skip driving school"
	_quit.name = "SkipSchool"
	_quit.pressed.disconnect(_back_to_title)
	_quit.pressed.connect(
		func() -> void:
			ask(
				SKIP_SCHOOL,
				func() -> void:
					set_paused(false)
					skip.call(),
				_quit
			)
	)


## The menu of the demo for a booth, GAME.md 9.8: Resume, Settings, Play the full game, which does
## [param full_game], in foil with a glint running across it to catch the eye, and Quit, which ends
## the game for whoever is showing it; nothing of a lobby's or the Clubhouse's.
func for_the_demo(full_game: Callable) -> void:
	_clubhouse_button.visible = false
	if _pinned_note != null:
		_pinned_note.queue_free()
		_pinned_note = null
	_quit.text = "Quit"
	_quit.pressed.disconnect(_back_to_title)
	_quit.pressed.connect(func() -> void: Game.quit())
	var settings := _quit.get_parent().get_child(_quit.get_index() - 1) as Control
	var full := MenuTheme.primary(add_entry("Play the full game", full_game, settings))
	Glint.on(full)


## Back to the lobby from a map, over Back to title, for whoever decides where the room goes: the
## one machine offline, back to Play, and the host online, back to the waiting room of GAME.md 9.6
## with everybody still connected. Either way it asks first, since it ends the map and any Grand
## Prix it is part of. Online it is only there while the host's say is this machine's, which at a
## dedicated server may come to it in the middle of a map, GAME.md 9.3a.
func offer_the_lobby() -> Button:
	var button := MenuTheme.button("Back to lobby")
	_to_lobby = button
	button.pressed.connect(
		func() -> void:
			var words := lobby_words(session != null, Game.grand_prix != null)
			ask(words, _leave_to_lobby, button)
	)
	_quit.add_sibling(button)
	_quit.get_parent().move_child(button, _quit.get_index())
	return button


## What is asked before going back to the lobby: the question, the line under it and the button
## that goes. Online, with everybody still connected; either way, the end of what is being played.
static func lobby_words(online: bool, grand_prix: bool) -> Array[String]:
	var line := "The Grand Prix ends here." if grand_prix else "This match ends here."
	if online:
		var what := "the Grand Prix" if grand_prix else "this match"
		line = (
			"Everybody comes back to the lobby with you and stays connected, but %s ends here."
			% what
		)
	return ["Back to the lobby?", line, "Back to lobby"]


## What is asked before leaving for the title online, and not offline, where nobody else is in
## it: the host takes everybody's room away with it, and a client only leaves, handing on the host's
## say if it has it at a dedicated server, GAME.md 9.3a, [param saying], to one of the
## [param others] still playing. With nobody else playing there is nobody to hand it to: the game
## ends, for the [param watching] watchers there are, or for nobody.
static func leave_words(
	hosting: bool, saying := false, others := 1, watching := 0
) -> Array[String]:
	if hosting:
		return [
			"Back to the title?",
			"Everybody who has joined will be disconnected.",
			"Disconnect everybody"
		]
	var line := "You leave the room, and the others play on without you."
	if saying and others <= 0:
		line = (
			"You leave the room, and with nobody else playing the game ends for those watching."
			if watching > 0
			else "You leave the room, and with nobody else in it the game ends."
		)
	elif saying:
		line = "You leave the room, the others play on without you, and the host's say passes on."
	return ["Back to the title?", line, "Leave"]


## Who else is in the room, as the host's say sees it, GAME.md 9.3a: players at other machines,
## and watchers. The same list Manage players shows.
static func others_here(session: NetSession) -> Vector2i:
	var others := 0
	var watching := 0
	for guest: Dictionary in session.host_controls.guests():
		if guest.has("color"):
			others += 1
		else:
			watching += 1
	return Vector2i(others, watching)


func _back_to_title() -> void:
	if not asks_before_leaving():
		_leave_to_title()
		return
	var saying := not session.is_host and session.host_controls.mine()
	var here := others_here(session) if saying else Vector2i(1, 0)
	ask(leave_words(session.is_host, saying, here.x, here.y), _leave_to_title, _quit)


## Whether the way back to the title asks first, see [method leave_words]: online, except for a
## host nobody has joined yet, player or watcher. There is nobody to disconnect, and a question
## about them would be a question about nothing.
func asks_before_leaving() -> bool:
	if session == null:
		return false
	return not session.is_host or session.anybody_connected()


func _leave_to_title() -> void:
	set_paused(false)
	Game.go_to_title()


func _leave_to_lobby() -> void:
	set_paused(false)
	if session != null:
		Game.back_to_the_room()
	else:
		Game.go_to_lobby(get_tree().get_first_node_in_group(&"match") as Match)


## Puts [param words], a question, the line under it and the button that goes ahead, in place of
## the menu, or of what is up in its place, and does [param action] if the answer is yes. No, or
## Back, is the menu or that again, with the cursor on [param from], the button that asked.
func ask(words: Array[String], action: Callable, from: Button) -> void:
	_on_yes = action
	_asked_by = from
	_asked_over = _aside if _aside != null else _main
	_asked_over.visible = false
	_switches.visible = false
	if words.size() > 3:
		_confirm.ask(words[0], words[1], words[2], words[3])
	else:
		_confirm.ask(words[0], words[1], words[2])


## Whether a question is up in place of the menu.
func asking() -> bool:
	return _confirm.visible


func _answered(yes: bool) -> void:
	var over := _asked_over
	_put_the_question_away()
	if yes:
		_on_yes.call()
		# Asked over the menu, yes goes on somewhere else; over the list of players, the list is
		# up again, and the row of somebody gone gives the cursor to its Back.
		if over == _main:
			return
	if _asked_by != null and is_instance_valid(_asked_by) and _asked_by.is_visible_in_tree():
		_asked_by.grab_focus()


func _put_the_question_away() -> void:
	_confirm.visible = false
	var over := _asked_over if _asked_over != null and is_instance_valid(_asked_over) else _main
	_asked_over = null
	over.visible = true
	_switches.visible = _panel.visible and over == _main and not in_clubhouse()


## The settings, over the room, with the menu waiting underneath for Back. The match stays paused
## while they are open, as far as this machine has any say in it, GAME.md 3.8.
func open_settings() -> void:
	if _settings != null:
		return
	_panel.visible = false
	_switches.visible = false
	_settings = SETTINGS_SCENE.instantiate()
	_settings.overlay = true
	_settings.closed.connect(_settings_closed)
	add_child(_settings)


## The loyalty program over the menu, GAME.md 8.9, where it was left or on the map at [param at],
## as the pinned note asks; put away, the cursor goes back to its button.
func open_loyalty(at := &"") -> void:
	if _loyalty != null:
		return
	_loyalty = LoyaltyDialog.open(self, false, at)
	_loyalty.put_away.connect(
		func() -> void:
			_loyalty = null
			if _pinned_note != null:
				_pinned_note.look()
			_tag_fresh()
	)


## The catalog over the menu, GAME.md 8.8; put away, the cursor goes back to its button.
func open_catalog() -> void:
	if _catalog != null:
		return
	_catalog = CatalogDialog.open(self)
	_catalog.put_away.connect(
		func() -> void:
			_catalog = null
			_tag_fresh()
	)


## The Clubhouse's buttons in place of the menu's own, the cursor on the first of them, or the
## menu's own back, the cursor on the Clubhouse, GAME.md 3.8, as the title's are.
func show_clubhouse(on: bool) -> void:
	if on == in_clubhouse():
		return
	var own := _resume.get_parent() as Control
	# As tall as the menu's own, with room under its buttons, so the pane and its heading stay put.
	_club.custom_minimum_size.y = own.size.y if on else 0.0
	own.visible = not on
	_club.visible = on
	# The switches over the players' corners are reached from the menu's own buttons.
	_switches.visible = _panel.visible and not on
	var shown := _club_buttons() if on else _buttons()
	_note_under(shown)
	if not on:
		_switches.put_up(_buttons())
	if _panel.visible:
		(shown[0] if on else _clubhouse_button).grab_focus()


## Whether the Clubhouse's buttons are up in place of the menu's own.
func in_clubhouse() -> bool:
	return _club != null and _club.visible


## The Clubhouse's buttons: the loyalty program's once the profile has been welcomed to it, the
## catalog's and the achievements', and Back; a room that offers the kart dialog puts its button
## over Back, see [method offer_kart].
func _fill_clubhouse() -> void:
	if Game.settings.profile.loyalty.welcomed:
		_loyalty_button = MenuTheme.button(LoyaltyDialog.program_name(Game.settings.profile))
		_loyalty_button.name = "Loyalty"
		_loyalty_button.pressed.connect(open_loyalty)
		_club.add_child(_loyalty_button)
	_catalog_button = MenuTheme.button("Catalog")
	_catalog_button.name = "Catalog"
	_catalog_button.pressed.connect(open_catalog)
	_club.add_child(_catalog_button)
	_achievements_button = MenuTheme.button("Achievements")
	_achievements_button.name = "Achievements"
	_achievements_button.pressed.connect(open_achievements)
	_club.add_child(_achievements_button)
	var back := MenuTheme.button("Back")
	back.name = "ClubhouseBack"
	back.pressed.connect(show_clubhouse.bind(false))
	_club.add_child(back)
	# The cursor stays in the list, as it does in the menu's own, see [DriveSwitches]: the switches
	# are not up beside it, and down from Back is the pinned note's way while it shows.
	var listed := _club_buttons()
	for button: Button in listed:
		button.focus_neighbor_left = NodePath(".")
		button.focus_neighbor_right = NodePath(".")
	listed[0].focus_neighbor_top = NodePath(".")
	back.focus_neighbor_bottom = NodePath(".")
	_tag_fresh()


## The Clubhouse's buttons, top to bottom.
func _club_buttons() -> Array[Button]:
	var found: Array[Button] = []
	for child: Node in _club.get_children():
		if child is Button:
			found.append(child)
	return found


## The NEW tags, as the title's Clubhouse wears them, GAME.md 3.8: the program's while a landmark
## won has not been looked at or an edition is owed, the catalog's while a card in it has not, the
## achievements' while one earned has not, Customize kart's, where the room offers it, while a piece
## of dress has not been shown in the kart dialog, 4.4a, and the Clubhouse's while any of them does.
func _tag_fresh() -> void:
	var profile := Game.settings.profile
	var program := Loyalty.has_fresh(profile) or profile.loyalty.owed > 0
	var cards := not profile.catalog.fresh.is_empty()
	var earned := Achievements.has_fresh(profile)
	var dress := _kart_button != null and BayNew.has_new(profile)
	if _loyalty_button != null:
		CatalogCell.tag(_loyalty_button, program)
	if _kart_button != null:
		CatalogCell.tag(_kart_button, dress)
	CatalogCell.tag(_catalog_button, cards)
	CatalogCell.tag(_achievements_button, earned)
	CatalogCell.tag(_clubhouse_button, program or cards or earned or dress)


## The achievements over the menu, GAME.md 8.10, the cursor on [param at]'s, of the profile playing
## or [param whose], as a toast clicked asks; put away, the cursor goes back to the menu.
func open_achievements(at := &"", whose: Profile = null) -> void:
	if _achievements != null and is_instance_valid(_achievements):
		_achievements.call(&"show_achievement", at)
		return
	_achievements = load(ACHIEVEMENTS).call(&"open", self, at, whose)
	_achievements.connect(
		&"put_away",
		func() -> void:
			_achievements = null
			_tag_fresh()
	)


## Whether the settings are open over the room.
func settings_open() -> bool:
	return _settings != null


## Whether the menu or the settings from it are up, which is when nothing else in the room is
## listening.
func is_open() -> bool:
	return (_panel.visible and not _leaving) or _settings != null


## Opens the menu of the room [param tree] is running, if it has one.
static func open_in(tree: SceneTree) -> void:
	tree.call_group(GROUP, &"set_paused", true)


func _exit_tree() -> void:
	_in_tree.erase(self)


## Whether the room [param tree] is running has its menu up.
static func is_open_in(tree: SceneTree) -> bool:
	for menu: PauseMenu in _in_tree:
		if menu.get_tree() == tree and menu.is_open():
			return true
	return false


func _settings_closed() -> void:
	_settings = null
	_panel.visible = true
	# Up again as they now are: the settings may have changed how the first player drives.
	_switches.visible = true
	_switches.put_up(_buttons())
	_note_under(_buttons())
	_resume.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# The settings have the controls while they are up: Escape there is their Back, and a rebind
	# of the pause button is a binding, not a request to close the menu.
	if _settings != null:
		return
	# Kit's folder open over the slip has Escape while it is up: the note looked at closer put back
	# first, then the folder, and only then the menu, STORY.md 7.2. Its group by name: the folder's
	# class reaches far enough into the game to bring this menu round again.
	if not _panel.visible and get_tree().get_first_node_in_group(FOLDERS) != null:
		return
	if event.is_action_pressed(InputActions.PAUSE):
		set_paused(not _panel.visible)
		get_viewport().set_input_as_handled()
		return
	# B on a pad backs out of the menu, GAME.md 4.2. It only closes: a menu nobody has opened is
	# not something to back out of, and B is a button a player will be leaning on anyway. Out of a
	# question it is no, and back to the menu.
	if _panel.visible and event.is_action_pressed(&"ui_cancel"):
		MenuTheme.back_sound()
		if asking():
			_answered(false)
		elif _aside != null:
			_put_away_aside()
		elif in_clubhouse():
			show_clubhouse(false)
		else:
			set_paused(false)
		get_viewport().set_input_as_handled()


## Opens or closes the menu for whoever is at this screen. Alone that is the same thing as
## stopping the match; online it is a request, and the match stops when the last player makes it.
## A row of holes across the list, as the ticket's perforation has, without its bites: the pane
## draws only the one perforation, under its heading, and that one never scrolls.
static func _dotted_rule() -> Control:
	var rule := Control.new()
	rule.custom_minimum_size.y = TicketStyle.HOLE_RADIUS * 2.0
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.draw.connect(
		func() -> void:
			var x := TicketStyle.HOLE_GAP
			while x <= rule.size.x - TicketStyle.HOLE_GAP:
				rule.draw_circle(
					Vector2(x, rule.size.y * 0.5), TicketStyle.HOLE_RADIUS, TicketStyle.HOLE_INK
				)
				x += TicketStyle.HOLE_GAP
	)
	return rule


## The fine print at the foot of the buttons: in a map of a Grand Prix, how the run is played, see
## [method run_words]; nothing otherwise.
func _say_the_run() -> void:
	var room := get_tree().get_first_node_in_group(&"match") as Match
	var words := run_words(room.rules) if room != null and room.rules != null else ""
	_run_line.text = words
	_run_foot.visible = not words.is_empty()


## What a map of a Grand Prix is, as the room's menu says it at its foot, GAME.md 3.8: which
## map of how many, how long each runs, to how many points and what of their jokers everybody takes
## on to the next; nothing for a single map.
static func run_words(rules: MatchRules) -> String:
	if rules.rounds <= 0:
		return ""
	var keep := clampi(rules.keep_jokers, 0, MatchOptions.KEEPS.size() - 1)
	var parts: PackedStringArray = [
		"Grand Prix",
		"map %d of %d" % [rules.round, rules.rounds],
		"%s each" % MatchOptions.length_words(rules.duration),
		"first to %d" % rules.team_target() if rules.target_score > 0 else "no target",
		"jokers: %s" % MatchOptions.KEEPS[keep].to_lower(),
	]
	# Each part kept whole where the line wraps: it breaks between them, never inside one.
	for i: int in parts.size():
		parts[i] = parts[i].replace(" ", "\u00a0")
	return " \u00b7 ".join(parts)


func set_paused(paused: bool) -> void:
	# A question left up is not there the next time the menu opens, nor anything else in its place.
	if asking():
		_put_the_question_away()
	_put_away_aside()
	_leaving = not paused and _panel.visible
	if paused:
		# It opens on its own buttons, whatever it was put away on.
		show_clubhouse(false)
		_say_the_run()
		_panel.visible = true
		_shade.modulate.a = 1.0
	else:
		var shades: Array[CanvasItem] = [_shade]
		MenuTheme.put_away(_main, _gone, shades)
		if _leaving:
			resumed.emit()
	_switches.visible = paused
	if paused:
		MenuTheme.deal(_main)
		_switches.put_up(_buttons())
		_note_under(_buttons())
		_tag_fresh()
	else:
		_switches.take_down()
	if session == null:
		_freeze(paused)
	else:
		# The host closing its menu lets go of a pause it made everybody take.
		if not paused:
			session.host_controls.force_pause(false)
		session.want_pause(paused)
	if paused:
		_resume.grab_focus()


## The menu put away, once it has gone, see [method MenuTheme.put_away].
func _gone() -> void:
	if not _leaving and _panel.visible and _main.visible:
		return
	_leaving = false
	_panel.visible = false


## The pinned note under the pane reached down from the last of [param menu], GAME.md 8.9.
func _note_under(menu: Array[Button]) -> void:
	if _pinned_note != null and not menu.is_empty():
		_pinned_note.above = menu[-1]


## The menu's own buttons, top to bottom, for the switches to be reached from.
func _buttons() -> Array[Button]:
	var found: Array[Button] = []
	for child: Node in _resume.get_parent().get_children():
		if child is Button:
			found.append(child)
	return found


## The match stopped for everybody, from the host's menu, GAME.md 3.8. Online a room only stops
## once everybody has asked, which is the right thing to wait for until somebody has to answer
## the door; this is the host not waiting. Closing the menu lets go of it.
func _force_pause() -> void:
	if session == null or not session.host_controls.mine():
		return
	# Pressed again, it lets go: the room runs on for whoever is not asking to stop.
	session.host_controls.force_pause(not session.host_controls.forcing)
	_show_force()


## Whether the host's button to stop everybody is there: online, with the host's say. Kept up
## while the room stands, with a tick in it while its own pause is what is holding the room, so
## the one who stopped everybody can see they did and let go again, GAME.md 3.8.
func _can_force() -> bool:
	return session != null and session.host_controls.mine()


## The button as the pause stands: ticked and held down while this machine's pause holds the room.
func _show_force() -> void:
	var forcing := session != null and session.host_controls.forcing
	_force.icon = MenuTheme.tick() if forcing else null
	MenuTheme.hold(_force, forcing)


## Puts [param pane] up in place of the menu, with the cursor in it; its Back, or B, is the menu
## again with the cursor on [param from].
func _open_aside(pane: Control, from: Button) -> void:
	_aside = pane
	_aside_from = from
	_main.visible = false
	_switches.visible = false
	pane.call(&"open")


## Steam's own invite dialog over the game, or with Steam's overlay off, the game's own list.
func _invite_friends() -> void:
	if not Store.on() or not Store.steam.lobbies.invite():
		_open_aside(_invites, _invite)


func _put_away_aside() -> void:
	if _aside == null:
		return
	_aside.visible = false
	_aside = null
	_main.visible = true
	_switches.visible = _panel.visible
	if _panel.visible and is_instance_valid(_aside_from) and _aside_from.visible:
		_aside_from.grab_focus()


## The host's button comes and goes as the room stops and starts, and a client that has not opened
## its own menu is told why nothing is moving.
func _process(_delta: float) -> void:
	_force.visible = _panel.visible and _can_force()
	if _force.visible:
		_show_force()
	var says := session == null or session.host_controls.mine()
	_manage.visible = session != null and says
	_door_button.visible = _manage.visible
	_invite.visible = Store.steam_game()
	if _stamp.visible:
		var hung := _stamp.size * STAMP_OFF
		_stamp.position = _main.get_global_rect().position - _panel.get_global_rect().position
		_stamp.position += Vector2(_main.size.x - hung.x, -hung.y)
	if _to_lobby != null:
		_to_lobby.visible = says
	# The say handed to somebody else at a dedicated server, GAME.md 9.3a, takes its panes with it.
	if not says and (_aside == _players or _aside == _door):
		if asking() and _asked_over == _aside:
			_put_the_question_away()
		_put_away_aside()
	_held.visible = (
		session != null
		and not session.is_host
		and session.paused
		and not _panel.visible
		and _settings == null
	)


func _freeze(on: bool) -> void:
	get_tree().paused = on
	if _heading != null:
		_heading.text = heading(session != null, on)


## What the menu is headed, GAME.md 3.8: Paused, which it always is alone, since opening it stops
## the match; online Menu, as the match goes on for the others, until everybody has it open and the
## match has stopped, [param stopped].
static func heading(online: bool, stopped: bool) -> String:
	return "Paused" if stopped or not online else "Menu"
