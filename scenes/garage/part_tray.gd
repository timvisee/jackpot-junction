class_name PartTray
extends Control
## The rack of one part's pieces in the kart dialog, GAME.md 4.4a: hung over the bench when a
## part's hook is pressed, a pegboard of the boards' own make, see [method BoardArt.draw_rack], each
## piece hanging from its peg on a clip over its outline painted in yellow, its name on a strip of
## masking tape under it, and the one worn in an outline of the house's gold with ON clipped to it.
## The part's None or its plain one first, then those won, then those not won yet: an outline
## painted in dashes with only a peg, a "?" stenciled in it and the tape saying where in the loyalty
## program it is won, GAME.md 8.9. A piece of the Steam supporter pack, 10.8, wears the pack's star
## pinned to its outline and a night-blue tape; where the pack is not owned it hangs dimmed in a
## dashed outline with "Supporter Pack" on its tape, and wearing it opens the pack's store page.
## Where the pack is not offered, as in a build from GitHub, its pieces are not on the rack at all.
## A piece won, or moved up a finish, that the dialog has not shown yet wears the NEW tag over its
## outline's top left corner, ON having the right, see
## [method TrayCell.set_fresh]. The cursor on a piece, or the mouse over it for as long as it is
## there, has the kart try it on, see [signal tried] and [signal left]; pressed, it is worn, see
## [signal chosen]. More pieces than the rack holds at once scroll along it, by the cursor, a drag
## or the chevrons at its ends; Close, a black plate stenciled as the motto's is, puts it away, see
## [signal done]. Along its top the part, how many of it are won, and the keys that wear a piece and
## put the rack away, drawn for the device in hand, see [method show_binds]. Hung out, it rises
## into its place from behind the bench's bottom edge, a little past and back; put away, it drops
## back behind it, see [method slide_in] and [method well].

## The cursor came to [param index]'s place, or the mouse over it; the mouse went off it; it was
## pressed; Close was.
signal tried(index: int)
signal left(index: int)
signal chosen(index: int)
signal done
## The Starlight switch pressed, GAME.md 10.8, see [member starlight].
signal starlight_pressed
## The supporter pack owned, or no longer, while it is out, GAME.md 10.8, as one bought in Steam's
## overlay is, see [method Store.recheck_supporter]: [param on] the piece the cursor is on, or -1.
signal pack_changed(on: int)

## How a place is picked out, see [method draw_place]: not at all, by the cursor on it, in the
## house's gold, its piece lifted off its peg, or by the mouse over it, in a soft white.
enum Look { PLAIN, CURSOR, POINTER }
## Whether a piece is of the supporter pack, and owned: none, owned, or offered and locked.
enum Pack { NONE, OWNED, LOCKED }

