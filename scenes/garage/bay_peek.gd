class_name BayPeek
extends Control
## The way to the kart dialog on the title, GAME.md 3.8 and 4.4a: the Garage's bay from outside,
## the dialog's enamel sign over a roll-up door two thirds up, the player's kart parked in the lit
## bay behind it between its painted lines, the door's posts and sill striped. It peeks in from the
## right edge over the license while the Clubhouse is up, sliding in as the Clubhouse opens and
## away as it closes, see [method show_in], and stays away on a screen with no room for it there;
## the kart dialog has other ways in, the pause menu's and the settings' Me tab's. It slides out
## under the cursor, or when the menu's cursor comes to it, the door rolling up the rest of the way
## and the kart coming forward, and opens the dialog on a click, a tap or the accept button. The
## cursor reaches it going right from the buttons nearer its height than the license's, and goes
## between it and the license up and down, see [method reach].

signal opened

## Where it stands: away off the right edge, peeking in, or out under the cursor.
enum Place { AWAY, PEEK, OUT }

const SIZE := Vector2(290.0, 350.0)
## How big it is drawn, how much of it shows while it peeks in, how far it leans in and out, where
## its middle stands down the screen, how far in from the edge it comes out under the cursor, how
## long it takes to slide, and how dim it is while it waits.
const SCALE := 0.8
const PEEK := 0.8
const TILT := -0.1
const TILT_OUT := -0.03
const HEIGHT := 0.4
const IN := 28.0
const SLIDE := 0.25
## Opaque, unlike the license's: the kart would show through the door over it.
const DIM := Color(0.66, 0.66, 0.7)
## The room kept round it: from the screen's top and from what else is on the title.
const ROOM := 12.0
## Its parts: the sign, the wall, the opening, how far down the door hangs while it peeks in and
## while it is out, and the kart's picture, how far it comes forward, how it is turned and filmed.
const SIGN := Rect2(25.0, 0.0, 240.0, 72.0)
const WALL := Rect2(0.0, 52.0, 290.0, 298.0)
const OPENING := Rect2(28.0, 112.0, 234.0, 196.0)
const DOOR_DOWN := 62.0
const DOOR_UP := 26.0
const PICTURE := Rect2(30.0, 128.0, 230.0, 188.0)
const FORWARD := 16.0
const TURN := PI - 0.55
const FILM_FRAMES := 3
## The wall's blocks, and the bay's own colors.
const BLOCK := Vector2(48.0, 22.0)
const BLOCK_LINE := Color(0.0, 0.0, 0.0, 0.35)
const WALL_INK := Color("#3b3f45")
const BAY_BACK := Color("#2a2d33")
const BAY_LIGHT := Color(1.0, 0.93, 0.7, 0.28)
const BAY_LINES := Color("#dbad33")
const SIGN_WORDS := Color("#f6eedc")
## The hint by it while it has the cursor, as big as the license's.
const HINT_SIZE := 24
## What its still parts are drawn into once, see [KeptPictures], round it far enough for the
## shadows, and the group the bays waiting on the pictures are in.
const BAKED := Rect2(-24.0, -24.0, SIZE.x + 48.0, SIZE.y + 48.0)
const GROUP := &"bay_peeks"

## Up with the Clubhouse, see [method show_in], and out under the cursor.
var up := false
var out := false

var _title: Control
var _column: Control
var _license: Control
var _buttons: Array[Control] = []
var _door := DOOR_DOWN
var _picture: TextureRect
var _film: SubViewport
var _door_layer: Control
var _front: Control
var _mark: Control
var _hint: Control
var _slide: Tween


## The bay for [param title], by [param column], its menu, over [param license], which may be
## null; away off the right edge until the Clubhouse opens.
static func add_to(title: Control, column: Control, license: Control) -> BayPeek:
	var bay := BayPeek.new()
	bay.name = "BayPeek"
	bay._title = title
	bay._column = column
	bay._license = license
	title.add_child(bay)
	title.resized.connect(bay.place)
	bay.place()
	return bay


