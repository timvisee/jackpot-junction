class_name ProofCover
extends Control
## What dresses the catalog's pane as the House's press proof, GAME.md 8.8, see [ProofArt]. Under
## everything in the pane, the cutting mat, the page's sheet and the one under it, and what lies
## in the mat's foot: drawn once into a picture of the pane at its size and shown from that every
## frame, and drawn as itself only until that picture is ready, or while the pane is still changing
## size. Over everything, each drawn once into a picture of its own: the crop marks round the cards
## showing, which move as they scroll; the swatch fan spilling off the mat's foot; the loupe on the
## large card; the bulldog clip on the spec sheet; and the job ticket under the column. It stands
## last in the pane, over the rest, and takes no input.

## How many frames the pane keeps its size and its layout before its mat is drawn into a picture
## at them, as the loyalty program's cover waits, see [constant AtlasCover.REST].
const REST := 2
## The room round the pane the mat's picture takes in, for its shadow.
const ROOM := 32.0
## How many pictures of the mat are kept at once: the one shown, and the size before it, for a
## window dragged back. The same picture serves both pages; what each sheet says in its foot is
## drawn over it, see [method ProofArt.foot_line].
const KEPT := 2
## The room inside the mat round what is in the pane, left, top, right and foot, with room and
## short of it; and how far in from the sheet's edge the cards stand, for the printer's marks.
const INSIDE: Array[float] = [44.0, 44.0, 44.0, 44.0]
const INSIDE_SHORT: Array[float] = [20.0, 18.0, 20.0, 20.0]
const SHEET_IN := 34
const SHEET_IN_SHORT := 22
## How far up from the sheet's foot the cards stop on a short screen, for its line under them.
const SHEET_FOOT_SHORT := 32
## The foot's things: how far in from the sheet's edge the steel rule starts, how far past it the
## swatch fan's rivet is and the tin past that, and how far short of Back they stop.
const RULE_IN := 10.0
const FAN_PAST := 30.0
const TIN_PAST := 270.0
const TIN_ROOM := 410.0
const BACK_ROOM := 60.0
## How much of the foot's room past what they need the fan and the tin each move along by, so a
## wide screen spreads them over the foot rather than leaving them all at its left end.
const FAN_SPREAD := 0.3
const TIN_SPREAD := 0.4
## How far up off the foot's middle the fan's rivet is.
const FAN_UP := 10.0
## The job ticket: how far under what it lies under, how far in, and how far short of Back.
const TICKET_UNDER := 30.0
const TICKET_IN := 14.0
const TICKET_ABOVE := 14.0
## The bulldog clip: how far in from the spec sheet's right edge.
const CLIP_IN := 60.0
## How far the pane, the sheet or a place in the foot may move before the mat is drawn again for
## it, see [method _settled].
const NEAR := 1.5
## The group of what shows the pictures of the things over the pane, told once they are drawn, and
## the step their sizes are rounded up to.
const PICTURES := &"proof_pictures"
const STEP := 8

## The job line in each sheet's foot, and the job ticket's head and lines, GAME.md 8.8.
const JOKER_SHEET := "JOKER DECK  ·  SHEET 1 OF 2  ·  %d OF %d PRINTED"
const ITEM_SHEET := "POWER-UP SET  ·  SHEET 2 OF 2  ·  %d OF %d PRINTED"
## The stamp across the head of the jokers' sheet while it shows one suit alone, GAME.md 8.8.
const ONLY := "%s ONLY  ·  %d OF %d"
const WILD_ONLY := "WILD CARDS ONLY  ·  %d OF %d"
const TICKET := "JOB TICKET"
const TICKET_NUMBERED := "JOB TICKET    No. %s"
const CUSTOMER := "CUSTOMER"
const JOB := "JOB"
const JOKER_JOB := "Joker deck, %d cards"
const ITEM_JOB := "Power-up set, %d"
const STOCK := "STOCK"
const HOUSE_STOCK := "House card, 300 g"
const INKS := "INKS"
const HOUSE_INKS := "4 col. + house gold"
const PRINTED := "PRINTED"
const PRINTED_OF := "%d of %d"
## The pictures of the mat kept, by what each was drawn for, the oldest first.
static var _kept: Dictionary[String, Texture2D] = {}

