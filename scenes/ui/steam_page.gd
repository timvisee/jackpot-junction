class_name SteamPage
extends VBoxContainer
## Play Online's Steam tab, GAME.md 10.8: Quick Play first, with the cursor, see [QuickPlay]; one
## box of every Steam game this player may join, friends' games first, marked Friend, whether public
## or not, then public games, the lowest ping first, a full game last of all; and under it Host a
## game beside who may join it, anyone, friends or those invited, which is kept for next time. Over
## the box, how many are playing the game right now, once that is enough to say. With Steam not
## there, the box says why.
##
## Friends' games are read again every two seconds, since Steam keeps what each friend plays up to
## date by itself; the public list is asked of Steam every five, and the count every thirty.

## How often friends' games are read again, in seconds.
const FRIENDS_EVERY := 2.0
## What the box's link says, at the end of the rows and alone in an empty box: Quick Play's way,
## GAME.md 10.8.
const START_ONE := "Start a game with bots: anybody can join it"
## What the line over the box says, and what it starts with once enough are playing.
const LINE := "Join anybody's game on Steam, or host one."
const PLAYING := "%s playing now. "
## What each way of being open to players is called on the button that picks one.
const WHO_WORDS: Array[String] = ["Anyone can join", "Friends can join", "Invite only"]

## Quick Play, its button pinned at the top of the box, and what it does, see [QuickPlay], given
## by Play Online.
var quick_button: Button
var quick: QuickPlay
## The box, its list, the line over it, and the buttons under it.
var box: ListBox
var games: GameList
var line: Label
var host_button: Button
var who_button: OptionButton

## The games last read: friends', and the public list's.
var _friends: Array[Dictionary] = []
var _public: Array[Dictionary] = []
var _friends_since := FRIENDS_EVERY
var _public_since := SteamPublic.ASK_EVERY
var _count_since := SteamPublic.COUNT_EVERY


func _init() -> void:
	name = "SteamPage"
	add_theme_constant_override("separation", 16)
	# A line over the box as the servers' page has, so the two are one height and turning between
	# them moves nothing.
	line = ListBox.fit(MenuTheme.subtitle(LINE))
	line.name = "Line"
	add_child(line)
	games = GameList.new()
	games.chosen.connect(_join)
	box = ListBox.of("Steam games", games, START_ONE)
	box.link.pressed.connect(quick_play)
	add_child(box)
	# The way on from here, in foil, GAME.md 8.1a: first in the box, over the games, so the box
	# stands where every page's does and turning between them moves nothing.
	quick_button = MenuTheme.primary(MenuTheme.button("Quick Play", Type.BODY))
	quick_button.name = "QuickPlay"
	quick_button.custom_minimum_size = Vector2(0.0, MenuTheme.button_size().y)
	quick_button.pressed.connect(quick_play)
	box.pin(quick_button)
	var ways := ListBox.button_row()
	add_child(ways)
	host_button = ListBox.add_row_button(ways, "Host a game")
	host_button.name = "HostAGame"
	host_button.pressed.connect(host)
	# Who may join a game hosted from here, as Lobby settings has it too, GAME.md 10.8.
	who_button = MenuTheme.option(WHO_WORDS, Game.settings.lobby_who)
	who_button.name = "WhoCanJoin"
	who_button.custom_minimum_size = Vector2(0.0, MenuTheme.button_size().y)
	who_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ScreenReader.label(who_button, "Who can join")
	who_button.item_selected.connect(
		func(who: int) -> void:
			Game.settings.lobby_who = who
			Game.settings.save_to_disk()
	)
	ways.add_child(who_button)
	if not Store.on():
		box.link.visible = false
		quick_button.disabled = true
		host_button.disabled = true
		who_button.disabled = true
		games.add_child(ListBox.fit(MenuTheme.subtitle(Store.missing, Type.BODY)))


func _process(delta: float) -> void:
	# Quick Play has Steam's list to itself while it looks.
	if not Store.on() or not is_visible_in_tree() or (quick != null and quick.is_busy()):
		return
	_friends_since += delta
	_public_since += delta
	_count_since += delta
	var public := Store.steam.public
	if _public_since >= SteamPublic.ASK_EVERY and not public.asking():
		_public_since = 0.0
		public.ask(SteamPublic.WORLDWIDE, _on_listed)
	if _count_since >= SteamPublic.COUNT_EVERY:
		_count_since = 0.0
		if not public.counted.is_connected(_on_counted):
			public.counted.connect(_on_counted)
		public.count()
	if _friends_since >= FRIENDS_EVERY:
		_friends_since = 0.0
		_friends = Store.steam.friends.games()
		for game: Dictionary in _friends:
			game["ping"] = public.ping_of(str(game.get("where", "")))
		show_games()


func _on_listed(found: Array[Dictionary]) -> void:
	_public = found
	show_games()


func _on_counted(players: int) -> void:
	line.text = ((PLAYING % players) if players >= SteamPublic.COUNT_FROM else "") + LINE


## Friends' games and the public ones on the list together, see [method merged].
func show_games() -> void:
	games.show_games(merged(_friends, _public), box.link)


## [param friends]' games and the [param public] ones as the list shows them, GAME.md 10.8: a
## game once, a friend's first, then the lowest ping, a game nobody could tell the ping of after
## those, and a full game last of all.
static func merged(friends: Array[Dictionary], public: Array[Dictionary]) -> Array[Dictionary]:
	var listed: Array[Dictionary] = []
	var lobbies: Array[int] = []
	for game: Dictionary in friends + public:
		var lobby := int(game.get("steam_lobby", 0))
		if lobby in lobbies:
			continue
		lobbies.append(lobby)
		listed.append(game)
	listed.sort_custom(before)
	return listed


## Whether [param a] is listed before [param b], see [method merged].
static func before(a: Dictionary, b: Dictionary) -> bool:
	if GameList.is_full(a) != GameList.is_full(b):
		return not GameList.is_full(a)
	if bool(a.get("friend", false)) != bool(b.get("friend", false)):
		return bool(a.get("friend", false))
	var ping_a := int(a.get("ping", SteamPublic.NO_PING))
	var ping_b := int(b.get("ping", SteamPublic.NO_PING))
	if (ping_a < 0) != (ping_b < 0):
		return ping_a >= 0
	if ping_a != ping_b:
		return ping_a < ping_b
	return GameList.title_of(a).naturalnocasecmp_to(GameList.title_of(b)) < 0


## Where the cursor goes as the page comes up: Quick Play, GAME.md 10.8.
func first_way() -> Control:
	return quick_button


## Quick Play pressed, or the box's link: a game found, or one started, see [QuickPlay].
func quick_play() -> void:
	if quick != null:
		quick.start()


## A Steam game hosted here, GAME.md 10.8, open to whoever the player picked: into its waiting
## room, as a LAN game is.
func host() -> void:
	Game.go_to_waiting(SteamJoins.host_config())


## A game on the list joined, or watched, through Steam, GAME.md 10.8.
func _join(game: Dictionary, mode: String) -> void:
	var joins := get_tree().get_first_node_in_group(SteamJoins.GROUP) as SteamJoins
	if joins != null:
		joins.join(int(game["steam_lobby"]), mode == "watch")
