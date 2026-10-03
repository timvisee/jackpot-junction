class_name ServerList
extends VBoxContainer
## The dedicated servers a player keeps, GAME.md 9.3a, on the Play Online screen, a row each: a
## button with the server's name over its address, which connects to it, and Remove beside it.
## Empty to start with: a player adds the servers they play on, or connects to one directly.
##
## A kept server is a dictionary of its "name", "address" and "port". It belongs to the player
## rather than the machine, with the rest of where they play, see [member Settings.servers].

## [param server] chosen, to connect to, or to be taken off the list.
signal chosen(server: Dictionary)
signal removing(server: Dictionary)

## The most servers the list keeps, the longest name one may have, and the longest address: a
## host name at its longest.
const MOST := 20
const NAME_LENGTH := 32
const ADDRESS_LENGTH := 253


func _init() -> void:
	add_theme_constant_override("separation", 8)


## A kept server, cleaned: [param name] may be empty, and is then its address.
static func entry(name: String, address: String, port: int) -> Dictionary:
	return {
		"name": name.strip_edges().left(NAME_LENGTH),
		"address": address.strip_edges().left(ADDRESS_LENGTH),
		"port": port,
	}


## What a settings file says the kept servers are, as many as make sense and no more: anything
## that is not one is left out rather than trusted.
static func clean(raw: Variant) -> Array[Dictionary]:
	var kept: Array[Dictionary] = []
	if not raw is Array:
		return kept
	for each: Variant in raw:
		if kept.size() >= MOST or not each is Dictionary:
			continue
		var said: Dictionary = each
		var port: Variant = said.get("port")
		var address := str(said.get("address", "")).strip_edges()
		if address.is_empty() or not port is int or int(port) <= 0 or int(port) > 65535:
			continue
		kept.append(entry(str(said.get("name", "")), address, int(port)))
	return kept


## Where [param server] is, as a player types it: its address, and its port after a colon.
static func where(server: Dictionary) -> String:
	return "%s:%d" % [server["address"], server["port"]]


## What [param server] is called on its row: its name, or where it is for one with none.
static func label(server: Dictionary) -> String:
	var named := str(server["name"])
	return named if not named.is_empty() else where(server)


## Whether [param a] and [param b] are the same server, whatever either is called.
static func same(a: Dictionary, b: Dictionary) -> bool:
	return str(a["address"]).to_lower() == str(b["address"]).to_lower() and a["port"] == b["port"]


## The rows made again for [param servers], with the cursor on the row of [param focus] if that
## is one of them.
func show_servers(servers: Array[Dictionary], focus: Dictionary = {}) -> void:
	for old: Node in get_children():
		remove_child(old)
		old.queue_free()
	for i: int in servers.size():
		var row := _row(servers[i], i)
		add_child(row)
		if not focus.is_empty() and same(servers[i], focus):
			(row.get_child(0) as Button).grab_focus.call_deferred()


## The button that connects to the row of [param index], or null.
func connect_button(index: int) -> Button:
	return find_child("Server%d" % index, true, false) as Button


## The button that takes the row of [param index] off the list, or null.
func remove_button(index: int) -> Button:
	return find_child("Remove%d" % index, true, false) as Button


## One server: the button that connects to it, its name over where it is unless it has none, and
## Remove beside it.
func _row(server: Dictionary, index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var named := not str(server["name"]).is_empty()
	var text := label(server) + ("\n" + where(server) if named else "")
	var join := MenuTheme.button(text, Type.BODY)
	join.name = "Server%d" % index
	join.custom_minimum_size = Vector2(420.0, 64.0 if named else 52.0)
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.pressed.connect(func() -> void: chosen.emit(server))
	row.add_child(join)
	var remove := MenuTheme.button("Remove", Type.BODY)
	remove.name = "Remove%d" % index
	remove.custom_minimum_size = Vector2(150.0, 52.0)
	remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	remove.pressed.connect(func() -> void: removing.emit(server))
	row.add_child(remove)
	return row
