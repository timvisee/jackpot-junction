class_name ServerList
extends VBoxContainer
## The dedicated servers a player keeps, GAME.md 9.3a, on the Play Online screen, a row each: a grip
## of six dots it is moved up and down the list by, a button with the server's name over its
## address, smaller and in gray, which connects to it, and beside it a pencil that edits it and a
## trash can that takes it off the list.
## Empty to start with: a player adds the servers they play on, or connects to one directly.
##
## A mouse or a finger drags a row by its grip, the other rows making way as it goes, and the box
## scrolls for a row dragged to its edge. The cursor, a pad's or the keyboard's, picks a row up
## with accept on its grip, the row rimmed in gold and the dots an arrow up and down; up and down
## move it a place, the stick a place a push, and accept or back puts it down, as does the cursor
## going anywhere else.
##
## A kept server is a dictionary of its "name", "address" and "port", and "called", what the server
## said it is called the last time it was connected to, GAME.md 9.3a. It belongs to the player
## rather than the machine, with the rest of where they play, see [member Settings.servers].

## [param server] chosen, to connect to, to be taken off the list, or to be edited.
signal chosen(server: Dictionary)
signal removing(server: Dictionary)
signal editing(server: Dictionary)
## [param server] moved to place [param to] on the list by its grip.
signal moved(server: Dictionary, to: int)

## The most servers the list keeps, the longest name one may have, and the longest address: a
## host name at its longest.
const MOST := 20
const NAME_LENGTH := 32
const ADDRESS_LENGTH := 253
## The ink of a server's address under its name: there to be read when it is wanted, and less to
## look at than the name the player gave it.
const WHERE_INK := Color(0.6, 0.6, 0.66)
## How near the top or the bottom of the box round the list a dragged row is for the box to scroll,
## and how fast it does, in pixels a second.
const EDGE := 48.0
const EDGE_SCROLL := 600.0

## The server picked up by its grip, by the cursor to move with up and down or by a pointer
## dragging it; empty for none.
var lifted: Dictionary = {}

## The row a pointer drags by its grip, the place it was picked up from, and where the pointer is.
var _dragged: HBoxContainer
var _dragged_from := 0
var _pointer_y := 0.0
## Which way the stick is held while a server is picked up, which moves it a place a push.
var _stick := 0


func _init() -> void:
	add_theme_constant_override("separation", 8)


func _ready() -> void:
	set_process(false)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


