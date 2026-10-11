class_name StripStyle
extends StyleBox
## A strip of the house's stock, GAME.md 8.1a: what is glanced at while driving, bled off an edge
## of the screen with its other end slanted, and a stripe of color along that end where the strip
## says whose it is. The corner blocks of the HUD, the rows of the standings and the lines of the
## kill feed are cut from it. Its banknote waves, its seal and its line of microprint are worked
## out once for a size and kept, as a ticket's are, see [TicketStyle].

## How many sizes are kept worked out at once: a board of four rows is four sizes.
const KEPT := 8
## How the waves under a strip are laid, and how big its microprint is set: small enough to read
## as a rule from a step back, big enough to read as words up close, larger on a touch screen,
## a phone's, where the screen is a few inches across and seven of its units were a line nobody
## could read however close they held it.
const WAVE_GAP := 10.0
const WAVE_HEIGHT := 4.0
const WAVE_LENGTH := 150.0
const MICRO_SIZE := 9
const MICRO_TOUCH := 14

## The stock, a little clear so the table shows at the edges of the eye.
@export var fill := Color(HouseTheme.STOCK, 0.86):
	set = _set_fill
## How far the slanted end leans over the strip's height.
@export var slant := 14.0:
	set = _set_slant
## The stripe along the slanted end, clear for none, and how wide it is.
@export var stripe := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_stripe
@export var stripe_width := 8.0:
	set = _set_stripe_width
## A short wash of color fading inward from both ends of the strip, from the stripe and from the
## edge it comes off, clear for none, at its strongest at the ends; and how far in it reaches.
@export var glow := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_glow
@export var glow_width := 40.0:
	set = _set_glow_width
## Which edge the strip comes off: the left one, with its slanted end on the right, or the right
## one, with its slanted end on the left.
@export var off_right := false:
	set = _set_off_right
## Which way the end leans: wide at the top, for a strip hung from the top of the screen, or wide
## at the bottom, for one standing on the bottom of it.
@export var wide_at_bottom := false:
	set = _set_wide_at_bottom
## Foil along the top and the bottom edge, for the leader's row; clear for none.
@export var edge_top := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_edge_top
@export var edge_bottom := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_edge_bottom
## The engraving: its ink, whether waves run across the whole strip, how big the seal by the
## slanted end is, and the words of the microprint along the foot; nothing for any of them empty.
@export var engraving := Color(0.0, 0.0, 0.0, 0.0):
	set = _set_engraving
@export var waves := false:
	set = _set_waves
@export var seal := 0.0:
	set = _set_seal
@export var micro := "":
	set = _set_micro
@export var micro_size := MICRO_SIZE:
	set = _set_micro_size
## The texture over the stock, see [Surface], how strongly it is laid, and the light on the strip
## from its top left; nothing for none.
@export var surface := Surface.Kind.NONE:
	set = _set_surface
@export var surface_ink := 0.0:
	set = _set_surface_ink
@export var light := 0.0:
	set = _set_light

var _kept: Dictionary[Vector2, Dictionary] = {}
var _order: Array[Vector2] = []


