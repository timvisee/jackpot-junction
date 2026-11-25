class_name InputGlyph
extends Control
## One binding drawn rather than written, GAME.md 8.3: a key as a key cap with the key on it, a
## gamepad face button as a round button in its own color, a shoulder or a trigger as a pill,
## a stick as a stick, the D-pad as a D-pad, a mouse button as a mouse with that button lit, and
## a tap on a touch screen as a finger pointing down onto it, and a touch screen's steering as the
## wheel it is drawn as there. A pad's buttons are drawn as its family prints them, see
## [PadFamily]: a PlayStation pad's four as their shapes, a Nintendo pad's letters where they are.
## For a controller Steam Input reads, an action's button is the one Steam has it on, GAME.md 10.8,
## and Steam's own picture of it where it is on what a pad has not got, a back button, a trackpad.
##
## "Shift drift   Ctrl nitro" is a sentence to be read. The same line with the two keys drawn as
## keys is a picture to be recognized, which is what a hint glanced at mid-corner has to be. The
## shapes are drawn rather than loaded, because the bindings belong to the player: any key on the
## keyboard can end up in one of these, and no set of pictures can cover that in advance.

enum Kind { KEY, FACE, SHOULDER, STICK, DPAD, MOUSE, FINGER, WHEEL, ITEM, MENU, PICTURE }
## The shapes a [constant Kind.SHOULDER] takes: a pill with a word on it, a bumper, a trigger, a
## stick pressed in, and a small round button with its picture on it, Menu's three bars, say.
enum Part { PILL, BUMPER, TRIGGER, CLICK, ICON }

## How tall a glyph is by default and how much air sits either side of the caption inside one.
const HEIGHT := 22.0
## The face buttons in the colors everybody's pad has on them, so A reads as A before it is read.
const FACE_COLORS: Dictionary[String, Color] = {
	"A": Color("#5FBF5F"),
	"B": Color("#D9534F"),
	"X": Color("#4A7FD4"),
	"Y": Color("#E8C33D"),
}
## The dark of a chip, kept for what draws a button of its own beside a glyph, see [DressArt].
const CHIP := Color(HouseTheme.STOCK, 0.94)
const EDGE_WIDTH := 1.6
## A PlayStation pad's four shapes in the colors they have always had, by the button: cross,
## circle, square and triangle. Lifted a little to read on a dark button, and deepened to read on a
## light one.
const SHAPE_COLORS: Dictionary[JoyButton, Color] = {
	JOY_BUTTON_A: Color("#7fa6ec"),
	JOY_BUTTON_B: Color("#ec6b6b"),
	JOY_BUTTON_X: Color("#e58fd0"),
	JOY_BUTTON_Y: Color("#4fd0a6"),
}
const SHAPE_DEEP: Dictionary[JoyButton, Color] = {
	JOY_BUTTON_A: Color("#2f63c8"),
	JOY_BUTTON_B: Color("#d23b3b"),
	JOY_BUTTON_X: Color("#c23f99"),
	JOY_BUTTON_Y: Color("#13926a"),
}
## How wider than tall a stick is drawn: its head goes beside it, the way it is pushed.
const STICK_WIDE := 1.55
## How wide Steam's picture of a button may be drawn for how tall, at most and at least.
const PICTURE_WIDE := Vector2(0.8, 2.5)
## How wide a mouse is for how tall it is.
const MOUSE_WIDE := 0.72
## How wide a tap is for how tall it is: a hand with its finger on the glass and the ring of the
## tap round the fingertip, from Google's Material Symbols, see THIRD_PARTY.md and [GlyphArt].
const FINGER_WIDE := 0.8
const DOUBLE_MARK := "\u00d72"
## The meta a node wears to say how every glyph under it is painted, see [method look_under], and
## whose they are, see [method seat_under].
const LOOK_META := &"glyph_look"
const SEAT_META := &"glyph_seat"
## The three buttons a mouse is drawn for; any other is written on a key cap.
const MOUSE_BUTTONS: Array[MouseButton] = [
	MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE
]
## What a touch screen's own buttons are called on them, GAME.md 4.2, for the hint that names one:
## a pill with the word on it, the way the screen has it. Steering is the stick under the left
## thumb, drawn as a stick with nothing written in it.
const TOUCH_WORDS: Dictionary[StringName, String] = {
	InputActions.THROTTLE: "GAS",
	InputActions.BRAKE: "BRAKE",
	InputActions.NITRO: "NITRO",
	InputActions.HANDBRAKE: "DRIFT",
	InputActions.FIRE: "FIRE",
	InputActions.USE_ITEM: "ITEM",
}

