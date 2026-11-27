class_name GameList
extends VBoxContainer
## Games there are to join, a row each, GAME.md 9.3: a button with the game's name, the one its host
## gave it or else whose it is, over a smaller line in gray saying whether it is in the lobby or on
## which map, how many play in it of how many may and whether it wants a password, which joins it;
## and an eye beside it, which watches it instead. A game this version cannot play can be neither,
## and one whose host lets nobody watch cannot be watched. The LAN games screen lists the games
## found on the network in one, and Play Online a dedicated server's, 9.3a.
##
## A Steam game, 10.8, says how it is played rather than how many play in it, and draws its seats
## and ping at the row's end instead, see [GameSeats], with Friend after its name when a friend is
## in it. A full one cannot be joined, says so, and can still be watched.

## [param game] chosen, to play in, [param mode] "join", or to watch, "watch".
signal chosen(game: Dictionary, mode: String)

## The longest map a game is said to be on, "Crossfire, map 2 of 3", as a host on the network says
## it.
const MAP_LENGTH := 48
## The Friend and Full tags: their ink, the gold's, and a full game's gray.
const FRIEND_FILL := Palette.CHIP_GOLD
const FULL_FILL := Color(0.36, 0.35, 0.4)


func _init() -> void:
	add_theme_constant_override("separation", 8)


## The rows made again for [param games], which is while a pad's cursor may be on one: it stays on
## the same button of the same game if that is still there, and goes to [param fallback] if not.
func show_games(games: Array[Dictionary], fallback: Control) -> void:
	var had := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var kept := ""
	if had != null and is_ancestor_of(had):
		kept = String(had.name)
	for old: Node in get_children():
		remove_child(old)
		old.queue_free()
	for game: Dictionary in games:
		add_child(_row(game))
	if kept.is_empty():
		return
	var again := find_child(kept, true, false) as Button
	if again != null and not again.disabled:
		again.grab_focus()
	elif fallback != null:
		fallback.grab_focus()


## What [param game] is called: the name its host gave it, or else whose it is, "Ann's game".
static func title_of(game: Dictionary) -> String:
	var title := PlayerNames.clean(str(game.get("title", "")), PlayerNames.TITLE_LENGTH)
	return title if not title.is_empty() else default_title(str(game.get("name", "")))


## What a game hosted by [param host] is called when it was given no name.
static func default_title(host: String) -> String:
	var named := PlayerNames.clean(host)
	return "%s's game" % (named if not named.is_empty() else "Host")


## How [param game] stands, in a line under its name: in the lobby or on which map, how many play
## in it and may, and the rest.
static func describe(game: Dictionary) -> String:
	var where := "In the lobby"
	if not game["lobby"]:
		var map := PlayerNames.clean(str(game.get("map", "")), MAP_LENGTH)
		where = "Playing %s" % map if not map.is_empty() else "Playing"
	var parts: PackedStringArray = [where]
	if bool(game.get("chips", false)):
		var mode := PlayerNames.clean(str(game.get("mode", "")), MAP_LENGTH)
		if not mode.is_empty():
			parts.append(mode)
	else:
		parts.append("%d/%d players" % [game["players"], game["most"]])
	if game["password"]:
		parts.append("password")
	if not NetDoor.compatible(Game.version(), str(game["version"])):
		parts.append("version %s" % game["version"])
	return " · ".join(parts)


## Where [param game] is hosted, for its tooltip: the host's address and port, for a game found on
## the network, or nothing for a server's, which is at the server's address already said over the
## list.
static func where(game: Dictionary) -> String:
	if not game.has("address"):
		return ""
	return "Host: %s:%d" % [game["address"], int(game["port"])]


## One game: the button that joins it, saying what it is, and where it is hosted when a pointer
## rests on it, and the eye beside it.
func _row(game: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var playable := NetDoor.compatible(Game.version(), str(game["version"]))
	var join := MenuTheme.button("", Type.BODY)
	join.name = "Join%d" % int(game["id"])
	MenuTheme.two_lines(join, title_of(game), describe(game), ServerList.WHERE_INK)
	var full := is_full(game)
	if bool(game.get("chips", false)):
		_seats_on(join, game, full)
	# Its words dimmed with it, which are not the button's own.
	if not playable or full:
		join.get_node("Words").modulate.a = 0.5
	join.custom_minimum_size = Vector2(0.0, 64.0)
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.disabled = not playable or full
	join.tooltip_text = where(game)
	join.pressed.connect(func() -> void: chosen.emit(game, "join"))
	row.add_child(join)
	var watch := IconButton.of(IconButton.Kind.EYE, "Watch")
	watch.name = "Watch%d" % int(game["id"])
	watch.disabled = not playable or not bool(game.get("watching", true))
	watch.tooltip_text = ("Watch without a kart" if not watch.disabled else "Not open to watchers")
	watch.pressed.connect(func() -> void: chosen.emit(game, "watch"))
	row.add_child(watch)
	return row


## Whether [param game] has no seat left, a Steam game's, GAME.md 10.8: it can only be watched.
static func is_full(game: Dictionary) -> bool:
	var most := int(game.get("most", 0))
	return bool(game.get("chips", false)) and most > 0 and int(game.get("players", 0)) >= most


## A Steam game's row: its words on the left, the seats and the ping at the end, see [GameSeats],
## and its tags after its name; its whole standing said in words for a screen reader.
func _seats_on(join: Button, game: Dictionary, full: bool) -> void:
	var words := join.get_node("Words") as VBoxContainer
	words.offset_left = 22.0
	words.offset_right = -(GameSeats.WIDTH + 22.0)
	for line: Node in words.get_children():
		(line as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var tags: Array[String] = []
	if bool(game.get("friend", false)):
		tags.append("Friend")
	if full:
		tags.append("Full")
	if not tags.is_empty():
		var named := words.get_node("Name") as Label
		var row := HBoxContainer.new()
		row.name = "NameRow"
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_child(row)
		words.move_child(row, named.get_index())
		words.remove_child(named)
		row.add_child(named)
		# As wide as its words beside the tags, where trimming would shrink it to nothing.
		named.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		for tag: String in tags:
			row.add_child(_tag(tag, FULL_FILL if tag == "Full" else FRIEND_FILL))
	var seats := GameSeats.of(game)
	seats.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	seats.offset_left = -(GameSeats.WIDTH + 18.0)
	seats.offset_right = -18.0
	join.add_child(seats)
	var people := int(game.get("players", 0))
	var standing := "%d of %d players" % [people, int(game.get("most", 0))]
	var bots := int(game.get("bots", 0))
	if bots > 0:
		standing += ", %d bot%s" % [bots, "" if bots == 1 else "s"]
	if seats.ping >= 0:
		standing += ", %d ms" % seats.ping
	var parts: PackedStringArray = [describe(game), standing]
	if not tags.is_empty():
		parts.append(", ".join(PackedStringArray(tags)))
	ScreenReader.name(join, title_of(game), " · ".join(parts))


## A tag after a game's name, its word in small capitals on [param fill].
static func _tag(word: String, fill: Color) -> Label:
	var tag := Label.new()
	tag.name = word + "Tag"
	tag.text = word.to_upper()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	Type.set_font(tag, Type.STRONG, Type.SMALL - 2)
	Type.ink(tag, HouseTheme.ON_FOIL if fill == FRIEND_FILL else HouseTheme.WORDS)
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(4)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	tag.add_theme_stylebox_override("normal", style)
	return tag


## What the row of the game [param id] says, its name over how it stands, for asking what it shows.
func row_text(id: int) -> String:
	return MenuTheme.lines_of(find_child("Join%d" % id, true, false) as Button)