## A kept server, cleaned: [param name] may be empty, and is then what the server is
## [param called], or its address for neither.
static func entry(name: String, address: String, port: int, called := "") -> Dictionary:
	return {
		"name": name.strip_edges().left(NAME_LENGTH),
		"address": address.strip_edges().left(ADDRESS_LENGTH),
		"port": port,
		"called": PlayerNames.clean(called, PlayerNames.TITLE_LENGTH),
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
		var called := str(said.get("called", ""))
		kept.append(entry(str(said.get("name", "")), address, int(port), called))
	return kept


## Where [param server] is, as a player types it: its address, and its port after a colon.
static func where(server: Dictionary) -> String:
	return "%s:%d" % [server["address"], server["port"]]


## What [param server] is called on its row: the name the player gave it, or else the one the
## server gives itself, or where it is for one with neither.
static func label(server: Dictionary) -> String:
	for named: String in [str(server["name"]), str(server.get("called", ""))]:
		if not named.is_empty():
			return named
	return where(server)


## The smaller line under [param server]'s name on its row: where it is, after what the server calls
## itself when the player calls it something else; nothing for one known only by where it is.
static func under(server: Dictionary) -> String:
	if label(server) == where(server):
		return ""
	var named := str(server["name"])
	var called := str(server.get("called", ""))
	if not named.is_empty() and not called.is_empty() and called != named:
		return "%s · %s" % [called, where(server)]
	return where(server)


## Whether [param a] and [param b] are the same server, whatever either is called.
static func same(a: Dictionary, b: Dictionary) -> bool:
	return str(a["address"]).to_lower() == str(b["address"]).to_lower() and a["port"] == b["port"]


## The rows made again for [param servers], with the cursor on the row of [param focus] if that
## is one of them: on its button called [param part], Server, Grip, Edit or Remove, so a server
## being moved keeps the cursor on the grip moving it. One picked up stays picked up.
func show_servers(servers: Array[Dictionary], focus: Dictionary = {}, part := "Server") -> void:
	_dragged = null
	set_process(false)
	for old: Node in get_children():
		remove_child(old)
		old.queue_free()
	if not servers.any(func(each: Dictionary) -> bool: return _is_lifted(each)):
		lifted = {}
	for i: int in servers.size():
		var row := _row(servers[i], i)
		add_child(row)
		_look(row, _is_lifted(servers[i]))
		if not focus.is_empty() and same(servers[i], focus):
			var on := row.find_child("%s%d" % [part, i], false, false) as Button
			if on == null or on.disabled:
				on = row.get_child(0) as Button
			on.grab_focus.call_deferred()


## The button that connects to the row of [param index], or null.
func connect_button(index: int) -> Button:
	return find_child("Server%d" % index, true, false) as Button


## The button that takes the row of [param index] off the list, or null.
func remove_button(index: int) -> Button:
	return find_child("Remove%d" % index, true, false) as Button


## The button of the row of [param index] called [param part], Grip or Edit, or null.
func row_button(part: String, index: int) -> Button:
	return find_child("%s%d" % [part, index], true, false) as Button


## One server: the grip it is moved by, the button that connects to it, its name over where it is,
## smaller and in gray, see [method under], or where it is alone for one with no name, and beside it
## the pencil and the trash can.
func _row(server: Dictionary, index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.set_meta(&"server", server)
	var grip := IconButton.of(IconButton.Kind.GRIP, "Drag to move")
	grip.name = "Grip%d" % index
	grip.mouse_default_cursor_shape = Control.CURSOR_DRAG
	grip.gui_input.connect(_on_grip.bind(row, grip))
	row.add_child(grip)
	var named := not under(server).is_empty()
	var join := MenuTheme.button("", Type.BODY)
	join.name = "Server%d" % index
	join.custom_minimum_size = Vector2(420.0, 64.0 if named else 52.0)
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.pressed.connect(func() -> void: chosen.emit(server))
	row.add_child(join)
	MenuTheme.two_lines(join, label(server), under(server), WHERE_INK)
	var edit := IconButton.of(IconButton.Kind.PENCIL, "Edit")
	edit.name = "Edit%d" % index
	edit.pressed.connect(func() -> void: editing.emit(server))
	row.add_child(edit)
	var remove := IconButton.of(IconButton.Kind.TRASH, "Remove")
	remove.name = "Remove%d" % index
	remove.pressed.connect(func() -> void: removing.emit(server))
	row.add_child(remove)
	return row


## Everything said to a row's grip. A mouse or a finger drags the row by it; the cursor picks it up
## with accept, moves it with up and down, and puts it down with accept or back.
func _on_grip(event: InputEvent, row: HBoxContainer, grip: Button) -> void:
	var server: Dictionary = row.get_meta(&"server")
	var press := event as InputEventMouseButton
	if press != null:
		if press.button_index == MOUSE_BUTTON_LEFT:
			grip.accept_event()
			if press.pressed:
				_drag(row, press.global_position.y)
			else:
				_drop()
		return
	if event is InputEventMouseMotion:
		if _dragged == row:
			grip.accept_event()
			_pointer_y = (event as InputEventMouseMotion).global_position.y
			_follow()
		return
	if event.is_action_pressed(&"ui_accept"):
		grip.accept_event()
		_pick_up({} if _is_lifted(server) else server)
		return
	if not _is_lifted(server) or _dragged != null:
		return
	var by := _step(event)
	if by != 0:
		var to := clampi(row.get_index() + by, 0, get_child_count() - 1)
		if to != row.get_index():
			moved.emit(server, to)
	elif event.is_action_pressed(&"ui_cancel"):
		_pick_up({})
	# Picked up, the cursor stays on it: whatever would take it off the grip is the grip's.
	if event is InputEventJoypadMotion or event.is_action_type():
		grip.accept_event()


## Which way [param event] moves a server picked up: up -1, down 1, or 0. A key or a button again as
## it repeats, and the stick a place a push, back through the middle before the next.
func _step(event: InputEvent) -> int:
	var stick := event as InputEventJoypadMotion
	if stick != null:
		if stick.axis != JOY_AXIS_LEFT_Y:
			return 0
		var way := 0 if absf(stick.axis_value) < 0.5 else int(signf(stick.axis_value))
		var push := way if way != _stick else 0
		_stick = way
		return push
	if event.is_action_pressed(&"ui_up", true):
		return -1
	if event.is_action_pressed(&"ui_down", true):
		return 1
	return 0


## [param server] picked up by the cursor, or with an empty one, whatever was put down.
func _pick_up(server: Dictionary) -> void:
	lifted = server
	_stick = 0
	for row: Node in get_children():
		_look(row as HBoxContainer, _is_lifted(row.get_meta(&"server")))


## A pointer has taken [param row] by its grip at the height [param y].
func _drag(row: HBoxContainer, y: float) -> void:
	_dragged = row
	_dragged_from = row.get_index()
	_pointer_y = y
	_pick_up(row.get_meta(&"server"))
	set_process(true)


## The dragged row moved to the place the pointer is at among the others, which make way for it.
func _follow() -> void:
	var to := 0
	for other: Node in get_children():
		if other != _dragged and _pointer_y > (other as Control).get_global_rect().get_center().y:
			to += 1
	if to != _dragged.get_index():
		move_child(_dragged, to)


## The pointer has let go: the row stays where it was dragged to, and the list is told if that is
## somewhere else.
func _drop() -> void:
	if _dragged == null:
		return
	var row := _dragged
	_dragged = null
	set_process(false)
	_pick_up({})
	if row.get_index() != _dragged_from:
		moved.emit(row.get_meta(&"server"), row.get_index())


## The box round the list scrolls while a row is dragged to its top or its bottom edge.
func _process(delta: float) -> void:
	var box := get_parent()
	while box != null and not box is ScrollContainer:
		box = box.get_parent()
	if _dragged == null or box == null:
		return
	var scroll := box as ScrollContainer
	var edges := scroll.get_global_rect()
	var way := 0
	if _pointer_y < edges.position.y + EDGE:
		way = -1
	elif _pointer_y > edges.end.y - EDGE:
		way = 1
	if way != 0:
		scroll.scroll_vertical += roundi(way * EDGE_SCROLL * delta)
		_follow()


## The cursor anywhere but on the grip of the server picked up puts it down.
func _on_focus_changed(control: Control) -> void:
	if lifted.is_empty() or _dragged != null:
		return
	var row := control.get_parent() as HBoxContainer if control != null else null
	var on_grip := row != null and row.get_parent() == self and control == row.get_child(0)
	if not on_grip or not _is_lifted(row.get_meta(&"server")):
		_pick_up({})


## How [param row] looks: rimmed in gold, its grip an arrow up and down, while it is picked up.
func _look(row: HBoxContainer, up: bool) -> void:
	for each: Node in row.get_children():
		var button := each as Button
		if button == null:
			continue
		var fill := MenuTheme.BUTTON_HOVER if up else MenuTheme.BUTTON_BG
		var rim := Palette.CHIP_GOLD if up else MenuTheme.BUTTON_RIM
		button.add_theme_stylebox_override("normal", MenuTheme.button_style(fill, rim))
	var picture := row.get_child(0).get_node("Picture") as IconButton.Picture
	picture.kind = IconButton.Kind.MOVE if up else IconButton.Kind.GRIP
	picture.queue_redraw()


func _is_lifted(server: Dictionary) -> bool:
	return not lifted.is_empty() and same(server, lifted)


## What the row of [param index] says, its lines one under the other, for asking what it shows.
func row_text(index: int) -> String:
	return MenuTheme.lines_of(connect_button(index))