func _ready() -> void:
	size = SIZE
	pivot_offset = SIZE * 0.5
	scale = Vector2.ONE * SCALE
	rotation = TILT
	modulate = DIM
	visible = false
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_picture = TextureRect.new()
	_picture.name = "Kart"
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.position = PICTURE.position
	_picture.size = PICTURE.size
	add_child(_picture)
	_door_layer = _layer("Door", _draw_door)
	_front = _layer("Front", _draw_front)
	add_to_group(GROUP)
	_mark = _layer("FocusMark", _draw_mark)
	# A touch screen has no hover to slide under: the tap opens the dialog on the spot.
	if not TouchInput.enabled:
		mouse_entered.connect(slide.bind(true))
		mouse_exited.connect(func() -> void: slide(has_focus()))
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	dress()


func _layer(named: String, paint: Callable) -> Control:
	var layer := Control.new()
	layer.name = named
	layer.size = SIZE
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.draw.connect(paint)
	add_child(layer)
	return layer


## The player's kart filmed standing in the bay as it is dressed now, again after the kart dialog
## has changed it: a few frames, so whatever it wears is in place, then kept.
func dress() -> void:
	if Game.is_headless() or not is_inside_tree():
		return
	if _film != null:
		_film.name = "FilmGone"
		_film.queue_free()
	_film = SubViewport.new()
	_film.name = "Film"
	_film.size = Vector2i(PICTURE.size * 2.0)
	_film.transparent_bg = true
	_film.own_world_3d = true
	# Filmed whether the bay is up or not: it is away off the edge while the Clubhouse is shut.
	_film.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.62, 0.7)
	world.environment = environment
	_film.world_3d = world
	var settings := Game.settings
	var kart := KartVisuals.display_model(
		maxi(settings.seat_color(0), 0), KartStyle.from_array(settings.kart_styles[0])
	)
	KartVisuals.plate_for_here_on(kart)
	kart.rotation.y = TURN
	kart.position.y = -0.25
	_film.add_child(kart)
	var camera := Camera3D.new()
	camera.fov = 34.0
	camera.look_at_from_position(Vector3(0.0, 1.9, 3.5), Vector3(0.0, 0.7, 0.0), Vector3.UP)
	_film.add_child(camera)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.1
	light.rotation_degrees = Vector3(-40.0, -30.0, 0.0)
	_film.add_child(light)
	add_child(_film)
	_picture.texture = _film.get_texture()
	var filming := _film
	for i: int in FILM_FRAMES:
		await get_tree().process_frame
	if is_instance_valid(filming):
		filming.render_target_update_mode = SubViewport.UPDATE_DISABLED


## The menu's cursor between [param buttons], the menu's, this and the license: going right from
## a button it comes to whichever of the two is nearer the button's height while this is up, and
## going left from either it goes to the button showing nearest its own; up and down go between
## them. While this is away the license is reached as it was.
func reach(buttons: Array[Control]) -> void:
	for button: Control in buttons:
		reach_from(button)
	for side: int in [SIDE_TOP, SIDE_RIGHT]:
		set_focus_neighbor(side, get_path())
	set_focus_neighbor(SIDE_BOTTOM, get_path_to(_license) if _license != null else get_path())
	if _license != null:
		_license.gui_input.connect(_on_license_input)


## [param button] one of the menu's buttons too, put in after the rest.
func reach_from(button: Control) -> void:
	_buttons.append(button)
	button.gui_input.connect(_on_button_input.bind(button))


func _on_button_input(event: InputEvent, button: Control) -> void:
	if not up or not event.is_action_pressed(&"ui_right", true):
		return
	var middle := button.get_global_rect().get_center().y
	var to: Control = self
	if _license != null and absf(_middle_of(_license) - middle) < absf(_middle_of(self) - middle):
		to = _license
	button.accept_event()
	to.grab_focus()


