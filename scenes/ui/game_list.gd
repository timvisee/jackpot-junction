class_name GameList
extends VBoxContainer
## Games there are to join, a row each, GAME.md 9.3: a button saying whose it is, whether it is
## still in the lobby, how many play in it of how many may and whether it wants a password, which
## joins it, and Watch beside it, which watches it instead. A game this version cannot play can be
## neither, and one whose host lets nobody watch cannot be watched. The LAN games screen lists the
## games found on the network in one, and Play Online a dedicated server's, 9.3a.

## [param game] chosen, to play in, [param mode] "join", or to watch, "watch".
signal chosen(game: Dictionary, mode: String)


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


## A game in a line: whose, how it stands, how many play in it and may, and the rest.
static func describe(game: Dictionary) -> String:
	var parts: PackedStringArray = [
		"%s's game" % game["name"],
		"in the lobby" if game["lobby"] else "playing",
		"%d/%d players" % [game["players"], game["most"]],
	]
	if game["password"]:
		parts.append("password")
	if not NetDoor.compatible(Game.version(), str(game["version"])):
		parts.append("version %s" % game["version"])
	return " · ".join(parts)


## One game: the button that joins it, saying what it is, and Watch beside it.
func _row(game: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var playable := NetDoor.compatible(Game.version(), str(game["version"]))
	var join := MenuTheme.button(describe(game), Type.BODY)
	join.name = "Join%d" % int(game["id"])
	join.custom_minimum_size = Vector2(0.0, 52.0)
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.disabled = not playable
	join.pressed.connect(func() -> void: chosen.emit(game, "join"))
	row.add_child(join)
	var watch := MenuTheme.button("Watch", Type.BODY)
	watch.name = "Watch%d" % int(game["id"])
	watch.custom_minimum_size = Vector2(150.0, 52.0)
	watch.disabled = not playable or not bool(game.get("watching", true))
	watch.tooltip_text = ("Watch without a kart" if not watch.disabled else "Not open to watchers")
	watch.pressed.connect(func() -> void: chosen.emit(game, "watch"))
	row.add_child(watch)
	return row