var kind := Kind.KEY
## What is written on the glyph: the key, the button, or the stick's side.
var caption := ""
## The color of the line the glyph sits in, which everything but a face button is drawn in.
var ink := Color.WHITE
var font_size := 15
## Which way a stick is moved or a D-pad is pressed, as a unit vector on the screen.
var along := Vector2.RIGHT
## Whether this is a stick that moves both ways along its axis. One binding is half a stick and
## is drawn pushed that way; a pair of them, GAME.md 8.3, is the whole stick and is drawn centered.
var both_ways := false
## Whether this is a stick pushed every way at once, a head on each of its four sides: the way to
## go in simple driving, GAME.md 4.2, rather than one axis of it. Square, being as tall as wide.
## For a mouse: which of its buttons is pressed, and whether twice.
var mouse_button := MOUSE_BUTTON_LEFT
var double_click := false
var every_way := false:
	set(value):
		every_way = value
		# A touch screen's steering is a wheel only for the wheel and pedals: the push of simple
		# driving is the stick it is drawn as there, GAME.md 4.2.
		if every_way and kind == Kind.WHEEL:
			kind = Kind.STICK
		custom_minimum_size = _wanted()
		queue_redraw()

## Whose pad a pad's button is drawn for, see [method pin]: [constant DeviceInput.ANY] for the pad
## touched last, which it follows as the player picks up another; and that pad's family.
var pad := DeviceInput.ANY
var family := PadFamily.Family.GENERIC
## Which of the four buttons under the thumb a face button is, by where it sits on the pad.
var face := JOY_BUTTON_INVALID
## What a button that is not one under the thumb is drawn as, see [enum Part], and which side of
## the pad it is on, -1 the left: a bumper and a trigger lean out to their side.
var part := Part.PILL
var side := 0
## How it is painted, by what it stands on, see [enum GlyphArt.Look].
## How it is painted, by what it stands on: taken as it goes in from the nearest node above it that
## says, see [method look_under], and [constant GlyphArt.Look.LIGHT] where none does.
var look := GlyphArt.Look.LIGHT:
	set(value):
		look = value
		queue_redraw()
## The color of the player whose line it is, or clear for a line nobody's in particular: taken as
## it goes in, as [member look] is, see [method seat_under].
var seat := Color(0, 0, 0, 0):
	set(value):
		seat = value
		queue_redraw()

## The item an item button glyph was last drawn wearing, see [method of_item_button].
var _shown_item := &""
## The pad's button drawn, and [member PadFamily.epoch] when its family was last looked at; and
## whether its words are its own, see [method written].
var _event: InputEvent
var _epoch := -1
var _written := false
## The action drawn, where the glyph is one of an action's on a pad; and where Steam has it bound on
## that pad, see [method DeviceInput.steam_bound], with Steam's own picture of it, if that is drawn.
var _action := &""
var _steam: Dictionary = {}
var _picture: Texture2D
var _picture_svg := ""


func _ready() -> void:
	# Only the item button changes by itself, as the item in hand does, and a pad's button, as the
	# player picks up a pad of another family.
	set_process(kind == Kind.ITEM or _event != null)
	# Drawn on the screen's own pixels, so drawn again where it moves to, see [method _draw].
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()
	elif what == NOTIFICATION_ENTER_TREE:
		look = look_of(self)
		seat = _meta_above(self, SEAT_META, Color(0, 0, 0, 0))


## The first binding of [param action] for one device kind, as a glyph. Null when nothing is
## bound to it there, which is what a hint should leave out rather than write a dash for.
static func of_action(action: StringName, keyboard: bool, ink: Color, font_size: int) -> InputGlyph:
	var event := InputActions.first_event(action, keyboard)
	if event == null:
		return null
	var glyph := of_event(event, ink, font_size)
	if glyph._event != null:
		glyph._action = action
		glyph._refit()
	return glyph