## The pane it dresses, the pages in it, and what in it the things on the mat go by: the foot row
## and Back.
var pane: PanelContainer
var tabs: TabContainer
var foot: Control
var back: Control
## Whether the pane fills a short screen, see [method fit].
var short := false
## The story's motto in the sheet's foot, and each page's job line beside it, by the page's index.
var motto := ""
var slugs: Array[String] = []
## The job ticket's head and each page's lines under it, by the page's index, see
## [method ProofArt.job_ticket].
var ticket_head := ""
var tickets: Array = []

## The pane's size, the sheet and the places in the foot the mat was last drawn for: kept until
## any of them moves by a pixel or more, as a layout settles a hair either side of a size and the
## mat would be drawn again for each, see [method _settled].
var _settled_size := Vector2.ZERO
var _settled_sheet := Rect2()
var _settled_places := ProofArt.Places.new()
## What the mat is being drawn into a picture for, what it was last asked for, and the frame that
## last changed on.
var _drawing := ""
var _wanted := ""
var _changed_frame := 0


## The mat as a picture, drawn by [DrawnTexture] at its pixels: the pane's room and the room round
## it, scaled up to them.
class Drawing:
	extends Control

	var room: Vector2
	var scale_by := 1.0
	var sheet: Rect2
	var places: ProofArt.Places
	var short := false

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		draw_set_transform(Vector2.ONE * ProofCover.ROOM * scale_by, 0.0, Vector2.ONE * scale_by)
		ProofArt.mat(self, Rect2(Vector2.ZERO, room), sheet, places, short)


## One thing over the pane as a picture drawn once a run: [member draw_it] called with the picture
## as what to draw on and the transform to draw it with, its origin at [member middle] of its room,
## scaled up to its pixels.
class Piece:
	extends Control

	var middle: Vector2
	var scale_by := 1.0
	var draw_it: Callable

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		draw_it.call(self, Transform2D(0.0, Vector2.ONE * scale_by, 0.0, middle * scale_by))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(PICTURES)
	pane.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	pane.draw.connect(_draw_mat)
	for each: Control in [foot, back]:
		each.item_rect_changed.connect(_redraw_all)
		each.visibility_changed.connect(_redraw_all)
	tabs.tab_changed.connect(func(_tab: int) -> void: _redraw_all())
	for index: int in tabs.get_tab_count():
		var page := tabs.get_tab_control(index)
		(page.get_node("Well") as Control).item_rect_changed.connect(_redraw_all)
		var scroll := page.get_node("Well/Scroll") as ScrollContainer
		scroll.get_v_scroll_bar().value_changed.connect(func(_to: float) -> void: queue_redraw())
		for path: String in ["Well/Scroll/Grid", "Side/Column/Preview", "Side/Column/Pane"]:
			(page.get_node(path) as Control).item_rect_changed.connect(queue_redraw)
		# The card the large picture shows, for its suit under the loupe.
		(page.get_node("Side/Column/Preview") as Control).draw.connect(queue_redraw)
		var switches := page.get_node_or_null("Side/Column/Switches") as Control
		if switches != null:
			switches.item_rect_changed.connect(queue_redraw)
	set_process(false)