## The words along its top: the part, how many of its pieces are won, and what the keys do, or a
## finger on a touch screen.
const COUNT := "%d of %d won"
const WEAR := "%s wear it   %s put it away"
const WEAR_STARLIGHT := "%s wear it   %s put it away   %s starlight"
const WEAR_TOUCH := "tap a piece to wear it"
const BINDS_SIZE := 13
const HEADINGS: Array[String] = [
	"PAINTS", "HATS", "FLAGS", "TRAILS", "PLATE FRAMES", "TIRE MARKS", "BODIES", "CARD BACKS"
]
const NOT_WON := "?"
const ON := "ON"
## A piece of the supporter pack, GAME.md 10.8: what its tape says while the pack is not owned, the
## night-blue tape and the cream it is written in, the star pinned to its outline, where and how
## big, and how dim its piece hangs while the pack is not owned.
const SUPPORTER_PACK := "Supporter Pack"
const SUPPORTER_TAPE := Color("#1d2a4a")
const SUPPORTER_WORDS := Color("#f3ead2")
const SUPPORTER_STAR := Color("#f8eed4")
const STAR_AT := Vector2(4.0, -4.0)
const STAR_SIZE := 12.0
const LOCKED_DIM := 0.55
## The Starlight switch, GAME.md 10.8: a stenciled plate beside Close with the pack's star on it,
## where it stands and what it says, and its word's size; the star lit while the piece worn is in
## Starlight. Only where the pack is owned, and for a piece a finish lies on.
const STARLIGHT_AT := Rect2(858.0, -16.0, 170.0, 42.0)
const STARLIGHT := "STARLIGHT"
const STARLIGHT_SIZE := 17
const CLOSE := "CLOSE"
## How deep its frame is along the top, for its words, and round the rest.
const BAND := 30.0
const EDGE := 10.0
## Where its pieces hang, inside its frame between its chevrons, the chevrons either side of them,
## and Close at the right end of its top.
const INSIDE := Rect2(60.0, 30.0, 1280.0, 136.0)
const ARROW := Vector2(40.0, 120.0)
## Close stands up over the rack's top edge, a tab big enough to find and press.
const CLOSE_AT := Rect2(1036.0, -16.0, 160.0, 42.0)
const CLOSE_SIZE := 19
## A piece's place on it, how far apart they hang, and in each its outline and its tape.
const CELL := Vector2(138.0, 136.0)
const CELL_GAP := 12.0
const OUTLINE := Rect2(13.0, 20.0, 112.0, 74.0)
const TAPE := Rect2(6.0, 102.0, 126.0, 28.0)
## The places' group, told when the picture of a look of one is ready, and how far round a place its
## picture reaches, for its tape's glow and shadow.
const GROUP := &"part_tray_places"
const AROUND := 14.0
## The place the cursor is on: its outline painted over brighter, and how warm the board inside it
## is; the one the mouse is over: its outline white and its tape bright, see [method draw_place].
const LIT_OUTLINE := Color("#ffd55a")
const LIT_INSIDE := 0.3
const POINTED_OUTLINE := Color(1.0, 1.0, 1.0, 0.85)
const POINTED_TAPE := Color("#fbf7ec")
## How far its piece is lifted off its peg by the cursor, see [enum Look].
const LIFTED := 5.0
const WORDS_ON_RED := Color("#f6eedc")
## How far under its place it rises from, behind the bench's edge, and how long it takes to come up
## and to go down.
const SLIDE := 220.0
const SLIDE_IN := 0.26
const SLIDE_OUT := 0.16

var part := 0
var cells: Array[TrayCell] = []
## The Starlight switch, and whether the piece worn of the part is in Starlight, see
## [constant STARLIGHT_AT].
var starlight: Button
var starlight_on := false
## Whether it is hung out, or on its way out, and how it slides.
var _out := false
var _slide: Tween
var _scroll: ScrollContainer
var _row: HBoxContainer
var _count := ""
var _binds: Control
var _back_arrow: Button
var _on_arrow: Button
## The device the binds were last drawn for, see [method show_binds].
var _hinted: Array = [false, true, false]
## Whether the supporter pack was owned when it was last filled, see [signal pack_changed].
var _filled_owned := false


## Out, and the supporter pack owned or no longer since it was filled, says so, see
## [signal pack_changed].
func _process(_delta: float) -> void:
	if not _out or cells.is_empty() or Supporter.owned() == _filled_owned:
		return
	_filled_owned = Supporter.owned()
	var on := -1
	for cell: TrayCell in cells:
		if cell.has_focus():
			on = cell.index
	pack_changed.emit(on)


## What it slides in and out of behind the bench's edge: the stage, cut off at its foot, hung on the
## stage for the rack to be hung in.
static func well() -> Control:
	var room := Control.new()
	room.name = "TrayWell"
	room.size = BayArt.STAGE
	room.clip_contents = true
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return room


## Hung out over the bench, rising into its place, unless it is out already.
func slide_in() -> void:
	if _out:
		return
	_out = true
	visible = true
	_slide_to(BayArt.TRAY.position.y, SLIDE_IN, Tween.TRANS_BACK, Tween.EASE_OUT)


