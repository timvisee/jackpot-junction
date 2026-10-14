class_name AtlasCover
extends Control
## What dresses the loyalty dialog's pane as the House's road atlas, GAME.md 8.9, see [AtlasArt].
## Under everything in the pane, the cover and what lies on it: drawn once into a picture of the
## pane at its size and shown from that every frame, and drawn as itself only until that picture is
## ready, or while the pane is still changing size. Over everything, the tape at the map's corners,
## the photo corners that hold the card, and the card's bind. It stands last in the pane, over the
## rest, and takes no input.

## What a picture of [method piece] is of.
enum Kind { TAPE, SLIT, PENCIL, COIL }

## How far in from the card's bottom right corner the middle of its bind is drawn, on the photo
## corner there, as the License page's is on the license.
const BIND_IN := 6.0
## How many frames the pane keeps its size and its layout before its cover is drawn into a picture
## at them: the dialog's layout settles over the first frame or two it is up, and a window dragged
## to another size changes it every frame until it is let go of, so a picture is drawn once rather
## than at every size it passes.
const REST := 2
## The room round the pane the picture takes in, for the cover's shadow and its ribbons.
const ROOM := 48.0
## The room inside the cover round what is in the pane, left, top, right and foot, with room and
## short of it: at the foot as much as leaves the rules and the atlas's name clear under the map,
## and the tape at the map's foot inside the cover's edge.
const INSIDE: Array[float] = [50.0, 48.0, 50.0, 44.0]
const INSIDE_SHORT: Array[float] = [24.0, 22.0, 24.0, 38.0]
## How long a strip of tape at a corner of the map is, with room and short of it.
const TAPE := 80.0
const TAPE_SHORT := 64.0
## The group of what shows the pictures of [method piece], told once they are drawn; the room round
## each picture for its shadow and its torn ends, and how far a pencil's shadow falls.
const PICTURES := &"atlas_pictures"
const PICTURE_ROOM := 6.0
const PENCIL_FALL := Vector2(3.0, 5.0)
## The pocket the card lies in: how far round the card it is pressed, its dark, the deeper shade
## along its top edge and how deep that is, and the light its bottom lip catches.
const POCKET_OUT := 4.0
const POCKET := Color(0.02, 0.03, 0.07, 0.62)
const POCKET_SHADE := Color(0.0, 0.0, 0.0, 0.5)
const POCKET_SHADE_WIDE := 4
const POCKET_LIP := Color(1.0, 1.0, 1.0, 0.14)
## The room between the details and the card: as little as leaves the card's bind room over it; on
## a short screen, how tall it is at the least for a pencil to lie in it, how far in from its right
## and up from its foot the pencil's point is, how long the pencil is at the most and the least,
## its length rounded down to a step so a few pictures do for every screen, and how it is turned.
const SPARE_LEAST := 18.0
const SPARE_TALL := 56.0
const SPARE_IN := 18.0
const SPARE_UP := 22.0
const SPARE_PENCIL := 300.0
const SPARE_SHORTEST := 160.0
const SPARE_STEP := 20.0
const SPARE_TURN := -0.07
## The pencil lies in the room right of the map's tabs, over its top edge: how tall that row is at
## the least for it, how long it is, how far short of the map's right edge its point stops, clear of
## the tape there, how far clear of the tabs and their binds it keeps, how much higher its point
## is than its end, and how far over the middle of its row it lies.
const PENCIL_ROW := 30.0
const PENCIL_LONG := 430.0
const PENCIL_SHORT := 90.0
const PENCIL_CLEAR := 24.0
const PENCIL_RISE := 22.0
const PENCIL_UP := 5.0
## The dividers left of Back, at the column's foot: how far left of Back their points stop, how
## long their legs are, the way they point, toward Back and a little down, and the room they need
## between Back and the column's left edge.
const DIVIDERS_SHORT := 32.0
const DIVIDERS_REACH := 110.0
const DIVIDERS_TOWARD := 0.12
const DIVIDERS_ROOM := 160.0

## The cover last drawn into a picture, and what it was drawn for. Kept for the run, so the dialog
## opened again at the same size shows it from its first frame.
static var _kept: Texture2D
static var _kept_key := ""