## [param action] as Steam has it bound on its pad [param device], GAME.md 10.8, and drawn again as
## that changes; null where Steam has it on nothing.
static func of_steam(action: StringName, device: int, ink: Color, font_size: int) -> InputGlyph:
	if DeviceInput.steam_bound(action, device).is_empty():
		return null
	# Any button of a pad's to start from: Steam's place for the action is drawn in its stead.
	var stand_in := InputEventJoypadButton.new()
	stand_in.button_index = JOY_BUTTON_A
	var glyph := of_event(stand_in, ink, font_size)
	glyph._action = action
	glyph.pin(device)
	return glyph


## [param action] as the touch screen has it: a pill with the word on its button, or the steering
## wheel the stick is drawn as for steering, see [TouchStick]. Null for an action the screen has
## no button for.
static func of_touch(action: StringName, ink: Color, font_size: int) -> InputGlyph:
	# The pause action on a touch screen is the menu button in the corner, drawn as its three bars,
	# so a hint can name the very button that is there, GAME.md 8.3, see [TouchControls].
	if action == InputActions.PAUSE:
		return _of_menu(ink, font_size)
	var steering := action in [InputActions.STEER_LEFT, InputActions.STEER_RIGHT]
	if not steering and not TOUCH_WORDS.has(action):
		return null
	if action == InputActions.USE_ITEM:
		return of_item_button(ink, font_size)
	var glyph := InputGlyph.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.ink = ink
	glyph.font_size = font_size
	glyph.kind = Kind.WHEEL if steering else Kind.SHOULDER
	glyph.caption = "" if steering else TOUCH_WORDS[action]
	glyph.both_ways = steering
	glyph.along = Vector2.RIGHT
	glyph.custom_minimum_size = glyph._wanted()
	return glyph


## The menu button of a touch screen as a glyph, GAME.md 8.3: the three bars everybody knows, on a
## chip, so a hint names the very button that sits in the corner, see [TouchControls].
static func _of_menu(ink: Color, font_size: int) -> InputGlyph:
	var glyph := InputGlyph.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.ink = ink
	glyph.font_size = font_size
	glyph.kind = Kind.MENU
	glyph.custom_minimum_size = glyph._wanted()
	return glyph


## The item button of a touch screen as it looks just now, GAME.md 8.3: a round button wearing the
## picture of the item in hand, or empty and faint with nothing in it, rather than a pill reading
## ITEM that the button itself never shows. Drawn again as the item in hand changes.
static func of_item_button(ink: Color, font_size: int) -> InputGlyph:
	var glyph := InputGlyph.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.ink = ink
	glyph.font_size = font_size
	glyph.kind = Kind.ITEM
	glyph.custom_minimum_size = glyph._wanted()
	return glyph


## A tap on a touch screen: a hand with its finger on the glass, with the ring of the tap round the
## fingertip, GAME.md 8.3. A word in a pill, "Tap", read as one more button to find.
static func of_finger(ink: Color, font_size: int) -> InputGlyph:
	var glyph := InputGlyph.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.ink = ink
	glyph.font_size = font_size
	glyph.kind = Kind.FINGER
	glyph.custom_minimum_size = glyph._wanted()
	return glyph


## A pill with [param word] on it, for what has no key or button to draw.
static func of_word(word: String, ink: Color, font_size: int) -> InputGlyph:
	var glyph := InputGlyph.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.ink = ink
	glyph.font_size = font_size
	glyph.kind = Kind.SHOULDER
	glyph.caption = word
	glyph.custom_minimum_size = glyph._wanted()
	return glyph


static func of_event(event: InputEvent, ink: Color, font_size: int) -> InputGlyph:
	var glyph := InputGlyph.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.ink = ink
	glyph.font_size = font_size
	glyph.kind = _kind_of(event)
	var click := event as InputEventMouseButton
	if glyph.kind == Kind.MOUSE:
		glyph.mouse_button = click.button_index
		glyph.double_click = click.double_click
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		glyph._event = event
		glyph.family = PadFamily.of_device(glyph.pad)
		glyph._epoch = PadFamily.epoch
	if glyph.kind == Kind.FACE:
		glyph.face = (event as InputEventJoypadButton).button_index
	glyph.caption = _caption_of(event, glyph.kind, glyph.family)
	glyph._shape_as(event)
	glyph.along = _along(event)
	glyph.custom_minimum_size = glyph._wanted()
	return glyph