## Put away, dropping back behind the bench's edge, and hidden once it is there.
func slide_out() -> void:
	if not _out:
		return
	_out = false
	_slide_to(BayArt.TRAY.position.y + SLIDE, SLIDE_OUT, Tween.TRANS_QUAD, Tween.EASE_IN)
	_slide.tween_callback(hide)


## Whether it is hung out, or on its way out, rather than put away or on its way down.
func is_out() -> bool:
	return _out


func _slide_to(y: float, took: float, how: Tween.TransitionType, easing: Tween.EaseType) -> void:
	if _slide != null:
		_slide.kill()
	_slide = create_tween().set_trans(how).set_ease(easing)
	_slide.tween_property(self, ^"position:y", y, took)


func _ready() -> void:
	position = BayArt.TRAY.position + Vector2(0.0, SLIDE)
	size = BayArt.TRAY.size
	mouse_filter = Control.MOUSE_FILTER_STOP
	# The frame's grain and the tapes' are tiles, laid over and over.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.position = INSIDE.position
	_scroll.size = INSIDE.size
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.follow_focus = true
	add_child(_scroll)
	TouchScroll.attach(_scroll)
	_row = HBoxContainer.new()
	_row.name = "Cells"
	_row.add_theme_constant_override("separation", int(CELL_GAP))
	_scroll.add_child(_row)
	_scroll.get_h_scroll_bar().value_changed.connect(func(_value: float) -> void: _say_arrows())
	_scroll.get_h_scroll_bar().changed.connect(_say_arrows)
	_row.resized.connect(_say_arrows)
	var arrow_y := INSIDE.position.y + (INSIDE.size.y - ARROW.y) * 0.5
	_back_arrow = _arrow(-1, Vector2(EDGE + 4.0, arrow_y))
	_on_arrow = _arrow(1, Vector2(size.x - EDGE - 4.0 - ARROW.x, arrow_y))
	var close := _plate_button("Close", CLOSE_AT)
	close.draw.connect(
		func() -> void:
			var box := Rect2(Vector2.ZERO, close.size)
			BoardArt.draw_stencil_plate(close, box, close.is_hovered(), false)
			var ink := BayArt.ENAMEL if close.is_hovered() else BoardArt.PAINT
			var middle := box.get_center().y
			for x: float in [11.0, box.size.x - 11.0]:
				BayArt.screw(close, Vector2(x, middle), 3.5, 0.7)
			var cross := Vector2(34.0, middle)
			for way: Vector2 in [Vector2(1.0, 1.0), Vector2(1.0, -1.0)]:
				close.draw_line(cross - way * 8.0, cross + way * 8.0, ink, 3.4, true)
			BayArt.left(close, Vector2(54.0, middle), CLOSE, CLOSE_SIZE, ink, Type.display_font())
	)
	close.pressed.connect(func() -> void: done.emit())
	starlight = _plate_button("Starlight", STARLIGHT_AT)
	starlight.hide()
	starlight.draw.connect(_draw_starlight)
	starlight.pressed.connect(func() -> void: starlight_pressed.emit())


## The Starlight switch's plate: stenciled as Close's is, the pack's star on its left, lit while the
## piece worn is in Starlight.
func _draw_starlight() -> void:
	var box := Rect2(Vector2.ZERO, starlight.size)
	BoardArt.draw_stencil_plate(starlight, box, starlight.is_hovered() or starlight_on, false)
	var ink := SUPPORTER_STAR if starlight_on else BoardArt.PAINT
	if starlight.is_hovered() and not starlight_on:
		ink = BayArt.ENAMEL
	var middle := box.get_center().y
	for x: float in [11.0, box.size.x - 11.0]:
		BayArt.screw(starlight, Vector2(x, middle), 3.5, 0.7)
	draw_star(starlight, Vector2(32.0, middle), STAR_SIZE if starlight_on else STAR_SIZE * 0.85)
	BayArt.left(
		starlight, Vector2(50.0, middle), STARLIGHT, STARLIGHT_SIZE, ink, Type.display_font()
	)