## The pane it dresses, and what in it the things on and over the cover go by: the map's well and
## the row of its tabs over it, the line beside the title and the switches at the head's right, the
## card's place and Back; and the room under the details, which has a pencil lying in it on a short
## screen.
var pane: PanelContainer
var well: Control
var tabs: Control
var line: Label
var switches: Control
var card: Control
var back: Control
var spare: Spare
## Whether the pane fills a short screen, see [method fit].
var short := false
## The atlas's name, in the foot of its rules, the story's at the stage it is at.
var motto := ""

## What the cover is being drawn into a picture for, what it was last asked for, and the frame that
## last changed on.
var _drawing := ""
var _wanted := ""
var _changed_frame := 0


## The cover as a picture, drawn by [DrawnTexture] at its pixels: the pane's room and the room round
## it, scaled up to them.
class Drawing:
	extends Control

	var room: Vector2
	var scale_by := 1.0
	var short := false
	var motto := ""
	var places: AtlasArt.Places

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		var room_round := Vector2.ONE * AtlasCover.ROOM * scale_by
		var base := Transform2D(0.0, Vector2.ONE * scale_by, 0.0, room_round)
		draw_set_transform_matrix(base)
		AtlasArt.cover(self, Rect2(Vector2.ZERO, room), short, motto, places, base)


## A strip of tape, a photo corner, the top left one, a pencil, or the coil along the
## top of a slip, as a picture drawn once a run: the tape's middle, the card's corner, the pencil's
## eraser end or the slip's top left corner at [member middle] of the picture's room.
class Piece:
	extends Control

	var kind := AtlasCover.Kind.TAPE
	var long := 0.0
	var middle: Vector2
	var scale_by := 1.0

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		var base := Transform2D(0.0, Vector2.ONE * scale_by, 0.0, middle * scale_by)
		draw_set_transform_matrix(base)
		match kind:
			AtlasCover.Kind.TAPE:
				AtlasArt.tape(self, Vector2.ZERO, 0.0, long)
			AtlasCover.Kind.SLIT:
				AtlasArt.slit(self, Vector2.ZERO, Vector2.ONE)
			AtlasCover.Kind.PENCIL:
				AtlasArt.pencil(self, Vector2.ZERO, Vector2(long, 0.0), base)
			AtlasCover.Kind.COIL:
				AtlasArt.coil(self, Vector2.ZERO, long)


## The card's place at the column's foot, holding it: a pocket pressed into the cloth under it,
## dark, that shows once the card is taken out, as the letter's darker spot does once the card is
## torn off it. Shown while the card is.
class Pocket:
	extends Control

	var card: Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		size_flags_vertical = Control.SIZE_SHRINK_END
		custom_minimum_size = card.custom_minimum_size
		add_child(card)
		card.position = Vector2.ZERO
		visible = card.visible
		card.visibility_changed.connect(func() -> void: visible = card.visible)

	func _draw() -> void:
		var hollow := Rect2(Vector2.ZERO, size).grow(AtlasCover.POCKET_OUT)
		var round_by := int(LoyaltyCard.CORNER * LoyaltyDialog.CARD_SCALE + AtlasCover.POCKET_OUT)
		var dark := StyleBoxFlat.new()
		dark.bg_color = AtlasCover.POCKET
		dark.border_color = AtlasCover.POCKET_SHADE
		dark.border_width_top = AtlasCover.POCKET_SHADE_WIDE
		dark.border_blend = true
		dark.set_corner_radius_all(round_by)
		draw_style_box(dark, hollow)
		var lip := StyleBoxFlat.new()
		lip.draw_center = false
		lip.border_color = AtlasCover.POCKET_LIP
		lip.border_width_bottom = 1
		lip.set_corner_radius_all(round_by)
		draw_style_box(lip, hollow.grow(1.0))