## Every pad's button drawn under [param root] drawn for the pad [param device] is, rather than
## for the pad touched last: a player's own hints, where they play from a pad of their own.
static func pin_all(root: Node, device: int) -> void:
	if device < 0 or root == null:
		return
	if root is InputGlyph:
		(root as InputGlyph).pin(device)
	for child: Node in root.get_children():
		pin_all(child, device)


## Every glyph under [param root], those there now and those put there later, painted in
## [param look], [enum GlyphArt.Look]: said once by the place, whose rows of hints are built over
## as the device or the line changes.
static func look_under(root: Node, look: GlyphArt.Look) -> void:
	root.set_meta(LOOK_META, look)
	_look_again(root)


## Every glyph under [param root], now and later, one player's, in their [param color]: the lines
## that ride with a kart or stand in its corner of the screen.
static func seat_under(root: Node, color: Color) -> void:
	root.set_meta(SEAT_META, color)
	_look_again(root)


static func _look_again(root: Node) -> void:
	if root is InputGlyph:
		var glyph := root as InputGlyph
		glyph.look = look_of(glyph)
		glyph.seat = _meta_above(glyph, SEAT_META, Color(0, 0, 0, 0))
	for child: Node in root.get_children():
		_look_again(child)


## How a glyph at [param node] is painted: as the nearest node from it up says, see
## [method look_under].
static func look_of(node: Node) -> GlyphArt.Look:
	return _meta_above(node, LOOK_META, GlyphArt.Look.LIGHT)


static func _meta_above(node: Node, meta: StringName, otherwise: Variant) -> Variant:
	var at := node
	while at != null:
		if at.has_meta(meta):
			return at.get_meta(meta)
		at = at.get_parent()
	return otherwise


## [param root] with its pad's buttons drawn for the pad [param device] is, see [method pin_all].
static func pinned(root: Control, device: int) -> Control:
	pin_all(root, device)
	return root


## [param root] with its pad's buttons drawn for the pad of the player driving [param kart].
static func pinned_for(root: Control, kart: Object) -> Control:
	return pinned(root, device_of(kart))


## The pad the player driving [param kart] plays from, or [constant DeviceInput.ANY] for one who
## reads every device or is not at this machine: asked of it by name, so this names no kart.
static func device_of(kart: Object) -> int:
	if kart == null or not is_instance_valid(kart):
		return DeviceInput.ANY
	var input: Variant = kart.get("input")
	var device: Variant = (input as Object).get("device") if input is Object else null
	return device if device is int else DeviceInput.ANY


## This glyph drawn for the pad [param device] is, see [method pin_all].
func pin(device: int) -> void:
	pad = device
	_refit()


## Drawn again for the family of its pad, as that is now, and where Steam has its action bound on
## that pad.
func _refit() -> void:
	_epoch = PadFamily.epoch
	if _event == null:
		return
	var now := PadFamily.of_device(pad)
	var steam := _steam_bound()
	if now == family and steam == _steam:
		return
	family = now
	_steam = steam
	_picture = steam.get("picture") as Texture2D
	_picture_svg = str(steam.get("svg", ""))
	if _picture != null or not _picture_svg.is_empty():
		kind = Kind.PICTURE
		caption = str(steam.get("word", ""))
		# Made bigger than drawn, so it shrinks smoothly, where Steam's own drawing is not had.
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif steam.has("word"):
		# Steam's name for a button it has no picture of, on a pill.
		kind = Kind.SHOULDER
		caption = str(steam["word"])
		part = Part.PILL
	else:
		var drawn: InputEvent = steam.get("event", _event)
		kind = _kind_of(drawn)
		if kind == Kind.FACE:
			face = (drawn as InputEventJoypadButton).button_index
		if not _written:
			caption = _caption_of(drawn, kind, family)
		_shape_as(drawn)
		along = _along(drawn).abs() if both_ways else _along(drawn)
	custom_minimum_size = _wanted()
	queue_redraw()


## Where Steam has the action drawn bound on the pad drawn for, or the pad touched last; empty for
## a pad the game binds itself.
func _steam_bound() -> Dictionary:
	if _action.is_empty() or DeviceInput.steam_pads.is_empty():
		return {}
	return DeviceInput.steam_bound(_action, pad if pad >= 0 else PadFamily.last_pad())