## The pieces of [param part_of] in the order the rack holds them: its None first where it has one,
## a trail's being past its plain smoke, then those [param owner] has won or everybody has, then
## those still to be won, each lot in the order the part has them; and at the very end those of the
## supporter pack where it is offered and not owned, see [method pack_of].
static func order_of(part_of: int, owner: KartOwner = null) -> Array[int]:
	var choices := KartDialog.choices_of(part_of)
	var order: Array[int] = []
	var none := choices.find("None")
	if none >= 0:
		order.append(none)
	var locked: Array[int] = []
	var later: Array[int] = []
	for i: int in choices.size():
		if i == none:
			continue
		var pack := pack_of(part_of, i)
		if pack == Pack.LOCKED:
			locked.append(i)
		elif pack == Pack.NONE and not Supporter.offered() and _of_the_pack(part_of, i):
			continue
		elif owner == null or owner.owns(part_of, i):
			order.append(i)
		else:
			later.append(i)
	order.append_array(later)
	order.append_array(locked)
	return order


## Whether [param index] of [param part_of], a card back past the kart's own parts, is a piece of
## the supporter pack, GAME.md 10.8, owned or not.
static func _of_the_pack(part_of: int, index: int) -> bool:
	if part_of == KartStyle.CHOICES.size():
		return index in CardBack.SUPPORTER
	return KartStyle.supporter(part_of, index)


## Whether [param index] of [param part_of] is a piece of the supporter pack, GAME.md 10.8, and
## whether it may be worn here: [enum Pack]'s none for any other piece, and for one of the pack's
## where the pack is not offered at all.
static func pack_of(part_of: int, index: int) -> Pack:
	var backs := part_of == KartStyle.CHOICES.size()
	if not (index in CardBack.SUPPORTER if backs else KartStyle.supporter(part_of, index)):
		return Pack.NONE
	if Supporter.owned():
		return Pack.OWNED
	return Pack.LOCKED if Supporter.offered() else Pack.NONE


## A flat button of the rack's at [param place], named [param called], drawn by whoever connects to
## its draw.
func _plate_button(called: String, place: Rect2) -> Button:
	var button := Button.new()
	button.name = called
	button.accessibility_name = called
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.position = place.position
	button.size = place.size
	for look: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"hover_pressed"]:
		button.add_theme_stylebox_override(look, StyleBoxEmpty.new())
	button.mouse_entered.connect(button.queue_redraw)
	button.mouse_exited.connect(button.queue_redraw)
	add_child(button)
	return button


## A chevron at [param at] that scrolls the rack a rackful toward [param way].
func _arrow(way: int, at: Vector2) -> Button:
	var arrow := _plate_button("Back" if way < 0 else "On", Rect2(at, ARROW))
	arrow.draw.connect(
		func() -> void:
			var box := Rect2(Vector2.ZERO, arrow.size)
			var lit := arrow.is_hovered() and not arrow.disabled
			BoardArt.draw_stencil_plate(arrow, box, lit, arrow.disabled)
			var ink := BayArt.ENAMEL if lit else BoardArt.PAINT
			BoardArt.chevron(arrow, box, way, Color(ink, 0.22) if arrow.disabled else ink)
	)
	arrow.pressed.connect(scroll_by.bind(way))
	return arrow


## The rack scrolled a rackful toward [param way], -1 back and 1 on.
func scroll_by(way: int) -> void:
	var bar := _scroll.get_h_scroll_bar()
	_scroll.scroll_horizontal = int(clampf(bar.value + way * bar.page, 0.0, bar.max_value))
	_say_arrows()


