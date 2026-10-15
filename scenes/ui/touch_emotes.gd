class_name TouchEmotes
extends Control
## The emote button of a touch screen, GAME.md 3.8 and 4.2: a small round one beside the menu
## button, with a smile on it, that opens the four emotes in a row beside it, along the top of the
## screen where nothing else is: under it are the board, and the driving buttons further down. A
## tap on one of them puts it up over the kart and shuts the row again; a tap on the button shuts
## it too, and so does one anywhere else, which goes on to whatever it landed on. Only with somebody
## else in the match to see it: against bots alone it is a button for talking to nobody. Somebody
## watching has it too, whose emotes float up from the bottom in gray, see [WatcherEmotes].

## How big the button is, and how far it keeps from the menu button.
const RADIUS := 27.0
const GAP := 14.0
## How big an emote in the row is, and the room between two of them.
const SIDE := 58.0
const SPACING := 10.0

var match_node: Match
## Whether the row of emotes is out.
var open := false:
	set(value):
		open = value
		queue_redraw()


static func attach(hud: MatchHud) -> TouchEmotes:
	var emotes := TouchEmotes.new()
	emotes.name = "TouchEmotes"
	emotes.match_node = hud.match_node
	hud.add_child(emotes)
	return emotes


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## The middle of the button, to the left of the menu button and level with it.
func button_center() -> Vector2:
	var menu := Vector2(size.x - TouchControls.MENU_INSET.x, TouchControls.MENU_INSET.y)
	return menu - Vector2(TouchControls.MENU_RADIUS + GAP + RADIUS, 0.0)


## The middle of emote [param index] in the row beside the button, the first nearest it.
func emote_center(index: int) -> Vector2:
	var first := RADIUS + GAP + SIDE * 0.5
	return button_center() - Vector2(first + index * (SIDE + SPACING), 0.0)


## The slot of the player at this screen, whose emotes these are, or null while there is none.
func _player_slot() -> PlayerSlot:
	for slot: PlayerSlot in match_node.slots:
		var player := slot.input as PlayerInput
		if player != null and player.device == DeviceInput.ANY and slot.kart != null:
			return slot
	return null


## Whether anybody but [param mine] in the match is a person, here or on another machine.
func _anybody_else(mine: PlayerSlot) -> bool:
	for slot: PlayerSlot in match_node.slots:
		if slot != mine and slot.is_human():
			return true
	return false


## Whether this machine is only watching, with emotes but no kart.
func _watching() -> bool:
	return Net.online() and Net.session.watching


func _process(_delta: float) -> void:
	var mine := _player_slot()
	var anybody := _anybody_else(mine) if mine != null else _watching() and _anybody_else(null)
	var shown := not PauseMenu.is_open_in(get_tree()) and not TouchInput.kept_from(self) and anybody
	if shown != visible:
		visible = shown
		open = false


# Heard before the driving controls, which are under it, so a tap that lands on it is its alone.
func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if not visible or touch == null or not touch.pressed:
		return
	var at := get_global_transform_with_canvas().affine_inverse() * touch.position
	if at.distance_to(button_center()) <= RADIUS * TouchControls.REACH:
		open = not open
		get_viewport().set_input_as_handled()
		return
	if not open:
		return
	open = false
	for i: int in EmoteArt.EMOTES.size():
		if at.distance_to(emote_center(i)) <= SIDE * 0.5 * TouchControls.REACH:
			TouchInput.emote(i)
			get_viewport().set_input_as_handled()
			return


func _draw() -> void:
	var middle := button_center()
	var fill := TouchInk.fill_down() if open else TouchControls.FILL
	draw_circle(middle, RADIUS, fill)
	draw_arc(middle, RADIUS, 0.0, TAU, 48, TouchInk.rim(), TouchControls.RIM_WIDTH, true)
	# A smile, in the ink the menu button's bars are drawn in.
	var face := Rect2(middle - Vector2.ONE * RADIUS, Vector2.ONE * RADIUS * 2.0)
	var ink := TouchControls.INK
	IconShapes.disc(self, face, 0.38, 0.4, 0.07, ink)
	IconShapes.disc(self, face, 0.62, 0.4, 0.07, ink)
	draw_arc(IconShapes.at(face, 0.5, 0.48), RADIUS * 0.42, 0.35, PI - 0.35, 16, ink, 3.5, true)
	if not open:
		return
	var slot := _player_slot()
	var color := slot.color() if slot != null else WatcherEmotes.INK
	for i: int in EmoteArt.EMOTES.size():
		var box := Rect2(emote_center(i) - Vector2.ONE * SIDE * 0.5, Vector2.ONE * SIDE)
		EmoteArt.draw_into(self, box, i, color)
