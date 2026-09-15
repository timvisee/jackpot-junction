extends Control
## Host or join an online match by address and port, GAME.md 9.3. The host plays with the last
## lobby options against bots until friends join and take the bots' karts.

var address_field: LineEdit
var port_field: LineEdit
var host_button: Button
var join_button: Button
var status: Label


func _ready() -> void:
	MenuTheme.background(self)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	centre.add_child(column)
	column.add_child(MenuTheme.title("Play online", 64))
	column.add_child(
		MenuTheme.subtitle(
			"Host a match on your port, or join a friend's address. Direct connection, no relay."
		)
	)
	address_field = LineEdit.new()
	address_field.text = Game.settings.last_address
	address_field.custom_minimum_size = Vector2(320.0, 44.0)
	address_field.add_theme_font_size_override("font_size", 22)
	column.add_child(MenuTheme.row("Address", address_field))
	port_field = LineEdit.new()
	port_field.text = str(Game.settings.last_port)
	port_field.custom_minimum_size = Vector2(320.0, 44.0)
	port_field.add_theme_font_size_override("font_size", 22)
	column.add_child(MenuTheme.row("Port", port_field))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 16.0)
	column.add_child(spacer)
	host_button = MenuTheme.button("Host")
	host_button.pressed.connect(func() -> void: _start("host"))
	column.add_child(host_button)
	join_button = MenuTheme.button("Join")
	join_button.pressed.connect(func() -> void: _start("join"))
	column.add_child(join_button)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(func() -> void: Game.go_to_title())
	column.add_child(back)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)
	host_button.grab_focus()


## The configuration for hosting or joining with the current fields.
func config(mode: String) -> MatchConfig:
	var result := MatchConfig.from_settings(Game.settings)
	result.online = mode
	result.address = address_field.text.strip_edges()
	result.port = (
		int(port_field.text) if port_field.text.is_valid_int() else NetSession.DEFAULT_PORT
	)
	return result


func _start(mode: String) -> void:
	var result := config(mode)
	if result.port <= 0 or result.port > 65535:
		status.text = "Port must be between 1 and 65535"
		return
	if mode == "join" and result.address.is_empty():
		status.text = "Enter the host's address"
		return
	Game.settings.last_address = result.address
	Game.settings.last_port = result.port
	Game.settings.save_to_disk()
	Game.start_match(result)