## The chevrons pressable only toward more pieces.
func _say_arrows() -> void:
	if _back_arrow == null:
		return
	var bar := _scroll.get_h_scroll_bar()
	_back_arrow.disabled = bar.value <= 1.0
	_on_arrow.disabled = bar.value + bar.page >= bar.max_value - 1.0
	_back_arrow.queue_redraw()
	_on_arrow.queue_redraw()


## Fills the rack with [param part_of]'s pieces as [param owner] has them: which are won, which is
## worn, in its color.
func fill(part_of: int, owner: KartOwner, worn: int, color: Color) -> void:
	part = part_of
	_filled_owned = Supporter.owned()
	for cell: TrayCell in cells:
		cell.hide()
		cell.queue_free()
	cells.clear()
	var choices := KartDialog.choices_of(part)
	var won := 0
	var unseen := owner.new_pieces()
	starlight.visible = Supporter.owned() and part_of < KartStyle.BODY and worn > 0
	starlight_on = starlight.visible and owner.starlit(part_of, worn)
	starlight.queue_redraw()
	ScreenReader.name(starlight, STARLIGHT.capitalize(), "on" if starlight_on else "off")
	for i: int in order_of(part, owner):
		var cell := TrayCell.new()
		cell.name = "Cell%d" % i
		cell.index = i
		cell.part = part
		cell.named = choices[i]
		cell.owned = owner.owns(part, i)
		cell.pack = pack_of(part, i)
		cell.worn = i == worn
		cell.where = "" if cell.owned else KartOwner.won_at(part, i)
		if cell.pack == Pack.LOCKED:
			cell.where = SUPPORTER_PACK
		cell.finish = owner.finish_of(part, i)
		cell.fresh = Vector2i(part, i) in unseen
		cell.color = color
		cell.focus_entered.connect(tried.emit.bind(i))
		cell.mouse_entered.connect(tried.emit.bind(i))
		cell.mouse_exited.connect(left.emit.bind(i))
		cell.pressed.connect(chosen.emit.bind(i))
		_row.add_child(cell)
		cells.append(cell)
		won += 1 if cell.owned else 0
	# The supporter pack's pieces where it is not owned are not won in the program, nor counted.
	var counted := cells.filter(func(each: TrayCell) -> bool: return each.pack != Pack.LOCKED)
	_count = COUNT % [won, counted.size()]
	_scroll.scroll_horizontal = 0
	_say_arrows()
	show_binds(_hinted[0], _hinted[1], _hinted[2])
	queue_redraw()
	ScreenReader.say(self, ScreenReader.line([ScreenReader.spoken(HEADINGS[part]), _count]))


## The keys that wear a piece and put the rack away, along its top after the count, for the device
## in hand: a tap's words on a touch screen for [param touch], Enter and Esc for [param keys], a
## click for Enter while [param pointer] has the mouse in hand, and A and B on a pad.
func show_binds(touch: bool, keys: bool, pointer: bool) -> void:
	_hinted = [touch, keys, pointer]
	if _binds != null:
		_binds.queue_free()
	var ink := Color(WORDS_ON_RED, 0.9)
	if touch:
		_binds = InputHint.row(WEAR_TOUCH, [], ink, BINDS_SIZE)
	else:
		var wear: InputEvent
		var away: InputEvent
		if keys:
			var enter := InputEventKey.new()
			enter.keycode = KEY_ENTER
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			wear = click if pointer else enter
			var escape := InputEventKey.new()
			escape.keycode = KEY_ESCAPE
			away = escape
		else:
			var accept := InputEventJoypadButton.new()
			accept.button_index = JOY_BUTTON_A
			var cancel := InputEventJoypadButton.new()
			cancel.button_index = JOY_BUTTON_B
			wear = accept
			away = cancel
		var glyphs: Array = [
			InputGlyph.of_event(wear, ink, BINDS_SIZE), InputGlyph.of_event(away, ink, BINDS_SIZE)
		]
		if starlight != null and starlight.visible:
			var star_key := InputEventKey.new()
			star_key.keycode = KEY_TAB
			var star_button := InputEventJoypadButton.new()
			star_button.button_index = JOY_BUTTON_Y
			glyphs.append(InputGlyph.of_event(star_key if keys else star_button, ink, BINDS_SIZE))
		_binds = InputHint.row(
			WEAR_STARLIGHT if glyphs.size() > 2 else WEAR, glyphs, ink, BINDS_SIZE
		)
	_binds.name = "Binds"
	add_child(_binds)
	_place_binds()