## The mat with room round the pane or [param is_short] of it, where the pane fills the screen: the
## room inside it round the pane's contents and round the cards on the sheets, and it drawn again.
## Called after [method CatalogDialog.fill_screen], whose room round the cards it replaces.
func fit(is_short: bool) -> void:
	short = is_short
	var inside := pane.get_theme_stylebox(&"panel") as StyleBoxEmpty
	var room := INSIDE_SHORT if short else INSIDE
	for side: int in 4:
		inside.set_content_margin(side as Side, room[side])
	for index: int in tabs.get_tab_count():
		var well := tabs.get_tab_control(index).get_node("Well") as ListBox.Well
		well.set_inset(SHEET_IN_SHORT if short else SHEET_IN)
		well.add_theme_constant_override("margin_bottom", SHEET_FOOT_SHORT if short else SHEET_IN)
	_redraw_all()


## What the press proof says of each page of [param pages], each its cards' ids, the jokers' and
## the power-ups': the job line in its sheet's foot, how many of how many were printed, and the job
## ticket's lines, for the profile playing in [param settings].
func say(settings: Settings, pages: Array[Array]) -> void:
	var catalog := settings.profile.catalog
	var number := settings.license_number.to_upper()
	ticket_head = TICKET if number.is_empty() else TICKET_NUMBERED % number
	slugs.clear()
	tickets.clear()
	for i: int in pages.size():
		var ids: Array[StringName] = []
		ids.assign(pages[i])
		var found := catalog.found_of(ids)
		slugs.append((JOKER_SHEET if i == 0 else ITEM_SHEET) % [found, ids.size()])
		var lines: Array[PackedStringArray] = [
			PackedStringArray([CUSTOMER, settings.license_holder]),
			PackedStringArray([JOB, (JOKER_JOB if i == 0 else ITEM_JOB) % ids.size()]),
			PackedStringArray([STOCK, HOUSE_STOCK]),
			PackedStringArray([INKS, HOUSE_INKS]),
			PackedStringArray([PRINTED, PRINTED_OF % [found, ids.size()]]),
		]
		tickets.append(lines)


## The room inside a mat with room round the pane, as a pane's own look, to be put on the pane
## before it is laid out.
static func inside() -> StyleBoxEmpty:
	var room := StyleBoxEmpty.new()
	for side: int in 4:
		room.set_content_margin(side as Side, INSIDE[side])
	return room


## Where the things in the mat's foot lie, left of Back, by where the foot, Back and the sheet are
## now: the steel rule, the swatch fan past it and the tin past that, each only where there is room
## for it; and nothing on a short screen, whose pane has no foot.
func places() -> ProofArt.Places:
	var placed := ProofArt.Places.new()
	if not foot.is_visible_in_tree():
		return placed
	var y := _on_pane(foot).get_center().y
	var from := _on_pane(_page_node("Well")).position.x + RULE_IN
	var stop := _on_pane(back).position.x - BACK_ROOM
	var room := stop - from
	var rule := minf(ProofArt.RULE_LONG, room - FAN_PAST - TIN_ROOM - TIN_PAST)
	var tin := true
	if rule < ProofArt.RULE_LEAST:
		tin = false
		rule = minf(ProofArt.RULE_LONG, room - FAN_PAST - ProofArt.FAN_LONG)
	if rule < ProofArt.RULE_LEAST:
		return placed
	placed.rule = Rect2(
		Vector2(from, y - ProofArt.RULE_TALL * 0.5), Vector2(rule, ProofArt.RULE_TALL)
	)
	var needs := rule + FAN_PAST + (TIN_PAST + TIN_ROOM if tin else ProofArt.FAN_LONG)
	var spare := maxf(room - needs, 0.0)
	placed.fan = Vector2(from + rule + FAN_PAST + spare * FAN_SPREAD, y - FAN_UP)
	if tin:
		placed.tin = Vector2(placed.fan.x + TIN_PAST + spare * TIN_SPREAD, y + 6.0)
	return placed


## The page showing's job line, and its job ticket's lines.
func slug() -> String:
	return slugs[tabs.current_tab] if tabs.current_tab < slugs.size() else ""


func ticket() -> Array[PackedStringArray]:
	var lines: Array[PackedStringArray] = []
	if tabs.current_tab < tickets.size():
		lines.assign(tickets[tabs.current_tab])
	return lines