## The room in the column between the details and the card. On a short screen, which has no card and
## no foot, a pencil lies at its bottom right wherever there is room for one, from its own picture,
## so the details growing or shrinking from landmark to landmark draw nothing again.
class Spare:
	extends Control

	var lying := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		custom_minimum_size.y = AtlasCover.SPARE_LEAST
		add_to_group(AtlasCover.PICTURES)
		resized.connect(queue_redraw)

	func _draw() -> void:
		if not lying or size.y < AtlasCover.SPARE_TALL:
			return
		var long := minf(size.x - AtlasCover.SPARE_IN * 2.0, AtlasCover.SPARE_PENCIL)
		long = floorf(long / AtlasCover.SPARE_STEP) * AtlasCover.SPARE_STEP
		if long < AtlasCover.SPARE_SHORTEST:
			return
		var to := size - Vector2(AtlasCover.SPARE_IN, AtlasCover.SPARE_UP)
		var from := to - Vector2.from_angle(AtlasCover.SPARE_TURN) * long
		AtlasCover.piece(self, AtlasCover.Kind.PENCIL, from, AtlasCover.SPARE_TURN, long)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(PICTURES)
	pane.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	pane.draw.connect(_draw_cover)
	# What lies on the cover goes by where these are; what lies over it, by the well and the card.
	for each: Control in [well, back, tabs, line, switches]:
		each.item_rect_changed.connect(pane.queue_redraw)
		each.visibility_changed.connect(pane.queue_redraw)
	for each: Control in [well, card]:
		each.item_rect_changed.connect(queue_redraw)
		each.visibility_changed.connect(queue_redraw)
	for signal_of: Signal in [card.item_rect_changed, card.visibility_changed, resized]:
		signal_of.connect(_place_bind)
	set_process(false)


## The cover with room round the pane or [param short] of it, where the pane fills the screen: the
## room inside it round the pane's contents, and it drawn again.
func fit(is_short: bool) -> void:
	short = is_short
	var inside := pane.get_theme_stylebox(&"panel") as StyleBoxEmpty
	var room := INSIDE_SHORT if short else INSIDE
	for side: int in 4:
		inside.set_content_margin(side as Side, room[side])
	if spare != null:
		spare.lying = short
		spare.queue_redraw()
	pane.queue_redraw()
	queue_redraw()


## Dresses [param pane] as the atlas's cover, last in it, over the rest: what lies on it and over
## it going by [param parts], each by its name, see [member pane], and [param motto] stamped in its
## foot; the details' slip, as [code]slip[/code] among them, turning its pages over it.
static func dress(
	pane: PanelContainer, parts: Dictionary[StringName, Control], motto: String
) -> AtlasCover:
	var cover := AtlasCover.new()
	cover.name = "Cover"
	cover.pane = pane
	cover.well = parts[&"well"]
	cover.tabs = parts[&"tabs"]
	cover.line = parts[&"line"] as Label
	cover.switches = parts[&"switches"]
	cover.card = parts[&"card"]
	cover.back = parts[&"back"]
	cover.spare = parts[&"spare"] as Spare
	cover.motto = motto
	pane.add_child(cover)
	# The slip's page turns over its coil on the cover, clear of the side column's scroll.
	var slip := parts.get(&"slip") as LoyaltyPane
	if slip != null:
		slip.turn_on(cover)
	return cover


## The room inside a cover with room round the pane, as a pane's own look, to be put on the pane
## before it is laid out.
static func inside() -> StyleBoxEmpty:
	var room := StyleBoxEmpty.new()
	for side: int in 4:
		room.set_content_margin(side as Side, INSIDE[side])
	return room


