class_name PartHook
extends Button
## The hook of one part of a kart's dress on the kart dialog's pegboards, GAME.md 4.4a, see
## [BoardArt]: the piece worn hanging from its peg over its painted outline, its name written on
## the hook's tape, in its finish where it has one. Pressed, it opens the tray of that part's
## pieces, see [PartTray]; while that is open it is lit. Looked at, by the mouse over it or the
## cursor on it, the dialog ties a rope from it to where its part is on the kart. The last on the
## right is the shuffle's plate rather than a hook, every part at random: only its push button is
## drawn here, lit while the mouse or the cursor is on it and pushed in while it is pressed, and
## for a moment as it rolls, the shuffle done by its key or a pad's button as much as by a click.
##
## The board, the outline, the clip and the tape are the bay's picture, see [BayCover]; only the
## piece and the words on the tape are drawn here, and the hook picked out as the rack's places are,
## see [method PartTray.draw_place]: its tape gold and glowing and its outline lit while the cursor
## is on it or its rack is out, and in white while the mouse is over it. While its rack holds a
## piece the dialog has not shown yet it wears the NEW tag, see [method set_fresh].

## How long the shuffle's push button spins once pressed, its die's faces running down through it as
## a slot machine's reel does, see [method BoardArt.draw_push]: how many faces go by, how far into
## the roll it starts to brake, and comes to its last, a little past it, how far past, and how fast
## it spins, in faces a second, for its pips to be drawn out all they are.
const ROLL := 1.0
const ROLL_FACES := 12
const ROLL_BRAKE := 0.35
const ROLL_STOP := 0.8
const ROLL_PAST := 0.22
const ROLL_BLUR := 30.0
## How long the push button stays pushed in as it rolls, for a shuffle done by a key.
const PUSH_TIME := 0.14
## How far round the hook its picked-out picture reaches, for its tape's glow, and the group told
## when one is ready, see [method _draw_picked].
const PICKED_AROUND := 16.0
const PICKED := &"part_hooks_picked"
## The hook's words: the name of the piece as big as fits the tape, and the finish under it.
const WORDS_SIZE := 26
const WORDS_LEAST := 14

## Which part, in the order of [constant KartStyle.CHOICES], the card back after them, or the
## shuffle.
var part := 0
## The piece worn, what it is called, and the finish it is in.
var worn := ""
var finish_word := ""
## Whether its part's tray is open.
var lit := false
## Whether it wears the NEW tag, see [method set_fresh].
var fresh := false
var picture: DressPicture
## The die's face on the shuffle's push button, and how far into a roll of it it is, or -1.
var face := 5

var _rolling := -1.0
## How much longer it stays pushed in from a roll.
var _pushed := 0.0
## The faces on the reel of a roll: the face it showed first, the one it lands on last, and none the
## same as the one before.
var _reel := PackedInt32Array()
var _rng := RandomNumberGenerator.new()
var _tag: Control


static func make(part_of: int) -> PartHook:
	var hook := PartHook.new()
	hook.part = part_of
	hook.name = "Hook%s" % BayArt.part_word(part_of).capitalize().replace(" ", "")
	var slot := BoardArt.hook_rect(part_of)
	hook.position = slot.position
	hook.size = slot.size
	return hook


func _ready() -> void:
	add_to_group(FocusGlide.GROUP)
	add_to_group(PICKED)
	focus_mode = Control.FOCUS_ALL
	flat = true
	for look: StringName in [
		&"normal", &"hover", &"pressed", &"disabled", &"focus", &"hover_pressed"
	]:
		add_theme_stylebox_override(look, StyleBoxEmpty.new())
	if part != BoardArt.SHUFFLE:
		picture = DressPicture.make(part, 0, Color.WHITE)
		picture.ink = Color(BoardArt.PAINT, 0.7)
		var room := BoardArt.picture_of(part)
		picture.position = room.position - position
		picture.size = room.size
		add_child(picture)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	set_process(false)
	if part == BoardArt.SHUFFLE:
		_rng.randomize()
	_tell()