## Where the job ticket lies, over the screen's own room: under the stack's switches on the jokers'
## page, under the spec sheet on the items', clear of Back; nothing where there is not the room.
func ticket_spot() -> Rect2:
	var side := _page_node("Side")
	if side == null or not side.is_visible_in_tree():
		return Rect2()
	var above := _page_node("Side/Column/Switches")
	if above == null:
		above = _page_node("Side/Column/Pane")
	var top := _on_self(above).end.y + TICKET_UNDER
	var bottom := _on_self(side).end.y
	if back.is_visible_in_tree() and back.get_parent() == foot:
		bottom = minf(bottom, _on_self(back).position.y - TICKET_ABOVE)
	if bottom - top < ProofArt.TICKET_SIZE.y:
		return Rect2()
	return Rect2(Vector2(_on_self(above).position.x + TICKET_IN, top), ProofArt.TICKET_SIZE)


func _redraw_all() -> void:
	pane.queue_redraw()
	queue_redraw()


## The mat under the pane's contents: its picture, or, until that is ready for the pane as it now
## is, the mat drawn as itself and its picture asked for; and over it what the page's sheet says
## in its foot, a line or two of words.
func _draw_mat() -> void:
	_settled()
	var rect := Rect2(Vector2.ZERO, _settled_size)
	var sheet := _settled_sheet
	var placed := _settled_places
	var scale_by := maxf(KeptPictures.scale_of(pane), 0.25)
	var key := "%s|%s|%.3f|%s|%s" % [short, _settled_size, scale_by, sheet, placed.key()]
	var kept: Texture2D = _kept.get(key)
	if kept != null:
		var whole := rect.grow(ROOM)
		pane.draw_texture_rect_region(kept, whole, Rect2(Vector2.ZERO, whole.size * scale_by))
	else:
		ProofArt.mat(pane, rect, sheet, placed, short)
		_want(key, scale_by, sheet, placed)
	if sheet.has_area():
		ProofArt.foot_line(pane, sheet, slug(), motto)


## The pane's size, the sheet and the foot's places as the mat is drawn for them: as they are,
## rounded, unless none has moved by a pixel since it was last drawn, the hair a layout wobbles by
## as the column beside the cards changes, which would draw the whole mat again for nothing to see.
func _settled() -> void:
	var size := pane.size.round()
	var sheet := _sheet()
	var placed := places()
	var near := (
		size.distance_to(_settled_size) < NEAR
		and _near(sheet, _settled_sheet)
		and _near(placed.rule, _settled_places.rule)
		and placed.tin.distance_to(_settled_places.tin) < NEAR
	)
	if not near:
		_settled_size = size
		_settled_sheet = sheet
		_settled_places = placed


## Whether [param a] and [param b] are within a pixel or so of each other, corners and size.
static func _near(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) < NEAR and a.size.distance_to(b.size) < NEAR


## The page showing's sheet, its well's rect on the pane, or nothing for a page with no well.
func _sheet() -> Rect2:
	var well := _page_node("Well")
	if well == null or not well.is_visible_in_tree():
		return Rect2()
	var rect := _on_pane(well)
	return Rect2(rect.position.round(), rect.size.round())


## The picture of the mat for [param key] asked for: drawn once what is wanted has stayed the same
## for [constant REST] frames, and until then waited for.
func _want(key: String, scale_by: float, sheet: Rect2, placed: ProofArt.Places) -> void:
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
	drawing.room = _settled_size
	drawing.scale_by = scale_by
	drawing.sheet = sheet
	drawing.places = placed
	drawing.short = short
	var pixels := Vector2i(((_settled_size + Vector2.ONE * ROOM * 2.0) * scale_by).ceil())
	DrawnTexture.kept(self, drawing, pixels, _keep.bind(key))