## This glyph with [param words] written on it in place of its own caption, as a key cap can be: an
## arrow for an arrow key, say. Returns itself.
func written(words: String) -> InputGlyph:
	caption = words
	_written = true
	custom_minimum_size = _wanted()
	return self


static func _kind_of(event: InputEvent) -> Kind:
	var button := event as InputEventJoypadButton
	if button != null:
		if (
			button.button_index
			in [
				JOY_BUTTON_DPAD_LEFT,
				JOY_BUTTON_DPAD_RIGHT,
				JOY_BUTTON_DPAD_UP,
				JOY_BUTTON_DPAD_DOWN,
			]
		):
			return Kind.DPAD
		# Only the four under the thumb are round: they are the ones with a single letter on them
		# and a color everybody knows. Start, Back and the stick clicks carry a word, and a word
		# squeezed into a circle is a smudge, so they take the same pill the shoulders do.
		if button.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y]:
			return Kind.FACE
		return Kind.SHOULDER
	var motion := event as InputEventJoypadMotion
	if motion != null:
		var trigger := motion.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]
		return Kind.SHOULDER if trigger else Kind.STICK
	var click := event as InputEventMouseButton
	if click != null and click.button_index in MOUSE_BUTTONS:
		return Kind.MOUSE
	return Kind.KEY


## What a [constant Kind.SHOULDER] for [param event] is drawn as, see [enum Part]: a shoulder
## button as a bumper and a trigger as a trigger, leaning out to their side of the pad, a stick's
## click as the stick pressed in, Menu and View and the like as their pictures, and the rest as a
## word on a pill.
func _shape_as(event: InputEvent) -> void:
	part = Part.PILL
	side = 0
	var button := event as InputEventJoypadButton
	var motion := event as InputEventJoypadMotion
	if (
		button != null
		and button.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]
	):
		part = Part.BUMPER
		side = -1 if button.button_index == JOY_BUTTON_LEFT_SHOULDER else 1
	elif button != null and button.button_index in [JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK]:
		part = Part.CLICK
		side = -1 if button.button_index == JOY_BUTTON_LEFT_STICK else 1
	elif motion != null and motion.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		part = Part.TRIGGER
		side = -1 if motion.axis == JOY_AXIS_TRIGGER_LEFT else 1
	elif button != null and caption in GlyphArt.ICONS:
		part = Part.ICON


## What is written on the glyph. A stick carries which of the two it is and nothing else: the
## ring and the arrows say the rest, and "Left Stick X-Axis +" is a description of an input map
## rather than of anything a player does. The D-pad carries nothing, being one of a kind.
static func _caption_of(event: InputEvent, kind: Kind, drawn: int = -1) -> String:
	if kind == Kind.DPAD:
		return ""
	if kind == Kind.MOUSE:
		var click := event as InputEventMouseButton
		return DOUBLE_MARK if click.double_click else ""
	if kind == Kind.STICK:
		var motion := event as InputEventJoypadMotion
		var right := motion != null and motion.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]
		return "R" if right else "L"
	return InputActions.event_text(event, drawn)


## Which way the stick is pushed or the pad pressed, on the screen: along X or along Y for a
## stick, in the direction the binding actually reads, and the direction itself for a D-pad.
static func _along(event: InputEvent) -> Vector2:
	var motion := event as InputEventJoypadMotion
	if motion != null:
		var way := -1.0 if motion.axis_value < 0.0 else 1.0
		var vertical := motion.axis in [JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_Y]
		return (Vector2.DOWN if vertical else Vector2.RIGHT) * way
	var button := event as InputEventJoypadButton
	if button != null:
		match button.button_index:
			JOY_BUTTON_DPAD_LEFT:
				return Vector2.LEFT
			JOY_BUTTON_DPAD_RIGHT:
				return Vector2.RIGHT
			JOY_BUTTON_DPAD_UP:
				return Vector2.UP
			JOY_BUTTON_DPAD_DOWN:
				return Vector2.DOWN
	return Vector2.RIGHT


