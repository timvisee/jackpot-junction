class_name CatalogCell
extends Control
## One place in the catalog's grid, GAME.md 8.8: a card face up, or for one never found its die
## line, not printed yet, see [DieLine]; which wears the cursor's frame under the cursor, the gold
## edge a button wears, a little way out round the card, the glide of [FocusGlide] sliding to it
## from wherever the cursor was; and a NEW tag on its corner while the profile has not yet looked
## at it. The card stays still: a card that
## lifts and grows out of a hand is the hand's, and a page of them doing it is restless. The card is
## drawn scaled to fit the cell, in the middle of it, the frame's room round it. Laid out by
## [CardGrid].

## The cursor has come to it: the pane says what it is, and it is no longer new.
signal looked_at(cell: CatalogCell)

## The room between the card's edge and the frame round it under the cursor.
const FRAME_ROOM := 7.0
## The NEW tag: its word, its size on the card, and how far it stands out over the card's corner.
const NEW := "NEW"
const NEW_SIZE := 15
const NEW_OUT := Vector2(10.0, -12.0)
## The group every NEW tag is in, told when the tag's picture is ready, see [NewTag].
const TAGS := &"new_tag_pictures"
## The group every cell is in, told when a card's picture is ready, see [method show_picture]; how
## far round the card its picture reaches, for the card's shadow; and the step its pixels are
## rounded up to.
const PICTURES := &"catalog_cell_pictures"
const PICTURE_ROOM := 8.0
const PICTURE_STEP := 8
## How much bigger the card comes up for a moment when Next new takes the cursor to it, and how long
## it takes to grow and to settle back, see [method pop].
const POP := 1.16
const POP_GROWS := 0.12
const POP_SETTLES := 0.45

## The joker or the item in this place, by id, and whether it was ever found.
var id: StringName
var found := false
## The card drawn: a [JokerCard] or [ItemCard] face up, a [DieLine] for one never found. Shown
## until its picture is ready, see [method show_picture], and kept, hidden, after.
var card: Control
## Why the pressman's grease pencil rings the card, a word each, or none, see [method set_marks].
var marks := PackedStringArray()

var _frame := FocusGlide.look()
var _tag: Control
## Over the card, the same size and in the same place, holding the NEW tag, which stays when the
## card itself is hidden for its picture.
var _over: Control
var _make: Callable
var _picture_of := ""
var _picture: Texture2D
## The card coming up and settling back while it does, see [method pop].
var _pop: Tween


## A place for the card [param make] makes, for [param what], face up where [param taken]; it
## makes the card again for its picture, which every card face down in the same back shares.
static func holding(what: StringName, taken: bool, make: Callable) -> CatalogCell:
	var cell := CatalogCell.new()
	cell.name = String(what)
	cell.id = what
	cell.found = taken
	cell.card = make.call()
	cell._make = make
	if cell.card is DieLine:
		cell._picture_of = "card|die"
	elif cell.card is CardBack:
		cell._picture_of = "card|back|%d" % CardBack.worn()
	else:
		cell._picture_of = "card|%s|%s" % ["joker" if cell.card is JokerCard else "item", what]
	cell.add_child(cell.card)
	cell.add_child(cell._over)
	cell._tell()
	return cell


## The size of a cell for a card drawn at [param scale] of its own: the card and the frame's room.
static func shape(scale_of: float) -> Vector2:
	return JokerCard.SIZE * scale_of + Vector2.ONE * FRAME_ROOM * 2.0


## The card drawn the eye to, GAME.md 8.8: a moment bigger, over the cards round it, and settling
## back, for the cursor Next new took to it from wherever it was, see [NextNew].
func pop() -> void:
	if _pop != null:
		_pop.kill()
	pivot_offset = size * 0.5
	z_index = 1
	_pop = create_tween()
	_pop.tween_property(self, "scale", Vector2.ONE * POP, POP_GROWS).set_trans(Tween.TRANS_BACK)
	_pop.tween_property(self, "scale", Vector2.ONE, POP_SETTLES).set_trans(Tween.TRANS_SINE)
	_pop.tween_callback(func() -> void: z_index = 0)


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	# Passed on as well, so the wheel and a finger's drag scroll the cards it stands among.
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_to_group(FocusGlide.GROUP)
	add_to_group(PICTURES)
	_over = Control.new()
	_over.name = "Over"
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.size = JokerCard.SIZE


## An entry of the catalog's list to a screen reader, see [ScreenReader].
func _notification(what: int) -> void:
	ScreenReader.drawn(self, what, AccessibilityServer.ROLE_LIST_ITEM)


