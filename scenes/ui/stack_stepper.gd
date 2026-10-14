class_name StackStepper
extends Control
## The catalog's field for the stack a joker is shown as, GAME.md 8.8, drawn the way the house's
## switches are, see [method HouseArt.switch], so it sits under one as one of a pair: the switch's
## lane, a little longer, with a chip at either end, minus on the left and plus on the right, and
## the stack between them in gold. A click or a tap on either half steps it that way; an end that
## cannot go further is faded. Left to the mouse and a finger: keys and a pad have the hand's
## button. On the catalog's mat its lane is a pill of the House's paper, as the switch over it is,
## see [member on_paper]. Each chip is a few dozen shapes, its notches and its clay's flecks, so
## each is drawn once into a picture and shown from that, faded by its tint, GAME.md 10.7.

## A click or a tap stepped the stack by [param by], one down or one up.
signal stepped(by: int)

## How big the field is: the switch's height, and room for the two chips and a stack between.
const SIZE := Vector2(88.0, HouseArt.SWITCH.y)
## The lane's dark and its rim, the switch's own when off; the chips' face, the switch's knob off,
## gold under the pointer; how far in the chips sit, and how much of an end that cannot go further
## shows.
const TRACK := Color(0.05, 0.05, 0.07)
const RIM := Color(0.52, 0.51, 0.57)
const CHIP_INSET := 2.5
const FADED := 0.3
const SIGN_INK := Color(0.96, 0.96, 0.98)
const VALUE_SIZE := Type.LABEL
## The group of every stepper, told when a chip's picture is ready, and how far round a chip its
## picture reaches, for its edge's softness.
const PICTURES := &"stack_stepper_pictures"
const PICTURE_ROOM := 2.0

## The stack shown, and the most it can be; none for a card face down.
var value := 0
var limit := 0
## Whether its lane is the House's paper, its rim and its words in ink, laid on the mat with its
## shadow under it, as the switch over it is, see [method AtlasTicketStyle.dress_switch].
var on_paper := false:
	set(paper):
		on_paper = paper
		_lane.bg_color = HouseTheme.PAPER if paper else TRACK
		_lane.border_color = Color(HouseTheme.INK, 0.35) if paper else RIM
		_lane.shadow_color = ProofArt.FALLEN if paper else Color.TRANSPARENT
		_lane.shadow_size = 1 if paper else 0
		_lane.shadow_offset = AtlasTicketStyle.LIFT if paper else Vector2.ZERO
		queue_redraw()

var _lane := StyleBoxFlat.new()
## Which half the pointer is over, -1 or 1, or 0 for neither.
var _over := 0


func _init() -> void:
	add_to_group(PICTURES)
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lane.bg_color = TRACK
	_lane.border_color = RIM
	_lane.set_border_width_all(1)
	_lane.set_corner_radius_all(int(SIZE.y * 0.5))
	_lane.anti_aliasing = true
	mouse_exited.connect(
		func() -> void:
			_over = 0
			queue_redraw()
	)


## Shows [param copies] of at most [param most], or nothing for none.
func show_stack(copies: int, most: int) -> void:
	value = copies
	limit = most
	queue_redraw()


## Whether it can go down, or up.
func can_less() -> bool:
	return value > 1


func can_more() -> bool:
	return value > 0 and value < limit


## What it says between its chips.
func shown() -> String:
	return "×%d" % value if value > 0 else "–"


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		var over := -1 if motion.position.x < size.x * 0.5 else 1
		if over != _over:
			_over = over
			queue_redraw()
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	var by := -1 if click.position.x < size.x * 0.5 else 1
	if (by < 0 and can_less()) or (by > 0 and can_more()):
		Audio.play_sfx(&"ui_click", MenuTheme.CLICK_DB, 0.0)
		stepped.emit(by)


func _draw() -> void:
	draw_style_box(_lane, Rect2(Vector2.ZERO, size))
	var radius := size.y * 0.5
	var chip := radius - CHIP_INSET
	_end(Vector2(radius, radius), chip, -1, can_less())
	_end(Vector2(size.x - radius, radius), chip, 1, can_more())
	var font := Type.STRONG
	var words := shown()
	var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, VALUE_SIZE).x
	var base := radius + (font.get_ascent(VALUE_SIZE) - font.get_descent(VALUE_SIZE)) * 0.5
	draw_string(
		font,
		Vector2((size.x - wide) * 0.5, base),
		words,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		VALUE_SIZE,
		_value_ink()
	)


## The stack's gold, or the rim's gray for none; on paper both the darker that read on it.
func _value_ink() -> Color:
	if value <= 0:
		return HouseTheme.INK_FAINT if on_paper else RIM
	return HouseTheme.on_paper(JokerDetail.STACK) if on_paper else JokerDetail.STACK


## One end's chip round [param middle], [param radius] out, with minus or plus on it as [param by]
## says, gold under the pointer and faded where it cannot go: from its picture, or drawn as itself
## until that is ready.
func _end(middle: Vector2, radius: float, by: int, can: bool) -> void:
	var gold := can and _over == by
	var fade := Color(1.0, 1.0, 1.0, 1.0 if can else FADED)
	var room := radius + PICTURE_ROOM
	var scale_by := maxf(KeptPictures.scale_of(self), 0.25)
	var pixels := Vector2i.ONE * ceili(room * 2.0 * scale_by)
	var picture := KeptPictures.of(
		self,
		"stack_chip|%s|%d|%.1f" % [gold, by, radius],
		pixels,
		func() -> Control:
			var drawing := ChipPicture.new()
			drawing.radius = radius
			drawing.by = by
			drawing.gold = gold
			drawing.scale_by = pixels.x / (room * 2.0)
			return drawing,
		PICTURES
	)
	if picture == null:
		draw_set_transform(middle)
		ChipPicture.paint(self, radius, by, gold, fade.a)
		draw_set_transform(Vector2.ZERO)
		return
	draw_texture_rect(
		picture, Rect2(middle - Vector2.ONE * room, Vector2.ONE * room * 2.0), false, fade
	)


## A chip of the stepper's as a picture: its face, steel or gold, and its sign.
class ChipPicture:
	extends Control

	var radius := 10.0
	var by := 1
	var gold := false
	var scale_by := 1.0

	## A chip [param radius] out round the origin of [param on]'s transform, its face gold where
	## [param gold] says and steel otherwise, minus or plus on it as [param by] says, as strong as
	## [param fade].
	static func paint(on: CanvasItem, radius: float, by: int, gold: bool, fade := 1.0) -> void:
		var face := HouseTheme.FOIL if gold else HouseArt.STEEL
		ChipArt.chip(on, Vector2.ZERO, radius, Color(face, fade), 6)
		var arm := radius * 0.45
		var ink := Color(SIGN_INK, fade)
		on.draw_line(Vector2(-arm, 0.0), Vector2(arm, 0.0), ink, 2.0, true)
		if by > 0:
			on.draw_line(Vector2(0.0, -arm), Vector2(0.0, arm), ink, 2.0, true)

	func _draw() -> void:
		var room := radius + PICTURE_ROOM
		draw_set_transform(Vector2.ONE * room * scale_by, 0.0, Vector2.ONE * scale_by)
		paint(self, radius, by, gold)