## How big this glyph wants to be: as tall as its line asks, and as wide as its picture is for
## that, see [GlyphArt]: square for a button, wider for a word on it.
func _wanted() -> Vector2:
	var tall := HEIGHT * maxf(float(font_size) / 15.0, 1.0)
	var art := _art()
	if art != null:
		return Vector2(art.wide, art.tall) * (tall / GlyphArt.TALL)
	if kind == Kind.PICTURE and _picture != null:
		var wide := float(_picture.get_width()) / maxf(float(_picture.get_height()), 1.0)
		return Vector2(tall * clampf(wide, PICTURE_WIDE.x, PICTURE_WIDE.y), tall)
	return Vector2(tall, tall)


## This glyph's picture, see [GlyphArt]; null for the item button, which is the touch screen's
## own drawn small, and for Steam's picture where only the picture was had and not its drawing.
func _art() -> GlyphArt.Art:
	var art: GlyphArt.Art = null
	match kind:
		Kind.FACE:
			art = _face_art()
		Kind.STICK:
			art = GlyphArt.stick(caption, _ways(), STICK_WIDE, every_way)
		Kind.DPAD:
			art = GlyphArt.dpad(_ways())
		Kind.MOUSE:
			art = GlyphArt.mouse(mouse_button, caption, MOUSE_WIDE)
		Kind.FINGER:
			art = GlyphArt.finger(FINGER_WIDE)
		Kind.WHEEL:
			art = GlyphArt.wheel()
		Kind.MENU:
			art = GlyphArt.icon("Menu")
		Kind.PICTURE:
			art = null if _picture_svg.is_empty() else GlyphArt.steam(_picture_svg)
		Kind.KEY:
			art = GlyphArt.key(caption)
		Kind.SHOULDER:
			art = _shoulder_art()
	return art


## A pad's button that is not one under the thumb, as what it is, see [enum Part].
func _shoulder_art() -> GlyphArt.Art:
	var art: GlyphArt.Art = null
	match part:
		Part.BUMPER:
			art = GlyphArt.bumper(caption, side)
		Part.TRIGGER:
			art = GlyphArt.trigger(caption, side)
		Part.CLICK:
			art = GlyphArt.click(caption)
		Part.ICON:
			art = GlyphArt.icon(caption)
	return art if art != null else GlyphArt.pill(caption)


## A face button as its pad has it: in its color with its letter dark on it where the pad's are
## colored, a PlayStation pad's shape in that shape's color, and a Nintendo pad's or a Steam
## Deck's letter as the rest of the glyphs are written.
func _face_art() -> GlyphArt.Art:
	var shape: int = face if PadFamily.shapes(family) else JOY_BUTTON_INVALID
	if PadFamily.lettered(family) and FACE_COLORS.has(caption):
		return GlyphArt.face(caption, shape, FACE_COLORS[caption], "face_mark")
	if shape != JOY_BUTTON_INVALID:
		var tones := SHAPE_COLORS if look == GlyphArt.Look.DARK else SHAPE_DEEP
		return GlyphArt.face(caption, shape, "face", tones.get(face, Color.WHITE))
	return GlyphArt.face(caption, shape)


## The ways a stick is drawn pushed, or a D-pad pressed: the one its binding reads, both ends of
## the axis for a pair of them, or all four for a stick pushed every way.
func _ways() -> Array[Vector2]:
	# Built rather than written as a conditional literal: an untyped array assigned to a typed one
	# throws, and a throw halfway through a draw is a glyph with nothing in it.
	var ways: Array[Vector2] = [along]
	if both_ways:
		ways.append(-along)
	if every_way:
		ways.assign([Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP])
	return ways


## Where it is drawn: its own height, in the middle of whatever height its row gives it. A row
## stretches each of its glyphs to its tallest, a stick pushed every way, and Steam's round Y
## drawn to that height came out an egg.
func drawn_box() -> Rect2:
	var tall := size.y
	if custom_minimum_size.y > 0.0:
		tall = minf(tall, custom_minimum_size.y)
	return Rect2(0.0, roundf((size.y - tall) * 0.5), size.x, tall)