## A strip off the left or the right edge, [param leaning] over its height, with content margins
## [param outer] on the side it comes off, [param inner] on its slanted end and [param down] above
## and below.
static func cut(right: bool, leaning: float, outer: float, inner: float, down: float) -> StripStyle:
	var style := StripStyle.new()
	style.off_right = right
	style.slant = leaning
	style.content_margin_left = inner if right else outer
	style.content_margin_right = outer if right else inner
	style.content_margin_top = down
	style.content_margin_bottom = down
	Surface.wear(style, "hud")
	return style


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	var made := _made(rect.size)
	RenderingServer.canvas_item_add_set_transform(to_canvas_item, Transform2D(0.0, rect.position))
	var shape: PackedVector2Array = made["shape"]
	if fill.a > 0.0:
		RenderingServer.canvas_item_add_polygon(to_canvas_item, shape, [fill])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, made["closed"], [fill], 1.0, true)
		Surface.draw(to_canvas_item, made, shape, rect.size, surface, surface_ink)
		Surface.light(to_canvas_item, shape, rect.size, light)
	Engraving.draw(to_canvas_item, made["lines"], engraving, made["inks"])
	if glow.a > 0.0:
		var clear := Color(glow, 0.0)
		var faded := PackedColorArray([glow, clear, clear, glow])
		for wash: String in ["glow_end", "glow_edge"]:
			RenderingServer.canvas_item_add_polygon(to_canvas_item, made[wash], faded)
	if stripe.a > 0.0:
		RenderingServer.canvas_item_add_polygon(to_canvas_item, made["stripe"], [stripe])
	if edge_top.a > 0.0:
		var top: PackedVector2Array = made["top"]
		RenderingServer.canvas_item_add_line(to_canvas_item, top[0], top[1], edge_top, 1.6, true)
	if edge_bottom.a > 0.0:
		var bottom: PackedVector2Array = made["bottom"]
		RenderingServer.canvas_item_add_line(
			to_canvas_item, bottom[0], bottom[1], edge_bottom, 1.0, true
		)
	var words: String = made["micro"]
	if not words.is_empty():
		var font := Type.STRONG
		var at: Vector2 = made["micro_at"]
		font.draw_string(
			to_canvas_item,
			at,
			words,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			micro_size,
			Color(engraving, minf(engraving.a * 6.5, 0.5))
		)
	RenderingServer.canvas_item_add_set_transform(to_canvas_item, Transform2D.IDENTITY)


## The points of a strip [param size] big, the way it is cut here, from the edge it comes off round
## to its slanted end.
func outline(size: Vector2) -> PackedVector2Array:
	var w := size.x
	var h := size.y
	var lean := minf(slant, w * 0.5)
	var top_end := w if not wide_at_bottom else w - lean
	var bottom_end := w - lean if not wide_at_bottom else w
	return _mirrored(
		PackedVector2Array(
			[Vector2(0.0, 0.0), Vector2(top_end, 0.0), Vector2(bottom_end, h), Vector2(0.0, h)]
		),
		w
	)


