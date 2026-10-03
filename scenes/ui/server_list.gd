class_name ServerList
extends VBoxContainer
## The dedicated servers a player keeps, GAME.md 9.3a, on the Play Online screen, a row each: a
## button with the server's name over its address, smaller and in gray, which connects to it, and a
## trash can beside it, which takes it off the list.
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
## The ink of a server's address under its name: there to be read when it is wanted, and less to
## look at than the name the player gave it.
const WHERE_INK := Color(0.6, 0.6, 0.66)


func _init() -> void:
	add_theme_constant_override("separation", 8)


## A kept server, cleaned: [param name] may be empty, and is then its address.
static func entry(name: String, address: String, port: int) -> Dictionary:
	return {
		"name": name.strip_edges().left(NAME_LENGTH),
		"address": address.strip_edges().left(ADDRESS_LENGTH),
		"port": port,
	}


## What is wrong with [param typed] as the address of a server or a host, GAME.md 9.3a, or empty for
## nothing: an IPv4 or IPv6 address, the latter with or without its square brackets, or a host name,
## its labels of letters, digits and hyphens, none longer than 63 nor starting or ending with a
## hyphen. All digits and dots is an IPv4 address or nothing, so 999.1.1.1 is not a host name. An
## address with a port after it is said to be one, since the port has a box of its own.
static func address_problem(typed: String) -> String:
	var address := typed.strip_edges()
	if address.is_empty():
		return "Enter an address"
	if address.begins_with("[") and address.ends_with("]"):
		address = address.substr(1, address.length() - 2)
	if address.is_valid_ip_address():
		return ""
	var colon := address.rfind(":")
	if colon > 0 and address.count(":") == 1 and address.substr(colon + 1).is_valid_int():
		if address_problem(address.left(colon)).is_empty():
			return "Put the port in the Port box"
	if not _host_name(address):
		return "That is not an address: use an IP address or a host name"
	return ""


## Whether [param name] is a host name as the internet's rules have one.
static func _host_name(name: String) -> bool:
	var host := name.trim_suffix(".")
	if host.is_empty() or host.length() > ADDRESS_LENGTH:
		return false
	var numbers := true
	for label: String in host.split("."):
		if label.is_empty() or label.length() > 63:
			return false
		if label.begins_with("-") or label.ends_with("-"):
			return false
		for letter: String in label:
			var lower := letter.to_lower()
			var allowed := (lower >= "a" and lower <= "z") or (lower >= "0" and lower <= "9")
			if not allowed and letter != "-":
				return false
		numbers = numbers and label.is_valid_int()
	return not numbers


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
		if not address_problem(address).is_empty() or not port is int:
			continue
		if int(port) <= 0 or int(port) > 65535:
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


## One server: the button that connects to it, its name over where it is, smaller and in gray,
## or where it is alone for one with no name, and the trash can beside it.
func _row(server: Dictionary, index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var named := not str(server["name"]).is_empty()
	var join := MenuTheme.button("", Type.BODY)
	join.name = "Server%d" % index
	join.custom_minimum_size = Vector2(420.0, 64.0 if named else 52.0)
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.pressed.connect(func() -> void: chosen.emit(server))
	row.add_child(join)
	var words := VBoxContainer.new()
	words.name = "Words"
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	join.add_child(words)
	var title := _line(label(server), Type.STRONG, Type.BODY, Color(0.92, 0.92, 0.95))
	title.name = "Name"
	words.add_child(title)
	if named:
		var under := _line(where(server), Type.TEXT, Type.SMALL, WHERE_INK)
		under.name = "Where"
		words.add_child(under)
	var remove := IconButton.of(IconButton.Kind.TRASH, "Remove")
	remove.name = "Remove%d" % index
	remove.pressed.connect(func() -> void: removing.emit(server))
	row.add_child(remove)
	return row


## A line of a row's button, centered, in [param font] at [param size] and [param ink].
static func _line(text: String, font: Font, size: int, ink: Color) -> Label:
	var line := Label.new()
	line.text = text
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(line, font, size)
	Type.ink(line, ink)
	return line


## What the row of [param index] says, its lines one under the other, for asking what it shows.
func row_text(index: int) -> String:
	var button := connect_button(index)
	if button == null:
		return ""
	var lines: PackedStringArray = []
	for each: Node in button.get_node("Words").get_children():
		lines.append((each as Label).text)
	return "\n".join(lines)