## Says it wears [param index] of its part, called [param named], in [param color] and
## [param finished], one of the loyalty program's finishes or 0.
func say(index: int, named: String, color: Color, finished: int) -> void:
	worn = named
	finish_word = Loyalty.FINISHES[finished - 1] if finished > 0 else ""
	if picture != null:
		picture.show_choice(part, index, color, finished)
	queue_redraw()
	_tell()


## Named for a screen reader: its part, and the piece worn in its finish as its tape says, after
## its NEW tag, or for the shuffle what its plate says it does.
func _tell() -> void:
	var tagged := ScreenReader.spoken(CatalogCell.NEW) if fresh else ""
	var said := ScreenReader.line([tagged, worn, finish_word])
	if part == BoardArt.SHUFFLE:
		said = ScreenReader.spoken(BoardArt.SHUFFLE_SAYS)
	ScreenReader.name(self, ScreenReader.spoken(BayArt.part_word(part)), said)


## Whether it wears the NEW tag, GAME.md 4.4a: while its part's rack holds a piece won, or moved up
## a finish, that the dialog has not shown yet. Hung over its outline's top corner away from its
## tape, as a card's is over the card's, a picture of itself, see [CatalogCell].
func set_fresh(on: bool) -> void:
	if on == fresh:
		return
	fresh = on
	if on:
		var outline := BoardArt.outline_of(part)
		var left := BoardArt.on_left(part)
		var corner := Vector2(outline.position.x if left else outline.end.x, outline.position.y)
		_tag = BayNew.new_tag_at(self, corner - position, left)
	else:
		_tag.hide()
		_tag.queue_free()
		_tag = null
	_tell()


func set_lit(on: bool) -> void:
	lit = on
	queue_redraw()


## Whether the dialog should tie its rope now: the mouse over it, the cursor on it, or its tray out.
func looked_at() -> bool:
	return is_hovered() or has_focus() or lit


## Where the cursor's frame slides to and from, see [FocusGlide]: the outline its piece hangs in,
## or for the shuffle its plate.
func focus_frame() -> Rect2:
	if part == BoardArt.SHUFFLE:
		return Rect2(Vector2.ZERO, size).grow(4.0)
	var outline := BoardArt.outline_of(part)
	return Rect2(outline.position - position, outline.size).grow(2.0)


## The shuffle's die spun as a slot machine's reel: its faces running down through the button,
## fast and then slowing, until it comes to rest on one at random, the button pushed in a moment
## as it starts. Pressed again as it spins, it spins on from the face it is on.
func roll() -> void:
	_pushed = PUSH_TIME
	var from := face
	if _rolling >= 0.0:
		from = _reel[clampi(roundi(reel_run(_rolling / ROLL)), 0, _reel.size() - 1)]
	_reel = PackedInt32Array([from])
	for i: int in ROLL_FACES:
		var next := _rng.randi_range(1, 5)
		_reel.append(next + 1 if next >= _reel[-1] else next)
	_rolling = 0.0
	set_process(true)


## How many faces on the reel has run at [param t] into a roll, from 0 to 1: spinning at full speed,
## then braking evenly, coming to a stop a little past its last face, and settling back onto it.
static func reel_run(t: float) -> float:
	if t >= ROLL_STOP:
		return ROLL_FACES + ROLL_PAST * (1.0 - smoothstep(ROLL_STOP, 1.0, t))
	# Full speed until it brakes, as fast as gets it to its stop by then, braking to nothing.
	var u := t / ROLL_STOP
	var brake := ROLL_BRAKE / ROLL_STOP
	var speed := 2.0 / (1.0 + brake)
	var run := speed * u
	if u > brake:
		var braked := u - brake
		run -= speed * braked * braked / (2.0 * (1.0 - brake))
	return (ROLL_FACES + ROLL_PAST) * run