## The picture drawn for [param key], kept with the few before it and shown should the pane still
## be as it was drawn for.
func _keep(texture: Texture2D, key: String) -> void:
	if _drawing == key:
		_drawing = ""
	_kept[key] = texture
	while _kept.size() > KEPT:
		_kept.erase(_kept.keys()[0])
	if key == _wanted:
		pane.queue_redraw()


## Waits for the pane to rest at its size, then asks for its picture again.
func _process(_delta: float) -> void:
	if Engine.get_process_frames() - _changed_frame < REST:
		return
	set_process(false)
	pane.queue_redraw()


## Over the pane's contents: the crop marks round the cards showing, the swatch fan in the foot, the
## loupe on the large card, the clip on the spec sheet and the job ticket under the column.
func _draw() -> void:
	_draw_crop_marks()
	_draw_stamp()
	var placed := places()
	if placed.fan != Vector2.ZERO:
		var fan := ProofArt.fan_reach()
		_piece("proof_fan", _on_self_point(placed.fan), fan, ProofArt.swatch_fan)
	var preview := _page_node("Side/Column/Preview") as CardPreview
	var suit := _suit_of(preview)
	var loupe := preview != null and preview.is_visible_in_tree()
	loupe = loupe and preview.side() >= CardPreview.LEAST
	# The card's suit as a little card under the loupe, or with no room for the loupe before the
	# name in the pane, GAME.md 8.8.
	_title_suit(-1 if loupe else suit)
	if loupe:
		var across := preview.side()
		var box := _on_self(preview)
		var middle := Vector2(box.position.x + floorf((box.size.x - across) * 0.5), box.position.y)
		middle += Vector2.ONE * across * 0.5
		var reach := across * 0.5 + ProofArt.LOUPE_OUT
		_piece(
			"proof_loupe|%d" % roundi(reach),
			middle,
			ProofArt.loupe_reach(reach),
			func(on: CanvasItem, base: Transform2D) -> void: ProofArt.loupe(on, reach, base)
		)
		if suit >= 0:
			var bezel := reach + ProofArt.LOUPE_OUT + ProofArt.LOUPE_RIM * 0.5
			_piece(
				"proof_suit|%d" % suit,
				middle + Vector2.from_angle(ProofArt.SUIT_CARD_AT) * bezel,
				ProofArt.suit_card_reach(),
				func(on: CanvasItem, base: Transform2D) -> void: ProofArt.suit_card(on, suit, base)
			)
	var spec := _page_node("Side/Column/Pane")
	if spec != null and spec.is_visible_in_tree():
		var clip := Vector2(_on_self(spec).end.x - CLIP_IN, _on_self(spec).position.y)
		_piece("proof_clip", clip, Rect2(-60.0, -52.0, 120.0, 90.0), ProofArt.bulldog_clip)
	var spot := ticket_spot()
	if spot.has_area():
		var lines := ticket()
		var said := ticket_head
		for line: PackedStringArray in lines:
			said += "|" + " ".join(line)
		_piece(
			"proof_ticket|%d" % said.hash(),
			spot.get_center(),
			Rect2(-spot.size * 0.5, spot.size).grow(16.0),
			func(on: CanvasItem, base: Transform2D) -> void:
				ProofArt.job_ticket(on, ticket_head, lines, base)
		)


## The crop marks in the sheet's margins at the edges of the cards showing: their columns over and
## under the cards, their rows either side as they scroll.
func _draw_crop_marks() -> void:
	var grid := _page_node("Well/Scroll/Grid") as CardGrid
	var scroll := _page_node("Well/Scroll")
	if grid == null or not scroll.is_visible_in_tree():
		return
	var shown := _on_self(scroll)
	var across := PackedFloat32Array()
	var down := PackedFloat32Array()
	for cell: Control in grid.cells():
		var card := _on_self(cell).grow(-CatalogCell.FRAME_ROOM)
		if across.size() < grid.columns * 2:
			across.append_array([card.position.x, card.end.x])
		for y: float in [card.position.y, card.end.y]:
			if y >= shown.position.y - 1.0 and y <= shown.end.y + 1.0 and not down.has(y):
				down.append(y)
	ProofArt.crop_marks(self, shown, across, down)