## Drawn as its picture, see [GlyphArt], made the very size it is on the screen and set on the
## screen's own pixels, so nothing about it is smudged by being stretched or set between two.
func _draw() -> void:
	var box := drawn_box()
	if kind == Kind.ITEM:
		draw_set_transform(box.position)
		_draw_item_button(Rect2(Vector2.ZERO, box.size))
		return
	var art := _art()
	if art == null:
		if _picture != null:
			draw_texture_rect(_picture, fitted(box), false)
		return
	# Its own shape in the middle of the box, never stretched: a row can give a glyph more room
	# than it asked for.
	var unit := box.size.y / art.tall
	var shown := Rect2(
		box.position + Vector2((box.size.x - art.wide * unit) * 0.5, 0.0),
		Vector2(art.wide * unit, box.size.y)
	)
	var to_screen := get_viewport().get_final_transform() * get_global_transform_with_canvas()
	var scale := absf(to_screen.get_scale().y)
	if scale <= 0.0:
		return
	var pixels := Vector2i(
		maxi(roundi(shown.size.x * scale), 1), maxi(roundi(shown.size.y * scale), 1)
	)
	var picture := GlyphArt.texture(GlyphArt.svg(art, ink, pixels, look, seat))
	if picture == null:
		return
	var at := shown.position
	if is_zero_approx(to_screen.x.y) and is_zero_approx(to_screen.y.x):
		at = to_screen.affine_inverse() * (to_screen * at).round()
	draw_texture_rect(picture, Rect2(at, Vector2(pixels) / scale), false, Color(1, 1, 1, ink.a))


## The most of [param box] Steam's picture takes in its own proportions, in the middle of it: a
## box wider or narrower than the picture draws it smaller, never squashed.
func fitted(box: Rect2) -> Rect2:
	var picture := Vector2(_picture.get_size())
	if picture.x <= 0.0 or picture.y <= 0.0:
		return box
	var drawn := picture * minf(box.size.x / picture.x, box.size.y / picture.y)
	return Rect2(box.position + (box.size - drawn) * 0.5, drawn)


## A PlayStation pad's shape for the button [param face] is, drawn on [param on] at [param middle],
## [param reach] out from it, in [param tone]: the cross, the circle, the square or the triangle.
## The leaflet of the whole pad prints them too, see [PadDiagram].
static func draw_shape(
	on: CanvasItem, face: JoyButton, middle: Vector2, reach: float, tone: Color
) -> void:
	var thick := maxf(1.8, reach * 0.36)
	match face:
		JOY_BUTTON_A:
			var arm := reach * 0.82
			on.draw_line(middle - Vector2(arm, arm), middle + Vector2(arm, arm), tone, thick, true)
			on.draw_line(
				middle + Vector2(-arm, arm), middle + Vector2(arm, -arm), tone, thick, true
			)
		JOY_BUTTON_B:
			on.draw_arc(middle, reach * 0.86, 0.0, TAU, 24, tone, thick, true)
		JOY_BUTTON_X:
			var side := reach * 1.5
			var square := Rect2(middle - Vector2(side, side) * 0.5, Vector2(side, side))
			on.draw_rect(square, tone, false, thick)
		JOY_BUTTON_Y:
			var top := middle + Vector2(0.0, -reach * 0.98)
			var corners := PackedVector2Array(
				[
					top,
					middle + Vector2(reach * 0.94, reach * 0.66),
					middle + Vector2(-reach * 0.94, reach * 0.66),
					top,
				]
			)
			on.draw_polyline(corners, tone, thick, true)


## The item button, see [method of_item_button], with the item in hand's picture on it.
func _draw_item_button(box: Rect2) -> void:
	var middle := box.size * 0.5
	var radius := minf(box.size.x, box.size.y) * 0.5 - 1.0
	var holding := TouchInput.item_id != &""
	var strength := 1.0 if holding else TouchControls.FAINT
	draw_circle(middle, radius, Color(TouchControls.FILL, TouchControls.FILL.a * strength))
	var rim := Color(TouchInk.rim(), TouchControls.RIM * strength)
	draw_arc(middle, radius, 0.0, TAU, 32, rim, 1.5, true)
	_shown_item = TouchInput.item_id
	if holding:
		var side := radius * 2.0 * TouchControls.ITEM_ART
		var art := Rect2(middle - Vector2(side, side) * 0.5, Vector2(side, side))
		PowerUpArt.draw_into(self, art, TouchInput.item_id, TouchInput.item_color)


func _process(_delta: float) -> void:
	if kind == Kind.ITEM and TouchInput.item_id != _shown_item:
		queue_redraw()
	if _event != null and _epoch != PadFamily.epoch:
		_refit()
