class_name BayControls
extends RefCounted
## Two of the kart dialog's controls that are more drawing than doing, GAME.md 4.4a: Back, a plate
## the Department of Karts printed, see [method BayArt.draw_back], and the binds that turn the kart
## over the bench's right end, drawn for the device in hand rather than written out; and where the
## binds hung on its buttons go, see [ButtonBinds].

## What the paint chip card says of the color on it: the kart's own, one being tried on, or none
## yet.
const COLOR_YOURS := "yours"
const COLOR_TRYING := "trying it on"
const COLOR_NONE := "No color yet"
const COLOR_PICK := "pick a can"
## How big the learner's L is, screwed to the bench where the plate goes before a license, how far
## round it its kept picture reaches, for its shadow, and the group told when that is ready.
const LEARNER_SIDE := 64.0
const LEARNER_AROUND := 4.0
const LEARNER_GROUP := &"learner_plate"
## How the binds that turn the kart read, by drag or by the stick, and how big they are.
const TURN_DRAG := "%s drag to turn"
const TURN_STICK := "%s to turn"
const TURN_SIZE := 15
const TURN_INK := Color(1.0, 1.0, 1.0, 0.88)


## Back as a plate reading [param printed], [param tip] its tooltip: lifted off the wall while the
## mouse or the cursor is on it, pushed onto it while it is pressed.
static func back_plate(printed: String, tip: String) -> Button:
	var button := Button.new()
	button.name = "Back"
	button.tooltip_text = tip
	button.position = BayArt.BACK.position
	button.size = BayArt.BACK.size
	button.flat = true
	for look: StringName in [
		&"normal", &"hover", &"pressed", &"disabled", &"focus", &"hover_pressed"
	]:
		button.add_theme_stylebox_override(look, StyleBoxEmpty.new())
	button.draw.connect(
		func() -> void:
			var down := button.get_draw_mode() in [Button.DRAW_PRESSED, Button.DRAW_HOVER_PRESSED]
			var lit := button.is_hovered() or button.has_focus()
			BayArt.draw_back(button, Rect2(Vector2.ZERO, button.size), printed, lit, down)
			if button.has_focus():
				button.draw_style_box(FocusGlide.look(), Rect2(Vector2.ZERO, button.size).grow(4.0))
	)
	for told: Signal in [
		button.mouse_entered,
		button.mouse_exited,
		button.focus_entered,
		button.focus_exited,
		button.button_down,
		button.button_up
	]:
		told.connect(button.queue_redraw)
	button.add_to_group(FocusGlide.GROUP)
	return button


## The learner's L where the plate goes before a license, GAME.md 4.4a: the driving school's white
## square with its red L, as the kart wears it, see [SchoolFigure], a screw in each top corner and
## its shadow on the bench. Only to be seen; drawn once and kept, see [BayArt], one draw.
static func learner_plate() -> Control:
	var plate := Control.new()
	plate.name = "Learner"
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.size = Vector2.ONE * LEARNER_SIDE
	plate.add_to_group(LEARNER_GROUP)
	plate.draw.connect(
		func() -> void:
			var whole := Rect2(Vector2.ZERO, plate.size).grow(LEARNER_AROUND)
			var art := BayArt.kept(
				plate,
				"learner:%s" % plate.size,
				whole.size,
				func(on: CanvasItem) -> void:
					draw_learner(on, Rect2(Vector2.ONE * LEARNER_AROUND, plate.size)),
				LEARNER_GROUP
			)
			if art != null:
				plate.draw_texture_rect(art, whole, false)
			else:
				draw_learner(plate, Rect2(Vector2.ZERO, plate.size))
	)
	return plate