## Where the things on the cover lie: the pencil right of the map's tabs, over its top edge, its
## point short of the map's right edge, where the tabs and their binds leave it the room, or with no
## tabs in the head, past the line beside the title, where the switches leave it the room; and the
## dividers left of Back at the foot of the column, where there is room for them. A short screen
## has Back in its head and little room right of its tabs, and nothing lies on its cover; the
## atlas's name there is under the map's middle, clear of the tape on its corners, which come down
## near it. Laid out from the map's edge, or the line's, rather than from the binds, the pencil lies
## in the same place whatever binds are drawn, so the cover is drawn again only where it no longer
## has the room.
func places() -> AtlasArt.Places:
	var placed := AtlasArt.Places.new()
	if short:
		placed.name_at = _on_pane(well).get_center().x
		return placed
	var row := _on_pane(tabs)
	var to_x := _on_pane(well).end.x - PENCIL_SHORT
	var from_x := to_x - PENCIL_LONG
	var taken := row.position.x + tabs.get_combined_minimum_size().x + PENCIL_CLEAR
	var middle := row.get_center().y - PENCIL_UP
	var has_tabs := tabs.is_visible_in_tree() and row.size.y >= PENCIL_ROW
	if not has_tabs and line.is_visible_in_tree():
		# No tabs: in the head, past the line's words.
		var font := line.get_theme_font(&"font")
		var size_of := line.get_theme_font_size(&"font_size")
		var said := font.get_string_size(line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_of).x
		from_x = _on_pane(line).position.x + said + PENCIL_CLEAR * 2.0
		to_x = from_x + PENCIL_LONG
		taken = from_x
		middle = _on_pane(line).get_center().y - PENCIL_UP
		if to_x > _on_pane(switches).position.x - PENCIL_CLEAR:
			from_x = -INF
	if (has_tabs or line.is_visible_in_tree()) and from_x >= taken:
		placed.pencil_from = Vector2(from_x, middle + PENCIL_RISE * 0.5)
		placed.pencil_to = Vector2(to_x, middle - PENCIL_RISE * 0.5)
	var at := _on_pane(back)
	if at.position.x - _on_pane(well).end.x >= DIVIDERS_ROOM:
		var tips := Vector2(at.position.x - DIVIDERS_SHORT, at.get_center().y)
		placed.toward = DIVIDERS_TOWARD
		placed.reach = DIVIDERS_REACH
		placed.hinge = tips - Vector2.from_angle(DIVIDERS_TOWARD) * DIVIDERS_REACH
	return placed


## The cover under the pane's contents: its picture, or, until that is ready for the pane as it
## now is, the cover drawn as itself and its picture asked for.
func _draw_cover() -> void:
	var rect := Rect2(Vector2.ZERO, pane.size)
	var placed := places()
	var scale_by := maxf(KeptPictures.scale_of(pane), 0.25)
	var key := "%s|%s|%.3f|%s|%s" % [short, pane.size.round(), scale_by, motto, placed.key()]
	if _kept != null and key == _kept_key:
		var whole := rect.grow(ROOM)
		pane.draw_texture_rect_region(_kept, whole, Rect2(Vector2.ZERO, whole.size * scale_by))
		return
	AtlasArt.cover(pane, rect, short, motto, placed)
	_want(key, scale_by, placed)


## The picture of the cover for [param key] asked for: drawn once what is wanted has stayed the
## same for [constant REST] frames, and until then waited for.
func _want(key: String, scale_by: float, placed: AtlasArt.Places) -> void:
	if not is_inside_tree() or Game.is_headless():
		return
	var frame := Engine.get_process_frames()
	if key != _wanted:
		_wanted = key
		_changed_frame = frame
	if frame - _changed_frame < REST:
		set_process(true)
		return
	if _drawing == key:
		return
	_drawing = key
	var drawing := Drawing.new()
	drawing.room = pane.size
	drawing.scale_by = scale_by
	drawing.short = short
	drawing.motto = motto
	drawing.places = placed
	var pixels := Vector2i(((pane.size + Vector2.ONE * ROOM * 2.0) * scale_by).ceil())
	DrawnTexture.kept(self, drawing, pixels, _keep.bind(key))


## The picture drawn for [param key], kept and shown should the pane still be as it was drawn for.
func _keep(texture: Texture2D, key: String) -> void:
	if _drawing == key:
		_drawing = ""
	if key != _wanted:
		return
	_kept = texture
	_kept_key = key
	pane.queue_redraw()


## Waits for the pane to rest at its size, then asks for its picture again.
func _process(_delta: float) -> void:
	if Engine.get_process_frames() - _changed_frame < REST:
		return
	set_process(false)
	pane.queue_redraw()


## Holds [param glyph], the bind that shows the card in full, over the card's bottom right corner
## and the photo corner there, in its place as the card moves; the one held before let go of. None
## for null.
func hold_bind(glyph: Control) -> void:
	var old := get_node_or_null("CardBind")
	if old != null:
		remove_child(old)
		old.queue_free()
	if glyph == null:
		return
	glyph.name = "CardBind"
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glyph)
	_place_bind()