## The keys' row in the middle of the top's depth, past the part and its count.
func _place_binds() -> void:
	if _binds == null:
		return
	var heading := HEADINGS[part]
	var from := 34.0 + BayArt.wide_of(heading, 22, Type.mark_font())
	from += BayArt.wide_of(_count, 14, Type.STRONG) + 28.0
	_binds.position = Vector2(from, (BAND - _binds.get_combined_minimum_size().y) * 0.5).round()


## Marks [param index] the one worn.
func wear(index: int) -> void:
	for cell: TrayCell in cells:
		cell.set_worn(cell.index == index)


## The place of [param index] of the part's choices, wherever it is on the rack, or null.
func cell_at(index: int) -> TrayCell:
	for cell: TrayCell in cells:
		if cell.index == index:
			return cell
	return null


func _draw() -> void:
	BoardArt.draw_rack(self, Rect2(Vector2.ZERO, size), BAND, EDGE)
	var heading := HEADINGS[part]
	BayArt.left(self, Vector2(22.0, BAND * 0.5), heading, 22, WORDS_ON_RED, Type.mark_font())
	var from := 34.0 + BayArt.wide_of(heading, 22, Type.mark_font())
	BayArt.left(
		self, Vector2(from, BAND * 0.5 + 1.0), _count, 14, Color(WORDS_ON_RED, 0.85), Type.STRONG
	)


## The pictures of the three looks of a piece's place asked for ahead, while the rack is still put
## away, so the first time it is hung out its places are pictures already rather than drawn as
## themselves for a frame, see [method TrayCell._draw]; the same pictures, kept by the same names.
func warm() -> void:
	# The worn one with the cursor on it too: the cursor lands on it as the rack is hung out.
	for each: Array in [
		[true, false, Look.PLAIN],
		[true, true, Look.PLAIN],
		[false, false, Look.PLAIN],
		[true, true, Look.CURSOR]
	]:
		var hangs: bool = each[0]
		var in_gold: bool = each[1]
		var look: Look = each[2]
		BayArt.kept(
			self,
			"place:%s:%s:%s:%d" % [hangs, in_gold, CELL, look],
			CELL + Vector2.ONE * AROUND * 2.0,
			func(on: CanvasItem) -> void:
				draw_place(on, Vector2.ONE * AROUND, hangs, in_gold, look),
			GROUP
		)