func _made(size: Vector2) -> Dictionary:
	if _kept.has(size):
		return _kept[size]
	var made := {}
	var w := size.x
	var h := size.y
	var shape := outline(size)
	made["shape"] = shape
	var closed := shape.duplicate()
	closed.append(shape[0])
	made["closed"] = closed
	var lean := minf(slant, w * 0.5)
	var top_end := w if not wide_at_bottom else w - lean
	var bottom_end := w - lean if not wide_at_bottom else w
	var band := minf(stripe_width, w * 0.25)
	made["stripe"] = _mirrored(
		PackedVector2Array(
			[
				Vector2(top_end - band, 0.0),
				Vector2(top_end, 0.0),
				Vector2(bottom_end, h),
				Vector2(bottom_end - band, h),
			]
		),
		w
	)
	# The washes of [member glow], each listed from its strong end at the top round to its strong end
	# at the bottom: in from the stripe along the slanted end, and in from the edge it comes off.
	var reach := minf(glow_width, w * 0.3)
	made["glow_end"] = _mirrored(
		PackedVector2Array(
			[
				Vector2(top_end - band, 0.0),
				Vector2(top_end - band - reach, 0.0),
				Vector2(bottom_end - band - reach, h),
				Vector2(bottom_end - band, h),
			]
		),
		w
	)
	made["glow_edge"] = _mirrored(
		PackedVector2Array(
			[Vector2(0.0, 0.0), Vector2(reach, 0.0), Vector2(reach, h), Vector2(0.0, h)]
		),
		w
	)
	made["top"] = _mirrored(PackedVector2Array([Vector2(0.0, 0.8), Vector2(top_end, 0.8)]), w)
	made["bottom"] = _mirrored(
		PackedVector2Array([Vector2(0.0, h - 0.5), Vector2(bottom_end, h - 0.5)]), w
	)
	var lines: Array[PackedVector2Array] = []
	var inks: Array[PackedColorArray] = []
	if engraving.a > 0.0:
		if waves:
			lines.append_array(
				Engraving.waves(
					Rect2(0.0, WAVE_GAP * 0.5, w, h), WAVE_GAP, WAVE_HEIGHT, WAVE_LENGTH
				)
			)
		if seal > 0.0:
			var middle := Vector2(minf(top_end, bottom_end) - band - seal * 1.2, seal * 1.1)
			middle = _mirrored(PackedVector2Array([middle]), w)[0]
			lines.append_array(Engraving.rings(middle, seal, seal * 0.08, 18, 10, 180))
			lines.append_array(Engraving.rosette(middle, seal * 0.62))
		lines = Engraving.inside(lines, shape)
		for line: PackedVector2Array in lines:
			inks.append(PackedColorArray([engraving]))
	made["lines"] = lines
	made["inks"] = inks
	made["micro"] = ""
	if not micro.is_empty() and engraving.a > 0.0:
		var room := minf(top_end, bottom_end) - band - 24.0
		var font := Type.STRONG
		var words := ""
		while (
			font.get_string_size(words + micro, HORIZONTAL_ALIGNMENT_LEFT, -1, micro_size).x < room
		):
			words += micro
		while (
			words.length() > 0
			and (font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, micro_size).x > room)
		):
			words = words.substr(0, words.length() - 1)
		made["micro"] = words.strip_edges()
		var x := 14.0
		if off_right:
			x = (
				w
				- 14.0
				- font.get_string_size(made["micro"], HORIZONTAL_ALIGNMENT_LEFT, -1, micro_size).x
			)
		made["micro_at"] = Vector2(x, h - 6.0)
	if _order.size() >= KEPT:
		_kept.erase(_order.pop_front())
	_kept[size] = made
	_order.append(size)
	return made


## [param points] turned round for a strip off the right edge.
func _mirrored(points: PackedVector2Array, w: float) -> PackedVector2Array:
	if not off_right:
		return points
	var turned := PackedVector2Array()
	for point: Vector2 in points:
		turned.append(Vector2(w - point.x, point.y))
	return turned


func _changed() -> void:
	_kept.clear()
	_order.clear()
	emit_changed()


func _set_fill(value: Color) -> void:
	fill = value
	emit_changed()


func _set_slant(value: float) -> void:
	slant = value
	_changed()


func _set_stripe(value: Color) -> void:
	stripe = value
	emit_changed()


func _set_stripe_width(value: float) -> void:
	stripe_width = value
	_changed()


func _set_glow(value: Color) -> void:
	glow = value
	_changed()


func _set_glow_width(value: float) -> void:
	glow_width = value
	_changed()


func _set_off_right(value: bool) -> void:
	off_right = value
	_changed()


func _set_wide_at_bottom(value: bool) -> void:
	wide_at_bottom = value
	_changed()


func _set_edge_top(value: Color) -> void:
	edge_top = value
	emit_changed()


func _set_edge_bottom(value: Color) -> void:
	edge_bottom = value
	emit_changed()


func _set_engraving(value: Color) -> void:
	engraving = value
	_changed()


func _set_waves(value: bool) -> void:
	waves = value
	_changed()


func _set_seal(value: float) -> void:
	seal = value
	_changed()


func _set_micro(value: String) -> void:
	micro = value
	_changed()


func _set_micro_size(value: int) -> void:
	micro_size = value
	_changed()


func _set_surface(value: Surface.Kind) -> void:
	surface = value
	_changed()


func _set_surface_ink(value: float) -> void:
	surface_ink = value
	emit_changed()


func _set_light(value: float) -> void:
	light = value
	emit_changed()
