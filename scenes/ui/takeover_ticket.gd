class_name TakeoverTicket
extends PanelContainer
## What a player who took over a bot's kart in the middle of a Steam game is told, GAME.md 10.8: a
## paper ticket at the foot of the screen, whose kart it was and what came with it, "You took over
## Kit's kart" over "420 banked · 60 in the pot · 2 jokers", for three seconds.

## How long it stays, and how long it takes to fade.
const SHOWN_FOR := 3.0
const FADE := 0.4
## How far in from the right and over the foot of the screen it stands.
const FROM_SIDE := 48.0
const FROM_FOOT := 190.0

var _title: Label
var _line: Label
var _fading: Tween


## The ticket, on [param room], put up when [param session]'s host says so; none without a session.
static func add_to(room: Node, session: NetSession) -> TakeoverTicket:
	if session == null:
		return null
	var ticket := TakeoverTicket.new()
	ticket.name = "TakeoverTicket"
	var layer := CanvasLayer.new()
	layer.name = "Takeover"
	layer.add_child(ticket)
	room.add_child(layer)
	# A method of the ticket's own, so the session, which outlives the room, lets go of it with it.
	session.host_controls.took_over.connect(ticket.show_for)
	return ticket


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", TicketStyle.cut(HouseTheme.PAPER, 9.0, 22.0, 14.0))
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_title = Label.new()
	Type.set_font(_title, Type.DISPLAY, Type.LARGE)
	Type.ink(_title, HouseTheme.INK)
	column.add_child(_title)
	_line = Label.new()
	Type.set_font(_line, Type.TEXT, Type.LABEL)
	Type.ink(_line, HouseTheme.INK_FAINT)
	column.add_child(_line)


## Up for [constant SHOWN_FOR] seconds: the kart was [param from]'s, with [param banked] banked,
## [param coins] in the pot and [param jokers] jokers.
func show_for(from: String, banked: int, coins: int, jokers: int) -> void:
	_title.text = words(from).to_upper()
	_line.text = came_with(banked, coins, jokers)
	visible = true
	modulate.a = 1.0
	reset_size()
	position = get_viewport_rect().size - size - Vector2(FROM_SIDE, FROM_FOOT)
	if _fading != null:
		_fading.kill()
	_fading = create_tween()
	_fading.tween_interval(SHOWN_FOR - FADE)
	_fading.tween_property(self, "modulate:a", 0.0, FADE)
	_fading.tween_callback(func() -> void: visible = false)


## The ticket's title: whose kart it was.
static func words(from: String) -> String:
	if from.is_empty():
		return Lang.t("You took over a kart")
	return Lang.t("You took over %s's kart") % from


## The line under it: what came with the kart.
static func came_with(banked: int, coins: int, jokers: int) -> String:
	var parts: PackedStringArray = [Lang.t("%d banked") % banked, Lang.t("%d in the pot") % coins]
	parts.append(Lang.tn("%d joker", "%d jokers", jokers) % jokers)
	return " · ".join(parts)