## Names it for a screen reader: the card's name and words, or that it is not found yet, with its
## NEW tag and the words of the pressman's grease pencil round it.
func _tell() -> void:
	var words := card.accessibility_name if found else ""
	var more := card.accessibility_description if found else ""
	ScreenReader.name(
		self,
		words if not words.is_empty() else CatalogDialog.NOT_FOUND,
		ScreenReader.line(
			PackedStringArray([ScreenReader.spoken(NEW) if is_fresh() else "", more]) + marks
		)
	)


func _ready() -> void:
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	mouse_entered.connect(_on_mouse_entered)
	resized.connect(_place)
	_place()


## The mouse over it gives it the cursor, as it does any button; not on a touch screen, where the
## mouse a phone makes of a finger would give it every card a swipe passed over, see [TouchScroll].
func _on_mouse_entered() -> void:
	if not TouchInput.enabled:
		grab_focus()


func _draw() -> void:
	if has_focus():
		draw_style_box(_frame, Rect2(Vector2.ZERO, size))
	if _picture != null:
		var fit := card.scale.x
		var room := Vector2.ONE * PICTURE_ROOM
		draw_texture_rect(
			_picture, Rect2(card.position - room * fit, (JokerCard.SIZE + room * 2.0) * fit), false
		)


## The pressman's grease pencil round the card, GAME.md 8.8, with [param words] beside it for why:
## the first of its page found, the one taken most, the joker that went off most, see [method
## marks_of] and [method ProofArt.grease_ring]; none for no words. Drawn over the card and over the
## cells beside it, which it reaches a little way into.
func set_marks(words: PackedStringArray) -> void:
	if words == marks:
		return
	marks = words
	_tell()
	var worn := _over.get_node_or_null("Ring")
	if worn != null:
		worn.name = "RingGone"
		worn.queue_free()
	if words.is_empty():
		return
	var ring := Control.new()
	ring.name = "Ring"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.size = JokerCard.SIZE
	ring.z_index = 1
	ring.draw.connect(
		func() -> void:
			ProofArt.grease_ring(ring, Rect2(Vector2.ZERO, JokerCard.SIZE), _ends_row(), marks)
	)
	_over.add_child(ring)
	# Its OK goes to the other side of it as the card comes to the end of its row, or leaves it.
	item_rect_changed.connect(ring.queue_redraw)


## Whether the card is the last in its row of the grid, with nothing beside it on its right.
func _ends_row() -> bool:
	var grid := get_parent() as CardGrid
	return grid != null and get_index() % grid.columns == grid.columns - 1


func is_ringed() -> bool:
	return _over.has_node("Ring")


## Why each card of [param ids] that the pressman rings is ringed, by its id, GAME.md 8.8: the
## first of them found, the one taken or used the most, twice at least, and the joker that went off
## by itself the most.
static func marks_of(catalog: CatalogState, ids: Array[StringName]) -> Dictionary:
	var marks := {}
	for pair: Array in [
		[catalog.first_of(ids), ProofArt.RING_FIRST],
		[catalog.most_of(ids), ProofArt.RING_MOST],
		[catalog.most_gone_off(ids), ProofArt.RING_BEST],
	]:
		if pair[0] != &"":
			var words: PackedStringArray = marks.get(pair[0], PackedStringArray())
			words.append(pair[1])
			marks[pair[0]] = words
	return marks


## Whether the card wears the NEW tag, see [CatalogState.is_fresh].
func set_fresh(on: bool) -> void:
	if on == (_tag != null):
		return
	if on:
		_tag = new_tag()
		_over.add_child(_tag)
	else:
		_over.remove_child(_tag)
		_tag.queue_free()
		_tag = null
	# Looked at, it is told again once the cursor has gone: told at once, a reader would read the
	# card out a second time over without the tag.
	if not has_focus():
		_tell()


func is_fresh() -> bool:
	return _tag != null


func _on_focus(on: bool) -> void:
	queue_redraw()
	if on:
		looked_at.emit(self)
	else:
		_tell()


## The card scaled to fit the cell inside the frame's room, in the middle of it.
func _place() -> void:
	if card == null:
		return
	var full := JokerCard.SIZE
	var room := size - Vector2.ONE * FRAME_ROOM * 2.0
	var fit := maxf(minf(room.x / full.x, room.y / full.y), 0.0)
	card.pivot_offset = Vector2.ZERO
	card.scale = Vector2.ONE * fit
	card.position = (size - full * fit) * 0.5
	_over.scale = card.scale
	_over.position = card.position
	show_picture()