func _on_license_input(event: InputEvent) -> void:
	if up and event.is_action_pressed(&"ui_left", true):
		_license.accept_event()
		_back_to_the_buttons(_license)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if event.is_action_pressed(&"ui_left", true):
		accept_event()
		_back_to_the_buttons(self)
	elif (
		(click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
		or (touch != null and touch.pressed)
		or event.is_action_pressed(&"ui_accept")
	):
		accept_event()
		opened.emit()


## The button showing nearest [param from]'s height takes the cursor.
func _back_to_the_buttons(from: Control) -> void:
	var middle := _middle_of(from)
	var nearest: Control = null
	for button: Control in _buttons:
		if not button.is_visible_in_tree():
			continue
		var off := absf(button.get_global_rect().get_center().y - middle)
		if nearest == null or off < absf(nearest.get_global_rect().get_center().y - middle):
			nearest = button
	if nearest != null:
		nearest.grab_focus()


## How far down the screen [param control]'s middle is, turned and scaled as it is.
static func _middle_of(control: Control) -> float:
	return (control.get_global_transform() * Rect2(Vector2.ZERO, control.size)).get_center().y


## In from the right edge as the Clubhouse opens, [param on], or away off it as it closes; never
## in on a screen with no room for it.
func show_in(on: bool) -> void:
	up = on and has_room()
	focus_mode = Control.FOCUS_ALL if up else Control.FOCUS_NONE
	if _license != null:
		_license.focus_neighbor_top = _license.get_path_to(self if up else _license)
	if up:
		visible = true
	elif out:
		out = false
		_door = DOOR_DOWN
		_picture.position = PICTURE.position
		_door_layer.queue_redraw()
	_move(_middle(Place.PEEK if up else Place.AWAY), TILT, DIM, DOOR_DOWN)
	_slide.tween_callback(func() -> void: visible = up)


## Out from the edge under the cursor, [param to_out], or back to peeking in.
func slide(to_out: bool) -> void:
	if not up or to_out == out:
		return
	out = to_out
	var place := Place.OUT if out else Place.PEEK
	_move(
		_middle(place),
		TILT_OUT if out else TILT,
		Color.WHITE if out else DIM,
		DOOR_UP if out else DOOR_DOWN
	)
	if out:
		Audio.play_sfx(&"ui_move", MenuTheme.MOVE_DB, 0.0)


func _move(middle: Vector2, tilt: float, tint: Color, door: float) -> void:
	if _slide != null and _slide.is_valid():
		_slide.kill()
	_slide = create_tween()
	_slide.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_slide.set_parallel(true)
	_slide.tween_property(self, "position", middle - SIZE * 0.5, SLIDE)
	_slide.tween_property(self, "rotation", tilt, SLIDE)
	_slide.tween_property(self, "modulate", tint, SLIDE)
	_slide.tween_method(_roll, _door, door, SLIDE)
	var forward := PICTURE.position + Vector2(0.0, FORWARD if door == DOOR_UP else 0.0)
	_slide.tween_property(_picture, "position", forward, SLIDE)
	_slide.chain()


func _roll(to: float) -> void:
	_door = to
	_door_layer.queue_redraw()


## Where it stands on the screen once the screen's size changes, and away should there be no room
## for it now.
func place() -> void:
	if up and not has_room():
		show_in(false)
		return
	position = _middle(Place.OUT if out else (Place.PEEK if up else Place.AWAY)) - SIZE * 0.5


## Where its middle is, on the title, [param at] the [enum Place].
func _middle(at: Place) -> Vector2:
	var screen := _title.size if _title != null else Vector2(1920.0, 1080.0)
	var wide := SIZE.x * SCALE
	var y := screen.y * HEIGHT
	match at:
		Place.OUT:
			return Vector2(screen.x - wide * 0.5 - IN, y)
		Place.PEEK:
			return Vector2(screen.x - wide * PEEK + wide * 0.5, y)
	return Vector2(screen.x + wide, y)


## Whether it has the room, peeking in and out under the cursor: on the screen top to bottom, clear
## of the menu and of the license as they are turned, with [constant ROOM] to spare round it.
func has_room() -> bool:
	if _title == null:
		return false
	var around: Array[PackedVector2Array] = [_corners_on_title(_column)]
	if _license != null:
		around.append(_corners_on_title(_license))
	for at: Place in [Place.PEEK, Place.OUT]:
		var mine := _corners(at)
		var box := Rect2(mine[0], Vector2.ZERO)
		for corner: Vector2 in mine:
			box = box.expand(corner)
		if box.position.y < 0.0 or box.end.y > _title.size.y:
			return false
		for each: PackedVector2Array in around:
			if not Geometry2D.intersect_polygons(mine, each).is_empty():
				return false
	return true


## [param control]'s corners on the title, turned and scaled as it is.
func _corners_on_title(control: Control) -> PackedVector2Array:
	var turn := control.get_global_transform()
	turn.origin -= _title.global_position
	return turn * _box_corners(Rect2(Vector2.ZERO, control.size))


## Its corners on the title [param at] the [enum Place], leaning as it does there, with
## [constant ROOM] round them.
func _corners(at: Place) -> PackedVector2Array:
	var turn := Transform2D(TILT_OUT if at == Place.OUT else TILT, _middle(at))
	return turn * _box_corners(Rect2(-SIZE * SCALE * 0.5, SIZE * SCALE).grow(ROOM))


static func _box_corners(box: Rect2) -> PackedVector2Array:
	return PackedVector2Array(
		[
			box.position,
			Vector2(box.end.x, box.position.y),
			box.end,
			Vector2(box.position.x, box.end.y)
		]
	)


func _on_focus(on: bool) -> void:
	slide(on)
	_mark.queue_redraw()


## The hint by it while it has the cursor, of the accept button on the keyboard for
## [param keyboard], or the pad's; none for [param shown] false.
func show_hint(shown: bool, keyboard: bool) -> void:
	if _hint != null:
		_hint.name = "HintGone"
		_hint.queue_free()
		_hint = null
	if not shown or not has_focus():
		return
	var glyph := InputGlyph.of_action(&"ui_accept", keyboard, Palette.CHIP_WHITE, HINT_SIZE)
	if glyph == null:
		return
	_hint = glyph
	_hint.name = "Hint"
	_hint.scale = Vector2.ONE / SCALE
	add_child(_hint)
	var wide := _hint.get_combined_minimum_size() / SCALE
	_hint.position = Vector2(-wide.x - 18.0, WALL.end.y - wide.y)


## The still parts as the pictures they were drawn into, once those are ready, see [KeptPictures]:
## the wall and the bay behind the kart, and over it the door's drum, its posts and sill, and the
## sign. Drawn as themselves until then.
func _draw() -> void:
	var back := _baked("bay_back", _paint_back)
	if back != null:
		draw_texture_rect(back, BAKED, false)
	else:
		_paint_back(self)


func _draw_front() -> void:
	var front := _baked("bay_front", _paint_front)
	if front != null:
		_front.draw_texture_rect(front, BAKED, false)
	else:
		_paint_front(_front)


## The picture of [param key], drawn by [param paint] for as many pixels as it is shown at, or null
## till it is ready.
func _baked(key: String, paint: Callable) -> Texture2D:
	var by := ceilf(KeptPictures.scale_of(self) * 4.0) / 4.0
	return KeptPictures.of(
		self,
		key,
		Vector2i((BAKED.size * by).round()),
		func() -> Control: return Baked.new(paint, by),
		GROUP,
		&"_on_baked"
	)


func _on_baked() -> void:
	queue_redraw()
	_front.queue_redraw()


## The wall and the bay inside it: its back wall with the Garage's red line along it, its floor,
## the light on it and the lines painted on it.
static func _paint_back(on: CanvasItem) -> void:
	BayArt.shadow(on, WALL, 6.0, 16, 0.5, 6.0)
	on.draw_rect(WALL, WALL_INK)
	var lines := PackedVector2Array()
	var row := 0
	var y := WALL.position.y
	while y < WALL.end.y:
		lines.append_array([Vector2(WALL.position.x, y), Vector2(WALL.end.x, y)])
		var x := WALL.position.x + (0.0 if row % 2 == 0 else BLOCK.x * 0.5)
		while x < WALL.end.x:
			lines.append_array([Vector2(x, y), Vector2(x, minf(y + BLOCK.y, WALL.end.y))])
			x += BLOCK.x
		y += BLOCK.y
		row += 1
	on.draw_multiline(lines, BLOCK_LINE, 1.5)
	on.draw_rect(Rect2(WALL.position, Vector2(WALL.size.x, 6.0)), Color(1.0, 1.0, 1.0, 0.08))
	var back := Rect2(OPENING.position, Vector2(OPENING.size.x, 118.0))
	on.draw_rect(back, BAY_BACK)
	on.draw_rect(
		Rect2(back.position + Vector2(0.0, 70.0), Vector2(back.size.x, 6.0)), BayArt.RED_LINE
	)
	var floor := Rect2(Vector2(OPENING.position.x, back.end.y), Vector2(OPENING.size.x, 78.0))
	on.draw_rect(floor, BayArt.FLOOR)
	BayArt.glow(on, Vector2(SIZE.x * 0.5, 250.0), 120.0, BAY_LIGHT)
	var left := Vector2(70.0, back.end.y)
	var right := Vector2(220.0, back.end.y)
	on.draw_line(left, Vector2(48.0, floor.end.y), BAY_LINES, 3.0, true)
	on.draw_line(right, Vector2(242.0, floor.end.y), BAY_LINES, 3.0, true)
	on.draw_line(left, right, BAY_LINES, 2.0, true)


## Over the kart, the door rolled up as far as it is: its slats, the bar along its foot with the
## handle, and the dark it throws onto the bay.
func _draw_door() -> void:
	var door := Rect2(OPENING.position, Vector2(OPENING.size.x, _door))
	_door_layer.draw_rect(door, BayArt.GALVANIZED)
	var slats := PackedVector2Array()
	var shine := PackedVector2Array()
	var y := door.position.y + 9.0
	while y < door.end.y - 6.0:
		slats.append_array([Vector2(door.position.x, y), Vector2(door.end.x, y)])
		shine.append_array([Vector2(door.position.x, y + 2.0), Vector2(door.end.x, y + 2.0)])
		y += 9.0
	if not slats.is_empty():
		_door_layer.draw_multiline(slats, BayArt.GALVANIZED_LOW, 2.0)
		_door_layer.draw_multiline(shine, Color(1.0, 1.0, 1.0, 0.35), 1.0)
	_door_layer.draw_rect(
		Rect2(Vector2(door.position.x, door.end.y - 7.0), Vector2(door.size.x, 7.0)), BayArt.STEEL
	)
	_door_layer.draw_rect(
		Rect2(Vector2(SIZE.x * 0.5 - 13.0, door.end.y), Vector2(26.0, 6.0)), BayArt.CHROME_LOW
	)
	_door_layer.draw_rect(
		Rect2(Vector2(OPENING.position.x, door.end.y), Vector2(OPENING.size.x, 10.0)),
		Color(0.0, 0.0, 0.0, 0.3)
	)


## Over the door: the drum it rolls up into, the striped posts and sill, and the kart dialog's
## enamel sign, small.
static func _paint_front(on: CanvasItem) -> void:
	on.draw_rect(Rect2(14.0, 98.0, 262.0, 16.0), BayArt.STEEL)
	on.draw_rect(Rect2(14.0, 98.0, 262.0, 3.0), BayArt.STEEL_HIGH)
	BoardArt.stripes(on, Rect2(14.0, 114.0, 14.0, 194.0), BoardArt.PAINT, 10.0, 22.0)
	BoardArt.stripes(on, Rect2(262.0, 114.0, 14.0, 194.0), BoardArt.PAINT, 10.0, 22.0)
	BoardArt.stripes(on, Rect2(14.0, 308.0, 262.0, 12.0), BoardArt.PAINT, 10.0, 22.0)
	BayArt.shadow(on, SIGN, 10.0, 10, 0.45, 4.0)
	BayArt.box(on, SIGN, 10.0, BayArt.ENAMEL)
	BayArt.box(on, SIGN.grow(-4.0), 7.0, BayArt.ENAMEL_RED)
	BayArt.ring(on, SIGN.grow(-8.0), 5.0, BayArt.ENAMEL, 1.5)
	var middle := SIGN.get_center()
	BayArt.words(on, middle + Vector2(0.0, -6.0), BayArt.TITLE, 34, SIGN_WORDS, Type.mark_font())
	BayArt.words(
		on,
		middle + Vector2(0.0, 19.0),
		BayArt.UNDER_TITLE,
		10,
		Color(SIGN_WORDS, 0.8),
		Type.display_font()
	)
	for corner: Vector2 in [
		SIGN.position + Vector2(10.0, 10.0),
		Vector2(SIGN.end.x - 10.0, SIGN.position.y + 10.0),
		Vector2(SIGN.position.x + 10.0, SIGN.end.y - 10.0),
		SIGN.end - Vector2(10.0, 10.0)
	]:
		BayArt.screw(on, corner, 3.0, 0.7)


func _draw_mark() -> void:
	if has_focus():
		FocusMark.draw_on(_mark, WALL, 6.0, SIDE_LEFT, SCALE)


## What a still part is drawn by into its picture, [member by] times as many pixels as it has.
class Baked:
	extends Control

	var paint: Callable
	var by := 1.0

	func _init(painted: Callable, scaled: float) -> void:
		paint = painted
		by = scaled

	func _draw() -> void:
		draw_set_transform(-BAKED.position * by, 0.0, Vector2.ONE * by)
		paint.call(self)