## A piece's place on the rack, drawn on [param on] from [param at]: its outline, its peg and clip
## where it [param hangs], in gold for one [param worn] with ON clipped to it, or the "?" of one not
## won yet, and its tape. Picked out as [param look] says: for the cursor its tape gold foil, a
## little bigger and glowing on the board, which stands out from the masking tapes beside it on any
## screen, its outline painted over brighter and thicker and the board inside it warmed; for the
## mouse its outline and its tape in white. It
## looks one of a few ways, so it is drawn once a run each way and kept, see [BayArt]; only the
## piece and the words on its tape drawn over it, see [method tape_words].
static func draw_place(
	on: CanvasItem, at: Vector2, hangs: bool, worn: bool, look := Look.PLAIN, pack := Pack.NONE
) -> void:
	var outline := Rect2(OUTLINE.position + at, OUTLINE.size)
	if look == Look.CURSOR:
		BayArt.box(on, outline.grow(-2.0), 7.0, Color(HouseTheme.FOIL, LIT_INSIDE))
	BoardArt.draw_place(on, outline, hangs and pack != Pack.LOCKED, worn)
	if look != Look.PLAIN:
		var edge := FeltArt.rounded(outline, 8.0)
		edge.append(edge[0])
		on.draw_polyline(edge, LIT_OUTLINE if look == Look.CURSOR else POINTED_OUTLINE, 4.5, true)
	var tape := Rect2(TAPE.position + at, TAPE.size)
	match look:
		Look.CURSOR:
			BayArt.draw_tape(on, tape.grow(2.0), HouseTheme.FOIL, HouseTheme.FOIL)
		Look.POINTER:
			var pointed := POINTED_TAPE if pack == Pack.NONE else SUPPORTER_TAPE.lightened(0.2)
			BayArt.draw_tape(on, tape, pointed)
		_:
			BayArt.draw_tape(on, tape, BayArt.MASKING if pack == Pack.NONE else SUPPORTER_TAPE)
	if pack != Pack.NONE:
		draw_star(on, Vector2(outline.position.x, outline.end.y) + STAR_AT, STAR_SIZE)
	if not hangs and pack == Pack.NONE:
		BayArt.words(
			on, outline.get_center(), NOT_WON, 44, BoardArt.on_board(0.5), Type.mark_font()
		)
	if worn:
		var tag := Rect2(
			Vector2(outline.end.x - 32.0, outline.position.y - 8.0), Vector2(38.0, 18.0)
		)
		BayArt.box(on, Rect2(tag.position + Vector2(1.0, 2.0), tag.size), 4.0, Color(0, 0, 0, 0.45))
		BayArt.box(on, tag, 4.0, HouseTheme.FOIL)
		BayArt.words(on, tag.get_center(), ON, 12, HouseTheme.ON_FOIL, Type.display_font())


## The supporter pack's star, GAME.md 10.8, pinned at [param middle] on [param on]: a night-blue
## enamel pin [param radius] round with a cream rim and a four-pointed star on it, the star of the
## pack's stardust and its card backs.
static func draw_star(on: CanvasItem, middle: Vector2, radius: float) -> void:
	on.draw_circle(middle + Vector2(1.0, 2.0), radius + 1.0, Color(0.0, 0.0, 0.0, 0.4))
	on.draw_circle(middle, radius + 1.5, SUPPORTER_STAR)
	on.draw_circle(middle, radius, SUPPORTER_TAPE)
	var points := PackedVector2Array()
	for i: int in 8:
		var reach := radius * (0.78 if i % 2 == 0 else 0.24)
		points.append(middle + Vector2.UP.rotated(TAU * i / 8.0) * reach)
	on.draw_colored_polygon(points, SUPPORTER_STAR)