## The card as a picture of itself once that is drawn, GAME.md 10.7: a card is a few dozen
## controls and shapes, a page of them most of what the catalog cost a frame, and a picture is one
## draw. Drawn at the screen's own pixels for the size the card is shown at, see [KeptPictures];
## until it is ready, the card is shown as itself.
func show_picture() -> void:
	if card == null or not _make.is_valid() or not is_inside_tree():
		return
	var whole := JokerCard.SIZE + Vector2.ONE * PICTURE_ROOM * 2.0
	var across := whole.x * card.scale.x * KeptPictures.scale_of(self)
	if across < 1.0:
		return
	var wide := KeptPictures.step_up(across, PICTURE_STEP)
	var pixels := Vector2i(wide, roundi(wide * whole.y / whole.x))
	var make := _make
	_picture = KeptPictures.of(
		self,
		_picture_of,
		pixels,
		func() -> Control:
			var holder := Control.new()
			var copy: Control = make.call()
			var fit := pixels.x / whole.x
			copy.pivot_offset = Vector2.ZERO
			copy.scale = Vector2.ONE * fit
			copy.position = Vector2.ONE * PICTURE_ROOM * fit
			holder.add_child(copy)
			return holder,
		PICTURES,
		&"show_picture"
	)
	card.visible = _picture == null
	queue_redraw()


## Hangs the NEW tag over [param on]'s top right corner, or takes it off: the title's Clubhouse and
## the loyalty program's button wear it while a landmark is new, GAME.md 8.9.
static func tag(on: Control, fresh: bool) -> void:
	var worn := on.get_node_or_null("New")
	if fresh == (worn != null):
		return
	if worn != null:
		# Under another name until it goes, so a new one can take its own.
		worn.name = "NewGone"
		(worn as Control).hide()
		worn.queue_free()
		return
	on.add_child(new_tag())


## The chip of foil a NEW tag is, its shadow under it; the count of a dialog's Next new is on one
## too, see [NextNew].
static func foil() -> TicketStyle:
	var style := TicketStyle.cut(HouseTheme.FOIL, 4.0, 7.0, 2.0)
	style.shadow = 6.0
	return style


## The NEW tag: the word in the foil's dark ink on a chip of foil, over the card's top right corner.
static func new_tag() -> Control:
	var tag := NewTag.new()
	tag.name = "New"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := foil()
	tag.add_theme_stylebox_override("panel", style)
	var word := Label.new()
	word.text = NEW
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.strong(word, NEW_SIZE, HouseTheme.ON_FOIL)
	tag.add_child(word)
	tag.word = word
	tag.chip = style
	# Hung by its top right corner, growing left and down from there, since its words have no size
	# until they are in the tree.
	tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tag.offset_left = NEW_OUT.x
	tag.offset_right = NEW_OUT.x
	tag.offset_top = NEW_OUT.y
	tag.offset_bottom = NEW_OUT.y
	return tag


## The NEW tag, shown as a picture of itself once that is drawn, GAME.md 10.7: a page of cards
## wears a score of them, a few draws each drawn as they are, and every one is the same. Its word
## and its chip are kept, the word hidden and the chip swapped for room as big, so it stays the
## size it is.
class NewTag:
	extends PanelContainer

	## How far round the tag its picture reaches, for its shadow.
	const ROOM := 12.0

	var word: Label
	var chip: StyleBox
	## Whether it is drawn as itself every time, as the copy drawn for its own picture is.
	var live := false
	var _picture: Texture2D

	func _ready() -> void:
		add_to_group(CatalogCell.TAGS)
		draw.connect(_draw_picture)
		resized.connect(show_picture)
		show_picture()

	## The picture once it is ready, see [KeptPictures], and the tag as itself until then.
	func show_picture() -> void:
		if live or word == null or size.x < 1.0 or not is_inside_tree():
			return
		var shown := size
		var whole := shown + Vector2.ONE * ROOM * 2.0
		var scale := KeptPictures.scale_of(self)
		var pixels := Vector2i(ceili(whole.x * scale), ceili(whole.y * scale))
		_picture = KeptPictures.of(
			self,
			"new_tag",
			pixels,
			func() -> Control:
				var holder := Control.new()
				var copy := CatalogCell.new_tag() as NewTag
				copy.live = true
				copy.set_anchors_preset(Control.PRESET_TOP_LEFT)
				copy.custom_minimum_size = shown
				copy.size = shown
				copy.scale = Vector2.ONE * pixels.x / whole.x
				copy.position = Vector2.ONE * ROOM * copy.scale.x
				holder.add_child(copy)
				return holder,
			CatalogCell.TAGS,
			&"show_picture"
		)
		if _picture == null:
			return
		custom_minimum_size = shown
		var room := StyleBoxEmpty.new()
		for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			room.set_content_margin(side, chip.get_content_margin(side))
		add_theme_stylebox_override("panel", room)
		word.visible = false
		queue_redraw()

	func _draw_picture() -> void:
		if _picture != null:
			draw_texture_rect(
				_picture, Rect2(-Vector2.ONE * ROOM, size + Vector2.ONE * ROOM * 2.0), false
			)