## A thing over the pane at [param at], reaching [param reach] round it, from its picture kept by
## [param key], or drawn by [param draw_it] as itself until that is ready, given what to draw on and
## the transform to draw with, its origin at the thing's middle.
func _piece(key: String, at: Vector2, reach: Rect2, draw_it: Callable) -> void:
	var scale_by := maxf(KeptPictures.scale_of(self), 0.25)
	var room := reach.size
	var middle := -reach.position
	var pixels := Vector2i(
		KeptPictures.step_up(room.x * scale_by, STEP), KeptPictures.step_up(room.y * scale_by, STEP)
	)
	var picture := KeptPictures.of(
		self,
		key,
		pixels,
		func() -> Control:
			var drawing := Piece.new()
			drawing.middle = middle
			drawing.scale_by = scale_by
			drawing.draw_it = draw_it
			return drawing,
		PICTURES
	)
	if picture == null:
		draw_it.call(self, Transform2D(0.0, at))
		draw_set_transform(Vector2.ZERO)
		return
	var shown := Vector2(pixels) / scale_by
	draw_texture_rect(picture, Rect2(at - middle, shown), false)


## The node at [param path] in the page showing, or null.
## Across the head of the jokers' sheet while it shows one suit's cards alone, the stamp that says
## so and how many of them it shows: easier to see than the chip pressed in under the pane.
func _draw_stamp() -> void:
	var words := stamp_words()
	var well := _page_node("Well")
	if words.is_empty() or well == null or not well.is_visible_in_tree():
		return
	var suit := CatalogDialog.suit_shown
	var sheet := _on_self(well)
	var at := Vector2(sheet.get_center().x, sheet.position.y + (12.0 if short else 15.0))
	_piece(
		"proof_stamp|%s" % words,
		at,
		ProofArt.filter_stamp_reach(),
		func(on: CanvasItem, base: Transform2D) -> void:
			ProofArt.filter_stamp(on, suit, words, base)
	)


## What the stamp across the jokers' sheet says, or nothing while it shows every suit.
func stamp_words() -> String:
	var suit := CatalogDialog.suit_shown
	var grid := _page_node("Well/Scroll/Grid") as CardGrid
	if tabs.current_tab != 0 or suit == SuitFilter.ALL or grid == null:
		return ""
	var shown := grid.cells().size()
	var all := grid.get_child_count()
	if suit == Joker.Suit.WILD:
		return WILD_ONLY % [shown, all]
	return ONLY % [JokerSuits.name_of(suit).to_upper(), shown, all]


## The suit of the joker [param preview] shows, or -1 for none: an item, or a card face down.
static func _suit_of(preview: CardPreview) -> int:
	if preview == null or preview.kind != CardPreview.Kind.JOKER:
		return -1
	var joker := CatalogDialog.CATALOG.by_id(preview.id)
	return joker.suit if joker != null else -1


## Has the joker pane showing put [param suit] before the card's name, or nothing for -1, once it
## is not saying so already.
func _title_suit(suit: int) -> void:
	var spec := _page_node("Side/Column/Pane") as JokerDetail
	if spec != null and spec.title_suit() != suit:
		spec.show_title_suit.call_deferred(suit)


func _page_node(path: String) -> Control:
	var page := tabs.get_current_tab_control()
	return page.get_node_or_null(path) as Control if page != null else null


func _on_pane(node: Control) -> Rect2:
	var rect := node.get_global_rect()
	rect.position -= pane.global_position
	return rect


func _on_self(node: Control) -> Rect2:
	var rect := node.get_global_rect()
	rect.position -= global_position
	return rect


func _on_self_point(on_pane: Vector2) -> Vector2:
	return on_pane + pane.global_position - global_position