## A piece's place on the rack: the piece hanging in its outline with its name on the tape under
## it, or the "?" of one not won yet and where it is won, see [method draw_place].
class TrayCell:
	extends Button

	var index := 0
	var part := 0
	var named := ""
	var owned := true
	## Whether it is a piece of the supporter pack, and owned, see [method PartTray.pack_of].
	var pack := Pack.NONE
	var worn := false
	var where := ""
	var finish := 0
	## Whether it wears the NEW tag, see [method set_fresh].
	var fresh := false
	var color := Color.WHITE
	var picture: DressPicture
	## The picture of its place it showed last, shown on while a new one is drawn.
	var _art: Texture2D
	var _tag: Control

	func _ready() -> void:
		custom_minimum_size = CELL
		focus_mode = Control.FOCUS_ALL
		flat = true
		# Picked out by its own look rather than the menus' focus frame, see [method draw_place].
		add_to_group(GROUP)
		for look: StringName in [
			&"normal", &"hover", &"pressed", &"disabled", &"focus", &"hover_pressed"
		]:
			add_theme_stylebox_override(look, StyleBoxEmpty.new())
		if owned or pack == Pack.LOCKED:
			picture = DressPicture.make(part, index, color, finish)
			var room := OUTLINE.grow(-7.0)
			picture.position = room.position
			picture.size = room.size
			if pack == Pack.LOCKED:
				picture.modulate.a = LOCKED_DIM
			add_child(picture)
		for told: Signal in [focus_entered, focus_exited, mouse_entered, mouse_exited]:
			told.connect(_lift)
		focus_exited.connect(_tell)
		_hang_tag()
		_tell()

	## Named for a screen reader as its tape says it, with its NEW tag, and ON while it is the one
	## worn.
	func _tell() -> void:
		var tagged := ScreenReader.spoken(CatalogCell.NEW) if fresh else ""
		var on := ScreenReader.spoken(ON) if worn else ""
		var packed := SUPPORTER_PACK if pack == Pack.OWNED else ""
		var said := named + ", " + SUPPORTER_PACK if pack == Pack.LOCKED else tape_words()
		ScreenReader.name(self, said, ScreenReader.line([tagged, on, packed]))

	## Whether it wears the NEW tag, GAME.md 4.4a: won or moved up a finish and not shown yet.
	func set_fresh(on: bool) -> void:
		if on == fresh:
			return
		fresh = on
		_hang_tag()
		# Looked at, it is told again once the cursor has gone, as a catalog's card is.
		if not has_focus():
			_tell()

	## The NEW tag over its outline's top left corner while it is new, as a card's is over the
	## card's right, the right being where ON is clipped; a picture of itself, see [CatalogCell],
	## so the place's own picture is kept as it is.
	func _hang_tag() -> void:
		if fresh == (_tag != null):
			return
		if _tag != null:
			_tag.hide()
			_tag.queue_free()
			_tag = null
			return
		_tag = BayNew.new_tag_at(self, OUTLINE.position, true)

	## Its piece lifted off its peg while the cursor is on it, as if picked up to be looked at.
	func _lift() -> void:
		if picture != null:
			picture.position.y = OUTLINE.grow(-7.0).position.y - (LIFTED if has_focus() else 0.0)
		queue_redraw()

	func set_worn(on: bool) -> void:
		worn = on
		queue_redraw()
		_tell()

	## Where the cursor's frame slides to and from, see [FocusGlide]: the outline the piece hangs in.
	func focus_frame() -> Rect2:
		return OUTLINE.grow(2.0)

	## What it says on its tape: the piece and its finish, or where one not won yet is won.
	func tape_words() -> String:
		if not owned:
			return where
		return named + (" · " + Loyalty.finish_name(finish) if finish > 0 else "")

	func _draw() -> void:
		# By its size rounded: scrolled, a control's size drifts in its last places, and its
		# picture looked for by that was drawn again, the cell missing for a frame.
		var cell := Rect2(Vector2.ZERO, size.round())
		var whole := cell.grow(AROUND)
		var hangs := owned
		var in_gold := worn
		var look := Look.PLAIN
		if has_focus():
			look = Look.CURSOR
		elif is_hovered():
			look = Look.POINTER
		var packed := pack
		var art := BayArt.kept(
			self,
			"place:%s:%s:%s:%d:%d" % [hangs, in_gold, cell.size, look, packed],
			whole.size,
			func(on: CanvasItem) -> void:
				PartTray.draw_place(on, Vector2.ONE * AROUND, hangs, in_gold, look, packed),
			GROUP
		)
		# Until the picture of a new look is drawn, the last one, never nothing.
		if art != null:
			_art = art
		if _art != null:
			draw_texture_rect(_art, whole, false)
		else:
			PartTray.draw_place(self, Vector2.ZERO, owned, worn, look, pack)
		var says := tape_words()
		var face := BayArt.marker_font() if owned else BayArt.hand_font()
		var size_now := 16 if owned else 17
		while BayArt.wide_of(says, size_now, face) > TAPE.size.x - 10.0 and size_now > 10:
			size_now -= 1
		var ink := BayArt.MARKER
		if pack != Pack.NONE and not has_focus():
			ink = SUPPORTER_WORDS
		BayArt.words(self, TAPE.get_center(), says, size_now, ink, face)
