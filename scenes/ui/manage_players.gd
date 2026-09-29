class_name ManagePlayers
extends PanelContainer
## The host's list of everybody in its game, GAME.md 10.3, from its pause menu in place of the menu
## itself: the host's own players first, marked Me, then each other player by the name and color
## of their seat and each watcher by the name the host gave them, with Kick beside every one of
## those. Somebody kicked goes back to the title, told why, and may join again; in the lobby their
## seat is emptied, and on a map a bot takes their kart on, as for anybody who leaves. The list
## follows whoever comes and goes while it is up.

## Back: the menu is up again in its place.
signal closed

const NAME_WIDTH := 320.0
const KICK_SIZE := Vector2(120.0, 44.0)
const HAND_SIZE := Vector2(170.0, 44.0)
const TAG_INK := Color(0.66, 0.66, 0.72)

var session: NetSession

var _rows: VBoxContainer
var _back: Button
var _note: Label
## Who the rows were drawn for, so they are only made again when somebody comes or goes.
var _drawn := ""


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuTheme.pane_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	column.add_child(MenuTheme.title("Players", Type.TITLE))
	_note = MenuTheme.subtitle("", Type.LABEL)
	column.add_child(_note)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	column.add_child(_rows)
	_back = MenuTheme.button("Back")
	_back.pressed.connect(func() -> void: closed.emit())
	column.add_child(_back)


## Up, drawn afresh, with the cursor on the first Kick, or on Back with nobody to kick.
func open() -> void:
	visible = true
	_note.text = "Somebody kicked goes back to the title, and can join again."
	if _handing():
		_note.text = (
			"Somebody kicked goes back to the server's games, and can join again."
			+ " Make host hands them the host's say."
		)
	_drawn = ""
	_redraw()
	var first := _rows.find_children("*", "Button", true, false)
	(first[0] as Button if not first.is_empty() else _back).grab_focus()


func _process(_delta: float) -> void:
	if visible:
		_redraw()


func _redraw() -> void:
	var guests := session.host_controls.guests() if session != null else []
	var mine := _mine()
	var drawn := str(mine) + str(guests)
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
		_rows.add_child(MenuTheme.subtitle("Nobody else is here.", Type.BODY))
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
			found.append({"name": slot.display_name(), "color": slot.color(), "me": true})
	return found


func _row(guest: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var named := Label.new()
	named.text = guest["name"]
	named.custom_minimum_size = Vector2(NAME_WIDTH, 0.0)
	named.clip_text = true
	Type.strong(named, Type.BODY, guest.get("color", TAG_INK))
	row.add_child(named)
	var tag := Label.new()
	tag.text = "Watching" if not guest.has("color") else "Playing"
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Type.text(tag, Type.LABEL, TAG_INK)
	row.add_child(tag)
	# Where the buttons would be on a row without them, so every row is the same height and the
	# buttons line up.
	if guest.get("me", false):
		tag.text = "Me"
		if _handing():
			row.add_child(_room_for(HAND_SIZE))
		row.add_child(_room_for(KICK_SIZE))
		return row
	var peer: int = guest["peer"]
	var seat: int = guest.get("seat", -1)
	# Somebody else playing can be handed the say at a dedicated server, GAME.md 9.3a. A LAN game's
	# host is the machine it runs on, and has nobody to hand it to.
	if _handing() and guest.has("color"):
		var hand := MenuTheme.button("Make host", Type.BODY)
		hand.custom_minimum_size = HAND_SIZE
		hand.pressed.connect(func() -> void: session.host_controls.make_host(peer))
		row.add_child(hand)
	elif _handing():
		row.add_child(_room_for(HAND_SIZE))
	var kick := MenuTheme.button("Kick", Type.BODY)
	kick.custom_minimum_size = KICK_SIZE
	kick.pressed.connect(func() -> void: session.host_controls.kick(peer, seat))
	row.add_child(kick)
	return row


static func _room_for(button: Vector2) -> Control:
	var room := Control.new()
	room.custom_minimum_size = button
	return room


## Whether the say here is a client's at a dedicated server, which it can hand to somebody else.
func _handing() -> bool:
	return session != null and not session.is_host and session.host_controls.mine()