func _process(delta: float) -> void:
	if _rolling < 0.0:
		set_process(false)
		return
	_rolling += delta
	_pushed = maxf(_pushed - delta, 0.0)
	if _rolling >= ROLL:
		_rolling = -1.0
		face = _reel[-1]
	queue_redraw()


func _draw() -> void:
	if part == BoardArt.SHUFFLE:
		var down := get_draw_mode() in [DRAW_PRESSED, DRAW_HOVER_PRESSED] or _pushed > 0.0
		var at := BoardArt.push_of() - position
		var lit_up := is_hovered() or has_focus()
		if _rolling < 0.0:
			BoardArt.draw_push(self, at, lit_up, down, face)
		else:
			var t := _rolling / ROLL
			var speed := (reel_run(minf(t + 0.02, 1.0)) - reel_run(t)) / (0.02 * ROLL)
			var blur := clampf(speed / ROLL_BLUR, 0.0, 1.0)
			BoardArt.draw_push(self, at, lit_up, down, face, _reel, reel_run(t), blur)
	elif has_focus() or lit:
		_draw_picked(true)
	elif is_hovered():
		_draw_picked(false)
	if part != BoardArt.SHUFFLE:
		var tape := BoardArt.tape_of(part)
		tape.position -= position
		var face := BayArt.marker_font()
		var words_size := WORDS_SIZE
		while (
			BayArt.wide_of(worn, words_size, face) > tape.size.x - 16.0 and words_size > WORDS_LEAST
		):
			words_size -= 1
		BayArt.words(self, tape.get_center(), worn, words_size, BayArt.MARKER, face)
		if not finish_word.is_empty():
			BayArt.left(
				self,
				Vector2(tape.position.x + 4.0, tape.end.y + 14.0),
				finish_word.to_upper(),
				13,
				Color(BoardArt.PAINT, 0.9),
				Type.display_font()
			)
	if part == BoardArt.SHUFFLE and (has_focus() or lit):
		draw_style_box(FocusGlide.look(), focus_frame())


## The hook picked out, by the cursor for [param cursor] and by the mouse otherwise, see
## [method draw_picked]: drawn once each way and kept, see [BayArt], one draw.
func _draw_picked(cursor: bool) -> void:
	var whole := Rect2(Vector2.ZERO, size.round()).grow(PICKED_AROUND)
	var which := part
	var shift := Vector2.ONE * PICKED_AROUND - BoardArt.hook_rect(part).position
	var art := BayArt.kept(
		self,
		"hook_picked:%d:%s:%s" % [part, cursor, whole.size],
		whole.size,
		func(on: CanvasItem) -> void: draw_picked(on, which, shift, cursor),
		PICKED
	)
	if art != null:
		draw_texture_rect(art, whole, false)
	else:
		draw_picked(self, part, -position, cursor)


## The hook of [param part] picked out on [param on], its stage moved by [param shift], as the
## rack's places are, see [method PartTray.draw_place]: by the cursor for [param cursor], its
## outline lit and the board in it warmed, its clip over that, and its tape gold and glowing; by the
## mouse its outline and its tape in white.
static func draw_picked(on: CanvasItem, of: int, shift: Vector2, cursor: bool) -> void:
	var outline := BoardArt.outline_of(of)
	outline.position += shift
	var tape := BoardArt.tape_of(of)
	tape.position += shift
	if cursor:
		BayArt.box(on, outline.grow(-2.0), 9.0, Color(HouseTheme.FOIL, PartTray.LIT_INSIDE))
	var edge := FeltArt.rounded(outline, 10.0)
	edge.append(edge[0])
	var ink := PartTray.LIT_OUTLINE if cursor else PartTray.POINTED_OUTLINE
	on.draw_polyline(edge, ink, 4.5, true)
	BoardArt.peg_and_clip(on, BoardArt.peg_of(of) + shift)
	if cursor:
		BayArt.draw_tape(on, tape.grow(2.0), HouseTheme.FOIL, HouseTheme.FOIL)
	else:
		BayArt.draw_tape(on, tape, PartTray.POINTED_TAPE)