## The learner's L in [param box] on [param on]: its shadow, the sign, and its screws.
static func draw_learner(on: CanvasItem, box: Rect2) -> void:
	var square := Rect2(box.position + Vector2(2.0, 4.0), box.size - Vector2(4.0, 4.0))
	BayArt.box(on, square, 6.0, Color(0, 0, 0, 0.4))
	SchoolFigure.draw_into(on, box, SchoolFigure.Kind.LEARNER, SchoolFigure.BOOK_INK)
	for x: float in [10.0, box.size.x - 10.0]:
		BayArt.screw(on, box.position + Vector2(x, 10.0), 3.0, 0.6)


## How the kart is turned, as a dark card of the HUD's hints, its middle at
## [constant BayArt.TURN_HINT]: a turntable's arrow round, and a finger dragging it on a touch
## screen for [param touch], the right stick pushed either way for [param stick], and the mouse
## dragging it otherwise.
static func turn_hint(touch: bool, stick: bool) -> Control:
	var glyph: InputGlyph
	var says := TURN_DRAG
	if touch:
		glyph = InputGlyph.of_finger(TURN_INK, TURN_SIZE)
	elif stick:
		var push := InputEventJoypadMotion.new()
		push.axis = JOY_AXIS_RIGHT_X
		push.axis_value = 1.0
		glyph = InputGlyph.of_event(push, TURN_INK, TURN_SIZE)
		glyph.both_ways = true
		says = TURN_STICK
	else:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		glyph = InputGlyph.of_event(click, TURN_INK, TURN_SIZE)
	var mark := Control.new()
	mark.name = "Turntable"
	mark.custom_minimum_size = Vector2(34.0, 24.0)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.draw.connect(
		func() -> void: BayArt.draw_turntable(mark, Rect2(Vector2.ZERO, mark.size), TURN_INK)
	)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	row.add_child(mark)
	row.add_child(InputHint.row(says, [glyph], TURN_INK, TURN_SIZE))
	var card := InputHint.card(row)
	card.name = "TurnHint"
	card.resized.connect(
		func() -> void: card.position = (BayArt.TURN_HINT - card.size * 0.5).round()
	)
	return card


## The key or pad button that presses what the cursor is on, Enter on a [param keyboard] and A on
## a pad, hung from [param edge], the middle of its foot, as [ButtonBinds] hangs a button's under
## it: a hook's rack opened, a can's color put on, the name or the plate typed into, a name rolled.
static func press_bind(edge: Vector2, keyboard: bool) -> InputGlyph:
	var press: InputEvent
	if keyboard:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		press = key
	else:
		var push := InputEventJoypadButton.new()
		push.button_index = JOY_BUTTON_A
		press = push
	var glyph := InputGlyph.of_event(press, ButtonBinds.INK, ButtonBinds.FONT_SIZE)
	glyph.name = "PressBind"
	_hang(glyph, edge)
	return glyph


## The shuffle's bind, if [param push] wears one, hung under its push button rather than under its
## whole plate.
static func under_push(push: Button) -> void:
	var bind := push.get_node_or_null("Bind") as Control
	if bind != null:
		bind.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_hang(bind, BoardArt.push_of() - push.position + Vector2(0.0, BoardArt.PUSH + 13.0))


## [param glyph] hung from [param edge], a third of it over it, as [ButtonBinds] hangs one.
static func _hang(glyph: Control, edge: Vector2) -> void:
	var wanted := glyph.custom_minimum_size
	glyph.position = (edge - wanted * Vector2(0.5, 0.35)).round()
	glyph.size = wanted


## The paint chip card by the cans drawn on [param on]: the color [param tried] on from them, or
## [param picked], the kart's own, or none yet, see [method BayArt.draw_chip].
static func draw_chip(on: Control, picked: int, tried: int) -> void:
	var shown := tried if tried >= 0 else picked
	var card := Rect2(Vector2.ZERO, on.size)
	if shown < 0:
		BayArt.draw_chip(on, card, Color(0, 0, 0, 0), COLOR_NONE, COLOR_PICK)
		return
	BayArt.draw_chip(
		on,
		card,
		Palette.player_color(shown),
		Palette.color_name(shown),
		COLOR_TRYING if tried >= 0 else COLOR_YOURS
	)