## The card's bind on the card's bottom right corner, [constant BIND_IN] in from it, shown while the
## card is.
func _place_bind() -> void:
	var glyph := get_node_or_null("CardBind") as Control
	if glyph == null:
		return
	glyph.visible = card.is_visible_in_tree()
	var middle := _on_self(card).end - Vector2.ONE * BIND_IN
	glyph.position = middle - glyph.get_combined_minimum_size() * 0.5


## Over the pane's contents: tape at the map's corners, but its foot's left on a short screen,
## where that corner is the screen's own; and the card held in its photo corners.
func _draw() -> void:
	var map := _on_self(well)
	var long := TAPE_SHORT if short else TAPE
	var strips: Array[Array] = [
		[Vector2(map.end.x, map.position.y), PI * 0.25], [map.end, -PI * 0.25]
	]
	if not short:
		strips.append([Vector2(map.position.x, map.end.y), PI * 0.25])
	for strip: Array in strips:
		piece(self, AtlasCover.Kind.TAPE, strip[0], strip[1], long)
	if card.is_visible_in_tree():
		var turn := 0.0
		for corner: Array in AtlasArt.corners_of(_on_self(card)):
			piece(self, AtlasCover.Kind.SLIT, corner[0], turn, 0.0)
			turn += PI * 0.5


## A strip of tape [param long] long, a photo corner, a pencil [param long] long from its
## eraser's end, or the coil along the top of a slip [param long] wide from its top left corner, at
## [param at] on [param on] turned [param turn]: from its picture, or drawn as itself until that is
## ready. [param on] is in the group [constant PICTURES], to be drawn again
## once the picture is.
static func piece(on: CanvasItem, kind: Kind, at: Vector2, turn: float, long: float) -> void:
	var room := Vector2.ONE * (AtlasArt.SLIT + AtlasArt.SLIT_OUT)
	var middle := Vector2.ONE * AtlasArt.SLIT_OUT
	if kind == AtlasCover.Kind.TAPE:
		room = Vector2(long, long * AtlasArt.TAPE_WIDE)
		middle = room * 0.5
	elif kind == AtlasCover.Kind.PENCIL:
		room = Vector2(long + PENCIL_FALL.x, AtlasArt.PENCIL_HALF * 2.0 + PENCIL_FALL.y)
		middle = Vector2(0.0, AtlasArt.PENCIL_HALF)
	elif kind == AtlasCover.Kind.COIL:
		room = Vector2(long, AtlasArt.COIL_UP + AtlasArt.COIL_DOWN)
		middle = Vector2(0.0, AtlasArt.COIL_UP)
	room += Vector2.ONE * PICTURE_ROOM * 2.0
	middle += Vector2.ONE * PICTURE_ROOM
	var scale_by := maxf(KeptPictures.scale_of(on), 0.25)
	var picture := KeptPictures.of(
		on,
		"atlas_piece|%d|%d" % [kind, roundi(long)],
		Vector2i((room * scale_by).ceil()),
		func() -> Control:
			var drawing := Piece.new()
			drawing.kind = kind
			drawing.long = long
			drawing.middle = middle
			drawing.scale_by = scale_by
			return drawing,
		PICTURES
	)
	if picture == null:
		match kind:
			AtlasCover.Kind.TAPE:
				AtlasArt.tape(on, at, turn, long)
			AtlasCover.Kind.SLIT:
				AtlasArt.slit(on, at, Vector2.from_angle(turn + PI * 0.25) * sqrt(2.0))
			AtlasCover.Kind.PENCIL:
				AtlasArt.pencil(on, at, at + Vector2.from_angle(turn) * long)
			AtlasCover.Kind.COIL:
				AtlasArt.coil(on, at, long)
		return
	on.draw_set_transform(at, turn, Vector2.ONE)
	on.draw_texture_rect_region(picture, Rect2(-middle, room), Rect2(Vector2.ZERO, room * scale_by))
	on.draw_set_transform(Vector2.ZERO)


func _on_pane(node: Control) -> Rect2:
	var rect := node.get_global_rect()
	rect.position -= pane.global_position
	return rect


func _on_self(node: Control) -> Rect2:
	var rect := node.get_global_rect()
	rect.position -= global_position
	return rect
